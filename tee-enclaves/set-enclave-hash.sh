#!/bin/bash

# MR Enclave Update Automation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/summary_generator.sh"
source "${SCRIPT_DIR}/contract_interaction.sh"

declare MRENCLAVE MRSIGNER RPC_URL NETWORK
declare NITRO_RUN_ID NITRO_KECCAK_HASH NITRO_IMAGE_NAME NITRO_ENCLAVER_NAME

# Load environment variables from repo root
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ -f "${ENV_FILE}" ]; then
    echo -e "${BLUE}📋 Loading environment variables from: ${ENV_FILE}${NC}"
    set -a
    source "${ENV_FILE}"
    set +a
    echo -e "${GREEN}✅ Environment variables loaded${NC}"
else
    echo -e "${YELLOW}⚠️  No .env file found at: ${ENV_FILE}${NC}"
    echo -e "${YELLOW}💡 Script will prompt for required values${NC}"
fi
MAIN_TEE_VERIFIER_ADDRESS=${MAIN_TEE_VERIFIER_ADDRESS:-""}
PRIVATE_KEY=${PRIVATE_KEY:-""}

cleanup() {
    if [ -f "${REPORT_BIN}" ] || [ -f "${REPORT_HEX}" ]; then
        echo -e "${YELLOW}🧹 Cleaning up intermediate files...${NC}"
        rm -f "${REPORT_BIN}" "${REPORT_HEX}"
        echo -e "${GREEN}✅ Intermediate files cleaned up${NC}"
    fi
}

trap cleanup EXIT

# =============================================================================
# SGX - EXTRACT ENCLAVE VALUES
# =============================================================================

check_report_file() {
    if [ ! -f "${REPORT_FILE}" ]; then
        echo -e "${RED}❌ Report file '${REPORT_FILE}' not found${NC}"
        echo -e "${YELLOW}💡 Please ensure you have a report.txt file with the enclave hash${NC}"
        echo -e "${YELLOW}💡 You can copy the enclave hash from the Batch Poster Docker logs${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found report file: ${REPORT_FILE}${NC}"
}

convert_to_binary() {
    echo -e "${YELLOW}🔄 Converting hex to binary...${NC}"
    
    if command -v xxd >/dev/null 2>&1; then
        xxd -r -p "${REPORT_FILE}" > "${REPORT_BIN}"
        echo -e "${GREEN}✅ Binary file created: ${REPORT_BIN}${NC}"
    else
        echo -e "${RED}❌ xxd command not found. Please install xxd or manually convert the file${NC}"
        exit 1
    fi
}

decode_report_data() {
    echo -e "${YELLOW}🔍 Decoding report data...${NC}"
    
    if [ -x "./decode_report_data.sh" ]; then
        ./decode_report_data.sh
        echo -e "${GREEN}✅ Report data decoded successfully${NC}"
    else
        echo -e "${RED}❌ decode_report_data.sh is not executable${NC}"
        chmod +x ./decode_report_data.sh
        ./decode_report_data.sh
        echo -e "${GREEN}✅ Report data decoded successfully after chmod +x${NC}"
    fi
}

extract_enclave_values() {
    echo -e "${YELLOW}🔍 Extracting enclave values...${NC}"
    
    MRENCLAVE=$(./decode_report_data.sh | grep "MRENCLAVE:" | cut -d' ' -f2)
    MRSIGNER=$(./decode_report_data.sh | grep "MRSIGNER:" | cut -d' ' -f2)
    
    if [ -z "${MRENCLAVE}" ]; then
        echo -e "${RED}❌ Could not extract MRENCLAVE value${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ MRENCLAVE extracted: ${MRENCLAVE}${NC}"
    echo -e "${GREEN}✅ MRSIGNER extracted: ${MRSIGNER}${NC}"
}

# =============================================================================
# AWS NITRO — COMPUTE PCR0 KECCAK FROM REMOTE BUILD
# =============================================================================

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo -e "${RED}❌ Missing required command: $1${NC}";
        return 1;
    }
}

