# nicobailon/visual-explainer

- URL: https://github.com/nicobailon/visual-explainer
- Category: domain-specific-coding
- Stars snapshot: 8,445 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 8f1d0e38ab0f265632a31d2fd032f7b730c98c15
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reusable pattern for visual explanation skills: artifact-first HTML output, domain-specific diagram/table/slide guidance, fact-sheet verification checkpoints, and cross-harness skill packaging. Best borrowed as a skill design pattern, not as a runtime: most guarantees are prompt-level, there is no automated visual validator, and sharing is tied to a Pi-compatible `vercel-deploy` dependency.

## Why It Matters

`visual-explainer` turns a common coding-agent weakness into a focused workflow: when an agent would normally emit ASCII diagrams, giant terminal tables, or prose-heavy reviews, it instead produces browser-readable HTML artifacts. That makes it relevant to Agentic Coding Lab's domain-specific-coding research because it shows how a narrow skill can reshape output medium, verification behavior, and context loading without building a full agent runtime.

The strongest idea is that visual explanation is treated as an artifact workflow, not just a styling preference. The skill specifies output location, browser viewing, Mermaid zoom/pan behavior, responsive navigation, table semantics, slide-deck mechanics, fact checking, and anti-patterns. For future lab skills, this is a useful example of converting domain taste and recurring failure modes into portable instructions plus templates.

## What It Is

The repository is an Agent Skill / plugin package for generating self-contained HTML pages and slide decks. It contains one canonical skill under `plugins/visual-explainer/`, eight command templates, four reference HTML templates, four reference documents, one sharing script, and lightweight harness guidance for Claude Code, Pi, Codex CLI, OpenCode/opencode, Cursor, and OpenClaw.

It is not an app server or diagramming library. The host agent reads the skill and command Markdown, gathers facts from the target project, writes a `.html` file to `~/.agent/diagrams/`, and opens it in a browser when the environment permits. Mermaid, Chart.js, anime.js, Google Fonts, and optional `surf-cli` image generation are documented as browser/CDN helpers rather than vendored runtime dependencies.

## Research Themes

- Token efficiency: Strong pattern, light implementation. The skill keeps heavy CSS, Mermaid, slide, and library details in `references/` and `templates/` so the agent can load only the relevant material. Individual reference files are large enough that selective reading remains important.
- Context control: Strong. `SKILL.md` acts as the canonical behavior contract, commands add task-specific data-gathering and verification phases, and harness-specific `AGENTS.md` files point back to the same source instead of duplicating instructions.
- Sub-agent / multi-agent: Weak. No delegation model or multi-agent runtime exists. The closest related pattern is decision-rationale recovery from conversation history, progress docs, commit messages, and plan files.
- Domain-specific workflow: Very strong. The repo encodes visual explanation decisions: when to use Mermaid vs. CSS Grid vs. tables vs. Chart.js, how to handle diagrams over 10-12 nodes, when slides are allowed, how to avoid generic AI-looking design, and how to make technical reviews readable.
- Error prevention: Moderate to strong at the instruction level. Commands require fact sheets before HTML generation, and the skill requires quality checks for hierarchy, theme behavior, overflow, zoom controls, and clean browser opening. There is no automated test harness enforcing those checks.
- Self-learning / memory: Conditional. The repo does not store learning, but `diff-review` and `project-recap` explicitly mine progress docs, commit history, and prior decisions to preserve rationale and reduce re-entry cost.
- Popular skills: Locally relevant command templates are `diff-review`, `plan-review`, `project-recap`, `fact-check`, `generate-web-diagram`, `generate-visual-plan`, `generate-slides`, and `share-page`.

## Core Execution Path

The default path is skill-triggered artifact generation:

1. The user asks for a diagram, architecture overview, diff review, plan review, project recap, slide deck, or complex table.
2. The host loads `plugins/visual-explainer/SKILL.md`, or a slash-command template under `commands/` loads it first.
3. The skill chooses an output mode: Mermaid for routed diagrams, CSS Grid cards for text-heavy architecture, real `<table>` markup for audits/comparisons, Chart.js for dashboards, or slide-deck mode only when explicitly requested.
4. The agent reads the matching template and references: `mermaid-flowchart.html`, `architecture.html`, `data-table.html`, `slide-deck.html`, `css-patterns.md`, `libraries.md`, `responsive-nav.md`, and/or `slide-patterns.md`.
5. Review commands gather source facts before presentation. `diff-review`, `plan-review`, `project-recap`, and `generate-visual-plan` all require a structured fact sheet of names, counts, behavior claims, and sources before generating HTML.
6. The agent writes a single HTML artifact to `~/.agent/diagrams/` and opens it with the host's browser mechanism if allowed.
7. Optional sharing runs `scripts/share.sh`, which copies the HTML to a temp directory as `index.html`, invokes a Pi-compatible `vercel-deploy` script, and returns deployment JSON plus live/claim URLs.

