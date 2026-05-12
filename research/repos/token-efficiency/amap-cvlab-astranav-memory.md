# amap-cvlab/AstraNav-Memory

- URL: https://github.com/amap-cvlab/AstraNav-Memory
- Category: token-efficiency
- Stars snapshot: 72 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: d32b59fa014bae05dce9c2caa72e1fd52af62559
- Reviewed at: 2026-05-12T12:28:30+09:00
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong research reference for visual-context token compression and long-memory prompting. Best ideas are fixed-budget image memory, pose-localized visual placeholders, a frozen encoder plus small compression bridge, and explicit compression-rate ablations. Direct Agentic Coding Lab adoption is conditional because this is an embodied-navigation VLM, not a coding-agent system, and the released runtime has fragile scripts, little targeted testing, and several execution-path gaps.

## Why It Matters

AstraNav-Memory studies a hard version of token efficiency: keeping many visual observations inside a single model context. The paper and code compress a 720 x 640 RGB frame from Qwen2.5-VL's native visual token budget to about 30 tokens, then prompt the navigation model with up to roughly 50 historical images plus the current panorama.

For Agentic Coding Lab, the important pattern is not navigation itself. The useful pattern is "compress rich context at the modality boundary, keep exact metadata as text, and make memory length an explicit budget." Coding agents have analogous context pressure from screenshots, logs, traces, file snippets, UI states, and prior tool results. AstraNav-Memory shows one way to keep a long trail of observations without external retrieval or object mapping.

The repo also matters because it exposes the cost tradeoff. The paper reports that 50 uncompressed images train at 26.4 seconds per iteration and use 90.6 GB, while 50 compressed images train at 6.5 seconds per iteration and use 46.8 GB. It also shows that more compression is not always better: 64x compression sharply hurts navigation success.

## What It Is

AstraNav-Memory is the official implementation of the arXiv paper "AstraNav-Memory: Contexts Compression for Long Memory" (arXiv:2512.21627). It is an image-centric lifelong-navigation policy built on Qwen2.5-VL-3B, DINOv3, Habitat-Sim, GOAT-Bench, and HM3D-OVON.

The repository has three main pieces:

- `inference_code/hm3d-online`: closed-loop Habitat navigation scripts for GOAT and OVON, a `Bank` memory object, prompt assembly, frontier selection, coordinate parsing, and video/log helpers.
- `train_code`: a vendored ModelScope SWIFT training tree with local modifications for `--use_compression`, `--compression_times`, and DINO settings.
- `train_code/transformers-4.57.1`: a vendored and modified Transformers tree. The actual Qwen2.5-VL compression path is in the local `qwen2_5_vl` model and processor files.

The public quickstart is minimal: install `train_code/requirements.txt`, which installs the local Transformers tree editable, run `bash run_train.sh` for SFT, and run `goat-nav.py` or `ovon-nav.py` for Habitat inference after downloading checkpoints and datasets.

## Research Themes

- Token efficiency: Primary theme. The main design compresses DINOv3 patch features through two PixelUnshuffle plus Conv blocks and Qwen's 2x2 patch merger. Paper claims 598 native visual tokens per frame become about 30 tokens for 720 x 640 images.
- Context control: Strong conceptually but narrow in code. Inference caps visual memory with `image_length=50`, serializes relative pose before each historical image placeholder, and passes `use_compression=True` into the processor. There is no adaptive retrieval, summarization, recency scoring, or learned forgetting.
- Sub-agent / multi-agent: Not present. There is one embodied agent loop and one VLM policy.
- Domain-specific workflow: Strong for embodied navigation. The workflow combines spin-around observations, frontier detection, local coordinate conversion, VLM target/frontier choice, Habitat shortest-path following, and SR/SPL metrics.
- Error prevention: Weak in released code. The paper has ablations, but the repo has no targeted tests for compression shape invariants, prompt/image count matching, parser failures, or closed-loop script startup.
- Self-learning / memory: Moderate as implicit in-context memory. The agent accumulates images and poses during a lifelong episode, but memory is not durable across runs and is not stored in a searchable index.
- Popular skills: No skill system. Reusable patterns are visual-token compression, fixed memory windows, local-pose annotations, and efficiency ablation reporting.

