# MemGPT: Towards LLMs as Operating Systems

- URL: https://arxiv.org/abs/2310.08560
- Cite as: arXiv:2310.08560
- DOI: 10.48550/arXiv.2310.08560
- Authors: Charles Packer, Sarah Wooders, Kevin Lin, Vivian Fang, Shishir G. Patil, Ion Stoica, Joseph E. Gonzalez
- Venue / source: arXiv preprint, UC Berkeley project page
- Published: arXiv submitted 2023-10-12; v2 revised 2024-02-12
- Citations snapshot: OpenAlex 41 cited-by count; Semantic Scholar 721 citation count
- Citation source: OpenAlex work W4387636003, `cited_by_count=41`, and Semantic Scholar paper 908dad62c0e43d80e3e3cb3c0402f7c71c70499c, `citationCount=721`, captured 2026-05-31. The two services disagree substantially, so both are recorded.
- Code: https://github.com/cpacker/MemGPT redirects to https://github.com/letta-ai/letta; project page at https://research.memgpt.ai
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Foundational context-control paper. MemGPT's durable contribution is the OS-style separation between bounded active context, mutable working memory, recall logs, archival storage, memory-pressure interrupts, and function-call based paging. Agentic Coding Lab should borrow the tiered memory and audited page-in/page-out pattern, but not the claim that self-directed memory management alone is enough for reliable coding agents.

## Problem

MemGPT targets a core failure of long-horizon agents: the model's fixed prompt window is treated as if it were the whole state of the task. Long conversations, document collections, and agent traces quickly exceed that window. Simply training or buying longer-context models is expensive, still exposes models to "lost in the middle" behavior, and does not provide an explicit policy for what should remain active, what should be stored, and how stale information should be retrieved.

The paper reframes the problem as virtual context management. The model should see a bounded "physical memory" prompt, while an agent runtime manages slower external stores that can be searched, paged into context, or updated through explicit operations.

This is directly relevant to Agentic Coding Lab. Coding agents accumulate file paths, user constraints, failed commands, diffs, hypotheses, test results, environment details, and unresolved risks. A flat chat transcript makes those facts compete with every other token. MemGPT provides an early architecture for making context placement an explicit runtime responsibility instead of a passive truncation accident.

## Method

MemGPT divides state into main context and external context.

Main context is the prompt passed to the LLM. It has three regions:

1. System instructions: static, read-only instructions describing the memory hierarchy, function schemas, and control-flow rules.
2. Working context: a fixed-size read/write text block edited only through MemGPT functions. In chat settings this holds key user facts, persona facts, preferences, and other high-value state.
3. FIFO queue: the rolling event/message history. It contains user and agent messages, system messages such as memory-pressure warnings, function inputs, function outputs, and a recursive summary of evicted messages.

External context has two stores:

1. Recall storage: a message database. The queue manager writes incoming messages and model outputs to it, and retrieved messages can be appended back into the FIFO queue.
2. Archival storage: a read/write store for arbitrary-length text objects. In the document QA experiments it is implemented with PostgreSQL, pgvector, HNSW indexing, and OpenAI text-embedding-ada-002 embeddings.

The queue manager appends new events to the FIFO queue, assembles the prompt, and triggers LLM inference. It also enforces capacity policy. At a warning threshold, described as 70% of the model context window in the paper, it inserts a memory-pressure system message so the model can preserve important information before eviction. At a flush threshold, described as 100%, it evicts a configured amount of queue content, updates the recursive summary, and keeps evicted messages retrievable from recall storage.

The function executor parses model completions as function calls, validates arguments, executes memory operations, and feeds results or runtime errors back to the model. Retrieval is paginated so a memory search cannot overflow the active prompt. Control flow is event based: user messages, system alerts, uploads, and timed events can trigger inference. A function call can include `request_heartbeat=true` to immediately return control to the model for another inference step, allowing multi-step retrieval before yielding to the user.

## Evidence

The paper evaluates MemGPT in multi-session chat and document analysis.

For multi-session chat, the authors extend the Multi-Session Chat dataset with a deep memory retrieval task. The agent must answer questions that require facts from earlier sessions rather than persona summaries alone. MemGPT improves every underlying model in Table 2:

- GPT-3.5 Turbo baseline: 38.7% accuracy and 0.394 ROUGE-L recall; MemGPT: 66.9% and 0.629.
- GPT-4 baseline: 32.1% accuracy and 0.296 ROUGE-L recall; MemGPT: 92.5% and 0.814.
- GPT-4 Turbo baseline: 35.3% accuracy and 0.359 ROUGE-L recall; MemGPT: 93.4% and 0.827.

For the conversation-opener task, MemGPT variants produce openings that use prior-session information and score similarly to or above the hand-written human opener under the paper's similarity metrics. The authors explicitly attribute engagement quality to storing important information in working context.

