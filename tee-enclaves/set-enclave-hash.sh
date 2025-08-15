#!/bin/bash

# MR Enclave Update Automation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/summary_generator.sh"

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

get_contract_address() {
    if [ -n "${MAIN_TEE_VERIFIER_ADDRESS}" ]; then
        echo -e "${BLUE}📋 Main EspressoTEEVerifier address from .env: ${MAIN_TEE_VERIFIER_ADDRESS}${NC}"
        read -p "Use this address? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter main EspressoTEEVerifier contract address: " MAIN_TEE_VERIFIER_ADDRESS
        fi
    else
        echo -e "${YELLOW}⚠️  No main EspressoTEEVerifier contract address specified${NC}"
        echo -e "${YELLOW}💡 Create a .env file from env.template and set MAIN_TEE_VERIFIER_ADDRESS${NC}"
        read -p "Would you like to specify the main EspressoTEEVerifier contract address now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter main EspressoTEEVerifier contract address: " MAIN_TEE_VERIFIER_ADDRESS
        fi
    fi
    
    if [ -n "${MAIN_TEE_VERIFIER_ADDRESS}" ]; then
        echo -e "${GREEN}✅ Main EspressoTEEVerifier address: ${MAIN_TEE_VERIFIER_ADDRESS}${NC}"
        return 0
    else
        echo -e "${YELLOW}💡 No contract address provided, skipping contract setup${NC}"
        return 1
    fi
}

get_tee_verifier_address() {
    if [ "$TEE_TYPE" = "nitro" ]; then
        echo -e "${BLUE}🔍 Getting AWS Nitro TEE verifier address...${NC}"
        CONTRACT_ADDRESS=$(cast call "${MAIN_TEE_VERIFIER_ADDRESS}" "espressoNitroTEEVerifier()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
        echo -e "${GREEN}✅ Nitro TEE Verifier address: ${CONTRACT_ADDRESS}${NC}"
    else
        echo -e "${BLUE}🔍 Getting SGX TEE verifier address...${NC}"
        CONTRACT_ADDRESS=$(cast call "${MAIN_TEE_VERIFIER_ADDRESS}" "espressoSGXTEEVerifier()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
        echo -e "${GREEN}✅ SGX TEE Verifier address: ${CONTRACT_ADDRESS}${NC}"
    fi
    
    if [ -n "${CONTRACT_ADDRESS}" ] && [ "${CONTRACT_ADDRESS}" != "0x" ]; then
        return 0
    else
        if [ "$TEE_TYPE" = "nitro" ]; then
            echo -e "${RED}❌ Failed to get AWS Nitro TEE verifier address${NC}"
        else
            echo -e "${RED}❌ Failed to get SGX TEE verifier address${NC}"
        fi
        return 1
    fi
}

select_network_rpc() {
    echo ""
    echo -e "${BLUE}🌐 Network Selection${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}📡 MAINNETS${NC}"
    echo -e "   ${YELLOW}1.${NC}  Ethereum Mainnet"
    echo -e "       └─ ${ETHEREUM_MAINNET_RPC}"
    echo -e "   ${YELLOW}2.${NC}  Arbitrum Mainnet" 
    echo -e "       └─ ${ARBITRUM_MAINNET_RPC}"
    echo ""
    echo -e "${BLUE}🧪 TESTNETS${NC}"
    echo -e "   ${YELLOW}3.${NC}  Ethereum Sepolia"
    echo -e "       └─ ${ETHEREUM_SEPOLIA_RPC}"
    echo -e "   ${YELLOW}4.${NC}  Arbitrum Sepolia"
    echo -e "       └─ ${ARBITRUM_SEPOLIA_RPC}"
    echo ""
    echo -e "${YELLOW}⚙️  CUSTOM${NC}"
    echo -e "   ${YELLOW}5.${NC}  🛠️  Custom RPC URL"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select network (1-5): " -n 1 -r
    echo ""
    echo
    
    case $REPLY in
        1)
            RPC_URL="${ETHEREUM_MAINNET_RPC}"
            NETWORK="Ethereum Mainnet"
            ;;
        2)
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum Mainnet"
            ;;
        3)
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"
            NETWORK="Ethereum Sepolia"
            ;;
        4)
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia"
            ;;
        5)
            read -p "Enter custom RPC URL: " RPC_URL
            NETWORK="Custom"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Invalid selection, skipping contract setup${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Selected: ${NETWORK} - ${RPC_URL}${NC}"
    return 0
}

prompt_contract_update() {
    echo ""
    echo -e "${YELLOW}🔗 Contract Update Setup${NC}"
    echo "==============================="
    
    if ! get_contract_address; then
        return
    fi
    
    if ! select_network_rpc; then
        return
    fi
    
    if ! get_tee_verifier_address; then
        return
    fi
    
    run_contract_update_workflow
}

