# mvanhorn/last30days-skill

- URL: https://github.com/mvanhorn/last30days-skill
- Category: domain-specific-coding
- Stars snapshot: 26,770 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 1e03af19e0ad435ee6d227a3593b0c6e5d2ecbe8
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong pattern source for recency-focused research skills. Best reusable parts are the multi-source retrieval engine, host-model pre-research contract, date-windowed source adapters, evidence envelopes, raw artifact saves, degraded-run warnings, comparison fanout, and source-quality gates. Main risks are the oversized prompt contract, many host-compliance assumptions, credential-heavy source coverage, relative-only date windows, optional live evals, and manual WebSearch appendix handling.

## Why It Matters

`mvanhorn/last30days-skill` is a domain-specific agent skill for answering "what is happening right now?" questions from live social, video, market, code, and web sources. It is not just an instruction file. The runtime package combines a long `SKILL.md` contract with a Python 3.12 engine that plans queries, retrieves from many platforms, normalizes evidence, ranks by recency and engagement, clusters related items, emits model-readable evidence blocks, and persists raw research artifacts.

For Agentic Coding Lab, the repo is valuable because it tackles a common agent failure mode: answering current questions from stale model memory or shallow web search. It demonstrates a concrete workflow for recency-sensitive research: resolve the entity first, generate platform-aware subqueries, run source adapters in parallel, preserve source metadata, warn on thin evidence, and force the final synthesis to remain traceable to raw artifacts.

## What It Is

The repo packages one main Agent Skill, `last30days`, version `3.3.0`. It installs across Claude Code, Codex, Cursor, Copilot, Gemini CLI, Hermes, OpenClaw, and other Agent Skills hosts. The user-facing product is the slash-command skill; `skills/last30days/scripts/last30days.py` is the engine behind it.

The engine supports Reddit, X/Twitter, YouTube, TikTok, Instagram, Hacker News, Polymarket, GitHub, Digg, Bluesky, Truth Social, Threads, Pinterest, Xiaohongshu, grounded web search, and Perplexity. Some sources are free and public. Others need user-provided credentials, browser cookies, local CLIs, or API keys. The default framing is last 30 days, with `--days` / `--lookback-days` for relative windows and watchlist mode using 90 days.

The repo also includes configuration docs, a local SQLite store, watchlist and briefing scripts, an optional search-quality evaluator, a v3 verification script, fixtures, and roughly 90 test files covering source adapters, rendering contracts, planning, date utilities, setup, storage, competitors, and security workflow expectations.

## Research Themes

- Token efficiency: Mixed but instructive. The engine pushes large retrieval output into files and compact evidence envelopes, and docs use separate `CONFIGURATION.md`, `CONCEPTS.md`, and references. However, `SKILL.md` is around 1,700 lines and contains many operational laws, failure-mode histories, examples, and synthesis templates. The repo knows this is a problem and hoists critical laws to the top, but the skill remains heavy.
- Context control: Strong at the engine boundary. Evidence is represented as typed `SourceItem`, `Candidate`, `Cluster`, and `Report` objects, then rendered into separate raw-evidence and pass-through-footer envelopes. The skill contract tells the model which blocks to read, which to transform, and which to copy exactly. Context control is weaker in the prompt layer because compliance depends on the host model reading and obeying a long contract.
- Sub-agent / multi-agent: No general subagent framework, but comparison mode uses parallel fanout across entities. Each entity gets a separate `pipeline.run()` with its own handles, subreddits, GitHub data, and context, then results are merged into a comparison scaffold. This is a useful lightweight multi-run pattern.
- Domain-specific workflow: Very strong. The domain is live recency research, and the repo encodes concrete source affordances: Reddit comments and upvotes, X likes/reposts, YouTube transcripts, TikTok/Instagram captions and comments, HN points/comments, Polymarket odds, GitHub PR/release/repo metadata, and web-search freshness filters.
- Error prevention: Strong and explicit. There are query-trap preflights, deterministic fallback warnings, degraded-run banners, source concentration warnings, rate-limit sharing, retry-on-thin-source logic, relevance pruning, social engagement floors, Polymarket disambiguation, secret-hygiene CI, and render tests for known model failure modes.
- Self-learning / memory: Moderate. `--store`, `store.py`, `watchlist.py`, and `briefing.py` provide a persistent SQLite substrate for recurring topics, finding dedupe, deltas, and briefings. This is workflow memory, not autonomous skill self-improvement. The beta-channel process and docs encode lessons from failures, but there is no automatic learning loop.
- Popular skills: The main reusable skill is `last30days`. Related reusable components are `last30days.py`, `pipeline.py`, `planner.py`, `resolve.py`, source adapters, `render.py`, `store.py`, `watchlist.py`, `briefing.py`, `evaluate_search_quality.py`, and `verify_v3.py`.

