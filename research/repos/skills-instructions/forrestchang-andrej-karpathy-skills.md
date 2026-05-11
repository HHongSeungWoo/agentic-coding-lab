# forrestchang/andrej-karpathy-skills

- URL: https://github.com/forrestchang/andrej-karpathy-skills
- Category: skills-instructions
- Stars snapshot: 124,809 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 2c606141936f1eeef17fa3043a72095b4765b9c2
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Small, focused behavior pack for reducing coding-agent mistakes. Useful as a minimal instruction baseline for assumption surfacing, simplicity, surgical diffs, and verification loops; weak as a full support system because it has no loader, tests, hooks, context budgeting, memory, or enforcement layer.

## Why It Matters

This repo is a compact example of the opposite design from large prompt libraries: one short behavioral rule set, packaged for Claude Code, Cursor, and copy-paste project instructions. It targets common coding-agent failures that matter to Agentic Coding Lab: silent assumptions, overbuilt abstractions, unrelated edits, and unverifiable completion claims.

Its value is in distillation. The repo shows that a small set of sharply worded rules can become portable across harnesses when the same content is exposed through `CLAUDE.md`, a Claude Code skill, a Claude plugin manifest, and a Cursor always-on rule.

## What It Is

`forrestchang/andrej-karpathy-skills` is an instruction-only repository. The core content is four principles: think before coding, simplicity first, surgical changes, and goal-driven execution. Those principles appear in `CLAUDE.md`, `skills/karpathy-guidelines/SKILL.md`, and `.cursor/rules/karpathy-guidelines.mdc`.

The packaging surface is minimal. `.claude-plugin/plugin.json` names one plugin and points `skills` at `./skills/karpathy-guidelines`. `.claude-plugin/marketplace.json` publishes that plugin under the `karpathy-skills` marketplace id. The Cursor rule has `alwaysApply: true`, so Cursor applies it automatically when the rule is present in a project. `README.md` and `CURSOR.md` explain install paths; `EXAMPLES.md` gives concrete before/after examples for each principle.

## Research Themes

- Token efficiency: Strong for instruction size. The entire active rule set is roughly 65-67 lines depending on host format, with examples kept in a separate doc that does not need to be loaded during normal operation.
- Context control: Moderate. The repo uses separate files for host-specific surfaces, but it has no dynamic loader, retrieval policy, or mechanism for loading examples only when needed.
- Sub-agent / multi-agent: None. No delegation, reviewer, planner, or worker roles are defined.
- Domain-specific workflow: Moderate for coding workflow, not framework-specific. It encodes general engineering behavior rather than language or stack rules.
- Error prevention: Strong at prompt level. It directly targets assumption errors, scope creep, drive-by refactors, and fixes without reproducible tests.
- Self-learning / memory: None. No persistent memory, feedback capture, or skill improvement loop exists.
- Popular skills: The only skill is `karpathy-guidelines`; its useful trigger scope is writing, reviewing, or refactoring code.

## Core Execution Path

There is no executable agent runtime in this repository. Execution depends on the host client.

For Claude Code plugin use, the user adds the repo as a plugin marketplace and installs `andrej-karpathy-skills@karpathy-skills`. The marketplace manifest points at the repository root, the plugin manifest exposes `./skills/karpathy-guidelines`, and the host discovers the `SKILL.md` frontmatter. When a coding, review, or refactor task matches the skill description, the host can load the skill body into context.

For per-project Claude-style use, the user copies or appends `CLAUDE.md`. A compatible agent reads that file as project instructions and applies the four principles to subsequent coding tasks.

For Cursor, the committed `.cursor/rules/karpathy-guidelines.mdc` is the active artifact. Its frontmatter sets `alwaysApply: true`, so the rules are applied without user selection when the file is present under `.cursor/rules/`.

The actual behavioral loop is instruction-driven: before implementing, surface assumptions or ask; choose minimal code; touch only lines tied to the request; define success criteria and verify with tests or checks. No script enforces this loop.

## Architecture

The repository is a flat instruction package:

- `CLAUDE.md`: canonical short rule set for Claude-style project instructions.
- `skills/karpathy-guidelines/SKILL.md`: same rule set with skill frontmatter, including name, description, and MIT license.
- `.claude-plugin/plugin.json`: plugin metadata with name, description, version, author, license, keywords, and skill path.
- `.claude-plugin/marketplace.json`: marketplace metadata that exposes the plugin bundle as `karpathy-skills`.
- `.cursor/rules/karpathy-guidelines.mdc`: Cursor project rule with `alwaysApply: true`.
- `README.md`: rationale, install commands, customization guidance, and success signals.
- `CURSOR.md`: setup notes and sync guidance for Cursor.
- `EXAMPLES.md`: illustrative failure and repair examples for the four principles.
- `README.zh.md`: Chinese localization of README content.

