# op7418/guizang-ppt-skill

- URL: https://github.com/op7418/guizang-ppt-skill
- Category: domain-specific-coding
- Stars snapshot: 10.6k (GitHub repository page, captured 2026-05-20)
- Reviewed commit: 6bfa520b86ed5a3dffdac0a3323155e2b6f516b6
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong domain-specific agent skill for turning source material into polished HTML presentation artifacts. Best reusable patterns are locked visual systems, progressive reference loading, slot-first image handling, real failure checklists, low-power presentation runtime, and a static Swiss validator. Main gaps are browser QA still being manual, validation being regex/static and Swiss-only, CDN/runtime trust boundaries, and instruction drift across long prompt files.

## Why It Matters

`guizang-ppt-skill` is a concrete example of a coding agent skill that does not primarily produce application code but still uses code-native artifacts to solve a specialist creative workflow. It converts presentation design into editable HTML/CSS/JS, which lets an agent copy templates, choose layouts, insert assets, run static checks, and iterate in a browser instead of asking a slide editor to do the work.

The research value is the way the repo encodes domain taste as operational constraints. It does not merely say "make better slides." It defines two visual systems, layout catalogs, theme presets, image ratios, screenshot framing rules, interaction behavior, self-check tiers, and validation commands. That is directly relevant to Agentic Coding Lab because many useful future skills will need this shape: turn expert workflow knowledge into constrained artifacts, references, and tests that a general coding agent can follow.

## What It Is

The repository is a single Agent Skill for Claude Code, Codex, and similar local coding agents. The main output is a browser-presentable horizontal-swipe HTML deck, optionally accompanied by local `images/` assets, generated visuals, screenshot treatments, and platform cover formats. It ships with two deck systems:

- Style A: editorial magazine / e-ink presentation style, with serif-led titles, WebGL atmosphere, narrative layouts, and 5 curated themes.
- Style B: Swiss International Typographic Style, with strict sans-serif typography, 16-column grid thinking, one accent color, locked layouts, image slots, and a validator.

It is not a slide-editor app, MCP server, build system, or general presentation framework. The host agent reads `SKILL.md`, copies one of the HTML templates, fills slide sections from reference skeletons, optionally generates or normalizes images, previews the result in a browser, and runs the Swiss validator when using Style B.

## Research Themes

- Token efficiency: Good pattern, mixed implementation. The repo splits heavyweight detail into `references/`, so an agent can load only style-specific themes, layouts, screenshot, image, or map guidance. The tradeoff is that `SKILL.md`, `layouts-swiss.md`, and `checklist.md` are long and partly overlapping, so agents can still spend substantial context unless the workflow enforces selective reads.
- Context control: Strong. The main skill routes by style, then by artifact need: template, theme, layout catalog, validator, image prompts, screenshot framing, map component, and checklist. It also distinguishes Claude Code's `ask_question` style from Codex's plain conversation, which prevents tool-specific context leakage.
- Sub-agent / multi-agent: Weak. There is no delegation model, subagent contract, or parallel generation/review workflow. The closest reusable pattern is separating creative generation, asset preparation, static validation, and visual QA as phases that different workers could own.
- Domain-specific workflow: Very strong. The repo encodes the deck-making workflow end to end: intake questions, narrative rhythm, template copy, layout selection, image ratio binding, screenshot treatment, platform covers, navigation runtime, low-power mode, validator, browser preview, and iterative tuning.
- Error prevention: Strong for documented failure modes, moderate in enforcement. Style B has a static validator for registered layouts, `data-layout`, image slots, SVG text, centered body titles, experimental layouts, and S22 image rules. Both styles have a large checklist of recurring visual failures. Style A and browser-level behavior still rely on manual review.
- Self-learning / memory: Moderate as repository memory, not runtime memory. The checklist records real pitfalls and recent commits show it being updated after deck failures. There is no mechanism for storing project-specific user corrections or learning from generated decks automatically.
- Popular skills: The package has one main skill. Most reusable sub-patterns live in `references/checklist.md`, `references/layouts-swiss.md`, `references/swiss-layout-lock.md`, `references/image-prompts.md`, `references/screenshot-framing.md`, and `scripts/validate-swiss-deck.mjs`.

