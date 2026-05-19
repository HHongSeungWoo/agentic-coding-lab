# dair-ai/Prompt-Engineering-Guide

- URL: https://github.com/dair-ai/Prompt-Engineering-Guide
- Category: context-control
- Stars snapshot: 74,452 (GitHub REST API repository endpoint, captured 2026-05-12)
- Reviewed commit: 57673726396dd94acb23bdb1e67f27c78ee85a8e
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a taxonomy and pattern source for context engineering, RAG, tool descriptions, agent state, and prompt decomposition. Not useful as a direct dependency or executable harness because the repo is primarily a prose guide and Nextra content site.

## Why It Matters

This repo is one of the broadest public prompt/context engineering guides. For Agentic Coding Lab, its value is not code reuse; it is a well-organized catalog of concepts that map directly onto coding-agent context control: explicit instructions, task decomposition, structured outputs, RAG, memory, tool descriptions, state tracking, and verification.

The most relevant recent material reframes prompt engineering as context engineering. It treats agent reliability as a function of what enters the context window, when it enters, how outputs are structured, and how failures are observed. That framing transfers well to coding agents, where poor context selection causes skipped subtasks, stale assumptions, invalid tool calls, and weak review behavior.

## What It Is

Prompt Engineering Guide is a Next.js/Nextra documentation site with MDX pages, multilingual translations, image assets, and a small set of tutorial notebooks. The content spans beginner prompting, advanced prompting techniques, RAG, AI agents, risks, models, papers, tools, datasets, and applications.

For this review, the important parts are the English source pages for context engineering, agents, RAG, prompt chaining, ReAct, function calling, context caching, and coding. The repo includes build scripts for the docs site but no project-level test suite or production agent implementation.

## Research Themes

- Token efficiency: Context caching guide, RAG retrieval, prompt chaining, compression references, and long-context cautions all support reducing repeated or noisy context. The repo discusses token efficiency conceptually but does not provide reusable token-budget instrumentation.
- Context control: Strongest theme. The context engineering guide breaks context into system prompt, instructions, user input, structured inputs/outputs, tools, RAG/memory, and historical state. It repeatedly emphasizes explicit constraints, delimiters, current-date injection, schemas, and context filtering.
- Sub-agent / multi-agent: Agent pages describe orchestrator and search-worker splits, clean sub-agent context, minimal sub-agent inputs, and separate model choices for planner versus worker. This is directly relevant to coding-agent worker dispatch.
- Domain-specific workflow: Good taxonomy but shallow implementation. Examples cover deep research, RAG title generation, code generation, function calling, and research-paper querying, but most are tutorials rather than hardened workflows.
- Error prevention: Good prose guidance on ambiguity removal, status values, observability, retries, failure marking, and verification. No executable error-prevention harness is included.
- Self-learning / memory: Agent and context engineering pages distinguish short-term context, long-term vector memory, task state, cached subqueries, and external storage. The advice is useful, but the repo does not define memory schemas or retention policies.
- Popular skills: Prompt decomposition, prompt chaining, ReAct, RAG, structured outputs, tool/function calling, context caching, task-state tracking, explicit current-date context, and agent verification.

## Core Execution Path

There is no agent runtime. The execution path is documentation publication:

1. MDX content lives under `pages/`, with English source pages such as `pages/guides/context-engineering-guide.en.mdx`, `pages/agents/*.en.mdx`, `pages/research/rag.en.mdx`, and `pages/techniques/*.en.mdx`.
2. Nextra metadata files, especially `pages/_meta.en.json` and per-section `_meta.en.json` files, define navigation order.
3. Next.js scripts in `package.json` expose `dev`, `build`, and `start`; there are no `test` or lint scripts.
4. API helpers read local metadata for content listings. `pages/api/getPageContent.ts` fetches raw English MDX content from the GitHub `main` branch and strips imports, exports, and frontmatter before returning page content.
5. Tutorial notebooks under `notebooks/` demonstrate RAG, function calling, ReAct, and Gemini context caching with external APIs and local/vector stores.

