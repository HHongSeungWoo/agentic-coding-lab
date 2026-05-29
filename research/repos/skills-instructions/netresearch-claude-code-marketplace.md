# netresearch/claude-code-marketplace

- URL: https://github.com/netresearch/claude-code-marketplace
- Category: skills-instructions
- Stars snapshot: 39 (GitHub REST API, captured 2026-05-29; matches index row snapshot)
- Reviewed commit: 92f83ed8f04a8df0f5acbef8a313cf678725e80c
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful reference for operating a curated skill marketplace, package-style skill distribution, human discovery pages, and skill-repo quality gates. It does not implement a runtime skill selector or semantic router; it mostly reduces selection overhead through catalog structure, categories, related-skill links, short descriptions, package managers, and generated `AGENTS.md` indexes handled by adjacent tooling.

## Why It Matters

`netresearch/claude-code-marketplace` is a real vendor/team marketplace for Agent Skills rather than a loose prompt list. It shows how an organization with many domain skills can avoid copying full skill bodies into one repository: the marketplace keeps a compact `.claude-plugin/marketplace.json` of source references, while each skill stays in its own repository.

For skill-management-routing research, the repo is valuable because it attacks the "too many skills" problem at the catalog and distribution layers. It groups skills by domain, creates bilingual per-skill landing pages, enforces no-orphan metadata, exposes several install flows, and points to package-manager integrations that register only installed skills into a project `AGENTS.md` block.

The main caveat is important. This repo is not the host-side loader that chooses a skill during an agent session. It cannot prove that Claude Code, Codex, Cursor, or another agent will route correctly once dozens of skills are installed. Its reusable patterns are marketplace shape, metadata discipline, distribution channels, and validation, not model-side activation logic.

## What It Is

The repository is a Claude Code plugin marketplace plus a GitHub Pages discovery site for 40 Netresearch Agent Skills. The source-of-truth catalog is `.claude-plugin/marketplace.json`, whose `plugins[]` entries contain `name`, `description`, `source.repo`, and a canonical `category`.

The marketplace uses source references only. It does not vendor the skill repositories. Claude Code installs skills from their source repos through `/plugin marketplace add netresearch/claude-code-marketplace` and `/plugin install <skill>@netresearch-claude-code-marketplace`; other agents can use `npx skills add`, Composer, npm, releases, or direct clone flows described in the site and linked skill READMEs.

The repo also contains an Eleventy site under `site/`. The site reads the marketplace manifest, fetches linked skill README files at build time, extracts use cases, expected outputs, context requirements, tags, and related skills, then renders EN/DE landing pages, per-skill detail pages, search indexes, sitemaps, OpenGraph images, and JSON-LD.

The catalog contains a notable "skill-skills" group: `agent-harness`, `automated-assessment`, `retro`, `agent-rules`, and `skill-repo`. The site presents them as an improvement loop where harness makes repos agent-ready, assessment checks work against checkpoints, retro turns session friction into rules/skills/checkpoints, and the companion skills generate rules or standardize skill repositories.

## Research Themes

- Token efficiency: Moderate. The repo avoids one giant skill bundle by keeping marketplace metadata small and skill bodies in external repos. The generated site and package integrations support progressive disclosure, but the marketplace descriptions themselves still form a 40-skill catalog and do not implement query-time shortlist retrieval for the agent.
- Context control: Moderate to strong at distribution time. `AGENTS.md` says runtime behavior stays in each skill repo's `SKILL.md`; the marketplace owns discovery copy, categories, installation paths, related links, and landing pages. Linked Composer/npm tooling then registers a lightweight project `AGENTS.md` index with `read-skill` style detail loading.
- Sub-agent / multi-agent: Indirect. The marketplace includes `automated-assessment`, whose README describes domain-batched LLM agents, and `retro`, which can materialize learnings into skill PRs or checkpoints. The marketplace repo itself does not orchestrate subagents.
- Domain-specific workflow: Strong. Most entries are TYPO3, PHP, DevOps, security, Jira, documentation, and Netresearch workflow skills. The catalog has both canonical categories and thematic groups, giving humans a domain map instead of a flat list.
- Error prevention: Strong for marketplace maintenance. Validation enforces JSON shape, unique slugs/descriptions, category enum, slug regex, description hard cap, README catalog rows, no-orphan metadata, hreflang consistency, visual regression, Lighthouse, gitleaks, dependency review, and pinned GitHub Actions.
- Self-learning / memory: Moderate through adjacent skills. `retro` analyzes sessions and routes learnings to user memory, project rules, skill updates, new skills, checkpoints, or harness artifacts. The marketplace only lists and explains this loop; the learning mechanism lives in `retro-skill`.
- Popular skills: The repo has no install telemetry per skill. Catalog-level signals favor the "skill-skills" loop, TYPO3 development skills, and daily-driver productivity skills such as `context7`, `file-search`, `cli-tools`, `jira-integration`, `coach`, and `retro`.

