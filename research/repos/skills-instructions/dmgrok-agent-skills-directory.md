# dmgrok/agent_skills_directory

- URL: https://github.com/dmgrok/agent_skills_directory
- Category: skills-instructions
- Stars snapshot: 17 (research/index.md candidate row and GitHub REST API, captured 2026-05-29)
- Reviewed commit: 82f4706ff1502d696425275795ea6ea2ec51f68f
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful early reference for skill catalog aggregation, metadata-first search, and heuristic recommendation, but it is not yet a reliable skill package manager or runtime router. The strongest ideas are the unified catalog schema, quality and maintenance metadata, exports, bundles, and search-first shortlist generation. The weakest parts are overstated README/security claims, incomplete installs that fetch only `SKILL.md`, stale/inconsistent generated summaries under incremental aggregation, and a lack of real runtime activation enforcement.

## Why It Matters

`dmgrok/agent_skills_directory` attacks the exact scaling problem behind skill management: too many scattered `SKILL.md` repositories, too many descriptions to inspect manually, unclear freshness, duplicate skills, and no compact way to decide which skills are worth loading.

For Agentic Coding Lab, it is valuable because it treats skills as catalog entries before they become context. The repo keeps skill bodies outside the main catalog and exposes names, descriptions, tags, categories, source URLs, maintenance metadata, provider stars, duplicate annotations, and quality scores. That is the right shape for a search-first router: filter a large universe down to a small candidate set, then fetch or activate only the selected skill instructions.

It also shows the downside of turning a catalog into a package manager too early. The CLI advertises install, update, publish, validate, and export surfaces, but several of those are partial. The implementation is most credible as a static metadata directory and triage layer, not as a hardened distribution, security, or runtime-loading system.

## What It Is

The repo is a Python-based skill directory with generated static artifacts and a small CLI:

- `scripts/aggregate.py` aggregates `SKILL.md` files from a hardcoded provider list.
- `catalog.json` and `catalog.min.json` are generated catalogs. The reviewed snapshot reports version `2026.05.29`, generated at `2026-05-29T10:12:51.673709+00:00`, with 1,059 skill rows across 43 providers.
- `schema/catalog-schema.json`, `schema/skill-manifest-schema.json`, and `schema/bundles-schema.json` define the intended JSON contracts.
- `exports/` contains filtered catalogs for Claude, Copilot, MCP-tagged skills, premium quality, active skills, and shields.io badges.
- `docs/` is a static browser that loads the catalog, builds a client-side search index, filters by provider/category/type/tags, and renders quality/maintenance/duplicate badges.
- `cli/skills.py` exposes `skillsdir` commands for search, info, suggest, install, uninstall, list, init, update, config, cache, run, detect, validate, publish, login, whoami, export, and stats.
- `cli/loader.py` provides a universal skill representation plus exports to MCP resource JSON, LangChain, CrewAI, AutoGen, OpenAI assistants, Anthropic tools, combined prompts, Copilot instructions, and Claude-style instructions.
- `.github/workflows/update-catalog.yml` runs daily at 06:00 UTC and commits regenerated catalogs when changed.
- `.github/workflows/validate-new-provider.yml` validates proposed providers with gitleaks, the external `dmgrok/LGTM_agent_skills` action, and a lightweight provider test before opening a PR.

The repo also points to an external `dmgrok/mcp_mother_skills` MCP server. This repository contains MCP export helpers and MCP-compatible JSON exports, but it does not implement a standalone MCP server.

## Research Themes

