# Custom Tools

Key commands in `~/.bin/` (all have `--help`):

```
tree (--gitignore available)    safe_rm.sh
find_large_files.sh             notify.sh
rename.sh                      encrypt.sh / decrypt.sh
sbatch.sh / slogin.sh          install_*.sh
```

Access: `~/.bashrc`, `~/.bash.d/*.src`, `~/.bin/*/*.sh`

## tree Quick Reference

```bash
tree -L 2                           # Top-level overview
tree -a --gitignore                  # All files, respecting .gitignore
tree -d -h --du                      # Directories with sizes
tree -I "node_modules|__pycache__"   # Exclude patterns
tree -J > structure.json             # JSON output
```
