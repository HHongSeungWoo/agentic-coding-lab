# sourcery-ai/sourcery

- URL: https://github.com/sourcery-ai/sourcery
- Category: error-prevention
- Stars snapshot: 1,813 (GitHub REST API repository metadata, captured 2026-05-19 KST)
- Reviewed commit: dea33cb404a1527079222036f8d86bc0a003d158
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful reference for PR-time coding error prevention, especially the mix of hosted AI review, static rules, pre-commit/CI `--check`, custom rule tests, PR interaction commands, and an explicit "Prompt for AI Agents" review artifact. Fit is conditional because the repo itself is mostly docs, pre-commit metadata, issue templates, and release packaging; the actual reviewer runtime is a proprietary packaged binary and hosted service, so execution internals are not auditable from this repository.

## Why It Matters

Sourcery is a purpose-built AI code review system rather than a general coding agent. It sits where coding-agent mistakes should be caught: before or during pull request review, in pre-commit hooks, in CI, and inside IDEs through an LSP server. Its public docs describe reviews that cover bug risks, design decisions, code quality, performance, and team standards. Its repo publishes the pre-commit hook and release anchor used by downstream projects.

For Agentic Coding Lab, Sourcery is most valuable as a workflow pattern: combine deterministic static rules, project-specific review rules, diff-scoped checks, human-visible PR comments, machine-actionable exit codes, and feedback/review commands. It is less valuable as implementation reference because the main analysis engine is not source-available here.

## What It Is

The repository is the public Sourcery distribution and integration repo. It contains:

- A README describing Sourcery's hosted PR review, IDE coding assistant, LLM providers, privacy posture, and install links.
- A pre-commit hook definition that installs `sourcery==1.43.0` and runs `sourcery review --check`.
- A minimal `pyproject.toml` for the `sourcery-precommit` release version.
- LSP client integration notes for running the Sourcery language server binary with `sourcery lsp`.
- GitHub issue templates and a small issue automation workflow.
- A demo GIF and release metadata.

I also downloaded the matching PyPI wheel `sourcery==1.43.0` under `/tmp` for inspection. That wheel exposes `sourcery.wrapper:main`, which shells out to a bundled `sourcery` executable. The wheel also bundles public rule YAML files, rule tests, Black/lib2to3/tree-sitter style parser dependencies, and a UI dist bundle, but the executable itself is opaque binary code.

## Research Themes

- Token efficiency: Moderate. Sourcery's documented best practice is to review only changed code with `--diff=git diff HEAD` or a PR base diff, avoiding full-repo review noise and cost. PR summaries and review guides may add tokens, but `--no-summary` is recommended for pre-commit.
- Context control: Strong at workflow level. `.sourcery.yaml` supports ignored paths, enabled/disabled rule ids or tags, rule types, Python version, custom rules, rule tags, metrics, GitHub labels, clone detection, and proxy settings. Review Rules can be scoped by path glob. Inline `# sourcery skip` comments suppress specific rules or all rules for a function.
- Sub-agent / multi-agent: Limited. Sourcery is not a subagent framework. The notable agent-facing artifact is the collapsed `Prompt for AI Agents` inside PR review output, intended to be copied into an agent to address comments.
- Domain-specific workflow: Strong for code review. It has Python and JavaScript/TypeScript static rules, custom AST-like rules, PR review sections, review commands, IDE/LSP suggestions, Sentry issue investigation, and optional security scanning.
- Error prevention: Strong as a PR/CI/IDE gate. It flags bug risks, code quality issues, performance issues, team standard violations, static rule matches, low-quality functions, duplicate clones, and custom rule violations. `--check` can fail CI/pre-commit when unresolved issues remain.
- Self-learning / memory: Moderate but opaque. User thumbs up/down reactions on review comments are documented as signals used to tailor future comments. The implementation, retention model, and auditability are not exposed in this repo.
- Popular skills: Not a Codex skill repo. Reusable "skills" are review sectioning, custom rule authoring with tests, diff-scoped pre-commit/CI checks, PR comment commands, IDE LSP feedback, and agent prompt generation from review comments.

## Core Execution Path