## Core Execution Path

The normal host-driven path is:

1. The host loads `skills/last30days/SKILL.md`.
2. `SKILL.md` tells the model to run WebSearch pre-research when available, resolving X handles, related accounts, GitHub users or repos, subreddits, hashtags, creators, and current context.
3. The host model generates a JSON query plan and passes it to `last30days.py` through `--plan`. Named-entity topics are explicitly considered degraded if this step is skipped.
4. The engine resolves config, available sources, depth, requested source filters, relative date range, and optional per-source targeting flags.
5. `pipeline.run()` creates or sanitizes a `QueryPlan`, logs planner trace lines, and runs source adapters in parallel with `ThreadPoolExecutor`.
6. Each adapter returns raw dicts that are normalized into `SourceItem` records with title, body, URL, source, author/container, date, engagement, relevance hints, and metadata.
7. Normalization applies the requested date window, date confidence, source-specific fields, comment remapping, and low-confidence fallbacks.
8. `signals.py` computes local relevance, freshness, engagement, source quality, and local rank scores; weak items are pruned and URLs are deduped.
9. The pipeline can run supplemental handle searches, retry thin sources with simplified core queries, enrich GitHub stars, cluster candidates, and attach warnings.
10. `render.py` emits compact output with a badge, safety note, date/source metadata, warning blocks, model-readable evidence, source coverage, best takes, pass-through footer, and an end-of-canonical-output boundary.
11. If `--save-dir` is set, raw Markdown, JSON, or HTML artifacts are saved under `LAST30DAYS_MEMORY_DIR` or the requested directory.
12. The host model synthesizes from the raw evidence and includes the engine footer verbatim; post-engine WebSearch supplements are supposed to be appended to the saved raw file.

Headless fallback path:

1. If the host cannot do WebSearch, the skill can pass `--auto-resolve`.
2. `resolve.py` uses configured Brave, Exa, Serper, Parallel, or OpenRouter-backed search to discover subreddits, X handle, GitHub profile/repos, and news context.
3. The engine uses its internal planner or deterministic fallback if no LLM provider is configured.
4. Degraded-run and pre-research warnings make missing preflight visible in stdout, not only stderr.

Recurring monitoring path:

1. A user runs with `--store` or sets `LAST30DAYS_STORE=1`.
2. `store.py` records topics, runs, findings, sightings, and FTS rows in SQLite with URL-based dedupe.
3. `watchlist.py` runs topics on a schedule supplied by an external scheduler, hardcoding quick mode and 90-day lookback.
4. `briefing.py` turns stored findings into daily or weekly brief data.

## Architecture

The repo is a skill package plus a Python engine:

- `skills/last30days/SKILL.md`: canonical agent-facing runtime contract, output laws, planning protocol, source guidance, synthesis template, and security section.
- `skills/last30days/scripts/last30days.py`: CLI entry point, parser, save handling, competitor mode, auto-resolve bridge, store integration, and rendering dispatch.
- `skills/last30days/scripts/lib/pipeline.py`: orchestration, source availability, planning, parallel retrieval, retries, normalization, ranking, clustering, warnings, and source dispatch.
- `skills/last30days/scripts/lib/schema.py`: dataclass model for provider runtime, query plans, source items, candidates, clusters, reports, and retrieval bundles.
- `skills/last30days/scripts/lib/dates.py`: relative date range, parsing, confidence, age, and recency score utilities.
- `skills/last30days/scripts/lib/normalize.py`, `signals.py`, `relevance.py`, `dedupe.py`, `fusion.py`, `cluster.py`, `rerank.py`, `snippet.py`: source-independent evidence shaping and ranking.
- Source adapters under `scripts/lib/`: Reddit public and ScrapeCreators, X through Bird/xAI/xurl/xquik, YouTube, TikTok, Instagram, HN, Polymarket, GitHub, Digg, Bluesky, Truth Social, Threads, Pinterest, Xiaohongshu, Perplexity, and grounded web.
- `scripts/lib/resolve.py` and `categories.py`: engine-side entity and category pre-resolution.
- `scripts/lib/render.py` and `html_render.py`: compact evidence output, source coverage, footer, degraded warning, comparison output, and shareable HTML.
- `scripts/store.py`, `watchlist.py`, `briefing.py`: local persistent research memory and scheduled monitoring.
- `scripts/evaluate_search_quality.py` and `verify_v3.py`: optional regression and verification harnesses.
- `CONFIGURATION.md`, `CONCEPTS.md`, `HERMES_SETUP.md`, `CHANGELOG.md`, `docs/`: operator docs, vocabulary, release notes, search docs, and failure-mode writeups.
- `.github/workflows/validate.yml`: runs `uv run pytest` on PRs and main pushes.
- `.github/workflows/security.yml`: advisory dependency audit and TruffleHog secret scan.

