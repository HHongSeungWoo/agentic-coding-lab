# Runtime Skill Routing At Scale

- Topic: runtime-skill-routing
- Captured at: 2026-05-31
- Status: reviewed synthesis

## Problem

The corrected scope is not skill storage, upload, marketplace search, or installation. The question is runtime use:

How does an agent with 10,000 available skills or tools find the right few, load only the needed context, and execute only what was actually authorized?

The hard parts are:

- first-hop selection when even skill descriptions are too expensive to keep in prompt;
- distinguishing near-duplicate skills whose names and descriptions overlap;
- recovering when the initial router misses;
- keeping exposed context and executable authority in sync;
- pruning selected skills/tools during long sessions;
- learning from false positives, false negatives, and verification outcomes;
- making a skill router work with mutable local/project/user skill corpora.

The main finding is that no reviewed repo fully solves the whole system. The strongest pattern is a layered runtime router: hard filters, cheap retrieval, rich reranking, compact shortlist exposure, explicit full-skill reads, host-side execution gates, and telemetry.

## Source Notes

Direct runtime-routing reviews:

- `zhengyanzhao1997/SkillRouter`: closest match to the 10,000-skill problem. It retrieves and reranks over roughly 80K skills and shows that full skill body text matters. The repo is benchmark/inference code, not a production router.
- `langchain-ai/langgraph-bigtool`: clean LangGraph implementation where the model first sees only `retrieve_tools`, then selected schemas are bound after store retrieval. It lacks hard execution gating and pruning.
- `modelscope/ms-agent`: real skill runtime with hybrid FAISS dense plus BM25 sparse retrieval, LLM filtering, DAG planning, progressive resource loading, and sandbox/local execution. It is not proven at 10K scale and indexes only compact skill metadata.
- `Pro-GenAI/Tool-SEE`: compact proof of concept for top-k tool retrieval plus always-available `search_tools` expansion. It is in-memory full-scan retrieval, not production infrastructure.
- `Ruhal-Doshi/skill-depot`: local MCP search, preview, and full-read loop over Markdown skills. Good progressive disclosure contract, thin ranking and policy.
- `varunreddy/SkillMesh`: practical top-k skill-card router with BM25, optional dense/Chroma, MCP tools, and provider-specific context emitters. Scale evidence is small.
- `LittlePeter52012/skill-router`: tiny one-shot CLI and always-loaded meta-skill. Useful for hundreds of local skills, not a semantic 10K router.
- `OpenBMB/ToolBench`: strong large-pool tool-learning reference over 16K APIs, including retriever training and task evaluation. Research-grade runtime and first-turn-only retrieval.
- `Reason-Wang/ToolGen`: learned alternative to retrieval: represent tools as virtual action tokens, generate the selected token, then load docs. Strong for fixed tool universes, awkward for fast-changing skill libraries.
- `jiajingyyyyyy/AutoTool`: runtime offload for repeated workflows. It predicts next tools from recent trajectories and fills parameters, but it is not first-hop global retrieval.

Supporting reviewed sources:

- `PrefectHQ/fastmcp`: tool search transforms, providers, component visibility, session-aware listing, and auth-aware surfaces.
- `aipotheosis-labs/aci`: semantic function search, schema projection, allowed-only discovery, credential injection, and execution telemetry.
- `SqueezeAILab/TinyAgent`: ToolRAG-style narrowing plus a warning: model-visible tools and executable tools can drift unless the host enforces the same subset.
- `lastmile-ai/mcp-agent`: server allowlists, namespaced MCP tool aggregation, per-request filters, and token accounting.
- `ShishirPatil/gorilla`: BFCL evaluation patterns for relevance, irrelevance, multi-function, and multi-turn tool use.
- The earlier `skill-management-routing` batch remains useful for source governance, install locks, provenance, catalog validation, and marketplace hygiene. It is not the runtime answer by itself.

## Candidate Classes

### Body-Aware Skill Routers

`SkillRouter` is the highest-signal reference. It says the router should use skill bodies, not just name and description, because at large scale many skills are lexically similar but behaviorally different. The transfer to Agent Skills is direct: index `SKILL.md` body text and examples for retrieval/reranking, but expose only a short shortlist to the agent.

The gap is productization. The public code does not include a daemon, persistent ANN index, incremental updates, live activation, permission binding, compaction retention, or feedback loop.

### Host-Mediated Tool Shortlisting

`langgraph-bigtool`, `Tool-SEE`, `skill-depot`, and `SkillMesh` all implement the same useful runtime boundary:

1. Keep a tiny bootstrap tool or router instruction always visible.
2. Search a full catalog outside the model context.
3. Return top-k IDs or compact cards.
4. Let the agent request full details for selected items.
5. Bind or render only the selected capabilities.

