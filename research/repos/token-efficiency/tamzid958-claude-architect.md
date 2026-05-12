# tamzid958/claude-architect

- URL: https://github.com/tamzid958/claude-architect
- Category: token-efficiency
- Stars snapshot: 75 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: ea75d21514798e439be10d27589a28ea99298bce
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful prompt-pack reference for token-efficient project scaffolding through layered, selectively loaded framework context. Best ideas are the global -> language base -> framework delta model, small command protocols, framework pitfall shortcuts, and phase/context caps. Do not copy the broad tool allowlists, unsupported token-savings claims, or prompt-only safety model as enforcement.

## Why It Matters

`claude-architect` addresses a common coding-agent token waste pattern: every scaffold, plan, review, debug, or test request tends to make the user repeat framework conventions, command names, structure preferences, and quality gates. The repo's main answer is not compression in the algorithmic sense. It is a set of Claude Code slash-command templates plus a framework reference matrix that lets the agent load a small, relevant slice of guidance instead of carrying a large universal project-generation manual.

For Agentic Coding Lab, this matters because it is a practical context-shaping design. The repo decomposes reusable coding-agent knowledge into:

- global defaults loaded every session,
- command-specific workflows loaded only when invoked,
- a framework detection matrix used as a router,
- language base files for common conventions,
- framework delta files for only the parts that differ.

That is a direct token-efficiency pattern: route first, load narrow context, plan in small phases, and use `/clear` re-anchors when long generation work grows stale. The repo is less useful as a direct dependency because it is static Markdown with no runtime verifier, eval harness, or measured benchmark data.

## What It Is

The repository is a Claude Code prompt pack. It contains one installer script, one global `CLAUDE.md` template, 15 command templates, one framework detection matrix, and framework reference Markdown files across TypeScript/JavaScript, Python, Go, Rust, .NET, Java, Kotlin, PHP, Ruby, Swift, mobile, and C/C++.

The 15 command files cover a full developer lifecycle:

- `/scaffold`
- `/onboard`
- `/plan`
- `/review`
- `/migrate`
- `/debug`
- `/refactor`
- `/test`
- `/deploy`
- `/doc`
- `/api`
- `/component`
- `/secure`
- `/deps`
- `/perf`

`install.sh` copies the global defaults to `~/.claude/CLAUDE.md`, copies command files to `~/.claude/commands/`, and copies `frameworks/` under the commands directory. There is no package manager manifest, no compiled code, no tests directory, no CI workflow, no MCP server, no hook implementation, and no generated app example. The repository is primarily reusable instructions.

## Research Themes

- Token efficiency: Moderate to strong as a design pattern. The README claims 70% reduction from delta-only framework files and gives task-level token estimates such as scaffold full-stack app dropping from roughly 50-80k to 15-25k. The actual repo supports token efficiency structurally through narrow command files, framework routing, inheritance, merged framework refs, phase caps, file path references, and `/clear` re-anchors. The claims are not backed by reproducible traces or benchmark scripts.
- Context control: Strong instruction-level controls. `/scaffold` tells the agent not to import files over 100 lines, keep phase diffs under 200 lines, reference paths instead of repeating contents, and suggest `/clear` after several interactions. `/onboard`, `/plan`, `/review`, `/debug`, and related commands begin by reading `CLAUDE.md`, current project structure, and the matched framework reference instead of loading every framework file.
- Sub-agent / multi-agent: Minimal. The repo does not define subagents or worker protocols. It does split work by command and model tier: Opus for planning, review, onboarding, debugging, migration, security, and performance; Sonnet for scaffold, refactor, tests, deploy, docs, API, component, and dependency work.
- Domain-specific workflow: Strong for general software engineering. The framework refs encode route structures, test tools, error handling, pitfalls, commands, and project layouts for many stacks. It is broad rather than domain-specific to one product area.
- Error prevention: Moderate. Workflows require clarification before coding, approval before implementation, phase-by-phase verification, build/lint/test gates, pitfall checks, root-cause analysis, and no false confidence in security audits. These are prompt controls only.
- Self-learning / memory: Low. There is no memory store or self-learning loop. Continuity is handled through `Plan.md`, `Migration-Plan.md`, generated `CLAUDE.md`, docs, commits, and `/clear` re-anchor prompts.
- Popular skills: No formal skill registry or `SKILL.md` bundles exist. The reusable units are command templates, especially `/scaffold`, `/onboard`, `/plan`, `/review`, `/debug`, `/test`, `/secure`, and the framework reference files.

