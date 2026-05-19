# Windy3f3f3f3f/how-claude-code-works

- URL: https://github.com/Windy3f3f3f3f/how-claude-code-works
- Category: context-control
- Stars snapshot: 2,396 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: bc6eb685478063d396f9acc893b616fe689482d2
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: High-value architecture map for coding-agent context control, especially prompt assembly, compression, tool-result budgeting, cache stability, skill/memory injection, subagent isolation, and hook-driven guardrails. Use it as a pattern catalog, not as authoritative source or reusable code, because the repo is documentation-only and its Claude Code internals claims are not independently reproducible from included source.

## Why It Matters

This repo is useful because it treats Claude Code as a production context-control system rather than as a generic "LLM plus tools" loop. The strongest chapters explain how bounded-context coding agents survive long sessions: assemble stable prompt prefixes, inject volatile context through meta messages, progressively compress history, persist oversized tool results out of band, recover recent working files after compaction, and keep tool schemas stable enough for prefix caching.

For Agentic Coding Lab, the practical value is a vocabulary and set of design patterns. It names the surfaces that should be managed explicitly: system prompt, user/project instructions, tool schemas, message history, tool results, memory files, skills, task state, hook feedback, plan files, and subagent handoffs. This helps turn "context engineering" into concrete implementation boundaries.

The main caution is provenance. The repo is a narrative analysis of Claude Code internals and prompt text. It does not include the analyzed Claude Code source, extraction scripts, test fixtures, or a way to validate every line-number and constant claim. Treat detailed constants as candidate design inputs, not as facts to cargo-cult.

## What It Is

The repo is a bilingual Docsify documentation site. It contains Markdown chapters in Chinese under `docs/` and English translations under `en/docs/`, plus root landing pages, navigation files, a Docsify `index.html`, and image assets. There is no runtime implementation of a context-control system in this checkout.

The reviewed content is organized as Claude Code internals writeups:

- Agent loop and `QueryEngine` lifecycle.
- Context engineering, compression, prompt caching, and `system-reminder` injection.
- Tool interface, tool assembly, lazy tool search, MCP integration, and large-result handling.
- Code editing strategy and read-before-edit safety.
- Skills, memory, hooks, multi-agent architecture, plan mode, permission/security, task system, system prompt design, and minimal-agent components.

The repo also has an explicit update trail in `README_EN.md` with dated changelog rows from 2026-03-31 through 2026-04-09. The latest reviewed commit is 2026-05-05 with message `Refine tool system documentation`.

## Research Themes

- Token efficiency: Very strong as documentation. Key patterns include section-level system prompt caching, static/dynamic prompt boundaries, partitioned tool sorting, lazy `ToolSearch`, oversized tool-result persistence, cache-aware microcompact, post-compact skill/file restoration, task reminder throttling, and fork subagents sharing parent cache prefixes.
- Context control: Core theme. The repo describes a full context stack: stable system prompt, memoized git and CLAUDE.md context, normalized message history, five-stage compression, memory prefetch, attachment-based reminders, task state injection, plan-mode attachments, and hook-provided context.
- Sub-agent / multi-agent: Strong. It distinguishes regular subagents with self-contained prompts, fork subagents with cache-identical parent context, coordinator-only orchestration, swarm/team execution, worktree isolation, scratchpad sharing, and task-notification result delivery.
- Domain-specific workflow: Moderate. The repo targets software engineering agents broadly. It provides concrete workflows for editing, planning, verification, hooks, and tasks, but it is not a domain-specific coding pack for a particular language or stack.
- Error prevention: Strong as a pattern source. It covers read-before-edit enforcement, exact search-and-replace edits, ambiguous match failures, permission denial tracking, hook blocking, stop hooks, Bash AST safety checks, sandboxing, dangerous path protection, and independent verification agents.
- Self-learning / memory: Strong. The memory chapter is one of the clearest practical designs: closed memory taxonomy, index-not-container `MEMORY.md`, semantic recall, freshness warnings, background extraction, scoped write permissions, and "verify memory against current code" rules.
- Popular skills: Useful ideas are skill frontmatter discovery, `whenToUse` trigger descriptions with negative cases, inline versus fork execution, skill-level hooks, post-compaction skill restoration, and path-scoped skills. The repo is not itself a skill library.

