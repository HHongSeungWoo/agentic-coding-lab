# anthropics/skills

- URL: https://github.com/anthropics/skills
- Category: skills-instructions
- Stars snapshot: 131,994 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: f458cee31a7577a47ba0c9a101976fa599385174
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal reference for Agent Skills packaging, progressive disclosure, domain-specific instructions, helper scripts, plugin distribution, and deterministic verification patterns; it is not an agent application, but it is directly reusable as a model for skill systems.

## Why It Matters

This repository is Anthropic's public reference corpus for Claude skills. It matters because it shows what a production-oriented skill ecosystem looks like in practice: each capability is a directory with frontmatter, activation description, instructions, optional scripts, reference material, and assets. The README defines skills as "folders of instructions, scripts, and resources" that Claude can load dynamically (source: `/tmp/myagents-research/anthropics-skills/README.md`).

For agentic coding research, the value is not a runnable agent loop. The value is the interface contract between an agent and externalized capability packs: concise metadata for triggering, progressive loading of detailed guidance, executable helpers as tool boundaries, and examples of QA, validation, packaging, and evaluation.

## What It Is

`anthropics/skills` is a reference and distribution repository for Agent Skills. It contains 17 skill directories under `skills/`, a minimal `template/SKILL.md`, a spec redirect in `spec/agent-skills-spec.md`, marketplace metadata in `.claude-plugin/marketplace.json`, and third-party notices.

The repository splits its installable Claude Code plugin surface into `document-skills`, `example-skills`, and `claude-api` bundles. The marketplace metadata points each plugin to selected skill directories and marks them `strict: false` (source: `/tmp/myagents-research/anthropics-skills/.claude-plugin/marketplace.json`).

The local spec file now delegates to `https://agentskills.io/specification`. That page defines a skill as a directory requiring `SKILL.md`, with optional `scripts/`, `references/`, and `assets/`; it also describes progressive disclosure where metadata is loaded first, then the body, then resources as needed (source: `https://agentskills.io/specification`).

## Research Themes

- Token efficiency: Strong. The core design keeps startup context small by exposing only `name` and `description`, then loading `SKILL.md` and auxiliary resources only after trigger. Many skills explicitly tell the agent to load reference files only when needed.
- Context control: Strong. Large content is pushed into scripts, references, examples, templates, and assets. `webapp-testing` explicitly warns not to read large scripts before trying `--help`.
- Sub-agent / multi-agent: Moderate. `skill-creator` uses with-skill and baseline runs, grader/analyst agents, and benchmark aggregation. It is an evaluation workflow, not a general multi-agent runtime.
- Domain-specific workflow: Very strong. Document skills, MCP building, frontend design, web testing, communications, artifacts, brand styling, and generative art each encode domain-specific procedures and constraints.
- Error prevention: Strong. Document skills include validation and QA loops, formula error checking, XML schema validation, visual inspection, and explicit pitfalls.
- Self-learning / memory: Conditional. The repo does not implement long-term agent memory, but `skill-creator` has iterative eval/improve loops, history files, train/test split, and description optimization.
- Popular skills: No usage or install-frequency data was reviewed, so this note does not rank skill popularity. Locally relevant skills for agentic coding and tool-use research include document manipulation (`pdf`, `docx`, `pptx`, `xlsx`), `skill-creator`, `mcp-builder`, `webapp-testing`, `frontend-design`, and `web-artifacts-builder`.

## Core Execution Path

Execution starts outside this repository in a host client such as Claude Code, Claude.ai, or the Claude API. The client discovers skill metadata from installed skill directories or plugin bundles. The activation decision is driven primarily by the `name` and `description` frontmatter in each `SKILL.md`.

When a user request matches a skill description, the host loads that skill's `SKILL.md` body. The body then directs the agent through a task-specific workflow and points to local scripts, references, examples, or assets. Data moves from user request to skill instructions, then into either model-guided work or deterministic helper scripts. Script outputs, generated files, validation results, screenshots, and benchmark JSON become feedback for the agent.

Representative execution paths:

- `webapp-testing`: User asks to test a local app. Skill tells the agent to choose static HTML, existing server, or managed server path. For managed servers, run `scripts/with_server.py --help`, then use the helper to start servers, wait on ports, run a Playwright script, and clean up processes.
- `skill-creator`: User asks to create or improve a skill. The skill captures intent, drafts `SKILL.md`, creates eval prompts, runs with-skill and baseline cases, grades outputs, aggregates benchmarks, generates review UI, then iterates. `scripts/run_eval.py` simulates trigger checks by creating temporary Claude command files and watching `claude -p` stream events for `Skill` or `Read` tool activation.
- `xlsx`: User wants spreadsheet work. The skill routes analysis to pandas/openpyxl, requires formulas instead of hardcoded calculated values, runs `scripts/recalc.py`, and checks recalculated workbook output for Excel errors.
- `pptx` and `docx`: User asks to create or edit Office files. The skill directs the agent through extraction, editing, packing, validation, rendering, and QA. `scripts/office/validate.py` validates Office XML and selected redlining constraints.

