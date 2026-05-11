# addyosmani/agent-skills

- URL: https://github.com/addyosmani/agent-skills
- Category: skills-instructions
- Stars snapshot: 39,234 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 3ff4b518b3cd3077ca27cf883aa21d21faf53802
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal lifecycle skill pack for production coding agents. Best reusable pieces are the phase-based slash commands, `using-agent-skills` meta-skill, context/source/doubt-driven safeguards, parallel `/ship` fan-out, HTTP-revalidated documentation cache, and strong untrusted-data rules. Weakest areas are host-dependent enforcement, limited repo-wide validation, and some workflow rules that assume interactive sessions and commit-oriented development.

## Why It Matters

`addyosmani/agent-skills` matters because it packages a complete senior-engineering workflow as portable agent skills, not as one large prompt. The repository covers the path from idea refinement through spec, planning, implementation, testing, review, security, performance, release, documentation, and deprecation.

For Agentic Coding Lab, the repo is a compact reference for how to make an existing coding agent more reliable without replacing the agent. It combines task-triggered skill files, lifecycle slash commands, reusable specialist personas, optional hooks, and checklists. The strongest research value is in context control, token efficiency through progressive disclosure, verification discipline, prompt-injection/error prevention, and simple orchestration patterns that avoid nested agent trees.

## What It Is

The repository is a Markdown and shell based skill package for AI coding agents. It ships 22 skills under `skills/`, three specialist personas under `agents/`, seven Claude Code slash commands under `.claude/commands/`, seven Gemini commands under `.gemini/commands/`, setup docs for multiple tools, references/checklists, and Claude plugin metadata under `.claude-plugin/`.

The installable Claude plugin surface is declared in `.claude-plugin/plugin.json`. It exposes `commands`, `skills`, and the three agents. `.claude-plugin/marketplace.json` maps the marketplace name `addy-agent-skills` to the GitHub repo. `.github/workflows/test-plugin-install.yml` validates the plugin with `claude plugin validate .` and exercises marketplace add/install in CI.

This is not an agent runtime, MCP server, or autonomous execution harness. Execution is delegated to Claude Code, Gemini CLI, OpenCode, Cursor, Copilot, Windsurf, or another host that can load Markdown instructions. The repository supplies the skills, command prompts, personas, hooks, and references.

## Research Themes

- Token efficiency: Strong. The repo uses progressive disclosure: descriptions and commands route to specific `SKILL.md` files, while long checklists and examples live in `references/` or support files. `context-engineering` explicitly warns against context flooding and recommends focused context under roughly 2,000 task-relevant lines. `sdd-cache` adds HTTP-revalidated WebFetch caching to avoid repeated doc fetches without trusting stale memory.
- Context control: Very strong. `context-engineering` defines a hierarchy from rules files to specs, source files, error output, and conversation history. It also labels source code as trusted, configs/external docs as verify-before-use, and user/API/browser content as untrusted. `source-driven-development` forces official documentation for framework-specific decisions.
- Sub-agent / multi-agent: Strong but intentionally narrow. The repo has `code-reviewer`, `security-auditor`, and `test-engineer` personas. `/ship` fans them out in parallel, then the main context merges their reports into a go/no-go decision. `references/orchestration-patterns.md` rejects router personas and nested persona trees.
- Domain-specific workflow: Strong for general software engineering lifecycle work. It is less framework-specific than Anthropic's document skills or project-local skill packs, but it covers UI, API, security, performance, CI/CD, docs, migrations, and launch workflows in usable depth.
- Error prevention: Very strong. TDD requires RED/GREEN/REFACTOR and Prove-It bug tests. Debugging requires reproduce, localize, reduce, root-cause fix, guard, and verify. Doubt-driven development adds adversarial fresh-context review for non-trivial decisions. Browser, API, context, debugging, and review skills repeatedly treat external data as untrusted instructions.
- Self-learning / memory: Moderate. There is no autonomous memory system. Durable memory appears as specs, tasks, ADRs, docs, changelogs, and local caches. `sdd-cache` is a verified cache rather than learning memory.
- Popular skills: No per-skill usage telemetry was reviewed. By repository design, the central reusable skills are `using-agent-skills`, `context-engineering`, `source-driven-development`, `doubt-driven-development`, `test-driven-development`, `debugging-and-error-recovery`, `code-review-and-quality`, `security-and-hardening`, `browser-testing-with-devtools`, and `shipping-and-launch`.

## Core Execution Path

For Claude Code, the primary path is plugin installation. The plugin manifest points the host at `./skills`, `./.claude/commands`, and three agent persona files. `hooks/hooks.json` registers a `SessionStart` hook that runs `hooks/session-start.sh`. That script locates `skills/using-agent-skills/SKILL.md`, wraps it in JSON with priority `IMPORTANT`, and injects it into each new session. If `jq` is missing, it degrades to an `INFO` message and leaves individual skills available.