For Agentic Coding Lab, the closest "runtime" pattern is the guide's deep-research-agent example: planner creates search tasks, external state tracks task status, search worker executes focused queries, orchestrator synthesizes, and prompt rules determine whether tasks may be skipped or must be executed.

## Architecture

The repo is a content system, not a library:

- `pages/` contains the main source of truth for docs. English pages are mirrored by many translated pages, creating high content volume and duplicate structure.
- `pages/guides/context-engineering-guide.en.mdx` is the most direct context-control artifact. It defines context engineering broadly and walks through a multi-agent search-planning prompt with date injection, structured output fields, tool context, RAG/memory, and historical state.
- `pages/agents/context-engineering.en.mdx` and `pages/agents/context-engineering-deep-dive.en.mdx` convert the concept into a deep research agent case study, including task completion rules, spreadsheet-like state tracking, explicit status values, flexible versus strict execution, sub-agent communication, context-length management, and error handling instructions.
- `pages/research/rag.en.mdx` summarizes RAG paradigms and evaluation: naive, advanced, modular, retrieval/generation/augmentation, query rewriting, reranking, compression, adaptive retrieval, context relevance, faithfulness, noise robustness, and counterfactual robustness.
- `pages/techniques/prompt_chaining.en.mdx` and `pages/techniques/react.en.mdx` show decomposition patterns: quote extraction before answering, and interleaved Thought/Action/Observation trajectories.
- `pages/applications/function_calling.en.mdx` and `notebooks/pe-function-calling.ipynb` show how tool definitions and descriptions become model context for selecting and parameterizing tools.
- `notebooks/pe-rag.ipynb` demonstrates a simple Chroma/SentenceTransformer retrieval flow that injects retrieved short-title examples into a prompt. `notebooks/gemini-context-caching.ipynb` demonstrates caching a large research text file with a TTL and querying it repeatedly.

## Design Choices

- Uses prose-first taxonomy rather than a reusable software framework. This makes it easy to mine concepts but weak as an implementation reference.
- Treats context engineering as a full context-window design problem rather than only prompt wording. The guide includes dynamic fields, query augmentation, tool definitions, structured outputs, few-shot examples, RAG, short-term memory, long-term memory, state, and evaluation.
- Recommends explicit contracts for agent behavior: required task status transitions, allowed status values, output fields, date formats, retry/failure rules, and whether skipped tasks require justification.
- Encourages separation of concerns through planner/worker agents. The deep-dive argues that a single large-context agent forgot searches and state updates, while a dedicated search worker reduced burden and isolated context.
- Promotes observability through external task trackers and logs. This is one of the most transferable ideas for coding agents because context mistakes need visible traces.
- Uses citations and figure-source links for RAG and classic techniques, but newer context-engineering content is partly based on DAIR.AI course material and personal workflow examples rather than reproducible experiments.
- Keeps practical examples close to docs and notebooks, but does not pin all external API behavior or provide tests that prove notebooks still run.

## Strengths

- Strong, reusable vocabulary for context-control design: system layer, task layer, tool layer, memory layer, dynamic context adjustment, validation, completion rules, structured outputs, and historical state.
- Practical attention to agent failure modes: skipped tasks, inconsistent status values, missing debugging visibility, context growth, tool ambiguity, and silent failure.
- Good RAG taxonomy that separates retrieval quality from generation quality and names concrete evaluation dimensions: context relevance, answer faithfulness, answer relevance, noise robustness, negative rejection, information integration, and counterfactual robustness.
- Useful coding-agent analogies: use a plan, delegate narrow work to clean-context workers, store intermediate work outside the conversation, retrieve only relevant memory, and verify outputs.
- Good provenance for RAG and classic prompting pages through paper links and figure-source references.
- Active enough to remain current as a guide: reviewed repo has 1,589 commits, 131 commits since 2025-01-01, and latest pushed commit on 2026-03-11.

