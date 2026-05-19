# mgechev/skills-best-practices

- URL: https://github.com/mgechev/skills-best-practices
- Category: context-control
- Stars snapshot: 1,900 (GitHub REST API `stargazers_count`, captured 2026-05-19)
- Reviewed commit: 979bd0360c82064ee8cf1ca9a0a0ff5335bae2ee
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Small but useful skill-authoring reference for context control. Its strongest value is the disciplined separation of discovery metadata, lean `SKILL.md`, just-in-time references/assets, tiny deterministic scripts, and LLM-based validation prompts. Treat it as a rubric and pattern source, not a complete validation system, because the included validator script is currently broken and no automated test or CI harness is present.

## Why It Matters

This repository is a concise guide for writing agent skills that do not bloat the context window. It frames a skill as a routed, progressively disclosed package: frontmatter for discovery, `SKILL.md` for high-level procedure, `references/` for dense knowledge, `assets/` for templates, and `scripts/` for deterministic operations.

For Agentic Coding Lab, the useful part is not volume. The repo is only 296 tracked source lines across six files. The useful part is the sharp set of constraints: route by metadata, avoid human-centric docs inside skills, keep the main instruction file below 500 lines, load deep resources only when needed, and test skill behavior by asking LLMs to simulate routing, execution, edge cases, and architecture refinement.

The caution is maturity. The repo explains good skill hygiene and includes one meta skill for creating skills, but the bundled validator script cannot execute at the reviewed commit, the skill references a missing template path, and there is no automated regression harness.

## What It Is

`skills-best-practices` is a best-practices guide plus an example/installable meta skill named `skill-creator`.

The root `README.md` is the human-facing guide. It covers skill directory structure, frontmatter discoverability, progressive disclosure, procedural instruction style, deterministic scripts, and a validation guide based on LLM critique.

The `skill/` directory is the agent-facing artifact. It contains:

- `skill/SKILL.md`: an agent procedure for authoring skills.
- `skill/references/checklist.md`: final audit checklist.
- `skill/assets/SKILL.template.md`: starting template.
- `skill/scripts/validate-metadata.py`: intended metadata validator.

There is no application runtime, package manifest, CI configuration, published schema, or test suite in the reviewed checkout.

## Research Themes

- Token efficiency: Strong at the instruction-pattern level. The repo explicitly tells authors to keep `SKILL.md` lean, move bulky content to one-level-deep supporting folders, use templates instead of prose, delete redundant logic, and load resources just in time.
- Context control: Strong and central. The design turns context control into file structure rules and routing discipline: metadata first, high-level procedure second, detailed references only on demand.
- Sub-agent / multi-agent: Low. The repo does not define sub-agent workflows, agent isolation, handoffs, or parallel coordination.
- Domain-specific workflow: Medium. The guidance is generic, but it requires domain-native terminology and gives Angular/Vite examples that show how a skill should avoid vague cross-domain triggers.
- Error prevention: Medium. The checklist, edge-case testing prompts, negative triggers, deterministic scripts, and descriptive stderr guidance are practical. Enforcement is weak because the validator is broken and no automated skill tests run.
- Self-learning / memory: Low. The repository does not implement memory, feedback storage, telemetry, or self-improving skill updates.
- Popular skills: Only one actual skill is present, `skill-creator`. Its most useful subpatterns are metadata validation, directory scaffolding, progressive disclosure review, script identification, and final checklist audit.

## Core Execution Path

There are two practical execution paths.

The human path starts in `README.md`:

1. Define a skill with `SKILL.md`, `scripts/`, `references/`, and `assets/`.
2. Optimize the `name` and `description` frontmatter because those are the only fields available before activation.
3. Keep `SKILL.md` below 500 lines and use it as navigation plus primary procedure.
4. Move bulky schemas, API details, domain logic, and output templates into supporting folders.
5. Write numbered procedural instructions for agents, not explanatory prose for humans.
6. Bundle tiny deterministic scripts for fragile or repetitive tasks.
7. Validate discovery, logic, edge cases, and architecture by asking an LLM to simulate routing and execution.

The agent path starts when the host loads the `skill-creator` metadata from `skill/SKILL.md`:

1. The skill triggers for creating skill directories, drafting procedural instructions, or optimizing metadata.
2. Step 1 asks the agent to define `name` and `description`, then run `python3 scripts/validate-metadata.py --name "[name]" --description "[description]"`.
3. Step 2 creates the skill root plus `scripts/`, `references/`, and `assets/`, while avoiding human docs.
4. Step 3 drafts `SKILL.md` and enforces progressive disclosure.
5. Step 4 identifies fragile tasks that deserve single-purpose scripts.
6. Step 5 reviews hallucination gaps, path style, and the checklist.