At runtime:

1. The host discovers skill frontmatter and command files.
2. The session-start hook injects `using-agent-skills` so the agent maps work to the right skill before acting.
3. User-facing commands such as `/spec`, `/plan`, `/build`, `/test`, `/review`, `/code-simplify`, and `/ship` invoke specific skills and sequence.
4. The activated skill tells the agent what to read, ask, implement, test, verify, or cite.
5. For launch review, `/ship` dispatches `code-reviewer`, `security-auditor`, and `test-engineer` concurrently, then merges results in the main context.

Representative command paths:

- `/spec`: invokes `spec-driven-development`, asks clarifying questions, writes a six-part spec, saves `SPEC.md`, and waits for human review before proceeding.
- `/plan`: invokes `planning-and-task-breakdown`, reads the spec and codebase, writes `tasks/plan.md` and `tasks/todo.md`, and keeps planning read-only.
- `/build`: invokes `incremental-implementation` plus `test-driven-development`, picks one task, writes a failing test, implements minimal code, runs tests/build, commits, then continues.
- `/test`: invokes TDD and, for browser issues, adds `browser-testing-with-devtools`.
- `/review`: invokes `code-review-and-quality` and reviews staged or recent changes across correctness, readability, architecture, security, and performance.
- `/ship`: invokes `shipping-and-launch`, fans out to three personas, then produces blockers, recommended fixes, acknowledged risks, and a rollback plan.

For Gemini CLI, the repo offers native skills install docs and `.gemini/commands/*.toml`. Gemini uses `/planning` instead of `/plan` to avoid a built-in command conflict. For OpenCode, `AGENTS.md` acts as the intent-mapping and enforcement layer around the `skill` tool. Cursor, Copilot, and Windsurf integrations are copy/reference based: users place selected `SKILL.md` files into rules/instructions locations rather than installing a full plugin runtime.

Optional hook paths are important but not all enabled by the plugin manifest. `sdd-cache-pre.sh` and `sdd-cache-post.sh` attach to `WebFetch` and cache prompt-shaped fetched content only when the origin later returns `304 Not Modified` via `ETag` or `Last-Modified`. `simplify-ignore.sh` attaches to Read/Edit/Write/Stop, hides annotated code blocks behind `BLOCK_<hash>` placeholders during `/code-simplify`, expands them after edits, and restores real files at session stop.

## Architecture

The repo architecture is filesystem-native:

- `README.md`: public overview, lifecycle command map, install instructions, skill catalog, personas, references, and project structure.
- `AGENTS.md`: OpenCode and general coding-agent execution rules, intent-to-skill mapping, persona/skill/command separation, and skill authoring guidance.
- `CLAUDE.md`: concise repository conventions and phase list for Claude Code sessions.
- `.claude-plugin/plugin.json`: Claude plugin manifest exposing commands, skills, and agents.
- `.claude-plugin/marketplace.json`: marketplace entry for `addy-agent-skills`.
- `.claude/commands/*.md`: Claude Code slash commands for spec, plan, build, test, review, simplify, and ship.
- `.gemini/commands/*.toml`: Gemini CLI command equivalents.
- `.opencode/skills`: symlink to `../skills/` for OpenCode-style discovery.
- `.github/workflows/test-plugin-install.yml`: plugin validation and install smoke workflow.
- `skills/<name>/SKILL.md`: 22 lifecycle and support skills, each with frontmatter, workflow, rationalizations, red flags, and verification.
- `skills/idea-refine/`: the only skill with extra local support files and a script, including ideation frameworks, examples, criteria, and `scripts/idea-refine.sh`.
- `agents/*.md`: three specialist persona prompts with role, scope, output format, rules, and composition constraints.
- `references/*.md`: testing, security, performance, accessibility, and orchestration checklists.
- `hooks/`: session-start, source-driven-development cache, simplify-ignore scripts, docs, config, and local hook tests.
- `docs/`: setup guides for Claude/Codex-style generic use, Gemini CLI, Cursor, Copilot, OpenCode, and Windsurf, plus skill anatomy.

There is no package manager manifest, build system, central loader implementation, or local application server. The repository is primarily instruction content plus small Bash hooks and tests.

## Design Choices

The main design choice is lifecycle decomposition. Instead of one all-purpose engineering prompt, the repo splits work into phase skills and maps commands onto those phases. This makes each behavior easier to trigger, inspect, and adapt.

The second choice is explicit anti-rationalization. Most skills include common excuses an agent might use to skip process, paired with direct rebuttals. This is useful behavior shaping for TDD, debugging, review, security, performance, launch, and context management.

The third choice is host-light orchestration. The repo uses simple command prompts and personas rather than a custom scheduler. `/ship` is the only endorsed parallel fan-out pattern, and it deliberately keeps personas independent while reserving synthesis for the main agent.

