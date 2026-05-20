# google-labs-code/stitch-skills

- URL: https://github.com/google-labs-code/stitch-skills
- Category: domain-specific-coding
- Stars snapshot: 5,524 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 2c93fbcf00bfde9b02b8f7322a1148cdd6cba02a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong candidate for domain-specific UI/design coding skills. Best reusable patterns are the three-plugin skill package, `.stitch/` artifact contract, DESIGN.md as project-level visual memory, explicit Stitch MCP boundaries, scripts that move large files outside model context, and workflow skills that chain design generation, design-system creation, asset upload, code extraction, and build verification. Biggest gaps are thin repository-level validation, prompt-heavy skill bodies, broad tool grants, some metadata/prose drift, and limited machine-readable contracts around skill dependencies.

## Why It Matters

`stitch-skills` shows how a vendor-specific design surface can be exposed to general coding agents through portable skills rather than a monolithic app. The repo is small, but it covers a full design-to-code and code-to-design loop: generate screens in Stitch, download HTML and screenshots, extract a design system from code, upload HTML or DESIGN.md through the Stitch API, create project-level design systems, convert Stitch designs into React components, and drive multi-page site iterations with baton files.

For Agentic Coding Lab, the value is the domain packaging pattern. Stitch-specific knowledge is split into reusable skill folders, scripts, resources, examples, and plugin manifests. The best parts make tool limits explicit: MCP calls are used for project/screen/design-system operations, shell scripts handle signed URLs and large base64 uploads, and local `.stitch/` files become the durable interface between iterations. This is a practical model for UI/design domains where agent context alone is too brittle.

## What It Is

`google-labs-code/stitch-skills` is a public collection of Agent Skills and plugins for Google Stitch. It follows an Agent Skills style layout under `plugins/` with three plugin packages:

- `stitch-design`: core design workflows for code-to-design, generation/edit/variants, design-system management, source-to-DESIGN.md extraction, static HTML extraction, and upload.
- `stitch-build`: build-side workflows for React components, Remotion walkthrough videos, and shadcn/ui integration.
- `stitch-utilities`: support skills for DESIGN.md synthesis, prompt enhancement, autonomous site loops, and opinionated "taste" design systems.

The reviewed tree has 13 `SKILL.md` files, plugin metadata, examples, references, resources, and scripts. It is not a runtime service. It relies on the caller's coding agent, Stitch MCP server, and local shell environment. The README advertises compatibility with Antigravity, Gemini CLI, Claude Code, Cursor, and other Agent Skills consumers.

## Research Themes

- Token efficiency: Moderate. The repo uses progressive disclosure through `SKILL.md` plus `references/`, `resources/`, `examples/`, and `scripts/`. The strongest token-control move is pushing large file transfer and base64 encoding into scripts instead of MCP/model arguments. Weakness: several skill bodies are long and include full workflow prose inline.
- Context control: Strong for design work. `DESIGN.md`, `.stitch/metadata.json`, `.stitch/designs/*.html`, `.stitch/designs/*.png`, `.stitch/SITE.md`, and `.stitch/next-prompt.md` create durable context artifacts. `generate-design` explicitly separates project-level visual tokens from generation prompts to avoid theme leakage.
- Sub-agent / multi-agent: Light. There is no internal multi-agent orchestrator. `stitch-loop` creates a baton pattern that can be resumed by repeated agents or external orchestration, and the Remotion skill can combine Stitch MCP with Remotion MCP, but the repo is mostly single-agent workflow guidance.
- Domain-specific workflow: Strong. Skills encode Stitch project discovery, screen retrieval, signed asset downloads, prompt enhancement, design-system upload, screen generation/editing/variants, HTML extraction, code artifact generation, and walkthrough-video production.
- Error prevention: Mixed. Good patterns include required user confirmation before uploads, design-system prompt constraints, AST validation for generated React components, shadcn setup checks, screenshot/HTML local caching, and CI for one gold-standard component. Gaps include little CI over the full skill catalog and no schema validation for most skill artifacts.
- Self-learning / memory: No adaptive learning. Memory is artifact-based: `DESIGN.md` captures visual language, `metadata.json` captures Stitch identifiers, `SITE.md` captures long-term site plan, and `next-prompt.md` carries the next task.
- Popular skills: `stitch::generate-design`, `stitch::code-to-design`, `stitch::manage-design-system`, `stitch::extract-design-md`, `stitch::extract-static-html`, `stitch::upload-to-stitch`, `react:components`, `remotion`, `shadcn-ui`, `design-md`, `enhance-prompt`, `stitch-loop`, and `taste-design`.

