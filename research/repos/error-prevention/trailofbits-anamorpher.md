# trailofbits/anamorpher

- URL: https://github.com/trailofbits/anamorpher
- Category: error-prevention
- Stars snapshot: 1,048 (GitHub REST API repository metadata, captured 2026-05-19 KST)
- Reviewed commit: 6aa9877ed64d0d1b1bf6d8b86d754ab5098c155b
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: High-value adversarial reference for multimodal coding-agent input safety. Anamorpher is an attack and visualization tool, not a defensive framework, but its execution path makes one important failure concrete: the user-visible image and the model-visible image can diverge after preprocessing. The reusable lesson is to normalize, preview, OCR, diff, and policy-gate screenshots and document images before any visual text can influence agent context or tool use.

## Why It Matters

Coding agents increasingly accept screenshots, design mocks, PDF/image attachments, browser captures, and generated UI images as task context. If the agent or upstream model pipeline resizes those inputs, text that is nearly invisible at the submitted resolution can become legible to the model after downsampling. That breaks a basic operator assumption: "what I saw is what the model received."

Anamorpher matters for error prevention because it demonstrates a concrete prompt-injection channel that bypasses normal text prompt review. The Trail of Bits writeup ties this class to production multimodal systems and agentic tool use, including cases where image text could trigger sensitive actions if the agent trusts visual instructions as ordinary user intent. For Agentic Coding Lab, this belongs in the threat model for screenshot and document intake, MCP/tool approval, browser automation, OCR pipelines, and any "read this image and act" workflow.

## What It Is

Anamorpher is a Python and Flask tool with a static frontend for generating and visualizing image-scaling attacks against multimodal AI systems. It creates crafted high-resolution images that appear benign at full size but reveal a target text image after selected 4:1 downsampling operations.

The repo contains:

- A Flask backend with routes for downsampling images, generating target text images, listing demo/decoy assets, and generating adversarial images.
- Three adversarial generators for nearest-neighbor, bilinear, and bicubic 4:1 downscaling.
- Downsampler adapters for OpenCV, Pillow, PyTorch, and TensorFlow so users can compare implementation-specific behavior.
- A browser UI for selecting images, methods, decoys, and generation parameters.
- Demo and decoy image fixtures, plus tests for generator math, dependency compatibility, imports, and type-fix assumptions.

The repo is mostly useful as an adversarial fixture and design study. It does not implement prompt-injection detection, policy enforcement, user approval, or agent tool restrictions.

## Research Themes

- Token efficiency: Limited. The repo does not optimize token budgets or context packing. The relevant pattern is to avoid sending raw, ambiguous visual context straight to the model; compute a canonical model-visible preview, OCR summary, hashes, and diffs once, then pass only reviewed artifacts into agent context.
- Context control: Very strong as a threat model. The core issue is hidden context introduced by image preprocessing. Defensive systems need a context boundary for visual inputs: every transformed image representation should be explicit, reviewable, and marked untrusted.
- Sub-agent / multi-agent: Not a multi-agent framework. The defensive implication is important for delegated agents: a visual instruction should not be able to propagate from a screenshot-reading step into shell, browser, calendar, email, or MCP tool use without provenance and confirmation.
- Domain-specific workflow: Strong for image preprocessing security. It focuses on downsampling algorithms, implementation differences, 4:1 image transforms, luma-based embedding, and visual verification across libraries.
- Error prevention: Strong as a negative test source. It shows how preprocessing mismatch can create tool-use errors, unsafe command execution, data exfiltration paths, and false operator confidence. It should inspire multimodal input gates rather than be copied as a feature.
- Self-learning / memory: None. There is no memory layer, feedback loop, corpus learning, or adaptive policy.
- Popular skills: Not a skill-pack repo. Reusable "skills" are threat modeling multimodal inputs, fingerprinting preprocessing, generating adversarial fixtures, and verifying model-visible previews before action.

## Core Execution Path

The browser app loads backend configuration from `/api/downsamplers`, `/api/decoy-images`, and `/api/demo-images`. In the downsampling tab, the user uploads a square image whose dimensions are divisible by four or selects a demo image. The frontend sends base64 image data, a downsampler name, an interpolation method, and a target resolution to `/api/downsample`. The backend validates the base64 input, checks image shape and target size, dispatches to the selected downsampler adapter, and returns original plus downsampled images as base64 PNGs.

The adversarial path starts with target text. `/api/generate-text-image` sanitizes the text, font size, image size, and alignment, then renders green text on a dark square image and reports whether the text overflowed. `/api/generate-adversarial` receives method, text, decoy filename, font/alignment, and method parameters. It sanitizes each field, finds a matching decoy from `backend/adversarial_generators/decoy_images`, derives target size as one quarter of the decoy width, and renders a target text image at that size.

