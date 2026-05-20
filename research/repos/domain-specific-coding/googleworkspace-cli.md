# googleworkspace/cli

- URL: https://github.com/googleworkspace/cli
- Category: domain-specific-coding
- Stars snapshot: 26,440 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: a3768d0e82ad83cca2da97724e46bea4ff0e6dbd
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for domain-specific agent tooling around a real business API surface. Best ideas are dynamic command generation from provider schemas, a small helper boundary for true orchestration, generated agent skills, scoped auth presets, dry-run/schema workflows, and context-window guardrails. Do not copy the static recipe layer or docs verbatim without validation; several recipe/help details can drift from implemented flags.

## Why It Matters

`gws` is a domain-specific CLI for Google Workspace that explicitly targets both humans and AI agents. It is useful for Agentic Coding Lab because it turns a huge, fast-changing business API surface into a compact command grammar: `gws <service> <resource> [sub-resource] <method> [flags]`.

The repo is especially relevant for coding agents that need to act inside a productivity domain without bespoke MCP servers for every operation. It shows how to combine runtime provider discovery, structured JSON output, local authentication, generated skills, helper commands, dry-run safety, and prompt-injection/content scanning behind one executable boundary.

The strongest research value is not Google Workspace itself. It is the domain workflow pattern: expose raw provider API operations mechanically, then add a narrow set of handwritten helpers only when schema-driven calls cannot cover orchestration, format translation, or cross-service workflows.

## What It Is

The repository is a Rust Cargo workspace with two crates:

- `crates/google-workspace`: reusable library crate for Discovery document models, service registry, validation, error types, and HTTP client helpers.
- `crates/google-workspace-cli`: binary crate for the `gws` executable, auth commands, runtime command construction, request execution, helper commands, generated skills, setup flow, output formatting, and token storage.

At runtime, `gws` resolves a service alias such as `drive`, fetches the corresponding Google Discovery document, builds a `clap` command tree for resources and methods, reparses the user's arguments, validates params/body, obtains an OAuth token if possible, and executes the HTTP request. The repo also ships generated `skills/*/SKILL.md` files, a Gemini extension manifest, a `CONTEXT.md` for agents, personas, recipes, and CI that regenerates skills from Discovery API changes.

This is not an officially supported Google product. The reviewed version is `0.22.5` in `crates/google-workspace-cli/Cargo.toml`.

## Research Themes

- Token efficiency: Strong but partly advisory. The CLI defaults to structured JSON and supports table/YAML/CSV formats plus `--page-all` NDJSON. `CONTEXT.md` tells agents to use field masks and schema introspection before large calls, but field masks are passed through `--params`, not a real top-level `--fields` flag.
- Context control: Strong concept. `CONTEXT.md`, generated service skills, helper skills, personas, and recipes externalize domain workflow memory so agents do not need a long system prompt for every Workspace task.
- Sub-agent / multi-agent: Weak runtime support, moderate artifact support. There is no subagent engine, but skills/personas/recipes can be loaded selectively by different agents or roles.
- Domain-specific workflow: Very strong. Services, helpers, workflows, event subscriptions, Gmail send/reply/forward/read/watch, Drive upload, Sheets read/append, Calendar agenda/insert, Model Armor, and Apps Script push are all represented as domain commands.
- Error prevention: Strong in code-level validation and CI, mixed in generated artifacts. Path traversal checks, resource-name validation, URL encoding, schema validation, encrypted credentials, terminal sanitization, dry-run, and access-not-configured hints are useful. Static recipe commands are not fully validated against helper flags.
- Self-learning / memory: Weak. The repo stores static skills, personas, recipes, cache files, and credentials, but it does not learn from past agent actions or user corrections.
- Popular skills: No usage telemetry was reviewed. Locally important agent-facing skills include `gws-shared`, `gws-drive`, `gws-gmail`, `gws-calendar`, `gws-modelarmor`, `gws-workflow`, `gws-gmail-send`, `gws-gmail-triage`, `gws-events-subscribe`, and persona/recipe skills for executive assistant, project manager, HR, sales ops, team lead, and researcher roles.

## Core Execution Path

The main raw API path is a two-phase command parse:

