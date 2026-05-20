# nexu-io/open-design

- URL: https://github.com/nexu-io/open-design
- Category: domain-specific-coding
- Stars snapshot: 47,515 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 69469c639e2411f1b61bf0f0cf951b73f91cce5d
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for domain-specific design coding workflows. The reusable core is the layered artifact contract: portable `SKILL.md`, active `DESIGN.md`, craft references, `open-design.json` plugin sidecars, pipeline atoms, GenUI surfaces, applied snapshots, local project files, and deterministic verification gates. Best ideas are worth stealing; the full app is too broad and fast-moving to copy wholesale.

## Why It Matters

Open Design is not only a UI generator. It is a domain-specific coding workflow for turning existing coding-agent CLIs into design artifact producers. The repo shows how to package design work as files, schemas, prompts, staged assets, pipelines, preview surfaces, and review loops rather than as one large prompt.

For Agentic Coding Lab, the value is the workflow substrate: how visual design intent is made explicit, scoped, reusable, reviewable, and tied to tool/runtime boundaries. It gives concrete patterns for agent skills, design-system context, per-run context chips, artifact provenance, prompt assembly, headless CLI use, preview isolation, and output quality gates.

## What It Is

The reviewed checkout is a TypeScript monorepo for a local-first Open Design app: a web UI, local daemon, desktop shell, plugin runtime, contracts package, CLI/dev tooling, design systems, skills, examples, and e2e tests. The daemon detects and launches external coding-agent CLIs such as Claude Code, Codex, Gemini, Cursor Agent, OpenCode, Qwen, Copilot, Devin, Kiro, Kilo, Vibe, Pi, and DeepSeek; Open Design supplies design-specific context and artifact handling while the chosen agent owns the model/tool loop.

The local corpus is large: 132 checked-in `skills/**/SKILL.md` files, 150 `design-systems/**/DESIGN.md` files, and 414 `plugins/**/open-design.json` manifests in the reviewed tree. Those counts differ from some README and metadata copy, which reflects how quickly this repo is moving.

Core checked-in artifact types are:

- `SKILL.md`: portable agent workflow instructions with optional `od:` frontmatter for mode, preview, inputs, craft, outputs, and capability requirements.
- `DESIGN.md`: active design-system memory for palette, typography, components, layout, and anti-patterns.
- `craft/*.md`: universal visual-quality rules, such as typography, color, anti-slop, and UX rules, injected only when a skill asks for them.
- `open-design.json`: plugin sidecar that adds marketplace metadata, inputs, context refs, pipeline stages, GenUI surfaces, connector/MCP refs, trust, and capabilities without replacing `SKILL.md`.
- Applied plugin snapshots: immutable per-run records of inputs, resolved context, pipeline, granted capabilities, assets, connectors, MCP servers, and query text.
- Artifact files: generated project files, manifests, previews, exports, and sidecars stored on disk under project working directories.

## Research Themes

- Token efficiency: Strong pattern. The stack separates durable context into `DESIGN.md`, craft files, skill bodies, plugin blocks, atom blocks, prompt metadata, and design-system token channels. It also supports pull-index style design-system files so large source evidence can stay out of the first prompt.
- Context control: Very strong. `composeSystemPrompt()` orders memory, user/project instructions, design system prose, token CSS, component manifests, craft references, active skill, active plugin, active pipeline-stage atom fragments, project metadata, deck/media contracts, critique protocol, and MCP auth guidance with explicit precedence.
- Sub-agent / multi-agent: Moderate. It does not orchestrate many model agents internally; instead it delegates the main loop to one selected external coding-agent CLI and normalizes their outputs. The reusable pattern is adapter capability negotiation and graceful feature degradation.
- Domain-specific workflow: Very strong. The repo encodes design generation as typed modes, artifact recipes, design-system contracts, direction selection, question forms, live preview, element ids, critique, export, and handoff.
- Error prevention: Strong. It has anti-slop artifact linting, artifact stub-regression guard, prompt-size guards, origin checks, path traversal guards, trust/capability gates, skill side-file staging, schema validation, and Critique Theater / Design Jury contracts.
- Self-learning / memory: Moderate. There is an auto-memory path that extracts user preferences into Markdown and reinjects them, but the most mature memory pattern is still static/project context rather than a full learned policy loop.
- Popular skills: Strong local candidates include `saas-landing`, `design-md`, deck skills, dashboard/live-artifact examples, video/image templates, design-system creation, critique, wireframe, and scenario plugins such as `od-default`, `od-new-generation`, `od-figma-migration`, and `od-tune-collab`.

