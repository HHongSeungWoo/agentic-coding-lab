# Codex Harness Coding Performance

- Topic: codex-harness-coding-performance
- Captured at: 2026-05-31
- Status: reviewed synthesis

## Problem

A Codex-like harness cannot assume that stronger coding ability comes only from a stronger base model. The reviewed notes point to a different route: improve the environment around the model so the same model sees the right task state, retrieves the right project knowledge, uses only relevant skills/tools, acts inside safe execution boundaries, verifies claims before reporting success, and leaves replayable traces for regression.

The core failure modes are consistent across the research:

- wrong context: stale docs, missing project facts, oversized transcripts, buried constraints, or lossy summaries;
- wrong capability: too many skills/tools in prompt, weak routing, missing domain-specific procedure, or schema overload;
- wrong action: unsafe shell, broad file writes, dependency installs, git mutations, or untrusted-content instruction following;
- wrong verification: model claims success without test evidence, reviews only prose, or fails to inspect runtime/browser behavior;
- wrong learning loop: failures are not recorded as evals, routing misses are not fed back, and traces are not replayable.

The main finding is that coding performance should be treated as a harness property: a reproducible task loop with typed context, gated tools, sandboxed execution, verification artifacts, and eval telemetry. Prompt instructions matter, but they are most effective when backed by runtime structures.

## Source Notes

High-signal sources for this synthesis:

- Skills and workflow: `obra/superpowers`, `addyosmani/agent-skills`, `anthropics/skills`, `agentskills/agentskills`, `vercel-labs/skills`, `vercel-labs/agent-skills`.
- Runtime routing: `zhengyanzhao1997/SkillRouter`, `langchain-ai/langgraph-bigtool`, `OpenBMB/ToolBench`, `varunreddy/SkillMesh`, plus `runtime-skill-routing.md` and `skill-management-routing.md`.
- Harness and execution: `SWE-agent/SWE-agent`, `openai/evals`, `promptfoo/promptfoo`, `microsoft/playwright`, `microsoft/playwright-mcp`.
- Sandbox/runtime: `e2b-dev/E2B`, `daytonaio/daytona`.
- Context and retrieval: `context-control.md`, `DeusData/codebase-memory-mcp`, `upstash/context7`.
- Error prevention: `kodustech/kodus-ai`, `vercel-labs/openreview`, `kaplanelad/shellfirm`, `guardrails-ai/guardrails`, `tldrsec/prompt-injection-defenses`.

## Main Thesis

The strongest architecture is not a larger system prompt. It is a staged coding harness:

1. route the task to a small active capability set;
2. assemble typed context from current repo state, durable memory, docs, and exact evidence;
3. execute in a sandbox or controlled workspace with narrow command/file/network authority;
4. force feedback loops through tests, linters, browser checks, review, and safety validators;
5. save trace artifacts so failures become routing, context, or verifier regressions.

This turns "coding skill" into several measurable surfaces: skill recall, context recall, action validity, patch correctness, verification completeness, safety outcome, token cost, latency, and replayability.

## Patterns To Steal

### 1. Workflow Skills With Hard Gates

`superpowers`, `addyosmani/agent-skills`, `anthropics/skills`, and `agentskills` converge on a useful shape: package engineering behavior as activatable skills instead of one monolithic prompt.

Reusable details:

- keep a small always-visible meta-contract that teaches when to load skills;
- make each skill description a trigger contract, not marketing copy;
- split complex work into phase skills: clarify, spec, plan, implement, debug, test, review, verify, finish;
- put long references and scripts outside active context until needed;
- encode verification inside the skill, not as an optional final note;
- evaluate descriptions with positive and negative trigger prompts.

For a Codex-like harness, this improves performance by reducing process-skipping. The model is less likely to jump from vague request to broad edits if the harness forces a stage boundary and evidence requirement.

### 2. Runtime Skill And Tool Routing

`SkillRouter` is the strongest warning: name and description alone are not enough at large scale. Body-aware retrieval and reranking over full skill text materially matter when many skills overlap. `langgraph-bigtool`, `ToolBench`, and `SkillMesh` show the runtime interface shape.

Recommended routing loop:

1. Always expose only `search_skills` or `retrieve_tools`.
2. Hard-filter by project, host, language, file globs, enabled packs, trust, risk, and permissions.
3. Retrieve over compact metadata plus bounded body text.
4. Rerank a candidate window using richer `SKILL.md` bodies, examples, negative triggers, and prior outcomes.
5. Expose only 3-7 candidates to the model.
6. Load full instructions/resources only after activation.
7. Bind execution authority to selected skills/tools, not merely prompt visibility.
8. Re-route on verification failure, missing capability, or task phase change.

Performance gain comes from lowering prompt clutter and false-positive tool use while preserving recall. Safety gain comes only if the execution layer rejects capabilities that were not selected and authorized.

### 3. Typed Context Instead Of Flat Transcript

The context-control synthesis and paper notes point to the same design: long context does not remove the need for explicit context management. A coding harness should maintain separate stores for:

- raw recent turns;
- typed working state;
- evidence ledger;
- retrieved project/code/docs context;
- durable memory;
- compressed summaries;
- branch/subtask fold results.

The `codebase-memory-mcp` note adds a concrete codebase retrieval shape: project-scoped graph search, code search, call tracing, schema discovery, architecture summaries, and snippets with limits. `Context7` adds a narrow resolve-then-query pattern for current library documentation.

Minimum working-state fields:

```text
goal
user_constraints
repo_state
files_touched
commands_run
current_failures
hypotheses_tried
decisions
active_skills
selected_tools
evidence_ids
verification_status
next_actions
```

Performance gain comes from keeping exact error text, paths, diffs, and decisions available after compaction, while avoiding full transcript replay.

### 4. Sandbox As The Execution Boundary

`SWE-agent`, E2B, and Daytona all reinforce that coding agents need a real execution substrate, not just shell access glued onto the host.

Reusable details:

- task instance schema: repo source, base commit, problem statement, environment image, allowed tools, verifier commands;
- fresh workspace or sandbox per run, with reset/clean semantics;
- tool bundles with schemas, executables, install steps, state commands, and docs;
- network policy and secret policy explicit in the run manifest;
- stable output layout: trajectory, patch, logs, test output, exit status, verifier result;
- replay command that can rerun a trajectory or at least reconstruct the run manifest.

For local Codex-like work, the minimum version is not a cloud microVM. It is a controlled workspace lifecycle: know the cwd, branch, dirty state, writable roots, shell permissions, env exposure, network policy, and cleanup behavior. For untrusted code, dependency installs, PR review, or generated execution, use a real sandbox with default-deny network and scoped credentials.

### 5. Verification-First Harness

`SWE-agent`, Playwright, Promptfoo, OpenAI Evals, Kodus, and OpenReview all show that verification must be first-class.

Recommended harness primitives:

- `run_test(command, purpose, expected_signal)` with exact output capture;
- `run_typecheck`, `run_lint`, `run_unit`, `run_integration`, `run_browser`;
- browser verification through Playwright with ARIA snapshots, locator actions, trace links, and failure-only artifacts;
- staged submit/review guard showing cumulative diff before final claim;
- structured findings with severity, evidence, changed-line anchor, confidence, and reproduction/verification command;
- final response gate that refuses "done" unless verification status is known.

Performance gain is mostly fewer false completions. The model may still make coding mistakes, but the harness catches more before the user does.

### 6. Error-Prevention Controls Around Actions

Prompt-injection notes, Shellfirm, Guardrails, Kodus, and OpenReview make the same point: prompt wording is not a safety boundary.

Useful controls:

- taint all repo files, issue text, webpages, logs, package metadata, and generated intermediate text;
- separate untrusted-content reading from privileged editing/action roles when risk is high;
- validate shell commands before execution with rule IDs, severity, context, alternatives, and approval decisions;
- validate paths against workspace roots and file allow/deny lists;
- validate tool arguments with JSON Schema or typed parsers;
- classify generated patches before applying or pushing;
- scan for secrets and prompt-injection markers before sending context to external tools;
- use canaries/leak checks for hidden policy and secrets;
- audit allowed, denied, and approval-gated actions.

These controls improve coding outcomes indirectly: fewer catastrophic branches, fewer irrelevant generated edits, fewer unsafe dependency/script executions, and more trust in automation.

### 7. Domain-Specific Skills With Executable Pipelines

`vercel-labs/agent-skills` is the best example of moving domain expertise from prose to a pipeline. `vercel-optimize` uses signal collection, deterministic gates, candidate briefs, JSON sub-agent outputs, verification, sanitizer passes, and report rendering.

Generalized pattern:

