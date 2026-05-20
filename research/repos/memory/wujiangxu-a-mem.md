# WujiangXu/A-mem

- URL: https://github.com/WujiangXu/A-mem
- Category: memory
- Stars snapshot: 888 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 0c8039f28fdcc08189a23c07a3437d9d2482f9c2
- Reviewed at: 2026-05-19T23:27:14+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful in-scope reproduction repo for the NeurIPS 2025 A-Mem paper, especially for seeing the actual LoCoMo evaluation path, note construction prompts, LLM-directed link/update decisions, retrieval-k tuning, and a later robust plain-text parser variant for non-OpenAI backends. It is not a production memory substrate: storage is in-process plus pickle/NumPy caches, privacy and scope controls are absent, LLM calls can expose raw conversation memory, and the scripts are tied to local research environments.

## Why It Matters

`WujiangXu/A-mem` is the paper-reproduction side of A-Mem rather than the packaged `agiresearch/A-mem` memory library. That makes it useful for a different question: what did the authors actually run to test agentic memory on long-term conversation QA, and what operational compromises were needed to support OpenAI, vLLM, SGLang, and Ollama backends?

For Agentic Coding Lab, the core value is the memory update pattern. Each incoming interaction becomes a structured note with content, timestamp, context, keywords, tags, and links. The system retrieves nearby memories, asks an LLM whether to strengthen links or update neighbors, and later answers questions from a bounded retrieved memory context. This is directly relevant to coding-agent memory for durable project lessons, repeated failures, user preferences, and linked decisions.

## What It Is

A-Mem is a Python research implementation for the NeurIPS 2025 paper "A-Mem: Agentic Memory for LLM Agents" (arXiv:2502.12110). The README says this repo is specifically for reproducing paper results and points production users to `WujiangXu/A-mem-sys`.

The repo contains two memory/evaluation variants. `memory_layer.py` and `test_advanced.py` are the original JSON-schema-based pipeline. `memory_layer_robust.py`, `llm_text_parsers.py`, and `test_advanced_robust.py` are a later robust pipeline that removes strict JSON schema dependency and supports OpenAI, vLLM, SGLang, and Ollama through plain-text section markers and parsers.

The checked-in dataset is `data/locomo10.json`, a 10-sample LoCoMo subset. Shell scripts run full robust experiments and retrieval-k sweeps on the authors' local GPU paths. There is no package metadata, server, MCP layer, auth system, persistent database, or unit-test suite beyond the evaluation scripts.

## Research Themes

- Token efficiency: Strong idea value. Paper results and scripts retrieve bounded top-k memory snippets instead of prompting with full conversations, with reported A-Mem contexts around 1,100-2,500 tokens versus roughly 16,900 for full-context LoCoMo/MemGPT baselines. The code has a `retrieve_k` parameter and k-sweep script, but no general token-budget allocator or truncation guard.
- Context control: Moderate for retrieval volume, weak for boundaries. The system stores timestamp, context, keywords, tags, and links, and retrieves by generated query keywords. It has no user/project/agent/run scope, no metadata filter API, no namespace isolation, and no policy layer for cross-session memory.
- Sub-agent / multi-agent: Low. The memory system can point different LLM backends at the same evaluation logic, but it does not coordinate agents, isolate agent identities, or resolve competing memory updates.
- Domain-specific workflow: Moderate. The domain is long-term conversational QA on LoCoMo. The pipeline parses sessions, image captions, QA categories, adversarial questions, metrics, and category-specific answering prompts. There are no coding-agent adapters, repository schemas, or tool-trace memory types.
- Error prevention: Mixed. The robust variant adds retries, backend connectivity checks, parser fallbacks, heuristic repairs, and graceful storage without evolution if evolution fails. The original path has fragile JSON parsing, silent empty responses for some backend errors, pickle cache loading, hard-coded local script paths, and no deterministic tests for memory evolution correctness.
- Self-learning / memory: Strong concept, research-grade execution. The main mechanism is LLM-mediated note evolution: new memories can create links to nearby memories and update neighbor context/tags. It does not have durable audit history, contradiction handling, deletion, retention, or provenance beyond raw note fields and eval logs.
- Popular skills: Useful patterns include Zettelkasten-style note memory, LLM-generated metadata, explicit link generation, neighbor metadata evolution, robust section-marker parsing, retrieval-k sweeps, and LoCoMo-style long-horizon memory evaluation.

## Core Execution Path

