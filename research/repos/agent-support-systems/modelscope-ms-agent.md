# modelscope/ms-agent

- URL: https://github.com/modelscope/ms-agent
- Category: agent-support-systems
- Stars snapshot: 4,282 (GitHub REST API, captured 2026-05-31; matches `research/index.md` row captured 2026-05-29)
- Reviewed commit: f491aaaee84dc1ba3bb3cbfaf3258fefe9ff2dc7
- Reviewed at: 2026-05-31T18:56:59+09:00
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong runtime reference for agent skill discovery because the code really implements a hybrid dense+sparse skill retriever, LLM filtering, DAG construction, progressive resource loading, and sandbox/local skill execution. It is not yet a proven 10K-skill solution: skill loading and indexing are eager, indexes are rebuilt in-process, retrieval corpus is only skill id/name/description, tests are small and API-dependent, MCP/tool selection is still global tool-schema prompting, and there is no benchmark showing large-library accuracy or latency.

## Why It Matters

`modelscope/ms-agent` is one of the few reviewed repos that moves beyond skill marketplace/install management into actual runtime use. Its `AutoSkills` module answers the user's core question directly: when an agent has many skills, do not place all skill bodies in the prompt. Load skill metadata, retrieve a small candidate set with dense+sparse search, ask the LLM to filter and build a dependency DAG, and only then load full skill content plus selected scripts/references/resources for execution.

That makes it useful for Agentic Coding Lab even though the implementation is not production-scale for 10,000 skills. The code exposes the shape of a runtime selector and the failure modes we need to solve: candidate recall, index persistence, metadata quality, prompt budget for query analysis, deterministic shortlist ordering, tool-vs-skill separation, and verification that docs claims match executable behavior.

## What It Is

MS-Agent is a Python agent framework with `LLMAgent`, MCP/tool calling, memory, RAG/knowledge search, deep research projects, code generation projects, WebUI, and a newer Agent Skills module. The reviewed scope is the skill runtime and adjacent agent architecture, not the full product.

The Agent Skills subsystem follows the Anthropic-style `SKILL.md` directory contract. A skill directory contains required YAML frontmatter in `SKILL.md` and may include scripts, references, resources, and requirements. `SkillLoader` parses these directories into `SkillSchema` objects. `AutoSkills` then builds a retriever corpus, selects skills for a user query, constructs an execution DAG, and uses `DAGExecutor` plus `SkillContainer` to run the selected skills.

At the reviewed commit, the repo itself has only three bundled `SKILL.md` files: `ms-agent-skills/SKILL.md` plus two example Claude skills under `examples/skills/claude_skills/{docx,pdf}`. Docs and tests refer to a larger 16-skill Claude corpus under `projects/agent_skills`, but that path is not present in the current checkout. The large-library behavior is therefore implemented as framework code, not demonstrated by a large in-repo corpus.

## Research Themes

- Token efficiency: Strong conceptually and partially implemented. `AutoSkills` switches to retrieval when skill count is greater than 10, exposes only retrieved candidates to LLM filters, and progressive execution loads selected scripts/references/resources after planning. Weakness: initialization still parses every `SKILL.md`, stores full content in memory, and direct mode sends all descriptions when retrieval is disabled or skill count is 10 or below.
- Context control: Stronger than registry-only repos. `LLMAgent` intercepts new tasks before normal chat/tool loops, routes skill-like queries to `AutoSkills`, and returns compact execution summaries. `SkillAnalyzer` truncates `SKILL.md` content to 4,000 characters for planning and references/resources to 2,000 characters for command generation. Separate memory compressors prune tool outputs and summarize long conversations, but they are not specifically integrated with skill-selection telemetry.
- Sub-agent / multi-agent: Medium. The skill DAG supports sequential and parallel skill execution and passes upstream outputs downstream through environment variables. The wider repo also has deep-research sub-agent prompts and an MCP capability gateway, but the skill router itself is a DAG executor, not a multi-agent deliberation system.
- Domain-specific workflow: Strong. The design is meant for domain skills such as PDF, DOCX, PPTX, data analysis, chart generation, and code tools. Skills can include deterministic scripts and references, and execution can run in a sandbox or local mode.
- Error prevention: Medium. `SkillContainer` has Docker sandbox support, local dangerous-pattern checks, output directory conventions, timeouts, retry, execution specs, and LLM-based error analysis/fixing for failed Python code. However, safety is regex/prompt-assisted, not a full permission/provenance system.
- Self-learning / memory: Medium-low for skills. The repo has memory support and context compression, but the skill runtime does not record activation telemetry, success/failure history, user preference, or learned routing improvements. Skill selection is stateless across runs except for ordinary logs/history.
- Popular skills: The useful artifacts are not the bundled skill corpus but the runtime patterns: `AutoSkills`, `HybridRetriever`, `SkillAnalyzer`, `DAGExecutor`, `SkillContainer`, `LLMAgent.do_skill`, and the `ms-agent-skills` MCP capability wrapper.

