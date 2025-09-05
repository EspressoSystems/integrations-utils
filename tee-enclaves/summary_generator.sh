#!/bin/bash

# =============================================================================
# TEE SUMMARY GENERATOR
# =============================================================================

SUMMARY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_summaries_dir() {
    mkdir -p "${SUMMARY_SCRIPT_DIR}/summaries"
}

get_summary_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

generate_nitro_summary() {
    local run_id="$1"
    local enclaver_image_name="$2"
    local keccak_hash="$3"
    local image_name="$4"
    local mrenclave="$5"
    
    local summary_timestamp=$(get_summary_timestamp)
    local nitro_summary="${SUMMARY_SCRIPT_DIR}/summaries/nitro_${summary_timestamp}.txt"
    
    cat > "${nitro_summary}" << EOF
AWS Nitro TEE Summary
===============================

Generated: $(date)
TEE Type: AWS Nitro
Run ID: ${run_id}
Image Name: ${enclaver_image_name}

PCR0 Generation Results:
- PCR0 keccak hash: ${keccak_hash}$([ -n "$image_name" ] && echo "
- Docker image: ${image_name}")
- MRENCLAVE: ${mrenclave}

Use the generated docker image in the Nitro Box: ${image_name}

Contract Update Parameters:
- Contract Function: setEnclaveHash (0x93b5552e)
- enclaveHash: 0x${mrenclave}
- valid: true

Workflow Details:
- Repository: EspressoSystems/aws-nitro
- Run ID: ${run_id}

Next Steps:
1. Go to Etherscan/Arbiscan
2. Navigate to the EspressoNitroTEEVerifier contract
3. Connect with owner wallet
4. Call setEnclaveHash function with the above parameters
EOF

    echo "summaries/nitro_${summary_timestamp}.txt"
}

generate_sgx_summary() {
    local mrenclave="$1"
    local mrsigner="$2"
    local report_file="$3"
    local base_image="$4"
    local gsc_image="$5"
    
    local summary_timestamp=$(get_summary_timestamp)
    local sgx_summary="${SUMMARY_SCRIPT_DIR}/summaries/sgx_${summary_timestamp}.txt"
    
    cat > "${sgx_summary}" << EOF
Intel SGX TEE Summary
===============================

Generated: $(date)
TEE Type: Intel SGX

$(if [ -n "${base_image}" ] && [ -n "${gsc_image}" ]; then
echo "GSC Workflow Process:"
echo "- Nitro Image: ${base_image}"
echo "- GSC Image: ${gsc_image}"
echo "- Method: GitHub Actions workflow (EspressoSystems/gsc)"
echo ""
elif [ -n "${report_file}" ] && [ -f "${report_file}" ]; then
echo "Legacy Method (report.txt):"
cat "${report_file}"
echo ""
else
echo "Method: Unknown/Direct extraction"
echo ""
fi)
Processed Data:
- MRENCLAVE: ${mrenclave}
$(if [ -n "${mrsigner}" ]; then echo "- MRSIGNER: ${mrsigner}"; else echo "- MRSIGNER: (not available from GSC method)"; fi)

Contract Update Parameters:
- Contract Function: setEnclaveHash (0x93b5552e)
- enclaveHash: 0x${mrenclave}
- valid: true

Next Steps:
1. Go to Etherscan/Arbiscan
2. Navigate to the EspressoSGXVerifier contract
3. Connect with owner wallet
4. Call setEnclaveHash function with the above parameters
EOF

    echo "summaries/sgx_${summary_timestamp}.txt"
}