generate_nitro_pcr0_remote() {
    echo -e "${YELLOW}🔧 Generating AWS Nitro PCR0 via GitHub Action${NC}"
    require_cmd gh || {
        echo -e "${RED}❌ GitHub CLI (gh) required. Install via:${NC}"
        echo "  brew install gh  # macOS"
        echo "  Or https://cli.github.com/"
        return 1
    }
    require_cmd cast || return 1

    if ! gh auth status &>/dev/null; then
        echo -e "${RED}❌ Not logged in to GitHub. Run:${NC}"
        echo "  gh auth login"
        return 1
    fi

    local nitro_tag
    read -p "Enter Nitro node tag (e.g. pr-689): " nitro_tag
    nitro_tag="${nitro_tag:-latest}"

    local enclaver_image_name
    read -p "Enter Enclaver image name (e.g. test): " enclaver_image_name
    enclaver_image_name="${enclaver_image_name:-test}"

    echo -e "${BLUE}📦 Triggering workflow in EspressoSystems/aws-nitro...${NC}"

    echo -e "${BLUE}⏳ Running workflow and capturing run ID...${NC}"
    gh workflow run "Build Enclaver Docker Image" \
        --repo EspressoSystems/aws-nitro \
        -F nitro_node_image_tag="$nitro_tag" \
        -F enclaver_image_name="$enclaver_image_name" \
        -F config_hash="0000000000000000000000000000000000000000000000000000000000000000"


    echo "Gh Run Name: Build Enclaver Docker Image - $enclaver_image_name"

    sleep 5

    run_list=$(gh run list --repo EspressoSystems/aws-nitro --workflow="Build Enclaver Docker Image" --json databaseId,displayTitle)

    run_id=$(echo "$run_list" | jq --arg name "$enclaver_image_name" '.[] | select(.displayTitle | contains($name)) | .databaseId' | head -n 1) || {
        echo -e "${RED}❌ Failed to get workflow run ID${NC}"
        return 1
    }

    if [ -z "$run_id" ]; then
        echo -e "${RED}❌ No valid run ID found${NC}"
        return 1
    fi
    echo "Retrieved run ID: $run_id"
    
    NITRO_RUN_ID="$run_id"
    NITRO_ENCLAVER_NAME="$enclaver_image_name"

    gh repo set-default EspressoSystems/aws-nitro || {
        echo -e "${RED}❌ Failed to set default repository for gh CLI${NC}"
        return 1
    }

    echo -e "${BLUE}🔄 Running GitHub Actions workflow...${NC}"
    local run_log status run_info timestamp
    
    while true; do
        sleep 5
        run_info=$(gh run view "$run_id" --repo EspressoSystems/aws-nitro --json status 2>/dev/null || echo "")
        status=$(echo "$run_info" | jq -r '.status')

        if [ "$status" = "completed" ]; then
            echo -e "${GREEN}✅ Workflow completed successfully${NC}"
            echo -e "${BLUE}⏳ Processing workflow results...${NC}"
            sleep 10
            
            run_log=$(gh run view "$run_id" --repo EspressoSystems/aws-nitro --log 2>/dev/null || echo "")
            keccak_hash=$(echo "$run_log" | grep -E 'PCR0 keccak hash: 0x[0-9a-fA-F]+' | tail -n1 | sed -n 's/.*PCR0 keccak hash: \(0x[0-9a-fA-F]*\).*/\1/p')
            timestamp=$(echo "$run_log" | grep -E 'TIMESTAMP:' | tail -n1 | sed -n 's/.*TIMESTAMP: \([0-9]*\).*/\1/p')
            
            if [ -n "$timestamp" ]; then
                image_name="ghcr.io/espressosystems/aws-nitro-poster:${enclaver_image_name}-${timestamp}"
            fi
            
            NITRO_KECCAK_HASH="$keccak_hash"
            NITRO_IMAGE_NAME="$image_name"
            MRENCLAVE="${keccak_hash#0x}"
            break
        fi
        if echo "$run_log" | grep -q "Run failed"; then
            echo -e "${RED}❌ Workflow failed${NC}"
            return 1
        fi
    done
    if [ -z "$keccak_hash" ]; then
        echo -e "${RED}❌ Failed to extract PCR0 hash from workflow logs${NC}"
        return 1
    fi

    echo ""
    echo -e "${GREEN}🎉 AWS Nitro PCR0 Generation Complete!${NC}"
    echo "=========================================="
    echo -e "${BLUE}📋 Results:${NC}"
    echo "   PCR0 Hash: ${keccak_hash}"
    if [ -n "$image_name" ]; then
        echo "   Image:     ${image_name}"
    fi
    echo "   Use the generated docker image in the Nitro Box"
    echo ""
}

# =============================================================================
# CONTRACT INTERACTION
# =============================================================================

