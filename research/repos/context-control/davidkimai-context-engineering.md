# davidkimai/Context-Engineering

- URL: https://github.com/davidkimai/Context-Engineering
- Category: context-control
- Stars snapshot: 8,917 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 6158def66a2d2174ed8356cf376e5f44e10d78ea
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Broad context-engineering handbook with useful context-control patterns, especially component taxonomy, token budgeting, dynamic assembly, schemas, memory hierarchies, evaluation loops, cognitive-tool prompts, and protocol-shell notation. Best used as a pattern mine for Agentic Coding Lab, not copied as a runtime or source of implementation claims. The repo is large, mostly educational Markdown, and many advanced "field" artifacts are conceptual, simulated, planned, or drifted from the actual checkout.

## Why It Matters

`davidkimai/Context-Engineering` matters because it tries to define context engineering as a full design discipline rather than a prompt-writing trick. It names the information that enters an LLM as structured components: instructions, external knowledge, tools, memory, dynamic state, and the current query. That framing is directly relevant to context-control work for coding agents.

For Agentic Coding Lab, the repo is most valuable as a vocabulary and pattern catalog. It contains practical examples of token budgeting, context pruning, dynamic assembly, evaluation metrics, schema design, memory hierarchies, prompt programs, and verification templates. The less directly reusable material is the higher-level "neural field", "attractor", and "quantum semantic" framing, which is often presented as conceptual scaffolding rather than production code.

## What It Is

The repository is a handbook and course for context engineering. It combines top-level overview docs, a structured course under `00_COURSE/`, conceptual foundations under `00_foundations/`, runnable or semi-runnable Python guides under `10_guides_zero_to_hero/`, reusable Python/YAML templates under `20_templates/`, prompt templates under `20_templates/PROMPTS/`, one toy chatbot example under `30_examples/00_toy_chatbot/`, reference docs under `40_reference/`, protocol-shell docs under `60_protocols/`, cognitive-tool docs and schemas under `cognitive-tools/`, and agent instructions in `CLAUDE.md` and `GEMINI.md`.

It is not an agent runtime, MCP server, evaluation harness, or installable coding-agent skill pack. There is no package manifest, CI config, dependency lockfile, top-level automated test suite, or working command registry in the reviewed checkout. It is primarily Markdown education plus demonstration Python.

## Research Themes

- Token efficiency: Strong as a design theme. `40_reference/token_budgeting.md`, `20_templates/minimal_context.yaml`, `10_guides_zero_to_hero/01_min_prompt.py`, `02_expand_context.py`, and `00_COURSE/03_context_management/labs/memory_management_lab.py` all emphasize value per token, fixed budgets, allocation ratios, pruning, summarization, key-value memory, and context-window assembly. Implementation quality varies from simple heuristics to more detailed benchmark code.
- Context control: Strong conceptually. The repo repeatedly models context as assembled parts rather than one prompt. The clearest pattern is `C = A(c_instr, c_know, c_tools, c_mem, c_state, c_query)` in the course and dynamic assembly lab. `ContextAssembler`, `ContextOrchestrator`, `ContextWindowManager`, and schema files show concrete structures for selecting, ordering, truncating, and measuring context.
- Sub-agent / multi-agent: Moderate. The course has multi-agent chapters and `CLAUDE.md`/`GEMINI.md` define coding workflows, but the actual `70_agents/` tree is effectively empty in this checkout. Multi-agent content is mostly docs and examples, not a reusable orchestrator.
- Domain-specific workflow: Moderate to strong for educational workflows. The prompt templates include research, literature review, diligence, incident, alignment, memory, pipeline, protocol, and ethics agents. The code-generation pattern in `dynamic_assembly_lab.py` is relevant to coding agents, but most templates are generic and need local domain adaptation.
- Error prevention: Moderate. `CLAUDE.md`, `GEMINI.md`, `cognitive-tools/cognitive-templates/verification.md`, `40_reference/eval_checklist.md`, and scoring/benchmark scripts give systematic verification, self-reflection, fact checking, and implementation verification patterns. There is little automated enforcement.
- Self-learning / memory: Strong as a theme, mixed as implementation. The repo contains memory-attractor protocols, a memory-management lab with working/long-term memory classes, `20_templates/recursive_context.py`, `20_templates/prompt_program_template.py`, and `cognitive-tools/cognitive-schemas/schema-library.yaml`. Many advanced memory claims are conceptual or simulated.
- Popular skills: No usage telemetry was present. Highest-signal artifacts for reuse are `20_templates/minimal_context.yaml`, `20_templates/control_loop.py`, `20_templates/scoring_functions.py`, `20_templates/recursive_context.py`, `00_COURSE/01_context_retrieval_generation/labs/dynamic_assembly_lab.py`, `00_COURSE/03_context_management/labs/memory_management_lab.py`, `40_reference/token_budgeting.md`, `cognitive-tools/cognitive-templates/verification.md`, and `CLAUDE.md` workflow protocols.

