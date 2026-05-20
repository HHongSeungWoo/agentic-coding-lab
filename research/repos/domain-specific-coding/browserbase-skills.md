# browserbase/skills

- URL: https://github.com/browserbase/skills
- Category: domain-specific-coding
- Stars snapshot: 3,359 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: b2ae7283497efec71533d292b19b874dd9d0fc4e
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for browser-automation skills and web-facing domain workflows. Best reusable parts are explicit local/remote browser mode selection, accessibility snapshot loops, composable fetch/search/browser/trace/API-discovery boundaries, CDP trace artifacts, safe-browser MCP containment, and evidence-based UI testing. Biggest gaps are prompt-level permission enforcement, no visible CI/eval harness, README/package drift, mixed artifact locations, and several nonportable host assumptions.

## Why It Matters

`browserbase/skills` is a first-party Browserbase skill collection for giving coding agents web access through the `browse` CLI and Browserbase cloud sessions. It is directly relevant to domain-specific coding because the skills are not generic "browse the web" instructions. They encode concrete browser automation modes, session lifecycle rules, authenticated context handling, trace capture, UI testing protocols, API discovery from browser traffic, prospecting workflows, and a constrained browser-agent demo.

For Agentic Coding Lab, the repo is most useful as a pattern library for safe and inspectable web automation. It shows how to split broad browser capability into smaller skills: static fetch, search, interactive browser, cloud CLI, cookie sync, trace capture, offline API extraction, UI QA, and site-specific learning. It also shows the risks of a skill pack built mostly on host prompt discipline: many important boundaries are written as instructions instead of enforced by scripts or CI.

## What It Is

The repository contains 13 skill directories under `skills/`:

- `browser`: interactive local or Browserbase browser driving through `browse open`, `snapshot`, `click`, `fill`, `screenshot`, and session commands.
- `browserbase-cli`: platform operations through the official `browse` CLI, including sessions, projects, contexts, extensions, fetch, search, templates, and functions.
- `functions`: Browserbase Functions creation, local dev, publishing, and invocation.
- `fetch` and `search`: direct Browserbase API workflows for non-interactive retrieval and search.
- `cookie-sync`: local Chrome cookie export into a Browserbase persistent context.
- `browser-trace`: CDP firehose, screenshots, DOM dumps, per-page bisection, Browserbase artifact finalization, and query helpers.
- `browser-to-api`: offline OpenAPI generation from a `browser-trace` network capture.
- `ui-test`: adversarial UI testing workflow with subagents, step budgets, screenshots on failure, deterministic checks, and HTML reports.
- `autobrowse`: an outer-loop skill that runs an inner browser agent, reads traces, improves `strategy.md`, and graduates site-specific skills.
- `safe-browser`: a builder guide and Claude Agent SDK template for a runtime agent that can only call a domain-allowlisted `safe_browser` MCP tool.
- `company-research` and `event-prospecting`: Browserbase Search/Fetch powered prospecting pipelines with subagent batching, anti-hallucination rules, and HTML/CSV reports.

The top-level README also lists `site-debugger` and `bb-usage`, but those directories were not present at the reviewed commit. The repo is mostly Markdown plus Node scripts; there is no visible CI directory, and the root package manifest appears stale relative to the checked-in files.

## Research Themes

- Token efficiency: Strong for browser use. The `browser` skill repeatedly says to prefer accessibility snapshots over screenshots, and many skills route large details to `REFERENCE.md`, `EXAMPLES.md`, `references/`, or scripts. `browser-trace` and `autobrowse` push large run data to files instead of chat. Weakness: `ui-test`, `event-prospecting`, and some reference files are large enough that agents must load selectively.
- Context control: Strong separation between capability levels. `fetch`/`search` are for cheap non-interactive work, `browser` is for rendered/interacted pages, `browser-trace` listens but does not drive, and `browser-to-api` only post-processes traces. The research skills force use of wrapper scripts such as `extract_page.mjs` instead of raw ad hoc pipelines. Context control is weaker where long subagent prompts are embedded in `SKILL.md`.
- Sub-agent / multi-agent: Strong prompt patterns, especially in `ui-test`, `company-research`, `event-prospecting`, and `autobrowse`. They define coordinator versus worker roles, per-worker scopes, browse step budgets, output markers, and batching. Most enforcement is prompt-level except for script output formats and artifact checks.
- Domain-specific workflow: Very strong. Browserbase concepts are first-class: local versus remote, Browserbase Identity, verified browsers, CAPTCHA solving, residential proxies, persistent contexts, `connectUrl` CDP attach, `--keep-alive`, session release, downloads, and debugger URLs.
- Error prevention: Good browser-operation habits: always open first, snapshot before acting, re-snapshot after DOM changes, use latest refs, stop sessions, screenshot failures, and compare before/after states. `browser-to-api` redacts common secrets before persisting samples. Company/event research includes concrete anti-hallucination rules. Weakness: many "never use X" and permission rules are not machine enforced.
- Self-learning / memory: `autobrowse` is the main self-improvement loop. It records task runs, traces, summaries, messages, screenshots, and a learned `strategy.md`; the outer agent tests one hypothesis per iteration and can graduate a site-specific skill. Cookie-sync and Browserbase contexts provide session memory. There is no repo-level durable learning beyond artifacts and curated skills.
- Popular skills: Most valuable reusable patterns are in `browser`, `ui-test`, `browser-trace`, `browser-to-api`, `safe-browser`, `cookie-sync`, `autobrowse`, `company-research`, `event-prospecting`, `fetch`, `search`, `functions`, and `browserbase-cli`.

