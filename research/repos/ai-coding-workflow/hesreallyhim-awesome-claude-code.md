# hesreallyhim/awesome-claude-code

- URL: https://github.com/hesreallyhim/awesome-claude-code
- Category: ai-coding-workflow
- Stars snapshot: 44,327 via GitHub API on 2026-05-20
- Reviewed commit: 614f102accbcd48206d63a21df64adc984026b40
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value discovery and taxonomy source for Claude Code workflow artifacts, especially skills, hooks, commands, orchestrators, CLAUDE.md patterns, context tooling, and verification resources. Treat it as a curated map plus maintenance pipeline, not as a reusable implementation framework or proof that listed projects are safe.

## Why It Matters

`awesome-claude-code` is one of the broadest Claude Code ecosystem indexes. It matters for Agentic Coding Lab because it exposes the current working vocabulary of AI coding support systems: agent skills, slash commands, hooks, status lines, CLAUDE.md files, workflows, orchestrators, config managers, alternative clients, official docs, and output styles.

The best research value is taxonomy and candidate discovery. The repository's CSV currently contains 226 total resources and 203 active resources. Active categories include 51 Tooling entries, 43 Slash-Commands, 35 Workflows & Knowledge Guides, 24 CLAUDE.md Files, 19 Agent Skills, 12 Hooks, 7 Status Lines, 5 Alternative Clients, 4 Output Styles, and 3 Official Documentation entries. That spread is useful for finding follow-up candidates around context management, MCP, verification, memory, subagents, and agent orchestration.

The repo is not itself a Claude Code runtime. Most workflow depth lives in linked third-party projects, short copied examples under `resources/`, and generated README views. Any concrete pattern from a listed resource still needs separate source review.

## What It Is

The repository is a CSV-backed awesome list with a significant automation layer. `THE_RESOURCES_TABLE.csv` is the source of truth. Python scripts generate multiple README views, badges, category assets, flat sortable/filterable pages, and repo ticker SVGs. GitHub Actions validate submissions, enforce contribution rules, create resource PRs after maintainer approval, validate links, update release data, check repository health, and send badge notifications.

At the reviewed commit, the root `README.md` is a work-in-progress Table of Contents placeholder. The usable public list is mainly in `README_ALTERNATIVES/README_AWESOME.md`, `README_ALTERNATIVES/README_CLASSIC.md`, `README_ALTERNATIVES/README_EXTRA.md`, and the generated flat views. `resources/` preserves a limited set of small resource excerpts such as slash commands, CLAUDE.md files, design-review workflow files, and official Claude Code GitHub Actions examples, but the repo explicitly says this directory is not currently a full maintained archive.

## Research Themes

- Token efficiency: Moderate. The repo does not implement a token-saving system, but it is useful for discovering token/context tools such as context priming commands, usage monitors, session restore/search tools, compact CLAUDE.md examples, and status lines that expose context usage. The generated flat views reduce browsing cost by category and sort order.
- Context control: Strong as a discovery map. The table includes context priming, CLAUDE.md files, Basic Memory, session restore, conversation search, context-engineering kits, MCP-enhanced configs, and status/context monitors. The resource samples show commands that explicitly read project files, load docs, or build Product Requirement Prompts.
- Sub-agent / multi-agent: Strong as a candidate source. The list includes agent skills, subagent collections, orchestrators, teams, swarms, task managers, design-review agents, and Claude Code GitHub Actions examples. The repo itself does not orchestrate coding agents beyond its curation automation.
- Domain-specific workflow: Strong. Categories separate skills, workflows, tooling, hooks, commands, CLAUDE.md files, official docs, clients, and status lines. Slash-command subcategories split version control, testing, context loading, documentation, CI/deployment, and project/task management.
- Error prevention: Mixed. The curation process asks submitters to disclose network calls, elevated permissions, validation prompts, installation/uninstallation behavior, and claim evidence. The repo includes a static `.claude/commands/evaluate-repository.md` safety review prompt, URL validation, duplicate checks, stale-resource flags, CI, link validation, and repo health checks. It does not verify third-party resources deeply or continuously beyond metadata/link checks.
- Self-learning / memory: Conditional. The repo lists memory/session tools such as Basic Memory, Claude Session Restore, recall, `cc-sessions`, and `claude-code-tools`, but it does not provide a local memory engine.
- Popular skills: No usage telemetry is present. High-signal listed skill candidates include AgentSys, Claude Code Agents, Compound Engineering Plugin, Context Engineering Kit, Everything Claude Code, Fullstack Dev Skills, Superpowers, Trail of Bits Security Skills, and TACHES Claude Code Resources.

## Core Execution Path

The main local execution path is README generation:

