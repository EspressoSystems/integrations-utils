# Integrations Utils

A collection of tools designed to help you work with Espresso integrated chains. This repository is actively maintained and will continue to grow with additional utilities to support integration workflows.

Have a feature request or something not working? We'd love to hear from you — open an issue or share your suggestions!

## Tools

### 📝 [tee-enclaves](./tee-enclaves)

Tools for updating TEE verifier contracts with enclave hashes directly through the CLI. Supports both Intel SGX and AWS Nitro enclaves across multiple Espresso integrated chains.

### ⚡ [tx-load-gen](./tx-load-gen)

A TypeScript-based transaction load generator for stress testing and generating consistent transaction volume on supported Espresso integrated chains.

### 🏗️ [aws-setup](./aws-setup)

Ansible playbook that configures the EC2 instances with the necessary software, services, and directory structure required to host the batch posters inside AWS Nitro TEEs enclaves.

---

For detailed information about each tool, check out the README in its respective folder.
