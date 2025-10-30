# Enclave Hash Contract Update Tool

This folder contains tools for updating TEE verifier contracts with enclave hash values. The tool allows you to register or unregister enclave hashes directly on the blockchain without requiring image generation.

## What This Does

- **Updates TEE verifier contracts** by calling `setEnclaveHash()` function
- **Supports both Intel SGX and AWS Nitro** enclave types
- **Register or unregister hashes** (set valid=true or valid=false)
- **Works with multiple chains** - Ethereum and Arbitrum mainnets and testnets
- **Automatic contract lookup** - Fetches verifier addresses from sequencer inbox contracts
- **Two modes**: Interactive (manual) and Non-interactive (automation)

## Files

- `set-enclave-hash.sh` - **Non-interactive version** for automation and CI/CD
- `set-enclave-hash-interactive.sh` - **Interactive version** for manual use
- `set-enclave-hash-lib.sh` - Shared library with common functions
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
   - Set `PRIVATE_KEY` for automatic execution (optional)
   - Customize RPC URLs if needed (Ethereum Mainnet, Arbitrum Mainnet, Sepolia testnets)

3. **Make scripts executable:**

   ```bash
   chmod +x *.sh
   ```

## Usage - Interactive Mode

Use the **interactive version** when you need to manually confirm each step:

```bash
./set-enclave-hash-interactive.sh
```

The script will prompt you for:

1. **Enclave hash** - Provide the 64-character hex hash (with or without 0x prefix)
2. **TEE type** - Choose Intel SGX or AWS Nitro Enclaves
3. **Target chain** - Choose from testnets and mainnets
4. **Confirmation** - Review details before executing the contract update

### Interactive Mode Examples

```bash
# Run interactive mode
./set-enclave-hash-interactive.sh

# Show help
./set-enclave-hash-interactive.sh --help
```

## Usage - Non-Interactive Mode

Use the **non-interactive version** for automation, CI/CD pipelines, or batch operations:

```bash
./set-enclave-hash.sh [OPTIONS]
```

### Required Arguments

- `-h, --hash HASH` - 64-character hex enclave hash (with or without 0x prefix)
- `-t, --tee-type TYPE` - TEE type: `sgx` or `nitro`
- `-c, --chain CHAIN` - Chain selection number (1-18)

### Optional Arguments

- `-p, --private-key KEY` - Private key for contract execution (0x prefix optional)
- `--auto-execute` - Skip confirmation and execute contract update automatically
- `--valid VALID_FLAG` - Valid flag for the hash: `true` (register) or `false` (unregister), defaults to `true`
- `--custom-rpc RPC_URL` - Custom RPC URL (required for custom chain - 18)
- `--custom-address ADDRESS` - Custom EspressoTEEVerifier address (required for custom chain - 18)
- `--help` - Show help message

### Non-Interactive Mode Examples

```bash
# Display contract details without execution
./set-enclave-hash.sh \
  --hash abcd1234... \
  --tee-type sgx \
  --chain 2

# Register hash with private key (automatic execution)
./set-enclave-hash.sh \
  --hash abcd1234... \
  --tee-type nitro \
  --chain 9 \
  --private-key 0x1234... \
  --auto-execute

# Unregister hash with private key
./set-enclave-hash.sh \
  --hash abcd1234... \
  --tee-type nitro \
  --chain 9 \
  --valid false \
  --private-key 0x1234... \
  --auto-execute

# Custom chain with full parameters
./set-enclave-hash.sh \
  --hash abcd1234... \
  --tee-type nitro \
  --chain 18 \
  --custom-rpc https://rpc.example.com \
  --custom-address 0x1234... \
  --private-key 0x5678... \
  --auto-execute

# Show help
./set-enclave-hash.sh --help
```

## Supported Chains

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
2. **Validate TEE type** - Check for 'sgx' or 'nitro'
3. **Select chain** - Choose from available chains or custom setup
4. **Fetch contract addresses** - Automatically get TEE verifier addresses
5. **Show contract details** - Display the TEE verifier contract address and network
6. **Generate summary** - Create a summary file for your records
7. **Execute transaction** (if enabled) - Execute the contract update

## Generated Files

When you run the tool, summary files will be created in the `summaries/` folder:

- `sgx_YYYYMMDD_HHMMSS.txt` - SGX contract update summary with MRENCLAVE
- `nitro_YYYYMMDD_HHMMSS.txt` - AWS Nitro contract update summary with MRENCLAVE

These summaries contain:

- Timestamp of update
- Enclave hash used
- Contract parameters
- Next steps for manual verification

## Requirements

- **Foundry (cast)** - For blockchain interactions. Install from [getfoundry.sh](https://getfoundry.sh)
- **Bash** - For running the scripts
- **RPC endpoints** - Ethereum/Arbitrum RPC URLs (can be configured in .env or selected at runtime)

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Setup environment (optional - for RPC URLs and private key)
cp ../env.template ../.env
# Edit .env if you want to pre-configure RPC URLs or PRIVATE_KEY

./set-enclave-hash-interactive.sh
./set-enclave-hash.sh --hash 1234abcd... --tee-type sgx --chain 2
```