## Core Execution Path

`LLMAgent.run_loop()` prepares the LLM, runtime, tools, memory, RAG, and knowledge search. On a new task it normalizes messages and calls `do_skill()` before standard RAG and tool-calling. `do_skill()` extracts the user query and calls `should_use_skills()`, which lazily initializes `AutoSkills` from `config.skills.path` and asks `AutoSkills._analyze_query()` whether the query needs skills.

`AutoSkills.__init__()` loads all configured skills through `load_skills()`. If `enable_retrieve` is unset, it turns retrieval on only when `len(all_skills) > 10`. It builds a compact corpus document per skill in the form `[skill_id] name: description` and initializes `HybridRetriever` when retrieval is enabled. Default retrieval settings are `top_k=3`, `min_score=0.8`, and `max_candidate_skills=10`.

`AutoSkills.get_skill_dag()` has two modes. In direct mode, it sends all skill names/descriptions to `PROMPT_DIRECT_SELECT_SKILLS` and asks the LLM to select skills and build a DAG. In search mode, it first asks the LLM to analyze the query and produce one or more `skill_queries`; this prompt includes only the first 20 skills from `_get_skills_overview()`. It then runs `HybridRetriever.async_search()` for each query, unions retrieved skill IDs, truncates to `max_candidate_skills` if needed, runs a fast LLM filter over name/description, optionally runs a deep LLM filter over truncated `SKILL.md` content, and finally calls `_build_dag()` to validate the selected IDs and dependency order.

`HybridRetriever` is real code, not just documentation. It uses a sentence-transformers embedding model downloaded via ModelScope, a FAISS `IndexFlatIP` dense index, a local BM25 implementation over tokenized corpus text, z-score normalization, weighted dense/BM25 fusion with default `alpha=0.7`, sigmoid mapping, `min_score` filtering, and `top_k` truncation. Async search computes dense and sparse scores concurrently.

Execution starts when `AutoSkills.run()` calls `execute_dag()`. `DAGExecutor` executes the LLM-produced order sequentially or in parallel groups. For each skill, it builds `ExecutionInput`, injects upstream outputs as `UPSTREAM_OUTPUTS` and per-skill stdout env vars, mounts the skill directory, and uses progressive analysis if an LLM is available. Progressive analysis first asks the LLM which scripts/references/resources are needed, then loads only those files, then asks the LLM to generate concrete commands. `SkillContainer` executes Python, shell, JavaScript, or inline Python code in Docker sandbox mode or local mode, collects output files, records execution specs, and retries failed Python code with LLM-generated fixes.

Tools and MCP servers follow a different path. `ToolManager.get_tools()` returns all configured tool schemas in deterministic order to the model. It supports `include`/`exclude` filters, name truncation, concurrency limits, and MCP server tools, but there is no retrieval layer for a large tool catalog. So the repo's runtime skill routing should not be confused with large-MCP-tool routing.

## Architecture

The skill-routing architecture is a layered runtime:

- `SkillLoader` and `SkillSchemaParser`: scan local directories or ModelScope repo IDs, require `SKILL.md` frontmatter with `name` and `description`, collect scripts/references/resources, and build `SkillSchema`.
- `HybridRetriever`: local dense+sparse search over compact skill metadata strings.
- `AutoSkills`: main selector. It decides skill need, retrieves candidate skills, performs LLM fast/deep filtering, builds a skill dependency DAG, and delegates execution.
- `SkillAnalyzer`: progressive context loader. It prompts over metadata, truncated skill body, and resource file names; then loads only plan-selected resources and asks for executable commands.
- `DAGExecutor`: dependency-aware execution engine with parallel groups, upstream output propagation, retry, self-reflection, and execution context retention.
- `SkillContainer`: sandbox/local execution boundary with output directories, script execution helpers, security regexes, and markdown execution specs.
- `LLMAgent`: host integration. It lazily initializes skills from agent config and short-circuits normal chat/tool loops when skills handle the task.
- `ToolManager` and `MCPClient`: ordinary tool/MCP infrastructure. They are adjacent but not routed by the skill retriever.
- `ContextCompressor`, `refine_condenser`, and memory modules: general context management for long conversations and tool outputs, not skill-index governance.

