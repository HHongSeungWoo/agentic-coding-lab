# larksuite/cli

- URL: https://github.com/larksuite/cli
- Category: domain-specific-coding
- Stars snapshot: 9,641 (GitHub REST API repository search, captured 2026-05-11 in research/index.md)
- Reviewed commit: 3bab9a0692d075ea5e3af2f00ef26f9735b1fec3
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for domain-specific coding agents that need a CLI, skill pack, auth boundary, policy layer, and schema-backed command surface. Conditional fit because the implementation is deeply tied to Lark/Feishu APIs and the source checkout does not vendor a full generated API metadata snapshot.

## Why It Matters

This repository shows how a SaaS domain can be exposed to coding agents without asking the model to improvise raw HTTP calls. It combines a Cobra CLI, generated API command metadata, curated domain shortcuts, structured output, agent-facing skills, strict identity controls, and safety gates around authentication, filesystem artifacts, policy, hooks, and content scanning.

For agentic coding research, the valuable part is not the Lark API coverage itself. The transferable pattern is a layered operational surface: skills tell the agent how to choose workflows, `schema` tells the agent what a command expects, shortcut commands encode common business workflows, raw `api` remains an escape hatch, and every layer feeds structured permission and verification errors back to the caller.

## What It Is

`lark-cli` is the official Lark/Feishu CLI for humans and AI agents. The README presents it as a three-layer command system:

- domain shortcuts for common workflows such as drive, docs, IM, calendar, base, sheets, minutes, and event consumption
- generated service/resource/method commands built from Open Platform API metadata
- a raw API command for direct Open API access

The CLI is implemented in Go with Cobra. `main.go` delegates to `cmd.Execute()`. `cmd/build.go` constructs the root command, registers built-in command groups, dynamically registers service commands from metadata, mounts shortcut commands, applies strict-mode pruning, installs platform plugins and hooks, applies user policy, and records command inventory. `cmd/root.go` handles invocation bootstrap, notices, lifecycle hooks, structured error envelopes, and permission-specific hints.

The repo also ships agent skills under `skills/`, including shared operating rules and domain-specific procedures. Those skills are part of the product surface: they tell agents when to use bot versus user identity, how to handle browser auth handoff, how to interpret permission errors, when to run dry-run, how to use schemas, and how to treat URLs and artifacts.

## Research Themes

- Token efficiency: The CLI moves large domain knowledge out of the prompt and into executable commands, help text, `schema`, and skills. `lark-shared` centralizes common rules, while domain skills such as `lark-drive` and `lark-event` contain focused workflows. This reduces repeated prompt context, but the current skill pack can still become token-heavy if an agent loads broad reference material instead of the narrow domain skill.
- Context control: `schema` commands, command tips, structured JSON output, `--jq`, and domain skills give the agent inspectable context at runtime. Strict mode and policy pruning also shape context by hiding or denying commands that should not be available for the current identity or workspace.
- Sub-agent / multi-agent: The repo does not implement a general multi-agent orchestrator. Its closest reusable pattern is event subprocess control: `event consume` emits NDJSON, handles readiness and termination, supports bounded `--max-events` and `--timeout`, and documents how an external agent harness should supervise one event stream per process.
- Domain-specific workflow: This is the strongest theme. Shortcuts provide declarative, human-readable commands over raw SaaS APIs. They define identity support, scopes, risk, flags, validation, dry-run, and output behavior in one place, while generated API commands keep full platform coverage available.
- Error prevention: The CLI uses dry-run, high-risk confirmation, safe relative file IO, path traversal checks, strict identity mode, policy pruning, structured permission hints, schema inspection, scope pre-checks, and content-safety scanning. Several layers fail closed, especially plugin restriction rules and invalid policy risk annotations.
- Self-learning / memory: There is no persistent learning loop that updates agent behavior from outcomes. The closest memory mechanisms are local config, profile, token stores, cached remote metadata, policy files, content-safety config, and cached pending auth scopes for split browser login.
- Popular skills: No usage telemetry was present in the reviewed source. The most central skills by repository role are `lark-shared`, `lark-drive`, and `lark-event`; other high-signal domains include calendar, IM, docs, base, sheets, markdown, and meeting or standup workflow skills.

