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

select_target_chain() {
    # Reset custom setup flag
    CUSTOM_SETUP=false

    echo ""
    echo -e "${BLUE}🌐 Chain Selection${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    echo -e "${BLUE}🧪 TESTNETS${NC}"
    echo -e "   ${YELLOW}1.${NC}  Rari Testnet"
    echo -e "   ${YELLOW}2.${NC}  LogX Testnet"
    echo -e "   ${YELLOW}3.${NC}  Appchain Testnet"
    echo -e "   ${YELLOW}4.${NC}  T3RN Testnet"
    echo -e "   ${YELLOW}5.${NC}  Apechain Testnet"
    echo -e "   ${YELLOW}6.${NC}  NodeOps Testnet"
    echo -e "${GREEN}📡 MAINNETS${NC}"
    echo -e "   ${YELLOW}7.${NC}  Rari Mainnet"
    echo -e "   ${YELLOW}8.${NC}  LogX Mainnet"
    echo -e "   ${YELLOW}9.${NC}  Appchain Mainnet"
    echo -e "   ${YELLOW}10.${NC} T3RN Mainnet"
    echo -e "   ${YELLOW}11.${NC} Apechain Mainnet"
    echo -e "   ${YELLOW}12.${NC} NodeOps Mainnet"
    echo -e "   ${YELLOW}13.${NC} Molten Mainnet\n"
    echo -e "${PURPLE}🔧 CUSTOM${NC}"
    echo -e "   ${YELLOW}14.${NC}  Custom (Manual EspressoTEEVerifier)\n"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select target chain (1-14): " -r
    echo
    
    case $REPLY in
        1)
            CHAIN_NAME="Rari Testnet"
            SEQUENCER_INBOX_ADDRESS="${RARI_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"  # Rari testnet settles on Arbitrum Sepolia
            NETWORK="Arbitrum Sepolia (Rari Testnet)"
            ;;
        2)
            CHAIN_NAME="LogX Testnet"
            SEQUENCER_INBOX_ADDRESS="${LOGX_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"  # LogX testnet settles on Ethereum Sepolia
            NETWORK="Ethereum Sepolia (LogX Testnet)"
            ;;
        3)
            CHAIN_NAME="Appchain Testnet"
            SEQUENCER_INBOX_ADDRESS="${APPCHAIN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_SEPOLIA_RPC}"  # Appchain testnet settles on Ethereum Sepolia
            NETWORK="Ethereum Sepolia (Appchain Testnet)"
            ;;
        4)
            CHAIN_NAME="T3RN Testnet"
            SEQUENCER_INBOX_ADDRESS="${T3RN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"  # T3RN testnet settles on Arbitrum Sepolia
            NETWORK="Arbitrum Sepolia (T3RN Testnet)"
            ;;
        5)
            CHAIN_NAME="Apechain Testnet"
            SEQUENCER_INBOX_ADDRESS="${APECHAIN_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"  # Apechain testnet settles on Arbitrum Sepolia
            NETWORK="Arbitrum Sepolia (Apechain Testnet)"
            ;;
        6)
            CHAIN_NAME="NodeOps Testnet"
            SEQUENCER_INBOX_ADDRESS="${NODEOPS_TESTNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_SEPOLIA_RPC}"  # NodeOps testnet settles on Arbitrum Sepolia
            NETWORK="Arbitrum Sepolia (NodeOps Testnet)"
            ;;
        7)
            CHAIN_NAME="Rari Mainnet"
            SEQUENCER_INBOX_ADDRESS="${RARI_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"  # Rari mainnet settles on Arbitrum One
            NETWORK="Arbitrum One (Rari Mainnet)"
            ;;
        8)
            CHAIN_NAME="LogX Mainnet"
            SEQUENCER_INBOX_ADDRESS="${LOGX_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_MAINNET_RPC}"  # LogX mainnet settles on Ethereum Mainnet
            NETWORK="Ethereum Mainnet (LogX Mainnet)"
            ;;
        9)
            CHAIN_NAME="Appchain Mainnet"
            SEQUENCER_INBOX_ADDRESS="${APPCHAIN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ETHEREUM_MAINNET_RPC}"  # Appchain mainnet settles on Ethereum Mainnet
            NETWORK="Ethereum Mainnet (Appchain Mainnet)"
            ;;
        10)
            CHAIN_NAME="T3RN Mainnet"
            SEQUENCER_INBOX_ADDRESS="${T3RN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"  # T3RN mainnet settles on Arbitrum One
            NETWORK="Arbitrum One (T3RN Mainnet)"
            ;;
        11)
            CHAIN_NAME="Apechain Mainnet"
            SEQUENCER_INBOX_ADDRESS="${APECHAIN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"  # Apechain mainnet settles on Arbitrum One
            NETWORK="Arbitrum One (Apechain Mainnet)"
            ;;
        12)
            CHAIN_NAME="NodeOps Mainnet"
            SEQUENCER_INBOX_ADDRESS="${NODEOPS_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"  # NodeOps mainnet settles on Arbitrum One
            NETWORK="Arbitrum One (NodeOps Mainnet)"
            ;;
        13)
            CHAIN_NAME="Molten Mainnet"
            SEQUENCER_INBOX_ADDRESS="${MOLTEN_MAINNET_SEQUENCER_INBOX_ADDRESS}"
            RPC_URL="${ARBITRUM_MAINNET_RPC}"  # Molten mainnet settles on Arbitrum One
            NETWORK="Arbitrum One (Molten Mainnet)"
            ;;
        14)
            CHAIN_NAME="Custom Network"
            CUSTOM_SETUP=true
            echo -e "${PURPLE}🔧 Custom Network - Select RPC${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

            # Show available RPC options
            echo -e "${BLUE}🌐 Select Network RPC:${NC}"
            echo -e "   ${YELLOW}1.${NC}  Ethereum Sepolia     (${ETHEREUM_SEPOLIA_RPC:-Not configured})"
            echo -e "   ${YELLOW}2.${NC}  Ethereum Mainnet    (${ETHEREUM_MAINNET_RPC:-Not configured})"
            echo -e "   ${YELLOW}3.${NC}  Arbitrum Sepolia    (${ARBITRUM_SEPOLIA_RPC:-Not configured})"
            echo -e "   ${YELLOW}4.${NC}  Arbitrum Mainnet    (${ARBITRUM_MAINNET_RPC:-Not configured})"
            echo -e "   ${YELLOW}5.${NC} Custom RPC URL\n"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -n "Select network (1-5): "
            read RPC_CHOICE
            echo

            case $RPC_CHOICE in
                1)
                    NETWORK="Ethereum Sepolia (Custom)"
                    RPC_URL="${ETHEREUM_SEPOLIA_RPC}"
                    ;;
                2)
                    NETWORK="Ethereum Mainnet (Custom)"
                    RPC_URL="${ETHEREUM_MAINNET_RPC}"
                    ;;
                3)
                    NETWORK="Arbitrum Sepolia (Custom)"
                    RPC_URL="${ARBITRUM_SEPOLIA_RPC}"
                    ;;
                4)
                    NETWORK="Arbitrum Mainnet (Custom)"
                    RPC_URL="${ARBITRUM_MAINNET_RPC}"
                    ;;
                5)
                    echo -e "${YELLOW}💡 Enter custom RPC URL:${NC}"
                    echo -n "RPC URL: "
                    read CUSTOM_RPC_URL
                    echo
                    if [ -z "$CUSTOM_RPC_URL" ]; then
                        echo -e "${RED}❌ RPC URL cannot be empty${NC}"
                        return 1
                    fi
                    NETWORK="Custom Network"
                    RPC_URL="$CUSTOM_RPC_URL"
                    ;;
                *)
                    echo -e "${RED}❌ Invalid network selection${NC}"
                    return 1
                    ;;
            esac

            if [ -z "$RPC_URL" ]; then
                echo -e "${RED}❌ Selected RPC is not configured. Please check your .env file or choose option 5.${NC}"
                return 1
            fi

            # Prompt for EspressoTEEVerifier address
            echo -e "${YELLOW}💡 Enter the EspressoTEEVerifier contract address:${NC}"
            echo -n "Address (0x...): "
            read MAIN_TEE_VERIFIER_ADDRESS
            echo

            # Validate address format
            if [[ ! "$MAIN_TEE_VERIFIER_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
                echo -e "${RED}❌ Invalid address format. Should be 40 hex characters${NC}"
                return 1
            fi

            ;;
        *)
            echo -e "${YELLOW}⚠️  Invalid selection${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Selected: ${CHAIN_NAME}${NC}"

    if [ "$CUSTOM_SETUP" = true ]; then
        echo -e "${PURPLE}📋 EspressoTEEVerifier: ${MAIN_TEE_VERIFIER_ADDRESS}${NC}"
    else
        echo -e "${BLUE}📋 Sequencer Inbox: ${SEQUENCER_INBOX_ADDRESS}${NC}"
    fi

    echo -e "${BLUE}📋 Network: ${NETWORK}${NC}"
    echo -e "${BLUE}📋 RPC: ${RPC_URL}${NC}"
    return 0
}

