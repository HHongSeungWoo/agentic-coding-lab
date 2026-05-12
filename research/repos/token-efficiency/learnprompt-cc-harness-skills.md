# LearnPrompt/cc-harness-skills

- URL: https://github.com/LearnPrompt/cc-harness-skills
- Category: token-efficiency
- Stars snapshot: 211 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 21de62ee4b31e8899630d0586d498d5f409f0317
- Reviewed at: 2026-05-12T12:07:56+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong compact reference for portable coding-agent skills that target memory hygiene, continuation compression, verification, coordination, and bounded proactive work. Best reusable idea is the "prompt template plus tiny context script" packaging pattern; main weakness is that most behavior remains advisory because the repo has no host runtime, hooks, eval harness, or command layer.

## Why It Matters

`LearnPrompt/cc-harness-skills` packages six small, installable skills around common coding-agent failure modes: stale memory, lossy compaction, unverified completion claims, polluted multi-agent context, and uncontrolled proactive background work. The repo is relevant to token efficiency because it treats context as something to shape before it enters the model: memory indexes stay short, compression has fixed sections, verification receives only git context, and coordinator prompts keep raw worker exploration out of final synthesis.

For Agentic Coding Lab, this is a useful example of taking larger harness behaviors and reducing them into portable skill bundles. It is not a full agent framework. It is a set of Markdown skills, prompt templates, source notes, and minimal Python helpers that can be copied into Claude Code, Codex, or OpenClaw skill directories.

## What It Is

The repository is a public skill pack with six bundles under `skills/`:

- `dream-memory`: consolidates logs, transcripts, and topic memories into a concise `MEMORY.md` index.
- `memory-extractor`: extracts durable `user`, `feedback`, `project`, and `reference` memories from recent turns.
- `structured-context-compressor`: produces a nine-section continuation summary for long sessions and handoffs.
- `verification-gate`: runs a read-only challenge pass after implementation.
- `swarm-coordinator`: structures multi-agent work into research, synthesis, implementation, and verification.
- `kairos-lite`: defines bounded proactive jobs with schedule, sleep, brief, and expiry rules.

Each bundle has `SKILL.md`, `README.md`, `references/prompt-template.md`, `references/source-notes.md`, and one Python helper script. The root README and release docs position the pack as CC-inspired but host-agnostic. The repo ships smoke-test notes and a `skills/check_all.sh` script that verifies bundle structure and Python compilation.

## Research Themes

- Token efficiency: Strong. The concrete mechanisms are concise memory indexes, topic-level memory manifests, a fixed nine-section continuation artifact, and small git-context snapshots for verification rather than loading full history.
- Context control: Strong. Every skill defines what to inspect, what to preserve, and what to avoid. The compressor explicitly preserves user messages and the verifier separates claimed validation from actual evidence.
- Sub-agent / multi-agent: Moderate. `swarm-coordinator` captures a useful ownership and phase model, but there is no runtime mailbox, worker launcher, permission sync, or orchestration engine.
- Domain-specific workflow: Low to moderate. The skills are coding-agent workflow primitives rather than framework-specific programming skills.
- Error prevention: Strong. `verification-gate`, memory rules against drifting code facts, and coordinator separation all target common agent mistakes.
- Self-learning / memory: Strong. The two memory skills distinguish durable collaboration facts from stale code-state facts and prefer topic updates over chronological dumps.
- Popular skills: Most valuable for this repo's category are `structured-context-compressor`, `dream-memory`, `memory-extractor`, `verification-gate`, and `swarm-coordinator`.

## Core Execution Path

The execution path is filesystem and prompt driven:

1. User installs one or more skill directories into a host skill path such as `~/.claude/skills`, `~/.codex/skills`, or `~/.openclaw/workspace/skills`.
2. User invokes a skill explicitly, for example asking the agent to use `/dream-memory`.
3. The agent reads `SKILL.md` for the trigger, quick-start command, workflow, and rules.
4. The optional helper script builds a small artifact: memory report, memory manifest, git verification context, task board, continuation template, or proactive job spec.
5. The host agent applies `references/prompt-template.md` to perform the actual reasoning and writes only the expected artifacts.
6. `skills/check_all.sh` can verify bundle presence and Python syntax, but it does not test skill effectiveness.