## Core Execution Path

The main educational path begins in `README.md`: read foundations, run `10_guides_zero_to_hero/01_min_prompt.py`, inspect `20_templates/minimal_context.yaml`, then study `30_examples/00_toy_chatbot/`.

The clearest operational context-control path is:

1. Represent task context as typed components: instructions, knowledge, tools, memory, state, and query.
2. Attach metadata to each component: priority, token count, relevance score, source, timestamp, and free-form metadata.
3. Apply constraints: maximum tokens, minimum relevance, component priority weights, and optional required component types.
4. Select components using either greedy utility or dynamic programming. Utility combines relevance and priority, then penalizes overlap via a Jaccard-style mutual information approximation.
5. Assemble selected parts in an explicit order, usually query, instructions, knowledge, tools, state, then memory.
6. Score or refine output using quality metrics, control loops, or verification prompts.

`00_COURSE/01_context_retrieval_generation/labs/dynamic_assembly_lab.py` demonstrates that path most concretely. It also registers use-case patterns for RAG, agent workflows, research assistants, code generation, and multimodal contexts.

The memory path is implemented in `00_COURSE/03_context_management/labs/memory_management_lab.py`: `WorkingMemory` uses bounded LRU storage, `LongTermMemory` uses persistent storage and importance-based retention, `HierarchicalMemorySystem` moves information across layers, and `ContextWindowManager` allocates token budget across system instructions, user query, retrieved context, and response buffer.

The agent workflow path lives mostly in instruction docs. `CLAUDE.md` defines protocols for systematic reasoning, explore-plan-code-commit, test-driven development, UI iteration, code analysis, code generation, refactoring, test generation, bug diagnosis, Git, and PRs. `GEMINI.md` mirrors many of those ideas and adds terminal, project navigation, search grounding, MCP integration, self-bootstrap, and response optimization protocols. These are prompt-level procedures, not host-integrated commands.

The protocol-shell path lives under `60_protocols/` and `20_templates/field_protocol_shells.py`. Protocol docs use a Pareto-style syntax with `intent`, `input`, `process`, `output`, and `meta` sections. The Python parser can parse simple shell strings, validate against JSON Schema, map operation names to methods, and execute registered operations. The field protocols themselves are mostly conceptual; many operation methods return canned example structures.

## Architecture

The repository architecture is content-first:

- `README.md`: public definition, quick start, learning path, research evidence, and repository positioning.
- `Complete_Guide.md`: short table of contents for masterclass modules.
- `STRUCTURE/`: versioned structure docs describing conceptual evolution from biological metaphor to field/protocol/meta-recursive framing.
- `CITATIONS.md`, `CITATIONS_v2.md`, `CITATIONS_v3.md`, `00_EVIDENCE/README.md`: provenance and research-bridge documents tying the repo to cognitive tools, symbolic mechanisms, memory-reasoning, quantum semantics, and attractor dynamics papers.
- `00_foundations/`: theory progression from atoms, molecules, cells, organs, cognitive tools, prompt programming, neural fields, symbolic mechanisms, quantum semantics, and unified field theory.
- `00_COURSE/`: larger course modules for mathematical foundations, retrieval/generation, processing, management, RAG, memory, tools, multi-agent systems, field theory, evaluation, and capstone orchestration.
- `10_guides_zero_to_hero/`: Python guides for minimal prompts, context expansion, control loops, RAG recipes, prompt programs, schema design, and recursive patterns.
- `20_templates/`: YAML/JSON and Python templates for minimal context, control loops, scoring, prompt programs, schema design, recursive context, field protocols, and field resonance.
- `20_templates/PROMPTS/`: Markdown prompt templates for cognitive tools, field operations, and domain-specific agents.
- `30_examples/00_toy_chatbot/`: Markdown-wrapped Python example files for a toy field-based chatbot.
- `40_reference/`: long-form reference docs on token budgeting, retrieval indexing, evaluation, patterns, schemas, latent mapping, field mapping, attractors, emergence, and symbolic residue.
- `60_protocols/`: protocol-shell docs, digests, and schemas.
- `cognitive-tools/`: templates, programs, schemas, and architecture docs for structured reasoning.
- `NOCODE/`: non-code explanations and practical protocol docs.
- `SECURITY_RESEARCH/`: system-prompt research notes, including a Claude Code system prompt copy.

