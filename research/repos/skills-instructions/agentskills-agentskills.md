# agentskills/agentskills

- URL: https://github.com/agentskills/agentskills
- Category: skills-instructions
- Stars snapshot: 19,601 (GitHub REST API repository search, captured 2026-05-29; GitHub page reviewed 2026-05-29 showed 19.6k)
- Reviewed commit: 5d4c1fda3f786fff826c7f56b6cb3341e7f3a911
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-signal specification and implementor guide for portable agent skills. It is valuable as a contract and design reference for Agentic Coding Lab, but the reference library is explicitly demonstration-grade and does not provide a production loader, registry, package manager, permission model, or sandbox.

## Why It Matters

`agentskills/agentskills` is the public specification and documentation source for the Agent Skills format. It matters because it defines a small, portable unit of agent behavior: a directory containing `SKILL.md` frontmatter and Markdown instructions, with optional scripts, references, assets, and metadata.

For Agentic Coding Lab, the main value is the contract between a host agent and externalized capability packs. The repo names the minimal skill shape, the activation metadata, the progressive-disclosure model, client scanning expectations, and a reference parser/validator. It gives us vocabulary for separating trigger metadata from full instructions and from heavy resources.

This is not a skill catalog like `anthropics/skills` and not an agent runtime. It is closer to a standards repo plus docs site plus small reference library.

## What It Is

The repository contains:

- `README.md` and `docs/home.mdx`: overview of Agent Skills as lightweight folders of instructions and resources.
- `docs/specification.mdx`: normative-ish format documentation for `SKILL.md`, required and optional frontmatter, optional directories, file references, progressive disclosure, and validation.
- `docs/client-implementation/adding-skills-support.mdx`: implementor guidance for discovery, parsing, disclosure, activation, permissions, context retention, and subagent delegation.
- `docs/skill-creation/*.mdx`: creator guidance for quickstart, best practices, description optimization, skill evals, and scripts.
- `docs/snippets/clients.jsx`: client showcase data listing many tools with claimed Agent Skills support, including VS Code, GitHub Copilot, Claude Code, Claude, OpenAI Codex, Gemini CLI, OpenCode, OpenHands, Goose, Cursor, and others.
- `skills-ref/`: Python reference parser, validator, prompt XML generator, CLI, and tests.

The repository has a minimal top-level `package.json` only for running the Mintlify documentation site. The reusable code surface is the Python `skills-ref` package under `skills-ref/`, not the top-level npm package.

## Research Themes

- Token efficiency: Strong. The core model is progressive disclosure: load only `name` and `description` at startup, load full `SKILL.md` only after activation, and load scripts/references/assets on demand.
- Context control: Strong. The docs recommend keeping `SKILL.md` under 500 lines and about 5,000 tokens, moving detailed content into focused support files, preserving activated skill content through context compaction, and deduplicating activations.
- Sub-agent / multi-agent: Moderate. The client guide treats subagent delegation as optional, where a skill can run in a separate focused session and return a summary. The repo does not implement a subagent runtime.
- Domain-specific workflow: Strong. The format is explicitly meant to encode specialized procedures, project conventions, scripts, templates, gotchas, and validation loops.
- Error prevention: Strong at the guidance level. Creator docs emphasize gotchas, checklists, validation loops, plan-validate-execute flows, script `--help`, structured output, dry-run support, idempotency, clear errors, and safe defaults.
- Self-learning / memory: Conditional. The format does not define memory, but the eval docs describe iterative skill improvement using transcripts, assertions, grading, benchmarks, and human feedback.
- Popular skills: Not applicable as a catalog. Popularity signal here is ecosystem adoption and stars, not skill-level usage. The client showcase is useful for portability research but is not proof of uniform behavior across clients.

## Core Execution Path

The intended execution path starts in a host agent, not in this repo.

1. At session startup, the host discovers skills from project, user, organization, built-in, or configured locations.
2. The host scans for skill directories containing `SKILL.md`, parses YAML frontmatter, and stores at least `name`, `description`, and `location`.
3. The host discloses a compact catalog to the model, commonly as XML, JSON, a bulleted list, or a dedicated skill-activation tool description.
4. The model or user chooses a skill. Activation is usually model-driven from the description, but explicit user activation via slash command or mention syntax is also recommended.
5. The host provides either the full `SKILL.md` or the body with frontmatter stripped. Dedicated activation tools may wrap content in structured tags, list bundled resources, enforce permissions, or track activation.
6. The agent follows the skill instructions and loads referenced files only as needed. Relative paths are resolved against the skill directory.
7. The host should preserve activated skill content across context compaction and avoid reinjecting duplicate skill instructions.