For document QA, MemGPT is evaluated on a retriever-reader setup using NaturalQuestions-Open questions and Wikipedia documents. The fixed-context baselines receive top-k retrieved documents in prompt. MemGPT instead loads the document collection into archival storage and can query it repeatedly through function calls. Figure 5 reports that MemGPT with GPT-4 or GPT-4 Turbo remains stable as the available retrieved-document pool grows, while fixed-context approaches depend on how much retrieved text fits or survives truncation.

The nested key-value task tests multi-hop retrieval. Values can themselves be keys, so the agent must keep looking up until a terminal value is reached. GPT-3.5 drops to 0% accuracy at one nesting level, while GPT-4 and GPT-4 Turbo drop to 0% by three nesting levels. MemGPT with GPT-4 stays reliable through the tested nesting depths, showing that function chaining plus explicit memory lookup can outperform one-shot long-context lookup.

The linked project page released paper, GitHub, and dataset links. The original `cpacker/MemGPT` code URL now redirects to `letta-ai/letta`, whose current README describes Letta as the successor to MemGPT for stateful agents with advanced memory, memory blocks, skills, and subagents. GitHub REST API data captured 2026-05-31 showed `letta-ai/letta` with 23,054 stars, Apache-2.0 license, and current version 0.16.8 in `pyproject.toml`.

## Limits

MemGPT is a foundational architecture, not a complete reliability story.

The strongest results depend on models with competent function calling. The paper reports degraded MemGPT performance with GPT-3.5 on document analysis and nested KV because it fails to perform enough lookups. This matters for coding agents: if the base model does not reliably call tools, search further, or handle errors, the memory hierarchy will not save the workflow.

The system can still stop too early. In document QA, the authors observe that MemGPT often stops paging through retriever results before exhausting the database, even though the gold document may appear deeper in the ranking. This exposes a policy gap: giving the model a search API is not the same as having a robust retrieval budget, stopping rule, or proof of exhaustiveness.

The evaluations are not software-engineering tasks. Multi-session chat and synthetic nested KV transfer well conceptually, but they do not test repository-scale code changes, failing test diagnostics, file edits, build artifacts, or user safety constraints. The DMR questions are generated with an LLM and judged with an LLM, which is useful but not enough evidence for high-stakes agent memory correctness.

The memory writes are self-directed natural-language edits. That is flexible, but it can also preserve incorrect facts, overwrite nuanced state, or blend provenance. The paper does not deeply address memory poisoning, prompt injection through retrieved content, privacy boundaries, multi-user access control, or transactional memory updates.

"Infinite context" remains an illusion. External memory is only useful when the agent asks the right questions, receives bounded results, and moves the right evidence into the active context. The runtime needs budgets, provenance, validation, and observability around those operations.

## Research Themes

- Token efficiency: Medium relevance. MemGPT reduces pressure on the active prompt by paging context in and out, but function-call chains and repeated retrieval can increase latency and total tokens.
- Context control: Very high relevance. The paper is explicitly about managing what enters, remains in, leaves, and re-enters the model's bounded context window.
- Sub-agent / multi-agent: Low relevance. MemGPT is an agent runtime with memory functions, not a multi-agent coordination method.
- Domain-specific workflow: High relevance. The prompts and memory policy differ for chat, document QA, and nested KV. Coding agents would need their own memory schema and stopping rules.
- Error prevention: Medium-high relevance. Memory-pressure warnings, parser validation, runtime error feedback, and paginated retrieval reduce some context-loss failures, but the paper does not provide coding-specific invariants.
- Self-learning / memory: High relevance. The system persists user and document state outside the prompt and lets the model update working memory over time, though it does not update model weights.
- Popular skills: Medium relevance. The system prompt plus function schema behaves like a reusable skill for context management; modern agent skills can adopt the same explicit memory-operation contract.

## Key Ideas

- Treat the prompt window as scarce main memory, not as the whole task state.
- Split memory by role: static instructions, mutable working context, rolling event queue, recall log, and archival store.
- Warn the model before eviction. A memory-pressure event gives the agent a chance to preserve high-value facts before the FIFO queue is flushed.
- Make memory movement explicit. Search, insert, replace, and page operations are functions whose results are reintroduced into context.
- Use event-driven control flow. User input, system alerts, uploads, and timed events can all trigger memory maintenance or response generation.
- Allow bounded function chaining. The `request_heartbeat=true` pattern lets the agent continue retrieval or memory edits before yielding a final user response.
- Paginate retrieval. Memory search results need page boundaries and counts so the model can traverse evidence without overflowing its own context.
- Keep raw recall separate from summaries. Summaries are useful, but recoverability improves when evicted raw messages remain searchable.

## Ideas To Steal

