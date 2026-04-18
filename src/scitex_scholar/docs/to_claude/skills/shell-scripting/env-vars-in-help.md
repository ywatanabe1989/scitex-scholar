# Env Vars in Help Text

When a CLI option has a default controlled by an environment variable, show the env var name in the help text — not the resolved value. This lets users discover configuration without reading source code.

## Bash

```bash
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -o, --output DIR   Output directory (default: \$MY_TOOL_OUTPUT_DIR)"
    echo "  -p, --port PORT    Server port (default: \$MY_TOOL_PORT, or 8080)"
    echo "  -h, --help         Show this help"
}
```

## Python (Click / argparse)

```python
@click.option("--output", default=None,
              help="Output directory (default: $MY_TOOL_OUTPUT_DIR)")
```

```python
parser.add_argument("--output", default=None,
                    help="Output directory (default: $MY_TOOL_OUTPUT_DIR)")
```
