# zhengyanzhao1997/SkillRouter

- URL: https://github.com/zhengyanzhao1997/SkillRouter
- Category: tool-use
- Stars snapshot: 161 (GitHub REST API, captured 2026-05-31); index row was 158 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: c8d3a24ec19da2e60bd4af65948bfe2dfcd02581
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal runtime skill-routing release. It directly addresses the "10,000+ skills without context blow-up" problem with a full-text retrieve-and-rerank pipeline over roughly 80K skills. The public repo is an evaluation/inference release, not a production router: it does not include training scripts, a persistent ANN service, live `SKILL.md` activation, execution-authority binding, telemetry, or a host integration.

## Why It Matters

This is the closest current repo to the actual runtime problem: how an agent should find the right few skills from a very large pool without loading every skill description into context. The paper and repo argue that name and description are not enough at 80K scale because many skills share surface wording while differing in implementation details. The important design move is that the router can inspect full skill text offline or in a side channel, while the downstream agent receives only a small ranked shortlist.

For Agentic Coding Lab, this reframes skill loading: the solution is not "better descriptions for 10,000 skills." It is a retrieval system over full `SKILL.md` bodies plus a narrow activation interface such as `search_skills`, `read_skill`, and top-k skill visibility.

## What It Is

SkillRouter is a public release for the paper "SkillRouter: Skill Routing for LLM Agents at Scale" (arXiv:2603.22455, v4 revised 2026-04-01). The repository contains:

- lightweight benchmark metadata under `data/eval_core`;
- Python inference/evaluation scripts under `src`;
- shell wrappers for downloading Hugging Face dataset shards and running the released models;
- links to the released `SkillRouter-Embedding-0.6B` and `SkillRouter-Reranker-0.6B` models;
- links to the `pipizhao/SkillRouter-Eval-Core` dataset.

The evaluation pool is not stored in Git. Hugging Face metadata and the local manifest report `easy` with 78,361 candidate skills and `hard` with 79,141 candidate skills. The scored benchmark uses 75 core tasks from 87 total tasks, excluding `generic_only` cases. The hard tier adds 780 LLM-generated distractor skills that are topically plausible but functionally wrong.

The skill records are shaped for retrieval: `skill_id`, `name`, `description`, `body`, and `source`. That maps well to `SKILL.md` if we treat frontmatter name/description as compact metadata and the markdown body as the high-value routing signal.

## Research Themes

- Token efficiency: Strong. The router retrieves and reranks from roughly 80K skills while exposing only a ranked list, avoiding global description loading. Public defaults retrieve top-50 for export and rerank top-20 for the end-to-end pipeline.
- Context control: Strong. The core hidden-body asymmetry is exactly the needed pattern: the router can use skill bodies, but the agent does not receive all bodies. The repo stops at ranked IDs rather than a host-facing context-injection policy.
- Sub-agent / multi-agent: Limited. The paper reports end-to-end gains across four coding agents, but the repo has no multi-agent orchestration or delegation code.
- Domain-specific workflow: Strong for coding and technical skills. The benchmark spans many domains and stresses function-level distinctions, but one paper case shows weakness on specialized multi-skill engineering tasks.
- Error prevention: Strong for routing errors, not execution errors. Hard negatives, hard-tier distractors, relevance labels, and coverage metrics target wrong-skill selection. There is no guard that prevents execution of unselected skills.
- Self-learning / memory: Weak in the public repo. The paper describes synthetic training data and false-negative filtering, but there is no runtime feedback, telemetry, or online update loop.
- Popular skills: Not a popularity catalog. The value is the routing/evaluation recipe over large skill pools, not a curated list of best skills.

## Core Execution Path

The runnable path is `scripts/evaluate_open_models.sh` -> `python3 -m src.run_open_model_eval`.

1. `scripts/download_eval_data.sh` downloads `tasks.jsonl`, `relevance.json`, and `easy/*.jsonl.gz` / `hard/*.jsonl.gz` from `pipizhao/SkillRouter-Eval-Core`.
2. `src.run_open_model_eval` loads the embedding model and reranker from Hugging Face by default.
3. Tasks are loaded from `data/eval_core/tasks.jsonl`; labels are loaded from `relevance.json`.
4. Queries are formatted with an instruction prefix and truncated to 2,000 characters.
5. For each tier, all pool skills are loaded from JSONL or JSONL.GZ shards. Pool text is formatted as `name | description | body`.
6. The embedding model encodes queries and pool texts, normalizes embeddings, and computes cosine similarity with `query_embs @ pool_embs.T`.
7. Retrieval keeps the top `retrieval_top_k`, default 20 in the open-model pipeline. `src.export_retrieval` separately defaults to top-50.
8. The reranker builds a query-document prompt for each candidate and scores the final token logits for `yes` versus `no`.
9. Candidates are sorted by reranker score, and both retrieval and reranked JSON prediction files are written.
10. Metrics are aggregated for `all`, `single`, and `multi` task strata.

