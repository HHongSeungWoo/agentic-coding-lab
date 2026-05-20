# SimoneAvogadro/android-reverse-engineering-skill

- URL: https://github.com/SimoneAvogadro/android-reverse-engineering-skill
- Category: domain-specific-coding
- Stars snapshot: 5,765 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 6a31ed3fa2fc96d2366e057dcf13bbf5c2bdcdaa
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Compact, useful domain-specific Claude Code plugin for Android reverse engineering. Strongest reusable patterns are the phase-based APK-to-API workflow, machine-readable dependency preflight, decompiler wrapper scripts, split/XAPK handling, targeted API-search taxonomy, call-flow tracing guidance, and progressive references. Do not copy it as-is for high-assurance work: legal authorization, untrusted-binary sandboxing, dependency-install approval, secret redaction, output size control, and automated tests are mostly outside the repo or prompt-enforced.

## Why It Matters

Android reverse engineering is a high-friction domain for coding agents because the agent must coordinate external tools, generated source trees, Android-specific entry points, obfuscation, HTTP-client idioms, and legal boundaries. This repo turns that domain into a narrow skill workflow: check tools, decompile the package, inspect manifest and package structure, trace UI-to-network call flows, search for API usage, then produce endpoint documentation and a call-flow map.

For Agentic Coding Lab, the repo is valuable as a domain-specific skill pattern. It shows how a small plugin can give an agent a concrete operating procedure and reusable scripts without building a full runtime. It also exposes the gaps that matter when a skill crosses into security research: prompt text is not enough for permissions, dependency installation, untrusted input handling, or artifact redaction.

## What It Is

The checkout is a Claude Code plugin named `android-reverse-engineering`, version `1.1.0`. It packages one skill, one `/decompile` command, five reference documents, and bash plus PowerShell helper scripts. The workflow targets APK, XAPK, JAR, and AAR files, with `jadx` as the default decompiler and Fernflower/Vineflower plus dex2jar as optional comparison tooling.

It is not a decompiler implementation, sandbox, malware-analysis lab, API-replay framework, or MCP server. It delegates actual analysis to external tools such as Java, jadx, Vineflower/Fernflower, dex2jar, apktool, adb, grep, unzip, and the host agent's file-reading behavior. The repo's value is the skill contract and wrapper workflow around those tools.

## Research Themes

- Token efficiency: Good static packaging pattern. The core `SKILL.md` gives the five-phase path, while tool-specific details live in `references/`. The API-search script narrows attention to Retrofit, OkHttp, Volley, WebView, hardcoded URLs, and auth strings before the agent reads surrounding code. Missing piece: no ranking, summarization, or context-budget strategy for huge decompiled source trees.
- Context control: Strong prompt-level shape. `/decompile` is a thin command overlay, `SKILL.md` is the canonical workflow, and references are loaded by need. Decompiled output is organized into predictable `sources/`, `resources/`, `jadx/`, `fernflower/`, `base/`, and split APK directories. Missing piece: no artifact manifest, package allow/deny list, third-party-library pruning workflow, or structured index of discovered endpoints.
- Sub-agent / multi-agent: Weak. No delegation model exists. A useful extension would split work into independent analysts for manifest/permissions, network endpoints, auth/interceptors, WebView/JS bridge, and obfuscation/class-flow reconstruction.
- Domain-specific workflow: Very strong. The workflow encodes Android-specific file formats, lifecycle entry points, manifest inspection, DI tracing, architecture patterns, decompiler choice, split APKs, XAPK bundles, obfuscation anchors, and common HTTP client libraries.
- Error prevention: Moderate. Dependency scripts produce `INSTALL_REQUIRED:` and `INSTALL_OPTIONAL:` markers, decompilation validates file type and engine, Fernflower gets a timeout in bash, partial decompiler output can be treated as usable, and split/bundled APKs are detected. Gaps: no CI, fixtures, shellcheck, PowerShell tests, sandbox, checksum validation, or redaction checks.
- Self-learning / memory: None. The skill is reusable domain memory, but it does not store project-specific findings, failed decompiler strategies, endpoint classifications, or user feedback for future analyses.
- Popular skills: The only local skill is `android-reverse-engineering`; the only command is `/decompile`. The reusable patterns are more important than invocation count: preflight -> decompile -> structure survey -> call-flow trace -> API extraction -> documented artifacts.

## Core Execution Path

