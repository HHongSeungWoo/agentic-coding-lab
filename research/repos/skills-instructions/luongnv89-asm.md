# luongnv89/asm

- URL: https://github.com/luongnv89/asm
- Category: skills-instructions
- Stars snapshot: 287 (GitHub REST API and index row, captured 2026-05-29; GitHub web UI opened the same day displayed 286)
- Reviewed commit: 02977f5a064b6e659744518d487bdc880d8f0b50
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value reference for skill inventory management, cross-host install paths, local/remote catalogs, security auditing, quality scoring, dedupe, bundles, and registry name resolution. It reduces installed-skill clutter and helps users pre-select smaller skill sets, but it is not a host runtime router: it does not control which skill descriptions a coding agent loads into context during a session.

## Why It Matters

`asm` is directly relevant to the skill-management-routing problem because it tackles the operational mess that appears before runtime selection: skills are scattered across Claude Code, Codex, Cursor, Windsurf, Copilot, OpenCode, Gemini CLI, and other host directories; the same skill is often copied or symlinked many times; there is no common way to search available skills, inspect context cost, audit security, update pinned sources, or publish a skill by name.

For Agentic Coding Lab, this repo is useful as a management layer rather than a reasoning layer. It shows how to normalize many host-specific skill locations into one CLI/TUI, how to build a bundled search index from remote skill repos, how to expose token/eval signals before installation, how to dedupe same-name skills across folders, and how to make name-based registry installs resolve to pinned GitHub commits.

It also reveals the remaining gap. Even with progressive disclosure, an agent can still receive too many skill descriptions if too many skills remain enabled in a host. `asm` can help users prune, filter, bundle, and install only the relevant subset, but it does not implement a deterministic or semantic runtime router that shortlists skills per task and injects only those descriptions.

## What It Is

`asm` is a TypeScript/Node CLI and Ink TUI published as `agent-skill-manager` with the `asm` binary. The reviewed `package.json` reports version `2.8.0`, Node `>=18 <23`, and dependencies including `ink`, `@inkjs/ui`, `react`, `yaml`, and `minisearch`.

The command surface includes:

- `list`, `search`, and `inspect` for installed skills.
- `install` for GitHub, local, registry, and Vercel-style skill installs.
- `audit` and `audit security` for duplicate detection and static risk scans.
- `eval` and `eval-providers` for skill quality and best-practice validation.
- `index ingest/search/list/remove` for building and querying local/bundled skill indexes.
- `bundle` commands for saving, exporting, installing, and listing curated skill sets.
- `outdated` and `update` for lock-file based lifecycle management.
- `publish` for generating an `asm-registry` manifest and opening a registry PR through `gh`.
- `init`, `link`, `export`, `import`, `stats`, `doctor`, and `config` for authoring and local inventory management.

The repo also ships a static catalog website, bundled `data/skill-index/*.json` repo indexes, pre-defined bundles, and several built-in skills under `skills/`, including `skill-auto-improver`, `skill-index-updater`, and `skill-creator`.

## Research Themes

- Token efficiency: Strong as a management signal, moderate as a runtime solution. `asm` computes approximate `tokenCount` for every indexed/installed `SKILL.md`, shows tokens in list/detail surfaces, splits website payloads into compact rows plus lazy detail files, and validates descriptions against a 250-character runtime target. It does not stop a host agent from loading all enabled skill descriptions.
- Context control: Strong outside the session. Provider enablement, project/global scopes, `--provider`, `--scope`, `--compact`, `--summary`, `--group-by`, `--limit`, bundles, dedupe, and search/index filters help users keep installed sets smaller. There is no in-session activation router or host prompt assembler.
- Sub-agent / multi-agent: Indirect. The repo supports many agent hosts and scans Claude/Codex plugin surfaces, but it does not orchestrate subagents or multi-agent workflows.
- Domain-specific workflow: Very strong for the domain of skill package management: install, search, audit, eval, dedupe, publish, update, bundle, and cross-host organization.
- Error prevention: Strong. The code has source parsing, path/name sanitization, conflict checks, security scans, manifest validation, typosquat detection, duplicate detection, health checks, update re-audit, path-shadowing diagnostics, pre-commit checks, and CI/security workflows.
- Self-learning / memory: Minimal. It remembers selected tools and lock-file source metadata, but there is no activation telemetry, adaptive routing, or automatic pruning based on actual usage.
- Popular skills: The repo is a catalog/index builder more than a skill corpus. Its bundled index points at thousands of skills across dozens of repos and its built-in `skill-auto-improver` is the most relevant internal skill for improving skill quality.

