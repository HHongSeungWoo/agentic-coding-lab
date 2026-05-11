# punkpeye/awesome-mcp-servers

- URL: https://github.com/punkpeye/awesome-mcp-servers
- Category: mcp
- Stars snapshot: 86,696 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 39b5e990fe94734de271a2b13ec1513811da9cdd
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Valuable as a broad MCP discovery corpus and taxonomy reference, but not directly reusable as an agent registry without a structured manifest, stronger normalization, and per-server safety metadata.

## Why It Matters

This is one of the most visible MCP server directories. At the reviewed commit it has 2,237 README list entries across 50 category headings, 867 Glama score badge references, and active contribution automation around PR quality labels and comments. For an agentic coding lab, it is useful less as executable infrastructure and more as a living map of what MCP server authors advertise: install commands, transport hints, local/cloud scope, language, security posture, memory/context features, and coding-agent tool surfaces.

## What It Is

The repo is a curated Markdown directory for Model Context Protocol servers. The canonical corpus is `README.md`, with localized `README-*.md` files, `CONTRIBUTING.md`, `LICENSE`, and one GitHub Actions workflow. There are no package manifests, source modules, schemas, generated catalog files, or runtime entrypoints in the repository.

The README links to the Glama web directory and says the web directory is synced with the repository. The repo itself stores entries as human-readable Markdown lines, usually in this shape: server link, optional Glama score badge, language/scope/OS tags encoded as emojis, and a free-form description. It also includes client, tutorial, community, framework, and tips sections.

## Research Themes

- Token efficiency: The repo has no runtime token-efficiency mechanism. The catalog highlights many token-oriented servers and gives coarse metadata that could support prefiltering before loading candidate docs, but Markdown lines are too verbose and irregular for direct low-token agent routing.
- Context control: Category headings, local/cloud markers, language markers, and descriptions provide a useful first-pass context filter. There is no structured capability model, permission model, or context budget field.
- Sub-agent / multi-agent: The corpus includes many multi-agent, delegation, council, and coding-agent orchestration servers, especially in Aggregators, Coding Agents, Developer Tools, Knowledge & Memory, Security, and Frameworks.
- Domain-specific workflow: Strong coverage. The taxonomy spans databases, code execution, developer tools, version control, file systems, search, security, workplace tools, finance, home automation, and many niche domains.
- Error prevention: The repo-level prevention is mostly contribution validation: duplicate detection, permitted tag checks, Glama badge nudges, GitHub primary-link checks, and owner/repo naming checks. The catalog also contains many listed servers for validation, sandboxing, policy, audit, prompt checks, and testing.
- Self-learning / memory: Knowledge & Memory is a large category with local and hosted memory, project-scoped search, session handoff, governed memory, context compaction, and persistent decision/history tools. The directory does not evaluate these claims itself.
- Popular skills: Discovery, server selection, registry mining, install UX design, safety triage, MCP marketplace taxonomy, metadata normalization, and seed lists for agent-tool evaluations.

## Core Execution Path

There is no MCP server or application execution path in this repo. The practical path is a contribution and directory-maintenance loop:

1. A contributor edits `README.md`, adding or changing one-server-per-line entries under a category.
2. `CONTRIBUTING.md` asks for repository link, concise functionality description, correct category, existing format/style, alphabetical order, accurate links, and one server per line.
3. For PRs, `.github/workflows/check-glama.yml` runs on `pull_request_target`. It checks out the base branch, reads the base README, obtains PR file patches from the GitHub API, and inspects added Markdown lines as strings.
4. The workflow labels PRs for Glama badge presence, valid emoji metadata, owner/repo name format, duplicates, and non-GitHub primary URLs. It also posts comments with remediation instructions.
5. On merged PRs, the workflow posts a welcome comment and points remote-server authors to the Glama connectors directory.

The action intentionally reads PR patches rather than executing contributor code. That is important because it uses `pull_request_target` with issue and PR write permissions.

## Architecture

The architecture is intentionally simple:

- `README.md`: canonical corpus and taxonomy. It contains intro links, legend, category table of contents, server entries, framework entries, MCP prompt tip, and star history.
- `CONTRIBUTING.md`: human contribution rules plus a bot fast-track convention: automated-agent PRs can add a marker to the PR title to opt in to a streamlined process.
- `.github/workflows/check-glama.yml`: maintenance automation for labels and PR comments. It embeds validation logic directly in `actions/github-script`.
- `README-fa-ir.md`, `README-ja.md`, `README-ko.md`, `README-pt_BR.md`, `README-th.md`, `README-zh.md`, `README-zh_TW.md`: localized copies that are much smaller than the English README and not a separate source of truth.
- `LICENSE`: MIT license.

There are no `docs/`, `scripts/`, `schema/`, `src/`, `tests/`, or generated-data directories at the reviewed commit.

## Design Choices

The key design choice is to optimize for GitHub-native contribution velocity over machine-readable registry quality. A Markdown README is easy for humans and automated PR authors to edit. It also keeps the public artifact inspectable without a build step.

Metadata is intentionally lightweight and visual: official implementation, language family, local/cloud/embedded scope, and OS support are encoded with a small emoji legend. This makes the list scannable, but it also limits reliable parsing and creates consistency drift.

Glama integration is used as a quality proxy. The workflow encourages new entries to include a Glama score badge and tells contributors that Glama checks need only prove that the server starts and responds to introspection requests. This gives the directory a weak verification hook without running arbitrary server code in this repo.

