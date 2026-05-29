# Repository Discovery Refresh - 2026-05-29

This refresh updates the repository discovery backlog after the previous reviewed repo backlog reached zero.

## Source Method

Discovery used GitHub REST API repository search on 2026-05-29, sorted by stars, with 30 results per category query. The raw API snapshot was kept in `/tmp/repo_refresh_2026-05-29.json` during the run and was not committed.

Search groups:

- `skills-instructions`: `"Claude Code" skills`
- `mcp`: `topic:model-context-protocol`
- `harness-eval`: `topic:llm-evaluation`
- `agent-support-systems`: `"agent runtime"`
- `token-efficiency`: `"context compression"`
- `context-control`: `"context engineering"`
- `memory`: `"agent memory"`
- `subagents-multiagents`: `"multi-agent"`
- `tool-use`: `"function calling"`
- `ai-coding-workflow`: `"coding agent"`
- `error-prevention`: `"prompt injection"`
- `domain-specific-coding`: `"agent skills"`

The refresh intentionally did not add general agent apps, model clients, IDE clients, desktop shells, or broad chat applications as direct subjects. High-star examples excluded for that reason included coding-agent apps and multi-provider clients that did not expose a reusable support-system surface in the search metadata.

## Index Changes

- Added 59 new `repo` rows with `Status: candidate`.
- Preserved all previously reviewed rows and notes.
- Updated the duplicated reviewed `affaan-m/everything-claude-code` rows to the current GitHub full name `affaan-m/ECC` after the REST API returned a permanent redirect.

Candidate additions by category:

- `skills-instructions`: 5
- `mcp`: 5
- `harness-eval`: 5
- `agent-support-systems`: 5
- `token-efficiency`: 4
- `context-control`: 5
- `memory`: 5
- `subagents-multiagents`: 5
- `tool-use`: 4
- `ai-coding-workflow`: 5
- `error-prevention`: 5
- `domain-specific-coding`: 6

## Highest-Priority Follow-Ups

- `anthropics/claude-plugins-official`: likely the most authoritative current plugin/skill packaging reference.
- `kubernetes-sigs/agent-sandbox` and `always-further/nono`: strong candidates for sandbox and permission-boundary design.
- `MinishLab/semble` and `DeusData/codebase-memory-mcp`: high-signal code context and memory MCP candidates.
- `BloopAI/vibe-kanban`, `openai/symphony`, and `agentsmd/agents.md`: strong current coding-agent workflow candidates.
- `luckyPipewrench/pipelock` and `Tencent/AI-Infra-Guard`: useful current safety and scanner candidates.

## Caveats

GitHub search is a popularity and keyword signal, not proof of scope fit. Every added row still needs deep review before adopting patterns. Several search hits were triaged only from metadata and may be reclassified during review.