## Core Execution Path

Installed-skill discovery starts in `src/config.ts` and `src/scanner.ts`. `loadConfig()` creates or reads `~/.config/agent-skill-manager/config.json`, merges new built-in providers without overwriting user-added providers, and resolves `~` or project-relative paths. `scanAllSkills()` builds scan locations for global/project provider paths and custom paths, reads immediate child directories containing `SKILL.md`, parses frontmatter, estimates token counts, detects symlinks and real paths, then adds Claude plugin marketplace skills and Codex plugin-cache entries for global scans.

The default provider registry covers many host paths. The implementation currently defines 19 built-ins, including Claude Code, Codex, OpenCode, Pi, Hermes, OpenClaw, generic Agents, Cursor, GitHub Copilot, Windsurf, Antigravity, Gemini CLI, Cline, Roo Code, Continue, Aider, Zed, Augment, and Amp. The README still markets 18 providers, so implementation and docs are slightly out of sync.

`asm list` loads config, scans all enabled providers, enriches skills with health warnings, sorts, and renders grouped, flat, compact, summary, group-by, JSON, or machine output. The grouped renderer collapses installations by directory name and scope, shows provider badges, token counts, scope, directory/symlink type, and warning counts. Large inventories automatically get a summary header.

`asm search` searches both installed skills and the available-skill index unless `--installed` or `--available` narrows it. Installed search is simple substring matching over name, description, creator, effort, location, and provider label. Available search uses `src/skill-index.ts`, which loads bundled and user index JSON files, lets user indexes override bundled indexes for the same repo, tokenizes name/description, assigns simple scores, and supports limited metadata filters for `license`, `creator`, and `version`.

`asm install` is an eight-step flow: registry resolution for bare/scoped names, source parsing, provider selection, scope selection, clone/local read, skill discovery, inspection/security scan, and install. For multi-skill repos it discovers `SKILL.md` directories up to depth 5, supports `--path`, `--all`, interactive selection, duplicate install-name checks, and batch install. Provider `all` uses the `agents` provider as canonical if available and symlinks the skill into other enabled provider directories.

`asm audit` has two main paths. Duplicate audit dedupes by real path, then flags same `dirName` across locations and same frontmatter `name` across different directory names. Security audit recursively scans files, flags shell/network/filesystem/environment/code-execution/credential/obfuscation patterns, infers permission classes, optionally fetches GitHub owner metadata, and calculates `safe`, `caution`, `warning`, or `dangerous` verdicts.

`asm index ingest` clones a GitHub repo, discovers skills, dedupes same-name skills within the repo using root priority (`skills/` before `.claude/skills/` before `.agent(s)/skills/`), verifies `SKILL.md`, computes token count, runs quality/eval summaries, infers or loads repo bundles, then writes a repo index JSON. `scripts/preindex.ts` repeats this for enabled curated repos in `data/skill-index-resources.json` and copies generated files into `data/skill-index/` for npm distribution.

`asm publish` validates local skill metadata, runs the security auditor, generates an `asm-registry` manifest, validates it, checks `gh` availability/authentication, then forks/branches/commits/opens a PR against `luongnv89/asm-registry`. If `gh` is unavailable, it returns fallback instructions and a valid manifest.

`asm outdated` and `asm update` use `~/.config/agent-skill-manager/.skill-lock.json`. Outdated checks compare registry entries against the registry index and GitHub entries against `git ls-remote`. Updates clone the latest source, run security audit, block `dangerous`, require `--yes` for `warning`/`caution`, then swap files and update the lock.

## Architecture

The repo is a CLI/TUI plus catalog-builder architecture:

