# kepano/obsidian-skills

- URL: https://github.com/kepano/obsidian-skills
- Category: domain-specific-coding
- Stars snapshot: 32,184 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: ac9398734fe719565809f7a6048b05c36b1ca38f
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Compact, high-signal example of domain-specific skill packaging for Obsidian. Best reusable patterns are one-surface-per-skill decomposition, trigger-rich `SKILL.md` frontmatter, progressive reference files, and embedded validation checklists. Main gaps are no executable schema validation, CI, fixture tests, version matrix, or permission model for vault and `obsidian eval` operations.

## Why It Matters

`obsidian-skills` shows how a domain owner can package application-specific knowledge for coding agents without building a runtime. Obsidian work has several narrow file and tool surfaces: Markdown extensions, Bases YAML, JSON Canvas, vault CLI operations, plugin/theme debugging, and web-page-to-note ingestion. The repository turns each surface into a separately discoverable skill with enough syntax, workflow, and pitfalls to guide an agent through real vault edits.

For Agentic Coding Lab, the value is reusable skill design. The repo is not a general coding harness, but it demonstrates how to make domain knowledge portable across Claude Code, Codex CLI, OpenCode, and Agent Skills-compatible tools while keeping heavyweight reference material behind explicit `references/` links.

## What It Is

The checkout is a small Agent Skills bundle for Obsidian. The root README documents installation through a plugin marketplace, `npx skills`, manual copy into Claude/Codex skill paths, and full-repo cloning for OpenCode. Hidden `.claude-plugin` metadata defines a marketplace plugin named `obsidian` at version `1.0.1`.

There are five checked-in skills:

- `obsidian-markdown`: Obsidian Flavored Markdown, wikilinks, embeds, callouts, properties, tags, comments, math, Mermaid, and footnotes.
- `obsidian-bases`: `.base` YAML files with filters, formulas, properties, views, summaries, quoting rules, and troubleshooting.
- `json-canvas`: `.canvas` JSON files following JSON Canvas 1.0 with nodes, edges, layout, IDs, colors, and validation checks.
- `obsidian-cli`: command-line interaction with a running Obsidian instance, including note operations and plugin/theme development.
- `defuddle`: using Defuddle CLI to extract clean Markdown from web pages and save tokens.

The repository has no application code, package manifest, local test suite, loader, MCP server, or CI workflow. Execution depends on the consuming agent's skill loader and on external tools such as Obsidian, the `obsidian` CLI, and Defuddle.

## Research Themes

- Token efficiency: Moderate. The `defuddle` skill explicitly reduces web-page clutter before ingestion, and the skill bundle keeps secondary details in references. The repo does not include retrieval ranking, context budgets, or measured token savings.
- Context control: Strong pattern. Frontmatter descriptions route usage by file type and user intent, while `references/` files keep less common callout, embed, property, function, and canvas examples out of the primary skill body until needed.
- Sub-agent / multi-agent: Weak. There is no subagent orchestration. The cross-tool angle is packaging compatibility across Claude Code, Codex CLI, OpenCode, and Agent Skills-compatible agents.
- Domain-specific workflow: Strong. Each skill maps Obsidian-specific formats and operations to concrete workflows: create notes, author Bases, edit canvases, operate vaults, debug plugins/themes, and convert web pages to Markdown.
- Error prevention: Moderate. The strongest checks are JSON Canvas ID/reference validation, Bases YAML quoting and duration pitfalls, Markdown render checks, and CLI development loops that reload, inspect errors, and visually inspect results. None are enforced by tests.
- Self-learning / memory: Limited. The bundle is reusable domain memory, but it does not store vault-specific feedback, learn from failed renders, or update rules from user corrections.
- Popular skills: No install or invocation telemetry was reviewed. Highest-value local skills for reuse are `obsidian-bases`, `json-canvas`, and `obsidian-cli` because they encode domain-specific syntax and verification beyond ordinary Markdown knowledge.

## Core Execution Path

The core path is skill-loader driven:

1. The agent runtime discovers `skills/<name>/SKILL.md` files and indexes their frontmatter `name` and `description`.
2. A user task mentions a relevant file type or Obsidian concept, such as `.base`, `.canvas`, wikilinks, vault search, plugin reload, or web-page extraction.
3. The matching skill gives a short workflow, syntax model, examples, and references to deeper files when needed.
4. The agent edits or creates vault artifacts: Markdown notes, Bases YAML, JSON Canvas files, or Obsidian CLI commands.
5. The skill asks for validation appropriate to the surface: parse JSON, validate YAML, check edge references, confirm formulas exist, open in Obsidian, inspect errors, or verify rendered output.
6. For plugin/theme work, `obsidian-cli` routes the loop through plugin reload, `dev:errors`, screenshot or DOM inspection, and console checks.

There is no local dispatcher, validator, or installer logic in the repo itself. The actual execution boundary is external: skill loading happens in the host agent; rendering and vault operations happen in Obsidian; web extraction happens in Defuddle.

