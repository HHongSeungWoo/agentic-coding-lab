# vercel-labs/skills

- URL: https://github.com/vercel-labs/skills
- Category: skills-instructions
- Stars snapshot: 20,568 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: b469d6954dd10be20d3e8d9bb59463584d42efbb
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value reference for cross-agent skill packaging and installation conventions. Best reusable parts are source parsing, bounded `SKILL.md` discovery, plugin-manifest compatibility, canonical `.agents/skills` storage with symlink/copy fan-out, project/global lock files, update hashes, path/terminal sanitization, and a public well-known registry format. It is an installer and registry client, not an agent runtime or skill loader.

## Why It Matters

`vercel-labs/skills` is the packaging tool around the emerging Agent Skills ecosystem. It is not mainly a skill corpus. The repo answers a different question: how should skills be found, filtered, installed, shared across many agents, updated, and tracked?

For Agentic Coding Lab, this is a stronger packaging reference than most prompt collections. It shows a practical CLI surface for GitHub shorthand, GitHub tree subpaths, GitLab URLs, arbitrary git URLs, local paths, `skills.sh` search, and hosted well-known indexes. It also shows the portability problem directly: the same `SKILL.md` directory has to land in Claude Code, Codex, Cursor, OpenCode, Copilot, Goose, Kiro, OpenHands, and many other agents whose project and global paths differ.

The repo also matters because it encodes safety lessons for skill installers. Skills run with full agent permissions, so the CLI strips terminal escapes from untrusted metadata, rejects path traversal in source subpaths and install names, verifies digests for well-known v0.2 artifacts, limits archive unpacking, warns on install, and blocks one explicitly risky community source unless the user opts in.

## What It Is

`vercel-labs/skills` is a Node/TypeScript CLI published as `skills` and `add-skill` on npm. The reviewed package version is `1.5.9`, with Node `>=18`, bundled by `obuild`, and package scripts for build, Vitest, type checking, formatting, license notice generation, and snapshot publishing.

The user-facing commands are:

- `skills add <source>`: discover and install skills from GitHub, GitLab, git URLs, local paths, direct tree paths, or well-known endpoints.
- `skills find [query]`: search `https://skills.sh/api/search` and optionally install the selected result.
- `skills list` / `skills ls`: list installed project or global skills, optionally as JSON.
- `skills remove` / `skills rm`: remove skills from canonical and agent-specific locations.
- `skills update` / `skills check` / `skills upgrade`: compare lock-file hashes and reinstall changed skills.
- `skills init [name]`: create a minimal `SKILL.md`.
- `skills experimental_install`: restore project skills from `skills-lock.json`.
- `skills experimental_sync`: crawl `node_modules` for package-shipped skills and sync them into agent directories.

The repo itself contains one bundled skill, `skills/find-skills/SKILL.md`, which teaches agents when and how to search the public skill directory. The rest of the repository is the installer/runtime-adjacent tooling.

## Research Themes

- Token efficiency: Moderate. The CLI uses metadata-first discovery via `name` and `description`, preserves progressive-disclosure skill directories instead of flattening them into one file, and offers a search command that returns compact source/install hints. It does not itself optimize model context at runtime.
- Context control: Strong at packaging time. Discovery is bounded to known skill containers by default, root `SKILL.md` shadows nested files, `--full-depth` is explicit, project-installed agent skills can be ignored through `skills-lock.json`, and `.claude-plugin` manifests can declare exact skill paths.
- Sub-agent / multi-agent: Indirect. The CLI installs skills for many agent hosts and treats `.agents/skills` as a universal shared location, but it does not orchestrate subagents or multi-agent workflows.
- Domain-specific workflow: Strong for skill distribution, weak for coding domains. The domain here is skill package management: source parsing, install placement, locking, updates, registry search, and cross-agent path compatibility.
- Error prevention: Strong. The repo has path traversal checks, safe directory-name generation, terminal escape stripping, digest validation, archive path/size/file-count limits, symlink loop handling, private-repo telemetry gating, lazy GitHub token use, OpenClaw source blocking, and broad tests.
- Self-learning / memory: Minimal. It remembers last selected agents and dismissed prompts in the global lock file, but there is no semantic memory or self-learning loop.
- Popular skills: This repo does not host a large skill catalog. Its bundled `find-skills` skill is notable because the CLI prompts users to install it after the first successful interactive install.

## Core Execution Path

The main `skills add` path is:

