# MoonshotAI/MoBA

- URL: https://github.com/MoonshotAI/MoBA
- Category: context-control
- Stars snapshot: 2,119 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: b5d58363311d3ca946f1ec444182727c15e338b5
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Valuable context-control pattern source, but not a directly reusable agent subsystem. Steal the block routing, mandatory local context, hybrid full/sparse fallback, and reference-vs-optimized verification ideas; do not copy the CUDA/FlashAttention-specific implementation or assume it works as a prompt-time drop-in for existing models.

## Why It Matters

MoBA is a compact, real implementation of trainable sparse long-context attention. It treats long context as blocks, routes each query token to a small top-k subset of historical KV blocks, always preserves local/current-block attention, and recombines sparse and local outputs with exact softmax accounting. For coding agents, the useful lesson is not the GPU kernel itself; it is the policy shape: maintain a bounded working set, score context blocks against the current query, keep the current task context unconditionally, and retain a full-context escape hatch for quality-sensitive steps.

The repo also shows a practical warning. MoBA is explicitly not a drop-in sparse attention mode for pretrained models. It needs continued training, uses sparse attention only for prefill in the released wrapper, and falls back to full FlashAttention during generation. Agentic context control should copy that caution: aggressive pruning needs adaptation, evaluation, and fallback instead of blind top-k truncation.

## What It Is

MoBA is a Python package for Mixture of Block Attention, built around PyTorch, Transformers, and FlashAttention. It exposes `register_moba(MoBAConfig(...))`, which inserts two attention implementations into HuggingFace Transformers' `ALL_ATTENTION_FUNCTIONS`: a naive mask-based reference (`moba_naive`) and an efficient FlashAttention-backed implementation (`moba`).

The method divides a sequence into fixed-size KV blocks. For each query token, it computes a parameter-less routing score by dotting the query with the mean-pooled key vector of each block. A causal top-k gate selects historical blocks, while the current block is always selected and handled with causal masking. The efficient implementation repacks selected query/block pairs into variable-length FlashAttention calls, then merges current-block attention and historical-block attention through online softmax.

The repository is an implementation artifact plus a technical report. It does not include full continued-pretraining code, large benchmark harnesses, model checkpoints, or a paged sparse decode implementation.

## Research Themes

- Token efficiency: Reduces attention compute for long sequences, not prompt token count. For agents, translate this into "spend retrieval/attention budget on top-ranked blocks" rather than expecting fewer source tokens to magically appear.
- Context control: Strong fit as an analogy. It has query-driven block selection, causal exclusion of future blocks, mandatory current-block inclusion, block-size/top-k tuning, and hybrid sparse/full attention.
- Sub-agent / multi-agent: No sub-agent orchestration. The MoE-style routing is conceptually similar to assigning work to experts, but the repo operates inside one model layer.
- Domain-specific workflow: Domain is long-context LLM training and inference. No coding-agent workflow, tool protocol, editor loop, or repository-navigation layer.
- Error prevention: Includes a naive implementation and a CUDA BF16 test that checks efficient output and gradients against the reference. This is useful as a verification pattern for context selectors.
- Self-learning / memory: No persistent memory. KV blocks are runtime sequence state, not a durable user/project memory store.
- Popular skills: No skill pack or instruction library. Useful as a research source for context-routing design.

## Core Execution Path

`examples/llama.py` parses `--moba-chunk-size`, `--moba-topk`, and `--attn`, calls `register_moba(MoBAConfig(...))`, then loads an `AutoModelForCausalLM` with `attn_implementation=args.attn`. `moba/__init__.py` registers `moba_naive` and `moba` by partially applying `moba_layer` with either `moba_attn_varlen_naive` or `moba_attn_varlen`.

`moba/wrapper.py` is the HuggingFace bridge. It asserts causal attention, converts `[batch, heads, seqlen, dim]` tensors into FlashAttention-style `[batch * seqlen, heads, dim]`, repeats KV heads for grouped-query attention, constructs cumulative sequence lengths, and calls the selected MoBA implementation during prefill when `q_len == kv_len`. When query length differs from KV length, the wrapper treats it as decode and uses standard `flash_attn_func`; sparse paged decode is not released in this repo.

`moba/moba_efficient.py` does the real work. `calc_chunks` computes per-batch chunk offsets and excludes the last chunk of each batch from historical sparse routing because current chunks are handled by local causal self-attention. `moba_attn_varlen` stacks K/V, computes chunk metadata, changes selective `moba_topk` to `moba_topk - 1` because the current block is always selected, and returns normal FlashAttention when no sparse historical block is needed. Otherwise it gathers filtered historical KV blocks, mean-pools keys per block/head, computes query-to-block gate scores in fp32, masks blocks that are future or outside the same batch, takes top-k, and packs selected query indices by block/head.

