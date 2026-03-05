#!/usr/bin/env bash
# Assembles css/file-icons.css into a Forgejo header.tmpl template.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CSS_FILE="$SCRIPT_DIR/css/file-icons.css"
OUT_DIR="$SCRIPT_DIR/templates/custom"

mkdir -p "$OUT_DIR"

{
    echo "<style>"
    echo "/* === file-icons.css === */"
    cat "$CSS_FILE"
    echo ""
    echo "</style>"
} > "$OUT_DIR/header.tmpl"

echo "Built: $OUT_DIR/header.tmpl ($(wc -l < "$CSS_FILE") lines of CSS)"