## Core Execution Path

The native marketplace path starts with Claude Code:

1. The user adds the marketplace with `/plugin marketplace add netresearch/claude-code-marketplace`.
2. Claude Code reads `.claude-plugin/marketplace.json`.
3. The user browses or installs a skill with `/plugin install <slug>@netresearch-claude-code-marketplace`.
4. The marketplace entry points Claude Code at `source.repo`, such as `netresearch/agent-harness-skill`.
5. Runtime execution then belongs to the installed skill repo and host agent, not this marketplace repo.

The public discovery path is a build-time pipeline:

1. `site/src/_data/marketplace.js` reads `.claude-plugin/marketplace.json`.
2. `site/scripts/fetch-readmes.js` uses Octokit to fetch every linked skill README and latest release, with ETag caching.
3. `site/scripts/parse-readme.js` extracts sections such as use cases, expected outputs, context requirements, related skills, and tags using tolerant heading aliases.
4. `site/src/_data/skills.js` merges marketplace entries, README cache, German descriptions, category labels, groups, install methods, derived related skills, and fallback use cases.
5. `site/scripts/check-orphans.js`, `check-categories.js`, and `check-seo-copy.js` validate the merged data.
6. Eleventy renders landing pages, per-skill detail pages, search indexes, sitemap, robots, 404 pages, JSON-LD, and install blocks.
7. `site/src/assets/js/enhance.js` adds install-method tabs, copy buttons, and client-side skill search without making the page dependent on JavaScript.

The package-style distribution path is external but explicitly wired into this repo:

- `site/src/_data/installMethods.js` generates Claude Code, `npx`, Composer package, and Composer direct-source install commands.
- The README and site point Node projects to `@netresearch/agent-skill-coordinator`, which scans `node_modules` on `postinstall`, validates skill metadata, and writes a managed `<skills_system>` block into `AGENTS.md`.
- The README and site point PHP projects to `netresearch/composer-agent-skill-plugin`, which discovers skills from packages or direct sources, applies trust prompts, pins direct sources in `composer.skills.lock`, and generates the same lightweight `AGENTS.md` skill index.

That package path is the closest thing to context-overhead reduction: projects import only relevant skill packages, expose name/description/location in `AGENTS.md`, and leave full `SKILL.md` content behind a read command.

## Architecture

The repository has four main layers:

- Marketplace manifest: `.claude-plugin/marketplace.json` has 40 `github` source references. Category distribution at review time was `development=26`, `workflow=5`, `devops=3`, `security=2`, `productivity=2`, `design=1`, and `document=1`.
- Maintenance rules: `AGENTS.md` defines scope separation, required marketplace fields, canonical categories, SEO/discovery rules, no-orphan rules, mirroring rules, and the checklist for marketplace changes.
- Validation and CI: `scripts/validate.sh` validates the manifest locally and in `.github/workflows/validate.yml`; `.github/workflows/pages.yml` builds and checks the site; `.github/workflows/security.yml` delegates gitleaks and dependency-review to reusable Netresearch workflows.
- Discovery site: `site/` is an Eleventy app with data loaders, parsers, category/group metadata, bilingual strings, templates, search JSON, CSS, small progressive enhancement JS, Playwright snapshots, and Lighthouse configuration.

Important local files:

