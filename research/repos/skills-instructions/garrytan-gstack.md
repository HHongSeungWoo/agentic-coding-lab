# garrytan/gstack

- URL: https://github.com/garrytan/gstack
- Category: skills-instructions
- Stars snapshot: 93,605 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 49cc4ff9c99e9b24f39aa7dcbfc456e840be29a8
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for skills-as-process, installable agent environments, browser-backed QA, cross-model review, and self-improving workflow state. Best ideas are the generated skill/template system, persistent browser daemon, review/ship gates, host adapters, and explicit safety hooks; main caution is that the system is large, prompt-heavy, and mixes instruction artifacts with many local executables and side-effecting setup paths.

## Why It Matters

`garrytan/gstack` is not just a prompt pack. It is a full AI coding workbench: dozens of `SKILL.md` workflows, a generated documentation system, a persistent Chromium daemon, host-specific skill packaging, review and ship gates, browser-skill runtime scripts, safety hooks, telemetry, and memory/GBrain integration.

For Agentic Coding Lab, it is a useful extreme case. It shows what happens when agent instructions are treated like product code: generated from templates, tested, evaluated with real model runs, installed into multiple coding hosts, and backed by local runtime utilities. The repo is especially relevant to skills/instructions, installable coding environments, error prevention, token/context control, multi-agent browser sharing, and memory loops.

## What It Is

The repository provides gstack, "Garry's Stack": a set of AI coding skills and local tools intended to make Claude Code and related coding agents behave like a structured engineering team. Skills cover product office hours, CEO review, engineering review, design review, DX review, autoplan, code review, QA, shipping, deployment, canary checks, security audits, retros, memory, browser use, remote-agent pairing, and safety modes.

The core repo shape is:

- Markdown skills in top-level directories such as `office-hours/`, `plan-ceo-review/`, `plan-eng-review/`, `review/`, `qa/`, `ship/`, `careful/`, and `freeze/`.
- `.tmpl` template sources plus generated `SKILL.md` files consumed by agents at runtime.
- `scripts/gen-skill-docs.ts` and `scripts/resolvers/` for shared preamble, review, design, DX, testing, GBrain, and host-specific resolver content.
- `hosts/*.ts` declarative configs for Claude, Codex, Factory, Kiro, OpenCode, Slate, Cursor, OpenClaw, Hermes, and GBrain output variants.
- `setup` for building binaries and linking skills into host-specific directories.
- `browse/src/` for the persistent browser daemon, command registry, token model, tunnel/pairing, browser-skill runtime, prompt-injection defenses, and path security.
- `test/` and `browse/test/` for static validation, unit tests, browser integration tests, and paid E2E/model evals.

## Research Themes

- Token efficiency: Mixed but instructive. The repo uses tiered preambles, resolver suppression, host-specific outputs, generated `gstack/llms.txt`, lazy loading of reference docs, and subagents to isolate large audits. It also ships very large generated skill files and accepts 25K-40K token workflows as a deliberate quality tradeoff.
- Context control: Strong. Templates centralize shared preamble and workflow sections, `{{INVOKE_SKILL}}` loads other skills with skip lists, plan-mode semantics are explicit, and browser content is wrapped in untrusted envelopes.
- Sub-agent / multi-agent: Strong. `/review`, `/ship`, `/autoplan`, and `/codex` use Claude subagents and Codex outside voices; `/pair-agent` exposes a scoped browser tunnel for other agents with tab ownership, setup keys, rate limits, and command allowlists.
- Domain-specific workflow: Strong. The repo encodes product, engineering, design, DX, QA, release, SRE, and security workflows as separate specialists with artifacts and gates.
- Error prevention: Very strong. Safety hooks catch destructive shell/edit actions, review gates target race/security/completeness failures, QA mandates browser evidence and regression tests, and ship re-runs tests/reviews/version/changelog/backlog/doc checks.
- Self-learning / memory: Strong but complex. Local JSONL learnings, timelines, builder profiles, domain skills, context save/restore, and GBrain sync/search all feed future sessions.
- Popular skills: The most reusable patterns are `/office-hours`, `/autoplan`, `/plan-eng-review`, `/review`, `/qa`, `/ship`, `/codex`, `/careful`, `/freeze`, `/pair-agent`, `/learn`, and `/sync-gbrain`.

## Core Execution Path

