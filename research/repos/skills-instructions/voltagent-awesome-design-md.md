# VoltAgent/awesome-design-md

- URL: https://github.com/VoltAgent/awesome-design-md
- Category: skills-instructions
- Stars snapshot: 75,531 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: f2d6b17d0dd706c9b0942674e6a6a782652cb127
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful corpus for DESIGN.md-as-agent-memory: brand-level UI instructions, token dictionaries, component rules, responsive behavior, iteration advice, and negative constraints. Best value is as a pattern library for design-system context control; weakest area is no local loader, preview generator, lint config, tests, or verification path.

## Why It Matters

`awesome-design-md` treats visual design guidance as a plain Markdown artifact that coding and design agents can ingest directly. That makes it relevant to agent context control: instead of putting brand taste, typography, spacing, component states, and anti-patterns into long chat prompts, the project externalizes them into `DESIGN.md` files that can be copied into a target project.

For Agentic Coding Lab, the interesting part is not the brands themselves. The interesting part is the document contract: a stable file name, structured tokens, component-level examples, "Do / Don't" guardrails, responsive rules, and iteration notes that help an agent generate UI with less ad hoc prompting.

## What It Is

The repository is a static Markdown collection of 71 `DESIGN.md` files under `design-md/<brand>/`. Each brand directory contains a design-system document; 70 also contain a tiny `README.md` redirecting users to `getdesign.md` for previews and downloads. `design-md/slack/` has a `DESIGN.md` but no local README.

The root `README.md` positions `DESIGN.md` as the visual counterpart to `AGENTS.md`: `AGENTS.md` tells coding agents how to build; `DESIGN.md` tells design agents how the UI should look and feel. The documented usage path is copy one file into a project root and tell an AI agent to use it.

The current checkout is not an executable tool. There is no package manifest, no local generator, no checked-in preview HTML, no test suite, and no top-level lint configuration. The only config-like files outside docs are GitHub funding and a design request issue template.

## Research Themes

- Token efficiency: Strong pattern, weak implementation. Moving visual rules into a task-specific file can reduce repeated prompt text, but individual `DESIGN.md` files are often 20-44 KB and need selective retrieval or summarization in long sessions.
- Context control: Strong. The corpus separates visual memory from coding instructions and uses stable headings, token names, and component entries that agents can reference precisely.
- Sub-agent / multi-agent: Weak. No subagent runtime exists. The best fit is handoff between coding agents, visual/design agents, Google Stitch, and external preview/download pages.
- Domain-specific workflow: Strong for UI generation. Files encode brand-specific colors, typography, spacing, layout, components, responsive behavior, and iteration guidance.
- Error prevention: Moderate. Do/Don't sections, known gaps, token references, and suggested `npx @google/design.md lint DESIGN.md` checks prevent common UI drift, but enforcement is not wired into this repo.
- Self-learning / memory: Conditional. The repository is a reusable design memory bank, but it does not learn from generated UI or store project-specific feedback.
- Popular skills: No install or usage telemetry was reviewed. Locally relevant entries for agentic UI workflows include `voltagent`, `cursor`, `claude`, `mintlify`, `vercel`, `posthog`, `supabase`, `opencode.ai`, `warp`, and `together.ai`.

## Core Execution Path

The actual execution path is manual and file-based:

1. A user chooses a brand directory under `design-md/`.
2. The user copies that directory's `DESIGN.md` into a project root or otherwise adds it to agent context.
3. A coding/design agent reads the Markdown. In newer files, the top block provides YAML-like token definitions for `colors`, `typography`, `rounded`, `spacing`, and `components`.
4. The prose sections explain the brand atmosphere, token roles, layout rules, component usage, responsive behavior, Do/Don't constraints, iteration guidance, and known gaps.
5. For edits, many files advise `npx @google/design.md lint DESIGN.md`, but this repo does not include a package script or CI job that runs it.
6. Per-brand READMEs point to `getdesign.md/<brand>/design-md` for previews, dark mode examples, and downloads, but those preview artifacts are not present in the checkout.