1. Maintainer or automation edits `THE_RESOURCES_TABLE.csv`.
2. `make generate` runs `scripts.resources.sort_resources`, then `scripts.readme.generate_readme`.
3. The generator loads CSV rows with `Active == TRUE`, applies `templates/resource-overrides.yaml`, loads `templates/categories.yaml`, and renders Awesome, Classic, Extra, and Flat README variants.
4. Flat views are generated for category x sort combinations using `scripts/readme/generators/flat.py`.
5. SVG badges and ticker assets are generated under `assets/`.
6. CI runs formatting, mypy, tests, and docs-tree checks.

The main contribution execution path is GitHub-hosted:

1. User submits a resource through `.github/ISSUE_TEMPLATE/recommend-resource.yml`.
2. `submission-enforcement-v2.yml` enforces the web-form flow, cooldown state, PR-submission rejection, and one-week repository age rule. Pull requests that look like resource submissions are classified with an Anthropic API call and closed if they bypass the issue pipeline.
3. `validate-new-issue.yml` sparse-checks out scripts/templates/CSV, parses the issue, validates required fields, validates URLs, checks duplicates, updates labels, and posts a validation comment.
4. A maintainer comments `/approve`, `/reject`, or `/request-changes`.
5. `handle-resource-submission-commands.yml` parses approved issues and calls `scripts.resources.create_resource_pr`.
6. `create_resource_pr.py` generates an ID, fetches GitHub commit/release metadata, appends the row, sorts CSV, regenerates READMEs/assets, validates expected generated outputs, commits, pushes, and opens a PR.
7. Merge-time notification can open a badge issue in the included resource repo unless `do-not-disturb` is set.

This is a substantial curation pipeline, but it is separate from the workflow implementations that the list points to.

## Architecture

The architecture is filesystem and GitHub Actions native:

- `THE_RESOURCES_TABLE.csv`: source table with ID, display name, category, subcategory, links, author, active/stale state, license, description, repository dates, release data, and source.
- `templates/categories.yaml`: category order, names, prefixes, icons, descriptions, and subcategories for generated README bodies.
- `templates/resource-overrides.yaml`: manual locks and skip-validation flags for special resources.
- `acc-config.yaml`: root README style and style-selector config.
- `scripts/readme/`: generator classes, markup renderers, path helpers, SVG templates, and asset writers.
- `scripts/resources/`: issue parsing, resource PR creation, CSV append/sort helpers, informal submission detection, and optional resource downloading.
- `scripts/validation/`: URL validation, GitHub metadata enrichment, stale-resource tracking, single-resource validation.
- `scripts/maintenance/`: repository health and release metadata updates.
- `scripts/ticker/`: GitHub search/ticker data fetching and SVG ticker generation.
- `.github/workflows/`: CI, link validation, release updates, ticker updates, submission enforcement, approval command handling, badge notifications, and repo health checks.
- `.claude/commands/evaluate-repository.md`: static review prompt for curation risk analysis.
- `resources/`: small snapshots of selected commands, CLAUDE.md files, official docs examples, and one design-review workflow.
- `README_ALTERNATIVES/`: generated list views.
- `assets/`: generated and static visual assets for badges, headers, table-of-contents graphics, social images, and tickers.

There is no MCP server, agent runtime, plugin installer, or local Claude Code command pack meant to be adopted as a complete workflow system.

## Design Choices

The central design choice is a single CSV "backend" with many generated Markdown views. That makes the list searchable and maintainable while still fitting GitHub README constraints.

The second useful choice is category separation by Claude Code primitive. Skills, hooks, slash commands, CLAUDE.md files, workflows, tooling, orchestrators, status lines, and clients are not mixed into one flat bucket. For research, this is more useful than a pure star-ranked list.

The third choice is a structured intake pipeline instead of user PRs. The project treats resource recommendations as form data, validates them, then lets a maintainer trigger PR creation through slash-command comments. This avoids merge conflicts in generated assets and reduces malformed submissions.

The fourth choice is metadata enrichment and freshness tracking. GitHub commit dates, release dates, license data, stale flags, broken-link issues, repo health checks, and ticker snapshots all feed the discovery layer. These are metadata checks, not implementation audits.

The fifth choice is conservative curation language. The issue template asks for install/uninstall instructions, network-call disclosure, elevated-permission disclosure, validation tasks, and evidence for claims. `.claude/commands/evaluate-repository.md` formalizes a static review prompt around implicit execution surfaces such as hooks, shell scripts, network access, and persistent state.

One inconsistent design point is `Output Styles`: it appears in the CSV and issue form, and flat views have a `styles` filter, but `templates/categories.yaml` does not define an `Output Styles` category. As a result, non-flat generated README views omit those active rows.

## Strengths

