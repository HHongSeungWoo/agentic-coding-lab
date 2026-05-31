# LittlePeter52012/skill-router

- URL: https://github.com/LittlePeter52012/skill-router
- Category: tool-use
- Stars snapshot: 2 (GitHub REST API, captured 2026-05-31); index row also has 2 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: fb5d566275a48a3aad858e923fe31d1041505890
- Reviewed at: 2026-05-31
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a tiny local CLI meta-skill for routing among hundreds of `SKILL.md` files, but it is not a 10,000-skill retrieval system. The core matcher is an O(n) keyword/fuzzy scorer over cached frontmatter, and optional embeddings only rerank the already-shortlisted local results.

## Why It Matters

`skill-router` is directly aimed at the runtime skill-selection problem: an agent keeps one always-loaded router skill in context, runs `skrt query "<task>"`, receives JSON with top skill paths, then reads the winning `SKILL.md`. That shape is much closer to the desired "agent uses many skills without loading all descriptions" pattern than marketplace/installer repos.

The repo is valuable because it shows a minimal implementation that can be copied quickly: local discovery, cache, top-k JSON output, pinning, configurable skill directories, CJK-aware matching, optional API-based embedding reranking, and a meta-skill that teaches agents to invoke the router. It is also valuable because its limits are clear: there is no ANN/vector index, no broad semantic candidate generation, no scale evidence beyond small synthetic tests, and no execution policy beyond returning paths.

## What It Is

SKRT is a Go CLI plus `SKILL.md` meta-skill. It scans configured local directories for files named exactly `SKILL.md`, extracts only `name` and `description` from YAML frontmatter, writes an index cache at `~/.skrt/index.json`, and returns ranked JSON results for a query.

The exposed user/agent surface is the `skrt` binary. Commands include `query`, `index`, `status`, `pin`, `dir`, `source`, `provider`, `update`, `smart-pin`, and `version`. There is no MCP server, daemon, HTTP API, or long-running process. The README explicitly positions it as a one-shot CLI, not MCP.

The package also includes a marketplace descriptor (`marketplace.json`) and an always-loaded `SKILL.md` that instructs an agent to run `skrt query`, parse the JSON, read the top result's path, and follow that skill. The repo module path and distribution docs are inconsistent: the checked-out repo is `LittlePeter52012/skill-router`, but `go.mod`, import paths, README install snippets, and `marketplace.json` refer to `github.com/skrt-dev/skill-router`.

## Research Themes

- Token efficiency: Strong practical pattern: keep only one short router skill always loaded, then load the selected skill file lazily. The output includes only rank/name/score/path/summary/reason instead of all skill descriptions.
- Context control: Query-time top-k skill selection is the main contribution. Context savings depend on the agent reliably calling the router when no already-loaded skill matches.
- Sub-agent / multi-agent: No subagent orchestration. It could be called by any agent, but there is no delegation model.
- Domain-specific workflow: Skill directories cover Antigravity, `.agents`, OpenCode, Qwen, cc-switch, Codex, Codex vendor imports, and project-local `./.agent/skills`. The matching itself is generic.
- Error prevention: Graceful fallback from API provider to local matching, ignored mirror directories to reduce duplicate skills, pinned skills, minimum score thresholds, and tests around matching/config/credentials. No permission enforcement or result verification.
- Self-learning / memory: `smart-pin` scans known chat-history locations and hard-coded skill-name patterns to suggest frequently useful pins. This is heuristic usage-based personalization, not learned routing.
- Popular skills: No bundled broad skill corpus. Test fixtures include small PDF/NotebookLM/router/brainstorming/scientific-writing examples. The real target is whatever local `SKILL.md` files the user has installed.

## Core Execution Path