## Core Execution Path

General installation path:

1. User installs with `npx skills add browserbase/skills` or adds the Claude Code plugin marketplace and installs the Browserbase plugin.
2. The host selects a skill from `SKILL.md` frontmatter descriptions and `allowed-tools`.
3. The skill usually checks for the `browse` CLI and `BROWSERBASE_API_KEY` when remote Browserbase APIs are needed.
4. The active skill either calls `browse` directly, calls a helper script, or builds a runnable local template.

Interactive browser path:

1. Choose environment on the first `browse open`: `--local` for clean local state, `--auto-connect` for an existing debuggable Chrome profile, `--cdp` for an explicit target, or `--remote` for Browserbase.
2. Run `browse snapshot` as the default perception channel.
3. Use refs from the latest snapshot for clicks and explicit selectors for filling/extraction.
4. Re-run snapshot after each action because refs can change.
5. Use screenshots only for visual layout or debugging, then `browse stop`.

Authenticated remote path:

1. `cookie-sync` connects to local Chrome over CDP and exports cookies.
2. It filters by domain when requested and injects cookies into a Browserbase persistent context.
3. Later work creates a Browserbase session from that context, attaches via `connectUrl`, optionally persists changes back, then releases the session.

Trace and API discovery path:

1. `browser-trace` starts a second read-only CDP client against a local or Browserbase target.
2. It records `cdp/raw.ndjson`, periodic screenshots, DOM dumps, URL samples, and a manifest.
3. `bisect-cdp.mjs` buckets events by domain and per page, writing summaries and JSONL files.
4. `browser-to-api` loads network request/response buckets, optionally joins response bodies captured by `browse network on`, filters noise, normalizes endpoints, infers schemas, redacts samples, and emits OpenAPI, a client, confidence data, Markdown, and HTML.

UI testing path:

1. Main agent analyzes a diff or explores a target app.
2. It writes three planning rounds, dedupes into a test list, and assigns independent groups.
3. Subagents run only assigned tests with explicit browse step budgets and named sessions when parallelized.
4. Every result returns `STEP_PASS`, `STEP_FAIL`, or `STEP_SKIP`; failures require screenshots.
5. Main agent merges results and optionally builds a self-contained HTML report.

Safe-browser path:

1. The skill copies a Claude Agent SDK template.
2. The runtime app launches local Chromium and enables CDP `Fetch` interception for all requests.
3. The generated agent is given exactly one MCP tool, `safe_browser`.
4. That tool exposes constrained actions such as `goto`, structured HN extractors, current URL, and audit log. It does not expose raw CDP.
5. Built-in assertions require allowed HN navigation, an internal comments visit, an off-domain block, audit log evidence, and written artifacts.

Autobrowse path:

1. A task lives in `./autobrowse/tasks/<task>/task.md`; `strategy.md` grows across iterations.
2. `evaluate.mjs` runs an inner Anthropic browser agent with one `execute` tool.
3. The tool parser allows only `browse` commands and runs them without a shell.
4. Each run writes `summary.md`, `trace.json`, `messages.json`, screenshots, and a `latest` symlink.
5. The outer agent reads the trace, forms one hypothesis, edits `strategy.md`, and repeats before graduating a self-contained skill.

Company/event research path:

1. Main agent builds a profile and output directory.
2. Search and extraction go through `browse cloud search` and `extract_page.mjs`.
3. Subagents are Bash-only by instruction, batch searches/fetches/writes, and write Markdown records with frontmatter.
4. Compile scripts turn Markdown into HTML reports and CSV files.

