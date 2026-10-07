#!/usr/bin/env bash
set -euo pipefail

build=false
retag_ghcr=false
retag_dockerhub=false

if [[ "${FORCE_BUILD:-false}" == true || \
      -z "${GHCR_LATEST_DIGEST:-}" || \
      -z "${DOCKERHUB_LATEST_DIGEST:-}" || \
      "$GHCR_LATEST_DIGEST" != "$DOCKERHUB_LATEST_DIGEST" || \
      "${PUBLISHED_NGINX_DIGEST:-}" != "$NGINX_DIGEST" || \
      "${PUBLISHED_SPNEGO_COMMIT:-}" != "$SPNEGO_COMMIT" ]]; then
  build=true
else
  [[ "${GHCR_STABLE_DIGEST:-}" == "$GHCR_LATEST_DIGEST" ]] || retag_ghcr=true
  [[ "${DOCKERHUB_STABLE_DIGEST:-}" == "$DOCKERHUB_LATEST_DIGEST" ]] || retag_dockerhub=true
fi

{
  printf 'build=%s\n' "$build"
  printf 'retag_ghcr=%s\n' "$retag_ghcr"
  printf 'retag_dockerhub=%s\n' "$retag_dockerhub"
} >> "$GITHUB_OUTPUT"
