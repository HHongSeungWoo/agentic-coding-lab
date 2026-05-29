# iflytek/skillhub

- URL: https://github.com/iflytek/skillhub
- Category: skills-instructions
- Stars snapshot: 3,232 (GitHub REST API and index row, captured 2026-05-29)
- Reviewed commit: 8bd7a6bc1d673bba288d3bc39552e586560153b3
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal enterprise skill registry for governing, searching, publishing, versioning, and installing agent skills. It is not itself a runtime skill router, but it shows the right registry-side primitives for reducing skill-selection context load: structured metadata, search indexes, labels, namespaces, review gates, and install-on-demand boundaries.

## Why It Matters

SkillHub attacks the upstream half of the skill-management-routing problem. Instead of putting every skill description into an agent prompt, it centralizes skill packages in a private registry, makes them searchable, and installs only selected packages into local agent skill directories. That makes it useful for Agentic Coding Lab as a reference for a governed skill catalog, even though the final runtime router still needs to be built elsewhere.

The repository is also unusually relevant because it handles enterprise concerns that most skill examples ignore: namespace ownership, RBAC, audit logs, review and promotion workflows, API tokens, search indexing, package validation, scanner integration, agent-specific install paths, and ClawHub/OpenClaw-compatible APIs.

## What It Is

SkillHub is a Java/Spring Boot modular monolith plus React web app and TypeScript CLI. It provides a self-hosted registry where users publish skill packages, review or approve them, search the catalog, resolve versions or tags, and download/install skills into agent-specific directories.

The skill coordinate model is namespace-based. Internal skills use `@{namespace_slug}/{skill_slug}`. For ClawHub-compatible clients, `@global/my-skill` becomes `my-skill`, while team skills become `team--my-skill`; the design reserves `--` so this mapping remains reversible.

The platform borrows the OpenSkills-style `SKILL.md` package convention but does not provide an agent runtime. Its core value is registry, governance, and distribution.

## Research Themes

- Token efficiency: Strong registry-side fit. Search and install are the intended selection boundary, so agents do not need to preload all skills. However, the repo does not implement prompt-time shortlist injection or automatic context packing.
- Context control: Good package-level progressive disclosure through `SKILL.md`, `references/`, `scripts/`, and `assets/`, plus install-on-demand. Runtime disclosure is delegated to the target agent after installation.
- Sub-agent / multi-agent: Limited. The project supports multiple agent install targets, but not multi-agent delegation or sub-agent orchestration.
- Domain-specific workflow: Strong for enterprise skill lifecycle management: publish, validate, review, promote, tag, search, install, audit, and administer.
- Error prevention: Good package validation, path traversal protection, file size/count limits, secret-pattern warnings, optional security scanner, RBAC, and immutable published versions.
- Self-learning / memory: Weak. It records stars, ratings, downloads, labels, and audit events, but does not learn routing rules from usage.
- Popular skills: Not a curated skills corpus. It exposes popularity signals such as download counts, stars, ratings, labels, newest sorting, and search ranking that a marketplace or router can consume.

## Core Execution Path

The publish path starts with a directory or zip package containing a root `SKILL.md`. The backend normalizes archive paths, strips unsafe archive roots, rejects traversal and absolute paths, validates file limits and content type expectations, parses frontmatter, checks namespace membership, assigns or validates the semantic version, detects slug conflicts, runs pre-publish secret checks, stores files in object storage, builds a bundle zip, persists metadata, creates review tasks when needed, emits audit events, and optionally triggers a scanner.

The lifecycle splits ordinary publish from privileged publish. Super admins can publish directly. Ordinary public or namespace-visible packages move to review, while private packages become uploaded and downloadable by the permitted owner path. Published versions are immutable; non-published same-version artifacts can be replaced.

The install path is CLI-first. The CLI resolves registry and token from flags, environment, or `~/.skillhub` config, searches or resolves a namespace/slug/version, downloads the bundle, safely extracts it into a project or user skill directory for a detected agent profile, writes `.skillhub/metadata.json`, and updates `~/.skillhub/inventory.json`.