1. `main.rs` loads `.env`, initializes logging, and extracts the first non-flag argument as a service or top-level command.
2. Top-level commands `schema`, `generate-skills`, and `auth` are handled directly.
3. For API services, `parse_service_and_version` resolves an alias from `services::SERVICES` or a `service:version` form.
4. `discovery::fetch_discovery_document` retrieves and caches the Google Discovery document under the user's `~/.config/gws/cache`.
5. `commands::build_cli` injects service-specific helper commands, then recursively adds Discovery resource/method subcommands with common flags such as `--params`, `--json`, `--upload`, `--output`, pagination, `--format`, `--dry-run`, and `--sanitize`.
6. `main.rs` reparses the subcommand arguments, checks whether a helper handles the request, and otherwise resolves the target Discovery method.
7. `executor::execute_method` parses `--params` and `--json`, validates required params and request bodies, renders the URL, validates upload/output paths, authenticates, handles dry-run output, sends the request, formats JSON/binary responses, paginates if requested, and optionally annotates or blocks output via Model Armor.

The helper path is separate but shares infrastructure. `helpers::get_helper` maps selected services to a `Helper` trait implementation. A helper injects `+verb` commands and returns `Ok(true)` when it handled a command. Examples include `drive +upload`, `gmail +send`, `gmail +triage`, `events +subscribe`, `docs +write`, `script +push`, and synthetic `workflow` commands that suppress raw Discovery resources and expose only cross-service helpers.

The skill-generation path uses the same command metadata. `generate_skills.rs` fetches Discovery docs, builds `clap` command trees, renders service/helper skills, reads persona and recipe TOML registries, and writes `skills/*/SKILL.md` plus `docs/skills.md`. CI has an hourly workflow to regenerate skills when upstream Discovery documents change.

## Architecture

The architecture has four layers:

- Discovery and service registry: `crates/google-workspace/src/discovery.rs`, `services.rs`, `validate.rs`, and `client.rs` define provider schemas, known service aliases, validation, and HTTP retry utilities.
- CLI runtime: `main.rs`, `commands.rs`, `schema.rs`, `executor.rs`, `formatter.rs`, `output.rs`, and `error.rs` provide dynamic command construction, schema introspection, request execution, output formatting, sanitized terminal/error output, and exit codes.
- Authentication and local state: `auth.rs`, `auth_commands.rs`, `credential_store.rs`, `token_storage.rs`, `oauth_config.rs`, `setup.rs`, and `setup_tui.rs` manage OAuth setup/login/logout/export/status, env-token and credential-file precedence, encrypted credentials, encrypted token caches, ADC fallback, proxy-aware token refresh, and quota project headers.
- Domain helpers and skills: `helpers/*`, `registry/personas.toml`, `registry/recipes.toml`, `generate_skills.rs`, `skills/*`, `docs/skills.md`, `CONTEXT.md`, and `gemini-extension.json` expose bounded domain workflows and agent-consumable instructions.

CI covers cargo tests, clippy, formatting, cargo-deny, cargo-audit, coverage, Nix checks, skill regeneration drift, skill validation, changeset policy, and an AGENTS policy that rejects generated Google API crates in favor of runtime Discovery.

## Design Choices

Dynamic Discovery is the central design choice. Rather than vendoring generated Rust crates for each Google API, the CLI treats Google's Discovery documents as the command registry. This keeps the raw command surface current as APIs change and makes service support mostly a registry entry plus a Discovery URL pattern.

The helper boundary is intentionally narrow. `helpers/README.md` says helpers must complement Discovery commands, not duplicate them. Good helper reasons are multi-step orchestration, format translation, multi-API composition, complex body construction, multipart upload, and workflow recipes. Bad helper reasons are single API wrappers, unbounded response-field flags, and re-exposing provider parameters that already fit `--params`.

Authentication is layered by environment and durability. Token precedence is raw access token, explicit credentials file, encrypted credentials, plaintext fallback, and ADC. `auth login` defaults to a deliberately limited scope set because broad/restricted Google scopes can fail for unverified OAuth apps. Helpers can request operation-specific scopes, and long-running helpers can ask an `AccessTokenProvider` for fresh tokens.

Output is both human- and agent-facing. JSON is the default machine-readable format; table, YAML, CSV, paginated NDJSON, binary downloads, and structured error JSON are supported. Terminal-facing messages sanitize control characters and dangerous Unicode.

The repo uses skills as generated domain documentation, not as the source of truth. Command behavior comes from Rust code plus Discovery docs; skills are regenerated artifacts that point agents toward the right commands, warnings, examples, and prerequisites.

## Strengths

Runtime Discovery is a strong command-registry pattern for large SaaS domains. It prevents agents from depending on a stale hardcoded operation list while keeping command syntax regular.

The helper design is disciplined. Prefixing helpers with `+` makes tool boundaries visible: raw API method calls stay schema-driven, and handwritten helpers are reserved for real orchestration or translation.