`MixedAttention.forward` runs two FlashAttention variable-length calls: causal current-block self-attention and non-causal attention from selected queries to selected historical blocks. It then uses log-sum-exp style online softmax math to combine the two outputs into the same normalization domain. `MixedAttention.backward` mirrors this by running FlashAttention backward for both paths and scattering gradients back through the packed query/KV indices.

`moba/moba_naive.py` is the readable reference. It builds a dense gate/mask over `[head, query, key]`, forces current block inclusion, excludes future blocks, applies top-k block selection, computes full attention with the resulting mask, and returns a result for comparison. `tests/test_moba_attn.py` generates CUDA BF16 variable-length inputs across batch/head/sequence/chunk/top-k combinations and checks efficient outputs and gradients against the naive implementation. `tests/test_moba_speedup.py` is a manual timing script comparing MoBA with FlashAttention at 32K sequence length.

## Architecture

The tracked source tree is small:

- `moba/config.py`: two-field dataclass for `moba_chunk_size` and `moba_topk`.
- `moba/__init__.py`: global Transformers attention registry hook.
- `moba/wrapper.py`: HuggingFace tensor-shape adapter and prefill/decode switch.
- `moba/moba_naive.py`: dense-mask educational/reference implementation.
- `moba/moba_efficient.py`: FlashAttention-backed variable-length implementation with custom autograd wrapper.
- `examples/llama.py`: minimal model-loading example.
- `tests/test_moba_attn.py`: correctness and gradient comparison against the naive reference.
- `tests/test_moba_speedup.py`: local speed experiment script.
- `README.md` and `MoBA_Tech_Report.pdf`: setup, method, evaluation claims, and design rationale.

There are no separate training pipelines, eval runners, config suites, deployment manifests, prompt assets, agent tool adapters, or memory stores. The implementation depends on `flash-attn==2.6.3`, `transformers>=4.48.3`, `accelerate>=1.3.0`, `einops>=0.8.1`, and `torch>=2.1.0`.

## Design Choices

MoBA uses a parameter-less gate: block representatives are mean-pooled keys, and query/block relevance is a dot product. This keeps the attention module parameter-compatible with full attention and enables switching between full and sparse modes during training.

The current block is mandatory. Historical block routing is dynamic, but the block containing the query is always included with causal masking. This avoids future-token leakage from mean pooling and preserves local attention quality.

Historical attention and current-block attention are computed separately. Current-block attention is causal; historical-block attention can be non-causal after causal routing has already excluded invalid blocks. This split maps well onto variable-length FlashAttention batches.

The efficient implementation uses MoE-style packing. It groups selected query tokens by chosen KV block/head, drops empty experts, builds cumulative lengths, runs FlashAttention over packed variable-length groups, and scatters results back.

The report emphasizes hybrid operation. Training can start sparse and finish full, or keep final Transformer layers in full attention during SFT. The released inference wrapper also uses MoBA for prefill and full attention for generation.

Block granularity is treated as a quality knob. The report's ablation keeps sparsity fixed while varying number of blocks and top-k, finding finer block segmentation performs better than coarse blocks.

## Strengths

- Small, readable codebase with both naive and efficient implementations.
- Clear actual execution path from Transformers registration to kernel call.
- Reference-vs-optimized tests compare both outputs and gradients, not only forward values.
- Design preserves Transformer parameters and allows full/sparse switching.
- Current-block inclusion is a strong context-safety rule that maps well to agent working sets.
- Efficient path shows how dynamic sparse routing can be made practical with batching and online softmax instead of one attention call per selected block.
- Report includes long-context evaluation framing beyond average loss, especially trailing-token loss and Needle-in-a-Haystack up to 1M context.

## Weaknesses

- Not a drop-in acceleration layer for existing pretrained models; the README and report require continued training.
- Sparse decode is absent in the released wrapper; generation uses full FlashAttention.
- Full training scripts, evaluation harnesses, and reproduction configs are not included.
- Implementation relies on FlashAttention internals (`_flash_attn_varlen_forward` and `_flash_attn_varlen_backward`), which can be fragile across library versions.
- Tests assume CUDA and BF16; there is no CPU or low-resource validation path.
- The global mutation of `ALL_ATTENTION_FUNCTIONS` is convenient for a demo but risky in larger applications with multiple model-loading paths.
- Mean-pooled key vectors are a weak semantic representation for code-level context if copied directly into retrieval or prompt selection.
- It reduces attention compute but still requires the whole prompt/KV sequence to be present during prefill.

