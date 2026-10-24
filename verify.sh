#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://assets.merim.bg}"

echo "=========================================================="
echo " Testing Merim CDN at: ${BASE_URL}"
echo "=========================================================="

TEST_PATHS=(
  "/healthz"
  "/stores/merim-favicon.png"
  "/stores/0ba9ce3e-2572-5b7c-8357-61f8928779b0_favicon.png"
  "/product_sample_images_new/1001_001_small.png"
  "/product_sample_images_new/1008_101.png"
  "/ribi/lavrak.png"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

for path in "${TEST_PATHS[@]}"; do
  url="${BASE_URL}${path}"
  echo -e "\n${BLUE}--> Testing:${NC} ${url}"
  
  RESPONSE=$(curl -sI -o - "${url}" || true)
  HTTP_STATUS=$(echo "$RESPONSE" | grep -E '^HTTP/' | head -n1 | awk '{print $2}')
  CORS_HEADER=$(echo "$RESPONSE" | grep -i '^access-control-allow-origin:' | head -n1 || true)
  CACHE_HEADER=$(echo "$RESPONSE" | grep -i '^cache-control:' | head -n1 || true)

  if [[ "$HTTP_STATUS" == "200" ]]; then
    echo -e "    Status:  ${GREEN}${HTTP_STATUS} OK${NC}"
  else
    echo -e "    Status:  ${RED}${HTTP_STATUS:-FAILED / UNREACHABLE}${NC}"
  fi

  if [[ -n "$CORS_HEADER" ]]; then
    echo -e "    CORS:    ${GREEN}${CORS_HEADER}${NC}"
  else
    echo -e "    CORS:    ${YELLOW}(None)${NC}"
  fi

  if [[ -n "$CACHE_HEADER" ]]; then
    echo -e "    Cache:   ${GREEN}${CACHE_HEADER}${NC}"
  fi
done

echo -e "\n=========================================================="
echo " Verification checks complete."
echo "=========================================================="
