# K-Dense-AI/scientific-agent-skills

- URL: https://github.com/K-Dense-AI/scientific-agent-skills
- Category: domain-specific-coding
- Stars snapshot: 24,888 stars from GitHub REST API, captured 2026-05-20
- Reviewed commit: 044285c33a78afda10468012105b86a225f66267
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value pattern mine for scientific-domain skills, especially progressive reference loading, explicit scientific failure modes, and evidence artifacts; do not adopt wholesale because tool boundaries, reproducibility, and scientific eval coverage are uneven.

## Why It Matters

This repo is one of the largest public examples of domain-specific agent skills aimed at scientific coding. It shows how a coding agent can be steered beyond generic Python help into research workflows that need specialist APIs, file formats, statistical assumptions, lab hardware abstractions, model-resource checks, and publication artifacts.

The useful lesson is not the catalog size by itself. The repo demonstrates a repeatable skill shape: concise trigger metadata, domain decision trees, references loaded only when needed, helper scripts, output contracts, and "do not misuse this tool" warnings. For Agentic Coding Lab, that is directly relevant to building skills that preserve context budget while still carrying domain expertise.

## What It Is

`scientific-agent-skills` is an Agent Skills standard repository with 138 skill directories under `scientific-skills/`. The collection covers scientific databases, paper search, bioinformatics, drug discovery, clinical ML, molecular docking, time-series forecasting, lab automation, statistics, EDA, scientific writing, schematics, slides, posters, and other research support workflows.

The repo is mostly Markdown instructions plus optional `references/`, `scripts/`, `assets/`, `examples/`, and `tests/` folders. My local scan found 671 reference files, 197 script files, 75 asset files, 27 example files, and 14 test files. It is not a centralized runtime framework: execution is delegated to the host agent, shell/Python scripts, external APIs, MCP servers, or third-party libraries.

## Research Themes

- Token efficiency: Best pattern is progressive disclosure. Skills such as `database-lookup`, `paper-lookup`, `exploratory-data-analysis`, and `pyhealth` tell the agent to read only the relevant reference file or task-specific guide. Weakness: many `SKILL.md` files are long and repeat large examples, so the corpus is not uniformly token efficient.
- Context control: Strongest examples include extension-specific EDA reference lookup, per-database API references, PyHealth's "read this file for this task" table, and DiffDock's split between quick workflow, parameter reference, and confidence/limitations. Control is advisory, not enforced by a loader or manifest.
- Sub-agent / multi-agent: No real sub-agent architecture. The repo composes skills by naming related skills in docs and examples, and the `autoskill` skill proposes skill combinations, but there is no planner-worker handoff or parallel agent protocol to reuse.
- Domain-specific workflow: Very strong. Skills encode scientific work patterns such as scaffold splitting for molecules, patient-level splits for EHR models, assumption checks before statistics, molecular docking confidence interpretation, resource preflight before model loading, and raw JSON evidence from database queries.
- Error prevention: Good local guardrails exist in individual skills: identifier-format tables, API rate-limit guidance, free alternatives for restricted databases, setup checkers, confidence warnings, data leakage warnings, and "when not to use" sections. System-level prevention is weaker because many skills lack explicit tool manifests and exact dependency pins.
- Self-learning / memory: Minimal. Most persistent state is task-local artifacts such as `.claude_resources.json`, EDA reports, forecast JSON, confidence score files, schematic review logs, and generated reports. There is no broad memory design for carrying lessons between runs.
- Popular skills: Most reusable design patterns came from `database-lookup`, `paper-lookup`, `exploratory-data-analysis`, `statistical-analysis`, `deepchem`, `diffdock`, `timesfm-forecasting`, `pyhealth`, `pylabrobot`, `scientific-schematics`, and `get-available-resources`.

## Core Execution Path

1. Install or copy the skill pack using the Agent Skills workflow described in the README.
2. Host agent discovers a skill through frontmatter `name` and `description`.
3. The active skill provides a domain workflow, usually starting with task classification: choose a database, file format, statistical test, model type, hardware backend, or output artifact.
4. The skill tells the agent which reference file to read next, which scripts to run, which APIs or packages to use, and what evidence to return.
5. Helper scripts produce artifacts when the task needs repeatability: EDA markdown reports, batch CSV validation, docking result summaries, system resource JSON, forecast outputs, diagnostic plots, schematic review logs, or security scan reports.
6. The repo-level safety path runs `scan_pr_skills.py` on changed skills in PRs and `scan_skills.py` weekly to regenerate `SECURITY.md`.

Representative execution paths:

- `database-lookup`: classify query, select one or more of 78 database APIs, read matching reference files, call REST or POST endpoints, and return raw JSON plus endpoint provenance.
- `exploratory-data-analysis`: detect extension, load a format reference, run `scripts/eda_analyzer.py` or custom analysis, and write a markdown report with file metadata, quality metrics, and downstream recommendations.
- `statistical-analysis`: select tests, check assumptions first, calculate effect sizes/power, and report results with assumptions and confidence intervals.
- `diffdock`: run environment setup check, validate batch CSV, run docking, parse confidence scores, export summaries, and warn that confidence is not binding affinity.
- `timesfm-forecasting`: run mandatory system preflight, load model only after RAM/GPU/disk checks pass, forecast with prediction intervals, and evaluate holdout metrics/coverage.
- `scientific-schematics`: generate a scientific diagram, review it with an LLM against document-type thresholds, and write versioned images plus JSON review logs.

## Architecture

The architecture is a broad skill corpus, not an application:

- Top-level docs: `README.md`, `docs/scientific-skills.md`, `docs/examples.md`, `docs/open-source-sponsors.md`.
- Skill root: `scientific-skills/<skill>/SKILL.md`.
- Optional skill payloads: `references/` for detailed context, `scripts/` for repeatable execution, `assets/` for templates/configs, `examples/` for demos, `tests/` for a small subset of skills.
- Scanner tooling: `scan_skills.py` for full security scan, `scan_pr_skills.py` for changed-skill PR comments.
- CI: `.github/workflows/pr-skill-scan.yml` scans changed skills and blocks on high severity; `.github/workflows/security-scan.yml` runs weekly and commits an updated `SECURITY.md`.
- Dependency model: root `pyproject.toml` only installs scanner/runtime support; each skill usually gives its own package installation instructions.

There is no central registry schema beyond file layout and Agent Skills frontmatter. Only 27 of 138 skill manifests declare `allowed-tools` in the cloned snapshot: 23 use `Read Write Edit Bash`, 3 use `Read Write`, and 1 uses `Bash`. Most tool boundaries are implicit in prose.

## Design Choices

The repo favors practical scientific runbooks over abstract agent framework code. Most skills are written as "when to use, how to choose, how to run, what can go wrong, what to return." That makes them easy to transplant into any compatible agent host.

The best context-control design is reference sharding. Large domain details are moved to files such as database endpoint references, format references, model guides, and workflow examples. Good skills include a small routing table that tells the agent which reference to load for each task.

The strongest scientific design choice is explicit epistemic boundary setting. DiffDock says pose confidence is not affinity. DeepChem warns against random molecular splits. PyHealth warns against sample-level patient leakage. Statistical Analysis requires assumption checks before interpretation. TimesFM blocks or warns on resource limits before model load.

Verification is mostly artifact-oriented rather than benchmark-oriented. Skills generate outputs that can be inspected: raw JSON with endpoints, markdown EDA reports, diagnostics, result CSVs, plots, review logs, and setup reports. Repo-level automated verification is focused on security scanning, not scientific correctness.

## Strengths

- Excellent domain workflow coverage across science, medicine, bioinformatics, chemistry, statistics, lab automation, and publishing.
- Reusable progressive-disclosure pattern: `SKILL.md` for routing, `references/` for depth, scripts/assets for execution.
- Good evidence contracts in several skills: return raw JSON and endpoint provenance, save reports, export CSV/JSON summaries, store review logs, and document parameters.
- Strong local error-prevention examples: leakage prevention, assumption checks, rate-limit guidance, identifier conversion, confidence-score caveats, setup checkers, and resource preflights.
- Security scanning is treated as a first-class repo artifact with PR scans and weekly full scans.
- Skills compose through ordinary scientific workflows without requiring a specific agent framework or model client.

## Weaknesses

- Security posture is visibly unresolved. The generated `SECURITY.md` for 2026-05-18 reports 856 findings, including 68 critical and 18 high findings, with only 107 of 138 skills marked safe. Some are likely conservative scanner findings, but the artifact still signals high review burden.
- Tool boundaries are inconsistent. Most skills omit `allowed-tools`, while many instructions ask agents to read files, write outputs, run shell commands, install packages, call APIs, or handle credentials.
- Scientific correctness evals are thin. There is no central benchmark harness that runs representative workflows against fixtures and checks domain outcomes. Tests exist only for a small subset, while many skills rely on examples and prose.
- Reproducibility is weak in many installation instructions because package versions are unpinned or loosely constrained, and external scientific APIs/databases change over time.
- Context budget can still explode. Some skills contain long examples, repeated prompt patterns, broad activation descriptions, and cross-skill promotion language.
- Documentation and executable surface drift in places. For example, `scientific-schematics` requires quality-check functions such as `run_quality_checks()`, `verify_accessibility()`, and `validate_resolution()`, but those function definitions are not present in that skill directory in the reviewed commit.

## Ideas To Steal

