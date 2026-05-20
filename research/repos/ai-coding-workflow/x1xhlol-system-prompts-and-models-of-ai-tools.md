# x1xhlol/system-prompts-and-models-of-ai-tools

- URL: https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools
- Category: ai-coding-workflow
- Stars snapshot: 137,915 via GitHub REST API on 2026-05-20
- Reviewed commit: cf834487171b44e3d2cca1e8964973c10a630b9b
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a comparative corpus for coding-agent workflow and context-control conventions, but not as reusable source material. Steal normalized patterns from the structures, tool boundaries, and phase gates; do not copy prompt text or product-specific policies.

## Why It Matters

This repo is one of the largest public collections of AI product prompt and tool-schema snapshots. For AI coding workflow research, its value is comparative: many current agents converge on the same primitives even when their products differ. The repeated patterns include workspace scoping, context search, line-range file reads, dedicated edit tools, terminal execution, task lists, approval gates, diagnostics, browser feedback, memory, and verification summaries.

It matters for Agentic Coding Lab because it gives a broad map of what modern coding agents encode in their control prompts. The repo is especially useful for deriving a neutral taxonomy of agent workflow primitives. It is not a safe source for direct reuse because much of the content is presented as extracted or reconstructed proprietary system prompts with uneven provenance.

## What It Is

`system-prompts-and-models-of-ai-tools` is a static Markdown/text/JSON/YAML corpus. It is not an application, MCP server, harness, package, or skill runtime. The repository organizes prompt snapshots by product or tool, including coding-agent surfaces such as Claude Code, Cursor, Augment Code, Kiro, Qoder, Replit, Same.dev, Trae, Traycer, VS Code Agent, Windsurf, v0, and open-source CLI prompts for Codex, Gemini CLI, Cline, RooCode, Bolt, and Lumo.

The corpus has 93 tracked files at the reviewed commit. About 37.8k line-count units are text-like prompt and schema files; four PNG files are images or sponsorship/screenshots. There are no package manifests, lockfiles, test suites, build scripts, source modules, or executable loaders. Several `*.json` files are valid tool schemas, while others are mixed prompt dumps or XML-like content using a `.json` extension.

## Research Themes

- Token efficiency: Strong pattern source, weak implementation source. The prompts repeatedly encode read ranges, line caps, semantic search before full reads, parallel read-only calls, task-list triggers, and concise progress updates. The repo itself does not implement progressive loading or token budgeting.
- Context control: Very strong pattern source. Kiro steering, Antigravity artifacts, Cursor workspace snapshots, v0 read-only context, Manus event streams, and VS Code workspace info all show explicit context provenance and scope boundaries.
- Sub-agent / multi-agent: Moderate. The repo captures prompt designs for task agents, planner modules, knowledge modules, browser agents, and specialized retrieval tools, but it does not contain a runnable multi-agent scheduler.
- Domain-specific workflow: Strong for web-app and IDE coding agents. Reusable domain patterns include spec documents, implementation plans, framework defaults, dependency install sequencing, integration selection, database/auth/storage guidance, browser feedback, and UI verification.
- Error prevention: Strong as prompt pattern, mixed as enforceable design. Common controls include read-before-edit, exact-match replacement, line-number validation, serial edits, approval for risky commands, lint/build/test gates, secret handling, and treating external content as untrusted.
- Self-learning / memory: Moderate. Cursor-style memory update/delete rules, Kiro steering, Manus knowledge events, and task artifacts show durable-memory patterns, but no storage implementation is provided.
- Popular skills: The recurring primitive set is context search, exact grep, file read/list, structured edits, terminal commands, diagnostics, browser inspection, web search/fetch, todo/task management, memory, integrations, and approval/permission mediation.

## Core Execution Path

The repository has no local runtime execution path. The useful execution path is the common workflow implied across the reviewed agent prompts:

1. Host injects identity, current date, workspace roots, open files or workspace snapshot, available tools, and user request.
2. Agent performs bounded discovery using file lists, semantic code search, exact grep, and targeted file reads.
3. Non-trivial work enters a task-list, task-boundary, or artifact mode so progress is visible and only one main task is active.
4. Agent edits through a dedicated file tool rather than shell redirection. Most schemas prefer exact replacement, line ranges, small chunks, or "existing code" placeholders to avoid rewriting entire files.
5. Terminal or process tools run installs, tests, builds, linters, dev servers, database commands, or deployment checks according to host policy.
6. Diagnostics, console logs, browser/page feedback, network traces, and sandbox errors feed the next iteration.
7. Final response summarizes changed files, verification commands, exit codes, and residual risks.