## Core Execution Path

The main command path starts in `main.go`, which imports the environment credential extension and calls `cmd.Execute()`. `cmd.Execute()` builds an invocation context, configures shell completion behavior, calls `buildInternal`, installs notices, executes Cobra, emits shutdown lifecycle hooks, and normalizes errors into structured output envelopes.

`buildInternal` creates the root `lark-cli` command and registers built-in groups such as `config`, `auth`, `profile`, `doctor`, `api`, `schema`, `completion`, `update`, and `event`. It then calls `service.RegisterServiceCommandsWithContext` to mount metadata-backed API commands and `shortcuts.RegisterShortcutsWithContext` to mount curated domain workflows. After registration, it installs an unknown-subcommand guard, applies strict-mode pruning, installs platform plugins, applies user policy, wires hooks, and records command inventory for diagnostics.

The generated service command path runs through `cmd/service/service.go`. Each method command receives flags such as `--params`, `--data`, `--as`, `--output`, `--page-all`, `--page-limit`, `--page-delay`, `--format`, `--jq`, `--dry-run`, and `--file` when applicable. Method metadata supplies required scopes, supported identities, docs URLs, risk level, and tips. At runtime the command resolves identity, checks strict mode, validates supported identity, validates mutually exclusive input flags, loads config, checks user scopes where possible, builds the request, supports dry-run, gates high-risk methods behind confirmation, calls the API, and handles pagination and response output.

The shortcut command path runs through `shortcuts/common`. A shortcut declares service, command, description, risk, scopes, conditional scopes, supported auth types, flags, formatting support, tips, dry-run support, validation, execution, and optional post-mount behavior. `runShortcut` resolves identity and config, checks scopes, builds a runtime context, resolves enum and input helpers, validates `jq`, runs shortcut validation, handles dry-run and high-risk confirmation, executes the shortcut, and captures deferred output errors.

The raw API path in `cmd/api/api.go` keeps an escape hatch for unsupported or newly released API calls. It accepts method and path, normalizes full Lark/Feishu URLs or `/open-apis` paths, supports params, data, identity, output, pagination, `jq`, dry-run, and file upload. Raw API errors are marked raw so the caller can see original platform details rather than only shortcut-level hints.

## Architecture

The architecture is a layered CLI plus agent skill system:

- Cobra root and command registry in `cmd/`
- metadata-backed generated service commands in `cmd/service` and `internal/registry`
- curated domain shortcuts in `shortcuts/`
- raw Open API access in `cmd/api`
- schema introspection in `cmd/schema`
- auth, token, profile, and credential providers in `cmd/auth`, `internal/auth`, `internal/credential`, and `extension/credential`
- workspace-aware config in `internal/core` and `cmd/config`
- output, filesystem, and content-safety helpers in `internal/output`, `internal/client`, `internal/vfs`, and `internal/security/contentsafety`
- policy, plugin, and hook extension surfaces in `extension/platform`, `internal/platform`, `internal/cmdpolicy`, and `internal/hook`
- event streaming commands and schemas in `cmd/event`, `internal/event`, and `events/`
- agent-facing skills in `skills/` and `skill-template/`

The command registry has two layers. The first is generated API metadata loaded from embedded files, cache, or remote fetch. `internal/registry/loader_embedded.go` embeds metadata files, while `remote.go` can fetch Open Platform definitions with a 10 MiB cap, five-second timeout, and 24-hour cache under the config directory. The reviewed checkout only embeds `meta_data_default.json`, whose services list is empty, so full API surface reproduction depends on runtime remote metadata or cache.

The second registry layer is shortcuts. `shortcuts/register.go` aggregates domain shortcut packages and mounts them under service groups. If a metadata service command already exists, shortcuts reuse that group; otherwise they create a domain command group. This lets the CLI combine exhaustive API coverage with ergonomic task commands.