- `bin/agent-skill-manager.ts`: binary entrypoint.
- `src/cli.ts`: argument parsing, help text, and command handlers.
- `src/index.tsx` and `src/views/`: Ink TUI dashboard, detail, config, duplicate-audit, help, and confirm views.
- `src/config.ts`: provider defaults, config path, lock path, index path, bundled index path, and selected-tool persistence.
- `src/scanner.ts`: installed-skill discovery for provider directories, Claude plugin marketplaces, Codex plugin cache, and Codex marketplace JSON.
- `src/skill-index.ts`: local/bundled available-skill search index loader and scorer.
- `src/installer.ts`: source parsing, GitHub URL/ref/subpath handling, cloning, skill discovery, validation, warning scan, install plan creation, copy/symlink install, provider selection, and conflict checks.
- `src/registry.ts`: `asm-registry` manifest schema, name resolution, typosquat suggestions, index fetch/cache, duplicate checks, and author identity helpers.
- `src/ingester.ts`: repo-to-index pipeline with verification, token count, eval summaries, and bundle inference.
- `src/auditor.ts`, `src/security-auditor.ts`, `src/health.ts`, and `src/verifier.ts`: duplicate detection, static security scans, installed-skill health warnings, and index verification.
- `src/evaluator.ts` and `src/eval/`: static skill quality scoring and pluggable eval providers.
- `src/eval/providers/skill-best-practice/v1/`: stricter SKILL.md best-practice validator aligned with `skill-creator`.
- `src/bundler.ts` and `src/repo-bundles.ts`: saved/predefined/repo-derived bundles and bundle install/export.
- `src/updater.ts` and `src/utils/lock.ts`: outdated checks, update flow, source lock entries, and commit tracking.
- `src/linker.ts`, `src/importer.ts`, `src/exporter.ts`, `src/initializer.ts`, `src/publisher.ts`, `src/doctor.ts`: local development, portability, publish, and diagnostics.
- `scripts/preindex.ts`, `scripts/build-catalog.ts`, `scripts/enrich-index.ts`, `scripts/security_check.py`: bundled index generation, website artifact generation, enrichment, and security baseline.
- `website-src/` and `website/`: React/Vite catalog UI, MiniSearch index, slim catalog rows, lazy detail pages, bundle builder, and docs pages.
- `.github/workflows/ci.yml` and `.github/workflows/security.yml`: unit/build/e2e/audit workflows across Node versions and security tooling.

## Design Choices

The central design choice is to manage skills across host directories without pretending the hosts share one runtime. `asm` normalizes path conventions and UI around a common `SkillInfo` shape, but it mostly installs the same `SKILL.md` directory into each host path rather than translating host-specific formats or permissions.

The second major choice is to separate available-skill search from registry name resolution. `data/skill-index/*.json` and `asm index search` are a broad searchable catalog of skills. `asm-registry`, by contrast, is for bare/scoped name resolution to a manifest with author, repository, pinned commit, optional `skill_path`, version, license, tags, security verdict, and publication time.

The third choice is metadata-first display. Search/list/detail surfaces prefer `name`, `description`, `version`, `creator`, `license`, `compatibility`, `allowedTools`, token count, verification status, and eval summaries. Full `SKILL.md` bodies and resources remain in skill directories; the website fetches per-skill detail lazily.

The fourth choice is filesystem-level dedupe rather than semantic dedupe. Installed duplicate detection uses real paths, directory names, and frontmatter names. Within repo ingestion, same-name skills are deduped by root priority. This is practical and deterministic, but it does not understand that two differently named skills may be semantically redundant.

The fifth choice is advisory security. `asm` scans and reports suspicious code patterns, blocks `dangerous` updates, and warns before risky installs. It does not sandbox installed skills or enforce `allowed-tools` across host agents.

The sixth choice is authoring quality through deterministic validators. The `skill-best-practice` provider enforces name shape, description shape, runtime description budget, allowed top-level keys, metadata version, metadata author warning, effort enum, directory-name match, and negative-trigger clause warning. This is directly relevant to reducing selection overhead because short, discriminative descriptions are the only part many hosts load eagerly.

## Strengths