1. The user invokes `/decompile <path>` or asks naturally to decompile, reverse engineer, extract Android API endpoints, or trace Android call flows.
2. The command or skill checks dependencies with `check-deps.sh` or `check-deps.ps1`. Required dependencies are Java 17+ and jadx. Optional dependencies include Vineflower/Fernflower, dex2jar, apktool, and adb.
3. If required dependencies are missing, the workflow routes to `install-dep.sh` or `install-dep.ps1`, then re-runs dependency checks. Optional dependency installation is supposed to be confirmed with the user.
4. Decompilation runs through `decompile.sh` or `decompile.ps1`. Default engine is `jadx`; JAR/AAR or problematic Java output can use Fernflower/Vineflower; `--engine both` creates side-by-side output for comparison. `--deobf` handles obfuscated code and `--no-res` narrows to code.
5. XAPK files are extracted, APKs inside the archive are enumerated, the XAPK manifest is copied to output, and each APK is decompiled into its own subdirectory. For wrapper APKs that contain `base.apk` plus split APKs, the script detects very small Java output and re-decompiles the inner base APK.
6. The agent reads `AndroidManifest.xml`, package layout, application class, Android components, permissions, and architecture signals such as ViewModel, Repository, Presenter, Dagger, or Hilt.
7. The agent traces call flows from Activities/Fragments and lifecycle methods through ViewModels/Presenters, repositories, DI modules, Retrofit interfaces, OkHttp clients, WebView bridges, or legacy HTTP code.
8. API discovery runs through `find-api-calls.sh` or `find-api-calls.ps1`, optionally scoped to Retrofit, OkHttp, Volley, URL strings, or auth patterns.
9. Final artifacts are expected to include decompiled source, architecture summary, endpoint documentation, and a call-flow map. The repo defines the artifact contract in prose, not as a machine-readable schema.

## Architecture

- `.claude-plugin/marketplace.json`: marketplace wrapper for the repo package, category `security`, plugin version `1.1.0`.
- `plugins/android-reverse-engineering/.claude-plugin/plugin.json`: plugin manifest pointing to `skills/` and `commands/`.
- `plugins/android-reverse-engineering/commands/decompile.md`: user-invocable command for target-file acquisition, dependency checks, decompile strategy, initial structure analysis, and next-step prompts.
- `plugins/android-reverse-engineering/skills/android-reverse-engineering/SKILL.md`: core trigger metadata and five-phase workflow.
- `references/setup-guide.md`: install guidance for Java, jadx, Vineflower/Fernflower, dex2jar, apktool, and adb.
- `references/jadx-usage.md`: jadx options, output layout, obfuscation guidance, and common workflows.
- `references/fernflower-usage.md`: Fernflower/Vineflower usage, engine-selection guidance, dex2jar APK flow, and options.
- `references/api-extraction-patterns.md`: search patterns and documentation shape for Retrofit, OkHttp, Volley, HttpURLConnection, WebView, URLs, and auth strings.
- `references/call-flow-analysis.md`: Android manifest, lifecycle, click-handler, application-init, DI, constants, and obfuscation tracing workflow.
- `scripts/check-deps.{sh,ps1}`: dependency probes with machine-readable missing-dependency lines.
- `scripts/install-dep.{sh,ps1}`: dependency installers using local installs, package managers, direct GitHub release downloads, PATH updates, and manual fallbacks.
- `scripts/decompile.{sh,ps1}`: wrappers for jadx/Fernflower/Vineflower, XAPK extraction, split APK detection, output structure summaries, and side-by-side comparison.
- `scripts/find-api-calls.{sh,ps1}`: grep/Select-String search wrappers for HTTP and auth patterns.

There is no `.github/` CI, test harness, fixtures, sample APKs, schema validator, sandbox launcher, endpoint-output parser, or generated-report template.

## Design Choices

The main design choice is to package a real security-analysis workflow as a skill plus thin shell wrappers. The prompt gives domain sequencing and interpretation; scripts provide repeatable command surfaces for dependency checks, decompilation, and API search.

The second strong choice is dual decompiler support. jadx is preferred for Android resources and first-pass coverage, while Fernflower/Vineflower is positioned as a better Java decompiler for complex code and a comparison fallback when jadx emits warnings. Running both engines into separate output directories is a useful verification pattern.

The third choice is Android artifact awareness. XAPK extraction, bundled `base.apk` detection, split APK handling, `AndroidManifest.xml` inspection, application class discovery, permissions, lifecycle methods, DI modules, and obfuscation anchors are all embedded into the workflow.

The repo uses progressive disclosure well. Common steps stay in `SKILL.md`; detailed CLI references, setup, API search patterns, and call-flow techniques are separate files. That lets an agent load only the relevant reference for the current phase.

