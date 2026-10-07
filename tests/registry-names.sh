#!/usr/bin/env bash
set -euo pipefail

output=$(mktemp)
trap 'rm -f "$output"' EXIT

GITHUB_ENV="$output" GITHUB_REPOSITORY=CygnusNetworks/nginx-spnego DOCKER_USERNAME=CygnusNetworks \
  bash scripts/registry-names.sh

expected=$'GHCR_IMAGE=ghcr.io/cygnusnetworks/nginx-spnego\nDOCKERHUB_IMAGE=cygnusnetworks/nginx-spnego\nDOCKERHUB_REF=docker.io/cygnusnetworks/nginx-spnego'
if [[ "$(<"$output")" != "$expected" ]]; then
  printf 'FAIL: registry image names are not lowercase\nExpected:\n%s\nActual:\n%s\n' "$expected" "$(<"$output")" >&2
  exit 1
fi
printf 'PASS: registry image names are lowercase\n'
