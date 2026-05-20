# sanjeed5/awesome-cursor-rules-mdc

- URL: https://github.com/sanjeed5/awesome-cursor-rules-mdc
- Category: domain-specific-coding
- Stars snapshot: 3,507 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 8fbf26908531c127a6076be0e55fbe17b57fb2d8
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a generated Cursor `.mdc` rule corpus and taxonomy source for domain-specific coding instructions. Best reusable parts are the library inventory, frontmatter convention, tag-driven section selection, and prompt recipe for opinionated example-heavy rules. Do not adopt wholesale: installation is manual, globs are often too broad, provenance is weak, and verification is mostly absent.

## Why It Matters

`awesome-cursor-rules-mdc` is a large public example of turning technology-specific best practices into Cursor project rules. It matters because it shows how a broad language/framework/tool taxonomy can be converted into many scoped instruction artifacts with a shared shape: YAML frontmatter, target globs, a short description, and a markdown body with concrete coding guidance.

For Agentic Coding Lab, the useful question is not whether these generated rules are individually correct. The useful pattern is how to mass-produce and maintain domain-specific coding instructions: keep a structured inventory, infer relevant file scopes, select topic sections from tags, cache research inputs, track generation progress, and produce portable rule files. The main caution is that generated guidance without source-level validation becomes a pattern mine, not a trusted rule dependency.

## What It Is

The repository is a Python-based generator plus a checked-in generated corpus of Cursor MDC rules. `rules.json` defines 241 libraries and technologies with tags. `src/generate_mdc_files.py` uses Exa search plus LiteLLM to generate one `.mdc` file per library into `rules-mdc/`. The current generated output contains 241 `.mdc` files, plus two stale `.md` duplicates (`docker.md` and `vim.md`) in the same directory.

The generated catalog is broad: languages, frameworks, testing tools, ORMs, cloud services, CI/CD platforms, AI/LLM libraries, frontend component systems, data science libraries, game engines, editors, and API tools. The top tags in `rules.json` are `python` (83), `javascript` (54), `framework` (36), `development` (32), `ai` (31), `ml` (31), `backend` (24), `cloud` (21), `frontend` (21), and `database` (18).

The repo also carries `rules-v0-deprecated/`, a much larger older corpus with 879 `.mdc` files across 132 directories. That deprecated tree appears to be a conversion or source-history artifact, not the current generation path. The current path is the flat `rules-mdc/` directory generated from `rules.json`.

## Research Themes

- Token efficiency: Mixed. One rule per library is easy to retrieve selectively, and frontmatter globs can narrow activation. But many generated files are long and code-heavy; six generated `.mdc` files exceed the generator prompt's own under-500-line target, and broad globs like `**/*` can pull large generic rules into unrelated work.
- Context control: Moderate. Every reviewed generated file has frontmatter with `description` and `globs`, and the repo includes Cursor rule reference docs explaining project, user, team, and `AGENTS.md` rule types. Control weakens because 82 generated files use `**/*`, no `alwaysApply` policy is generated for current `.mdc` files, and no installer maps files into Cursor's newer `.cursor/rules/<rule>/RULE.md` folder format.
- Sub-agent / multi-agent: Weak. The repo has no sub-agent runtime, handoff format, task fan-out, or review loop. It is a static rule generator and corpus.
- Domain-specific workflow: Strong as a catalog. Rules cover concrete domains such as React, Next.js, FastAPI, Docker, GitHub Actions, LangChain, OpenAI, Terraform, Kubernetes, Prisma, Postman, PyTorch, Selenium, and game/UI frameworks. Some generated rules contain useful task-specific sections for architecture, errors, security, tests, deployment, and anti-patterns.
- Error prevention: Moderate inside individual rules, weak at repo level. Many generated bodies include bad/good examples and testing sections. The repo itself does not validate rule correctness, frontmatter scope quality, generated code examples, current framework versions, or source citations.
- Self-learning / memory: Limited. `src/mdc_generation_progress.json` tracks 241 completed libraries, and Exa results are cached when generation runs. There is no feedback loop from user outcomes, issue fixes, local adoption, or failed Cursor interactions.
- Popular skills: High-signal rule candidates for reuse study include `react.mdc`, `next-js.mdc`, `fastapi.mdc`, `docker.mdc`, `python.mdc`, `openai.mdc`, `langchain.mdc`, `github-actions.mdc`, `terraform.mdc`, `pytest.mdc`, `prisma.mdc`, and `kubernetes.mdc`.

