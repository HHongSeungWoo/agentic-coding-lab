---
name: agentic-research
description: Project-local workflow for researching AI coding support systems in this repository. Use when the user asks to research, find candidates, deep-review, compare, or synthesize agent skills, instructions, MCP, harness/eval, context control, token efficiency, memory, subagents, multi-agent workflows, AI coding error prevention, or related papers/repos. Also use for casual Korean requests like "MCP 후보 찾아줘", "이 repo 깊게 읽어줘", "memory 논문 조사해줘", or "token 줄이는 방법 synthesis 해줘".
---

# Agentic Research

Use this skill to run the Agentic Coding Lab research pipeline without making the user remember exact commands or formats.

## Interpret Requests

Map natural language to the closest mode:

- "후보 찾아줘", "조사해줘", "Top 20": discovery + triage.
- "깊게 읽어줘", "deep review": write one repo or paper note.
- "논문 찾아줘", "최신 유명 논문": paper discovery + triage.
- "종합해줘", "synthesis", "장점만 뽑아줘": write synthesis from existing notes.

If target/scope is missing, ask one question only. Otherwise use defaults.

## Defaults

- Repo categories: `skills-instructions`, `mcp`, `harness-eval`, `agent-support-systems`.
- Paper topics: `token-efficiency`, `context-control`, `memory`, `subagents-multiagents`, `tool-use`, `ai-coding-workflow`, `error-prevention`, `domain-specific-coding`.
- Repo discovery: category Top 20 by GitHub stars.
- Paper discovery: 10-20 recent or influential papers.
- Recent paper window: last 12-24 months, plus older field-defining papers.
- Storage: Markdown only. Do not add JSON, CSV, SQLite, or vendored source snapshots.
- Clone external repos under `/tmp/myagents-research`.
- Record current snapshots with date, source, and provenance.

## Scope Rules

Include systems that improve AI coding above an existing agent tool:

- Skills, instructions, commands, rules, prompt packs, `AGENTS.md` patterns.
- MCP servers/clients/registries/tool adapters when useful for agent workflows.
- Harnesses, eval loops, verification, sandboxing, permission, review workflows.
- Token/context/memory/subagent/workflow/error-prevention systems.
- Agent frameworks only when reviewing reusable subsystem patterns.

Exclude agent apps/model clients as direct subjects:

- Codex, opencode, Claude Code, Cursor, Cline, IDE clients, general chat clients.

## File Locations

- Index: `research/index.md`
- Repo notes: `research/repos/<category>/<owner>-<repo>.md`
- Paper notes: `research/papers/<topic>/<year>-<short-title>.md`
- Synthesis: `research/synthesis/<topic>.md`
- Templates: `research/templates/repo-note.md`, `research/templates/paper-note.md`

## Discovery And Triage

For repo discovery:

1. Browse or use GitHub API/search for current candidate data.
2. Keep exactly the requested count, default 20.
3. Add rows to `research/index.md`.
4. Use `Scope fit`: `in-scope`, `conditional`, or `out-of-scope`.
5. Use `Status`: `candidate` or `triaged`.
6. Keep note path empty until deep review.

For paper discovery:

1. Browse arXiv, OpenReview, Semantic Scholar, OpenAlex, Papers with Code, author pages, and linked GitHub repos.
2. Prefer accessible full text, code, benchmark impact, or strong citation signal.
3. Use OpenAlex work IDs for citation provenance when available.
4. Add rows to `research/index.md`.

Always browse for stars, citations, latest papers, URLs, or current metadata.

## Deep Repo Review

Use this when the user names a GitHub repo or asks to deeply read a candidate.

1. Confirm the repo row exists in `research/index.md`; add one if needed.
2. Clone or update checkout under `/tmp/myagents-research/<owner>-<repo>`.
3. Record `Reviewed commit`.
4. Read README/docs, examples/tests, entrypoints, schemas/config, loaders/registries, orchestration, tool/MCP boundaries, prompt/context/memory assembly, sandbox/permission/verification/error handling.
5. Exclude generated, vendored, binary, UI-only, or unrelated paths with explanation.
6. Copy `research/templates/repo-note.md`.
7. Fill every section; no empty headings or placeholders.
8. Update index row to `reviewed` with note path and final verdict.

Focus on actual execution path and design choices, not README marketing.

## Deep Paper Review

Use this when the user names a paper or asks to deeply read a paper candidate.

1. Confirm the paper row exists in `research/index.md`; add one if needed.
2. Read accessible abstract, introduction, method, experiments, limitations, conclusion, diagrams/algorithms/prompts/ablations/benchmarks, and linked code/project pages.
3. Record URL, authors, venue/source, publication date, citation snapshot/source, DOI or arXiv ID, code link, reviewed date.
4. Copy `research/templates/paper-note.md`.
5. Fill every section; no empty headings or placeholders.
6. `Ideas To Steal` must translate paper ideas into Agentic Coding Lab patterns.
7. `Do Not Copy` must capture assumptions, costs, and failure modes.
8. Update index row to `reviewed` with note path and final verdict.

Do not infer method details from abstracts alone.

## Synthesis

Use synthesis when the user asks "그래서 뭐가 좋냐", "장점만 뽑아줘", or asks about a theme.

1. Read relevant repo and paper notes first.
2. Write `research/synthesis/<topic>.md`.
3. Compare patterns across sources.
4. Separate:
   - `Ideas To Steal`
   - `Do Not Copy`
   - `Artifact Candidates`
   - `Open Questions`
5. Prefer practical guidance for future skills, MCP configs, harnesses, memory rules, or workflow artifacts.

## Verification

Before saying work is complete:

```bash
rtk sh bootstrap/test_research.sh
rtk git status --short
```

For durable research changes, commit each completed step unless the user says not to:

```bash
rtk git add <changed-files>
rtk git commit -m "research: <short summary>"
```

If commit needs escalation because `.git/index.lock` is blocked, request escalation normally.