- Use a strict skill shape: trigger, "when not to use", core workflow, evidence outputs, verification steps, reference routing table, scripts/assets, and failure modes.
- Put large domain docs behind explicit reference routers. For each task type, tell the agent exactly which file to open and which section to search.
- Define evidence contracts inside skills. Examples: "return raw JSON and endpoints", "write report with metadata and quality metrics", "export confidence summary CSV", "save review log with scores and critiques."
- Add preflight scripts for expensive or risky scientific workloads before model download, GPU use, batch processing, or hardware control.
- Encode domain-specific anti-footgun rules directly in skills: no random molecule split for drug discovery, no patient leakage for clinical prediction, no interpreting docking confidence as affinity, no statistical result without assumptions/effect sizes.
- Pair every externally connected skill with a credential/network section: required env vars, destinations, rate limits, fallback options, and what data leaves the machine.
- Use repo-level scanner CI, but make it only one layer below domain fixtures and deterministic smoke tests.

## Do Not Copy

- Do not copy the giant all-in-one catalog strategy unless discovery and context loading are machine-controlled. Breadth without precise activation creates overlap and token cost.
- Do not rely on prose-only tool boundaries. Add machine-readable allowed tools, network destinations, write paths, and credential names.
- Do not claim examples are tested unless there is a runnable fixture or CI job proving it.
- Do not use unpinned install commands as the default for reproducible scientific skills.
- Do not make security scanning the only eval story. It finds malicious or risky behavior, not whether a workflow produces scientifically valid outputs.
- Do not require checklist functions or quality gates unless the scripts actually provide them.

## Fit For Agentic Coding Lab

Fit is strong as a pattern source for domain-specific coding skills. The most useful reusable pattern is "small router plus deep references plus repeatable scripts plus explicit evidence artifact." That pattern maps well to Agentic Coding Lab skills for specialized coding domains where the agent needs just-in-time context, not a full textbook in the prompt.

Adoption should be selective. Agentic Coding Lab should borrow the structure and scientific guardrails, then add stricter manifests, smaller trigger descriptions, pinned dependency profiles, fixture-based evals, and enforcement around tool/network/write boundaries.

Best candidate artifacts to build from this review:

- A repo-local skill template with required sections for evidence outputs, verification commands, resource checks, and "do not use when".
- A machine-readable skill manifest extension for tools, env vars, network endpoints, write paths, and generated artifacts.
- A domain-skill eval harness that runs small fixtures and checks output files, not only scanner reports.
- A context-router convention: each skill gets a compact routing table mapping user intent to exact reference files and sections.

## Reviewed Paths

- `README.md`: scope, install flow, security disclaimer, contribution guidance, and positioning.
- `docs/scientific-skills.md`: full catalog and category organization.
- `docs/examples.md`: cross-skill scientific workflow examples.
- `scientific-skills/database-lookup/SKILL.md`: database selection, API keys, rate limits, raw JSON evidence contract.
- `scientific-skills/paper-lookup/SKILL.md`: paper database routing, raw response contract, rate limits, fallback behavior.
- `scientific-skills/bgpt-paper-search/SKILL.md`: remote MCP boundary and structured evidence search.
- `scientific-skills/exploratory-data-analysis/SKILL.md` and `scripts/eda_analyzer.py`: format detection, reference lookup, report generation.
- `scientific-skills/statistical-analysis/SKILL.md` and `scripts/assumption_checks.py`: test selection, assumption checks, effect sizes, reporting.
- `scientific-skills/deepchem/SKILL.md`: molecular ML workflow, leakage prevention, benchmarks, model evaluation.
- `scientific-skills/diffdock/SKILL.md` and `scripts/setup_check.py`: setup validation, docking workflow, confidence limitations, output summaries.
- `scientific-skills/timesfm-forecasting/SKILL.md` and `scripts/check_system.py`: mandatory preflight, model-resource constraints, forecast evidence.
- `scientific-skills/pyhealth/SKILL.md`: clinical ML pipeline shape and patient-level split guardrail.
- `scientific-skills/pylabrobot/SKILL.md`: lab automation boundaries, simulation-first guidance, hardware backend abstraction.
- `scientific-skills/scientific-schematics/SKILL.md` and scripts/references: iterative visual generation, review logs, quality checklist drift.
- `scan_skills.py`, `scan_pr_skills.py`, `SECURITY.md`, `.github/workflows/pr-skill-scan.yml`, `.github/workflows/security-scan.yml`: scanner architecture and security evidence.
- `pyproject.toml`: repo-level dependency model for scanner tooling.

## Excluded Paths

- Binary/image/media assets such as GIFs, generated PNGs, and example output images were excluded because the review focused on skill design and execution boundaries, not visual content fidelity.
- Most large per-package reference files were sampled through representative skills rather than read exhaustively; they are repetitive API documentation and not all needed to assess the architecture.
- `uv.lock` was not reviewed in detail because dependency resolution for the scanner is less relevant than the per-skill unpinned install guidance.
- Release automation was only lightly inspected because publishing mechanics do not materially affect scientific workflow design.
- Full generated prompt bodies and long examples were not reproduced to avoid prompt-body copying and because the reusable pattern is structural, not verbatim text.