## Core Execution Path

The intended generation path is:

1. A maintainer edits `rules.json`, adding a library name and tags.
2. The maintainer installs Python dependencies with `uv sync`.
3. The maintainer sets `EXA_API_KEY` plus one LLM provider key, with Gemini as the configured default.
4. `uv run src/generate_mdc_files.py` loads `src/config.yaml`, validates environment variables, reads `rules.json`, and initializes a progress tracker.
5. For each selected library, the script queries Exa for modern best practices using the library name, current year, and up to three tags. Cached Exa results are reused unless `--refresh-exa` is passed.
6. The generator picks a section set from tags, infers a glob pattern, prompts the LLM to produce a complete `.mdc` file, parses the returned frontmatter, then writes `rules-mdc/<library>.mdc`.
7. The progress tracker marks each library `completed` or `failed`, allowing retry of failed libraries by default.

The current user installation path is much less explicit. The README explains how to run the generator, but does not provide a robust "install these rules into your target Cursor project" command. The checked-in `cursor-rules-reference.md` says modern Cursor project rules live under `.cursor/rules` as rule folders containing `RULE.md`, while legacy `.mdc` files remain functional. This repo outputs flat `.mdc` files and leaves copying, folder placement, update policy, and conflict resolution to the user.

## Architecture

The architecture is a simple generated corpus:

- `README.md`: project positioning, prerequisites, generator usage, command flags, and rule-addition workflow.
- `rules.json`: 241 library entries with tag arrays; this is the current taxonomy source.
- `src/generate_mdc_files.py`: generator, Exa cache logic, LiteLLM prompt construction, glob inference, section selection, progress tracking, and file writer.
- `src/config.yaml`: default paths, Gemini model, Exa/API rate limits, worker count, chunk size, and failed-only retry policy.
- `src/mdc-instructions.txt`: compact Cursor rule guidance and example frontmatter.
- `src/mdc_generation_progress.json`: current completion state for all 241 libraries.
- `rules-mdc/`: generated rule corpus, one flat file per library plus two stale `.md` duplicates.
- `rules-v0-deprecated/`: old conversion corpus and conversion-analysis script; useful for history, not current architecture.
- `cursor-rules-reference.md` and `cursor-rules-docs.md`: copied Cursor rule documentation covering rule types, folder structure, frontmatter, imports, `AGENTS.md`, and legacy `.mdc`.
- `.cursor/rules/python.mdc`: this repo's own Cursor rule, telling contributors to use `uv`; it has `alwaysApply: true` but a blank `globs`.

## Design Choices

The repo chooses generation over hand curation. The prompt asks for opinionated, actionable, code-heavy rules under 500 lines, with frontmatter plus markdown. This creates a consistent artifact shape quickly, but quality depends heavily on Exa result quality, model behavior, and later human review.

The taxonomy is tag-driven but the output is flat. Tags influence search queries and section choice, but they do not become output folders or install bundles. That keeps file lookup simple, but loses useful category boundaries such as frontend, backend, CI, cloud, testing, and AI.

Glob inference is rule-of-thumb based. Direct mappings exist for common names such as `react`, `vue`, `docker`, `terraform`, and `graphql`; otherwise the script falls back to tag mappings or `**/*`. This works for many language libraries but fails for some domains. For example, `typescript.mdc` is scoped to `**/*.{js,jsx}` because the TypeScript entry carries a `javascript` tag and there is no direct `typescript` name mapping. `github-actions.mdc` and `vim.mdc` both fall back to `**/*`, which over-applies their guidance.

The generation pipeline stores progress but not enough provenance. Exa result files are ignored by git, generated rules do not carry citation metadata, and the current checkout does not include a manifest tying each output file to the Exa answers, model version, prompt hash, or generation timestamp.

The script uses Pydantic models for internal shape but does not request structured JSON from the LLM. It asks for a full markdown file, strips code fences, then parses frontmatter with simple line splitting. That is pragmatic, but it leaves YAML edge cases and malformed generated content mostly unchecked.

