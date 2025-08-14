#!/bin/bash

# MR Enclave Update Automation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

declare MRENCLAVE MRSIGNER RPC_URL NETWORK

if [ -f ".env" ]; then
    echo -e "${BLUE}📋 Loading environment variables from .env file${NC}"
    export $(cat .env | grep -v '^#' | xargs)
    CONTRACT_ADDRESS=${TEE_SGX_ADDRESS:-""}
fi

cleanup() {
    if [ -f "${REPORT_BIN}" ] || [ -f "${REPORT_HEX}" ]; then
        echo -e "${YELLOW}🧹 Cleaning up intermediate files...${NC}"
        rm -f "${REPORT_BIN}" "${REPORT_HEX}"
        echo -e "${GREEN}✅ Intermediate files cleaned up${NC}"
    fi
}

trap cleanup EXIT

# =============================================================================
# EXTRACT ENCLAVE VALUES
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


    echo "Enclaver Image Name: Build Enclaver Docker Image - $enclaver_image_name"

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

    gh repo set-default EspressoSystems/aws-nitro || {
        echo -e "${RED}❌ Failed to set default repository for gh CLI${NC}"
        return 1
    }

    echo -e "${BLUE}🔄 Running GitHub Actions workflow...${NC}"
    local run_log keccak_hash image_name status run_info timestamp
    
    while true; do
        sleep 5
        run_log=$(gh run view "$run_id" --repo EspressoSystems/aws-nitro --log 2>/dev/null || echo "")
        run_info=$(gh run view "$run_id" --repo EspressoSystems/aws-nitro --json status 2>/dev/null || echo "")
        status=$(echo "$run_info" | jq -r '.status')

        if [ "$status" = "completed" ]; then
            echo -e "${GREEN}✅ Workflow completed${NC}"
            
            # Extract PCR0 keccak hash and timestamp from logs
            keccak_hash=$(echo "$run_log" | grep -E 'PCR0 keccak hash: 0x[0-9a-fA-F]+' | tail -n1 | sed -n 's/.*PCR0 keccak hash: \(0x[0-9a-fA-F]*\).*/\1/p')
            timestamp=$(echo "$run_log" | grep -E 'TIMESTAMP:' | tail -n1 | sed -n 's/.*TIMESTAMP: \([0-9]*\).*/\1/p')
            
            if [ -n "$timestamp" ]; then
                image_name="ghcr.io/espressosystems/aws-nitro-poster:${enclaver_image_name}-${timestamp}"
            fi
            
            break
        fi
        if echo "$run_log" | grep -q "Run failed"; then
            echo -e "${RED}❌ Workflow failed${NC}"
            return 1
        fi
    done
    if [ -z "$keccak_hash" ]; then
        echo -e "${RED}❌ Could not extract PCR0 from workflow logs${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ PCR0 keccak captured:${NC} ${keccak_hash}"
    
    if [ -n "$image_name" ]; then
        echo -e "${GREEN}✅ Image name captured:${NC} ${image_name}"
    else
        echo -e "${YELLOW}⚠️  Could not extract image name from workflow logs${NC}"
    fi

    cat > nitro_pcr0_summary.txt << EOF

AWS Nitro PCR0 Summary
===============================

Timestamp: $(date)

Computed:
- PCR0 keccak hash: ${keccak_hash}
$([ -n "$image_name" ] && echo "- Image name: ${image_name}")
EOF

    echo -e "${GREEN}✅ Summary saved to: nitro_pcr0_summary.txt${NC}"
}

# =============================================================================
# CONTRACT INTERACTION
# =============================================================================

prepare_contract_interaction() {
    echo -e "${YELLOW}🔗 Preparing contract update...${NC}"
    
    extract_enclave_values
    
    cat > sgx_enclave_summary.txt << EOF

MR Enclave Summary
===============================

Timestamp: $(date)

Raw Enclave Hash:
$(cat ${REPORT_FILE})

Processed Data:
- MRENCLAVE: ${MRENCLAVE}
- MRSIGNER: ${MRSIGNER}

Contract Update:
- Contract Function: setEnclaveHash (0x93b5552e)
- Parameters:
  * enclaveHash: 0x${MRENCLAVE}
  * valid: true

Next Steps:
1. Go to Etherscan/Arbiscan
2. Navigate to the EspressoSGXVerifier contract
3. Connect with owner key accessible from bitwarden
4. Call setEnclaveHash function with the above parameters
EOF

    echo -e "${GREEN}✅ Summary saved to: sgx_enclave_summary.txt${NC}"
}

get_contract_address() {
    if [ -z "${CONTRACT_ADDRESS}" ]; then
        echo -e "${YELLOW}⚠️  No contract address specified in TEE_SGX_ADDRESS environment variable${NC}"
        echo -e "${YELLOW}💡 Create a .env file from env.template and set TEE_SGX_ADDRESS${NC}"
        read -p "Would you like to specify a contract address now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter contract address: " CONTRACT_ADDRESS
        fi
    fi
    
    if [ -n "${CONTRACT_ADDRESS}" ]; then
        echo -e "${GREEN}✅ Contract address: ${CONTRACT_ADDRESS}${NC}"
        return 0
    else
        echo -e "${YELLOW}💡 No contract address provided, skipping contract setup${NC}"
        return 1
    fi
}