At the reviewed commit, that path has two concrete breaks: `validate-metadata.py` has an empty `if __name__ == "__main__":` block that raises `IndentationError`, and `skill/SKILL.md` points to `assets/skill-template.md` while the tracked asset is `assets/SKILL.template.md`.

## Architecture

The repository has four small layers.

The guide layer is `README.md`. It is the canonical explanation of the intended skill architecture, validation process, and context-window discipline.

The skill layer is `skill/SKILL.md`. It packages the guide as an agent procedure with frontmatter, numbered steps, progressive-disclosure rules, and error handling notes.

The support layer is split into standard skill subdirectories. `references/checklist.md` holds the audit checklist, `assets/SKILL.template.md` holds a skeleton skill file, and `scripts/validate-metadata.py` is intended to mechanize metadata checks.

The metadata/provenance layer is GitHub and Git. The repo is tiny, with five commits on `main` at review time, no license file, no release artifacts, and no workflow files.

## Design Choices

The strongest design choice is treating frontmatter as a routing contract. The README stresses that `name` and `description` are the only fields available before the agent chooses a skill, so vague descriptions make a skill invisible or overbroad.

Progressive disclosure is enforced through both file layout and prose. The recommended structure keeps `SKILL.md` as a short "brain" and pushes bulky content into flat `references/`, `assets/`, and `scripts/` directories. The one-level-deep rule prevents hidden nested context that the agent will not know how to load.

The repo separates human docs from agent skills. It says not to create `README.md`, `CHANGELOG.md`, or installation guides inside skill directories because those files consume attention without helping the agent execute.

The procedural style is intentionally rigid. The guide prefers numbered chronological steps, clear decision trees, concrete templates, third-person imperative commands, consistent domain terminology, and direct relative paths using forward slashes.

The validation design uses LLMs as reviewers of routing and logic. The README includes concrete prompts for discovery validation, logic validation, edge-case testing, and architecture refinement. This is useful because it tests the actual consumer of the skill: an LLM agent operating from metadata and loaded files.

The deterministic-script guidance is right but lightly implemented. The repo says scripts should handle fragile parsing and return descriptive stdout/stderr. The included validator aims at that pattern but is incomplete.

## Strengths

The repo is concise enough to act as a skill-authoring checklist. It avoids large theory sections and gives rules that map directly to agent behavior.

The context-window discipline is practical. Keeping `SKILL.md` below 500 lines, loading references only when needed, and replacing prose with templates are directly reusable for Agentic Coding Lab context-control skills.

The frontmatter guidance is strong. Positive triggers, negative triggers, strict names, parent-directory matching, third-person descriptions, and isolated metadata review all reduce false activations.

The validation prompts are valuable. Asking an LLM to generate should-trigger and should-not-trigger prompts, simulate step-by-step execution, identify hallucination gaps, attack edge cases, and restructure for progressive disclosure is a practical review loop.

The checklist is compact and operational. It covers metadata, directory matching, flat hierarchy, no human docs, forward slashes, lean context, imperative instructions, deterministic steps, progressive disclosure, scripts, and error handling.

The meta skill encodes the README as agent procedure. That makes the repo more than a static essay: it provides a reusable `skill-creator` workflow that another agent can load.

## Weaknesses

`skill/scripts/validate-metadata.py` is not executable at the reviewed commit. Running it raises `IndentationError: expected an indented block after 'if' statement on line 45` because the `if __name__ == "__main__":` block is empty.

The skill references a missing template path. `skill/SKILL.md` says to use `assets/skill-template.md`, but the tracked file is `skill/assets/SKILL.template.md`.

The validator is also incomplete as a policy implementation. Even if the syntax issue were fixed, the visible function does not validate parent directory matching, does not enforce a non-empty description, and labels forbidden pronouns as a warning while exiting with failure.

There is no automated test suite, CI workflow, schema validation, broken-link check, or smoke test for the bundled skill. The README recommends evals and points to `skillgrade`, but this repo does not include a runnable eval harness.

The "no human docs" rule needs scope discipline. It is useful inside a skill directory, but Agentic Coding Lab should still allow repo-level docs, ADRs, and research notes where humans maintain the system.

Some rules are stated as universal thresholds. A 500-line `SKILL.md` cap and one-level-deep references are good defaults, but a lab system should validate token cost and retrieval behavior directly instead of hard-coding all guidance as universal law.

The project has no license metadata in the GitHub API response and no license file in the checkout. Reuse should be limited to ideas and independently written artifacts unless licensing is clarified.

## Ideas To Steal

Use a three-part skill contract: frontmatter for routing, `SKILL.md` for the minimal execution path, and just-in-time supporting files for dense details.