The original path starts in `test_advanced.py`. `advancedMemAgent` creates an `AgenticMemorySystem` plus a second `LLMController` for query generation. `evaluate_dataset()` loads `data/locomo10.json`, loops through each sample's conversation sessions, converts each turn into text like `Speaker <name>says : <text>`, and calls `agent.add_memory(..., time=<session date>)`.

`AgenticMemorySystem.add_note()` builds a `MemoryNote`. If metadata is missing, the note calls `MemoryNote.analyze_content()`, which asks the configured LLM for keywords, one-sentence context, and tags using strict JSON schema. Then `process_memory()` retrieves five nearest existing memories with `SimpleEmbeddingRetriever`, formats their content/context/keywords/tags into a text block, and asks the LLM whether the new note should evolve.

If the LLM chooses `strengthen`, the system appends returned neighbor indices to the new note's `links` and replaces tags. If it chooses `update_neighbor`, it mutates the context and tags of retrieved existing memories. The note is then saved in `self.memories`, and a searchable string containing content, context, keywords, and tags is added to the sentence-transformer retriever. Every `evo_threshold` successful evolutions, `consolidate_memories()` rebuilds the retriever from current memory metadata.

At QA time, `answer_question()` asks the LLM to turn the question into keywords, retrieves top-k memories plus linked neighbors through `find_related_memories_raw()`, and prompts the same memory LLM to answer from that context. Category 2 adds date guidance, category 5 turns adversarial questions into a two-choice prompt, and metrics are computed by `utils.py`.

The robust path mirrors this flow. `RobustMemoryNote` uses plain-text prompts in `llm_text_parsers.py`; `RobustAgenticMemorySystem.process_memory()` splits evolution into up to three calls: decision, strengthen details, and neighbor updates. Parser functions first try JSON, then fall back to section markers, then repair empty metadata heuristically. If evolution fails, the robust system stores the new memory without evolution instead of aborting the whole run.

Both eval scripts cache built memories as pickle files plus retriever state as pickle and `.npy` embeddings under generated `cached_memories_*` directories. Subsequent runs reuse memory caches and only rerun QA answering. Output JSON files contain aggregate metrics and individual predictions; logs include prompts and raw retrieved context.

## Architecture

The runtime data model is `MemoryNote` or `RobustMemoryNote`. A note contains raw content, UUID, keywords, links, importance score, retrieval count, timestamp, last accessed time, context, evolution history, category, and tags. In practice, links are list indices into the in-memory note order rather than stable external IDs.

The active store is a Python dictionary plus an in-memory sentence-transformer retriever. `self.memories` is the source of truth for note objects. `SimpleEmbeddingRetriever` stores a corpus list and NumPy embeddings from `all-MiniLM-L6-v2`, then performs cosine similarity search. `HybridRetriever` exists with BM25 plus embeddings, save/load helpers, and incremental update methods, but the active `AgenticMemorySystem` path uses `SimpleEmbeddingRetriever`.

The LLM layer has controllers for OpenAI, Ollama through LiteLLM, SGLang direct HTTP, and robust vLLM OpenAI-compatible HTTP. The original controllers require `response_format` schemas and return empty schema-shaped responses on some backend errors. The robust controllers drop `response_format`, use plain prompts, add retries, and optionally check connectivity.

The evaluation layer handles LoCoMo parsing, memory ingestion, QA prompting, cache reuse, metric calculation, logging, and output writing. `load_dataset.py` preserves image turns by replacing image URLs with BLIP captions when available. `utils.py` computes exact match, F1, ROUGE, BLEU, BERTScore, METEOR, and SBERT similarity.

The paper artifact aligns with the code: note construction generates contextual descriptions/keywords/tags, link generation retrieves top-k candidate memories before LLM analysis, memory evolution updates neighbor metadata, and retrieval uses top-k memory snippets for question answering. The paper appendix also shows prompt templates and k settings, while this repo implements those prompts with more backend-specific details.

## Design Choices

A-Mem chooses atomic note memory rather than raw context replay. Every turn becomes a note, and the model-generated metadata is meant to make later retrieval and linking richer than content-only embeddings.

The most distinctive choice is LLM-directed evolution over retrieved neighbors. The system does not define fixed graph schemas or deterministic relation types. It asks the LLM whether to link the new note, update neighbors, both, or neither.

Retrieval is intentionally simple. The active path uses dense embeddings over a string that joins content and metadata. Links expand retrieved memories at answer time, but there is no graph database, relation traversal query language, or separate keyword candidate source.

The robust branch prefers portability over strict schema enforcement. Section markers and repair heuristics make local models easier to use, but they also weaken validation and can hide low-quality LLM output.