There is no central orchestration loop, loader implementation, sandbox layer, or permission manager in this repository. The orchestration boundary belongs to the host agent client; this repo supplies skill metadata, instructions, helper scripts, examples, and packaged plugin metadata.

## Architecture

The architecture is file-system native:

- `README.md`: repository purpose, install/use instructions, plugin commands, and basic skill creation guidance.
- `.claude-plugin/marketplace.json`: Claude Code marketplace metadata defining plugin bundles and included skill paths.
- `template/SKILL.md`: minimal skill skeleton with `name` and `description`.
- `spec/agent-skills-spec.md`: redirect to the live Agent Skills specification.
- `skills/<skill>/SKILL.md`: activation metadata and main instructions for each skill.
- `skills/<skill>/scripts/`: executable helpers for deterministic work or local workflow setup.
- `skills/<skill>/reference*/`, `examples/`, `templates/`, `assets/`, `themes/`, `canvas-fonts/`: additional materials loaded or used only when relevant.

The most sophisticated skill-internal architecture appears in `skill-creator`: it has `agents/` prompts, `scripts/` for validation/eval/reporting/aggregation, `references/schemas.md`, an `eval-viewer/`, and an HTML review asset. Document skills share office helper code and large OOXML schema trees, suggesting substantial document validation machinery reused across `docx`, `pptx`, and `xlsx`.

## Design Choices

The most important design choice is progressive disclosure. Descriptions carry trigger semantics; the main body carries compact procedural guidance; detailed implementation material lives in side files or scripts. This makes each skill a context-budgeted capability pack rather than a monolithic prompt.

Descriptions are intentionally specific and sometimes forceful. For example, `pdf` says to use the skill when a `.pdf` is mentioned or produced; `pptx` says to trigger whenever the user mentions decks, slides, presentations, or `.pptx`; `xlsx` explicitly excludes cases where the deliverable is not a spreadsheet. This is useful trigger engineering.

Helper scripts are used as execution boundaries. They encode repeatable operations such as server lifecycle management, Office validation, formula recalculation, PDF form inspection, skill validation, packaging, benchmark aggregation, and trigger-eval automation. The scripts generally print actionable error messages or structured JSON.

The repository separates simple instruction-only skills from complex production-like skills. `brand-guidelines` is mostly static design guidance; `internal-comms` routes to examples; `skill-creator`, `web-artifacts-builder`, document skills, and `mcp-builder` combine procedural workflows with executable tools and deeper references.

## Strengths

The repo is a clear reference for how to externalize agent behavior into portable, inspectable, installable units. It shows how much can be moved out of the system prompt and into task-triggered capabilities.

The document skills are especially useful for research because they include concrete verification loops: LibreOffice conversion, XML validation, visual rendering, formula recalculation, and error scans. These are not just style prompts; they are task workflows with measurable failure checks.

`skill-creator` is a strong meta-example. It treats skill quality as measurable behavior: test prompts, baseline comparisons, grader output, benchmark summaries, and description optimization. That is directly relevant to building self-improving agent instruction systems.

The marketplace metadata demonstrates a practical distribution mechanism. A repository can expose several installable bundles from the same source tree instead of forcing one all-or-nothing skill set.

## Weaknesses

The repository does not include the actual host-side skill loader, activation model, permission policy, sandbox enforcement, or runtime orchestration loop. Those are critical to real agent behavior but live outside this repo.

The local `spec/` directory is only a redirect, so the complete specification must be fetched from `agentskills.io`. This makes the repository less self-contained for offline archival review.

There are few conventional automated tests. The repo contains examples and evaluation machinery, but no top-level test suite for validating every included skill and script together.

Some skills carry large binary or schema payloads. That is realistic for production use, but it makes code review uneven: the important behavior is in instructions and selected scripts, while many assets are support material rather than logic.

## Ideas To Steal

Use skill descriptions as explicit trigger contracts, not vague summaries. Include positive and negative trigger conditions where misactivation is costly.

Adopt progressive disclosure as the core skill layout: small metadata, concise main instructions, task-specific references, and scripts for deterministic work.

Treat bundled scripts as black-box tools when possible. Tell the agent to run `--help` first and only read source when customization is necessary.

Package skill families into installable bundles, while preserving each skill as its own directory. This supports domain bundles like `document-skills` without collapsing everything into one prompt.

Build QA directly into skills. Good examples: `pptx` requires visual QA and fix-verify loops; `xlsx` requires recalculation and formula error checks; `docx` requires validation after generation.

For skill authoring, copy the `skill-creator` pattern: capture intent, write focused eval prompts, compare against baseline behavior, grade with evidence, aggregate benchmark results, and improve descriptions using failure data.

## Do Not Copy

Do not copy proprietary document-skill code or large bundled assets without checking license terms. The README says the document creation and editing skills are source-available, not open source (source: `/tmp/myagents-research/anthropics-skills/README.md`).

Do not rely on trigger descriptions alone as a security boundary. This repo does not implement permission enforcement, sandboxing, credential isolation, or policy checks.

Do not vendor large Office schemas, fonts, tarballs, or binary assets into Agentic Coding Lab unless a concrete workflow needs them.

