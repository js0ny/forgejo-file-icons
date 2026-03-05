# forgejo-file-icons

File-type icons for Forgejo's repository file browser. Replaces the default monochrome octicons with colored SVG icons based on file extension and filename.

![License](https://img.shields.io/badge/license-MIT%20%2B%20Apache%202.0-blue.svg)

## What it does

Uses CSS attribute selectors on Forgejo's `data-entryname` attributes to swap file/folder icons with language-specific SVGs from [vscode-great-icons](https://github.com/EmmanuelBeziat/vscode-great-icons) and [vscode-material-icon-theme](https://github.com/material-extensions/vscode-material-icon-theme).

Covers 1200+ SVG icons across hundreds of file extensions and filenames.

## Installation

### 1. Copy icons to your Forgejo assets directory

```bash
cp -r icons/ /path/to/forgejo/custom/public/assets/icons/
```

### 2. Build and install the template

```bash
bash build.sh
cp templates/custom/header.tmpl /path/to/forgejo/custom/templates/custom/header.tmpl
```

### 3. Restart Forgejo

The icons will appear immediately in repository file listings.

### Forgejo paths

| Setup | Custom directory |
|-------|-----------------|
| Binary | `$FORGEJO_WORK_DIR/custom/` or set via `FORGEJO_CUSTOM` |
| Docker | `/data/gitea/` (mount as volume) |
| Cloudron | `/app/data/custom/` |

Static assets go in `custom/public/` and templates in `custom/templates/`.

## How it works

The CSS uses Forgejo's existing `data-entryname` attribute on table rows:

```css
/* Match by extension */
tr.entry[data-entryname$=".rs"] .octicon-file {
    background-image: url('/assets/icons/rust.svg');
}

/* Match by exact filename */
tr.entry[data-entryname="Dockerfile"] .octicon-file {
    background-image: url('/assets/icons/docker.svg');
}
```

The default octicon SVG paths are made transparent and a `background-image` is set on the SVG element itself.

## Rebuilding from source

To regenerate icons and CSS from the upstream VS Code icon repos:

```bash
# Requires: git, python3
bash build-icons.sh

# Then rebuild the template
bash build.sh
```

`build-icons.sh` shallow-clones the icon repos, extracts SVGs, and generates `css/file-icons.css` using the extension mappings from vscode-great-icons.

## Adding custom icons

Edit `css/file-icons.css` and add a rule:

```css
/* myformat */
tr.entry[data-entryname$=".xyz"] .octicon-file { background-image: url('/assets/icons/myicon.svg'); }
```

Place the SVG in `icons/` and rebuild with `bash build.sh`.

## License

Build scripts and CSS are MIT-licensed. SVG icons are redistributed from upstream projects under their own licenses:

| Source | License |
|--------|---------|
| [vscode-great-icons](https://github.com/EmmanuelBeziat/vscode-great-icons) | MIT |
| [vscode-material-icon-theme](https://github.com/material-extensions/vscode-material-icon-theme) | MIT |
| [Material Design Icons](https://pictogrammers.com/library/mdi/) (Pictogrammers) | Apache 2.0 |
| [Material Symbols](https://fonts.google.com/icons) (Google) | Apache 2.0 |

See [NOTICE](NOTICE) for full attribution and license texts.
