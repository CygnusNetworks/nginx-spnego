#!/usr/bin/env bash
set -euo pipefail

repository_lc=$(printf '%s' "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
username_lc=$(printf '%s' "$DOCKER_USERNAME" | tr '[:upper:]' '[:lower:]')

{
  printf 'GHCR_IMAGE=ghcr.io/%s\n' "$repository_lc"
  printf 'DOCKERHUB_IMAGE=%s/%s\n' "$username_lc" "${repository_lc#*/}"
} >> "$GITHUB_ENV"