## Strengths

The repository is broad and immediately mineable. It gives a ready list of 241 coding domains where agent instructions are likely useful, with enough generated content to inspect recurring rule topics.

The shared `.mdc` shape is practical. `description` supports agent-decided relevance, `globs` supports file-scoped activation, and one file per library gives a natural unit for retrieval, review, and installation.

The generator's prompt recipe is better than generic "best practices" prompting. It explicitly asks for opinionated choices, common mistakes, real-world scenarios, code examples, context for when patterns apply, and modern practice.

The tag-to-section logic is a useful reusable abstraction. Backend tags add security, error handling, and API design; frontend tags add component architecture, state, and accessibility; testing tags add test organization and mocking. This is a good way to avoid one-size-fits-all instruction templates.

The progress tracker and Exa cache make regeneration operationally realistic. Failed-only retry, `--library`, `--tag`, `--workers`, `--rate-limit`, `--regenerate-all`, and `--refresh-exa` are the right knobs for maintaining a large generated catalog.

The included Cursor rule reference docs make the install boundary visible even though the repo does not automate it. They clarify project rules, team rules, user rules, `AGENTS.md`, legacy `.cursorrules`, and legacy `.mdc`.

## Weaknesses

There is no active validation harness for the generated rules. The repo has `pytest` dev dependencies, but no current `tests/` suite for the generator, no CI workflow in the reviewed checkout, no schema lint for `.mdc` frontmatter, no check for glob precision, and no example compilation or framework-version verification.

The generated corpus violates some of its own constraints. The prompt says to keep rules under 500 lines, but `gitlab-ci.mdc`, `android-sdk.mdc`, `scrapy.mdc`, `langchain-js.mdc`, `llamaindex-js.mdc`, and `bottle.mdc` are over 500 lines. `kubernetes.mdc` reaches exactly 500 lines.

Glob quality is uneven. Out of 243 files in `rules-mdc/`, 82 use `**/*`, making them likely to over-trigger. Some specific scopes are wrong or stale, such as `typescript.mdc` targeting only JavaScript/JSX files and generated `vim.mdc` targeting all files while stale `vim.md` has a narrower Vim-specific glob.

The install/use boundary is underdeveloped. Users get generated files, but no manifest, installer, conflict detector, update policy, remote-rule setup, or guidance for choosing between overlapping rules. The repo also does not emit Cursor's newer folder-based `RULE.md` structure.

Provenance is weak. Generated files do not say which Exa citations or model responses produced them. Because cached `exa_results/` and `logs/` are ignored, a reviewer cannot reconstruct why a rule recommended a specific API or version.

The generator mutates `rules.json` as part of processing by sorting and writing it back. That side effect is surprising for a generation command and could create noisy diffs unrelated to the requested rule update.

Rule correctness is not guaranteed. Some generated snippets appear plausible but may be stale, version-specific, or too generic. Security-sensitive areas such as OpenAI, AWS, Terraform, Docker, Auth0, and Kubernetes need domain review before adoption.

There is metadata drift. GitHub reports the repository license as CC0 and `LICENSE` is CC0, while `README.md` and `pyproject.toml` describe MIT. The current corpus also has stale `.md` duplicates next to generated `.mdc` files.

## Ideas To Steal

Use a structured inventory like `rules.json` as the source of truth for domain-specific coding rules. Include name, tags, target versions, owner, risk level, and intended activation scope.

Keep the generated artifact shape small and regular: frontmatter, description, globs, body, examples, verification section, and known assumptions.

Use tag-driven section selection to make rules more relevant. A database rule should emphasize migrations, query safety, and data modeling; a frontend rule should emphasize components, state, accessibility, and rendering boundaries.

Add a first-class glob review step. Treat `**/*` as suspicious unless the rule is intentionally global, and require file-scope tests for rules like TypeScript, GitHub Actions, Vim, Docker, and Terraform.

Preserve provenance in generated rule metadata. Store source URLs, captured date, model, prompt hash, generator commit, and reviewer status so agents and humans know whether a rule is generated, reviewed, or adopted.

Build an installer that emits modern Cursor folder rules, legacy `.mdc` files, and `AGENTS.md` snippets from the same source. Include conflict checks so users do not install overlapping React/Next/TypeScript rules blindly.