- Strong cross-host inventory model. The provider registry and scanner make scattered skill directories visible from one CLI/TUI.
- Useful context-cost signals. `tokenCount` is computed during scan/index, shown in CLI/TUI/website surfaces, and sortable/filterable in the website.
- Practical large-inventory UX. Summary, compact, group-by, limit, provider/scope filters, and grouped rows reduce human scanning overhead for hundreds of skills.
- Available-skill discovery is built in. Bundled/user indexes let `asm search` suggest uninstalled skills with install commands, while the website provides MiniSearch, facets, category filters, grade sort, token sort, and lazy details.
- Good install source support. GitHub shorthand, HTTPS GitHub URLs, refs, subpaths, local paths, multi-skill repos, private SSH fallback, `--all`, `--path`, and Vercel `npx skills add` delegation are covered.
- Registry manifests are pinned. Bare/scoped registry names resolve through a cached index to exact commits and optional skill paths instead of moving branch names.
- Dedupe and organization are explicit. Duplicate audit, provider `all` symlink fan-out, bundle creation/install/export, repo-derived bundles, and import/export support make skills easier to curate by workflow.
- Security and quality are first-class surfaces. `audit security`, `verifySkill`, `asm eval`, `skill-best-practice`, local pre-commit security checks, and CI security mirror give multiple layers of validation.
- The publish path is realistic. It validates frontmatter, audits the skill, generates a manifest, and opens a registry PR instead of blindly writing to a central index.
- The codebase has broad test coverage. Source parsing, scanner behavior, installer, registry, publisher, updater, security auditor, evaluator, bundler, config, linker, and CLI flows all have tests in `src/*.test.ts` and `tests/e2e/`.

## Weaknesses

- It is not a runtime skill router. It does not decide per user request which skills should be visible to the model, nor does it rewrite a host's active skill catalog to a short task-specific subset.
- Installed-skill search is simple substring matching. The website uses MiniSearch, but the CLI available-skill search in `src/skill-index.ts` uses a basic token score over name/description only, without embeddings, negative triggers, host compatibility ranking, usage history, or risk weighting.
- Descriptions remain the main activation key. `asm` improves and budgets them, but the selection problem still depends on authors writing good descriptions and users pruning installed sets.
- Host compatibility is path placement, not full adaptation. For Cursor, Copilot, Windsurf, and similar rule-file hosts, `asm` installs `SKILL.md` directories under configured paths; it does not translate skills into each host's native rule/instruction file schema.
- Docs and implementation drift. `src/config.ts` defines 19 built-in providers including Pi, while the README repeatedly says 18 providers and omits Pi from the table. The README FAQ also mentions an older release (`v2.6.2`) while `package.json` is `2.8.0`.
- Security verdicts are noisy. The repo's own security audit doc notes that shell plus network caused many `dangerous` verdicts that were benign under a stricter prompt-injection/credential-theft risk model.
- Registry and catalog are separate trust domains. The bundled skill index helps discovery but is not the same as the pinned registry. A skill found through `index search` may still install from a moving GitHub source unless the install URL includes a pinned ref.
- Update tracking has important edge cases. The reviewed install lock write records source owner/repo and ref, but not the selected skill subpath. `updateSkill()` assumes a global provider path, clones a repo root, and does not use the install subpath when swapping files. Registry installs that resolve to commit SHAs also pass that SHA through the lock `ref`, while `updateSkill()` uses `git clone --branch` for non-HEAD refs instead of the commit-aware clone helper. Multi-skill and commit-pinned updates therefore need hardening before copying this update design.
- No signatures or transparency log were found for registry installs. The registry manifest supports an optional checksum field, but local manifest generation does not populate it; installs rely mainly on GitHub commit pinning and registry review.
- There is no activation telemetry. `asm` can show what is installed, but not which skills actually fire, cause false positives, waste context, or should be retired.

## Ideas To Steal