Authentication is identity-aware. `cmdutil.ResolveAs` decides between user and bot identity from explicit `--as`, strict-mode forced identity, credential hints, or auto-detection. User access tokens are stored in the keychain; tenant access tokens are fetched and cached. Environment credentials can supply app id, app secret, user token, tenant token, default identity, and strict mode. A sidecar credential and transport path can delegate token injection to a same-host proxy under build tags.

Workspace state is isolated by runtime mode. `internal/core/workspace.go` detects local, OpenClaw, Hermes, and Lark Channel workspaces and maps non-local state under a dedicated runtime subdirectory. Config initialization is blocked in agent workspaces unless forced; the preferred agent path is binding an existing app and identity.

The extension boundary is in-process. Platform plugins are compiled into a fork with blank imports. They can observe commands, wrap command execution, register lifecycle hooks, or install one restriction rule. The host validates plugin metadata, capability declarations, duplicate names, hook consistency, and restriction rules before installing. There is no subprocess or `.so` sandbox boundary for untrusted plugin code.

## Design Choices

The most important design choice is to make the CLI itself carry machine-readable domain contracts. Service metadata supplies parameters, scopes, docs URLs, methods, risk, and identities. Shortcuts add task-level validation, conditional scopes, dry-run behavior, and output shaping. Skills teach the agent how to choose among those surfaces.

Auth is designed around explicit identity and permission feedback. User login supports a device flow with `--no-wait --json`, returning a verification URL and device code so an agent can hand the browser step to the user instead of blocking. Requested scopes can be cached and resumed later with `--device-code`. Permission errors are enriched with console URLs, recommended scopes, and identity-specific instructions: user identity receives `auth login --scope ...` guidance, while bot identity receives console scope-enable guidance.

Strict mode is used as a context and permission control. It can force bot or user identity, hide incompatible identity commands, and keep a hidden locked `--as` flag for compatibility. The help text explicitly says AI agents should not switch strict mode without user confirmation.

Filesystem artifacts use a narrow local-file boundary. The default FileIO provider rejects control characters, absolute paths, symlink escapes, and paths outside the current working directory. Output saving validates response content type, handles binary saves, and returns structured artifact metadata such as saved path, byte count, and content type. Shortcut helpers also define stable artifact layouts such as minute transcript and recording paths.

Policy is applied to the visible and executable command tree. YAML policy and plugin restriction rules can allow, deny, cap risk, constrain identities, and decide whether unannotated commands are allowed. Denied commands are hidden or overridden so the denial envelope wins before the command body can run. Plugin restriction conflicts fail closed; YAML-only policy errors warn and fail open.

Content safety is optional and environment controlled. When enabled, it scans JSON-like output for prompt-injection and system-prompt-leak patterns, can warn or block, and annotates JSON output with alerts. The scanner has max string length, max depth, timeout, and panic recovery. It fails open on provider error, timeout, or panic, which is pragmatic for CLI availability but weaker for security-critical deployments.

## Strengths

The command surface is layered well for coding agents. An agent can start with a domain shortcut, inspect exact fields through `schema`, fall back to generated service commands, and finally use raw `api` when needed. This minimizes prompt-only guessing while preserving escape hatches.

Auth and permission errors are unusually agent-friendly. Device-flow login has an explicit non-blocking mode, permission errors include recommended scopes and next commands, high-risk actions require explicit confirmation, and strict mode keeps identity drift visible.

The shortcut abstraction is a strong reusable design. It centralizes scopes, identities, risk, flags, validation, dry-run, execution, tips, and formatting. This is easier for agents to reason about than scattered command implementations.

The repository treats workspace artifacts as part of the safety model. Relative-path-only file IO, output metadata, artifact naming conventions, and resource ownership recovery hints reduce the chance that an agent writes to surprising locations or misuses downloaded content.

