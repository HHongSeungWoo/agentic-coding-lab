# Memory OS of AI Agent

- URL: https://arxiv.org/abs/2506.06326
- Cite as: arXiv:2506.06326; ACL Anthology 2025.emnlp-main.1318
- DOI: 10.18653/v1/2025.emnlp-main.1318
- Authors: Jiazheng Kang, Mingming Ji, Zhe Zhao, Ting Bai
- Venue / source: Proceedings of the 2025 Conference on Empirical Methods in Natural Language Processing, EMNLP 2025 main conference, ACL Anthology.
- Published: arXiv submitted 2025-05-30; ACL Anthology publication dated November 2025, pages 25961-25970.
- Citations snapshot: 4 citations
- Citation source: OpenAlex work W4416035609, `cited_by_count=4`, captured 2026-05-31. Semantic Scholar API check for `arXiv:2506.06326` returned HTTP 429 from the unauthenticated API, so Semantic Scholar was not used for the snapshot.
- Code: https://github.com/BAI-LAB/MemoryOS
- Topic: context-control
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: In-scope as a concrete hierarchical memory/context-control design, but Agentic Coding Lab should borrow the tiered memory lifecycle and retrieval contracts rather than the paper's persona-heavy dialogue system wholesale. The main value is STM/MTM/LPM separation, heat-based promotion, and explicit memory retrieval; the main risks are empirical knobs, stale or noisy memories, privacy exposure, and no direct software-engineering benchmark evidence.

## Problem

Long-running agents lose useful facts when fixed context windows overflow. In conversational settings this causes forgotten preferences, broken temporal continuity, and generic responses. In coding-agent settings the analogous failures are repeated commands, forgotten user constraints, stale hypotheses, lost test output, unsafe file reversions, or context summaries that omit exact paths and errors.

The paper argues that common memory systems handle storage, retrieval, or updating in isolation. MemoryOS instead frames memory as an operating-system-like subsystem with explicit tiers, promotion, eviction, retrieval, and prompt assembly. That is a good fit for the `context-control` topic because it manages what context survives, where it lives, when it is promoted, and how it re-enters the active prompt.

## Method

MemoryOS has four modules:

1. Memory storage organizes state into Short-Term Memory (STM), Mid-Term Memory (MTM), and Long-term Persona Memory (LPM).
2. Memory updating migrates old STM dialogue pages into MTM with FIFO, groups related pages into topic segments, computes heat for MTM segments, and promotes hot segments into LPM.
3. Memory retrieval pulls recent STM pages, performs two-stage MTM retrieval by segment then page, and retrieves LPM persona/knowledge items.
4. Response generation builds a prompt from the current query plus retrieved STM, MTM, and LPM context.

The OS analogy appears mostly in MTM. Conversation turns become "pages"; related pages are grouped into topic "segments." Segment matching combines embedding cosine similarity with keyword Jaccard similarity. Segment heat is a weighted score over retrieval count, interaction length, and recency. Low-heat segments can be evicted when MTM exceeds capacity, while hot segments over threshold `tau=5` update LPM.

The published implementation follows the paper's design at a practical Python level. The PyPI package stores user-specific JSON files for short, mid, and long-term memory. `ShortTermMemory` uses a fixed-size deque. `MidTermMemory` stores sessions with page embeddings, summary embeddings, keywords, heat fields, and FAISS inner-product search. `LongTermMemory` stores a user profile, user knowledge, and assistant knowledge as bounded queues with embeddings. `Retriever` runs MTM, user-knowledge, and assistant-knowledge retrieval in parallel, then `Memoryos.get_response()` assembles recent history, retrieved pages, user profile, and knowledge into the final LLM prompt.

The current repository also exposes a MemoryOS MCP server with `add_memory`, `retrieve_memory`, and `get_user_profile` tools, plus a ChromaDB variant, Docker path, playground, documentation, and LoCoMo reproduction scripts.

## Evidence

The paper evaluates on GVD and LoCoMo, both long-term conversational-memory benchmarks rather than software-engineering tasks. GVD has simulated multi-turn dialogues across 15 virtual users over 10 days. LoCoMo has ultra-long conversations averaging about 300 turns and 9K tokens, with single-hop, multi-hop, temporal, and open-domain question categories.

On GVD, MemoryOS beats the listed baselines:

- GPT-4o-mini: MemoryOS gets 93.3 accuracy, 91.2 correctness, and 92.3 coherence. The paper reports improvements of 3.2%, 5.4%, and 1.0% over the best baseline.
- Qwen2.5-7B: MemoryOS gets 91.8 accuracy, 82.3 correctness, and 90.5 coherence. The reported improvements are 5.3%, 3.5%, and 3.1%.

On LoCoMo, MemoryOS is strong on most categories:

