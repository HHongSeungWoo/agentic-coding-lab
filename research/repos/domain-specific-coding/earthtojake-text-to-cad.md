# earthtojake/text-to-cad

- URL: https://github.com/earthtojake/text-to-cad
- Category: domain-specific-coding
- Stars snapshot: 5,214 (GitHub REST API repository endpoint, captured 2026-05-29)
- Reviewed commit: ed8c56ced37cc944b71c0c68c2e1d629b269f93a
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Very strong candidate for domain-specific CAD, robotics, and hardware-design agent skills. Best reusable patterns are STEP-first artifact contracts, source-backed generator functions, topology-rich GLB sidecars, `@cad[...]` selectors, explicit geometry inspection and snapshot loops, local viewer handoff, robotics format boundaries, dry-run fabrication/printer workflows, and generated-runtime freshness checks. Biggest caveats are heavy dependencies, large generated package copies, limited automated benchmark scoring, and some physical-world safety/manufacturability checks remaining advisory.

## Why It Matters

`text-to-cad` is one of the clearest examples of domain-specific coding skills that go beyond prose. The repository packages CAD, robotics, fabrication, slicing, printer handoff, and local visual review into installable agent skills with shared Python and JavaScript runtimes.

For Agentic Coding Lab, the repo matters because it turns ambiguous natural-language hardware work into structured artifact generation. It defines primary outputs, sidecars, selectors, inspection commands, visual snapshots, viewer links, robot-description validators, catalog lookup, and dry-run physical handoffs. This is the kind of domain loop coding agents need when plain code tests are not enough.

## What It Is

The repo is a CAD skills workbench and plugin package. Root `skills/` is the source product; `plugins/cad/skills/` is a generated installable copy for Codex and Claude Code. The reviewed skill set includes:

- `cad`: build123d/Python CAD generation, STEP/STP primary outputs, DXF/STL/3MF/native GLB secondary outputs, inspection, snapshots, and viewer handoff.
- `cad-viewer`: local browser workbench for STEP/STP, GLB, STL, 3MF, G-code, DXF, URDF, SRDF, and SDF files.
- `step-parts`: hosted step.parts API search/download with checksum verification.
- `urdf`, `srdf`, and `sdf`: robot structure, MoveIt2 semantics, and simulator/world XML generation with validation.
- `gcode` and `bambu-labs`: slicer-backed plain G-code generation plus cautious local Bambu LAN upload/start controls.
- `sendcutsend`: SendCutSend-focused DXF/STEP preflight workflow using official source data and measured geometry facts.

The supporting code is substantial: `packages/cadpy` owns STEP/GLB/topology artifact generation; `packages/cadjs` owns reusable Three.js rendering, selectors, parsers, and viewer runtime helpers; `viewer/` is the React/Vite local review app; `packages/cadpy_metadata` supplies dependency-light provenance and generation-status helpers for URDF/SRDF/SDF runtimes.

## Research Themes

- Token efficiency: Strong. The skills use compact activation files with progressive references, and push geometry parsing, rendering, inspection, slicing, printer protocol, and source hashing into local scripts/packages instead of model context. Weakness: generated skill/runtime copies make the repo large, and agents need path discipline to avoid reading duplicate generated trees.
- Context control: Strong. CAD work is driven by explicit source files, output paths, `gen_step()`/`gen_urdf()`/`gen_srdf()`/`gen_sdf()` functions, hidden sidecars, source hashes, and viewer catalog metadata. The repo rules clearly separate source-of-truth directories from generated plugin/runtime copies.
- Sub-agent / multi-agent: Light. The repo does not implement multi-agent orchestration. Its transfer value is as a domain toolchain that subagents could use safely if handed explicit artifact paths and validation criteria.
- Domain-specific workflow: Excellent. It encodes CAD modeling assumptions, STEP-first generation, assembly positioning, topology selectors, visual snapshots, URDF/SRDF/SDF semantics, slicer profiles, Bambu LAN constraints, off-the-shelf part sourcing, and fabrication preflight.
- Error prevention: Strong but not complete. There are deterministic checks for output suffixes, unique targets, source fingerprints, stale topology sidecars, URDF graph validity, SRDF planning semantics, SDF structure, G-code profile bounds, printer start confirmations, local-host constraints, and generated-copy freshness. Engineering certification, FEA, real manufacturability, and printer physical safety still need human review.
- Self-learning / memory: No adaptive learning. Memory is artifact/provenance based: source hashes, generation lock files, metadata comments, STEP metadata, hidden GLB topology manifests, viewer catalog entries, and benchmark specs.
- Popular skills: `cad`, `cad-viewer`, `step-parts`, `urdf`, `srdf`, `sdf`, `gcode`, `bambu-labs`, `sendcutsend`.

