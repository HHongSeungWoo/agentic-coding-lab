# sickn33/antigravity-awesome-skills

- URL: https://github.com/sickn33/antigravity-awesome-skills
- Category: ai-coding-workflow
- Stars snapshot: 38,121 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: b3869ba7d5717d2c67fe816693cd62d8dea75c59
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Very broad installable skill registry and packaging system for coding-agent skills. Best reuse value is the manifest/schema, release-pinned installer, plugin-safe distribution generation, bundle/workflow metadata, and validation/audit tooling. Treat the skill corpus as a discovery source, not as uniformly deep or verified implementation guidance.

## Why It Matters

`antigravity-awesome-skills` is relevant because it tackles the distribution and discovery side of agent skills at scale. It is not just a list of prompts: the repo ships a public manifest, npm installer, tool-specific install paths, role bundles, workflow metadata, generated Claude/Codex plugin packages, validation scripts, CI, source attribution docs, and a hosted catalog.

For Agentic Coding Lab, the highest-value pattern is how a large skill library can be packaged without forcing every instruction into the active context. The repo explicitly documents lazy skill resolution, reduced installs, category/risk/tag filters, bundle activation, and plugin-safe subsets. Its weakness is the expected one for a fast-growing registry: quality, freshness, taxonomy, and risk classification are uneven across 1,462 skills.

## What It Is

The repository is a cross-tool library of `SKILL.md` folders for Claude Code, Cursor, Codex CLI, Gemini CLI, Antigravity, Kiro, OpenCode, AdaL CLI, and similar coding assistants. The reviewed snapshot contains 1,462 `skills/**/SKILL.md` files, a root `skills_index.json` manifest mirrored exactly to `data/skills_index.json`, 37 editorial bundle plugins for Claude/Codex marketplace-style installs, 5 workflow definitions, and an npm CLI named `antigravity-awesome-skills`.

The project has three distinct layers:

- Source skill corpus: `skills/`, contributor docs, risk/source/date metadata, optional references/scripts/templates/evals.
- Distribution machinery: `tools/bin/install.js`, generated `plugins/`, `.claude-plugin/`, `.agents/plugins/`, `skills_index.json`, `data/*.json`, and `CATALOG.md`.
- Discovery/user surfaces: README, `docs/users/*`, `docs/contributors/*`, `docs/maintainers/*`, hosted web app, bundles, workflows, and plugin marketplace manifests.

It is not an agent runtime, MCP server, evaluator, or scheduler. Skills execute only when a host agent loads and follows the Markdown instructions. Some individual skills include helper scripts, but the main repo-level runtime is install/discovery/validation, not task execution.

## Research Themes

- Token efficiency: Strong packaging patterns. The repo documents that hosts should read `skills_index.json`, resolve only requested `@skill-id` values, and lazily read `SKILL.md`. The installer supports `--risk`, `--category`, and `--tags` filters, OpenCode-specific reduced-install guidance, and Antigravity activation scripts that expose only selected skills from a backing library. The risk is still high if users install or activate everything in a context-sensitive host.
- Context control: Strong at the manifest and install layer. `schemas/skills-index.v1.schema.json` defines a stable discovery contract, and `docs/users/discovery-manifest.md` recommends path containment, per-turn maximums, and lazy reads. `scripts/activate-skills.sh` keeps a full `skills_library` while copying only selected bundle or skill ids into the live Antigravity skills folder. Enforcement remains host-side.
- Sub-agent / multi-agent: Moderate. The repo contains skills about orchestration, subagents, and agent evaluation, plus workflow metadata that sequences skills for SaaS MVPs, security audits, AI agent systems, QA/browser automation, and DDD. There is no central multi-agent runtime. `agent-orchestrator` has local Python scripts for registry scan/match/orchestration, but that is one skill's helper path, not the repo architecture.
- Domain-specific workflow: Very broad. The catalog covers development, cloud, security, AI/ML, workflow, web development, marketing, business, legal, health, document processing, and many API integrations. For AI coding workflow, the strongest sampled skills are planning, TDD, systematic debugging, verification, skill-writing, context/window management, tool-use guarding, and agent evaluation. Many other entries are lightweight guides or imported community material.
- Error prevention: Good repository-level tooling, uneven skill-level guarantees. Validation checks frontmatter, names, descriptions, risk labels, source attribution, `When to Use`, links, and offensive disclaimers. Audit tooling adds examples, limitations, overlong skill warnings, truncated descriptions, and risk suggestions. Security docs scanning rejects risky command patterns such as pipe-to-shell installs and token-like command examples unless allowlisted. However, 727 of 1,462 skills are still `risk: unknown`, and strict validation is documented as a diagnostic hardening pass rather than a fully green gate.
- Self-learning / memory: Weak as a repo-level system. The repo has memory-related skills and `antigravity-skill-orchestrator` suggests recording successful skill combinations through `agent-memory-mcp`, but there is no shared memory store or learning loop in the distribution layer.
- Popular skills: No real usage telemetry was reviewed. Docs repeatedly point users toward starter skills such as `brainstorming`, `concise-planning`, `lint-and-validate`, `git-pushing`, `systematic-debugging`, `test-driven-development`, and `verification-before-completion`.