Safety is handled unevenly. README has a lawful-use disclaimer, and dependency installation text says optional installs should ask the user. But the core skill and command do not begin with an explicit authorization checklist, ownership statement, target provenance check, malware/untrusted-input sandbox policy, or secret-handling policy. Install scripts can mutate `~/.local`, shell profiles, user PATH, and system packages; that needs host-level approval enforcement.

## Strengths

- Clear end-to-end domain workflow from APK/XAPK/JAR/AAR input to architecture summary, endpoint docs, and call-flow map.
- Practical dependency preflight with machine-readable missing-dependency markers that an agent can parse.
- Good decompiler orchestration: jadx default, Fernflower/Vineflower comparison, dex2jar bridge, deobfuscation option, code-only mode, output summaries, and bash-side partial-success handling.
- Handles modern Android distribution shapes better than a generic decompile prompt: XAPK archives, wrapper APKs, `base.apk`, split APKs, and config-split skipping.
- API extraction patterns cover the most common Android HTTP surfaces: Retrofit, OkHttp, Volley, HttpURLConnection, WebView, hardcoded URLs, base constants, and auth markers.
- Call-flow reference gives usable Android-specific tracing anchors: manifest, lifecycle, click handlers, application init, Dagger/Hilt, constants, BuildConfig, SharedPreferences, strings, and obfuscation-safe library calls.
- Cross-platform support is pragmatic. Bash and PowerShell scripts cover the same broad operations, and Windows PATH refresh is built into the PowerShell helpers.

## Weaknesses

- No automated verification suite. There are no sample APK/JAR fixtures, shellcheck runs, PowerShell tests, smoke tests for helper scripts, golden search outputs, or CI workflows.
- Legal and permission boundaries are mostly README-level. The workflow should require an explicit authorization/provenance checkpoint before decompilation and before extracting or documenting private APIs.
- Untrusted input handling is thin. APK/XAPK/JAR/AAR files are parsed by external tools and unzipped locally without a container, read-only mount, disk quota, path policy, malware caveat, or cleanup ledger beyond temporary XAPK extraction.
- Dependency installation is too powerful for a skill to run automatically. It may use sudo/package managers, direct downloads from latest GitHub releases, PATH/profile mutation, symlink creation, and directory removal under `~/.local/share`, with no checksums or pinned versions.
- Secret handling is not defined. The API search scripts can print API keys, tokens, bearer strings, client secrets, and authorization headers directly to terminal output or logs.
- Output can exceed agent context quickly. The repo does not define package filtering, third-party library exclusion, source-tree indexing, sampling, endpoint deduplication, or a structured output file for large apps.
- PowerShell parity is useful but less hardened than bash. The bash decompiler has richer partial-success handling and Fernflower timeout behavior; the PowerShell path mostly assumes called tools succeed or throw.
- No machine-readable final artifact schema. Endpoint documentation and call-flow maps are prose templates, so downstream tools cannot reliably diff or validate extracted APIs.

## Ideas To Steal

- Use a five-phase domain workflow: preflight, transform/decompile, structure survey, call-flow trace, endpoint extraction.
- Make dependency checks emit stable machine-readable markers such as `INSTALL_REQUIRED:<dep>` and `INSTALL_OPTIONAL:<dep>`.
- Ship wrapper scripts for repeatable domain operations instead of leaving the agent to improvise long tool commands.
- Keep a canonical skill with thin command overlays. `/decompile` adds invocation flow while `SKILL.md` remains the source of truth.
- Treat generated artifacts as first-class: source directory, resources directory, XAPK manifest, decompiler comparison directories, architecture summary, endpoint docs, and call-flow map.
- Use dual-engine comparison as verification. Side-by-side jadx and Fernflower outputs help recover from decompiler-specific bad code.
- Encode domain-specific search taxonomies. Retrofit annotations, OkHttp builders/interceptors, WebView bridges, URL constants, and auth keys are better anchors than generic full-text search.
- Provide call-flow guidance that starts from platform entry points and moves toward business logic: manifest -> lifecycle -> user action -> ViewModel/Presenter -> repository -> API client.
- Use progressive reference files for detailed tool usage and domain patterns so the main skill stays small.
- Add cross-platform scripts only when they preserve the same artifact contract and verification behavior.

## Do Not Copy