## Core Execution Path

The main CAD path is:

1. The `cad` skill classifies the request as part, assembly, modification, direct inspection, measurement, snapshot, or secondary export.
2. The agent writes or edits a build123d Python source with a callable `gen_step()`, using prose requirements as the user-facing specification and internal parameters as the CAD brief.
3. `skills/cad/scripts/step` calls into `cadpy.generation`, loads the generator, validates the envelope, writes STEP when needed, and produces a hidden `.step.glb` sidecar with topology and selector data.
4. `cadpy` records source hash/fingerprint metadata, compares existing sidecars against source and STEP hashes, invalidates stale topology, and warns when selector topology or geometry changes.
5. The agent runs `scripts/inspect refs --facts --planes --positioning` and targeted `measure`, `mate`, `frame`, or `diff` commands when geometry references matter.
6. The agent runs `scripts/snapshot` for visual verification of primary STEP/STP changes and then hands explicit files to `cad-viewer`.
7. CAD Viewer starts or reuses a local server for the owning root directory and returns per-file review links.

The robotics path is similar but XML-focused:

1. `urdf` generates explicit `.urdf` targets from `gen_urdf()`, embeds source metadata, and validates tree shape, links, joints, origins, axes, inertials, meshes, and limits.
2. `srdf` generates explicit `.srdf` targets from `gen_srdf()`, requires a linked valid URDF, inserts URDF metadata, checks robot-name match, validates planning groups, chains, end effectors, group states, and disabled collision link names.
3. `sdf` generates explicit `.sdf` targets from `gen_sdf()`, runs bundled validation, optionally runs `gz sdf --check`, and reports generator assumptions/warnings.
4. All robot-description skills require CAD Viewer handoff for created or modified artifacts.

The fabrication/printer path is deliberately staged:

1. `gcode` requires a supported mesh, explicit printer/profile wrapper JSON, slicer discovery, input inspection, dry-run slicing, execution, and static G-code validation.
2. `bambu-labs` starts from validated plain G-code, defaults to dry-run plans, requires `--execute` for network actions, requires `--confirm-start-print` for print starts, checks private/link-local/loopback printer hosts unless overridden, and distinguishes upload-only from upload-start.
3. `sendcutsend` fetches current official source data, measures exact DXF/STEP facts, compares only cited requirements to measured facts, and avoids ready verdicts when source evidence or order context is missing.

## Architecture

The repository is organized around source skills plus generated distribution copies:

- `skills/`: source skill directories, references, scripts, runtime package copies, and assets.
- `plugins/cad/`: generated plugin package with `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`, version metadata, and materialized skill copies.
- `.codex-plugin/marketplace.json` and `.claude-plugin/marketplace.json`: root marketplace entries that point to `plugins/cad`.
- `packages/cadpy`: Python package for STEP export/import, OpenCascade/build123d scene handling, GLB/topology sidecars, selector manifests, source hashing, assembly composition, validators, and artifact CLI.
- `packages/cadjs`: framework-agnostic JavaScript runtime for file scanning, STEP topology, render loading, Three.js model building, snapshot capture, robot parsers, selectors, display edges, DXF/G-code previews, and viewer utilities.
- `packages/cadpy_metadata`: small dependency-free Python helpers for source identity, metadata comments, and generation lock files used by URDF/SRDF/SDF runtimes.
- `viewer/`: React/Vite CAD Viewer app, local/hosted backends, server registry, MoveIt2 websocket support, and generated local package copies.
- `benchmarks/`: ten prompt-plus-test-case CAD benchmark specs with LFS-rendered GIF outputs.
- `scripts/build/*` and `scripts/check/*`: generated runtime builders, plugin validators, version checks, and full repo test wrapper.
- `docs/`: documentation site and demo surfaces.

The architectural boundary is explicit: root `packages/*` and `viewer/*` are source of truth; `skills/*/scripts/packages`, `skills/cad-viewer/scripts/viewer`, `viewer/packages/*`, and `plugins/cad/skills/*` are generated copies and should be refreshed by build scripts rather than hand-edited.

## Design Choices

