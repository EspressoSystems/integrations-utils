# MR Enclave Update Tools

This folder contains tools for processing MR enclave data and updating an existing TEE contract with the new enclave hash value.

## What This Does

- **Processes enclave data** from your report.txt file
- **Updates an existing contract** by calling `setEnclaveHash()` function
- **Does NOT deploy contracts** - the contract must already exist
- **Does NOT verify contracts** - this is about updating values

## Files

- `automate_enclave_verification.sh` - Main automation script with 6-step workflow
- `decode_report_data.sh` - Decodes enclave report data
- `config.sh` - Configuration values
- `env.template` - Environment variables template
- `README.md` - This file

## Setup

1. **Copy the environment template:**
   ```bash
   cp env.template .env
   ```

2. **Edit `.env` file:**
   - Set `TEE_SGX_ADDRESS` to your existing contract address
   - Optionally set `PRIVATE_KEY` for automatic execution
   - Customize RPC URLs if needed

## Usage

1. Place your `report.txt` file with enclave hash data in this folder
2. Run the automation: `./automate_enclave_verification.sh`
3. Follow the 6-step workflow to update your contract

## 6-Step Workflow

1. **Processing Enclave Data** - Validate and decode report.txt
2. **Preparing Contract Interaction** - Extract MRENCLAVE/MRSIGNER values
3. **Ready for Contract Update** - Display next steps
4. **Contract Setup & RPC Selection** - Configure network and contract
5. **Contract Owner Lookup** - Get owner address (optional)
6. **Execute Contract Update** - Run the update command

## Options

- **No arguments** - Full automation with 6-step workflow
- **`--help`** - Show help and usage information

## Generated Files

When you run the automation, this file will be created:
- `enclave_verification_summary.txt` - Complete summary for contract update

## Network Options

The script supports 4 networks:
1. **Ethereum Mainnet** - Production Ethereum
2. **Arbitrum Mainnet** - Production Arbitrum
3. **Ethereum Sepolia** - Testnet Ethereum
4. **Arbitrum Sepolia** - Testnet Arbitrum

## Contract Update Process

The script will:
- **Process enclave data** - Extract MRENCLAVE and MRSIGNER values
- **Show contract owner** - Display the owner address from the existing contract
- **Display complete command** - Show the exact cast command to update the contract
- **Execute automatically** - If PRIVATE_KEY is set in .env file

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Setup environment
cp env.template .env
# Edit .env with your existing contract address and optionally PRIVATE_KEY

# Run full automation (6-step workflow)
./automate_enclave_verification.sh

# Show help
./automate_enclave_verification.sh --help
```

## Requirements

- `xxd` - For hex-to-binary conversion
- `cast` (optional) - For contract interaction (install Foundry)
- `.env` file - For existing contract address and RPC configuration
- Bitwarden access - For owner private key
- **Existing contract** - The TEE contract must already be deployed