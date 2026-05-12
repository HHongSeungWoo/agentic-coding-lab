# Beckschen/LLaVolta

- URL: https://github.com/Beckschen/LLaVolta
- Category: token-efficiency
- Stars snapshot: 67 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 31ec1516ac282b7aa53a0d11e476f7295523ed3e
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful research-code reference for visual-context compression, especially the idea of compressing only marked visual spans after some model processing instead of truncating the whole prompt. It is not a coding-agent context system: the active path is a LLaVA fork that hard-codes 576 CLIP visual tokens and average-pools them inside a custom Llama decoder. Good pattern source for screenshot/UI context handling; weak as a reusable agent token-efficiency component.

## Why It Matters

LLaVolta targets a token-efficiency problem adjacent to coding agents: multimodal assistants spend large context and compute budget on dense visual patch tokens. In LLaVA-v1.5 with CLIP ViT-L/14 at 336px, one image becomes a 24 x 24 patch grid, or 576 visual embeddings, before any text answer generation. If an agent uses screenshots, diagrams, browser captures, whiteboards, or UI states as context, those visual spans can dominate the effective context budget.

The repo matters because it implements visual compression in the model execution path, not just as a preprocessing claim. It records image-token spans, inserts image embeddings at `<image>`, then compresses only those spans inside the language model at a configured layer. Text tokens, conversation tokens, and generated answer tokens stay outside the pooling operation.

For Agentic Coding Lab, the strongest transferable idea is span-local compression: tag a costly modality or evidence span, compress that span with a cheap operation or learned module, and preserve the rest of the agent transcript exactly. That is more useful than copying the specific average-pooling method.

## What It Is

LLaVolta is a NeurIPS 2024 research implementation titled "Efficient Large Multi-modal Models via Visual Context Compression." The codebase is a fork of LLaVA with custom training and evaluation scripts for compressed LLaVA-v1.5-style models.

The active implementation in the reviewed checkout uses:

- CLIP ViT-L/14-336 as the frozen vision tower.
- LLaVA's `mlp2x_gelu` multimodal projector.
- A custom `LlavaLlamaModel` that replaces Llama decoder layers with adaptive layers.
- A runtime grouping mode named `avgpool1d`.
- Configurable compression layer and stride, with example settings for heavy compression (`layer=2`, `stride=8`) and light compression (`layer=16`, `stride=8`).
- A progressive training schedule that can move through lists of compression layers/strides at training-step pivots.

The repo also contains experimental C-Abstractor and D-Abstractor modules under `llava/model/multimodal_projector/`, but they are not wired into the active builder path in the reviewed commit.

## Research Themes

- Token efficiency: Primary theme. The execution path reduces visual-token sequence length by average-pooling fixed 576-token image spans, e.g. stride 8 compresses 576 visual tokens to 72 pooled tokens per image. It saves visual context and attention compute but does not compress text, code, tools, logs, or normal agent history.
- Context control: Moderate. It uses explicit image-span indices and a `groupingLayer` gate, which is a good context-control primitive. There is no general budget manager, no dynamic policy, no model-aware token allocator, and no compression fallback per task.
- Sub-agent / multi-agent: None. No delegation, worker orchestration, or agent handoff logic.
- Domain-specific workflow: Strong for multimodal VQA research; weak for coding agents. Scripts cover VQAv2, GQA, VizWiz, ScienceQA, TextVQA, POPE, MME, MMBench, SEED-Bench, LLaVA-Bench, and MM-Vet.
- Error prevention: Low. Runtime assertions exist, but there are no dedicated tests for compression correctness, shape safety, regression quality, or span-index invariants.
- Self-learning / memory: None. Compression is per-forward-pass and model-training-time behavior, not durable memory.
- Popular skills: No skill or prompt library. Reusable patterns are modality-span marking, late-layer compression, progressive compression curriculum, and benchmark matrix scripts.

## Core Execution Path

The active inference and training path is:

1. `llava/eval/model_vqa_loader.py` or training scripts load a LLaVA checkpoint through `llava/model/builder.py`.
2. `CLIPVisionTower` selects a configured hidden layer, usually `-2`, and drops the CLS token when `mm_vision_select_feature == "patch"`.
3. For the default 336px CLIP tower, the image becomes 576 patch embeddings.
4. `LlavaMetaForCausalLM.encode_images` passes visual features through `mm_projector`.
5. `prepare_inputs_labels_for_multimodal` replaces each `<image>` token with the projected image-feature sequence and records where image tokens appeared in the original input.
6. `LlavaLlamaForCausalLM.forward` stores those image indices on `self.model.images_idx`.
7. `LlavaLlamaModel.forward` iterates decoder layers. When `layer_idx == self.groupingLayer` and `grouping != "none"`, it calls `visual_operating`.
8. `visual_operating` slices each image span using hard-coded `VISUAL_LENGTH = 576`, applies the configured operator only to the visual segment, and concatenates text and pooled visual segments back together.
9. The only active operator in this path is `visual_avg_pool1d`, which average-pools hidden states and position IDs with `kernel_size=stride` and `stride=stride`.
10. The attention mask is trimmed to match the shorter sequence.
11. During training, if labels exist and compression produced `label_ids`, labels are gathered to match pooled positions before cross-entropy.
12. During generation, `model.post_config(args)` receives `--layer`, `--stride`, and `--grouping` from eval scripts, then `generate` runs with the compressed visual span.

Training has two modes. Heavy and light compression scripts train with fixed progressive lists like `LAYERS=2,0` or `LAYERS=16,0`, `STRIDES=8,1`, and `PIVOTS=10000`. The 4-stage script fine-tunes with `LAYERS=2,2,16,0`, `STRIDES=8,2,2,1`, and `PIVOTS=1300,2600,3900`, then calls `step_stride_and_layer` after model forward when `progressive` is true.

## Architecture

The codebase is organized as a LLaVA fork:

- `llava/model/language_model/llava_llama.py`: central compression path, adaptive attention classes, custom decoder layers, visual-span pooling, progressive schedule, and generation hook.
- `llava/model/llava_arch.py`: multimodal input assembly, image encoding, image-token insertion, and image-index capture.
- `llava/model/multimodal_encoder/clip_encoder.py`: CLIP vision tower wrapper and patch-token selection.
- `llava/model/multimodal_projector/builder.py`: active projector builder for linear, `mlpNx_gelu`, and identity projectors.
- `llava/train/train.py`: model arguments for `layers`, `strides`, `grouping`, `progressive`, and pivots; trainer setup; projector loading and saving.
- `scripts/v1_5/train-*.sh`: example training recipes for reproduce, heavy compression, light compression, and 4-stage training.
- `scripts/v1_5/eval/*/*.sh`: benchmark-specific inference wrappers that pass compression args to eval loaders.
- `llava/model/multimodal_projector/visual_plugin.py` and `projectors.py`: experimental C/D abstractors, multiscale attention, and deformable-DETR-style visual projectors, but not active in `build_vision_projector`.

The active compression boundary is inside the language model, after vision encoding and projection. That means the compressor sees hidden-state visual tokens that already share the language-model hidden size, not raw pixels or CLIP-only features.

## Design Choices

LLaVolta compresses visual tokens after some language-model layers rather than only before the LLM. Heavy compression pools early at layer 2; light compression pools later at layer 16. This is a useful design axis: early pooling saves more downstream compute, while late pooling gives the model more layers to mix fine-grained visual evidence before downsampling.

Compression is span-local. The model tracks image insertion points and pools only the 576-token image segment. That is the most practical idea for agent systems: expensive context should be explicitly marked and transformed locally instead of summarizing the full conversation.

The pooling implementation is intentionally simple. `avg_pool1d` is cheap, deterministic, and easy to schedule, but it is not content-aware. It treats all visual patches equally, so it may erase small text, UI affordances, object boundaries, or fine-grained spatial evidence.

Position handling is approximate. The code average-pools visual position IDs and casts them back to the original position dtype. Custom attention then applies RoPE using the pooled positions. This preserves coarse order but is not a principled coordinate system for compressed visual regions.

The design assumes fixed visual length. `VISUAL_LENGTH = 576` matches one 24 x 24 CLIP patch grid. That keeps the code short but makes it fragile for anyres images, multiple grid resolutions, video frames, or alternate vision towers unless other paths are carefully constrained.

Training attempts to match inference compression. Heavy and light scripts train with compression settings and eval with matching `layer`/`stride` values. The 4-stage script uses progressive compression during fine-tuning, but its provided eval scripts set `grouping=none`, so the public script path does not demonstrate runtime token savings for that named setting.

## Strengths

The core mechanism is easy to understand and inspect. There is a clear line from eval args to `model.post_config`, decoder-layer gate, visual-span pooling, and shorter attention mask.

The repo gives concrete compression knobs. `grouping`, `layer`, `stride`, `layers`, `strides`, `pivots`, and `progressive` make it possible to compare early/late and aggressive/gentle compression without changing model code.

It preserves non-visual tokens by construction. Text instructions, answers, and ordinary prompt tokens are not averaged with image tokens, which is the right safety instinct for agent contexts.