The strongest design choice is making STEP the primary CAD artifact. The CAD skill treats STL, 3MF, DXF, and native GLB as secondary branches from or companions to a STEP-first process. That keeps the loop anchored in a high-fidelity exchange format instead of render-only geometry.

The second major choice is source-backed generation. Python generator functions are the editable source of truth, while STEP, XML, GLB, topology, STL, 3MF, DXF, and G-code files are derived artifacts. Source fingerprints include imported Python dependencies where possible, which lets tools detect stale outputs rather than trusting timestamps alone.

The third choice is making geometric references copyable and inspectable. Hidden GLB topology sidecars contain selectors for shapes, faces, edges, vertices, and occurrences. `@cad[...]` references can then be inspected, measured, diffed, or mated through CLI commands and CAD Viewer.

The fourth choice is explicit local visual review. CAD Viewer is not just a demo app; skills are instructed to start it and return exact links after creating or modifying CAD, robot-description, DXF, G-code, or mesh artifacts. Snapshot rendering also shares the `cadjs` render pipeline so deterministic visual checks are possible outside the interactive app.

The fifth choice is domain separation across robot formats. URDF owns physical structure, SRDF owns MoveIt planning semantics, and SDF owns simulation/world behavior. The skill instructions and scripts both reinforce those boundaries.

The sixth choice is cautious physical-world handoff. Slicing and Bambu workflows are dry-run-first, require explicit profiles or printer config, avoid inventing printer profiles, distinguish upload from start, and require stronger flags for live printer operations.

## Strengths

- Full domain workflow, not just prompts: CAD generation, inspection, rendering, viewer links, robot formats, part sourcing, slicing, fabrication checks, and printer handoff are all represented.
- Strong artifact contracts: explicit target paths, output suffix validation, unique output checks, source metadata, source fingerprints, generation lock files, and stale-sidecar detection.
- High-value topology layer: GLB sidecars carry selector/topology information that supports stable references, inspection, picking, measurements, planes, frames, and diff/mate workflows.
- Good generated-runtime discipline: source packages are copied into skill and viewer runtimes by build scripts, plugin copies are generated from root skills, and CI checks freshness.
- Useful robotics validators: URDF tree and mesh checks, SRDF-vs-URDF semantic checks, SDF structure checks, optional `gz sdf --check`, and clear limits on what static validation can prove.
- Practical hardware safety posture: G-code requires real slicer backends and explicit profile wrappers; Bambu workflows are dry-run by default and gate live starts; SendCutSend reviews are evidence-backed rather than speculative.
- Strong local viewer pattern: file catalog scanning, hidden sidecars, optional artifact regeneration, MoveIt2 controls, screenshot capture, and multiple CAD/robot/file formats in one workbench.
- Benchmarks are domain-relevant and readable: prompt specs include dimensions, expected bodies, geometric constraints, and negative checks.
- CI is broad for a skill repo: Node tests, viewer build, docs check, plugin validation, generated runtime checks, Python unittest discovery, and release-version consistency.

## Weaknesses

- The repo is large and duplicate-heavy because generated skill/plugin/viewer runtime copies are checked in. Reviewers and agents must avoid treating generated copies as separate source surfaces.
- Dependency cost is high. CAD work depends on build123d, cadquery-ocp/OpenCascade, VTK, trimesh, Playwright, Three.js, Node builds, and optional slicers or Gazebo/MoveIt tools.
- Benchmark specs are useful but not a full automated CAD eval harness. The Markdown cases define expected checks, but the reviewed repo does not appear to mechanically score all benchmark outputs against those criteria.
- Physical safety still relies on operator confirmation. The Bambu helper gates start commands, but it cannot verify build-plate clearance, filament, nozzle, surroundings, or printer UI acceptance.
- Manufacturability and engineering correctness are bounded. The skills explicitly avoid certification claims, and static checks cannot replace FEA, tolerance analysis, process-specific tooling review, or real-world test prints.
- Some enforcement remains host-prompt level. Viewer handoff, snapshot review, step.parts lookup before placeholders, and SendCutSend source freshness are skill requirements that depend on the calling agent following instructions.
- Broad plugin install includes network/printer/fabrication capabilities in one package. Future consumers should consider capability-scoped installs or explicit permission gates per physical side-effect workflow.
- Source loading for CAD generators necessarily adjusts import paths around the workspace and skill runtime. That is practical for local CAD projects but needs careful sandboxing in less trusted environments.

## Ideas To Steal

