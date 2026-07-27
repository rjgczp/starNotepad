#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env.production}"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/docker-compose.yml}"
CERT_FILE="/home/ubuntu/opt/data/ssl/xiaoyu.ski.pem"
KEY_FILE="/home/ubuntu/opt/data/ssl/xiaoyu.ski.key"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing production environment file: ${ENV_FILE}" >&2
  echo "Copy .env.example to .env.production and fill every required secret." >&2
  exit 1
fi

if [[ ! -r "${CERT_FILE}" || ! -r "${KEY_FILE}" ]]; then
  echo "TLS certificate or key is missing/unreadable:" >&2
  echo "  ${CERT_FILE}" >&2
  echo "  ${KEY_FILE}" >&2
  exit 1
fi

cd "${ROOT_DIR}"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" config --quiet
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --remove-orphans
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
