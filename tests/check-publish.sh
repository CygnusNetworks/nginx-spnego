#!/usr/bin/env bash
set -euo pipefail

output=$(mktemp)
trap 'rm -f "$output"' EXIT

check() {
  local name=$1 expected=$2
  shift 2
  : > "$output"
  env GITHUB_OUTPUT="$output" "$@" bash scripts/check-publish.sh > /dev/null
  if [[ "$(<"$output")" != "$expected" ]]; then
    printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$name" "$expected" "$(<"$output")" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$name"
}

common=(
  NGINX_DIGEST=sha256:new
  SPNEGO_COMMIT=new-release
  GHCR_LATEST_DIGEST=sha256:published
  DOCKERHUB_LATEST_DIGEST=sha256:published
  PUBLISHED_NGINX_DIGEST=sha256:new
  PUBLISHED_SPNEGO_COMMIT=new-release
  GHCR_STABLE_DIGEST=sha256:published
  DOCKERHUB_STABLE_DIGEST=sha256:published
  BUILD_RECIPE=recipe
  PUBLISHED_BUILD_RECIPE=recipe
  NOW_EPOCH=1800000000
  PUBLISHED_CREATED_EPOCH=1799000000
)

check 'unchanged upstream and complete tags skip publishing' \
  $'build=false\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}"

check 'changed NGINX digest rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_NGINX_DIGEST=sha256:old

check 'new SPNEGO release rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_SPNEGO_COMMIT=old-release

check 'changed Dockerfile or workflow rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_BUILD_RECIPE=old-recipe

check 'image older than 30 days rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_CREATED_EPOCH=1797000000

check 'missing creation date rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" PUBLISHED_CREATED_EPOCH=

check 'missing stable tag is copied without rebuilding' \
  $'build=false\nretag_ghcr=true\nretag_dockerhub=false' \
  "${common[@]}" GHCR_STABLE_DIGEST=

check 'stale stable tag is corrected without rebuilding' \
  $'build=false\nretag_ghcr=false\nretag_dockerhub=true' \
  "${common[@]}" DOCKERHUB_STABLE_DIGEST=sha256:old

check 'missing latest tag rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" GHCR_LATEST_DIGEST=

check 'different latest digests rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" DOCKERHUB_LATEST_DIGEST=sha256:different

check 'manual force rebuilds' \
  $'build=true\nretag_ghcr=false\nretag_dockerhub=false' \
  "${common[@]}" FORCE_BUILD=true
