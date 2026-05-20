# antfu/skills

- URL: https://github.com/antfu/skills
- Category: domain-specific-coding
- Stars snapshot: 5,007 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 50deaeb269d80d92db7a2c5a677290309ae307fc
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for frontend and tooling skill collections, especially Vite, Vue, Nuxt, pnpm, Vitest, tsdown, Turborepo, Slidev, and VueUse workflows. Best reusable ideas are submodule-backed provenance, compact trigger files, progressive references, manual plus generated plus vendored skill lanes, and domain-specific verification snippets. Biggest risks are generated-skill drift from checked-out source submodules, no CI/test harness, an unfinished `nitro` source lane, and uneven metadata/reference conventions across vendored skills.

## Why It Matters

`antfu/skills` packages a frontend maintainer's working preferences and ecosystem knowledge as installable agent skills. It is useful because it is not a broad prompt dump. It is a curated domain pack for a specific stack: Vue, Nuxt, Vite, VitePress, Vitest, UnoCSS, pnpm, Pinia, tsdown, Turborepo, Slidev, VueUse, and web design guidance.

For Agentic Coding Lab, the repo is a good study in skill collection design. It shows how to mix hand-written preferences, synthesized skills from upstream docs, and vendored official skills while keeping each skill portable as plain Markdown. It also exposes the maintenance failure modes that appear when generated instructions, source submodules, and vendored artifacts are kept in one repo without a verification harness.

## What It Is

`antfu/skills` is an Agent Skills collection intended to be installed with the `skills` CLI, for example `pnpx skills add antfu/skills --skill='*'`. The repository has 17 checked-in skill directories:

- Hand-maintained: `antfu`.
- Generated from source documentation: `vue`, `nuxt`, `pinia`, `pnpm`, `unocss`, `vite`, `vitepress`, and `vitest`.
- Vendored/synced: `slidev`, `tsdown`, `turborepo`, `vueuse-functions`, `vue-best-practices`, `vue-router-best-practices`, `vue-testing-best-practices`, and `web-design-guidelines`.

The repo also contains `sources/` and `vendor/` git submodules, generation instructions under `instructions/`, a canonical source map in `meta.ts`, and a TypeScript CLI in `scripts/cli.ts` for submodule init, vendor sync, update checks, and cleanup. There is no application runtime, MCP server, loader, public eval suite, or root CI workflow in the reviewed tree.

## Research Themes

- Token efficiency: Strong pattern in generated and many vendored skills. `SKILL.md` usually stays as a small index with tables pointing to topic files, while reference bodies are loaded only when needed. The large exception is catalog-style skills such as `vueuse-functions` and `turborepo`, whose top-level files are useful but heavy.
- Context control: Strong at package layout level. Skills route by frontmatter descriptions, topic tables, `references/` files, and sometimes command wrappers. `vue-best-practices` requires core references for Vue work, while `web-design-guidelines` fetches current remote rules at use time.
- Sub-agent / multi-agent: Weak. The repo does not define sub-agent orchestration or multi-agent handoffs. Its reuse model is skill selection plus progressive reference loading.
- Domain-specific workflow: Very strong for frontend and JavaScript tooling. The skills encode concrete stack choices, file conventions, config patterns, SSR pitfalls, library bundling, test setup, monorepo task orchestration, package management, Slidev export flows, and VueUse composable selection.
- Error prevention: Moderate to strong inside individual skills. Examples include Nuxt SSR leak/hydration warnings, Vue testing anti-patterns, Turborepo task-boundary rules, tsdown package validation, API snapshot/stale-build guidance, and Playwright/browser-runner recommendations.
- Self-learning / memory: None. The repo is curated reusable memory, but it does not learn from executions or record user/project feedback.
- Popular skills: Most relevant for this category are `antfu`, `vue`, `nuxt`, `vite`, `vitest`, `pnpm`, `tsdown`, `turborepo`, `vueuse-functions`, `vue-best-practices`, `vue-testing-best-practices`, `slidev`, and `web-design-guidelines`.

## Core Execution Path

For consumption, the path is host-driven:

1. User installs selected skills from `antfu/skills` through the `skills` CLI.
2. The agent host discovers each `skills/<name>/SKILL.md` by frontmatter `name`, `description`, and optional metadata.
3. The selected `SKILL.md` gives preferences, trigger scope, quick commands, and a reference table.
4. The agent loads only the reference files needed for the task, then applies the guidance in the target project.

