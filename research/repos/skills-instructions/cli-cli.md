# cli/cli

- URL: https://github.com/cli/cli
- Category: skills-instructions
- Stars snapshot: 44,629 (GitHub REST API, captured 2026-05-29; matches index row)
- Reviewed commit: f96972ce1c11fdb8eaa556257fde962a363dffde
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal implementation reference for skill package discovery, preview, install, update, and publish flows inside the official GitHub CLI. The broad GitHub CLI repo is out of scope overall, but the `gh skill` subsystem is directly relevant to skill-management-routing because it avoids a preloaded mega-catalog, uses query-time GitHub Code Search, caps and deduplicates result sets, previews skill trees before install, injects source provenance into `SKILL.md`, records lock metadata, supports version pinning, and validates Agent Skills authoring conventions.

## Why It Matters

`cli/cli` now contains a first-party `gh skill` preview command. This matters because it is not just another skill corpus: it is a production-style CLI surface for finding, inspecting, installing, updating, and publishing Agent Skills from GitHub repositories.

For Agentic Coding Lab's skill-routing problem, the most important lesson is how it handles scale without loading every skill description into model context. Search happens at query time through GitHub Code Search against `SKILL.md` files. The CLI then bounds enrichment work, ranks by compact metadata, caps duplicate skill names, and offers interactive filtering. This is closer to a "catalog retrieval layer" than a model-side runtime router.

The second important lesson is supply-chain metadata. Installed skills get source information injected into frontmatter: repository URL, resolved ref, source path, tree SHA, and optional pin. That metadata is then used by `gh skill update` and by provenance checks for re-published skills. This is a practical answer to the stale/duplicate/unknown-origin skill problem.

## What It Is

`gh skill` is a preview command group in the GitHub CLI. The root command is registered from `pkg/cmd/root/root.go` and implemented under `pkg/cmd/skills`. It has these subcommands:

- `gh skill search <query>`: search public GitHub repositories for matching `SKILL.md` files.
- `gh skill preview <repository> [<skill>]`: render a skill tree and `SKILL.md` without installing.
- `gh skill install <repository> [<skill[@version]>]`: install remote or local skills into agent-specific paths.
- `gh skill update [<skill>...]`: scan installed skills and re-download changed upstream versions.
- `gh skill publish [<directory>]`: validate a local skills repo and create a GitHub release.

The command is marked preview and aliased as `gh skills`. It supports GitHub.com and GHE data-residency hosts (`*.ghe.com`), while GitHub Enterprise Server is explicitly rejected for GitHub Skills.

## Research Themes

- Token efficiency: Strong for catalog access. It does not preload a global skill list; it retrieves candidates by query, processes only a bounded slice, fetches descriptions lazily for top candidates, and displays compact rows. It is not a runtime prompt compressor.
- Context control: Strong at install/discovery time. It discovers `SKILL.md` by convention, supports exact path installs to avoid whole-repo traversal, previews file trees before install, limits previewed extra files, and stores full skill directories instead of flattening resources into one prompt.
- Sub-agent / multi-agent: Indirect. It installs the same skill into many agent hosts and deduplicates shared `.agents/skills` destinations, but it does not orchestrate subagents.
- Domain-specific workflow: Strong for the skill supply-chain domain: search, preview, host path selection, provenance injection, update scanning, and publisher validation.
- Error prevention: Strong on filesystem/provenance checks, moderate on semantic safety. It blocks path traversal, skips local symlinks, excludes hidden host directories by default, warns about prompt injection and scripts, checks re-published upstream metadata, validates publish metadata, and advises secret/code/dependency scanning. It does not sandbox installed skill behavior.
- Self-learning / memory: Minimal. It records installs in `~/.agents/.skill-lock.json`, scans installed frontmatter on update, and emits privacy-gated telemetry; there is no model memory or adaptive routing loop.
- Popular skills: The repo does not host skills. Popularity is inferred during search from repository stars, with examples and acceptance tests using `github/awesome-copilot`.

## Core Execution Path

`gh skill search` starts with GitHub Code Search, not a maintained local catalog. For a query, it runs multiple searches: content search for `filename:SKILL.md`, path search with spaces normalized to hyphens, owner search when the query looks like a GitHub owner, and an extra hyphenated content search for multi-word queries. `--owner` scopes those searches to a user or organization.

