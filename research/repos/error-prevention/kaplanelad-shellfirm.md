# kaplanelad/shellfirm

- URL: https://github.com/kaplanelad/shellfirm
- Category: error-prevention
- Stars snapshot: 910 on 2026-05-19 via GitHub REST API
- Reviewed commit: 7ebf869770c197bf5591bdcf4003f6373af6c211
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong practical pattern source for command-level agent safety. The best pieces are the shared command-analysis pipeline, severity/context/policy escalation layers, Claude Code PreToolUse hook output, MCP analysis tools, audit-before-prompt behavior, blast-radius display, and quote-aware wrapper for interactive database shells. Do not copy the regex-only detector, fail-open wrapper behavior, or docs/runtime drift.

## Why It Matters

Shellfirm sits directly on the failure mode Agentic Coding Lab cares about: humans and AI coding agents issuing destructive terminal commands faster than they can reason about impact. It protects shell commands before execution with a local rule corpus, context-aware escalation, explicit challenges, structured agent decisions, team policy files, and JSON-lines audit events.

The project is useful because it covers both interactive humans and AI tools. Humans get an interrupting challenge. Agents get structured allow/deny output through Claude Code hooks or MCP tools. The shared core means the same risky-command catalog can feed multiple enforcement surfaces.

## What It Is

Shellfirm is a Rust CLI/library for detecting risky shell commands. It installs shell hooks for Bash, Zsh, Fish, Nushell, PowerShell, Elvish, Xonsh, and Oils; exposes `shellfirm pre-command` for interactive shell interception; exposes `shellfirm check` and `shellfirm mcp` for AI coding agents; and exposes `shellfirm wrap` as a PTY proxy for interactive programs such as `psql`, `mysql`, `redis-cli`, `mongosh`, and `mongo`.

The rule corpus is YAML compiled into the binary by `shellfirm/build.rs`. At the reviewed commit it contains 210 check definitions across 22 YAML files, covering filesystem, Git, GitHub CLI, Docker, Kubernetes/Helm, AWS, GCP, Azure, Terraform, databases, Redis, MongoDB, MySQL, psql, package managers, networking, shell download-execute patterns, Heroku, Fly.io, Vercel, and Netlify.

## Research Themes

- Token efficiency: Not a major theme. The useful token pattern is avoiding broad prompt-only safety text by returning compact structured rule IDs, severities, alternatives, and blast-radius fields to agents.
- Context control: Strong local context control. The pipeline detects SSH, root, Git branch, Kubernetes context, and production env vars, then filters irrelevant context labels by matched command group before displaying or assessing risk.
- Sub-agent / multi-agent: Limited. MCP makes shellfirm callable by agents, but there is no multi-agent orchestration or taint propagation between agents.
- Domain-specific workflow: Strong terminal/devops workflow. The rules are domain-specific to destructive CLI actions, Git history hazards, infra tools, cloud CLIs, databases, and interactive shells.
- Error prevention: Core theme. It blocks or challenges before execution, auto-denies high-severity agent commands, records audit events, suggests safer alternatives, and computes blast radius for some commands.
- Self-learning / memory: Minimal. It keeps config, custom checks, policies, and audit logs, but it does not learn new rules from past runs.
- Popular skills: Command risk assessment, shell hook installation, Claude Code hook integration, MCP tool server, additive team policy, audit logging, context-aware escalation, and wrapper protection for REPL-like tools.

## Core Execution Path

The CLI entrypoint builds subcommands, handles `init`, `connect`, and `policy` before loading full config, then loads settings from the platform config directory. If parsing `settings.yaml` fails, it warns and falls back to default settings. It loads custom checks from the config checks directory, migrates custom group names into `enabled_groups`, filters active built-in and custom checks, then dispatches `pre-command`, `check`, `mcp`, `wrap`, `audit`, `status`, or `config`.