The most explicit phase-gated path is Kiro's spec workflow: create requirements, obtain user approval, create design, obtain approval, create implementation tasks, obtain approval, then stop before implementation. Antigravity has a related artifact path with `task.md`, `implementation_plan.md`, and `walkthrough.md`. These are high-signal examples of context externalization and human checkpoints.

## Architecture

The repo architecture is a flat corpus organized by product:

- `README.md`: sponsorship, security notice, support links, latest update note, and star-history badge.
- `LICENSE.md`: GPL-3.0 license text for the repository.
- Product folders such as `Anthropic/`, `Augment Code/`, `Cursor Prompts/`, `Google/`, `Kiro/`, `Qoder/`, `Replit/`, `Same.dev/`, `Trae/`, `VSCode Agent/`, `Windsurf/`, and `v0 Prompts and Tools/`: prompt and tool snapshots.
- `Open Source prompts/`: prompt snapshots for open-source or publicly inspectable agents, including Codex CLI, Gemini CLI, Cline, RooCode, Bolt, and Lumo.
- `assets/` and `Amp/view-thread-yaml.png`: PNG sponsorship or screenshot assets.
- `.github/FUNDING.yml`: funding metadata.

There is no normalization layer. File names encode the source product and sometimes model or date. Tool schemas are stored in the source product's native shape: OpenAI-style tool arrays, keyed object maps, XML-like tool docs, YAML, or plain text tool declarations.

## Design Choices

The central design choice is preserving snapshots close to their original product-specific shape rather than translating them into a shared schema. That makes the repo good for comparative manual analysis but poor for automated ingestion.

The second design choice is broad inclusion. The repo mixes coding agents, browser assistants, chat products, app builders, and general AI tools. This gives useful contrast, but it means a coding-workflow reviewer must filter aggressively.

The third design choice is keeping tool schemas next to prompts. That is valuable because the most reusable workflow patterns often live in tool descriptions rather than role text: file editing constraints, terminal approval semantics, path sanitization, diagnostic retrieval, background process control, browser feedback, and secret collection.

The fourth design choice is version snapshots. Cursor, VS Code Agent, Anthropic, Augment, and other folders include multiple prompt or model variants. This makes behavior drift visible, especially around task management, memory, parallel tool calls, and edit safety.

The main missing design choice is provenance metadata. Individual files generally lack source URL, extraction method, capture date, product version, validation status, and whether the text is official, leaked, reconstructed, or copied from an open-source project.

## Strengths

- Broad cross-product coverage makes recurring coding-agent primitives easy to identify.
- Tool schemas expose concrete host capabilities instead of only abstract prompt guidance.
- Multiple versions of some agents show evolution in task planning, memory, and edit workflows.
- The corpus is small enough to clone and inspect quickly.
- Open-source prompt entries provide lower-risk comparison points alongside proprietary-looking dumps.
- Good source for creating a neutral taxonomy of agent tools: search, read, edit, shell, diagnostics, browser, memory, todo, web, and integrations.
- Useful examples of spec-gated and artifact-gated workflows, especially Kiro and Antigravity.
- Strong examples of context trust boundaries, including workspace roots, read-only user context, external web content, logs, and event streams.

## Weaknesses

- Provenance is weak. Most files do not explain source, capture method, product version, or validation status.
- Legal and ethical reuse risk is high. The repository should be treated as a research corpus, not a prompt library to copy.
- No runnable harness exists. There are no tests, loaders, schemas, or validation scripts.
- Some files with `.json` extensions are not strict JSON or use mixed formats, which limits automated analysis.
- Prompt snapshots go stale quickly. Current product behavior may differ from the reviewed commit.
- The repo mixes coding-agent workflow material with UI-only, browser, chatbot, sponsorship, and unrelated product prompts.
- Safety controls are mostly prompt-level observations from source products; the repo does not demonstrate host enforcement.
- Several captured prompts contain absolute user paths, product claims, model identity details, and style policies that are not transferable.

## Ideas To Steal