## Core Execution Path

The main design-generation path is:

1. User chooses or implies a task mode, skill, design system, and possibly a plugin.
2. The daemon resolves project metadata, active skill, active design system, plugin snapshot, craft requirements, memory, user/project instructions, connected MCP servers, and runtime agent definition.
3. The prompt composer builds a layered system prompt. Design-system prose and compiled token/component data bind visual rules; craft fills universal quality rules; the skill defines the artifact recipe; plugin and active-stage atom blocks define the workflow wrapper.
4. The daemon stages active skill side files into the project cwd under `.od-skills/<skill>/` as copies, not symlinks, so agents can read templates/references without mutating source resources.
5. The daemon launches the selected external CLI in the project working directory. Prompt delivery, stdin use, image paths, add-dir allowlists, MCP injection, environment, model selection, and prompt-size checks are adapter-specific.
6. The web and daemon stream events: tool calls, text, files, pipeline stages, GenUI requests, live artifacts, critique events, and final artifacts.
7. Artifacts are saved as normal files, previewed in sandboxed iframes, linted for visual regressions, guarded against tiny stub replacements, and optionally exported or handed off.

Plugin-driven runs add an apply step before generation. `applyPlugin()` validates inputs, resolves context chips, computes a manifest digest, grants capabilities based on trust, resolves or inherits a scenario pipeline, derives GenUI surfaces, and produces an applied snapshot. Later prompt reconstruction reads the snapshot, not the mutable live plugin.

## Architecture

The architecture is a layered monorepo:

- `apps/daemon/`: local HTTP/SSE daemon, agent runtime detection/launch, prompt composition, project/file/artifact APIs, plugins, pipeline, GenUI, MCP, memory, media, critique, and security gates.
- `apps/web/`: Next.js UI for chat, project views, plugin surfaces, previews, settings, examples, and Critique Theater display.
- `apps/desktop/`: Electron shell and sidecar automation.
- `packages/contracts/`: shared Zod schemas and pure renderers for plugins, prompts, critique, API contracts, and analytics.
- `packages/plugin-runtime/`: parsers, adapters, digesting, merge, validate, resolve, and pipeline fallback logic for plugin folders.
- `packages/diagnostics`, `packages/host`, `packages/registry-protocol`, `packages/sidecar-proto`, `packages/platform`, `packages/agui-adapter`: support packages.
- `skills/`, `design-systems/`, `craft/`, `plugins/`: the domain-specific content substrate.
- `docs/`: architecture, skills protocol, plugins spec, design-system authoring guide, agent adapters, testing notes, and roadmap.
- `e2e/`, package tests, and web/daemon tests: cross-runtime and app-level verification.

The most reusable boundary is "OD owns context, artifact lifecycle, and product UI; external agents own reasoning and tool use." The daemon is the privileged local process and the project cwd is the operational boundary.

## Design Choices

`SKILL.md` remains the portable executable contract. Open Design extends it with `od:` metadata but keeps the body plain Markdown so skills can still run in other agents. `open-design.json` is additive: it describes marketplace/use-case/context/pipeline surfaces without duplicating the prompt body.

`DESIGN.md` is treated as authoritative design memory. The daemon can inject the full prose, optional `tokens.css`, optional component manifests, and a pull-file index. This creates a push/pull context model: small binding contract in prompt, richer source evidence available only when needed.