The broader repo contains `capabilities` and `ms-agent-skills`, which expose MS-Agent functions through MCP-style capabilities. That package is a useful example of a skill wrapping a capability gateway, but it is not the same as the `AutoSkills` runtime router.

## Design Choices

The most important design choice is the explicit threshold: with more than 10 skills, the agent stops asking the LLM to inspect every skill description and switches to retrieval. This encodes a practical rule that small skill sets can be direct-prompted while larger sets need a selector.

The retriever indexes compact metadata, not full skill bodies. This is cheap and keeps retrieval documents short, but it means recall depends heavily on the quality of each skill's `name` and `description`. The deep LLM filter can inspect `SKILL.md` content, but only after retrieval has already selected candidates.

The query analyzer is LLM-first. It decides whether skills are needed and produces multiple search queries. This gives the router flexibility, but the prompt only shows the first 20 skills as an overview, so the need/no-need decision can be biased or under-informed when the library is much larger.

Filtering is staged. Retrieval gives a recall-oriented candidate set, fast LLM filtering removes obviously irrelevant candidates from names/descriptions, deep LLM filtering reviews truncated skill bodies, and DAG construction performs final minimal-sufficiency and dependency ordering. The design is right for context control, but candidate ordering currently passes through Python sets in places, so truncation can be nondeterministic when there are too many candidates.

Execution is treated as part of skill use, not just selection. The selected skills become a DAG and can exchange outputs. That is more useful than a top-1 skill router for compound tasks like "extract PDF tables and create an Excel report."

The skill parser intentionally accepts the simple Anthropic-style filesystem contract. This makes skills portable and easy to author, but frontmatter is too thin for 10K-scale routing: no required category, trigger examples, negative triggers, permissions, dependency, trust, host compatibility, or maturity fields.

The sandbox defaults are security-minded, but the system automatically disables sandbox in `LLMAgent._ensure_auto_skills()` when Docker is not running. Local mode warns users and runs regex checks, but still executes code on the host.

## Strengths

- Implements an actual runtime selector for skills, unlike marketplace/catalog-only repos.
- Hybrid dense+sparse retrieval is concrete and readable: FAISS semantic search plus BM25 lexical search, normalized and fused.
- The default top-k path keeps the LLM prompt bounded as skill count grows, at least in principle.
- The pipeline separates retrieval, LLM filtering, DAG construction, progressive resource loading, and execution.
- Progressive loading is well aligned with Anthropic-style skills: metadata first, then `SKILL.md`, then selected scripts/references/resources.
- DAG execution supports multi-skill workflows, parallel independent skills, and upstream/downstream data passing.
- The `LLMAgent` integration is lazy and opt-in through `config.skills`, so ordinary agents do not pay skill initialization cost unless configured.
- Execution specs, output directories, retry, and error-analysis prompts make skill execution more auditable than a plain "read a skill and improvise" approach.
- Tests cover many retrieval/DAG scenarios and upstream/downstream execution mechanics, even though the main retrieval tests require external LLM credentials.
- The repo is honest enough to expose adjacent context systems: memory compression, knowledge search, MCP tools, and capability gateway are separate mechanisms rather than being collapsed into "skills."

## Weaknesses

