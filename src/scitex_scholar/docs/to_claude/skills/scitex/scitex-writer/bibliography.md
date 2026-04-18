---
description: BibTeX management — add, list, merge, enrich bibliography entries.
---

# Bibliography

MCP tools for bibliography management:

| Tool | Description |
|------|-------------|
| `writer_add_bibentry` | Add a BibTeX entry |
| `writer_get_bibentry` | Get entry by key |
| `writer_list_bibentries` | List all entries |
| `writer_remove_bibentry` | Remove an entry |
| `writer_list_bibfiles` | List .bib files |
| `writer_merge_bibfiles` | Merge multiple .bib files |

```python
# Via MCP or CLI
# scitex-writer bib add "key" --doi 10.1038/nature12373
# scitex-writer bib list
# scitex-writer bib merge
```
