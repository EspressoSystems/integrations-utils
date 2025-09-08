# MR Enclave Update Automation

This folder contains tools for processing MR enclave data and updating TEE contracts with new enclave hash values. The main script supports multiple workflows including SGX image generation, AWS Nitro PCR0 generation, and direct contract updates.

## Related Repositories

This tool integrates with the following GitHub repositories for automated image building:

- **[EspressoSystems/gsc](https://github.com/EspressoSystems/gsc)** - Gramine Shielded Containers for Intel SGX image generation
- **[EspressoSystems/aws-nitro](https://github.com/EspressoSystems/aws-nitro)** - AWS Nitro Enclaves image generation

## What This Does

- **Processes enclave data** from report.txt files or Docker images
- **Generates SGX images** via GitHub Actions workflows
- **Generates AWS Nitro PCR0 hashes** via GitHub Actions workflows
- **Updates existing contracts** by calling `setEnclaveHash()` function
- **Supports contract-only mode** for direct hash registration/unregistration

## Files

- `set-enclave-hash.sh` - Main automation script with multiple workflow modes
- `config.sh` - Configuration values and environment setup
- `summary_generator.sh` - Summary file generation
- `extract_sgx_hash.sh` - SGX hash extraction from Docker images
- `decode_report_data.sh` - Decodes enclave report data
- `env.template` - Environment variables template
- `README.md` - This file

## Setup

1. **Copy the environment template:**

   ```bash
   cp env.template .env
   ```

2. **Edit `.env` file:**
   - Set `MAIN_TEE_VERIFIER_ADDRESS` to your existing TEE verifier contract address
   - Optionally set `PRIVATE_KEY` for automatic execution
   - Customize RPC URLs if needed (Ethereum Mainnet, Arbitrum Mainnet, Sepolia testnets)

## Usage

The main script supports multiple workflow modes:

### Full Automation Mode (Default)
1. **TEE Type Selection** - Choose between Intel SGX or AWS Nitro Enclaves
2. **SGX Processing Method** - Choose between GitHub workflow or legacy report.txt
3. **Image Generation** - Generate SGX images or extract from existing Docker images
4. **Hash Extraction** - Extract MRENCLAVE/MRSIGNER values
5. **Contract Update** - Update the TEE verifier contract

### Contract-Only Mode
- **Direct Hash Input** - Input a hash directly without image generation
- **Register/Unregister** - Choose to register (valid=true) or unregister (valid=false)
- **Contract Update** - Update the contract with the provided hash

### SGX Docker Mode
- **Docker Image Processing** - Extract MRENCLAVE from existing Docker images
- **Contract Update** - Update the contract with extracted hash

## Options

- **No arguments** - Full automation with image generation and contract update
- **`--contract-only`** - Contract-only mode for direct hash management
- **`--sgx-docker IMAGE`** - SGX automation using Docker image extraction
- **`--help`** - Show help and usage information

## Generated Files

When you run the automation, summary files will be created in the `summaries/` folder:

- `sgx_YYYYMMDD_HHMMSS.txt` - SGX workflow summary with MRENCLAVE/MRSIGNER
- `nitro_YYYYMMDD_HHMMSS.txt` - AWS Nitro workflow summary with PCR0 hash

## Network Options

The script supports 4 networks:

1. **Ethereum Mainnet** - Production Ethereum
2. **Arbitrum Mainnet** - Production Arbitrum
3. **Ethereum Sepolia** - Testnet Ethereum
4. **Arbitrum Sepolia** - Testnet Arbitrum

## Contract Update Process

The script will:

- **Process enclave data** - Extract MRENCLAVE/MRSIGNER values or generate new hashes
- **Show contract details** - Display the TEE verifier contract address and network
- **Display complete command** - Show the exact cast command to update the contract
- **Execute automatically** - If PRIVATE_KEY is set in .env file
- **Support register/unregister** - Choose to register (valid=true) or unregister (valid=false) hashes

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Setup environment
cp env.template .env
# Edit .env with your existing contract address and optionally PRIVATE_KEY

# Run full automation (image generation + contract update)
./set-enclave-hash.sh

# Run contract-only mode (direct hash management)
./set-enclave-hash.sh --contract-only

# Run SGX Docker mode (extract from Docker image)
./set-enclave-hash.sh --sgx-docker myregistry/sgx-app:v1.0

# Show help
./set-enclave-hash.sh --help