The Python reference library supports a narrow slice of this path: find `SKILL.md`, parse frontmatter, validate metadata constraints, read properties, and generate an `<available_skills>` XML block with name, description, and `SKILL.md` location.

## Architecture

The repo is documentation-first:

- `docs/docs.json` configures the Mintlify docs site and navigation.
- `docs/specification.mdx` is the core format document.
- `docs/client-implementation/adding-skills-support.mdx` is the implementor guide and contains the most useful loader expectations.
- `docs/skill-creation/*.mdx` defines creator practices and evaluation patterns.
- `docs/snippets/clients.jsx` maintains ecosystem listing data.
- `skills-ref/pyproject.toml` packages a Python 3.11+ library with `click` and `strictyaml`.
- `skills-ref/src/skills_ref/parser.py` parses frontmatter and reads required properties.
- `skills-ref/src/skills_ref/validator.py` validates known fields and constraints.
- `skills-ref/src/skills_ref/prompt.py` emits the suggested XML prompt catalog.
- `skills-ref/src/skills_ref/cli.py` exposes `validate`, `read-properties`, and `to-prompt`.
- `skills-ref/tests/` covers parser, validator, and prompt behavior.

There is no machine-readable JSON Schema, no canonical installer, no registry protocol, no plugin manifest for this repository itself, no reference activation tool server, and no production-grade file scanner.

## Design Choices

The strongest design choice is the very small skill contract. A skill is just a directory with `SKILL.md`; the required frontmatter is only `name` and `description`. Optional fields are `license`, `compatibility`, `metadata`, and experimental `allowed-tools`.

The `description` is treated as the trigger contract. The optimization guide is explicit that startup disclosure usually includes only name and description, so descriptions must encode when the skill should activate and avoid both false negatives and false positives.

The spec keeps packaging intentionally loose. Optional `scripts/`, `references/`, and `assets/` directories are conventions, not deep schemas. This improves portability and authoring simplicity but leaves compatibility, dependency installation, resource indexing, and security to clients.

The client guide recommends common search locations but does not mandate them. It highlights `.agents/skills/` as a cross-client convention and suggests also scanning client-specific directories, user-level scopes, project-level scopes, built-ins, `.claude/skills/`, ancestor directories, XDG config locations, and user-configured paths where appropriate.

The reference library is strict in validation but the client guide recommends lenient loading. This is a useful distinction: validators can enforce the spec, while runtime loaders should often warn and continue for compatibility.

## Strengths

The spec is compact enough to implement quickly. The minimal shape avoids overfitting to one agent runtime and makes skills easy to store in Git, bundle in projects, review, and share.

Progressive disclosure is well articulated. The docs connect file layout to token economics and context management, including guidance to preserve active skill content during compaction.

The client implementor guide is unusually practical for a format spec. It covers discovery scopes, collision precedence, trust checks for project-level skills, sandboxed/cloud-hosted agents, malformed YAML, lenient validation, model-driven activation, explicit user activation, dedicated activation tools, resource listing, permission allowlisting, context compaction, deduplication, and optional subagent execution.

The creator docs are directly reusable. Description evals, with-skill versus without-skill quality evals, assertion grading, benchmarks, transcript review, and validation-loop patterns are valuable for building better Agentic Coding Lab skills.

The reference library and tests expose concrete edge cases: lowercase `skill.md` compatibility, XML escaping, Unicode name validation, directory/name matching, description length, compatibility length, and experimental `allowed-tools` parsing.

The client showcase is useful ecosystem evidence. It shows that the format is being positioned as cross-client, including coding agents and broader agent products.

## Weaknesses

The reference library is explicitly not production-ready. `skills-ref/README.md` says it is for demonstration purposes only, so it should not be adopted as the Agentic Coding Lab loader without hardening.

The spec is partly prose instead of an executable contract. There is no JSON Schema or conformance test suite that client implementations can run against a corpus of valid and invalid skills.

Packaging and distribution are under-specified. There is no canonical archive format, lockfile, dependency manifest, registry API, signature/provenance mechanism, version-resolution rule, or update/install workflow.

Security boundaries are mostly delegated to clients. The docs mention project trust checks, permission allowlisting, pre-approved tools, and safe script practices, but the format itself does not define sandbox policy, capability grants, secret handling, network policy, destructive-action gating, or audit logs.

There are small contract tensions. The docs say clients should scan for files named exactly `SKILL.md`, while the reference parser accepts lowercase `skill.md`; the spec examples describe lowercase alphanumeric names with `a-z` wording, while tests and implementation allow Unicode alphanumeric characters. These may be intentional compatibility choices, but they need explicit treatment in any local implementation.

The `allowed-tools` field is experimental and only parsed/validated as a string. It is not a portable authorization model by itself.

## Ideas To Steal

Use `name` plus `description` as the always-loaded catalog, and keep full instructions out of base context until activation.