The hosted PR path starts when Sourcery is installed as a GitHub or GitLab integration and granted access to all or selected repos. On new pull requests, Sourcery reviews the diff and emits a review made of a PR summary, review guide, optional diagrams, linked issue analysis, overall review, static rule comments, AI review comments, and inline individual comments. Review sections can be enabled or disabled in the dashboard. The README says the service uses OpenAI and Anthropic LLMs and typically sends PR diff sections to those providers.

PR interaction is command-driven. Commenting `@sourcery-ai review` triggers a review or re-review. `@sourcery-ai summary`, `@sourcery-ai guide`, and `@sourcery-ai title` regenerate specific artifacts. `@sourcery-ai dismiss` or `@sourcery-ai resolve` clears outstanding comments. Replying `@sourcery-ai issue` to a Sourcery comment creates a GitHub issue. Replies can ask follow-up questions or push back on a suggestion. If another human is tagged, Sourcery should stay out of that thread until explicitly mentioned again.

The pre-commit path is public in `.pre-commit-hooks.yaml`: the hook id `sourcery` runs `sourcery review --check` for Python files and installs `sourcery==1.43.0`. The docs recommend passing `args: [--diff=git diff HEAD, --no-summary]` for pre-commit and using `--diff="git diff <base>"` in CI. The CLI supports `--enable`, `--disable`, `--check`, `--fix`, `--config`, `--csv`, `--verbose`, and `--summary/--no-summary`. `--check` returns exit code 1 if unsolved issues are found.

The local CLI package path is only partly inspectable. `entry_points.txt` maps `sourcery` to `sourcery.wrapper:main`; `wrapper.py` calls the adjacent bundled executable with original argv. The wheel contains a large proprietary executable plus YAML rule definitions. This means the command surface is inspectable, but scanner internals, hosted review prompt assembly, LLM routing, ranking, comment deduplication, and remediation logic are not.

The IDE path starts from a downloaded Sourcery binary. Clients run `sourcery --verify` to check API health and refactoring functionality, then start `sourcery lsp`. The LSP initialize request must include a Sourcery token, extension version, and editor version. After initialization, the server behaves as a standards-compliant LSP and provides refactoring suggestions and hover functionality.

The rules/config path combines built-in static rules and project-specific rules. `.sourcery.yaml` controls ignored files, rule enable/disable sets, rule types, Python version, custom rules, rule tags, metrics, GitHub settings, clone detection, and proxy. Custom rules define `id`, `pattern`, `description`, optional `condition`, optional `replacement`, optional `explanation`, tags, path include/exclude rules, and tests. Tests use `match`, `expect`, and `no-match` examples; failing custom rule tests become configuration errors in the IDE or YAML file.

## Architecture

The public repo architecture is a thin distribution shell:

- `README.md` points users to hosted GitHub App review, docs, IDE integrations, privacy terms, and feedback.
- `.pre-commit-hooks.yaml` defines the pre-commit contract and pins the CLI package version through `additional_dependencies`.
- `pyproject.toml` carries the pre-commit package version.
- `WritingAnLSPClient.md` documents binary download, `--verify`, `lsp`, and initialization options.
- `.github/ISSUE_TEMPLATE/**` captures reproducible bug reports, refactoring suggestions, feature requests, and support links.
- `.github/workflows/issue-automation.yml` adds issues to Sourcery's internal on-call project.
- `renovate.json` uses Renovate recommended config for dependency update automation.

The published wheel architecture adds more detail but not full source:

- `sourcery.wrapper:main` launches a bundled `sourcery` executable.
- `sourcery/rules/**` contains YAML static rules for Python, JavaScript/TypeScript, and Java.
- `sourcery/public_rules/**` contains optional rule packs such as Google Python Style Guide, remove debugging statements, and f-string rules.
- Rule YAML includes descriptions, patterns, tags, explanations, and tests.
- The wheel bundles parser/runtime dependencies and UI assets around the executable.

The product architecture, inferred from official docs and repo files, has four surfaces: hosted PR review service, CLI/pre-commit/CI binary, IDE LSP server, and dashboard configuration. Static analysis rules and LLM review are presented as separate review components that can be enabled or disabled.

## Design Choices

Sourcery deliberately places review in multiple feedback loops: IDE for early local feedback, pre-commit before changes leave the workstation, CI before merge, and PR comments for team review. This layered placement is the strongest design choice.