Craft rules are split from brand rules. A skill can request universal references like typography, color, anti-slop, and laws of UX; the active design system still wins on token values. This prevents every brand file from repeating general design taste.

Pipelines are atom-based. A plugin can declare ordered stages like discovery, plan, generate, critique, migration, diff review, or handoff. Stages emit events and may repeat until closed signals such as `critique.score`, `iterations`, `user.confirmed`, or `preview.ok` satisfy an expression.

GenUI is declared, not improvised. Plugins can declare form, choice, confirmation, and OAuth-prompt surfaces; the product renderer owns the UI and persistence tier. This is a better pattern than letting agents invent arbitrary app UI for every clarification.

The runtime adapter layer is capability-driven. Agents differ in streaming, native skill loading, prompt delivery, MCP support, image support, and edit ability. Open Design records these differences and degrades features rather than pretending every CLI supports the same protocol.

Verification is layered. Prompt instructions ask for preflight, self-check, and critique; code adds schema validation, lints, prompt-budget guards, origin validation, artifact regression guards, sandboxed previews, and broad unit/e2e coverage.

## Strengths

The artifact model is excellent. Skills, design systems, craft rules, plugin manifests, applied snapshots, generated files, and critique transcripts are all reviewable artifacts rather than invisible prompt state.

Context assembly is unusually disciplined. It handles precedence, active design-system override, user/project instructions, memory, skill side files, plugin input authority, stage-specific atom blocks, and MCP auth status explicitly.

The plugin model is a strong packaging pattern for long-running agent tasks. It captures inputs, resolved context, capabilities, pipeline, GenUI, provenance, and snapshot digest at apply time.

The repo has practical defenses against common agent-design failures: default purple/indigo palettes, emoji UI icons, left-accent cards, lorem text, invented metrics, artifact stubs, oversized argv prompts, bad origins, path traversal, and over-broad writable skill resources.

The adapter strategy is pragmatic. It avoids reimplementing every agent loop and instead focuses on detection, launch, prompt delivery, event normalization, cwd control, and capability gates.

The design-system authoring guide has useful review lenses. Lens A blocks structural/code correctness; Lens B captures reasoning completeness. That split maps well to agent-generated domain artifacts.

## Weaknesses

The repo is very broad and rapidly changing. README descriptions, local counts, and docs can drift; several docs describe target architecture or roadmap state rather than only shipped behavior.

Prompt mass can still get large. Full identity prompt, discovery layer, design-system prose, token CSS, component manifests, craft, skill body, plugin block, stage atoms, metadata, media/deck/critique contracts, and MCP guidance can be too much without stricter retrieval.

Some pipeline atoms are still permissive from the daemon's perspective. The registry supplies real observation mainly where the daemon has ground truth, while many atoms converge optimistically because the actual work happens inside the agent CLI.

Critique Theater is strongest for plain stdout paths and HTML-like artifacts. Non-plain adapters and media surfaces are gated or skipped, so review behavior is not uniform across agents or artifact types.

Bundled catalog quality is mixed. Some skills are full workflows with typed inputs and checklists; others are thin upstream catalog entries that tell the user to install the original external bundle.

The app surface is much larger than the reusable research target. Copying the whole system would bring desktop packaging, media providers, registries, localization, deployment, and marketplace complexity that Agentic Coding Lab does not need.

## Ideas To Steal

Use three separate context artifacts for UI/domain work: `AGENTS.md` for coding process, `DESIGN.md` for brand/visual contract, and `SKILL.md` for the task recipe.

Add a plugin sidecar pattern for long-running workflows: `open-design.json`-like metadata with inputs, context refs, capability requirements, pipeline stages, GenUI surfaces, and provenance.

Snapshot every applied workflow before a run. Persist inputs, resolved context, plugin version, digest, capabilities, assets, and pipeline so old runs can be reconstructed after plugin updates.

Adopt push/pull design-system context. Put concise `tokens.css` and component manifest in the prompt, keep source evidence or large fixtures behind a path allowlist for on-demand reads.

Split brand-specific rules from universal craft rules. Let task skills opt into only the craft references they need.

