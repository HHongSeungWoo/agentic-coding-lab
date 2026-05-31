# Reason-Wang/ToolGen

- URL: https://github.com/Reason-Wang/ToolGen
- Category: tool-use
- Stars snapshot: 179 (GitHub REST API repository endpoint, captured 2026-05-31; matches index snapshot 179 captured 2026-05-29)
- Reviewed commit: 6839374a255810efe69deea4056eec5c55e25802
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal research implementation for runtime-skill-routing because it attacks the 10,000+ capability problem by moving tool selection into generation itself: every API is represented as a virtual tool token, retrieval is next-token prediction over that token space, and action generation is constrained to valid tool tokens. It is not directly production-ready for dynamic skill libraries because adding new skills requires tokenizer/model updates or continual training, but the runtime footprint and execution loop are exactly the kind of alternative to description-heavy shortlist retrieval that Agentic Coding Lab should study.

## Why It Matters

ToolGen is directly aligned with the user's real question: how can an agent choose from a huge capability pool without putting every skill description into the prompt? The paper and repo target the same scaling failure. Traditional tool systems put tool schemas in context or add a separate retrieval stage; ToolGen instead teaches the model to emit a compact tool token from the task context.

The repo matters because it gives an executable shape, not just a paper idea. It includes the public `OpenAgent.ToolGen` runtime, vocabulary expansion code, three-stage training scripts, retrieval evals against BM25/embedding/ToolRetriever/long-context baselines, and an end-to-end ToolBench/StableToolBench loop that turns generated tool tokens into real RapidAPI calls.

For Agentic Coding Lab, the transferable idea is not "fine-tune every local skill into the base model tomorrow." The useful design pattern is an activation vocabulary: expose compact skill IDs or learned activation tokens at action-selection time, fetch only the selected skill's full documentation after selection, and keep execution authority separate from prompt exposure.

## What It Is

ToolGen is the official implementation of the ICLR 2025 paper "ToolGen: Unified Tool Retrieval and Calling via Generation." The paper page and arXiv abstract describe the core premise: represent tools as unique tokens, train an LLM to generate those tokens, then use the generated token both for retrieval and tool calling. The paper reports experiments with more than 47,000 tool/API actions from ToolBench.

The repository contains four main parts:

- `OpenAgent/`: the cleaned runtime package exposed by `from OpenAgent import ToolGen, RapidAPIWrapper`.
- `training/`: tokenizer/model loading, virtual-token embedding initialization, chat dataset loading, and DeepSpeed training scripts for memorization, retrieval, and end-to-end agent tuning.
- `evaluation/retrieval/`: retrieval benchmarks for ToolGen, BM25, dense encoders, OpenAI embeddings, and a long-context LLM baseline.
- `evaluation/toolbench/`: a vendored/adapted ToolBench inference stack for end-to-end task completion with generated actions, argument generation, RapidAPI execution, and StableToolBench-style scoring.

The public README points users to Hugging Face model and dataset collections, including `reasonwang/ToolGen-Llama-3-8B`, Qwen2.5 variants, and `reasonwang/ToolGen-Datasets`. The repo itself includes `training/src/configs/virtual_tokens.txt` with 46,985 virtual tokens.

## Research Themes

- Token efficiency: Very strong at action-selection time. The model does not need 47k tool descriptions in context; a selected API is a one-token action under atomic indexing. Runtime still injects selected tool documentation after the action token is generated so the model can produce arguments.
- Context control: Strong conceptual fit. Tool descriptions move from always-visible prompt text to lazy documentation lookup keyed by generated token. The implementation uses a fixed system prompt plus conversation history, then appends only the chosen tool's documentation for argument generation.
- Sub-agent / multi-agent: Low. The implementation is a single-chain agent. There is no delegation, role-specific router, or multi-agent skill ownership model.
- Domain-specific workflow: Moderate. The system is built around ToolBench/RapidAPI, not coding workflows. The pattern can transfer to coding skills if skills can be represented as stable activation IDs and backed by documentation/resources.
- Error prevention: Strong for nonexistent action names when constrained decoding is enabled; the trie/logits processor masks non-tool tokens. Weaker for argument correctness, tool side effects, dynamic tool drift, and API safety.
- Self-learning / memory: Low. Training is offline SFT-style. There is retry logic and trajectory fine-tuning, but no online activation telemetry, per-user memory, or automatic skill pruning.
- Popular skills: Generative tool retrieval, virtual tool tokens, atomic/semantic/numeric/hierarchical tool indexing, constrained beam search over valid tool IDs, three-stage tool memorization/retrieval/agent tuning, lazy documentation injection, ToolBench/StableToolBench evaluation, action-token-to-executor mapping.