For repository maintenance, there are three lanes:

1. Manual skills: `skills/antfu` is edited directly and captures Anthony Fu's preferences for code organization, pnpm, ESLint, Vitest, app development, libraries, and monorepos.
2. Generated skills: `meta.ts` lists upstream repositories under `submodules`; `AGENTS.md` tells the agent to read `sources/{project}/docs/`, apply `instructions/{project}.md`, synthesize concise reference files, create `SKILL.md`, and record `GENERATION.md`.
3. Vendored skills: `scripts/cli.ts sync` updates git submodules, copies selected `vendor/{project}/skills/{sourceSkill}` directories into `skills/{outputSkill}`, copies licenses, and writes `SYNC.md` with the vendor SHA.

The CLI also supports `init`, `check`, and `cleanup`. `check` reports whether submodules are behind upstream. It does not check whether generated skills match the currently checked-out submodule SHA, which matters because all eight generated skills are currently generated from older SHAs than the source submodules in the reviewed checkout.

## Architecture

Key files and directories:

- `README.md`: install instructions, skill catalog, source types, and rationale for shareable/on-demand skills.
- `AGENTS.md`: generation workflow, source types, file formats, writing guidelines, and update procedure.
- `meta.ts`: canonical list of generated-source repos, vendored repos, output skill mappings, and manual skill names.
- `scripts/cli.ts`: TypeScript maintenance CLI for submodules, vendor sync, update checks, and cleanup.
- `instructions/*.md`: project-specific preference overlays for generated skills, such as Vue Composition API, Vite ESM config, Nuxt Vite preference, and Vitest mocking style.
- `sources/`: upstream documentation repos as git submodules.
- `vendor/`: upstream skill repos as git submodules.
- `skills/`: installable output artifacts with `SKILL.md`, optional `references/` or `reference/`, optional `GENERATION.md`, optional `SYNC.md`, optional `LICENSE.md`, and one `command/` file for Turborepo.

The root package is small: `package.json` has `lint`, `start`, and `prepare`. It uses pnpm, ESLint, lint-staged, and simple-git-hooks. No `.github/workflows` directory exists in the reviewed checkout.

## Design Choices

The main design choice is a curated stack pack rather than a general marketplace. The collection is explicitly tilted toward modern TypeScript, ESM, Vue Composition API, Vite/Nuxt, pnpm, Vitest, and Anthony Fu's project conventions.

The second choice is three-source composition. Hand-written preferences handle taste and local conventions. Generated skills turn official docs into agent-oriented references. Vendored skills preserve upstream-owned skill packs and avoid manual edits by copying them from submodules.

The third choice is submodule-backed provenance. `GENERATION.md` and `SYNC.md` record source SHAs, and `.gitmodules` keeps upstream docs/skills in the repo. This is stronger than copying markdown with no source trail, but it needs validation to prevent drift.

The fourth choice is progressive disclosure by default. Most generated `SKILL.md` files are indexes with a short preference section and links to references such as `core-config`, `best-practices-ssr`, `features-catalogs`, or `advanced-projects`.

The fifth choice is letting individual skills define their own tool boundaries. `vueuse-functions` labels composables as `AUTO`, `EXTERNAL`, or `EXPLICIT_ONLY`; `web-design-guidelines` instructs runtime WebFetch; `turborepo` has a command wrapper and strict task-creation rules; `slidev` names export prerequisites and verification.

## Strengths

- Clear frontend/dev workflow coverage. The selected stack maps to real repeated coding-agent tasks: create Vue/Nuxt components, configure Vite, test with Vitest/Playwright, manage pnpm workspaces, bundle libraries, and configure monorepo tasks.
- Good packaging template for skill collections. `meta.ts`, `sources/`, `vendor/`, `skills/`, `GENERATION.md`, and `SYNC.md` form a reusable artifact layout.
- Strong progressive disclosure in generated skills. The top-level files route to smaller references instead of loading entire framework docs up front.
- Useful preference overlays. `instructions/vue.md`, `instructions/vite.md`, `instructions/nuxt.md`, and `instructions/vitest.md` show how to bias official-doc synthesis toward a maintainer's actual stack without burying that bias in generated prose.
- Vendored skill sync is deterministic. The script copies selected skills, licenses, and source SHAs, and the reviewed vendored `SYNC.md` SHAs match the checked-out vendor submodule SHAs.
- Several skills encode concrete verification patterns: API snapshots and stale-build gates for libraries, Playwright for E2E, Vitest browser mode for CSS/DOM assertions, Slidev export checks, and Turborepo cache/debug checks.
- Tool-boundary vocabulary is reusable. `AUTO` versus `EXTERNAL` versus `EXPLICIT_ONLY` in `vueuse-functions` is a compact pattern for preventing agents from adding unnecessary dependencies.