The important workflow choice is that facts are gathered and verified before visual composition. The HTML artifact should be a visualization of checked claims, not a freeform model-generated story.

## Architecture

The repository is small and file-system native:

- `package.json`: package metadata, Pi skill/prompt paths, version `0.7.1`, and distribution file list.
- `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json`: Claude Code marketplace distribution wrapper.
- `plugins/visual-explainer/.claude-plugin/plugin.json`: plugin manifest pointing `skills` at the canonical skill directory.
- `plugins/visual-explainer/SKILL.md`: main trigger metadata, workflow, diagram-type routing, visual design rules, output contract, sharing notes, quality checks, and anti-patterns.
- `plugins/visual-explainer/commands/*.md`: command-specific workflows for reviews, plans, recaps, fact checking, diagrams, slides, and sharing.
- `plugins/visual-explainer/references/*.md`: reusable CSS/layout, Mermaid/Chart.js/font, responsive navigation, and slide-deck guidance.
- `plugins/visual-explainer/templates/*.html`: exemplar self-contained pages for architecture, Mermaid flowcharts, data tables, and slide decks.
- `plugins/visual-explainer/scripts/share.sh`: bash wrapper for Vercel sharing through `vercel-deploy`.
- `configs/*`: harness guidance for Pi, Codex, OpenCode/opencode, Cursor, and OpenClaw that points users back to the canonical skill.

There is no source code loader, permission manager, sandbox, browser automation verifier, or CI-backed validator in the repo. Those responsibilities are delegated to the host agent and local environment.

## Design Choices

The core design choice is output-medium control. The skill forbids falling back to ASCII art when loaded and proactively converts sufficiently complex tables into browser artifacts. That is a useful domain instruction because it changes the agent's default communication channel for complex structured information.

The second major choice is progressive reference loading. The skill does not ask the agent to memorize every template. It maps content type to a specific template/reference set, which gives the host a natural context-control strategy: load only the files needed for the artifact being generated.

The visual design rules are unusually concrete. The skill bans common generic patterns, names acceptable font pairings and palettes, specifies Mermaid theming constraints, warns about Mermaid parser edge cases, requires zoom controls for diagrams, and distinguishes scrollable pages from slide decks. This turns visual quality into a checklist of repeatable decisions.

The review commands make verification part of the artifact contract. They ask the agent to collect command output, file references, function/type names, behavior descriptions, and confidence levels before composing the page. That is the right pattern for visual explanations, where polished layout can otherwise make unchecked claims look authoritative.

Cross-harness support is handled as adapter guidance rather than duplicated skill copies. The configs for Codex, Pi, OpenCode/opencode, Cursor, and OpenClaw all point at `plugins/visual-explainer/` as canonical. That keeps the repo maintainable while acknowledging that command-template support, browser access, and sharing vary by host.

## Strengths

- Clear artifact generation contract: self-contained HTML, stable output directory, descriptive filenames, and browser handoff.
- Strong domain routing rules: Mermaid vs. CSS Grid vs. table vs. dashboard vs. slide deck are chosen by content shape, not by generic preference.
- Good verification pattern for reviews: fact sheets, source citations, uncertainty handling, decision-rationale recovery, and explicit Good/Bad/Ugly sections.
- Strong context-control shape: command files are task overlays, while templates/references are loaded only for the selected output type.
- Practical visual quality guardrails: anti-slop constraints, overflow rules, responsive nav, theme handling, font/palette guidance, and diagram zoom/pan requirements.
- Cross-harness packaging is conservative: one canonical skill, package/marketplace metadata, and thin harness-specific instructions.

## Weaknesses

- Verification is mostly prompt-enforced. The repo has no Playwright smoke test, HTML validator, screenshot comparison, console-error checker, or automated Mermaid render check.
- Browser and CDN assumptions limit reliability. Generated files may depend on Google Fonts, Mermaid, Chart.js, anime.js, and browser access; offline or sandboxed hosts may only be able to produce the file path.
- `share-page` is a narrow tool boundary. `share.sh` only searches Pi-style `vercel-deploy` locations and uses shell parsing of deployment output, so sharing is less portable than HTML generation.
- Template and instruction drift exists. `SKILL.md` strongly warns against bare `<pre class="mermaid">`, while the slide-deck template still uses a simpler `<pre class="mermaid">` pattern inside its slide diagram example.
- Version metadata is not fully synchronized. Package and plugin manifests are `0.7.1`, but `SKILL.md` frontmatter still reports metadata version `0.6.3`.
- The templates are examples with fictional content. They are useful for pattern absorption, but without automated checks an agent can copy stale details, overfit a template, or miss newer guidance in references.