- No 10K benchmark. There is no evidence in repo tests or docs that the current retriever has acceptable recall/latency at 10,000 skills, let alone 80K-scale libraries.
- Indexing is eager and non-persistent. Each `AutoSkills` initialization loads all skills, all `SKILL.md` content, downloads/loads embedding/tokenizer models, builds dense embeddings, and builds BM25 in process.
- BM25 scoring is O(number of docs times query tokens), and dense retrieval only searches up to 500 dense hits while still producing an all-doc dense score vector with zeros for the rest. This is acceptable for small corpora but not a complete large-scale retrieval design.
- Retrieval corpus is only `[skill_id] name: description`. Tags and full body text are not indexed, so relevant skills can be missed when the description is generic or uses different vocabulary from the user query.
- The LLM query analyzer sees only the first 20 skill descriptions in `_get_skills_overview()`. For large libraries this overview is arbitrary context, not a representative catalog.
- Candidate truncation after retrieval converts a set to a list, so when `collected_skills` exceeds `max_candidate_skills`, candidate retention can be nondeterministic rather than score-ordered.
- The score threshold uses z-score fusion plus sigmoid. A fixed `min_score=0.8` is easy to miscalibrate across corpora, especially when corpus size or description quality changes.
- Direct selection mode still dumps all skill descriptions to the LLM when retrieval is off or there are 10 or fewer skills. That is fine for small packs but creates two very different behavioral regimes around the threshold.
- MCP/tool selection is not solved. The normal tool path exposes all configured tools to the LLM and relies on include/exclude filters, so "10,000 tools" would still blow up context unless those tools are wrapped as skills or another retrieval layer is added.
- Security is not a full trust model. There is no skill provenance, permission manifest, network policy metadata, package integrity, signing, quarantine, or execution approval flow.
- Docs drift exists. README and tests refer to `projects/agent_skills` and a 16-skill Claude corpus, but the current repo checkout does not include that path; only two example Claude skills are present.
- Test coverage for retrieval quality is API-dependent and corpus-small. The tests assert non-empty DAGs and valid structures but do not provide deterministic offline recall metrics, adversarial near-duplicate tests, or large-corpus performance tests.

## Ideas To Steal

- Use an explicit runtime skill pipeline: need detection -> query rewrite -> hybrid retrieval -> LLM fast filter -> LLM deep filter -> DAG -> progressive load -> execute.
- Turn on retrieval automatically above a small skill-count threshold, while still allowing explicit configuration.
- Keep retriever prompts compact and put full skill bodies behind a second-stage filter.
- Index a machine-generated compact document per skill and maintain a reverse map from document to skill ID.
- Let the LLM produce multiple retrieval queries rather than only searching the raw user prompt.
- Use a final DAG step so multi-skill tasks select a minimal set with dependencies instead of one isolated skill.
- Load only plan-selected scripts/references/resources during execution.
- Pass upstream skill outputs through structured env vars so downstream skills can be composed without reloading prior stdout into the LLM context.
- Keep skill execution logs/specs as durable artifacts for debugging and later evals.
- Treat skill routing separately from ordinary tool/MCP routing; a large tool catalog needs its own router or a bridge into the skill system.

## Do Not Copy

- Do not rely on `name` and `description` as the only indexed retrieval text for a 10K-skill library. Add tags, trigger examples, negative triggers, input/output types, tool requirements, body summaries, and possibly chunked body embeddings.
- Do not rebuild all indexes at agent startup when the skill library is large. Use persistent indexes, incremental updates, content hashes, and lazy model loading.
- Do not put an arbitrary first 20 skills into the query-analysis prompt. Use category summaries, sampled centroids, or a deterministic registry overview.
- Do not truncate candidate sets through unordered sets. Preserve retrieval scores and stable tie-breakers.
- Do not treat a fixed similarity threshold as universal. Calibrate per corpus and log false positives/false negatives.
- Do not let local execution be the silent fallback for untrusted skills. Require an explicit trust/approval boundary when Docker or another sandbox is unavailable.
- Do not assume that solving skill retrieval solves tool retrieval. MCP and ordinary tool schemas still need shortlist/routing if their count grows.
- Do not claim production-grade large-skill routing without a benchmark suite that measures recall@k, end-to-end task success, latency, index build time, and context tokens at realistic corpus sizes.

## Fit For Agentic Coding Lab

Fit is high as a prototype reference and conditional as an implementation source. The most reusable part is the shape of `AutoSkills`: compact registry text, hybrid retrieval, LLM filtering, final DAG, and progressive execution. This is directly aligned with the "10,000 skills without context blow-up" problem.

For Agentic Coding Lab, the right adoption path is to copy the pipeline concept, not the exact scaling implementation. A production router should add:

- `skills.index.json` generated from skill frontmatter plus validated routing metadata.
- Persistent dense and lexical indexes keyed by content hash.
- Retrieval over category, trigger examples, negative triggers, tags, tool/permission needs, and skill body summaries, not only descriptions.
- Stable score-ordered candidate handling and deterministic tie-breaks.
- A router eval harness with synthetic and real tasks, near-duplicate skills, missing-skill queries, and multi-skill DAG expectations.
- Telemetry for query, retrieved candidates, filtered candidates, selected skills, execution success, user correction, and false-positive activation.
- Tool/MCP routing parity so large tool catalogs are handled with the same top-k discipline.
- A stronger execution trust model: skill provenance, permission manifest, dependency lock/integrity, sandbox requirement, network policy, and approval hooks.

