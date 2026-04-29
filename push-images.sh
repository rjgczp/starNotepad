#!/usr/bin/env bash
set -euo pipefail

REGISTRY_REPO="${REGISTRY_REPO:-crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles}"
TAG="${1:-latest}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
REGISTRY_HOST="${REGISTRY_HOST:-${REGISTRY_REPO%%/*}}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-${CCR_USERNAME:-}}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-${CCR_PASSWORD:-}}"
GVA_IMAGE="${REGISTRY_REPO}:gva-server-${TAG}"
ADMIN_IMAGE="${REGISTRY_REPO}:admin-web-${TAG}"
HOME_IMAGE="${REGISTRY_REPO}:home-web-${TAG}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found. Please install/start Docker Desktop first."
  exit 1
fi

echo "[1/7] Login to image registry"
if [[ "${SKIP_LOGIN:-0}" == "1" ]]; then
  echo "Skip login enabled (SKIP_LOGIN=1)."
elif [[ -n "${REGISTRY_USERNAME:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  printf '%s' "${REGISTRY_PASSWORD}" | docker login "${REGISTRY_HOST}" --username "${REGISTRY_USERNAME}" --password-stdin
else
  echo "Tip: Use registry access credential (not cloud console login password)."
  echo "Optional non-interactive mode:"
  echo "  REGISTRY_USERNAME=<your-username> REGISTRY_PASSWORD=<your-password> ./push-images.sh ${TAG}"
  echo "Or skip login when already logged in:"
  echo "  SKIP_LOGIN=1 ./push-images.sh ${TAG}"
  docker login "${REGISTRY_HOST}"
fi

echo "[2/7] Build gva-server:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${GVA_IMAGE}" "${ROOT_DIR}/gin-vue-admin/server"

echo "[3/7] Build admin-web:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${ADMIN_IMAGE}" "${ROOT_DIR}/gin-vue-admin/web"

echo "[4/7] Build home-web:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${HOME_IMAGE}" "${ROOT_DIR}/personal-home-next"

echo "[5/7] Push gva-server:${TAG}"
docker push "${GVA_IMAGE}"

echo "[6/7] Push admin-web:${TAG}"
docker push "${ADMIN_IMAGE}"

echo "[7/7] Push home-web:${TAG}"
docker push "${HOME_IMAGE}"

echo
echo "Done."
echo "If you used a custom tag, update docker-compose.yml image tags accordingly."
