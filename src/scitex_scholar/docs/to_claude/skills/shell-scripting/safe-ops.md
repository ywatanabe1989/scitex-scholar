# Safe File Operations

## Safe Removal

Use `safe_rm.sh` instead of `rm` to preserve files in `.old/` with timestamp:

```bash
# Instead of: rm file.txt
safe_rm.sh file.txt
safe_rm.sh directory/
safe_rm.sh *.bak
```

## cp and rm Flags

Always add `-f` flag to `cp` and `rm` to prevent interactive prompts in automated sessions:

```bash
rm -f file.txt
rm -rf directory/
cp -f src dest
```
