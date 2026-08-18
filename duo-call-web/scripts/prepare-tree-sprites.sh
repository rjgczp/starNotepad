#!/usr/bin/env bash

# Convert the hand-painted sprite sheet into a transparent sheet while
# preserving white highlights inside the artwork. The flood fill only removes
# white pixels connected to the image edge; it does not erase heart highlights
# or flower petals.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PATH="${1:-$ROOT_DIR/src/assets/tree-sprites/love-growth-sprites.png}"
TEMP_PATH="$(mktemp "${TMPDIR:-/tmp}/love-growth-sprites.XXXXXX.png")"

cleanup() {
  rm -f "$TEMP_PATH"
}
trap cleanup EXIT

if ! command -v magick >/dev/null 2>&1; then
  echo "需要 ImageMagick 7（magick）来处理树素材。" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_PATH" ]]; then
  echo "找不到树素材：$SOURCE_PATH" >&2
  exit 1
fi

magick "$SOURCE_PATH" \
  -bordercolor white \
  -border 1 \
  -alpha on \
  -fuzz 8% \
  -fill none \
  -draw 'alpha 0,0 floodfill' \
  -shave 1x1 \
  "$TEMP_PATH"

mv "$TEMP_PATH" "$SOURCE_PATH"
echo "已生成透明树素材：$SOURCE_PATH"
