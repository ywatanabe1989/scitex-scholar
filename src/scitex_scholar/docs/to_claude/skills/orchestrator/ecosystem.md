# SciTeX Ecosystem Map

## Project Routing

| Package | Path | Purpose | Key Tech |
|---------|------|---------|----------|
| scitex-python | ~/proj/scitex-python | Core framework (session, io, plt, stats) | Python |
| scitex-cloud | ~/proj/scitex-cloud | Web platform | Django, TypeScript |
| scitex-ui | ~/proj/scitex-ui | Workspace shell + React components | TypeScript, React |
| scitex-app | ~/proj/scitex-app | App SDK for workspace | Python, TypeScript |
| figrecipe | ~/proj/figrecipe | Declarative plotting | Python, matplotlib |
| scitex-writer | ~/proj/scitex-writer | LaTeX manuscript compilation | Python, LaTeX |
| scitex-stats | ~/proj/scitex-stats | Statistical testing (23 tests) | Python |
| scitex-io | ~/proj/scitex-io | Universal file I/O (30+ formats) | Python |
| scitex-audio | ~/proj/scitex-audio | TTS with multiple backends | Python |
| scitex-notification | ~/proj/scitex-notification | Multi-backend notifications | Python |
| scitex-linter | ~/proj/scitex-linter | Code convention checker | Python |
| scitex-dev | ~/proj/scitex-dev | Ecosystem management tools | Python |
| scitex-clew | ~/proj/scitex-clew | Reproducibility verification | Python |
| socialia | ~/proj/socialia | Social media management | Python |
| crossref-local | ~/proj/crossref-local | 167M+ works citation DB | Python, SQLite |
| openalex-local | ~/proj/openalex-local | 284M+ works academic DB | Python, SQLite |
| scitex-dataset | ~/proj/scitex-dataset | Multi-domain dataset fetcher (biology, pharmacology, neuroscience, medical, ML) | Python |
| scitex-container | ~/proj/scitex-container | Apptainer/Docker management | Python, Bash |
| scitex-tunnel | ~/proj/scitex-tunnel | SSH reverse tunnels | Python, Bash |
| scitex-orochi | ~/proj/scitex-orochi | Agent communication hub (WebSocket, channels, presence) | Python, TypeScript |
| emacs_mcp_server | ~/proj/emacs_mcp_server | Emacs MCP bridge | Python |

## Task Routing Guide

"Fix a bug in the web UI" → scitex-cloud or scitex-ui
"Add a statistical test" → scitex-stats
"Plotting issue" → figrecipe or scitex-plt
"File loading problem" → scitex-io
"LaTeX compilation" → scitex-writer
"Audio not working" → scitex-audio
"Notification issue" → scitex-notification
"Agent communication" → scitex-orochi
"Emacs integration" → emacs_mcp_server
"Dataset download" → scitex-dataset
"Literature search" → crossref-local or openalex-local
"Container build" → scitex-container
"Cross-package issue" → scitex-dev (ecosystem tools)

## Dashboard Status Check

To get a quick status of all projects:
```elisp
;; List all agent vterms
(mapcar #'buffer-name
  (seq-filter (lambda (b)
    (with-current-buffer b
      (and (derived-mode-p 'vterm-mode)
           (string-prefix-p "agent-" (buffer-name)))))
    (buffer-list)))
```