prepare_contract_interaction() {
    echo -e "${YELLOW}🔗 Preparing contract update...${NC}"
    
    if [ "$TEE_TYPE" = "sgx" ]; then
        echo -e "${BLUE}🔍 Extracting SGX enclave values...${NC}"
        extract_enclave_values
        
        local summary_file=$(generate_sgx_summary "$MRENCLAVE" "$MRSIGNER" "$REPORT_FILE")
        echo -e "${GREEN}✅ Summary saved to ${summary_file}${NC}"
    else
        echo -e "${BLUE}🔍 Using AWS Nitro PCR0 hash...${NC}"
        echo -e "${GREEN}✅ MRENCLAVE ready for contract update: ${MRENCLAVE}${NC}"
        
        local summary_file=$(generate_nitro_summary "$NITRO_RUN_ID" "$NITRO_ENCLAVER_NAME" "$NITRO_KECCAK_HASH" "$NITRO_IMAGE_NAME" "$MRENCLAVE")
        echo -e "${GREEN}✅ Summary saved to ${summary_file}${NC}"
    fi
}

# =============================================================================
# OUTPUTS
# =============================================================================

show_usage() {
    echo -e "${BLUE}🔍 MR Enclave Update Automation${NC}"
    echo "============================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (no args)  - Full automation with contract update"
    echo "  --help     - Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  MAIN_TEE_VERIFIER_ADDRESS - Main EspressoTEEVerifier contract address (.env file)"
    echo "  PRIVATE_KEY          - Private key for contract owner (optional, will prompt for confirmation/input)"
    echo "  ETHEREUM_MAINNET_RPC - Ethereum mainnet RPC URL"
    echo "  ARBITRUM_MAINNET_RPC - Arbitrum mainnet RPC URL"
    echo "  ETHEREUM_SEPOLIA_RPC - Ethereum Sepolia RPC URL"
    echo "  ARBITRUM_SEPOLIA_RPC - Arbitrum Sepolia RPC URL"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full automation with contract update"
    echo "  $0 --help            # Show help"
    echo ""
    echo "  # With .env file containing MAIN_TEE_VERIFIER_ADDRESS"
    echo "  cp env.template .env  # Copy template and edit"
    echo "  $0                    # Run automation"
}

display_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Automation Complete!${NC}"
    echo "========================================"
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "Review the enclave update summary"
    echo ""
    echo -e "${YELLOW}🔗 Option 1: Use the script (recommended)${NC}"
    echo "   - Continue with the script to get the contract owner and update command"
    echo "   - This will show you exactly what to run"
    echo ""
    echo -e "${YELLOW}🔗 Option 2: Manual update via Etherscan/Arbiscan${NC}"
    echo "   - Go to Etherscan/Arbiscan"
    if [ "$TEE_TYPE" = "nitro" ]; then
        echo "   - Navigate to the EspressoNitroTEEVerifier contract"
    else
        echo "   - Navigate to the EspressoSGXVerifier contract"
    fi
    echo "   - Connect with the owner wallet"
    echo "   - Call setEnclaveHash function with:"
    echo "     * enclaveHash: 0x${MRENCLAVE}"
    echo "     * valid: true"
    echo ""
    echo -e "${YELLOW}💡 All data has been saved to files for reference${NC}"
}

# =============================================================================
# MAIN LOGIC
# =============================================================================

full_automation() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}🛡️  TRUSTED EXECUTION ENVIRONMENTS${NC}"
    echo ""
    echo -e "   ${YELLOW}1.${NC}  🔷 Intel SGX"
    echo -e "       └─ Uses existing enclave data (report.txt)"
    echo ""
    echo -e "   ${YELLOW}2.${NC}  ☁️  AWS Nitro Enclaves"
    echo -e "       └─ Generates Image and PCR0 hash via GitHub Actions"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select TEE type (1-2): " -n 1 -r
    echo
    echo ""
    
    case "$REPLY" in
        2)
            TEE_TYPE="nitro"
            ;;
        1|*)
            TEE_TYPE="sgx"
            ;;
    esac
    
    echo -e "${BLUE}🔍 Starting Full Enclave Update Automation${NC}"
    echo "======================================================="
    echo ""    

    case "$REPLY" in
        2)
            echo -e "${BLUE}📋 Step 1/6: AWS Nitro PCR0 Generation${NC}"
            echo "----------------------------------------"
            generate_nitro_pcr0_remote
            echo ""
            ;;
        1|*)
            echo -e "${BLUE}📋 Step 1/6: Processing SGX Enclave Data${NC}"
            echo "----------------------------------------"
            check_report_file
            convert_to_binary
            decode_report_data
            echo ""
            ;;
    esac
    
    echo -e "${BLUE}📋 Step 2/6: Preparing Contract Interaction${NC}"
    echo "----------------------------------------"
    prepare_contract_interaction
    echo ""

    echo -e "${BLUE}📋 Step 3/6: Ready for Contract Update${NC}"
    echo "----------------------------------------"
    display_next_steps
}

main() {
    case "${1:-}" in
        --help|-h)
            show_usage
            ;;
        "")
            full_automation
            prompt_contract_update
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"