## Core Execution Path

The central runtime is `OpenAgent.agents.toolgen.toolgen.ToolGen`. Initialization loads a Hugging Face tokenizer and causal LM, sets the template-specific EOS token, loads a mapping from ToolBench function names to ToolGen tokens, loads tool documentation, and builds a disjunctive trie over all valid action-token ID sequences. That trie is used by `AllowKeyWordsProcessor` to mask invalid next tokens during action generation.

At runtime, `SingleChainAgent.start()` creates a root state, then repeatedly calls `ToolGen.parse()`. `parse()` converts the current conversation into the ToolGen prompt format. It optionally generates a natural-language thought, appends a user turn asking the model to "Generate the action.", and calls `generate(..., restrict_actions=True)` so the next output must be one of the virtual tool tokens or `Finish`.

After the model emits a tool token, `calling()` looks up the token in `self.tool_documentation`. Only then does it append the selected tool's documentation to the conversation and ask the model to generate arguments. This is the runtime context trick: the full tool catalog is not in the prompt; only the chosen tool's documentation appears after selection.

`parse()` maps the generated virtual token back into a ToolBench/OpenAI-style function name through `self.token_to_toolbench_name`. It returns an assistant message containing a `tool_calls` entry with the selected function name and generated arguments. `SingleChainAgent.take_action()` then invokes the environment wrapper with that function call.

The public `RapidAPIWrapper` loads the full tool package from Hugging Face `tools.json`, converts APIs into OpenAI-function-like schemas, and keeps maps from function name to category, tool name, and API name. When called, it checks whether the action is `Finish`; otherwise it validates that the generated action name exists in `self.functions`, builds a StableToolBench/RapidAPI payload, and posts it to the configured service. A generated action therefore becomes execution authority only if it resolves through this host-side function map.

The training path mirrors the paper. First, tokenizer/model loading adds virtual tokens from `training/src/configs/virtual_tokens.txt`, resizes embeddings, and initializes each virtual token embedding with the mean embedding of its component tool/API words. Second, tool memorization trains documentation-to-token examples for 8 epochs. Third, retrieval training trains query-to-token examples for 1 epoch. Finally, end-to-end agent tuning trains on trajectory data with a longer 6,144-token max length so the model learns thought, action token, argument generation, observations, and final answer behavior.

## Architecture

ToolGen has three planes:

- Model/vocabulary plane: the LLM vocabulary is expanded with virtual tool tokens. Under atomic indexing, a token looks like `<<Tool Name&&API Name>>` and is intended to tokenize as exactly one new token.
- Runtime control plane: `ToolGen.parse()` decomposes each step into planning, action token generation, and argument generation. Constrained decoding is applied only for the action token phase.
- Execution plane: `RapidAPIWrapper` and the ToolBench inference environment map generated action names to executable API calls and status codes.

The mapping files are the join between these planes. `Tool2AtomicId.json` or `Tool2Id.json` maps normalized ToolBench names to virtual tokens. `tools.json` contains the documentation and parameter metadata. The tokenizer must already know the virtual tokens, or the generated/action token IDs will not line up with the runtime documentation and executor maps.

