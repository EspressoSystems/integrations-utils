#!/bin/bash

# Enclave Hash Contract Update Tool - Shared Library
# Contains common functions, validation, and setup logic

set -e

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_enclave_hash() {
    local hash="$1"
    
    if [ -z "$hash" ]; then
        echo -e "${RED}❌ Enclave hash cannot be empty${NC}"
        return 1
    fi
    
    # Remove 0x prefix if present
    hash="${hash#0x}"
    
    if [[ ! "$hash" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo -e "${RED}❌ Invalid hash format. Must be 64 hex characters${NC}"
        echo -e "${YELLOW}💡 Provided: $hash (${#hash} characters)${NC}"
        return 1
    fi
    
    MRENCLAVE="$hash"
    return 0
}

validate_tee_type() {
    local tee_type="$1"
    
    if [ -z "$tee_type" ]; then
        echo -e "${RED}❌ TEE type cannot be empty${NC}"
        echo -e "${YELLOW}💡 Valid options: 'sgx' or 'nitro'${NC}"
        return 1
    fi
    
    tee_type=$(echo "$tee_type" | tr '[:upper:]' '[:lower:]')
    
    if [[ ! "$tee_type" =~ ^(sgx|nitro)$ ]]; then
        echo -e "${RED}❌ Invalid TEE type: $tee_type${NC}"
        echo -e "${YELLOW}💡 Valid options: 'sgx' or 'nitro'${NC}"
        return 1
    fi
    
    TEE_TYPE="$tee_type"
    return 0
}

validate_chain_selection() {
    local chain="$1"
    
    if [ -z "$chain" ]; then
        echo -e "${RED}❌ Chain selection cannot be empty${NC}"
        return 1
    fi
    
    if ! [[ "$chain" =~ ^[0-9]+$ ]] || [ "$chain" -lt 1 ] || [ "$chain" -gt 18 ]; then
        echo -e "${RED}❌ Invalid chain selection: $chain${NC}"
        echo -e "${YELLOW}💡 Valid options: 1-18${NC}"
        return 1
    fi
    
    CHAIN_SELECTION="$chain"
    return 0
}

validate_private_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        return 0  # Private key is optional for non-execution modes
    fi
    
    # Add 0x prefix if not present
    if [[ ! "$key" =~ ^0x ]]; then
        key="0x${key}"
    fi
    
    if [[ ! "$key" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        echo -e "${RED}❌ Invalid private key format. Should be 64 hex characters${NC}"
        return 1
    fi
    
    PRIVATE_KEY="$key"
    return 0
}

# =============================================================================
# CHAIN SETUP
# =============================================================================

setup_chain_non_interactive() {
    CUSTOM_SETUP=false
    
    case $CHAIN_SELECTION in
        1)
            CHAIN_NAME="Rari Testnet"
            SEQUENCER_INBOX_ADDRESS="${RARI_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (Rari Testnet)"
            ;;
        2)
            CHAIN_NAME="LogX Testnet"
            SEQUENCER_INBOX_ADDRESS="${LOGX_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"
            NETWORK="Ethereum Sepolia (LogX Testnet)"
            ;;
        3)
            CHAIN_NAME="Appchain Testnet"
            SEQUENCER_INBOX_ADDRESS="${APPCHAIN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"
            NETWORK="Ethereum Sepolia (Appchain Testnet)"
            ;;
        4)
            CHAIN_NAME="T3RN Testnet"
            SEQUENCER_INBOX_ADDRESS="${T3RN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (T3RN Testnet)"
            ;;
        5)
            CHAIN_NAME="Apechain Testnet"
            SEQUENCER_INBOX_ADDRESS="${APECHAIN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (Apechain Testnet)"
            ;;
        6)
            CHAIN_NAME="NodeOps Testnet"
            SEQUENCER_INBOX_ADDRESS="${NODEOPS_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (NodeOps Testnet)"
            ;;
        7)
            CHAIN_NAME="Huddle01 Testnet"
            SEQUENCER_INBOX_ADDRESS="${HUDDLE01_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (Huddle01 Testnet)"
            ;;
        8)
            CHAIN_NAME="Rufus Testnet"
            SEQUENCER_INBOX_ADDRESS="${RUFUS_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"
            NETWORK="Arbitrum Sepolia (Rufus Testnet)"
            ;;
        9)
            CHAIN_NAME="Rari Mainnet"
            SEQUENCER_INBOX_ADDRESS="${RARI_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (Rari Mainnet)"
            ;;
        10)
            CHAIN_NAME="LogX Mainnet"
            SEQUENCER_INBOX_ADDRESS="${LOGX_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_MAINNET_RPC}"
            NETWORK="Ethereum Mainnet (LogX Mainnet)"
            ;;
        11)
            CHAIN_NAME="Appchain Mainnet"
            SEQUENCER_INBOX_ADDRESS="${APPCHAIN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_MAINNET_RPC}"
            NETWORK="Ethereum Mainnet (Appchain Mainnet)"
            ;;
        12)
            CHAIN_NAME="T3RN Mainnet"
            SEQUENCER_INBOX_ADDRESS="${T3RN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (T3RN Mainnet)"
            ;;
        13)
            CHAIN_NAME="Apechain Mainnet"
            SEQUENCER_INBOX_ADDRESS="${APECHAIN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (Apechain Mainnet)"
            ;;
        14)
            CHAIN_NAME="NodeOps Mainnet"
            SEQUENCER_INBOX_ADDRESS="${NODEOPS_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (NodeOps Mainnet)"
            ;;
        15)
            CHAIN_NAME="Huddle01 Mainnet"
            SEQUENCER_INBOX_ADDRESS="${HUDDLE01_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (Huddle01 Mainnet)"
            ;;
        16)
            CHAIN_NAME="Rufus Mainnet"
            SEQUENCER_INBOX_ADDRESS="${RUFUS_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_MAINNET_RPC}"
            NETWORK="Ethereum Mainnet (Rufus Mainnet)"
            ;;
        17)
            CHAIN_NAME="Molten Mainnet"
            SEQUENCER_INBOX_ADDRESS="${MOLTEN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"
            NETWORK="Arbitrum One (Molten Mainnet)"
            ;;
        18)
            CHAIN_NAME="Custom Network"
            CUSTOM_SETUP=true
            
            if [ -z "$CUSTOM_RPC_URL" ]; then
                echo -e "${RED}❌ Custom RPC URL required for chain 18${NC}"
                echo -e "${YELLOW}💡 Use: --custom-rpc <URL>${NC}"
                return 1
            fi
            
            if [ -z "$MAIN_TEE_VERIFIER_ADDRESS" ]; then
                echo -e "${RED}❌ Custom EspressoTEEVerifier address required for chain 18${NC}"
                echo -e "${YELLOW}💡 Use: --custom-address <0x...>${NC}"
                return 1
            fi
            
            if [[ ! "$MAIN_TEE_VERIFIER_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
                echo -e "${RED}❌ Invalid address format. Should be 40 hex characters${NC}"
                return 1
            fi
            
            NETWORK="Custom Network"
            RPC_URL="$CUSTOM_RPC_URL"
            ;;
        *)
            echo -e "${RED}❌ Invalid chain selection${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Selected: ${CHAIN_NAME}${NC}"
    echo -e "${BLUE}📋 Network: ${NETWORK}${NC}"
    echo -e "${BLUE}📋 RPC: ${RPC_URL}${NC}"
    
    if [ "$CUSTOM_SETUP" != true ]; then
        echo -e "${BLUE}📋 Sequencer Inbox: ${SEQUENCER_INBOX_ADDRESS}${NC}"
    else
        echo -e "${PURPLE}📋 EspressoTEEVerifier: ${MAIN_TEE_VERIFIER_ADDRESS}${NC}"
    fi
    
    return 0
}

