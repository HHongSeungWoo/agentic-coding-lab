# taylorwilsdon/google_workspace_mcp

- URL: https://github.com/taylorwilsdon/google_workspace_mcp
- Category: mcp
- Stars snapshot: 2,506 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 0d1475cc73628bf16d45df6f5ecad65243ac04f9
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong case study for a high-side-effect business-domain MCP server. Best reusable patterns are centralized OAuth scope maps, per-tool auth decorators, service/tier/permission filtering, OAuth 2.1 session binding, typed schemas for complex edits, and SSRF/local-file guardrails. Do not copy the default broad surface, bearerless attachment URLs, or reliance on client-side approval hints for dangerous actions.

## Why It Matters

Google Workspace is a useful stress test for agent tool safety because the same MCP server can read private context and perform irreversible business actions: send email, alter calendar events, share Drive files, edit Docs/Sheets/Slides, publish Forms, modify contacts, post Chat messages, and run Apps Script.

For Agentic Coding Lab, this is not a coding-assistant subsystem directly. It matters as a mature MCP design sample for credential scoping, tool grouping, generated schemas, OAuth/token storage, and side-effect boundaries in tools that agents naturally want to call.

## What It Is

`workspace-mcp` is a Python/FastMCP server and CLI exposing Google Workspace services over MCP. The reviewed package version is `1.21.0` and covers Gmail, Drive, Calendar, Docs, Sheets, Slides, Forms, Chat, Tasks, Contacts, Apps Script, and Custom Search.

The repo includes:

- A stdio and streamable-HTTP MCP server.
- Legacy OAuth 2.0 and OAuth 2.1 modes.
- Public-client PKCE support, external bearer-token mode, stateless HTTP mode, local/GCS credential stores, and optional OAuth proxy disk/Valkey storage.
- A `workspace-cli` wrapper and a Claude Code style `managing-google-workspace` skill with per-service reference docs.
- Docker and Helm deployment artifacts, with the Helm chart marked as user-submitted and potentially out of date.

## Research Themes

- Token efficiency: Moderate. Tool tiers (`core`, `extended`, `complete`), service filtering, pagination tokens, batch reads, and Markdown exports reduce unnecessary tool/schema/context load, but the default still imports the whole Workspace surface.
- Context control: Strong. Tools are grouped by service, tier, read-only mode, granular permission mode, and OAuth scope; local file reads default to the managed attachment directory.
- Sub-agent / multi-agent: Limited. The server supports multi-user OAuth 2.1 sessions but does not orchestrate subagents or multi-agent workflows.
- Domain-specific workflow: Strong. The repo maps business workflows into explicit tools and a companion skill router with service-specific references.
- Error prevention: Strong in auth/path/network areas; weaker on human approval because write tools rely on MCP annotations and client policy, not server-side confirmation gates.
- Self-learning / memory: Not a focus. Credential/session caches exist, but no agent memory or learning loop.
- Popular skills: Includes `skills/managing-google-workspace`, a non-user-invocable routing skill for 114 tools plus per-service parameter references.

## Core Execution Path

`main.py` loads environment variables, parses CLI flags, resolves transport, service list, tool tier, read-only mode, and granular permission entries. It imports selected service modules, wraps `server.tool()` to track registrations, sets enabled services for OAuth scope generation, filters registered tools, then starts either stdio or streamable HTTP.

Each service module registers tools with `@server.tool(...)`, `ToolAnnotations`, `@handle_http_errors(...)`, and `@require_google_service(...)` or `@require_multiple_services(...)`. The service decorator removes the injected Google API client from the MCP schema, resolves required scopes, obtains credentials, builds the Google API service, logs the tool/user/service, calls the original function, and closes the service.

In OAuth 2.0 mode, tool schemas include `user_google_email` unless `USER_GOOGLE_EMAIL` is injected by `SecureFastMCP.call_tool()`. In OAuth 2.1 mode, `user_google_email` is removed from schemas and resolved from the authenticated FastMCP context. The runtime rejects token/session/user mismatches and checks that available scopes satisfy the tool's required scopes.