## Core Execution Path

The main execution path starts with installation:

1. User runs `bash install.sh`.
2. Installer backs up an existing `~/.claude/CLAUDE.md` to `~/.claude/CLAUDE.md.bak` if present.
3. Installer copies `global-CLAUDE.md` into `~/.claude/CLAUDE.md`.
4. Installer copies 15 command Markdown files into `~/.claude/commands/`.
5. Installer copies `frameworks/` into `~/.claude/commands/frameworks/`.
6. User starts Claude Code and invokes a command such as `/scaffold`, `/onboard`, or `/debug`.

For new project generation, `/scaffold` is the critical path:

1. Parse user arguments into name, language, framework, purpose, type, data layer, auth, features, and constraints.
2. Rate the spec as too vague, partial, or clear.
3. Ask clarifying questions for vague or partial specs; otherwise state assumptions.
4. Use `frameworks/_index.md` to select one framework reference file.
5. Read that reference file, not the whole framework corpus.
6. Save a `Plan.md` with directory tree, dependencies, phases, and `CLAUDE.md` preview.
7. Stop and wait for user approval.
8. After approval, initialize git if needed, create a branch, implement phase by phase, run build/lint/test per phase, commit each phase, and update `Plan.md`.
9. If a phase fails after two fix attempts, stop and offer rollback or user decision.
10. After all phases, run full verification and summarize quick start plus next commands.

For existing projects, `/onboard` is the equivalent path:

1. Analyze stack read-only using `frameworks/_index.md`.
2. Map files with generated/vendor/build output filtered out.
3. Read representative source files and detect patterns.
4. Detect commands from manifests or task files.
5. Check git state.
6. Report findings and ask before generating anything.
7. Generate a compact project `CLAUDE.md` under 80 lines plus relevant docs.
8. Optionally offer hooks and permission allowlists.

Other commands reuse the same shape: parse and clarify, read project instructions, route to the matched framework reference, analyze current code, produce a plan or findings, stop for approval where changes are involved, execute in small phases, verify, and summarize.

## Architecture

The architecture is flat and Markdown-centric:

- `README.md`: product overview, install instructions, command map, token/cost claims, usage examples, permission allowlist example, troubleshooting, and final installed file tree.
- `global-CLAUDE.md`: always-loaded defaults for clarification, model choice, code quality, naming, error handling, security, testing, git workflow, performance, project hygiene, communication, and quality gates.
- `install.sh`: Bash installer that copies files into `~/.claude/`.
- Root command files: slash-command protocols with frontmatter `allowed-tools`, workflow steps, approval gates, verification gates, output templates, and rules.
- `frameworks/_index.md`: detection matrix mapping config files, dependencies, and directory signals to one reference file.
- `frameworks/<language>/_base.md`: language-level defaults for detection, package manager, commands, conventions, error handling, testing, architecture, `.gitignore`, and pitfalls.
- `frameworks/<language>/<framework>.md`: framework-specific delta files with detection signals, commands, conventions, error handling, tests, structure, convention blocks, `.gitignore` additions, and pitfalls.

The actual prompt loading model is a manual inheritance convention, not a parser. Files say "Inherits: global-CLAUDE.md" or "Inherits: typescript/_base.md", but no script expands those references. Claude is instructed to read the base and matched framework reference during command execution.

## Design Choices

The strongest design choice is context routing. `frameworks/_index.md` makes the agent decide which framework reference matters before reading detailed guidance. This avoids loading all ecosystems for a Next.js, FastAPI, Rails, or Rust web task.

The second strong choice is delta-only framework guidance. Base files hold language defaults; framework files hold only differences, commands, pitfalls, and convention blocks. This is a good pattern for maintainable prompt libraries because repeated advice is expensive and drifts across files.