- Build a two-layer skill system: a compact machine-readable index for discovery/routing and full skill directories for progressive disclosure.
- Keep local installed inventory and remote available catalog separate. Let users search both, but make trust/pinning status explicit.
- Put token count and eval score in every consumer-facing surface before install. This gives users an immediate reason to choose leaner skills.
- Enforce short, specific descriptions with negative-trigger clauses. `description-runtime-budget` and `negative-trigger-clause` are directly applicable to skill selection overhead.
- Use provider/scope filters and project-local skill sets as a first defense against global context bloat. Project-specific skill directories should be the normal path for specialized work.
- Add `summary`, `compact`, `group-by`, and `limit` views to any skill manager. The user needs inventory shape before line-by-line details.
- Use deterministic duplicate groups: real path, directory name, and frontmatter name. Then layer semantic duplicate detection later.
- Store provenance in a lock file: source type, source URL, ref/commit, install time, provider, registry name, subpath, and ideally folder hash.
- Keep registry resolution exact and scoped. Bare names can collide, so scoped `author/name` resolution and disambiguation prompts are the right pattern.
- Re-audit updates before swapping files. Blocking dangerous updates and requiring explicit confirmation for warnings is a useful lifecycle gate.
- Treat bundles as routing presets. A bundle is a human-curated shortlist for a workflow; a runtime router can start from the active bundle instead of the global skill universe.
- Split web catalog payloads into slim rows, search index, and lazy details. This is the frontend analogue of progressive disclosure.

## Do Not Copy

- Do not stop at install-time organization if the real goal is context reduction. Add a runtime shortlisting layer that exposes only a small candidate set of descriptions to the agent.
- Do not rely on README/provider counts as source of truth. Generate compatibility docs from provider config and fail CI when they drift.
- Do not copy the update lock omission for multi-skill repos. Source subpath, selected install path, original install method, and resolved commit must be stored and used during update.
- Do not treat `allowed-tools` metadata as portable enforcement. Each host needs its own permission model or a wrapper that can enforce the declared capabilities.
- Do not equate simple regex security scans with semantic safety. They are useful gates, but malicious prose, prompt injection, and policy bypass need additional review/eval layers.
- Do not let every global provider be enabled by default in automation. Non-interactive workflows should require an explicit provider/scope or a project policy.
- Do not use plain name/description scoring as the final router. Combine deterministic filters, category/task metadata, host compatibility, risk, token budget, usage history, and a final LLM decision over a short list.

## Fit For Agentic Coding Lab

Fit is high for `skills-instructions`, especially for the `skill-management-routing` topic. `asm` should be mined for the management substrate: provider path registry, scanning, search surfaces, index generation, security/eval signals, dedupe, bundles, registry manifests, publish workflow, and update lifecycle.

For Agentic Coding Lab, the missing layer is a runtime selector above this manager:

1. Keep an `asm`-like installed inventory and remote catalog.
2. Generate a normalized `skills.index.json` with fields such as `name`, `short_description`, `trigger_examples`, `negative_triggers`, `categories`, `hosts`, `scope`, `allowed_tools`, `token_count`, `risk`, `quality_score`, `source_commit`, `last_reviewed`, and `bundle_memberships`.
3. At session start, disclose only globally relevant built-ins plus project-pinned active bundles.
4. At task time, run deterministic filters first: project, host, file globs, task type, risk policy, and user-selected bundle.
5. Run lexical/semantic retrieval over the compact index to produce a shortlist.
6. Let the model choose from that shortlist, then load the full `SKILL.md` and referenced resources lazily.
7. Record activation telemetry and false-positive/false-negative reports so descriptions and routing metadata can be pruned over time.

`asm` can provide much of the inventory and packaging machinery for that plan. It should not be treated as the selector itself.

## Reviewed Paths