Adopt `.agents/skills/` as the cross-client location, while also supporting project-local and user-local scopes with deterministic precedence.

Treat descriptions as testable trigger contracts. Maintain should-trigger and should-not-trigger query sets, run multiple activation checks, and tune descriptions against validation prompts rather than intuition.

Wrap activated skill content in structured tags when using a dedicated activation tool. Include the skill directory and resource listing so relative paths are unambiguous without eagerly loading support files.

Protect activated skill content during compaction and deduplicate repeated activations. Losing durable instructions mid-task is a silent failure mode.

Use the creator docs' script guidance for Agentic Coding Lab skill helpers: non-interactive CLIs, concise `--help`, structured stdout, diagnostics on stderr, idempotency, dry-run flags for risky actions, clear exit codes, and predictable output size.

Build a conformance harness around the reference tests but extend it beyond frontmatter: discovery locations, collision precedence, activation wrapping, permission checks, resource path resolution, and compaction behavior.

## Do Not Copy

Do not treat `skills-ref` as production infrastructure. It is useful as a small executable spec sketch, but its own README says it is demonstration-only.

Do not rely on description matching as a security boundary. A model choosing a skill is not the same as policy enforcement.

Do not make `allowed-tools` mean "safe to run" without a client-side permission engine. The field is experimental and has no portable enforcement semantics in this repo.

Do not copy the loose packaging story if Agentic Coding Lab needs reproducible installs. Add local rules for versioning, provenance, dependency pinning, validation, and updates.

Do not assume all compatible clients behave identically. The showcase indicates broad adoption, but the docs repeatedly leave implementation choices to the client.

Do not over-specify every skill resource into the initial context. The whole format is optimized around progressive disclosure; eager loading would defeat the main design.

## Fit For Agentic Coding Lab

Fit is in-scope and high. This is a foundational source for the `skills-instructions` category because it defines the skill file contract and the host-client expectations around discovery, activation, and context handling.

The best Agentic Coding Lab use is not to vendor this repo wholesale. Instead, use it as the baseline external compatibility contract, then layer local production requirements on top: conformance tests, strict-plus-lenient parser behavior, package provenance, update rules, workspace trust, permission enforcement, script sandboxing, and activation observability.

For local research artifacts, this repo should inform:

- A local skill schema and validator compatible with `SKILL.md`.
- A skill catalog prompt format or activation tool contract.
- A trigger-eval harness for descriptions.
- A resource-loading policy that keeps references one hop away and paths relative to skill root.
- A hardened script-authoring guide for skills that run commands.
- A conformance suite that separates strict spec validity from lenient runtime loading.

## Reviewed Paths

- `/tmp/myagents-research/agentskills-agentskills/README.md`
- `/tmp/myagents-research/agentskills-agentskills/CONTRIBUTING.md`
- `/tmp/myagents-research/agentskills-agentskills/package.json`
- `/tmp/myagents-research/agentskills-agentskills/docs/home.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/specification.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/client-implementation/adding-skills-support.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/skill-creation/quickstart.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/skill-creation/best-practices.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/skill-creation/optimizing-descriptions.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/skill-creation/evaluating-skills.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/skill-creation/using-scripts.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/clients.mdx`
- `/tmp/myagents-research/agentskills-agentskills/docs/snippets/clients.jsx`
- `/tmp/myagents-research/agentskills-agentskills/docs/docs.json`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/README.md`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/pyproject.toml`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/__init__.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/models.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/parser.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/validator.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/prompt.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/cli.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/src/skills_ref/errors.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/tests/test_parser.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/tests/test_validator.py`
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/tests/test_prompt.py`
- `https://github.com/agentskills/agentskills`

## Excluded Paths

- `/tmp/myagents-research/agentskills-agentskills/.git/`: VCS internals, excluded except for commit capture.
- `/tmp/myagents-research/agentskills-agentskills/docs/images/`: client logos and static media; relevant only as docs assets, not skill contract logic.
- `/tmp/myagents-research/agentskills-agentskills/docs/favicon.svg` and `/tmp/myagents-research/agentskills-agentskills/docs/style.css`: docs presentation assets, not relevant to skill behavior.
- `/tmp/myagents-research/agentskills-agentskills/docs/snippets/ClientShowcase.jsx` and `/tmp/myagents-research/agentskills-agentskills/docs/snippets/LogoCarousel.jsx`: UI rendering code for the docs site; the client data file was reviewed instead.
- `/tmp/myagents-research/agentskills-agentskills/skills-ref/uv.lock`: dependency lockfile noted but not reviewed line-by-line because behavior is captured by `pyproject.toml`, source, and tests.
- License text files: license presence and split between code/documentation licenses were checked, but repeated legal text was not deeply reviewed.
