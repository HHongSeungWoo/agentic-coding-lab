# mattpocock/skills

- URL: https://github.com/mattpocock/skills
- Category: skills-instructions
- Stars snapshot: 70.2k (GitHub repository page, captured 2026-05-11)
- Reviewed commit: 9f2e0bd0ea776eb6372eb81fa8a4a47814a8404a
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal personal `.claude` skill corpus for agent workflow design. Best reusable ideas are small composable skills, setup-generated per-repo context docs, open-ended grilling, durable issue briefs, and explicit feedback loops. Weakest areas are limited host-side enforcement, no automated repo-wide validation, and issue-tracker behavior encoded as prose/CLI conventions.

## Why It Matters

`mattpocock/skills` matters because it is not a generic prompt pack. It is a public copy of a working personal `.claude` skill set, organized around real engineering failure modes: misaligned requirements, verbose or imprecise domain language, weak feedback loops, shallow architecture, poor triage, and unsafe git operations.

For Agentic Coding Lab, the useful pattern is "personal working method as installable skills." The repo shows how one engineer packages daily agent behavior into small instruction units, with just enough local config to adapt those units to different repositories. It is especially useful for studying context control, token efficiency through shared language, error prevention by workflow gates, and how skills can hand work to issue trackers or future agents without preserving whole chat history.

## What It Is

The repository is a filesystem-native skill library. Stable skills live under `skills/engineering/`, `skills/productivity/`, and `skills/misc/`; personal, in-progress, and deprecated skills are separated from the promoted plugin surface. The installable Claude plugin is declared in `.claude-plugin/plugin.json`, which points at 14 stable skills.

The top-level `README.md` frames the collection as "Skills For Real Engineers" and recommends installing with `npx skills@latest add mattpocock/skills`, then running `/setup-matt-pocock-skills`. That setup skill writes per-repo conventions into an agent instruction block plus `docs/agents/` files for issue tracker, triage labels, and domain docs. Other engineering skills consume those files.

This is not an agent runtime, MCP server, or orchestration framework. Runtime activation is delegated to Claude Code or another host that understands skill directories. The repository supplies trigger metadata, instructions, seed docs, shell helpers, and conventions.

## Research Themes

- Token efficiency: Strong. The repo reduces repeated explanation by pushing domain vocabulary into `CONTEXT.md`, ADRs, and `docs/agents/`. The `caveman` skill is explicitly about compressed communication. The setup ADR also keeps soft-dependency skills token-light by avoiding repeated setup warnings where missing config is not fatal.
- Context control: Strong. Stable skills load only their own `SKILL.md` plus nearby support files when needed. Per-repo setup splits issue tracker, label vocabulary, and domain doc rules into separate docs. `handoff` avoids duplicating content already captured in PRDs, ADRs, issues, commits, or diffs.
- Sub-agent / multi-agent: Conditional. The stable set has limited sub-agent orchestration; `improve-codebase-architecture` and its interface-design support describe parallel sub-agent design exploration, while the in-progress `review` skill uses parallel standards/spec review agents. This is a pattern source, not a mature multi-agent runtime.
- Domain-specific workflow: Very strong. Skills encode specific engineering motions: TDD, diagnosis, triage, PRD writing, issue slicing, architecture deepening, prototyping, pre-commit setup, and git guardrails.
- Error prevention: Strong. `diagnose` requires a reproducible feedback loop before hypotheses, `tdd` requires vertical red-green cycles, `triage` requires state roles and durable agent briefs, `git-guardrails-claude-code` blocks dangerous git commands, and `prototype` requires throwaway cleanup.
- Self-learning / memory: Moderate. There is no autonomous memory system, but `CONTEXT.md`, ADRs, `.out-of-scope/`, issue briefs, and handoff docs act as durable memory artifacts that future agents can read.
- Popular skills: GitHub stars indicate high repo visibility. The README emphasizes `grill-me`, `grill-with-docs`, `tdd`, `diagnose`, and `improve-codebase-architecture`; the stable plugin also promotes `setup-matt-pocock-skills`, `triage`, `to-prd`, `to-issues`, `zoom-out`, `prototype`, `caveman`, `handoff`, and `write-a-skill`.

## Core Execution Path

The host client discovers skill directories through installation or `.claude-plugin/plugin.json`. A user request activates a skill by frontmatter `name` and `description`, then the host loads that skill's `SKILL.md`. From there, execution is mostly model-guided workflow, with a few deterministic shell helpers.

The main repository-level path is:

