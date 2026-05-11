# github/spec-kit

- URL: https://github.com/github/spec-kit
- Category: agent-support-systems
- Stars snapshot: 95,562 (GitHub REST API, captured 2026-05-11); duplicate skills-instructions row captured 95,502
- Reviewed commit: 28145b9a3aa9b326f78d8a31c56a9565fabf9ab0
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong workflow reference for spec-driven AI coding with CLI setup, agent integrations, command templates, governance files, and quality gates. Conditional fit because it is a full development methodology/toolkit rather than a narrow skill pack.

## Why It Matters

`github/spec-kit` operationalizes spec-driven development for AI coding agents. It gives agents a structured path from product intent to spec, technical plan, task breakdown, and implementation. This matters because one major failure mode in AI coding is unstructured generation: the agent writes code before requirements, acceptance criteria, architecture, or task dependencies are clear.

For Agentic Coding Lab, the repo is a reference for turning natural-language workflow into durable repo artifacts: `spec.md`, `plan.md`, `tasks.md`, contracts, data models, quickstarts, checklists, and project constitution.

## What It Is

Spec Kit is a Python CLI and template pack. The `specify` CLI initializes projects for supported coding agents, installs command/skill files, writes shared `.specify` infrastructure, and can integrate with many assistants. The workflow commands are stored as markdown templates under `templates/commands/`.

The core user-facing sequence is:

1. `/speckit.constitution`
2. `/speckit.specify`
3. `/speckit.plan`
4. `/speckit.tasks`
5. `/speckit.implement`

Codex and Claude integrations use skills-style layouts, while other agents use markdown, TOML, YAML, or tool-specific command formats.

## Research Themes

- Token efficiency: Moderate. Spec Kit creates durable files so agents can reload concise artifacts, but command templates are long and procedural.
- Context control: Strong. It forces decomposition into spec, plan, research, data model, contracts, quickstart, tasks, and constitution.
- Sub-agent / multi-agent: Conditional. The core repo supports handoffs and extensions, but it is not primarily a multi-agent runtime.
- Domain-specific workflow: Strong. It encodes a domain-independent software workflow with explicit phase boundaries and artifact schemas.
- Error prevention: Strong. It uses checklists, constitution gates, branch/feature directory checks, task formatting rules, and prerequisite scripts.
- Self-learning / memory: Moderate. `.specify/memory/constitution.md` is a project memory/governance artifact, not adaptive memory.
- Popular skills: Relevant command templates are `specify`, `plan`, `tasks`, `implement`, `analyze`, `clarify`, `checklist`, and `constitution`.

## Core Execution Path

The local execution path starts with `specify init`. The Python CLI (`src/specify_cli/__init__.py`) resolves the requested integration, installs shared infrastructure, writes templates, and registers commands or skills for the chosen agent.

When a user invokes `/speckit.specify`, the agent follows `templates/commands/specify.md`: derive a short feature name, create a feature directory, copy `spec-template.md`, write `spec.md`, create a requirements checklist, validate the specification, and ask clarification questions only when required.