The third choice is command-specific protocols. Instead of one giant "developer manual", each command owns a narrow workflow. `/review` is mostly read-only and issue-focused. `/secure` is an audit checklist. `/debug` requires hypotheses before fixes. `/test` requires a test plan before writing tests. `/deps` separates audit, plan, and upgrade execution.

The fourth choice is approval gating. Most write commands produce a plan and explicitly stop before editing. This reduces wrong-code rework, which is likely the biggest real token saving even if the numeric claims are unverified.

The fifth choice is phase size control. `/scaffold` caps phases at 3-6 total, max 5 files per phase, and phase diffs under 200 lines. `/plan`, `/refactor`, and `/migrate` use similar phase and checkpoint language. This converts long generation into inspectable chunks.

The sixth choice is pitfall-first debugging and review. Framework files include known pitfalls, and commands repeatedly tell the agent to check them before inventing deeper explanations.

The weakest design choice is tool permission breadth. Many write-capable commands allow `Bash(*)` and `Edit(**)`. Some read-only commands have narrower frontmatter, but the high-risk generation commands mostly rely on instruction discipline rather than capability restriction.

## Strengths

The repo gives a concrete pattern for organizing large prompt knowledge without loading it all. The hierarchy and detection matrix are easy to adapt to other agent systems.

The command templates encode real execution discipline: clarify before coding, plan before edit, stop for approval, verify with build/lint/test, and summarize concrete outputs.

The framework refs are compact and operational. They include commands, structure, testing tools, error handling, convention blocks, and pitfalls that a coding agent can apply immediately.

The scaffold workflow explicitly treats context length as an engineering problem. It limits file imports, phase diffs, repeated content, and long-running session drift.

The security command has unusually good honesty language for a prompt pack: if a check cannot be verified, report "UNABLE TO VERIFY" instead of implying success.

The onboard workflow is read-only before approval and prioritizes detected project patterns over assumed framework defaults. That is important for avoiding generic code generation.

## Weaknesses

There is no enforcement layer. The repo depends entirely on Claude Code honoring Markdown instructions. There is no shell wrapper, MCP server, hook, schema validator, linter, or runtime budget checker.

The token-efficiency claims are not reproducible. README numbers and the 70% reduction claim have no benchmark fixture, captured prompts, token logs, or before/after traces in the repo.

Tool permissions are broad. `scaffold.md`, `onboard.md`, `debug.md`, `refactor.md`, `test.md`, `deploy.md`, `api.md`, `component.md`, `deps.md`, `perf.md`, and `migrate.md` all expose `Bash(*)` and `Edit(**)` in command frontmatter. That weakens safety if a command is invoked in an untrusted or poorly understood repo.

Rollback instructions include destructive `git reset --hard` options in several commands. They are framed as user choices after failure, but a safer design would route destructive recovery through explicit approval and exact changed-file accounting.

The installer overwrites `~/.claude/CLAUDE.md` after making one backup. It does not merge, diff, validate, or preserve multiple previous versions. `/onboard` has better merge language, but `install.sh` itself is blunt.

The permission allowlist example in README suggests broad `Edit(**)` plus multiple Bash patterns. That may be convenient for Claude Code, but it is not least privilege.

The framework knowledge is static. It says to use "latest stable" and detect versions at runtime, but no command fetches official docs or records source dates for framework guidance. Framework advice can drift quickly.

There is no test harness for the prompt pack. `install.sh` has no dry run or verification mode, command templates have no lint checks, and framework refs have no consistency tests.

GitHub metadata reports no license object even though README says MIT, and the checkout has no standalone `LICENSE` file. Reuse should check licensing before copying text wholesale.

## Ideas To Steal

Use a three-layer prompt reference tree for coding-agent knowledge: global defaults, language base, and framework deltas. This gives token savings without losing specificity.

Build a detection matrix as a context router. The agent should identify stack and framework from manifest/config/source signals, then read exactly one or a few matched references.