These are the most practical repos to copy for interface shape. Their common weakness is that context exposure is easier than authority control. A production system must make "selected" also mean "allowed to execute", not merely "shown in prompt".

### Hybrid Skill Execution Frameworks

`modelscope/ms-agent` is the best reviewed example where selection flows into execution. It does retrieval, LLM filtering, DAG construction, progressive resource loading, and code/script execution. This is closer to real skill use than top-k display alone.

The main issue is scale and retrieval depth. It builds indexes eagerly in process, uses compact metadata for first-stage retrieval, and has no large-library benchmark.

### Large-Pool Eval And Training Bases

`ToolBench` and `ToolGen` are not Agent Skills routers, but they are valuable because they evaluate or train against large tool universes.

`ToolBench` proves the conventional retrieval pattern at 16K API scale: train a retriever, select top-k APIs, expose only those schemas, then measure both retrieval and task success.

`ToolGen` shows a different design: make the model generate a compact activation token from a fixed tool vocabulary and fetch documentation only after selection. This removes retrieval infrastructure at runtime, but new skills are expensive because vocabulary and model weights need updates or continual training.

### Workflow Offload

`AutoTool` should not be treated as a global skill selector. Its value starts after a workflow is already underway. It can skip LLM calls when recent tool sequences and parameter dependencies make the next action predictable.

This fits as a second-stage optimization after retrieval has narrowed the active skill/tool universe.

### Small Local Meta-Routers

`LittlePeter52012/skill-router` is useful for a personal setup where a single always-loaded meta-skill calls a CLI and reads the selected `SKILL.md`. It is easy to deploy and debug.

It should not be oversold. It scans cached frontmatter and reranks only local keyword candidates. It does not prove semantic recall over 10,000 skills.

## Main Finding

The viable design is not "give the model 10,000 skill descriptions" and not "install fewer skills." It is a host-mediated activation protocol.

Recommended shape:

1. Always load only a router contract, not the skill catalog.
2. Build task descriptors from user request, repo facts, current files, host, risk, and explicit mentions.
3. Apply hard filters before semantic ranking: project scope, host compatibility, trust, risk approvals, language, file globs, dependencies, enabled/disabled state, and workspace policy.
4. Retrieve cheaply over compact metadata using BM25 plus dense embeddings.
5. Rerank the top 50-200 candidates with richer text: full `SKILL.md`, examples, negative triggers, schemas, traces, and prior verification outcomes.
6. Expose only 3-7 compact candidates to the model.
7. Provide `read_skill(id)` to load the full selected skill, and optionally `search_skills(query, filters)` for recovery.
8. Bind authority to activation: resources, scripts, tools, MCP servers, and shell permissions should be available only for activated skills unless the user or policy expands scope.
9. Track activation telemetry: query, filters, retrieved set, selected skill, loaded resources, execution result, verification result, missed-skill reports, and token cost.

This combines the strongest ideas from `SkillRouter`, `langgraph-bigtool`, `ms-agent`, `Tool-SEE`, `skill-depot`, `SkillMesh`, ACI, FastMCP, and BFCL-style evals.

## Runtime Algorithm

1. Normalize the task into a routing query.
   Include user request, current repo language, touched files, command intent, risk level, and explicit skill names.

2. Compute the eligible set.
   Remove skills that are disabled, incompatible with the host, outside project scope, stale, untrusted for this workspace, missing required tools, or above current risk approval.

3. Run first-stage retrieval.
   Use BM25 for exact terms and dense embeddings for semantic matches. Index compact metadata plus carefully bounded body slices. Keep enough recall, usually 50-200 candidates.

4. Rerank with richer evidence.
   Use full `SKILL.md` body, examples, input/output contracts, negative triggers, aliases, file globs, dependencies, prior success traces, and duplicate-family information. This is where `SkillRouter` is most important.

5. Return a small shortlist.
   The model should see `id`, name, one-line reason, negative trigger, risk, activation cost, and whether full read is recommended. Do not dump every description.

6. Activate explicitly.
   `read_skill(id)` loads the full skill body. References, scripts, and assets remain resource-level reads unless required by the skill. Activated content should survive compaction as an activation record.

7. Enforce authority.
   A selected skill's allowed tools, resource roots, network needs, shell permissions, and MCP servers should be joined to host policy. Prompt exposure alone is not a security boundary.

8. Re-route on uncertainty or failure.
   If the selected skill fails, if verification contradicts the result, or if the model reports missing capability, search again with the failure evidence added to the query.

9. Learn from outcomes.
   Update telemetry and eval sets. Promote reliable skills, demote noisy duplicates, rewrite weak descriptions, add negative triggers, or block unsafe skills.

## Design Requirements

