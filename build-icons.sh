#!/usr/bin/env bash
# Clones icon source repos, extracts SVGs, and generates css/file-icons.css
# from the vscode-great-icons icons.json mapping.
#
# Usage: bash build-icons.sh
#
# Sources:
#   - vscode-great-icons (MIT)  — primary icons + mapping
#   - vscode-material-icon-theme (MIT) — fallback for missing SVGs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/icons"
CSS_OUT="$SCRIPT_DIR/css/file-icons.css"
TMP_DIR="${TMPDIR:-/tmp}/forgejo-icons-$$"

GREAT_REPO="https://github.com/EmmanuelBeziat/vscode-great-icons.git"
MATERIAL_REPO="https://github.com/material-extensions/vscode-material-icon-theme.git"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Cloning icon repos..."
mkdir -p "$TMP_DIR"
git clone --depth 1 "$GREAT_REPO" "$TMP_DIR/great" 2>&1 | tail -1
git clone --depth 1 "$MATERIAL_REPO" "$TMP_DIR/material" 2>&1 | tail -1

GREAT_ICONS="$TMP_DIR/great/icons"
GREAT_JSON="$TMP_DIR/great/icons.json"
MATERIAL_ICONS="$TMP_DIR/material/icons"

echo "==> Generating icons and CSS..."
mkdir -p "$ICONS_DIR"

# Let Python do the heavy lifting: parse icons.json, copy SVGs, generate CSS
python "$SCRIPT_DIR/build-icons.py" \
    --great-json "$GREAT_JSON" \
    --great-icons "$GREAT_ICONS" \
    --material-icons "$MATERIAL_ICONS" \
    --out-icons "$ICONS_DIR" \
    --out-css "$CSS_OUT"

echo "==> Done."
echo "  Icons: $(ls -1 "$ICONS_DIR"/*.svg 2>/dev/null | wc -l) SVGs in icons/"
echo "  CSS:   $(wc -l < "$CSS_OUT") lines in css/file-icons.css"
echo ""
echo "Run 'bash build.sh' next to assemble into templates."