The install path starts in `setup`. It checks Bun, resolves install/source directories, parses host/prefix/team flags, builds the browse/design/make-pdf binaries when stale, generates host-specific skill docs, ensures Playwright Chromium exists, creates `~/.gstack`, and links skill directories into the target host's skill directory.

For Claude, setup creates top-level skill directories containing `SKILL.md` symlinks back into the gstack checkout. For Codex, it generates `.agents/skills/gstack-*` from templates, builds a minimal `~/.codex/skills/gstack` runtime root, and avoids exposing the whole source tree to recursive skill discovery. Factory and OpenCode have similar generated-skill linking paths. Kiro is handled by copy/sed path rewriting. OpenClaw, Hermes, and GBrain are treated mostly as methodology/artifact targets rather than normal setup installs.

At runtime, a user invokes a skill such as `/autoplan`, `/review`, `/qa`, or `/ship`. The generated `SKILL.md` begins with the shared preamble: update check, session tracking, config reads, repo mode, telemetry state, learnings search, timeline logging, routing checks, vendoring checks, checkpoint mode, and plan-mode rules. Tier 2+ skills also get AskUserQuestion formatting, context recovery, writing style, completeness, confusion protocol, continuous checkpoints, and context health. Tier 3+ skills add repo-mode/search-before-building guidance.

The key workflow path is:

1. `/office-hours` produces a design doc by asking forcing product/builder questions and saving artifacts under `~/.gstack/projects/<slug>/`.
2. `/autoplan` reads review skill files from disk and runs CEO -> design -> engineering -> DX review sequentially, auto-deciding intermediate choices by six decision principles while surfacing taste/user-challenge decisions at the final gate.
3. Implementation happens in the base coding agent, informed by the reviewed plan.
4. `/review` checks the diff against the base branch, reads checklists, runs scope drift, Greptile triage, slop scan, code review, adversarial subagents/Codex, fix-first auto-fixes, and review logging.
5. `/qa` finds a local/staging app, drives the browser daemon, documents issues immediately, fixes approved bugs, adds regression tests, and re-verifies.
6. `/ship` merges the base branch, bootstraps tests if missing, runs tests/evals, audits coverage via subagent, audits plan completion, runs review/design/adversarial passes, bumps version, updates changelog/backlog/docs, commits, pushes, and creates or updates a PR.

The browser execution path is separate but central. A `$B` command invokes the compiled browse CLI, which reads `.gstack/browse.json`, health-checks or starts a Bun server, and POSTs to `/command` with a bearer token. The server dispatches to read/write/meta commands against a persistent Playwright Chromium session. Page-content commands are wrapped as untrusted content; scoped tokens get extra hidden-content, ARIA, URL-blocklist, datamarking, and domain/rate/tab checks.

## Architecture

The architecture has three layers.

The instruction layer is Markdown-first. Human-authored `.tmpl` files contain workflow prose and placeholders. `scripts/gen-skill-docs.ts` discovers templates, extracts frontmatter, resolves placeholders through `scripts/resolvers/index.ts`, transforms frontmatter for each host, rewrites paths/tool names, emits host-specific `SKILL.md`, and optionally writes Codex `agents/openai.yaml` metadata. Generated files include an auto-generated header and are freshness-checked in CI.

The local runtime layer is Bun/TypeScript plus shell helpers. `package.json` builds compiled browse, design, make-pdf, and discovery binaries. `browse/src/server.ts` owns the daemon, tokens, routes, tunnel listener, activity/audit logs, and command dispatch. `browse/src/commands.ts` is the single command registry used by runtime and docs. Shared helpers enforce path security, file permissions, proxy redaction, token scope, domain skill storage, browser skill spawning, and content security.

The packaging layer is host-aware. `hosts/*.ts` define global roots, local roots, generated subdirectories, frontmatter behavior, path rewrites, resolver suppressions, runtime assets, linking strategies, co-author trailers, and host boundary instructions. Tests assert host config uniqueness and generated output properties. There is a stated goal of adding hosts by config rather than generator code changes, although the `setup` script still hardcodes much of the install branching.

Evaluation is treated as first-class. Static tests validate `$B` commands in generated skill docs against the command registry, snapshot flags, generated freshness, hook scripts, security gates, host configs, and browser commands. Paid evals use `claude -p` stream-json subprocess runs, LLM judges, touchfile-based selection, cost tracking, and GitHub Actions matrix jobs.

## Design Choices