- Build a coding-agent memory hierarchy with explicit tiers: active working state, recent event queue, raw command/test/edit recall log, and archival project knowledge. Do not rely on one generic transcript summary.
- Add memory-pressure interrupts to long runs. Before compaction or context flush, ask the agent to preserve exact file paths, commands run, failing outputs, user constraints, current hypothesis, modified files, and unresolved risks.
- Make context operations first-class tools. Provide typed operations such as `remember_fact`, `replace_fact`, `search_trace`, `search_project_notes`, `page_result`, and `mark_stale`, with budgets and provenance in every result.
- Preserve raw evidence behind summaries. Summaries should point back to command outputs, diffs, files, and timestamps so a later agent can verify instead of trusting compressed prose.
- Use heartbeat-style internal loops for retrieval, but cap them. A coding agent should be able to search, page, and inspect before answering, while the runtime enforces maximum iterations and requires a stopping reason.
- Separate recall from archival memory. Recent shell outputs and test failures need exact replayable recall; durable project lessons need curated archival memory with provenance and aging.
- Treat memory edits as auditable events. Log who or what wrote the memory, what source evidence justified it, what previous value was replaced, and when it should be revalidated.
- Create SWE-specific retrieval stopping rules. For example: keep searching until the failing test name, edited file, or exact error string has either been found or declared absent with a bounded search trace.

## Do Not Copy

- Do not market "infinite context" as reliability. It is a useful abstraction only when retrieval policy, paging budget, and provenance are engineered.
- Do not let the model freely rewrite durable coding memory without review or source links. Incorrect memories about commands, APIs, or repo conventions can cause repeated failures.
- Do not store code facts only as semantic vector memories. Exact paths, symbols, error lines, test names, hashes, and diffs need structured or lexical lookup as well.
- Do not assume memory search should continue until the model feels satisfied. Use explicit budgets, stopping criteria, and failure modes.
- Do not copy chat-persona memory policies into coding. Personalization and conversational engagement are not the same as preserving build state, constraints, and verification evidence.
- Do not rely on LLM judges alone for memory quality. Coding-agent memory should be evaluated by downstream task success, regression tests, and reproducible command outcomes.
- Do not ignore prompt-injection and privacy boundaries. Archival memory can contain untrusted content, secrets, user data, and stale instructions.

## Fit For Agentic Coding Lab

MemGPT is in-scope for `context-control` because it turns context from a passive token buffer into an actively managed runtime resource. The paper is especially valuable as a vocabulary and architecture reference: main context, external context, working context, recall storage, archival storage, memory pressure, eviction, paging, and interrupts.

For Agentic Coding Lab, the practical adaptation should be stricter than MemGPT's original chat setting. A coding runtime should treat memory as a typed state machine with source-backed entries, not just editable prose. Each durable memory item should carry provenance, confidence, freshness, and deletion/update rules. Retrieval should combine semantic search with exact matching over paths, commands, errors, test names, and symbols.

The strongest artifact candidate is a "context OS" contract for coding agents:

1. Define active context slots for goal, constraints, files touched, current hypothesis, latest failing evidence, and next action.
2. Keep a raw recall log for commands, tool outputs, diffs, and agent decisions.
3. Maintain curated archival notes for durable repo conventions and user preferences.
4. Trigger memory-pressure reviews before compaction.
5. Require retrieval traces and stopping reasons before claims that information is unavailable.
6. Evaluate memory policies by whether agents finish coding tasks with fewer repeated commands, fewer lost constraints, and better verification behavior.

The paper should be treated as a design seed, not as final implementation guidance. Its biggest lesson is that context management belongs in the agent runtime API, with observable operations and control flow, rather than being hidden inside summarization prompts.

## Related Repositories

- https://github.com/cpacker/MemGPT - Original linked repository from the paper/project page; currently redirects to `letta-ai/letta`.
- https://github.com/letta-ai/letta - Successor project, "Letta (formerly MemGPT)." GitHub REST API captured 2026-05-31 showed 23,054 stars, 2,455 forks, Apache-2.0 license, Python as the primary language, and `pyproject.toml` version 0.16.8. Current README describes stateful agents, memory blocks, tools, Letta API, Letta Code, skills, and subagents.
- https://research.memgpt.ai - Official paper project page with paper, GitHub, Discord, and Hugging Face dataset links.
- https://huggingface.co/MemGPT - Linked Hugging Face organization for released MemGPT datasets/models; page showed 8 datasets and 1 model when reviewed.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2310.08560
- arXiv PDF v2: https://arxiv.org/pdf/2310.08560
- ar5iv HTML full text: https://ar5iv.labs.arxiv.org/html/2310.08560
- Official project page: https://research.memgpt.ai
- Current Letta site redirected from `memgpt.ai`: https://www.letta.com
- Original/current code repository: https://github.com/cpacker/MemGPT and https://github.com/letta-ai/letta
- Letta README reviewed from raw GitHub: https://raw.githubusercontent.com/letta-ai/letta/main/README.md
- Letta citation file reviewed from raw GitHub: https://raw.githubusercontent.com/letta-ai/letta/main/CITATION.cff
- Letta package metadata reviewed from raw GitHub: https://raw.githubusercontent.com/letta-ai/letta/main/pyproject.toml
- GitHub REST API repository record: https://api.github.com/repos/letta-ai/letta
- OpenAlex API work record: https://api.openalex.org/works/W4387636003
- Semantic Scholar Graph API record: https://api.semanticscholar.org/graph/v1/paper/arXiv:2310.08560
- Hugging Face MemGPT organization: https://huggingface.co/MemGPT