- `.claude-plugin/marketplace.json`: installable marketplace index.
- `README.md`: human catalog grouped by Skill-skills, TYPO3, OroCommerce, quality/security, DevOps, productivity/integration, and branding.
- `AGENTS.md`: marketplace governance and metadata requirements.
- `SPEC.md` and `PLAN.md`: shipped design record for the GitHub Pages discovery site.
- `site/src/_data/skills.js`: central merge point from manifest, README cache, install methods, categories, groups, and fallback derivation.
- `site/src/_data/installMethods.js`: package-style command generator.
- `site/scripts/fetch-readmes.js` and `parse-readme.js`: aggregation from external skill repos.
- `site/scripts/check-orphans.js`: blocking no-orphan check over the merged skill data.
- `site/src/assets/js/enhance.js`: human search and install-copy UX.

## Design Choices

The marketplace deliberately separates discovery from execution. `AGENTS.md` says the marketplace owns catalog structure, categories, landing pages, installation paths, cross-links, and SEO copy, while execution semantics, triggers, and procedural detail stay in each skill repo's `SKILL.md`.

The manifest uses source references instead of vendoring skill bodies. This keeps the marketplace small and avoids a monolithic context file, but it also means trust, versioning, and runtime behavior are spread across many upstream repos.

The repo has two taxonomies. `plugins[].category` is a strict seven-value enum for validation and SEO, while `site/src/_data/groups.js` is a more narrative grouping for human browsing. This is a useful distinction: machine validation gets a stable enum, while humans get domain-oriented clusters.

The site treats every listed skill as a first-class page. Each skill should have a canonical detail URL, category, use cases, expected outputs, context requirements, related skills or a justified none, source repo, install path, and bilingual descriptions where applicable. This is a direct attack on catalog rot.

The build pulls skill-specific discovery fields from source READMEs instead of duplicating long procedural content. The repo already identifies a better future direction: use `SKILL.md` frontmatter for discovery fields such as `useCases`, `relatedSkills`, `expectedOutputs`, and `contextRequirements` rather than scraping README sections.

Package-manager integration is intentionally delegated. The marketplace advertises Composer and npm paths but does not implement either. The Node coordinator design is especially relevant: one coordinator package owns `postinstall`, scans data-only skill packages, and writes one `AGENTS.md` block, so individual skill packages do not each run scripts.

## Strengths

The repo is a strong example of a curated team marketplace. It keeps one compact install index, pushes skill runtime behavior to source repos, and gives users enough human-facing metadata to choose skills without opening 40 repositories.

The no-orphan rule is a useful catalog-quality primitive. Requiring category, use case, related skills or explicit none, repo link, install path, and canonical URL prevents "name plus vague description" entries from accumulating.

The "skill-skills" loop is a valuable operating model. Harness, assessment, retro, agent-rules, and skill-repo together form a lifecycle for making repos agent-ready, evaluating against skill checkpoints, feeding session friction back into rules/skills, and standardizing new skills.

Package-style distribution is practical. Composer and npm integrations let a project declare skills as dependencies and expose a lightweight `AGENTS.md` index. This is better than asking every agent session to scan a global marketplace with all available skills.

The site build is disciplined. It uses source metadata, generated pages, search JSON, hreflang checks, visual regression, Lighthouse, OpenGraph generation, and schema.org metadata. This makes the marketplace useful to humans and search engines without changing runtime skill behavior.

Security hygiene is better than many skill catalogs. Actions are pinned by SHA in the workflows, marketplace JSON is validated, gitleaks/dependency-review are present, the site parser escapes inline Markdown before re-marking safe output, and install scripts are centralized in package-manager coordinators rather than every skill package running arbitrary `postinstall`.

## Weaknesses

The repository does not implement skill activation, semantic routing, shortlist retrieval, conflict resolution, or context budgeting inside an agent. If a user installs many skills, the host agent still decides how to expose and choose them.

The marketplace entries are not pinned to commits, tags, versions, or digests. A `source.repo` reference is convenient, but it does not by itself preserve the exact upstream skill content reviewed when the marketplace entry was added.

The human site search is not an agent router. It helps humans find skills by slug, display name, description, category, tags, and use cases, but it does not produce a compact task-specific skill shortlist for an agent session.