The interactive shell path starts with `shellfirm init`. Zsh, Bash, Fish, Nushell, PowerShell, Elvish, Xonsh, and Oils hooks intercept Enter or pre-execution events and call `shellfirm pre-command -c <command>`. Zsh forces `--direct-tty` to avoid terminal-event hangs inside ZLE. Bash/Oils use DEBUG traps and history numbers to avoid repeated checks for shell internals. Most hooks skip empty commands and commands containing `shellfirm`.

`pre-command` resolves settings for `Mode::Shell`, strips quoted strings with a regex, splits the command on `&&`, `||`, `|`, and `;` while respecting quotes, then matches each segment and the full stripped command against active checks. Filters such as `PathExists`, `Contains`, and `NotContains` run after regex matching. It discovers `.shellfirm.yaml` by walking upward from cwd, detects runtime context only when there are matches or project extra checks, merges policy, applies policy extra checks, filters by `min_severity`, collects deny status and alternatives, and computes blast radius for supported checks.

If active matches exist, the shell path writes a pre-challenge audit event with outcome `Cancelled`, then builds an effective challenge from six monotonic layers: base challenge, severity escalation, group escalation, check-ID escalation, context escalation, and project policy overrides. Challenges are ordered `Math < Enter < Yes`. Deny-listed commands show a denial banner and block indefinitely in the real terminal prompter until the user interrupts. Passed challenges write a post-challenge `Allowed` audit event.

The AI-agent path has two entry points. `shellfirm connect claude-code` edits `~/.claude/settings.json` to install a `PreToolUse` hook for Bash with command `shellfirm check --stdin --format json --exit-code`, plus an MCP server entry. The `check` command parses Claude Code hook JSON (`tool_input.command`), simple JSON (`command`), or plain text; calls `agent::assess_command`; and emits Claude hook JSON with `hookSpecificOutput.permissionDecision` as `allow` or `deny`. In text `--exit-code` mode, risky commands exit 2; in JSON hook mode it exits 0 and communicates denial through the hook protocol.

The MCP path starts `shellfirm mcp`, creates a session ID, and runs a JSON-RPC stdio loop. It implements `initialize`, `tools/list`, `tools/call`, and `notifications/initialized`. The actual tools are `check_command`, `suggest_alternative`, `get_policy`, and `explain_risk`. Tool errors are returned inside MCP content with `isError: true` rather than as JSON-RPC transport errors.

The wrapper path starts `shellfirm wrap <program>`. It resolves per-tool delimiter and check groups, spawns the child in a PTY, forwards input/output, and buffers user input until a delimiter outside quotes is seen. The statement is analyzed through the same pipeline. If the challenge passes, the delimiter is forwarded; if denied, Ctrl-C is sent to the child. Analysis or challenge errors in the wrapper currently fail open and forward the statement.

## Architecture

Shellfirm is organized as a small shared engine with several frontends:

- Rule and config layer: `shellfirm/checks/*.yaml`, `shellfirm/build.rs`, `config.rs`, and custom checks in the user config directory.
- Analysis layer: `checks.rs`, `policy.rs`, `context.rs`, `blast_radius.rs`, and `env.rs` form the reusable command pipeline.
- Human enforcement layer: `cmd/init.rs`, `cmd/command.rs`, and `prompt.rs` install hooks, prompt users, and log audit events.
- Agent enforcement layer: `agent.rs`, `cmd/check_cmd.rs`, `mcp.rs`, `cmd/mcp_cmd.rs`, and `cmd/connect_cmd.rs` provide structured non-interactive decisions.
- Interactive-tool enforcement layer: `wrap/common.rs`, `wrap/unix.rs`, `wrap/windows.rs`, and `cmd/wrap_cmd.rs` proxy REPL-like command streams.
- Operator layer: `cmd/config.rs`, `cmd/policy_cmd.rs`, `cmd/audit_cmd.rs`, `cmd/status_cmd.rs`, and the optional TUI edit settings and inspect logs.

