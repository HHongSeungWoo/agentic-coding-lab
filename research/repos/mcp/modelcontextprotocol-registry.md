# modelcontextprotocol/registry

- URL: https://github.com/modelcontextprotocol/registry
- Category: mcp
- Stars snapshot: 6,796 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 276037b1ad877fa2990c2aed5bafb90a737da9d6
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strongly in-scope as the official MCP server metadata registry and server.json/API reference, but not sufficient by itself for safe coding-agent auto-install. It is best reused as a canonical metadata feed and validation shape, with separate security scanning, package provenance checks, tool introspection, sandbox policy, and install verification layered downstream.

## Why It Matters

This is the official community registry service for MCP servers. It defines the `server.json` metadata shape, hosts the official REST API, ships the `mcp-publisher` CLI, and codifies how publishers prove namespace and package ownership. For coding agents, this is the most important upstream candidate feed for MCP server discovery because it normalizes package references, transports, runtime arguments, environment variables, remotes, lifecycle status, and registry-managed metadata.

The registry is explicitly a metaregistry. It stores metadata pointing to npm, PyPI, NuGet, OCI, MCPB, or remote endpoints; it does not host server code, rank servers, scan quality, run servers, or solve execution policy. That boundary is useful: it gives agents a stable discovery substrate without pretending discovery equals trust.

## What It Is

The repo contains two Go binaries: `cmd/registry` for the hosted API server and `cmd/publisher` for publisher workflow. The API uses Huma on the Go standard library mux, PostgreSQL for storage, embedded JSON schemas for validation, JWTs for short-lived registry auth, and package-registry validators for publish-time ownership checks.

The data model centers on `pkg/api/v0.ServerJSON`, which includes schema URL, server name, description, repository metadata, version, packages, remotes, icons, website URL, and publisher-provided `_meta`. API responses wrap that in registry-managed `_meta` under `io.modelcontextprotocol.registry/official`, including status, published/updated timestamps, and `isLatest`.

## Research Themes

- Token efficiency: Useful as a compact metadata source compared with crawling every MCP server repo. The API supports cursor pagination, `updated_since`, `version=latest`, and name substring search, which lets agents sync deltas instead of repeatedly loading full catalogs.
- Context control: Strong metadata boundaries: package type, runtime arguments, environment variables, remote URLs, repository source/subfolder, and lifecycle status are separate fields. It still lacks tool schema summaries, capability classes, token cost estimates, or risk labels.
- Sub-agent / multi-agent: No multi-agent runtime. It is a registry/control-plane component that agent systems can use before spawning specialist installers, scanners, or tool evaluators.
- Domain-specific workflow: Strong for MCP publication and discovery. The workflow is publish package first, create `server.json`, authenticate namespace, validate, publish metadata, then let clients or subregistries consume it.
- Error prevention: Good schema/semantic validation, exact validation issue paths, version range rejection, URL restrictions, namespace auth, package ownership checks, duplicate remote URL checks, transaction locks, status handling, and many targeted regression tests.
- Self-learning / memory: None directly. The registry can support downstream memory by serving stable server/version/status metadata and incremental sync cursors.
- Popular skills: MCP server discovery, publisher UX, registry schema design, namespace authorization, package provenance checks, subregistry ETL, install metadata normalization, and security triage.

## Core Execution Path

Registry server startup:

1. `cmd/registry/main.go` parses `--version`, loads `MCP_REGISTRY_*` config, connects to PostgreSQL with bounded retry, runs embedded SQL migrations, builds `service.NewRegistryService`, optionally imports seed data, initializes telemetry, then starts `api.NewServer`.
2. `internal/api/server.go` wraps the mux with NUL-byte rejection, trailing-slash canonicalization, CORS, request metrics, root UI serving, `/metrics`, and Huma routes for `/v0` and `/v0.1`.
3. `internal/api/router/v0.go` registers health, ping, version, server listing/detail/version endpoints, edit/status endpoints, auth endpoints, publish, and validate.

Publish path:

1. A publisher runs `mcp-publisher init`, edits `server.json`, runs `mcp-publisher login <method>`, then `mcp-publisher publish [PATH]`.
2. The CLI reads `server.json`, loads `~/.config/mcp-publisher/token.json`, and posts JSON to `{registry}/v0/publish` with `Authorization: Bearer <token>`.
3. `internal/api/handlers/v0/publish.go` validates the bearer token, checks `publish` permission against the server name, runs schema-version plus semantic validation, then calls `RegistryService.CreateServer`.
4. `internal/service/registry_service.go` runs publish in one DB transaction: publisher `_meta` size check, optional external package ownership validation, per-server advisory lock, duplicate remote URL check, version count/duplicate/latest checks, unmark old latest if needed, insert row with official metadata, and structured phase timing logs.
5. PostgreSQL stores natural keys `(server_name, version)`, official metadata columns, and the original server JSON as JSONB.

Discovery path:

1. Consumers call `GET /v0.1/servers` or `/v0/servers` with optional cursor, limit, `updated_since`, search, version, and `include_deleted`.
2. `internal/database/postgres.go` builds indexed SQL filters, escapes LIKE metacharacters for search, uses row-constructor cursor comparison, hides deleted rows by default, and returns server JSON plus official metadata.
3. Downstream aggregators are expected to poll infrequently, store their own copy, and add curation, ratings, security scans, or extra `_meta`.

## Architecture

- `cmd/registry`: API server binary, config loading, PostgreSQL connection/migration, seed import, telemetry, graceful shutdown.
- `cmd/publisher`: `mcp-publisher` CLI with `init`, `login`, `logout`, `publish`, `status`, and `validate`.
- `pkg/model` and `pkg/api/v0`: shared server.json and API response types.
- `internal/api`: Huma HTTP route registration, middleware, handlers, OpenAPI-backed docs, root UI.
- `internal/auth`: registry JWT signing/validation and permission matching.
- `internal/api/handlers/v0/auth`: GitHub access token, GitHub Actions OIDC, DNS, HTTP, configurable OIDC, and anonymous local auth exchanges.
- `internal/service`: business rules for publish, update, status changes, latest-version selection, duplicate remote URL checks, and transaction boundaries.
- `internal/database`: PostgreSQL interface, migrations, schema, indexed list/detail queries, status updates, advisory locks.
- `internal/validators`: schema loading, semantic validation, package registry ownership validation, and validation result formatting.
- `docs/reference`: generic/official API docs, OpenAPI spec, server.json docs, CLI command reference, registry authorization.
- `docs/modelcontextprotocol-io`: publisher-facing quickstart, auth, package-type, remote-server, aggregator, versioning, moderation docs.

## Design Choices

The registry favors canonical metadata over curation. It deliberately omits ranking, broad search, tags/categories, download counts, source hosting, execution, and hosting. That keeps operational burden low and pushes value-added scoring to subregistries.

The trust model is layered but narrow. Namespace auth proves the publisher controls a GitHub user/org or domain namespace. Package validation checks that the referenced artifact advertises the same MCP server name. Registry metadata status lets publishers/admins deprecate or delete versions. None of those prove the server is safe to run.

The API keeps both `/v0` and `/v0.1` routes registered. Docs say v0.1 is frozen for API stability, while the CLI still posts to `/v0` endpoints. This keeps old clients working but gives integrators a versioned target.

Validation is intentionally staged. `/validate` performs full embedded schema plus semantic validation. Publish/edit currently perform schema-version and semantic checks, then publish-time package ownership checks. The enhanced-validation design document states full schema validation in publish is a future stage, not fully enforced in the current path.

The database moved from JSON-heavy storage to hybrid relational plus JSONB. Core lookup/status fields are columns for consistency and index performance, while server JSON remains intact as JSONB for flexible metadata.

## Strengths

- Official, machine-readable MCP metadata format with concrete package, remote, runtime, env-var, argument, repository, icon, and status fields.
- Strong publisher UX: `init`, `validate`, login methods, publish, status updates, clear migration links, and detailed validation paths.
- Useful discovery API for agents and subregistries: cursor pagination, incremental sync with `updated_since`, status filtering, latest-version filter, and simple search.
- Practical concurrency and consistency controls: per-server advisory locks, duplicate version rejection, latest-version uniqueness, remote URL conflict checks, and status recalculation.
- Good security hardening in auth paths: Ed25519 JWTs, short-lived registry tokens, GitHub OIDC audience binding, DNS/HTTP signed timestamp window, HTTP no-redirect fetch, private-IP/loopback/CGNAT/link-local blocking, key response size cap, and NUL-byte URL rejection.
- Package ownership checks cover npm `mcpName`, PyPI/NuGet README marker, OCI image label, and MCPB host/hash requirements.
- Tests cover publish, validation, server listing, deleted filtering, auth permissions, DNS/HTTP crypto paths, SSRF blocking, package registry validators, DB locking, latest recalculation, and status behavior.