1. collect signals before reading source broadly;
2. gate candidates mechanically;
3. create bounded briefs with allowed files, docs, and output schema;
4. let the model investigate only the candidate scope;
5. collect structured JSON;
6. verify claims against files, docs, metrics, and version constraints;
7. render user output from verified artifacts.

This is a major coding-performance lever for specialized work. The harness should not expect the model to remember every framework rule. It should provide focused, executable domain pipelines.

### 8. Trace And Eval Feedback Loop

OpenAI Evals and Promptfoo provide the reusable evaluation shape. SWE-agent adds coding-agent trajectories and replay. ToolBench and SkillRouter add router metrics.

Minimum metrics:

- task success;
- patch applies cleanly;
- tests passed/failed/skipped;
- verification command coverage;
- skill/tool Recall@K and Hit@K;
- selected-skill false positives;
- context retrieval precision;
- command denial/approval counts;
- invalid tool-call rate;
- token and latency by phase;
- reroute-after-failure rate;
- trace replay success.

The harness should record enough data to answer: did the task fail because the model coded badly, the router missed the right skill, context omitted evidence, a tool failed, a guard blocked action, or verification was insufficient?

## Recommended Codex-Like Harness Architecture

### Control Plane

The control plane owns task state, policy, and run artifacts.

- `task.yaml`: objective, constraints, repo, base ref, sandbox, allowed tools, verifier commands.
- `run-manifest.json`: model, active policies, selected skills, tool versions, environment, budgets.
- `context-state.json`: current typed working state.
- `evidence-ledger/`: exact command outputs, diffs, logs, browser traces, docs snippets, search results.
- `trajectory.jsonl`: model turns, tool calls, observations, policy decisions, context edits, verification events.
- `result.json`: patch status, tests, review findings, safety events, token/latency, final outcome.

### Capability Plane

The capability plane owns skills, tools, MCP servers, and authority.

- `skills.index.json` or SQLite registry with IDs, descriptions, bodies, globs, risks, trust, provenance, budgets, and eval status.
- `search_skills`, `read_skill`, `activate_skill`, `deactivate_skill`, `record_skill_feedback`.
- tool registry with stable IDs, schemas, side-effect class, sandbox requirements, and allowed roots.
- runtime gate that rejects unactivated/unapproved tools even if the model emits their names.

### Context Plane

The context plane owns retrieval and compaction.

- no-compress zones for commands, paths, stack traces, diffs, assertions, user constraints, and verification status;
- project code graph/code search over indexed repositories;
- docs retrieval through resolve-then-query interfaces;
- memory entries with provenance, scope, confidence, and invalidation;
- branch folding for exploratory subwork;
- position-sensitive assembly so critical facts are not buried.

### Execution Plane

The execution plane owns workspace/sandbox and side effects.

- workspace reset/dirty-state detection;
- command safety assessment before shell execution;
- path-contained file reads/writes;
- network egress policy;
- dependency-install policy;
- preview/browser session policy;
- patch extraction and staged submit review;
- cleanup and artifact retention.

### Verification Plane

The verification plane owns correctness evidence.

- project-native tests and typechecks;
- Playwright/browser checks when UI is involved;
- structured review findings;
- guard validators for JSON, commands, patches, SQL, markdown, secrets, and file paths;
- eval harness for regression tasks;
- final completion gate based on evidence, not model assertion.

## Artifact Candidates

- `skills.index.json`: compact registry with routing, risk, provenance, budget, and trust fields.
- `skill-router` MCP/local tool: `search_skills`, `read_skill`, `activate_skill`, `record_skill_feedback`.
- `context-state.json`: typed active task state.
- `evidence-ledger/`: exact raw outputs addressed by stable IDs.
- `command-authority`: shell policy service with allow/deny/approval, context, alternatives, and audit.
- `run-manifest.json`: reproducible task/environment/tool/model/budget manifest.
- `trajectory.jsonl`: replayable trace of model, tool, context, and policy events.
- `tool-bundles/`: schema, executable, install, state, docs, tests for each harness tool.
- `verifier.yaml`: project-specific verification commands and success signals.
- `coding-agent-evals/`: task fixtures with expected files, verifiers, skills, and safety expectations.
- `browser-verification/`: Playwright traces, JSON reports, ARIA snapshots, and locator/action journals.
- `review-findings.schema.json`: severity/evidence/confidence/anchor/fix structure.
- `prompt-injection-control-matrix.md`: taint sources, controls, deterministic validators, failure modes.

