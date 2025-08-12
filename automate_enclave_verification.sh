#!/bin/bash

# MR Enclave Verification Automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPORT_FILE="report.txt"
REPORT_BIN="report.bin"
REPORT_HEX="report.hex"

# Function to show usage
show_usage() {
    echo -e "${BLUE}🔍 Enclave Verification Automation${NC}"
    echo "========================================"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (no args)  - Full automation (recommended)"
    echo "  --quick    - Quick verification only"
    echo "  --help     - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full automation"
    echo "  $0 --quick           # Quick check only"
    echo "  $0 --help            # Show help"
}

# Function to check if report file exists
check_report_file() {
    if [ ! -f "${REPORT_FILE}" ]; then
        echo -e "${RED}❌ Report file '${REPORT_FILE}' not found${NC}"
        echo -e "${YELLOW}💡 Please ensure you have a report.txt file with the enclave hash${NC}"
        echo -e "${YELLOW}💡 You can copy the enclave hash from the Batch Poster Docker logs${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found report file: ${REPORT_FILE}${NC}"
    
    # Display the content
    echo -e "${BLUE}📋 Content preview:${NC}"
    head -c 100 "${REPORT_FILE}"
    echo "..."
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

# Function to prepare SGX TEE contract interaction
prepare_contract_interaction() {
    echo -e "${YELLOW}🔗 Preparing contract interaction...${NC}"
    
    # Extract the MRENCLAVE value from the decode output
    MRENCLAVE=$(./decode_report_data.sh | grep "MRENCLAVE:" | cut -d' ' -f2)
    MRSIGNER=$(./decode_report_data.sh | grep "MRSIGNER:" | cut -d' ' -f2)
    
    if [ -z "${MRENCLAVE}" ]; then
        echo -e "${RED}❌ Could not extract MRENCLAVE value${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ MRENCLAVE extracted: ${MRENCLAVE}${NC}"
    echo -e "${GREEN}✅ MRSIGNER extracted: ${MRSIGNER}${NC}"

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

Contract Interaction:
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
    
    # Clean up intermediate files
    echo -e "${YELLOW}🧹 Cleaning up intermediate files...${NC}"
    rm -f "${REPORT_BIN}" "${REPORT_HEX}"
    echo -e "${GREEN}✅ Intermediate files cleaned up${NC}"
}

# Function to display next steps
display_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Automation Complete!${NC}"
    echo "========================================"
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Review the enclave verification summary"
    echo "2. Go to Etherscan/Arbiscan"
    echo "3. Navigate to the TEE verifier contract:"
    echo "   - EspressoSGXVerifier (for SGX infrastructure)"
    echo "4. Connect with the owner wallet accessible from bitwarden"
    echo "5. Call setEnclaveHash function with:"
    echo "   - enclaveHash: 0x${MRENCLAVE}"
    echo "   - valid: true"
    echo ""
    echo -e "${YELLOW}💡 All data has been saved to files for reference${NC}"
}

# Function for quick verification mode
quick_verification() {
    echo -e "${BLUE}⚡ Quick Verification Mode${NC}"
    echo "================================"
    
    if [ -f "${REPORT_FILE}" ] && [ -f "${REPORT_BIN}" ]; then
        if [ -x "./decode_report_data.sh" ]; then
            echo -e "${GREEN}✅ Quick verification results:${NC}"
            echo ""
            ./decode_report_data.sh | grep -E "(MRENCLAVE|MRSIGNER)" | while read line; do
                echo -e "✅ $line"
            done
            echo ""
            echo -e "${BLUE}🔗 Function: setEnclaveHash (0x93b5552e)${NC}"
            echo -e "${BLUE}📋 enclaveHash: 0x$(./decode_report_data.sh | grep "MRENCLAVE:" | cut -d' ' -f2)${NC}"
            echo -e "${BLUE}📋 valid: true${NC}"
        else
            echo -e "${YELLOW}⚠️  decode_report_data.sh not found or not executable${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Required files not found. Run full automation first.${NC}"
        echo -e "${YELLOW}💡 Use: $0 (no arguments) for full processing${NC}"
    fi
}

# Function for full automation
full_automation() {
    echo -e "${BLUE}🔍 Starting Full Enclave Verification Automation${NC}"
    echo "=================================================="
    
    check_report_file
    convert_to_binary
    decode_report_data
    prepare_contract_interaction
    display_next_steps
}

# Main execution logic
main() {
    case "${1:-}" in
        --quick)
            quick_verification
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            full_automation
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