select_network_rpc() {
    echo -e "${BLUE}📋 Available RPC endpoints:${NC}"
    echo "1. Ethereum Mainnet: ${ETHEREUM_MAINNET_RPC}"
    echo "2. Arbitrum Mainnet: ${ARBITRUM_MAINNET_RPC}"
    echo "3. Ethereum Sepolia: ${ETHEREUM_SEPOLIA_RPC}"
    echo "4. Arbitrum Sepolia: ${ARBITRUM_SEPOLIA_RPC}"
    echo "5. Custom RPC"
    
    read -p "Select RPC endpoint (1/2/3/4/5): " -n 1 -r
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

ask_contract_update() {
    echo ""
    echo -e "${YELLOW}🔗 Contract Update Setup${NC}"
    echo "==============================="
    
    if ! get_contract_address; then
        return
    fi
    
    if ! select_network_rpc; then
        return
    fi
    
    run_contract_update
}

get_contract_owner() {
    echo -e "${YELLOW}🔄 Getting contract owner...${NC}"
    echo ""
    
    if cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null; then
        OWNER_ADDRESS=$(cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
        echo -e "${GREEN}✅ Contract owner: ${OWNER_ADDRESS}${NC}"
        echo -e "${YELLOW}💡 Look for this address in Bitwarden to find the private key${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to get contract owner. Check contract address and RPC.${NC}"
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

display_update_command() {
    echo -e "${BLUE}📋 Complete command to update the contract:${NC}"
    echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key YOUR_PRIVATE_KEY"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: Never share your private key and be careful with --private-key flag${NC}"
    echo -e "${YELLOW}💡 Replace YOUR_PRIVATE_KEY with the actual private key${NC}"
}

execute_contract_update() {
    if [ -n "${PRIVATE_KEY}" ]; then
        echo ""
        echo -e "${GREEN}🔑 Private key found in environment${NC}"
        echo -e "${BLUE}📋 Ready to execute:${NC}"
        echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY:0:10}..."
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
            echo -e "${YELLOW}💡 Command execution cancelled. You can run it manually later.${NC}"
        fi
    else
        echo ""
        echo -e "${YELLOW}💡 To execute automatically, set PRIVATE_KEY in your .env file${NC}"
        echo -e "${YELLOW}💡 Or run the command manually with your private key${NC}"
    fi
}

run_contract_update() {
    echo -e "${YELLOW}🚀 Contract Update Command${NC}"
    echo "==============================="
    echo ""
    
    # Extract MRENCLAVE for the call (in case it wasn't set)
    if [ -z "${MRENCLAVE}" ]; then
        MRENCLAVE=$(./decode_report_data.sh | grep "MRENCLAVE:" | cut -d' ' -f2)
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
    execute_contract_update
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
    echo "  TEE_SGX_ADDRESS      - Contract address for update (.env file)"
    echo "  PRIVATE_KEY          - Private key for contract owner (optional, will prompt if not set)"
    echo "  ETHEREUM_MAINNET_RPC - Ethereum mainnet RPC URL"
    echo "  ARBITRUM_MAINNET_RPC - Arbitrum mainnet RPC URL"
    echo "  ETHEREUM_SEPOLIA_RPC - Ethereum Sepolia RPC URL"
    echo "  ARBITRUM_SEPOLIA_RPC - Arbitrum Sepolia RPC URL"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full automation with contract update"
    echo "  $0 --help            # Show help"
    echo ""
    echo "  # With .env file containing TEE_SGX_ADDRESS"
    echo "  cp env.template .env  # Copy template and edit"
    echo "  $0                    # Run automation"
}

display_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Automation Complete!${NC}"
    echo "========================================"
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "Review the enclave verification summary"
    echo ""
    echo -e "${YELLOW}🔗 Option 1: Use the script (recommended)${NC}"
    echo "   - Continue with the script to get the contract owner and update command"
    echo "   - This will show you exactly what to run"
    echo ""
    echo -e "${YELLOW}🔗 Option 2: Manual update via Etherscan/Arbiscan${NC}"
    echo "   - Go to Etherscan/Arbiscan"
    echo "   - Navigate to the EspressoSGXVerifier verifier contract:"
    echo "   - Connect with the owner wallet accessible from Bitwarden"
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
    echo -e "${BLUE}🔍 Starting Full MR Enclave Update Automation${NC}"
    echo "======================================================="
    echo ""    

    echo -e "${BLUE}📋 Step 1/6: Processing Enclave Data${NC}"
    echo "----------------------------------------"
    check_report_file
    convert_to_binary
    decode_report_data
    echo ""
    
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
            echo -e "${BLUE}📋 Choose TEE type:${NC}"
            echo "1) Intel SGX"
            echo "2) AWS Nitro"
            read -p "Select (1/2): " -n 1 -r
            echo
            case "$REPLY" in
                2)
                    # Generate PCR0 via GitHub Action
                    generate_nitro_pcr0_remote
                    ;;
                1|*)
                    full_automation
                    ask_contract_update
                    ;;
            esac
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