- Token efficiency: Strong conceptually. The catalog keeps only routing metadata and source URLs, not full skill bodies. `suggest` prefilters the full catalog to 30 skills and truncates descriptions to 150 characters before optional LLM prompting.
- Context control: Moderate to strong. Web and CLI search operate over metadata, and `SkillLoader.from_catalog_entry(fetch_content=True)` fetches full `SKILL.md` only when explicitly loading a skill. However, the default CLI fetches the full 1.6 MB `catalog.json` rather than `catalog.min.json`, and there is no host-side activation budget or context retention policy.
- Sub-agent / multi-agent: Indirect. The catalog targets Claude, Copilot, Codex, Cursor, generic runtimes, and MCP-compatible exports, but there is no subagent orchestration or runtime delegation.
- Domain-specific workflow: Strong for skill discovery and governance. The repo models provider aggregation, issue-driven provider onboarding, validation, recommendation, static browsing, bundles, exports, and private registry override.
- Error prevention: Mixed. There are useful validators, gitleaks/LGTM provider workflows, malicious-pattern checks, duplicate detection, and maintenance scoring. But generated README/web "security validated" icons are quality-score proxies for catalog rows, not proof that every aggregated skill was scanned.
- Self-learning / memory: Minimal. The CLI records local search and install counts in `~/.skills/stats.json`, but there is no feedback loop that improves ranking, descriptions, or routing from activation outcomes.
- Popular skills: The repo is not a source skill corpus itself. Popularity comes from provider GitHub stars, quality buckets, and curated bundles. The current catalog has 553 skills at quality >= 70, 1,057 at quality >= 50, and 67 MCP-compatible export rows.

## Core Execution Path

The aggregation path is:

1. `PROVIDERS` in `scripts/aggregate.py` defines each provider with name, GitHub repo, tree API URL, raw base URL, and skill path prefix.
2. The aggregator fetches the provider tree from the GitHub API.
3. It finds paths ending in `SKILL.md` under the configured prefix.
4. It fetches each raw `SKILL.md`, parses YAML frontmatter, and requires at least `name`.
5. It infers category from name/description keywords, extracts tags, checks for sibling `scripts/`, `references/`, `assets/`, and `templates/` directories, detects MCP requirement heuristically, classifies very small skills as integration stubs, and fetches the last commit date touching the file.
6. It computes maintenance status and quality score from maintenance, resource folders, and provider trust.
7. It fetches provider stars and descriptions from GitHub REST, caching by repo URL.
8. It annotates duplicates by grouping skills by name and comparing body/description similarity with compression-based similarity.
9. It writes `catalog.json`, `catalog.min.json`, ecosystem exports, badge endpoints, the README skill table, changelog updates, and `aggregation_state.json`.

The recommendation path is:

1. `skillsdir suggest [path]` reads a project README, truncated to 8,000 characters.
2. It walks project files up to depth 3 while skipping `.git`, `node_modules`, virtualenvs, build outputs, and similar directories.
3. It detects languages, frameworks, file types, and package files from simple file-pattern heuristics.
4. It prefilters catalog skills by README keyword overlap, language/framework matches, category/domain hints, quality, and maintenance.
5. It converts only the top 30 to compact recommendation candidates.
6. Default recommendations are generated by heuristic scoring. `--llm` attempts an optional Perplexity MCP call, but the referenced function is not defined in this repo, so that path currently falls back after an exception.

The install path is much thinner than the README implies:

1. `skillsdir install <skill-id>` fetches the catalog and finds the selected row.
2. It chooses a target path based on agent detection or `--agent`.
3. It writes the remote `SKILL.md` and a generated local `skill.json` manifest.
4. It does not download resource folders such as `scripts/`, `references/`, `assets/`, or `templates/`, even though those folders are central to the catalog's quality score.
5. Dependency resolution looks for `source.skill_json_url`, but the reviewed catalog schema/source rows do not define that field, so dependency installation is mostly aspirational for current catalog entries.

## Architecture

The architecture has five layers:

- Aggregator: `scripts/aggregate.py` is the source of truth for provider aggregation, scoring, duplicate annotation, exports, README generation, and state tracking.
- Catalog contracts: `schema/catalog-schema.json` defines provider and skill metadata; `schema/skill-manifest-schema.json` defines an npm-like local `skill.json`; `schema/bundles-schema.json` defines use-case bundles.
- CLI: `cli/skills.py` is a monolithic command implementation for discovery, recommendation, install/update, validation, publishing, export, and local stats.
- Loader/export helpers: `cli/loader.py` can read local `SKILL.md`/`skill.json` directories and export loaded skills to several runtime-adjacent formats, including MCP resource dictionaries.
- Static site and generated exports: `docs/app.js` builds a browser-side search/filter index; `exports/*.json` serves filtered catalogs and badges through jsDelivr/GitHub Pages.

There is no database, hosted API service, semantic vector index, signed registry, package lock resolver for remote skills, or host-agent runtime loader in this repo. The public "API" is static JSON over CDN.

