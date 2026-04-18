# Context Window Analysis Prompt

Copy and paste one of these prompts into Claude Code to analyze your context usage.

---

## Basic Prompt (Copy & Paste)

```
Analyze the current context window usage.

Follow these steps:

1. Check if `--verbose` output or API response `usage` fields are available
2. If not, enumerate all currently loaded components and estimate token counts
   (rule of thumb: ~1 token per English word, ~1-2 tokens per CJK character):

   - System prompt
   - CLAUDE.md (user-level + project-level; flag any duplicates)
   - MCP tool definitions (group by server, show per-server breakdown)
   - Conversation history (number of turns + estimated tokens)
   - Other (memory, skills, etc.)

3. Output in this format:

## Context Window Usage Report

| Category | Details | Est. Tokens | % of Total |
|----------|---------|-------------|------------|
| System Prompt | core instructions | ... | ...% |
| CLAUDE.md (user) | ~/.claude/CLAUDE.md | ... | ...% |
| CLAUDE.md (project) | .claude/CLAUDE.md | ... | ...% |
| MCP Tools | server-a (N tools) | ... | ...% |
| | server-b (N tools) | ... | ...% |
| Conversation | N turns | ... | ...% |
| Available | - | ... | ...% |
| **Total** | - | **200,000** | **100%** |

4. Analysis:
   - Top 3 context consumers
   - Any duplicated content between user-level and project-level CLAUDE.md
   - MCP tools with overly verbose descriptions that could be trimmed
   - Estimated remaining turns at current consumption rate
```

---

## Accurate Measurement (Script Version)

```
Measure the actual token usage by running these steps:

1. `cat ~/.claude/CLAUDE.md | wc -c` to get user-level CLAUDE.md size
2. `cat .claude/CLAUDE.md | wc -c` to get project-level CLAUDE.md size
3. Call `tools/list` on each MCP server and measure the JSON string length of tool definitions
4. If possible, `pip install anthropic` and use the tokenizer for exact counts
5. Output results as a markdown table

Duplicate check:
- Diff user-level and project-level CLAUDE.md to extract overlapping lines
- Calculate wasted tokens from duplication
```

---

## Auto-Monitor (Hook Version)

Add this to your `.claude/settings.json` to log usage after every turn:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "command": "python3 -c \"import json,sys; data=json.load(sys.stdin); u=data.get('usage',{}); print(f'Input: {u.get(\"input_tokens\",0):,} | Output: {u.get(\"output_tokens\",0):,} | Cached: {u.get(\"cache_read_input_tokens\",0):,}')\" 2>/dev/null || true"
      }
    ]
  }
}
```

Note: The hook version may need adjustment based on the actual API response structure passed to hooks.

---

## Tips

- The basic prompt gives rough estimates (±30% accuracy)
- For serious optimization (e.g., 145+ MCP tools), use the script version
- The hook version is useful for tracking consumption trends over a session
- Pay special attention to MCP tool descriptions — trimming verbose descriptions can save thousands of tokens
