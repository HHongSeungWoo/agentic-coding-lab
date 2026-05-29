# tech-leads-club/agent-skills

- URL: https://github.com/tech-leads-club/agent-skills
- Category: skills-instructions
- Stars snapshot: 4,476 (GitHub REST API, captured 2026-05-29; matches existing index row)
- Reviewed commit: 81e7e0dd3abe314aa004ec276c1d64643d2bd6c0
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal skill registry, CLI installer, and MCP lookup server for scaling agent skills without loading every skill body. Best ideas are the separate catalog package, generated compact registry, multi-agent install path table, cache/lock/audit layers, progressive-disclosure MCP flow, and executable validation/security-scan pipeline. Main caveats are that routing still depends on long free-text descriptions, integrity hashes are mostly update hints rather than verified downloads, and some security/documentation claims are stronger than the current code.

## Why It Matters

`tech-leads-club/agent-skills` is directly about the problem behind `skill-management-routing`: how to hold many skills without stuffing every `SKILL.md` into context, how to let humans and agents find the right one, and how to install/update the selected subset across many coding agents.

The repo is useful because it is more than a prompt collection. It has a published skills catalog, a CLI package, a shared core library, an MCP server, a marketplace site, plugin marketplace manifests, validators, lockfiles, cache behavior, audit logs, and CI security scanning. That makes it a good reference for the operational layer around skills: catalog construction, discovery, installation, update detection, cross-agent paths, and on-demand agent access.

For Agentic Coding Lab, the most relevant question is whether a large skill inventory can be routed through a compact index. This repo's answer is a two-path model: the CLI installs a chosen working set into agent-specific skill directories, while the MCP server exposes the broader catalog as `search_skills -> read_skill -> fetch_skill_files` so an agent searches first and only fetches full instructions or references when needed.

## What It Is

This is an Nx/TypeScript monorepo with four main products:

- `packages/skills-catalog`: 80 skills in 15 categories, stored as `packages/skills-catalog/skills/(category)/skill/SKILL.md` with optional `references/`, `scripts/`, `templates/`, and `assets/`. It generates `skills-registry.json`, a 93,020-byte compact catalog containing names, descriptions, categories, file lists, authors, versions, and content hashes.
- `packages/cli`: `@tech-leads-club/agent-skills`, a CLI for listing, installing, updating, removing, caching, and auditing skills.
- `libs/core`: shared services for skill discovery, remote registry fetching, CDN downloads, agent path resolution, install/copy/symlink behavior, lockfile writes, and audit logging.
- `packages/mcp`: `@tech-leads-club/agent-skills-mcp`, a read-only MCP server that fetches the same catalog from jsDelivr and exposes skill search, read, file fetch, resource, and slash-prompt primitives.

The repo also has `packages/marketplace`, a Next.js static site generated from the registry and skill files; `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json`, which publish the MCP package as a plugin; and `tools/skill-plugin`, an Nx generator for new skill scaffolds.

## Research Themes

- Token efficiency: Strong in architecture. The MCP route loads a compact registry, searches against slim metadata, returns at most five results, then loads only `SKILL.md`, then optional referenced files. The weakness is that the registry still carries full free-text descriptions; average description length in the reviewed registry is about 472 characters, with 31 descriptions over 500 characters.
- Context control: Strong for progressive disclosure. `read_skill` returns main instructions plus a capped list of reference paths; `fetch_skill_files` permits at most five explicit files from allowed optional directories. The CLI install path is less context-aware because installed skills are delegated to host agents.
- Sub-agent / multi-agent: Indirect. The repo supports many agent hosts and includes skill/subagent creation skills, but it does not orchestrate subagents. Multi-agent value is mostly cross-agent packaging.
- Domain-specific workflow: Strong. The catalog covers architecture, cloud, creation, decision-making, design, development, GTM, learning, monitoring, performance, quality, security, tooling, and web automation.
- Error prevention: Strong at packaging and CI level. It has frontmatter/description validation, path sanitization, lockfile schema validation, audit logs, Snyk Agent Scan integration, allowlisted scan exceptions, fork-PR scan caveats, and merge-queue scan support.
- Self-learning / memory: Minimal. It stores installed skill state, cache metadata, audit logs, and deprecated-skill data, but there is no telemetry-driven routing feedback or automatic skill pruning loop.
- Popular skills: The catalog's important local patterns are `skill-architect`, `tlc-spec-driven`, `codenavi`, `aws-advisor`, `playwright-skill`, `security-best-practices`, `gh-fix-ci`, `coding-guidelines`, and `docs-writer`. Popularity is repo-level; no per-skill usage data was found.