## Design Choices

The key design choice is metadata-first cataloging. A skill row includes enough fields to rank and filter without injecting the skill body into context: `id`, `name`, `description`, `provider`, `category`, `tags`, `quality_score`, `maintenance_status`, `days_since_update`, `requires_mcp`, `github_stars`, `has_scripts`, `has_references`, `has_assets`, duplicate annotations, and source URLs.

Provider aggregation is intentionally centralized. Adding a provider means changing the hardcoded `PROVIDERS` dict or going through the issue workflow that opens a PR against `scripts/aggregate.py`. This is simple and reviewable but not a decentralized registry protocol.

Quality scoring is transparent and simple: maintenance contributes up to 50 points, resource folder presence up to 30 points, and provider trust up to 20 points. This is good enough for coarse ranking, but it is not equivalent to runtime safety or task effectiveness.

Recommendation is a deterministic search pipeline first. The router uses README keywords, detected tech stack, domain terms, quality, maintenance, and provider trust to build a shortlist. This is the most relevant pattern for managing many skills without spending context on every description or full instruction file.

The static web UI mirrors the same philosophy. It builds a preprocessed search string from name, description, and tags, then filters by provider, category, skill type, and URL tags. It also caches recent filter results client-side.

Security and validation are split across surfaces. CLI validation has optional `detect-secrets`, fallback regex patterns, and malicious-pattern checks. Provider submission workflow uses gitleaks and external LGTM/Lakera-enabled validation. Aggregation itself does not run those checks for every existing catalog row.

## Strengths

The catalog shape is practical for a skill router. It separates always-loadable routing metadata from full instructions, source files, and provider resources.

The provider list is broad and currently aggregates 43 providers in the generated catalog. It normalizes official and community skill repos into one browse/search surface.

The recommendation pipeline is small but useful. Project README plus shallow file structure is a reasonable low-cost signal for narrowing skills before a model sees candidates.

The scoring model is understandable. Maintenance, documentation/resource folders, and provider trust are imperfect but inspectable ranking features.

The repo treats duplication as a first-class catalog issue. It annotates mirrors and probable duplicates instead of silently dropping rows, and the UI exposes similar skills.

The static export strategy is easy to mirror. JSON over CDN plus generated filtered exports is cheaper and simpler than a live registry service.

The provider onboarding workflow is a useful governance sketch: issue template, repo checkout, gitleaks, LGTM action, provider config test, and PR creation.

The loader/export helpers are a useful compatibility sketch. `cli/loader.py` gives a simple internal skill object and runtime-specific serialization methods without requiring those runtimes at import time.

## Weaknesses

The README overstates implementation maturity. It presents `skillsdir` as a package manager that can install and manage skills from one command, but the actual install path copies only `SKILL.md` plus a generated `skill.json`; it loses scripts, references, assets, and templates.

Security validation claims are too broad. The generated README table and web UI infer secrets/injection/content checks from `quality_score` thresholds. That is not evidence that each aggregated skill passed a real secrets scan or prompt-injection check.

Provider validation can degrade to manual review while still passing the automated gate. If the external LGTM action fails or is skipped, the workflow writes default outputs with `passed=pending` and `score=70`; the check step allows `pending` as long as gitleaks passes.

The reusable `.github/workflows/validate-skill.yml` is much weaker than the docs-site pipeline description. It installs only `pyyaml` and uses a small inline validator with basic regex secret checks, not the full optional `detect-secrets`, gitleaks, LGTM, and Lakera pipeline described elsewhere.

Incremental aggregation leaves generated summaries inconsistent. The reviewed `catalog.json` reports `total_skills: 1059`, but `skill_type_summary` totals only 751 and `maintenance_summary` active plus maintained totals 751. `duplicate_summary.total_annotated` is 12 while counting rows with `duplicate_status` gives 13. This appears to come from merging unchanged provider rows after building summaries without recomputing summaries over the final merged catalog.

Skill IDs are not guaranteed unique. The current catalog has 1,059 rows but only 1,041 unique IDs, with 17 duplicate ID groups and 18 extra rows. Several duplicates come from the same provider and same skill name in different paths, so `provider/name` is not a sufficient primary key for this aggregation style.