The auth story is practical for agents. It supports local browser OAuth, exported credentials for headless use, service accounts, pre-obtained tokens, ADC, encrypted storage, proxy-aware refresh, scope presets, and `auth status/export/logout`.

Safety and verification primitives are concrete. `gws schema` lets agents inspect params/body shape before acting. `--dry-run` renders the HTTP method, URL, query params, body, and multipart state without sending. Mutating helper skills include confirmation cautions. CI checks code, dependencies, generated skills, and policy.

Context-control guidance is explicit. `CONTEXT.md` tells agents to use schema discovery first, apply field masks, avoid massive Workspace JSON, and dry-run mutations. Generated skills and recipes let agents load only service-specific instructions.

Security hardening is better than typical CLI glue. The repo validates paths, rejects dangerous Unicode/control characters, encodes URL path segments, validates resource names, strips terminal escapes, encrypts credentials/token caches, caps Retry-After delays, and gives specific API-enable hints for `accessNotConfigured`.

## Weaknesses

The agent docs have drift. `CONTEXT.md` lists `--fields '<MASK>'` as a key flag, but the dynamic command builder does not define a global or method-level `--fields` flag. Field masks need to be passed as `--params '{"fields": "..."}'`. This matters because an agent following the context file literally can generate invalid commands.

Static recipes are not validated against helper flags. For example, `registry/recipes.toml` and generated recipe skills use `gws docs +write --document-id ...`, while the implemented helper and generated `gws-docs-write` skill use `--document`. That is a concrete example of recipe drift from executable command metadata.

The raw executor does not use the shared retry wrapper. `send_with_retry` exists and is used by some helpers, but `executor::execute_method` sends raw Discovery API requests with `request.send()`. Generic API calls therefore have less retry resilience than selected helper paths.

Request-body schema validation is useful but strict. Unknown fields are rejected against the loaded Discovery schema, and the validator does not appear to honor every flexible JSON Schema case such as arbitrary `additionalProperties`. That can prevent bad payloads, but it can also reject newly added or loosely typed provider fields until Discovery/schema handling catches up.

The skills layer is large and can become context-heavy. Service skills like Drive enumerate many resources/methods. Without selective loading, agents may import too much Workspace surface when a narrow helper skill or one schema command would suffice.

The CLI exposes raw destructive API methods. Skill generation blocks a few high-risk method entries and shared skill guidance says to confirm write/delete operations, but the executable raw API surface still allows delete/update methods when a user or agent calls them directly.

## Ideas To Steal

Use provider schemas as the raw command registry for large domains. Keep the command grammar stable and push endpoint volatility into fetched/cached schemas.

Separate raw operations from helpers with a visible naming convention such as `+verb`. Make helper admission rules explicit: orchestration, format translation, multi-service composition, long-running workflow, or body construction only.

Generate agent skills from the actual CLI command tree. Skills should be downstream artifacts of executable metadata, not a parallel manually maintained API description.

Ship a compact `CONTEXT.md` or equivalent domain context file with hard rules for agents: inspect schema first, constrain output fields, dry-run mutations, and avoid large JSON dumps.

Make `--dry-run` return structured request previews. Agents can use that as a verification step before user-visible actions or before asking for approval.

Use auth presets and scope filters to lower onboarding failure. Default to practical minimal scopes, expose readonly/full/custom modes, and document why broad scopes may fail.

Provide structured error JSON with sanitized human hints. Keep stdout parseable for agents while using stderr for diagnostics and recovery instructions.

Add a generated-skill drift check to CI. If domain docs are generated from live schemas, run generation in CI and surface drift before stale skills become agent instructions.

## Do Not Copy

Do not copy the `--fields` documentation pattern without verifying executable flags. If field masks are provider query params, document them consistently as `--params`.

Do not maintain static recipe strings without command validation. Recipe examples should be tested against the generated `clap` metadata or rendered from the same command definitions as helper skills.

Do not expose raw delete/update operations to autonomous agents without an approval layer. `--dry-run` and skill cautions help, but an agent-facing harness should enforce policy outside the CLI too.

Do not rely on runtime Discovery alone for high-risk workflows. Cache staleness, schema quirks, provider outages, and strict validation edge cases still need fallback paths and clear recovery.

Do not ingest full service skills when a task needs one helper or one method schema. Add retrieval rules or skill slicing so agents load the smallest relevant artifact.