## Core Execution Path

The repo itself has no executable agent path. The core path it documents is:

1. User input enters a session manager (`QueryEngine`) that preprocesses slash commands, attachments, memory prompt, permissions, and budgets.
2. A streaming `query()` generator loops until the model stops calling tools.
3. At each loop entry, context is projected through tool-result budgeting, history snip, microcompact, context collapse, and autocompact as needed.
4. The API request is assembled from stable system prompt sections, tool schemas, user context, and normalized messages.
5. Streaming responses are parsed; completed `tool_use` blocks can start running before the full model response is complete.
6. Tool execution goes through lookup, schema validation, hook/classifier launch, permission check, execution, large-result handling, post-hooks, and `tool_result` emission.
7. Tool results, memory recalls, skill listings, task reminders, lazy tool/MCP deltas, and other attachments are wrapped as meta user messages, often with `<system-reminder>`.
8. The loop continues with updated messages, or terminates when the model returns plain text and stop hooks allow completion.

The context-specific path is the most relevant:

- Stable prompt bytes are protected with a static/dynamic boundary and section caches.
- Project instructions and current date are prepended to messages rather than merged into the global prompt.
- Volatile context arrives through attachments so it can be injected incrementally without breaking the system prompt cache.
- Old or oversized content is compressed locally first, summarized only when cheaper projections cannot preserve enough space.
- After heavy compaction, recent files, active skills, MCP instructions, agent lists, and plan state are re-announced so the model does not lose the active work surface.

## Architecture

As a repository, the architecture is simple: a Docsify static site with duplicated Chinese/English Markdown chapter trees. `index.html` loads Docsify and rendering plugins; `_sidebar.md`, `_navbar.md`, and `en/_sidebar.md` define navigation; `assets/` contains images.

As a documented system, the architecture is a layered coding-agent runtime:

- Session layer: `QueryEngine` manages user input, persistence, budgets, structured output retries, and final result extraction.
- Loop layer: `query()` is a state-machine async generator with transition reasons for normal tool turns, context overflow recovery, output-token recovery, stop-hook blocking, and token-budget continuation.
- Context layer: system prompt sections, user context, message normalization, cache breakpoints, compression, memory prefetch, and attachment injection.
- Tool layer: a unified `Tool` interface, build-time and runtime tool filtering, permission checks, concurrency-safe scheduling, MCP bridging, and UI rendering contracts.
- Extension layer: hooks, skills, memory, tasks, plan mode, subagents, coordinator mode, and swarm/team backends.
- Safety layer: permission modes, permission rules, Bash AST analysis, static validators, dangerous path checks, sandboxing, worktrees, denial tracking, and user confirmation.

This layered map is the repo's biggest contribution. It shows context control as cross-cutting infrastructure rather than as one summarization module.

## Design Choices

The strongest design choice is cache-aware context assembly. Static prompt sections are separated from dynamic content, tools are sorted so built-ins remain a stable prefix, MCP and optional tools are placed or loaded to limit cache churn, and beta headers/TTL eligibility latch at session start. The general pattern is "stability first, deltas later."

The second strong choice is progressive compression. The described pipeline tries local and reversible methods before irreversible summarization: persist large tool results to disk, snip or microcompact stale outputs, project collapsed views, and only then autocompact with a structured summary. This keeps expensive lossy compression out of the common path.

Another key choice is using meta user messages as the volatile-context channel. Memory recalls, skill listings, task reminders, plan-mode messages, hook feedback, and lazy tool deltas are injected into messages instead of mutating the system prompt. The model sees context updates, but prompt-cache-critical sections stay stable.

The tool system encodes safety semantics on the tool object. `isReadOnly(input)`, `isConcurrencySafe(input)`, `isDestructive(input)`, validation, and permission checks are input-aware methods rather than static labels. This lets read-only searches run in parallel while writes serialize and unknown tools fail closed.