1. User installs selected skills, including `/setup-matt-pocock-skills`.
2. `/setup-matt-pocock-skills` explores the current repo for remotes, `AGENTS.md` or `CLAUDE.md`, domain docs, ADRs, existing `docs/agents/`, and `.scratch/`.
3. It walks the user through three decisions one at a time: issue tracker, triage labels, and domain docs.
4. It updates the existing agent instruction file with an `## Agent skills` block and writes `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, and `docs/agents/domain.md` from seed templates.
5. Downstream skills read those docs when publishing issues, applying triage labels, naming domain concepts, or respecting ADRs.

Representative downstream paths:

- `/grill-with-docs`: reads existing glossary/ADRs, asks one question at a time, explores code when answerable from source, updates `CONTEXT.md` inline as terms settle, and creates ADRs only for hard-to-reverse, surprising trade-offs.
- `/tdd`: asks for interface and behavior priorities, writes one failing behavior test, implements the smallest green path, repeats by vertical slice, then refactors while tests pass.
- `/diagnose`: builds a deterministic feedback loop, reproduces the bug, ranks falsifiable hypotheses, instruments one prediction at a time, writes a regression test at the correct seam, fixes, and cleans debug artifacts.
- `/triage`: reads full issue context plus `.out-of-scope/`, recommends category/state roles, reproduces bugs before grilling, then posts a durable agent brief or needs-info notes.
- `/to-prd` and `/to-issues`: synthesize existing context, respect domain vocabulary and ADRs, publish PRDs or vertical-slice issues to the configured issue tracker.
- `/prototype`: routes either to a logic TUI with portable pure logic or to UI variants behind `?variant=` and a floating switcher, then captures the learned decision and deletes or absorbs the prototype.

There is no central scheduler, permission layer, or long-lived memory daemon. The "execution engine" is the host agent following skill text and using normal shell/issue-tracker tools.

## Architecture

The repo uses a simple directory architecture:

- `README.md`: public explanation, quickstart, and stable skill catalog.
- `CLAUDE.md`: repo-maintenance rules requiring stable skills to appear in README and plugin metadata, while personal/in-progress/deprecated skills stay excluded.
- `CONTEXT.md`: domain glossary for the skill repo itself, currently focused on issue trackers, issues, and triage roles.
- `docs/adr/0001-explicit-setup-pointer-only-for-hard-dependencies.md`: records dependency policy for setup-generated context.
- `.claude-plugin/plugin.json`: installable plugin manifest listing stable skill directories.
- `scripts/list-skills.sh`: lists every `SKILL.md` under the repo.
- `scripts/link-skills.sh`: symlinks non-deprecated skill directories into `~/.claude/skills`, with a guard against writing links back into the repo through a symlinked destination.
- `skills/engineering/`: coding workflow skills and their support docs/scripts.
- `skills/productivity/`: general workflow skills such as grilling, compressed communication, handoff, and skill writing.
- `skills/misc/`: occasional utility skills such as git guardrails and pre-commit setup.
- `skills/personal/`, `skills/in-progress/`, `skills/deprecated/`: explicitly non-promoted areas for personal setup, drafts, and retired ideas.
- `.out-of-scope/`: durable rejection records for the repo's own triage process.

Skill internals follow progressive disclosure by folder locality. A simple skill such as `zoom-out` is a short `SKILL.md`. A broader skill such as `tdd` links to `tests.md`, `mocking.md`, `interface-design.md`, `deep-modules.md`, and `refactoring.md`. `prototype` splits into `LOGIC.md` and `UI.md`. `triage` links to `AGENT-BRIEF.md` and `OUT-OF-SCOPE.md`. `setup-matt-pocock-skills` bundles seed files for GitHub, GitLab, local issue tracking, label mappings, and domain docs.

## Design Choices

The strongest design choice is small composability. Each skill owns one behavioral move: grill, diagnose, TDD, triage, issue slicing, PRD creation, architecture review, prototype, handoff. The repo avoids one master methodology prompt.

The second choice is explicit per-repo setup. Skills that publish or mutate external state need issue-tracker and label mappings. Skills that only become sharper with project language treat domain docs as soft dependencies. The ADR makes that split deliberate: hard-dependency skills carry a setup warning; soft-dependency skills stay lighter.

The third choice is durable language as token compression. `grill-with-docs` and `improve-codebase-architecture` update `CONTEXT.md` when terminology settles. The README argues that shared domain terms reduce future explanation and thinking tokens. Architecture skills also carry their own controlled vocabulary: Module, Interface, Implementation, Depth, Seam, Adapter, Leverage, and Locality.

The fourth choice is behavioral artifacts over chat memory. PRDs, vertical-slice issues, agent briefs, triage notes, ADRs, `.out-of-scope/` records, handoff docs, and prototype notes are the durable outputs. Skills repeatedly warn against stale file paths and line numbers in issue briefs, favoring interfaces and behavioral contracts.

The fifth choice is human control at decision points. Setup asks one decision at a time. Grilling asks one question at a time and explores the codebase instead of bothering the user when possible. TDD asks for interface and behavior priorities. Triage recommends before applying role changes.

## Strengths

The repo turns tacit senior-engineering habits into portable, reviewable skill files. The skills are concrete enough for an agent to follow, but still small enough to adapt.

Context control is practical. Domain docs, triage docs, support references, and seed templates keep large or project-specific material out of each skill's main body until it is relevant.

The error-prevention posture is strong. Feedback loops, red-green-refactor, durable acceptance criteria, out-of-scope memory, debug cleanup, prototype cleanup, and git hooks all target failures common in AI coding sessions.

The setup skill is a useful bridge between personal skills and foreign repos. It does not assume the user's issue tracker, label names, or doc layout; it discovers and records them once.

The architecture material is unusually good for agent instructions. It gives agents a precise vocabulary and decision tests, which can reduce vague refactor advice.

## Weaknesses

There is little runtime enforcement. Most safety and workflow gates rely on the host model obeying text instructions. The git guardrails skill can install a Claude Code hook, but that protection is optional and platform-specific.

There is no top-level automated validation suite ensuring the README, bucket READMEs, plugin manifest, and skill directories stay in sync. `CLAUDE.md` defines the rule, but enforcement is manual.

Issue tracker support is prose and CLI-template based. That keeps the repo lightweight, but real reliability depends on the agent constructing correct `gh` or `glab` commands and handling auth/API edge cases.

Several skills assume interactive user availability. This is appropriate for grilling and setup, but less useful for unattended agents unless converted into issue/spec artifacts first.

The public plugin surface is Claude-oriented. Empty `.codex/` and `.agents/` directories suggest no equivalent mature packaging for Codex or other harnesses in this repo at the reviewed commit.

## Ideas To Steal

Use a setup skill to write project-specific `docs/agents/` config once, then let other skills consume it. Split hard dependencies from soft context so every skill does not repeat setup boilerplate.

Make domain language a first-class token-efficiency tool. Require skills to read `CONTEXT.md`, use canonical terms, and update the glossary when new terms crystallize.

Prefer durable agent briefs over chat-dependent handoff. Describe current behavior, desired behavior, key interfaces, acceptance criteria, and out-of-scope items; avoid file paths and line numbers that stale quickly.

Encode triage as a small state machine with canonical roles mapped to local labels. This keeps issue workflows portable across repos without hard-coding every user's label strings.

Adopt the diagnosis loop: build feedback loop first, reproduce, rank falsifiable hypotheses, instrument one variable, regression-test at the correct seam, then clean debug artifacts.

Keep prototypes intentionally disposable. UI prototypes should be variant-switchable and hidden from production; logic prototypes should preserve only the pure model if the idea proves useful.

Use `.out-of-scope/` as agent-readable institutional memory for rejected feature classes. That prevents re-litigating the same requests and gives triage a retrieval target.

## Do Not Copy

Do not copy the repo as a complete process mandate. Some skills are intentionally personal and interactive; teams should tune checkpoints, issue tracker behavior, and terminology rules to their own workflow.

Do not treat skill prompts as enforcement. Filesystem permissions, destructive git limits, external issue mutations, and credential boundaries need host/tool controls, not just instructions.

Do not create a setup wizard that writes agent docs without preserving user edits. The reviewed setup skill explicitly explores current files, presents a draft, and updates existing blocks in place.

Do not overuse ADRs. This repo's rule is useful: record decisions only when they are hard to reverse, surprising without context, and born from real trade-offs.

Do not let issue briefs become implementation recipes. The repo is right to avoid brittle file paths and line numbers, but that requires discipline when adapting to local issue templates.

## Fit For Agentic Coding Lab

Fit is strongly in-scope. This is a compact example of how personal AI-coding practice can become a reusable support layer above an existing agent client. It is especially relevant to the `skills-instructions` category because its core artifact is the skill package itself, not an app or framework.

Agentic Coding Lab should treat it as a reference for agent skill packaging, context-control artifacts, token-efficient shared language, and error-prevention workflow design. The most reusable pieces are the setup skill, `grill-with-docs`, `diagnose`, `tdd`, `triage` plus `AGENT-BRIEF.md`, `prototype`, `caveman`, and the architecture vocabulary docs.

The best local adaptation would add automated consistency checks and harness-neutral packaging while preserving the repo's main insight: small skills should produce durable artifacts that shrink future agent context and make unattended work safer.

## Reviewed Paths

- `/tmp/myagents-research/mattpocock-skills/README.md`
- `/tmp/myagents-research/mattpocock-skills/CLAUDE.md`
- `/tmp/myagents-research/mattpocock-skills/CONTEXT.md`
- `/tmp/myagents-research/mattpocock-skills/docs/adr/0001-explicit-setup-pointer-only-for-hard-dependencies.md`
- `/tmp/myagents-research/mattpocock-skills/.claude-plugin/plugin.json`
- `/tmp/myagents-research/mattpocock-skills/scripts/list-skills.sh`
- `/tmp/myagents-research/mattpocock-skills/scripts/link-skills.sh`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/productivity/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/misc/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/personal/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/in-progress/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/deprecated/README.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/setup-matt-pocock-skills/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/setup-matt-pocock-skills/domain.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/setup-matt-pocock-skills/triage-labels.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/setup-matt-pocock-skills/issue-tracker-github.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/grill-with-docs/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/grill-with-docs/ADR-FORMAT.md`
- `/tmp/myagents-research/mattpocock-skills/skills/productivity/grill-me/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/tests.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/mocking.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/interface-design.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/deep-modules.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/tdd/refactoring.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/diagnose/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/diagnose/scripts/hitl-loop.template.sh`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/improve-codebase-architecture/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/improve-codebase-architecture/LANGUAGE.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/improve-codebase-architecture/DEEPENING.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/improve-codebase-architecture/INTERFACE-DESIGN.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/to-prd/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/to-issues/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/triage/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/triage/AGENT-BRIEF.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/triage/OUT-OF-SCOPE.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/prototype/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/prototype/LOGIC.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/prototype/UI.md`
- `/tmp/myagents-research/mattpocock-skills/skills/engineering/zoom-out/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/productivity/caveman/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/productivity/handoff/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/productivity/write-a-skill/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/misc/git-guardrails-claude-code/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh`
- `/tmp/myagents-research/mattpocock-skills/.out-of-scope/mainstream-issue-trackers-only.md`
- `/tmp/myagents-research/mattpocock-skills/.out-of-scope/question-limits.md`
- `/tmp/myagents-research/mattpocock-skills/.out-of-scope/setup-skill-verify-mode.md`
- `/tmp/myagents-research/mattpocock-skills/skills/in-progress/review/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/in-progress/writing-fragments/SKILL.md`
- `/tmp/myagents-research/mattpocock-skills/skills/deprecated/design-an-interface/SKILL.md`
- `https://github.com/mattpocock/skills`