Search then deduplicates by repository, namespace, and skill name. It pre-ranks before expensive metadata fetches, truncates the working set to roughly `page * limit * 3`, fetches frontmatter descriptions and repository stars concurrently, filters weak matches, ranks by name/namespace/description/star signals, and keeps at most three results per qualified skill name. The default limit is 15, page fetches use 100 raw Code Search results, and the hard API ceiling is 1,000 results.

Interactive search can multi-select results and then invokes the local `gh skills install` command for each selected result. It does not force preview first. The safer review path is available through `gh skill preview`, and the install command prints exact preview commands after install.

`gh skill preview` resolves a repository ref, discovers skills, filters hidden-directory skills unless `--allow-hidden-dirs` is set, lets the user select a skill if needed, fetches the skill's file tree, renders `SKILL.md` with frontmatter stripped, and either dumps all files through the pager or offers an interactive file picker. Non-interactive preview requires an explicit skill. Extra-file rendering is bounded to 20 files and 512 KiB total.

`gh skill install` resolves source, version, skill selection, target host, target scope, overwrite behavior, and provenance before writing files. Version resolution uses explicit `@version` or `--pin` first, then latest release, then default branch only when the repo has no usable latest release. A skill path such as `skills/name` or `plugins/ns/skills/name` takes a fast path through the Contents API and avoids full tree traversal. Name-based install discovers the repository tree, fetches descriptions for interactive selection, and blocks ambiguous or colliding selections.

Actual writing is handled by `internal/skills/installer`. Remote installs fetch the skill subtree by tree SHA, fetch every blob, block path traversal with `safepaths`, write files under the selected host directory, and inject GitHub metadata into `SKILL.md`. Local installs copy files from disk, skip symlinks, block traversal defensively, and inject `local-path` metadata.

`gh skill update` does not rely only on the lock file. It scans known agent host directories, parses installed `SKILL.md` frontmatter, groups skills by source repository, resolves the current upstream ref once per repo, rediscovers remote skills once per repo, compares stored tree SHA to remote tree SHA, skips pinned skills unless `--unpin` is set, and reinstalls changed skills with the same installer.

`gh skill publish` validates local skills before release. It checks Agent Skills naming, required frontmatter, description length, `allowed-tools` shape, unwanted install metadata, recommended license, long body size, unignored installed-skill directories, repository security settings, tag protection, the `agent-skills` topic, tag selection, immutable releases, pushed commits, and release creation.

## Architecture

The `gh skill` subsystem is split cleanly:

- `pkg/cmd/skills/skills.go`: top-level command, preview warning text, aliases, examples, telemetry sampling, and subcommand registration.
- `pkg/cmd/skills/search/search.go`: Code Search queries, result ranking, enrichment, deduplication, JSON/table output, and interactive install handoff.
- `pkg/cmd/skills/preview/preview.go`: ref resolution, skill selection, hidden-directory filtering, file tree rendering, markdown rendering, pager/file-picker behavior, render limits, and preview telemetry.
- `pkg/cmd/skills/install/install.go`: repo/local source handling, version parsing, path-vs-name selection, upstream provenance detection, host/scope selection, overwrite prompts, warning text, install plans, post-install review hints, and install telemetry.
- `pkg/cmd/skills/update/update.go`: installed-skill scanning, frontmatter metadata parsing, missing metadata prompts, grouped upstream checks, pinned-skill handling, dry-run/all/force behavior, and reinstall flow.
- `pkg/cmd/skills/publish/publish.go`: local authoring validation, metadata stripping, repo topic/tag/release flow, and advisory security checks.
- `internal/skills/discovery`: remote and local discovery conventions, ref resolution, tree traversal, blob fetching, hidden-dir partitioning, strict spec-name checks, and exact path lookup.
- `internal/skills/frontmatter`: YAML frontmatter parsing, metadata serialization, GitHub provenance injection, and local-path metadata injection.
- `internal/skills/installer`: remote/local file copying, path containment, concurrency, metadata injection, and lockfile recording.
- `internal/skills/registry`: supported agent host IDs and project/user install directories.
- `internal/skills/lockfile`: Vercel-compatible global lock schema v3 under `~/.agents/.skill-lock.json`.
- `internal/skills/source`: canonical source repository URLs and supported host validation.
- `acceptance/testdata/skills` and `pkg/cmd/skills/*_test.go`: acceptance and unit coverage for search, preview, install, update, publish, metadata, pins, hidden dirs, and provenance behavior.