get_main_tee_verifier_from_inbox() {
    echo -e "${BLUE}🔍 Getting main TEE verifier address from sequencer inbox...${NC}"
    
    MAIN_TEE_VERIFIER_ADDRESS=$(cast call "${SEQUENCER_INBOX_ADDRESS}" "espressoTEEVerifier()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
    
    if [ -n "${MAIN_TEE_VERIFIER_ADDRESS}" ] && [ "${MAIN_TEE_VERIFIER_ADDRESS}" != "0x" ]; then
        echo -e "${GREEN}✅ Main EspressoTEEVerifier address: ${MAIN_TEE_VERIFIER_ADDRESS}${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to get main TEE verifier address from sequencer inbox${NC}"
        echo -e "${YELLOW}💡 Check if:${NC}"
        echo "   - Sequencer inbox address is correct: ${SEQUENCER_INBOX_ADDRESS}"
        echo "   - RPC endpoint is responding: ${RPC_URL}"
        echo "   - Contract has the espressoTEEVerifier() method"
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
        echo -e
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
# CONTRACT OWNER MANAGEMENT
# =============================================================================

get_contract_owner() {
    if [ "$TEE_TYPE" = "nitro" ]; then
        echo -e "${YELLOW}🔄 Getting AWS Nitro TEE verifier contract owner...${NC}"
    else
        echo -e "${YELLOW}🔄 Getting SGX TEE verifier contract owner...${NC}"
    fi
    echo -e "${BLUE}📋 Checking owner of: ${CONTRACT_ADDRESS}${NC} \n"
    
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
        echo "   - RPC endpoint is invalid or not responding \n"
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
    echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY:0:8}... \n"
    echo -e "${YELLOW}⚠️  This will actually update the contract on ${NETWORK}${NC}"
    read -p "Are you ready to execute this command? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🚀 Executing contract update...${NC} \n"
        if cast send "${CONTRACT_ADDRESS}" "setEnclaveHash(bytes32,bool)" "0x${MRENCLAVE}" true --rpc-url "${RPC_URL}" --private-key "${PRIVATE_KEY}"; then
            echo -e "${GREEN}✅ Contract update successful!${NC}"
            echo -e "${GREEN}🎉 The enclave hash has been updated on ${NETWORK}${NC}"
        else
            echo -e "${RED}❌ Contract update failed${NC}"
            echo -e "${YELLOW}💡 Check the error message above for details${NC}"
        fi
    else
        echo -e "\n${YELLOW}💡 Command execution cancelled${NC}\n"
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
    echo "  - valid: true \n"
    echo ""
    
    # Optional
    echo -e "${BLUE}📋 Step 5/7: Contract Owner Lookup${NC}"
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
    
    echo -e "${BLUE}📋 Step 6/7: Display Update Command${NC}"
    echo "----------------------------------------"
    display_update_command
    echo ""
    
    echo -e "${BLUE}📋 Step 7/7: Execute Contract Update${NC}"
    echo "----------------------------------------"
    send_contract_transaction
}

prompt_contract_update() {

    if ! select_target_chain; then
        return
    fi

    # Skip getting main TEE verifier from inbox if it's a custom setup
    if [ "$CUSTOM_SETUP" != true ]; then
        if ! get_main_tee_verifier_from_inbox; then
            return
        fi
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
export -f select_target_chain
export -f get_main_tee_verifier_from_inbox
export -f get_tee_verifier_address
export -f get_contract_owner
export -f get_private_key
export -f display_update_command
export -f send_contract_transaction
export -f run_contract_update_workflow
export -f prompt_contract_update