The constrained decoder uses a disjunctive trie. Every valid action string is tokenized, EOS is appended, and the trie tells the logits processor which next token IDs are valid for the current generated prefix. Under atomic indexing this mostly becomes a one-token choice among 46,985 tool tokens plus finish. Under semantic/numeric/hierarchical indexing it supports multi-token action IDs.

Evaluation is split into retrieval and end-to-end task completion. Retrieval evals use ToolBench query/corpus/qrels files and report NDCG@1/3/5. End-to-end evals use the ToolBench/StableToolBench task runner with Solvable Pass Rate and Solvable Win Rate, comparing ToolGen with GPT-3.5, ToolLlama, ToolRetriever-backed settings, and ground-truth-tool settings.

## Design Choices

The biggest design choice is treating tool retrieval as generation, not vector lookup. The model's next-token distribution over tool tokens is the selector. This removes a separate retriever at runtime and eliminates prompt pressure from large tool catalogs.

Atomic indexing is the production-favored representation in this repo. It gives each API one unique vocabulary token, reducing action generation to one token and avoiding sequence-length bias. The paper compares atomic with semantic, numeric, and hierarchical encodings. Semantic indexing can perform well in retrieval because names carry meaning, but it introduces multi-token generation, beam-search bias toward longer names, and higher end-to-end hallucination risk.

Tool documentation is fetched after action selection. This is important because it separates "which tool?" from "how do I call it?" The selected token carries the identity; the runtime provides full parameter documentation only for that identity.

The training process intentionally separates knowledge phases. Memorization aligns documentation with tool IDs. Retrieval training aligns user requests with tool IDs. Agent tuning aligns trajectories with selection, argument generation, observations, and finishing.

The runtime keeps execution host-mediated. The model can generate a token, but the host maps that token into a known function and rejects unknown names. The `Finish` tool is also handled by the environment wrapper rather than trusted as free-form text.

The implementation assumes a mostly fixed tool universe. Appendix B of the paper explicitly acknowledges that generative retrieval systems have difficulty adopting totally new tools without continual training or similar update methods. That is a major design tradeoff for skill libraries.

## Strengths

ToolGen directly addresses the context blow-up problem. It is one of the clearest examples of an agent selecting from tens of thousands of tools without seeing their descriptions in the prompt.

The action-token abstraction is clean. It makes tool selection inspectable, compact, and constrainable. A generated activation token can be logged, scored, masked, or mapped to documentation and permissions.

Constrained decoding gives a real hallucination control for action names. In the action phase, invalid tool IDs can be masked out at the logits level rather than merely discouraged by prompt text.

The lazy documentation lookup is highly transferable. Even without fine-tuning, a skill router can copy the split: choose a compact skill ID first, then load only that skill's full instruction/resources for argument or execution planning.

The repo includes enough implementation detail to study the full path: virtual-token creation, embedding initialization, training data loading, inference prompts, action constraints, executor mapping, retrieval benchmarks, and end-to-end tool execution.

The evaluation setup is much more relevant than small toy tool-calling demos. ToolBench's 16k+ tool collections and 47k API actions are close to the scale where ordinary prompt-bound tool descriptions break down.

The reported retrieval numbers are strong in the paper: in multi-domain retrieval, ToolGen reports NDCG@1/3/5 of 87.67/88.84/91.54 for I1, 83.46/86.24/88.84 for I2, and 79.00/79.80/84.79 for I3, outperforming BM25, embedding similarity, and ToolRetriever in that setting. End-to-end retrieval-setting averages are also reported above the compared baselines: SoPR 53.28 and SoWR 51.51.

## Weaknesses

The fixed vocabulary is the core operational weakness. A real skill system changes constantly: skills are installed, updated, disabled, forked, namespaced, and scoped per project. ToolGen's approach needs new tokens and likely continued training for substantially new tools or changed usage scenarios.

Training cost is high. The README training script expects multi-GPU DeepSpeed runs, including 8 epochs for memorization and long-context agent tuning. This is not a lightweight router that can be rebuilt on every project checkout.