Do not copy overly domain-specific presentation, design, or brand opinions without adapting them to the local product and user base.

## Fit For Agentic Coding Lab

Fit is in-scope. `anthropics/skills` is not an agent application or model client, but it is exactly the kind of reusable instruction/support-system repository this category is meant to study.

The best reusable lessons are structural: skill directory conventions, progressive disclosure, skill marketplace metadata, helper-script boundaries, and embedded verification loops. The most relevant source examples for our lab are `skill-creator`, `mcp-builder`, `webapp-testing`, `frontend-design`, and the document skills' validation patterns.

For a coding-agent lab, the repository suggests a roadmap: make coding workflows installable as skills, give each skill a tight trigger contract, move heavyweight references out of active context, add deterministic validators, and evaluate skills against baseline agent behavior.

## Reviewed Paths

- `/tmp/myagents-research/anthropics-skills/README.md`
- `/tmp/myagents-research/anthropics-skills/.claude-plugin/marketplace.json`
- `/tmp/myagents-research/anthropics-skills/spec/agent-skills-spec.md`
- `https://agentskills.io/specification`
- `/tmp/myagents-research/anthropics-skills/template/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/brand-guidelines/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/canvas-design/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/doc-coauthoring/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/internal-comms/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/internal-comms/examples/`
- `/tmp/myagents-research/anthropics-skills/skills/frontend-design/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/algorithmic-art/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/algorithmic-art/templates/`
- `/tmp/myagents-research/anthropics-skills/skills/web-artifacts-builder/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/web-artifacts-builder/scripts/`
- `/tmp/myagents-research/anthropics-skills/skills/webapp-testing/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/webapp-testing/examples/`
- `/tmp/myagents-research/anthropics-skills/skills/webapp-testing/scripts/with_server.py`
- `/tmp/myagents-research/anthropics-skills/skills/mcp-builder/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/mcp-builder/reference/`
- `/tmp/myagents-research/anthropics-skills/skills/mcp-builder/scripts/`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/agents/`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/references/schemas.md`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/scripts/quick_validate.py`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/scripts/run_eval.py`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/scripts/run_loop.py`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/scripts/improve_description.py`
- `/tmp/myagents-research/anthropics-skills/skills/skill-creator/scripts/package_skill.py`
- `/tmp/myagents-research/anthropics-skills/skills/slack-gif-creator/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/theme-factory/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/pdf/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/pdf/forms.md`
- `/tmp/myagents-research/anthropics-skills/skills/pdf/reference.md`
- `/tmp/myagents-research/anthropics-skills/skills/pdf/scripts/check_fillable_fields.py`
- `/tmp/myagents-research/anthropics-skills/skills/docx/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/docx/scripts/accept_changes.py`
- `/tmp/myagents-research/anthropics-skills/skills/docx/scripts/office/`
- `/tmp/myagents-research/anthropics-skills/skills/pptx/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/pptx/editing.md`
- `/tmp/myagents-research/anthropics-skills/skills/pptx/pptxgenjs.md`
- `/tmp/myagents-research/anthropics-skills/skills/pptx/scripts/office/validate.py`
- `/tmp/myagents-research/anthropics-skills/skills/xlsx/SKILL.md`
- `/tmp/myagents-research/anthropics-skills/skills/xlsx/scripts/recalc.py`
- `/tmp/myagents-research/anthropics-skills/THIRD_PARTY_NOTICES.md`

## Excluded Paths

- `/tmp/myagents-research/anthropics-skills/.git/`: VCS internals, not relevant to skill behavior beyond commit capture.
- `/tmp/myagents-research/anthropics-skills/skills/canvas-design/canvas-fonts/*.ttf`: binary font payloads; noted as bundled assets but not reviewed byte-by-byte.
- `/tmp/myagents-research/anthropics-skills/skills/theme-factory/theme-showcase.pdf`: binary showcase output, useful as an example asset but not an instruction or execution path.
- `/tmp/myagents-research/anthropics-skills/skills/web-artifacts-builder/scripts/shadcn-components.tar.gz`: vendored/generated component archive; reviewed at bundle-script level, not unpacked.
- `/tmp/myagents-research/anthropics-skills/skills/docx/scripts/office/schemas/`, `/tmp/myagents-research/anthropics-skills/skills/pptx/scripts/office/schemas/`, `/tmp/myagents-research/anthropics-skills/skills/xlsx/scripts/office/schemas/`: large OOXML XSD schema payloads; reviewed as validation dependencies but not line-by-line.
- Most `LICENSE.txt` files: license presence and proprietary/open-source distinction were checked via README and notices, but repeated license text was not deeply reviewed.
- Language-specific Claude API docs under `/tmp/myagents-research/anthropics-skills/skills/claude-api/`: recognized as an API documentation skill, but excluded from deep review because this task focuses on the repository as a skill reference/support system rather than current Anthropic API behavior.
- Remaining helper scripts not named above: skimmed by directory listing and representative script review; excluded where they were duplicative Office pack/unpack/helpers or implementation details below the research granularity needed for this note.