There are no repo-level command definitions, host hooks, examples directory, or tests directory at the reviewed commit. The closest test surface is `skills/check_all.sh` plus `skills/TEST_REPORT.md`, which records manual smoke tests for Claude Code and OpenClaw and a blocked Codex runtime test due to missing local auth.

## Architecture

The architecture is intentionally flat:

- Root `README.md` explains the pack, installation examples, and host fit.
- `skills/README.md` documents publishing order, layout, local checks, and ClawHub publish commands.
- `skills/<skill>/SKILL.md` is the host-facing skill contract.
- `skills/<skill>/references/prompt-template.md` holds the actual reusable prompt.
- `skills/<skill>/references/source-notes.md` maps the portable skill back to CC source areas and says what was dropped.
- `skills/<skill>/scripts/*.py` produces bounded context or scaffolding for the prompt.
- `skills/check_all.sh` confirms directory structure and compiles helper scripts.
- Release docs capture publish copy and smoke-test status.

The Python helpers are deliberately small. They do not call LLM APIs or mutate host state by themselves. `dream_memory.py` inspects memory indexes, topic files, and recent logs/transcripts. `memory_manifest.py` parses simple Markdown frontmatter. `verification_context.py` shells out to git for status, diff stat, changed files, head, and branch. `task_board.py`, `render_template.py`, and `job_spec.py` print JSON or Markdown scaffolds.

## Design Choices

The strongest design choice is to make each skill portable by separating host-specific runtime behavior from the durable prompt pattern. Source notes repeatedly say the repo keeps workflow shape and drops private host wiring, feature flags, analytics, cache editing, pane management, notification internals, and hook timing.

The second choice is to use small context collectors instead of large framework adapters. This helps token efficiency because a verifier sees status and changed files, a memory extractor sees a manifest, and a compressor starts from a fixed outline rather than an unbounded free-form summary.

The third choice is negative guidance. Memory skills say not to store code-state facts that should be re-read from source. The compressor says not to compress away user corrections. The verifier says not to imply validation ran if it did not. Kairos Lite says not to create unrestricted daemons or hidden background writes.

The fourth choice is explicit phase separation. `swarm-coordinator` makes the coordinator own planning and synthesis while workers own bounded execution. `verification-gate` keeps verification separate from implementation. That reduces context pollution and optimistic self-review.

## Strengths

The repo gives concise, reusable patterns for several high-value coding-agent behaviors without requiring a new agent runtime. That makes it easy to adapt into other harnesses or project-local skills.

The memory guidance is practical. It separates durable preferences and project constraints from drifting code facts, and it pushes agents to merge topic files rather than create duplicate chronological notes.

The compressor is simple but high leverage. A fixed nine-section artifact is easier to verify after compaction than a generic summary, especially because it requires user messages, errors, pending tasks, current work, and next aligned step.

The verification skill directly addresses false completion. It asks for evidence that validation ran, separates verified from unverified work, and makes findings precede summary.

The package is honest about verification status. `skills/TEST_REPORT.md` says Claude Code and OpenClaw loaded all six skills, while Codex end-to-end invocation remained blocked by local authentication.

## Weaknesses

Most behavior is advisory. Without host support for reliable skill invocation, subagents, hooks, or scheduled jobs, these are prompts and helper scripts rather than enforced workflows.

The helper scripts collect useful context but do not implement full memory consolidation, extraction, compression, verification, or scheduling. The model still performs the key judgment calls.

There is no reproducible eval showing that the skills improve coding outcomes, reduce token use, or prevent errors across tasks. `check_all.sh` tests packaging and Python syntax only.

`swarm-coordinator` has a clear phase model but no concrete worker protocol beyond a generated task board. It omits mailbox semantics, permissions, result schemas, retry rules, and integration conflict handling.

Several Markdown links in README and release docs point to an absolute local path under `/Users/carl/Downloads/codegod/...`, which weakens portability polish even though it does not affect the skill mechanics.