## Design Choices

The central design choice is a split between the host model and the engine. The host model is responsible for pre-research, query planning, and final synthesis. The engine is responsible for retrieval, normalization, ranking, clustering, source coverage, and raw artifacts. `--plan` is the bridge between those layers.

The second choice is source diversity by adapter rather than generic web search. The engine models platform-specific signals: Reddit comments, YouTube transcripts, TikTok/Instagram captions, HN comments, Polymarket markets, and GitHub issue/PR/release metadata. This creates better evidence than web search alone, but also creates a larger credential and dependency surface.

The third choice is relative recency as the default. `dates.get_date_range()` computes UTC today minus N days. Adapters receive `from_date` and `to_date`, and web backends use freshness/date filters where possible. There is no first-class absolute `--from` / `--to`, so reproducible historical windows require code changes or controlled execution date.

The fourth choice is evidence-first rendering. The engine emits raw clusters inside comments marked "read this, do not emit verbatim" and wraps the stats footer in pass-through markers. This directly addresses model failures where agents dump raw clusters, invent section headers, append source lists, or skip the footer.

The fifth choice is visible degradation. If named-entity preflight or `--plan` is skipped, the renderer emits user-visible warning blocks. This is a strong pattern for agent skills: do not hide low-quality fallback behavior in stderr.

The sixth choice is local artifact continuity. Raw files, HTML briefs, SQLite findings, watchlists, and briefings provide a durable trail outside chat. The WebSearch supplement appendix is a good traceability idea, but it is still manually enforced by `SKILL.md` rather than written by the engine.

## Strengths

- Strong recency workflow: default 30-day lookback, `--days` override, source-specific date filtering, recency scoring, freshness modes, and warning when evidence appears stale or thin.
- Broad source coverage across social, video, code, prediction markets, public web, and niche networks. This is a practical model for "what are people saying now?" research.
- Real engine implementation with typed schema, parallel retrieval, source normalization, relevance/freshness/engagement scoring, fusion, reranking, clustering, and raw artifact rendering.
- Good entity pre-research contract. Step 0.55 forces handles, GitHub identities/repos, subreddits, category-peer communities, hashtags, creators, and current events context before retrieval.
- Useful comparison architecture. N-way comparisons fan out to full per-entity runs with per-entity targeting instead of collapsing everything into one weak query.
- Evidence artifacts are first-class: saved raw Markdown/JSON/HTML, pass-through footer, source coverage blocks, WebSearch supplement appendix protocol, SQLite findings, watchlists, and briefings.
- Quality gates are unusually explicit: query-trap refusal, degraded-run warnings, pre-research warnings, source concentration warnings, rate-limit propagation, transient retries, thin-source retry, engagement floors, Polymarket topic filters, and quality nudges.
- The test suite covers many known failures: dates, planner, rendering envelopes, source adapters, setup, competitors, raw saves, store/watchlist, security workflow, and version consistency. CI runs the pytest suite.
- Security and permissions are documented. `.env` permission warnings, macOS Keychain support, dummy-fixture policy, advisory secret scan, and explicit "does not post or mutate platform content" language are useful patterns.

## Weaknesses

- `SKILL.md` is very large and brittle. The repo mitigates this with top-loaded laws and explicit failure histories, but the underlying dependency is still host-model compliance with a long prompt contract.
- The host model must do a lot: WebSearch pre-research, JSON plan generation, correct flags, engine invocation, post-engine WebSearch supplements, saved-file appendix updates, and final synthesis formatting. Many of the strongest guarantees are instructions, not code.
- Absolute historical windows are not first-class. `--days` changes relative lookback only; there is no explicit `--from` / `--to` CLI flag for reproducible research snapshots.
- Date confidence varies by source. Normalization keeps undated items for most sources unless `require_date` is set, and evergreen YouTube fallback can keep out-of-window items for how-to topics. That is pragmatic, but it weakens strict recency claims.
- Source coverage depends heavily on credentials, local CLIs, cookies, and API keys. Free default sources are useful, but the richest results need user setup.
- WebSearch supplemental artifacts are manually appended by the host model. This can drift from what actually informed synthesis if the model forgets Step 2.5 or cannot write the file.
- Live retrieval quality eval exists but is optional and not part of default CI. `evaluate_search_quality.py` has good metrics, but no reviewed workflow ran it continuously.
- The security workflow is advisory-first: pip-audit and TruffleHog use `continue-on-error: true`. That is reasonable for onboarding, but it is not a blocking quality gate.
- Some source adapters depend on public endpoints, scraping APIs, browser cookies, or vendored X GraphQL code that may break as platforms change.
- The repo is optimized around a specific voice contract for `/last30days` output. Reusing the whole contract would import style constraints and failure histories that may not fit Agentic Coding Lab.