## Core Execution Path

Training path:

1. `train_code/run_train.sh` invokes `python swift/cli/sft.py`.
2. CLI arguments include `--max_length 20000`, `--use_compression true`, `--compression_times 2`, `--dino_from_pretrained facebook/dinov3-vitb16-pretrain-lvd1689m`, and `--dino_freeze true`.
3. SWIFT argument classes propagate compression flags through `TemplateArguments.get_template_kwargs` and model-loading kwargs.
4. `get_model_tokenizer_from_local` writes compression settings onto the model config before `from_pretrained`.
5. `Qwen2VLTemplate._encode` uses DINOv3 image preprocessing when compression is enabled, computes a compressed `image_grid_thw`, and expands each image placeholder to the compressed token count.
6. The local Qwen2.5-VL model lazily loads DINOv3 on first visual forward pass, freezes it, drops CLS/register tokens, reshapes patch features into a 2D grid, pads to a multiple of 8, applies two PixelUnshuffle plus Conv/BatchNorm/SiLU blocks, and feeds the compressed tokens through Qwen's vision transformer and merger.

GOAT inference path:

1. `goat-nav.py` loads navigation data, Habitat simulator config, `Qwen2_5_VLForConditionalGeneration`, and `AutoProcessor`.
2. Each decision cycle makes the agent spin through 12 left turns, storing every third spin image in `Bank.images_spin`.
3. Frontier utilities update fog-of-war maps and produce explorable frontier waypoints.
4. `getresult` builds a prompt containing historical memory images with local `[x, z, yaw]` pose text, four current panorama images, frontier coordinates, and the natural-language instruction.
5. The processor receives text plus resized 720 x 640 images with `use_compression=True`, `compression_times=2`, and `dino_size='vitb16'`.
6. The model generates natural language containing either a final target coordinate or a frontier coordinate inside `<coordinate>...</coordinate>`.
7. Parsed local coordinates are mapped back to world coordinates. Habitat's `GreedyGeodesicFollower` executes a path to that point, and the loop continues until success, failure, or step limit.

OVON inference follows the same conceptual path, but its released script does not currently pass `log_file_path` into `getresult`, so it is not runnable as-is.

## Architecture

The compression architecture is small relative to the vendored stack:

- DINOv3-ViT provides frozen patch features. The main setting uses `vitb16`, hidden size 768, patch size 16, and four register tokens that are stripped before compression.
- `DINOv3ViTImageProcessorFast` prepares raw images without Qwen's native image processor when compression is active.
- The processor and SWIFT template compute compressed `image_grid_thw` so text placeholder expansion matches visual feature count. For 720 x 640 and `compression_times=2`, the grid becomes 10 x 12 before Qwen's 2x2 merger, producing 30 language-side visual tokens.
- The model compression path uses `nn.PixelUnshuffle(2)` repeatedly. Each stage moves local 2x2 spatial neighborhoods into channels, then applies a 3x3 Conv2d, BatchNorm2d, and SiLU. The final stage maps into Qwen's vision hidden size.
- The remaining Qwen2.5-VL vision blocks, windowing, rotary embeddings, patch merger, multimodal projection, and language model remain mostly unchanged.

The navigation architecture is prompt-centric:

- `Bank` stores spin images/states and sampled goto images/states.
- `getresult` currently reads only spin data for the model prompt. Goto samples are stored but not used in the VLM prompt path.
- Current frontiers are provided as text coordinates, not images or masks.
- Historical image pose metadata is serialized as local 2D coordinate plus yaw text immediately before each `<image>` placeholder.
- The VLM output is parsed by regex and snapped to a frontier or transformed into a final world target.