## Weaknesses

- Conditional fit because it is a guide, not an agent-support system. It does not provide a prompt registry, schema package, context assembler, memory engine, or evaluation harness.
- Update discipline is mixed. Recent commits include content additions, model pages, UI fixes, and course-promotion updates; this is normal for a public guide but less rigorous than versioned technical docs.
- Some sections are incomplete or labeled as under development, especially advanced context engineering, open-source function calling notes, graph prompting, and coding best practices.
- Newer context-engineering pages include strong claims and useful examples, but they provide limited run logs, ablations, prompt-version history, or measurable before/after evidence.
- API examples are time-sensitive. The notebooks and function-calling examples depend on external providers, environment variables, hosted APIs, and model names that may age quickly.
- The site source has a provenance hazard: `pages/api/getPageContent.ts` fetches raw content from GitHub `main`, so content returned by that API is not pinned to the deployed commit.
- Large translated page set creates review noise; English source pages are the practical review target.

## Ideas To Steal

- Build a "context contract" checklist for every coding-agent workflow: role, task, constraints, current date/time, repo state, allowed tools, output schema, failure behavior, and verification command.
- Require task plans to specify whether each item is mandatory, optional, skipped with justification, or consolidated. Silent skipping should be treated as a context-control bug.
- Keep external task state for long-running agent work: task id, query or goal, status, result summary, timestamp, files touched, and verification evidence.
- Split context by responsibility. Use orchestrator context for goals and integration; use worker context for narrow file/repo/doc search; pass workers only the needed query and return structured findings.
- Define tool descriptions twice: machine schema for the runtime and natural-language usage rules for the model. The guide's function-calling and agent deep-dive both show that descriptions shape tool selection.
- Add "allowed status values" and "required output fields" to prompts whenever downstream automation consumes agent output.
- Treat RAG as context selection, not just retrieval. For coding agents, evaluate retrieved docs/snippets on relevance, faithfulness support, noise robustness, stale-content risk, and whether important context was omitted.
- Cache stable large context, but attach TTL and invalidation rules. The Gemini context-caching notebook suggests a pattern for repeated research sessions; coding agents need similar repo-doc cache boundaries.
- Add context validation before execution: completeness, clarity, consistency, and testability. This can become a preflight step for large implementation tasks.

## Do Not Copy

- Do not copy the repo as a dependency or runtime artifact. It has no reusable context-control API.
- Do not rely on star count or broad popularity as evidence of correctness; use the content as a pattern catalog and verify each pattern in our own workflows.
- Do not copy monolithic prompt examples directly into coding agents. The examples need adaptation to repo state, tool sandbox, patch policy, verification rules, and user interrupt handling.
- Do not treat the RAG survey summary as enough to implement RAG. It needs concrete chunking, indexing, reranking, citation, freshness, and evaluation decisions.
- Do not copy examples that fetch unpinned `main` content when durable provenance matters. Agentic Coding Lab notes and evals should pin commit hashes or captured snapshots.
- Do not adopt course-promotional callouts or UI/navigation patterns; they are not relevant to context-control artifacts.

## Fit For Agentic Coding Lab

High fit as a conceptual source and checklist generator; low fit as code. The repo should inform Lab artifacts such as:

- Context engineering skill/checklist for planning, tool use, memory, and verification.
- Agent prompt schema that separates system, task, tools, memory, state, and output contract.
- Worker-dispatch guidance that keeps sub-agent inputs minimal and outputs structured.
- RAG/context retrieval eval rubric for relevance, faithfulness, freshness, and noise.
- Research-note provenance rule: every external guide/paper pattern must record source path, reviewed commit/date, and evidence type.

The final verdict is "adopt ideas, not implementation." Best transfer is to turn the guide's taxonomy into local templates, lintable prompt contracts, and verification checklists for coding-agent workflows.

## Reviewed Paths