## Ideas To Steal

- Treat nontrivial visual explanations as durable artifacts with a known output directory and a browser-first viewing path.
- Add a fact-sheet checkpoint before generating any polished review or recap page.
- Keep task commands as thin overlays over a canonical skill; do not duplicate the full domain workflow per command.
- Route visual formats by content type: Mermaid for topology, CSS cards for rich module detail, semantic tables for audits, Chart.js for real charts, and slides only on explicit request.
- Include template/reference files as context-control units. The main skill should tell the agent exactly which files to read for each artifact mode.
- Encode visual anti-patterns as negative constraints, not vague taste advice.
- Require diagram ergonomics as part of the artifact contract: zoom controls, panning, click-to-expand, layout direction rules, node-count limits, and hybrid diagrams for complex systems.
- Make re-entry context a first-class section for diff reviews and project recaps: key invariants, non-obvious coupling, gotchas, and missing rationale.
- Keep cross-harness adapters thin and point them at the same canonical skill source.

## Do Not Copy

- Do not rely on prompt-level quality checks alone for high-assurance visual artifacts. Add browser smoke tests, screenshot checks, console checks, and Mermaid render validation if adopting this pattern.
- Do not copy CDN dependencies into environments that require offline or reproducible builds without vendoring or pinning them.
- Do not make sharing depend on one host's skill path unless the lab intentionally standardizes that host.
- Do not let example templates become the source of truth. Keep behavior in the skill/references and treat templates as samples.
- Do not use a polished HTML page to hide uncertainty. Preserve the fact-sheet pattern and mark unverified claims visibly.
- Do not copy the visual style verbatim. Copy the selection rules, artifact contract, and verification workflow.

## Fit For Agentic Coding Lab

Fit is in-scope for `domain-specific-coding`. The repo is not a general coding-agent framework, but it is a strong example of a domain skill that changes how agents gather, verify, and present codebase understanding.

Agentic Coding Lab should steal the workflow skeleton: canonical skill, command overlays, artifact directory, mode-specific references, fact-sheet verification, and browser artifact checks. The lab version should add machine verification around the output: launch a browser, inspect console errors, assert Mermaid SVGs rendered, check viewport overflow, and save a screenshot receipt.

The most useful reusable skill design is a two-plane contract: source facts stay in a verified fact sheet, and the HTML is a presentation layer over those facts. That separation would make visual artifacts reviewable, regenerable, and safer to use in planning or code-review workflows.

## Reviewed Paths

- `/tmp/myagents-research/nicobailon-visual-explainer/README.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/package.json`
- `/tmp/myagents-research/nicobailon-visual-explainer/CHANGELOG.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/LICENSE`
- `/tmp/myagents-research/nicobailon-visual-explainer/install-pi.sh`
- `/tmp/myagents-research/nicobailon-visual-explainer/.claude-plugin/plugin.json`
- `/tmp/myagents-research/nicobailon-visual-explainer/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/.claude-plugin/plugin.json`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/SKILL.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/diff-review.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/plan-review.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/project-recap.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/fact-check.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/generate-web-diagram.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/generate-visual-plan.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/generate-slides.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/commands/share-page.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/references/css-patterns.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/references/libraries.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/references/responsive-nav.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/references/slide-patterns.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/templates/architecture.html`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/templates/mermaid-flowchart.html`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/templates/data-table.html`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/templates/slide-deck.html`
- `/tmp/myagents-research/nicobailon-visual-explainer/plugins/visual-explainer/scripts/share.sh`
- `/tmp/myagents-research/nicobailon-visual-explainer/configs/pi/AGENTS.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/configs/codex/AGENTS.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/configs/opencode/AGENTS.md`
- `/tmp/myagents-research/nicobailon-visual-explainer/configs/cursor/visual-explainer.mdc`
- `/tmp/myagents-research/nicobailon-visual-explainer/configs/openclaw/AGENTS.md`

## Excluded Paths

- `/tmp/myagents-research/nicobailon-visual-explainer/.git/**`: VCS internals; commit SHA and recent log were captured separately.
- `/tmp/myagents-research/nicobailon-visual-explainer/banner.png`: README media asset, not an instruction or execution boundary.
- Remote README videos and GitHub attachment assets: useful demonstrations, but outside the cloned source and not needed for workflow analysis.
- Generated HTML outputs under `~/.agent/diagrams/`: none are checked into the repository; templates were reviewed instead.
- External CDN library source for Mermaid, Chart.js, anime.js, Google Fonts, and optional `surf-cli`: referenced as runtime/browser dependencies but not vendored source in this repo.
- Hosted Vercel deployments produced by `share-page`: dynamic external artifacts, outside the repository.