## Evaluation Requirements

A serious Codex-like harness should evaluate the harness layers separately before optimizing full task success.

### Router Evals

- positive and negative trigger prompts per skill;
- duplicate/near-miss skill distractors;
- project-local skill precedence over global skills;
- multi-skill full-coverage tasks;
- risk-filter tests where high-risk skills are hidden without approval;
- miss-recovery tests where failed verification triggers rerouting.

Metrics: Recall@50, Hit@1, Hit@3, FullCoverage@K, false-positive activation rate, token cost, latency, authority drift.

### Context Evals

- exact command output survives compaction;
- touched files and line references survive compaction;
- rejected hypotheses are not repeated;
- stale memory is invalidated by newer evidence;
- retrieval returns relevant code/docs without flooding context;
- critical facts are not only placed in the middle of long prompts.

Metrics: context recall, retrieval precision, token savings, compaction failure rate, restored-evidence success.

### Execution And Safety Evals

- destructive command blocked or approval-gated;
- path traversal denied;
- untrusted repo instruction cannot grant itself authority;
- dependency install policy enforced;
- network egress policy enforced;
- patch application respects writable roots and generated-file policy;
- secrets are not exposed in logs or external queries.

Metrics: allow/deny accuracy, false block rate, audit completeness, sandbox escape test result, secret leak checks.

### Coding Outcome Evals

- SWE-style issue tasks with repo snapshots and verifiers;
- project-specific bugfix/regression tasks;
- UI tasks with Playwright traces and reports;
- PR review tasks with seeded defects and expected findings;
- domain-skill tasks with expected candidate scopes and verified outputs.

Metrics: pass rate, patch correctness, test coverage, review precision/recall, rerun reproducibility, artifact completeness.

## Do Not Copy

Do not copy full agent apps or LLMOps platforms when the needed part is a small artifact contract. SWE-agent, Kodus, Promptfoo, E2B, Daytona, and Playwright are valuable pattern sources, but each brings product-specific assumptions.

Do not confuse context gating with permission gating. Showing the model fewer tools does not prevent execution unless the host rejects unselected tools.

Do not rely on prompt-only verification. "Run tests before saying done" must become a final-response gate with actual command evidence.

Do not treat long context as memory. Use retrieval, typed state, evidence IDs, and invalidation.

Do not copy sandbox claims without the sandbox substrate. SDKs and daemons are not isolation by themselves.

Do not let generated traces, browser artifacts, prompts, or repo logs persist forever without redaction and retention policy.

Do not make safety tools fail open silently. If a command-safety config or validator fails, the harness should either preserve last-known-good policy or surface a clear blocked/unknown status.

Do not optimize only final pass rate. Without router/context/tool/safety metrics, a pass-rate change is hard to diagnose.

## Practical Roadmap

### Phase 1: Deterministic Harness Skeleton

- Define `run-manifest.json`, `context-state.json`, `evidence-ledger/`, and `trajectory.jsonl`.
- Add final-response verification gates.
- Add command output and diff evidence IDs.
- Add a small local eval suite from real tasks.

### Phase 2: Skill And Tool Routing

- Build `skills.index.json` from installed skills.
- Add BM25 search plus deterministic filters.
- Add `search_skills` and `read_skill`.
- Add activation telemetry and trigger evals.
- Enforce selected-tool authority in the executor.

### Phase 3: Context And Codebase Memory

- Add project-scoped code search/graph retrieval.
- Add docs resolve-then-query for current library docs.
- Add compaction no-compress zones and recovery tests.
- Add stale-memory invalidation records.

### Phase 4: Safety And Sandbox

- Add command authority with rule IDs, severity, alternatives, and audit.
- Add path/file/network/dependency policies.
- Add sandbox execution for untrusted PRs, dependency installs, and generated code.
- Add secret/log redaction.

### Phase 5: Domain Pipelines And Evals

- Convert high-value domains into `collect -> gate -> brief -> investigate -> verify -> render` skills.
- Add Playwright browser verification for web tasks.
- Add PR review structured findings and verifier passes.
- Feed failures back into router, context, and verifier regression suites.

## Bottom Line

The highest-leverage improvement for a Codex-like harness is not a bigger prompt. It is a measurable operating system for coding tasks: route the right capability, preserve the right evidence, constrain the action surface, verify with real tools, and turn every failure into a replayable regression. The reviewed research is strongest when these pieces are combined; each source alone solves only one slice.