- `README.md`: project overview, guide map, local run instructions, citation, license, and update/course positioning.
- `package.json`: Next/Nextra scripts and dependency shape; confirms docs-site nature and lack of test scripts.
- `CLAUDE.md`: local project note convention and no-push guidance.
- `pages/_meta.en.json`: site navigation and course links.
- `pages/guides/context-engineering-guide.en.mdx`: primary context-engineering taxonomy and multi-agent search-planner prompt example.
- `pages/agents/context-engineering.en.mdx`: practical deep-research-agent context-engineering case study and metrics.
- `pages/agents/context-engineering-deep-dive.en.mdx`: planner/worker architecture, tool descriptions, status-value control, missing metadata, sub-agent communication, context-length management, and error handling.
- `pages/agents/deep-agents.en.mdx`: planning, orchestrator/sub-agent architecture, external memory, context retrieval, context engineering, and verification.
- `pages/agents/components.en.mdx`: planning, tool utilization, short-term memory, and long-term memory components.
- `pages/research/llm-agents.en.mdx`: agent framework, planning with feedback, memory, tools, evaluation, and challenges.
- `pages/research/rag.en.mdx`: RAG taxonomy, advanced/modular RAG, retrieval/generation/augmentation, evaluation, tools, challenges, and research insights.
- `pages/techniques/rag.en.mdx`: short RAG introduction and notebook link.
- `pages/research/rag-faithfulness.en.mdx` and `pages/research/rag_hallucinations.en.mdx`: focused RAG risk notes.
- `pages/introduction/elements.en.mdx` and `pages/introduction/tips.en.mdx`: prompt elements, specificity, separators, and ambiguity reduction.
- `pages/techniques/prompt_chaining.en.mdx`: decomposition into quote extraction and answer synthesis.
- `pages/techniques/react.en.mdx`: Thought/Action/Observation pattern, external tool interaction, and failure modes.
- `pages/applications/function_calling.en.mdx`: function/tool definition context and tool-choice behavior.
- `pages/applications/context-caching.en.mdx`: context caching use case and TTL-based large-context reuse.
- `pages/applications/coding.en.mdx`: code-generation examples and testing warning.
- `notebooks/pe-rag.ipynb`: Chroma/SentenceTransformer retrieval and retrieved-example prompt assembly.
- `notebooks/pe-function-calling.ipynb`: OpenAI function calling flow, tool descriptions, `tool_choice`, and tool-result message loop.
- `notebooks/gemini-context-caching.ipynb`: Gemini cached content with system instruction, file upload, TTL, and repeated queries.
- `pages/api/contentFiles.js`, `pages/api/promptsFiles.js`, and `pages/api/getPageContent.ts`: content-listing and raw-page fetch helpers that shape site provenance.
- Git metadata: latest commit, recent log, total commit count, commits since 2025-01-01, and GitHub REST metadata.

## Excluded Paths

- Translated MDX pages such as `*.fr.mdx`, `*.de.mdx`, `*.kr.mdx`, `*.zh.mdx`, and `ar-pages/`: excluded as duplicates of the English source structure for this review.
- `img/`, `public/`, `lecture/Prompt-Engineering-Lecture-Elvis.pdf`, screenshots, JPEGs, and SVG/icon assets: excluded as binary or visual support paths; reviewed only when source pages referenced their diagrams conceptually.
- `components/` UI controls, announcement bar, counters, copy buttons, icons, course cards, and screenshot components: excluded as site UI, except where course-promo imports indicated provenance/commercial context.
- `theme.config.tsx`, `next.config.js`, `middleware.js`, `tsconfig.json`, lockfiles, and framework wiring: excluded as docs-site infrastructure not shaping context-control patterns.
- Broad model pages, risk translations, paper lists, services/about/course pages, and dataset/tool catalog pages: excluded unless they directly supported context control, RAG, agents, function calling, or coding-agent transfer.
- `.agents/` and `.codex/`: present as empty directories in the reviewed checkout, so no content to evaluate.