## Core Execution Path

For full-library installs, the main path starts in `tools/bin/install.js`:

1. Parse flags for target host (`--claude`, `--codex`, `--cursor`, `--gemini`, `--antigravity`, `--kiro`, or `--path`) plus optional selectors (`--risk`, `--category`, `--tags`, `--version`, `--tag`).
2. Resolve the install target. Codex uses `$CODEX_HOME/skills` when set, otherwise `~/.codex/skills`; Antigravity defaults to `~/.gemini/antigravity/skills`.
3. Shallow-clone `https://github.com/sickn33/antigravity-awesome-skills.git` into a temp directory. By default the clone ref is the npm package version tag, e.g. `v11.4.1`, not necessarily `main`.
4. Recursively list `skills/**/SKILL.md`, parse frontmatter, and filter by risk/category/tags when selectors are present. Selectors are ANDed across dimensions and allow exclude tokens with a trailing `-`.
5. Copy matching skill directories plus `docs/` into the target. The copy path rejects unsafe symlinks outside the source root and refuses destination symlinks.
6. Write `.antigravity-install-manifest.json` and prune previously managed entries that are no longer selected.
7. Print post-install guidance, including reduced-install advice for `.agents/skills` paths and overload recovery docs for Antigravity.

For plugin distributions, the source path is generated:

1. `tools/scripts/plugin_compatibility.py` scans each skill for target-specific home paths, absolute host paths, broken/escaped local references, undeclared runtime dependency files, and explicit target restrictions.
2. It writes `data/plugin-compatibility.json` with per-skill `codex` and `claude` support states plus blocked reasons.
3. `tools/scripts/generate_index.py` builds `skills_index.json`, attaches plugin compatibility metadata to each skill, infers or overrides categories, and mirrors the manifest to `data/skills_index.json`.
4. Generated plugin folders under `plugins/` and marketplace manifests under `.claude-plugin/` and `.agents/plugins/` expose one root plugin plus 36 bundle plugins for each host. In this snapshot, Codex supports 1,429 skills and Claude supports 1,444.

For focused activation, `scripts/activate-skills.sh` and `scripts/activate-skills.bat` sync `skills/` into an Antigravity library folder, archive or preserve the live folder, expand bundle names through `tools/scripts/get-bundle-skills.py`, and copy only selected skills into the live directory.

At actual use time, the host agent still does the execution: a user invokes a skill by name, the host loads that `SKILL.md`, and the agent follows the Markdown. The repository does not enforce TDD, debugging, memory, permission, or verification behavior beyond the instructions and packaging metadata.

## Architecture