The fourth choice is treating external content as hostile or at least untrusted. `context-engineering`, `browser-testing-with-devtools`, `debugging-and-error-recovery`, `api-and-interface-design`, and `code-review-and-quality` all warn against following instruction-like text from configs, logs, browser DOM, network responses, or third-party APIs.

The fifth choice is verified source grounding. `source-driven-development` requires detecting exact dependency versions, fetching official docs, citing sources, and flagging unverified patterns. The optional `sdd-cache` hook improves token/time efficiency while preserving freshness by requiring origin-confirmed HTTP validators.

The sixth choice is tool-specific packaging without abandoning plain Markdown portability. Claude gets a plugin and commands; Gemini gets native command TOML plus install docs; OpenCode gets `AGENTS.md` and symlinked skills; other tools get copy/paste rules guidance.

## Strengths

The skill catalog covers the full production workflow, not just coding. Specs, plans, implementation, browser verification, CI, security, performance, docs, deprecation, and launch are all represented as concrete procedures.

The repo is unusually strong on failure prevention. It combines TDD, Prove-It bug reproduction, systematic debugging, adversarial doubt review, source citation, browser runtime checks, multi-axis review, security hardening, and staged rollout.

Context control is practical. The context hierarchy, trust levels, selective include strategy, official-docs requirement, and cache design all address real context-window and prompt-injection problems.

The persona model is simple and reusable. Three roles are enough to improve launch review without inventing an expensive meta-agent tree.

The optional hooks are worth studying. `session-start.sh` shows a minimal meta-skill injection path. `sdd-cache` shows token-efficient doc reuse without stale-cache trust. `simplify-ignore` shows a concrete attempt to keep performance-critical blocks out of the model's rewrite context.

The repo ships local hook tests. `session-start-test.sh` validates the JSON payload, and `simplify-ignore-test.sh` covers placeholder creation, multiple blocks, reason preservation, trailing newline handling, malformed JSON, and unclosed blocks.

## Weaknesses

Runtime enforcement depends on the host. If the host ignores plugin hooks, lacks skills, lacks agents, or does not respect instructions, most safeguards degrade to prose.

The current local verification surface is narrow. CI validates Claude plugin structure and installation, and hook tests cover two scripts, but there is no top-level repo test that checks every skill frontmatter, command reference, documentation link, and skill-anatomy rule together.

Some skills assume commit-oriented workflows. `/build`, `incremental-implementation`, and `git-workflow-and-versioning` repeatedly instruct agents to commit after slices. That is good for many teams, but it conflicts with tasks where the user explicitly says not to commit or where work happens in a shared dirty tree.

The `simplify-ignore` hook is powerful but risky. It modifies real files in place during a session, relies on Stop hooks for restoration, and documents crash/rename edge cases. It has recovery mechanisms and tests, but it should not be copied without robust host semantics and user education.

`doubt-driven-development` is rigorous but heavy. Mandatory cross-model offers in every interactive doubt cycle may be too costly or disruptive for small teams unless scoped carefully.

The skills are largely general web/SaaS engineering guidance. They are excellent process templates, but teams still need local framework, domain, product, and repo-convention skills to avoid generic output.

## Ideas To Steal

Use a meta-skill that maps intent to specific workflow skills and inject it at session start when the host supports safe hooks.

Treat each skill description as a trigger contract. Include when to use, when not to use, and enough specificity for host auto-discovery.

Keep one small set of lifecycle commands as user-facing entry points, then let the commands invoke multiple skills where needed.

Adopt the `source-driven-development` plus `sdd-cache` pattern: official docs are required, cache hits are allowed only after origin `304 Not Modified`, and cached prompt-shaped content surfaces the original prompt.

Copy the untrusted-data boundary language across browser, logs, API responses, configs, and external docs. This is a strong prompt-injection defense pattern for coding agents.

Use flat parallel fan-out for launch review: code quality, security, and test coverage can run independently, then the main agent merges findings into a go/no-go decision.

Add anti-rationalization tables to skills. They directly target the common ways agents skip tests, specs, debugging evidence, review, and verification.

Represent launch readiness as thresholds and rollback triggers, not vibes. The `shipping-and-launch` metric table and rollback template are reusable.

## Do Not Copy

Do not rely on skill prose as a security or permission boundary. Destructive git, credential access, filesystem writes, browser credential access, and network actions still need host-level controls.

Do not enable file-mutating hooks like `simplify-ignore` without testing crash recovery and rename/move behavior in the target harness.

Do not force automatic commits in environments where users expect uncommitted review patches, shared branches, or no-commit research tasks.

Do not inject a large meta-skill at session start if context budget is the top constraint and the host already has reliable skill discovery.