Generation runs inside `tempfile.TemporaryDirectory()`. The backend writes `target.png`, copies the selected decoy to `decoy.png`, picks the generator script for the chosen method, validates that script path is inside the adversarial generator directory, and invokes it with `subprocess.run(..., timeout=120)`. The script writes a generated adversarial PNG into the temp directory; the nearest-neighbor script also writes a downsampled verification PNG. The backend globs for method-specific generated filenames, validates the selected output path is inside the temp directory, reads it, and returns base64 images for the adversarial result, target image, and original decoy. The temporary directory is then deleted.

The generator scripts share a pattern: load decoy and target images, convert sRGB to linear-light values, adjust selected high-resolution pixels so the 4:1 downsample trends toward the target text image, convert back to sRGB, save a generated PNG, and print MSE/PSNR verification. The nearest-neighbor generator controls sampled pixels inside 4x4 blocks. The bilinear and bicubic generators compute interpolation weights and update an editable subset selected by a bottom-luma mask. All three currently modify only the red channel.

## Architecture

The architecture is intentionally small:

- `frontend/index.html`, `frontend/script.js`, and `frontend/styles.css`: static UI for image upload, demo selection, method selection, text preview, parameter entry, and result display.
- `backend/app.py`: Flask API, request validation, image encoding/decoding, text rendering, decoy/demo listing, subprocess orchestration, generated artifact loading, and error handling.
- `backend/sanitizer.py`: text, filename, method, alignment, numeric, HTML escaping, and safe-path validation helpers.
- `backend/adversarial_generators/*.py`: standalone CLI generators for nearest-neighbor, bilinear, and bicubic payload images.
- `backend/downsamplers/*.py`: common downsampler interface plus OpenCV, Pillow, PyTorch, and TensorFlow implementations.
- `backend/adversarial_generators/decoy_images/*.png` and `backend/demo_images/*.png`: binary fixture images for generation and demos.
- `tests/*.py`: import, dependency, numerical helper, generator behavior, and type-fix regression tests.
- `.github/workflows/ci.yml`, `.pre-commit-config.yaml`, and `CONTRIBUTING.md`: CI, formatting, linting, type checking, and dependency compatibility rules.

There is no service boundary for agent policy, no model integration, and no defensive runtime. The repo is an image-security lab tool.

## Design Choices

Anamorpher targets exact 4:1 downsampling. This keeps the inverse problem tractable and matches the demo workflow where a high-resolution decoy is transformed into a smaller model-visible target.

The downsampler abstraction is explicit about library differences. OpenCV, Pillow, PyTorch, and TensorFlow all expose similar method names, but their resizing behavior can differ. That design choice is directly relevant to defenses: a guard must test the same preprocessing stack used by the model, not a convenient local approximation.

Generation is implementation-aware rather than prompt-only. The code uses interpolation kernels, sampling offsets, luma masks, linear-light conversion, and per-block solvers. The attack works because preprocessing math creates a second visual representation, not because the visible full-resolution image contains normal readable text.

The backend treats generated artifacts as transient. It creates a private temp directory, writes deterministic input filenames, lets the generator save method-derived output filenames there, validates the output path, reads the image into base64, and relies on context-manager cleanup. Direct CLI use is different: running a generator manually writes `adv*.png` and verification files into the current working directory.

Input sanitization is practical but scoped to a local tool. Text is length-limited, stripped of HTML/control characters, and restricted to a narrow character set. Filenames are basename-normalized and pattern-checked. Numeric parameters have method-specific ranges. Script paths are constrained to the adversarial generator directory. Image data has base64 and decoded-size limits.

One brittle design choice is path anchoring. `backend/app.py` uses relative paths such as `adversarial_generators/...` and `demo_images` instead of anchoring them to the file's directory. The README says to run `uv run python backend/app.py` from the repo root, but those relative paths resolve differently from the actual `backend/...` asset locations unless the process runs from `backend` or env vars are set. Tests do not exercise that end-to-end route behavior.

## Strengths

Anamorpher makes the hidden-transform problem concrete. It is easier to reason about screenshot/document safety when a repo shows original image, transformed image, target image, decoy image, and library-specific downsampler output side by side.

The implementation highlights preprocessing fingerprinting. The same crafted image may behave differently under nearest, bilinear, bicubic, OpenCV, Pillow, TensorFlow, or PyTorch settings. That is a strong warning against generic "we resize safely" assumptions.

Generated artifact handling is mostly contained in the web path. The backend uses temp directories, fixed internal filenames, path validation, and base64 returns instead of exposing arbitrary output paths to the caller.

