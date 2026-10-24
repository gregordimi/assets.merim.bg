#!/usr/bin/env bash
set -euo pipefail

# Robustly load .env file if present (handles inline comments, quotes, spaces, ~ expansion)
if [[ -f ".env" ]]; then
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Trim leading/trailing whitespace from key
    key="$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # Skip comments or empty lines
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    
    # Strip any inline comment (# preceded by whitespace)
    value="$(echo "$value" | sed -e 's/[[:space:]]#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # Strip quotes if present
    value="${value#[\"\']}"
    value="${value%[\"\']}"
    # Expand tilde ~ to HOME directory
    value="${value/#\~/$HOME}"
    
    export "$key=$value"
  done < .env
fi

# 1. Server host/IP
SERVER="${1:-${SERVER_IP:-}}"

# 2. Server SSH user
SERVER_USER="${SERVER_USER:-}"

# 3. Local Source Directory
LOCAL_DIR="${2:-${LOCAL_ASSETS_DIR:-}}"

# 4. Remote Target Directory
REMOTE_DIR="${3:-${REMOTE_ASSETS_DIR:-/mnt/volume-fsn1-1/assets-cdn/data/}}"

# 5. Optional SSH key path or port
SSH_KEY="${SSH_KEY:-}"
SSH_PORT="${SSH_PORT:-}"

if [[ -z "$SERVER" ]]; then
  echo "Error: Server IP or SSH host is required."
  echo ""
  echo "Usage: $0 <SERVER_IP_OR_HOST> [LOCAL_STORAGE_DIR]"
  echo "Or set SERVER_IP in .env"
  exit 1
fi

# Determine SSH destination:
# - If SERVER contains '@', use as-is
# - If SERVER_USER is set and SERVER doesn't contain '@', use user@server
# - Otherwise, use SERVER directly (ideal for ~/.ssh/config aliases)
if [[ "$SERVER" == *"@"* ]]; then
  SSH_DEST="${SERVER}"
elif [[ -n "${SERVER_USER}" ]]; then
  SSH_DEST="${SERVER_USER}@${SERVER}"
else
  SSH_DEST="${SERVER}"
fi

# Auto-detect local directory if not provided
if [[ -z "$LOCAL_DIR" ]]; then
  if [[ -d "../merim-bg-landing/public/storage" ]]; then
    LOCAL_DIR="../merim-bg-landing/public/storage"
    echo "ℹ️  Using local directory: ${LOCAL_DIR}"
  elif [[ -d "./data" && $(find ./data -type f ! -name ".gitkeep" | wc -l) -gt 0 ]]; then
    LOCAL_DIR="./data"
    echo "ℹ️  Using local ./data directory"
  else
    echo "Error: Could not locate image source directory."
    echo "Please specify the local path in .env as LOCAL_ASSETS_DIR or as 2nd argument:"
    echo "  $0 ${SERVER} /path/to/public/storage/"
    exit 1
  fi
fi

# Ensure trailing slashes
[[ "$LOCAL_DIR" != */ ]] && LOCAL_DIR="${LOCAL_DIR}/"
[[ "$REMOTE_DIR" != */ ]] && REMOTE_DIR="${REMOTE_DIR}/"

# Build SSH options string for rsync
SSH_CMD="ssh"
if [[ -n "$SSH_KEY" ]]; then
  # Expand ~ if not already expanded
  SSH_KEY="${SSH_KEY/#\~/$HOME}"
  SSH_CMD="${SSH_CMD} -i ${SSH_KEY}"
fi
if [[ -n "$SSH_PORT" && "$SSH_PORT" != "22" ]]; then
  SSH_CMD="${SSH_CMD} -p ${SSH_PORT}"
fi

echo "=========================================================="
echo " Source:       ${LOCAL_DIR}"
echo " Destination:  ${SSH_DEST}:${REMOTE_DIR}"
[[ -n "$SSH_KEY" ]] && echo " SSH Key:      ${SSH_KEY}"
[[ -n "$SSH_PORT" && "$SSH_PORT" != "22" ]] && echo " SSH Port:     ${SSH_PORT}"
echo "=========================================================="

echo "===> Ensuring remote directory exists on server..."
${SSH_CMD} "${SSH_DEST}" "mkdir -p ${REMOTE_DIR}"

echo "===> Syncing assets via rsync..."
rsync -avzP -e "${SSH_CMD}" "${LOCAL_DIR}" "${SSH_DEST}:${REMOTE_DIR}"

echo "===> Ensuring proper permissions (755) on remote server..."
${SSH_CMD} "${SSH_DEST}" "chmod -R 755 ${REMOTE_DIR}"

echo "===> Transfer completed successfully!"