## Core Execution Path

The CLI install path is:

1. `packages/cli/src/index.ts` routes `agent-skills install`, `list`, `remove`, `update`, `cache`, and `audit`.
2. Non-interactive install requires `--skill`; if no `--agent` is provided, it defaults to Cursor, Claude Code, and Windsurf.
3. `runCliInstall` calls `getRemoteSkills`, then `ensureSkillDownloaded` or `forceDownloadSkill`.
4. `libs/core/src/lib/services/registry.service.ts` resolves the latest `@tech-leads-club/skills-catalog` npm version unless `SKILLS_CDN_REF` is set, fetches `skills-registry.json` from jsDelivr with unpkg fallback, and caches it under `~/.cache/agent-skills/registry.json` for 24 hours.
5. Selected skill files are downloaded from CDN into `~/.cache/agent-skills/skills/<skill>`, up to 10 files concurrently, with per-skill `.skill-meta.json` storing the registry `contentHash`.
6. `installSkills` copies or symlinks the cached skill directory into each target agent path. Local symlink installs first copy the skill into project `.agents/skills/<skill>` and then symlink agent-specific directories to that canonical copy.
7. Successful installs update `.agents/.skill-lock.json` for local installs or `~/.agents/.skill-lock.json` for global installs, then append a JSONL audit entry under `~/.agent-skills/audit.log`.

The CLI update path has two variants. Interactive `UpdateView` detects outdated installed skills and reinvokes `install` for selected agents, currently as local copy installs. Non-interactive `agent-skills update` forces a fresh registry and updates the local cache, but it does not visibly reinstall copied skill directories or update lockfile metadata in the reviewed code path.

The MCP runtime path is:

1. `packages/mcp/src/main.ts` starts a FastMCP stdio server, fetches the CDN registry at cold start, and builds Fuse indexes before serving requests.
2. `search_skills` searches name, extracted triggers, description, and category, returning up to five ranked results with `score`, `match_quality`, and `usage_hint`.
3. `read_skill` requires an exact skill name, fetches only `SKILL.md` from CDN, and returns the main content plus a compact list of optional reference paths under `scripts/`, `references/`, and `assets/`.
4. `fetch_skill_files` accepts up to five paths, validates every path against `skill.files[]` and the optional-reference prefixes, then fetches valid files in parallel.
5. `skills://catalog` exposes the full registry as an MCP resource for clients that can cache resources natively.

## Architecture

The core architectural split is catalog, installer, and runtime lookup:

- Catalog source: `packages/skills-catalog/skills/(category)/skill`, plus `_category.json` and optional `deprecated.yaml`.
- Generated catalog: `packages/skills-catalog/skills-registry.json`, generated by `generate-registry.ts`.
- Package distribution: `@tech-leads-club/skills-catalog` publishes the generated registry and all skill files; the CLI and MCP fetch from CDN rather than bundling every skill.
- CLI state: registry cache and downloaded skills live under `~/.cache/agent-skills`; lockfiles live under `.agents/.skill-lock.json` or `~/.agents/.skill-lock.json`; audit logs live under `~/.agent-skills/audit.log`.
- Agent compatibility: `agents.service.ts` defines project and global skill paths for Cursor, Claude Code, GitHub Copilot, Windsurf, Cline, Aider, Codex, Gemini CLI, Antigravity, Roo Code, Kilo Code, TRAE, Kiro, Amazon Q, Augment, Tabnine, OpenCode, Sourcegraph Cody, and Droid.
- MCP lookup: `packages/mcp/src/registry.ts` uses a 15-minute in-memory TTL, ETag revalidation, stale fallback after warmup, and background refresh.
- Quality gates: `tools/validate-skills.ts` validates skill folders and frontmatter; `packages/skills-catalog/src/scan-skills.ts` runs Snyk Agent Scan with hash cache and allowlist.
- Marketplace/UI: `packages/marketplace/scripts/generate-data.ts` transforms the registry and git last-modified dates into the website's `skills.json`.
- Plugin distribution: `.claude-plugin/marketplace.json`, `.cursor-plugin/marketplace.json`, and `packages/mcp/mcp.json` advertise the MCP server as an installable plugin/config block.

## Design Choices

The strongest design choice is to make `skills-registry.json` the routing surface. It is much smaller than the full 4.96 MB skill corpus and contains enough metadata for listing, searching, downloading, and update comparison.

The second choice is dual access. Humans install recurring skills with the CLI, while agents can ask the MCP for occasional skills on demand. That separates persistent, curated local skill sets from broader catalog exploration.

The third choice is cross-agent path portability. The installer treats each host as a path target and leaves actual runtime loading semantics to the host. This is pragmatic and broad, but not a guarantee that every host interprets the skill format identically.

The fourth choice is free-text descriptions as routing metadata. Descriptions are required to include "Use when" and "Do NOT use for" guidance, and MCP extracts trigger phrases from those descriptions. This is easy to author and compatible with Agent Skills conventions, but it is still a brittle indexing field compared with structured trigger arrays, negative-trigger arrays, domain tags, tool requirements, or risk labels.

The fifth choice is package-level content hashes. Registry generation computes a SHA-256 over every file in a skill directory and stores it on each skill entry. CLI cache metadata stores that hash, and update checks compare cached hash to registry hash.

The sixth choice is scanner-backed curation. The repo runs Snyk Agent Scan incrementally, with cache invalidation by content hash and a committed allowlist for reviewed false positives. This turns skill prompt/script review into an explicit CI gate rather than only README policy.

## Strengths

The catalog architecture is practical. It keeps source skills as folders, generates a compact registry, publishes a catalog package, and uses CDN fetches so clients do not have to ship all skills.

The MCP routing flow is exactly the right shape for context control: search first, read the main skill second, fetch references only when requested. Tool descriptions explicitly tell agents not to use `list_skills` proactively.

Search has useful but simple ranking features. Fuse.js weights `name` highest, then extracted `triggers`, then full `description`, then `category`; results include a score and `exact`/`strong`/`partial`/`weak` labels.

The installer supports a broad host matrix and both local/global scopes. The project-local canonical `.agents/skills` plus agent-specific fan-out is a good pattern for team workspaces.

The CLI has a real lifecycle surface: install, list, update, remove, cache clear, and audit view. Most skill catalogs stop at copy/paste instructions.

Lockfile writes are schema-validated and atomic enough for ordinary CLI use: backup existing file, write temp, rename temp to final, and recover to an empty v2 lock on corrupt reads.

The validation script encodes useful skill quality checks: kebab-case names, exact `SKILL.md`, frontmatter YAML, description length under 1024 characters, trigger phrases, negative scope, metadata version/author warnings, body length budget, examples, error handling, and referenced support files.

The security scan pipeline is more serious than most skill repos. It checks Snyk token availability, avoids caching scanner infrastructure failures, supports parallel scan jobs, applies expiring allowlist entries, uploads scan artifacts, comments on same-repo PRs, and adds merge-queue coverage for fork PRs.

## Weaknesses