The sanitization layer addresses ordinary web-tool risks: text length, HTML escaping, filename traversal, method allowlists, numeric bounds, base64 validation, decoded image size, square dimensions, and regular-file checks.

The tests document important numerical and dependency assumptions. They cover color conversions, interpolation weights, luma masks, channel constraints, nearest offsets, dither behavior, shape assertions, NumPy ABI constraints, importability, and CI dependency expectations.

The Trail of Bits blog provides useful defensive framing: avoid downscaling when possible, show users the model-visible transformed image, and prevent visual text from initiating sensitive tool calls without explicit confirmation.

## Weaknesses

It is an offensive generator and visualization tool, not an error-prevention framework. It does not detect hidden prompt injections, classify risky visual text, enforce tool policies, or protect an agent runtime.

The default backend path handling appears brittle relative to the README command. Because asset and script paths are CWD-relative, the documented `uv run python backend/app.py` flow can fail to find `backend/adversarial_generators`, `backend/demo_images`, and generator scripts unless run from the backend directory or configured with environment variables.

Tests are mostly unit-level and mock-heavy. They do not appear to exercise the Flask adversarial generation route, real subprocess execution, default path resolution, demo image loading, frontend/backend integration, or cross-library downsampling results end to end.

The attack implementation is narrow by design. It focuses on exact 4:1 scaling, selected interpolation methods, and current library behavior. Production systems can apply cropping, EXIF handling, colorspace changes, compression, antialiasing, tiling, document rasterization, or model-specific preprocessing that changes the outcome.

The generator math currently modifies only one color channel. That matches the demo style but is not a complete model of all possible image-scaling prompt injection techniques.

The web app returns generator stdout in the API response. That is useful for a local lab, but production defensive tooling should return structured metrics and artifact provenance, not raw script output.

There is no audit manifest for generated images. A defensive harness would want original hash, transformed hash, exact preprocessing library/version, dimensions, OCR outputs, policy decision, and user approval status.

The tool can help users create harmful multimodal prompt-injection artifacts. For defensive use, it should be isolated to test fixtures and red-team workflows, not exposed as a general utility.

## Ideas To Steal

Build a multimodal intake gate that renders the exact image representation the model will receive, then shows that representation to the user before visual text can affect tool use.

Treat screenshots and document images as untrusted instruction sources. OCR or model-read text extracted from images should be labeled as observed content, not promoted to developer/user commands.

Create differential visual checks: compare full-resolution OCR, model-resolution OCR, and thumbnails. If new imperative text appears only after transformation, fail closed or require explicit human approval.

Use a library-specific preprocessing harness. Test OpenCV, Pillow, browser canvas, PDF rasterizers, screenshot tools, and model-provider transforms separately because implementation details matter.

Store artifact provenance for every visual input: original bytes hash, decoded image metadata, transforms applied, output dimensions, preprocessing code version, OCR summaries, and policy decisions.

Add adversarial image fixtures to coding-agent evals. The pass condition should be that the agent reports suspicious visual-context mismatch and refuses to execute sensitive instructions from image text.

Separate "describe image" from "obey image." A screenshot reader can summarize visible content, but shell/file/network/MCP actions should require text-channel intent or explicit confirmation.

For document inputs, preview the rasterized pages the model sees rather than only the original PDF or uploaded image. Hidden content can emerge during scaling, rasterization, or thumbnail generation.

## Do Not Copy

Do not copy attack-generation code into normal agent workflows. Use it only in controlled security tests and fixtures.

Do not rely on choosing a "safe" downsampler as the main defense. The project and blog both show that implementation differences are fragile, and future transforms can change behavior.

Do not show users only the original high-resolution image. The relevant preview is the model-visible transformed image.

Do not let visual text initiate sensitive tool calls, shell commands, file writes, dependency installs, commits, emails, calendar actions, browser actions, or MCP calls without independent confirmation.

Do not anchor production policy to CWD-relative paths. Agent safety tools need explicit repo roots, content-addressed artifacts, and deterministic path resolution.

Do not depend on OCR alone. OCR can miss stylized, low-contrast, transformed, or model-legible text. Use OCR as one signal alongside image normalization, transform diffs, policy labels, and approval gates.

Do not return raw generator logs as the main API contract for defensive tools. Return structured metrics and decisions that agents can inspect reliably.

Do not assume unit tests of interpolation helpers prove end-to-end safety. The dangerous behavior appears at the full preprocessing pipeline boundary.

## Fit For Agentic Coding Lab

Fit is conditional but important for `error-prevention`. Anamorpher is not reusable as a guardrail library, but it is a strong adversarial reference for multimodal prompt-injection defenses around coding agents.