README parsing is a brittle discovery source. The parser is tolerant and cached, but headings can drift, nested sections can leak, and README prose is not the same as a stable machine contract. The repo acknowledges `SKILL.md` frontmatter discovery as the better long-term path.

The root `scripts/validate.sh` validates the manifest and README table, but not external repo trust, release pins, skill body safety, tool permissions, or semantic trigger overlap. Site CI fetches README data, but external skill content remains a distributed review problem.

Cross-ecosystem package integration has a known edge. The Node coordinator README says hybrid PHP/JS projects using both Composer and npm tools currently have a "last writer wins" issue for the shared `AGENTS.md` block. That is a real coordination risk for teams with both ecosystems.

The catalog is heavily Netresearch/TYPO3/PHP oriented. That is useful for domain specificity, but many patterns would need adaptation before serving as a general multi-organization skill marketplace.

## Ideas To Steal

Use a two-layer model: a compact machine marketplace manifest for install/source metadata and a richer human discovery site generated from source repos.

Require every skill listing to pass a no-orphan rule. At minimum: slug, display name, source repo, install command, category, short description, use cases, context requirements, related skills or justified none, and canonical detail page.

Separate machine category enum from human presentation groups. The former should be stable and validated; the latter can be tuned for discoverability.

Adopt package-manager coordinators for project-local skills. A project should declare the skills it actually needs, then generate a lightweight `AGENTS.md` index with name, description, and read command instead of loading a whole global marketplace.

Copy the "one coordinator, data-only skill packages" npm pattern. It reduces install-time script surface, avoids races between skill packages, and centralizes metadata validation and `AGENTS.md` writes.

Use a skill-skills lifecycle. Harness makes repos agent-ready, assessment evaluates checkpoints, retro mines session friction, agent-rules generates compact project instructions, and skill-repo standardizes authoring/distribution.

Move discovery metadata into `SKILL.md` frontmatter or another stable source-owned machine field. README scraping is a useful bridge, but long-term routing needs structured metadata.

Generate human pages and agent-facing indexes from the same manifest. Drift gets much harder when the manifest is the single source for source repos, categories, install commands, and slugs.

Add a context-budget policy on top of this pattern: only expose installed project skills by default, cap description length, support negative triggers, and retrieve a short skill shortlist before final model selection.

## Do Not Copy

Do not treat a marketplace catalog as a routing system. A catalog helps discovery; a router still needs task classification, deterministic filters, trigger tests, conflict handling, and telemetry.

Do not leave source references unpinned if review provenance matters. Add commit/tag/digest fields or lock files for the exact skill content that was reviewed and installed.

Do not rely on README sections as the only structured discovery metadata. Use source-owned structured fields and validate them in every skill repo.

Do not install a broad global catalog into every project. Keep project-local enabled skill sets small and dependency-like.

Do not let separate package ecosystems overwrite the same generated `AGENTS.md` block without a merge protocol. Hybrid projects need one writer or a deterministic aggregator.

Do not assume description-only routing will scale. Long or overlapping descriptions can increase context cost and trigger ambiguity; descriptions need evals, negative examples, and usage data.

Do not copy the public site as an agent context surface. The site is for humans. Agent-facing routing should use a compact index and load details only on demand.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. The repo is directly relevant to skill management and distribution, but it should be used as a marketplace and operations reference rather than as a runtime router reference.

For Agentic Coding Lab, the best adaptation would be:

- `skills.index.json` or equivalent compact registry with slug, category, domain, task verbs, positive triggers, negative triggers, required context, tools, risk level, maturity, source repo, pinned commit, and last-reviewed date.
- A generated human catalog like this repo's Pages site, but separate from the agent-facing shortlist index.
- Project-local skill dependency files, with Composer/npm-style coordinators writing an `AGENTS.md` block for only the enabled skills.
- A validator that checks no-orphan metadata, category enum, description length, trigger overlap, path safety, source pins, license fields, and README/site drift.
- A retro/assessment loop that turns skill activation failures into trigger metadata updates, tests, or skill PRs.

The repo's strongest lesson is organizational: once the number of skills grows, skill management becomes a product surface. You need catalog governance, install channels, source ownership, package locks, quality checks, and pruning rules before the model ever sees a skill description.

