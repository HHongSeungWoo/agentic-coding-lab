# asgeirtj/system_prompts_leaks

- URL: https://github.com/asgeirtj/system_prompts_leaks
- Category: ai-coding-workflow
- Stars snapshot: 40,484 via GitHub REST API on 2026-05-20
- Reviewed commit: 24a139b206be1046e107e02314a66ae980515351
- Reviewed at: 2026-05-20T21:43:49+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a current prompt-architecture corpus for comparing coding-agent workflow contracts, tool boundaries, memory/context layers, planning modes, and multi-agent shapes. Do not adopt or redistribute the raw prompt content; use only abstracted patterns and counterexamples.

## Why It Matters

This repo is one of the larger public collections of extracted system prompts, system messages, developer instructions, and tool descriptions for commercial AI assistants. Its relevance to Agentic Coding Lab is not the raw text. The value is that it exposes repeated design patterns across coding agents: how systems separate role, persona, tools, permissions, editing rules, work loops, memory, status updates, and final reporting.

For AI coding workflow research, it is best treated as a comparative anatomy dataset. A single repo shows Codex, Claude Code, Claude Desktop Code, Gemini CLI, Jules, Antigravity, Cursor, Copilot CLI, OpenCode, Amp, Warp, Zed, and other agent-like products using similar instruction blocks with different tradeoffs. That makes it useful for pattern mining, risk review, and "what not to copy" analysis.

The fit is conditional because the repo is a corpus, not a workflow implementation. It has no loader, benchmark, eval harness, provenance schema, permission runtime, or test suite for agent behavior. Some material may be stale, incomplete, unofficial, or legally sensitive. The safe research stance is to summarize structural patterns and avoid reproducing proprietary instructions.

## What It Is

`system_prompts_leaks` is a static Markdown collection organized by vendor and product:

- `Anthropic/`: Claude family prompts, including Claude Code, Claude Desktop Code, Claude Cowork, Claude Design, official-doc variants, raw variants, and older versions.
- `OpenAI/`: ChatGPT, API variants, tools, policies, and a focused `OpenAI/codex/` tree for Codex CLI and related modes.
- `Google/`: Gemini, Gemini CLI, Jules, Antigravity CLI, API variants, AI Studio, and related products.
- `Misc/`: coding and productivity agents including Cursor, Copilot CLI, OpenCode, Amp Code, t3-code, Warp, Zed, and others.
- `Perplexity/` and `xAI/`: smaller prompt sets for browser/search/chat assistants.

The reviewed checkout has 177 Markdown prompt files under the provider/product trees, plus a few non-Markdown prompt artifacts (`.xml`, `.json`, `.txt`). Total Markdown prompt corpus size is roughly 72,109 lines. The repository README acts as the index; `CONTRIBUTING.md` asks contributors to add raw prompts under the right vendor folder.

The only automation reviewed is `.github/workflows/traffic-to-badge.yml`, which collects GitHub traffic metrics and publishes badges. It is repository maintenance automation, not an agent workflow runtime.

## Research Themes

- Token efficiency: Strong as a pattern source. Several coding-agent prompts encode compact reading/search discipline, status-update rules, context minimization, subagent delegation for noisy work, and mode-specific brevity. The repo itself is token-heavy and should not be loaded wholesale.
- Context control: Strong as a comparative corpus. Repeated layers appear across agents: base identity, environment, user/project instructions, memory, tool schemas, mode overlays, and final-answer formatting. The best reusable pattern is explicit priority ordering and bounded context lookup.
- Sub-agent / multi-agent: Strong pattern coverage. Claude Code and Claude Desktop Code include task/subagent/team surfaces; Claude Cowork focuses on collaborative agents; Gemini CLI, Antigravity, Copilot CLI, Cursor, Amp, and Zed all contain delegation or side-agent concepts. Designs vary from simple task isolation to explicit team messaging and background context sidecars.
- Domain-specific workflow: Strong for AI coding workflows. The coding prompts repeatedly separate planning, implementation, review, browser/UI verification, git operations, shell commands, file edits, and PR/commit text generation.
- Error prevention: Strong pattern coverage but weak enforcement in this repo. The prompts emphasize dirty-worktree hygiene, permission/sandbox awareness, tool-call caution, source verification, security boundaries, and test/build verification. Because this repo is static text, none of these safeguards are executable here.
- Self-learning / memory: Moderate to strong as a prompt architecture theme. Codex and Claude Code examples include memory layers, memory lookup boundaries, persistence rules, and context resumption summaries. Copilot CLI includes memory-consolidation and continuation-summary prompt shapes. The repo has no own memory subsystem.
- Popular skills: Not a skill package. Reusable "skill-like" patterns are planning mode, code review mode, auto-review, source/research subagents, memory workers, task execution workers, UI/frontend guidance, and command/PR-generation prompt fragments.