- `skills/`: canonical source skill tree. 1,462 skill files were present in the reviewed commit; 79 skill folders include `scripts/`, 124 include `references/`, 12 include `templates/`, and 10 include `evals/evals.json`.
- `tools/bin/install.js`: npm installer CLI, target resolution, release-pinned shallow clone, selector filtering, safe copy, manifest write/prune, and post-install guidance.
- `tools/lib/`: shared Node helpers for frontmatter parsing, recursive skill discovery, symlink safety, project-root lookup, skill filtering, and workflow contract classification.
- `tools/scripts/`: repository generation, validation, audit, risk sync, catalog, plugin compatibility, reference validation, README/contributor sync, and web setup scripts.
- `data/`: generated or machine-readable manifests including `skills_index.json`, `bundles.json`, `editorial-bundles.json`, `workflows.json`, `plugin-compatibility.json`, `aliases.json`, and catalog data.
- `schemas/skills-index.v1.schema.json`: stable public discovery schema.
- `docs/users/`: user-facing install, usage, plugins, bundles, workflows, discovery manifest, overload recovery, and tool-specific guides.
- `docs/contributors/`: skill anatomy, template, quality bar, examples, security guardrails, and contribution guidance.
- `docs/maintainers/`: audit, release, rollback, repo sync, date tracking, generated-state, and security triage material.
- `.github/workflows/`: CI, repo hygiene, actionlint, CodeQL, dependency review, Pages, npm publish, skill review, and sync workflows.
- `.claude-plugin/` and `.agents/plugins/`: generated marketplace metadata for Claude Code and Codex.
- `plugins/`: generated root and bundle plugin directories. These duplicate plugin-safe subsets of `skills/`.
- `apps/web-app/`: React/Vite catalog UI and tests. Useful as a discovery surface, but not core to agent workflow execution.

`tools/config/generated-files.json` is important for maintenance. It marks `CATALOG.md`, root/data skill indexes, `data/catalog.json`, `data/bundles.json`, `data/plugin-compatibility.json`, `data/aliases.json`, `.agents/plugins/`, `.claude-plugin/*`, and `plugins/` as derived files. It also treats README and several docs/package files as mixed or release-managed.

## Design Choices

The central design choice is a plain filesystem skill format with generated distribution layers. `skills/<id>/SKILL.md` remains the source of truth; plugin folders and public indexes are generated products.

The second choice is separating discovery metadata from full instructions. `skills_index.json` provides id, path, category, name, description, risk, source, date, and plugin compatibility. This lets hosts search/select before reading full skill bodies.

The third choice is using multiple taxonomies rather than one canonical ontology. There are inferred categories from family prefixes and keyword rules, curated category overrides, generated machine bundles in `data/bundles.json`, and human editorial bundles in `data/editorial-bundles.json` / `docs/users/bundles.md`. This improves discoverability but creates naming drift such as `ai-ml` vs `data-ai`, `frontend` vs `front-end`, and broad `uncategorized`.

The fourth choice is treating plugin-safe as a portability filter. Compatibility checks block host-specific paths, absolute local paths, undeclared runtime dependency files, escaped references, broken references, or explicit target restrictions. They do not certify that the skill is behaviorally correct, low-risk, or deeply reviewed. In this snapshot, plugin-supported skills still include many `risk: unknown`, `critical`, and `offensive` entries.

The fifth choice is contributor source-only workflow. CI rejects direct derived-file changes in PRs, runs source validation, security docs checks, reference validation when needed, and previews generated drift separately. Main-branch workflows regenerate canonical artifacts.

The sixth choice is pragmatic safety hardening in tooling. Installer git refs are validated, symlink copies are constrained, install manifests prevent stale managed entries, bundle activation filters skill ids, and docs security tests scan for common high-risk command patterns.

## Strengths

The install/discovery model is practical. It supports full installs, reduced installs, tool-specific paths, release tags, custom paths, bundle plugins, and activation presets without requiring a custom host runtime.

The stable manifest is directly reusable. A small schema, mirrored payload, plugin compatibility metadata, and lazy-load guidance are enough for another host to implement safe discovery without reading 1,462 files up front.

The repo has better maintenance tooling than most skill collections. `npm run validate`, `audit:skills`, `validate:references`, `security:docs`, `plugin-compat:check`, generated-file contracts, and CI tests cover many registry integrity issues.

The plugin compatibility report is a useful pattern. Instead of publishing the whole source tree blindly, the repo records per-host supported/blocked status and reasons.