- Do not rely on a README disclaimer for high-risk reverse-engineering work. Put authorization, scope, and lawful-use checkpoints directly in the invoked skill and command.
- Do not auto-install decompilers or platform tools from a skill without explicit host/user approval, pinning, checksums, and a clear rollback story.
- Do not analyze untrusted APK/XAPK/JAR/AAR files on the host workspace by default. Use a sandbox, temp workspace, disk cap, network isolation when appropriate, and cleanup receipt.
- Do not print discovered secrets raw. Redact by default and require a deliberate opt-in for viewing full tokens or keys.
- Do not dump a whole decompiled source tree into context. Build an index, exclude third-party libraries, dedupe endpoints, and load files only around selected anchors.
- Do not treat grep hits as verified API documentation. Require surrounding-code review, base URL resolution, interceptor/header tracing, request/response type extraction, and call-site provenance.
- Do not copy dependency-download-latest behavior into durable lab tooling without freshness and supply-chain policy.
- Do not skip tests because a package is "just a skill." Scripted skills need fixtures, smoke tests, and regression checks for the exact artifacts they produce.

## Fit For Agentic Coding Lab

Fit is in-scope for `domain-specific-coding`. The repo is a strong example of making a coding agent useful in a narrow technical domain by packaging tool setup, transformation scripts, search heuristics, and output expectations together.

Agentic Coding Lab should borrow the structure, not the safety posture. A lab-grade version should add frontmatter or manifest metadata for risk level, required tools, mutating operations, network use, expected artifacts, and verification commands. It should also add a sandbox runner for untrusted binaries, pinned dependency installation, fixture tests, redaction rules, endpoint JSON output, and a context-control index for large decompiled trees.

The most reusable pattern is a domain workflow bundle: one canonical skill, one thin command, scripts for repeatable tool steps, references for deep domain knowledge, and a final artifact contract. This pattern transfers well to other domains such as firmware analysis, cloud IaC review, mobile privacy auditing, browser extension analysis, or protocol-client reconstruction.

## Reviewed Paths

- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/README.md`: installation, usage, feature table, repository layout, acknowledgments, and lawful-use disclaimer.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/.claude-plugin/marketplace.json`: marketplace package metadata, plugin pointer, version, category, repository, and license.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/.claude-plugin/plugin.json`: plugin metadata and skill/command roots.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/commands/decompile.md`: slash-command workflow, dependency handling, decompiler choice, structure analysis, and next-step prompts.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/SKILL.md`: trigger metadata, prerequisites, five-phase workflow, output contract, and reference routing.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/references/setup-guide.md`: dependency installation docs and troubleshooting.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/references/jadx-usage.md`: jadx CLI behavior, outputs, obfuscation strategies, and workflows.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/references/fernflower-usage.md`: Fernflower/Vineflower role, options, APK bridge through dex2jar, and comparison guidance.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/references/api-extraction-patterns.md`: Retrofit, OkHttp, Volley, legacy HTTP, WebView, URL, auth, and endpoint documentation patterns.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/references/call-flow-analysis.md`: manifest, lifecycle, UI handler, application init, DI, constants, and obfuscation tracing.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/check-deps.sh`: bash dependency probe and machine-readable summary.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/install-dep.sh`: bash dependency installer, package-manager paths, user-local installs, GitHub release downloads, and PATH mutation.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/decompile.sh`: bash decompiler wrapper, XAPK/split handling, Fernflower timeout, partial-success behavior, and comparison summary.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/find-api-calls.sh`: bash API pattern search.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/check-deps.ps1`: PowerShell dependency probe and Windows PATH refresh.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/install-dep.ps1`: PowerShell dependency installer, Windows package managers, direct downloads, and user PATH mutation.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/decompile.ps1`: PowerShell decompiler wrapper, XAPK/split handling, and comparison summary.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/plugins/android-reverse-engineering/skills/android-reverse-engineering/scripts/find-api-calls.ps1`: PowerShell API pattern search.
- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/LICENSE`: Apache-2.0 license.
- Repository structure at commit `6a31ed3fa2fc96d2366e057dcf13bbf5c2bdcdaa`, including hidden plugin metadata and absence of CI/tests/fixtures.

## Excluded Paths

- `/tmp/myagents-research/SimoneAvogadro-android-reverse-engineering-skill/.git/**`: VCS internals; commit SHA and recent log were captured separately.
- GitHub issues, pull requests, discussions, stargazer pages, and wiki pages: useful community context but outside the checked-in execution path for this note.
- External source for jadx, Vineflower/Fernflower, dex2jar, apktool, adb, Java, and Android SDK tools: treated as dependencies, not audited as part of this repo.
- Downloaded dependency artifacts from `install-dep.*`: not executed or reviewed because installation would mutate the environment.
- Live APK/XAPK/JAR/AAR samples and generated decompiled output: no sample target was provided; script behavior was reviewed through source and safe help/dependency probes.
- Long prompt bodies and documentation examples: reviewed for workflow patterns and summarized; not reproduced verbatim.
