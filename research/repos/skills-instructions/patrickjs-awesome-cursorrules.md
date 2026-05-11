# PatrickJS/awesome-cursorrules

- URL: https://github.com/PatrickJS/awesome-cursorrules
- Category: skills-instructions
- Stars snapshot: 39,463 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 5c9165bddbfab4ebf8284453e70c15803d219994
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a large Cursor-rule corpus and taxonomy for framework-specific agent instructions, but adopt as a pattern mine only; the repo has no active validation pipeline, uneven rule quality, stale links, and token-heavy monolithic files.

## Why It Matters

`awesome-cursorrules` is a broad public collection of checked-in AI coding instructions for Cursor. It matters because it shows how many teams and contributors encode project behavior as portable `.cursorrules` files or newer `.mdc` rule fragments: framework conventions, file layout, data-fetching patterns, security rules, testing expectations, and domain-specific API contracts.

For Agentic Coding Lab, the reusable insight is not "copy this whole corpus." The value is the artifact shape: one folder per target stack, a README index for discovery, optional per-rule README provenance, generated or source `.mdc` fragments with `description`, `globs`, and `alwaysApply`, and assembled `.cursorrules` files for older Cursor root-level use.

## What It Is

The repository is a static awesome-list plus rule corpus. The reviewed checkout contains 189 directories under `rules/`, 186 canonical `rules/**/.cursorrules` files, 931 `rules/**/*.mdc` files, 145 per-rule READMEs, one `.cursorrules.txt` Salesforce variant, one Rails `.mdx` file, and 21 extra flat `rules-new/*.mdc` files. The root `README.md` indexes rules by Frontend, Backend, Mobile, CSS, State Management, Database/API, Testing, Hosting, Build Tools, Language-Specific, Other, Documentation, and Utilities.

The execution path is manual. Users browse the README, copy a chosen `.cursorrules` file to their project root, then customize it. A second README path suggests installing a VS Code/Cursor extension that can add `.cursorrules` from the list. There is no local package, loader, installer, schema validator, or active CI in the checkout.

The corpus includes both broad framework packs, such as Next.js, React, Vue, FastAPI, Laravel, Flutter, and Solidity, and narrow domain packs, such as FormEngine form schemas, Momen GraphQL BaaS, Helium MCP, Netlify functions, Go Temporal DSL, Alpha Skills quant research, Chrome extensions, WordPress, Salesforce Apex, and a Unity Ringcon tower-defense project.

## Research Themes

- Token efficiency: Mixed. `rules-new/*.mdc` shows compact, glob-scoped rules, but many old `.cursorrules` files are large monoliths copied wholesale into context. There is no retrieval policy, ranking, or section extraction, so users can easily over-load Cursor with unrelated guidance.
- Context control: Moderate to strong as a pattern. MDC frontmatter with `description`, `globs`, and occasional `alwaysApply` enables file-scoped instruction loading. The `ProjectDocs/Build_Notes` and `ProjectDocs/contexts` rules are good examples of durable context files with explicit update policy.
- Sub-agent / multi-agent: Weak in implementation. The repo is Cursor-rule oriented and has no subagent runtime. Some entries reference MCP tools or "AI agents" as application concepts, but not as agent orchestration inside the repo.
- Domain-specific workflow: Strong. The best packs encode precise stack behavior: TanStack Query hydration, Temporal DSL bindings, Momen actionflows, FormEngine schema invariants, WordPress escaping and nonces, Solana Anchor account validation, Netlify compute placement, and Helium MCP tool selection.
- Error prevention: Strong in individual packs, weak in enforcement. Good rules cover dependency discipline, typed errors, webhook signatures, database field selection, SQL/query safety, `wp_verify_nonce`, capability checks, RLS, idempotency, and "do not invent" behavior. Nothing in the repo enforces these rules beyond prompt text.
- Self-learning / memory: Limited. The repo is a shared rule memory bank, not a learning system. It contains durable context-file patterns but no feedback loop, telemetry, promotion workflow, or project-specific memory store.
- Popular skills: High-signal local candidates include `rules-new/typescript.mdc`, `rules-new/nextjs-tanstack-query.mdc`, `rules-new/react-tanstack-router-query.mdc`, `rules/cursor-rules-pack-v2-cursorrules-prompt-file/.cursorrules`, `rules/nextjs-supabase-shadcn-pwa-cursorrules-prompt-file/context-files-rules.mdc`, `rules/github-code-quality-cursorrules-prompt-file/*`, `rules/react-formengine-ai-form-builder-cursorrules-prompt-file/.cursorrules`, `rules/helium-mcp-cursorrules-prompt-file/.cursorrules`, `rules/momen-cursurrules-prompt-file/.cursorrules`, and `rules/go-temporal-dsl-prompt-file/*`.