1. Agent keeps `skill-router/SKILL.md` loaded. The meta-skill tells it to run `skrt query "<user request>"` when no installed skill is already obvious or the user asks to find/search for a skill.
2. `cmd/skrt/main.go` loads `~/.skrt/config.json`, defaulting to common skill directories, `top_n: 5`, `min_score: 10`, and provider-first API mode with graceful fallback.
3. If the query contains CJK, Cyrillic, or Arabic characters and an API key is available, `internal/translate` calls Gemini `generateContent` to translate the query to English. If translation fails, the original query is used.
4. `internal/index.GetOrBuild` loads `~/.skrt/index.json` when valid, or calls `Build` to walk configured directories and find files named `SKILL.md`.
5. `internal/index.Build` reads the first 4KB of each `SKILL.md`, parses frontmatter with `pkg/frontmatter`, extracts `name` and `description`, tokenizes name/description, and records absolute path, parent directory, tokens, and mtime.
6. `internal/matcher.Engine.Query` scores every indexed entry with seven local strategies: exact name, containment, description substring, token overlap, individual token substring, Levenshtein fuzzy name matching, and CJK bigram overlap.
7. Pinned skills receive a boost or forced visibility at `min_score`; configured weights can add score boosts.
8. Results are deduplicated by skill name, sorted by score, truncated to `top_n`, and ranked.
9. If API provider is active and available, `internal/provider.APIProvider.Rerank` embeds the query and the already-returned candidates, blends keyword and cosine similarity scores, and re-sorts.
10. CLI prints JSON. The agent is expected to read the top result's `path` and execute the selected skill's instructions.

## Architecture

The architecture is deliberately small:

- `cmd/skrt`: single binary command dispatcher and JSON output layer.
- `internal/config`: user config, default skill directories, provider settings, pin/weight/source config.
- `internal/index`: filesystem discovery, frontmatter extraction, cache save/load, cache validation.
- `internal/matcher`: local scoring engine.
- `internal/provider`: provider interface, local passthrough provider, API embedding provider.
- `internal/translate`: optional cross-language query translation.
- `internal/smartpin`: usage-log scanner and pin suggestions.
- `internal/updater`: managed git source pull/install hooks.
- `pkg/frontmatter`: tiny zero-dependency parser for `name` and `description`.

The router has no persistent index server. Each query loads or rebuilds a JSON cache, scores entries in process, and exits. That keeps deployment simple, but it means routing sophistication is bounded by what can be done cheaply in one CLI invocation.

## Design Choices

Local-first behavior is the real backbone, even though default config says provider-first. If API credentials are missing or API calls fail, the provider resolves to local and returns keyword results unchanged.

Discovery is intentionally format-constrained: only files named `SKILL.md` are indexed, and only frontmatter `name` and `description` are read. The skill body, examples, tools, resources, permissions, and "when not to use" text are ignored for routing.

The index is compact and cacheable. Entries store name, description, absolute path, parent dir, precomputed tokens, and modtime. This is enough for fast frontmatter-level routing, but not enough for deep semantic skill matching.

Reranking is candidate-stage only. The API provider receives the top local results after `Engine.Query` already filtered and truncated them. Embeddings therefore cannot retrieve semantically relevant skills that local keyword/fuzzy matching missed.

Pinned skills act as routing priors. Pinned matched skills get a small boost capped below strong exact/name matches; unmatched pinned skills are kept visible at `min_score`. This is a pragmatic way to keep infrastructure skills discoverable without letting them always dominate.

Cross-language routing is split between translation and CJK token matching. With an API key, non-Latin queries can be translated before English-description matching; without one, local CJK token and bigram strategies still provide partial matching.

The updater is generic and trust-assuming. Managed sources are local git repos; `skrt update` can run configured install shell commands after pulling. This helps maintain skill sources but is not a secure package manager.

## Strengths

The repo directly implements a runtime route-then-read loop. This is the right control pattern for reducing skill description context overhead: an agent sees one router skill, not the whole skill catalog.

It is easy to deploy. A single Go CLI, no database, no Python stack, no daemon, and JSON output make it easy for terminal agents to call.

The local matcher is transparent and debuggable. Scores and match reasons are explicit, and local matching continues to work offline.