The search path builds skill-level documents from latest-version metadata, labels, keywords/tags frontmatter, and other frontmatter fields. The default implementation uses PostgreSQL full-text search with Jieba tokenization for Chinese/ASCII text, plus a lightweight hashing-based semantic reranker. Search is latest-published oriented and not version/tag/channel aware.

## Architecture

The backend is separated into modules: app/controllers/orchestration, domain entities and services, auth/RBAC/token handling, search SPI and PostgreSQL implementation, storage abstraction for local or S3/MinIO, and infrastructure/JPA repositories. Redis is used for sessions, locks, and idempotency. Storage writes individual files under `skills/{skillId}/{versionId}/{filePath}` and bundles under `packages/{skillId}/{versionId}/bundle.zip`.

The public surfaces are split by audience. The web portal uses `/api/web/skills` and related admin/auth endpoints. The CLI uses `/api/cli/v1/skills` for search, resolve, download, validate, publish, and delete. Compatibility clients use ClawHub-style `/api/v1/search`, `/api/v1/resolve`, `/api/v1/download`, `/api/v1/publish`, and `/.well-known/clawhub.json`.

The frontend is React 19, TypeScript, Vite, shadcn/ui, Tailwind, and TanStack Query/Router. For this review, the UI was treated as a boundary layer rather than the primary source of behavior.

## Design Choices

The registry data model is the strongest reusable part. `namespace` defines global/team isolation and lifecycle state. `namespace_member` grants OWNER/ADMIN/MEMBER roles. `skill` stores namespace, slug, owner, visibility, lifecycle state, latest pointer, statistics, and hidden overlay. `skill_version` stores version, status, manifest JSON, parsed metadata JSON, bundle key, file counts, size, and fingerprint. `skill_file` stores path, content type, size, object key, and SHA-256. `skill_tag` separates install channels such as `beta` or `stable` from classification labels. Review tasks, promotion requests, API tokens, audit logs, platform roles, namespace roles, labels, and search documents are separate tables.

The package schema is intentionally small: root `SKILL.md` with frontmatter `name` and `description` required, optional `version`, plus optional Astron fields such as `x-astron-category`, `x-astron-runtime`, and `x-astron-min-version`. The package can include `references/`, `scripts/`, and `assets/`. Extra frontmatter becomes search metadata, but there is no rich routing schema for globs, tools, permissions, negative triggers, cost, safety tier, or agent compatibility.

Version tags and labels are deliberately different. Tags point to published versions and behave like install channels. Labels are catalog/search metadata such as recommended or privileged labels, with translations and label filters.

Search-first loading is supported at the catalog boundary. Users or tools can query a structured index, inspect metadata, resolve a version, then install the package. The implementation does not yet close the loop by selecting a short list at runtime and injecting only those skill descriptions into an agent context.

## Strengths

SkillHub has a credible enterprise governance model: namespaces, namespace roles, platform roles, API token scopes, review tasks, promotion to global namespace, audit logs, soft governance overlays, and admin boundaries.

The publish/version/tag model is clear. Published versions are immutable, `latest` is reserved, custom tags target published versions, and promotion copies an approved team skill into the global namespace.

Package safety is materially better than most skill repositories. It normalizes archive paths, rejects traversal, enforces size/count limits, computes SHA-256 per file, creates a bundle fingerprint, checks frontmatter, warns on suspicious secrets, and can pass packages through an optional scanner pipeline.

The API/CLI/UI split is pragmatic. Native web APIs, CLI APIs, and ClawHub-compatible APIs are separated enough that Agentic Coding Lab could copy the boundary pattern without inheriting the whole platform.

The CLI target resolver is useful. It supports project/user scopes and many agent profiles, including Codex, Claude Code, Cursor, Gemini CLI, GitHub Copilot, OpenHands, Windsurf, OpenClaw, Kiro, Roo, Trae, OpenCode, and Kilo.

Search indexing is a good baseline for large skill collections. It combines metadata extraction, label keywords, access-control filtering, downloads/ratings/newest sorts, PostgreSQL FTS, and a cheap semantic reranker without requiring an embedding service.