## Design Choices

The strongest design choice is query-time discovery. `gh skill search` treats GitHub itself as the skill index by searching `SKILL.md` files, then limits enrichment. This avoids putting a giant skill catalog or many skill descriptions into the CLI or model context.

The second choice is path conventions instead of manifests for discovery. The matcher recognizes `skills/<name>/SKILL.md`, `skills/<namespace>/<name>/SKILL.md`, nested `.../skills/...`, `plugins/<namespace>/skills/<name>/SKILL.md`, and root-level `<name>/SKILL.md`. Hidden host install directories such as `.claude/skills` and `.agents/skills` are recognized separately and excluded by default.

The third choice is loose install compatibility but stricter publishing. Discovery accepts filesystem-safe names with uppercase, underscores, dots, and spaces for compatibility. Publishing enforces the stricter Agent Skills convention: lowercase alphanumeric plus hyphens, no leading/trailing/consecutive hyphens, max 64 characters, and frontmatter `name` matching the directory.

The fourth choice is provenance-in-frontmatter. Installed `SKILL.md` files carry `metadata.github-repo`, `github-ref`, `github-tree-sha`, `github-path`, and optional `github-pinned`. This makes an installed skill self-describing even without consulting a separate lock file.

The fifth choice is host-path registry rather than runtime integration. The CLI knows where Copilot, Claude Code, Cursor, Codex, Gemini CLI, OpenCode, Goose, Kiro, Windsurf, Warp, and many other hosts expect skills. It does not verify whether those hosts actually load or route the skill.

The sixth choice is advisory security around untrusted prose and scripts. The installer warns, suggests review, excludes hidden installed copies by default, checks upstream provenance, and blocks filesystem escape. It does not perform semantic prompt-injection scanning before install.

## Strengths

- Search scales without a monolithic catalog. It uses Code Search, over-fetches conservatively, truncates before enrichment, and fetches only descriptions/stars for a bounded working set.
- Ranking is explainable. Exact skill-name matches beat partial matches, namespace and description matches are secondary, and repository stars are a square-root bonus rather than the dominant signal.
- Aggregator flood control is explicit. The search path caps each qualified skill name to three sources so copied popular skills do not fill the result list.
- Preview is useful and bounded. It shows the file tree, strips frontmatter for `SKILL.md`, renders Markdown, fetches extra files on demand in interactive mode, and limits non-interactive extra-file output.
- Exact path install is a practical escape hatch for large repos. If a repository tree is too large for recursive discovery, the CLI tells users to install by path, which uses narrower Contents and tree calls.
- Provenance metadata is concrete. Updates and upstream checks can use repository URL, ref, source path, tree SHA, and pin status from the installed `SKILL.md`.
- Re-published skill detection is a valuable trust signal. If installed content already contains `github-repo` metadata pointing elsewhere, the CLI warns and can redirect to upstream.
- Cross-host install directories are extensive and deduplicated. Multiple selected hosts that share `.agents/skills` are grouped into one install plan.
- Publish validation addresses context hygiene. It warns when descriptions exceed 1,024 characters and when skill bodies exceed 500 lines, which directly targets skill description/context bloat.
- Safety tests cover path traversal, symlink skipping, hidden-dir filtering, lockfile recovery, pins, namespaced collisions, preview render caps, and telemetry privacy cases.

## Weaknesses