The extension and policy layers show a mature tool-boundary pattern. Command observers, wrappers, lifecycle hooks, restriction rules, policy pruning, denial envelopes, and deterministic plugin install give operators multiple ways to constrain a CLI without rewriting every command.

The event workflow is a useful pattern for long-running domain operations. It exposes schema, jq roots, bounded consumption, timeout, max-event limits, graceful stdin EOF handling, and NDJSON streaming so an agent harness can supervise an event process predictably.

## Weaknesses

The checked-out source does not contain a full generated API metadata snapshot. `meta_data_default.json` has no services, so the real command registry depends on remote metadata fetch or a local cache. That weakens offline reproducibility and makes exact command surface review harder unless a release artifact or pinned metadata file is captured.

The plugin system is not a sandbox for untrusted code. Plugins are compiled into the binary and run in-process. The host validates declarations and recovers from panics, but memory, process, and filesystem isolation are outside this boundary.

Content safety is off by default and fail-open on scan errors, timeouts, and panics. That is reasonable for a CLI that must not break normal output, but it should not be treated as a hard security boundary without additional enforcement.

Scope pre-checks depend on known token scopes. Some external credential paths, including the sidecar pattern, intentionally skip local scope certainty and rely on platform errors or proxy policy. That preserves compatibility but can move verification later in the workflow.

The skill pack is powerful but broad. Domain skills and references can consume substantial context if loaded wholesale. The design needs retrieval discipline: load shared rules plus the specific domain skill, then use `schema` and command help for detail instead of loading every reference.

Some policy behavior trades availability against strictness. Plugin restriction errors fail closed, but YAML-only policy errors warn and fail open. Operators who need hard local policy enforcement must account for that difference.

## Ideas To Steal

Use a three-layer command surface: curated task shortcuts, generated typed API commands, and raw API escape hatch.

Make `schema` a first-class command so agents can inspect parameters, request bodies, response fields, docs URLs, identities, scopes, examples, and strict-mode filtering at runtime.

Represent domain workflows as declarative shortcut structs with scopes, conditional scopes, risk, supported identities, flags, validation, dry-run, and execution hooks.

Treat auth as an agent workflow. Support non-blocking browser handoff, cache pending requested scopes, resume later by device code, and always return structured permission hints.

Use strict identity mode to prune or lock commands for bot-only or user-only environments. Keep hidden compatibility flags locked to the forced identity rather than letting old scripts silently drift.

Make policy affect both visibility and execution. Hide denied commands where possible and also override execution so hidden or directly invoked denied commands return a structured denial.

Use a safe FileIO abstraction for agent-accessible artifacts. Require relative paths, resolve symlinks, reject escapes, and report saved artifacts with structured metadata.

Add content-safety scanning as an output layer, but label whether it is warning-only, blocking, default-on, or fail-open so callers understand the boundary.

Design event commands as supervised subprocess protocols: one event key per process, readiness marker, NDJSON stream, bounded max events, timeout, signal handling, and schema-based filtering.

Ship domain skills with the CLI, but make them teach command selection and verification rather than duplicating every API detail.

## Do Not Copy

Do not copy the Lark/Feishu-specific scopes, service names, URLs, or token flows unless building for that platform.

Do not rely on live remote metadata as the only source of command definitions if reproducibility matters. Pin or vendor the metadata snapshot used for tests and docs.

Do not treat in-process plugins as an untrusted extension sandbox. Use process isolation or a separate policy engine when third-party plugin code is not trusted.

Do not rely on regex content safety as the only protection for prompt injection or data exfiltration. It is useful as a warning and block layer, not as a complete semantic safety system.

Do not silently load every domain skill into an agent context. Load the shared skill, the one relevant domain skill, and then use schema/help commands for the rest.

Do not make dangerous command confirmation a model-only decision. This repo's `--yes` pattern is useful because it requires explicit user approval before retrying high-risk operations.

## Fit For Agentic Coding Lab