## Ideas To Steal

Package each skill with three layers: activation contract in `SKILL.md`, exact prompt template in `references/`, and a tiny script that produces bounded context.

Use memory rules that explicitly forbid storing code facts that can drift. Durable memory should preserve user preferences, feedback, non-code constraints, and external references.

Make continuation compression a fixed-schema artifact. Include all user messages or an accurate condensed equivalent, errors and fixes, pending work, current work, and one next aligned step.

Require verification prompts to separate claimed validation from observed evidence. "Not run" should be a first-class outcome, not a footnote.

For multi-agent work, separate research, synthesis, implementation, and verification, and keep one owner per write surface.

For proactive agents, start with job specs that include schedule, brief output, and expiry before building any daemon-like behavior.

## Do Not Copy

Do not treat these skills as an enforcement boundary. They do not prevent writes, restrict tools, or guarantee that a host agent follows the prompt.

Do not copy the source-derived claims without checking license and provenance requirements for the target project. The repo has MIT licensing, but the source notes describe extraction from a mirrored CC codebase rather than an independently designed workflow.

Do not over-index on Python helpers as complete implementations. They are useful context shapers, not memory engines, schedulers, or verification harnesses.

Do not adopt `swarm-coordinator` as-is for complex multi-agent systems. Add worker result schemas, permission boundaries, dependency tracking, and integration rules first.

Do not claim Codex runtime compatibility from this repo alone. The included smoke report says Codex structure was verified but runtime invocation was blocked by authentication.

## Fit For Agentic Coding Lab

Fit is in-scope and strong for token-efficiency research. The repo is not a compression algorithm, but it demonstrates practical context-budget discipline for coding agents: compact memory indexes, targeted manifests, structured handoff summaries, bounded git verification snapshots, and coordinator-mediated synthesis.

Agentic Coding Lab should use it as a reference for project-local skill shape. The most useful local adaptation would be a stricter version of these patterns with machine-checkable inputs and outputs: schema-validated memory records, verification context with test command provenance, continuation summaries with required fields, and coordinator task boards that can be linted.

## Reviewed Paths

- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/LICENSE`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/check_all.sh`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/publish_all.sh`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/TEST_REPORT.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/RELEASE_PLAN.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/GIT_RELEASE_CHECKLIST.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/CLAWHUB_LISTINGS.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/GITHUB_RELEASE_v0.1.0.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/SHORT_POST_COPY.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/dream-memory/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/dream-memory/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/dream-memory/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/dream-memory/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/dream-memory/scripts/dream_memory.py`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/memory-extractor/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/memory-extractor/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/memory-extractor/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/memory-extractor/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/memory-extractor/scripts/memory_manifest.py`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/structured-context-compressor/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/structured-context-compressor/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/structured-context-compressor/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/structured-context-compressor/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/structured-context-compressor/scripts/render_template.py`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/verification-gate/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/verification-gate/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/verification-gate/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/verification-gate/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/verification-gate/scripts/verification_context.py`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/swarm-coordinator/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/swarm-coordinator/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/swarm-coordinator/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/swarm-coordinator/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/swarm-coordinator/scripts/task_board.py`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/kairos-lite/SKILL.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/kairos-lite/README.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/kairos-lite/references/prompt-template.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/kairos-lite/references/source-notes.md`
- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/skills/kairos-lite/scripts/job_spec.py`

## Excluded Paths

- `/tmp/myagents-research/LearnPrompt-cc-harness-skills/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `commands/`: no commands directory exists at reviewed commit, so there was no command implementation to inspect.
- `hooks/`: no hooks directory exists at reviewed commit; source notes describe host hooks that were intentionally dropped.
- `examples/`: no examples directory exists at reviewed commit; usage examples are inline in READMEs.
- `tests/`: no tests directory exists at reviewed commit; `skills/check_all.sh` and `skills/TEST_REPORT.md` are the only verification surfaces.
- Generated, vendored, binary, and UI-only assets: none were present in the tracked file list returned by `rg --files`.