## Core Execution Path

The root README is the main discovery surface:

1. A user scans category lists in `README.md`.
2. The user chooses a rule folder such as `nextjs-tanstack-query-cursorrules-prompt-file`.
3. The user copies that folder's `.cursorrules` file to a target project root.
4. Cursor appends the `.cursorrules` content to the global "Rules for AI" behavior for that project.
5. For newer MDC-compatible usage, a user can copy individual `.mdc` fragments into `.cursor/rules/` so Cursor can apply rules by glob, description, or `alwaysApply`.
6. Optional per-rule READMEs explain provenance and intended use, but most are descriptive, not executable.

There is a second implicit execution path in source-style packs: contributors keep topic-specific `.mdc` files beside an assembled `.cursorrules` file. For example, Next.js/TanStack Query exists as a concise `rules-new/nextjs-tanstack-query.mdc` and as a richer `rules/nextjs-tanstack-query-cursorrules-prompt-file/.cursorrules`. The assembled files are better for copy-paste, while `.mdc` fragments are better for selective loading.

The repository's own contribution path is documented in the root `.cursorrules`: add a folder, name it with `technology-focus-cursorrules-prompt-file`, add `.cursorrules`, optionally add README, and update the root README category. That governance file is partly stale because it says to place `.cursorrules` directly in `rules/`, while the actual corpus uses one subdirectory per pack.

## Architecture

The architecture is a static corpus with light metadata:

- `README.md`: awesome-list index, category taxonomy, usage instructions, contribution steps, sponsorship sections, and license.
- Root `.cursorrules`: maintainer rules for this repository's README structure, naming conventions, categories, and contribution style.
- `rules/<pack>/`: one rule pack per stack/domain, usually containing `.cursorrules`, optional source `.mdc` fragments, and often a README.
- `rules-new/*.mdc`: flat, newer Cursor MDC rules for common languages and frameworks such as TypeScript, React, Vue, Svelte, Next.js, FastAPI, Rust/Solana, database, Tailwind, Gitflow, clean-code, and code quality.
- `.github/workflows/main.yml`: commented-out `awesome-lint` workflow; no active CI.
- `.agents/` and `.codex/`: empty directories in this checkout.
- PNG logos and sponsorship images: README visual assets only.

The MDC files are the most structurally reusable part. In the reviewed checkout, 951 of 952 MDC files include `description` near the top, 942 include `globs`, and 23 include `alwaysApply` (`7` true, `16` false). This demonstrates a practical convention for progressive, file-scoped agent instructions without requiring a custom parser.

## Design Choices

The main design choice is lowest-friction portability. A `.cursorrules` file is plain text, easy to copy, and host-specific enough for Cursor users. This helped the corpus grow quickly, but it also means quality, freshness, and scope are managed socially rather than by tooling.

The category taxonomy mirrors developer intent rather than package structure. README sections group many overlapping frameworks and domains so users can browse by target task. The tradeoff is duplication: Next.js appears in many variants, React appears across state, frontend, and full-stack packs, and TypeScript conventions repeat heavily.

Several packs show a stronger pattern: decompose a large behavior contract into small `.mdc` files with frontmatter globs. Examples include `typescript-shadcn-ui-nextjs`, `nextjs-supabase-shadcn-pwa`, `go-temporal-dsl`, `momen`, `github-code-quality`, and `python-django-best-practices`. That gives maintainers a path to selective inclusion and future linting.

Domain packs are often much more valuable than generic style packs. FormEngine gives schema invariants and exact component-name corrections; Momen gives endpoint shapes, GraphQL operation conventions, actionflow state transitions, and asset upload rules; Helium MCP maps user intent to concrete MCP tools and rate-limit behavior; Go Temporal DSL defines actual structs, bindings, sequential/parallel semantics, and activity contracts.

Some rules are too generic to be directly useful. The `rules-new/database.mdc` file repeatedly says "use proper" design, migrations, queries, and security without naming checkable practices. Those should be treated as topic placeholders, not high-quality reusable instructions.

## Strengths

The corpus is broad and easy to mine. It covers mainstream web stacks, mobile, tests, hosting, APIs, databases, smart contracts, CMS work, browser extensions, form builders, MCP tool usage, and niche domain workflows.

MDC frontmatter is a good reusable convention. `description` gives discovery text, `globs` limits context to relevant files, and `alwaysApply` reserves always-on behavior for rare cases.

