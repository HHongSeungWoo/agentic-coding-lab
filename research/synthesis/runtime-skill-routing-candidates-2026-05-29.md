# Runtime Skill Routing Candidates - 2026-05-29

- Topic: runtime-skill-routing
- Captured at: 2026-05-29
- Status: candidate triage

## Scope Correction

The earlier `skill-management-routing` batch over-indexed on registries, marketplaces, installers, and package managers. Those repos answer "how do skills get stored, reviewed, installed, and updated?" They do not fully answer the runtime question:

How does an agent with thousands of available skills/tools find the right few, use them correctly, and avoid context blow-up?

For this new track, a candidate must address at least one runtime layer:

- build an index over many tools/skills;
- retrieve a small query-conditioned candidate set;
- rerank with richer tool/skill bodies or learned models;
- expose only top-k tools/skills to the LLM;
- keep execution authority aligned with the exposed shortlist;
- evaluate routing accuracy under large tool/skill pools;
- feed usage/failure data back into routing.

## Newly Added Repo Candidates

| Repo | Why It Fits |
| --- | --- |
| `zhengyanzhao1997/SkillRouter` | Direct retrieve-and-rerank system for skill selection at roughly 80K skill scale. It explicitly argues that name/description alone are insufficient and skill body text is decisive. |
| `langchain-ai/langgraph-bigtool` | Practical LangGraph reference for agents with large tool sets; uses a retrieval tool to select relevant tools instead of exposing all tool schemas. |
| `Pro-GenAI/Tool-SEE` | Tool Search Engine that indexes structured metadata and embeddings, then retrieves compact query-conditioned tool subsets before prompting. |
| `OpenBMB/ToolBench` | Large tool-learning and evaluation platform; useful for API/tool retrieval, execution traces, and measuring tool-selection behavior. |
| `Reason-Wang/ToolGen` | Learned tool retrieval/calling approach that represents tools for generation, useful as a non-classic retrieval alternative. |
| `jiajingyyyyyy/AutoTool` | Efficient tool selection using statistical/graph structure to reduce repeated LLM calls in agent loops. |
| `modelscope/ms-agent` | Claims hybrid dense+sparse skill discovery and execution framework; needs code verification to separate docs from implementation. |
| `varunreddy/SkillMesh` | Retrieval-gated skill architecture exposing top-k relevant capabilities per request. Small but directly aligned. |
| `Ruhal-Doshi/skill-depot` | Local-first MCP skill retrieval over Markdown skills with semantic search and selective loading. |
| `LittlePeter52012/skill-router` | Lightweight Go router claiming fast skill discovery/indexing/routing over 300+ skills with embedding reranking. |

## Existing Reviewed Sources To Reuse

These were already reviewed and should be reused as supporting evidence, not re-reviewed immediately:

- `PrefectHQ/fastmcp`: provider/transform/component catalog, BM25/regex search transforms, session visibility, and auth-aware listing.
- `aipotheosis-labs/aci`: semantic function search, schema projection, allowed-only discovery, credential injection, and execution telemetry.
- `SqueezeAILab/TinyAgent`: ToolRAG-style narrowing plus a cautionary failure: shown-to-model tools and allowed-to-execute tools can drift.
- `lastmile-ai/mcp-agent`: server allowlists, request-time tool filters, namespaced MCP tool aggregation, and token accounting.
- `shishirpatil/gorilla`: BFCL and function-calling evaluation patterns for relevance/irrelevance, multi-function, and multi-turn tool use.

## Evaluation Questions

For each candidate, review should answer:

1. Does it retrieve from the full pool at runtime, or only pre-install/pre-filter?
2. What fields are indexed: name, description, schema, examples, full body, code, historical traces?
3. Does the runtime expose only top-k tools/skills to the model?
4. Does it also restrict execution to that top-k set?
5. How does it handle ambiguous, overlapping, or near-duplicate tools?
6. What scale was actually evaluated: hundreds, thousands, tens of thousands?
7. Is retrieval lexical, vector, hybrid, reranker, graph, learned model, or LLM-based?
8. What is the failure mode when retrieval misses the right skill?
9. Is there telemetry or feedback to improve routing?
10. Can the pattern map from tools to Agent Skills `SKILL.md` bodies?

## Current Hypothesis

The likely architecture for Agentic Coding Lab is not "give the model 10,000 skill descriptions." It is:

1. Hard filters: workspace, host, trust, risk, language, file globs, enabled scope.
2. Cheap retrieval: BM25/vector over compact metadata.
3. Rich rerank: full `SKILL.md` body, examples, prior success traces, and negative triggers for top 50-200 only.
4. Shortlist exposure: give the model 3-7 candidate skills plus a `read_skill(id)` tool.
5. Authority sync: execution and resource reads are allowed only for selected/activated skills unless the router expands the shortlist.
6. Feedback loop: log misses, false activations, repeated manual overrides, and verification outcomes.

This track should produce a different synthesis from the registry/install one: a runtime router design and evaluation harness.