The `source.commit_sha` field is misleading. It is populated from the Git tree response SHA, not an explicit provider commit SHA for each source skill. It is useful provenance, but it should not be treated as a reviewed commit pin.

`fetch_last_updated_at()` hardcodes `sha=main` for per-file commit lookup. Providers configured on `master` or other branches can get missing or incorrect maintenance metadata.

The optional `--llm` suggestion path references `mcp_perplexity_perplexity_reason`, which is not defined in the repo. In practice, the default heuristic path is the working recommender.

The CLI writes to `~/.skills` for config, cache, installs, and local stats. That is fine for a user CLI, but it complicates sandboxed agent use and team-reproducible project state.

`pyproject.toml` declares package name `agent-skills`, while the README tells users `pip install skillsdir`. That may be correct if published with separate metadata elsewhere, but the source tree itself does not make that packaging story obvious.

## Ideas To Steal

Use a two-tier skill index: compact routing metadata in a catalog, full `SKILL.md` and resources fetched only after shortlist or activation.

Keep catalog rows explicit about source provenance: provider, repo, path, raw `SKILL.md` URL, provider stars, last update, and resource-folder flags.

Use deterministic prefiltering before any LLM-based router. README keywords, project language/framework detection, category, tags, quality, and maintenance are cheap and reduce candidate count dramatically.

Expose both full and minified catalogs. A minified agent-facing index can avoid shipping provider descriptions and verbose fields into a runtime path.

Separate human catalog browsing from agent-facing exports. The docs site, full catalog, filtered exports, badge endpoints, and bundles serve different consumers.

Track maintenance as a routing signal. Freshness should not be the only score, but stale skills should be less likely to auto-activate.

Annotate duplicates instead of hiding them. For skill routing, knowing that two candidates are mirrors or near-duplicates is more useful than silently picking one.

Provide private registry override. `skillsdir config set registry <url>` is a simple model for enterprise or project-local catalogs.

Use bundles as coarse route presets. Bundles can map task families such as frontend, data, security, or docs to a small curated group of skills before finer ranking.

Build an MCP-facing resource layer, but keep it metadata-first. `skill://provider/name` resource URIs are a reasonable shape if list operations return compact entries and read operations fetch one full skill.

## Do Not Copy

Do not use a quality score as a proxy for security scan pass/fail. Store real validation results as separate fields with scan time, scanner version, and source.

Do not install only `SKILL.md` if the catalog scores scripts, references, and assets. A package manager must fetch the whole skill directory or explicitly mark an instruction-only install.

Do not use `provider/name` alone as the canonical key when one provider can contain duplicate skill names in different paths. Include source path, provider path slug, or a stable content hash.

Do not merge incremental provider rows without recomputing all catalog summaries, duplicate annotations, and badges over the final merged catalog.

Do not claim an MCP server exists in the catalog repo when the actual server is external. Keep "MCP-compatible export" separate from "implemented MCP server".

Do not make optional external security services silently become pass-equivalent defaults. If LGTM or Lakera is unavailable, mark the row pending and block auto-approval or clearly require manual review.

Do not feed a full static catalog into model context. Even the minified catalog is about 947 KB in the reviewed snapshot; routing should query/filter it outside the model and expose only a short shortlist.

Do not treat GitHub stars as trust. Stars are useful for sorting providers in a UI, but provenance, pinning, validation, ownership, and local policy matter more for automatic activation.

## Fit For Agentic Coding Lab

Fit is high for `skill-management-routing`, but the adoption target should be the catalog/routing design, not the package manager as implemented.

The best local adaptation is a `skills.index.json` or similar index that stores only agent-router fields: id, namespace, short trigger description, negative triggers, tags, categories, file globs, required tools, risk level, trust/maturity label, source path, reviewed commit, validation status, and last-used/activation stats. Full skill content should stay lazy.

Agentic Coding Lab should pair this with a deterministic router:

1. Filter by project enabled skill set, host compatibility, workspace trust, and file globs.
2. Filter/search by task keywords, repo metadata, changed file types, and explicit user mentions.
3. Rank by semantic/keyword match, quality, recency, risk, and prior successful activations.
4. Present only a small shortlist to the model.
5. Fetch full `SKILL.md` and resources only for the selected skill.