Turn generated bad/good examples into eval seeds. Even if examples are not runnable as-is, they can drive static checks for whether the rule encodes concrete behavior instead of vague advice.

## Do Not Copy

Do not copy the full generated corpus into a project. It would create context bloat, over-trigger broad rules, and introduce conflicts between adjacent technology rules.

Do not treat LLM-generated best-practice bodies as authoritative. Review and version-pin rules before using them for security, cloud, deployment, database, or framework-migration work.

Do not copy broad `**/*` globs as a default. They should be reserved for truly global project behavior, not library-specific rules.

Do not ship rules without provenance. Exa and model outputs are useful inputs, but teams need capture dates, source URLs, model IDs, and reviewer status.

Do not rely on Cursor prompt rules as the only enforcement mechanism. Pair critical guidance with linters, tests, pre-commit hooks, CI checks, policy-as-code, or MCP/tool permissioning.

Do not keep generated stale duplicates beside canonical outputs. Mixed `.md` and `.mdc` variants make installation and update behavior ambiguous.

## Fit For Agentic Coding Lab

Fit is in-scope as a domain-specific coding instruction corpus and generator pattern. It is not a runtime, eval harness, MCP system, or agent workflow engine. Its value is as a source of reusable instruction design patterns and cautionary examples.

Best local adoption path is a curated derivative, not a dependency. Agentic Coding Lab should borrow the inventory-plus-generator idea, add stricter schema and provenance, review globs manually, split large rules, preserve source citations, and add verification commands to each adopted rule.

The repo is especially useful for designing a future rule marketplace: generated candidate rules start as `candidate`, pass through lint and domain review, receive target framework versions and validation hooks, then become installable Cursor, Codex, or `AGENTS.md` artifacts.

## Reviewed Paths

- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/README.md`: generator purpose, prerequisites, usage flags, rule-addition path, and project-structure claims.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/rules.json`: 241-library taxonomy, tag distribution, and selected entries for TypeScript, Docker, GitHub Actions, and Vim.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/src/generate_mdc_files.py`: generator execution path, Exa integration, LiteLLM prompt, glob inference, section selection, progress tracking, frontmatter parsing, and file-writing behavior.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/src/config.yaml`: model, rate limits, paths, worker count, chunk size, and retry policy.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/src/mdc-instructions.txt`: compact Cursor rule format guidance used as local generation context.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/src/mdc_generation_progress.json`: completion state for all 241 generated libraries.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/src/plan.md` and `src/exa-example.py`: original implementation plan and Exa usage example.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/.cursor/rules/python.mdc`: repository-local Cursor rule and example of `alwaysApply`.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/cursor-rules-reference.md`: Cursor rule type, folder, frontmatter, import, `AGENTS.md`, and legacy `.mdc` reference.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/pyproject.toml`, `.env.example`, `.gitignore`, and `LICENSE`: dependencies, key requirements, generated-output exclusions, and license metadata.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/rules-mdc/`: full metadata and line-count pass over 243 files; sampled rule bodies for `react`, `next-js`, `fastapi`, `docker`, `openai`, `langchain`, `github-actions`, `python`, `typescript`, `vim`, and duplicate `.md` files.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/rules-v0-deprecated/`: directory/file counts plus `test_conversion.py` review to understand deprecated conversion history and why it is not the current path.

## Excluded Paths

- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/.git/`: VCS internals; commit SHA captured separately.
- `/tmp/myagents-research/sanjeed5-awesome-cursor-rules-mdc/uv.lock`: dependency lockfile; noted as generator support but not relevant to rule taxonomy or instruction design.
- Full line-by-line review of all 241 generated `.mdc` bodies: metadata, counts, and representative files were reviewed; exhaustive content validation would be a separate domain audit.
- Full line-by-line review of `rules-v0-deprecated/`: counted and sampled only because it is explicitly deprecated and not the current generator output.
- Ignored `src/exa_results/` and `src/logs/`: not present in the checkout because `.gitignore` excludes generated caches and logs.
- External URLs cited or implied by generated rule bodies: not reviewed individually because the task was to deep-review the repository candidate, not validate every generated best-practice citation.