## Core Execution Path

The main code-to-design path is a chained workflow:

1. `stitch::code-to-design` delegates to `extract-static-html` to produce a standalone HTML snapshot from a running app or fallback JSX mock.
2. It delegates to `extract-design-md` to scan frontend source, theme files, CSS, Tailwind config, and components, then write `.stitch/DESIGN.md`.
3. It delegates to `manage-design-system` to upload DESIGN.md and call Stitch design-system creation tools.
4. It delegates to `upload-to-stitch` to upload the standalone HTML into the target Stitch project.

The main design-generation path is:

1. Discover the Stitch MCP namespace, list or create the target project, and check for design systems.
2. If no project design system exists, create one through `manage-design-system`; once it exists, avoid repeating colors, fonts, or theme tokens in generation prompts.
3. Enhance the user prompt into structure, content, and component language.
4. Call `generate_screen_from_text`, `edit_screens`, or `generate_variants`.
5. Surface Stitch `outputComponents` feedback to the user.
6. Download HTML and screenshot assets into `.stitch/designs`, update `.stitch/metadata.json`, and iterate with focused edits instead of regenerating from scratch when only polish is needed.

The design-system upload path is particularly reusable:

1. Generate `.stitch/DESIGN.md` with YAML frontmatter and semantic Markdown sections.
2. Pause for user confirmation before upload.
3. Run `upload_to_stitch.py`, which reads the file locally, base64-encodes it in-process, and sends a REST `screens:batchCreate` request.
4. Fetch project details to get the correct screen instance IDs.
5. Call `create_design_system_from_design_md`; for applying an existing design system, pass only `id` and `sourceScreen` to avoid invalid-argument failures.

The Stitch-to-React path is:

1. Retrieve screen metadata with Stitch MCP.
2. Check whether `.stitch/designs/{page}.html` and `.png` already exist and ask before refreshing.
3. Use `fetch-stitch.sh` for signed HTML and screenshot downloads; append width to screenshot URLs to avoid low-resolution thumbnails.
4. Review the screenshot for visual intent.
5. Generate modular React/TypeScript components, move static data to `src/data/mockData.ts`, isolate logic in hooks, and map Stitch/Tailwind tokens to local theme values.
6. Run `npm run validate <file>` to parse TSX with SWC and reject missing Props interfaces or hardcoded hex colors.
7. Run the app for live visual verification.

The autonomous site loop is:

1. Read `.stitch/next-prompt.md` frontmatter for the page name and prompt body.
2. Read `.stitch/SITE.md` and `.stitch/DESIGN.md` for project memory and visual contract.
3. Generate a Stitch screen, download assets, and move generated HTML into `site/public/{page}.html`.
4. Update navigation, sitemap, roadmap, and the next baton.
5. Optionally use Chrome DevTools MCP for visual comparison when available.

## Architecture

The repo is an installable skill bundle:

- `README.md`: installation, prerequisites, plugin catalog, and repository structure.
- `plugins/stitch-design/plugin.json`: plugin metadata for design workflows.
- `plugins/stitch-build/plugin.json`: plugin metadata for build workflows.
- `plugins/stitch-utilities/plugin.json`: plugin metadata for helper/design-quality workflows.
- `plugins/*/skills/*/SKILL.md`: task-specific agent contracts.
- `scripts/`: executable helpers for large downloads, static snapshots, HTML post-processing, API uploads, shadcn setup checks, and React validation.
- `resources/`, `reference/`, and `references/`: schema notes, design mappings, setup guides, checklists, templates, API notes, and component guidance.
- `examples/`: sample DESIGN.md files, Remotion composition, React component, shadcn patterns, site memory, and baton files.
- `.github/workflows/validate-skills.yml`: CI that installs React-component skill dependencies and validates the gold-standard TSX example.