## Ideas To Steal

Use block routing as a context-selection primitive for agents. Partition conversation, repo, docs, traces, and memory into stable blocks; compute compact block representatives; score them against the current task; include only top-k historical blocks in the working prompt.

Make the current working set non-negotiable. Always include the latest user request, active files/diff, failing test output, and immediately relevant instructions before any sparse selection of older context.

Separate "local/current" context from "historical/retrieved" context. Treat current task context as causal/local attention and older context as routed blocks with explicit relevance evidence.

Adopt hybrid sparse/full modes. Use sparse context for normal turns, but expand to full or broader context for planning, final verification, high-risk edits, cross-cutting refactors, or when selector confidence is low.

Tune block granularity deliberately. Fine blocks can preserve precision, but too many blocks increase routing overhead. Agentic Coding Lab could evaluate file-level, symbol-level, section-level, and turn-level blocks the same way MoBA ablates chunk size and top-k.

Keep a naive reference selector. Build a simple exhaustive or high-recall context selector and test any optimized router against it on golden tasks, including backreferences to old instructions and single-line critical facts.

Measure trailing-context quality. Average task success can hide failures on older context. Add evals where the decisive instruction, file, or memory is buried far back and must still be routed in.

## Do Not Copy

Do not copy the FlashAttention/autograd implementation into an agent stack. It solves model-kernel attention, not prompt assembly, repository retrieval, or tool context budgeting.

Do not treat hard top-k block routing as safe without fallbacks. Coding tasks often hinge on one small symbol, migration, convention, or instruction that a learned or heuristic score can miss.

Do not use mean-pooled embeddings as the only block representative for code. Code context needs names, imports, call graphs, tests, ownership, recency, and error traces in addition to semantic similarity.

Do not assume prompt-time pruning gives the same behavior as trained sparse attention. MoBA needs continued training; agent context pruning needs its own adaptation and eval loop.

Do not copy the global registry mutation pattern for production agent systems. Prefer explicit context providers and per-run configuration over hidden global hooks.

Do not copy the prefill-only story as a complete solution. For agents, the analog would be selecting context only once at task start and never revisiting it; real coding loops need rerouting after edits, tests, and new failures.

## Fit For Agentic Coding Lab

Fit is conditional but useful. MoBA should be cited as a design pattern for dynamic block-level context control, not adopted as dependency or runtime component. The most useful artifact candidate is a "block router" for agent context: a documented policy and test harness that always includes current working context, selects bounded historical blocks by task query, records why each block was selected, and escalates to broader context under uncertainty.

This repo also supports a research principle for the lab: every context compression mechanism needs a reference path, quality evals focused on far-back dependencies, and a fallback path that can recover full context when sparse selection is risky.

## Reviewed Paths

- `README.md`: setup, quick start, implementation distinction between naive and efficient, continued-training warning, claimed speedup context.
- `MoBA_Tech_Report.pdf`: method, causal/current-block design, implementation algorithm, scaling-law experiments, hybrid training, long-context benchmarks, efficiency claims, limitations implied by prefill/full-generation split.
- `moba/config.py`: public configuration surface.
- `moba/__init__.py`: Transformers attention registration.
- `moba/wrapper.py`: actual HuggingFace execution bridge and prefill/decode behavior.
- `moba/moba_naive.py`: reference attention mask and top-k block-selection semantics.
- `moba/moba_efficient.py`: chunk metadata, routing, packed variable-length FlashAttention calls, online-softmax combine, backward path.
- `examples/llama.py`: minimal integration example and defaults (`moba_chunk_size=4096`, `moba_topk=12`).
- `tests/test_moba_attn.py`: correctness and gradient test matrix.
- `tests/test_moba_speedup.py`: local FlashAttention-vs-MoBA timing script.
- `pyproject.toml` and `requirements.txt`: package metadata and dependency constraints.
- GitHub repository metadata: stars, forks, default branch, pushed date, topics, and license from GitHub REST API on 2026-05-19.

## Excluded Paths

- `figures/*.png`: binary visual assets used by README/report. Reviewed at the documentation level through README/report captions and surrounding text, but not analyzed as source.
- `LICENSE`: MIT license text, not relevant to execution path or context-control design beyond confirming permissive licensing.
- `.gitignore`: repository hygiene only.
- `.git/`: local clone metadata, excluded from research content.
- Generated text extraction `/tmp/myagents-research/moonshotai-moba-report.txt`: temporary reviewer artifact derived from `MoBA_Tech_Report.pdf`, not a source file.
- No vendored dependencies, generated source trees, binary kernels, UI-only application code, MCP/tool adapters, or agent-specific prompt assets are present in the tracked repository.
