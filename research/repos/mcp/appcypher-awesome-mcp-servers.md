# appcypher/awesome-mcp-servers

- URL: https://github.com/appcypher/awesome-mcp-servers
- Category: mcp
- Stars snapshot: 5,529 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 280218b4bba97a49facf929f8012dec5e30384b6
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful human-readable MCP discovery seed with a broad taxonomy and explicit safety warning, but weak as an agent-ready registry because entries lack structured metadata, install recipes, trust provenance, and automated verification.

## Why It Matters

This repo is a compact MCP server catalog that shows how a maintainer grouped a fast-growing server ecosystem for human browsing. For Agentic Coding Lab, its value is taxonomy and candidate discovery: it exposes domains agents commonly want to connect to, including file systems, databases, search, version control, development tools, monitoring, security, workflow automation, and aggregators.

It is less useful as an operational source of truth. A coding agent cannot safely install or select servers from this list without separately checking each target repository for package source, transport mode, permissions, maintenance state, security model, and setup commands.

## What It Is

`awesome-mcp-servers` is a CC0 Markdown-only awesome list of Model Context Protocol servers. At the reviewed commit it contains three tracked files: `README.md`, `CONTRIBUTING.md`, and `CODE_OF_CONDUCT.md`.

The README is the corpus. It has a security warning, a table of supported clients, a server taxonomy, per-category descriptions, server link bullets, a legend for official and alternate implementations, and a small tools/utilities section. The reviewed README has 31 server categories, 216 server entries, 14 supported clients, and 5 server-manager utility entries.

## Research Themes

- Token efficiency: Good for quick candidate discovery because each entry is one concise line, but poor for agent ingestion because HTML icons, badges, duplicated phrasing, and prose-only metadata add parsing noise without machine-readable fields.
- Context control: Category sections provide useful context boundaries. An agent can read only `Development Tools`, `Search & Web`, or `Databases` instead of the whole list, but anchors and free-form Markdown make reliable slicing brittle.
- Sub-agent / multi-agent: No direct sub-agent design. It indirectly supports multi-agent systems by surfacing MCP servers for version control, databases, observability, browser automation, research, and enterprise app aggregators.
- Domain-specific workflow: Strong domain coverage. The taxonomy maps MCP servers by workflow area rather than implementation language, which is the right first filter for coding agents choosing tools.
- Error prevention: Top-level security warning is valuable and unusually explicit for an awesome list. Error prevention stops there: no per-entry permission class, destructive-operation flag, sandbox requirement, credential scope, or verification result.
- Self-learning / memory: No memory system. The list can seed a local memory or registry of reviewed MCP servers after each candidate is independently validated.
- Popular skills: Not a skills pack. The most relevant reusable "skills" are discovery patterns: categorize by task domain, mark official sources, distinguish alternate implementations, and include utilities for installation/management.

## Core Execution Path

Maintenance path is manual:

1. Contributor proposes a README change.
2. Contribution guidelines ask them to search for duplicates, submit one suggestion per pull request, place additions at the bottom of the relevant category, keep descriptions succinct, check spelling/grammar, trim trailing whitespace, use useful PR/commit titles, and keep lists alphabetized.
3. Maintainer reviews and merges or directly edits README.
4. Users browse the README by client table, category table of contents, category heading, or search.
5. Users follow external links to each server project for actual installation and usage.

There is no schema, parser, catalog file, package manifest, test suite, CI workflow, link checker, awesome-list linter, duplicate detector, or generated index in the repo.

## Architecture

The repository is a single-source Markdown catalog:

- `README.md` is both documentation and database. It contains security guidance, supported clients, server categories, server entries, utility entries, and license text.
- Server categories are `##` headings with HTML anchors and short blockquote descriptions.
- Server records are bullets with an HTML image or emoji icon, display name, URL, optional `<sup>` markers, and a prose description.
- Legend markers distinguish "official protocol implementation" with a star marker and alternate implementations with numeric markers such as `1`, `2`, and `3`.
- `CONTRIBUTING.md` defines light editorial rules but no executable validation.
- `CODE_OF_CONDUCT.md` defines community behavior and maintainer enforcement contact.

Largest server categories by entry count are `Search & Web` with 23 entries, `Development Tools` with 20, `Databases` with 19, `Note Taking` and `AI Services` with 10 each, and `Finance` and `Security` with 9 each.

## Design Choices

- Human-first taxonomy: broad workflow categories make browsing easy for people and map well to agent task intents.
- Safety-first intro: the README leads with a warning that MCP servers can execute arbitrary code, access system resources, leak data, and be abused through prompt injection.
- Client orientation: supported-client table frames MCP as an ecosystem used by Claude Desktop, Cursor, VS Code, Goose, Continue, Zed, LibreChat, and others.
- Trust shorthand: a star marker marks official implementations, but the repo does not record who verified official status, when it was checked, or what "official" means for vendor-hosted APIs versus protocol-maintained servers.
- Alternate implementation markers: numeric superscripts help show multiple servers for the same service, but they do not encode recommendation, maturity, language, transport, or security posture.
- External visual identity: entries use remote favicons and image URLs for scanability, which makes the source visually noisy and creates fragile Markdown.
- Manual editorial control: contribution rules prefer duplicate avoidance, concise descriptions, one suggestion per PR, category placement, spelling, grammar, and alphabetic ordering.

## Strengths

