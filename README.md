# MR Enclave Update Tools

This folder contains tools for processing MR enclave data and updating an existing TEE contract with the new enclave hash value.

## What This Does

- **Processes enclave data** from your report.txt file
- **Updates an existing contract** by calling `setEnclaveHash()` function
- **Does NOT deploy contracts** - the contract must already exist
- **Does NOT verify contracts** - this is about updating values

## Files

- `automate_enclave_verification.sh` - Main automation script for updating contract
- `decode_report_data.sh` - Decodes enclave report data
- `env.template` - Environment variables template
- `README.md` - This file

## Setup

1. **Copy the environment template:**
   ```bash
   cp env.template .env
   ```

2. **Edit `.env` file:**
   - Set `TEE_SGX_ADDRESS` to your existing contract address
   - Optionally customize RPC URLs

## Usage

1. Place your `report.txt` file with enclave hash data in this folder
2. Run the automation: `./automate_enclave_verification.sh`
3. The script will process the data and show the contract update command
4. The script will show the contract owner so you know which private key to use

## Options

- **No arguments** - Full automation with contract update setup
- **`--quick`** - Quick parameter display only
- **`--help`** - Show help

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

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Setup environment
cp env.template .env
# Edit .env with your existing contract address

# Run full automation (with contract update setup)
./automate_enclave_verification.sh

# Quick parameter display only
./automate_enclave_verification.sh --quick

# Show help
./automate_enclave_verification.sh --help
```

## Requirements

- `xxd` - For hex-to-binary conversion
- `cast` (optional) - For contract interaction (install Foundry)
- `.env` file - For existing contract address and RPC configuration
- Bitwarden access - For owner private key
- **Existing contract** - The TEE contract must already be deployed