The strongest architectural boundary is "MCP for Stitch control plane, scripts for large bytes, files for durable state." MCP operations cover project lookup, screen generation, screen editing, variant generation, screen metadata, design-system creation, and design-system application. Shell/Python/TypeScript scripts handle places where model output or MCP arguments are a poor fit: signed URL fetches, rendered DOM snapshots, local asset inlining, and file upload payloads.

## Design Choices

The most important design choice is treating `DESIGN.md` as the source of truth for visual language. Multiple skills either create it, consume it, upload it, or require a block from it in prompts. This lets the agent keep generation prompts focused on layout and content while project-level Stitch design systems carry color, typography, and roundness.

The second choice is composing workflows from smaller skills. `code-to-design` is a thin orchestration skill that points to extraction, design-system, and upload skills instead of duplicating implementation details. This is a good reusable packaging style for domain workflows that have multiple phases and different tool boundaries.

The third choice is explicit token-limit mitigation. `upload_to_stitch.py` exists because base64 file payloads can exceed model output limits. `snapshot.ts`, `extract_inline_html.ts`, and `post_process.ts` similarly keep asset inlining and HTML capture in local programs rather than model context.

The fourth choice is using local `.stitch/` files as the workflow contract. Generated designs, screenshots, metadata, design systems, site plan, and next prompt live in predictable files that can be inspected, diffed, and resumed.

The fifth choice is placing human checkpoints around irreversible or external side effects. `extract-static-html` asks the user to choose a capture strategy and confirm before snapshotting after a server starts. `manage-design-system` and `upload-to-stitch` require confirmation before uploading to Stitch.

The sixth choice is hybrid verification. The repo uses prompt checklists for design quality, AST checks for React component shape/style constraints, shell checks for shadcn setup, Remotion composition checklists, and a small CI workflow. This is not comprehensive, but it shows how design skills can combine qualitative review and executable gates.

## Strengths

- Clear reusable plugin split: design workflows, build workflows, and utilities are packaged separately but can reference one another.
- Practical tool boundary modeling: Stitch MCP handles remote domain operations, while scripts handle high-volume or fragile data transfer.
- Strong artifact contract around `.stitch/`: design systems, generated assets, metadata, site memory, and baton prompts make runs restartable and reviewable.
- Good context discipline in `generate-design`: design tokens belong to project-level design systems, not every screen-generation prompt.
- Useful source-to-design-system workflow: `extract-design-md` handles React/Tailwind, Vue, Svelte, Angular, and plain CSS references, and asks agents to translate raw CSS into semantic visual language.
- Static HTML capture is unusually concrete: Puppeteer snapshot supports rendered DOM capture, CSS/image inlining, viewport/dark mode/full-height options, custom removal selectors, click support, and JSON stats.
- Upload script is a strong pattern for avoiding model-output base64 truncation and directly calling a domain API from local code.
- React build skill has an executable validation path using SWC AST parsing, not only prose.
- `stitch-loop` gives a simple reusable autonomous workflow pattern: project memory file, design memory file, current baton, generated artifact, and next baton.
- Examples and templates are close to the task domain: component templates, Remotion screen templates, DESIGN.md examples, shadcn examples, and baton/site files.

## Weaknesses