- Broad discovery coverage across coding-agent-relevant domains, especially development tools, version control, search/web, databases, monitoring, security, and sandboxing.
- Security warning is direct and names concrete risks: system access, code execution, prompt injection, and data exposure.
- Category descriptions explain expected capability shape, not just product names.
- Supported-client table helps researchers understand which agent hosts had visible MCP UX at review time.
- Utility section points to manager-style projects such as `mcp-get`, `yamcp`, and `ToolHive`, which are more relevant to install UX than raw server links.
- Small repo surface makes provenance easy to audit: three tracked Markdown files and no hidden build pipeline.

## Weaknesses

- No machine-readable catalog. Entries cannot be reliably consumed without custom Markdown/HTML parsing and manual cleanup.
- No install UX per server. Most entries omit package name, transport, command, required environment variables, Docker support, operating system constraints, or client config snippets.
- No verification. The repo does not check links, parse Markdown, validate anchors, confirm MCP compatibility, run servers, inspect tools, or record last-tested dates.
- Metadata quality is inconsistent. Some entries have malformed HTML or links, external HTTP assets, typos, mixed bolding, inconsistent icon markup, and descriptions with marketing claims rather than operational facts.
- Trust model is too thin for agents. The star marker is useful but insufficient without signed releases, package provenance, maintainer identity, dependency risk, permission class, license, and source-vs-hosted distinction.
- Security data is global, not per entry. High-risk classes such as file system, shell, browser, cloud, finance, identity, and data access are not labeled with least-privilege guidance.
- Maintenance process is mostly social. The GitHub API reports issues disabled and many open PR-like items, while the repo itself has no review checklist beyond the contribution guide.
- The README includes a "Helpful Tools & Utilities" link target that does not match the actual `Tools & Utilities` heading, which shows anchor drift risk.

## Ideas To Steal

- Keep human taxonomy, but back it with structured records: category, service, repo URL, package coordinates, transport, install command, auth method, permission class, destructive capability, sandbox requirement, last verified commit, and license.
- Preserve concise one-line descriptions, then add agent-only metadata in adjacent YAML/JSON generated from validated source records.
- Use category descriptions as routing hints for coding agents: "version control", "database", "browser automation", "test management", "observability", and "sandbox execution" map cleanly to tool-selection policies.
- Convert the star marker into a provenance-backed trust field with values such as `protocol-official`, `vendor-official`, `community`, and `unknown`, plus evidence URL and verification date.
- Add per-entry risk labels: local file access, shell execution, browser control, network egress, credentialed SaaS, write-capable API, financial operation, identity/admin operation.
- Add install UX fields for `npx`, `uvx`, Docker, binary, hosted URL, and client config snippets so a coding agent can produce safe setup plans.
- Add verification pipeline: Markdown lint, link check, anchor check, duplicate detector, schema validation, server start smoke test where feasible, and MCP tool-list introspection.
- Include "coding-agent applicability" scoring so servers useful for repo work, test repair, code search, PR review, and debugging surface ahead of general business integrations.

## Do Not Copy

- Do not use a single free-form README as the canonical registry if agents must consume it.
- Do not rely on icons, product names, or short descriptions as trust metadata.
- Do not mark official implementations without recording evidence and verification time.
- Do not list shell, filesystem, browser, identity, database, finance, or cloud-control servers without per-entry risk labels.
- Do not make install discovery require opening each upstream repository.
- Do not accept manual curation without link, anchor, duplicate, spelling, and schema checks.
- Do not include remote visual assets in the canonical data layer; keep UI decoration generated from clean metadata.

## Fit For Agentic Coding Lab

Fit is in-scope as an MCP discovery and taxonomy reference. It should be treated as a seed list, not as a trusted registry. The most reusable part is the domain taxonomy because it mirrors the capability areas coding agents need: filesystem, sandboxing, version control, cloud storage, databases, communication, monitoring, search/web, cloud platforms, workflow automation, system automation, research/data, development tools, visualization, security, and aggregators.

For Agentic Coding Lab, the repo suggests a two-layer approach: a readable awesome-style overview for humans and a validated metadata registry for agents. Any candidate imported from this repo should go through independent review of upstream code, installation path, permissions, secrets, license, maintenance, and smoke-test behavior before being recommended to a coding agent.

## Reviewed Paths

- `README.md`: Primary corpus, including security warning, supported clients, category taxonomy, server entries, markers, tools/utilities, and license notice.
- `CONTRIBUTING.md`: Manual maintenance and submission rules.
- `CODE_OF_CONDUCT.md`: Governance and maintainer enforcement context.
- Git history: Recent commit cadence and merge/direct-edit style, including reviewed HEAD `280218b4bba97a49facf929f8012dec5e30384b6`.
- GitHub REST metadata: Star count, fork count, timestamps, topics, default branch, issue/PR availability, and repository visibility captured 2026-05-11.

## Excluded Paths

- `.git/`: VCS storage only; used only through `git log`, `git rev-parse`, and tracked-file inspection.
- Remote icon/image URLs embedded in `README.md`: UI decoration and external assets; not fetched because they do not affect MCP taxonomy, metadata quality, trust, install UX, or verification semantics.
- Generated, vendored, binary, schema, scripts, docs, tests, CI, and UI-only paths: none are tracked in the reviewed repository. Their absence is part of the finding: maintenance and validation are manual.
