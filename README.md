# Enclave Verification Tools

This folder contains tools for processing MR enclave data and preparing it to update the TEE contract.

## Files

- `automate_enclave_verification.sh` - Main automation script
- `decode_report_data.sh` - Decodes enclave report data
- `README.md` - This file

## Usage

1. Place your `report.txt` file with enclave hash data in this folder
2. Run the automation: `./automate_enclave_verification.sh`
3. The script will generate all necessary files and show contract call parameters

## Generated Files

When you run the automation, this file will be created:
- `enclave_verification_summary.txt` - Complete summary for contract interaction

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Run full automation
./automate_enclave_verification.sh

# Quick verification only
./automate_enclave_verification.sh --quick

# Show help
./automate_enclave_verification.sh --help
``` 