## Core Execution Path

There is no application execution path. The repo's real path is contribution and consumption:

1. Contributor obtains a prompt and adds a `.md` file under the vendor/product folder.
2. README links the file under a provider table and highlights recently updated items.
3. Consumers browse the README, open relevant prompt files, and compare structures manually.
4. GitHub Actions updates traffic badges on a schedule.

For this deep review, the workflow path was:

1. Clone current `main` under `/tmp/myagents-research/asgeirtj-system_prompts_leaks`.
2. Record HEAD commit `24a139b206be1046e107e02314a66ae980515351`.
3. Read README, contribution rules, directory layout, file counts, and maintenance workflow.
4. Review coding-agent prompt structures from `Anthropic/claude-code.md`, `Anthropic/claude-desktop-code.md`, `Anthropic/claude-cowork.md`, `OpenAI/codex/*.md`, `Google/gemini-cli.md`, `Google/jules.md`, `Google/antigravity-cli.md`, and selected `Misc/` coding-agent prompts.
5. Exclude broad chatbot-only, media, generated badge, VCS, and UI-only/presentation material except where it clarified prompt architecture.

The notable execution insight is that modern coding-agent prompts tend to form a layered contract:

1. Identity and mission.
2. Collaboration style and persistence.
3. Engineering judgment and scope discipline.
4. Tool boundaries and permission model.
5. File-editing and shell-command rules.
6. Planning/review/special modes.
7. Memory/context-loading policy.
8. Verification and final-reporting rules.
9. Host-specific developer/app context.
10. User/project instruction overlay.

## Architecture

The repository architecture is intentionally simple:

- `README.md`: provider/product index, recent-update table, external press link, topic badges, and repository metadata.
- `CONTRIBUTING.md`: contribution rule: place raw prompt content in the right provider directory.
- `Anthropic/`: Claude prompt corpus, including coding, browser, office, design, official, raw, and old variants.
- `OpenAI/codex/`: Codex-focused prompt corpus, including per-model prompts, personality overlays, plan mode, and auto-review.
- `OpenAI/tool-*.md` and policy files: tool and policy prompt fragments useful for seeing tool-boundary wording.
- `Google/`: Gemini and Google coding-agent prompt corpus, including Gemini CLI, Jules, and Antigravity CLI.
- `Misc/`: other coding/productivity agents such as Cursor, Copilot CLI, OpenCode, Amp Code, Warp, Zed, and t3-code.
- `.github/workflows/traffic-to-badge.yml`: scheduled traffic badge generation.
- `.github/wapo-see-the-hidden-rules-behind-AI.jpeg`: media asset tied to README/press context.

There is no package manifest, test harness, schema, metadata database, prompt parser, provenance validator, or agent runtime. Prompt files are plain artifacts. This simplicity makes browsing easy but makes provenance, freshness, and safe reuse hard.

## Design Choices

The biggest design choice is curation by product/vendor rather than by workflow primitive. That makes the repo good for comparing products, but it requires manual synthesis to extract reusable coding workflow concepts such as planning mode, edit policy, test verification, memory, or subagent delegation.

The second design choice is preserving raw prompt files. This maximizes evidence fidelity for prompt researchers but creates a major reuse risk. Direct copying would import proprietary wording, stale product assumptions, and host-specific tool names. For Agentic Coding Lab, the right extraction layer is a short pattern note, not borrowed prompt text.

The third design choice is version accumulation. The corpus keeps multiple model/product versions, which helps compare drift across releases. The weakness is that versions are not normalized with a metadata header for source, capture date, confidence, authenticity, tool surface, or exact product build.

Across the coding-agent files, the strongest design pattern is modular prompt layering. Codex splits general instructions, frontend guidance, editing constraints, special user requests, user collaboration, formatting, permissions context, memory, and user instructions. Claude Code variants expose harness, text-output rules, memory, environment, tools, git/PR, and skill/tool discovery. Copilot CLI collects main prompt, conditional modes, continuation summaries, memory workers, sidekicks, and subagent definitions. Amp and Antigravity show explicit mode catalogs and artifact/report templates.

The fourth design pattern is mode separation. Plan mode, auto-review, autonomous mode, non-interactive mode, research orchestrator mode, and task-execution mode constrain what the agent may do, which tools it may use, and how it reports. This is more reusable than any single prompt phrase.

