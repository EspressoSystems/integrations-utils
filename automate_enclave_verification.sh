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
# DATA PROCESSING MODULE
# =============================================================================

# Function to check if report file exists
check_report_file() {
    if [ ! -f "${REPORT_FILE}" ]; then
        echo -e "${RED}❌ Report file '${REPORT_FILE}' not found${NC}"
        echo -e "${YELLOW}💡 Please ensure you have a report.txt file with the enclave hash${NC}"
        echo -e "${YELLOW}💡 You can copy the enclave hash from the Batch Poster Docker logs${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found report file: ${REPORT_FILE}${NC}"
}

# Function to convert hex to binary
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

# Function to decode the report data
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

# Function to extract enclave values
extract_enclave_values() {
    echo -e "${YELLOW}🔍 Extracting enclave values...${NC}"
    
    # Extract the MRENCLAVE value from the decode output
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
# CONTRACT INTERACTION MODULE
# =============================================================================

# Function to prepare SGX TEE contract interaction
prepare_contract_interaction() {
    echo -e "${YELLOW}🔗 Preparing contract update...${NC}"
    
    # Extract enclave values first
    extract_enclave_values
    
    # Create a summary file for easy reference
    cat > enclave_verification_summary.txt << EOF
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

    echo -e "${GREEN}✅ Summary saved to: enclave_verification_summary.txt${NC}"
}

# Function to get contract address from user or environment
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

# Function to select network and RPC endpoint
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

# Function to ask user about contract update
ask_contract_update() {
    echo ""
    echo -e "${YELLOW}🔗 Contract Update Setup${NC}"
    echo "==============================="
    
    # Get contract address first
    if ! get_contract_address; then
        return
    fi
    
    # Select network and RPC endpoint
    if ! select_network_rpc; then
        return
    fi
    
    # Run the contract update function which includes owner check
    run_contract_update
}

# Function to run contract update
run_contract_update() {
    echo -e "${YELLOW}🚀 Contract Update Command${NC}"
    echo "==============================="
    
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
    
    # Ask if they want to get the TEE contract owner address
    read -p "Would you like to get the TEE contract owner address? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔄 Getting contract owner...${NC}"
        echo ""
        
        if cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null; then
            OWNER_ADDRESS=$(cast call "${CONTRACT_ADDRESS}" "owner()" --rpc-url "${RPC_URL}" 2>/dev/null | sed 's/^0x000000000000000000000000/0x/' 2>/dev/null)
            echo -e "${GREEN}✅ Contract owner: ${OWNER_ADDRESS}${NC}"
            echo -e "${YELLOW}💡 Look for this address in Bitwarden to find the private key${NC}"
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
        fi
        echo ""
    fi
    
    # Show the complete command that will work
    echo -e "${BLUE}📋 Complete command to update the contract:${NC}"
    echo "cast send ${CONTRACT_ADDRESS} \"setEnclaveHash(bytes32,bool)\" 0x${MRENCLAVE} true --rpc-url ${RPC_URL} --private-key YOUR_PRIVATE_KEY"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: Never share your private key and be careful with --private-key flag${NC}"
    echo -e "${YELLOW}💡 Replace YOUR_PRIVATE_KEY with the actual private key from Bitwarden${NC}"
    
    # Check if private key is set in environment
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

# =============================================================================
# OUTPUT MODULE
# =============================================================================

# Function to show usage
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

# Function to display next steps
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

# Function for full automation
full_automation() {
    echo -e "${BLUE}🔍 Starting Full MR Enclave Update Automation${NC}"
    echo "======================================================="
    
    # Data Processing Module
    check_report_file
    convert_to_binary
    decode_report_data
    
    # Contract Interaction Module
    prepare_contract_interaction
    
    # User Interface Module
    display_next_steps
}

# Main execution logic
main() {
    case "${1:-}" in
        --help|-h)
            show_usage
            ;;
        "")
            # Clear workflow: Data → Contract → Results
            full_automation
            ask_contract_update
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run the main function
main "$@" 