Stage skill assets into the project cwd as copies, not symlinks. This gives agents readable templates/references without making source skills writable.

Use declared GenUI surfaces for agent-human checkpoints: discovery forms, direction choices, authorization, OAuth, diff review, and confirmations.

Add deterministic design-quality checks outside prompts: anti-slop lints, stub-regression detection, schema checks, contrast/focus requirements, and artifact preview smoke tests.

Make adapter capabilities visible to workflow selection. Disable comment mode, external MCP, image input, or resume when the selected agent cannot support them.

## Do Not Copy

Do not copy long prompt bodies or branding/style libraries verbatim. Extract schemas, layering rules, and verification patterns instead.

Do not inherit the whole product surface. Agentic Coding Lab likely needs a smaller workflow substrate, not a full design app with media providers, desktop packaging, marketplace, and deployment matrix.

Do not trust prompt-only critique. Pair any "jury" or self-review loop with parsers, structured scores, artifacts, test fixtures, and fallback policy.

Do not assume every external coding agent has equivalent permissions, streaming shape, native skills, MCP support, or edit fidelity. Keep capability negotiation central.

Do not load every design-system and craft file into every run. This repo proves the value of domain context, but also shows why retrieval and section pruning are necessary.

Do not treat third-party/bundled plugin catalogs as safe by default. Keep tiered trust, scoped capabilities, path guards, and install integrity checks.

## Fit For Agentic Coding Lab

Fit is strongly in-scope for `domain-specific-coding`. Open Design is a concrete example of turning general coding agents into a domain-specific design-coding environment through artifacts, schemas, prompt composition, UI checkpoints, adapters, and verification.

Best local adaptation is a smaller "domain workflow pack" architecture: portable skill folder, design/domain memory file, craft/reference snippets, plugin sidecar, applied snapshot, stage events, GenUI request format, and deterministic verification scripts. That would let Agentic Coding Lab support UI/design tasks, migration tasks, or other domains without rebuilding a monolithic app.

Highest-value steal is the separation of concerns: domain knowledge lives in files; workflow shape lives in manifests and pipeline stages; runtime differences live in adapters; safety lives in capability gates and deterministic checks; generated output lives as inspectable project files.

## Reviewed Paths

