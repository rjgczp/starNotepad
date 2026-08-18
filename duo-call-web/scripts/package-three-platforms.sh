#!/usr/bin/env bash

# Build a release directory containing the web site, Android APK/AAB, and the
# desktop installer for the host operating system. This script intentionally
# never overwrites an existing release directory.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-$(node -p "require('./package.json').version")}"
OUTPUT_DIR="$ROOT_DIR/releases/$VERSION"
STAGING_DIR="$(mktemp -d /tmp/duo-release.XXXXXX)"
trap 'rm -rf "$STAGING_DIR"' EXIT
TAURI_VERSION="$(node -p "require('./src-tauri/tauri.conf.json').version")"
ANDROID_VERSION="$(sed -nE 's/^[[:space:]]*versionName[[:space:]]+"([^"]+)".*/\1/p' android/app/build.gradle | head -n 1)"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.+][0-9A-Za-z.-]+)?$ ]]; then
  echo "版本号必须为语义化版本，例如 0.2.0：$VERSION" >&2
  exit 1
fi

if [[ "$VERSION" != "$TAURI_VERSION" || "$VERSION" != "$ANDROID_VERSION" ]]; then
  echo "版本号不一致：package.json=$VERSION, tauri=$TAURI_VERSION, android=$ANDROID_VERSION" >&2
  echo "请先同步 package.json、src-tauri/tauri.conf.json 和 android/app/build.gradle。" >&2
  exit 1
fi

if [[ -e "$OUTPUT_DIR" ]]; then
  echo "发布目录已存在，为避免覆盖已中止：$OUTPUT_DIR" >&2
  exit 1
fi

if [[ ! -f .env.native ]]; then
  echo "缺少 .env.native；请先执行 cp .env.native.example .env.native 并确认线上 API 地址。" >&2
  exit 1
fi

if [[ ! -f android/keystore.properties ]]; then
  echo "缺少 Android 签名配置 android/keystore.properties。" >&2
  echo "可先复制 android/keystore.properties.example，再填写正式 keystore 信息。" >&2
  exit 1
fi

for command in node npm java cargo; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "缺少构建依赖：$command" >&2
    exit 1
  fi
done

if [[ ! -x node_modules/.bin/tauri ]]; then
  echo "正在安装前端构建依赖…"
  npm ci
fi

echo "[1/5] 运行前端测试"
npm test

echo "[2/5] 构建 Web 静态站点"
npm run build
mkdir -p "$STAGING_DIR/web"
cp -R dist/. "$STAGING_DIR/web/"

echo "[3/5] 同步并构建 Android release APK/AAB"
npm run android:sync
(
  cd android
  ./gradlew assembleRelease bundleRelease
)

APK_PATH="android/app/build/outputs/apk/release/app-release.apk"
AAB_PATH="android/app/build/outputs/bundle/release/app-release.aab"
if [[ ! -f "$APK_PATH" || ! -f "$AAB_PATH" ]]; then
  echo "没有找到已签名的 Android release 包。请检查 android/keystore.properties 与 keystore。" >&2
  exit 1
fi

echo "[4/5] 构建当前系统的桌面安装包"
npm run desktop:build

echo "[5/5] 汇总发布文件"
mkdir -p "$OUTPUT_DIR/web" "$OUTPUT_DIR/android" "$OUTPUT_DIR/desktop"
cp -R "$STAGING_DIR/web/." "$OUTPUT_DIR/web/"
cp "$APK_PATH" "$OUTPUT_DIR/android/情侣小屋_${VERSION}.apk"
cp "$AAB_PATH" "$OUTPUT_DIR/android/情侣小屋_${VERSION}.aab"

desktop_package_found=false
while IFS= read -r -d '' artifact; do
  cp "$artifact" "$OUTPUT_DIR/desktop/"
  desktop_package_found=true
done < <(find src-tauri/target/release/bundle -type f \( -name '*.dmg' -o -name '*.msi' -o -name '*.exe' -o -name '*.AppImage' -o -name '*.deb' -o -name '*.rpm' \) -print0)

if [[ "$desktop_package_found" != true ]]; then
  echo "未找到桌面安装包，请检查 Tauri 构建输出。" >&2
  exit 1
fi

(
  cd "$OUTPUT_DIR"
  while IFS= read -r -d '' artifact; do
    shasum -a 256 "$artifact"
  done < <(find . -type f ! -name 'SHA256SUMS' -print0)
) > "$OUTPUT_DIR/SHA256SUMS"

echo "打包完成：$OUTPUT_DIR"