The default directory list is aware of several agent ecosystems: Antigravity, `.agents`, OpenCode, Qwen, cc-switch, Codex, Codex vendor imports, and project-local skills.

The cache and bounded concurrent scan are sensible for hundreds of files. Reading only the first 4KB keeps large skill bodies out of the indexing path.

The meta-skill is a useful packaging trick. It turns the router into an agent-callable behavior without requiring host-native plugin support.

Credentials are handled better than many small repos: API keys can live in env vars or `~/.skrt/credentials` with `0600` permissions, while config stores only the env var name.

## Weaknesses

This is not a 10,000-skill semantic router. Local query time is O(n) over indexed skills, and there is no inverted index, approximate nearest-neighbor index, vector store, hierarchical taxonomy, or learned retriever.

Embedding reranking is too late in the pipeline. Since local matching truncates to `top_n` before `APIProvider.Rerank`, the embedding provider only reorders a small keyword-selected list. It does not solve synonym-heavy, body-only, or weak-description retrieval.

The router ignores skill body content. Many real skills have short generic descriptions and decisive instructions/examples later in the body. This repo cannot use that signal.

The latency claims are mixed. README and `SKILL.md` claim sub-50ms or sub-80ms routing, but the README also says API mode is about 3-5s, translation has an 8s timeout, and provider setup changes fusion timeout to 10s. The local benchmark simulates only about 205 entries, not 300, 1,000, or 10,000.

Cache invalidation is fragile. The fast cache-validity path compares the cache file mtime to skill directories and immediate child directories, not every `SKILL.md` file. Editing an existing `SKILL.md` can update the file mtime without updating directory mtime, so a stale cache can be treated as valid. There is also a checksum-order mismatch risk because build-time checksum uses concurrently collected entries without sorting, while validation checksum sorts paths.

There is no execution gating. The CLI returns paths; the agent decides what to read and do. There is no allowlist, trust score, signature, permissions metadata, sandbox boundary, or policy that prevents loading a malicious or stale skill.

The frontmatter parser is intentionally partial. It handles simple `name:` and `description:` fields, quotes, and basic multiline descriptions, but it is not a YAML parser and ignores richer metadata that would help routing.

The distribution metadata is inconsistent with the actual repository owner. `go.mod` declares `github.com/skrt-dev/skill-router`, while the reviewed repo is `github.com/LittlePeter52012/skill-router`; install snippets and `marketplace.json` also point at `skrt-dev`. That is a practical adoption risk.

The tests are useful but narrow. They cover config defaults, frontmatter parsing, local matching behavior, credential file permissions, provider selection, and ignored mirrors. They do not validate real API reranking quality, 300+ installed skills, 10,000 skills, cache invalidation edge cases, or malicious skill handling.

## Ideas To Steal

Ship the router as a skill. An always-loaded `skill-router` skill that tells the agent exactly when to call a CLI and how to read the result is a practical bridge for hosts that do not have native runtime skill retrieval.

Use a tiny JSON index as the first routing layer. `name`, `description`, `path`, `dir`, `tokens`, mtime, and source metadata are enough for a cheap first pass, and the agent never needs the full catalog in context.

Return absolute `SKILL.md` paths in JSON. This makes the next action deterministic: the agent can read the selected file instead of guessing package names.

Expose match reasons. `exact_name`, `name_in_query`, `desc_substring`, `keyword_match`, and similar reasons are useful debugging telemetry for skill routing.

Add pins and weights as operator controls. Runtime routing will always need manual priors for infrastructure skills and user-specific workflows.

Keep local fallback mandatory. A skill router should still work without network, model credentials, or provider uptime.

Add usage-driven maintenance. `smart-pin` is crude, but the direction is right: logs and activation history should feed pruning, pinning, aliases, and routing metadata.

Support cross-host directory defaults. Skill sprawl is multi-client; a useful router should discover Codex, Claude-style, Cursor/OpenCode, Gemini/Qwen, project-local, and vendor-import locations with explicit precedence.

## Do Not Copy