- It is not a runtime skill router. The CLI can find and install skills, but host agents still decide what descriptions enter context, how activation works, and whether resource loading is lazy.
- Search depends on GitHub Code Search availability, rate limits, and public indexing. Private repos are not searched globally, and broad query quality depends on `SKILL.md` frontmatter discipline.
- Search ranking is shallow by design. It does not run semantic embedding retrieval, description evals, usage quality scoring, trust labels, or maintainer reputation beyond repository stars.
- Preview-before-install is encouraged but optional. Interactive search can go straight to install; install prints warnings and post-install preview commands rather than requiring review before writes.
- Security is mostly advisory after filesystem containment. Prompt injection, malicious instructions, and dangerous scripts remain human/host-agent review problems.
- The global lock file is supplementary. `gh skill update` primarily scans installed `SKILL.md` metadata, while `~/.agents/.skill-lock.json` is global and Vercel-compatible rather than a project dependency lock.
- Namespaced skills are installed flat by base `Name`, while some displayed and lockfile identifiers use `namespace/name`. The code intentionally blocks same-base-name collisions, but consumers must not infer physical paths from display names.
- Hidden host directories are tricky. Excluding them by default is the right safety posture, but `--allow-hidden-dirs` can still install copied skills whose canonical upstream is uncertain.
- Publish checks are not a full supply-chain gate. It recommends secret scanning, push protection, code scanning, Dependabot, tag protection, immutable releases, and license metadata, but many are warnings or best-effort API probes.
- Host compatibility is path-based. `allowed-tools`, permissions, hooks, MCP servers, and loader semantics differ across agents and are not normalized by this CLI.

## Ideas To Steal

- Build a two-stage skill catalog: external search/index first, short candidate shortlist second, full skill content only after explicit preview or activation.
- Keep always-visible skill metadata compact. `name`, `namespace`, `description`, path, source repo, stars/trust, and pin status are enough for selection surfaces.
- Add result-set flood control by qualified skill name so aggregator repos cannot dominate search results.
- Support exact path install and preview as a first-class route for huge repos. This is the practical fix when recursive tree discovery is too expensive or truncated.
- Inject provenance into installed skill files, not only sidecar state. Frontmatter survives copy/move and lets future tools update or audit skills.
- Store source path plus tree SHA. Comparing whole skill-folder tree SHA is better than comparing only `SKILL.md` because skills often include scripts and references.
- Treat hidden agent directories as suspect copied installs. Exclude by default and require an explicit flag plus warning to import from them.
- Separate compatibility discovery from publish validation. Runtime loaders can be lenient; publisher tooling can be strict and actionable.
- Print exact preview commands using the installed commit SHA after install. This turns review into a reproducible command, not a vague suggestion.
- Deduplicate install plans by destination directory. Multi-agent installs should not write duplicate skill copies when hosts share `.agents/skills`.

## Do Not Copy

- Do not make stars a trust score. Stars are useful for tie-breaking search results, not for safety or correctness.
- Do not rely on Code Search as the only registry if private/internal skill governance matters. Internal systems need curated indexes, review state, and policy metadata.
- Do not let install be the first moment a user sees risky content for high-trust workflows. Require preview or policy review for untrusted sources.
- Do not treat source frontmatter as cryptographic provenance. `github-repo` metadata can be copied or forged; pinning, release immutability, signatures, or reviewed digests are separate controls.
- Do not assume path installation equals runtime activation. Agentic Coding Lab still needs loader tests that prove each host discovers the skill and does not over-inject descriptions.
- Do not ignore namespace/display/path mismatches. If adopting flat installation, keep UI, locks, update filters, and physical paths unambiguous.
- Do not use a global-only lock file for team skill dependencies. Project-level reproducibility needs a committed lock or manifest with reviewed refs/digests.
- Do not copy the broad host registry without validation. Host paths drift, and some hosts may require extra resource registration or loader configuration.

## Fit For Agentic Coding Lab

Fit is conditional but high for the `gh skill` subsystem. The rest of `cli/cli` is a general GitHub CLI and should remain out of scope. The skill command is directly useful as a packaging, search, and update reference.

For Agentic Coding Lab, the best local adaptation would be a skill manager with:

- a compact machine-readable skill index used for retrieval, not for prompt preloading;
- deterministic filters before LLM selection: project, host, task type, path/glob, maturity, trust, and permissions;
- query-time search over installed and remote skill metadata;
- preview-before-install as a required policy for unreviewed sources;
- installed `SKILL.md` provenance metadata plus a project lock file;
- path-based install/preview for large repos;
- hidden-directory import warnings;
- re-published-skill upstream detection;
- validators for name, description length, body length, `allowed-tools`, metadata stripping, and dependency/script risk.

The repo is less useful for runtime activation design. It does not answer how many installed skill descriptions should enter an agent's base prompt, how to evaluate trigger false positives, or how to preserve active skills through compaction. Those concerns need a separate host-side router/eval layer.