The subagent design separates three use cases that many systems conflate: self-contained subagents for focused work, fork subagents for cache reuse and full-context inheritance, and coordinator workers for explicit orchestration. The "workers cannot see your conversation" rule is a practical prompt-writing constraint.

The memory design deliberately refuses to remember derivable facts. It stores user preferences, behavior feedback, project decisions, and external references, while requiring stale code/file claims to be verified against current state. That is a useful guardrail for any persistent-memory system in coding agents.

## Strengths

The repo has unusually concrete context-control mechanics for a documentation-only source. It does not stop at "summarize history"; it breaks down cache placement, message normalization, compression levels, memory injection, skill preservation, plan state, task reminders, and tool-result offload.

It translates many production pain points into reusable patterns: prompt-too-long recovery, max-output-token escalation, stop-hook continuation, denial-loop degradation, read-before-edit enforcement, post-compact recovery, and independent verification.

The tool and hook chapters are high signal for agent runtime design. They show where to put policy: at tool registration, pre-tool hooks, permission decisions, result processing, post-tool hooks, stop hooks, and lifecycle hooks.

The memory chapter is especially actionable. Its "MEMORY.md is an index, not a container" pattern, semantic recall manifest, freshness warnings, and background extractor are directly reusable in a smaller lab system.

The plan and task chapters expose context as workflow state. Plan files, task files, reminders, approvals, and verification nudges are all treated as context surfaces that need controlled injection and persistence.

The system-prompt chapter gives a rare consolidated view of prompt sections and built-in agent prompts. Even if exact prompt text changes upstream, the section taxonomy is useful.

## Weaknesses

The repo is not an implementation. There are no runnable hooks, tools, tests, schemas, extractors, or benchmark harnesses in this checkout. Adoption requires translating prose into artifacts.

Provenance is weak for detailed internals. The repo says the analysis comes from source code, but the reviewed checkout does not include the analyzed source, extraction scripts, source snapshots, or verification tests. Line counts, feature flags, constants, and prompt text should be treated as claims.

Some claims are likely time-sensitive. Claude Code internals, system prompts, feature flags, model names, and product behavior can change quickly. The repo has a changelog, but no automated drift detector.

The English documentation is incomplete for system prompt design. `en/docs/14-system-prompt-design.md` is a stub pointing to the Chinese original, so English readers must rely on Chinese content for that chapter.

There is occasional inconsistency between summary pages and deep chapters. For example, the README calls the compression pipeline "4-level" while the context-engineering chapter includes tool-result budget trimming as a five-level pipeline. This is not fatal, but it reinforces that the repo should be mined for patterns rather than copied literally.

The repo's diagrams and examples are explanatory, not executable contracts. Many practical details need a stricter spec before implementation: data schemas, failure behavior, storage layout, permissions, and test cases.

## Ideas To Steal

Build a context assembly contract with explicit surfaces: static prompt, dynamic prompt, tool schemas, project instructions, memory index, message history, tool results, attachments, task state, and subagent results. Require every new context source to declare location, update frequency, cache impact, and budget.

Use progressive compression in this order: offload oversized tool results to files, clear stale tool outputs, fold read-time views without mutating raw history, then run full summarization only as a last resort. Keep the original raw artifacts recoverable where possible.

Make volatile context an attachment stream. Inject memory, skills, task reminders, hook feedback, and plan-mode guidance as meta messages with clear tags instead of changing global instructions every turn.

Add post-compact recovery as a first-class step. Rehydrate the last few edited/read files, active skill prompts, current plan, available subagents, lazy tool listings, and MCP instruction deltas after compaction.

Use an "index, not container" memory file. Keep `MEMORY.md` compact and link to typed memory files with descriptions. Retrieve full files only when a semantic selector chooses them.

Require memory freshness warnings. If memory mentions files, symbols, line numbers, or behavior, the agent must verify against current code before using it as fact.

Treat tools as self-describing policy objects. Tool definitions should own schema, description, prompt hints, result budget, read-only status, concurrency status, destructive status, validation, permissions, and rendering or summary format.