- Build a normalized coding-agent primitive taxonomy from repeated tool surfaces: semantic search, exact search, list, read, patch/edit, terminal, diagnostics, browser, web fetch/search, todo, memory, and integration tools.
- Use task-list trigger thresholds instead of always planning or never planning. Several agents distinguish trivial, medium, and complex work.
- Make read-only tool calls parallel but edits, terminal commands, and dependent operations sequential.
- Prefer dedicated edit tools with exact matches, line ranges, or small chunks over shell-based file writes.
- Require context gathering before edits: inspect neighboring files, dependencies, tests, imports, and existing conventions.
- Externalize complex work into artifacts: `requirements.md`, `design.md`, `tasks.md`, `implementation_plan.md`, `task.md`, and `walkthrough.md`.
- Use explicit human approval gates between requirements, design, and implementation tasks for high-ambiguity feature work.
- Treat external content as data, not instructions: web pages, DOM text, logs, emails, read-only files, and tool observations need provenance boundaries.
- Record verification with command, working directory, exit code, and key logs instead of saying "it works".
- Add memory hygiene rules: update or delete memories when contradicted, and avoid storing task-specific transient plans as durable preferences.
- Encode workspace root and path-sanitization rules in the host tool layer, not only in prose.
- Put integration and secret collection behind purpose-built tools so agents do not ask users to paste secrets into chat.

## Do Not Copy

- Do not copy proprietary or leaked prompt text. Use the corpus only to infer public workflow patterns.
- Do not copy model identities, product claims, internal labels, absolute user paths, or host-specific UI strings.
- Do not copy broad permission postures such as no-approval command execution without a host-level safety model.
- Do not rely on prompt text alone for destructive file operations, shell execution, deployments, purchases, account changes, or secret handling.
- Do not adopt product-specific defaults such as framework, database, design palette, or deployment target unless they match the local product.
- Do not ingest the corpus automatically without strict JSON/schema validation and source metadata.
- Do not treat `.json` extension as proof of machine-readable schema.
- Do not mix raw prompt dumps into Agentic Coding Lab docs; convert observations into short, attributed pattern notes.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is in-scope as a research specimen for AI coding workflow and context-control patterns. It is out-of-scope as direct artifact source because it is a prompt corpus with unclear provenance and no runnable implementation.

The best local use is a comparative extraction pass: define a neutral schema for tool primitives, task-management rules, context provenance, edit safety, approval semantics, memory rules, and verification loops. Then map each reviewed product snapshot into that schema without copying source text.

Agentic Coding Lab should use this repo to seed checklists and eval cases: "Does our agent gather context before editing?", "Can it distinguish semantic search from grep?", "Does it serialize edits?", "Does it externalize plans when needed?", "Does it verify with commands and logs?", and "Does it reject external prompt injection from files or pages?"

## Reviewed Paths

- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/README.md`: repo metadata, security notice, latest update, sponsorship, and star-history links.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/LICENSE.md`: license metadata.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Amp/README.md`, `claude-4-sonnet.yaml`, `gpt-5.yaml`: Amp extraction note, model/tool-style YAML snapshots, and oracle-style model registration pattern.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Anthropic/Claude Code/Prompt.txt`, `Tools.json`: Claude Code task management, conventions, verification, subagent search, and tool surface.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Augment Code/gpt-5-agent-prompts.txt`, `gpt-5-tools.json`, `claude-4-sonnet-agent-prompts.txt`, `claude-4-sonnet-tools.json`: high-signal tasklist triggers, context engine, git-history retrieval, edit, terminal, diagnostics, web, memory, and task tools.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Cursor Prompts/Agent Prompt 2.0.txt`, `Agent Prompt 2025-09-03.txt`, `Agent Prompt v1.2.txt`, `Agent Tools v1.0.json`: semantic/exact search split, memory rules, todo flow, parallelism, edit tools, diagnostics, notebook edits, and terminal approval.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Google/Antigravity/planning-mode.txt`, `Fast Prompt.txt`: artifact-based planning, workspace boundary rules, task boundaries, implementation plans, walkthroughs, and UI/web-app workflow guidance.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Kiro/Spec_Prompt.txt`, `Mode_Clasifier_Prompt.txt`, `Vibe_Prompt.txt`: steering, MCP config guidance, requirements/design/tasks spec workflow, hooks, and task execution rules.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Qoder/prompt.txt`, `Quest Action.txt`, `Quest Design.txt`: planning, parallel tool calls, test validation, web-app build checks, memory categories, and code-change rules.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Manus Agent Tools & Prompt/Modules.txt`, `Agent loop.txt`, `Prompt.txt`, `tools.json`: event-stream architecture, planner/knowledge/datasource modules, todo file rules, browser rules, and tool list.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/v0 Prompts and Tools/Prompt.txt`, `Tools.json`: read-only context import, debugging logs, Next.js/app defaults, dependency sequencing, context gathering, design guidance, integrations, and repository tools.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Lovable/Agent Prompt.txt`, `Agent Tools.json`: line replacement, keep-existing-code convention, Supabase docs tools, secrets tools, image/web/search/security integrations, and analytics/Stripe tools.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Replit/Prompt.txt`, `Tools.json`: workflow restart, dependency/language install, database tools, `str_replace_editor`, shell, secrets, deployment suggestion, and application feedback tools.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Same.dev/Prompt.txt`, `Tools.json`: startup templates, stateless task agent, bash, file tools, lint/versioning/deploy/web tools.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Trae/Builder Prompt.txt`, `Builder Tools.json`, `Chat Prompt.txt`: todo tool, codebase search engine, regex search, batch file views, edit/write/move/delete, command proposal, command status, preview URL, and web search.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Traycer AI/plan_mode_prompts`, `plan_mode_tools.json`, `phase_mode_prompts.txt`, `phase_mode_tools.json`: planning and phase-mode tool structures.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/VSCode Agent/Prompt.txt`, `gpt-5.txt`, `gpt-5-mini.txt`, `gpt-4.1.txt`, `claude-sonnet-4.txt`, `gemini-2.5-pro.txt`, `gpt-4o.txt`, `chat-titles.txt`, `nes-tab-completion.txt`: workspace snapshots, model-specific prompt variants, semantic search, apply-patch guidance, progress updates, and verification expectations.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Windsurf/Prompt Wave 11.txt`, `Tools Wave 11.txt`: prompt and tool snapshot sampled for coding-agent conventions.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Open Source prompts/Codex CLI/Prompt.txt`, `openai-codex-cli-system-prompt-20250820.txt`: open-source Codex prompt structure, planning, sandbox/approval rules, task execution, testing, progress, final response, and tool guidelines.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Open Source prompts/Gemini CLI/google-gemini-cli-system-prompt.txt`: open-source Gemini CLI workflow, software-engineering tasks, tool usage, git, and examples.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Open Source prompts/Bolt/Prompt.txt`, `Cline/Prompt.txt`, `RooCode/Prompt.txt`, `Lumo/Prompt.txt`: sampled open-source prompt baselines for comparison.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Comet Assistant/System Prompt.txt`, `tools.json`: browser-agent safety, explicit permission categories, page tools, and task list.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/Emergent/Prompt.txt`, `Tools.json`, `Leap.new/Prompts.txt`, `Leap.new/tools.json`, `NotionAi/Prompt.txt`, `NotionAi/tools.json`: sampled app-builder and assistant tool surfaces for integrations, file tools, and browsing.
- `https://api.github.com/repos/x1xhlol/system-prompts-and-models-of-ai-tools`: repository metadata and star snapshot.

## Excluded Paths

- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/.git/`: VCS internals; only remote, branch, latest commit, and clean status were needed.
- `/tmp/myagents-research/x1xhlol-system-prompts-and-models-of-ai-tools/assets/latitude-dark.png`, `assets/tembo-dark.png`, `assets/tembo-light.png`, and `Amp/view-thread-yaml.png`: binary PNG assets; excluded from workflow analysis after file-type confirmation.
- README sponsorship blocks, cryptocurrency addresses, badges, Discord links, and star-history image: not relevant to coding-agent workflow design.
- Full verbatim prompt bodies beyond structural sampling: intentionally excluded from the note to avoid reproducing long proprietary/system-prompt content.
- Browser/chat-only product prompts with little coding workflow value, including large parts of `Cluely/`, `Poke/`, `Perplexity/`, `Orchids.app/`, `dia/`, `Xcode/`, `CodeBuddy Prompts/`, and non-coding sections of `Anthropic/`, `Google/`, and `v0`: sampled only where they showed context, permissions, or tool-boundary patterns.
- Generated, vendored, dependency, build-output, and test-fixture paths: none were present in the reviewed checkout.