The runtime still needs a full host-side tool package. `RapidAPIWrapper` loads `tools.json` and keeps all function maps locally. ToolGen saves model context, but it does not by itself solve process-memory, dependency import, permission, or supply-chain scale.

The action selector is learned from ToolBench data, so transfer to coding skills is not automatic. Coding skills are longer, more procedural, often file/context-dependent, and may require "when not to use" constraints that ToolBench API docs do not capture.

Execution safety is mostly name validation plus API status handling. There is no permission model, side-effect classifier, approval gate, sandbox policy, provenance check, or per-user allowlist.

Argument generation still relies on prompt-provided documentation and free-form model output. The repo validates action existence, but it does not provide a robust typed argument repair loop comparable to modern structured-output runtimes.

The implementation has rough edges typical of research code. Some paths duplicate ToolGen classes between `OpenAgent` and `evaluation/toolbench`, many scripts assume local `data/` downloads and GPU/CUDA, some code uses hard-coded model/token IDs, and upstream tests are not packaged as a simple CPU test suite.

Reported metrics are paper-level, not a turnkey reproducibility result in this checkout. The repo requires external Hugging Face datasets/models, ToolBench keys, StableToolBench service setup, GPUs, and OpenAI keys for several baselines.

## Ideas To Steal

Introduce compact activation IDs for skills. A skill does not need its full markdown description in the initial context if the runtime can first choose `skill:<id>` and then load the selected skill.

Separate activation from instruction loading. The first phase should answer "which skill ID should be active?" The second phase should fetch full `SKILL.md`, examples, scripts, and constraints only for that ID.

Use a constrained action space for skill activation. Even if we do not fine-tune model vocabulary, the host can constrain `activate_skill` arguments to known IDs through structured output, trie decoding, grammar decoding, or post-generation validation with retry.

Treat skill descriptions as training/eval data, not only prompt text. ToolGen's memorization and retrieval phases suggest building datasets from `(task, selected_skill_id)`, `(skill_doc, skill_id)`, and `(trajectory, activated_skill_ids)` records.

Keep a host-side activation map. The model should generate a compact ID; the host should resolve that ID to documentation, resources, allowed tools, and permissions. Generated IDs should never directly imply execution authority.

Design an "atomic plus semantic" hybrid. Atomic IDs are stable and constrainable, but semantic metadata helps zero-shot routing. A practical skill router can use semantic retrieval to shortlist and atomic IDs for final activation/execution.

Evaluate at large action-space size. ToolGen is valuable because it tests beyond dozens of tools. Agentic Coding Lab should build synthetic and real evals at 1k, 10k, and 50k skill/tool candidates, measuring top-k accuracy, context tokens, latency, hallucinated IDs, and downstream task success.

Use lazy documentation injection as a hard budget rule. For each action step, include only the currently selected skill's detailed docs unless a task explicitly needs multiple skills.

Log activation tokens as telemetry. ToolGen-like selection gives clear events: prompt context, generated skill ID, selected docs loaded, execution attempted, status code, retry, and final success. That data can power pruning and reranking.

## Do Not Copy

Do not bake every changing local skill into model weights. It makes installation, updates, user-specific packs, and project-scoped skills too expensive.

Do not assume action-token validity equals safe execution. A valid generated skill ID still needs policy checks, trust/provenance checks, side-effect classification, and user/project authorization.

Do not drop descriptions entirely. ToolGen still fetches documentation after selection for argument generation. Skills need the same: compact activation first, rich instruction second.

Do not use ToolBench API metrics as a proxy for coding-skill success. ToolBench APIs have names, parameters, and query labels; coding skills often encode multi-step workflows, repo conventions, and negative triggers.

Do not make the skill universe global and static. Agentic Coding Lab needs project-enabled scopes, host compatibility, versioning, and fast install/remove semantics.

Do not rely only on SFT. Runtime skill routing should combine deterministic filters, retrieval, constrained activation, telemetry, and possibly learned rerankers. ToolGen's learned selector is powerful but expensive to keep fresh.

