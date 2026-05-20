# aipotheosis-labs/aci

- URL: https://github.com/aipotheosis-labs/aci
- Category: tool-use
- Stars snapshot: 4,777 (GitHub REST API repository endpoint, captured 2026-05-20)
- Reviewed commit: 0006bee0d94f4324bd127e967c9f152aec1a473a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong practical reference for agent tool-use infrastructure: a registry of app/function schemas, semantic tool discovery, model-facing schema filtering, credential brokering, per-agent app permissions, per-project app/function enablement, and direct REST or connector execution. Best ideas to steal are the layered permission model, `visible` schema extension, dynamic discovery before execution, and central auth/linked-account boundary. Do not copy its weak spots around broad discovery defaults, sensitive logging, natural-language policy checks, and limited sandboxing.

## Why It Matters

ACI is one of the more concrete open-source examples of "tool use as infrastructure" rather than "tool use as prompt format." It does not stop at returning OpenAI or Anthropic tool schemas. It owns the whole path from app catalog to credentials to function execution, with separate records for projects, agents, app configurations, linked accounts, and tool-call logs.

That makes it useful for Agentic Coding Lab because coding agents need exactly these boundaries: discover a small set of relevant tools, expose only safe arguments to the model, validate model arguments before side effects, inject hidden operational defaults, route through an execution adapter, and record what happened. ACI also shows the risks of this approach: once a platform brokers many third-party APIs for agents, logging, credential handling, permissions, and sandbox boundaries become first-class design work.

## What It Is

ACI is a monorepo with:

- `backend/`: FastAPI server, PostgreSQL plus pgvector data model, app/function registry ingestion CLI, REST and connector function executors, OAuth/API-key/no-auth linked accounts, quota/rate limit logic, tests, and deployment code.
- `frontend/`: Next.js developer portal for browsing apps, configuring linked accounts, selecting functions, using a playground, and viewing logs.
- `backend/apps/`: JSON registry reviewed at this commit with 98 app directories and 987 function definitions.

The repo itself is the ACI platform. The README links to separate repositories for the Unified MCP server, Python SDK, TypeScript SDK, and agent examples. Those external repos are important to the ecosystem but were not reviewed as part of this note because the assignment scope is `aipotheosis-labs/aci`.

## Research Themes

- Token efficiency: Strong. `/apps/search` and `/functions/search` use OpenAI embeddings plus pgvector sorting so an agent can request relevant apps/functions by intent instead of loading the full catalog. Function definitions can be returned as `basic`, OpenAI, OpenAI Responses, or Anthropic formats. The `visible` schema extension removes hidden parameters before the tool schema reaches the model.
- Context control: Strong but uneven. `allowed_only` can restrict search to enabled functions under apps allowed for the current agent, and the frontend playground caps selected functions through `NEXT_PUBLIC_AGENT_MAX_FUNCTIONS`. However, broader discovery remains possible when callers do not opt into the allowed-only path, and `/agent/chat` accepts selected function names then fetches definitions without the same filtering used by execution.
- Sub-agent / multi-agent: Moderate. The `Agent` model gives each logical actor its own API key, allowed app list, and custom instructions. This is useful for multi-agent permission separation, but there is no orchestration, delegation protocol, subagent scheduler, or inter-agent memory.
- Domain-specific workflow: High. The registry includes coding-adjacent and agentic operations such as GitHub, Vercel, Render, Supabase, Cloudflare, Sentry, E2B, Browserbase, Frontend QA Agent, and Agent Secrets Manager. The integration guide gives repeatable app/function schema authoring patterns.
- Error prevention: Moderate to high. Inputs are validated against filtered JSON Schema, hidden required defaults are injected, app/function enablement is checked before execution, credentials are centrally encrypted and refreshed, API quotas/rate limits exist, and tests cover many failure modes. Gaps remain around destructive-action labels, data-level scopes, redaction, egress controls, and robust policy failure behavior.
- Self-learning / memory: Low. The platform stores app configuration, linked accounts, secrets, website evaluation results, usage logs, `last_used_at`, and search/eval data, but it does not learn from tool-call outcomes or update a durable agent policy from feedback.
- Popular skills: Tool registry ingestion, schema-to-provider format conversion, semantic tool search, progressive tool disclosure, credential brokering, OAuth linking, app/function allowlists, connector execution, REST credential injection, E2B sandbox delegation, browser QA workbench, and function-search evaluation.

## Core Execution Path

