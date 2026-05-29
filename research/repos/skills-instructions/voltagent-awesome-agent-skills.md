# VoltAgent/awesome-agent-skills

- URL: https://github.com/VoltAgent/awesome-agent-skills
- Category: skills-instructions
- Stars snapshot: 23.5k (GitHub web UI, captured 2026-05-29; index row records 23,502 via GitHub REST API, captured 2026-05-29)
- Reviewed commit: f4a2d027b25b5526f85ab3567215d926f332a4ae
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Broad, current, highly useful catalog of agent skills across official teams and community projects. Best value is taxonomy, discovery, compatibility-path conventions, quality-bar language, and candidate sourcing for deeper reviews. It is not a registry implementation or installable skill corpus, and its biggest gaps are weak machine-readable metadata, no automated link/schema validation, no per-skill provenance snapshot, and curation criteria that remain mostly social rather than executable.

## Why It Matters

`awesome-agent-skills` is directly relevant to Agentic Coding Lab because it maps the fast-moving Agent Skills ecosystem in one place. It covers official and community skills for Claude Code, Codex, Antigravity, Gemini CLI, Cursor, GitHub Copilot, OpenCode, Windsurf, and other skill-compatible agents. The repo is valuable less as code and more as ecosystem intelligence: which organizations publish skills, which task domains are common, how skill names are normalized, which skills point to hosted catalogs, and what compatibility paths are emerging across clients.

The useful research signal is also temporal. The reviewed checkout has recent PR-driven updates, a `Skills-1424+` README badge, 359 GitHub commits in the web UI, and a contribution flow that favors real usage over brand-new submissions. That makes it a good watchlist for finding mature skills before deciding which ones deserve deeper technical review.

## What It Is

The repository is a curated Markdown index. In the reviewed checkout it contains only three tracked content files: `README.md`, `CONTRIBUTING.md`, and `LICENSE`. It does not vendor the listed skills, expose a JSON registry, publish package metadata, implement a loader, or include install scripts. Each skill remains in its original repository or on `officialskills.sh`.

The root README organizes more than a thousand skill entries into official team sections and community sections. A simple bullet count in the reviewed README found 1,114 Markdown list entries matching the main `- **[name](url)** - description` pattern, while the README badge claims `1424+` skills. The difference is expected because some sections describe collections or nested skills in prose, but it also shows why this README should be treated as a human catalog rather than a normalized database.

The catalog heavily uses `officialskills.sh` links for official or platform-hosted skills. A line count found 587 README lines containing `officialskills.sh`; the remainder are mostly direct GitHub links or occasional external pages. The official sections include Anthropic, VoltAgent, Angular, Composio, Supabase, Google Gemini, Stripe, HashiCorp, Vercel, Cloudflare, Netlify, Google Workspace, Hugging Face, Trail of Bits, Sentry, Microsoft, OpenAI, Figma, Redis, NVIDIA, Google Cloud, and many others. Community sections include Vector Databases, Marketing, Productivity and Collaboration, Development and Testing, Context Engineering, Specialized Domains, and n8n Automation.

## Research Themes

