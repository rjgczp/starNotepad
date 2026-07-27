#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env.production}"
REGISTRY_REPO="crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles"

touch "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

set_value() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  awk -v key="${key}" -v value="${value}" '
    BEGIN { found = 0 }
    index($0, key "=") == 1 {
      if (!found) print key "=" value
      found = 1
      next
    }
    { print }
    END { if (!found) print key "=" value }
  ' "${ENV_FILE}" > "${tmp}"
  mv "${tmp}" "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
}

get_value() {
  local key="$1"
  awk -F= -v key="${key}" 'index($0, key "=") == 1 { sub(/^[^=]*=/, ""); print; exit }' "${ENV_FILE}"
}

set_secret_if_missing() {
  local key="$1"
  local current
  current="$(get_value "${key}")"
  if [[ -z "${current}" || "${current}" == replace_with_random_value ]]; then
    set_value "${key}" "$(openssl rand -hex 32)"
  fi
}

# Preserve the legacy SMTP secret without printing it before config.yaml is replaced.
if [[ -z "$(get_value GVA_EMAIL_SECRET)" && -f "${ROOT_DIR}/gin-vue-admin/server/config.yaml" ]]; then
  legacy_email_secret="$(awk '
    /^email:/ { in_email = 1; next }
    in_email && /^[^[:space:]]/ { exit }
    in_email && /^[[:space:]]+secret:/ {
      sub(/^[[:space:]]*secret:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "${ROOT_DIR}/gin-vue-admin/server/config.yaml")"
  if [[ -n "${legacy_email_secret}" && "${legacy_email_secret}" != \$\{* ]]; then
    set_value GVA_EMAIL_SECRET "${legacy_email_secret}"
  fi
fi

set_value GVA_SERVER_IMAGE "${REGISTRY_REPO}:gva-server-latest"
set_value ADMIN_WEB_IMAGE "${REGISTRY_REPO}:admin-web-latest"
set_value HOME_WEB_IMAGE "${REGISTRY_REPO}:home-web-latest"
set_value BLOG_FRONTEND_IMAGE "${REGISTRY_REPO}:blog-frontend-latest"
set_value DUO_CALL_WEB_IMAGE "${REGISTRY_REPO}:duo-call-web-latest"
set_value BLUEMAP_IMAGE "${REGISTRY_REPO}:bluemap-jre-25"
set_value DUO_TURN_HOST turn.xiaoyu.ski
set_value DUO_TURN_USERNAME duo
set_value TURN_EXTERNAL_IP 82.157.105.7
set_value NODE_ENV production

set_secret_if_missing GVA_JWT_SIGNING_KEY
set_secret_if_missing DUO_CALL_JWT_SECRET
set_secret_if_missing DUO_CALL_KEY_ENCRYPTION_KEY
set_secret_if_missing DUO_TURN_PASSWORD

echo "Production environment is ready (secret values were not printed)."
