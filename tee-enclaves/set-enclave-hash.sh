#!/bin/bash

# Enclave Hash Contract Update Tool - Non-Interactive Version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/summary-generator.sh"
source "${SCRIPT_DIR}/contract-interaction.sh"
source "${SCRIPT_DIR}/set-enclave-hash-lib.sh"

declare MRENCLAVE RPC_URL NETWORK

# =============================================================================
# NON-INTERACTIVE MODE VARIABLES
# =============================================================================

ENCLAVE_HASH=""
TEE_TYPE=""
CHAIN_SELECTION=""
PRIVATE_KEY_ARG=""
AUTO_EXECUTE=false
VALID_FLAG="true"

# =============================================================================
# HELP AND USAGE
# =============================================================================

show_help() {
    echo -e "${BLUE}🔍 Enclave Hash Contract Update Tool - Non-Interactive Mode${NC}"
    echo "==========================================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Required Arguments:"
    echo "  -h, --hash HASH              64-character hex enclave hash (with or without 0x prefix)"
    echo "  -t, --tee-type TYPE          TEE type: 'sgx' or 'nitro'"
    echo "  -c, --chain CHAIN            Chain selection number (1-18)"
    echo "    Testnets:  1=Rari, 2=LogX, 3=Appchain, 4=T3RN, 5=Apechain,"
    echo "               6=NodeOps, 7=Huddle01, 8=Rufus"
    echo "    Mainnets:  9=Rari, 10=LogX, 11=Appchain, 12=T3RN, 13=Apechain,"
    echo "               14=NodeOps, 15=Huddle01, 16=Rufus, 17=Molten"
    echo "    Custom:    18=Custom Network"
    echo ""
    echo "Optional Arguments:"
    echo "  -p, --private-key KEY        Private key for contract execution (0x prefix optional)"
    echo "  --auto-execute               Skip confirmation and execute contract update automatically"
    echo "  --custom-rpc RPC_URL         Custom RPC URL (required if chain=18 and custom RPC selected)"
    echo "  --custom-address ADDRESS     Custom EspressoTEEVerifier address (required for chain=18)"
    echo "  --valid VALID_FLAG           Valid flag for contract update (true or false)"
    echo "  --help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Non-interactive mode - display only"
    echo "  $0 --hash abcd1234... --tee-type sgx --chain 2"
    echo ""
    echo "  # Non-interactive with auto-execution"
    echo "  $0 --hash abcd1234... --tee-type nitro --chain 9 --private-key 0x1234... --auto-execute"
    echo ""
    echo "  # Non-interactive with custom chain"
    echo "  $0 --hash abcd1234... --tee-type nitro --chain 18 \\"
    echo "     --custom-rpc https://rpc.example.com \\"
    echo "     --custom-address 0x1234... --private-key 0x5678... --auto-execute"
    echo ""
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--hash)
                ENCLAVE_HASH="$2"
                shift 2
                ;;
            -t|--tee-type)
                TEE_TYPE="$2"
                shift 2
                ;;
            -c|--chain)
                CHAIN_SELECTION="$2"
                shift 2
                ;;
            -p|--private-key)
                PRIVATE_KEY_ARG="$2"
                shift 2
                ;;
            --auto-execute)
                AUTO_EXECUTE=true
                shift
                ;;
            --custom-rpc)
                CUSTOM_RPC_URL="$2"
                shift 2
                ;;
            --custom-address)
                MAIN_TEE_VERIFIER_ADDRESS="$2"
                shift 2
                ;;
            --valid)
                VALID_FLAG="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# EXECUTION FUNCTIONS
# =============================================================================

execute_non_interactive() {
    echo ""
    echo -e "${BLUE}🚀 Contract Update - Non-Interactive Mode${NC}"
    echo "======================================================="
    echo ""
    
    # Skip chain setup if already done
    if [ -z "$CHAIN_NAME" ]; then
        if ! setup_chain_non_interactive; then
            return 1
        fi
    fi
    
    # Get main TEE verifier from inbox if not custom setup
    if [ "$CUSTOM_SETUP" != true ]; then
        if ! get_main_tee_verifier_from_inbox; then
            return 1
        fi
    fi
    
    if ! get_tee_verifier_address; then
        return 1
    fi
    
    # Display contract details
    display_contract_details
    
    # Generate summary without prompts
    echo -e "${YELLOW}📄 Generating summary files...${NC}"
    
    # Execute contract update if private key provided and auto-execute enabled
    if [ -n "$PRIVATE_KEY" ] && [ "$AUTO_EXECUTE" = true ]; then
        export EXECUTION_STATUS="Successfully executed"
        generate_summary
        if ! execute_contract_update "$VALID_FLAG"; then
            return 1
        fi
    else
        export EXECUTION_STATUS="Not executed - command displayed for manual execution"
        generate_summary
        display_execution_command
    fi
    
    return 0
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Load environment variables from repo root
    ENV_FILE="${SCRIPT_DIR}/../.env"
    if [ -f "${ENV_FILE}" ]; then
        echo -e "${BLUE}📋 Loading environment variables from: ${ENV_FILE}${NC}"
        set -a
        source "${ENV_FILE}"
        set +a
        echo -e "${GREEN}✅ Environment variables loaded${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No .env file found at: ${ENV_FILE}${NC}"
        echo -e "${YELLOW}💡 Some configuration may need to be provided via arguments${NC}"
        echo ""
    fi
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate all required arguments
    if ! validate_enclave_hash "$ENCLAVE_HASH"; then
        exit 1
    fi
    
    if ! validate_tee_type "$TEE_TYPE"; then
        exit 1
    fi
    
    if ! validate_chain_selection "$CHAIN_SELECTION"; then
        exit 1
    fi
    
    if [ -n "$PRIVATE_KEY_ARG" ]; then
        if ! validate_private_key "$PRIVATE_KEY_ARG"; then
            exit 1
        fi
    fi
    
    if ! execute_non_interactive; then
        exit 1
    fi
}

main "$@"