MS-Agent's code is especially useful because it shows the missing pieces clearly. It has enough runtime structure to be worth learning from, but the current repo does not close the 10K-scale problem by itself.

## Reviewed Paths

- `README.md`: product framing, release notes, Agent Skills claims, memory/context compression claim, and docs drift around `projects/agent_skills`.
- `docs/en/Components/AgentSkills.md` and `ms_agent/skill/README.md`: documented skill architecture, hybrid retrieval claim, progressive loading levels, configuration, security model, and examples.
- `examples/agent/run_agent_with_skills.py`: minimal LLMAgent skill configuration and execution example.
- `ms_agent/agent/llm_agent.py`: host integration, lazy `AutoSkills` initialization, `should_use_skills`, `do_skill`, standard run loop, tool/RAG/memory ordering, and skill short-circuit behavior.
- `ms_agent/skill/auto_skills.py`: main runtime for query analysis, retrieval, LLM filtering, DAG construction, progressive analysis, execution, retry, and result formatting.
- `ms_agent/retriever/hybrid_retriever.py`: FAISS dense index, BM25 sparse retriever, score fusion, async search, and scalability implications.
- `ms_agent/skill/loader.py` and `ms_agent/skill/schema.py`: filesystem/ModelScope skill loading, frontmatter requirements, file classification, lazy resource-loading data structures, and schema validation.
- `ms_agent/skill/prompts.py`: query analysis, fast/deep filtering, DAG construction, progressive skill analysis, command generation, and execution-error repair prompts.
- `ms_agent/skill/container.py` and `ms_agent/skill/spec.py`: sandbox/local execution, output collection, security pattern checks, execution records, upstream links, and spec artifacts.
- `ms_agent/tools/tool_manager.py`, `ms_agent/tools/base.py`, and `ms_agent/tools/mcp_client.py`: ordinary tool/MCP exposure, include/exclude filters, deterministic ordering, concurrency, and absence of runtime retrieval for large tool sets.
- `ms_agent/knowledge_search/sirchmunk_search.py`: adjacent code/document retrieval system, reviewed to separate knowledge search from skill routing.
- `ms_agent/memory/condenser/context_compressor.py`: context overflow detection, tool-output pruning, and conversation summarization.
- `ms-agent-skills/SKILL.md` and `ms-agent-skills/references/**`: capability-gateway skill wrapper and MCP-facing capability index.
- `examples/skills/claude_skills/{docx,pdf}/SKILL.md`: bundled skill examples used to confirm actual in-repo skill corpus size.
- `tests/skills/test_claude_skills.py`: API-dependent retrieval/DAG/execution tests and drift against missing `projects/agent_skills` path.
- `tests/skills/test_dag_upstream_downstream.py`: deterministic tests for DAG output propagation, env var injection, sequential/parallel execution, and output file propagation.
- `requirements/framework.txt`, `requirements/research.txt`, and `setup.py`: dependencies for FAISS, sentence-transformers, ModelScope, MCP, memory/code extras, and packaging behavior.

## Excluded Paths

- `webui/frontend/**`, `webui/backend/**`, frontend package files, and UI assets: product interface and server plumbing, not the skill routing algorithm.
- Most `projects/**` domain applications such as deep research, fin research, code genesis, doc research, and singularity cinema: useful demos, but outside the runtime-skill-routing focus except for release/context notes sampled through README.
- Binary/media assets under `asset/**`, `docs/resources/**`, project examples, audio/video/image outputs, and screenshots: documentation/demo artifacts rather than executable routing logic.
- Notebook files and generated example resources: not needed to verify skill selection or context assembly.
- `docs/zh/**` after checking the English docs and code paths: duplicate localized documentation for the reviewed concepts.
- Full line-by-line review of every built-in tool implementation under `ms_agent/tools/**`: the key question was whether tool selection is routed. `ToolManager`/`MCPClient` were sufficient to establish that tools are globally exposed with include/exclude filters.
- External ModelScope hub skill repositories and the historical `modelscope-agent<=0.8.0` archive: current repo code was the source of truth for this review.
- Live upstream skill execution tests: the main retrieval/execution tests require external LLM API keys and external skill corpus setup. I used static code review plus the repo's deterministic DAG tests as evidence of implemented mechanics.