`/speckit.plan` runs `scripts/bash/setup-plan.sh --json` or the PowerShell equivalent, resolves feature paths, copies `plan-template.md`, loads `spec.md` and `constitution.md`, fills technical context, generates `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, and updates the agent context file.

`/speckit.tasks` runs `setup-tasks.sh`, validates that `spec.md` and `plan.md` exist, resolves the task template, reads optional design documents, and generates a strict checkbox task list organized by user story.

`/speckit.implement` checks prerequisite files and checklist status, reads the task and design artifacts, verifies ignore files, executes tasks phase by phase, marks completed tasks, and validates completion.

## Architecture

The architecture has three layers:

- CLI layer: `src/specify_cli/` provides Typer-based init/check/version behavior, integration registry, command registrar, authentication helpers, presets, extensions, workflow primitives, and shared infrastructure installers.
- Template layer: `templates/` contains spec, plan, tasks, constitution, checklist, VS Code settings, and command prompts.
- Script layer: `scripts/bash/` and `scripts/powershell/` provide deterministic file/path setup for feature creation, planning, task setup, and prerequisite checks.

Integrations subclass `IntegrationBase` or `SkillsIntegration`. Codex writes `.agents/skills/speckit-<name>/SKILL.md` and uses `AGENTS.md`; Claude writes `.claude/skills/.../SKILL.md` and uses `CLAUDE.md`. The registrar rewrites template references into generated project paths and adapts frontmatter/output format by client.

Tests cover agent config consistency, auth, branch numbering, CLI version, extensions, merge behavior, path traversal in the registrar, plan/task setup, timestamp branches, upgrades, workflows, and many integrations.

## Design Choices

The key design choice is artifact-first agent workflow. Rather than making the agent keep the plan in chat, Spec Kit writes each phase into a predictable file structure.

The second choice is command templates as procedural prompts. The templates give the agent exact steps and validation rules, while shell scripts handle path discovery and precondition checks.

The third choice is integration abstraction. Agent differences are captured in integration classes and registrar configs, including command directory, format, invocation separator, context file, and non-interactive dispatch args.

The fourth choice is explicit quality gates. Specs must avoid implementation details, plans must pass constitution checks, tasks must be dependency ordered and independently testable, and implementation must stop for incomplete checklists unless the user approves proceeding.

## Strengths

Spec Kit gives AI coding a durable paper trail. Requirements, decisions, contracts, tasks, and validation scenarios become repo artifacts, which improves reviewability and continuity across sessions.

The command templates are operationally specific. They say what files to read, what files to create, how to format tasks, and when to stop.

The integration architecture is useful for multi-client support. Codex, Claude, Gemini, Copilot, Cursor, OpenCode, Goose, and many others can receive equivalent command behavior in their native format.

The tests show real concern for installer correctness and path safety, including registrar path traversal tests.

The extension and preset catalogs make the system extensible without forcing all workflow variations into core.

## Weaknesses

The method is heavy for small changes. Creating a constitution/spec/plan/tasks chain can be overkill for a narrow bug fix.

The templates are long and may consume significant context when invoked. Artifact decomposition helps later phases, but command execution itself is verbose.

Spec-driven development can create false confidence if the generated specs are not reviewed by humans or tested against running software.

The repo is a workflow toolkit, not a validator that proves code satisfies the spec. It relies on the agent to follow templates and on tests/checklists to catch drift.

## Ideas To Steal

Use durable feature folders for agent work: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `contracts/`, and `quickstart.md`.

Separate product "what/why" from technical "how" using different commands.

Add strict task formatting rules so tasks can be parsed and executed by agents.

Use small deterministic setup scripts to handle paths and prerequisites instead of letting the model invent them.

Represent agent integrations through a registry with per-client output format and context file settings.

Make project constitution a first-class memory artifact.

## Do Not Copy

Do not force the full workflow onto every coding request. Add a lightweight path for bug fixes and small refactors.

Do not treat generated specs as truth without review. Specs can encode bad assumptions.

Do not copy the extension ecosystem wholesale; extensions should be reviewed like third-party code.

Do not rely on branch naming as the only feature identity. Spec Kit already decouples feature directory from branch name, and that is the safer pattern.

## Fit For Agentic Coding Lab

Fit is conditional but strong. It belongs under agent-support-systems more than pure skills-instructions because its core contribution is workflow infrastructure.

Agentic Coding Lab should adapt the artifact model and prerequisite scripts. A smaller local variant could support research notes, implementation plans, and verification tasks without requiring the full Spec Kit lifecycle.

## Reviewed Paths

- `/tmp/myagents-research/github-spec-kit/README.md`
- `/tmp/myagents-research/github-spec-kit/spec-driven.md`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/__init__.py`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/agents.py`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/integrations/base.py`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/integrations/codex/__init__.py`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/integrations/claude/__init__.py`
- `/tmp/myagents-research/github-spec-kit/src/specify_cli/workflows/base.py`
- `/tmp/myagents-research/github-spec-kit/templates/commands/specify.md`
- `/tmp/myagents-research/github-spec-kit/templates/commands/plan.md`
- `/tmp/myagents-research/github-spec-kit/templates/commands/tasks.md`
- `/tmp/myagents-research/github-spec-kit/templates/commands/implement.md`
- `/tmp/myagents-research/github-spec-kit/templates/plan-template.md`
- `/tmp/myagents-research/github-spec-kit/scripts/bash/setup-plan.sh`
- `/tmp/myagents-research/github-spec-kit/scripts/bash/setup-tasks.sh`
- `/tmp/myagents-research/github-spec-kit/tests/`
- `/tmp/myagents-research/github-spec-kit/extensions/`

## Excluded Paths

- `/tmp/myagents-research/github-spec-kit/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/github-spec-kit/media/`: visual assets and logos, not core behavior.
- `/tmp/myagents-research/github-spec-kit/docs/community/`: community lists reviewed from README only.
- Most integration subclasses not named above: registry shape reviewed through base, Codex, and Claude examples.
- PowerShell scripts: bash equivalents reviewed as representative implementation.
- Extension implementation details under `extensions/*`: noted as ecosystem surface, not deeply reviewed in this batch.