## Ideas To Steal

- Build recency research as a pipeline, not a prompt: pre-resolve entity identity, generate platform-aware subqueries, run adapters, normalize typed evidence, rank, cluster, warn, save artifacts, then synthesize.
- Require source diversity by design. Treat Reddit, X, YouTube, HN, Polymarket, GitHub, short video, and web as different evidence classes with different strengths.
- Emit user-visible degraded-run warnings when a high-quality path was skipped. Do not bury "fallback planner" or "no pre-research" in logs.
- Use evidence envelopes: one block for model-only raw evidence, one block for pass-through footer, and an explicit boundary that tells the model what not to emit.
- Preserve raw artifacts by default for research tools. A saved raw Markdown file plus source footer is much more audit-friendly than chat-only citations.
- Add a post-engine supplemental search budget separate from pre-research. Pre-research resolves targets; supplements fill long-form and web context gaps.
- Model source-specific confidence. Multi-source clusters should outrank single-source claims; source concentration should produce warnings.
- Use per-entity fanout for comparisons. A single query for "A vs B vs C" is usually shallower than independent runs with per-entity handles, repos, and communities.
- Keep recurrence and memory separate from one-shot search. `store.py`, `watchlist.py`, and `briefing.py` show a lightweight local pattern for trend monitoring.
- Add regression tests for exact model failure modes, especially rendering boundaries, degraded warnings, source availability, and setup/config behavior.

## Do Not Copy

- Do not copy the full 1,700-line `SKILL.md` as a general research template. Extract the contracts and implement more of them in scripts.
- Do not rely on the host model to manually append web supplements to raw files if the engine can own that artifact step.
- Do not claim a strict last-30-days window unless every source item is date-filtered or explicitly caveated.
- Do not make named-entity quality depend only on prompt discipline. Add machine checks that reject missing `--plan`, missing resolved handles, or missing subreddit/category coverage where possible.
- Do not assume all users can or should provide browser cookies and many API keys. Design graceful source coverage summaries and free-source baselines.
- Do not expose raw social content to the synthesizing model without an untrusted-content warning or prompt-injection boundary.
- Do not treat engagement as truth. Upvotes, likes, views, and odds are signals, not validation; controversial or brigaded topics need contradiction handling.
- Do not make CI advisory-only forever for a repo that handles credentials and browser tokens. Move dependency and secret checks to blocking once baselined.

## Fit For Agentic Coding Lab

Fit is high for `domain-specific-coding`, especially recency-focused research workflows for AI coding tools, agent ecosystems, libraries, and fast-moving developer communities. The repo should be mined for architecture and artifact patterns rather than adopted wholesale.

Best direct fits:

- A "recent evidence research" skill for Agentic Coding Lab candidates that uses source adapters, date windows, evidence artifacts, and visible quality warnings.
- A generic pre-research contract for named entities: resolve official handles, GitHub repos/users, community forums, category peers, and current context before querying.
- A reusable evidence schema with `source`, `published_at`, `date_confidence`, `engagement`, `snippet`, `metadata`, and `source_items`.
- A raw-artifact convention for research notes: model-readable evidence, source coverage, supplemental web appendix, and final synthesis provenance.
- A comparison fanout pattern for evaluating competing agent systems with per-entity targeting and isolated sub-runs.
- A local watchlist/briefing substrate for tracking changes in active repos, agent frameworks, and social discussions over time.

Less direct fits:

- The `/last30days` voice laws, badge, footer phrasing, and final-output style are product-specific.
- Source-specific credentials, ScrapeCreators, xAI, Bird, yt-dlp, and platform APIs need replacement or optional adapters in a lab setting.
- The long prompt contract should be reduced into smaller skills, scripts, validators, and tests before reuse.

## Reviewed Paths