## Weaknesses

- The README explicitly describes the project as a proof of concept and says skill performance has not been fully tested.
- Generated skills are stale relative to checked-out source submodules. For example, `skills/vite/GENERATION.md` records `c47015eba4f0de255218c35769628d87152216ca`, but `sources/vite` is checked out at `3d69d3e05bcaab6efe7c3ec8e78dcd6632d0f0c6`. The same mismatch appears for `vue`, `nuxt`, `pinia`, `pnpm`, `unocss`, `vitepress`, and `vitest`.
- `meta.ts` and `.gitmodules` include `nitro` under generated sources, but there is no `skills/nitro` output and no README row for Nitro. This suggests the canonical source list can get ahead of published artifacts.
- No public CI workflow or test harness validates skill shape, links, source SHA freshness, README/catalog consistency, generated examples, or script behavior.
- Generated-skill updates rely on an agent following `AGENTS.md` manually. The maintenance CLI can sync vendored skills, but it does not regenerate generated skills or fail when `GENERATION.md` is behind `sources/*`.
- Metadata and reference conventions are uneven across vendored skills. Some use `references/`, others use `reference/`; some frontmatter uses nested `metadata`, others use top-level `version`, `license`, or `author`.
- Some top-level skills are very large indexes. `vueuse-functions` and `turborepo` are valuable but can consume context quickly if loaded wholesale.
- Tool and permission boundaries are mostly prose. There is no host-enforced approval model for remote fetches, dependency installation, browser operations, package publishing, or CI-affecting config changes.

## Ideas To Steal

- Use a three-lane skill source model: `manual` for local conventions, `generated` for upstream docs, and `vendor` for external skill packs.
- Keep a canonical `meta.ts` or equivalent manifest that maps source repos to output skill names. Add validation so every manifest entry has an output or an explicit disabled state.
- Record source provenance beside every generated or synced skill with source path, git SHA, and date.
- Split generated skills into a small `SKILL.md` router plus one-concept reference files. Keep frontmatter descriptions specific enough for automatic skill selection.
- Add tiny preference overlays per domain before synthesis. This lets generated docs carry local stack policy, such as TypeScript, ESM, Composition API, or Vitest mocking choices.
- Reuse the `AUTO` / `EXTERNAL` / `EXPLICIT_ONLY` invocation policy for libraries with many optional helpers.
- Add explicit verification snippets to domain references: run build, update API snapshots, check browser output, run affected monorepo tasks, confirm generated files exist, or verify SSR-safe state.
- Use vendored skill syncing only for artifacts owned upstream, and make local modifications happen upstream instead of mutating copied outputs.

## Do Not Copy