Important implementation detail: the repo says "full skill text," but the public scripts use bounded text. Retrieval passes `desc_max=500` and `body_max=8000` characters in `run_open_model_eval`; reranking defaults to `body_max=2000` characters inside `format_rerank_prompt`; both stages also have tokenizer `max_length=4096`. The body is clearly used, but this is not an unbounded full-body read for very large skill files.

## Architecture

The architecture is a two-stage information retrieval pipeline:

- Offline or batch side: encode each skill as text built from name, description, and body.
- Online query side: encode the user task, retrieve the most similar skills, then rerank a small candidate set with a cross-encoder.
- Evaluation side: compare ranked skill IDs with expert relevance labels using retrieval and coverage metrics.

The public implementation uses brute-force matrix similarity in memory. The paper describes approximate nearest-neighbor retrieval as part of the serving path, but the repo does not include a FAISS/HNSW/index service, persisted embeddings, incremental index updates, or a daemon/API. `src.data_io` can stream JSONL/GZ paths, but `run_open_model_eval` loads full pools into lists before encoding.

The released models are standard Hugging Face Transformers:

- `pipizhao/SkillRouter-Embedding-0.6B`: Qwen3 embedding fine-tune, 595,776,512 BF16 parameters, feature-extraction pipeline.
- `pipizhao/SkillRouter-Reranker-0.6B`: Qwen3 reranker fine-tune, 595,776,512 BF16 parameters, text-ranking/cross-encoder role.

## Design Choices

The most important choice is to make the router body-aware while keeping the agent context small. SkillRouter tests the common progressive-disclosure assumption and finds that name+description routing is fragile in large overlapping pools. The paper reports 31 to 44 percentage point Hit@1 drops when skill bodies are removed across sparse, dense, and reranking baselines.

The second major choice is top-20 reranking. The encoder handles large-pool recall, while the reranker spends more expensive cross-encoder capacity on a small shortlist. This is directly reusable for `SKILL.md`: retrieve from all installed/enabled skills, rerank a candidate window with full markdown bodies, then expose only a few activated skills to the agent.

The paper's training recipe matters even though it is not implemented in this repo. It fine-tunes the 0.6B encoder on 37,979 synthetic query-skill pairs, mines 10 negatives per query from semantic, lexical, taxonomy, and random sources, filters likely false negatives, then trains the 0.6B reranker with 32,283 top-20 candidate lists and listwise cross-entropy. The false-negative handling is especially relevant because large skill registries contain duplicates and near-duplicates.

The evaluation intentionally separates Easy and Hard tiers. Easy measures large-pool retrieval. Hard adds plausible distractors to stress ambiguous and overlapping skills. That is a useful test shape for our own skill registry because duplicate and over-general skills are the real failure mode.

## Strengths

SkillRouter is purpose-built for runtime skill routing rather than registry management. It answers the user's exact concern: many available skills should be searched by a router, not listed in the model prompt.

The empirical claim is concrete. The benchmark has roughly 80K candidates, 75 scored expert-verified tasks, single-skill and multi-skill labels, and metrics beyond top-1. The HF dataset page confirms the released row counts and fields, and the repo's local manifest mirrors those counts.

The body-access result is highly actionable. Full `SKILL.md` bodies should be indexed and reranked even if the model sees only short activation summaries. Description-only routing is not enough once many skills overlap.

The 0.6B + 0.6B pipeline is a practical size target. The paper reports 74.0% average Hit@1 and 70.4% average Recall@10 for the compact pipeline, and a serving benchmark with 495.8 ms p50 latency and 871.4 ms p95 latency for the 1.2B pipeline's online path. That excludes model loading, offline pool embedding, and index construction, but it shows the shape is not inherently enterprise-only.

The benchmark includes multi-skill tasks and coverage metrics, which are essential for coding agents. A task may need five skills, not just the best-looking one.

## Weaknesses

The repo is not a production router. It has no long-running service, no persisted vector index, no incremental reindexing, no `search_skills` API, no `read_skill` API, and no agent integration.

The public repo does not include the training pipeline. Hard-negative mining, false-negative filtering, listwise reranker training, synthetic query generation, and duplicate handling are described in the paper but not shipped as runnable code.

The execution-authority boundary is absent. The pipeline outputs ranked `skill_id` lists. It does not ensure that an agent can only execute tools/resources associated with the selected skills, nor does it define how to expand the shortlist safely after a miss.

The public scripts are evaluation-oriented and memory-heavy. They load pools, encode all pool texts in a run, and compute a full similarity matrix. This is fine for reproduction, but it is not the serving architecture we would deploy.

The "full body" story needs qualification. Body text is the decisive signal, but the public code truncates bodies by characters and model context length. For real `SKILL.md` trees with references/scripts/assets, we need a chunking and resource-expansion strategy rather than one flat string.

The core benchmark is small in query count. Seventy-five scored tasks are useful for routing analysis, but not enough to prove production reliability across a personal or organization-specific skill inventory.

Multi-skill recovery remains imperfect. The compact pipeline improves top-1 routing, but Recall@10 around 70% means downstream agents can still miss required skills for compound tasks. A production router needs fallback expansion, uncertainty signals, and telemetry from failed executions.