The best files encode concrete "never do this" guardrails. Examples include no `graphql-ws` for Momen, no unescaped WordPress output, no direct WordPress core edits, no raw webhook processing before signature verification, no direct client DB full-record exposure, no `useEffect` for data fetching where loaders or query hooks belong, and no premium FormEngine components unless requested.

Several packs turn project context into durable artifacts. The Next.js/Supabase/Shadcn PWA pack requires task-specific build notes and stable project context files, with append-only plan updates and clear rationale for context changes.

The repo includes useful MCP instruction style. Helium MCP does not just say "use MCP"; it maps news, bias, ticker, options, strategies, and memes questions to specific tool names, call minimization, rate-limit behavior, and response shape.

There are good examples of framework-specific agent instructions that include runnable code patterns: TanStack Query hydration, TanStack Router loader/query integration, Next.js Server Actions as mutation functions, Netlify function signatures, and Temporal workflow DSL execution.

## Weaknesses

There is no active validation pipeline. `.github/workflows/main.yml` is fully commented out, so broken links, missing files, duplicate categories, malformed frontmatter, and stale examples are not caught in CI.

The README index is already inconsistent with the corpus. In this commit, README has 179 local `rules/` links; two are missing (`drupal-11-cursorrules-promt-file` typo and `meta-prompt-cursorrules-prompt-file`). Thirteen actual `.cursorrules` files are not linked from the README, including `aspnet-abp`, `flutter-riverpod`, `nextjs-supabase-shadcn-pwa`, `temporal-python`, and `xian-smart-contracts`.

Three rule directories have no canonical `.cursorrules`: Salesforce uses `.cursorrules.txt`, Scala Kafka only has `.mdc` fragments, and Swift UIKit has nonstandard `.cursorrules-mvvm-rxswift` files. These may be usable, but they violate the README's default copy path.

Quality is uneven. Some rules are precise and current; others are generic, repetitive, or contradictory. The root `.cursorrules` says each `.cursorrules` should be placed directly in `rules/`, but the actual organization is subdirectories. Some READMEs describe upstream `.cursor/rules/` trees that are not exactly present in the mirrored folder.

Token discipline is not enforced. A user copying multiple large `.cursorrules` files would load overlapping framework instructions and conflicting preferences. There is no deduplication, compatibility matrix, or "choose one" guidance for similar Next.js/React/TypeScript packs.

Security-sensitive examples need review before use. Some packs tell users to provide service credentials or project credentials to an AI assistant. The rule intent may be schema discovery, but a team baseline should replace that with scoped MCP, test fixtures, or explicit secret-handling policy.

## Ideas To Steal

Use a two-tier rule format: compact `.mdc` fragments with `description`, `globs`, and `alwaysApply` for selective loading, plus optional assembled `.cursorrules` for legacy Cursor users.

Create a small rule-pack schema and lint it: required README entry, existing target path, valid frontmatter, no empty `globs` unless intentional, no stale `.cursorrules.txt` variants, and no broken local links.

Write domain rules as concrete contracts, not generic best-practice prose. Good rules name exact APIs, forbidden alternatives, data shapes, state transitions, verification commands, and response formats.

Adopt the build-notes/context-files pattern: separate stable project context from per-task progress notes, make context changes rare and rationale-backed, and require append-only task-note evolution.

Use tool-selection guides for MCP packs. Helium MCP is a strong model: map user intents to tool names, specify when not to call tools, handle rate limits, and define compact answer shape.

Add "do not copy blindly" metadata to broad packs. For overlapping framework packs, include target versions, assumptions, known conflicts, and a "compatible with" list.

Build a local high-signal subset instead of importing the catalog: TypeScript strictness, Next.js/TanStack Query hydration, error handling, dependency discipline, webhook/database safety, context files, and one or two domain packs.

## Do Not Copy

Do not copy the entire README corpus into a project. It will create context bloat, overlapping instructions, and likely conflicts across framework variants.

Do not trust `.cursorrules` files as enforceable safety. Pair critical rules with tests, linters, hooks, MCP permissioning, or review gates.

Do not import generic "use proper X" rules without rewriting them into checkable behaviors and examples.

Do not copy sponsor images, logos, UI-only README assets, or awesome-list boilerplate into Agentic Coding Lab artifacts.

Do not ask users to paste production credentials into an AI session as a default workflow. Use scoped tokens, local config, MCP permission prompts, or mock schemas.

Do not assume README links and file names are correct. The reviewed commit has broken and unindexed rule paths.

## Fit For Agentic Coding Lab