## Core Execution Path

The intended path is a host-agent workflow:

1. User asks for a magazine-style deck, Swiss-style deck, horizontal swipe deck, article-to-deck conversion, deck visuals, screenshot redesign, or social cover.
2. The host loads `SKILL.md` and decides whether enough input exists. If not, it asks a compact set of style, audience, duration, source, image, theme, and hard-constraint questions.
3. The agent chooses Style A or Style B and copies the matching template: `assets/template.html` or `assets/template-swiss.html`.
4. The agent picks a curated theme from `references/themes.md` or `references/themes-swiss.md`; custom colors are intentionally blocked.
5. For Style A, the agent plans theme rhythm and chooses from 10 layout skeletons. For Style B, it reads the layout lock first, chooses registered S01-S22 layouts, and writes `data-layout` on each slide.
6. The agent fills slide HTML with source content and local image paths. Images are supposed to be created or normalized only after the target slot and ratio are known.
7. If in Codex and images are useful, the agent asks before generating visuals. The image flow selects documentary photo, infographic, system map, UI scene, data block, or screenshot treatment and stores outputs under `images/{page}-{semantic}.{ext}`.
8. The agent runs the checklist. For Swiss decks it also runs `node scripts/validate-swiss-deck.mjs path/to/index.html`.
9. The deck is opened directly in a browser. Navigation, ESC overview, low-power mode, animation, image fit, text overflow, and bottom navigation safety are manually inspected.
10. User feedback is handled by editing HTML/CSS, mostly via inline font, height, spacing, and image-position tweaks.

The most important workflow choice is slot-first generation. The repo repeatedly says to pick layout and image ratio before creating or inserting assets. That prevents a common agent failure: generating attractive standalone images that cannot fit the deck.

## Architecture

The architecture is a static skill bundle plus browser runtime:

- `README.md` and `README.en.md`: install paths, supported agents, use cases, workflow summary, Style A/B summaries, image flow, cover generation, FAQ, and contribution guidance.
- `SKILL.md`: main trigger metadata, runtime adaptation, intake workflow, template copy rules, layout selection, image handling, validation, preview loop, resource-loading order, and design principles.
- `assets/template.html`: Style A seed deck. It contains CSS tokens, WebGL dark/light canvases, horizontal deck navigation, keyboard/wheel/touch controls, ESC overview, Lucide icons, local-first Motion One import, CDN fallback, and low-power mode.
- `assets/template-swiss.html`: Style B seed deck. It adds Carbon-like spacing and motion tokens, a canvas-card page model, Swiss classes, example cover/closing sections, static navigation, optional WebGL grid, ASCII canvas field for accent slides, Motion recipes for S layouts, and low-power behavior.
- `assets/motion.min.js`: local Motion One fallback, referenced by both templates but not audited as source because it is minified vendor code.
- `assets/screenshot-backgrounds/`: 9 bundled WebP backgrounds, 5 for Style A and 4 for Style B screenshot framing.
- `references/layouts.md`: Style A layout skeletons, theme rhythm, image sizing, animation recipes, and class preflight.
- `references/layouts-swiss.md`: Style B design baseline, P0 alignment rules, layout catalog, animation notes, S22 image hero guidance, and historical P23/P24 experiments marked as disabled by default.
- `references/swiss-layout-lock.md`: the authoritative S01-S22 registry, image slot rules, map extension registration, and forbidden structures.
- `references/components.md`: Style A component reference for typography, chrome/footer, callouts, stats, rows, figures, icons, ghost text, highlights, and Motion.
- `references/themes.md` and `references/themes-swiss.md`: curated palette variables and selection rules.
- `references/image-prompts.md`: image-type routing, ratio selection, screenshot redesign boundaries, and concise prompt templates for Style A/B visuals.
- `references/screenshot-framing.md`: screenshot-preservation workflow, semantic parameters, background asset mapping, and when to use generation versus programmatic framing.
- `references/swiss-map-component.md`: S08 MapLibre extension with static fallback, point/relation data contract, interaction controls, and event isolation.
- `references/checklist.md`: P0-P3 failure-memory checklist for layout lock, typography, image fit, nav safety, visual QA, placeholders, and common slide mistakes.
- `scripts/validate-swiss-deck.mjs`: Node static validator for Swiss deck HTML.
- `.github/ISSUE_TEMPLATE/*` and `.github/pull_request_template.md`: contribution intake that asks for prompts, generated HTML, screenshots, environment, theme, visual QA, and validation notes.
- `CONTRIBUTING.md`: contributor workflow, Swiss validator guidance, template QA expectations, and preference for focused visual fixes.
- `LICENSE`: MIT license.