- Token efficiency: Moderate as a catalog pattern, not as runtime behavior. The repo points to compact skill descriptions, recommends top-level metadata under about 100 tokens, and calls for loading large resources on demand. It does not enforce token budgets or provide retrieval indexes beyond the README.
- Context control: Strong as guidance. The "Skill Quality Standards" section explicitly recommends progressive disclosure, concise metadata, skill bodies below 500 lines, and separate resources. The repo itself is one large README, so downstream systems need their own generated index or retrieval layer.
- Sub-agent / multi-agent: Conditional. The catalog includes subagent and orchestration-related skills, but the repo does not implement subagents. It is useful for finding role, delegation, and multi-agent workflow examples in linked repositories.
- Domain-specific workflow: Very strong as coverage. The sections span application frameworks, cloud providers, databases, observability, testing, security, design, product, marketing, data/AI, context engineering, automation, and specialized domains.
- Error prevention: Moderate. The catalog includes testing, security, eval, audit, code-review, debugger, prompt-security, and quality-standard skills, and it warns about prompt injection, tool poisoning, malware payloads, and unsafe data handling. There is no local validation harness for the catalog itself.
- Self-learning / memory: Conditional. The catalog lists memory and context-engineering skills, but it does not store run history, telemetry, ratings, install counts, or adaptive recommendations.
- Popular skills: No per-skill usage data is available locally. High-signal entries for Agentic Coding Lab include `anthropics/skill-creator`, `anthropics/mcp-builder`, `openai/openai-docs`, `openai/playwright`, `openai/security-threat-model`, `mattpocock/skills`, `obra/superpowers`, `NeoLabHQ/sdd`, `NeoLabHQ/sadd`, `hamelsmu/eval-audit`, `hamelsmu/error-analysis`, `muratcankoylan/context-*`, `awrshift/claude-memory-kit`, `hqhq1025/skill-optimizer`, and `prompt-security/clawsec`.

## Core Execution Path

The execution path is editorial rather than programmatic:

1. A maintainer or contributor adds a Markdown bullet to `README.md`.
2. The entry uses the `author/skill-name` display convention, links to the skill source or hosted page, and includes a short description.
3. The entry is placed under an official team section, an existing community subcategory, or "Other" if no category fits.
4. Users browse the README, follow a link to the original skill, then install or copy it according to that source project's instructions.
5. Users can use the repo's assistant path table to decide where skills should live for their client, such as `.agents/skills/` for Codex project skills or `~/.agents/skills/` for Codex global skills.

The contribution path is similarly simple. `CONTRIBUTING.md` requires a public repository with a working skill, README or `SKILL.md` documentation, an author/org prefix, a short description of 10 words or fewer, real community usage, and a PR title shaped like `Add skill: author/skill-name`. It also says this repository curates links only and that each skill lives in its own repo.

There is no local code path that downloads, installs, scans, executes, or validates listed skills.

## Architecture

The checked-in architecture is intentionally flat:

- `README.md`: human-facing catalog, table of contents, official and community sections, security notice, assistant skill-path matrix, quality criteria, contributing summary, contributor image, license note, and link reference definitions.
- `CONTRIBUTING.md`: entry format, placement rules, acceptance requirements, PR title convention, and curation caveats.
- `LICENSE`: MIT license for the repository contents.
- `.gitignore`: present in the remote file list, but no substantive runtime behavior was found in tracked content review.

The README acts as all of these at once: landing page, taxonomy, source list, compatibility reference, security disclaimer, and lightweight quality guide. That keeps maintenance simple but creates predictable scaling limits. There is no separate machine-readable source of truth for entries, categories, origin type, claimed compatibility, last-checked date, source commit, license, tool requirements, or security-review state.

## Design Choices

The strongest design choice is the split between official team sections and community skill categories. Official sections are organized by publisher, which helps provenance and trust assessment. Community sections are organized by use case, which helps discovery when the user knows the task but not the author.

The second important choice is naming by `author/skill-name`. That mirrors package names and GitHub owners, makes provenance visible in the label, and prevents generic names like `testing` or `docs` from becoming ambiguous.

The third choice is cross-agent path normalization. The README includes project and global skill directories for Antigravity, Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode, and Windsurf. This is one of the most directly reusable pieces for Agentic Coding Lab because it turns scattered client conventions into a compatibility matrix.

The fourth choice is public risk disclosure. The security notice says skills are curated, not audited; warns that linked skills can change after being added; tells users to review sources before installing; and names risks such as prompt injections, tool poisoning, malware payloads, and unsafe data handling. It recommends Snyk's skill scanner and Agent Trust Hub, but does not run those tools locally.

