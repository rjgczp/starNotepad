#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.production"
CERT_DIR="/home/ubuntu/opt/data/letsencrypt"
LIVE_DIR="${CERT_DIR}/live/xiaoyu.ski"
TARGET_CERT="/home/ubuntu/opt/data/ssl/xiaoyu.ski.pem"
TARGET_KEY="/home/ubuntu/opt/data/ssl/xiaoyu.ski.key"

# Nothing to do while the deployed certificate is valid for at least 30 days.
if openssl x509 -checkend 2592000 -noout -in "${TARGET_CERT}" >/dev/null 2>&1 &&
  openssl x509 -in "${TARGET_CERT}" -noout -ext subjectAltName 2>/dev/null | grep -q 'DNS:map.xiaoyu.ski'; then
  exit 0
fi

cd "${ROOT_DIR}"
docker compose --env-file "${ENV_FILE}" stop gva-web
restart_nginx() {
  docker compose --env-file "${ENV_FILE}" start gva-web
}
trap restart_nginx EXIT

docker run --rm -p 80:80 \
  -v "${CERT_DIR}:/etc/letsencrypt" \
  certbot/certbot:latest certonly --standalone --non-interactive --agree-tos \
  --register-unsafely-without-email --cert-name xiaoyu.ski --expand \
  -d xiaoyu.ski \
  -d home.xiaoyu.ski \
  -d blog.xiaoyu.ski \
  -d ai.xiaoyu.ski \
  -d ht.xiaoyu.ski \
  -d map.xiaoyu.ski

sudo install -o root -g root -m 0644 "${LIVE_DIR}/fullchain.pem" "${TARGET_CERT}"
sudo install -o root -g root -m 0600 "${LIVE_DIR}/privkey.pem" "${TARGET_KEY}"

trap - EXIT
restart_nginx