Fit is in-scope as a skills-instructions pattern source. The repository is not a runtime, eval harness, or agent framework, but it is a large example of how developers package coding-agent behavior into portable files.

Best adoption path is selective extraction. Agentic Coding Lab should borrow the MDC metadata convention, build a linted local rule-pack index, and adapt the strongest domain contracts into smaller skills or project rules. The corpus is especially useful for discovering recurring rule topics: framework defaults, context files, test placement, error handling, security invariants, dependency discipline, tool selection, and domain-specific schemas.

The repo should remain a candidate mine, not a dependency. Any imported rule needs owner review, version tagging, conflict checking, and verification hooks before it becomes a durable lab artifact.

## Reviewed Paths

- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/README.md`: root index, category taxonomy, usage paths, contribution steps, and broken/unindexed link checks.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/.cursorrules`: maintainer rules for adding and organizing rule packs.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/contributing.md`: generic awesome-list contribution flow.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/.github/workflows/main.yml`: commented-out lint workflow.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules-new/`: all 21 flat MDC files listed and representative files read (`typescript`, `nextjs-tanstack-query`, `react-tanstack-router-query`, `codequality`, `clean-code`, `gitflow`, `database`, `python`, `rust`).
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/cursor-rules-pack-v2-cursorrules-prompt-file/.cursorrules` and `README.md`: dependency, error, webhook, state, fetch, and database safety sample.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/github-code-quality-cursorrules-prompt-file/.cursorrules`, `README.md`, and MDC fragments: regex-style behavior rules and generated per-rule files.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/nextjs-supabase-shadcn-pwa-cursorrules-prompt-file/.cursorrules`, `context-files-rules.mdc`, and `build-notes-file-rules.mdc`: context-control and build-note workflow.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/nextjs-tanstack-query-cursorrules-prompt-file/.cursorrules` and `README.md`: Server Component hydration, query options, Server Actions, and optimistic updates.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/react-tanstack-router-query-cursorrules-prompt-file/.cursorrules`: Router loader plus Query cache pattern.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/go-temporal-dsl-prompt-file/index.mdc`, `workflow.mdc`, and related file listing: DSL structure, bindings, activities, sequential/parallel execution.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/helium-mcp-cursorrules-prompt-file/.cursorrules`: MCP setup, tool-selection guide, rate-limit and citation behavior.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/react-formengine-ai-form-builder-cursorrules-prompt-file/.cursorrules`: schema invariants, component naming, validation keys, output shape.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/momen-cursurrules-prompt-file/.cursorrules`, `README.md`, and file listing: GraphQL BaaS, actionflows, AI agents, Stripe, binary asset, MCP schema rules.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/netlify-official-cursorrules-prompt-file/.cursorrules`: provider-context override pattern and Netlify compute rules.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/wordpress-claude-stack/.cursorrules` and `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/vue-claude-stack/.cursorrules`: compact framework-specific "Full AI Stack" entries, with note that only `.cursorrules` is present locally.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/alpha-skills-quant-factor-research/.cursorrules`: skill-menu style domain wrapper linking to external full definitions.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/rules/salesforce-apex-cursorrules-prompt-file/.cursorrules.txt`, `rules/scala-kafka-cursorrules-prompt-file/*.mdc`, and `rules/swift-uikit-cursorrules-prompt-file/*`: noncanonical rule path examples.
- Directory-level counts and structure review for all checked-in `rules/**`, `rules-new/**`, `.mdc`, `.cursorrules`, README, image, and root metadata files.

## Excluded Paths

- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/.git/`: VCS internals; commit SHA captured separately.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/.agents/` and `/tmp/myagents-research/PatrickJS-awesome-cursorrules/.codex/`: empty directories in this checkout; no agent behavior to review.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/*.png`: README logos and sponsorship assets; UI-only/binary, unrelated to rule semantics.
- `/tmp/myagents-research/PatrickJS-awesome-cursorrules/LICENSE`, `.gitignore`, `.github/FUNDING.yml`, and `code-of-conduct.md`: provenance/community metadata; checked lightly but not analyzed as reusable agent instruction design.
- Individual rule packs not named in Reviewed Paths: included in corpus counts and path/link checks, but not read line-by-line because 186 `.cursorrules` and 952 `.mdc` files would be a separate exhaustive audit.
- External upstream repos and websites linked from rule READMEs, including alpha-skills, Helium MCP, FormEngine docs, Momen docs, and paid Cursor Rules Pack pages: noted as provenance or dependency surfaces, but outside the cloned corpus.
- Remote README images and sponsorship links: marketing/UI-only and not required for agent-rule reuse.