- `README.md`: product description, install paths, source list, v3 feature overview, and setup claims.
- `skills/last30days/SKILL.md`: canonical agent contract, output laws, pre-research, planning, execution, synthesis, supplement, HTML, and security instructions.
- `CONCEPTS.md`: package vocabulary and Skill/Engine/Harness distinction.
- `CONFIGURATION.md`: flags, env vars, source credentials, save paths, provider priority, web backend priority, store/watchlist/briefing, and per-client patterns.
- `AGENTS.md`: contributor orientation, commands, version rules, config-doc sync rules, and security hygiene.
- `HERMES_SETUP.md`: Hermes installation and host-specific behavior.
- `pyproject.toml`: package name, version, Python requirement, pytest configuration.
- `skills/last30days/scripts/last30days.py`: CLI parser, save/output behavior, plan parsing, auto-resolve, competitor mode, store integration, and run dispatch.
- `skills/last30days/scripts/lib/pipeline.py`: source availability, orchestration, parallel retrieval, retry logic, normalization/ranking pipeline, warnings, and adapter dispatch.
- `skills/last30days/scripts/lib/schema.py`: report and evidence dataclasses.
- `skills/last30days/scripts/lib/dates.py`: relative date windows, date parsing, confidence, age, and recency score.
- `skills/last30days/scripts/lib/normalize.py`: per-source normalization, date filtering, comment remapping, source item creation, and metadata shaping.
- `skills/last30days/scripts/lib/signals.py`: source quality, relevance, freshness, engagement scoring, rank score, and pruning.
- `skills/last30days/scripts/lib/relevance.py`: token-overlap relevance model, stopwords, synonyms, and generic-token handling.
- `skills/last30days/scripts/lib/render.py`, `html_render.py`: compact output, evidence envelopes, footer, warnings, source coverage, comparison output, and HTML artifact behavior.
- `skills/last30days/scripts/lib/planner.py`: LLM planner prompt, deterministic fallback, source weighting, freshness/cluster modes, and plan sanitization.
- `skills/last30days/scripts/lib/resolve.py`, `categories.py`: engine-side auto-resolve, subreddit extraction, X/GitHub extraction, repo canonicalization, category-peer expansion, and context summary.
- Source adapters sampled in `reddit_public.py`, `reddit.py`, `reddit_enrich.py`, `xai_x.py`, `bird_x.py`, `youtube_yt.py`, `tiktok.py`, `instagram.py`, `hackernews.py`, `polymarket.py`, `github.py`, `grounding.py`, `perplexity.py`, `digg.py`, `bluesky.py`, `truthsocial.py`, `threads.py`, `pinterest.py`, `xquik.py`, and `xurl_x.py`.
- `skills/last30days/scripts/lib/env.py`: config loading, env precedence, `.env` permissions, Keychain, Codex auth handling, browser cookie extraction, and source availability helpers.
- `skills/last30days/scripts/lib/preflight.py`: keyword-trap refusal gate.
- `skills/last30days/scripts/lib/quality_nudge.py`: core-source quality score and missing/degraded source nudges.
- `skills/last30days/scripts/store.py`, `watchlist.py`, `briefing.py`: SQLite persistence, scheduled topic runs, deltas, delivery, and brief generation.
- `skills/last30days/scripts/evaluate_search_quality.py`, `verify_v3.py`: optional retrieval regression and verification tooling.
- `docs/how-search-works.md`, `docs/search-quality-eval.md`, selected `docs/solutions/**`: architecture explanation and evaluation/failure-mode docs.
- `.github/workflows/validate.yml`, `.github/workflows/security.yml`: test and advisory security workflows.
- Representative tests under `tests/`: dates, pipeline, render envelopes, planner, resolve, categories, Polymarket, GitHub, Reddit, YouTube, quality nudge, store, watchlist, security workflow, save raw per entity, competitor fanout, and version consistency.

## Excluded Paths

- `.git/**`: VCS internals; only branch, cleanliness, latest commit, and reviewed SHA were recorded.
- `skills/last30days/scripts/lib/vendor/bird-search/**`: vendored X client was inventoried and sampled only as an adapter dependency; full GraphQL implementation review was out of scope.
- `media/**` and image/audio assets under `skills/last30days/assets/**`: UI/marketing/demo assets were not relevant to research workflow design.
- `docs/test-results/**`, `test-run.log`, and generated comparison outputs: treated as historical artifacts, not current execution path.
- `fixtures/**`: sampled through tests and evaluator docs; fixture body exhaustiveness was unnecessary for workflow assessment.
- `uv.lock`: dependency lockfile was inventoried but not manually audited line by line.
- Full release-note and launch-copy prose in `release-notes.md`, `CHANGELOG.md`, and selected docs: sampled for behavior and version claims, not copied or exhaustively analyzed.
- External service documentation for Reddit, X, YouTube, ScrapeCreators, Polymarket, GitHub, Brave, Exa, Serper, Parallel, OpenRouter, and Perplexity: review focused on checked-in contracts and adapter behavior.