Do not copy research-code assumptions into production: hard-coded CUDA, required external data layout, duplicate classes, unrestricted API execution service URLs, and scripts that assume private keys should stay out of the runtime core.

## Fit For Agentic Coding Lab

Fit is strong as a research pattern for runtime-skill-routing, especially as a counterpoint to registry and marketplace repos. ToolGen shows the far end of the design space: instead of shrinking skill descriptions with better metadata, make skill activation a compact generation target and load documentation lazily.

The practical Agentic Coding Lab version should be lighter. Start with a compact `skills.index.json` or vector/hybrid index, route to a shortlist, then force the model to choose from stable skill IDs via structured output. Only after an ID is selected should the host load full skill content. This gives many of ToolGen's context benefits without retraining the base model for every skill update.

For high-volume built-in skill packs, ToolGen suggests a future learned activator. If the Lab accumulates enough telemetry, it could fine-tune or train a small selector model on `(task context, skill ID)` pairs while keeping the main agent model unchanged.

The execution boundary should be stricter than ToolGen's research runtime. A generated skill ID should pass through allowlists, project policy, side-effect gates, dependency availability checks, and optional user approval before any tool or script becomes executable.

The biggest open question is update strategy. ToolGen admits new or substantially changed tools are hard for generative retrieval. The Lab should treat learned activation as an optimization over a dynamic host registry, not as the sole source of skill knowledge.

## Reviewed Paths