## Architecture

The architecture is a static skill package:

- `README.md`: install methods, host compatibility, and a table of the five skills.
- `.claude-plugin/plugin.json`: plugin metadata for the `obsidian` package, including description, author, repository, license, and keywords.
- `.claude-plugin/marketplace.json`: marketplace wrapper pointing to the repo root as plugin source.
- `skills/obsidian-markdown/SKILL.md`: primary Markdown skill with references to `PROPERTIES.md`, `CALLOUTS.md`, and `EMBEDS.md`.
- `skills/obsidian-bases/SKILL.md`: primary Bases skill with `FUNCTIONS_REFERENCE.md` for formula and type functions.
- `skills/json-canvas/SKILL.md`: primary Canvas skill with `EXAMPLES.md` for complete canvas patterns.
- `skills/obsidian-cli/SKILL.md`: CLI and plugin/theme development skill.
- `skills/defuddle/SKILL.md`: token-saving web extraction skill.
- `LICENSE`: MIT license.

The checked-in content is about 1,824 lines across README, skills, and references. No `.github/`, scripts, package manager files, schemas, fixtures, snapshots, or generated artifacts are present in the reviewed commit.

## Design Choices

The main design choice is decomposition by Obsidian surface rather than by broad role. Markdown, Bases, Canvas, CLI, and Defuddle each get a distinct trigger and workflow, so an agent can load the smallest relevant domain contract.

The second strong choice is progressive disclosure. The main skill bodies include common syntax and common mistakes; less frequent enumerations live in references. This is especially useful for Bases functions and Canvas examples, where full examples can be token-heavy but are still useful when generating whole files.

The skills include validation as part of the workflow text. JSON Canvas gets the strongest structural checklist: unique IDs, valid edge references, required node fields, legal types, legal sides/endpoints, color formats, and parseable JSON. Bases covers YAML syntax, undefined formulas, duration math, and null guards. Obsidian CLI covers a development loop that observes errors and UI output after reload.

The repo chooses host portability over enforcement. A plain `SKILL.md` plus references can work across agents, but the package cannot itself prove that the agent followed the instructions or that generated vault artifacts render correctly.

Tool boundaries are explicit but lightweight. `obsidian-cli` says a running Obsidian instance is required, and `defuddle` tells agents to install or use a separate CLI. The skills do not define sandbox rules, confirmation prompts, or destructive-operation limits for vault writes or JavaScript evaluation.

## Strengths

The package is concise and domain-dense. It avoids a giant all-purpose Obsidian prompt and instead gives each format enough rules to be useful without making every Obsidian task load every reference.

The frontmatter descriptions are practical trigger contracts. They name file extensions, user terms, and task intents, which helps a skill-compatible agent select the right guidance automatically.

The references are well scoped. Markdown properties, callouts, and embeds are separate; Bases function reference is separate; Canvas complete examples are separate. This is a reusable pattern for any domain where common rules and exhaustive reference tables have different context value.

The skills focus on known failure modes. Bases warns about YAML quoting, duration values, undefined formulas, and missing null checks. Canvas warns about duplicate IDs, dangling edges, and escaped newlines. These are more useful than generic "be careful" instructions.

The CLI skill closes the loop for plugin and theme work better than static docs alone. Reloading, checking errors, inspecting screenshots/DOM, and reading console output are a concrete verification path for a GUI-heavy app.

The install documentation covers multiple host shapes: marketplace plugin, `npx skills`, manual Codex/Claude copies, and OpenCode full-repo discovery.

## Weaknesses

There is no executable validation harness. The repo tells agents to validate YAML/JSON and test in Obsidian, but it does not ship schemas, sample fixtures, scripts, CI, or golden files that can catch regressions in the skills themselves.

Version assumptions are implicit. Obsidian Bases, Obsidian CLI commands, Defuddle CLI flags, JSON Canvas, and host skill specifications can change, but the skills do not pin tested versions or record a compatibility matrix.

Safety boundaries are thin for vault operations. The CLI skill includes write commands, plugin reload, arbitrary JavaScript evaluation, screenshots, DOM inspection, and console access, but does not add confirmation rules, backup guidance, read-only defaults, or secret-handling policy.

Render verification depends on a live Obsidian app. That is realistic for the domain, but it limits headless automation and makes CI-style validation harder unless a separate harness is added.

The package has no examples of failed outputs and repairs. It lists pitfalls, but does not include before/after fixtures showing malformed `.base`, `.canvas`, or Markdown artifacts and the expected fix.

The Defuddle skill optimizes token intake, but it does not specify content trust boundaries, citation retention, source URL metadata, or handling for pages where extraction loses important structure.

## Ideas To Steal

Package domain skills by artifact surface: one skill for each file format, command surface, or ingestion tool rather than one broad domain blob.

Use frontmatter descriptions as routing metadata. Include file extensions, task verbs, and domain terms so skill selection can happen before the agent reads the full body.