The validation workflow is pragmatic but partial. It catches duplicate GitHub URLs, missing Glama badges, unknown/missing metadata emojis, primary non-GitHub URLs in added entries, and bad name format. It does not enforce alphabetical order, description length, category validity, transport type, license, auth model, permission scope, package name, install command correctness, maintenance status, or safety claims.

## Strengths

- Very broad MCP coverage with high discovery value for coding-agent infrastructure, context tools, memory systems, security proxies, search tools, and developer workflows.
- Simple contribution surface lowers friction for humans and agents.
- Category taxonomy is useful as a seed ontology for an MCP registry.
- Glama badge convention creates an external quality signal and pushes authors toward introspection checks.
- PR automation handles common catalog hygiene problems without executing untrusted PR code.
- The catalog exposes real market language around MCP: zero-config, `npx`, `uvx`, remote endpoint, local-first, read-only, sandbox, policy, audit, tool count, and context savings.

## Weaknesses

- The canonical data model is free-form Markdown. Entries are not normalized enough for reliable agent-side install, ranking, filtering, or security gating.
- Verification is mostly indirect. Glama presence is encouraged, but not every entry has a badge, and the repo does not store score, check result, tool schema, or last verified timestamp.
- Security metadata is not first-class. Dangerous capabilities such as shell, file write, browser control, SSH, OS automation, and credential access appear in descriptions but are not machine-tagged.
- Install UX is inconsistent. Some entries include `npx`, `uvx`, `pip`, Docker, remote URLs, or Claude commands; many only link to repos.
- Existing corpus contains irregularities that validation will not necessarily clean up, including non-GitHub primary links and inconsistent formatting in older entries.
- Translations appear as duplicated Markdown snapshots, not generated artifacts with a visible source pipeline.
- There is no schema or catalog export for agents to consume without scraping.

## Ideas To Steal

- Use a human-friendly Markdown catalog as the public editing surface, but generate a structured registry from it with strict validation.
- Keep a compact category taxonomy for discovery: Aggregators, Coding Agents, Developer Tools, Knowledge & Memory, Search, Security, Version Control, File Systems, Code Execution, and Frameworks are especially relevant for coding agents.
- Require lightweight metadata at submission time: language, local/cloud, OS, transport, install method, auth required, data access class, write capability, network access, and verification source.
- Use an external introspection score or badge, but snapshot the score, timestamp, tool count, and failure reason into the registry.
- Copy the PR-comment pattern for contributor UX: automated labels plus precise remediation comments are better than silent rejection.
- Treat "awesome list" descriptions as weak signals for candidate discovery, then verify by cloning the target server and inspecting its own manifests, tests, and docs.

## Do Not Copy

- Do not use free-form Markdown lines as the authoritative registry for agent installation.
- Do not rely on emoji metadata where agent safety or automated filtering matters.
- Do not treat a badge URL as sufficient trust. Store signed or timestamped verification facts.
- Do not allow install commands in descriptions to become executable instructions without package, lock, provenance, and permission checks.
- Do not mix canonical corpus, translations, and web-directory synchronization without a visible generation/validation boundary.
- Do not let "one server per line" be the only granularity. Agents need server identity, package identity, transport, tools, scopes, secrets, and risk class as separate fields.

## Fit For Agentic Coding Lab

Fit is high for research discovery and taxonomy bootstrapping, medium for registry ingestion, and low for direct installation. It is a strong source of candidates in MCP areas that matter to coding agents: codebase indexing, shell/process control, browser and OS automation, CI/CD, memory, context compression, security policy, verification, and multi-agent orchestration.

For Agentic Coding Lab, the useful artifact would be a derived, verified subset: selected entries parsed from this corpus, enriched from each target repo, scored for coding-agent relevance, and classified by safety risk. The raw repo should be treated as a noisy upstream candidate feed.

## Reviewed Paths

- `README.md`: canonical directory, legend, category taxonomy, entry format, Glama web-directory link, framework list, prompt tip, and sampled entries from Aggregators, Code Execution, Coding Agents, Command Line, Developer Tools, Knowledge & Memory, Search & Data Extraction, Security, and Frameworks.
- `CONTRIBUTING.md`: contribution rules, format expectations, alphabetical ordering guidance, one-entry-per-line rule, accuracy expectations, and automated-agent PR opt-in marker.
- `.github/workflows/check-glama.yml`: PR maintenance automation, duplicate detection, Glama badge check, permitted emoji list, owner/repo name check, non-GitHub primary URL check, labels, and remediation comments.
- `LICENSE`: MIT licensing.
- `README-fa-ir.md`, `README-ja.md`, `README-ko.md`, `README-pt_BR.md`, `README-th.md`, `README-zh.md`, `README-zh_TW.md`: localized README copies reviewed for role and size, not as canonical data sources.
- Git metadata: `git ls-files`, latest README/workflow logs, and reviewed commit SHA used to verify repository shape and maintenance activity.
- GitHub REST repository metadata: stars, default branch, license, pushed/updated timestamps, forks, open issues, and repo URL.

## Excluded Paths

- `.git/`: cloned repository metadata, not part of review content.
- Localized README files beyond role/size checks: duplicate translated directory content; the English `README.md` is the canonical corpus for this review.
- Generated/vendored/binary paths: none present in the tracked tree at the reviewed commit.
- UI-only paths: none present in the tracked tree at the reviewed commit.
- Runtime source, scripts, schemas, tests, and docs directories: none present in the tracked tree at the reviewed commit; absence is itself a finding because validation and catalog structure live in Markdown plus one workflow.