Minimum production-grade `skill-router` surface:

```text
search_skills(query, filters, top_k, mode) -> compact candidates
read_skill(skill_id, sections?) -> bounded full skill context
activate_skill(skill_id, reason) -> authority token and resource manifest
list_active_skills() -> currently loaded skills and budgets
deactivate_skill(skill_id) -> remove model-facing context and authority
record_skill_feedback(skill_id, outcome, evidence) -> telemetry
```

Minimum routing metadata:

```json
{
  "id": "org.skill-name",
  "name": "skill-name",
  "description": "Short trigger contract",
  "when_to_use": ["specific task patterns"],
  "when_not_to_use": ["near misses"],
  "aliases": ["alternate names"],
  "examples": ["positive routing query"],
  "negative_examples": ["should not route here"],
  "file_globs": ["**/*.py"],
  "languages": ["python"],
  "hosts": ["codex"],
  "risk": "read-only|workspace-write|network|exec|secrets",
  "allowed_tools": ["shell", "web", "mcp:docs"],
  "resources": ["references/", "scripts/"],
  "activation_tokens_estimate": 1200,
  "source_ref": "git url + commit/path",
  "trust": "experimental|reviewed|hardened",
  "status": "enabled|disabled|blocked|stale"
}
```

## Evaluation Harness

A serious router needs evals separate from downstream task success.

Core eval sets:

- positive trigger prompts for every important skill;
- negative trigger prompts for confusing near-misses;
- duplicate/overlap tests where only one skill is correct;
- multi-skill tasks where the expected output is a small set or DAG;
- project-scope tests where global skills should lose to project skills;
- risk tests where high-risk skills should be withheld without approval;
- miss-recovery tests where an initial wrong route should trigger rerouting.

Core metrics:

- Recall@50 before rerank;
- Hit@1, Hit@3, and coverage after rerank;
- false-positive activation rate;
- false-negative rate from human override or verification failure;
- token cost per routing decision and per activated skill;
- latency p50/p95 for 100, 1,000, and 10,000 skills;
- authority drift rate: executable tools not in activated shortlist;
- compaction survival: active skill record still present after context compaction;
- task success delta versus all-tools, no-router, and oracle-skill baselines.

Useful test design comes from `SkillRouter` hard distractors, `ToolBench` retrieval plus execution evaluation, and BFCL relevance/irrelevance and multi-turn function-call tests.

## Do Not Copy

Do not copy registry or marketplace repos as the runtime layer. They solve supply chain and discovery, not per-turn activation.

Do not rely on name and description only. `SkillRouter` is the strongest warning that body text matters in large, overlapping skill pools.

Do not confuse "model only saw top-k" with "host only allows top-k." `langgraph-bigtool`, `SkillMesh`, and TinyAgent-style systems show why prompt narrowing must be paired with executable gating.

Do not make retrieval a one-shot dead end. `ToolBench` is useful, but first-turn-only retrieval is too brittle for long coding tasks.

Do not use in-memory full scans as evidence of production scale. `Tool-SEE` validates interface shape, not 10K deployment.

Do not depend on learned virtual tool tokens for fast-changing personal/project skill libraries unless retraining and versioning are part of the product. `ToolGen` is strongest for fixed or slowly changing tool universes.

Do not let the agent repeatedly call `read_skill` without budget control. Progressive disclosure still needs active budgets and pruning.

## Implementation Bias

For Agentic Coding Lab, the practical starting point is:

1. Build a local SQLite or JSONL registry with strict IDs, provenance, risk, host compatibility, and enabled scopes.
2. Add BM25 first because it is deterministic, local, cheap, and debuggable.
3. Add dense retrieval for semantic recall and use reciprocal rank fusion or weighted fusion.
4. Add reranking over full `SKILL.md` bodies for the top candidate window.
5. Expose an MCP or local tool with `search_skills`, `read_skill`, and `activate_skill`.
6. Enforce authority through host policy, not prompt text.
7. Add evals before adding more skills.

This path borrows the router shape from `skill-depot` and `langgraph-bigtool`, the scale lesson from `SkillRouter`, the execution flow from `ms-agent`, the evaluation style from `ToolBench` and BFCL, and the policy layer from ACI and FastMCP.

## Open Questions

- Should the router be an MCP server, a built-in host primitive, or both?
- What is the right active shortlist size for coding tasks: 3, 5, or 7?
- Should `read_skill` return full Markdown or section-level excerpts first?
- How should duplicate skills be grouped: aliases, families, supersedence, or project precedence?
- What activation evidence is safe to store without leaking project secrets?
- When should a failed verification reroute versus retry the same skill?
- Should high-risk skills be visible in search results before explicit approval?
- How should dynamic user-created skills enter the index without breaking retrieval quality?