- GPT-4o-mini MemoryOS gets 35.27 F1 / 25.22 BLEU-1 on single-hop, 41.15 / 30.76 on multi-hop, 20.02 / 16.52 on temporal, and 48.62 / 42.99 on open-domain. It ranks first on average F1 and BLEU-1 among the compared reproduced systems, though the original A-Mem number is higher than MemoryOS on GPT-4o-mini multi-hop.
- Qwen2.5-3B MemoryOS gets 23.26 / 15.39 on single-hop, 21.44 / 14.95 on multi-hop, 10.18 / 8.18 on temporal, and 26.23 / 22.39 on open-domain.
- The paper body states average LoCoMo improvements of 49.11% F1 and 46.18% BLEU-1 on GPT-4o-mini. The ACL abstract says 48.36% F1 and 46.18% BLEU-1, so the F1 improvement is inconsistent between metadata/abstract and body text.

Efficiency evidence is mixed but useful. On LoCoMo, the paper reports MemoryOS at 3,874 recalled tokens, 4.9 average LLM calls, and 36.23 average F1. This uses far fewer tokens than MemGPT's 16,977 and far fewer calls than A-Mem*'s 13.0, but more tokens and calls than MemoryBank or TiM. The efficiency win is therefore relative to high-performing memory baselines, not absolute minimal overhead.

Ablations support the tiered design. Removing the whole memory system hurts most; within MemoryOS, MTM has the largest contribution, then LPM, then the dialogue-page chain. Hyperparameter analysis finds that retrieving more MTM pages helps until noise and overhead dominate, and the authors choose `k=10` for LoCoMo.

## Limits

The authors acknowledge two core limitations: memory capacities and thresholds are empirically set rather than grounded in a principled cognitive or systems model, and segment topics depend on the LLM's extraction ability without dynamic merging to resolve overlapping or evolving themes.

The benchmark fit is indirect for Agentic Coding Lab. GVD and LoCoMo test personal dialogue recall, not issue repair, code search, test failure triage, patch planning, or tool-use safety. A coding agent has higher requirements for exactness: file paths, command outputs, stack traces, diffs, dependency versions, user prohibitions, and unresolved risks must be preserved more faithfully than broad user traits.

The implementation also shows operational risks:

- Privacy: user private facts and profiles are extracted into persistent JSON files; the MCP server exposes retrieval/profile tools without a documented authorization model beyond local configuration.
- Staleness: long-term facts are promoted by heat and LLM extraction, but there is no strong validity interval, source pointer, contradiction resolver, or project-state freshness check.
- Prompt fragility: profile and knowledge extraction are natural-language LLM prompts, so malformed outputs, over-extraction, and hallucinated traits can become persistent memory.
- Cost and latency: memory updates require multiple LLM calls for continuity checks, meta summaries, topic summaries, profile analysis, and knowledge extraction.
- Retrieval quality: the code relies on embedding similarity thresholds and FAISS over stored summaries/pages. This is useful, but it is not a guarantee that the retrieved memory is task-relevant or current.
- Product focus: the public package defaults are oriented toward user personalization and short English responses, not coding work.

## Research Themes

- Token efficiency: Medium. MemoryOS reduces recalled tokens relative to MemGPT while preserving better answer quality, but it is not mainly a compression paper and still adds retrieval/update calls.
- Context control: High. It explicitly controls active, mid-term, and long-term context flow, including promotion, eviction, retrieval, and prompt assembly.
- Sub-agent / multi-agent: Low. The system has user and assistant memory plus an MCP server, but it is not a multi-agent coordination architecture.
- Domain-specific workflow: Medium. The paper targets personalized dialogue; the framework can transfer to coding only after replacing persona schemas with coding-state schemas.
- Error prevention: Medium. It prevents some forgetting errors, but can also introduce stale-memory and false-memory errors unless memory entries carry provenance and freshness checks.
- Self-learning / memory: High. The central contribution is persistent memory that updates from interactions via heat, segmentation, and profile/knowledge extraction.
- Popular skills: Medium. The MCP tools and memory lifecycle suggest reusable agent skills around `add_memory`, `retrieve_memory`, profile inspection, and memory hygiene.

## Key Ideas

- Split memory by operational role: recent exact context, topic-organized mid-term context, and distilled long-term knowledge should not be stored or retrieved the same way.
- Treat memory promotion as a lifecycle event. A fact should move upward only when enough use, recency, or interaction evidence justifies it.
- Retrieve in two stages. First identify candidate topics/segments, then pull exact pages within those segments.
- Use bounded queues for long-term knowledge. Memory needs deletion and capacity pressure, not only append-only accumulation.
- Keep response generation separate from memory management. The agent should see a composed context view rather than manually managing all storage layers every turn.
- Expose memory as tools. MCP-style `add_memory`, `retrieve_memory`, and `get_user_profile` map naturally to host-owned memory inspection and debugging.

## Ideas To Steal

- Build a three-tier coding memory contract:
  - STM: current goal, latest user constraints, recent edits, recent commands, exact failing outputs, and next action.
  - MTM: topic segments such as "auth bug investigation," "test harness setup," "migration decision," or "dependency conflict," each with exact page references.
  - LTM: durable project lessons, recurring user preferences, known repo conventions, and stable verification practices.