The experiment scripts prioritize reproduction throughput. They cache expensive memory construction, sweep retrieval `k`, launch vLLM servers, and run models in parallel. That is practical for research, but it bakes in local filesystem paths, GPU IDs, and log/cache conventions.

## Strengths

The repo makes the paper's memory loop concrete. It is possible to trace note construction, candidate retrieval, link/update decisions, cache creation, QA retrieval, and metric aggregation end to end.

The note schema is useful for agentic coding memory. Content plus context, keywords, tags, timestamps, and links gives a reviewable middle ground between raw logs and opaque vectors.

The robust parser layer is a practical adaptation. It recognizes that strict JSON schema support is uneven across model backends and adds retries, JSON-or-text parsing, and heuristic fallback.

The k-sweep workflow is valuable. It treats memory retrieval count as a task/model-specific parameter and makes the token-quality tradeoff explicit.

The paper and repo together provide useful evaluation framing. LoCoMo categories map well to memory capabilities: single-hop recall, multi-hop synthesis, temporal reasoning, open-domain grounding, and adversarial "not in memory" behavior.

## Weaknesses

This is not a durable memory system. Notes live in process memory during a run and are cached with pickle for experiments. There is no database, migration story, scoped retrieval API, service boundary, restart-safe mutation log, or memory deletion lifecycle.

Privacy and safety controls are absent. Raw conversation turns, generated memory metadata, prompts, raw retrieved context, pickle caches, and result logs can contain sensitive data. The code sends note content and neighbor memory content to external LLM APIs unless the user chooses a local backend. There is no redaction, encryption, consent, retention, auth, tenant isolation, audit policy, or secret filtering.

The original path is fragile. It depends on strict JSON schema behavior, has a JSON parsing fallback that references an undefined exception variable inside `analyze_content()`, and some backend controllers silently return empty schema-shaped objects on errors.

Memory links are weakly typed. Returned connections are indices, not stable IDs with validation and provenance. If note order or retrieval ordering changes, links can become hard to reason about.

Index consistency is loose. Neighbor updates mutate in-memory notes, but the retriever only sees updated metadata after consolidation. With the default threshold, many updates can sit outside the retrieval index.

There are no focused unit tests. Files named `test_advanced*.py` are full evaluation scripts, not small tests of parsing, note construction, link validation, cache loading, or evolution update correctness. `requirements.txt` lists `pytest`, but no pytest suite is present.

The shell scripts are not portable as-is. They contain absolute paths under `/common/users/wx139/...`, fixed GPU assignments, local environment names, and direct process killing by port.

## Ideas To Steal

Use structured, reviewable memory notes for coding-agent lessons. A note should expose raw source, generated summary/context, keywords, tags, timestamps, links, and confidence rather than only embedding vectors.

Make memory evolution explicit. Split actions into "store new note", "link to existing notes", and "update existing note metadata" so each operation can be logged and tested.

Retrieve a small neighbor set before asking the LLM to evolve memory. This bounds cost and keeps evolution decisions grounded in nearby evidence.

Treat retrieval `k` as an eval parameter, not a constant. Coding tasks may need different `k` for build errors, architecture questions, dependency quirks, and user preferences.

Use robust section-marker parsers for local models, but keep a strict validation layer around IDs, allowed actions, and output sizes.

Cache expensive memory construction separately from answer-time retrieval in eval harnesses. This makes memory experiments cheaper and lets teams sweep recall parameters without rebuilding memory.

Adapt the LoCoMo-style category split for coding memory evals: single fact recall, multi-step relation recall, temporal/staleness checks, open-domain plus repo grounding, and adversarial "not known" checks.

## Do Not Copy

Do not store private coding-agent memory as raw pickle files and unredacted logs. Use scoped storage, encryption or local-only policy where needed, and explicit deletion/retention.

Do not send raw source-code logs, user preferences, or secrets to external LLMs for memory extraction by default. Local extraction or a redaction/consent gate should be the default for repo memory.

Do not use list indices as durable memory links. Use stable note IDs, validate returned links, and record why a link was created.

Do not let memory metadata update without updating the search index or recording that the index is stale.

Do not hide LLM failures by returning empty metadata. Failed extraction should be observable and retriable, especially when memory quality affects future agent behavior.

Do not copy the environment-specific experiment scripts into a shared lab harness. Replace absolute paths, hard-coded GPUs, and unmanaged server lifecycles with configurable runners.

Do not treat paper benchmark performance as direct evidence for coding-agent memory. Recreate a task-specific eval with code, tools, commands, failures, fixes, and privacy boundaries.

