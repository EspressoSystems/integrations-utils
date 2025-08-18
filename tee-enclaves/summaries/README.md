# TEE Summaries

This directory contains automatically generated summary files from TEE (Trusted Execution Environment) operations.

## File Types

- **`nitro_*.txt`**: Complete AWS Nitro workflow summaries
- **`sgx_*.txt`**: Complete Intel SGX workflow summaries

## File Naming

Files are automatically timestamped: `YYYYMMDD_HHMMSS`

Examples:

- `nitro_20250814_143052.txt`
- `sgx_20250814_142845.txt`

## Contents

Each summary contains the complete workflow results:

- Generated timestamp and TEE type
- Processing results (PCR0/MRENCLAVE data)
- Contract update parameters ready for use
- Next steps for manual execution

## Cleanup

These files are generated automatically and can be cleaned up periodically if needed.