The biggest design choice is "workflow roles as executable skills." Each skill is a specialist with a concrete job, required reads, artifact writes, gates, stop conditions, and completion status protocol. The repo does not rely on generic "be careful" guidance; it decomposes engineering process into named roles and reusable resolver blocks.

The second choice is generated instructions. Shared behaviors such as preamble, AskUserQuestion shape, review dashboard, test bootstrap, design methodology, Codex outside voice, GBrain context load, and QA methodology are generated from code. That reduces drift and lets host-specific variants suppress or rewrite sections.

The third choice is local environment installation rather than pure prompts. gstack creates real skill directories, compiled CLIs, browser daemon state, local analytics, review logs, learnings, and optional hooks. This makes skills more reliable but increases install and maintenance surface.

The fourth choice is browser persistence. A long-lived daemon avoids 3-5 second cold starts and preserves cookies/tabs/localStorage across commands. Command refs use Playwright locators rather than DOM mutation, and the daemon auto-restarts on version mismatch.

The fifth choice is layered security around agent/browser interaction. The repo uses localhost binding, bearer tokens, scoped tokens, dual local/tunnel listeners, tunnel command allowlists, root-token rejection on tunnel, temp-only file serving, realpath path validation, untrusted envelopes, hidden-element detection, CDP default-deny allowlist, canary tokens, and classifier bench tests.

The sixth choice is compounding memory. `/learn`, preamble learnings search, domain skills, GBrain context load/save, sync-gbrain, and transcript ingestion all try to preserve operational context. New domain skills start quarantined and require successful use before activation; global promotion is explicit.

## Strengths

The repo has unusually concrete execution paths for a skills repository. Setup, generation, runtime command dispatch, tests, evals, hooks, and memory paths are all present in source, not only described in README marketing.

The template/resolver system is a strong pattern for large instruction systems. It lets maintainers tune shared behavior once and emit variants for multiple host constraints, while tests prevent stale generated docs and command drift.

The browser daemon is a meaningful agent capability multiplier. It gives coding workflows real UI verification, screenshots, authenticated sessions, command chaining, snapshots with refs, browser skills, and remote agent pairing.

The error-prevention posture is deep. `/review` targets non-obvious production bugs, `/ship` refuses to skip verification on reruns, `/qa` requires bug evidence and regression tests, `/investigate` forbids fixes before root cause, and `/careful`/`/freeze` add tool hooks where the host supports them.

The multi-agent design is practical. Cross-model reviews include filesystem boundary prompts so Codex does not recursively follow Claude skill files, and `/pair-agent` uses scoped tokens and tab ownership instead of sharing the root browser token.

The repo tests instruction quality as code. Static tests, source-level security contract tests, browser E2Es, security benches, and LLM-as-judge fixtures are all relevant to Agentic Coding Lab's goal of making agent support systems measurable.

## Weaknesses

The system is heavy. Many generated skills are long, the preamble performs many side effects, and the repo accepts large context costs. This may be reasonable for high-value workflows, but it is not a minimal pattern to copy wholesale.

The install surface is broad. Setup installs dependencies, builds binaries, writes to `~/.gstack`, links skills, mutates host config, runs migrations, may install Playwright Chromium, and can register team hooks. That is powerful but raises support and trust costs for users.

Host support is not as clean as the host config abstraction suggests. `hosts/` includes Cursor and Slate configs and docs say setup/tooling read configs, but `setup` still explicitly accepts only Claude, Codex, Kiro, Factory, OpenCode, auto, plus special OpenClaw/Hermes/GBrain exits. This creates risk that docs/configs get ahead of install reality.

Some safety mechanisms are advisory or host-dependent. `/freeze` blocks Edit/Write through hooks, but its own note admits Bash can still modify files outside the boundary. `/careful` catches common destructive patterns, not arbitrary destructive scripts.

Memory and telemetry require careful privacy handling. The repo documents opt-in telemetry and secret scanning, but several features write local JSONL and can sync or ingest transcripts. The `gstack-memory-helpers.ts` secret scanner warns and returns `scanner:"missing"` when `gitleaks` is absent, so fail-closed behavior depends on callers.

The browser security model is thoughtfully layered, but the attack surface is large: persistent browser state, cookie import, local HTTP server, extension, tunnel, scoped tokens, browser-skill scripts, CDP allowlist, and domain-skill prompt injection all need ongoing maintenance.