- Do not rely on `GENERATION.md` as passive provenance only. Add a freshness check that compares each generated skill SHA to the current submodule SHA or an intentionally pinned source ref.
- Do not let a canonical source manifest contain unpublished outputs without a documented status field.
- Do not ship a domain skill collection without CI for markdown links, frontmatter shape, source freshness, and command smoke tests.
- Do not make every skill a large table. For huge APIs such as VueUse, add a smaller router layer or generated index chunks by category.
- Do not mix `reference/` and `references/` if downstream tooling expects one convention.
- Do not depend on remote-fetch skills for reproducible audits unless the fetched version, URL, and date are captured in the produced artifact.
- Do not copy long upstream docs into durable prompts. Keep the synthesis pattern, but require source links and concise agent-oriented examples.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`. The repo is a practical example of turning a frontend maintainer's stack knowledge into reusable skill artifacts. It should be mined for collection packaging, context control, provenance files, and reusable skill-generation workflow rather than copied as a production-ready harness.

Best adoption candidates:

- A repo-local skill collection template with `meta.ts`, `sources/`, `vendor/`, `skills/`, and per-skill provenance files.
- A generated-skill freshness test that fails when `GENERATION.md` does not match the intended source ref.
- A domain preference overlay file for each generated skill.
- A library/helper invocation policy table to avoid unnecessary dependencies.
- A standard verification section for each skill family: frontend render, unit test, E2E, package build, API snapshot, monorepo task, or deploy preview.

Less direct fits:

- Anthony Fu's exact preferences are stack-specific. Reuse the preference-overlay mechanism, not every preference.
- The current maintenance CLI is useful for submodules and vendor sync, but generated skill production still needs a more deterministic harness before it becomes a lab baseline.

## Reviewed Paths

- `/tmp/myagents-research/antfu-skills/README.md`: install flow, catalog, source types, proof-of-concept note, and skills-versus-AGENTS rationale.
- `/tmp/myagents-research/antfu-skills/AGENTS.md`: generation instructions, source lanes, file formats, writing guidelines, and update procedure.
- `/tmp/myagents-research/antfu-skills/meta.ts`: submodule, vendor, and manual skill registry.
- `/tmp/myagents-research/antfu-skills/scripts/cli.ts`: init, sync, check, cleanup, vendor copy, license copy, and provenance writing.
- `/tmp/myagents-research/antfu-skills/package.json`: scripts, pnpm version, hooks, lint-staged, and dev dependencies.
- `/tmp/myagents-research/antfu-skills/.gitmodules`: source and vendor submodule mapping.
- `/tmp/myagents-research/antfu-skills/instructions/*.md`: project-specific overlays for generated skills.
- `/tmp/myagents-research/antfu-skills/skills/antfu/SKILL.md` and `skills/antfu/references/*.md`: manual preference skill, setup, app development, library development, monorepo, and ESLint guidance.
- `/tmp/myagents-research/antfu-skills/skills/vue/SKILL.md`, `skills/vite/SKILL.md`, `skills/nuxt/SKILL.md`, `skills/pnpm/SKILL.md`, `skills/vitest/SKILL.md`, and selected references: generated frontend/tooling skill structure and examples.
- `/tmp/myagents-research/antfu-skills/skills/*/GENERATION.md`: generated skill provenance files and source SHAs.
- `/tmp/myagents-research/antfu-skills/skills/*/SYNC.md`: vendored skill provenance files and vendor SHAs.
- `/tmp/myagents-research/antfu-skills/skills/tsdown/SKILL.md` and selected `references/`: library bundling and CI-aware package validation patterns.
- `/tmp/myagents-research/antfu-skills/skills/turborepo/SKILL.md` and `skills/turborepo/command/turborepo.md`: command wrapper, monorepo task boundaries, cache, CI, and filtering patterns.
- `/tmp/myagents-research/antfu-skills/skills/vueuse-functions/SKILL.md`: large API routing table and invocation policy labels.
- `/tmp/myagents-research/antfu-skills/skills/vue-best-practices/SKILL.md`, `skills/vue-testing-best-practices/SKILL.md`, and selected `reference/` files: component workflow, testing anti-patterns, Playwright, and browser-runner guidance.
- `/tmp/myagents-research/antfu-skills/skills/slidev/SKILL.md`: presentation workflow, export prerequisites, and verification.
- `/tmp/myagents-research/antfu-skills/skills/web-design-guidelines/SKILL.md`: runtime remote-guideline fetch pattern.
- Submodule status for `sources/*` and `vendor/*`: compared generated and synced provenance against checked-out source/vendor SHAs.

## Excluded Paths

- `/tmp/myagents-research/antfu-skills/.git/`: VCS internals; commit and submodule SHAs were captured separately.
- Full upstream source repositories under `sources/`: sampled only for submodule status and generation provenance because the review target was skill design, not upstream framework implementation.
- Most vendored upstream repository internals under `vendor/`: sampled through copied skill outputs and sync metadata; exhaustive vendor-source review belongs to each upstream repo.
- `pnpm-lock.yaml`: not useful for domain skill design beyond confirming package-manager choice.
- Full prompt/reference bodies for large skills such as `vueuse-functions`, `turborepo`, `slidev`, `tsdown`, and Vue best practices: sampled representative sections to avoid reproducing long prompt bodies verbatim.
- Live installation through `pnpx skills add`: not executed because repository packaging and checked-in artifacts were sufficient for this review.
- External docs linked by references, except the GitHub repository page and GitHub REST metadata: reviewed focus was the checked-in skill package and current repo metadata.
