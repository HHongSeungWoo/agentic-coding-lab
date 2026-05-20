# twostraws/SwiftUI-Agent-Skill

- URL: https://github.com/twostraws/SwiftUI-Agent-Skill
- Category: domain-specific-coding
- Stars snapshot: 3,928 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: be297ff80dddec529af1f9b1f1f114aab6c9d11c
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong compact example of a domain-specific coding skill. Best reusable patterns are narrow SwiftUI issue targeting, small reference shards, explicit partial-review loading, concrete file/line output format, cross-agent packaging, and domain-specific verification prompts. Main gaps are no executable checks, no tests/CI, no structured rule metadata, no docs/version validation, and some package version drift between install surfaces.

## Why It Matters

This repo is useful because it shows a lightweight alternative to large rule packs: one short `SKILL.md`, nine focused references, and agent-specific metadata are enough to steer a coding agent toward modern SwiftUI behavior. The skill focuses on mistakes LLMs often make in Apple-platform code: obsolete APIs, UIKit leakage, fragile data flow, navigation mistakes, inaccessible controls, unnecessary view recomputation, old concurrency idioms, and weak project hygiene.

For Agentic Coding Lab, the repo is valuable less as an execution harness and more as a domain skill pattern. It shows how expert platform judgment can be split into small topical files that agents load only when needed, with enough code examples to shape fixes but not so much prose that the skill becomes a prompt dump.

## What It Is

`twostraws/SwiftUI-Agent-Skill` packages "SwiftUI Pro", an Agent Skills-format review skill for Claude Code, Codex, Gemini, Cursor, and related coding assistants. The top-level README documents install and invocation paths. The runtime skill lives under `swiftui-pro/` with a `SKILL.md`, `references/`, assets, Claude plugin metadata, and an OpenAI agent manifest.

The core skill reviews Swift and SwiftUI code for correctness, modern API use, maintainability, accessibility, performance, and project conventions. It assumes new SwiftUI projects target iOS 26 and Swift 6.2 or later, prefers SwiftUI over UIKit, avoids third-party dependencies unless the user asks, and reports only genuine issues. A nested `swiftui-pro/skills/swiftui-pro/` copy exists for Claude plugin packaging and points its references back to the shared `swiftui-pro/references/` directory through a tracked symlink.

## Research Themes

- Token efficiency: Good. `SKILL.md` is compact and delegates detail to nine short reference files totaling 288 lines. It explicitly says partial reviews should load only relevant references. README contribution guidance tells authors to keep Markdown concise and avoid rules LLMs already know.
- Context control: Good for a review checklist, weak for automated scoping. The review process orders topical passes and maps each pass to one reference file, but there is no scanner, file selector, rule registry, or project-target detector.
- Sub-agent / multi-agent: None. The skill is designed for one agent doing a review, with no fan-out, manifest, sub-agent brief, output collector, or merge protocol.
- Domain-specific workflow: Strong. Rules cover modern SwiftUI API migration, Observation-based state, navigation, presentation, accessibility, design, performance, Swift idioms, Swift concurrency, SwiftData/CloudKit constraints, localization, SwiftLint, and Xcode MCP preference.
- Error prevention: Moderate. It prevents common SwiftUI and Swift mistakes through explicit rules and before/after output examples. It lacks executable validation, docs allow-lists, semver gates, or test fixtures that would catch stale or over-broad rules.
- Self-learning / memory: None. The repo is curated static guidance, not a memory or feedback system.
- Popular skills: The repo contains one skill, `swiftui-pro`; README links sibling skills for SwiftData, Swift Concurrency, Swift Testing, and the broader Swift Agent Skills collection.

## Core Execution Path

The runtime path is prompt-driven:

1. User invokes `swiftui-pro` directly, via natural language, or through the OpenAI agent manifest's default prompt.
2. The agent reads `swiftui-pro/SKILL.md` or, for Claude plugin installs, `swiftui-pro/skills/swiftui-pro/SKILL.md`.
3. For a full review, the agent follows the ordered checklist: modern API, views/modifiers/animations, data flow, navigation, design, accessibility, performance, Swift language, and hygiene.
4. Each checklist step points to one reference file under `references/`.
5. If the user asks for a partial review, the agent should load only the relevant reference files.
6. Findings are grouped by file and line, name the violated rule, show a brief before/after fix, skip files without issues, and end with a prioritized summary.

There is no executable path after the prompt is loaded: no script scans source files, no schema validates findings, no test suite checks examples, and no CI verifies the skill package. Verification remains an instruction to the agent and user-facing review output rather than a repository-enforced pipeline.

## Architecture

The repository is a small skill package rather than an application:

- `README.md`: install, usage, contribution guidance, and links to companion Swift skills.
- `.claude-plugin/marketplace.json`: marketplace entry for installing `swiftui-pro` as a Claude plugin.
- `swiftui-pro/.claude-plugin/plugin.json`: plugin manifest with skill root `./skills/`.
- `swiftui-pro/SKILL.md`: primary Agent Skills-compatible skill, versioned `1.1` in frontmatter.
- `swiftui-pro/skills/swiftui-pro/SKILL.md`: nested Claude plugin skill, versioned `1.0`, using `${CLAUDE_SKILL_DIR}` reference paths.
- `swiftui-pro/skills/swiftui-pro/references`: tracked symlink to `../../references`.
- `swiftui-pro/references/*.md`: nine topical rule files.
- `swiftui-pro/agents/openai.yaml`: OpenAI display metadata, icons, brand color, default prompt, and implicit invocation policy.
- `assets/` and `swiftui-pro/assets/`: logo and icon files.

Artifact boundaries are clean at the high level: install metadata, skill instructions, references, and assets are separate. The weak boundary is duplication between two `SKILL.md` files and three version sources (`SKILL.md` metadata, plugin manifest, marketplace manifest), which are already out of sync.

## Design Choices

The main design choice is topical progressive disclosure. `SKILL.md` gives the agent an ordered review plan, while details live in small Markdown files named for concrete review domains. This makes partial reviews cheap and keeps the activation prompt readable.

The second choice is domain-specific strictness rather than generic best practices. Rules are opinionated about modern SwiftUI: avoid old navigation APIs, prefer Observation over legacy `ObservableObject` in new code, use `NavigationStack`/`NavigationSplitView`, prefer `Task` over `onAppear()` for async work, avoid `AnyView`, preserve structural identity, keep view bodies simple, and prefer system accessibility/design primitives.

The third choice is to use human-readable rules instead of machine-readable rule records. This keeps authoring easy, but it means there are no rule IDs, severity labels, applicability fields, source URLs, examples inventory, or stale-rule checks.

The fourth choice is cross-agent packaging. The repo supports `npx skills add`, Claude plugin marketplace install, Codex-style `$swiftui-pro` invocation, and OpenAI agent metadata. This is useful for portability, but the nested Claude packaging creates version skew unless release checks compare all manifests.

The fifth choice is output discipline. The skill tells agents to report by file, cite line numbers, state the rule, show before/after code, skip clean files, and prioritize the summary. That output contract is simple but reusable for review-focused skills.

## Strengths

- Compact skill structure with clear activation metadata and a short domain checklist.
- Reference files are small, topical, and easy to load selectively for partial reviews.
- Strong SwiftUI domain coverage: modern API migration, state/data flow, navigation, animations, accessibility, performance, Swift language idioms, concurrency, SwiftData, localization, and project hygiene.
- Rules target concrete LLM failure modes rather than broad tutorial content.
- Output format pushes agents toward actionable review findings with file/line references and before/after code.
- Good portability signals: Agent Skills layout, Claude plugin metadata, OpenAI manifest, install docs for multiple assistants, and marketplace packaging.
- Useful artifact boundary between instructions and reference shards; references can evolve independently of the skill shell.
- The skill explicitly prefers Xcode MCP tools when configured, which is a good pattern for domain skills that can use specialized inspection tools.

## Weaknesses

- No automated verification. The repo has no tests, CI, package manifest, lint harness, fixture projects, or generated-rule validation.
- No structured rule metadata. Rules cannot be filtered by platform, Swift version, severity, source, confidence, or review mode except by choosing whole reference files.
- Version drift exists: primary `swiftui-pro/SKILL.md` says metadata version `1.1`, nested plugin skill says `1.0`, and plugin/marketplace manifests say `1.0.0`.
- Some rules are likely time-sensitive, especially iOS 26 and Swift 6.2 guidance, but there is no Apple-docs snapshot, citation allow-list, or docs freshness check.
- The full review still asks the agent to load every reference file and inspect code manually. There is no deterministic pre-scan for deprecated APIs, icon-only buttons, `NavigationView`, `AnyView`, `DispatchQueue`, force unwraps, or other mechanically detectable patterns.
- The skill has no project capability detection. It tells agents to consider Main Actor default isolation, SwiftLint, Localizable catalogs, Xcode MCP, and deployment target, but does not define how to detect them.
- Examples are useful but not harvested into eval cases. The repo could catch regressions by turning before/after snippets into positive and negative fixtures.
- The nested symlink is concise, but some packaging environments handle symlinks poorly; no release check verifies that installed packages resolve references correctly.

## Ideas To Steal