Several advertised directories or files are absent or empty in this checkout. `70_agents/README.md`, `80_field_integration/README.md`, `context-schemas/README.md`, `context-schemas/context_v7.0.json`, `60_protocols/shells/README.md`, and some cognitive-tool subdirectory READMEs contain only a newline. Schema files such as `context-schemas/context_v3.5.json` and `context_v6.0.json` describe larger planned trees than the current repository actually contains.

## Design Choices

The first major design choice is a progressive taxonomy. The repo uses a biological metaphor: atoms are single prompts, molecules are examples and few-shot structures, cells are memory/stateful context, organs are multi-step or multi-agent systems, neural systems are cognitive tools, and neural fields are continuous semantic structures with persistence and attractors.

The second choice is typed context assembly. The most practical formalism is `C = A(c_instr, c_know, c_tools, c_mem, c_state, c_query)`. This maps cleanly onto coding-agent context: project rules, docs/search results, available tools, persistent memories, current git/task state, and the user request.

The third choice is measuring context, not only writing it. Token counts, latency, relevance, coherence, comprehensiveness, conciseness, accuracy, field resonance, protocol adherence, information preservation, compression ratio, attention entropy, and memory utilization appear across templates and benchmark scripts.

The fourth choice is schema-heavy representation. YAML/JSON schemas and schema-cookbook docs are used to make context components, protocol shells, symbolic residue, and cognitive-tool programs explicit and parseable.

The fifth choice is protocol notation. The repo uses `/operation.name{param='value'}` syntax to turn cognitive or field operations into short, ordered process steps. This is readable and useful as a checklist language, though the parser is basic and cannot support all nested forms shown in docs.

The sixth choice is provenance by versioned research bridges rather than strict implementation provenance. `CITATIONS*`, `STRUCTURE*`, and `context-schemas/context_v*.json` document conceptual evolution, but they also drift from the actual files on disk.

## Strengths

The component taxonomy is useful and easy to adapt. Coding agents need to decide what instructions, code, docs, tools, memories, state, and query details enter context; this repo gives those roles names and basic selection logic.

The dynamic assembly lab has practical machinery. Priority, relevance, token count, redundancy penalties, greedy selection, dynamic programming selection, and reusable patterns map well to agent context assembly.

The memory-management lab is one of the stronger implementation artifacts. It includes bounded working memory, long-term memory, persistence hooks, decay, search, token allocation, truncation by sentence, allocation optimization from history, and performance monitoring.

The verification and evaluation material is broad. It covers self-checking templates, fact checking, consistency checking, implementation verification, component assessment, system integration assessment, benchmark design, and quality metrics.

The prompt-program and cognitive-tool sections give reusable structures for turning reasoning into modular steps. The best pattern is "understand, extract, highlight, apply, validate" because it is compact enough to become an Agentic Coding Lab skill or command skeleton.

The repo explicitly recognizes context as more than prompt text. Retrieval, memory, tool signatures, dynamic state, schemas, control loops, and evaluation are all treated as first-class pieces.

## Weaknesses

The repo is not a cohesive runnable system. It has many educational scripts and docs, but no top-level install/test workflow, dependency manifest, or consistent package structure.

Many advanced artifacts are conceptual or simulated. Field protocol implementations often return canned example attractors/residues/patterns. Some guide files return dummy embeddings, simulated responses, or no-client errors when dependencies or API keys are absent.

Documentation and actual repository state are out of sync. Several schema files describe missing directories such as larger `70_agents`, `80_field_integration`, and `90_meta_recursive` trees. The README advertises agent command support and links to `.claude/commands`, but no `.claude` directory was present in the reviewed checkout.

The course is explicitly under construction and contains many incomplete code blocks inside Markdown. That is acceptable for a handbook, but it limits direct reuse as an engineering dependency.

Terminology can overreach. Concepts such as quantum semantics, symbolic residue, attractor dynamics, and neural fields may be useful metaphors, but the repo often mixes research summaries, philosophical framing, and implementation claims. Agentic Coding Lab should extract concrete mechanisms and avoid importing claims wholesale.

The parser and schemas are too shallow for the full protocol notation shown in docs. `field_protocol_shells.py` uses regex parsing for simple sections and operations, so it is a sketch of a protocol runtime rather than a robust DSL.

