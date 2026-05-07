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
BLUEMAP_SOURCE_IMAGE="${BLUEMAP_SOURCE_IMAGE:-eclipse-temurin:25-jre}"
BLUEMAP_IMAGE="${REGISTRY_REPO}:bluemap-jre-25"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found. Please install/start Docker Desktop first."
  exit 1
fi

echo "[1/10] Login to image registry"
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

echo "[2/10] Build gva-server:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${GVA_IMAGE}" "${ROOT_DIR}/gin-vue-admin/server"

echo "[3/10] Build admin-web:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${ADMIN_IMAGE}" "${ROOT_DIR}/gin-vue-admin/web"

echo "[4/10] Build home-web:${TAG}"
docker build --platform "${BUILD_PLATFORM}" -t "${HOME_IMAGE}" "${ROOT_DIR}/personal-home-next"

echo "[5/10] Pull BlueMap JRE base image"
docker pull --platform "${BUILD_PLATFORM}" "${BLUEMAP_SOURCE_IMAGE}"

echo "[6/10] Tag BlueMap JRE image for registry"
docker tag "${BLUEMAP_SOURCE_IMAGE}" "${BLUEMAP_IMAGE}"

echo "[7/10] Push gva-server:${TAG}"
docker push "${GVA_IMAGE}"

echo "[8/10] Push admin-web:${TAG}"
docker push "${ADMIN_IMAGE}"

echo "[9/10] Push home-web:${TAG}"
docker push "${HOME_IMAGE}"

echo "[10/10] Push BlueMap JRE image"
docker push "${BLUEMAP_IMAGE}"

echo
echo "Done."
echo "Use these images in docker-compose.yml or .env.production:"
echo "  GVA_SERVER_IMAGE=${GVA_IMAGE}"
echo "  ADMIN_WEB_IMAGE=${ADMIN_IMAGE}"
echo "  HOME_WEB_IMAGE=${HOME_IMAGE}"
echo "  BLUEMAP_IMAGE=${BLUEMAP_IMAGE}"