The routing index still scales linearly with description text. At 80 skills the 93 KB registry is fine, but at thousands of skills the always-fetched descriptions become a real context and search-footprint problem. There is no compact embedding/index artifact, structured trigger schema, shortlist cache, usage telemetry, or pruning loop.

Description parsing is fragile in the registry generator. `generate-registry.ts` parses frontmatter with regex, not YAML. One reviewed skill uses a folded YAML description and appears in the registry with description `>`, which breaks routing for that skill even though the validator uses a real YAML parser.

Integrity is weaker than the README wording implies. The registry content hash is computed at build time and stored in cache metadata, but `downloadSkill` does not recompute the downloaded directory and compare it to the registry hash before marking the skill cached. The lockfile stores the cached hash, but no reviewed operation recomputes installed skill contents to detect tampering.

Provenance is package-level, not source-level. The registry entries include author/version/contentHash, but not reviewed commit, source URL per imported third-party skill, license per skill in the registry, signature, npm provenance verification result, or immutable CDN URL. The CLI resolves latest catalog version but can fall back to `latest`; the MCP always uses `@latest`.

The update story is uneven. Interactive update reinstalls selected skills as local copies and does not preserve prior symlink/global method. CLI update refreshes the cache but does not appear to rewrite copied installed skill directories or lockfile timestamps/hashes.

Security documentation overstates some symlink behavior. `SECURITY.md` describes a `validateSymlinkTarget` function and target validation for chained symlinks, but the reviewed installer service only removes/reuses existing paths and creates new relative symlinks; I did not find an implementation matching the documented target-validation snippet.

The HTTP layer has constants for timeout and retries in core, but the reviewed `NodeHttpAdapter` calls native `fetch` without timeout or retry behavior. The MCP uses ky retry on cold start but the CLI registry/download path relies mostly on fallback CDN and cache.

Runtime compatibility is not enforced. The CLI can copy a skill into many agent directories, but it does not verify that each host actually discovers the skill, respects progressive disclosure, supports resources/scripts, or honors tool-permission metadata.

The repo has minor version/engine inconsistencies. The root package requires Node `>=24`, the CLI package says `>=22`, the MCP package says `>=24`, and CONTRIBUTING says `>=22`.

## Ideas To Steal

Use a generated `skills-registry.json` as the first-stage routing artifact, but split it into an agent-facing compact index and a richer human/installer registry. The agent-facing index should avoid full descriptions when a shorter trigger field is enough.

Keep CLI install and MCP on-demand lookup as separate product surfaces. Persistent local skills and exploratory catalog search solve different context problems.

Adopt the `search -> read -> fetch references` protocol for skill routing. Make "list all skills" an explicit browse-only operation, not a default agent step.

Use weighted deterministic search before LLM selection. A deterministic shortlist gives the model fewer choices and lowers the chance of selecting from hundreds of descriptions.

Make negative scope mandatory. The repo's `Do NOT use for` validation is a good way to reduce false positive activations when skills overlap.

Use `.agents/skills` as canonical project storage and fan out to agent-specific directories. Preserve copy fallback because symlinks and host path support differ.

Record install state in a lockfile with agents, method, scope, source, version, content hash, timestamps, and eventually reviewed source commit or package version.

Keep an audit log for skill lifecycle operations. Even a simple JSONL append log is useful when debugging why an agent suddenly has a new instruction surface.

Turn skill quality guidance into a validator. Description shape, negative scope, line budgets, metadata, support-file references, and reserved-name checks should be executable.

Use incremental security scanning keyed by whole-skill content hash, but pair it with deterministic local checks and manual review. The allowlist format with `reason`, `allowedBy`, `allowedAt`, and optional `expiresAt` is worth copying.

## Do Not Copy

Do not rely on regex frontmatter parsing for generated routing metadata. Use a YAML parser for registry generation or the routing index will silently degrade on valid YAML syntax.

Do not treat content hashes as integrity unless downloads are recomputed and verified. A stored upstream hash is useful for update detection, but not enough for tamper detection.