Keep command workflows separate from framework facts. A `/debug` workflow should be reusable across stacks while stack-specific pitfall files provide the fast path.

Make "pitfall sections" first-class in every framework note. Debugging and review commands can consult them before broader exploration.

Use compact project `CLAUDE.md` generation with an explicit line budget. The `/onboard` and `/scaffold` under-80-line guidance is a good guard against creating another oversized context blob.

Require approval gates before writes in scaffold, test, API, component, refactor, migration, dependency, deploy, and performance workflows.

Steal the phase constraints: max files per phase, approximate diff size, per-phase verification, and continuation anchors after context growth.

For Agentic Coding Lab, pair this prompt layout with machine checks: lint command frontmatter for least privilege, verify that command plans include exact paths, measure tokens loaded per command, and enforce path-specific read budgets.

## Do Not Copy

Do not copy `Bash(*)` and `Edit(**)` as default command permissions. Use least-privilege tool frontmatter per command and escalate only for write phases.

Do not cite the 70% token reduction or task token tables as evidence without reproducing them against captured tasks.

Do not adopt prompt-only quality gates as a substitute for real verification. Build/lint/test claims need command evidence, not output template slots.

Do not use "latest stable everywhere" as a universal dependency policy. It improves freshness but hurts reproducibility; project scaffolding should record resolved versions or lock files.

Do not ship an installer that overwrites global agent instructions without a diff, merge path, and explicit confirmation.

Do not put destructive rollback commands directly in generated workflow text without a safer approval wrapper and pre-reset state capture.

Do not assume static framework references stay correct. Add source provenance, review dates, and doc-refresh checks for fast-moving frameworks.

Do not treat the framework "inheritance" comments as executable composition. If used locally, build or document a loader that makes inherited context explicit and bounded.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is not a token compressor, context database, or coding-agent runtime. It is a prompt architecture reference for reducing unnecessary context in project-generation and developer-lifecycle workflows.

The most valuable local adaptation is a stricter command/reference system:

- `commands/<task>.md` for workflow only,
- `refs/frameworks/_index.md` for routing,
- `refs/frameworks/<language>/_base.md` for language defaults,
- `refs/frameworks/<framework>.md` for small deltas,
- machine-readable metadata for allowed tools, read budgets, write surfaces, and required verification.

Agentic Coding Lab should also add a harness around these ideas: run the same scaffold/debug/review tasks with and without routed references, record loaded files, returned command bytes, token counts, rework cycles, and validation outcomes. That would turn this repo's plausible design into measured evidence.

As a dependency, fit is low. As a pattern source for token-efficient command and reference organization, fit is high.

## Reviewed Paths