The tool distinguishes safer refactorings from suggestions and no-replacement comments. Docs describe refactorings as behavior-preserving changes Sourcery can apply automatically, suggestions as best-practice changes that may alter behavior and are not auto-fixed by default, and comments as issues without clear automatic replacements. This classification is directly relevant to coding-agent auto-fix safety.

Diff-scoped review is treated as the normal CI/pre-commit mode. Reviewing only new or changed code prevents legacy issue floods and helps developers use Sourcery as a gate on introduced mistakes.

Custom rules are small, testable, and path-scoped. The rule format encourages examples of positive matches, expected replacements, and no-match cases, which is a practical way to reduce false positives before a rule becomes a team standard.

Suppression is explicit. Project config can disable rule ids or tags, and inline comments can skip a specific rule or all rules for a function. GitHub settings can use ignore labels such as `sourcery-ignore`.

PR review output is operational, not just a single comment. Sourcery splits summaries, guides, diagrams, linked issue analysis, overall review, inline comments, and AI-agent prompts. Users can regenerate or dismiss pieces independently.

The distribution model trades transparency for portability. A tiny public repo and a large self-contained wheel simplify installation, but make the core review algorithm, LLM prompts, confidence thresholds, and error recovery impossible to audit from source.

## Strengths

Sourcery directly targets coding mistakes at PR time. Its documented review coverage includes bug risks, design issues, code quality, performance, and coding standards rather than only style.

The CLI and pre-commit path has real gate semantics. `--check` can fail with exit code 1, and `--diff` lets teams gate only new violations.

Static rule definitions are practical and readable. YAML rules carry ids, languages, tags, patterns, explanations, and tests. Example rules catch issues like raising generic exceptions or JavaScript loops with constant end conditions.

Custom rule tests are a strong error-prevention pattern. Requiring `match`, `expect`, and `no-match` snippets helps teams encode review policy without relying solely on prompt text.

IDE/LSP integration catches issues before PRs. `sourcery lsp` plus initialization options gives editors a standard protocol boundary rather than bespoke editor logic.

PR interaction commands give human reviewers control. Regenerating summaries/guides, resolving comments, creating issues, and asking follow-up questions make the reviewer part of the PR conversation.

The `Prompt for AI Agents` section acknowledges the agent remediation loop. Reviewers can hand a specific, comment-derived prompt to a coding agent instead of asking an agent to infer all failures from raw PR comments.

The repo issue templates request reproducing snippets, IDE version, Sourcery version, and operating system. That is useful failure triage structure for rule bugs and bad suggestions.

## Weaknesses

The main runtime is closed and opaque. The repo does not expose the hosted review pipeline, local binary internals, prompt construction, LLM result validation, static analyzer engine, scoring, deduplication, or patch generation.

The repository license and package license differ in practice. The GitHub repo carries an MIT license, while the PyPI wheel metadata says `License: Proprietary`. For Agentic Coding Lab, treat the implementation as non-reusable.

LLM review quality is not mechanically guaranteed. Sourcery can report useful review comments, but this repo does not show deterministic checks around the AI-generated review text or prove that comments are correct.

`--fix` can automatically apply some changes, but the repo does not expose the safety checks that decide whether a fix is behavior-preserving. Any coding-agent adaptation needs tests and diff inspection after auto-fix.

Dashboard-only configuration reduces reviewability. Review sections, review rules, language, approvals, AI comments, and static rule toggles are documented as dashboard settings, not repo-versioned policy files.

The feedback learning loop is not auditable. Thumbs up/down reactions are documented as tailoring future reviews, but there is no visible model, data retention, scope, or rollback mechanism.

The binary wheel is large and vendors many compiled libraries. This improves portability but expands the trust boundary for pre-commit and CI installs.

The docs and package metadata have minor drift. For example, public docs currently reference a development pre-commit rev while the reviewed repo tag is `v1.43.0`, and the wheel README's example rev differs from the checked-out release.

## Ideas To Steal

Add a review artifact that is explicitly formatted for coding agents. Sourcery's `Prompt for AI Agents` is a good pattern: turn reviewer findings into an agent-ready task prompt instead of expecting agents to parse every thread.

Gate new mistakes, not all historical mistakes. Use `--diff`-style scope for agent-generated changes so a verifier reports errors introduced by the agent without overwhelming it with legacy debt.

Make review output modular. Separate summary, review guide, linked issue analysis, overall decision, inline comments, and agent remediation prompt so agents and humans can consume the right layer.

