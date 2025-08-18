#!/bin/bash

# Configuration file for MR Enclave Update Automation
# This file contains all configuration values and can be sourced by the main script

# File paths
REPORT_FILE="report.txt"
REPORT_BIN="report.bin"
REPORT_HEX="report.hex"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Environment variables (will be loaded from .env)
CONTRACT_ADDRESS=${CONTRACT_ADDRESS:-""}
PRIVATE_KEY=${PRIVATE_KEY:-""}
ETHEREUM_MAINNET_RPC=${ETHEREUM_MAINNET_RPC:-""}
ARBITRUM_MAINNET_RPC=${ARBITRUM_MAINNET_RPC:-""}
ETHEREUM_SEPOLIA_RPC=${ETHEREUM_SEPOLIA_RPC:-""}
ARBITRUM_SEPOLIA_RPC=${ARBITRUM_SEPOLIA_RPC:-""} 