The fifth design pattern is tool-surface explicitness. Coding prompts list tools, when to use them, what arguments mean, and what not to do. Several prompts distinguish read/search tools from write/edit/shell tools, and some use side agents to keep verbose results out of the main context.

## Strengths

- Broad cross-agent coverage in one checkout: Codex, Claude Code, Claude Desktop Code, Gemini CLI, Jules, Antigravity, Cursor, Copilot CLI, OpenCode, Amp, Warp, Zed, and related assistants.
- Strong evidence of convergent coding-agent prompt architecture: identity, autonomy, engineering judgment, tool rules, edit rules, git hygiene, verification, and final report sections recur across products.
- Good source for planning-mode patterns: non-mutating discovery, intent clarification, implementation plan formatting, and transition rules from planning to execution.
- Good source for subagent/delegation patterns: task agents, research agents, review agents, memory workers, sidekick/background context agents, and team-style messaging.
- Useful memory/context examples: layered memory, lightweight lookup boundaries, continuation summaries, memory consolidation workers, and explicit stale-memory verification rules.
- Useful negative examples: large prompt dumps, tool-list overload, stale version names, unclear provenance, and product-specific assumptions show what should be abstracted away.
- Simple repository shape makes it easy to audit paths and exclude non-workflow material.

## Weaknesses

- Legal and ethical reuse risk is high. The repo's value is structural analysis, not prompt reuse.
- Provenance is inconsistent. Files do not consistently record capture method, source trust level, exact product build, or authenticity confidence.
- No machine-readable metadata. There is no schema for provider, product, date, model, tool surface, prompt layer, or relation between files.
- No executable harness. The repo cannot test whether any prompt rule changes agent behavior.
- No safety boundary. Static prompt text cannot enforce permissions, sandboxing, file writes, network access, or secrets handling.
- Product/version drift is unavoidable. The README says the corpus is updated regularly, but individual files can become stale quickly.
- Curation by vendor/product makes workflow synthesis manual and expensive.
- Some prompt files are very large. Loading broad files into an agent context can waste tokens and increase contamination risk.

## Ideas To Steal

- Build prompt architecture from explicit layers: identity, collaboration, engineering judgment, tool policy, edit policy, memory, verification, reporting, and user/project overlays.
- Treat planning mode as a separate contract: explore and clarify without mutating, then emit a concrete plan and require an explicit transition into execution.
- Define tool categories by risk: read/search, write/edit, shell, browser, network, memory, subagent, and user-question tools should have separate rules.
- Use subagents for noisy exploration, code review, research, test execution, and memory consolidation; keep synthesis in the main context.
- Add continuation-summary rules for long tasks so context compaction produces actionable resume state.
- Add memory lookup rules that decide when memory is relevant, how many search steps are acceptable, and when remembered facts must be reverified.
- Keep final-answer, commit-message, PR-description, and review-output templates separate from implementation instructions.
- Mine repeated cross-product sections into a neutral checklist for our own agent prompts instead of borrowing wording.

## Do Not Copy

- Do not copy raw proprietary/system-prompt content from this repo into Agentic Coding Lab.
- Do not treat leaked prompts as authoritative product documentation.
- Do not import product-specific model names, tool names, permission assumptions, or host UI behavior as durable rules.
- Do not use one giant prompt file as the default architecture; split reusable workflow into skills, modes, commands, and tool policies.
- Do not rely on prompt instructions for security if a sandbox, permission gate, hook, or test can enforce the rule.
- Do not load the whole corpus into context. Select a few files, extract structural features, then write an abstraction.
- Do not copy permissive autonomous-mode or non-interactive-mode instructions without explicit safeguards and verification requirements.
- Do not preserve stale memory or continuation summaries without a freshness boundary.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is in scope for `ai-coding-workflow` only as a prompt-architecture and workflow-pattern corpus. It is not a skill pack, MCP server, harness, eval framework, memory engine, or agent runtime.

Best use:

- Compare prompt section taxonomies across coding agents.
- Extract neutral design patterns for planning mode, review mode, memory, subagents, permissions, and verification.
- Identify unsafe prompt-only assumptions that Agentic Coding Lab should enforce with tools or tests.
- Build a small internal "coding-agent prompt architecture checklist" from repeated patterns.

Poor use:

- Copying prompt text.
- Treating the repo as a baseline prompt.
- Citing leaked content as official documentation.
- Loading many raw prompt files into active coding sessions.