The most important boundary is the `Environment` trait. Production code uses `RealEnvironment`; tests use `MockEnvironment` for env vars, cwd, path existence, command output, files, and upward policy discovery. This makes context detection, policy discovery, filters, and blast-radius behavior testable without touching real machines.

## Design Choices

Rules are plain YAML records with `id`, `from`, regex `test`, description, severity, optional filters, and optional safer alternatives. Build-time embedding avoids runtime discovery for built-ins and keeps `get_all()` cached.

Safety decisions are monotonic. Severity, group, check-ID, context, and project policy can raise challenge strength but not lower it. Project policy can add checks, add deny-list entries, and add challenge overrides. User/global `deny_patterns_ids` and project `deny` force denial regardless of severity.

Human and agent modes differ only after analysis. Human mode displays a banner and runs a challenge. Agent mode builds a `RiskAssessment` and auto-denies if the maximum active severity is at or above `agent.auto_deny_severity` (default `High`) or if any matched rule is denied. This is the right shape for coding-agent safety: same detector, different enforcement adapter.

Runtime context is treated as a risk amplifier, not a standalone blocker. SSH raises to Elevated, while root, protected Git branches, production Kubernetes contexts, and configured production env vars raise to Critical. Relevant-context filtering hides Kubernetes context for Git commands and hides Git branch for Kubernetes commands, while keeping global SSH/root/env signals.

Blast radius is intentionally best-effort. It uses bounded subprocess calls such as `find`, `du`, `git diff`, `git clean -dn`, Docker list commands, and Kubernetes resource listing with a three-second timeout. Failures omit the blast-radius line rather than blocking the core challenge path.

The wrapper design protects commands that normal shell hooks cannot see after entering an interactive child. Its quote-aware input buffer is simple but valuable: it avoids splitting SQL at semicolons inside quoted strings.

## Strengths

The guardrail lives on the actual execution path for shell hooks and Claude Code Bash tool calls. A risky command is checked before the shell accepts it or before Claude Code receives an allow/deny hook decision.

The rule corpus is broad and practical. It covers common coding-agent accidents: `rm -rf`, force pushes, Git cleanup, deleting Kubernetes namespaces, Terraform auto-approve destroy/apply, dropping databases/tables, flushing Redis, deleting cloud resources, deleting GitHub secrets/releases/repos, disabling firewalls, and piping remote code to shells.

The monotonic escalation model is easy to reason about. Global settings, severity, local context, and team policy compose without allowing a lower-precedence layer to weaken protections.

The project includes strong test seams. Pure logic tests cover pattern matching, policy merge, splitting, alternatives, and severity escalation. Sandboxed integration tests cover context, policies, alternatives, compound commands, relevant-context filtering, and audit. YAML-driven check tests exercise many positive and negative command examples. Wrapper tests cover delimiter behavior and interactive Redis/SQL-style statements.

The Claude Code hook output is pragmatic. Returning exit 0 with `hookSpecificOutput.permissionDecision` matches the hook protocol and avoids relying on process exit alone for JSON-mode decisions.

Pre-challenge audit is a useful failure-handling pattern. If the user presses Ctrl-C or the process dies during the prompt, there is still a durable `Cancelled` record with event ID, command, matched IDs, severity, context labels, and blast-radius fields.

The `Environment` abstraction and `MockEnvironment` make side-effect-free tests possible for normally risky behavior such as root/SSH/prod context, path filters, Git branch lookup, Kubernetes context lookup, policy files, and blast radius.

## Weaknesses

The detector is regex-based, not shell-parser-based. It strips quoted strings before analysis, which reduces false positives for `echo "rm -rf /"` but can also hide quoted destructive targets. It does not model shell expansion, aliases, functions, command substitution, environment-variable values, or generated scripts.