## Reviewed Paths

- `/tmp/myagents-research/netresearch-claude-code-marketplace/README.md`: marketplace overview, skill list, skill-skills group, install paths, source-reference architecture, internal marketplace note, and discovery site link.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/.claude-plugin/marketplace.json`: 40-plugin catalog, source references, descriptions, categories, and schema URL.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/AGENTS.md`: scope separation, required fields, category enum, no-orphan rule, mirroring rule, SEO/discovery rules, and marketplace workflow checklist.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/SPEC.md`: shipped Pages architecture, assumptions, data sources, validation strategy, known overrides, and Phase 2 follow-ups.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/PLAN.md`: build pipeline, component responsibilities, risks, verification checkpoints, and package/discovery follow-ups.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/scripts/validate.sh`: manifest syntax, structure, duplicate, category, slug, description, and README-row validation.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/.github/workflows/validate.yml`: marketplace validation workflow.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/.github/workflows/pages.yml`: site build, README fetch, checks, Lighthouse, visual regression, and Pages deploy.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/.github/workflows/security.yml`: delegated gitleaks and dependency-review workflows.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/package.json`: Eleventy scripts, checks, build commands, and dependencies.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/.eleventy.js`: static site config, inline Markdown safety filter, path prefix, and rendering filters.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/scripts/fetch-readmes.js`: Octokit README/latest-release fetcher, ETag cache, parser rerun on 304, and strict-fetch behavior.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/scripts/parse-readme.js`: tolerant section extraction and related-skill link parsing.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/scripts/check-orphans.js`: blocking required-field/no-orphan check over merged skill data.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/scripts/check-categories.js`: category enum check over merged skill data.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/scripts/check-seo-copy.js`: advisory SEO and description checks.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/marketplace.js`: marketplace summary loader.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/skills.js`: canonical merged skill objects and fallback derivation.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/installMethods.js`: Claude Code, npx, Composer package, and Composer direct-source install command generation.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/groups.js`: thematic discovery groups, especially `skill-skills`.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/categories.js`: seven-value category enum and labels.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/searchIndex.js`: generated human search-index payload.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/overrides.json`: documented related-skill exceptions.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_data/i18n/en.json`: skill-skills loop copy, install flow, search labels, and discovery text.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_includes/partials/skill-card.njk`: card-level category, description, install, and detail link rendering.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_includes/partials/install-block.njk`: reusable copyable install command block.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/_includes/layouts/skill.njk`: per-skill install, use case, context, related-skill, tag, repo-link, and JSON-LD rendering.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/en/index.njk`: English landing page, skill-skills loop, grouped cards, and search form.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/src/assets/js/enhance.js`: install-method tabs, copy-to-clipboard, lazy search index, and card filtering.
- External README cross-checks: `netresearch/node-agent-skill-coordinator`, `netresearch/composer-agent-skill-plugin`, `netresearch/skill-repo-skill`, `netresearch/agent-harness-skill`, `netresearch/automated-assessment-skill`, `netresearch/retro-skill`, and `netresearch/agent-rules-skill`.
- GitHub REST API response for `netresearch/claude-code-marketplace`: stars, forks, topics, license, default branch, updated/pushed timestamps, and repository metadata.

## Excluded Paths

- `/tmp/myagents-research/netresearch-claude-code-marketplace/.git/`: VCS internals, excluded except for commit capture.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/package-lock.json`: dependency lockfile noted for npm context but not line-by-line audited.
- `/tmp/myagents-research/netresearch-claude-code-marketplace/site/tests/visual/*-snapshots/*.png`: visual-regression baselines, not relevant to skill routing or catalog architecture.
- CSS styling details under `site/src/assets/css/`: skimmed only for site architecture; not reviewed for visual design because the research focus was skill management and routing.
- Full source of external linked skill repositories: only public README files were cross-checked for package-style distribution and skill-skills responsibilities. Their implementations need separate repo notes if we want to review their actual scripts, hooks, trust models, and command behavior.
- Runtime behavior inside Claude Code, Cursor, Codex, GitHub Copilot, Gemini CLI, or skills.sh: inferred from repository docs and install commands only; the host loaders were not part of this checkout.