## Weaknesses

- The registry is not an install-safety system. It has no malware scanning, maintainer reputation, signed attestations, runtime sandbox policy, permission taxonomy, tool introspection result, or verified install transcript.
- Publish/edit do not yet run full JSON Schema validation in the main path; full validation is available through `/validate`.
- Package ownership markers are weak trust signals. npm `mcpName`, README strings, and OCI labels can prove metadata alignment but not code safety or artifact integrity.
- OCI validation intentionally skips failure on HTTP 429 rate limiting, which is good for publisher UX but weakens strict verification.
- MCPB requires `fileSha256`, but the registry only checks field presence and URL accessibility; clients must validate downloaded bytes.
- `mcp-publisher logout` removes local token files but does not revoke server-side tokens. Tokens are short-lived, but still stored as local plaintext JSON with `0600` permissions.
- Discovery is intentionally simple: no categories, tags, ranking, advanced search, install resolver, compatibility matrix, or quality score.
- Some docs are derived or stale around older paths, and `complete.md` can drift from source docs; the latest reviewed commit was itself a docs sync fix.

## Ideas To Steal

- Treat registry metadata as canonical but incomplete: use it to queue downstream verification jobs, not to authorize immediate execution.
- Copy the split between publisher-provided server JSON and registry-managed response metadata. Agents need to know which fields came from authors and which fields came from trusted registry infrastructure.
- Use short-lived capability tokens with resource-pattern permissions for publish/edit flows.
- Use package-specific ownership validators before accepting install metadata.
- Keep `updated_since` plus `include_deleted=true` semantics for incremental sync. Agents need deletion/deprecation events, not only active rows.
- Use explicit validation issue objects with type, severity, path, message, and reference. This is far better for agent remediation than one string error.
- Store runtime arguments, environment variables, secrets, and file path variables as structured inputs rather than free-form install commands.
- Keep status as lifecycle metadata instead of mutating or removing history; agents can make policy decisions from active/deprecated/deleted transitions.

## Do Not Copy

- Do not treat package ownership validation as a run-safety guarantee.
- Do not skip full schema validation on the final write path if building a stricter agent registry.
- Do not allow rate-limit bypasses to silently count as verification success for high-risk package types.
- Do not rely on publisher-provided descriptions for capability or permission classification.
- Do not expose server metadata directly to auto-install without repository review, package digest/lock capture, tool-schema introspection, sandboxing, and secret-handling policy.
- Do not copy the absence of categories/tags if the downstream use case is coding-agent tool routing; agents need risk and capability facets.
- Do not assume registry status `active` means maintained, secure, or useful.

## Fit For Agentic Coding Lab

Fit is high as an upstream source and schema reference. The registry gives Agentic Coding Lab a concrete shape for MCP server identity, versioning, publication provenance, package references, install-time inputs, transport URLs, and lifecycle state.

Fit is medium for direct installer UX. `server.json` contains enough to start designing package-specific installers, but the repo intentionally does not define a complete local install planner, sandbox profile, permission prompt, or verification harness.

Fit is low as a trust authority for autonomous coding agents. A safe agent workflow should import registry records, fetch exact package/repository metadata, verify package digest or lock, inspect MCP tools/resources/prompts, classify read/write/network/secret/file-system risks, run smoke tests in a sandbox, and cache a signed local verification note before exposing the server to an agent.

## Reviewed Paths