- `/tmp/myagents-research/tamzid958-claude-architect/README.md`: purpose, install path, command list, token/cost claims, examples, permission allowlist, troubleshooting, and installed tree.
- `/tmp/myagents-research/tamzid958-claude-architect/global-CLAUDE.md`: global behavior defaults, quality gates, model guidance, and project hygiene rules.
- `/tmp/myagents-research/tamzid958-claude-architect/install.sh`: actual installer path and overwrite/backup behavior.
- `/tmp/myagents-research/tamzid958-claude-architect/scaffold.md`: main generation protocol, framework routing, approval gate, phase caps, verification, and token rules.
- `/tmp/myagents-research/tamzid958-claude-architect/onboard.md`: read-only analysis, project `CLAUDE.md` generation, docs, hooks, and permission proposal workflow.
- `/tmp/myagents-research/tamzid958-claude-architect/plan.md`: planning path, impact analysis, exact file paths, phases, and continuation anchor.
- `/tmp/myagents-research/tamzid958-claude-architect/review.md`: code-review scope detection, context loading, severity model, and read-only tool frontmatter.
- `/tmp/myagents-research/tamzid958-claude-architect/debug.md`: bug definition, hypotheses, isolation, root-cause rules, and regression-test requirements.
- `/tmp/myagents-research/tamzid958-claude-architect/refactor.md`: behavior-preserving refactor flow, dependency mapping, phase verification, and rollback language.
- `/tmp/myagents-research/tamzid958-claude-architect/test.md`: test planning, framework-specific test guidance, mutation sanity check, and approval gate.
- `/tmp/myagents-research/tamzid958-claude-architect/api.md`: endpoint generation plan, validation/response patterns, framework examples, tests, and verification.
- `/tmp/myagents-research/tamzid958-claude-architect/component.md`: component planning, state/accessibility/test requirements, and framework patterns.
- `/tmp/myagents-research/tamzid958-claude-architect/doc.md`: documentation generation from code, API/component/architecture templates, and read-only tool frontmatter.
- `/tmp/myagents-research/tamzid958-claude-architect/deploy.md`: deploy analysis, Docker/CI rules, secret handling, health checks, and verification.
- `/tmp/myagents-research/tamzid958-claude-architect/secure.md`: security audit checklist, no-false-confidence rule, dependency audit guidance, and narrower tool frontmatter.
- `/tmp/myagents-research/tamzid958-claude-architect/deps.md`: dependency health-check and upgrade flow, risk ordering, lock-file rules, and one-major-at-a-time guidance.
- `/tmp/myagents-research/tamzid958-claude-architect/perf.md`: performance profiling, baseline measurement, phased optimization, and metrics-in-commit rule.
- `/tmp/myagents-research/tamzid958-claude-architect/migrate.md`: migration inventory, phase plan, coexistence mode, rollback plan, and cleanup rules.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/_index.md`: detection matrix and ambiguity rules.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/typescript/_base.md`, `typescript/api.md`, `typescript/nextjs.md`, `typescript/react.md`, `typescript/vue.md`, `typescript/nuxt.md`, `typescript/svelte.md`, `typescript/sveltekit.md`, `typescript/nestjs.md`, `typescript/astro.md`, `typescript/remix.md`: TypeScript base and web/API framework references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/python/_base.md`, `python/django.md`, `python/fastapi.md`, `python/flask.md`, `python/scrapy.md`: Python base and framework references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/go/_base.md`, `go/web.md`: Go base and merged Gin/Echo/Fiber reference.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/rust/_base.md`, `rust/web.md`, `rust/tauri.md`: Rust base, merged Actix/Axum/Rocket, and Tauri reference.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/dotnet/_base.md`, `dotnet/aspnet-core.md`, `dotnet/blazor.md`, `dotnet/maui.md`: .NET references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/java/_base.md`, `java/spring-boot.md`, `java/quarkus.md`: Java references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/kotlin/_base.md`, `kotlin/ktor.md`: Kotlin references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/php/_base.md`, `php/laravel.md`, `php/symfony.md`: PHP references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/ruby/_base.md`, `ruby/rails.md`, `ruby/sinatra.md`: Ruby references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/swift/_base.md`, `swift/swiftui.md`, `swift/vapor.md`: Swift references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/mobile/_base.md`, `mobile/react-native-expo.md`, `mobile/flutter.md`: mobile references.
- `/tmp/myagents-research/tamzid958-claude-architect/frameworks/cpp/_base.md`, `cpp/cmake.md`: C/C++ references.
- `/tmp/myagents-research/tamzid958-claude-architect/.gitignore`: generated/vendor/build/env exclusion pattern.
- Git metadata and GitHub REST API metadata: exact commit, branch, commit date, stars, forks, issue count, license metadata, and pushed timestamp.

## Excluded Paths

- `/tmp/myagents-research/tamzid958-claude-architect/.git/`: clone metadata only. Used through Git commands to record commit, branch, history, and remote, not reviewed as content.
- `/tmp/myagents-research/tamzid958-claude-architect/.agents/`: empty directory in checkout; no agent definitions to review.
- `/tmp/myagents-research/tamzid958-claude-architect/.codex/`: empty directory in checkout; no Codex-specific files to review.
- Generated paths: none present in the tracked file list.
- Vendored dependencies: none present in the tracked file list.
- Binary assets: none present in the tracked file list.
- UI-only paths: none present. The repository is Markdown instructions plus one Bash installer.
- Tests/examples directories: none present. Examples are inline in `README.md`; there is no runnable test harness or generated sample project to exclude.
