#!/bin/bash

# Contract Interaction Module
# Handles all smart contract operations for TEE verifier updates

set -e

# Source config if not already loaded
if [ -z "${SCRIPT_DIR}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/config.sh"
fi

# =============================================================================
# CONTRACT ADDRESS MANAGEMENT
# =============================================================================

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

# =============================================================================
# NETWORK SELECTION
# =============================================================================

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

# =============================================================================
# CONTRACT OWNER MANAGEMENT
# =============================================================================

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

# =============================================================================
# PRIVATE KEY MANAGEMENT
# =============================================================================

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

# =============================================================================
# CONTRACT EXECUTION
# =============================================================================

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

# =============================================================================
# MAIN WORKFLOW
# =============================================================================

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

# =============================================================================
# EXPORTS FOR MAIN SCRIPT
# =============================================================================

# Export functions that may be called from the main script
export -f get_contract_address
export -f get_tee_verifier_address
export -f select_network_rpc
export -f get_contract_owner
export -f get_private_key
export -f display_update_command
export -f send_contract_transaction
export -f run_contract_update_workflow
export -f prompt_contract_update