- `/tmp/myagents-research/modelcontextprotocol-registry/README.md`: project status, quick start, architecture summary, auth methods, metaregistry role.
- `/tmp/myagents-research/modelcontextprotocol-registry/go.mod`: Go module and major dependencies including Huma, pgx, JWT, jsonschema, go-containerregistry, OIDC, telemetry.
- `/tmp/myagents-research/modelcontextprotocol-registry/Makefile` and `docker-compose.yml`: build/test/dev-compose targets, ko image build, local Postgres/dev config, registry environment variables.
- `/tmp/myagents-research/modelcontextprotocol-registry/cmd/registry/main.go`: server startup, config, DB retry/migration, seed import, telemetry, shutdown.
- `/tmp/myagents-research/modelcontextprotocol-registry/cmd/publisher/main.go`, `cmd/publisher/commands/*.go`, and `cmd/publisher/auth/*.go`: CLI dispatch, init detection, token storage, validate/publish/status calls, GitHub, GitHub OIDC, DNS/HTTP, and anonymous auth flows.
- `/tmp/myagents-research/modelcontextprotocol-registry/pkg/model/types.go`, `pkg/model/constants.go`, and `pkg/api/v0/types.go`: server.json data model, package/transport/input types, schema constants, official response metadata.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/api/server.go`, `internal/api/router/*.go`, and `internal/api/handlers/v0/*.go`: middleware, route registration, publish/validate/list/detail/edit/status/health/version behavior, root UI serving boundary.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/api/handlers/v0/auth/*.go` and `internal/auth/*.go`: auth exchanges, JWT generation/validation, permissions, namespace blocking hook, SSRF defenses, DNS/HTTP crypto validation.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/service/*.go`: publish/update/status service logic, version comparison, latest recalculation, duplicate remote URL checks, transaction phases.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/database/*.go` and selected `internal/database/migrations/*.sql`: DB interface, PostgreSQL implementation, migrations, current hybrid schema, indexes, advisory locks, filters, status fields, latest healing.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/validators/*.go`, `internal/validators/registries/*.go`, and `internal/validators/schemas/README.md`: schema loading, semantic validation, package registry ownership checks, embedded schema provenance.
- `/tmp/myagents-research/modelcontextprotocol-registry/docs/reference/api/*.md`, `docs/reference/api/openapi.yaml`, `docs/reference/server-json/*.md`, `docs/reference/cli/commands.md`, and `docs/modelcontextprotocol-io/*.md`: API contract, server.json contract, official requirements, auth, package types, quickstart, aggregators, remote servers, moderation/versioning context.
- `/tmp/myagents-research/modelcontextprotocol-registry/docs/design/*.md`: architecture, principles, roadmap, ecosystem vision, enhanced-validation design.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/**/*_test.go`, `cmd/publisher/**/*_test.go`, `tests/integration/main.go`, `tests/integration/README.md`, `scripts/test_publish.sh`, and `scripts/test_endpoints.sh`: coverage of publish/discovery/auth/validation/database/status and end-to-end publication scripts.
- Git metadata and GitHub REST repository metadata: reviewed commit, commit message, default branch, stars, pushed/updated timestamps, forks, issues, license metadata.

## Excluded Paths

- `/tmp/myagents-research/modelcontextprotocol-registry/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/modelcontextprotocol-registry/go.sum` and `deploy/go.sum`: generated dependency lockfiles; dependency architecture reviewed through `go.mod` and source imports.
- `/tmp/myagents-research/modelcontextprotocol-registry/complete.md`: concatenated documentation mirror for LLM/quickstart consumption; excluded as derived content because source docs were reviewed directly.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/validators/schemas/*.json`: generated/synced schema snapshots from `modelcontextprotocol/static`; reviewed provenance and current schema constant, not every generated schema body.
- `/tmp/myagents-research/modelcontextprotocol-registry/docs/design/*.pdf` and `docs/**/ecosystem-diagram.excalidraw.svg`: binary/visual design assets; Markdown design docs were sufficient for architecture and scope.
- `/tmp/myagents-research/modelcontextprotocol-registry/internal/api/handlers/v0/ui_index.html`: root browser UI only; API/server execution path reviewed through handlers and middleware.
- `/tmp/myagents-research/modelcontextprotocol-registry/deploy/`: Pulumi/Kubernetes infrastructure skimmed for deployment context, excluded from core analysis because registry runtime, validation, and publication behavior live in `cmd`, `internal`, `pkg`, and docs.
- `/tmp/myagents-research/modelcontextprotocol-registry/scripts/mirror_data/`, `tools/admin/`, and seed data beyond role checks: operational helpers and sample/mirror workflows, not the main publication/discovery path.
- `/tmp/myagents-research/modelcontextprotocol-registry/LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `CHANGES.md`, and `CLAUDE.md`: skimmed for governance/security/release context, not central to execution-path analysis.
