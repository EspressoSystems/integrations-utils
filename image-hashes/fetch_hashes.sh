#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH="espressosystems/aws-nitro-poster"
REG_BASE="https://ghcr.io/v2/${IMAGE_PATH}"

# Get Bearer token using PAT if provided, otherwise anonymous.
get_token() {
  local token=""
  if [[ -n "${GHCR_USER:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    token="$(curl -sSL -u "${GHCR_USER}:${GITHUB_TOKEN}" \
      "https://ghcr.io/token?service=ghcr.io&scope=repository:${IMAGE_PATH}:pull" \
      | jq -r '.token // empty')"
  fi
  if [[ -z "$token" ]]; then
    token="$(curl -sSL "https://ghcr.io/token?service=ghcr.io&scope=repository:${IMAGE_PATH}:pull" \
      | jq -r '.token // empty')"
  fi
  echo "$token"
}

TOKEN="$(get_token)"
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "Failed to obtain GHCR token. Set GHCR_USER and GITHUB_TOKEN (PAT with read:packages) if needed." >&2
  exit 1
fi
AUTH_HDR="Authorization: Bearer ${TOKEN}"

get_manifest_json() {
  local ref="$1"
  curl -sSL -H "$AUTH_HDR" \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json' \
    "${REG_BASE}/manifests/${ref}"
}

# Resolve multi-arch index to a single manifest (prefer linux/amd64).
get_manifest_resolved() {
  local ref="$1" manifest
  manifest="$(get_manifest_json "$ref")"
  if jq -e '.manifests' >/dev/null 2>&1 <<<"$manifest"; then
    local digest
    digest="$(jq -r '(.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest), .manifests[0].digest | select(.!=null)' <<<"$manifest" | head -n1)"
    get_manifest_json "$digest"
  else
    echo "$manifest"
  fi
}

get_config_json() {
  local ref="$1" manifest cfg_digest
  manifest="$(get_manifest_resolved "$ref")"
  cfg_digest="$(jq -r '.config.digest' <<<"$manifest")"
  curl -sSL -H "$AUTH_HDR" \
    -H 'Accept: application/vnd.oci.image.config.v1+json, application/vnd.docker.container.image.v1+json' \
    "${REG_BASE}/blobs/${cfg_digest}"
}

# Extract enclave hash from config labels.
get_hash_for_tag() {
  local tag="$1" cfg label_hash desc
  cfg="$(get_config_json "$tag")"

  [[ "${DEBUG:-0}" = "1" ]] && { echo "== $tag ==" >&2; jq -c '.config.Labels // {}' <<<"$cfg" >&2; }

  label_hash="$(jq -r '.config.Labels["enclave.hash"] // empty' <<<"$cfg")"
  if [[ -n "$label_hash" && "$label_hash" != "null" ]]; then
    echo "$label_hash"
    return 0
  fi

  desc="$(jq -r '.config.Labels["org.opencontainers.image.description"] // empty' <<<"$cfg")"
  if [[ -n "$desc" && "$desc" != "null" ]]; then
    echo "$desc" | grep -Eo '0x[0-9a-fA-F]{64}' || true
    return 0
  fi

  echo ""
}

tags_json="$(curl -sSL -H "$AUTH_HDR" "${REG_BASE}/tags/list?n=500")"
if ! jq -e '.tags' >/dev/null 2>&1 <<<"$tags_json"; then
  echo "Failed to list tags from GHCR." >&2
  exit 1
fi

results_tmp="$(mktemp)"
trap 'rm -f "$results_tmp"' EXIT

jq -r '.tags[]' <<<"$tags_json" | while IFS= read -r tag; do
  [[ -z "$tag" ]] && continue
  hash="$(get_hash_for_tag "$tag" || true)"
  [[ -n "$hash" ]] && printf "%s\t%s\n" "$tag" "$hash" >>"$results_tmp"
done

if [[ ! -s "$results_tmp" ]]; then
  echo "No images with enclave hashes found."
  exit 0
fi

OUTPUT_FILE="${OUTPUT_FILE:-./hashes.md}"
{
  printf "| Image Tag | Enclave Hash |\n"
  printf "|-----------|-------------|\n"
  sort -t $'\t' -k1,1 "$results_tmp" | awk -F'\t' '{printf "| %s | %s |\n", $1, $2}'
} > "$OUTPUT_FILE"

echo "✓ Saved $(wc -l < "$OUTPUT_FILE" | tr -d ' ') entries to: $OUTPUT_FILE"