The registry path starts in `backend/apps/<app>/app.json` and `functions.json`. App files define metadata, categories, active/visibility flags, supported security schemes, and optional default credentials. Function files define globally unique function names, descriptions, tags, visibility, protocol, REST metadata or connector metadata, and JSON Schema parameters with ACI's `visible` extension.

The admin CLI loads those files with `upsert-app` and `upsert-functions`. `upsert-app` can render Jinja secrets from `.app.secrets.json`, validates with Pydantic, generates an app embedding from name/display/provider/description/categories, and creates or updates the DB record with a dry-run diff unless `--skip-dry-run` is supplied. `upsert-functions` validates each function schema, ensures all functions belong to one app, generates embeddings from name/description/parameters, and creates or updates DB rows.

Runtime requests use `X-API-KEY`. The dependency layer hashes the provided key with HMAC, finds the API key row, rejects disabled/deleted keys, loads the owning agent and project, then enforces daily and monthly quotas for search and execute routes. API keys are stored encrypted, while lookup uses `key_hmac`.

Discovery goes through `/apps/search` or `/functions/search`. If an intent is supplied, the server embeds it and sorts apps/functions by cosine distance in pgvector. Function search can optionally filter to allowed apps and enabled functions by intersecting `agent.allowed_apps` with project app configurations. Results are formatted through `format_function_definition`; OpenAI and Anthropic formats run through `filter_visible_properties`, so invisible headers, defaults, and other system parameters are not exposed to the model.

Execution goes through `/functions/{function_name}/execute`. The server retrieves the function, verifies the app is configured for the project, checks that the app configuration is enabled, checks that the agent is allowed to use the app, checks that the function is enabled under the app configuration, and finds an enabled linked account for `linked_account_owner_id`. It then gets credentials from the linked account or app defaults, refreshes OAuth2 tokens when expired, runs a custom instruction violation check when configured, selects an executor by protocol/security scheme, and executes.

The base executor validates model input against the visible schema only, injects required invisible defaults from the full schema, removes `None` values, and delegates. REST execution builds an `httpx.Request`, injects API key or OAuth2 token into header/query/body/cookie based on the security scheme, sends the request, and returns JSON or text. Connector execution derives `aci.server.app_connectors.<app>` and class/method names from `APP__FUNCTION`, imports the class, constructs it with linked account and credentials, then calls the method with validated parameters.

The playground path is split. `/v1/agent/chat` streams an OpenAI response with selected function definitions, but actual tool execution happens in the frontend: tool invocations call `/v1/functions/{name}/execute` with the selected linked-account owner ID, then add the result back to the chat. This mirrors the common "model chooses tool, host executes tool" pattern and keeps side effects behind the function execution API.

## Architecture

The central database model is:

- `Project`: tenant container with org id, visibility access, quotas, agents, app configurations, and linked accounts.
- `Agent`: logical actor under a project with `allowed_apps`, `custom_instructions`, and one API key in the current design.
- `APIKey`: encrypted key plus HMAC lookup, status, and agent binding.
- `App`: third-party integration metadata, security schemes, default credentials, visibility, active flag, function relationship, and embedding.
- `Function`: callable operation with app relationship, description, tags, protocol, protocol data, parameters, response schema, visibility, active flag, and embedding.
- `AppConfiguration`: per-project app enablement, selected security scheme, optional OAuth override, `all_functions_enabled`, and `enabled_functions`.
- `LinkedAccount`: per-project, per-app, per-owner credential record with security scheme, encrypted credentials, enabled flag, and `last_used_at`.
- `Secret` and `WebsiteEvaluation`: connector-specific state for Agent Secrets Manager and Frontend QA Agent.

The backend is organized around schema modules, CRUD modules, FastAPI routes, function executors, app connectors, middleware, and CLI commands. Protocol support is intentionally small: `rest` for direct HTTP APIs and `connector` for custom Python code. Auth support is API key, OAuth2, and no-auth. Search support depends on OpenAI embeddings and pgvector.

The frontend is a developer portal rather than the core runtime. The relevant agent surfaces are app configuration, linked-account setup, function selection, playground chat, tool result rendering, logs, and usage dashboards.

ACI also has safety and operations layers: KMS-backed encryption types for credentials, HMAC API-key lookup, PropelAuth for developer portal org access, IP rate limiting, quota enforcement through billing plans, Sentry/Logfire structured logging, backend CI, CodeQL, and a Claude-powered integration review workflow.

## Design Choices

The most useful design choice is the schema visibility split. Tool definitions keep full execution schemas, but model-facing definitions include only `visible` fields. Required invisible fields must have defaults or be objects that can receive defaults recursively. This lets an integration hide `Content-Type`, API-specific headers, or other operational fields while still constructing a complete HTTP request.