## Fit For Agentic Coding Lab

Fit is high as a research pattern and moderate as implementation source. The repo shows how an A-Mem-style agentic memory pipeline behaves under real long-conversation QA evaluation, and the robust variant offers practical parser ideas for local model backends.

The best adaptation is a corrected note graph for coding agents: repo-scoped durable notes, stable IDs, source/provenance fields, privacy classes, validated links, bounded linked recall, local-first extraction, update logs, and deterministic tests around evolution decisions.

For Agentic Coding Lab, this repo is especially useful as a reminder that memory quality is an execution-path property, not just an architecture diagram. Every claimed memory operation should have a reproducible test: ingest, extract, link, update, retrieve, answer, delete, and reject unrelated/adversarial recall.

## Reviewed Paths

- `/tmp/myagents-research/wujiangxu-a-mem/README.md`: repo purpose, paper link, official implementation pointer, setup, robust evaluation usage, k-sweep guidance, and citation.
- `/tmp/myagents-research/wujiangxu-a-mem/memory_layer.py`: original LLM controllers, note schema, metadata generation, embedding retriever, evolution prompt, add/consolidate/retrieve paths, and ad hoc tests.
- `/tmp/myagents-research/wujiangxu-a-mem/memory_layer_robust.py`: robust controllers, retries, connectivity check, robust note construction, plain-text evolution calls, graceful fallback, and retrieval behavior.
- `/tmp/myagents-research/wujiangxu-a-mem/llm_text_parsers.py`: plain-text prompts, section-marker parsers, JSON fallback, keyword/context/tag repair, answer parsing, and update-neighbor parsing.
- `/tmp/myagents-research/wujiangxu-a-mem/test_advanced.py`: original LoCoMo evaluation flow, cache creation/loading, query generation, QA prompts, logging, output writing, and metric aggregation.
- `/tmp/myagents-research/wujiangxu-a-mem/test_advanced_robust.py`: robust evaluation flow for OpenAI, Ollama, SGLang, and vLLM without strict JSON schema.
- `/tmp/myagents-research/wujiangxu-a-mem/load_dataset.py`: LoCoMo dataclasses, session parsing, image-caption handling, QA category handling, and dataset statistics.
- `/tmp/myagents-research/wujiangxu-a-mem/utils.py`: exact match, F1, ROUGE, BLEU, BERTScore, METEOR, SBERT similarity, and aggregate metrics.
- `/tmp/myagents-research/wujiangxu-a-mem/run_all_experiments.sh`: robust multi-model experiment launcher, vLLM startup, OpenAI parallel evals, GPU assumptions, logs, and metric summary.
- `/tmp/myagents-research/wujiangxu-a-mem/run_k_sweep.sh`: retrieval-k sweep workflow, cached-memory reuse, vLLM lifecycle, and result summarization.
- `/tmp/myagents-research/wujiangxu-a-mem/requirements.txt`: dependency surface for embeddings, LLM clients, evaluation metrics, and listed pytest dependency.
- `/tmp/myagents-research/wujiangxu-a-mem/data/locomo10.json`: sampled to verify LoCoMo QA/session structure; full 66,750-line dataset was not line-by-line reviewed.
- `https://arxiv.org/abs/2502.12110` and `https://ar5iv.labs.arxiv.org/html/2502.12110v11`: NeurIPS 2025 paper metadata, methodology, results, limitations, appendix prompts, and k hyperparameters.

## Excluded Paths

- `/tmp/myagents-research/wujiangxu-a-mem/.git/`: VCS internals; exact reviewed commit is recorded separately.
- `/tmp/myagents-research/wujiangxu-a-mem/Figure/intro-a.jpg`, `/tmp/myagents-research/wujiangxu-a-mem/Figure/intro-b.jpg`, and `/tmp/myagents-research/wujiangxu-a-mem/Figure/framework.jpg`: binary presentation figures. The README and paper captions were used to understand claims, but image pixels were excluded from implementation analysis.
- Generated runtime outputs that scripts would create, including `logs/`, `cached_memories_advanced_*`, `cached_memories_robust_*`, `results_robust_*.json`, and `results_k_sweep/`: not present in the clean checkout and excluded as generated evaluation artifacts.
- Local virtual environments, model caches, NLTK downloads, sentence-transformer caches, vLLM/SGLang server logs, and Python bytecode caches if generated by running experiments: generated environment artifacts, not repo design.
- No vendored third-party source, generated SDK, notebook output, or UI-only application code was present in the reviewed checkout.