## Weaknesses

SkillHub is not a runtime router. It reduces catalog browsing and installation cost, but it does not decide which installed skills enter the model context for a task. Documentation mentions AGENTS-style sync, but the current CLI code does not implement a `sync` command or generate AGENTS skill blocks.

Routing metadata is thin. Most selection power comes from `name`, `description`, labels, keywords/tags, and extra frontmatter. That is not enough for a precise high-scale skill router. Agentic Coding Lab would need explicit fields for trigger intent, file globs, tool/runtime requirements, permission boundaries, conflict groups, confidence examples, and exclusion cases.

Search visibility has a notable private-skill gap. The search scope carries user, member namespace, admin namespace, and platform-wide fields, but the PostgreSQL query only includes PUBLIC and member-visible NAMESPACE_ONLY documents. PRIVATE skills appear accessible through detail/download paths for owners, but not discoverable through the normal search path. For skill routing, private owner/admin discoverability must be first-class.

Docs and code have drifted. The protocol docs mention smaller limits than the backend config, lifecycle docs omit actual statuses such as `UPLOADED`, `SCANNING`, and `SCAN_FAILED`, product docs describe a no-op prepublish validator while code has secret checks, and CLI docs imply sync behavior that was not present in the reviewed CLI.

Integrity and provenance stop short at the client boundary. The server stores file hashes and version fingerprints, but the CLI install flow downloads and extracts a bundle without verifying a returned fingerprint, without writing a lockfile containing the fingerprint, and without package signatures, SBOMs, or provenance attestations.

The local CLI inventory is not fully race-safe. Writes are locked and atomic, but read-modify-write is not locked as one transaction; the integration tests explicitly document a possible lost-update case for parallel installs.

Search is latest-skill oriented rather than version or channel oriented. A tag install can resolve to content that search ranking did not represent, and search cannot directly ask for "skills where beta has routing metadata X".

## Ideas To Steal

Use a registry-backed skill index with namespace, slug, owner, visibility, status, latest published version, custom install tags, labels, stats, parsed frontmatter, file hashes, and bundle fingerprint. That is a better source of truth than scanning local skill directories on every task.

Make search the first stage of context control. Filter by namespace, visibility, labels, runtime, safety tier, and file/task signals before any LLM sees skill descriptions. Then rerank a bounded candidate set and load only selected skill summaries or full `SKILL.md` files.

Separate classification labels from install channel tags. Labels help discovery and routing; tags pin operational channels such as stable, beta, team-default, or audited.

Copy the governance spine: namespace ownership, review gates, global promotion, API token scopes, audit logs, immutable published versions, and frozen/archived namespaces.

Adopt the package validation pipeline, but tighten it: root `SKILL.md`, normalized paths, extension/content checks, size caps, secret scan, optional scanner, immutable published artifacts, and quarantine statuses.

Reuse the agent profile resolver idea. Installing to project or user scopes across many agent clients is a real product need, and profile metadata is cleaner than hard-coded path branches.

Add what SkillHub does not have: a client lockfile with registry URL, namespace, slug, resolved version, bundle fingerprint, per-file hashes, installed path, and signed provenance metadata. Verify before extraction and before runtime loading.

## Do Not Copy

Do not treat registry search as runtime routing. Agentic Coding Lab still needs a router that maps task evidence to a small, ordered skill shortlist and controls prompt inclusion.

Do not rely on description-only selection. Add structured routing metadata and examples so skill choice does not degrade as the catalog grows.

Do not let documentation become the contract when code differs. For a skill platform, schema, lifecycle states, file limits, and CLI behavior need generated or tested docs.

Do not skip install-time integrity verification. Server-side SHA and fingerprint storage are insufficient if the CLI never checks them.

Do not keep local inventory read-modify-write outside one lock. This becomes painful when multiple agents, terminals, or background installers share the same skill cache.

Do not expose every installed skill to an agent prompt by default. Registry scale only helps if installed skills are still selected progressively.

Do not overload `latestVersionId` to mean both latest published and private owner preview without very explicit API semantics. Routers need stable distinctions between published, review, preview, and private versions.