Automated testing is absent. `find` and `rg` found no `*test*` files in the checkout. Evaluation content exists as references and benchmark scripts, not as CI-backed tests.

## Ideas To Steal

Use the six-component context model for coding agents: instructions, knowledge, tools, memory, state, and query. It is a clean checklist for context assembly and review.

Add context component metadata everywhere: source, priority, relevance, token count, timestamp, and rationale for inclusion. This makes context pruning auditable.

Build a small context assembler that supports greedy selection, redundancy penalties, and fixed token allocations. The dynamic assembly lab gives a workable starting shape.

Adopt token allocation ratios for agent prompts. A coding-agent version could reserve budget for project instructions, current task, code snippets, docs/search results, command outputs, memory, and response buffer.

Use compact cognitive-tool templates such as understand, extract, highlight, apply, validate for complex coding tasks, especially debugging, design review, migration planning, and code explanation.

Turn verification templates into skills: solution verification, fact checking, consistency checks, implementation verification, and alternative perspective analysis.

Use protocol-shell syntax as a human-readable workflow format, but back it with a stricter parser if it becomes executable.

Keep versioned context schemas, but add an automated drift check that verifies schema file trees against actual repo paths.

## Do Not Copy

Do not copy the field/attractor/quantum terminology into Agentic Coding Lab unless it is translated into concrete operations, metrics, and failure modes.

Do not treat the protocol-shell parser as production ready. Regex parsing is brittle, many operations are only sketches, and nested protocol examples exceed the parser's real capabilities.

Do not rely on the repo's cited research summaries as proof that a given implementation works. Validate any adapted mechanism with local tasks and benchmarks.

Do not copy large prompt templates wholesale. Many are verbose and generic; Agentic Coding Lab should compress them into focused skills with explicit triggers and tests.

Do not mirror planned directories or schema-described structure without checking actual files. The repo has notable documentation-to-filesystem drift.

Do not use the Python scripts as a dependency without adding packaging, dependency declarations, linting, tests, and API cleanup.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is in-scope for `context-control` because it directly studies context structure, assembly, compression, memory, schema design, and evaluation. It is not primarily a coding-agent support system, and its strongest value is pattern extraction rather than adoption.

Agentic Coding Lab should mine it for a context assembly DSL, component metadata, token allocation policy, verification templates, memory hierarchy ideas, and schema drift checks. The practical adaptation should be smaller and more rigorous than the source: fewer metaphors, more executable validators, local examples, and tests that prove the context-control behavior under real coding tasks.

## Reviewed Paths