The repo also supports a useful governance artifact: provider onboarding should be PR-based with machine validation, provenance capture, duplicate detection, and manual review for security-sensitive skills. But the local version should make validation outputs first-class data rather than inferred badges.

## Reviewed Paths

- `/tmp/myagents-research/dmgrok-agent-skills-directory/README.md`: positioning, usage claims, provider list, quality system, exports, contributing, private registry, CI validation, and related projects.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/pyproject.toml`: Python package metadata, `skillsdir` console script, optional validation/build/dev dependencies, and package name/version.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/scripts/aggregate.py`: provider definitions, GitHub API fetching, frontmatter parsing, tag/category extraction, maintenance and quality scoring, MCP detection, duplicate annotation, incremental state, exports, README generation, and summary generation.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/scripts/test_provider.py`: provider validation fetch/parse smoke test used by onboarding workflow.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/scripts/analyze_repo.py`: candidate repo analyzer, simple quality scoring, duplicate checks, and provider-config suggestion.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/cli/skills.py`: CLI commands, catalog cache, agent detection, search, info, suggestion, install/update, validation, publishing, export, and stats.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/cli/loader.py`: local/remote/catalog skill loading, runtime export methods, and MCP resource handler helper.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/cli/validate.py`: optional `detect-secrets`, fallback regex secret detection, malicious-pattern detection, schema-ish validation, duplicate-name checks, and formatting.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/schema/catalog-schema.json`: catalog provider and skill row contract.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/schema/skill-manifest-schema.json`: local `skill.json` manifest contract, runtime, dependencies, files, scripts, capabilities, inputs, and outputs.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/schema/bundles-schema.json`: curated bundle schema.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/catalog.json` and `/tmp/myagents-research/dmgrok-agent-skills-directory/catalog.min.json`: generated catalog snapshot, counts, summaries, duplicate annotations, and compact fields.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/exports/*.json`: filtered catalog exports and badge endpoint data.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/bundles.json`: curated skill bundles and current version mismatch with bundle schema expectations.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/docs/index.html`: docs-site claims about validation, MCP usage, skill structure, scoping guidance, CLI docs, exports, and installation paths.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/docs/app.js`: static catalog loading, search index, filter cache, provider/category/type/tag filters, compatibility inference, duplicate/quality/maintenance rendering, and modal details.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/.github/workflows/update-catalog.yml`: daily catalog update and release workflow.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/.github/workflows/validate-skill.yml`: reusable skill validation workflow.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/.github/workflows/validate-new-provider.yml`: new-provider issue parsing, gitleaks, LGTM validation, provider testing, provider PR creation, and issue comments.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/.github/copilot-instructions.md`: repo-maintainer architecture notes and stale internal stats/line-count claims.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/tests/test_aggregate.py`: available unit tests for frontmatter parsing and tag extraction.
- `https://api.github.com/repos/dmgrok/agent_skills_directory`: current repository metadata and star snapshot.

## Excluded Paths

- `/tmp/myagents-research/dmgrok-agent-skills-directory/.git/`: VCS internals, used only to capture reviewed commit and working-tree status.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/LICENSE`: license text was noted but not reviewed line-by-line.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/CHANGELOG.md`: sampled for generated catalog update context only; not central to routing behavior.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/install.sh`, `/tmp/myagents-research/dmgrok-agent-skills-directory/homebrew-tap/`, and `/tmp/myagents-research/dmgrok-agent-skills-directory/scripts/build_standalone.py`: distribution wrappers were noted but not deeply audited because the review focus was catalog/routing behavior.
- `/tmp/myagents-research/dmgrok-agent-skills-directory/docs/style.css`: presentation styling, not relevant to catalog semantics.
- Full line-by-line review of all 1,059 generated skill rows in `catalog.json`: aggregate counts, representative fields, duplicate groups, summaries, and export filters were inspected instead.
- Full line-by-line review of every generated badge/export JSON file: export counts and schemas were inspected; repetitive generated rows were not manually audited.
- External repositories listed as providers and external services such as `dmgrok/LGTM_agent_skills`, `dmgrok/mcp_mother_skills`, `skills.sh`, jsDelivr, Lakera Guard, and gitleaks internals: behavior was assessed from this repo's configuration and calls, not from those external implementations.