## Architecture

The repo is a skill bundle rather than a single app:

- `README.md`: install instructions, catalog, usage examples, troubleshooting, and resource links.
- `package.json` and `tsconfig.json`: stale or aspirational root package metadata; root `bin` points to `./dist/src/cli.js`, but no `src/` or `dist/` existed in the reviewed tree.
- `agent/`: empty directories for downloads, screenshots, and custom scripts.
- `skills/<name>/SKILL.md`: trigger and main workflow instructions.
- `skills/<name>/REFERENCE.md` and `EXAMPLES.md`: expanded command/API examples for simpler skills.
- `skills/<name>/references/`: deeper workflow docs, report templates, testing patterns, browser recipes, research patterns, and examples.
- `skills/<name>/scripts/*.mjs`: helper scripts for trace capture, API discovery, research extraction/reporting, cookie sync, and autobrowse evaluation.
- `skills/safe-browser/templates/claude-agent-sdk/`: runnable constrained-agent demo.
- `skills/*/package.json` and selected lockfiles: local dependencies where needed, mainly `autobrowse`, `cookie-sync`, and the safe-browser template.

The artifact model is file-system native. Important outputs include `.o11y/<run>/`, `.context/ui-test-screenshots/`, `.context/ui-test-report.html`, `./autobrowse/traces/`, Browserbase context IDs, Browserbase session downloads/logs, safe-browser `artifacts/`, and Desktop research report directories.

## Design Choices

The central design choice is to make `browse` the browser boundary. Skills do not ask the model to directly use Playwright/CDP except inside controlled helper scripts or generated templates. This produces a small command vocabulary that agents can learn and makes local versus remote mode explicit.

The second choice is capability splitting. Static fetch/search, interactive browser, platform CLI operations, tracing, offline API inference, UI testing, cookie sync, and self-improvement are separate skills. This improves skill selection and keeps cheaper operations from opening a full browser session.

The third choice is artifact-first debugging. `browser-trace`, `ui-test`, and `autobrowse` all persist screenshots, DOM, JSONL, summaries, or messages so the next agent step can inspect evidence instead of relying on chat memory.

The fourth choice is script-backed wrappers for fragile work. `extract_page.mjs` preserves meta tags and falls back to rendered markdown; `bisect-cdp.mjs` slices noisy CDP streams into search-friendly buckets; `browser-to-api` stages load/filter/normalize/infer/emit.

The fifth choice is host-level prompt permissions rather than repo-level enforcement. `allowed-tools` is present in frontmatter, and multiple skills instruct agents to batch Bash calls to reduce approval prompts, but there is no repository validator proving those permissions or prompt contracts stay correct.

The sixth choice is explicit browser session semantics. The skills call out daemon state, named sessions, `BROWSE_SESSION`, `--keep-alive`, context persistence, release, and the difference between local browse daemon session names and Browserbase cloud session IDs.

## Strengths

- Excellent browser automation primitives: snapshot-first perception, explicit environment mode, latest-ref discipline, clean session cleanup, and remote escalation criteria.
- Good tool-boundary taxonomy: search/fetch/browser/CLI/trace/API-discovery are separate tools or skills with clear "when to use" rules.
- `browser-trace` is a strong reusable observability pattern: a second CDP client observes while the main automation drives, then artifacts are bisected into domain and page buckets.
- `browser-to-api` is a practical replay-to-spec pipeline with filtering, path templating, GraphQL/multiplexed operation decomposition, schema inference, redaction, confidence flags, and generated reports.
- `safe-browser` demonstrates a real runtime containment boundary: one MCP tool, no raw CDP passthrough, CDP Fetch interception, allowlist decisions, audit log, and assertions.
- `ui-test` encodes a serious QA loop: planning rounds, subagent budgets, deterministic checks before screenshots, before/after snapshots, failure screenshots, result markers, and report generation.
- `autobrowse` provides a compact self-improving skill loop with trace artifacts, a command-only inner agent, no-shell execution of `browse`, one-hypothesis updates, and skill graduation criteria.
- Research workflows have concrete anti-hallucination rules, structured Markdown frontmatter, report compilation, and extraction wrappers that prevent common "thin SPA page" mistakes.
- Browserbase-specific session handling is well covered: contexts, persistence, verified mode, proxy geolocation, CAPTCHA/bot-protection escalation, debugger URLs, and download artifacts.

## Weaknesses