There are references inside some files to `scripts/derive-examples-block.mjs`, `/preview-design`, and `/generate-kit`. Those appear to describe an upstream or external generation pipeline, but no matching script or route exists in this repository.

## Architecture

The architecture is a flat static corpus:

- `README.md`: concept explanation, collection index, usage instructions, contribution notes, and license statement.
- `CONTRIBUTING.md`: contribution workflow; maintainers ask for issues first and state they do not accept new `DESIGN.md` pull requests.
- `design-md/<brand>/DESIGN.md`: the design-system memory artifact consumed by agents.
- `design-md/<brand>/README.md`: minimal redirect to hosted `getdesign.md` previews and downloads; absent for `slack`.
- `.github/ISSUE_TEMPLATE/design-md-request.yml`: request form for generating a new `DESIGN.md` from a website.
- `.github/FUNDING.yml`, `.gitignore`, `LICENSE`: project metadata, not agent behavior.

The files are not uniform. 61 `DESIGN.md` files use a newer `version: alpha` frontmatter plus expanded sections like `Overview`, `Colors`, `Typography`, `Layout`, `Components`, `Shapes`, `Elevation & Depth`, `Do's and Don'ts`, `Responsive Behavior`, `Iteration Guide`, and `Known Gaps`. 10 older files use a numbered Stitch-style section layout ending with `Agent Prompt Guide`.

## Design Choices

The core design choice is Markdown as the agent interface. That keeps the artifact host-agnostic: Codex, Claude Code, Cursor, Stitch, or another agent can read it without a custom parser.

The newer files combine machine-friendly token blocks with human-readable explanations. For example, `voltagent/DESIGN.md` defines named color, typography, radius, spacing, and component tokens first, then explains when each token should or should not be used. This gives agents both direct values and judgment rules.

The documents encode negative constraints, not just style preferences. Cursor's file says timeline pastels stay inside in-product agent visualizations; VoltAgent's file says the primary green is CTA-only and the brand is dark-canvas only; Mintlify's file says Inter is for prose and Geist Mono is for code. These constraints are useful for preventing plausible but off-brand UI.

The `ex-*` component entries are a notable abstraction. They map common application surfaces such as pricing cards, product selectors, app-shell rows, data-table cells, auth cards, modals, empty states, and toasts onto brand-native tokens. That is directly useful for agent UI coding because it translates brand identity into generic app-building primitives.

The repo chooses broad brand coverage over local verification. It has many design memories, but no screenshot tests, generated previews, schema checks, or examples proving an agent can reproduce each style from the file alone.

## Strengths

The corpus shows a concrete way to separate design-system memory from general project instructions. A project can keep `AGENTS.md` focused on code workflow and `DESIGN.md` focused on visual output.

The best files are dense, actionable, and agent-friendly. They specify exact hex values, font fallbacks, line heights, radii, spacing scales, component states, breakpoints, touch targets, layout collapse rules, and anti-patterns.

The Do/Don't sections are high-value guardrails. They capture the brand decisions agents often miss: when not to use accent colors, when not to add shadows, when not to introduce light mode, and when a visual motif is scoped to one subsystem.

The `Iteration Guide` and `Known Gaps` sections are useful memory hygiene. They tell future agents how to edit the design file and where not to over-infer missing facts.

The static-file format makes cross-tool workflow simple. A user can copy a file, paste it into context, commit it to a repo, or route it through a design agent without installing a runtime.

## Weaknesses

The repository's README is ahead of the checkout. It claims 73 `DESIGN.md` files and says each site includes `preview.html` and `preview-dark.html`, but the reviewed checkout has 71 `DESIGN.md` files and zero `.html` preview files.

There is no executable validation path. The docs mention `npx @google/design.md lint DESIGN.md` in many files, but no package script, CI workflow, lockfile, or lint result is committed.

The corpus is uneven. 61 files use the newer token/prose structure, while 10 older files use a shorter numbered format. Some quality issues are visible, such as `design-md/slack/DESIGN.md` naming the system "Slacc Inspired".