Do not use `@latest` as the only MCP catalog source in production. Pin a catalog version or expose a project policy that chooses when the registry advances.

Do not make descriptions the only routing feature at large scale. Add structured trigger terms, exclusions, domains, host compatibility, required tools, risk class, and maturity level.

Do not let CLI update mean "cache updated" when users expect installed agent directories to change. Updates should either reinstall or clearly name the cache-only behavior.

Do not copy documentation claims that are not backed by tests and source. The symlink validation and timeout/retry claims need to match implementation.

Do not assume copied skills are safe because they passed a scanner once. Skills can contain prose that asks the host agent to run dangerous commands; scanner output should be one gate, not the policy boundary.

Do not install globally to many agents as a casual default. For Agentic Coding Lab, project-local and explicit agent selection should be the safe default.

## Fit For Agentic Coding Lab

Fit is high. This repo is one of the strongest reviewed references for skill management at scale because it combines catalog generation, package distribution, CLI lifecycle management, MCP progressive disclosure, validation, security scanning, and cross-agent path conventions.

The best Agentic Coding Lab adaptation is a stricter internal skill registry with:

- a compact `skills.index.json` for routing;
- a full `skills.registry.json` for install/provenance;
- YAML-parsed frontmatter;
- structured triggers and negative triggers separate from prose;
- per-skill source URL, reviewed commit, license, owner, and trust label;
- content hash verification after download;
- lockfiles that pin catalog version and source digest;
- usage telemetry for activations, false positives, and unused skills;
- a policy layer for host compatibility and risky tools;
- an MCP/API flow that returns only a shortlist, then full instructions, then named resources.

The repo should not be copied as a complete production answer. It is an excellent current implementation, but Agentic Coding Lab should harden routing metadata, integrity verification, update semantics, and runtime compatibility checks before adopting the pattern.

## Reviewed Paths