## Excluded Paths

- `/tmp/myagents-research/mattpocock-skills/.git/`: VCS internals; only commit SHA and history metadata were needed.
- `/tmp/myagents-research/mattpocock-skills/LICENSE`: legal metadata, not an execution path.
- `/tmp/myagents-research/mattpocock-skills/.codex/` and `/tmp/myagents-research/mattpocock-skills/.agents/`: empty directories at the reviewed commit.
- `/tmp/myagents-research/mattpocock-skills/skills/personal/**`: skimmed via README/frontmatter; excluded from deep review because `CLAUDE.md` says personal skills are not promoted in README or plugin metadata.
- `/tmp/myagents-research/mattpocock-skills/skills/in-progress/**`: reviewed representative `review` and `writing-fragments` files for design direction, but excluded from plugin-surface conclusions because the bucket README says drafts are not ready to ship.
- `/tmp/myagents-research/mattpocock-skills/skills/deprecated/**`: reviewed one interface-design predecessor for lineage, but excluded from current execution-path analysis because the bucket is explicitly retired.
- `/tmp/myagents-research/mattpocock-skills/skills/misc/scaffold-exercises/**`, `/tmp/myagents-research/mattpocock-skills/skills/misc/setup-pre-commit/**`, and `/tmp/myagents-research/mattpocock-skills/skills/misc/migrate-to-shoehorn/**`: acknowledged as stable misc skills, but not deeply reviewed because the research focus was general agent skill packaging, context control, and coding-workflow reliability rather than course scaffolding or TypeScript test-data migration.
- README image and external badge assets: UI/marketing assets only; no local bitmap or generated asset needed source review.
- No vendored dependency tree, generated source tree, or local binary payload was found in the reviewed file list.