- Use one `SKILL.md` as a routing shell and keep detailed guidance in small topical `references/` files.
- Add an explicit instruction that partial reviews load only relevant references.
- Build domain skills around "mistakes agents actually make", not complete documentation coverage.
- Make every finding name the violated rule, cite file/line, show a minimal before/after fix, and end with prioritized impact.
- Add domain-tool preference rules, such as using Xcode MCP preview/documentation tools when available.
- Cross-link companion skills when a subdomain deserves a separate deep skill, as this repo does for SwiftData, Swift Concurrency, and Swift Testing.
- Keep references short enough that maintainers can update them directly without a build system.
- Separate install metadata, agent metadata, references, and visual assets so the skill can target several assistants from one source tree.

## Do Not Copy

- Do not rely only on prose for rules that can be scanned mechanically. Deprecated API names, old navigation APIs, `AnyView`, force unwraps, and `DispatchQueue` are good scanner candidates.
- Do not ship multiple `SKILL.md` copies without a consistency check for version, argument hints, paths, and review process text.
- Do not leave platform-version rules uncited and unvalidated if the skill makes strong claims about newly released APIs.
- Do not use only broad topical files when rules need applicability metadata such as iOS version, Swift version, project setting, or migration cost.
- Do not assume symlinked references will work in every installer unless package tests cover the actual install surfaces.
- Do not let "report only genuine problems" be the only false-positive control; pair it with severity, confidence, and applicability guidance.

## Fit For Agentic Coding Lab

Fit is high for lightweight domain-skill design. This repo is a good model for a first-pass SwiftUI or platform-specific review skill where the goal is to compress expert taste into a portable prompt artifact.

Best reusable patterns:

- `SKILL.md` as a thin orchestrator with reference-file routing.
- Small, domain-named references that support selective context loading.
- Review output contract with file/line, violated rule, fix snippet, and prioritized summary.
- Contribution rule that avoids repeating knowledge base models already know.
- Cross-agent packaging metadata and default prompts.

Needed upgrades for Agentic Coding Lab:

- Add rule IDs, severities, applicability fields, and source/provenance links.
- Add scanners for mechanically detectable SwiftUI/Swift patterns.
- Add fixture Swift projects or extracted code snippets for regression tests.
- Add release checks for version consistency and symlink packaging.
- Add a docs freshness process for Apple API claims and newly introduced platform APIs.

## Reviewed Paths

- `README.md`: install paths, invocation examples, contribution guidance, companion skills, and stated target platforms.
- `.claude-plugin/marketplace.json`: Claude marketplace metadata and plugin source path.
- `swiftui-pro/.claude-plugin/plugin.json`: plugin manifest and nested skill root.
- `swiftui-pro/SKILL.md`: primary review process, core instructions, output contract, and references index.
- `swiftui-pro/skills/swiftui-pro/SKILL.md`: nested Claude plugin skill copy and reference path handling.
- `swiftui-pro/skills/swiftui-pro/references`: tracked symlink to shared references.
- `swiftui-pro/agents/openai.yaml`: OpenAI display metadata, default prompt, and implicit invocation policy.
- `swiftui-pro/references/api.md`: modern SwiftUI API/deprecation guidance.
- `swiftui-pro/references/views.md`: view structure, extraction, previews, buttons, tabs, and animation guidance.
- `swiftui-pro/references/data.md`: Observation, state ownership, bindings, SwiftData, and CloudKit constraints.
- `swiftui-pro/references/navigation.md`: navigation and presentation rules.
- `swiftui-pro/references/design.md`: Human Interface Guidelines-style design and layout rules.
- `swiftui-pro/references/accessibility.md`: Dynamic Type, VoiceOver, Reduce Motion, color differentiation, and tappable control guidance.
- `swiftui-pro/references/performance.md`: structural identity, `AnyView`, body work, lazy stacks, async task use, and view-builder storage.
- `swiftui-pro/references/swift.md`: Swift idioms, localization, errors, modern Foundation, and Swift concurrency rules.
- `swiftui-pro/references/hygiene.md`: secrets, comments, tests, SwiftLint, string catalogs, and Xcode MCP preference.
- `assets/logo.svg`, `swiftui-pro/assets/swiftui-pro-icon.svg`, and `swiftui-pro/assets/swiftui-pro-icon.png`: packaging/display assets, inspected at inventory level only.

## Excluded Paths

- `.git/` internals: not needed beyond recording commit, tag, and remote provenance.
- `CODE_OF_CONDUCT.md` and `LICENSE`: standard project governance/license files, not part of skill execution.
- Image/SVG body details: asset presence and role were enough for packaging review.
- Full reproduction of prompt and reference bodies: summarized to avoid copying long instruction text verbatim.
- External companion repositories and linked Hacking with Swift article/video: noted as context only; this review target was the current source tree for `SwiftUI-Agent-Skill`.