The benchmark scripts cover many standard multimodal tasks. That gives a broad evaluation shape even though raw results and automated regression checks are not bundled in a durable test harness.

The progressive schedule is a useful training pattern. Starting with more aggressive or earlier compression and moving through stages can teach a model to tolerate compressed visual spans instead of applying compression only at inference.

The code reveals what is actually active. Several abstractor modules look more sophisticated, but the wired path is average pooling inside `llava_llama.py`; this makes the repo useful as a case study in separating paper architecture options from shipped execution paths.

## Weaknesses

The active method is not a general token-efficiency system. It handles visual patch embeddings only. It does not compress chat history, source files, diffs, terminal output, stack traces, tool schemas, or retrieved docs.

Hard-coded `VISUAL_LENGTH = 576` is a major portability constraint. Any change to image resolution, patch size, any-resolution mode, or video/multi-frame representation can misalign slicing.

There is no dedicated test suite for the compression logic. The only test-like file is a serve message script; no unit tests assert pooled sequence lengths, label alignment, attention-mask shape, multi-image behavior, or equivalence when `grouping=none`.

The average-pooling policy can destroy details. For coding agents, screenshots often contain small text, menu states, icons, cursor focus, and subtle layout bugs; uniform pooling is a weak default for those evidence types.

Several experimental visual-projector files are not integrated. `visual_plugin.py`, `projectors.py`, and `configuration_honeybee.py` contain C/D abstractor ideas, but `builder.py` only returns linear, MLP, or identity projectors. Copying those files would add complexity without active behavior.

The scripts have rough edges. `ROOT_DATA`, `ROOT_WEIGHT`, and `ROOT_LOG` are unset in the examples, and the light-compression fine-tune script points to `$ROOT_WEIGHT/llava-v1.5-7b-pretrain-compression/mm_projector.bin` even though its pretrain output is named with `$NAME`. That makes reproduction more manual than the README implies.

The repo does not expose a clear cost/latency measurement harness. README images claim acceleration, but the reviewed source does not include durable benchmark records, CI checks, or token/compute accounting artifacts.

## Ideas To Steal

Use explicit span metadata for expensive context. Instead of compressing a whole agent transcript, mark visual/screenshot/tool-output spans and transform only those spans.

Offer a cheap deterministic compressor as a baseline. Average pooling is too weak for many tasks, but a simple local operation is useful as a fallback and as a lower-bound benchmark against learned compressors.

Experiment with late compression. For screenshots or visual traces, a model may benefit from a few layers of detailed evidence before compression. The early-vs-late layer knob is more interesting than one global compression ratio.

Train with the compression schedule that inference will use. Applying token reduction only at inference is risky; LLaVolta's scripts show a curriculum-style way to make the model robust to compressed context.

Keep text/code/tool spans exact while compressing visual spans. The core transfer to coding agents is "compress the lossy modality, preserve the brittle modality."

Create invariant tests around span surgery. For Agentic Coding Lab, tests should prove that compression changes only the target span, preserves surrounding token order, maintains source IDs, and keeps labels/masks aligned.

Treat screenshot compression as separate from transcript compression. A UI screenshot has spatial redundancy; a stack trace or diff has exact-token semantics. They need different compressors and different correctness criteria.

## Do Not Copy

Do not hard-code a visual span length in an agent framework. Carry explicit span boundaries and lengths from the encoder or tool that produced the context.

Do not average-pool code, diffs, logs, JSON, or tool-call messages. The LLaVolta operation is only plausible because adjacent visual patch embeddings are spatially related and already continuous.

Do not import unused abstractor modules without wiring and tests. The C/D abstractor code is interesting, but the active repo path does not validate it.

Do not claim token savings from training scripts alone. Verify actual prompt length, hidden-state length, attention-mask shape, latency, answer quality, and failure modes under the exact inference settings.

Do not use uniform pooling as the final screenshot strategy. For coding work, saliency around text, focused elements, errors, and changed regions matters more than average appearance.

Do not rely on README diagrams as evidence. The reviewed implementation shows a narrower and rougher path than the paper/README positioning.

## Fit For Agentic Coding Lab

Fit is conditional. LLaVolta is valuable as a design reference for visual-context compression, not as a direct component for coding-agent context control.

The most relevant Agentic Coding Lab artifact would be a screenshot/context-span compressor that preserves provenance and lets the agent request re-expansion of visual regions. LLaVolta suggests compressing visual tokens locally and late; Agentic Coding Lab should add region metadata, OCR preservation, UI-element saliency, and verification screenshots before trusting compression.