Do not rerank only after truncating to top-N keyword matches. For 10,000 skills, embeddings or lexical indexes must participate in candidate generation before final reranking.

Do not rely only on `description` frontmatter. Build routing documents from name, description, body headings, "when to use", "when not to use", examples, tools, file globs, permissions, owner, source, and observed activation outcomes.

Do not treat sub-50ms README claims as proven. Require benchmark fixtures at 1k, 10k, and 100k skills, with cold cache, warm cache, local-only, lexical retrieval, embedding retrieval, and reranking separated.

Do not use directory mtime as the only fast cache invalidation guard. Track per-file mtimes/content hashes or use a watcher/index build step.

Do not make provider-first the default if the product promise is low-latency local routing. API reranking and translation must be explicit, budgeted, cached, or run after a wider local retrieval stage.

Do not execute configured update/install shell commands as part of a trusted skill-management story without separate permission prompts, provenance, and audit logs.

Do not ship ambiguous module/repo install metadata. A router is infrastructure; install path drift breaks adoption immediately.

## Fit For Agentic Coding Lab

This repo is a good lightweight prototype for the "one always-loaded router skill" artifact. The most reusable pieces are the CLI contract, JSON output shape, meta-skill instructions, path-based lazy loading, pins/weights, and match-reason telemetry.

For Agentic Coding Lab's target problem, it should be treated as a baseline, not the final architecture. A production design should add a two-stage retriever: deterministic filters by project/host/category/tool/file-glob/trust, then lexical or vector candidate generation over richer skill documents, then rerank to a short context budget. The runtime should expose `search_skills`, `read_skill`, `record_skill_activation`, and `record_skill_feedback` surfaces, and it should persist activation metrics for pruning and alias generation.

The repo is practically useful if the local library has tens to a few hundreds of well-described `SKILL.md` files. It is not sufficient evidence for "give the agent 10,000 skills and it will find the right one without context issues."

## Reviewed Paths

- `README.md`: product claims, CLI reference, architecture diagram, provider/translation notes, non-MCP positioning, latency claims.
- `SKILL.md`: always-loaded meta-skill instructions and agent route-then-read workflow.
- `marketplace.json`: marketplace/distribution metadata and compatibility claims.
- `go.mod`: module path and Go version metadata.
- `cmd/skrt/main.go`: CLI command dispatch, query flow, provider setup/status, source/update/smart-pin command surfaces, JSON output.
- `internal/index/builder.go`: SKILL.md discovery, first-4KB frontmatter scan, token generation, concurrent indexing.
- `internal/index/cache.go`: cache save/load/validation, checksum path, cache invalidation assumptions.
- `internal/index/types.go`: index and skill entry schema.
- `internal/matcher/engine.go`: seven-strategy local scorer, pin/weight handling, dedupe, top-N truncation.
- `internal/provider/provider.go`, `internal/provider/local.go`, `internal/provider/api.go`: provider abstraction, local passthrough, embedding rerank and fusion.
- `internal/translate/translate.go`: CJK/Cyrillic/Arabic detection and Gemini translation fallback path.
- `internal/config/config.go`: default directories, provider defaults, source config, pins/weights.
- `internal/credentials/credentials.go`: API key resolution and `0600` credentials storage.
- `internal/smartpin/analyzer.go`: usage-log scanning and pin suggestion heuristics.
- `internal/updater/updater.go`: managed git source pull and install-command execution.
- `pkg/frontmatter/parser.go`: minimal frontmatter parser.
- `internal/*/*_test.go`, `pkg/frontmatter/parser_test.go`, `testdata/skills/*/SKILL.md`: available tests and fixture scope.
- `Makefile`: build/test/bench/release targets.

## Excluded Paths

No generated, vendored, binary, or UI-only paths were present in the checkout. I did not execute provider setup or live embedding/translation calls because that would require user API credentials and would not test the checked-in implementation deterministically. I did not run upstream Go tests or benchmarks because this environment has no `go` binary available through `rtk` (`rtk go test ./...` and the benchmark command failed before execution with "No such file or directory").