There is no `package.json`, CI workflow, test fixture directory, schema file, install script, MCP manifest, or executable deck generator. The execution boundary is the host agent plus the generated HTML file.

## Design Choices

The strongest design choice is constraints over open-ended creativity. Style A and Style B are not loose aesthetics; they are bounded systems with allowed palettes, allowed typography roles, allowed layouts, and explicit anti-patterns. This is exactly the kind of narrowing that helps a general agent perform a specialist task reliably.

The Swiss layout lock is the most reusable workflow pattern. The repo records a finite S01-S22 layout registry, requires `data-layout`, marks unregistered P23/P24 structures as experimental, and backs the rule with a validator. This turns "stay on brand" from a prose preference into a checkable contract.

The asset strategy is practical. Images are treated as embedded deck assets, not standalone pictures. Prompts forbid image-internal footers, page numbers, logos, chrome, and decorative frames because those collide with slide chrome. Screenshot handling defaults to preserving original content through programmatic framing with bundled backgrounds before asking a model to redraw the UI.

The templates are self-contained enough for local editing but not dependency-free. They include runtime JS for swipe navigation, ESC overview, WebGL or ASCII animation, local-first Motion One, CDN fallbacks, Lucide icons, Google Fonts, and optional MapLibre. This is a good agent-native artifact shape, but it also means runtime safety and offline behavior need scrutiny.

The checklist is used as memory. Instead of generic "verify quality," it captures concrete failures: missing classes, centered Swiss titles, SVG text labels, image slot mismatch, object-position cropping, bottom navigation overlap, too-small font sizes, and stale placeholders. That is a strong pattern for turning repeated agent failures into guardrails.

The repo intentionally differentiates host environments. For example, Claude Code can ask structured questions, while Codex should use plain conversation and avoid assuming Claude-only tools. That kind of host-specific branch prevents portable skills from accidentally depending on one runtime.

## Strengths

- Excellent artifact-template pattern: two complete HTML runtimes let the agent produce editable, inspectable, browser-native decks without a separate build step.
- Strong domain workflow: intake, narrative rhythm, layout choice, theme choice, image generation, screenshot handling, validation, preview, and iteration are all covered.
- Swiss validator turns a subset of aesthetic rules into machine checks, especially registered layout IDs, SVG text traps, image slot binding, and dangerous S22 image placement.
- Progressive reference structure gives agents a natural context boundary: load Style A or Style B references only when needed, and load image/screenshot/map guidance only for those asset types.
- Asset handling is unusually specific. The repo defines target ratios, naming conventions, local image placement, slot attributes, screenshot backgrounds, and when to use `fit-contain` versus generated slot-filling images.
- Low-power mode is a useful runtime safety feature for presentation artifacts. It responds to reduced motion preference, persists a toggle, stops animation loops, and reveals content statically.
- Contribution workflow asks for generated HTML, screenshots, environment, and visual QA, which matches the artifact's actual failure modes.
- The recent commit history shows active refinement around font-size floors, weight ladders, screenshot framing, and bundled backgrounds, so the skill is maintaining operational lessons rather than remaining a one-shot prompt.

## Weaknesses