- Use a primary domain artifact contract: for CAD, make STEP primary and treat render/toolpath/mesh files as derived or secondary.
- Require generator functions such as `gen_step()`, `gen_urdf()`, `gen_srdf()`, and `gen_sdf()` as source-of-truth entrypoints for structured artifact generation.
- Pair generated binary/visual artifacts with machine-readable sidecars that carry topology, selectors, source hashes, and provenance.
- Make references copyable: `@cad[...]` selectors are a strong pattern for moving from visual picking to repeatable CLI inspection.
- Add a mandatory "generate, inspect, snapshot, view" loop for non-text artifacts where unit tests alone are insufficient.
- Split domain formats by ownership. URDF, SRDF, and SDF boundaries are a reusable model for other domains with adjacent but distinct artifact types.
- Ship a local reviewer app when domain artifacts are hard to evaluate in text. The app should run against explicit roots and return stable per-file links.
- Use dry-run-first helpers for physical side effects, and require extra flags for upload, start, cancel, or other irreversible operations.
- Treat generated runtime/package copies as checked artifacts with freshness scripts and CI, not as hand-edited source.
- Keep domain benchmarks as prompt specs with explicit positive and negative checks, then evolve them into executable evals.

## Do Not Copy

- Do not copy the whole generated tree into another lab system. Extract the source/package/build pattern and regenerate target-specific bundles.
- Do not rely on CAD Viewer snapshots as proof of engineering correctness. They are visual review aids, not manufacturability, safety, tolerance, or physics verification.
- Do not merge printer-control capabilities into a default skill install without clear permission boundaries.
- Do not let large CAD assets, GLB sidecars, or LFS pointers flow into model context. Keep them as files and inspect through structured tools.
- Do not treat off-the-shelf component placeholders as acceptable before catalog search when exact purchasable parts matter.
- Do not copy vendor-specific SendCutSend or Bambu rules as stable facts. Those workflows need current official sources, device status, and explicit operator intent.
- Do not hand-edit generated package/plugin copies. The useful pattern is source-first edit plus generated freshness check.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`. This repo should be treated as a pattern source for artifact-heavy coding domains where the output is not just source code. It demonstrates how to combine skills, scripts, packages, sidecars, local viewers, provenance, validation, and physical-world safety gates into a single agent-facing workflow.

Best direct transfers:

- A generic structured-artifact skill template: source generator, primary artifact, derived sidecars, inspection CLI, visual review, provenance, and final handoff.
- A selector/reference system for non-text outputs, modeled on `@cad[...]`.
- A local viewer handoff contract for CAD, robotics, diagrams, data pipelines, or simulation artifacts.
- A generated-runtime packaging discipline for skills that need heavy local helper code.
- A dry-run and explicit-confirmation contract for workflows that touch hardware, manufacturing vendors, cloud spend, or external systems.

Less direct transfers:

- CAD/OpenCascade-specific implementation details are too domain-bound to reuse outside geometry-heavy systems.
- Bambu LAN and SendCutSend details should be treated as examples of physical/vendor boundary design, not generic rules.
- The repo's full dependency stack is appropriate for CAD but too heavy for simple domain skills.

## Reviewed Paths

- `/tmp/myagents-research/earthtojake-text-to-cad/README.md`: skill catalog, installation paths, benchmark list, LFS guidance, and overall positioning.
- `/tmp/myagents-research/earthtojake-text-to-cad/AGENTS.md`: source/generated boundaries, artifact placement, validation commands, viewer rules, and LFS policy.
- `/tmp/myagents-research/earthtojake-text-to-cad/CONTRIBUTING.md` and `COMMIT.md`: local setup, skill linking, runtime regeneration, source boundaries, release/version workflow, and git hygiene.
- `/tmp/myagents-research/earthtojake-text-to-cad/.codex-plugin/marketplace.json`, `.claude-plugin/marketplace.json`, `plugins/cad/.codex-plugin/plugin.json`, `plugins/cad/.claude-plugin/plugin.json`, and `plugins/cad/README.md`: marketplace and plugin packaging.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/cad/SKILL.md` plus selected references: CAD activation, STEP-first workflow, inspection, snapshots, positioning, parameters, secondary exports, repair loop, and viewer handoff.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/cad-viewer/SKILL.md` and `viewer/README.md`: local viewer startup, root/file URL contract, supported formats, server reuse, and MoveIt2 handoff notes.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/urdf/SKILL.md`, `skills/urdf/scripts/urdf/cli.py`, and `skills/urdf/scripts/urdf/source.py`: URDF source-of-truth generator flow and validation implementation.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/srdf/SKILL.md`, `skills/srdf/scripts/srdf/cli.py`, and `skills/srdf/scripts/srdf/source.py`: SRDF workflow, URDF linkage, planning-group validation, end-effector checks, group states, and disabled-collision handling.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/sdf/SKILL.md`, `skills/sdf/scripts/sdf/cli.py`, and `skills/sdf/scripts/sdf/validation.py`: SDF generation, bundled validation, optional external `gz sdf --check`, assumptions, and warnings.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/gcode/SKILL.md` and `skills/gcode/scripts/gcode_tool.py`: slicer discovery, profile contract, dry-run/execute split, static G-code validation, and input-format boundaries.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/bambu-labs/SKILL.md` and `skills/bambu-labs/scripts/bambu_lan_print.py`: printer safety rules, config, FTPS/MQTT handoff, local-host checks, dry-run defaults, and live start/cancel confirmation flags.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/sendcutsend/SKILL.md`: official-source fetch requirement, measured geometry comparisons, DXF/STEP preflight shape, and report discipline.
- `/tmp/myagents-research/earthtojake-text-to-cad/skills/step-parts/SKILL.md` and `skills/step-parts/scripts/download_step_part.py`: hosted API lookup, alias search guidance, STEP download, checksum verification, and viewer handoff.
- `/tmp/myagents-research/earthtojake-text-to-cad/packages/cadpy/README.md`, `packages/cadpy/src/cadpy/generation.py`, `step_artifact.py`, `validators.py`, `reporting.py`, `glb.py`, `glb_topology.py`, `step_scene.py`, and selected tests: STEP generation, topology sidecars, selector manifests, source fingerprints, stale artifact checks, validation helpers, and assembly behavior.
- `/tmp/myagents-research/earthtojake-text-to-cad/packages/cadjs/README.md`, `packages/cadjs/docs/render-pipeline.md`, `packages/cadjs/src/lib/cadDirectoryScanner.mjs`, and `packages/cadjs/src/lib/step/stepArtifactCompiler.mjs`: reusable JS runtime, render pipeline, catalog scanning, topology validation, and artifact regeneration.
- `/tmp/myagents-research/earthtojake-text-to-cad/packages/cadpy_metadata/README.md` and `packages/cadpy_metadata/src/cadpy_metadata/generator.py`: dependency-light source identity, XML metadata, and generation-status locks.
- `/tmp/myagents-research/earthtojake-text-to-cad/benchmarks/*.md`: ten CAD benchmark prompt specs and expected geometric checks.
- `/tmp/myagents-research/earthtojake-text-to-cad/scripts/test.sh`, `scripts/check/test.sh`, `scripts/build/*.sh`, `scripts/check/validate-plugins.sh`, and `.github/workflows/check-builds.yml`: CI, generated-copy freshness, plugin validation, package checks, docs checks, and broad test wrapper.
- `/tmp/myagents-research/earthtojake-text-to-cad/.gitattributes` and `.lfsconfig`: LFS policy for CAD exchange files, GLB/topology assets, benchmark GIFs, and asset fetch exclusions.

## Excluded Paths

- `/tmp/myagents-research/earthtojake-text-to-cad/.git/`: VCS internals; commit SHA and clean checkout status were captured separately.
- Generated package/plugin copies under `plugins/cad/skills/*`, `viewer/packages/*`, `skills/cad/scripts/packages/*`, `skills/cad-viewer/scripts/viewer/packages/*`, and built viewer `dist` assets: sampled for packaging context but not reviewed as independent source because repo rules mark root `skills/`, `packages/`, and `viewer/` as sources of truth.
- Large LFS-backed GIF/assets under `assets/**` and `benchmarks/**`: reviewed through README, Markdown specs, and LFS policy; binary visual contents were not exhaustively inspected.
- Full docs site implementation under `docs/`: sampled through README/package/config and route/component inventory; the research target was agent workflow/runtime design, not marketing site implementation.
- Full minified/sourcemap bundles and generated snapshot browser runtime assets: excluded because source modules and build scripts were available.
- External services and devices: step.parts, SendCutSend, Bambu printers, slicer CLIs, Gazebo, and MoveIt2 were reviewed from checked-in skill contracts and scripts; no live hardware, vendor order, or simulator run was performed.
- Remote branches and unmerged pull requests other than the reviewed `main` commit.
