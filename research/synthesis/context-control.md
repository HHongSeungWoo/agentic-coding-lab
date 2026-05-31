# Context Control For Agentic Coding

- Topic: context-control
- Captured at: 2026-05-31
- Status: reviewed synthesis

## Problem

Long-context models do not remove the need for context engineering. The reviewed papers converge on the same failure: long-horizon agents need exact state, recent evidence, long-term facts, retrieval, compression, and execution history, but a flat transcript makes those facts hard to preserve, locate, and verify.

For coding agents, context control is not just token saving. It must preserve:

- current goal and user constraints;
- files touched and why;
- commands run, exact failures, and verification status;
- hypotheses already tested and rejected;
- active skill/tool assumptions;
- project memory and stale-fact invalidations;
- branch/subtask results that should survive compaction.

The strongest design pattern is a typed context operating model: separate raw recent context, durable memory, retrieved evidence, compressed summaries, and serving/runtime cache behavior. Each layer needs explicit budgets, provenance, and regression tests.

## Source Classes

### Agent-Visible Context Actions

`Context as a Tool`, `Context-Folding`, `Memory as Action`, `MEM1`, and `MemAgent` all argue that context should be acted on explicitly rather than passively truncated.

The reusable idea is a host-visible context API:

- write/update/delete memory entries with stable IDs;
- fold exploratory branches and return compact typed results;
- maintain a bounded working state;
- audit context edits as part of the trajectory;
- train or evaluate context policy from task outcomes.

Do not copy the heavy RL setups first. The practical first version should be deterministic and auditable: explicit commands like `write_memory`, `update_state`, `fold_branch`, `restore_evidence`, and `record_context_failure`.

### Memory Architectures

`MemGPT`, `Memory OS`, `Mem0`, and `Evaluating Memory in LLM Agents via Incremental Multi-Turn Interactions` give the memory layer vocabulary.

The useful structure is tiered memory:

- active context: what the model sees now;
- working memory: concise mutable state for the current task;
- episodic/recent logs: raw actions and observations;
- archival memory: searchable durable facts;
- invalidation records: stale facts and superseded decisions.

The main warning is that self-directed memory is not sufficient. Coding agents need host-side schemas, provenance, exact evidence links, and tests for stale-fact overwrite.

### Prompt And Retrieval Compression

`LLMLingua`, `LongLLMLingua`, `LLMLingua-2`, `RECOMP`, and `ACON` show how to reduce context before model calls.

The reusable pattern is not blanket compression. It is measured, source-specific compression:

- compress search/retrieval snippets differently from shell output;
- keep exact commands, paths, code, diffs, stack traces, assertions, and user constraints in no-compress zones;
- use query-aware compression when a task is specific;
- use failure-driven compression regression, as in ACON, before trusting summaries.

Compression should be treated as a behavior-changing component, not formatting cleanup.

### Long-Context Benchmarks

`Lost in the Middle`, `LongBench`, and `LoCoBench-Agent` are most useful as evaluation design sources.

The key lesson from `Lost in the Middle` is that "it was in context" is not a guarantee. Important facts buried in the middle can be ignored. Context assembly should rank, duplicate, or place critical facts deliberately.

`LongBench` contributes length bins, leakage checks, and broad task schemas, but it is not a SWE-agent benchmark.

`LoCoBench-Agent` is the closest direct benchmark for coding agents: multi-turn exploration, semantic search, compression traces, comprehension and efficiency metrics, and 10K-1M token codebase scale. Treat its rankings as a snapshot because the released code includes heuristic metrics and paper/code drift.

### Serving-Side Cache Control

`Attention Sinks`, `SnapKV`, and `PyramidKV` are conditional for Agentic Coding Lab. They operate inside the inference stack, not at the prompt or agent-workflow layer.

They still provide useful design intuition:

- protect a small recent window;
- select older context by task tail or attention signal;
- allocate budgets differently across layers or context regions;
- make retained/dropped context inspectable when possible.

These are most actionable if the lab owns model serving or can configure vLLM/Transformers-style cache policies.

## Recommended Architecture

Build context as layered artifacts, not as one transcript.

1. Raw recent window
   Keep the last few user/assistant/tool turns intact, especially if they include decisions, failing outputs, or edits.

2. Typed working state
   Maintain a compact, schema-backed state record:
   `goal`, `constraints`, `files_touched`, `commands_run`, `current_failures`, `hypotheses`, `decisions`, `pending_risks`, and `next_actions`.

3. Evidence ledger
   Store exact raw evidence by ID: command output, stack traces, search results, diffs, test logs, links, and source snippets. Summaries should cite evidence IDs.

4. Durable memory
   Save only durable facts: project conventions, repeated fixes, user preferences, known environment quirks, and validated lessons. Include provenance, confidence, scope, and invalidation rules.

5. Retrieval layer
   Retrieve evidence and memory into active context by task query, file path, error signature, and current phase. Use exact lexical search for code/errors and semantic search for conceptual facts.