Permissions are layered rather than single-point. Project visibility controls public/private app/function access. Agent `allowed_apps` controls which apps a specific API key can execute. App configuration controls whether the app is enabled for the project and which functions are enabled. Linked account status controls whether a particular end-user credential can be used. Execution enforces all layers even if discovery is broad.

ACI separates model-facing function definitions from host-side credential injection. Authentication details are never meant to appear as function parameters. API keys, OAuth2 tokens, refresh tokens, and OAuth client secrets are stored centrally, encrypted in JSONB or binary columns, and injected by the executor immediately before the external request.

The registry format is deliberately simple: app and function JSON files plus a CLI. That makes integrations easy to review and generate, while Pydantic validators catch schema mistakes such as missing `visible`, missing `additionalProperties`, bad REST top-level locations, unsupported protocol metadata, or mismatched app/function names.

The connector protocol is a pragmatic escape hatch. Most APIs can be represented as REST functions, but Gmail, E2B, Render database queries, Frontend QA Agent, Agent Secrets Manager, and other custom flows can use Python connectors.

The platform treats search as an API, not just a UI feature. Both app and function search can be called by agents with intent text, result limits, offsets, categories/app filters, and provider-specific output formats.

The workbench features are specialized connectors rather than a general agent runtime. E2B runs Python code inside an E2B sandbox using the user's E2B API key. Frontend QA Agent starts an asynchronous browser-use evaluation, stores status/results, rate-limits by URL, validates URLs against common SSRF cases, and tells callers to poll for results.

## Strengths

ACI gives a full execution path that many tool-use repos omit: registry, schema validation, discovery, formatted tool definitions, credential linking, permission checks, execution, logging, and tests.

The `visible` parameter mechanism is a high-value pattern for coding tools. It creates a clean separation between model intent fields and host-only operational fields without needing two separate schemas.

The app/function search APIs are directly relevant to token pressure. A coding agent can discover tools by intent, request basic definitions first, then pull provider-specific schemas only for chosen functions.

The credential model is stronger than ad hoc environment variables. Linked accounts isolate end-user credentials by project/app/owner, OAuth2 refresh is centralized, API keys and OAuth secrets are encrypted at rest, and clients receive scrubbed public credential views.

Execution checks are explicit and test-covered. The route verifies existence, app configuration, app enablement, agent app permission, function enablement, linked account existence, and linked account enabled status before side effects.

The test suite covers search filtering, execution failures, API-key and OAuth linked accounts, hidden default injection, custom instruction blocking, app configuration changes, rate/quota behavior, encrypted credentials, and connector behavior.

The CLI workflow is useful for registry governance. Dry-run diffs, schema validation, embedding regeneration only when relevant fields change, and fuzzy natural-language execution tests make integration additions more reviewable.

The frontend playground shows a realistic host loop: selected tools go to the model, tool calls come back to the host, the host executes with a linked account, and results return to the model stream.

## Weaknesses

Discovery defaults are permissive. `/functions/search` only filters to enabled and allowed functions when `allowed_only` or the older `allowed_apps_only` flag is true. Without that flag, a caller can retrieve public functions outside its agent's allowed app list, although execution still blocks side effects. Agentic Coding Lab should make least-privilege discovery the default.

`/agent/chat` fetches selected function definitions by name without applying the same project, active, app, and function enablement filters used by `/functions/search` or `/functions/{name}/execute`. Execution remains protected, but unauthorized function schemas can still enter the model context if a caller submits those names.

Sensitive logging needs stronger boundaries. Middleware logs POST request bodies, function execution logs serialized function inputs and result data, and log filtering mainly constrains field names rather than redacting secrets inside JSON. API-key linked-account creation and agent-secret tools are especially sensitive surfaces.

Natural-language custom instructions are a useful policy layer but not a sufficient safety boundary. The check depends on an external model call, adds latency and cost, can be bypassed by missing instructions, and the intended "let request pass on inference failure" path appears brittle because later code still expects a parsed response object.

OAuth2 account linking has pragmatic compromises. The state payload is signed but not encrypted, and the source notes no expiration check. Custom redirect URLs are supported for OAuth overrides, which is useful for white-label flows but should be paired with strict validation and expiry in a production policy.

Permissions are mostly app/function level. There are no first-class destructive-action labels, approval requirements, per-parameter policies, resource scopes, tenant data filters, or typed risk classes. A function such as creating a repository and a function such as searching code both fit the same enablement model unless custom instructions are added.