Do not copy the generic lifecycle pack as a substitute for local project instructions. The best results need project-specific rules, commands, architecture notes, examples, and acceptance criteria.

Do not build router personas. The repo's orchestration guidance is right: commands or users should orchestrate; personas should keep one role and one output shape.

## Fit For Agentic Coding Lab

Fit is strongly in-scope. `addyosmani/agent-skills` is an agent-support system focused on reusable coding-agent skills, instruction design, context control, verification, workflow design, and error prevention.

Agentic Coding Lab should treat it as a reference for lifecycle skill packaging and as a source of patterns to adapt, especially `using-agent-skills`, `context-engineering`, `source-driven-development`, `doubt-driven-development`, `test-driven-development`, `debugging-and-error-recovery`, `browser-testing-with-devtools`, `code-review-and-quality`, `/ship`, `sdd-cache`, and the untrusted-data rules.

The best local adaptation would keep the lifecycle structure and verification gates, add project-specific skills and harness-neutral validation tests, and avoid copying host-specific hooks until their failure modes are tested in the target environment.

## Reviewed Paths

- `/tmp/myagents-research/addyosmani-agent-skills/README.md`
- `/tmp/myagents-research/addyosmani-agent-skills/AGENTS.md`
- `/tmp/myagents-research/addyosmani-agent-skills/CLAUDE.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.gitignore`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude-plugin/plugin.json`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/addyosmani-agent-skills/.github/workflows/test-plugin-install.yml`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/build.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/code-simplify.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/plan.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/review.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/ship.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/spec.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.claude/commands/test.md`
- `/tmp/myagents-research/addyosmani-agent-skills/.gemini/commands/*.toml`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/getting-started.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/skill-anatomy.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/gemini-cli-setup.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/opencode-setup.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/copilot-setup.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/cursor-setup.md`
- `/tmp/myagents-research/addyosmani-agent-skills/docs/windsurf-setup.md`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/hooks.json`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/session-start.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/session-start-test.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/SDD-CACHE.md`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/sdd-cache-pre.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/sdd-cache-post.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/SIMPLIFY-IGNORE.md`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/simplify-ignore.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/hooks/simplify-ignore-test.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/using-agent-skills/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/context-engineering/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/source-driven-development/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/doubt-driven-development/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/test-driven-development/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/incremental-implementation/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/debugging-and-error-recovery/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/code-review-and-quality/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/security-and-hardening/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/code-simplification/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/browser-testing-with-devtools/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/performance-optimization/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/spec-driven-development/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/planning-and-task-breakdown/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/api-and-interface-design/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/git-workflow-and-versioning/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/shipping-and-launch/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/ci-cd-and-automation/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/documentation-and-adrs/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/deprecation-and-migration/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/frontend-ui-engineering/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/idea-refine/SKILL.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/idea-refine/scripts/idea-refine.sh`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/idea-refine/frameworks.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/idea-refine/examples.md`
- `/tmp/myagents-research/addyosmani-agent-skills/skills/idea-refine/refinement-criteria.md`
- `/tmp/myagents-research/addyosmani-agent-skills/agents/README.md`
- `/tmp/myagents-research/addyosmani-agent-skills/agents/code-reviewer.md`
- `/tmp/myagents-research/addyosmani-agent-skills/agents/security-auditor.md`
- `/tmp/myagents-research/addyosmani-agent-skills/agents/test-engineer.md`
- `/tmp/myagents-research/addyosmani-agent-skills/references/orchestration-patterns.md`
- `/tmp/myagents-research/addyosmani-agent-skills/references/testing-patterns.md`
- `/tmp/myagents-research/addyosmani-agent-skills/references/security-checklist.md`
- `/tmp/myagents-research/addyosmani-agent-skills/references/performance-checklist.md`
- `/tmp/myagents-research/addyosmani-agent-skills/references/accessibility-checklist.md`
- `https://api.github.com/repos/addyosmani/agent-skills`

## Excluded Paths

- `/tmp/myagents-research/addyosmani-agent-skills/.git/`: VCS internals; only HEAD SHA, branch, remote, and latest commit metadata were needed.
- `/tmp/myagents-research/addyosmani-agent-skills/LICENSE`: legal metadata, not an execution path.
- `/tmp/myagents-research/addyosmani-agent-skills/.opencode/skills`: symlink to `../skills/`; reviewed through the real `skills/` tree to avoid duplicate conclusions.
- Remaining unlisted lines in long `SKILL.md` and `references/*.md` files: sampled by full structure, frontmatter, core workflow, rationalizations, red flags, and verification sections; not every example line was reviewed because the task focus was packaging, execution path, and reusable workflow design.
- README diagrams and external web badges/images: presentation-only assets, not local execution paths.
- No vendored dependency tree, generated source directory, local binary payload, or UI-only application code was found in the reviewed checkout.