6. Compression layer
   Compress by source type with explicit no-compress zones. Use summaries for narrative and redundant logs, not for exact code, paths, commands, or failure text.

7. Branch folding
   For exploratory subwork, keep full branch transcript off the main path and return a typed result: what was tried, evidence IDs, conclusion, risks, and next recommendation.

8. Context telemetry
   Log what was retained, dropped, compressed, retrieved, and later needed. Turn misses into regression tests.

## Ideas To Steal

- From `Context as a Tool`: context edits should be explicit, auditable tool actions instead of invisible summarization.
- From `Context-Folding`: branch/return boundaries are a better abstraction than summarizing every turn.
- From `Memory as Action`: memory writes/deletes need stable IDs, evidence, and write-before-delete summaries.
- From `MEM1` and `MemAgent`: evaluate memory policies by downstream success, not by summary quality.
- From `MemGPT`: treat active context, working memory, recall, and archival storage as separate tiers.
- From `Memory OS`: use promotion from short-term to mid-term to long-term memory, but attach provenance and staleness controls.
- From `Mem0`: frame memory as a latency/token trade-off and benchmark it against no-memory and full-context baselines.
- From `LLMLingua` family: compression must be selective, query-aware, and guarded by forced-retention rules.
- From `RECOMP`: compress retrieved context before augmentation, but preserve exact references to original evidence.
- From `ACON`: build compression rules from contrastive failures where full context succeeds and compressed context fails.
- From `Lost in the Middle`: place critical facts near high-attention positions and regression-test position sensitivity.
- From `LoCoBench-Agent`: evaluate coding context control with interactive multi-turn tasks, not single-shot QA only.
- From `Attention Sinks`, `SnapKV`, and `PyramidKV`: protect recent context and select older context deliberately when serving-layer control is available.

## Do Not Copy

Do not use generic lossy prompt compressors on raw coding transcripts without hard retention rules. Commands, file paths, line numbers, stack traces, diffs, and failing assertions are not expendable prose.

Do not treat long context as a substitute for retrieval. `Lost in the Middle` shows why buried facts fail even when present.

Do not let the model silently edit its own memory without host-visible logs. Memory edits need IDs, evidence, scope, timestamps, and rollback or invalidation.

Do not copy RL-heavy memory papers as an initial implementation. The first useful product is a deterministic context ledger with tests.

Do not use conversational-memory benchmarks as proof of coding-agent memory quality. Coding needs file/path/error/state-specific evals.

Do not rely on summaries as the only durable artifact. Summaries should point to raw evidence IDs.

Do not mix short-term task state and long-term project memory. Temporary hypotheses should expire; durable conventions should survive.

Do not assume cache/KV papers solve agent context. They solve serving efficiency and local attention retention, not task memory, provenance, or state.

## Artifact Candidates

- `context-state.md` or `context-state.json`: typed working state for the active task.
- `evidence-ledger/`: exact command outputs, diffs, logs, search snippets, and source links addressed by stable IDs.
- `context-events.jsonl`: append-only log of retain/drop/compress/retrieve/fold/memory-write decisions.
- `memory-store.md` plus index: durable project facts with provenance, confidence, scope, and invalidation.
- `context-policy.md`: no-compress zones, source-specific compression rules, retention budgets, and placement rules.
- `branch-fold.md`: template for subtask return messages with evidence IDs and unresolved risks.
- `context-regression/`: tests where full context succeeds but compressed/retrieved context previously failed.
- `position-sensitivity-evals/`: checks that critical facts remain recoverable when context grows.
- `memory-staleness-evals/`: tests for overwriting old facts and resisting stale memories.
- `compression-audit.md`: record of compressor version, dropped fields, token savings, and downstream outcome.

## Evaluation Requirements

Minimum eval suite for Agentic Coding Lab context control:

- command-output retention: exact error text remains available after compression;
- file/path retention: touched files and line references survive compaction;
- stale-memory overwrite: old project facts are superseded by newer evidence;
- rejected-hypothesis memory: agent does not repeat failed approaches after compaction;
- retrieval precision: memory search returns relevant evidence IDs without flooding context;
- long-session recovery: after synthetic compaction, agent can continue from typed state;
- branch folding: exploratory branches return enough evidence to justify next action;
- position sensitivity: critical facts are not buried only in the middle of long prompts;
- token/latency accounting: context policy reduces cost without lowering task success;
- safety retention: user constraints and destructive-operation decisions are never compressed away.

## Practical Starting Point

For this repo, the next useful build target is not a learned memory agent. It is a small context ledger:

1. Define the working-state schema.
2. Save exact evidence IDs for commands, diffs, and search results.
3. Add source-specific compression rules with no-compress zones.
4. Add `fold_branch` and `restore_evidence` conventions.
5. Add regression tasks from real failures.
6. Only after deterministic policies work, evaluate learned compression or memory-update policies.

That path captures most of the practical value from the reviewed papers while avoiding the highest-risk assumptions.