- `/tmp/myagents-research/davidkimai-context-engineering/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/Complete_Guide.md`
- `/tmp/myagents-research/davidkimai-context-engineering/CLAUDE.md`
- `/tmp/myagents-research/davidkimai-context-engineering/GEMINI.md`
- `/tmp/myagents-research/davidkimai-context-engineering/CITATIONS.md`
- `/tmp/myagents-research/davidkimai-context-engineering/CITATIONS_v2.md`
- `/tmp/myagents-research/davidkimai-context-engineering/CITATIONS_v3.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_EVIDENCE/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/STRUCTURE/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/STRUCTURE/STRUCTURE.md`
- `/tmp/myagents-research/davidkimai-context-engineering/STRUCTURE/STRUCTURE_v2.md`
- `/tmp/myagents-research/davidkimai-context-engineering/STRUCTURE/STRUCTURE_v3.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/01_atoms_prompting.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/02_molecules_context.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/03_cells_memory.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/04_organs_applications.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/05_cognitive_tools.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/07_prompt_programming.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/08_neural_fields_foundations.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/11_emergence_and_attractor_dynamics.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/12_symbolic_mechanisms.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_foundations/13_quantum_semantics.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/01_context_retrieval_generation/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/01_context_retrieval_generation/00_overview.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/01_context_retrieval_generation/03_dynamic_assembly.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/01_context_retrieval_generation/labs/dynamic_assembly_lab.py`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/01_context_retrieval_generation/templates/assembly_patterns.py`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/02_context_processing/benchmarks/processing_metrics.py`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/02_context_processing/benchmarks/long_context_evaluation.py`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/03_context_management/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/03_context_management/00_overview.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/03_context_management/02_memory_hierarchies.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/03_context_management/03_compression_techniques.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/03_context_management/labs/memory_management_lab.py`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/04_retrieval_augmented_generation/02_agentic_rag.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/05_memory_systems/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/06_tool_integrated_reasoning/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/07_multi_agent_systems/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/09_evaluation_methodologies/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/09_evaluation_methodologies/00_evaluation_frameworks.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/09_evaluation_methodologies/01_component_assessment.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/09_evaluation_methodologies/02_system_integration.md`
- `/tmp/myagents-research/davidkimai-context-engineering/00_COURSE/10_orchestration_capstone/00_capstone_overview.md`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/01_min_prompt.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/02_expand_context.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/03_control_loops.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/04_rag_recipes.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/05_prompt_programs.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/06_schema_design.py`
- `/tmp/myagents-research/davidkimai-context-engineering/10_guides_zero_to_hero/07_recursive_patterns.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/minimal_context.yaml`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/neural_field_context.yaml`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/schema_template.yaml`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/schema_template.json`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/control_loop.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/scoring_functions.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/prompt_program_template.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/recursive_context.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/field_protocol_shells.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/field_resonance_measure.py`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/research.agent.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/diligence.agent.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/memory.agent.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/protocol.agent.md`
- `/tmp/myagents-research/davidkimai-context-engineering/20_templates/PROMPTS/verification_loop.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/00_toy_chatbot/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/00_toy_chatbot/chatbot_core.py.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/00_toy_chatbot/context_field.py.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/00_toy_chatbot/protocol_shells.py.md`
- `/tmp/myagents-research/davidkimai-context-engineering/30_examples/00_toy_chatbot/meta_recursive_demo.py.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/token_budgeting.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/retrieval_indexing.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/eval_checklist.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/patterns.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/schema_cookbook.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/cognitive_patterns.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/field_mapping.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/attractor_dynamics.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/symbolic_residue_types.md`
- `/tmp/myagents-research/davidkimai-context-engineering/40_reference/emergence_signatures.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/shells/attractor.co.emerge.shell.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/shells/recursive.emergence.shell.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/shells/recursive.memory.attractor.shell.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/shells/context.memory.persistence.attractor.shell.md`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/schemas/protocolShell.v1.json`
- `/tmp/myagents-research/davidkimai-context-engineering/60_protocols/schemas/symbolicResidue.v1.json`
- `/tmp/myagents-research/davidkimai-context-engineering/context-schemas/context.json`
- `/tmp/myagents-research/davidkimai-context-engineering/context-schemas/context_v3.5.json`
- `/tmp/myagents-research/davidkimai-context-engineering/context-schemas/context_v6.0.json`
- `/tmp/myagents-research/davidkimai-context-engineering/context-schemas/context_v7.0.json`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/cognitive-templates/reasoning.md`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/cognitive-templates/verification.md`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/cognitive-programs/basic-programs.md`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/cognitive-programs/program-library.py`
- `/tmp/myagents-research/davidkimai-context-engineering/cognitive-tools/cognitive-schemas/schema-library.yaml`
- `/tmp/myagents-research/davidkimai-context-engineering/NOCODE/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/NOCODE/20_practical_protocols/README.md`
- `/tmp/myagents-research/davidkimai-context-engineering/SECURITY_RESEARCH/README.md`
- `https://api.github.com/repos/davidkimai/Context-Engineering`

## Excluded Paths

- `/tmp/myagents-research/davidkimai-context-engineering/.git/`: VCS internals; only HEAD SHA, branch, latest commit metadata, and contributor/update patterns were needed.
- `/tmp/myagents-research/davidkimai-context-engineering/LICENSE`: legal metadata, not a context-control artifact.
- `/tmp/myagents-research/davidkimai-context-engineering/PODCASTS/*.mp4`: binary media files totaling roughly 34.4 MB; excluded because the task focused on docs, templates, scripts, tests, and provenance. `PODCASTS/README.md` and transcript metadata were sampled only for awareness.
- External images and badges embedded in `README.md`: presentation-only remote assets, not local execution or context-control paths.
- Empty or near-empty stub files beyond noted examples: reviewed for substance and excluded from deeper analysis because they add no workflow or implementation content.
- Long no-code educational prose under `NOCODE/` and masterclass modules under `masterclass_content/`: sampled for structure, then excluded from deeper review because equivalent technical patterns were covered in `00_foundations/`, `00_COURSE/`, `20_templates/`, `40_reference/`, and `cognitive-tools/`.
- Full line-by-line review of all 223 Markdown files was excluded. The review focused on top-level docs, handbook/course structure, context-engineering taxonomy, agent/workflow examples, templates/scripts, schema/protocol files, evaluation material, and update/provenance docs.
- No vendored dependency directory, generated build output, UI-only application tree, or automated test tree was found in the reviewed checkout.