- `/tmp/myagents-research/tech-leads-club-agent-skills/README.md`: overview, security claims, supported agents, CLI options, cache description, and MCP workflow.
- `/tmp/myagents-research/tech-leads-club-agent-skills/SECURITY.md`: threat model, CLI defense-in-depth claims, lockfile/audit/scanner documentation, and MCP security claims.
- `/tmp/myagents-research/tech-leads-club-agent-skills/CONTRIBUTING.md`: skill structure, authoring standards, validation expectations, and release/security scan process.
- `/tmp/myagents-research/tech-leads-club-agent-skills/package.json`: monorepo scripts, package groups, scan/release scripts, dependencies, and root Node engine.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/skills-registry.json`: generated catalog shape, skill/category counts, file lists, content hashes, and description footprint.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/src/generate-registry.ts`: category scanning, frontmatter extraction, slug fixing, file list capture, hash generation, and deprecated-skill loading.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/src/utils.ts`: registry metadata types, ignored files, frontmatter regex parser, file walking, and content hash computation.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/src/scan-skills.ts`: Snyk Agent Scan integration, hash cache, SNYK token handling, parallel scan, allowlist, result output, and failure behavior.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/security-scan-allowlist.yaml`: reviewed exceptions and expiration/reason metadata.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/skills-catalog/project.json`: registry generation, build copy, validation, and security-scan Nx targets.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/constants.ts`: canonical directories, cache names, TTLs, and concurrency constants.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/types.ts`: agent, install, lockfile, registry, and audit data shapes.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/utils.ts`: name sanitization, path safety, and category formatting.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/agents.service.ts`: supported agent list, project/global skill paths, and installation detection.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/registry.service.ts`: remote registry fetch/cache, CDN URL construction, skill download/cache, update detection, and cache clearing.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/skills-provider.service.ts`: local-vs-remote mode detection, local discovery, categories, and skill lookup.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/installer.service.ts`: copy/symlink install behavior, canonical storage, install path validation, lock updates, remove behavior, and audit logging.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/lockfile.service.ts`: v2 lock schema, migration, atomic writes, backup writes, and lock entry updates.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/audit-log.service.ts`: JSONL audit log path, append behavior, and reader.
- `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/adapters/node-http.adapter.ts` and `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/adapters/node-package-resolver.adapter.ts`: fetch and npm latest-version adapters.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/index.ts`: command routing and CLI options.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/cli/install.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/cli/update.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/cli/cache.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/cli/remove.ts`, and `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/cli/audit.ts`: non-interactive lifecycle commands.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/hooks/useInstaller.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/hooks/useSkillContent.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/cli/src/views/UpdateView.tsx`, and representative views/components: interactive install/update/content behavior.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/README.md`: progressive-disclosure MCP workflow, tool contracts, prompts, resource, caching, and error behavior.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/package.json` and `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/mcp.json`: package metadata and MCP config.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/main.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/registry.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/constants.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/utils.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/resources.ts`, and `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/prompts.ts`: MCP startup, cache, indexes, prompt guidance, and resource exposure.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/tools/search-tool.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/tools/list-tool.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/tools/skill-tool.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/tools/fetcher-tool.ts`, and their `core/` helpers: list/search/read/fetch behavior and response shaping.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/__tests__/registry.test.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/mcp/src/tools/__tests__/*.test.ts`, `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/services/__tests__/*.spec.ts`, and `/tmp/myagents-research/tech-leads-club-agent-skills/libs/core/src/lib/utils.spec.ts`: representative tests for routing, fetch validation, installer behavior, lockfiles, registry cache, and path helpers.
- `/tmp/myagents-research/tech-leads-club-agent-skills/tools/validate-skills.ts`: skill validator and batch reporting.
- `/tmp/myagents-research/tech-leads-club-agent-skills/tools/skill-plugin/src/generators/skill/*`: skill generator schema and `SKILL.md` template.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/marketplace/scripts/generate-data.ts`: marketplace data generation from registry and git history.
- `/tmp/myagents-research/tech-leads-club-agent-skills/.github/workflows/release.yml`, `/tmp/myagents-research/tech-leads-club-agent-skills/.github/actions/security-scan/action.yml`, and `/tmp/myagents-research/tech-leads-club-agent-skills/.github/actions/validate-skills/action.yml`: CI, merge-queue scan, release, validation, and artifact behavior.
- `/tmp/myagents-research/tech-leads-club-agent-skills/.claude-plugin/marketplace.json`, `/tmp/myagents-research/tech-leads-club-agent-skills/.cursor-plugin/marketplace.json`, and `https://api.github.com/repos/tech-leads-club/agent-skills`: plugin metadata and current repository metadata.

## Excluded Paths

- `/tmp/myagents-research/tech-leads-club-agent-skills/.git/`: VCS internals, excluded except for commit, branch, and remote verification.
- `/tmp/myagents-research/tech-leads-club-agent-skills/package-lock.json`: dependency lockfile was not line-by-line audited; package surfaces and security-relevant code were reviewed instead.
- `/tmp/myagents-research/tech-leads-club-agent-skills/packages/marketplace/src/app`, `/tmp/myagents-research/tech-leads-club-agent-skills/packages/marketplace/src/components`, and static assets: marketplace presentation was secondary to catalog generation and routing behavior.
- Full contents of all 80 skill bodies and 684 skill-catalog files: the catalog structure, registry metadata, representative malformed frontmatter, and selected examples were reviewed; every domain-specific instruction was not exhaustively audited.
- Audio/image assets such as `packages/cli/src/assets/chiptune.mp3`, marketplace images, logos, favicons, and SVGs: UI/media assets, not skill-management logic.
- Generated release changelog entries were sampled for security-scan/history context but not treated as primary implementation.
- Remote npm package contents and CDN artifacts: behavior was inferred from the local repo source, generated registry, and public GitHub/API metadata rather than independently downloading every published package tarball.
- `research/index.md`: existing row was read for the snapshot and status context, but intentionally not edited per user instruction.