Make lazy tool discovery explicit. Keep initial tool schemas small; expose a searchable catalog with `searchHint` metadata; load exact tools through a `select:` path when the model already knows what it needs.

Use stop hooks for "can only finish when evidence exists." A stop hook can block finalization until tests, lint, typecheck, or verification artifacts exist, then feed failures back as model-visible context.

For multi-agent work, require self-contained prompts and typed return artifacts. A worker should receive the goal, reason, known facts, file paths, exclusions, output shape, and whether it may write code. Do not let the parent write "based on your findings" as a handoff.

Use independent verification agents after nontrivial work. The verifier's job should be to break the implementation, run real commands, and return PASS/FAIL/PARTIAL with evidence.

Make plan mode a permission state, not only a prompt instruction. During planning, allow reads and plan-file writes only; restore the prior mode after approval; inject the approved plan into implementation context.

Store multi-agent task state one file per task. This gives fine-grained locking, readable task IDs, atomic claiming, ownership cleanup, and cross-process coordination without a heavy service.

## Do Not Copy

Do not treat the repo as an authoritative Claude Code specification. It is an external documentation project with no bundled source or verification harness.

Do not copy exact constants without local evidence. Thresholds like token buffers, result-size limits, turn counts, or retry counts should be re-tuned against Agentic Coding Lab workloads.

Do not rely on prompt text alone for safety. The strongest patterns in the writeups pair prompts with tool validation, permission states, path checks, hooks, and execution-time enforcement.

Do not put live task lists, memory bodies, or changing tool catalogs into the static system prompt. That would break the cache-stability goal the repo repeatedly emphasizes.

Do not make memory a code map. File paths, architecture facts, and implementation details drift; prefer current code, git, and docs as source of truth.

Do not let subagents inherit parent history by default. Use self-contained prompts for most workers; reserve fork/full-context inheritance for cases where cache economics and isolation are deliberately managed.

Do not let worker outputs flow back as untrusted raw transcripts. Summarize or classify handoffs, and preserve detailed artifacts in files when needed.

Do not copy the documentation site's UI layer or images into the lab. The value is in the architecture patterns, not the Docsify packaging.

## Fit For Agentic Coding Lab

Fit is conditional but high-signal. The repo belongs in `context-control` because it gives a broad, practical taxonomy for controlling what a coding agent sees, forgets, recalls, and delegates. It is not directly adoptable because it is prose, not source.

The best Agentic Coding Lab adaptation is a small executable context-control pack:

- `context-surfaces.md`: defines prompt/message/tool/memory/task/subagent context surfaces and cache policy.
- `compression-policy.md`: specifies local offload, stale-output clearing, reversible folding, full summary, and post-compact recovery.
- `memory-contract.md`: implements typed memory files, compact index, freshness warnings, and verify-before-trust rules.
- `tool-contract.md`: requires every tool to declare read/write/concurrency/result-budget/security semantics.
- `subagent-contract.md`: requires self-contained prompts, output schemas, and verification evidence.
- `plan-mode-contract.md`: defines read-only exploration, plan-file approval, and permission restoration.
- Tests that simulate oversized tool output, stale memory, compaction recovery, denied permissions, stop-hook blocking, and worker handoffs.

The central lesson is that context control is not one feature. It is the interaction of prompt stability, tool boundaries, memory retrieval, artifact persistence, compression, and workflow state.

## Reviewed Paths