- No visible `.github` workflows, public CI, fixture-driven evals, or repository-wide schema checks were present. Many important guarantees are only written in prompts.
- Top-level README drifts from the tree: it lists `site-debugger` and `bb-usage`, but those skill directories were absent at the reviewed commit.
- Root package metadata appears stale: `package.json` declares a `browser` binary in `dist/src/cli.js` and a TypeScript build, but the reviewed tree had no `src/`, no `dist/`, and no root TypeScript dependency.
- Skill maturity is uneven. `browser-trace`, `browser-to-api`, `safe-browser`, and `autobrowse` have real scripts or assertions; `fetch`, `search`, `browser`, and `browserbase-cli` are mostly prose wrappers around external APIs.
- Permission boundaries are mostly prompt-level. `allowed-tools` says Bash-only for many skills, but subagent restrictions such as "never WebSearch", "only Bash", and "batch all writes" are not enforced by code in this repo.
- Artifact locations are inconsistent: `.o11y/`, `.context/`, `./autobrowse/`, `~/Desktop/...`, and installed skill `profiles/` are all used. This complicates cleanup, ownership, and multi-worker operation.
- Some skills encourage writes into installed skill directories or user-global locations. `company-research` saves profiles under the skill directory, and `autobrowse` graduates to `~/.claude/skills/`.
- Several host assumptions are nonportable: macOS `open`, Desktop output paths, Claude-specific Agent/AskUserQuestion tools, Claude Agent SDK, and a hardcoded `~/Developer/scratchpad/.env` fallback in the safe-browser template.
- Some generated reports and scripts have rough edges. For example, `browser-to-api`'s HTML card method label is hardcoded as `POST`, even though the pipeline can emit regular REST operations with other methods.
- Security-sensitive flows need stronger redaction and handling. `browser-to-api` redacts common headers and PII, but cookie-sync exports real local cookies and research/report scripts can write large unreviewed outputs without a central policy layer.

## Ideas To Steal

- Split browser capability by cost and risk: search, fetch, interactive browser, trace capture, offline API extraction, UI QA, and auth context sync should be separate skills.
- Make browser mode explicit on first command. Teach agents to choose clean local, existing local Chrome, explicit CDP, or Browserbase remote based on the task and auth/protection needs.
- Prefer accessibility snapshots as the default perception channel and reserve screenshots for visual evidence or failure capture.
- Use a second CDP client for observability. Persist raw firehose, screenshots, DOM, URL samples, manifest, and per-page summaries.
- Turn traffic capture into a staged offline pipeline: pair requests/responses, filter noise, normalize endpoints, infer schemas, redact samples, emit reports, and surface confidence flags.
- Use constrained MCP tools for high-risk browsing agents. Expose task-specific actions and structured extractors, not raw CDP or arbitrary shell.
- Require UI testing result markers and failure screenshots. Combine deterministic checks, before/after snapshots, and screenshot evidence in a mergeable artifact format.
- For self-improving skills, keep `task.md`, `strategy.md`, traces, screenshots, messages, and summary files in a workspace; update one hypothesis at a time.
- Wrap fragile web extraction in scripts that preserve metadata and have rendered fallbacks. Do not make agents parse raw JSON/HTML envelopes with shell text filters.
- Include explicit anti-hallucination rules for research skills: claims must trace to extracted page fields or source snippets, and low evidence caps scoring.

## Do Not Copy