There are no dependencies, build steps, tests, generated assets, binary payloads, MCP configs, hooks, or command scripts.

## Design Choices

The main design choice is extreme compression. The active instruction file does not try to cover every coding workflow. It names four failure modes and gives direct rules for each.

The second design choice is host-specific duplication instead of an abstraction layer. The same rules are copied into Claude project instructions, a Claude skill, and a Cursor rule. This avoids runtime machinery, but it creates a sync burden when wording changes.

The third design choice is examples outside the active context. `EXAMPLES.md` is much longer than the rules and demonstrates hidden assumptions, over-abstraction, speculative features, drive-by refactors, style drift, vague goals, incremental verification, and test-first bug reproduction. Keeping those examples separate protects the normal context budget.

The fourth design choice is caution over speed. The README and instruction files explicitly say the rules can be relaxed for trivial tasks, which matters because always-on clarification and verification can slow obvious one-line fixes.

## Strengths

The repo is easy to audit and adopt. The whole behavioral payload fits in one screen, and the examples make the intended behavior concrete.

The principles map cleanly to common coding-agent failure classes. "Every changed line should trace directly to the user's request" is especially useful as a diff-review heuristic.

Packaging is pragmatic. A single rule set works as `CLAUDE.md`, a Claude Code skill/plugin, and a Cursor always-on rule.

The examples are useful training material. They show why plausible best-practice code can still be wrong when it adds premature abstraction, unrelated validation, or formatting churn.

## Weaknesses

The repo has no enforcement. If the host ignores project instructions or skills, nothing happens.

There is no verification machinery. The guidance says to test and define success criteria, but it does not provide test runners, checklists, hooks, or evidence collection.

There is no context orchestration beyond small file size. It does not teach when to load `EXAMPLES.md`, when to compact, or how to prevent instruction conflict with larger project rules.

The same content is duplicated across several files. `CURSOR.md` asks contributors to keep `CLAUDE.md`, `.cursor/rules/karpathy-guidelines.mdc`, and `skills/karpathy-guidelines/SKILL.md` in sync, but the repo does not automate that check.

The README says MIT and plugin metadata declares MIT, but the reviewed checkout has no standalone `LICENSE` file and GitHub API reports `license: null`.

## Ideas To Steal

Use tiny always-on behavior rules for high-frequency coding mistakes instead of loading a large methodology for every task.

Keep examples separate from active rules. Let the skill mention the principles briefly, then provide examples as optional reference material.

Make "changed line traces to request" a standard review question for coding-agent diffs.

Ship the same rule set through multiple host surfaces, but add a sync test so duplicated instruction files cannot drift.

Phrase verification as success criteria before implementation, not as a vague "run tests later" reminder.

Include an explicit tradeoff note so agents know when not to over-apply heavyweight process to trivial edits.

## Do Not Copy

Do not copy the repo as a complete agent-support system. It is a good behavior seed, not a workflow engine.

Do not rely on `alwaysApply: true` rules alone in a large workspace. Always-on instruction piles can create conflicts and token overhead if many packs use this pattern.

Do not duplicate instruction text across hosts without automated drift detection.

Do not treat prompt-level "surgical changes" as enough protection. Filesystem permissions, diff checks, and tests are still needed.

Do not import the examples into active context by default; they are useful but much larger than the core rule set.

## Fit For Agentic Coding Lab

Fit is in-scope. This repo is directly relevant as a minimal skills/instructions artifact for coding-agent error prevention.

Agentic Coding Lab should treat it as a baseline micro-skill: short trigger description, small active payload, optional examples, and multi-harness packaging. The most reusable local artifact would be a compact "surgical coding" rule set combined with deterministic checks: diff scope review, test evidence capture, and duplicate-instruction sync validation.

It is not a model for subagents, memory, MCP, sandboxing, or eval harnesses. Pair it with stronger workflow systems when those are needed.

## Reviewed Paths

- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/README.md`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/CLAUDE.md`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/skills/karpathy-guidelines/SKILL.md`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/.claude-plugin/plugin.json`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/.cursor/rules/karpathy-guidelines.mdc`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/CURSOR.md`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/EXAMPLES.md`
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/README.zh.md`

## Excluded Paths

- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/.git/`: VCS internals; used only to capture commit and history.
- `/tmp/myagents-research/forrestchang-andrej-karpathy-skills/README.zh.md`: read for parity and recent commit context, but not analyzed deeply because it is a localization of `README.md`.
- Generated, vendored, binary, UI-only, and unrelated application paths: none found in tracked source. The repo is text-only instruction/config material.
