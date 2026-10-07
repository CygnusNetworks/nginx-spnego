#!/usr/bin/env bash
set -euo pipefail

build=false
retag_ghcr=false
retag_dockerhub=false

now=${NOW_EPOCH:-$(date -u +%s)}
max_age_days=${MAX_AGE_DAYS:-30}
reason=

if [[ "${FORCE_BUILD:-false}" == true ]]; then
  reason='manual force'
elif [[ -z "${GHCR_LATEST_DIGEST:-}" || -z "${DOCKERHUB_LATEST_DIGEST:-}" ]]; then
  reason='latest tag missing'
elif [[ "$GHCR_LATEST_DIGEST" != "$DOCKERHUB_LATEST_DIGEST" ]]; then
  reason='latest tags differ between registries'
elif [[ "${PUBLISHED_NGINX_DIGEST:-}" != "$NGINX_DIGEST" ]]; then
  reason='NGINX base image changed'
elif [[ "${PUBLISHED_SPNEGO_COMMIT:-}" != "$SPNEGO_COMMIT" ]]; then
  reason='SPNEGO release changed'
elif [[ "${PUBLISHED_BUILD_RECIPE:-}" != "$BUILD_RECIPE" ]]; then
  reason='Dockerfile or build workflow changed'
elif (( now - ${PUBLISHED_CREATED_EPOCH:-0} > max_age_days * 86400 )); then
  reason="published image is older than $max_age_days days"
fi

if [[ -n "$reason" ]]; then
  build=true
  printf 'Rebuild: %s\n' "$reason"
else
  printf 'Published image is up to date\n'
  [[ "${GHCR_STABLE_DIGEST:-}" == "$GHCR_LATEST_DIGEST" ]] || retag_ghcr=true
  [[ "${DOCKERHUB_STABLE_DIGEST:-}" == "$DOCKERHUB_LATEST_DIGEST" ]] || retag_dockerhub=true
fi

{
  printf 'build=%s\n' "$build"
  printf 'retag_ghcr=%s\n' "$retag_ghcr"
  printf 'retag_dockerhub=%s\n' "$retag_dockerhub"
} >> "$GITHUB_OUTPUT"