- Do not rely on prompt-only tool bans for high-risk workflows. Add validators, wrappers, or host policy where possible.
- Do not let README catalogs drift from actual skill directories. Add a catalog consistency check.
- Do not ship stale root package metadata. If the repo is only a skill bundle, remove or fix package/bin/build claims.
- Do not scatter outputs across global Desktop, installed skill dirs, and local project dirs without an ownership and cleanup policy.
- Do not copy user-specific paths such as `~/Developer/scratchpad/.env` or macOS-only `open` commands into portable templates.
- Do not expose cookie export as a casual helper without strong domain filtering, clear user consent, and redacted logs.
- Do not generate user-facing reports from observed traffic without clear caveats about coverage, inductive schemas, and secrets redaction.
- Do not copy long subagent prompt bodies wholesale. Extract the artifact contracts, budget rules, and verification gates.
- Do not treat Browserbase-specific verified/proxy/CAPTCHA behavior as generally available in other browser runtimes.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`, especially browser automation and web-facing agent workflows. The repo should be mined for reusable skill design patterns rather than adopted as an unexamined dependency.

Best direct fits:

- A browser automation skill template with explicit mode selection, snapshot-first workflow, cleanup rules, and evidence capture.
- A trace artifact contract under `.o11y/<run>/` with manifest, raw CDP, per-page summaries, screenshots, DOM, and query helpers.
- A constrained-browser MCP template that exposes only domain-specific actions and audit logs.
- A UI-test harness contract with planning rounds, step budgets, named sessions, `STEP_*` markers, screenshots, and HTML report output.
- A replay-to-API pipeline that treats coverage and redaction as first-class output fields.
- A self-improving browser skill loop with task files, strategy files, traces, one-hypothesis updates, and graduation checks.

Less direct fits:

- Browserbase credentials, verified browsers, proxy geolocation, and CAPTCHA solving are product-specific.
- Claude Agent SDK, Claude plugin marketplace, and Claude-specific subagent tools need adapters for other hosts.
- Desktop/global output paths should be replaced with repo-local owned output directories in multi-worker environments.

## Reviewed Paths

- `README.md`: catalog, install path, usage examples, local/remote guidance, and troubleshooting.
- `package.json`, `tsconfig.json`: root package/build metadata.
- `agent/browser_screenshots/.gitkeep`, `agent/custom_scripts/.gitkeep`, `agent/downloads/.gitkeep`: empty artifact directories.
- `skills/browser/SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`: core browse CLI workflow, local/remote modes, session handling, and examples.
- `skills/browserbase-cli/SKILL.md`, `REFERENCE.md`: Browserbase platform CLI boundary and command groups.
- `skills/functions/SKILL.md`, `REFERENCE.md`: Browserbase Functions workflow.
- `skills/fetch/SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`: Fetch API boundary, options, errors, and safety notes.
- `skills/search/SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`: Search API boundary, response shape, and safety notes.
- `skills/cookie-sync/SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`, `scripts/cookie-sync.mjs`: local cookie export, context creation, verified/proxy options, and CDP discovery.
- `skills/browser-trace/SKILL.md`, `REFERENCE.md`, `EXAMPLES.md`, `scripts/*.mjs`: CDP capture, snapshot loop, bisection, Browserbase finalization, and query helpers.
- `skills/browser-to-api/SKILL.md`, `REFERENCE.md`, `scripts/*.mjs`, `scripts/lib/*.mjs`: trace-to-OpenAPI pipeline, redaction, filtering, normalization, schema merge, YAML emit, client/report generation.
- `skills/ui-test/SKILL.md`, `README.md`, `EXAMPLES.md`, `references/*.md`, `references/report-template.html`: UI testing workflow, deterministic checks, adversarial patterns, parallel sessions, screenshots, and report template.
- `skills/autobrowse/SKILL.md`, `README.md`, `REFERENCE.md`, `EXAMPLES.md`, `scripts/evaluate.mjs`, `references/example-task.md`, `references/example-skill.md`: self-improving browser loop and inner-agent harness.
- `skills/safe-browser/SKILL.md`, `templates/claude-agent-sdk/package.json`, `templates/claude-agent-sdk/hn-scraper-demo.mjs`: constrained MCP tool demo and assertions.
- `skills/company-research/SKILL.md`, `references/workflow.md`, `references/research-patterns.md`, `references/example-research.md`, `references/report-template.html`, `scripts/*.mjs`, `profiles/example.json`: company research pipeline, extraction, report compiler, anti-hallucination rules.
- `skills/event-prospecting/SKILL.md`, `references/workflow.md`, `references/research-patterns.md`, `references/event-platforms.md`, `references/example-research.md`, `scripts/*.mjs`, `profiles/example.json`: event prospecting pipeline, recon/extract/report scripts, subagent batching, enrichment controls.

## Excluded Paths

- `.git/**`: VCS internals; only the reviewed commit and latest commit metadata were recorded.
- Binary, generated, and lockfile internals such as `package-lock.json` bodies: inventoried but not deeply reviewed because package dependency resolution was not central to skill design.
- Full long prompt bodies in `ui-test`, `company-research`, `event-prospecting`, and examples: reviewed for workflow shape, boundaries, artifacts, and failure modes without reproducing prompt text.
- Full HTML report template bodies and generated report CSS: sampled for artifact shape; not analyzed as UI implementation.
- Every line of large reference files such as UX heuristics, adversarial patterns, and event platform details: sampled for structure and relevance to browser automation/domain skill patterns.
- External Browserbase, Anthropic, Chrome, and Claude documentation: the review focused on checked-in repo contracts and scripts.