The repo also sharpens a boundary: text/code context and visual context should not share one generic summarizer. Coding agents need exact preservation for source and tool semantics, while screenshots can tolerate lossy spatial compression if important small details are protected.

Adoption should be pattern-level only. Borrow span marking, late compression experiments, progressive training/evaluation schedules, and invariant checks. Do not depend on this repo as an agent runtime, MCP server, prompt compressor, or memory layer.

## Reviewed Paths

- `README.md`: project positioning, install path, training/evaluation entrypoints, benchmark families, and LLaVolta scheme claims.
- `pyproject.toml`: package identity, LLaVA-derived dependencies, train extras, and packaging exclusions.
- `config.json` and `modelconfig/config.json`: default LLaVA-v1.5 model settings, CLIP tower, projector type, 4096 max positions, 576-token visual assumptions, and `grouping` field.
- `llava/constants.py`: `VISUAL_LENGTH = 576`, image token constants, and 24 x 24 visual-position mappings.
- `llava/model/language_model/llava_llama.py`: adaptive attention, custom decoder stack, image-span pooling, progressive schedule, forward/generate integration, label gathering, and post-config path.
- `llava/model/llava_arch.py`: vision module initialization, image encoding, multimodal input assembly, image-token replacement, image-index capture, mask/label padding, and tokenizer setup.
- `llava/model/multimodal_encoder/clip_encoder.py`: CLIP loading, hidden-layer selection, CLS dropping, patch feature shape, and frozen tower behavior.
- `llava/model/multimodal_projector/builder.py`: active projector factory and absence of abstractor integration.
- `llava/model/multimodal_projector/visual_plugin.py`, `projectors.py`, and `configuration_honeybee.py`: experimental abstractor/projector designs, reviewed to determine whether they are active.
- `llava/model/builder.py`: checkpoint loading, tokenizer/image-token setup, vision tower loading, and default `context_len` behavior.
- `llava/train/train.py`, `train_mem.py`, `train_xformers.py`, `llava_trainer.py`: training args, compression-list parsing, projector saving/loading, gradient/checkpointing setup, and multimodal data pipeline.
- `scripts/v1_5/train-heavy-compression.sh`, `train-light-compression.sh`, `train-4stage.sh`, and `train-reproduce.sh`: concrete training schedules, layer/stride settings, progressive pivots, and reproduction assumptions.
- `scripts/v1_5/eval/heavy_compression/*.sh`, `light_compression/*.sh`, `4stage/*.sh`, and `reproduce/*.sh`: runtime compression settings passed into evaluation commands.
- `llava/eval/model_vqa_loader.py`, `model_vqa.py`, `model_vqa_mmbench.py`, `model_vqa_science.py`, and conversion/eval helpers: inference path, CLI compression args, generation settings, answer output, and benchmark glue.
- `docs/Data.md`, `docs/Evaluation.md`, `docs/MODEL_ZOO.md`, and `docs/Customize_Component.md`: inherited LLaVA data/eval/model/component guidance, checked for context and divergence from LLaVolta-specific README/scripts.
- Git metadata and GitHub REST API metadata: exact reviewed commit, last commit date/message, default branch, license, star snapshot, and repository status.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands to record commit and cleanliness, not reviewed as source behavior.
- `llava/eval/table.tar`: binary archived evaluation table. Excluded as generated/binary data; evaluation code and scripts were reviewed instead.
- `images/`, `llava/serve/examples/`, and README-hosted images: static screenshots/GIF/JPG/SVG assets. Excluded as visual marketing/demo assets, not runtime compression logic.
- `llava/eval/webpage/`: static HTML/CSS/JS viewer for evaluation output. Excluded as UI-only and unrelated to model compression.
- `llava/serve/`: Gradio/controller/model-worker serving layer. Skimmed only for test presence; excluded from deep review because it does not implement token/context compression.
- `docs/Windows.md`, `docs/macOS.md`, `docs/Intel.md`, `docs/LoRA.md`, `docs/LLaVA_Bench.md`, `docs/LLaVA_from_LLaMA2.md`, `docs/ScienceQA.md`, and `docs/Finetune_Custom_Data.md`: inherited setup/task documentation. Excluded after sampling because LLaVolta-specific compression behavior lives in README, scripts, and model code.
- `scripts/convert_*`, `scripts/extract_mm_projector.py`, `scripts/merge_lora_weights.py`, and upload scripts: dataset/checkpoint format utilities. Reviewed at path level only; excluded from deep analysis because they do not affect visual-token compression.
- Vendored dependency source: none present in the tracked checkout.
