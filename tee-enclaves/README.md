# Enclave Hash Contract Update Tool

This folder contains tools for updating TEE verifier contracts with enclave hash values. The tool allows you to register or unregister enclave hashes directly on the blockchain without requiring image generation.

## Special Branches

### 4-CPU AWS Nitro Images (`4-cpu` branch)

For building AWS Nitro Enclaves images optimized for 4 CPU cores:

```bash
# Checkout to the 4-cpu branch
git checkout 4-cpu

# Run the automation - this will trigger the aws-nitro workflow with 4cpu configuration
./set-enclave-hash.sh
```

**Key differences in the 4-cpu branch:**
- Uses the `4cpu` ref when triggering the aws-nitro workflow
- Generated images include `-4cpu` suffix for easy identification

## What This Does

- **Updates TEE verifier contracts** by calling `setEnclaveHash()` function
- **Supports both Intel SGX and AWS Nitro** enclave types
- **Register or unregister hashes** (set valid=true or valid=false)
- **Works with multiple chains** - Ethereum and Arbitrum mainnets and testnets
- **Automatic contract lookup** - Fetches verifier addresses from sequencer inbox contracts

## Files

- `set-enclave-hash.sh` - Main script for contract updates
- `contract-interaction.sh` - Contract interaction logic
- `config.sh` - Configuration values and environment setup
- `summary-generator.sh` - Summary file generation for tracking updates
- `env.template` - Environment variables template (in parent directory)
- `README.md` - This file

## Setup

1. **Copy the environment template:**

   ```bash
   cp ../env.template ../.env
   ```

2. **Edit `.env` file:**
   - Optionally set `PRIVATE_KEY` for automatic execution
   - Customize RPC URLs if needed (Ethereum Mainnet, Arbitrum Mainnet, Sepolia testnets)

## Usage

The script is simple and straightforward:

1. **Run the script** - No arguments needed
2. **Input your enclave hash** - Provide the 64-character hex hash (with or without 0x prefix)
3. **Select TEE type** - Choose Intel SGX or AWS Nitro Enclaves
4. **Select target chain** - Choose from testnets and mainnets
5. **Execute contract update** - Script will guide you through the transaction

## Options

- **No arguments** - Default mode: update contract with enclave hash
- **`--help`** - Show help and usage information

## Generated Files

When you run the tool, summary files will be created in the `summaries/` folder:

- `sgx_YYYYMMDD_HHMMSS.txt` - SGX contract update summary with MRENCLAVE
- `nitro_YYYYMMDD_HHMMSS.txt` - AWS Nitro contract update summary with MRENCLAVE

These summaries contain:

- Timestamp of update
- Enclave hash used
- Contract parameters
- Next steps for manual verification

## Supported Chains

The script supports multiple testnets and mainnets:

**Testnets:**

1. Rari Testnet
2. LogX Testnet
3. Appchain Testnet
4. T3RN Testnet
5. Apechain Testnet
6. NodeOps Testnet
7. Huddle01 Testnet
8. Rufus Testnet

**Mainnets:**
9. Rari Mainnet
10. LogX Mainnet
11. Appchain Mainnet
12. T3RN Mainnet
13. Apechain Mainnet
14. NodeOps Mainnet
15. Huddle01 Mainnet
16. Rufus Mainnet
17. Molten Mainnet

**Custom:**
18. Custom Network (Manual EspressoTEEVerifier setup)

## Contract Update Process

The script will:

1. **Validate hash input** - Ensures the hash is 64 hex characters
2. **Select TEE type** - Choose Intel SGX or AWS Nitro
3. **Select chain** - Choose from available chains or custom setup
4. **Fetch contract addresses** - Automatically get TEE verifier addresses
5. **Show contract details** - Display the TEE verifier contract address and network
6. **Display command** - Show the exact cast command to update the contract
7. **Execute transaction** - If PRIVATE_KEY is set, execute the update
8. **Generate summary** - Create a summary file for your records

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Setup environment (optional - for RPC URLs and private key)
cp ../env.template ../.env
# Edit .env if you want to pre-configure RPC URLs or PRIVATE_KEY

# Run the tool
./set-enclave-hash.sh

# Show help
./set-enclave-hash.sh --help
```

## Requirements

- **Foundry (cast)** - For blockchain interactions. Install from [getfoundry.sh](https://getfoundry.sh)
- **Bash** - For running the scripts
- **RPC endpoints** - Ethereum/Arbitrum RPC URLs (can be configured in .env or selected at runtime)

## Example Workflow

```bash
$ ./set-enclave-hash.sh

# You'll be prompted to:
# 1. Enter your enclave hash (64 hex characters)
# 2. Select TEE type (SGX or Nitro)
# 3. Choose your target chain
# 4. Confirm the transaction details
# 5. Execute the contract update

# A summary file will be created in summaries/ for your records
```