- Validation is narrow. `validate-swiss-deck.mjs` is useful but regex-based and Swiss-only; it does not parse DOM/CSS robustly, does not render the deck, does not inspect computed layout, and does not check console errors or screenshots.
- Style A has no equivalent validator. Its quality gates rely on prompts and manual browser inspection, even though missing classes, image overflow, and theme rhythm are known failure modes.
- Visual QA is manual. The docs require browser review, but the repo does not ship Playwright checks, viewport screenshots, overflow assertions, canvas nonblank checks, or a fixture deck suite.
- Runtime trust boundaries are thin. Generated decks can contain arbitrary HTML/JS, external fonts, Lucide CDN, jsDelivr fallback, and optional MapLibre/OpenStreetMap loading. There is no CSP guidance, dependency pinning policy beyond Motion's fallback URL, or secret/sensitive-data handling beyond screenshot redaction prompts.
- "Single HTML file" is only partly true. The template is one HTML file, but real decks commonly rely on local `images/`, Google Fonts, Lucide CDN, optional Motion CDN fallback, optional MapLibre, and non-vendored map tiles.
- `template-swiss.html` includes example cover and closing slides with `[必填]` placeholders inside the template body. That may help agents copy patterns, but it also increases the risk that a generated deck accidentally ships placeholder slides unless the agent deletes or fully replaces them.
- Some instruction drift exists. `references/components.md` still says slides must contain `data-theme`, while current templates mostly infer from classes. `layouts-swiss.md` contains historical P23/P24 sections and even routing tables for them, while the validator blocks those structures by default. The map component example uses small border radii even though Swiss rules elsewhere say no rounded corners.
- There is no structured manifest for layout IDs, image slots, recipes, or theme variables. The source of truth is prose plus HTML/CSS, so validators and agents can drift from the docs.
- The main prompt corpus is Chinese-heavy and long. That is fine for the original audience but makes cross-language reuse and selective context loading harder unless an agent has a disciplined retrieval workflow.

## Ideas To Steal

- Use a main `SKILL.md` as an orchestrator and keep detailed domain material in named reference files that map to phases: themes, layouts, assets, screenshots, maps, and checks.
- Encode domain constraints as registries plus validators. The Swiss S01-S22 registry and `data-layout` validator are a strong model for future design, documentation, database, or domain-specific coding skills.
- Add asset slot contracts to generated artifacts. `data-image-slot` is a small, reusable pattern that ties generation ratio, layout intent, and validation together.
- Treat screenshot preservation as a workflow, not an image prompt. Programmatic framing with reusable background assets should be the default when fidelity matters.
- Make real failure memory explicit. A P0/P1 checklist grounded in actual broken outputs is more useful than broad style advice.
- Separate generation from verification. The repo's best path is: choose layout, fill content, generate assets only after slot choice, run static checks, then visually preview.
- Include low-power and accessibility-minded runtime controls in rich artifacts. Long-running canvas/WebGL effects should have a toggle and a static fallback.
- Write host-specific instructions inside portable skills. Claude Code, Codex, Cursor, and plain chat have different tool surfaces; the skill should state how to adapt.
- Require contribution reports to include the generated artifact and screenshots. Visual systems cannot be debugged from prose alone.

## Do Not Copy

- Do not rely on regex checks as the final quality gate for visual artifacts. Use DOM parsing, browser rendering, console checks, screenshot receipts, and viewport overflow tests.
- Do not leave prompt docs, examples, templates, and validators as separate untyped sources of truth. Add a machine-readable layout/theme/slot manifest if adopting this pattern at scale.
- Do not ship placeholder example slides inside production seed templates unless the generator explicitly strips or replaces them.
- Do not call an artifact "single-file" if critical fonts, icons, maps, motion, or images depend on external or adjacent files without clear offline guarantees.
- Do not let generated HTML ingest sensitive screenshots without a stronger redaction and review policy.
- Do not copy the specific visual style wholesale. The reusable idea is constrained design systems plus artifact checks, not the IKB Swiss or editorial magazine aesthetic itself.
- Do not make custom-color prohibition universal. It works here because aesthetic stability is the product; other domains may need a different constraint boundary.

## Fit For Agentic Coding Lab

Fit is in-scope for `domain-specific-coding`. The repo is not a coding harness, but it is a strong example of how a coding agent can operate in a specialized visual domain by manipulating HTML templates, local assets, and validators.

Agentic Coding Lab should borrow the structure: bounded visual systems, reference files as context modules, explicit asset slots, generated-artifact verification, and failure-memory checklists. The lab version should add stronger machine verification: parse generated HTML, run Playwright across desktop/mobile viewports, check console errors, verify nav and low-power controls, assert no placeholders remain, inspect local image slot coverage, and save screenshots as review evidence.