## Ideas To Steal

Treat skills as generated, tested artifacts. Use templates for human workflow prose and resolvers for shared, source-backed command references, host paths, safety blocks, and review gates.

Use tiered preambles. Small utility skills should not pay the same context tax as ship/review/QA workflows.

Keep a single command registry that feeds runtime dispatch, docs, parser validation, and generated reference material.

Build host adapters declaratively: frontmatter transforms, path rewrites, resolver suppressions, runtime asset lists, and co-author/boundary text per host.

Use fix-first review classification. Separate mechanical auto-fixes from judgment-required ASK items, and require evidence before claiming patterns are safe or handled elsewhere.

Use a persistent browser daemon for QA and design review. Real screenshots, console errors, responsive checks, and interaction refs make agent QA much less speculative.

Use scoped remote-agent browser tokens with tab ownership and command allowlists. Do not share the root browser token with paired agents.

Quarantine agent-authored memory before it auto-fires. Domain skills' quarantined -> active -> global state machine is a good pattern for prompt-injection-aware self-learning.

Use real eval artifacts for skill quality: command extraction, generated doc freshness, E2E transcripts, LLM judge fixtures, and cost/turn tracking.

## Do Not Copy

Do not copy the whole preamble into every skill. Pull only the sections needed for the risk level; otherwise startup cost and behavioral noise will dominate.

Do not treat Markdown instructions as enforcement. Safety hooks and browser token scopes help, but actual security boundaries need OS/process/filesystem controls.

Do not let setup scripts grow host-specific branches after creating a declarative config system. If the abstraction is "add one host config," the installer should consume that same config.

Do not sync or ingest user transcripts without a clear privacy gate, secret scanner policy, and per-repo trust model. Local JSONL is safer than remote sync by default.

Do not expose a browser tunnel without physical surface separation or an equivalent hard boundary. Header/origin checks alone are weaker than the dual-listener pattern used here.

Do not use Codex/other-model outside voices without a boundary instruction that prevents the model from reading and executing the skill system itself.

Do not assume "more review passes" always helps. `/autoplan` and `/ship` are useful for big work, but small patches need a thinner path.

## Fit For Agentic Coding Lab

Fit is in-scope and strong. gstack is one of the richest examples of an agent-support system built above existing coding agents. It combines skill instructions, installable runtime, generated docs, verification gates, multi-agent support, browser tooling, and memory.

Agentic Coding Lab should use it as a reference for:

- Generated skill pipelines with host-specific outputs.
- Long-running local tools that give agents better perception and verification.
- Review/QA/ship workflows that encode error-prevention discipline.
- Skill eval harnesses that measure whether instructions actually work.
- Scoped browser sharing and tab isolation for multi-agent coordination.
- Prompt-injection-aware memory/domain-skill lifecycle design.

The main adaptation should be smaller and more modular. Copying gstack whole would import too much process, state, and install surface. The better path is to extract specific patterns into narrow skills and pair each with lightweight verification.

## Reviewed Paths

