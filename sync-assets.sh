#!/usr/bin/env bash
set -euo pipefail

# Helper script to sync local static assets to the Hetzner CDN volume.
#
# Usage:
#   ./sync-assets.sh <SERVER_IP_OR_HOSTNAME> [LOCAL_STORAGE_DIR]
#
# Examples:
#   ./sync-assets.sh 123.45.67.89
#   ./sync-assets.sh 123.45.67.89 ../merim-bg-landing/public/storage/

SERVER="${1:-}"
LOCAL_DIR="${2:-}"

if [[ -z "$SERVER" ]]; then
  echo "Error: Server IP or hostname is required."
  echo "Usage: $0 <SERVER_IP_OR_HOSTNAME> [LOCAL_STORAGE_DIR]"
  exit 1
fi

# Detect local directory if not provided
if [[ -z "$LOCAL_DIR" ]]; then
  if [[ -d "../merim-bg-landing/public/storage" ]]; then
    LOCAL_DIR="../merim-bg-landing/public/storage/"
  elif [[ -d "./data" ]]; then
    LOCAL_DIR="./data/"
  else
    echo "Error: Could not locate local storage directory."
    echo "Please specify path to public/storage/: $0 <SERVER_IP> /path/to/public/storage/"
    exit 1
  fi
fi

# Ensure trailing slash for rsync source
[[ "$LOCAL_DIR" != */ ]] && LOCAL_DIR="${LOCAL_DIR}/"

REMOTE_TARGET="root@${SERVER}:/mnt/volume-fsn1-1/assets-cdn/data/"

echo "===> Syncing assets from '${LOCAL_DIR}' to '${REMOTE_TARGET}'..."
rsync -avzP "${LOCAL_DIR}" "${REMOTE_TARGET}"

echo "===> Ensuring proper permissions (755) on remote server..."
ssh "root@${SERVER}" "chmod -R 755 /mnt/volume-fsn1-1/assets-cdn/data"

echo "===> Transfer completed successfully!"