Best Agentic Coding Lab adaptations:

- A screenshot/document intake guard that normalizes images through the same pipeline used before model submission.
- A "model-visible preview" requirement for CLI and browser-based agents.
- OCR and vision-model differential checks between original, thumbnail, model-sized, and provider-sized variants.
- Tool-permission rules that block image-derived instructions from triggering sensitive actions.
- Eval fixtures based on benign-looking screenshots that reveal short hidden instruction identifiers after downsampling, without storing operational attack payloads in docs.
- A provenance record attached to each visual artifact so later agent steps know whether text came from user input, OCR, model vision, or transformed image content.

The main implementation lesson is not the pixel solver. It is the policy boundary: visual context must be transformed, inspected, labeled, and constrained before it joins the instruction hierarchy.

## Reviewed Paths

- `README.md`: repo purpose, setup, supported methods, limitations, and references.
- Trail of Bits blog post "Weaponizing image scaling against production AI systems" (2025-08-21): attack context, implementation-specific preprocessing discussion, and mitigation guidance.
- `pyproject.toml`: package metadata, Python/dependency constraints, build config, lint/type/test tooling.
- `CONTRIBUTING.md`: dependency compatibility matrix, CI expectations, and NumPy ABI risk.
- `.github/workflows/ci.yml`, `.github/dependabot.yml`, and `.pre-commit-config.yaml`: test/lint/typecheck workflow, pinned actions, dependency update policy, and formatting hooks.
- `backend/app.py`: Flask routes, base64 image validation, text rendering, decoy/demo listing, downsampling, adversarial generation orchestration, subprocess execution, temp artifact handling, and error responses.
- `backend/sanitizer.py`: text, filename, alignment, method, numeric, HTML escaping, and safe-path validation.
- `backend/adversarial_generators/nearest_gen_payload.py`: nearest-neighbor generator, 4x block sampling offset, color conversion, null-space dither, CLI outputs, and verification downsample artifact.
- `backend/adversarial_generators/bicubic_gen_payload.py`: bicubic kernel weights, luma mask, editable subset solver, color conversion, CLI output, and MSE/PSNR verification.
- `backend/adversarial_generators/bilinear_gen_payload.py`: bilinear weights, OpenCV-oriented verification path, luma mask, editable subset solver, antialias flag, and CLI output.
- `backend/downsamplers/base.py`, `opencv_downsampler.py`, `pillow_downsampler.py`, `pytorch_downsampler.py`, `tensorflow_downsampler.py`, and `__init__.py`: adapter interface and library-specific resizing behavior.
- `frontend/script.js`: API wiring, upload checks, demo loading, downsampling request flow, text preview request flow, adversarial generation request flow, and result display.
- `frontend/index.html`: UI controls and expected user workflow for downsampling and adversarial generation.
- `tests/test_nearest_gen_payload.py`, `test_bicubic_gen_payload.py`, and `test_bilinear_gen_payload.py`: generator helper, interpolation, luma, channel, dither, argument, and shape tests.
- `tests/test_build.py`, `test_dependencies.py`, `test_dependency_constraints.py`, and `test_type_fixes_verification.py`: project structure, import, dependency, ABI, and type-regression tests.
- `backend/adversarial_generators/decoy_images/*.png`, `backend/demo_images/*.png`, `image_scaling_figure.png`, and `gemini-cli-PoC.gif`: reviewed only as binary fixture/demo inventory and dimensions, not as source logic or reproduced payload content.

## Excluded Paths

- `.git/**`: checkout metadata, not part of the reviewed source design.
- `uv.lock`: generated dependency lock data. I reviewed `pyproject.toml`, dependency tests, and `CONTRIBUTING.md` for dependency policy instead.
- `LICENSE` and `CODEOWNERS`: project governance metadata, not relevant to execution path or defensive design.
- Most of `frontend/styles.css`: UI-only presentation. I skimmed enough to confirm it does not affect backend generation, artifact handling, or agent-safety implications.
- Binary images and GIFs under `backend/adversarial_generators/decoy_images/**`, `backend/demo_images/**`, `image_scaling_figure.png`, and `gemini-cli-PoC.gif`: useful as fixtures and demonstrations, but binary content was not reproduced or analyzed for payload text. I recorded their role and dimensions only.
- External linked research papers and third-party docs from README/blog references: useful background, but the reviewed implementation and defensive conclusions came from this repo plus the linked Trail of Bits project writeup.
- Installed dependencies and package internals for Flask, OpenCV, Pillow, PyTorch, TensorFlow, NumPy, bleach, and MarkupSafe: reviewed as declared dependencies and through local adapter use, not as vendored source.