Malformed user settings fail soft to `Settings::default()`. For a safety tool, that can silently drop user deny lists, ignored/enabled group choices, thresholds, and stricter policy. A safer lab design would keep last-known-good settings or fail closed for agent/hook enforcement.

Project policy has some incomplete edges. `ProjectPolicy.context` exists and the scaffold mentions context, but the reviewed merge path does not apply project context config. The scaffold comments mention `challenge: Deny`, but `Challenge` only supports `Math`, `Enter`, and `Yes`; real denial is via the `deny` list.

Agent audit is weaker than the docs imply. The `AuditEvent` type has `agent_name` and `agent_session_id`, and the public docs discuss agent audit fields, but `check` and MCP assessment paths do not write audit events in the reviewed code. Audit is implemented for `pre-command` and `wrap`.

The LLM module is not wired into the active assessment path. `llm.rs` has Anthropic/OpenAI-compatible providers and parsing helpers, but `agent::assess_command`, `check`, and `mcp` use regex/policy analysis only at this commit.

The wrapper fails open on analysis or challenge errors. That is understandable for preserving an interactive session, but it is a poor default for high-risk database or production shells.

MCP-only integrations are advisory unless the agent voluntarily calls the MCP tool before executing commands. Claude Code gets an automatic Bash PreToolUse hook; Cursor, Windsurf, Zed, and Cline setup paths mostly install MCP only.

Interactive deny is implemented by displaying denial text and sleeping forever until Ctrl-C. It blocks execution, but it means real denied shell prompts do not naturally return a structured `Denied` result or post-denial audit event.

Context detection is intentionally shallow. Root detection depends on `EUID` env var, Git and Kubernetes detection use 100 ms subprocesses and fail silently, and `sensitive_paths` are configurable but not used in the reviewed context risk computation.

Docs and code have drift. The public docs describe an MCP tool named `assess_command`, while the reviewed code exposes `check_command`, `suggest_alternative`, `get_policy`, and `explain_risk`. Some docs and README wording also lag current config paths and implementation details.

## Ideas To Steal

Use one shared command-risk pipeline with multiple adapters: interactive challenge, hook protocol JSON, MCP tool output, CI text exit code, and REPL wrapper.

Represent risky command rules as small, testable records with IDs, severity, filters, descriptions, and safer alternatives. Keep rule IDs stable so config, policy, audit, tests, and docs all point to the same thing.

Make escalation monotonic. Local config, severity, runtime context, group overrides, check overrides, and project policy should only increase friction or denial, never reduce it.

Separate human and agent decisions after analysis. Humans can solve challenges; agents should get deterministic structured allow/deny decisions and safer alternatives.

Add a pre-prompt audit record before any blocking UI. If the user cancels, the trace should still show what command was intercepted and why.

Filter context labels by matched domain. Showing `branch=main` for every filesystem command creates noise; showing it for Git commands is useful.

Attach blast-radius facts to high-risk commands when cheap to compute. Concrete impact like file count, Git commit count, Docker resources, or Kubernetes resources is more useful than only "critical".

Use direct hook integration for the agent that actually executes shell commands. MCP analysis tools are useful, but automatic PreToolUse or equivalent enforcement is stronger.

Protect interactive child tools with delimiter-aware wrappers. Coding agents often enter `psql`, `redis-cli`, or similar shells where normal command hooks no longer see destructive statements.

Build all high-risk context and blast-radius probes behind a testable environment interface. This allows deterministic tests without invoking real `git`, `kubectl`, `docker`, or filesystem destruction.

## Do Not Copy

Do not depend on regex and quote stripping as the final command understanding layer for autonomous high-impact agents. Use a shell parser, command AST, or typed tool wrappers for critical paths.

Do not silently revert malformed safety config to permissive defaults. Fail closed or preserve the previous valid config for enforcement paths.

Do not expose an MCP analysis tool as the only guardrail for agents that can execute shell commands through another path.