The fifth choice is lightweight quality criteria. The README says descriptions should be third-person, explain what the skill does and when to use it, use specific trigger keywords, keep top-level metadata small, keep bodies below 500 lines, load resources on demand, avoid absolute paths, and request only scoped tools. These criteria are concise and useful, but they are not tied to a validator.

The sixth choice is curation by social proof. The contribution requirements reject very new skills and ask for real community usage. This is practical for an awesome list, but it leaves evidence undefined: stars, downloads, org provenance, issue activity, production use, citations, or maintainer attestation are not normalized.

## Strengths

The catalog gives a broad taxonomy of where agent skills are already useful. It reveals common clusters: provider SDK guidance, framework best practices, cloud operations, databases, browser automation, document workflows, design systems, QA/security, evals, context engineering, memory, product/marketing, and domain-specific specialist workflows.

The official/team sections are excellent candidate sources. They surface skills from organizations whose docs and APIs are likely to evolve, including OpenAI, Anthropic, Microsoft, Google, Cloudflare, Vercel, Firebase, Flutter, MongoDB, Apollo, Auth0, Brave, Datadog, NVIDIA, and others.

The assistant path table is high leverage. It gives project and global install locations across clients, including Codex's `.agents/skills/` and `~/.agents/skills/`, which is directly useful when designing cross-agent packaging or migration tooling.

The quality criteria are compact enough to become checklist rules. Description semantics, progressive disclosure, no absolute paths, and scoped tools are good baseline checks for any skill authoring workflow.

The security warning is appropriately cautious for a link catalog. It avoids implying that curation equals audit, and it explicitly calls out skill-specific attack surfaces.

The contribution rules keep entries readable. The 10-word description limit and author/org prefix reduce README bloat and force contributors to make labels scannable.

The recent commit history shows active community maintenance. The last reviewed commit updated sponsorship/ecosystem sections, and the preceding commits merged PRs adding skills such as `indranilbanerjee/digital-marketing-pro`, `santifer/career-ops`, and `dembrandt/dembrandt-skills`.

## Weaknesses

There is no machine-readable catalog. Every entry, category, description, and URL lives in one README, so downstream systems need to parse Markdown and handle inconsistent formatting, prose sections, collection entries, and hosted links.

There is no local verification. I did not find checks for broken links, duplicate labels, category drift, dead `officialskills.sh` pages, direct GitHub paths that no longer contain `SKILL.md`, description length violations, or compatibility claims.

There is no reviewed-source snapshot for listed skills. The catalog links to moving branches and hosted pages without recording source commits, last validation date, license, security-review status, or whether the linked skill has changed since inclusion.

The install story is delegated. The path table tells users where skills can live, but the repo does not provide per-entry install commands, package manifests, checksums, dependency declarations, or safe copy/update flows.

The "official" label is not backed by checked evidence in the repo. Many entries likely are official, but the catalog does not store proof such as verified org ownership, upstream announcement URL, or maintainer attestation.

The quality standards are prose-only. They are good guidance, but there is no schema, linter, PR check, or CI workflow to enforce description shape, metadata size, absolute-path bans, scoped-tool requirements, or resource layout.

The security posture is advisory. The README recommends scanners and manual review, but the repo does not publish scan results, threat model summaries, risky-permission flags, or trust levels.

The catalog mixes single skills, skill collections, hosted pages, direct `SKILL.md` files, repos, and domain systems. That is fine for browsing, but it makes automated selection and install harder without an explicit `entry_type`.

## Ideas To Steal

Use the official/team plus community/use-case split for Agentic Coding Lab's own skill index. It supports both provenance-first and task-first discovery.

Adopt the `author/skill-name` label convention and require a short description that names both capability and trigger condition.

Steal the cross-agent path matrix and extend it with install semantics: project path, global path, manifest format, trigger metadata fields, tool-permission field, supported assets, and known host limitations.

Turn the quality criteria into executable checks: third-person description, "what and when" wording, keyword specificity, top-level metadata budget, body length budget, no absolute paths, scoped tools, required source URL, and optional references/assets split.

