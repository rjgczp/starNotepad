#!/usr/bin/env bash
set -euo pipefail

REGISTRY_REPO="${REGISTRY_REPO:-crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles}"
TAG="${1:-latest}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
REGISTRY_HOST="${REGISTRY_HOST:-${REGISTRY_REPO%%/*}}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-${CCR_USERNAME:-}}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-${CCR_PASSWORD:-}}"
PROXY_HTTP_URL="${PROXY_HTTP_URL:-}"
PROXY_HTTPS_URL="${PROXY_HTTPS_URL:-${PROXY_HTTP_URL}}"
PROXY_ALL_URL="${PROXY_ALL_URL:-}"
NO_PROXY="${NO_PROXY:-localhost,127.0.0.1}"

GVA_IMAGE="${REGISTRY_REPO}:gva-server-${TAG}"
ADMIN_IMAGE="${REGISTRY_REPO}:admin-web-${TAG}"
HOME_IMAGE="${REGISTRY_REPO}:home-web-${TAG}"
BLOG_IMAGE="${REGISTRY_REPO}:blog-frontend-${TAG}"
DUO_IMAGE="${REGISTRY_REPO}:duo-call-web-${TAG}"

# 提示：BLUEMAP_IMAGE 已固定，无需每次重复推送
BLUEMAP_IMAGE="${REGISTRY_REPO}:bluemap-jre-25"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
GVA_BUILD_DIR="${ROOT_DIR}/gin-vue-admin/server/.docker"

cleanup() {
  rm -rf "${GVA_BUILD_DIR}"
}
trap cleanup EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found. Please install/start Docker Desktop first."
  exit 1
fi

echo "[1/11] Login to image registry"
if [[ "${SKIP_LOGIN:-0}" == "1" ]]; then
  echo "Skip login enabled (SKIP_LOGIN=1)."
elif [[ -n "${REGISTRY_USERNAME:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  printf '%s' "${REGISTRY_PASSWORD}" | docker login "${REGISTRY_HOST}" --username "${REGISTRY_USERNAME}" --password-stdin
else
  docker login "${REGISTRY_HOST}"
fi

echo "[2/11] Build gva-server:${TAG}"
mkdir -p "${GVA_BUILD_DIR}"
(
  cd "${ROOT_DIR}/gin-vue-admin/server"
  env GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -o "${GVA_BUILD_DIR}/gva-server" .
)
docker build \
  --platform "${BUILD_PLATFORM}" \
  --build-arg HTTP_PROXY="${PROXY_HTTP_URL}" \
  --build-arg HTTPS_PROXY="${PROXY_HTTPS_URL}" \
  --build-arg ALL_PROXY="${PROXY_ALL_URL}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  -t "${GVA_IMAGE}" "${ROOT_DIR}/gin-vue-admin/server"

echo "[3/11] Build admin-web:${TAG}"
docker build \
  --platform "${BUILD_PLATFORM}" \
  --build-arg HTTP_PROXY="${PROXY_HTTP_URL}" \
  --build-arg HTTPS_PROXY="${PROXY_HTTPS_URL}" \
  --build-arg ALL_PROXY="${PROXY_ALL_URL}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  -t "${ADMIN_IMAGE}" "${ROOT_DIR}/gin-vue-admin/web"

echo "[4/11] Build home-web:${TAG}"
docker build \
  --platform "${BUILD_PLATFORM}" \
  --build-arg HTTP_PROXY="${PROXY_HTTP_URL}" \
  --build-arg HTTPS_PROXY="${PROXY_HTTPS_URL}" \
  --build-arg ALL_PROXY="${PROXY_ALL_URL}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  -t "${HOME_IMAGE}" "${ROOT_DIR}/personal-home-next"

echo "[5/11] Build blog-frontend:${TAG}"
docker build \
  --platform "${BUILD_PLATFORM}" \
  --build-arg HTTP_PROXY="${PROXY_HTTP_URL}" \
  --build-arg HTTPS_PROXY="${PROXY_HTTPS_URL}" \
  --build-arg ALL_PROXY="${PROXY_ALL_URL}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  -t "${BLOG_IMAGE}" "${ROOT_DIR}/blog-frontend"

echo "[6/11] Build duo-call-web:${TAG}"
docker build \
  --platform "${BUILD_PLATFORM}" \
  --build-arg HTTP_PROXY="${PROXY_HTTP_URL}" \
  --build-arg HTTPS_PROXY="${PROXY_HTTPS_URL}" \
  --build-arg ALL_PROXY="${PROXY_ALL_URL}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  -t "${DUO_IMAGE}" "${ROOT_DIR}/duo-call-web"

echo "[7/11] Push gva-server:${TAG}"
docker push "${GVA_IMAGE}"

echo "[8/11] Push admin-web:${TAG}"
docker push "${ADMIN_IMAGE}"

echo "[9/11] Push home-web:${TAG}"
docker push "${HOME_IMAGE}"

echo "[10/11] Push blog-frontend:${TAG}"
docker push "${BLOG_IMAGE}"

echo "[11/11] Push duo-call-web:${TAG}"
docker push "${DUO_IMAGE}"

echo
echo "Done."
echo "Use these images in docker-compose.yml or .env.production:"
echo "  GVA_SERVER_IMAGE=${GVA_IMAGE}"
echo "  ADMIN_WEB_IMAGE=${ADMIN_IMAGE}"
echo "  HOME_WEB_IMAGE=${HOME_IMAGE}"
echo "  BLOG_FRONTEND_IMAGE=${BLOG_IMAGE}"
echo "  DUO_CALL_WEB_IMAGE=${DUO_IMAGE}"
echo "  BLUEMAP_IMAGE=${BLUEMAP_IMAGE}"