Do not copy fail-open behavior from the wrapper for production databases or deployment shells unless there is a separate mandatory approval layer.

Do not ship docs that describe stronger audit, LLM, or MCP behavior than the code actually enforces. For safety tooling, docs drift becomes operator risk.

Do not make denial a terminal infinite sleep in new agent-facing systems. Return a typed denial result, log it, and let the caller decide how to recover.

Do not keep unused safety-looking config fields such as sensitive paths or project policy context unless they affect the enforcement path.

## Fit For Agentic Coding Lab

Shellfirm is a strong fit for the `error-prevention` category because it is small enough to study and close to the actual coding-agent shell hazard. The most useful adaptation is not the full terminal tool, but a command safety service with these pieces:

- A versioned rule catalog for destructive commands and side-effecting workflows.
- A typed assessment result with matched rule IDs, severity, allow/deny, alternatives, context labels, and blast radius.
- A monotonic escalation model across repo policy, branch/context, command type, and agent mode.
- Mandatory integration at the shell execution boundary, not only optional model guidance.
- Audit records for allowed, denied, skipped, and cancelled decisions.
- A test harness with mock environment, command matrix, and positive/negative YAML examples.

For Agentic Coding Lab, this should become a "command authority" pattern. Every agent-originated shell command goes through assessment before execution. Read-only commands can pass silently; destructive commands require explicit human approval or are denied; project policies can add local checks; and dangerous contexts such as protected branches, root, SSH, or production env vars raise the threshold.

## Reviewed Paths