Require every skill description to include positive triggers and negative triggers. Test those descriptions in isolation before reviewing the full skill.

Make progressive disclosure auditable. Add checks for `SKILL.md` line count, flat supporting directories, direct relative paths, no nested reference trees, and no skill-local human docs.

Use LLM simulation as a required review step. Ask the model to execute the skill step by step, name exact files/scripts it would use, and flag the line where it would have to guess.

Use adversarial edge-case prompts before polishing. The README's "ruthless QA tester" pattern maps well to skill reviews for migrations, context compression, memory writes, and tool adapters.

Store output templates in `assets/` rather than describing formats in prose. This reduces instruction tokens and gives agents something concrete to copy.

Bundle tiny validators for fragile metadata and structure checks. For Agentic Coding Lab, make these real CLI tools with tests: frontmatter parser, directory-name matcher, link/path checker, line-count checker, and script smoke runner.

Make final checklists first-class references. A small `references/checklist.md` loaded only at the final audit stage is a clean context-control pattern.

## Do Not Copy

Do not copy the current validator script without fixing and testing it. It fails before argument parsing.

Do not rely on LLM-only validation as the whole quality gate. Pair discovery/logic critique prompts with deterministic checks and regression fixtures.

Do not copy path names blindly. The repo's own skill/template path mismatch shows why broken-reference checks matter.

Do not ban all documentation in all contexts. The rule should apply to installed skill directories, not to the surrounding research repo or maintainer documentation.

Do not make every supporting resource exactly one level deep if a runtime has a better indexed retrieval system. Keep the underlying goal: predictable just-in-time loading with low discovery overhead.

Do not treat "scripts are tiny CLIs" as permission to hide important business logic in untested scripts. Scripts should have argv contracts, descriptive errors, and smoke tests.

Do not import the guide wholesale into every skill. The point is to enforce the pattern through templates and validators so each skill stays narrow.

## Fit For Agentic Coding Lab

Fit is high for skill and context-control authoring, but narrow. This repo should inform Agentic Coding Lab's skill template, validator, and review checklist rather than become a runtime dependency.

Best adaptation:

- A lab skill template with strict frontmatter, positive and negative triggers, short procedural steps, and an error-handling section.
- A `skill lint` command that checks frontmatter, parent directory naming, line count, supporting folder depth, broken relative links, forbidden skill-local docs, and executable script smoke tests.
- A discovery eval fixture that feeds only metadata to an LLM and checks should-trigger and should-not-trigger examples.
- A logic eval fixture that feeds `SKILL.md` plus tree listing to an LLM and asks for step-by-step execution plus hallucination gaps.
- A final audit checklist loaded just in time, not always included in the main skill context.

The central lesson for Agentic Coding Lab: context control starts before a skill is loaded. Discovery metadata, file layout, and just-in-time resource rules decide how much context the agent spends and whether it loads the right instructions at all.

## Reviewed Paths

- `README.md`: reviewed for repository purpose, skill structure, frontmatter discoverability, progressive disclosure rules, procedural style, deterministic-script guidance, and LLM-based validation prompts.
- `skill/SKILL.md`: reviewed for actual meta-skill frontmatter, trigger contract, skill-authoring procedure, progressive disclosure steps, script usage, and error handling guidance.
- `skill/references/checklist.md`: reviewed for final audit criteria covering metadata, directory structure, context size, deterministic logic, scripts, and error handling.
- `skill/assets/SKILL.template.md`: reviewed for template frontmatter, procedure skeleton, just-in-time file references, and error-handling skeleton.
- `skill/scripts/validate-metadata.py`: reviewed for implemented metadata checks and smoke-tested with `python3`; found syntax failure at the reviewed commit.
- `.gitignore`: reviewed for generated, vendor, environment, build, and editor paths that should be excluded from source review.
- Git metadata: reviewed commit, branch history, tracked file list, and exact checkout state.
- GitHub REST repository metadata: reviewed star, fork, issue, language, default branch, pushed date, and license snapshot.

## Excluded Paths

- `.git/`: excluded as version-control internals. Git commands were used instead to capture commit and history metadata.
- `node_modules/`, `dist/`, `build/`, `.venv/`, `venv/`, `env/`, `__pycache__/`, editor folders, logs, and `.env*` files: excluded by `.gitignore`; none were relevant maintained source in the reviewed checkout.
- External links to Claude docs, `skillgrade`, and SkillsBench: noted as provenance and related validation direction, but not deep-reviewed because this note is scoped to `mgechev/skills-best-practices`.
- No generated source directories, vendored dependencies, binary assets, or UI-only application paths were present in the tracked checkout.