## Design Choices

The strongest design choice is compressing visual tokens before they hit the expensive long-context part of the model. Instead of summarizing images in text or building an object map, the code keeps images as visual embeddings and reduces their token footprint.

Frozen DINOv3 is a practical stabilization choice. It makes the compression bridge trainable without constantly changing the visual backbone and gives the system stronger self-supervised semantics than a navigation-only encoder.

PixelUnshuffle is a better fit than naive pooling for this setting. It preserves local neighborhoods by moving spatial detail into channels, then lets convolution decide what to keep. That is a useful pattern for coding-agent screenshots or UI states where spatial structure matters.

The fixed `image_length` window is simple and inspectable. It avoids complex retrieval logic and gives a clear budget, but it also means the agent has no learned or semantic choice about which old observations stay in context.

The prompt format combines exact text metadata with compressed visual payloads. Relative pose coordinates remain readable and inspectable, while image content becomes compressed hidden state. That hybrid pattern is more reusable for coding agents than the navigation-specific frontier loop.

The paper's ablation design is valuable. It reports both accuracy and system cost for memory length and compression rate, making the tradeoff legible instead of claiming compression only helps.

## Strengths

The core compression idea is clear and testable: DINO patch grid -> PixelUnshuffle/Conv stages -> Qwen-compatible visual tokens.

The efficiency numbers are useful. Paper reports 50 compressed images cutting iteration time from 26.4s to 6.5s and memory from 90.6 GB to 46.8 GB compared with 50 uncompressed images.

The ablations avoid a common compression trap. They show 4x compression with 100 images can outperform 16x in accuracy, while 64x is too lossy. That supports budget tuning rather than maximal compression.

The memory format is simple enough to port: a bounded list of observations, each with relative pose text and a compressed visual token sequence.

The system avoids object-centric map dependencies in the main path. That reduces upstream detection and reconstruction failure propagation, which is relevant to coding agents that may not want brittle per-asset parsers for every context type.

The repo releases both training and inference code plus multiple checkpoint variants, not only a paper description.

## Weaknesses

The released inference scripts are fragile. `qwen_utils_goat.py` imports `datetime` as a module but calls `datetime.now()`, which will raise at the first `getresult` log write. `ovon-nav.py` calls `getresult` without the required `log_file_path` argument. `Bank.__len__` references missing `self.images`.

There are weak parser fallbacks. If the model output lacks a parseable coordinate, `getresult` can fall through into `np.array(None)` because the fallback condition checks whether `local_to_global_map is None`, but it is initialized as a dictionary.

Goto memory is effectively dead in prompt assembly. The `Bank` class stores sampled goto images separately, but `getresult` uses only `get_spin_data`. This makes the memory design narrower than the class suggests.

The code depends on a large vendored training stack. Most of `train_code` is ModelScope SWIFT, and `train_code/transformers-4.57.1` is a full Transformers copy. The relevant custom edits are small but buried in vendor code.

The modified Transformers files are not perfectly consistent. The `modular_qwen2_5_vl.py` path describes one DINO patch design, while the generated `modeling_qwen2_5_vl.py` contains the runtime `use_compression` PixelUnshuffle path. The header says generated files should not be manually edited, but runtime behavior lives there.

Test coverage is not focused on AstraNav-Memory. The included tests are broad SWIFT tests; search found no targeted tests for `use_compression`, DINO shape handling, image placeholder counts, or navigation prompt parsing.

Direct coding-agent adoption is limited. The method needs model-weight control, a local modified multimodal model, and training data. Hosted coding models cannot accept this embedding-level compression path directly.

The paper acknowledges boundary-sensitive failures. DINO features work well for salient objects like books and freezers but struggle on carpet/floor style boundaries, suggesting compressed visual memory can lose fine-grained cues.

## Ideas To Steal