Add provenance fields that this repo lacks: source URL, source commit or release, captured date, license, owner type, origin proof, last link check, last security scan, and whether the entry points at a single skill or a collection.

Use this repo as a candidate harvester. Prioritize deeper reviews for entries that combine official publisher provenance, explicit error-prevention workflows, cross-agent compatibility, deterministic checks, or context/memory mechanisms.

Copy the security disclaimer pattern, but attach a risk score. Useful fields would include executes shell, requests broad tools, touches credentials, calls external APIs, uses MCP, writes files, changes infrastructure, or handles high-stakes domains.

Create a small generated index from README-like Markdown rather than asking agents to read the full catalog. The generated index should support filtering by category, owner, host client, domain, risk, and review status.

## Do Not Copy

Do not copy the one-large-README architecture as the only source of truth. It is easy to maintain manually, but weak for validation, provenance, and automated retrieval.

Do not equate "curated" with "safe". The repo itself says listed skills are not audited and may change after inclusion.

Do not import linked skills without pinning a commit or release. Moving branch links can silently change instructions, scripts, dependencies, or permissions.

Do not accept "official" as a free-form heading in a research index. Require evidence that the skill came from the named team or an approved publishing channel.

Do not rely on a 10-word description as enough metadata for agent selection. It is useful for browsing, but an agent needs trigger conditions, exclusions, dependencies, tool requirements, and expected outputs.

Do not let sponsored or ecosystem-tool sections blur research scoring. The README includes an ecosystem/sponsor slot; Agentic Coding Lab should separate discovery value from promotional placement.

Do not use the catalog as a direct install source. Treat it as a pointer list until a separate installer can verify URLs, commits, checksums, manifests, and tool permissions.

## Fit For Agentic Coding Lab

Fit is in-scope. The repository is not an agent application, but it is a strong skills-instructions candidate because it captures ecosystem taxonomy, naming conventions, source provenance cues, cross-agent compatibility paths, quality-bar language, security caveats, and many candidate links for deeper review.

The best local adaptation is not to mirror the README manually. Agentic Coding Lab should create a normalized skill-candidate table seeded from this catalog, then enrich each row with pinned source commit, license, owner proof, host compatibility, install path, trigger metadata, dependency/tool declarations, security scan status, and review verdict.

For active agent systems, this repo is most useful as a discovery layer and taxonomy source. For production skill use, each linked skill should be reviewed at source, pinned, linted, and tested independently.

## Reviewed Paths

- `/tmp/myagents-research/voltagent-awesome-agent-skills/README.md`
- `/tmp/myagents-research/voltagent-awesome-agent-skills/CONTRIBUTING.md`
- `/tmp/myagents-research/voltagent-awesome-agent-skills/LICENSE`
- `https://github.com/VoltAgent/awesome-agent-skills`
- `research/index.md` row for `VoltAgent/awesome-agent-skills`
- `research/templates/repo-note.md`

## Excluded Paths

- `/tmp/myagents-research/voltagent-awesome-agent-skills/.git/`: VCS internals; commit SHA and recent history were captured separately.
- Remote README badge images, contributor image, VoltAgent logo/banner images, and sponsor badges: UI and marketing assets, not skill behavior.
- External repositories and hosted pages linked from the README, including `officialskills.sh` entries: reviewed only as catalog targets and examples of provenance/hosting conventions; their contents require separate source reviews.
- Assistant official-doc links in the path matrix: treated as compatibility references, not deeply reviewed as current client documentation.
- Snyk Skill Security Scanner and Agent Trust Hub: noted as recommended tools but not executed against the catalog.
- Open GitHub issues and PR discussion threads: recent merge history and current web UI counts were checked, but individual review conversations were outside the owned note scope.
- `research/index.md`: candidate row existence was confirmed, but the file was not edited per user instruction.