- `/tmp/myagents-research/garrytan-gstack/README.md`
- `/tmp/myagents-research/garrytan-gstack/AGENTS.md`
- `/tmp/myagents-research/garrytan-gstack/CLAUDE.md`
- `/tmp/myagents-research/garrytan-gstack/CONTRIBUTING.md`
- `/tmp/myagents-research/garrytan-gstack/ARCHITECTURE.md`
- `/tmp/myagents-research/garrytan-gstack/docs/skills.md`
- `/tmp/myagents-research/garrytan-gstack/docs/OPENCLAW.md`
- `/tmp/myagents-research/garrytan-gstack/docs/domain-skills.md`
- `/tmp/myagents-research/garrytan-gstack/docs/ADDING_A_HOST.md`
- `/tmp/myagents-research/garrytan-gstack/package.json`
- `/tmp/myagents-research/garrytan-gstack/setup`
- `/tmp/myagents-research/garrytan-gstack/SKILL.md`
- `/tmp/myagents-research/garrytan-gstack/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/gstack/llms.txt`
- `/tmp/myagents-research/garrytan-gstack/agents/openai.yaml`
- `/tmp/myagents-research/garrytan-gstack/conductor.json`
- `/tmp/myagents-research/garrytan-gstack/.github/workflows/skill-docs.yml`
- `/tmp/myagents-research/garrytan-gstack/.github/workflows/evals.yml`
- `/tmp/myagents-research/garrytan-gstack/.gitlab-ci.yml`
- `/tmp/myagents-research/garrytan-gstack/scripts/gen-skill-docs.ts`
- `/tmp/myagents-research/garrytan-gstack/scripts/host-config.ts`
- `/tmp/myagents-research/garrytan-gstack/scripts/resolvers/`
- `/tmp/myagents-research/garrytan-gstack/hosts/`
- `/tmp/myagents-research/garrytan-gstack/office-hours/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/autoplan/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/plan-ceo-review/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/plan-eng-review/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/review/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/qa/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/ship/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/codex/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/careful/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/careful/bin/check-careful.sh`
- `/tmp/myagents-research/garrytan-gstack/freeze/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/freeze/bin/check-freeze.sh`
- `/tmp/myagents-research/garrytan-gstack/guard/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/learn/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/sync-gbrain/SKILL.md.tmpl`
- `/tmp/myagents-research/garrytan-gstack/lib/gstack-memory-helpers.ts`
- `/tmp/myagents-research/garrytan-gstack/bin/gstack-memory-ingest.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/cli.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/server.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/commands.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/path-security.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/security.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/cdp-allowlist.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/browser-skill-commands.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/domain-skills.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/src/domain-skill-commands.ts`
- `/tmp/myagents-research/garrytan-gstack/test/helpers/skill-parser.ts`
- `/tmp/myagents-research/garrytan-gstack/test/helpers/session-runner.ts`
- `/tmp/myagents-research/garrytan-gstack/test/skill-validation.test.ts`
- `/tmp/myagents-research/garrytan-gstack/test/skill-e2e.test.ts`
- `/tmp/myagents-research/garrytan-gstack/test/hook-scripts.test.ts`
- `/tmp/myagents-research/garrytan-gstack/test/llm-judge-recommendation.test.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/test/server-auth.test.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/test/tunnel-gate-unit.test.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/test/domain-skills-storage.test.ts`
- `/tmp/myagents-research/garrytan-gstack/browse/test/security*.test.ts`

## Excluded Paths

- `/tmp/myagents-research/garrytan-gstack/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/garrytan-gstack/bun.lock`: dependency lockfile; package names and build/test scripts were reviewed through `package.json`.
- `/tmp/myagents-research/garrytan-gstack/CHANGELOG.md`: very large generated/history document; not needed for current execution-path review beyond confirming versioned release practice.
- Root project task backlog file: large maintainer backlog; useful for maintainers but not central to runtime or design choices reviewed here.
- `/tmp/myagents-research/garrytan-gstack/docs/images/` and `extension/icons/`: binary/image assets; not relevant to skills/instruction design beyond UI branding.
- `/tmp/myagents-research/garrytan-gstack/extension/*.js`, `*.css`, and HTML: UI-side browser extension implementation; skimmed by file map, excluded as UI-heavy and secondary to the instruction/runtime model.
- `/tmp/myagents-research/garrytan-gstack/design/` and `make-pdf/`: adjacent product CLIs; reviewed only through build scripts and skill references because the research target is coding-agent skills and browser/runtime support.
- `/tmp/myagents-research/garrytan-gstack/supabase/`: telemetry/update-check backend migrations and functions; noted as telemetry infrastructure but not needed to understand local agent execution paths.
- `/tmp/myagents-research/garrytan-gstack/openclaw/skills/`: native OpenClaw methodology adaptations; reviewed docs and directory shape, not every adapted skill line-by-line.
- `/tmp/myagents-research/garrytan-gstack/model-overlays/`: model-specific prompt patches; relevant to generation but not central enough to inspect every overlay.
- `/tmp/myagents-research/garrytan-gstack/.agents/`, `.factory/`, `.opencode/`, `.codex/`: generated/host packaging outputs; reviewed generation code and representative metadata instead of every generated copy.
- `/tmp/myagents-research/garrytan-gstack/browser-skills/hackernews-frontpage/`: bundled example browser skill; useful example, but not the core browser-skill runtime.
- `/tmp/myagents-research/garrytan-gstack/test/fixtures/` and `browse/test/fixtures/`: generated/test fixture data; representative tests were read instead.
- Remaining top-level skill directories not listed under Reviewed Paths: covered through README/docs/`gstack/llms.txt` and shared resolvers; not all skill prose was line-read because the assigned focus was actual execution paths and reusable system design.