- `README.md`: project framing, shell/agent features, examples, integrations, install, and docs links.
- Public docs: `https://shellfirm.vercel.app/docs/agents-and-automation`, configuration, context-aware protection, team policies, check pipeline, filters/alternatives, blast radius, and interactive wrapper pages were checked for implementation alignment.
- `Cargo.toml`, `shellfirm/Cargo.toml`, `shellfirm/build.rs`, `build.rs`: workspace/package shape, feature flags, binary features, dependencies, and check embedding.
- `shellfirm/src/bin/shellfirm.rs`: CLI startup, early command handling, config loading, custom check loading, active check loading, and subcommand dispatch.
- `shellfirm/src/checks.rs`: check schema, filters, cached rule loading, core `analyze_command`, command splitting, severity filtering, policy merge use, challenge construction, alternatives, deny, and blast-radius dispatch.
- `shellfirm/src/config.rs`: settings schema, challenges, per-mode overrides, agent config, wrapper config, severity escalation, defaults, config read/write, active check filtering, and custom check migration.
- `shellfirm/src/policy.rs`: `.shellfirm.yaml` discovery, parsing, additive merge, deny, challenge overrides, branch matching, scaffold, and validation.
- `shellfirm/src/context.rs`: SSH/root/Git/Kubernetes/env detection, risk computation, escalation, branch wildcard matching, and relevant-context filtering.
- `shellfirm/src/env.rs`: `Environment` trait, real subprocess timeout behavior, virtual files, mock env vars, command outputs, paths, and policy discovery.
- `shellfirm/src/prompt.rs`: banner display, challenge types, terminal prompter, direct TTY fallback, deny handling, mock prompter, and prompt helpers.
- `shellfirm/src/audit.rs`: JSON-lines audit schema, outcomes, write/read/clear behavior, timestamps, and agent/blast-radius fields.
- `shellfirm/src/blast_radius.rs`: runtime blast-radius dispatch and filesystem, Git, Docker, and Kubernetes impact calculations.
- `shellfirm/src/agent.rs`: non-interactive agent assessment, matched-rule output, auto-deny threshold, alternatives, context, and human-approval flag.
- `shellfirm/src/mcp.rs` and `shellfirm/src/bin/cmd/mcp_cmd.rs`: JSON-RPC stdio server, tool list, tool calls, error content, session ID, and policy reporting.
- `shellfirm/src/bin/cmd/check_cmd.rs`: agent hook command parsing, text/JSON output, Claude Code hook protocol, exit-code behavior, and formatting.
- `shellfirm/src/bin/cmd/connect_cmd.rs`: Claude Code hooks and MCP config, Cursor/Windsurf/Zed/Cline MCP config, idempotent install/uninstall, and config write behavior.
- `shellfirm/src/bin/cmd/init.rs`: shell detection, hook generation, install/uninstall, direct TTY Zsh hook, Bash/Oils DEBUG trap behavior, and tests.
- `shellfirm/src/bin/cmd/wrap_cmd.rs`, `shellfirm/src/wrap/common.rs`, `shellfirm/src/wrap/unix.rs`, `shellfirm/src/wrap/windows.rs`: wrapper CLI, config resolution, input buffering, statement handling, fail-open behavior, PTY proxy, raw-mode guard, and control-byte handling.
- `shellfirm/src/bin/cmd/config.rs`, `shellfirm/src/bin/cmd/policy_cmd.rs`, `shellfirm/src/bin/cmd/audit_cmd.rs`, `shellfirm/src/bin/cmd/status_cmd.rs`: operator commands, validation, status display, and audit operations.
- `shellfirm/src/llm.rs`: optional LLM provider implementation, response parsing, factory behavior, and tests; noted as not wired into active command assessment.
- `shellfirm/checks/*.yaml`: built-in rule groups, severities, filters, and alternatives across 210 definitions.
- `docs/config.md`, `docs/add-new-patterns.md`, `docs/checks/*.md`: local docs for config, rule authoring, and representative check groups.
- `shellfirm/tests/pure_logic.rs`: rule, split, policy, alternative, severity, and config round-trip tests.
- `shellfirm/tests/sandboxed_integration.rs`: full mocked pipeline, context escalation, policy deny, alternatives, audit, severity layers, and relevant-context tests.
- `shellfirm/tests/decision_matrix.rs` and `shellfirm/tests/decisions/matrix.yaml`: YAML behavior matrix for command/context/policy outcomes.
- `shellfirm/tests/checks/*.yaml` and `shellfirm/tests/checks.rs`: positive/negative rule examples for check definitions.
- `shellfirm/tests/escalation_matrix_proptest.rs`, `shellfirm/tests/per_mode_resolution.rs`, `shellfirm/tests/sandboxed_integration.rs`, `shellfirm/tests/tui_app.rs`: escalation, mode resolution, integration, and config UI behavior around safety settings.
- `npm/shellfirm/bin/shellfirm`, `npm/shellfirm/package.json`, `npm/cli-*/package.json`: npm binary wrapper and platform package routing.

## Excluded Paths

- `docs/media/example.gif`: binary demo asset, useful for presentation but not command safety logic.
- `docs/docker/**`: demo Dockerfiles and README files for shell setup; not part of the runtime enforcement path.
- `shellfirm/src/tui/**` and most TUI rendering/widget internals: UI-only config editing surface. I skimmed tests/config interactions but used core config and command paths as enforcement source of truth.
- `shellfirm/src/snapshots/**` and `shellfirm/src/bin/cmd/snapshots/**`: generated `insta` snapshots. They confirm output shape but do not define behavior beyond source/tests.
- `npm/cli-darwin-*`, `npm/cli-linux-x64`, `npm/cli-win32-x64`: platform package metadata. No native binaries are vendored in the checkout; main npm wrapper was enough for packaging behavior.
- `Cargo.lock`: dependency lockfile, not an execution or policy design path.
- `scripts/bump-npm-version.sh`, `CHANGELOG.md`, `CONTRIBUTING.md`, and release/process metadata: useful project operations context, not command interception, approval, policy, or failure handling.
- Exhaustive public documentation pages for every protection group were not read line by line. Source YAML and test fixtures were used as the source of truth for rule behavior, with docs sampled for alignment and drift.