REST execution is direct network egress from the backend. There is no per-app egress allowlist beyond registry `server_url`, no retry policy, no circuit breaker, no response-size guard before logging, and no isolation boundary around connector code except when a connector delegates to an external sandbox such as E2B.

Frontend QA Agent has useful URL validation, but it still runs browser automation from the server process and its own source recommends stronger sandboxing. DNS rebinding, redirects, and browser-level fetch behavior need more than a one-time hostname/IP check.

CI has good backend and CodeQL coverage, but the integration review workflow watches `apps/**` while integration files live under `backend/apps/**` in this repo, so that review automation may not trigger for the main registry path.

## Ideas To Steal

Use one canonical tool schema with a model-facing projection. Keep full JSON Schema for execution, add a `visible` list for model-exposed fields, and validate model input only against the visible projection before injecting host-only defaults.

Make discovery a first-class, permission-aware API. `search_tools(intent, allowed_only=true, format=basic)` should be the default path before loading full schemas.

Layer permissions: project visibility, agent tool allowlist, workspace configuration, individual function enablement, linked account status, and runtime policy. Execution should enforce all layers even if discovery or UI selection fails.

Separate credentials from tool arguments. Store and refresh credentials centrally, expose only public security scheme summaries, and inject credentials at the last possible execution step.

Support multiple schema output formats from the same function record. Basic, OpenAI, OpenAI Responses, and Anthropic definitions can all be projections of the same registry entry.

Add an integration CLI with dry-run diffs, strict schema validation, selective embedding regeneration, and natural-language fuzzy tests that generate tool inputs from prompts.

Use connector protocol sparingly for workflows that REST schemas cannot express, such as sandbox execution, browser QA, secrets management, OAuth quirks, and SDK-heavy APIs.

Record execution telemetry as structured envelopes with start/end times, success/error, input, output size, and linked account owner. Pair this with redaction and risk policy before adopting.

Model workbench-like tasks as asynchronous functions with status polling, cooldowns, and stored results. Frontend QA Agent is a useful pattern for long-running browser inspection.

## Do Not Copy

Do not make broad tool discovery the default for a scoped agent. Least-privilege search should be opt-out, not opt-in.

Do not expose function definitions through chat or playground endpoints without reusing the same permission checks used by execution.

Do not log raw request bodies, tool inputs, credential creation payloads, or tool results without field-level redaction and route-specific scrubbers.

Do not rely on natural-language custom instructions as the main guard for dangerous actions. Use typed risk labels, scoped credentials, explicit approvals, and deterministic policy checks.

Do not treat in-process connector code as sandboxed. Registry authors are trusted code authors unless each connector runs behind a separate containment boundary.

Do not execute arbitrary registered REST targets without an egress policy, response-size limits, timeout classes, and audit metadata for external side effects.

Do not store permission state only as string arrays once the system needs large-scale governance, delegation, reviews, or history. Move to relational policy records or versioned policy documents before it becomes hard to audit.

Do not copy OAuth state handling without expiry, replay protection, and clear redirect validation.

## Fit For Agentic Coding Lab

Fit is strong. ACI is directly in scope for `tool-use` because it shows how a coding-agent lab can move from static tool lists to a governed tool platform. The best local artifact to build from this review is a permission-aware tool registry with schema projections, semantic discovery, credential injection, deterministic execution checks, and structured telemetry.

For Agentic Coding Lab, the most valuable pattern is "discover small, expose filtered schema, execute through host." The Lab should combine ACI's registry and auth ideas with stricter defaults: allowed-only discovery, typed risk levels, approval gates for destructive tools, redacted logs, egress controls, and sandboxed execution for code/browser/shell connectors.

ACI is less useful as a complete agent runtime. It does not provide planning, subagent orchestration, memory, repair loops, or coding-specific verification flows. It should be treated as a tool-control-plane reference that can sit below those agent layers.

## Reviewed Paths