The skill authoring docs are useful for our own skill standards. `docs/contributors/skill-anatomy.md`, `quality-bar.md`, `security-guardrails.md`, `CONTRIBUTING.md`, and the sampled `writing-skills` skill all capture concrete frontmatter, trigger, limitations, examples, and safety expectations.

The context-overload response is realistic. Full libraries can hurt agent hosts, so the repo gives both preventive filters and recovery scripts rather than pretending the catalog size has no cost.

## Weaknesses

The corpus is uneven. Manifest stats in the reviewed commit show 727 `risk: unknown`, 228 missing `date_added`, 127 `uncategorized`, and only 10 `evals/evals.json` files across 1,462 skills. That is expected for a large community registry but important for reuse decisions.

Plugin-safe is easy to overread. The docs frame plugins as a safer default surface, but the implemented compatibility check is mainly path/setup portability. It does not block all high-risk content: Codex plugin-compatible entries include 714 `unknown`, 128 `critical`, and 24 `offensive` skills; Claude includes 721 `unknown`, 129 `critical`, and 25 `offensive` skills.

There is little behavioral verification of individual skills. CI checks metadata, references, plugin packaging, installer behavior, command-risk patterns, and web app behavior. It does not prove that a sampled skill reliably improves coding outcomes, enforces TDD in a host, or produces correct domain-specific code.

The taxonomy is useful but noisy. Seventy-five categories were present in the root manifest, with both generated and curated labels. This helps search, but a downstream system should normalize categories before depending on them.

Workflows are instructional metadata, not a scheduler. `data/workflows.json` and `docs/users/workflows.md` sequence skills for outcomes, but there is no workflow engine that checks artifacts, dependency order, or completion evidence.

Some sampled skills show generated or generic cleanup seams. For example, strong workflow skills such as `brainstorming`, `test-driven-development`, and `verification-before-completion` are still `risk: unknown`; `verification-before-completion` repeats a `When to Use` heading; and several meta/orchestrator skills are more aspirational than integrated with the repo-level manifest system.

The repo is large and duplicate-heavy from generated outputs. `plugins/antigravity-awesome-skills-claude/skills/**` duplicates 1,444 skill files, and bundle plugin folders duplicate smaller subsets. Reviewers must distinguish source from generated distribution artifacts.

## Ideas To Steal

Use a stable `skills_index.json`-style manifest with a JSON schema, source path, risk/source/date metadata, plugin compatibility metadata, and a documented lazy-load contract.

Separate source skill folders from generated distribution folders. Mark generated paths explicitly and keep PRs source-only.

Add an installer that supports release-pinned shallow clone, host-specific paths, custom path, risk/category/tag selectors, safe ref validation, symlink safety, install manifests, and stale-entry pruning.

Create a plugin compatibility report with blocked reasons. Keep compatibility separate from quality/risk review so users can see both dimensions.

Offer two levels of curation: machine-readable broad bundles for tooling and small editorial bundles for human onboarding.

Ship overload recovery as a first-class workflow. A backing `skills_library` plus live selected subset is a simple, reusable context-control pattern.

Adopt docs security scanning for dangerous command snippets, token-like examples, and offensive-skill disclaimers.

Use maintainer audit output with finding codes and suggested risk labels, but keep ambiguous risk changes manual.

## Do Not Copy

Do not import the whole skill corpus into a default Agentic Coding Lab context. It would create trigger noise, context pressure, and review burden.

Do not treat plugin compatibility as safety certification. A downstream plugin should additionally filter by risk, source trust, manual review status, and local policy.

Do not rely on the category taxonomy as-is for programmatic routing. Normalize or remap the categories first.

Do not copy legal, health, finance, offensive-security, or deployment-impacting skills without subject review and host-level permission controls.

Do not copy generated plugin folders or catalog files into our source-of-truth layer. Copy source patterns and generation contracts instead.

Do not overclaim workflow execution depth. Most repo-level workflows are playbooks for a host agent, not enforced pipelines with state, tests, and gates.

## Fit For Agentic Coding Lab

Fit is high for packaging, discovery, install, and validation patterns. It is medium for actual skill content reuse.