- CI is narrow. The only reviewed workflow validates the React component gold-standard example; it does not validate all `SKILL.md` metadata, plugin JSON, scripts, examples, or cross-skill links.
- Skill dependency contracts are prose-only. `code-to-design` depends on three other skills, but there is no machine-readable dependency map or install-time check.
- Tool grants are broad. Most Stitch skills allow `stitch*:*`, `Bash`, `Read`, `Write`, and `web_fetch`, which is convenient but less precise than per-flow capability scoping.
- Some metadata and prose drift. `upload-to-stitch` prose lists image and HTML file types, while the script also supports `.md`; README names build skills without the `stitch::` prefix used by design skills; `react:components` naming differs from the surrounding Stitch namespace style.
- Verification is partly aspirational. Many design-quality checks are prompt checklists, and visual verification relies on user/manual review or optional external browser tooling.
- Several skills include long prompt templates and examples inline. This is readable for humans but can cost context when a caller only needs a narrow branch of the workflow.
- Security boundaries are uneven. Scripts intentionally fetch remote resources and launch headless Chrome; they include some URL/timeout/file-size safeguards, but there is no repository-level policy test suite around SSRF/path/resource risks.
- `extract-static-html` requires user strategy selection and multiple confirmations, which is safe but can interrupt automated pipelines unless the orchestrator has a clear approval mechanism.
- The repo mostly validates generated React shape, not design fidelity. Screenshot comparison, contrast checks, responsive checks, and artifact regression checks are described or optional, not enforced centrally.

## Ideas To Steal

- Package domain workflows as plugin families, not one giant skill. Keep design, build, and utility surfaces separate while allowing explicit skill handoffs.
- Use a durable domain folder like `.stitch/` to hold generated assets, external IDs, design-system memory, site memory, and next-task baton.
- Make design systems project-level context. Prompt generation should describe layout and content; token/theme instructions should live in a reusable design-system artifact.
- Use local scripts for large or fragile payloads. Base64 uploads, signed URL downloads, rendered snapshots, and asset inlining should not flow through model output.
- Add explicit "theme leakage" rules to UI-generation skills: once a design system exists, do not repeat color/font/roundness tokens in generation prompts.
- Encode external API quirks in reference docs, such as passing only `id` and `sourceScreen` for `apply_design_system`.
- Use AST-based validators for generated code artifacts, even if the first version checks only a few domain invariants.
- Put reusable templates next to skills: component skeletons, design-system examples, screen manifests, baton schema, and setup verification scripts.
- Create a baton loop for autonomous multi-page work: task prompt in, generated artifact out, project memory updated, next task written.
- Require user confirmation before external uploads, credential use, or creating remote artifacts, and make the checkpoint part of the skill contract.

## Do Not Copy