For HTTP OAuth 2.1, `core/server.py` configures FastMCP's `GoogleProvider` or a custom `ExternalOAuthProvider`, attaches session/auth middleware, optionally uses encrypted disk or Valkey OAuth proxy storage, and supports an allowed dynamic-client redirect URI allowlist. In stdio mode, a minimal local callback server handles OAuth redirects and attachment serving.

## Architecture

The architecture is organized by cross-cutting auth/core modules and per-service tool modules:

- `core/server.py`: shared `SecureFastMCP` instance, OAuth 2.1 provider setup, middleware, health, callback, and attachment routes.
- `main.py`: CLI/env configuration, service import selection, transport startup, and deployment mode checks.
- `auth/scopes.py`: centralized Google OAuth scope constants, service scope maps, read-only maps, and hierarchy-aware scope checks.
- `auth/permissions.py`: cumulative per-service permission levels, including Gmail levels and a special Tasks `manage` level that denies delete/clear-completed actions.
- `auth/service_decorator.py`: tool-level auth injection, OAuth 2.0/OAuth 2.1 mode detection, service-account domain-wide delegation, session/user binding, and required-scope attachment.
- `auth/google_auth.py`: OAuth flow creation, PKCE verifier handling, state validation, callback token exchange, refresh-token preservation, credential refresh, and credential lookup.
- `auth/credential_store.py`: local JSON and GCS credential store backends.
- `auth/oauth21_session_store.py`: in-memory session maps plus shared OAuth state file handling.
- `core/tool_registry.py` and `core/tool_tier_loader.py`: post-registration tool filtering.
- `core/utils.py` and `core/http_utils.py`: file allowlist, sensitive-path blocking, SSRF-safe fetch, DNS pinning, redirect validation, and common error handling.
- Service modules under `gmail/`, `gdrive/`, `gcalendar/`, `gdocs/`, `gsheets/`, `gslides/`, `gforms/`, `gchat/`, `gtasks/`, `gcontacts/`, `gappsscript/`, and `gsearch/`.

## Design Choices

The repo chooses one broad Workspace gateway rather than many small MCP servers. It mitigates that breadth with service filtering, tier filtering, read-only mode, and granular per-service permissions.

Scopes are centralized and then attached to tools through decorators. This keeps OAuth consent, runtime credential validation, and tool filtering aligned better than hand-maintained per-tool checks.

OAuth 2.1 is treated as the multi-user HTTP path. User identity comes from the validated token/session rather than a model-supplied `user_google_email`, which is the right direction for remote MCP deployments.

Tool annotations are used consistently to advertise read-only, destructive, idempotent, and open-world hints. They improve client UX but are not server-side approval controls.

Complex schemas are generated from Python type hints and Pydantic models. Docs batch operations use strict discriminated Pydantic models with `extra="forbid"`; tests keep golden schemas for Docs and Contacts.

Local file reads are intentionally narrow by default. The attachment directory is allowed, `ALLOWED_FILE_DIRS` can expand scope, and sensitive paths such as `.env`, `.ssh`, `.aws`, gcloud config, `/etc/passwd`, and common credential files are blocked even inside allowlisted directories.

## Strengths

Credential scoping is unusually deliberate for an MCP server. Enabled services drive OAuth scope requests, read-only mode swaps scope maps, granular permissions override broad service maps, and runtime checks account for Google's broader-scope hierarchy.

OAuth/session binding is strong. OAuth state is random, expiring, persisted with file locks and `0600` permissions, consumed on callback, and bound to sessions when available. OAuth 2.1 sessions reject cross-account access attempts.

Credential storage has real hardening. Local credential files are URL-encoded to prevent traversal/collisions and written as `0600` under `0700` directories. GCS storage avoids user enumeration, supports CMEK verification, and uses generation preconditions to avoid stale concurrent token writes.

Network/file guardrails are concrete. Remote URL uploads use SSRF-safe streaming, private/internal IP rejection, DNS pinning, redirect revalidation, disabled proxy trust, URL redaction in many errors, and size limits. Local upload paths are canonicalized and allowlisted.