- Replace persona extraction with coding-state extraction. Promote fields like `files_touched`, `commands_run`, `failures_seen`, `hypotheses_rejected`, `decisions_made`, `open_risks`, `source_refs`, and `expires_when`.
- Use heat as a prioritization signal, but make it typed. Test failures and explicit user constraints should have higher promotion weight than chatty discussion volume.
- Add memory provenance. Every promoted memory should link back to source turn, command output, file path, or note path so a coding agent can audit why it believes the fact.
- Add freshness and invalidation. Memories about code, dependencies, APIs, and tests should expire or be revalidated when files, commits, package versions, or dates change.
- Provide a memory debugger. A `retrieve_memory`-like tool should show what would enter the prompt, why it matched, its age, confidence, and source, before it affects the agent.
- Keep memory host-owned. For Agentic Coding Lab, the harness should enforce storage schemas, redaction, scope, and update rules instead of letting the model silently write arbitrary memories.
- Test memory as behavior. Create long-session coding regressions where the correct final action depends on facts mentioned many turns earlier, and score whether the memory system retrieves the exact fact without importing stale or unrelated facts.

## Do Not Copy

- Do not copy the 90-dimension user-persona schema for coding agents. It is too personal, too broad, and mostly irrelevant to code correctness.
- Do not use heat alone as truth. Frequently accessed memories can still be wrong, obsolete, or poisoned.
- Do not persist private user facts without explicit scope, redaction, and inspection controls.
- Do not treat LLM-generated profiles or summaries as authoritative. They need source links, review surfaces, and contradiction handling.
- Do not let old project memories override the current repository state. Code, tests, and current user instructions must remain higher authority.
- Do not use a single global memory namespace for all projects or agents. Coding memories need project, branch, task, and user boundaries.
- Do not assume benchmark gains transfer to software engineering. LoCoMo success only validates long-dialogue recall and personalization.
- Do not hide memory retrieval inside the final prompt. Agentic workflows need visibility into which memories were selected and why.

## Fit For Agentic Coding Lab

MemoryOS is a strong pattern source for context-control architecture, not an adoption target. It gives Agentic Coding Lab a concrete vocabulary for memory tiers and lifecycle operations:

- `short-term`: active turn/session facts that should remain exact and local.
- `mid-term`: topic-indexed work traces that can be retrieved by semantic/task similarity.
- `long-term`: stable lessons or conventions that are promoted only with provenance and invalidation rules.

The most useful design move is making memory management a subsystem with explicit storage, update, retrieval, and generation phases. For coding agents, that subsystem should be schema-first and evidence-first. A memory item should not merely say "the user prefers concise answers"; it should say "for this repo, run `rtk sh bootstrap/test_research.sh` before finalizing research notes, sourced from AGENTS/RTK instructions, valid until changed." That turns MemoryOS's conversational memory idea into a practical coding-lab context-control mechanism.

## Related Repositories

- https://github.com/BAI-LAB/MemoryOS - Official implementation. Captured 2026-05-31 via GitHub API at commit `1d717060350931af33d1d0dc3d4e50a72c125a48`; 1,413 stars, 137 forks, Apache-2.0 license, Python. The repo includes PyPI, MCP, ChromaDB, playground, Docker, documentation, and LoCoMo evaluation paths.
- https://bai-lab.github.io/MemoryOS/docs - Official documentation page. It documents package setup, MCP tools, configuration parameters, and the high-level memory lifecycle.
- https://baijia.online/memoryos/ - Linked MemoryOS playground/project page from the README. The README says an invitation code may be needed for the online platform.

## Reviewed Sources

- arXiv abstract page: https://arxiv.org/abs/2506.06326
- arXiv PDF v1: https://arxiv.org/pdf/2506.06326
- ACL Anthology page: https://aclanthology.org/2025.emnlp-main.1318/
- ACL Anthology PDF: https://aclanthology.org/2025.emnlp-main.1318.pdf
- OpenAlex API work record: https://api.openalex.org/works/W4416035609
- Semantic Scholar API attempted: https://api.semanticscholar.org/graph/v1/paper/arXiv:2506.06326?fields=title,citationCount,influentialCitationCount,externalIds,venue,year,publicationDate,authors,url,openAccessPdf
- Official code repository: https://github.com/BAI-LAB/MemoryOS
- Official documentation: https://bai-lab.github.io/MemoryOS/docs
- Implementation checkout reviewed at `/tmp/myagents-research/BAI-LAB-MemoryOS`, commit `1d717060350931af33d1d0dc3d4e50a72c125a48`.
- Implementation files reviewed: `README.md`, `memoryos-pypi/memoryos.py`, `memoryos-pypi/short_term.py`, `memoryos-pypi/mid_term.py`, `memoryos-pypi/long_term.py`, `memoryos-pypi/retriever.py`, `memoryos-pypi/updater.py`, `memoryos-pypi/prompts.py`, `memoryos-pypi/utils.py`, `memoryos-mcp/server_new.py`, and `eval/main_loco_parse.py`.
