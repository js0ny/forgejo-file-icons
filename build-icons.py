"""
Generates css/file-icons.css and copies SVG icons from vscode-great-icons
and vscode-material-icon-theme.

Called by build-icons.sh — not intended to be run directly.
"""

import argparse
import json
import os
import shutil
from collections import defaultdict
from pathlib import Path


def find_svg(icon_name: str, great_dir: str, material_dir: str) -> str | None:
    """Find an SVG file for the given icon name, preferring great-icons."""
    for d in [great_dir, material_dir]:
        path = os.path.join(d, f"{icon_name}.svg")
        if os.path.isfile(path):
            return path
    return None


# Names in great-icons mapping that we know have different filenames
ICON_ALIASES = {
    "shell": ["console", "terminal", "shell"],
    "c-h": ["c-h", "h"],
    "cpp-h": ["cpp-h", "hpp"],
    "rlang": ["rlang", "r"],
    "react_alt": ["react_alt", "react-alt"],
}

# Filenames upstream's icons.json has no entry for, despite the SVGs shipping in
# vscode-material-icon-theme. Without these the most common files in any repo
# (README.md above all) fall through to the generic document icon.
EXTRA_FILE_NAMES = {
    "readme": "readme",
    "readme.md": "readme",
    "readme.rst": "readme",
    "readme.txt": "readme",
    "readme.adoc": "readme",
    "changelog": "changelog",
    "changelog.md": "changelog",
    "changes.md": "changelog",
    "history.md": "changelog",
    "contributing": "contributing",
    "contributing.md": "contributing",
    "authors": "authors",
    "authors.md": "authors",
    "todo": "todo",
    "todo.md": "todo",
}


