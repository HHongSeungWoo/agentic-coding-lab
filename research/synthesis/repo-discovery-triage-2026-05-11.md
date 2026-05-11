# Repository Discovery Triage Snapshot - 2026-05-11

This snapshot records the repository discovery pass used to expand `research/index.md` across all repository categories.

## Source Method

Discovery used GitHub REST API repository search and repository metadata snapshots sorted by stars on 2026-05-11. Search groups were:

- `skills-instructions`: existing top-20 index rows were retained.
- `mcp`: `topic:model-context-protocol`, `topic:mcp`, `"Model Context Protocol"`, `"MCP server"`, and `org:modelcontextprotocol`.
- `harness-eval`: `topic:llm-evaluation`, `topic:evals`, `"LLM eval"`, `"agent benchmark"`, `"SWE-bench"`, and direct known evaluation harness checks.
- `agent-support-systems`: `"agent memory"`, `"context engineering"`, `"agent sandbox"`, `"Claude Code memory"`, `"agent runtime"`, `"agent workspace"`, and direct known support-system checks.

## Triage Rules

- `in-scope`: directly reusable as an Agentic Coding Artifact source or deep-review target.
- `conditional`: useful only for a subsystem pattern, because the repository is broader than agentic coding support.
- `out-of-scope`: excluded from the index when the repository was a general agent application, model client, tutorial-only repository, or unrelated project with incidental keyword matches.

## Result

The index now has repository discovery and triage coverage for:

- `skills-instructions`: 20 rows.
- `mcp`: 20 rows.
- `harness-eval`: 20 rows.
- `agent-support-systems`: 20 rows.

The next research step is deep review of the highest-signal `in-scope` and `conditional` candidates, writing repository notes from `research/templates/repo-note.md`.