1. `src/cli.ts` routes `add`, `a`, `i`, and `install` to `runAdd`.
2. `src/add.ts` parses options, auto-enables non-interactive `-y` behavior when it detects a supported AI agent, and auto-selects the detected agent plus universal `.agents/skills` agents when possible.
3. `src/source-parser.ts` parses local paths, GitHub shorthand, `github:` / `gitlab:` prefixes, GitHub and GitLab tree URLs, `owner/repo@skill`, `#ref` fragments, SSH URLs, direct git URLs, and arbitrary HTTP(S) well-known sources.
4. GitHub sources from allowlisted owners (`vercel`, `vercel-labs`, `heygen-com`) first try the blob fast path in `src/blob.ts`: GitHub Trees API for `SKILL.md` discovery, raw GitHub for frontmatter, and `skills.sh/api/download` for full snapshot files. Failures fall back to cloning.
5. Other git-like sources are shallow-cloned through `src/git.ts` into a temp directory with LFS smudge disabled and a configurable clone timeout.
6. `src/skills.ts` discovers skills by parsing valid `SKILL.md` frontmatter with required string `name` and `description`, skipping `metadata.internal: true` unless explicitly enabled.
7. The user or `--skill` filter selects skills; plugin groupings from `.claude-plugin/marketplace.json` or `.claude-plugin/plugin.json` are preserved for display and lock metadata.
8. Agent targets are chosen from `src/agents.ts`, either by explicit `--agent`, detected agents, universal defaults, or interactive search.
9. The installer writes either direct copies or a canonical copy plus symlinks. Project canonical storage is `./.agents/skills/<skill>`, global canonical storage is `~/.agents/skills/<skill>`.
10. Successful installs update either global `~/.agents/.skill-lock.json` or project `skills-lock.json`, then print a warning that skills run with full agent permissions.

The update path is hash-based. Global installs use lock schema v3 with GitHub tree SHAs for skill folders when available. Project installs use a deterministic SHA-256 over installed skill files. `skills update` groups skills by source, fetches a repo tree or clones as needed, compares hashes, detects deleted upstream skills, and invokes the local CLI entrypoint to reinstall updated skills.

The well-known path is separate from git. `src/providers/wellknown.ts` probes `/.well-known/agent-skills/index.json` first and legacy `/.well-known/skills/index.json` second. It supports legacy `files[]` indexes and the newer v0.2 schema with `type`, `url`, and `sha256` digest. `skill-md` artifacts install as a single `SKILL.md`; `archive` artifacts can install `SKILL.md` plus resources after digest verification and archive safety checks.

## Architecture

The architecture is a CLI plus small provider/discovery modules:

- `bin/cli.mjs`: npm bin wrapper that enables Node compile cache, then imports the built `dist/cli.mjs`.
- `src/cli.ts`: command router, help/banner, version, and `skills init`.
- `src/add.ts`: main install orchestrator, option parsing, prompts, security-audit display, telemetry gating, lock updates, and one-time `find-skills` prompt.
- `src/source-parser.ts`: source normalization for GitHub, GitLab, local paths, git URLs, refs, subpaths, and well-known fallback.
- `src/skills.ts`: `SKILL.md` parsing, bounded discovery, internal-skill hiding, `.claude-plugin` grouping, duplicate suppression, and explicit `--full-depth` behavior.
- `src/plugin-manifest.ts`: compatibility bridge for Claude Code plugin marketplace and plugin manifests, with containment checks and `./`-relative path validation.
- `src/agents.ts`: path registry for the supported agent targets, including universal `.agents/skills` users and agent-specific project/global paths.
- `src/installer.ts`: canonical/copy/symlink installer, path sanitization, symlink-loop avoidance, cross-platform symlink fallback, installed-skill listing, and well-known/blob file writing.
- `src/blob.ts`: GitHub Trees API discovery, lazy auth fallback, `SKILL.md` path selection, `skills.sh` snapshot download, and folder-hash extraction.
- `src/providers/wellknown.ts`: hosted skill index support, v0.2 digest validation, archive extraction, and legacy index compatibility.
- `src/skill-lock.ts` and `src/local-lock.ts`: global and project lock files, update metadata, selected-agent preferences, prompt dismissal, and deterministic project hashes.
- `src/update.ts`, `src/remove.ts`, `src/list.ts`, `src/find.ts`, `src/sync.ts`, and `src/install.ts`: lifecycle commands around installed skills.
- `tests/` and `src/*.test.ts`: Vitest coverage for parsing, discovery, path safety, installers, locks, updates, sync, terminal sanitization, and distribution build.
- `.github/workflows/ci.yml`, `agents.yml`, and `publish.yml`: build/test/format checks on Ubuntu and Windows, agent metadata validation/sync, and npm provenance publishing.