Agentic Coding Lab should keep this note as a map of structural patterns and risks. Any adoption should be rephrased, host-neutral, and backed by executable checks where possible.

## Reviewed Paths

- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/README.md`: repository index, provider tables, recently updated entries, and high-level purpose.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/CONTRIBUTING.md`: contribution model and raw-prompt preservation rule.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/.github/workflows/traffic-to-badge.yml`: only local automation; badge/traffic maintenance, not agent runtime.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Anthropic/claude-code.md`: Claude Code prompt architecture, memory, environment, tools, git/PR, skills, and tool discovery.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Anthropic/claude-desktop-code.md`: desktop coding-agent task management, tool list, MCP/browser/preview tools, and PR workflow.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Anthropic/claude-cowork.md`: collaborative/multi-agent and browser/shell/artifact patterns.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Anthropic/claude-design.md`: UI/design-agent prompt layering sampled only for domain-specific frontend workflow structure.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/codex/gpt-5.5.md`: Codex layered instruction architecture, developer/user overlays, memory, permissions, collaboration, and formatting.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/codex/gpt-5.4.md`, `gpt-5.3-codex.md`, `gpt-5.2-codex.md`: sampled for version drift and stable Codex workflow sections.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/codex/plan_mode.md`: planning-mode contract and non-mutating workflow boundary.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/codex/codex-auto-review.md`: review-mode output and behavior specialization.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/codex/personality_pragmatic.md` and `personality_friendly.md`: thin persona overlays sampled as examples of style layers separate from workflow layers.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/OpenAI/tool-*.md`: sampled for tool-boundary and policy-fragment patterns, not copied.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Google/gemini-cli.md`: Gemini CLI coding workflow, context efficiency, subagent/skill surfaces, hooks, and operational rules.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Google/jules.md`: planning, AGENTS.md handling, bash/process rules, and merge-diff patterns.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Google/antigravity-cli.md`: subagent communication, conversation logs, artifact formatting, research-plan-execute-verify workflow, and task/plan templates.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/cursor.md`: tool surface, MCP/resource access, code references, git operations, skills, and transcripts.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/copilot-cli.md`: main prompt, conditional modes, research orchestration, continuation summaries, memory worker, and subagent definitions.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/opencode.md`: compact software-engineering workflow and operational guidelines.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/amp-code.md`: mode catalog, autonomy levels, task-list/subagent policies, and quality-bar sections.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/t3-code.md`: plan mode and generated text prompt fragments.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/warp-2.0-agent.md`: terminal-agent task, tool, coding, version-control, and output rules.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/Misc/zed.md`: coding-agent communication, tool use, diagnostics, debugging, external API, and multi-agent delegation patterns.
- `https://api.github.com/repos/asgeirtj/system_prompts_leaks`: star, fork, issue, pushed-at, license, topic, and repository metadata snapshot.

## Excluded Paths

- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/.git/`: VCS internals; used only to record HEAD commit and latest commit metadata.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/.github/wapo-see-the-hidden-rules-behind-AI.jpeg`: README/press media asset, not workflow architecture.
- Traffic badge outputs on the remote `traffic` branch: generated repository analytics artifacts, not reviewed locally.
- `/tmp/myagents-research/asgeirtj-system_prompts_leaks/LICENSE`, `.gitignore`, `.gitattributes`: legal/housekeeping metadata, not prompt architecture.
- Broad chatbot-only files under `xAI/`, `Perplexity/`, and non-coding `OpenAI/`, `Anthropic/`, `Google/`, and `Misc/` paths: excluded after sampling README/file layout because the task focus was AI coding workflow, not general assistant personality or safety policy.
- `Anthropic/raw/**`, `Anthropic/old/**`, `OpenAI/Old/**`, and older model/personality variants: sampled only where needed for version-drift awareness; not deeply reviewed because they duplicate higher-signal current coding-agent structures.
- `OpenAI/API/**` and `Google/*-api.md`: excluded except for tool-boundary contrast; API prompt variants are less relevant to interactive coding workflow.
- `Google/gemini-3.5-flash-tools.json`, `Anthropic/old/claude-3.7-sonnet-w-tools.xml`, and `OpenAI/Old/chatgpt-4o-mini.txt`: non-Markdown prompt artifacts; not central to structural coding-agent workflow.
- Product-specific UI/design-only prompts, office-app prompts, voice/browser assistant prompts, and education prompts: excluded unless they exposed reusable coding-agent architecture.
- No vendored dependency tree, generated source directory, local binary dependency, or runnable UI application was found in the reviewed checkout.