- Do not rely on prompt-only verification for UI/design fidelity. Pair checklists with screenshot tests, contrast checks, responsive checks, and artifact regression guards where possible.
- Do not keep dependency and capability requirements only in prose if skills are meant to be installed selectively. Add machine-readable dependencies and capability declarations.
- Do not give every workflow broad `Bash`/`Read`/`Write`/MCP access by default. Scope capabilities to the smallest useful surface when the host supports it.
- Do not duplicate long prompt bodies across skills. Prefer compact activation instructions plus focused reference files loaded on demand.
- Do not let docs drift from scripts. If upload supports `.md`, the supported-file table and README should say so, and CI should check it.
- Do not copy the taste-design bans wholesale as a universal policy. The useful pattern is encoding design anti-patterns in a semantic design system; exact aesthetic choices should remain project-specific.
- Do not assume optional browser/MCP verification exists. Skills should specify fallback verification artifacts when Chrome DevTools, Remotion MCP, or other optional tools are absent.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`. This repo is a compact case study in turning a visual design product into agent-usable workflow packages. It is especially useful for UI/design/code artifact flows, context control via domain files, and handling tool boundaries where MCP, shell scripts, and local project files each have a distinct role.

Best local adaptation is a generic domain skill package shape:

- `plugin.json` or sidecar metadata for marketplace/install grouping.
- `SKILL.md` for activation and workflow.
- `references/` for progressive domain guidance.
- `resources/` for templates and schemas.
- `examples/` for gold-standard outputs.
- `scripts/` for large byte movement, validation, and deterministic transforms.
- `.domain/metadata.json`, `.domain/DESIGN.md` or equivalent memory files, `.domain/assets/`, and `.domain/next-prompt.md` for durable context.

The repo should be mined for contracts and boundaries, not copied as-is. Stitch API names, project IDs, and visual taste defaults are domain-specific; the reusable part is the shape of skill handoffs, artifact persistence, context narrowing, and local-script verification.

## Reviewed Paths

- `/tmp/myagents-research/google-labs-code-stitch-skills/README.md`: installation, prerequisites, plugin catalog, skill list, repo structure, and Agent Skills layout.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/plugin.json`, `plugins/stitch-build/plugin.json`, `plugins/stitch-utilities/plugin.json`: plugin metadata and packaging boundaries.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/code-to-design/SKILL.md`: orchestration chain for static HTML extraction, DESIGN.md extraction, design-system upload, and HTML upload.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/generate-design/SKILL.md`: prompt enhancement, project/design-system lookup, generation/edit/variant flows, asset download, metadata update, and theme-token constraints.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/manage-design-system/SKILL.md` and `reference/tool-schema.md`: design-system retrieval, upload, create/apply schemas, metadata, and confirmation gates.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/extract-design-md/SKILL.md` plus framework references: source-code design-system extraction workflow for React/Tailwind, Vue, Svelte, Angular, and plain CSS.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/extract-static-html/SKILL.md` and `scripts/snapshot.ts`, `extract_inline_html.ts`, `post_process.ts`: rendered DOM snapshot, fallback JSX-to-HTML extraction, local image/CSS inlining, and script safeguards.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-design/skills/upload-to-stitch/SKILL.md` and `scripts/upload_to_stitch.py`: REST upload path, API-key boundary, base64-in-process strategy, file-type handling, and confirmation gate.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-build/skills/react-components/SKILL.md`, `scripts/fetch-stitch.sh`, `scripts/validate.js`, `resources/*`, and `examples/gold-standard-card.tsx`: Stitch-to-React workflow, signed fetch helper, AST validation, style guide, API reference, checklist, and template/example.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-build/skills/remotion/SKILL.md`, `scripts/download-stitch-asset.sh`, `resources/composition-checklist.md`, and examples: Stitch-to-video workflow, asset manifest, composition template, and render guidance.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-build/skills/shadcn-ui/SKILL.md`, `scripts/verify-setup.sh`, resources, and examples: shadcn/ui discovery, install, customization, accessibility, validation, and setup checks.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-utilities/skills/design-md/SKILL.md`: Stitch project/screen analysis into semantic DESIGN.md files.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-utilities/skills/enhance-prompt/SKILL.md` and `references/KEYWORDS.md`: prompt refinement and optional DESIGN.md injection.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-utilities/skills/stitch-loop/SKILL.md`, `examples/SITE.md`, `examples/next-prompt.md`, and `resources/baton-schema.md`: baton loop, site memory, project metadata, and autonomous multi-page workflow.
- `/tmp/myagents-research/google-labs-code-stitch-skills/plugins/stitch-utilities/skills/taste-design/SKILL.md` and `resources/DESIGN.md`: opinionated semantic design-system generation and anti-pattern encoding.
- `/tmp/myagents-research/google-labs-code-stitch-skills/.github/workflows/validate-skills.yml`: available CI coverage for React component validation.
- `/tmp/myagents-research/google-labs-code-stitch-skills/CONTRIBUTING.md`, `SECURITY.md`, and `LICENSE`: contribution, vulnerability-reporting, support, and Apache-2.0 licensing context.

## Excluded Paths

- `/tmp/myagents-research/google-labs-code-stitch-skills/.git/`: VCS internals; commit SHA captured separately.
- Full long prompt examples and reference bodies: sampled and summarized to avoid reproducing large prompt text verbatim.
- `plugins/stitch-build/skills/react-components/package-lock.json`: dependency lockfile reviewed only as package/CI context, not line-by-line.
- Full shadcn resource guide bodies and example TSX files: sampled for workflow, setup, customization, and verification patterns; exhaustive component-library review was out of scope.
- Full Remotion example component code: reviewed at structure level for manifest/template/checklist patterns rather than code-quality audit.
- External Stitch, Agent Skills, Remotion, and shadcn documentation URLs referenced by the repo: treated as dependency/provenance links, not independently reviewed here.
- Remote branches other than current `origin/main`: review target was the recorded commit on `main`.