Source provenance is not inspectable in-repo. The files say tokens are extracted from public websites, but there are no extraction scripts, capture logs, screenshots, CSS snapshots, or comparison tests.

The files can be large enough to become context-heavy. Without a retrieval policy, an agent may ingest a 40 KB brand document when only button tokens or layout rules are needed.

## Ideas To Steal

Add a project-root `DESIGN.md` convention next to `AGENTS.md` for UI work. Keep coding process and visual system memory separate.

Use stable token names and component references so agents can cite `{colors.primary}`, `{typography.body-md}`, `{rounded.lg}`, or `button-primary` instead of paraphrasing visual rules.

Include Do/Don't constraints for every design memory. Negative examples prevent the most common "looks plausible but wrong" agent output.

Translate brand systems into generic app surfaces with `ex-*` entries: pricing tier, app-shell row, data table cell, auth form, modal, toast, and empty state.

Add an `Iteration Guide` that tells agents how to safely modify the design memory and what verification command to run.

Use `Known Gaps` to prevent overconfident invention when source material did not expose animation, dark mode, validation states, or syntax highlighting.

## Do Not Copy

Do not copy brand identities, proprietary font names, or public-site lookalikes into production UI without legal and product review. The repo is MIT-licensed as documents, but the underlying brands are not yours.

Do not assume Markdown alone is enough for reliable generation. Pair `DESIGN.md` with screenshot review, linting, component tests, and design-system ownership.

Do not import a full 40 KB design file into every agent turn. Use retrieval, section extraction, or summaries based on the current UI task.

Do not trust README claims about generated previews. In this commit, preview HTML is not in the repo.

Do not copy the corpus format without adding provenance and verification if your goal is high-assurance design-system memory.

## Fit For Agentic Coding Lab

Fit is in-scope. This is not a coding-agent skill runtime, but it is a strong example of externalized instruction memory for UI generation. It belongs in `skills-instructions` because the primary artifact is agent-readable guidance that changes how agents build interfaces.

The best local adaptation is a smaller, verified `DESIGN.md` pattern for Agentic Coding Lab projects: concise tokens, component mappings, Do/Don't rules, responsive behavior, known gaps, and a required verification command. The repo also suggests a useful cross-tool contract: `AGENTS.md` for build behavior, `DESIGN.md` for visual behavior, and optional hosted previews for inspection.

## Reviewed Paths

- `/tmp/myagents-research/VoltAgent-awesome-design-md/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/CONTRIBUTING.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/LICENSE`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/.gitignore`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/.github/FUNDING.yml`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/.github/ISSUE_TEMPLATE/design-md-request.yml`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/voltagent/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/voltagent/README.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/claude/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/cursor/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/mintlify/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/vercel/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/together.ai/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/kraken/DESIGN.md`
- `/tmp/myagents-research/VoltAgent-awesome-design-md/design-md/slack/DESIGN.md`
- Directory and structure review of all `design-md/*/DESIGN.md` and `design-md/*/README.md` files, including counts for newer `version: alpha` files, older numbered-format files, lint-command mentions, missing README entries, and missing preview HTML.

## Excluded Paths

- `/tmp/myagents-research/VoltAgent-awesome-design-md/.git/`: VCS internals; commit SHA captured separately.
- `/tmp/myagents-research/VoltAgent-awesome-design-md/.agents/` and `/tmp/myagents-research/VoltAgent-awesome-design-md/.codex/`: empty directories in this checkout; no agent behavior to review.
- Hosted `getdesign.md` preview pages: referenced by per-brand READMEs but outside the cloned repository and not required to understand the repo's checked-in execution path.
- Original public websites represented by the design files: source inspiration/provenance targets, but reviewing every live site would be a separate visual audit rather than a repo execution-path review.
- GitHub-generated badge images and remote README image assets: UI-only/remote assets; not part of local agent instructions.
- GitHub funding metadata: noted for project metadata, excluded from agent-context analysis.