The best Agentic Coding Lab extraction is a smaller registry contract: source skills, public manifest, plugin compatibility report, bundle metadata, selector-based installer, source-only generated-file policy, and command-risk validation. For content, selectively review individual skills such as planning, debugging, TDD, verification, context management, skill-writing, and agent evaluation before adoption.

The repo is most valuable as a reference for scaling a skill ecosystem. It is less valuable as evidence that each skill works well. Any adopted skill should go through local review, risk labeling, and a small behavioral fixture.

## Reviewed Paths

- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/README.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/package.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/CONTRIBUTING.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/getting-started.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/usage.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/plugins.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/bundles.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/workflows.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/discovery-manifest.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/users/agent-overload-recovery.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/contributors/skill-anatomy.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/contributors/quality-bar.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/contributors/security-guardrails.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/maintainers/audit.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/maintainers/skills-update-guide.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/sources/sources.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/schemas/skills-index.v1.schema.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills_index.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/data/skills_index.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/data/bundles.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/data/editorial-bundles.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/data/workflows.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/data/plugin-compatibility.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/bin/install.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/lib/skill-utils.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/lib/symlink-safety.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/lib/skill-filter.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/lib/workflow-contract.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/config/generated-files.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/generate_index.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/plugin_compatibility.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/validate_skills.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/audit_skills.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/build-catalog.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/get-bundle-skills.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/tests/run-test-suite.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/tests/installer_filters.test.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/tests/plugin_directories.test.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/tools/scripts/tests/docs_security_content.test.js`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.github/workflows/ci.yml`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.github/workflows/skill-review.yml`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.claude-plugin/plugin.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.agents/plugins/marketplace.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/plugins/antigravity-awesome-skills/.codex-plugin/plugin.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/plugins/antigravity-awesome-skills-claude/.claude-plugin/plugin.json`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/scripts/activate-skills.sh`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/scripts/activate-skills.bat`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/brainstorming/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/systematic-debugging/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/test-driven-development/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/verification-before-completion/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/writing-skills/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/scripts/scan_registry.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/scripts/match_skills.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/scripts/orchestrate.py`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/references/capability-taxonomy.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-orchestrator/references/orchestration-patterns.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/antigravity-skill-orchestrator/SKILL.md`
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/skills/agent-evaluation/SKILL.md`
- `https://api.github.com/repos/sickn33/antigravity-awesome-skills`

## Excluded Paths

- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.git/`: VCS internals; only HEAD commit, latest commit metadata, and clean status were needed.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/apps/web-app/**`: React/Vite catalog UI. Sampled only through repo structure and package scripts; excluded from deep review because the task focus is AI coding workflow and skill packaging, not the public browsing UI.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/plugins/**`: generated plugin distributions and duplicated skill trees. Reviewed root manifests and generation policy, not every copied plugin skill.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/.agents/plugins/**` and `.claude-plugin/**`: generated marketplace metadata. Sampled manifests only.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/CATALOG.md`, `data/catalog.json`, `data/aliases.json`, and generated catalog/web assets: derived outputs; reviewed by contract and representative stats rather than line-by-line.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs_zh-CN/**` and `/tmp/myagents-research/sickn33-antigravity-awesome-skills/docs/vietnamese/**`: translated duplicates of canonical docs; excluded to avoid duplicate conclusions.
- `/tmp/myagents-research/sickn33-antigravity-awesome-skills/assets/**`, web public images/icons, PDFs such as `theme-showcase.pdf`, tarballs such as `shadcn-components.tar.gz`, and other binary/media files: binary or presentation assets, not workflow mechanics.
- Most individual `skills/**/SKILL.md` files: the corpus is too large for line-by-line review in one candidate note. I sampled AI coding workflow, orchestration, evaluation, and skill-authoring paths and used manifest/tooling stats for corpus-level claims.
- `package-lock.json`, `data/package-lock.json`, and `apps/web-app/package-lock.json`: lockfiles noted for reproducibility but not reviewed line-by-line.
- CI workflows not listed above, issue/discussion templates, funding, code of conduct, release notes, star-history image generation, and translated maintainer reports: governance or presentation material outside the reviewed execution/discovery path.