Tool grouping is practical. `--tools`, `WORKSPACE_MCP_TOOLS`, `--tool-tier`, `WORKSPACE_MCP_TOOL_TIER`, `--read-only`, and `--permissions service:level` give operators multiple ways to reduce blast radius.

Tests cover the high-risk plumbing: credential path security, GCS atomic writes, PKCE, OAuth callback state fallback, OAuth 2.1 session store, permission parsing, read-only scope generation, local path validation, SSRF helpers, callback server behavior, and schema golden files.

## Weaknesses

The default mode is still broad. Without flags, all services and many write-capable tools are imported, and scope generation can request a large Workspace consent surface.

There are no server-side human confirmation gates for high-impact actions. Sending mail, sharing files, deleting calendar events, updating Apps Script code, running script functions, and batch-editing docs/sheets/slides happen in the tool call; the server relies on OAuth consent, tool annotations, and the MCP client to prompt or approve.

Auditability is mostly operational logging, not a durable audit trail. Logs include useful user/tool/service lines, but there is no structured append-only event log, request ID chain, before/after diff store, or policy decision record. Some logs include sensitive business context such as search queries, file names, file paths, and at least one raw URL path before redaction.

Local Google credentials are plaintext JSON protected by filesystem permissions, not application-level encryption. CLI token storage and OAuth proxy disk/Valkey storage use Fernet encryption, but the main local credential store does not.

Attachment serving is bearerless. `/attachments/{file_id}` returns temporary files by UUID with in-memory metadata and expiry, but any party with the URL can fetch the content while the process retains it.

Safety limits are uneven. Gmail URL attachments enforce 25 MB, Drive URL uploads cap at 2 GB, but 2 GB is still large for an agent tool and some Google API downloads read response content into memory without a comparable global budget.

Granular permissions are mostly scope-level. Only Tasks adds semantic action denial for a middle permission level; most services are `readonly` vs `full`, so actions such as Drive sharing or Docs batch mutation are not separately policy-gated once the write scope is available.

The Helm chart is caveated as user-submitted and may be stale. It advertises security controls, but defaults such as `readOnlyRootFilesystem: false`, disabled network policy, and an apparently unused `/app/.credentials` mount need deployment review before adoption.

## Ideas To Steal

Use one central scope registry and have every tool attach required scopes through a decorator. Then reuse the same metadata for OAuth consent, read-only filtering, permission-mode filtering, and runtime validation.

Make OAuth 2.1 identity authoritative. In remote MCP mode, remove user identity from model-controlled tool parameters and derive it from the verified access token/session.

Provide multiple operator controls over the tool surface: service allowlist, tiers, global read-only mode, and granular service permissions.

Add MCP `ToolAnnotations` consistently, but pair them with real server-side enforcement for policy-critical operations.

Use strict Pydantic schemas for high-impact batch operations. The Docs operation schema is a good example of replacing free-form JSON with discriminated operation types and forbidden extra fields.

Copy the SSRF pattern: resolve and validate host, reject non-global IPs, pin the connection to the validated IP, preserve Host/SNI, disable environment proxy trust, and revalidate every redirect.

Keep credential-store implementations explicit and tested. URL-encoded filenames, `0600` files, `0700` directories, GCS generation preconditions, and optional CMEK checks are all reusable patterns.

Ship a companion skill/reference layer for large tool suites so agents have routing and parameter guidance without stuffing every detail into one prompt.

## Do Not Copy

Do not expose a default all-tools Workspace surface to agents. Start from read-only, service-scoped, and tier-scoped deployments.

Do not rely on OAuth scopes or MCP annotations as the only guard for business side effects. Add server-side confirmation, policy, dry-run, or approval records for send/share/delete/run actions.

Do not publish bearerless attachment URLs unless the deployment accepts URL capability semantics and short-lived leakage risk.

Do not store local refresh tokens in plaintext JSON if the deployment threat model includes host compromise or shared machines.

Do not log raw user queries, file paths, URLs, recipients, subjects, or document names without a redaction and retention policy.

Do not copy the 2 GB remote upload budget as a default agent limit. Use much lower defaults plus explicit operator overrides.

