#!/usr/bin/env bash
set -euo pipefail

# Load .env file if present
if [[ -f ".env" ]]; then
  # export non-comment lines
  export $(grep -v '^#' .env | xargs -0 2>/dev/null || true)
fi

# 1. Server IP / Host: argument $1 > SERVER_IP env variable
SERVER="${1:-${SERVER_IP:-}}"

# 2. Local Source Directory: argument $2 > LOCAL_ASSETS_DIR env variable > auto-detect
LOCAL_DIR="${2:-${LOCAL_ASSETS_DIR:-}}"

# 3. Remote Target Directory: argument $3 > REMOTE_ASSETS_DIR env variable > default
REMOTE_DIR="${3:-${REMOTE_ASSETS_DIR:-/mnt/volume-fsn1-1/assets.merim.bg/data/}}"

# Validate server
if [[ -z "$SERVER" ]]; then
  echo "Error: Server IP is required."
  echo ""
  echo "Usage:"
  echo "  $0 <SERVER_IP> [LOCAL_STORAGE_DIR]"
  echo ""
  echo "Or set SERVER_IP in a .env file:"
  echo "  SERVER_IP=123.45.67.89"
  echo "  LOCAL_ASSETS_DIR=/path/to/merim-bg-landing/public/storage"
  exit 1
fi

# Auto-detect local directory if still not set
if [[ -z "$LOCAL_DIR" ]]; then
  if [[ -d "../merim-bg-landing/public/storage" ]]; then
    LOCAL_DIR="../merim-bg-landing/public/storage"
    echo "ℹ️  Auto-detected local directory: ${LOCAL_DIR}"
  elif [[ -d "./data" && $(find ./data -type f ! -name ".gitkeep" | wc -l) -gt 0 ]]; then
    LOCAL_DIR="./data"
    echo "ℹ️  Using local ./data directory"
  else
    echo "Error: Could not locate image source directory."
    echo "Please provide it as the 2nd argument:"
    echo "  $0 ${SERVER} /path/to/public/storage/"
    exit 1
  fi
fi

# Ensure trailing slashes for rsync
[[ "$LOCAL_DIR" != */ ]] && LOCAL_DIR="${LOCAL_DIR}/"
[[ "$REMOTE_DIR" != */ ]] && REMOTE_DIR="${REMOTE_DIR}/"

REMOTE_TARGET="root@${SERVER}:${REMOTE_DIR}"

echo "=========================================================="
echo " Source:  ${LOCAL_DIR}"
echo " Target:  ${REMOTE_TARGET}"
echo "=========================================================="

echo "===> Syncing assets..."
rsync -avzP "${LOCAL_DIR}" "${REMOTE_TARGET}"

echo "===> Ensuring proper permissions (755) on remote server..."
ssh "root@${SERVER}" "chmod -R 755 ${REMOTE_DIR}"

echo "===> Transfer completed successfully!"
