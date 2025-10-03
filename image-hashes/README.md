# Image Hashes

Extracts enclave hashes from [aws-nitro-poster](https://github.com/EspressoSystems/aws-nitro/pkgs/container/aws-nitro-poster) Docker images on GitHub Container Registry (GHCR).

> **⚠️ Important Disclaimer:**
> - These images are **only for AWS Nitro TEE environments**.
> - Before using any image version, **always check the [nitro-espresso-integration releases](https://github.com/EspressoSystems/nitro-espresso-integration/releases)** to ensure:
>   - The version is properly released (not a pre-release)
>   - The version matches your deployment requirements
>   - The release notes don't indicate any known issues

## What it does

The script fetches all tagged versions of the `aws-nitro-poster` image and extracts the `enclave.hash` label (or parses it from the image description) for each tag, then outputs a Markdown table to `hashes.md`.

## Prerequisites

- `bash` (macOS/Linux)
- `curl`
- `jq` - install via `brew install jq` (macOS) or `apt install jq` (Linux)

## Setup

1. Copy `env.template` to `.env` in the repo root (if not already done):

   ```bash
   cp env.template .env
   ```

2. Edit `.env` and add your GitHub credentials:

   ```bash
   GHCR_USER=your_github_username
   GITHUB_TOKEN=ghp_your_personal_access_token
   ```

   Your PAT needs the `read:packages` scope. Create one at: https://github.com/settings/tokens

## Usage

### Basic

```bash
bash fetch_hashes.sh
```

The script automatically loads credentials from `../.env` if it exists.

### Custom output file

```bash
OUTPUT_FILE="./my-hashes.md" bash fetch_hashes.sh
```

### Debug mode

See labels for each tag:

```bash
DEBUG=1 bash fetch_hashes.sh
```

## Output

The script generates `hashes.md` with a table like:

| Image Tag | Enclave Hash |
|-----------|--------------|
| apechain-espresso-v3.5.6 | 0xf5d8d5f61ae9f2d9e7ee97e020ffdd4f9a07390ba02ead07350eaa120aae9e74 |
| v3.5.6-809e685-apechain | 0x... |

## How it works

1. Fetches all tags from GHCR (up to 500)
2. For each tag:
   - Resolves the manifest (handles multi-arch images)
   - Fetches the config blob
   - Extracts `enclave.hash` from Docker labels
3. Outputs results as a Markdown table

## References

- [nitro-espresso-integration releases](https://github.com/EspressoSystems/nitro-espresso-integration/releases) - **Check here before using any image version**
- [aws-nitro-poster versions](https://github.com/EspressoSystems/aws-nitro/pkgs/container/aws-nitro-poster/versions?filters%5Bversion_type%5D=tagged) - Container registry with all image tags
- Images are tagged via CI with `LABEL enclave.hash="0x..."` and `LABEL org.opencontainers.image.description="...PCR0: 0x..."`