def find_svg_with_aliases(icon_name: str, great_dir: str, material_dir: str) -> str | None:
    """Try the icon name and known aliases."""
    names = list(ICON_ALIASES.get(icon_name, [icon_name]))
    if icon_name not in names:
        names.insert(0, icon_name)
    for name in names:
        result = find_svg(name, great_dir, material_dir)
        if result:
            return result
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--great-json", required=True)
    parser.add_argument("--great-icons", required=True)
    parser.add_argument("--material-icons", required=True)
    parser.add_argument("--out-icons", required=True)
    parser.add_argument("--out-css", required=True)
    args = parser.parse_args()

    with open(args.great_json, encoding="utf-8") as f:
        data = json.load(f)

    file_extensions = data.get("fileExtensions", {})
    file_names = {**data.get("fileNames", {}), **EXTRA_FILE_NAMES}

    # -------------------------------------------------------------------------
    # 1. Collect all icons referenced and copy SVGs
    # -------------------------------------------------------------------------
    all_icon_names: set[str] = set()
    for icon in file_extensions.values():
        all_icon_names.add(icon.replace("_f_", ""))
    for icon in file_names.values():
        all_icon_names.add(icon.replace("_f_", ""))

    copied = 0
    missing = []
    for icon_name in sorted(all_icon_names):
        src = find_svg_with_aliases(icon_name, args.great_icons, args.material_icons)
        if src:
            dest = os.path.join(args.out_icons, f"{icon_name}.svg")
            shutil.copy2(src, dest)
            copied += 1
        else:
            missing.append(icon_name)

    # Also copy ALL SVGs from both repos (so we have the full library available)
    for src_dir in [args.great_icons, args.material_icons]:
        for f in Path(src_dir).glob("*.svg"):
            dest = os.path.join(args.out_icons, f.name)
            if not os.path.exists(dest):
                shutil.copy2(str(f), dest)
                copied += 1

    print(f"  Copied {copied} SVGs ({len(missing)} icons missing SVGs: {', '.join(missing[:10])}{'...' if len(missing) > 10 else ''})")

    # -------------------------------------------------------------------------
    # 2. Build extension → icon_name mapping, grouped by icon
    # -------------------------------------------------------------------------
    missing_set = set(missing)

    def suffix_of(ext: str) -> str:
        return ext if ext.startswith(".") else f".{ext}"

    # Every rule below has identical specificity (0,3,1), so the cascade is decided
    # purely by document order. Bucket extensions by suffix length: if one suffix
    # ends with another (".blade.php" vs ".php") the longer is the more specific
    # match, so it must be emitted later to win.
    len_to_icon_exts: dict[int, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for ext, icon in sorted(file_extensions.items()):
        icon_name = icon.replace("_f_", "")
        if icon_name in missing_set:
            continue
        suffix = suffix_of(ext)
        len_to_icon_exts[len(suffix)][icon_name].append(suffix)

    icon_to_names: dict[str, list[str]] = defaultdict(list)
    for name, icon in sorted(file_names.items()):
        icon_name = icon.replace("_f_", "")
        if icon_name in missing_set:
            continue
        icon_to_names[icon_name].append(name)

    # -------------------------------------------------------------------------
    # 3. Generate CSS
    # -------------------------------------------------------------------------
    lines: list[str] = []
    w = lines.append

    w("/*")
    w(" * File Icons — Custom SVG icons by file extension")
    w(" * AUTO-GENERATED by build-icons.sh — do not edit manually.")
    w(" *")
    w(" * Icons sourced from:")
    w(" *   - vscode-great-icons (MIT)")
    w(" *   - vscode-material-icon-theme (MIT)")
    w(" */")
    w("")

    # The octicon <svg> keeps its box and alignment; only its paths are blanked so
    # the background image shows through. Swapping it for a pseudo-element instead
    # would mean re-deriving Forgejo's sizing and baseline by hand.
    w("/* Base: hide original SVG paths, align, and prepare for background swap */")
    w("tr.entry[data-entryname] .octicon-file,")
    w("tr.entry[data-entryname] .octicon-file-directory-fill,")
    w("tr.entry[data-entryname] .octicon-file-submodule {")
    w("    fill: transparent;")
    w("    vertical-align: -1.5px;")
    w("    background: center/contain no-repeat;")
    w("}")
    w("")
    w("/* Default file icon */")
    w("tr.entry[data-entryname] .octicon-file {")
    w("    background-image: url('/assets/icons/document.svg');")
    w("}")
    w("")
    w("/* Default folder icon */")
    w("tr.entry[data-entryname] .octicon-file-directory-fill,")
    w("tr.entry[data-entryname] .octicon-file-submodule {")
    w("    background-image: url('/assets/icons/folder.svg');")
    w("}")
    w("")

    def css_string(value: str) -> str:
        return value.replace("\\", "\\\\").replace('"', '\\"')

    # The trailing `i` matches case-insensitively: upstream's mapping is all
    # lowercase, but the files on disk are Dockerfile, Makefile, LICENSE, README.md.
    def ext_selector(suffix: str) -> str:
        return f'tr.entry[data-entryname$="{css_string(suffix)}" i]'

    def name_selector(name: str) -> str:
        return f'tr.entry[data-entryname="{css_string(name)}" i]'

    def emit(icon_name: str, selectors: list[str]) -> None:
        w(f"/* {icon_name} */")
        w(
            ",\n".join(f"{sel} .octicon-file" for sel in selectors)
            + f" {{ background-image: url('/assets/icons/{icon_name}.svg'); }}"
        )
        w("")

    for length in sorted(len_to_icon_exts):
        for icon_name in sorted(len_to_icon_exts[length]):
            emit(icon_name, [ext_selector(s) for s in len_to_icon_exts[length][icon_name]])

    # Exact filenames last: an entry named docker-compose.yml must beat the generic
    # .yml suffix rule, and identical specificity means last-one-wins.
    w("/* ---- Exact filenames (override extension rules above) ---- */")
    w("")
    for icon_name in sorted(icon_to_names):
        emit(icon_name, [name_selector(n) for n in icon_to_names[icon_name]])

    # Write output
    css_content = "\n".join(lines)
    with open(args.out_css, "w", encoding="utf-8") as f:
        f.write(css_content)

    # Stats
    ext_icons = {icon for group in len_to_icon_exts.values() for icon in group}
    total_exts = sum(len(v) for group in len_to_icon_exts.values() for v in group.values())
    total_names = sum(len(v) for v in icon_to_names.values())
    total_icons = len(ext_icons | set(icon_to_names))
    print(f"  Generated CSS: {total_icons} icons, {total_exts} extensions, {total_names} named files")


if __name__ == "__main__":
    main()