get_contract_owner() {
    if [ "$TEE_TYPE" = "nitro" ]; then
        echo -e "${YELLOW}🔄 Getting AWS Nitro TEE verifier contract owner...${NC}"
    else
        echo -e "${YELLOW}🔄 Getting SGX TEE verifier contract owner...${NC}"
    fi
    echo -e "${BLUE}📋 Checking owner of: ${CONTRACT_ADDRESS}${NC}"
    echo ""
    
    if cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null; then
        OWNER_ADDRESS=$(cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
        if [ "$TEE_TYPE" = "nitro" ]; then
            echo -e "${GREEN}✅ AWS Nitro TEE verifier contract owner: ${OWNER_ADDRESS}${NC}"
        else
            echo -e "${GREEN}✅ SGX TEE verifier contract owner: ${OWNER_ADDRESS}${NC}"
        fi
        echo -e "${YELLOW}💡 Find associated private key${NC}"
        return 0
    else
        if [ "$TEE_TYPE" = "nitro" ]; then
            echo -e "${RED}❌ Failed to get AWS Nitro TEE verifier contract owner. Check contract address and RPC.${NC}"
        else
            echo -e "${RED}❌ Failed to get SGX TEE verifier contract owner. Check contract address and RPC.${NC}"
        fi
        echo -e "${YELLOW}💡 Common issues:${NC}"
        echo "   - Contract address is incorrect"
        echo "   - RPC endpoint is invalid or not responding"
        echo ""
        echo -e "${YELLOW}💡 Would you like to install 'cast' (Foundry's command-line tool)?${NC}"
        echo "This is required for contract interaction."
        read -p "Install cast now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}📋 Downloading Foundry...${NC}"
            curl -L https://foundry.paradigm.xyz | bash
            echo -e "${GREEN}✅ Foundry downloaded.${NC}"
            echo -e "${BLUE}📋 Installing Foundry...${NC}"
            foundryup
            echo -e "${GREEN}✅ Foundry installed.${NC}"
            echo -e "${YELLOW}💡 You can now run the script again to get the contract owner.${NC}"
        else
            echo -e "${YELLOW}💡 You can manually install 'cast' later by following the instructions on Foundry's website.${NC}"
        fi
        return 1
    fi
}

get_private_key() {
    if [ -n "${PRIVATE_KEY}" ]; then
        echo -e "${BLUE}Private key found in .env file: ${PRIVATE_KEY:0:8}...${NC}"
        read -p "Use this private key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            echo -e "${YELLOW}💡 Please enter your private key:${NC}"
        fi
    else
        echo -e "${YELLOW}🔑 No private key found in .env file${NC}"
        echo -e "${YELLOW}💡 Please enter your private key for contract execution:${NC}"
    fi
    
    # Prompt for private key hidden input
    echo -n "Private key (0x...): "
    read -s NEW_PRIVATE_KEY
    echo  
    
    if [ -z "$NEW_PRIVATE_KEY" ]; then
        echo -e "${YELLOW}⚠️  No private key provided${NC}"
        return 1
    fi
    
    if [[ ! "$NEW_PRIVATE_KEY" =~ ^0x ]]; then
        NEW_PRIVATE_KEY="0x${NEW_PRIVATE_KEY}"
    fi
    
    if [[ ! "$NEW_PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        echo -e "${RED}❌ Invalid private key format. Should be 64 hex characters${NC}"
        return 1
    fi
    
    PRIVATE_KEY="$NEW_PRIVATE_KEY"
    echo -e "${GREEN}✅ Private key set${NC}"
    return 0
}

display_update_command() {
    echo -e "${BLUE}📋 Complete command to update the contract:${NC}"
    echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key YOUR_PRIVATE_KEY"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: Never share your private key and be careful with --private-key flag${NC}"
    echo -e "${YELLOW}💡 Replace YOUR_PRIVATE_KEY with the actual private key${NC}"
}

send_contract_transaction() {
    echo ""
    echo -e "${YELLOW}🔑 Setting up private key for contract execution...${NC}"
    
    if ! get_private_key; then
        echo ""
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}📋 Ready to execute contract update:${NC}"
    echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY:0:8}..."
    echo ""
    echo -e "${YELLOW}⚠️  This will actually update the contract on ${NETWORK}${NC}"
    read -p "Are you ready to execute this command? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🚀 Executing contract update...${NC}"
        echo ""
        if cast send "${CONTRACT_ADDRESS}" "setEnclaveHash(bytes32,bool)" "0x${MRENCLAVE}" true --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}"; then
            echo -e "${GREEN}✅ Contract update successful!${NC}"
            echo -e "${GREEN}🎉 The enclave hash has been updated on ${NETWORK}${NC}"
        else
            echo -e "${RED}❌ Contract update failed${NC}"
            echo -e "${YELLOW}💡 Check the error message above for details${NC}"
        fi
    else
        echo ""
        echo -e "${YELLOW}💡 Command execution cancelled${NC}"
        echo ""
    fi
}

run_contract_update_workflow() {
    echo -e "${YELLOW}🚀 Contract Update Command${NC}"
    echo "==============================="
    echo ""
    
    if [ -z "${MRENCLAVE}" ]; then
        if [ "$TEE_TYPE" = "sgx" ]; then
            MRENCLAVE=$(./decode_report_data.sh | grep "MRENCLAVE:" | cut -d' ' -f2)
        else
            echo -e "${RED}❌ MRENCLAVE not available for AWS Nitro workflow${NC}"
            echo -e "${YELLOW}💡 This should have been set during PCR0 generation${NC}"
            return 1
        fi
    fi
    
    echo -e "${BLUE}📋 Contract Call Details:${NC}"
    echo "Network: ${NETWORK}"
    echo "Contract: ${CONTRACT_ADDRESS}"
    echo "Function: setEnclaveHash (0x93b5552e)"
    echo "Parameters:"
    echo "  - enclaveHash: 0x${MRENCLAVE}"
    echo "  - valid: true"
    echo ""
    
    # Optional
    echo -e "${BLUE}📋 Step 4/6: Contract Owner Lookup${NC}"
    echo "----------------------------------------"
    read -p "Would you like to get the TEE contract owner address? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        get_contract_owner
        echo ""
    else
        echo -e "${YELLOW}⏭️  Skipping contract owner lookup${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}📋 Step 5/6: Display Update Command${NC}"
    echo "----------------------------------------"
    display_update_command
    echo ""
    
    echo -e "${BLUE}📋 Step 6/6: Execute Contract Update${NC}"
    echo "----------------------------------------"
    send_contract_transaction
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