## Ideas To Steal

Build a runtime skill router around three representations: compact metadata for cheap filtering, full `SKILL.md` body text for retrieval/rerank, and separately lazy-loaded resources/scripts for execution-time help.

Use a staged shortlist: hard filters first, cheap retrieval over all enabled skills next, then a richer reranker over a candidate window. Do not ask the LLM to choose from thousands of descriptions.

Evaluate metadata-only versus body-aware routing in our own skill corpus. If body-aware routing wins, keep descriptions short and spend effort on high-quality body structure, examples, negative triggers, and references.

Create hard distractor tests. For every skill, generate or mine same-domain alternatives that look plausible but do the wrong thing. Measure whether the router selects the functionally correct skill, not just a related skill.

Track multi-skill coverage. Hit@1 is not enough for coding workflows. Use Recall@K and FullCoverage@K for tasks that require several skills.

Add false-negative and duplicate handling to any training/eval set. Skill registries naturally contain equivalent or near-equivalent skills; treating all non-gold skills as wrong will corrupt training and metrics.

Expose only a small activated set to the agent, but keep a `read_skill(id)` expansion path. A good target is top 3 to 7 visible skills, with the router allowed to expand from a top-20 or top-50 candidate window when confidence is low.

Tie authority to selection. The selected shortlist should gate which skill resources, helper scripts, MCP tools, or commands become available. Otherwise retrieval improves context but not safety.

## Do Not Copy

Do not copy the repo as a serving implementation. It is a benchmark runner, not a deployable router.

Do not rely on name and description as the only routing fields. SkillRouter's strongest lesson is that this fails under overlap.

Do not flatten arbitrarily large skill folders into one truncated string without measuring what was lost. `SKILL.md` bodies, references, examples, scripts, and tool schemas may need separate indexes or chunk-level evidence.

Do not treat top-1 success as enough. Coding tasks often need multiple skills, and the paper's own examples include cases where missing a specialized secondary skill hurts downstream execution.

Do not leave execution authority broader than the routed shortlist. The router should reduce both prompt context and available action surface.

Do not assume the published training gains are reproducible from this repo alone. The most important training components are paper-described but not shipped.

## Fit For Agentic Coding Lab

Fit is very high for the runtime-skill-routing track. SkillRouter gives a concrete architecture for scaling from dozens of skills to tens of thousands:

1. Maintain a machine-readable skill index with `id`, namespace, host compatibility, trust policy, description, body hash, and body text.
2. Use deterministic filters for workspace, host, language, trust, permissions, and file globs.
3. Retrieve over name, description, and body for all enabled skills.
4. Rerank a top-20 or top-50 candidate set using richer bodies and examples.
5. Expose only a top 3 to 7 shortlist to the agent.
6. Provide `read_skill(id)` for lazy loading and `expand_skill_search(query, reason)` for misses.
7. Restrict resources/tools/scripts to selected skills unless the router expands the shortlist.
8. Log activations, misses, manual overrides, duplicate conflicts, and verification outcomes for pruning and retraining.

This repo should be a core reference for our runtime router design, but it needs to be paired with registry/install systems such as `agent-skills`, `asm`, or `skillhub` for governance and with an agent host integration for actual activation.

## Reviewed Paths

- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/README.md`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/common.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/run_open_model_eval.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/export_retrieval.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/evaluate_predictions.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/metrics.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/src/data_io.py`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/data/eval_core/README.md`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/data/eval_core/manifest.json`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/data/eval_core/tasks.jsonl`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/data/eval_core/relevance.json`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/evaluation/README.md`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/scripts/download_eval_data.sh`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/scripts/evaluate_open_models.sh`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/scripts/evaluate_predictions.sh`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/requirements.txt`
- `/tmp/myagents-research/zhengyanzhao1997-skillrouter/Makefile`
- GitHub REST API metadata for `zhengyanzhao1997/SkillRouter`
- Hugging Face API/page metadata for `pipizhao/SkillRouter-Eval-Core`
- Hugging Face API/page metadata for `pipizhao/SkillRouter-Embedding-0.6B`
- Hugging Face API/page metadata for `pipizhao/SkillRouter-Reranker-0.6B`
- arXiv abstract and HTML for `2603.22455`

## Excluded Paths

- `assets/readme/pipeline.png`: visual overview only; README and code contain the actionable pipeline details.
- Full Hugging Face dataset shards under `easy/` and `hard/`: not downloaded because the dataset API, local manifest, and HF viewer already establish row counts and field shape, and the full dataset is about 803 MB.
- Hugging Face model weights: not downloaded because the review targets architecture and code path, and model metadata confirms parameter counts and base models.
- Full open-model evaluation: not run because it requires downloading dataset shards and model weights and is CUDA-oriented. Python syntax verification was run with `rtk python -m compileall src`.
- Upstream source repos `benchflow-ai/skillsbench` and `majiayu000/claude-skill-registry`: API metadata was checked for provenance context, but those repos were not deep-reviewed as part of this owned note.