Use a fixed context budget for rich observations. Instead of "include all screenshots/logs until context breaks," make the window explicit and expose memory length in configs and evaluations.

Keep exact metadata in text next to compressed payloads. For coding agents, that could mean file path, timestamp, viewport, command, exit code, or line range as text, with bulky payload summarized or embedded separately.

Compress at the modality boundary. Screenshots, trace trees, DOM snapshots, and UI videos can be compressed before entering the general language context, while exact source remains available through tools.

Use a small trainable bridge over a frozen encoder. A coding-agent equivalent could freeze a log/code/screenshot encoder and train only a compact adapter for a local agent model.

Make compression rate an evaluation dimension. Track accuracy, latency, memory, and context length for 1x, 4x, 16x, and more aggressive settings instead of reporting token savings alone.

Preserve spatial layout through rearrangement before pooling. PixelUnshuffle-style "space to channels" is useful when local geometry matters, such as screenshots, diagrams, and rendered UI diffs.

Report the non-linear context limit honestly. AstraNav-Memory notes that 16x token compression does not mean 16x more images, because the pre-compression DINO encoder still consumes memory.

## Do Not Copy

Do not copy the released inference scripts as production examples without fixing startup bugs, parser fallbacks, and argument mismatches.

Do not bury critical model changes inside a vendored dependency tree. For Agentic Coding Lab, keep compression adapters in first-party modules with narrow patches against upstream libraries.

Do not rely on embedding-level compression for exact code edits, citations, security review, or line-specific reasoning. Use compressed context for recall and triage, then fetch exact raw source before action.

Do not assume more history always helps. The paper's 200-image and 500-image results show attention noise and information loss can outweigh longer memory.

Do not evaluate token compression only with task success. Add invariants for placeholder/image counts, shape math, parser outputs, exact metadata preservation, and fallback behavior.

Do not treat visual memory as a substitute for retrieval when the user needs provenance. The model can remember that something was seen, but the exact source artifact should remain tool-addressable.

## Fit For Agentic Coding Lab

Fit is conditional but high-value as a pattern source for token-efficient multimodal memory. The repo is not about coding agents, but the compression discipline transfers well to agent contexts that include visual UI state, long command logs, trace timelines, and repeated observations.

The best local artifact inspired by this repo would be a "rich observation budget" harness: every observation carries exact text metadata plus a compressed payload, every compression level has task and fidelity tests, and raw artifacts stay fetchable by ID.

For current Codex-style hosted agents, direct embedding injection is not practical. The near-term adaptation is prompt-level: preserve exact anchors, compress bulky observation text/images into bounded records, and require raw-tool lookup before editing or citing. The longer-term research path is local open-weight agents that can consume learned compressed context tokens.

## Reviewed Paths