Use static rules with tests for team conventions. A coding lab should allow repo-local rules with `match`, `expect`, and `no-match` snippets, then verify rule behavior before using those rules as merge gates.

Classify automated changes by safety. Copy the refactoring/suggestion/comment split: auto-apply only behavior-preserving transformations, require human or test-backed confirmation for behavior-changing suggestions, and only comment when no safe replacement exists.

Expose review commands as comments or slash commands. `review`, `summary`, `guide`, `dismiss`, `resolve`, and `issue` map cleanly to agent workflows such as rerun verifier, regenerate fix plan, resolve accepted comments, and file follow-up work.

Keep local and PR checks aligned. The same rule ids and config should work in IDE, pre-commit, CI, and PR review so agents see failures before merge.

Provide a `--verify` health path. Before relying on an external review service, check authentication, service health, and local analyzer functionality separately from a real review.

Support path-scoped review rules. Coding-agent policies often differ for tests, migrations, generated files, infrastructure, and app code; rules need include/exclude patterns.

Record enough bug-report context for false positives. Require exact code snippet, tool version, editor/CI environment, OS, and expected behavior when users report bad review comments.

## Do Not Copy

Do not build Agentic Coding Lab around an opaque binary if the goal is reproducible research. Use Sourcery as workflow inspiration, not as source-level implementation.

Do not treat AI review comments as proof. A coding-agent verifier needs deterministic backing checks, tests, typechecks, secret scans, static analysis, and diff inspection.

Do not make dashboard configuration the only policy source. Agent policies should be repo-versioned, reviewable, and testable.

Do not auto-apply review suggestions without a post-fix verification loop. Even "safe" refactorings should be followed by tests or at least parsing/type checks when a coding agent edits files.

Do not let feedback reactions silently rewrite team policy. Positive and negative reactions can tune noise, but critical rules should remain explicit and auditable.

Do not send code to hosted LLM reviewers without a clear privacy boundary, retention policy, and user consent. Sourcery documents its boundary, but each lab deployment needs its own.

Do not rely on PR comments alone as a merge gate. Comments are easy for agents to ignore unless tied to failing checks, required reviews, or a structured remediation task.

## Fit For Agentic Coding Lab

Fit is medium-high for `error-prevention` as a product/workflow pattern and low as open-source implementation reference. Sourcery shows where to place checks and how to shape review output for humans and agents, but it does not expose enough runtime internals to copy.

Best adaptations:

- A repo-local reviewer that produces PR summary, review guide, inline findings, and agent-ready remediation prompt.
- A static rule engine with rule ids, path scope, tags, explanations, and match/no-match/expect tests.
- Diff-scoped verification that fails only on newly introduced issues by default.
- A command interface for rerun review, regenerate summary, resolve accepted findings, and file follow-up issues.
- A safety classification for fixes: auto-refactor, suggest-with-tests, or comment-only.
- Health checks for auth, service availability, config validity, and analyzer functionality before an agent depends on external review.

Main caveat: Sourcery prevents mistakes after code is written or opened in a PR. Agentic Coding Lab also needs pre-action controls: command approval, path write scopes, sandboxing, dependency policy, secret handling, and required verification before final response.

## Reviewed Paths