- `/tmp/myagents-research/nexu-io-open-design/README.md`: product overview, execution loop, skills/design systems, agent runtime, roadmap, provenance, and status claims.
- `/tmp/myagents-research/nexu-io-open-design/docs/architecture.md`: topology, daemon/web split, skill registry, design-system resolver, artifact store, preview renderer, and data flow.
- `/tmp/myagents-research/nexu-io-open-design/docs/skills-protocol.md`: `SKILL.md` compatibility, `od:` extensions, typed inputs, parameters, outputs, craft, discovery precedence, and design-system injection.
- `/tmp/myagents-research/nexu-io-open-design/docs/plugins-spec.md`: plugin folder shape, `open-design.json`, trust, Apply pipeline, atoms, GenUI, pipelines, snapshots, and scenarios.
- `/tmp/myagents-research/nexu-io-open-design/docs/agent-adapters.md`: external CLI adapter contract, detection strategy, prompt injection/native skills, capabilities, and per-agent notes.
- `/tmp/myagents-research/nexu-io-open-design/docs/design-systems.md`: 9-section schema, authoring rules, Lens A/Lens B review framework, CSS tokens, accessibility, and motion rules.
- `/tmp/myagents-research/nexu-io-open-design/docs/atoms.md`: first-party atom catalog, implemented/planned atom IDs, signals, and `until` vocabulary.
- `/tmp/myagents-research/nexu-io-open-design/docs/critique-theater.md`: Design Jury / Critique Theater roles, scoring, rollout gates, replay, and degraded states.
- `/tmp/myagents-research/nexu-io-open-design/docs/skills-contributing.md`: skill authoring bar, hand-built examples, checklist requirement, i18n fallback, and validation expectations.
- `/tmp/myagents-research/nexu-io-open-design/docs/testing/plugin-system-test-suite.md`: plugin-system coverage map, known gaps, and validation matrix.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/prompts/system.ts`: prompt stack ordering, design-system token channel, craft injection, skill/plugin/stage blocks, deck/media/critique gates, MCP guidance, and plain-stream override.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/skills.ts`: skill scanner, frontmatter parsing, mode/platform/scenario inference, craft requirements, derived examples, skill side-file preamble, and aliases.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/design-systems.ts`: design-system registry, manifest support, swatches, user metadata, token/component assets, pull-file allowlist, and token-channel gate.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/craft.ts`: craft loader and slug validation.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/cwd-aliases.ts`: active-skill staging into `.od-skills/` as copies and path-segment safety.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/runtimes/*`: runtime registry, detection, launch, invocation, types, and adapter metadata for external coding-agent CLIs.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/server.ts`: selected chat/run path for prompt composition, project cwd, attachments, tool tokens, MCP injection, skill staging, prompt budgets, spawn, inactivity guard, and pipeline firing.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/plugins/*`: apply, persistence migrations, trust, pipeline scheduler, atom bodies, atom workers, snapshots, installer/registry boundaries, and validation.
- `/tmp/myagents-research/nexu-io-open-design/packages/contracts/src/plugins/*` and `packages/contracts/src/prompts/*`: plugin schemas, context items, applied snapshots, plugin block renderer, atom block renderer, and critique contracts.
- `/tmp/myagents-research/nexu-io-open-design/packages/plugin-runtime/src/*`: manifest parser, validator, digest, merge, adapters, and pipeline fallback.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/artifact-stub-guard.ts` and `apps/daemon/src/lint-artifact.ts`: deterministic guards against stub artifacts and AI-design slop.
- `/tmp/myagents-research/nexu-io-open-design/apps/daemon/src/origin-validation.ts`: browser origin/host validation boundary.
- `/tmp/myagents-research/nexu-io-open-design/plugins/_official/scenarios/od-default/open-design.json`: default scenario pipeline and GenUI surface example.
- `/tmp/myagents-research/nexu-io-open-design/plugins/_official/examples/saas-landing/SKILL.md`: complete skill example with typed inputs, craft refs, output contract, and self-check.
- `/tmp/myagents-research/nexu-io-open-design/skills/design-md/SKILL.md`, `skills/artifacts-builder/SKILL.md`, `skills/design-review/SKILL.md`: examples of thin curated upstream skill entries.
- Directory-level counts and structure review for `skills/`, `design-systems/`, `craft/`, `plugins/`, `packages/`, `apps/`, and `e2e/`.

## Excluded Paths

- `/tmp/myagents-research/nexu-io-open-design/.git/`: VCS internals; commit SHA captured separately.
- Binary and large visual assets under `docs/assets/`, `docs/screenshots/`, `assets/`, `tools/pack/resources/`, and `edited_image.png`: useful for product/UI, but not needed for workflow-pattern analysis.
- Localized README/QUICKSTART/CONTRIBUTING/MAINTAINERS copies in non-English locales: sampled via English source docs; excluded to avoid duplicating translation review.
- Helm, Docker, packaging, installer, notarization, and release resources under `deploy/`, `tools/pack/`, and platform-specific resource folders: deployment surface, not central to reusable agent workflow design.
- Landing-page marketing content under `apps/landing-page/`: product/site presentation, not core coding-agent workflow mechanics.
- Media-provider template details and prompt-template galleries under `prompt-templates/`, image/video/audio skill internals, and screenshots: domain content sampled at structure level only.
- Full line-by-line review of all 132 skills, 150 design systems, and 414 plugin manifests: covered by counts, representative samples, docs, parsers, and validation paths; exhaustive content audit would be separate.
- External upstream repositories named in docs or skill provenance, such as Open CoDesign, huashu-design, guizang-ppt-skill, awesome-design-md, awesome-design-skills, multica, and cc-switch: treated as provenance/inspiration, not reviewed here.