- `README.md`: project positioning, core compression claim, checkpoint matrix, install commands, inference/training entrypoints, and citation.
- arXiv paper `2512.21627`: method, architecture, dataset construction, GOAT/HM3D-OVON results, memory-length and compression-rate ablations, DINO backbone ablation, limitations around boundary-sensitive targets, and conclusion.
- GitHub REST API metadata: star count, description, default branch, pushed date, license metadata, and repository status.
- `train_code/run_train.sh`: actual SFT command, max context length, DINO settings, compression flags, and training defaults.
- `train_code/requirements.txt`: dependency path showing local editable `transformers-4.57.1`.
- `train_code/data/data_demo.jsonl`: sample multimodal navigation message schema with image placeholders, frontier coordinates, assistant coordinate output, image paths, status, strategy, and target.
- `train_code/swift/llm/argument/base_args/template_args.py` and `base_args.py`: CLI argument propagation for compression settings.
- `train_code/swift/llm/template/base.py`, `register.py`, and `template/template/qwen.py`: SWIFT template initialization, DINO processor setup, compressed `image_grid_thw` calculation, and placeholder expansion.
- `train_code/swift/llm/model/register.py`: model config mutation, AutoProcessor construction with compression kwargs, and model/tokenizer loading path.
- `train_code/transformers-4.57.1/src/transformers/models/qwen2_5_vl/configuration_qwen2_5_vl.py`: local config fields for `use_compression`, `compression_times`, DINO path, DINO size, and freeze flag.
- `train_code/transformers-4.57.1/src/transformers/models/qwen2_5_vl/modeling_qwen2_5_vl.py`: runtime DINO dictionaries, DINO lazy loading, PixelUnshuffle/Conv compression stack, padding, Qwen visual forward path, and image feature insertion.
- `train_code/transformers-4.57.1/src/transformers/models/qwen2_5_vl/processing_qwen2_5_vl.py`: processor-side compressed grid calculation and image token replacement.
- `train_code/transformers-4.57.1/src/transformers/models/qwen2_5_vl/modular_qwen2_5_vl.py`: intended modular design and divergence from generated runtime file.
- `inference_code/hm3d-online/goat-nav.py`: GOAT closed-loop simulator loop, spin observations, bank writes, frontier detection, VLM decision call, Habitat path following, and SR/SPL output.
- `inference_code/hm3d-online/ovon-nav.py`: OVON equivalent path and argument mismatch with `getresult`.
- `inference_code/hm3d-online/qwen_utils_goat.py`: prompt construction, local/world coordinate transforms, image preprocessing, processor/model invocation, coordinate parser, and `Bank` memory object.
- `inference_code/hm3d-online/frontier_utils.py`, `path_utils.py`, `sim_utils.py`, and relevant parts of `utils.py`: fog-of-war frontier detection, coordinate conversion, path-cost helpers, simulator construction, dataset loading, logging, and result/video helpers.
- `inference_code/configs/habitat/*.yaml`: sensor dimensions, FOV, agent radius/height, turn angle, step size, simulator defaults, and hardcoded dataset config path.
- `inference_code/hm3d-online/data_utils.py`: legacy/alternate MTU3D/PQ3D object-centric decision pipeline using DINOv2, FastSAM, point clouds, Query3D models, frontier/object logits, and CUDA-heavy cleanup.
- `train_code/tests/*` and searched test tree: generic SWIFT test harness and absence of AstraNav compression-specific tests.
- `assets/memory.jpg` and `assets/model.jpg`: architecture and memory figures, reviewed at README/paper level rather than as binary assets.
- Git metadata: exact reviewed commit, last commit author/date/message, clone status, and tracked file inventory.

## Excluded Paths

- `.git/`: clone metadata only. Used through Git commands for commit and status, not reviewed as source content.
- Most of `train_code/transformers-4.57.1/**`: vendored Hugging Face Transformers. I reviewed the modified Qwen2.5-VL and DINO-related execution paths but excluded unrelated model families, docs, generated docs, utility scripts, and tests.
- Most of `train_code/swift/**`: vendored ModelScope SWIFT framework. I reviewed compression argument, template, model-loading, and relevant generic test paths; unrelated training algorithms, UI, RLHF, Megatron, deployment, and dataset registries were excluded as vendor surface.
- `train_code/docs/**`, `train_code/examples/**`, and `train_code/asset/**`: generic SWIFT documentation, examples, UI images, and community assets. They do not define AstraNav-Memory compression behavior.
- Binary image assets under `assets/` and `train_code/docs/resources/`: reviewed only through README/paper claims. Raw binary content was excluded because it does not affect execution logic.
- Generated or bulky benchmark/image output files: none are needed for the repo note. The paper tables and source code provide the architecture and evidence.
- Habitat datasets, model checkpoints, ModelScope downloads, and local `./MTU3D` paths referenced by scripts: not present in the clone. I reviewed call sites and path assumptions, not external data.
- UI-only surfaces in vendored SWIFT: excluded because AstraNav-Memory runs through CLI scripts and model code, not the SWIFT web UI.