## Reviewed Paths

- `/tmp/myagents-research/cli-cli/pkg/cmd/root/root.go`: registration of the `skills` command in the main GitHub CLI command tree.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/skills.go`: top-level command group, preview status, aliases, examples, subcommand registration, and telemetry sampling.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/search/search.go`: Code Search queries, pagination, truncation, enrichment, ranking, duplicate collapse, output modes, rate-limit handling, and interactive install handoff.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/preview/preview.go`: preview resolution, skill selection, hidden-directory filtering, file tree rendering, markdown rendering, pager/file picker behavior, render limits, and telemetry.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/install/install.go`: remote/local install flow, version parsing, path-based lookup, discovery, selection search, collisions, host/scope plans, overwrite prompts, upstream provenance checks, warnings, review hints, and telemetry.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/update/update.go`: installed-skill scanning, metadata parsing, repo grouping, update detection, pinned handling, dry-run/all/force behavior, and reinstall flow.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/publish/publish.go`: Agent Skills validation, metadata cleanup, security diagnostics, git remote detection, topic/tag/release flow, and immutable release guidance.
- `/tmp/myagents-research/cli-cli/internal/skills/discovery/discovery.go`: path conventions, hidden-dir conventions, ref resolution, tree traversal, exact path lookup, blob fetching, local discovery, name validation, and spec compliance.
- `/tmp/myagents-research/cli-cli/internal/skills/discovery/collisions.go`: same-base-name collision detection for flat installs.
- `/tmp/myagents-research/cli-cli/internal/skills/frontmatter/frontmatter.go`: YAML parsing, GitHub metadata injection, local metadata injection, and serialization.
- `/tmp/myagents-research/cli-cli/internal/skills/installer/installer.go`: remote and local installation, bounded concurrency, path containment, symlink skipping, metadata injection, and lockfile recording.
- `/tmp/myagents-research/cli-cli/internal/skills/registry/registry.go`: supported agent registry, default GitHub Copilot target, shared `.agents/skills`, project/user path resolution, and scope labels.
- `/tmp/myagents-research/cli-cli/internal/skills/lockfile/lockfile.go`: global `.skill-lock.json` schema, Vercel lock version compatibility, source URL/path/hash fields, pinned refs, and file locking.
- `/tmp/myagents-research/cli-cli/internal/skills/source/source.go`: canonical source URL construction, metadata repo parsing, and supported-host validation.
- `/tmp/myagents-research/cli-cli/pkg/cmd/skills/*/*_test.go`: unit tests for command parsing, search ranking/deduplication, preview limits, install pins/hidden dirs/upstream redirects/collisions, update scanning, and publish validation.
- `/tmp/myagents-research/cli-cli/internal/skills/*/*_test.go`: tests for discovery conventions, exact path lookup, truncated tree fallback, metadata injection, path traversal blocking, registry paths, and lockfile recovery.
- `/tmp/myagents-research/cli-cli/acceptance/testdata/skills/*.txtar`: acceptance coverage for search, preview, install, local install, pinning, hidden dirs, namespaced installs, update, and publish lifecycle.
- `https://api.github.com/repos/cli/cli`: current star, license, default branch, and repository metadata snapshot.

## Excluded Paths

- `/tmp/myagents-research/cli-cli/.git/`: used only to capture the reviewed commit.
- General GitHub CLI commands under `/tmp/myagents-research/cli-cli/pkg/cmd/*` unrelated to `skills`: excluded except `pkg/cmd/root/root.go` registration.
- General API, git, table, markdown, prompter, telemetry, and iostream utility packages: only read indirectly through `gh skill` call sites where needed.
- `/tmp/myagents-research/cli-cli/README.md`, `/tmp/myagents-research/cli-cli/docs`, and `/tmp/myagents-research/cli-cli/.github`: searched for `gh skill`, Agent Skills, and `SKILL.md`; no high-signal skill command docs were found beyond code/tests.
- Acceptance tests unrelated to `skills`: excluded because the review scope is the `gh skill` subsystem.
- Full dependency lockfiles, generated assets, shell completions, packaging scripts, and release infrastructure outside the skill command: not relevant to skill-management-routing.
- External repositories installable by `gh skill`, including `github/awesome-copilot`: not reviewed here except as fixtures/examples in tests.