- `/tmp/myagents-research/luongnv89-asm/README.md`: product claims, command surface, registry workflow, skill verification, provider table, install formats, bundle docs, and SKILL.md format.
- `/tmp/myagents-research/luongnv89-asm/package.json`: package version, binary names, scripts, dependencies, engines, and npm metadata.
- `/tmp/myagents-research/luongnv89-asm/docs/ARCHITECTURE.md`: stated CLI/TUI architecture, core modules, eval framework, data flow, duplicate detection, and uninstall process.
- `/tmp/myagents-research/luongnv89-asm/docs/CHANGELOG.md`: recent changes around index scale, token counts, eval summaries, bundles, dedupe, description budgets, security baseline, and provider changes.
- `/tmp/myagents-research/luongnv89-asm/docs/eval-skill-creator-audit.md`: alignment between `asm eval` providers and skill-creator rules.
- `/tmp/myagents-research/luongnv89-asm/docs/security/skill-audit-269.md`: real-world audit results, false-positive analysis, and recommendations for security verdicts.
- `/tmp/myagents-research/luongnv89-asm/src/config.ts`: provider registry, config/lock/index paths, default merging, and selected-tool persistence.
- `/tmp/myagents-research/luongnv89-asm/src/scanner.ts`: provider scanning, plugin marketplace scanning, Codex plugin cache scanning, marketplace JSON reading, dedupe, search, and sorting.
- `/tmp/myagents-research/luongnv89-asm/src/utils/types.ts`: `SkillInfo`, `LockEntry`, `IndexedSkill`, `RepoIndex`, security audit, bundle, publish, install, and config types.
- `/tmp/myagents-research/luongnv89-asm/src/cli.ts`: command handlers for list, search, install, audit, index, bundle, publish, outdated, and update flows.
- `/tmp/myagents-research/luongnv89-asm/src/formatter.ts`: grouped/compact/summary/group-by renderers, token column, available search rendering, JSON/machine formatting, and detail/inspect output.
- `/tmp/myagents-research/luongnv89-asm/src/skill-index.ts`: bundled/user index loading, merge precedence, simple token scoring, metadata filters, and total count.
- `/tmp/myagents-research/luongnv89-asm/src/registry.ts`: `asm-registry` manifest validation, fetch/cache, exact/scoped resolution, duplicate detection, typosquat suggestions, and schema helpers.
- `/tmp/myagents-research/luongnv89-asm/src/installer.ts`: source parsing, local path disambiguation, GitHub ref/subpath handling, cloning, skill discovery, install validation, warning scan, provider selection, install plan, symlink fan-out, and conflict checks.
- `/tmp/myagents-research/luongnv89-asm/src/ingester.ts`: repo index pipeline, within-repo dedupe, verification, token count, eval summaries, and bundle inference.
- `/tmp/myagents-research/luongnv89-asm/src/skill-dedupe.ts`: priority rules for same-name skills across `skills/`, `.claude/skills/`, `.agent/skills/`, and `.agents/skills/`.
- `/tmp/myagents-research/luongnv89-asm/src/security-auditor.ts`: static scan patterns, source analysis, permission inference, verdict calculation, and report formatting.
- `/tmp/myagents-research/luongnv89-asm/src/auditor.ts`: duplicate grouping and deterministic keep ordering.
- `/tmp/myagents-research/luongnv89-asm/src/verifier.ts`: index-time verification criteria.
- `/tmp/myagents-research/luongnv89-asm/src/evaluator.ts`: quality scoring categories, context-efficiency scoring, auto-fix behavior, and batch/eval helpers.
- `/tmp/myagents-research/luongnv89-asm/src/eval/providers/skill-best-practice/v1/index.ts`: strict SKILL.md validation, description runtime budget, negative-trigger clause, metadata, effort enum, and directory/name checks.
- `/tmp/myagents-research/luongnv89-asm/src/updater.ts`: outdated checks, registry/GitHub source comparison, security re-audit, atomic swap, and update limitations.
- `/tmp/myagents-research/luongnv89-asm/src/utils/lock.ts`: lock file read/write, provider rewrite, and commit hash capture.
- `/tmp/myagents-research/luongnv89-asm/src/publisher.ts`: publish metadata parsing, manifest generation, markdown/control-char sanitization, gh CLI checks, and fallback instructions.
- `/tmp/myagents-research/luongnv89-asm/src/bundler.ts` and `/tmp/myagents-research/luongnv89-asm/src/repo-bundles.ts`: saved/predefined/repo-derived bundle creation, validation, loading, listing, and inferred domain grouping.
- `/tmp/myagents-research/luongnv89-asm/src/linker.ts`: symlink development workflow and local linkable-skill discovery.
- `/tmp/myagents-research/luongnv89-asm/src/health.ts`: installed-skill health warnings for missing metadata, invalid YAML, empty body, and high file counts.
- `/tmp/myagents-research/luongnv89-asm/src/doctor.ts` and `/tmp/myagents-research/luongnv89-asm/src/utils/path-shadowing.ts`: environment diagnostics and `asm` PATH shadowing detection.
- `/tmp/myagents-research/luongnv89-asm/src/utils/token-count.ts`: approximate token-count heuristic and display formatting.
- `/tmp/myagents-research/luongnv89-asm/data/skill-index-resources.json`: curated repo resource list and enabled flags for bundled indexing.
- `/tmp/myagents-research/luongnv89-asm/data/skill-index/luongnv89_asm.json`: example bundled index entry for this repo's own skill.
- `/tmp/myagents-research/luongnv89-asm/scripts/preindex.ts`, `/tmp/myagents-research/luongnv89-asm/scripts/enrich-index.ts`, and `/tmp/myagents-research/luongnv89-asm/scripts/build-catalog.ts`: index generation, token/eval enrichment, catalog output, MiniSearch generation, slim row/detail split, and star fetch.
- `/tmp/myagents-research/luongnv89-asm/scripts/security_check.py`, `/tmp/myagents-research/luongnv89-asm/security/semgrep-rules.yml`, and `/tmp/myagents-research/luongnv89-asm/.pre-commit-config.yaml`: local security baseline and pre-commit quality gates.
- `/tmp/myagents-research/luongnv89-asm/.github/workflows/ci.yml` and `/tmp/myagents-research/luongnv89-asm/.github/workflows/security.yml`: CI matrix, build/e2e checks, npm audit, pinned actions, and security mirror.
- `/tmp/myagents-research/luongnv89-asm/website-src/src/lib/filter-sort.js`, `/tmp/myagents-research/luongnv89-asm/website-src/src/lib/minisearch-options.js`, and `/tmp/myagents-research/luongnv89-asm/website-src/src/hooks/useCatalog.jsx`: website search/filter/sort, MiniSearch config, slim catalog loading, and lazy detail architecture.
- `https://github.com/luongnv89/asm`: current GitHub page metadata and stars display.
- `https://api.github.com/repos/luongnv89/asm`: GitHub REST metadata snapshot for stars, default branch, language, license, timestamps, forks, issues, and repository description.
- `research/index.md` row for `luongnv89/asm`: candidate row, category, topic, indexed stars snapshot, URL, and note path state; read only per user instruction.
- `research/templates/repo-note.md`: required note structure.