The most transferable pattern is "domain skill as artifact factory." The user does not need a full PPT application or a custom runtime; the agent needs a repeatable workflow, reusable templates, slot contracts, and quality gates.

## Reviewed Paths

- `/tmp/myagents-research/op7418-guizang-ppt-skill/README.md`: Chinese install, use cases, Style A/B overview, workflow, image flow, cover generation, FAQ, and contribution notes.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/README.en.md`: English install and workflow mirror, platform support, Swiss validator summary, image and cover flow, FAQ, and roadmap.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/SKILL.md`: main skill trigger, intake flow, host adaptation, template copy rules, class preflight, layout selection, image handling, validation, preview, and design principles.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/assets/template.html`: Style A runtime, CSS classes, WebGL backgrounds, deck navigation, ESC overview, low-power toggle, Lucide, and Motion loading.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/assets/template-swiss.html`: Style B runtime, canvas-card layout system, Swiss class API, example cover/closing sections, WebGL grid, ASCII canvas field, navigation, low-power toggle, and Motion recipes.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/layouts.md`: Style A preflight, theme rhythm, image ratio rules, animation recipes, and layout skeleton catalog.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/layouts-swiss.md`: Swiss baseline, P0 alignment rules, layout diversity, image principles, S01-S22 skeletons, and disabled experimental layout notes.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/swiss-layout-lock.md`: registered layout table, S08 map extension, image slot rules, and forbidden Swiss structures.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/components.md`: Style A component catalog, image frame constraints, icon rules, and Motion usage.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/themes.md`: Style A theme presets and palette-change rules.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/themes-swiss.md`: Style B accent presets and no-mixing rules.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/image-prompts.md`: image type routing, ratio selection, Style A/B visual constraints, and screenshot redesign guidance.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/screenshot-framing.md`: screenshot-preserving treatment, semantic parameters, bundled background mapping, and when to redraw.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/swiss-map-component.md`: S08 MapLibre extension, static fallback, point/relation data contract, controls, and interaction isolation.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/references/checklist.md`: P0-P3 quality gates for layout lock, typography, images, nav safety, placeholders, and visual QA.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/scripts/validate-swiss-deck.mjs`: static validator implementation and rule coverage.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/CONTRIBUTING.md`: contribution workflow, visual QA expectations, and Swiss validator guidance.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/.github/pull_request_template.md`: PR checklist for screenshots, dense text slide, image slide, navigation, low-power mode, validator, and manual browser review.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/.github/ISSUE_TEMPLATE/bug_report.yml`: bug intake for prompt/source deck, generated HTML, screenshots, environment, and theme.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/.github/ISSUE_TEMPLATE/feature_request.yml`: feature intake for real deck-making problems and affected area.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/.github/ISSUE_TEMPLATE/question.yml`: usage/install/template question intake.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/LICENSE`: MIT license.
- Git metadata for commit `6bfa520b86ed5a3dffdac0a3323155e2b6f516b6`, recent log, branch, and remote.
- GitHub repository page for current star and issue/PR snapshot.

## Excluded Paths

- `/tmp/myagents-research/op7418-guizang-ppt-skill/.git/**`: VCS internals; commit SHA and recent log were captured separately.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/assets/motion.min.js`: minified third-party runtime; import path and fallback behavior were reviewed through templates, but the minified implementation was not audited.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/assets/screenshot-backgrounds/**/*.webp`: binary image assets; file presence, grouping, and intended usage were reviewed, but visual content was not individually inspected.
- `/tmp/myagents-research/op7418-guizang-ppt-skill/.github/ISSUE_TEMPLATE/config.yml`: issue-template config only; not relevant to execution or workflow design.
- Remote GitHub attachment preview images and README badges: presentation metadata, not part of the cloned execution path.
- External runtime sources for Google Fonts, Lucide, jsDelivr Motion fallback, MapLibre, and OpenStreetMap tiles: referenced dependency boundaries, but not vendored source in this repository.
- Generated deck outputs under user projects: none are checked in; templates and reference skeletons were reviewed instead.