- `/tmp/myagents-research/reason-wang-toolgen/README.md`: Repository positioning, Hugging Face model/data links, public ToolGen usage snippet, virtual token setup, three training stages, and retrieval/end-to-end evaluation instructions.
- `/tmp/myagents-research/reason-wang-toolgen/training/README.md`: DeepSpeed commands for tool memorization, retrieval training, and end-to-end agent tuning; epoch counts, max lengths, batch settings, and GPU/memory assumptions.
- `/tmp/myagents-research/reason-wang-toolgen/training/train.py`: Training entrypoint, dataclass arguments, tokenizer/model loading, dataset construction, Hugging Face `Trainer` setup, and save behavior.
- `/tmp/myagents-research/reason-wang-toolgen/training/models/loading.py`: Virtual-token addition, embedding resize, and average-token embedding initialization for tool tokens.
- `/tmp/myagents-research/reason-wang-toolgen/training/data/loading.py`, `/tmp/myagents-research/reason-wang-toolgen/training/data/dataset.py`, and `/tmp/myagents-research/reason-wang-toolgen/training/data/utils.py`: JSON/chat dataset loading, loss masking, truncation, and training sample handling.
- `/tmp/myagents-research/reason-wang-toolgen/training/prompts/utils.py` and `/tmp/myagents-research/reason-wang-toolgen/training/prompts/templates.py`: Conversation formatting and label masking for chat-style SFT.
- `/tmp/myagents-research/reason-wang-toolgen/training/src/configs/virtual_tokens.txt`: 46,985-line virtual token list used for atomic tool/API representation.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/agents/toolgen/toolgen.py`: Public runtime ToolGen class, system prompts, mapping/documentation loading, constrained action generation, planning/action/calling decomposition, and returned `tool_calls` messages.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/agents/toolgen/inference.py`: Disjunctive trie and logits processors used to constrain action token generation.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/agents/toolgen/utils.py`: ToolBench name normalization and endpoint request helper.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/agents/base.py`: Single-chain agent loop, parsing model messages, invoking tools, handling observations, terminal states, and hallucinated function names.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/tools/src/rapidapi/rapidapi.py`: Host-side tool package loading, OpenAI-style schema conversion, function-name maps, `Finish` handling, and RapidAPI/StableToolBench payload execution.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/tools/src/rapidapi/server.py` and `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/tools/src/rapidapi/utils.py`: API request execution, observation shortening, error-code mapping, and finish argument parsing.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_toolgen.py`: Main ToolGen retrieval evaluation, constrained beam search, NDCG computation, full/stage-limited candidate spaces, and result logging.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_toolgen_atomic.py`: Older atomic-token retrieval evaluation using top logits over virtual tokens.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_bm25.py`, `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_encoder.py`, `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_openai_embedding.py`, and `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/eval_longcontext.py`: Baseline retrieval/evaluation implementations and prompt/context-cost comparisons.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/retrieval/metrics.py`, `/tmp/myagents-research/reason-wang-toolgen/evaluation/utils/retrieval.py`, and `/tmp/myagents-research/reason-wang-toolgen/evaluation/utils/embedding.py`: Retrieval helper functions, FAISS/BM25 indexers, embedding utilities, and NDCG helpers.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/LLM/toolgen.py` and `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/LLM/toolgen_atomic.py`: ToolBench-specific ToolGen runtimes, retry logic, optional relevant-token prompts, constrained/unconstrained action generation, and logging.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/Algorithms/single_chain.py`: End-to-end ToolBench agent loop and integration point where ToolGen receives ground-truth functions for evaluation but generates action tokens directly.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/Downstream_tasks/rapidapi.py`: ToolBench environment wrapper, tool retrieval baseline integration, OpenAI-function schema generation, API stepping, status codes, and pipeline runner.
- `/tmp/myagents-research/reason-wang-toolgen/scripts/retrieval/*.sh`, `/tmp/myagents-research/reason-wang-toolgen/scripts/inference/*.sh`, `/tmp/myagents-research/reason-wang-toolgen/scripts/pass_rate/run_pass_rate.sh`, `/tmp/myagents-research/reason-wang-toolgen/scripts/preference/run_preference.sh`, and `/tmp/myagents-research/reason-wang-toolgen/scripts/convert_answer/run_convert_answer.sh`: Intended command-line flows for retrieval, inference, answer conversion, pass-rate scoring, and preference scoring.
- `/tmp/myagents-research/reason-wang-toolgen/requirements.txt`: Dependency surface, including PyTorch/Transformers/FastChat/DeepSpeed/evaluation dependencies.
- GitHub REST repository endpoint and local git metadata: star snapshot, default branch, repository timestamps, and reviewed commit.
- Paper pages: ICLR 2025 proceedings and arXiv v3 page/HTML were used to verify the method framing, 47k-tool claim, reported retrieval/end-to-end metrics, indexing comparison, hallucination discussion, and tool-extension limitation.

## Excluded Paths

- `/tmp/myagents-research/reason-wang-toolgen/.git/`: VCS storage. Used only through git metadata commands for provenance.
- `/tmp/myagents-research/reason-wang-toolgen/assets/banner.png`: README banner image; not relevant to runtime routing or training mechanics.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/agents/function_calling.py`: OpenAI function-calling baseline wrapper. Reviewed at a high level through search, but excluded from detailed analysis because the focus was ToolGen runtime selection rather than generic OpenAI tool calls.
- `/tmp/myagents-research/reason-wang-toolgen/OpenAgent/tools/retrieval/`: Generic retrieval helper package. The ToolGen-specific runtime does not depend on it for action-token selection; retrieval baselines were reviewed under `evaluation/retrieval`.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/model/`: ToolBench model adapter utilities. Relevant only as baseline infrastructure, not as ToolGen's selection mechanism.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/LLM/chatgpt_function_model.py`, `tool_llama*.py`, `tool_chat_model.py`, and `retriever.py`: Baseline LLM/retriever implementations. They were considered as comparison boundaries but not deeply reviewed because the requested focus was ToolGen's runtime selection.
- `/tmp/myagents-research/reason-wang-toolgen/evaluation/toolbench/inference/Algorithms/DFS.py` and tree-search utilities: Alternative ToolBench search algorithm not used by the primary ToolGen single-chain path examined here.
- External Hugging Face model weights and datasets: Referenced by README and code but not downloaded. They are required for full reproduction but are outside the repository snapshot.
- External ToolBench, StableToolBench, RapidAPI services, OpenAI services, and live API keys: Required for end-to-end execution, but not vendored in this repo and not invoked during this review.