- Excellent discovery spread across the current Claude Code ecosystem.
- Useful taxonomy for AI coding workflows: skills, hooks, commands, CLAUDE.md, workflows, orchestrators, config managers, status/context monitors, clients, and docs.
- CSV source of truth supports scripts, generated views, and automated metadata updates.
- Flat README permutations give practical category and sort navigation without JavaScript.
- Intake workflow requires human maintainer approval while automating validation and PR creation.
- Submission form asks the right safety questions for agent workflow artifacts: shell execution, network calls, elevated permissions, uninstall path, and evidence of claims.
- `.claude/commands/evaluate-repository.md` is a concise reusable static-review prompt for curation triage.
- Tests cover generator path behavior, category utilities, link/resource validation, ticker generation, issue detection, README output expectations, and TOC anchors.
- Resource samples preserve concrete examples of context priming, PR review, testing-plan prompts, design-review agents, Playwright MCP usage, and Claude Code GitHub Actions.

## Weaknesses

- Root `README.md` is currently a WIP placeholder, so users must know to inspect generated alternatives or the CSV for the actual list.
- This is a curated index, not an implementation review corpus. Descriptions are useful triage hints, not verified technical claims.
- 84 active resources are marked stale and 2 active resources are also marked removed from origin, so freshness requires checking the row metadata before using entries.
- `resources/` is explicitly no longer a full maintained archive and contains only selected snippets.
- `Output Styles` is present in the CSV and issue form but absent from `templates/categories.yaml`, which creates a rendering/taxonomy mismatch outside flat views.
- Category granularity is helpful but still uneven: MCP appears mostly under Tooling or CLAUDE.md Files rather than as a first-class category.
- Submission enforcement uses a private ops repo and Anthropic API classification path, so the full operational state and model decision logs are not reproducible from the public repo alone.
- The curation pipeline can detect broken links, duplicates, licenses, and stale repositories, but it cannot prove that installable hooks, shell scripts, or orchestrators are safe.
- Several copied command examples are intentionally prompt-only and can be overbroad if reused without local permission and verification boundaries.

## Ideas To Steal

- Use a single structured table for candidate discovery, then generate multiple human views from it.
- Keep category prefixes in IDs, for example `skill-*`, `cmd-*`, `hook-*`, `wf-*`, so resource type survives sorting and display changes.
- Add flat generated views for category and sort navigation when a Markdown-only interface must stay searchable.
- Require resource submissions to provide validation tasks and prompts, not just marketing claims.
- Add curation questions for network calls, telemetry, shell scripts, elevated permissions, and uninstall behavior.
- Use a static repository-evaluation command that focuses on implicit execution surfaces, declared vs actual permissions, persistent state, and red flags.
- Separate "metadata validation passed" from "maintainer reviewed" from "resource adopted"; those are different trust levels.
- Track `Last Modified`, `Last Checked`, `Stale`, `Repo Created`, and `Latest Release` directly in candidate metadata.
- Treat context-management resources as a dedicated discovery theme even when they arrive under different product labels.
- Maintain small local fixtures of commands/CLAUDE.md/actions examples for taxonomy study, while linking to full upstream sources for deep reviews.

## Do Not Copy

- Do not copy the listed third-party resources into our own workflow without deep-reviewing their source repositories.
- Do not treat awesome-list inclusion as security approval.
- Do not adopt copied prompt snippets that run shell commands, read broad diffs, or call external tools without adapting permissions and verification gates.
- Do not rely on link health, GitHub release dates, or issue counts as a substitute for implementation quality.
- Do not mirror large third-party repos into our research tree; keep notes and source links instead.
- Do not couple core research indexes to generated visual assets. The data model should remain useful without README artwork.
- Do not add a category in the issue form or CSV without ensuring every generator category registry can render it.
- Do not use a private operational state repo for essential public reproducibility unless the public repo documents the resulting state transitions clearly.

## Fit For Agentic Coding Lab

Fit is strong for discovery and taxonomy, medium for direct artifact adoption.

Agentic Coding Lab should use this repo as a candidate source for follow-up deep reviews in ai-coding-workflow, skills-instructions, mcp, context-control, memory, harness-eval, and error-prevention. It is especially good for identifying clusters: context priming, MCP helpers, repo/session memory, PR review commands, quality hooks, subagent teams, orchestrators, status lines that expose context/token data, and config managers that validate agent files.

It should not be used as evidence that a listed project works or is safe. The right adoption path is to mine the taxonomy, pick individual high-fit resources, clone those upstream repos separately, and write repo notes against their actual code and prompts.

## Reviewed Paths

- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/README.md`: current root WIP state.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/README_ALTERNATIVES/README_AWESOME.md`: generated awesome-list view and category contents.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/README_ALTERNATIVES/README_CLASSIC.md`: generated classic headings and rendered category coverage.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/THE_RESOURCES_TABLE.csv`: parsed for counts, categories, active/stale flags, and theme samples.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/templates/categories.yaml`: category taxonomy and subcategory definitions.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/templates/resource-overrides.yaml`: validation skip and field lock model.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/acc-config.yaml`: root style and generated view config, checked indirectly through docs/generator.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/pyproject.toml`: package metadata, dependencies, lint, type, test, and coverage config.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/Makefile`: maintainer command surface and CI/test/generation targets.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/docs/HOW_IT_WORKS.md`: submission flow and generated view explanation.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/docs/README-GENERATION.md`: multi-list architecture and generator design.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/docs/TESTING.md`: verification commands and regeneration test notes.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/docs/CONTRIBUTING.md`: submission, safety, and evidence requirements.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/docs/SECURITY.md`: security scope and third-party resource caveats.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/README.md`: statement that resource snapshots are historical and may be archived.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.claude/commands/evaluate-repository.md`: static curation review prompt.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/ISSUE_TEMPLATE/recommend-resource.yml`: issue-form schema and safety/validation questions.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/submission-enforcement-v2.yml`: cooldown, PR enforcement, model classifier, and repo-age checks.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/validate-new-issue.yml`: issue parse/validation workflow.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/handle-resource-submission-commands.yml`: maintainer slash-command handling.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/ci.yml`: CI entrypoint.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/check-repo-health.yml`: scheduled active repo health check.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/validate-links.yml`: scheduled link validation and issue reporting.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/update-github-release-data.yml`: scheduled release metadata update.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/update-repo-ticker.yml`: scheduled ticker data update.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.github/workflows/notify-on-merge.yml`: badge notification workflow.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/README.md`: script architecture and workflow summary.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/readme/generate_readme.py`: generator orchestration.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/readme/generators/base.py`: CSV loading, overrides, template replacement, backups, and output writing.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/readme/generators/flat.py`: flat category/sort views and `Output Styles` flat filter.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/categories/category_utils.py`: category manager.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/resources/parse_issue_form.py`: issue parsing and validation.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/resources/create_resource_pr.py`: automated resource PR creation.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/resources/resource_utils.py`: CSV append and PR content helpers.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/resources/detect_informal_submission.py`: informal submission heuristic.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/validation/validate_single_resource.py`: single URL/resource validation.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/validation/validate_links.py`: inspected by symbols for GitHub metadata, stale flags, overrides, and release logic.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/maintenance/check_repo_health.py`: active GitHub repo health check.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/ticker/fetch_repo_ticker_data.py`: GitHub search/ticker source.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/slash-commands/context-prime/context-prime.md`: context loading command sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/slash-commands/create-prp/create-prp.md`: PRP/context packet command sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/slash-commands/pr-review/pr-review.md`: multi-perspective PR review command sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/slash-commands/testing_plan_integration/testing_plan_integration.md`: test-planning command sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/workflows-knowledge-guides/Design-Review-Workflow/design-review-agent.md`: design-review subagent with Playwright MCP tool surface.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/workflows-knowledge-guides/Design-Review-Workflow/design-review-slash-command.md`: command invoking design-review workflow.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/official-documentation/Claude-Code-GitHub-Actions/pr-review-comprehensive.yml`: Claude Code GitHub Action PR review sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/claude.md-files/claude-code-mcp-enhanced/CLAUDE.md`: MCP-enhanced CLAUDE.md sample.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/claude.md-files/Basic-Memory/CLAUDE.md`: MCP memory/project guide sample.
- `https://api.github.com/repos/hesreallyhim/awesome-claude-code`: stars, default branch, pushed date, and description snapshot.

## Excluded Paths

- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/.git/`: VCS internals; only HEAD commit and latest commit metadata were needed.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/assets/`: generated/static badges, headers, ticker SVGs, screenshots, and social images; relevant as generated output but not as workflow logic.
- Most `/tmp/myagents-research/hesreallyhim-awesome-claude-code/README_ALTERNATIVES/README_FLAT_*.md`: generated permutations; sampled representative generated README views and reviewed generator logic instead of every generated file.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/tests/fixtures/github-html/`: generated/fixture HTML for anchor tests, not source workflow behavior.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/tests/fixtures/informal_issues/`: test fixtures for issue detection; behavior reviewed through the detector and tests list.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/scripts/archive/`: archived/deprecated scripts, excluded from coverage and not part of current pipeline.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/data/repo-ticker*.csv`: generated ticker snapshots; ticker fetcher reviewed instead.
- Unlisted files under `/tmp/myagents-research/hesreallyhim-awesome-claude-code/resources/**`: sampled by category only. The directory is historical and incomplete, so deep review should target upstream repos rather than these snapshots.
- `/tmp/myagents-research/hesreallyhim-awesome-claude-code/LICENSE`, `.gitignore`, `.pre-commit-config.yaml`, `.python-version`: project metadata; checked only for context where needed.