# =============================================================================
# SUMMARY GENERATION
# =============================================================================

generate_summary() {
    echo -e "${YELLOW}📄 Generating summary files...${NC}"
    
    local network="${NETWORK:-Not specified}"
    local contract="${CONTRACT_ADDRESS:-Not specified}"
    local valid="${VALID_FLAG:-true}"
    local status="${EXECUTION_STATUS:-Not executed}"
    
    if [ "$TEE_TYPE" = "sgx" ]; then
        echo -e "${GREEN}✅ SGX enclave hash: ${MRENCLAVE}${NC}"
        
        local summary_file=$(generate_sgx_summary "$MRENCLAVE" "" "" "" "" "$network" "$contract" "$valid" "$status")
        echo -e "${GREEN}✅ Summary saved to ${summary_file}${NC}"
    else
        echo -e "${GREEN}✅ AWS Nitro enclave hash: ${MRENCLAVE}${NC}"
        
        local summary_file=$(generate_nitro_summary "" "" "$MRENCLAVE" "" "$MRENCLAVE" "$network" "$contract" "$valid" "$status")
        echo -e "${GREEN}✅ Summary saved to ${summary_file}${NC}"
    fi
}

# =============================================================================
# CONTRACT EXECUTION (COMMON)
# =============================================================================

display_contract_details() {
    echo ""
    echo -e "${BLUE}📋 Contract Call Details:${NC}"
    echo "Network: ${NETWORK}"
    echo "Contract: ${CONTRACT_ADDRESS}"
    echo "Function: setEnclaveHash (0x93b5552e)"
    echo "Parameters:"
    echo "  - enclaveHash: 0x${MRENCLAVE}"
    echo "  - valid: true"
    echo ""
}

display_execution_command() {
    local valid_flag="${VALID_FLAG:-true}"
    
    echo ""
    echo -e "${BLUE}📋 Command to execute the update:${NC}"
    if [ -n "$PRIVATE_KEY" ]; then
        echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} ${valid_flag} --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY:0:8}..."
    else
        echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} ${valid_flag} --rpc-url ${RPC_URL} --private-key <YOUR_PRIVATE_KEY>"
        echo -e "${YELLOW}⚠️  Private key required. Use --private-key to provide it${NC}"
    fi
    echo -e "${YELLOW}⚠️  WARNING: Never share your private key${NC}"
}

execute_contract_update() {
    local valid="${1:-true}"  # Default to true if not specified
    
    echo ""
    echo -e "${YELLOW}🚀 Executing contract update...${NC}"
    echo -e "${YELLOW}⚠️  This will update the contract on ${NETWORK}${NC}"
    echo -e "${YELLOW}📋 Setting valid=${valid}${NC}"
    echo ""
    
    if cast send "${CONTRACT_ADDRESS}" "setEnclaveHash(bytes32,bool)" "0x${MRENCLAVE}" "$valid" --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}"; then
        echo ""
        echo -e "${GREEN}✅ Contract update successful!${NC}"
        echo -e "${GREEN}🎉 The enclave hash has been updated on ${NETWORK}${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Contract update failed${NC}"
        echo -e "${YELLOW}💡 Check the error message above for details${NC}"
        return 1
    fi
}

# Export all functions
export -f validate_enclave_hash
export -f validate_tee_type
export -f validate_chain_selection
export -f validate_private_key
export -f setup_chain_non_interactive
export -f generate_summary
export -f display_contract_details
export -f display_execution_command
export -f execute_contract_update