Fit is conditional but high value. The repo is not a general coding agent framework, and most commands are bound to Lark/Feishu. Still, it is one of the stronger examples of turning a domain SaaS into a controllable agent tool surface.

It is most relevant for research on domain-specific coding agents that need to work inside a business platform: command registries, schema introspection, identity-aware auth, local artifact safety, policy-constrained command trees, structured error handling, and skill-driven workflow selection.

The most reusable experimental direction is to separate the pattern from the platform: implement a small domain CLI with shortcut declarations, generated command metadata, schema inspection, strict identity mode, safe artifact IO, dry-run, high-risk confirmation, structured errors, and a narrow skill pack. Then measure whether agents make fewer permission, parameter, and artifact mistakes than with raw API docs alone.

## Reviewed Paths

- `/tmp/myagents-research/larksuite-cli/README.md`
- `/tmp/myagents-research/larksuite-cli/main.go`
- `/tmp/myagents-research/larksuite-cli/cmd/build.go`
- `/tmp/myagents-research/larksuite-cli/cmd/root.go`
- `/tmp/myagents-research/larksuite-cli/cmd/global_flags.go`
- `/tmp/myagents-research/larksuite-cli/cmd/platform_bootstrap.go`
- `/tmp/myagents-research/larksuite-cli/cmd/service/service.go`
- `/tmp/myagents-research/larksuite-cli/cmd/api/api.go`
- `/tmp/myagents-research/larksuite-cli/cmd/schema/schema.go`
- `/tmp/myagents-research/larksuite-cli/cmd/auth/auth.go`
- `/tmp/myagents-research/larksuite-cli/cmd/auth/login.go`
- `/tmp/myagents-research/larksuite-cli/cmd/auth/login_scope_cache.go`
- `/tmp/myagents-research/larksuite-cli/cmd/config/init.go`
- `/tmp/myagents-research/larksuite-cli/cmd/config/strict_mode.go`
- `/tmp/myagents-research/larksuite-cli/cmd/event/consume.go`
- `/tmp/myagents-research/larksuite-cli/cmd/event/schema.go`
- `/tmp/myagents-research/larksuite-cli/internal/registry/loader.go`
- `/tmp/myagents-research/larksuite-cli/internal/registry/loader_embedded.go`
- `/tmp/myagents-research/larksuite-cli/internal/registry/remote.go`
- `/tmp/myagents-research/larksuite-cli/internal/registry/meta_data_default.json`
- `/tmp/myagents-research/larksuite-cli/internal/registry/scope_priorities.json`
- `/tmp/myagents-research/larksuite-cli/internal/registry/scope_overrides.json`
- `/tmp/myagents-research/larksuite-cli/internal/cmdutil/factory.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdutil/factory_default.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdutil/identity_flag.go`
- `/tmp/myagents-research/larksuite-cli/internal/core/config.go`
- `/tmp/myagents-research/larksuite-cli/internal/core/workspace.go`
- `/tmp/myagents-research/larksuite-cli/internal/core/notconfigured.go`
- `/tmp/myagents-research/larksuite-cli/internal/auth/token_store.go`
- `/tmp/myagents-research/larksuite-cli/internal/credential/default_provider.go`
- `/tmp/myagents-research/larksuite-cli/extension/credential/env/env.go`
- `/tmp/myagents-research/larksuite-cli/extension/credential/sidecar/provider.go`
- `/tmp/myagents-research/larksuite-cli/extension/transport/sidecar/interceptor.go`
- `/tmp/myagents-research/larksuite-cli/sidecar/protocol.go`
- `/tmp/myagents-research/larksuite-cli/sidecar/hmac.go`
- `/tmp/myagents-research/larksuite-cli/sidecar/server-demo/handler.go`
- `/tmp/myagents-research/larksuite-cli/sidecar/server-demo/allowlist.go`
- `/tmp/myagents-research/larksuite-cli/sidecar/server-demo/audit.go`
- `/tmp/myagents-research/larksuite-cli/shortcuts/register.go`
- `/tmp/myagents-research/larksuite-cli/shortcuts/common/types.go`
- `/tmp/myagents-research/larksuite-cli/shortcuts/common/runner.go`
- `/tmp/myagents-research/larksuite-cli/shortcuts/common/dryrun.go`
- `/tmp/myagents-research/larksuite-cli/shortcuts/common/artifact_path.go`
- `/tmp/myagents-research/larksuite-cli/internal/vfs/localfileio/localfileio.go`
- `/tmp/myagents-research/larksuite-cli/internal/vfs/localfileio/path.go`
- `/tmp/myagents-research/larksuite-cli/internal/client/response.go`
- `/tmp/myagents-research/larksuite-cli/internal/output/errors.go`
- `/tmp/myagents-research/larksuite-cli/internal/output/emit.go`
- `/tmp/myagents-research/larksuite-cli/internal/output/emit_core.go`
- `/tmp/myagents-research/larksuite-cli/internal/output/ownership_recovery.go`
- `/tmp/myagents-research/larksuite-cli/internal/security/contentsafety/config.go`
- `/tmp/myagents-research/larksuite-cli/internal/security/contentsafety/provider.go`
- `/tmp/myagents-research/larksuite-cli/internal/security/contentsafety/scanner.go`
- `/tmp/myagents-research/larksuite-cli/extension/contentsafety/types.go`
- `/tmp/myagents-research/larksuite-cli/extension/contentsafety/registry.go`
- `/tmp/myagents-research/larksuite-cli/extension/platform/README.md`
- `/tmp/myagents-research/larksuite-cli/extension/platform/plugin.go`
- `/tmp/myagents-research/larksuite-cli/extension/platform/rule.go`
- `/tmp/myagents-research/larksuite-cli/extension/platform/builder.go`
- `/tmp/myagents-research/larksuite-cli/internal/platform/host.go`
- `/tmp/myagents-research/larksuite-cli/internal/platform/staging.go`
- `/tmp/myagents-research/larksuite-cli/internal/platform/error.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdpolicy/engine.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdpolicy/apply.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdpolicy/resolver.go`
- `/tmp/myagents-research/larksuite-cli/internal/cmdpolicy/yaml/schema.go`
- `/tmp/myagents-research/larksuite-cli/internal/hook/install.go`
- `/tmp/myagents-research/larksuite-cli/internal/hook/emit.go`
- `/tmp/myagents-research/larksuite-cli/internal/event/registry.go`
- `/tmp/myagents-research/larksuite-cli/events/register.go`
- `/tmp/myagents-research/larksuite-cli/events/im/register.go`
- `/tmp/myagents-research/larksuite-cli/events/im/message_receive.go`
- `/tmp/myagents-research/larksuite-cli/events/im/native.go`
- `/tmp/myagents-research/larksuite-cli/skills/lark-shared/SKILL.md`
- `/tmp/myagents-research/larksuite-cli/skills/lark-drive/SKILL.md`
- `/tmp/myagents-research/larksuite-cli/skills/lark-event/SKILL.md`
- `/tmp/myagents-research/larksuite-cli/skill-template/master-skill-template.md`
- `/tmp/myagents-research/larksuite-cli/tests/cli_e2e/`
- `/tmp/myagents-research/larksuite-cli/scripts/skill-format-check`

## Excluded Paths

- `/tmp/myagents-research/larksuite-cli/.git/`
- Full line-by-line review of every shortcut implementation outside the common registration and runner paths
- Full line-by-line review of every skill reference file under `skills/*/references/`
- Exhaustive review of every CLI end-to-end test fixture under `tests/cli_e2e/`
- Live Lark/Feishu API calls, browser auth flows, and tenant-specific console configuration
- Release packaging, npm artifacts, generated binaries, and lockfile metadata not needed for architecture review
- Build-tag sidecar demo execution; only protocol, provider, interceptor, and demo server source were reviewed
- External hosted Open Platform documentation beyond URLs and docs references present in the source