## Design Choices

The most important design choice is the canonical universal directory. Many agents already agree on `.agents/skills`; the CLI treats that path as the source of truth and only creates agent-specific symlinks when necessary. This reduces duplicated skill copies and gives project teams a single committed skill directory.

The second choice is bounded discovery. The CLI prioritizes the root, `skills/`, curated/experimental/system skill containers, and known agent skill directories. It walks common containers one extra level to support catalog layouts such as `skills/<category>/<skill>/SKILL.md`, but it does not recursively surface every `SKILL.md` under examples or tests unless `--full-depth` is passed.

The third choice is installer portability over runtime semantics. The CLI does not translate skill features per host. It copies or symlinks the same skill directory to each agent's expected path and leaves actual loading, tool permissions, `allowed-tools`, hooks, and context behavior to the host agent. The README compatibility table is documentation, not enforcement.

The fourth choice is multiple source channels behind one `add` command. GitHub shorthand, direct tree URLs, GitLab, arbitrary git, local paths, `owner/repo@skill`, public `skills.sh` snapshots, and well-known hosted indexes all converge to the same selection and install path.

The fifth choice is update tracking through lock files rather than package managers. Global lock entries store source, ref, skill path, GitHub folder hash, timestamps, and plugin grouping. Project lock entries are timestamp-free and sorted to minimize merge conflicts.

The sixth choice is advisory safety instead of sandboxing. The CLI warns, sanitizes, validates paths, and surfaces audit data from an external service, but installed skills are ultimately plain files that can instruct an agent to use whatever permissions the host grants.

## Strengths

- Excellent cross-agent path registry. `src/agents.ts` captures project/global install directories and detection logic for Claude Code, Codex, Cursor, OpenCode, Copilot, Gemini CLI, Goose, Kiro, OpenHands, Qwen Code, Roo, and many more.
- Practical install model. Canonical `.agents/skills` storage with symlink fan-out, copy fallback, Windows junction support, and skip logic for non-existent project agent roots makes multi-agent installs feasible.
- Strong source parsing. GitHub shorthand, tree subpaths, refs, skill filters, GitLab subgroups, SSH URLs, local paths, and arbitrary well-known URLs are represented as structured `ParsedSource` values.
- Good skill discovery defaults. The search order favors real skill containers, supports nested category catalogs, honors Claude plugin manifests, and avoids accidentally reinstalling already tracked project agent skills.
- Strong path and terminal safety. The code sanitizes install names, validates subpaths and manifest paths, strips terminal escape/control sequences from untrusted metadata, and rejects archive paths that escape the target directory.
- Useful update story. Folder tree SHAs for GitHub-backed global installs and deterministic local hashes for project installs are simple, inspectable, and more robust than comparing only `SKILL.md`.
- Good test surface. The repo has 32 test files covering installer symlinks/copying, source parsing, full-depth discovery, plugin manifests, local locks, updates, sync, well-known provider behavior, XDG paths, terminal sanitization, and distribution build.
- CI runs build, format check, and tests on Ubuntu and Windows. A separate agents workflow validates agent metadata and syncs generated README/package keyword sections.

## Weaknesses

- This is not a runtime loader. It cannot prove when a host agent will load a skill, how much context it will consume, or whether host-specific metadata such as `allowed-tools`, hooks, or `context: fork` is honored.
- Registry trust is mixed. `skills find` relies on `skills.sh` install counts and source labels, while actual skill safety still depends on inspecting upstream repos. The security audit table is advisory and non-blocking.
- GitHub blob fast install is allowlisted to a few owners and depends on the external `skills.sh/api/download` snapshot service. Other GitHub sources fall back to cloning, and stale or unavailable snapshots fall back silently.
- README telemetry wording appears stronger than the code. The README says telemetry is automatically disabled in CI, but `src/telemetry.ts` sends telemetry unless `DISABLE_TELEMETRY` or `DO_NOT_TRACK` is set; CI only adds a `ci=1` flag.
- The repo declares MIT in `package.json` and README, but the reviewed tree has no root `LICENSE` file and GitHub's REST metadata reported `license: null`. That is a packaging/legal hygiene gap.
- Well-known hosted skills get digest verification in v0.2, but update tracking remains weaker than GitHub tree-hash tracking. Well-known global lock entries carry an empty folder hash and are reported as not automatically checkable.
- `--yes` behavior can be broad. If no installed agents are detected, non-interactive install selects all agents; project installs skip many non-universal missing roots, but global installs can still target many agent-specific directories.
- Many safety checks prevent filesystem and terminal attacks, but they do not inspect the semantic content of a skill before installation. Malicious prose remains a host-agent and human-review problem.