- `README_EN.md` for repo purpose, architecture overview, key design claims, document map, metrics, contributor notes, changelog, and provenance claims.
- `en/README.md` for English site landing page structure and high-level design summary.
- `en/docs/quick-start.md` for the condensed agent-loop, context, tool, editing, security, hook, multi-agent, memory, skill, and minimal-component overview.
- `en/docs/01-overview.md` for controlled tool-loop framing, source directory map, data flow, startup phases, core design principles, and source-scale references.
- `en/docs/02-agent-loop.md` for QueryEngine versus query loop, loop state, streaming tool execution, feature gates, continue sites, error withholding, token tracking, and stop conditions.
- `en/docs/03-context-engineering.md` for request anatomy, system/user context assembly, CLAUDE.md discovery, message normalization, five-stage compression, token budgets, cache breakpoints, `system-reminder`, memory prefetch, and reactive compression.
- `en/docs/04-tool-system.md` for `Tool` interface shape, fail-closed defaults, tool assembly, runtime filtering, large result handling, MCP integration, lazy `ToolSearch`, and cache-aware sorting.
- `en/docs/05-code-editing-strategy.md` for search-and-replace editing, validation pipeline, uniqueness constraints, read-before-edit, external modification detection, atomic write section, worktree isolation, and LSP integration.
- `en/docs/06-hooks-extensibility.md` for hook event taxonomy, hook types, execution engine, JSON output schemas, trust model, PermissionRequest hooks, Stop hooks, async rewake, and skill/plugin hook layering.
- `en/docs/07-multi-agent.md` for subagent types, tool filtering, context isolation, fork subagents, coordinator mode, swarm backends, scratchpad, result delivery, worktree isolation, and plan-mode interactions.
- `en/docs/08-memory-system.md` for memory taxonomy, storage layout, index truncation, semantic recall, freshness and drift defenses, background extraction, team memory, agent memory, and injection paths.
- `en/docs/09-skills-system.md` for skill sources, lazy loading, `whenToUse`, token-budgeted skill listing, prompt substitution, inline/fork execution, MCP skill restrictions, skill persistence, and skill-level hooks.
- `en/docs/10-plan-mode.md` for plan-mode entry paths, attachment throttling, workflow variants, plan file management, approval, permission restoration, re-entry, and remote/fork recovery considerations.
- `en/docs/11-permission-security.md` for defense-in-depth layers, permission modes/rules, decision flow, racing permission handlers, Bash AST safety, dangerous path protection, sandboxing, prompt-injection defenses, environment variables, denial tracking, and PermissionRequest hooks.
- `en/docs/13-minimal-components.md` for the seven minimum coding-agent components and the contrast between minimal and production context/tool architecture.
- `en/docs/15-task-system.md` for file-backed task state, locks, high-water IDs, three-layer UI update detection, reminder injection, multi-agent claiming, verification nudges, hooks, and task prompt guidance.
- `docs/14-system-prompt-design.md` for system-prompt section taxonomy, static/dynamic boundary, dynamic sections, built-in agent prompt excerpts, Agent tool prompt guidance, coordinator prompt guidance, tool prompt catalog, and prompt assembly/cache boundary notes. The English file is a stub, so the Chinese original was reviewed for this chapter.
- `en/docs/reference.md` for quick-reference concepts, tool inventory, source entry points, and key threshold summary.
- Root navigation files (`_sidebar.md`, `en/_sidebar.md`, `_navbar.md`, `en/_navbar.md`) were checked to understand documentation structure and missing/incomplete translation paths.
- Git metadata was used only to record the reviewed commit and latest commit message.

## Excluded Paths

- `.git/**` was excluded as version-control metadata; the reviewed commit records source state.
- `assets/architecture.png`, `assets/kaibo.jpg`, and `assets/qq.jpg` were excluded from deep review as binary/image assets. The architecture image is reflected by adjacent README Mermaid/text content, so no unique context-control logic depended on image inspection.
- `index.html`, `_coverpage.md`, `_navbar.md`, `en/_navbar.md`, `_sidebar.md`, `en/_sidebar.md`, `.nojekyll`, `.gitattributes`, and `.gitignore` were excluded from substantive review as Docsify/static-site and repository packaging rather than context-control content.
- `LICENSE` was excluded as legal metadata.
- Chinese `docs/*.md` chapters other than `docs/14-system-prompt-design.md` were not deeply re-reviewed because the English `en/docs/*.md` mirrors cover the same content for the relevant architecture chapters. `docs/14-system-prompt-design.md` was included because the English counterpart is only a stub.
- No generated source, vendored dependencies, binaries beyond image assets, tests, scripts, schemas, or runtime implementation paths were present in the checkout.