Keep main skill bodies short and put exhaustive references under `references/`. This gives agents common rules immediately while preserving deeper examples for demand-loaded context.

Make validation checklists artifact-specific. JSON needs ID/reference integrity; YAML needs parse and quoting checks; CLI workflows need error inspection and visual checks; Markdown needs render checks.

Include "known pitfall" sections near the syntax they affect. Duration math and escaped newline warnings are good examples because they prevent specific, recurring agent mistakes.

Define tool boundaries in the skill: whether a local app must be running, when to prefer a CLI over web fetch, and what external docs or command help are authoritative.

Ship marketplace metadata beside the skills. A small `plugin.json` plus marketplace manifest makes the package easier to install without changing the skill format itself.

## Do Not Copy

Do not rely on prompt text as the only safety layer for write-capable vault operations. Add permission, backup, diff, or dry-run conventions for destructive edits.

Do not expose arbitrary `obsidian eval` workflows without a policy. App-context JavaScript is powerful and should be gated by user intent, scoped commands, and observable verification.

Do not treat external app rendering as a substitute for local syntax checks. Add machine validation where possible before asking a user to open Obsidian.

Do not copy long domain reference tables into every task context. Preserve the progressive reference pattern and retrieve only the section needed for the current artifact.

Do not omit version provenance for fast-moving domain tools. A reusable lab skill should record tested Obsidian, CLI, JSON Canvas, and Defuddle versions or update cadence.

Do not use web extraction as a black box for research notes without retaining source URL, retrieval date, and enough provenance to audit what was summarized.

## Fit For Agentic Coding Lab

Fit is conditional but useful. `obsidian-skills` is not primarily a software-coding workflow repo; most skills target knowledge-base authoring. It belongs in `domain-specific-coding` because it packages exact domain syntax, file formats, command workflows, and GUI verification loops that a coding agent can use when modifying Obsidian vaults or developing Obsidian plugins/themes.

The best adoption path is pattern extraction, not direct dependency. Agentic Coding Lab should borrow the decomposition model, reference layout, trigger metadata, and artifact-specific validation checklists. For production use, add executable validators, fixtures, version tags, and stronger permission boundaries around tool calls.

## Reviewed Paths

- `/tmp/myagents-research/kepano-obsidian-skills/README.md`: install methods, host compatibility, skill table, and OpenCode directory requirement.
- `/tmp/myagents-research/kepano-obsidian-skills/.claude-plugin/plugin.json`: plugin identity, version, description, keywords, repository, and license metadata.
- `/tmp/myagents-research/kepano-obsidian-skills/.claude-plugin/marketplace.json`: marketplace package wrapper.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-markdown/SKILL.md`: Obsidian Markdown workflow, wikilinks, embeds, callouts, frontmatter, tags, comments, math, Mermaid, and render verification.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-markdown/references/PROPERTIES.md`: frontmatter property types, default properties, and tag syntax.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-markdown/references/CALLOUTS.md`: callout variants, folding, nesting, supported types, aliases, and custom CSS hook.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-markdown/references/EMBEDS.md`: note, image, external image, audio, PDF, list, and search-result embeds.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-bases/SKILL.md`: `.base` YAML schema, filters, formulas, properties, views, summaries, examples, quoting rules, and troubleshooting.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-bases/references/FUNCTIONS_REFERENCE.md`: global, type-specific, date, duration, string, number, list, file, link, object, and regex functions.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/json-canvas/SKILL.md`: JSON Canvas structure, node and edge schema, ID generation, layout guidance, colors, validation checklist, and references.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/json-canvas/references/EXAMPLES.md`: complete canvas examples for text connections, project boards, research canvases, and flowcharts.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/obsidian-cli/SKILL.md`: vault targeting, file targeting, common commands, plugin/theme development loop, screenshots, DOM inspection, console checks, and app-context evaluation.
- `/tmp/myagents-research/kepano-obsidian-skills/skills/defuddle/SKILL.md`: Defuddle installation note, Markdown extraction preference, metadata extraction, output formats, and `.md` URL boundary.
- `/tmp/myagents-research/kepano-obsidian-skills/LICENSE`: MIT license and author attribution.
- Directory and structure review for all checked-in files at commit `ac9398734fe719565809f7a6048b05c36b1ca38f`, including hidden plugin metadata and absence of tests, package files, schemas, and CI workflows.

## Excluded Paths

- `/tmp/myagents-research/kepano-obsidian-skills/.git/`: VCS internals; commit SHA captured separately.
- GitHub issues, pull requests, discussions, and wiki pages: useful community context but outside the checked-in execution path requested for this repo note.
- External Obsidian, Agent Skills, JSON Canvas, Defuddle, Claude, Codex, and OpenCode documentation linked from README and skills: referenced for provenance but not deeply audited because the goal was the repository's packaging design.
- Live Obsidian app behavior and installed `obsidian` CLI commands: not executed; no local vault or running app was part of this review.
- Defuddle CLI execution against live pages: not run; the review focused on how the skill packages the workflow, not on extraction quality.
