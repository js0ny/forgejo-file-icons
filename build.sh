#!/usr/bin/env bash
# Assembles CSS and JS source files into Forgejo custom templates.
# CSS files  -> templates/custom/header.tmpl  (injected before </head>)
# JS files   -> templates/custom/footer.tmpl  (injected before </body>)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CSS_DIR="$SCRIPT_DIR/css"
JS_DIR="$SCRIPT_DIR/js"
OUT_DIR="$SCRIPT_DIR/templates/custom"

mkdir -p "$OUT_DIR"

# Count JS files (determines whether FOUC cloak and footer are needed)
JS_COUNT=$(ls "$JS_DIR"/*.js 2>/dev/null | wc -l || true)

# --- Build header.tmpl from CSS files ---
{
    if [ "$JS_COUNT" -gt 0 ]; then
        # Inline script runs before first paint — adds class that CSS uses to cloak
        # elements that JS will modify (prevents FOUC)
        echo '<script>document.documentElement.classList.add("js-loading");</script>'
    fi
    echo "<style>"
    for f in "$CSS_DIR"/*.css; do
        [ -f "$f" ] || continue
        echo "/* === $(basename "$f") === */"
        cat "$f"
        echo ""
    done
    echo "</style>"
} > "$OUT_DIR/header.tmpl"

# --- Build footer.tmpl from JS files (only if JS files exist) ---
if [ "$JS_COUNT" -gt 0 ]; then
    {
        echo "<script>"
        for f in "$JS_DIR"/*.js; do
            [ -f "$f" ] || continue
            echo "// === $(basename "$f") ==="
            cat "$f"
            echo ""
        done
        # Remove FOUC cloak after all synchronous modifications are done
        echo '// === FOUC reveal ==='
        echo 'document.documentElement.classList.remove("js-loading");'
        echo "</script>"
    } > "$OUT_DIR/footer.tmpl"
else
    rm -f "$OUT_DIR/footer.tmpl"
fi

echo "Built:"
echo "  $OUT_DIR/header.tmpl  (from $(ls "$CSS_DIR"/*.css 2>/dev/null | wc -l) CSS files)"
if [ "$JS_COUNT" -gt 0 ]; then
    echo "  $OUT_DIR/footer.tmpl  (from $JS_COUNT JS files)"
else
    echo "  (no JS files — footer.tmpl skipped)"
fi