## Fit For Agentic Coding Lab

Fit is strong for the registry, governance, and catalog-search layer. SkillHub should influence how Agentic Coding Lab models skill packages, namespaces, publication workflow, review, labels, audit, install targets, and artifact validation.

Fit is conditional for routing. The repo does not solve runtime skill selection, prompt budget allocation, or progressive description loading by itself. Agentic Coding Lab should use SkillHub as the managed source of truth, then build a separate routing layer over structured metadata, task traces, local repository signals, user intent, and bounded semantic search.

The most useful adaptation would be a smaller registry/index service rather than the full Java platform: `skill.json` or parsed `SKILL.md` metadata, versioned package artifacts, local lockfiles, search-first candidate retrieval, review/audit metadata, and a router that can load one-line summaries first, then full skill docs only for finalists.

## Reviewed Paths

- `README.md`
- `docs/00-product-direction.md`
- `docs/01-system-architecture.md`
- `docs/02-domain-model.md`
- `docs/04-search-architecture.md`
- `docs/05-business-flows.md`
- `docs/06-api-design.md`
- `docs/07-skill-protocol.md`
- `docs/14-skill-lifecycle.md`
- `docs/2026-03-20-skill-label-system-design.md`
- `docs/security-scanning.md`
- `docs/openclaw-integration-en.md`
- `docs/skillhub/en/guide/cli.md`
- `document/docs/02-administration/security/authorization.md`
- `document/docs/03-user-guide/publishing/create-skill.md`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillPublishService.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillDownloadService.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillQueryService.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillTagService.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillLifecycleProjectionService.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillPackageValidator.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillPackagePolicy.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/SkillMetadataParser.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/service/BasicPrePublishValidator.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/model/SkillVersionStatus.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/model/SkillMetadata.java`
- `server/skillhub-domain/src/main/java/com/iflytek/skillhub/domain/model/VisibilityChecker.java`
- `server/skillhub-search/src/main/java/com/iflytek/skillhub/search/PostgresFullTextQueryService.java`
- `server/skillhub-search/src/main/java/com/iflytek/skillhub/search/PostgresFullTextIndexService.java`
- `server/skillhub-search/src/main/java/com/iflytek/skillhub/search/PostgresSearchRebuildService.java`
- `server/skillhub-search/src/main/java/com/iflytek/skillhub/search/HashingSearchEmbeddingService.java`
- `server/skillhub-search/src/main/java/com/iflytek/skillhub/search/SearchTextTokenizer.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/controller/SkillSearchController.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/controller/CliSkillController.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/controller/support/SkillPackageArchiveExtractor.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/service/SkillSearchAppService.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/service/CliSkillAppService.java`
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/ApiTokenService.java`
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/ApiTokenScopeService.java`
- `server/skillhub-auth/src/main/java/com/iflytek/skillhub/auth/RbacService.java`
- `server/skillhub-app/src/main/java/com/iflytek/skillhub/app/security/RouteSecurityPolicyRegistry.java`
- `server/skillhub-infra/src/main/resources/db/migration/V1__init_schema.sql`
- `server/skillhub-app/src/main/resources/application.yml`
- `cli/src/clients/skillhub-client.ts`
- `cli/src/services/install-service.ts`
- `cli/src/commands/publish.ts`
- `cli/src/platform/archive.ts`
- `cli/src/agents/resolver.ts`
- `cli/src/agents/detector.ts`
- `cli/src/agents/profiles/codex.ts`
- `cli/src/stores/inventory-store.ts`
- `cli/test/integration/concurrency.test.ts`

## Excluded Paths

- `web/` component implementation details beyond API/UI boundary checks.
- `scanner/` analyzer internals beyond backend scanner integration and lifecycle semantics.
- `deploy/`, `monitoring/`, Helm, Kubernetes, and Docker operational packaging.
- Generated artifacts, package lockfiles, screenshots, binary assets, and CI badge/media files.
- Historical planning notes under documentation trees that did not affect the current package, registry, search, or governance behavior.