## Ideas To Steal

- Use `.agents/skills` as the canonical shared project skill location, then symlink to agent-specific directories only when those roots exist.
- Keep source parsing structured. Represent `source type`, `url`, `ref`, `subpath`, `localPath`, and `skillFilter` explicitly so install, lock, update, and telemetry paths do not drift.
- Use bounded discovery by default and require an explicit `--full-depth` mode for unusual layouts. This avoids pulling test/example `SKILL.md` files into real installs.
- Treat plugin manifests as discovery hints, but only for local contained `./` paths. This is a useful compatibility bridge without importing remote plugin registry behavior wholesale.
- Store project skill locks as deterministic, sorted, timestamp-free JSON. That is a good pattern for team-shared skill dependencies.
- Compute update hashes over the whole skill folder, not only `SKILL.md`. Skills often carry references, scripts, assets, and examples that matter as much as the trigger file.
- Sanitize terminal output from remote metadata before printing anything in a CLI. Skill names and descriptions are untrusted input.
- Prefer digest-addressed hosted artifacts for non-git registries. The v0.2 well-known `sha256:` model is a compact pattern for static skill hosting.
- Add a small `find-skills` style discovery skill to any skill package manager so agents can explain the ecosystem without loading the whole CLI README.

## Do Not Copy

- Do not treat install success as runtime compatibility. Agentic Coding Lab should have a loader/eval layer that verifies the target agent actually discovers and activates installed skills.
- Do not rely only on public install counts or repository stars for trust. Keep source review, pinning, and local policy gates in the loop.
- Do not copy the telemetry mismatch. If docs say telemetry is disabled in CI, enforce that in `isEnabled()` or change the documentation.
- Do not make hosted registry audit data the only security gate. Advisory partner scores should complement deterministic checks and human review.
- Do not use a package license field as a substitute for a root license file if the repo is intended as a reusable open-source reference.
- Do not auto-install to every possible global agent directory in non-interactive environments without a tighter default for automation.
- Do not assume symlinks are always available. The copy fallback and Windows-specific tests are worth preserving.

## Fit For Agentic Coding Lab

Fit is high and directly in scope for the `skills-instructions` index. This repo should be mined for packaging, install, discovery, and update conventions rather than for runtime prompt methodology.

The most useful local adaptation would be an Agentic Coding Lab skill package contract with:

- `SKILL.md` frontmatter requirements.
- optional `references/`, `scripts/`, `assets/`, and `examples/` folders.
- a canonical project install path under `.agents/skills`.
- explicit compatibility metadata for supported hosts.
- a local `skills-lock.json` with deterministic folder hashes.
- source provenance fields: source type, URL, ref, skill path, and reviewed commit or digest.
- a validator that checks frontmatter, path containment, terminal-safe metadata, archive limits, and stale generated docs.

The second useful adaptation is a registry model. A small internal well-known index with digest-pinned skill artifacts would be easier to mirror and review than a live marketplace-only model. For GitHub-backed skills, folder tree SHA tracking is a simple update mechanism to copy.

The repo is less useful as a source of agent reasoning instructions. The bundled `find-skills` skill is serviceable, but the deeper value is how skills get packaged and installed across toolchains.

## Reviewed Paths