- `/tmp/myagents-research/aipotheosis-labs-aci/README.md`: Product overview, MCP/SDK positioning, VibeOps use case, feature claims, external repo links, and local development entry points.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/README.md`: Backend architecture, local Docker setup, seed flow, app/function CLI usage, test workflow, admin CLI, and function-search evaluation pipeline.
- `/tmp/myagents-research/aipotheosis-labs-aci/INTEGRATION_GUIDE.md`: App/function JSON contract, security schemes, REST versus connector protocols, `visible` parameter rules, examples, fuzzy testing, and frontend validation flow.
- `/tmp/myagents-research/aipotheosis-labs-aci/SECURITY.md`: Vulnerability reporting, incident process, safe harbor, and scope.
- `/tmp/myagents-research/aipotheosis-labs-aci/CLAUDE.md`: Repo-local architecture summary and developer command map; used as orientation only, then verified against source.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/apps`: Registry structure and representative apps/functions, including Brave Search, arXiv, Gmail, E2B, Frontend QA Agent, Agent Secrets Manager, Browserbase, GitHub, Vercel, Render, Supabase, Cloudflare, and Sentry. Counted 98 `functions.json` files and 987 function records.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/cli/commands/upsert_app.py`, `upsert_functions.py`, `fuzzy_test_function_execution.py`, and `backend/scripts/seed_db.sh`: Registry ingestion, validation, embedding generation, dry-run behavior, natural-language test helper, and local seeding.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/common/db/sql_models.py`, CRUD modules, schemas, `processor.py`, `validator.py`, `embeddings.py`, `encryption.py`, and `custom_sql_types.py`: Core data model, permission/credential records, schema filtering, hidden default injection, JSON Schema validation, embeddings, HMAC lookup, and encrypted credential storage.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/server/routes/apps.py`, `functions.py`, `app_configurations.py`, `linked_accounts.py`, `projects.py`, and `agent.py`: Discovery, function definition formatting, execution checks, app configuration, account linking, project/agent management, and playground chat.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/server/function_executors` and `backend/aci/server/app_connectors`: REST execution, credential injection, connector import/call path, E2B sandbox delegation, Frontend QA Agent workbench, Gmail connector, Render connector, and Agent Secrets Manager.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/server/security_credentials_manager.py`, `oauth2_manager.py`, `dependencies.py`, `acl.py`, `quota_manager.py`, middleware, and logging filters: API-key validation, OAuth2 refresh/linking, PropelAuth org access, quota/rate limiting, request context logging, and log-field filtering.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/server/tests`, `backend/aci/common/tests`, `backend/aci/cli/tests`: Tests for function search, execution, schema filtering, hidden defaults, linked accounts, custom instructions, quotas, encrypted credentials, app configuration, and connector behavior.
- `/tmp/myagents-research/aipotheosis-labs-aci/frontend/src/app/playground`, `frontend/src/hooks/use-tool-execution.ts`, `frontend/src/lib/api/appfunction.ts`, `frontend/src/app/logs/page.tsx`, and selected app configuration components: Playground tool loop, selected function control, host-side function execution from the browser, and log display.
- `/tmp/myagents-research/aipotheosis-labs-aci/.github/workflows`: Backend CI, CodeQL, dev portal workflow, and integration review workflow.
- Git metadata and GitHub REST repository endpoint: reviewed commit, branch, commit date, star/fork/open issue counts, topics, license, default branch, and repository timestamps.

## Excluded Paths

- `/tmp/myagents-research/aipotheosis-labs-aci/.git/`: VCS storage only. Used through `git rev-parse`, `git show`, branch, and status commands for provenance.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/uv.lock` and `/tmp/myagents-research/aipotheosis-labs-aci/frontend/package-lock.json`: Generated lockfiles. Dependency boundaries were reviewed through `pyproject.toml` and selected `package.json` files instead.
- `/tmp/myagents-research/aipotheosis-labs-aci/frontend/public/*`: Binary images, icons, thumbnails, and SVG/logo assets. Excluded because they do not define tool discovery, auth, permissions, execution, sandboxing, or safety behavior.
- Most of `/tmp/myagents-research/aipotheosis-labs-aci/frontend/src/components/ui`, chart components, layout components, date utilities, styling, and static home/pricing/settings UI: UI-only implementation details. Selected playground, app configuration, logs, and API-client paths were reviewed because they affect agent tool execution or observability.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/aci/alembic/versions`: Migration history generated from DB model changes. Reviewed only at the schema level through current SQLAlchemy models and high-level file listing.
- `/tmp/myagents-research/aipotheosis-labs-aci/backend/deployment` and Docker image build details: Deployment infrastructure was outside the tool-use execution path, except for confirming CI/deployment shape from high-level files.
- External linked repositories `aci-mcp`, `aci-python-sdk`, `aci-typescript-sdk`, and `aci-agents`: Excluded because this assignment targets `aipotheosis-labs/aci`. Their existence is noted as integration surface but their code was not reviewed here.
- Third-party API definitions inside large app files such as Slack/GitHub/Browserbase were sampled for schema patterns, not exhaustively audited endpoint by endpoint. The review focused on registry mechanics and execution behavior rather than validating every external API wrapper.