- `README.md`: product scope, hosted PR review behavior, review contents, GitHub App install link, private repo plan boundary, LLM provider/privacy statement, IDE assistant scope, and integration links.
- `.pre-commit-hooks.yaml`: hook id, package dependency, command entrypoint `sourcery review --check`, and Python file type scope.
- `pyproject.toml`: release/package version `1.43.0` for the pre-commit wrapper.
- `WritingAnLSPClient.md`: binary download flow, `sourcery --verify`, `sourcery lsp`, stdio LSP transport, and required initialization options.
- `.github/ISSUE_TEMPLATE/bug_report.md`: failure report checklist, reproduction snippet, version/environment fields, and troubleshooting/doc links.
- `.github/ISSUE_TEMPLATE/refactoring_suggestion.md`: requested before/after examples and guidance toward custom rules for too-specific suggestions.
- `.github/ISSUE_TEMPLATE/feature_request.md` and `config.yml`: feature request checks and support/documentation contact links.
- `.github/workflows/issue-automation.yml`: issue automation path for routing opened/labeled issues into Sourcery's project.
- `renovate.json`: maintenance automation policy.
- `LICENSE`: repository MIT license.
- PyPI wheel `sourcery==1.43.0` downloaded to `/tmp/myagents-research/sourcery-ai-sourcery-pypi`: inspected `sourcery.wrapper.py`, `entry_points.txt`, `METADATA`, `public_rules/README.md`, selected Python and JavaScript rule YAML, and wheel file listing.
- Official docs `Code-Review/Code-Reviews-on-Pull-Requests/Overview/`: hosted PR review scope: bug risks, design decisions, code quality, performance, standards, summary, and review guide.
- Official docs `Code-Review/Code-Reviews-on-Pull-Requests/Components-of-a-Code-Review/`: PR summary, review guide, diagrams, linked issue analysis, overall review, `Prompt for AI Agents`, individual comments, and dashboard section toggles.
- Official docs `Code-Review/Code-Reviews-on-Pull-Requests/Interacting-with-Sourcery/`: PR commands, reply behavior, issue creation, dismiss/resolve, and thumbs feedback.
- Official docs `Code-Review/Configuration/` and `Code-Review/Teaching-Sourcery/`: review settings, review rules, path patterns, concise rule guidance, and feedback-based tailoring.
- Official docs `Getting-Started/Setting-Up-Your-Account/Connecting-Your-Repos/` and `Integrations/Git-Integrations/GitHub/`: GitHub/GitLab linking, selected repository access, Enterprise/self-hosted setup, and PR review integration.
- Official docs `References/Legacy-Integrations/CLI/command-line-interface/` and `References/Legacy-Integrations/CI/CI-and-Pre-Commit/`: CLI commands, `--diff`, `--check`, `--fix`, config path, pre-commit, and CI usage.
- Official docs `References/Legacy-Configuration/sourcery-yaml/`, `Rule-Settings/`, `Inline/`, and `Proxy/`: project config fields, rule settings, clone detection, GitHub labels/ignore labels, inline skip comments, and proxy failure handling.
- Official docs `References/Sourcery-Rules/Overview/`, `Python/Default-Rules/`, and `Custom-Rules/`: AST/static rule model, refactoring/suggestion/comment split, custom rule fields, replacement behavior, path scoping, tags, and rule tests.
- Official docs `References/Troubleshooting/`: `sourcery.log`, proxy issues, unsupported platform issues, disabled account handling, token re-login, and support escalation.
- Official docs `Integrations/Additional-Integrations/sentry/`: Sentry investigation/fix flow and PR creation path, reviewed as adjacent production-error remediation.

## Excluded Paths

- `.git/**`: clone metadata, object database, hooks, refs, and logs; not product or rule execution design.
- `sourcery-demo.gif`: binary/UI demo asset; useful for marketing but not inspectable error-prevention logic.
- PyPI wheel `sourcery-1.43.0.data/purelib/sourcery/sourcery`: 271 MB proprietary executable; noted as the core runtime boundary but excluded from source analysis because it is binary.
- PyPI wheel compiled/vendor libraries such as `libpython3.11.so.1.0`, `_ssl.so`, `grpc/_cython/cygrpc.so`, `tree_sitter/_binding.so`, `pydantic_core/_pydantic_core.so`, parser/runtime `.so` files, certificate bundles, locale/country databases, and compression libraries: dependency/runtime payload, not source-level design.
- PyPI wheel `coding-assistant-app/dist/**`: bundled UI CSS/JS/SVG assets; excluded as UI-only except for noting that the wheel carries an IDE assistant UI bundle.
- Broad PyPI wheel `black/**`, `blib2to3/**`, `lib2to3/**`, `yapf_third_party/**`, and parser resource files: vendored formatter/parser infrastructure; sampled only enough to identify dependency shape.
- Most rule YAML files under `sourcery/rules/**` and `public_rules/**`: sampled representative Python and JavaScript rules plus public rules README. Full rule catalog enumeration would be repetitive; the note focuses on rule schema, tests, and error-prevention pattern.
- Legacy GitHub wiki pages: search result confirmed they redirect users to newer docs. I used current official docs instead.
- Separate repos such as `sourcery-ai/action` and `sourcery-ai/sourcery-vscode`: relevant adjacent integrations, but outside this assignment's repo scope.
