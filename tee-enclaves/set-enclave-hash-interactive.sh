#!/bin/bash

# Enclave Hash Contract Update Tool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/summary-generator.sh"
source "${SCRIPT_DIR}/contract-interaction.sh"
source "${SCRIPT_DIR}/set-enclave-hash-lib.sh"

declare MRENCLAVE RPC_URL NETWORK

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
PRIVATE_KEY=${PRIVATE_KEY:-""}

# =============================================================================
# OUTPUTS
# =============================================================================

show_usage() {
    echo -e "${BLUE}🔍 Enclave Hash Contract Update Tool${NC}"
    echo "============================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (no args)           - Update contract with enclave hash"
    echo "  --help              - Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  PRIVATE_KEY          - Private key for contract owner (optional, will prompt for confirmation/input)"
    echo "  ETHEREUM_MAINNET_RPC - Ethereum mainnet RPC URL"
    echo "  ARBITRUM_MAINNET_RPC - Arbitrum mainnet RPC URL"
    echo "  ETHEREUM_SEPOLIA_RPC - Ethereum Sepolia RPC URL"
    echo "  ARBITRUM_SEPOLIA_RPC - Arbitrum Sepolia RPC URL"
    echo ""
    echo "Note: The script automatically fetches TEE verifier contract addresses from sequencer inbox contracts."
    echo "No need to manually specify contract addresses - just provide RPC URLs for the target networks."
    echo ""
    echo "Examples:"
    echo "  $0                 # Register/unregister enclave hash"
    echo "  $0 --help          # Show help"
    echo ""
    echo "  # With .env file containing RPC URLs"
    echo "  cp env.template .env  # Copy template and edit"
    echo "  $0                    # Run tool"
    echo ""
    echo "What this tool does:"
    echo "  • Input an enclave hash directly (64-character hex string)"
    echo "  • Choose to register (valid=true) or unregister (valid=false)"
    echo "  • Select TEE type (Intel SGX or AWS Nitro)"
    echo "  • Update the TEE verifier contract on your selected chain"
}

# =============================================================================
# HASH INPUT AND CONTRACT UPDATE
# =============================================================================

update_contract_with_hash() {
    echo -e "${BLUE}🔍 Enclave Hash Contract Update${NC}"
    echo "======================================================="
    echo ""
    
    echo -e "${YELLOW}📝 Please enter the enclave hash you want to register/unregister${NC}"
    echo -e "${YELLOW}💡 This should be a 64-character hex string (with or without 0x prefix)${NC}"
    echo ""
    
    read -p "Enter enclave hash: " input_hash
    
    if ! validate_enclave_hash "$input_hash"; then
        exit 1
    fi
    
    echo -e "${GREEN}✅ Hash validated: ${MRENCLAVE}${NC}"
    echo ""
    
    echo -e "${BLUE}📋 TEE Type Selection${NC}"
    echo "----------------------------------------"
    echo -e "${YELLOW}🛡️  Select the TEE type for this hash:${NC}"
    echo -e "   ${YELLOW}1.${NC}  🔷 Intel SGX"
    echo -e "   ${YELLOW}2.${NC}  ☁️  AWS Nitro Enclaves"
    echo ""
    read -p "Select TEE type (1-2): " -n 1 -r
    echo
    echo ""
    
    case "$REPLY" in
        2)
            TEE_TYPE="nitro"
            echo -e "${GREEN}✅ Selected: AWS Nitro Enclaves${NC}"
            ;;
        1|*)
            TEE_TYPE="sgx"
            echo -e "${GREEN}✅ Selected: Intel SGX${NC}"
            ;;
    esac
    echo ""
    
    echo -e "${BLUE}📋 Contract Update Setup${NC}"
    echo "----------------------------------------"
    prompt_contract_update
    
    echo ""
    echo -e "${BLUE}📋 Generate Summary${NC}"
    echo "----------------------------------------"
    generate_summary
}

main() {
    case "${1:-}" in
        --help|-h)
            show_usage
            ;;
        "")
            update_contract_with_hash
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