Do not treat the Helm chart as production-ready without rechecking runtime user, credential directory wiring, read-only filesystem, network policy, TLS, OAuth 2.1, and persistent token storage.

## Fit For Agentic Coding Lab

Fit is conditional but useful. This is not a coding support system like a test harness, memory engine, or code-review MCP. It is a strong reference for how a real high-privilege business-domain MCP server handles auth, schemas, scoping, and side effects.

Agentic Coding Lab should mine it for patterns that transfer to coding tools: central permission metadata, identity-bound auth decorators, strict schemas for batch edits, tiered tool registration, SSRF/path hardening, and tests around token/session boundaries. It should avoid the broad default surface and add stronger approval/audit layers before adapting similar write-capable tools.

## Reviewed Paths

- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/README.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/SECURITY.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/pyproject.toml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/manifest.json`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/server.json`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/fastmcp.json`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/main.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/fastmcp_server.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/server.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/tool_registry.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/tool_tier_loader.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/tool_tiers.yaml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/utils.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/http_utils.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/attachment_storage.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/storage.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/core/cli.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/scopes.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/permissions.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/service_decorator.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/google_auth.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/oauth_config.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/oauth21_session_store.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/credential_store.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/auth_info_middleware.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/mcp_session_middleware.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/external_oauth_provider.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/oauth_callback_server.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/auth/port_resolver.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gmail/gmail_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gmail/gmail_helpers.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdrive/drive_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdrive/drive_helpers.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gcalendar/calendar_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdocs/docs_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdocs/operation_schemas.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdocs/docs_markdown.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdocs/docs_markdown_writer.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gdocs/managers/header_footer_manager.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gsheets/sheets_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gslides/slides_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gforms/forms_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gchat/chat_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gtasks/tasks_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gcontacts/contacts_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gappsscript/apps_script_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gappsscript/README.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/gsearch/search_tools.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/skills/managing-google-workspace/SKILL.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/skills/managing-google-workspace/references/server-options.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/Dockerfile`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/docker-compose.yml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/helm-chart/workspace-mcp/README.md`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/helm-chart/workspace-mcp/values.yaml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/helm-chart/workspace-mcp/templates/deployment.yaml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/helm-chart/workspace-mcp/templates/secret.yaml`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/auth/test_credential_security.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/auth/test_oauth21_session_store.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/auth/test_google_auth_pkce.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/auth/test_google_auth_callback_refresh_token.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/auth/test_gcs_credential_store.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/test_permissions.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/test_scopes.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/test_main_permissions_tier.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/core/test_validate_file_path.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/core/test_attachment_route.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/core/test_allowed_redirect_uris.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/gdrive/test_ssrf_protections.py`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/gdocs/golden/docs_tool_schemas.json`
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/tests/gcontacts/golden/contacts_tool_schemas.json`

## Excluded Paths

- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/.git/`: VCS internals; exact reviewed commit recorded separately.
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/uv.lock`: generated dependency lockfile; reviewed package metadata, source, and tests instead of lock entries.
- `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/.venv/`, `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/__pycache__/`, `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/build/`, `/tmp/myagents-research/taylorwilsdon-google_workspace_mcp/dist/`: generated or local dependency/build artifacts; not present or not relevant to design review.
- README badges, screenshots, videos, and website-linked images: marketing/UI assets; not part of the MCP execution path.
- Most per-service parameter reference files under `skills/managing-google-workspace/references/`: sampled through the router and server-options docs; executable tool source and schemas were reviewed directly.
- Most service-specific unit tests outside auth, permissions, schemas, path/SSRF, and attachment routes: excluded after sampling because the review focus was MCP/auth/safety architecture rather than API-by-API output formatting.
- `tests/gappsscript/manual_test.py`: manual integration helper requiring external Google services; not needed for static architecture review.
- `LICENSE`, chart helper templates, HPA/PDB/service/ingress templates, and package registry metadata files such as `smithery.yaml` and `glama.json`: legal, packaging, or deployment-adjacent metadata; reviewed only when relevant through primary manifest and Helm/Docker files.
