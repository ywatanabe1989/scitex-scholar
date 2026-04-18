---
description: Complete figrecipe CLI reference — all commands with options and examples.
---

# CLI Reference

Entry point: `figrecipe` (installed by `pip install figrecipe`).

```bash
figrecipe --help
figrecipe --version
figrecipe --help-recursive    # full help for all commands
```

## Figure Creation

### figrecipe plot

Create a figure from a declarative YAML/JSON spec file.

```bash
figrecipe plot spec.yaml
figrecipe plot spec.yaml -o figure.png
figrecipe plot spec.yaml -f pdf --dpi 600
figrecipe plot spec.yaml --style SCITEX
figrecipe plot spec.yaml --show              # display interactively
figrecipe plot spec.yaml --save-recipe       # also save .yaml recipe
```

Options: `-o/--output`, `-f/--format [png|pdf|svg]`, `--dpi`, `--style`, `--show`, `--save-recipe`

### figrecipe reproduce

Recreate a figure from a saved YAML recipe.

```bash
figrecipe reproduce recipe.yaml
figrecipe reproduce recipe.yaml -o output.png
figrecipe reproduce recipe.yaml -f pdf --dpi 600
figrecipe reproduce recipe.yaml --show
```

Options: `-o/--output`, `-f/--format [png|pdf|svg]`, `--dpi`, `--show`

### figrecipe compose

Combine multiple figures into one.

```bash
figrecipe compose panel_a.yaml panel_b.yaml -o composed.png
figrecipe compose a.png b.png c.png -o out.png --layout horizontal
figrecipe compose a.png b.png c.png d.png -o out.png --layout grid --cols 2
figrecipe compose a.png b.png -o out.png --layout vertical --dpi 600
```

Options: `-o/--output` (required), `--layout [horizontal|vertical|grid]`, `--cols`, `--dpi`

### figrecipe gui

Launch the interactive GUI editor.

```bash
figrecipe gui
figrecipe gui recipe.yaml
figrecipe gui recipe.yaml --port 8080
figrecipe gui recipe.yaml --desktop          # native window (requires figrecipe[desktop])
```

## Image Processing

### figrecipe convert

Convert figure between formats.

```bash
figrecipe convert figure.eps -o figure.png
figrecipe convert figure.pdf -o figure.svg
```

### figrecipe crop

Crop whitespace from a figure image. Requires `figrecipe[imaging]`.

```bash
figrecipe crop figure.png
figrecipe crop figure.png -o figure_tight.png
figrecipe crop figure.png --margin 2mm
figrecipe crop figure.png --margin 10px
figrecipe crop figure.png --overwrite
```

Options: `-o/--output`, `--margin` (e.g., `2mm`, `10px`, default `1mm`), `--overwrite`

### figrecipe diff

Show pixel difference between two figures.

```bash
figrecipe diff old.png new.png -o diff.png
```

### figrecipe hitmap

Generate hitmap for GUI element selection.

```bash
figrecipe hitmap recipe.yaml
```

## Data & Validation

### figrecipe extract

Extract data arrays from a figure.

```bash
figrecipe extract recipe.yaml
figrecipe extract recipe.yaml -o data.csv
```

### figrecipe validate

Validate that a recipe can reproduce its original figure.

```bash
figrecipe validate recipe.yaml
figrecipe validate recipe.yaml --threshold 50.0
figrecipe validate recipe.yaml --strict         # threshold = 0
figrecipe validate recipe.yaml -q               # quiet: PASS/FAIL only
```

Options: `--threshold` (MSE, default 100), `--strict`, `-q/--quiet`

### figrecipe info

Show recipe metadata.

```bash
figrecipe info recipe.yaml
```

## Diagram

### figrecipe diagram

```bash
figrecipe diagram render flow.mmd -o flow.png
figrecipe diagram create --preset WORKFLOW
figrecipe diagram --help
```

## Style & Appearance

### figrecipe style

```bash
figrecipe style list              # list all presets
figrecipe style show SCITEX       # show preset details
figrecipe style apply SCITEX      # apply globally
figrecipe style reset             # reset to matplotlib defaults
```

### figrecipe fonts

```bash
figrecipe fonts list              # list available fonts
```

## Integration

### figrecipe mcp

```bash
figrecipe mcp start               # start MCP server
figrecipe mcp run                 # run MCP server (alias)
figrecipe mcp install             # install MCP configuration
```

### figrecipe skills

```bash
figrecipe skills list             # list available skills
figrecipe skills get SKILL        # show a specific skill
figrecipe skills get plot-types   # example: show plot-types skill
```

### figrecipe list-python-apis

```bash
figrecipe list-python-apis        # list all public Python API functions
```

## Utility

### figrecipe completion

```bash
figrecipe completion bash         # generate bash completion
figrecipe completion zsh          # generate zsh completion
```

### figrecipe version

```bash
figrecipe version
```