- `/tmp/myagents-research/vercel-labs-skills/README.md`: command surface, source formats, install scopes, supported agents, skill authoring, discovery paths, plugin manifest discovery, compatibility table, troubleshooting, telemetry, and related links.
- `/tmp/myagents-research/vercel-labs-skills/AGENTS.md`: contributor-facing architecture map, command list, update-checking notes, lock-file compatibility, and development commands.
- `/tmp/myagents-research/vercel-labs-skills/package.json`: npm bin surface, version, dependencies, scripts, package manager, engine, and declared MIT license.
- `/tmp/myagents-research/vercel-labs-skills/bin/cli.mjs`: npm entrypoint and compile-cache wrapper.
- `/tmp/myagents-research/vercel-labs-skills/src/cli.ts`: command routing, help text, banner, version, and `init` template generation.
- `/tmp/myagents-research/vercel-labs-skills/src/add.ts`: main install flow, options, prompts, OpenClaw block, blob/clone selection, audit display, lock updates, telemetry, and `find-skills` prompt.
- `/tmp/myagents-research/vercel-labs-skills/src/source-parser.ts`: source parsing and subpath sanitization.
- `/tmp/myagents-research/vercel-labs-skills/src/skills.ts`: `SKILL.md` parser, discovery order, full-depth mode, internal skill handling, and filtering.
- `/tmp/myagents-research/vercel-labs-skills/src/plugin-manifest.ts`: `.claude-plugin` marketplace/plugin manifest compatibility and containment validation.
- `/tmp/myagents-research/vercel-labs-skills/src/agents.ts`: supported agent registry and path conventions.
- `/tmp/myagents-research/vercel-labs-skills/src/installer.ts`: canonical install paths, symlink/copy behavior, path safety, file exclusions, well-known/blob installers, and installed-skill listing.
- `/tmp/myagents-research/vercel-labs-skills/src/blob.ts`: GitHub tree fetch, lazy auth fallback, skill path discovery, blob snapshot download, and tree-hash helpers.
- `/tmp/myagents-research/vercel-labs-skills/src/providers/wellknown.ts`: well-known discovery schemas, digest verification, archive extraction, and hosted-skill fetching.
- `/tmp/myagents-research/vercel-labs-skills/src/skill-lock.ts` and `/tmp/myagents-research/vercel-labs-skills/src/local-lock.ts`: global/project lock schema, selected-agent memory, prompt dismissal, folder hashes, and sorted lock writes.
- `/tmp/myagents-research/vercel-labs-skills/src/update.ts`, `/tmp/myagents-research/vercel-labs-skills/src/update-source.ts`, `/tmp/myagents-research/vercel-labs-skills/src/remove.ts`, `/tmp/myagents-research/vercel-labs-skills/src/list.ts`, `/tmp/myagents-research/vercel-labs-skills/src/find.ts`, `/tmp/myagents-research/vercel-labs-skills/src/sync.ts`, and `/tmp/myagents-research/vercel-labs-skills/src/install.ts`: lifecycle commands around installed skills.
- `/tmp/myagents-research/vercel-labs-skills/src/frontmatter.ts` and `/tmp/myagents-research/vercel-labs-skills/src/sanitize.ts`: YAML frontmatter parsing and terminal-safe metadata output.
- `/tmp/myagents-research/vercel-labs-skills/skills/find-skills/SKILL.md`: bundled discovery skill.
- `/tmp/myagents-research/vercel-labs-skills/tests/*.test.ts` and `/tmp/myagents-research/vercel-labs-skills/src/*.test.ts`: representative test coverage for parser, installer, update, sync, security, and compatibility behavior.
- `/tmp/myagents-research/vercel-labs-skills/.github/workflows/ci.yml`, `/tmp/myagents-research/vercel-labs-skills/.github/workflows/agents.yml`, and `/tmp/myagents-research/vercel-labs-skills/.github/workflows/publish.yml`: quality and release workflows.
- `/tmp/myagents-research/vercel-labs-skills/scripts/validate-agents.ts`, `/tmp/myagents-research/vercel-labs-skills/scripts/sync-agents.ts`, `/tmp/myagents-research/vercel-labs-skills/scripts/execute-tests.ts`, and `/tmp/myagents-research/vercel-labs-skills/scripts/generate-licenses.ts`: generated docs/metadata, test runner, and third-party license notice tooling.

## Excluded Paths

- `/tmp/myagents-research/vercel-labs-skills/.git/`: used only to identify the reviewed commit and not reviewed as source.
- `/tmp/myagents-research/vercel-labs-skills/pnpm-lock.yaml`: dependency lockfile was not deeply audited beyond confirming package-manager context.
- `/tmp/myagents-research/vercel-labs-skills/ThirdPartyNoticeText.txt`: generated dependency notices were noted but not exhaustively reviewed as a source artifact.
- Full source of every test fixture and every prompt-screen visual row case: tests were sampled by feature area; exhaustive line-by-line fixture review was not needed for packaging assessment.
- Remote services used by the CLI (`skills.sh`, `add-skill.vercel.sh`, GitHub API, raw GitHub, and well-known publisher endpoints): behavior was inferred from client code and current public repo metadata, not from private service internals.
- Candidate upstream skill repositories installable through this CLI, including `vercel-labs/agent-skills`: only this CLI repository was reviewed in this note.