Do not copy Model Armor integration as a universal solution. It is Google Cloud specific, needs `cloud-platform` scope and configured templates, and should be an optional boundary rather than a hard dependency for all agent workflows.

## Fit For Agentic Coding Lab

Fit is conditional but strong for `domain-specific-coding`. The repo is a real CLI product, not a generic coding-agent framework. It belongs in this category because it ships agent skills, agent context rules, and domain workflow patterns for a high-value business API surface.

The best local adaptation is an "agent-safe domain CLI" pattern: dynamic provider schema registry, structured JSON output, schema introspection command, dry-run request previews, narrow helpers, generated skills, role recipes, context-window field-mask rules, explicit auth scope modes, sanitized structured errors, and CI checks that generated agent artifacts match executable command metadata.

The main caution for Agentic Coding Lab is artifact drift. If skills, recipes, and context files become trusted agent instructions, they must be generated or validated against actual command definitions. Otherwise they become another stale prompt pack.

## Reviewed Paths

- `/tmp/myagents-research/googleworkspace-cli/README.md`
- `/tmp/myagents-research/googleworkspace-cli/CONTEXT.md`
- `/tmp/myagents-research/googleworkspace-cli/AGENTS.md`
- `/tmp/myagents-research/googleworkspace-cli/gemini-extension.json`
- `/tmp/myagents-research/googleworkspace-cli/Cargo.toml`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace/Cargo.toml`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace/src/discovery.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace/src/services.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace/src/client.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace/src/validate.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/Cargo.toml`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/main.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/commands.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/executor.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/schema.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/auth.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/auth_commands.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/credential_store.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/token_storage.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/error.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/output.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/generate_skills.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/README.md`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/mod.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/drive.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/docs.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/gmail/mod.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/gmail/send.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/gmail/triage.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/events/subscribe.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/workflows.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/src/helpers/modelarmor.rs`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/registry/personas.toml`
- `/tmp/myagents-research/googleworkspace-cli/crates/google-workspace-cli/registry/recipes.toml`
- `/tmp/myagents-research/googleworkspace-cli/docs/skills.md`
- `/tmp/myagents-research/googleworkspace-cli/docs/CONTRIBUTING.md`
- `/tmp/myagents-research/googleworkspace-cli/lefthook.yml`
- `/tmp/myagents-research/googleworkspace-cli/.github/workflows/ci.yml`
- `/tmp/myagents-research/googleworkspace-cli/.github/workflows/coverage.yml`
- `/tmp/myagents-research/googleworkspace-cli/.github/workflows/audit.yml`
- `/tmp/myagents-research/googleworkspace-cli/.github/workflows/policy.yml`
- `/tmp/myagents-research/googleworkspace-cli/.github/workflows/generate-skills.yml`
- Representative generated skills: `skills/gws-shared/SKILL.md`, `skills/gws-drive/SKILL.md`, `skills/gws-gmail-send/SKILL.md`, `skills/gws-modelarmor/SKILL.md`, `skills/gws-modelarmor-sanitize-response/SKILL.md`, and `skills/recipe-share-event-materials/SKILL.md`.
- Structure review of all `skills/*/SKILL.md` names from the file listing, plus targeted search for field-mask docs, `send_with_retry` usage, destructive-skill blocking, and recipe/helper flag drift.

## Excluded Paths

- `/tmp/myagents-research/googleworkspace-cli/.git/`: VCS internals; reviewed commit captured separately.
- `/tmp/myagents-research/googleworkspace-cli/Cargo.lock`, `pnpm-lock.yaml`, and `flake.lock`: dependency lockfiles; noted existence but not line-reviewed because the research target is agent/domain workflow design, not dependency audit.
- `/tmp/myagents-research/googleworkspace-cli/art/` and `demo.gif`: demo/visual assets, not command or agent workflow logic.
- `/tmp/myagents-research/googleworkspace-cli/docs/logo.jpg`, `docs/demo.tape`, and remote README badge/image assets: presentation-only assets.
- `/tmp/myagents-research/googleworkspace-cli/npm/`: install/run wrapper for npm distribution; relevant to packaging but not central to command registry, auth, helpers, or agent context patterns.
- `/tmp/myagents-research/googleworkspace-cli/scripts/`: release, coverage, art, and version-sync helper scripts; CI and source files gave enough verification context for this review.
- Unread portions of very large Gmail helper tests and all generated skill files not named above: sampled and searched for relevant patterns; full exhaustive line review would duplicate the generated skill index.
- Live Google Workspace APIs and OAuth flows: not executed because the task is repository pattern review and no Workspace credentials were provided.