## Excluded Paths

- `/tmp/myagents-research/luongnv89-asm/.git/`: VCS internals, excluded except for commit capture.
- `/tmp/myagents-research/luongnv89-asm/package-lock.json`: dependency lockfile noted but not audited line by line because package behavior and security checks were reviewed through source, package metadata, CI, and scripts.
- `/tmp/myagents-research/luongnv89-asm/assets/`, `/tmp/myagents-research/luongnv89-asm/.github/issue-assets/`, and logo/favicon files: visual assets and screenshots, not relevant to routing or management logic.
- `/tmp/myagents-research/luongnv89-asm/website/`: generated/static website output was sampled through source build scripts and frontend source instead of reviewing every generated artifact.
- Most React presentational components under `/tmp/myagents-research/luongnv89-asm/website-src/src/components/` and pages under `/tmp/myagents-research/luongnv89-asm/website-src/src/pages/`: catalog behavior was reviewed through hooks, filter/sort utilities, and build scripts; individual UI rendering files were not central to skill routing analysis.
- Full contents of every test fixture under `/tmp/myagents-research/luongnv89-asm/tests/fixtures/` and `/tmp/myagents-research/luongnv89-asm/src/eval/providers/*/fixtures/`: tests were used as coverage evidence through filenames and selected source references, not exhaustively re-reviewed as product logic.
- Full `skills/skill-creator/`, `skills/skill-auto-improver/`, `skills/skill-index-updater/`, and other bundled skill bodies: noted as built-in skill assets; this note focuses on the manager architecture rather than deep-reviewing each bundled skill.
- External skill repositories listed in `data/skill-index-resources.json` and generated `data/skill-index/*.json`: treated as catalog inputs, not cloned or reviewed for this note.
- The live `luongnv89/asm-registry` repository: registry behavior was inferred from this client's manifest, resolver, publisher, and README description; the registry repo itself needs a separate review.
- Live hosted catalog service at `https://luongnv.com/asm/`: referenced as the published catalog surface, but runtime behavior was reviewed from local website source and build artifacts rather than from the deployed site.
