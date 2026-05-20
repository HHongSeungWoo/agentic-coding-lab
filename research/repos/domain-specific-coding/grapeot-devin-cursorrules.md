# grapeot/devin.cursorrules

- URL: https://github.com/grapeot/devin.cursorrules
- Category: domain-specific-coding
- Stars snapshot: 5,967 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 284b743cca749a290bfe726e2e40466d207d7c9b (default `master`; template branch also sampled at 47979ee96731c79fd3923e08a69226d0373273dd; multi-agent branch sampled at 7e8d90b360aed685ed4a234d487b8febf1859b91)
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful pattern mine for lightweight domain-specific coding rules: it combines a self-updating rule file, scratchpad memory, local tool wrappers, and installer branching for Cursor/Windsurf/Copilot. Do not adopt it as-is because prompt-state mutation, broad tool execution, stale model/tool assumptions, and weak verification make it fragile outside a trusted toy workspace.

## Why It Matters

`devin.cursorrules` shows a minimal way to turn editor-level coding-agent instructions into a richer operating loop. Instead of building a new agent runtime, it layers behavior onto Cursor, Windsurf, or GitHub Copilot by shipping rule files, a scratchpad, optional LLM/search/browser tools, and a cookiecutter installer.

For Agentic Coding Lab, the interesting part is not the Devin comparison. The reusable pattern is a small domain-specific prompt pack that gives an existing coding agent: persistent task planning, project-local lessons, tool affordance documentation, and a habit of updating progress before continuing. It is also a useful cautionary example because the strongest behavior is prompt convention, not host-enforced policy.

## What It Is

The default branch is a compact rules-and-tools repository. It contains `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `scratchpad.md`, four Python tools under `tools/`, unit tests, a GitHub Actions workflow, tutorial screenshots, and setup docs. The rule files tell the agent to use the project rule or scratchpad file as both task planner and lesson memory, then describe local helper commands for screenshot verification, LLM calls, web scraping, and DuckDuckGo search.

The recommended install path is not the default branch copy path. README points users to `cookiecutter gh:grapeot/devin.cursorrules --checkout template`. The `template` branch adds `cookiecutter.json`, pre/post generation hooks, a project skeleton, IDE-specific rule-file pruning, optional API key prompting, virtualenv creation, and dependency installation. The repo also has a separate experimental `multi-agent` branch that reframes the rule file around Planner and Executor roles using `tools/plan_exec_llm.py` and a `Multi-Agent Scratchpad`.

There is no custom agent scheduler, loader, sandbox, permission manager, or MCP boundary. Cursor/Windsurf/Copilot remain the hosts; this repo provides instructions and helper scripts those hosts may choose to follow.

## Research Themes

- Token efficiency: Moderate. The default rule file is small enough to load whole, and the tool docs are concise. There is no progressive-disclosure directory, metadata, globs, rule routing, or "load only when needed" mechanism beyond prose.
- Context control: Strong as a habit, weak as enforcement. The prompt tells the agent to maintain a scratchpad and lessons section, which gives durable local context, but it stores active planning and memory in the same always-loaded rules file.
- Sub-agent / multi-agent: Present only on the experimental branch. Planner/Executor roles are simulated through prompt discipline and a shared scratchpad; only the Planner calls a higher-reasoning LLM helper, and there are no separate isolated agents.
- Domain-specific workflow: In-scope for coding-agent workflow rather than a software framework domain. It targets "Devin-like" coding behavior: plan first, update progress, use browser/search/LLM tools, verify screenshots, and remember corrections.
- Error prevention: Useful local patterns include task checklists, milestone reflection, lessons learned, tests for helper scripts, and screenshot verification. Risks remain because YOLO/editor command execution, web browsing, LLM calls, and self-editing rules are not policy-gated.
- Self-learning / memory: Central feature. The rule file explicitly asks the agent to write reusable lessons from user corrections. This is simple and visible, but it can bloat context, pollute instructions with stale task state, and overwrite behavior if poorly edited.
- Popular skills: The high-signal artifacts are `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `hooks/post_gen_project.py`, `tools/llm_api.py`, `tools/web_scraper.py`, `tools/search_engine.py`, `tools/screenshot_utils.py`, and the `multi-agent` branch's `.cursorrules` plus `tools/plan_exec_llm.py`.

## Core Execution Path

The manual path is copy-based:

1. User copies `tools/` plus the relevant rule file into a project root.
2. Cursor reads `.cursorrules`; Windsurf reads `.windsurfrules` plus `scratchpad.md`; GitHub Copilot reads `.github/copilot-instructions.md`.
3. On each task, the agent is instructed to review the scratchpad/rules file, clear unrelated old task state if needed, explain the task, write a checklist, and update progress after subtasks.
4. When extra capabilities are needed, the agent runs local Python helper scripts for LLM calls, search, browser scraping, or screenshots.
5. When the user corrects behavior, the agent records the reusable lesson in the same durable instruction file.

The cookiecutter path adds installer logic:

1. User runs cookiecutter against the `template` branch.
2. `pre_gen_project.py` validates project name, IDE choice, and optional LLM provider, then optionally captures an API key in a temporary file.
3. `post_gen_project.py` writes the selected key into `.env`, removes unused IDE rule files, inserts "ignore LLM/screenshot sections" notices when no key is configured, creates a `venv`, and installs `requirements.txt` with `uv` or `pip`.
4. The generated project is ready for the editor host to consume the chosen rule file.

The multi-agent branch changes the loop:

1. The rule file defines Planner and Executor responsibilities.
2. Planner work should be delegated to `tools/plan_exec_llm.py`, usually with an o1-style model.
3. The Planner response is not applied automatically; the current agent must edit the shared scratchpad according to the model's suggested patch.
4. Executor work proceeds from scratchpad action items and writes status or blockers back before returning to Planner.

## Architecture

The default branch architecture is deliberately small:

- `README.md`: positioning, setup options, tool list, and link to tutorial.
- `step_by_step_tutorial.md`: beginner Cursor setup, YOLO-mode discussion, cookiecutter walkthrough, and examples.
- `.cursorrules`: Cursor instructions, tool affordance docs, lessons, and empty scratchpad section.
- `.windsurfrules` plus `scratchpad.md`: Windsurf variant that separates scratchpad state from the rules file.
- `.github/copilot-instructions.md`: Copilot variant with similar planning, lessons, and tool instructions.
- `tools/llm_api.py`: provider adapter for OpenAI-compatible APIs, Azure OpenAI, DeepSeek, SiliconFlow, Anthropic, Gemini, and a hardcoded local endpoint.
- `tools/web_scraper.py`: Playwright-based concurrent page fetcher plus HTML text extraction.
- `tools/search_engine.py`: DuckDuckGo search wrapper with retry and stdout/stderr separation.
- `tools/screenshot_utils.py`: Playwright screenshot capture helper.
- `tests/`: mocked unit tests for environment loading, provider adapters, search formatting, web parsing, and screenshot/LLM verification.
- `.github/workflows/tests.yml`: CI installs dependencies, installs Chromium, copies `.env.example`, and runs `unittest discover`.

The template branch adds `cookiecutter.json`, `hooks/pre_gen_project.py`, `hooks/post_gen_project.py`, `.cursorignore`, generated project README, and generated versions of the same tools and rule files.

The multi-agent branch adds `tools/plan_exec_llm.py`, `tools/token_tracker.py`, package `tools/__init__.py`, token/plan tests, and a larger role-oriented `.cursorrules`.

## Design Choices

The repo chooses host leverage over runtime complexity. Cursor, Windsurf, and Copilot already provide editing, shell execution, and chat. This project only supplies prompt contracts and helper scripts.

The main instruction artifact is both behavior contract and mutable workspace memory. That keeps setup simple and makes lessons visible, but it mixes stable policy, learned preferences, active task state, and stale examples.

Tooling is exposed as local commands rather than structured tool APIs. The prompt teaches the agent command shapes such as "run this Python file with this provider" and expects the host to execute shell commands. This is portable across editors but lacks schemas, permission labels, typed outputs, or tool-call auditing.

The install boundary is pragmatic. Manual setup supports copying only what a host needs; cookiecutter supports project type selection, optional provider setup, venv creation, and dependency installation. The installer is convenient, but it runs arbitrary post-generation Python from a GitHub branch and performs package installation immediately.

The multi-agent branch models agents as roles in one context, not separate processes. It gets the benefit of an explicit planning checkpoint while still relying on one editor agent to call the Planner helper, edit the scratchpad, execute work, and decide when to continue.

## Strengths

The artifact is easy to understand and adapt. A team can read one rule file and see the intended loop: plan, track, use tools, record lessons, and keep going.

The Windsurf variant makes a better separation than Cursor by keeping scratchpad state in `scratchpad.md` rather than appending all state to the rules file. That is a small but important context-control pattern.

The cookiecutter branch demonstrates a useful install/use boundary. It selects the right rule artifact per host, avoids shipping all variants into the generated project, and inserts warnings when optional LLM features are not configured.

The tool pack covers practical gaps in editor agents: current search, webpage extraction, multimodal screenshot review, and fallback calls to a second LLM. The scripts are short enough for an agent to inspect before use.

The self-learning pattern is concrete. Lessons are not hidden in external memory; they are Markdown bullets in a project file that humans can review and edit.

The multi-agent branch captures a reusable checkpoint pattern: Planner owns decomposition and completion signoff; Executor owns implementation and blocker reporting. Even without isolated subagents, that explicit handoff is worth reusing in smaller form.

## Weaknesses

The prompt-state design can corrupt the stable instruction surface. If the agent writes task notes, temporary assumptions, or bad lessons into `.cursorrules`, every future interaction inherits that noise.

There is no permission or sandbox model. The README/tutorial discusses YOLO mode and command confirmation, but the repo itself cannot distinguish read-only, mutating, networked, credentialed, or destructive operations.

Verification coverage is shallow and partly stale. Tests mostly mock helper behavior rather than testing end-to-end agent workflows. `tests/test_web_scraper.py` still mocks an `aiohttp` style session while the implementation uses Playwright contexts, so the test does not match the current execution path.

Model and API assumptions age quickly. The rule files and scripts mention fixed model names, provider endpoints, a hardcoded Azure endpoint, and a hardcoded local LLM host. Several comments/docs lag behind code-level defaults.

Installer convenience creates trust risk. Cookiecutter `post_gen_project.py` can write API keys to `.env`, create environments, and install dependencies. That is acceptable only when the user trusts the repo and reviewed branch.

Output contracts for search/scrape/LLM tools are prose-level. There is no JSON schema, no provenance envelope, no citation requirement, no retries for browser navigation beyond Playwright defaults, and no compacting strategy for large scraped pages.

The multi-agent branch is experimental and brittle. It requires the agent to call another model, then manually apply a text-edit suggestion to a scratchpad. Failures in that loop are not machine-checked.

## Ideas To Steal

Use a visible project-local scratchpad for long-running coding tasks, but keep it separate from stable rules by default.

Keep rule packs host-specific at the boundary: one Cursor file, one Windsurf file plus scratchpad, one Copilot instructions file. Do not make every host load every variant.

Add a tiny installer that prunes unused artifacts, creates the expected local environment, and makes optional features explicit when credentials are absent.

Document tools as affordances near the agent instructions, but pair each tool with input/output examples, safety labels, and verification expectations.

Copy the "lessons learned from corrections" idea, but route lessons into a reviewable memory file with promotion rules, dates, owners, and pruning.

Reuse the Planner/Executor checkpoint as a lightweight workflow pattern: Planner writes success criteria and next actions; Executor reports progress and blockers; Planner alone signs off completion.

For screenshot verification, combine browser capture with multimodal LLM review, but require deterministic checks first where possible and treat LLM review as supporting evidence.

## Do Not Copy

Do not write active task scratchpad state directly into always-loaded instruction files.

Do not rely on YOLO/editor command settings as a safety boundary. Add explicit approval and permission labels for mutating, networked, credentialed, and destructive tools.

Do not ship fixed model names, private endpoints, or current-year assumptions without a freshness policy.

Do not treat mocked helper tests as proof that an agent workflow works. Add smoke tests for generated projects, tool command contracts, and prompt/rule linting.

Do not ask users to run a remote cookiecutter branch that writes credentials and installs dependencies unless the branch commit is pinned and the hook behavior is clear.

Do not let local web scraping/search tools return unbounded text into agent context. Add source metadata, truncation, deduplication, and citation rules.

Do not implement multi-agent coordination by freeform scratchpad edits alone if correctness matters. Use structured state, role-specific context, and machine-checkable transitions.

## Fit For Agentic Coding Lab

Fit is in-scope as a domain-specific coding workflow prompt pack. It is not a framework to depend on, but it is a good small example of how much behavior can be added with a rule file plus helper scripts.

The best Agentic Coding Lab adaptation would be a safer "coding workflow pack" with:

- stable `AGENTS.md` or skill instructions separate from mutable `scratchpad.md`,
- a `lessons.md` file with promotion/pruning rules,
- tool cards with safety level, command, output shape, and verification use,
- installer that pins source commit and asks before dependency installation,
- prompt/rule linting plus generated-project smoke tests,
- optional Planner/Executor loop backed by structured state rather than freeform patch suggestions.

This repo should be treated as a pattern source for scratchpad/memory/tool affordance design, not as a direct source of operational policy.

## Reviewed Paths

- `/tmp/myagents-research/grapeot-devin-cursorrules/README.md`: setup options, tool claims, self-evolution framing, and multi-agent branch pointer.
- `/tmp/myagents-research/grapeot-devin-cursorrules/step_by_step_tutorial.md`: Cursor setup, YOLO-mode discussion, cookiecutter flow, and example tool use.
- `/tmp/myagents-research/grapeot-devin-cursorrules/.cursorrules`: Cursor planning, scratchpad, tool, lessons, and memory pattern.
- `/tmp/myagents-research/grapeot-devin-cursorrules/.windsurfrules`: Windsurf variant with external `scratchpad.md` boundary.
- `/tmp/myagents-research/grapeot-devin-cursorrules/.github/copilot-instructions.md`: Copilot variant.
- `/tmp/myagents-research/grapeot-devin-cursorrules/scratchpad.md`: Windsurf scratchpad starter and lesson target.
- `/tmp/myagents-research/grapeot-devin-cursorrules/tools/llm_api.py`: provider adapters, model defaults, image handling, env loading, and error behavior.
- `/tmp/myagents-research/grapeot-devin-cursorrules/tools/web_scraper.py`: Playwright browsing, HTML parsing, concurrency, URL validation, and output format.
- `/tmp/myagents-research/grapeot-devin-cursorrules/tools/search_engine.py`: DuckDuckGo search wrapper, retry behavior, and result formatting.
- `/tmp/myagents-research/grapeot-devin-cursorrules/tools/screenshot_utils.py`: screenshot capture helper.
- `/tmp/myagents-research/grapeot-devin-cursorrules/tests/test_llm_api.py`
- `/tmp/myagents-research/grapeot-devin-cursorrules/tests/test_search_engine.py`
- `/tmp/myagents-research/grapeot-devin-cursorrules/tests/test_web_scraper.py`
- `/tmp/myagents-research/grapeot-devin-cursorrules/tests/test_screenshot_verification.py`
- `/tmp/myagents-research/grapeot-devin-cursorrules/.github/workflows/tests.yml`: CI setup and unit test command.
- `/tmp/myagents-research/grapeot-devin-cursorrules/.devcontainer/devcontainer.json`: devcontainer baseline.
- `/tmp/myagents-research/grapeot-devin-cursorrules/.env.example`, `requirements.txt`, `.vscode.example/settings.json`, and `.gitignore`: environment and dependency boundary.
- `origin/template:cookiecutter.json`: generated-project choices and copy-without-render rules.
- `origin/template:hooks/pre_gen_project.py`: project/provider validation and optional API key prompt.
- `origin/template:hooks/post_gen_project.py`: IDE rule pruning, no-key notices, `.env` update, venv creation, and dependency install.
- `origin/template:{{cookiecutter.project_name}}/.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, `.cursorignore`, `.env`, `README_devin.cursorrules.md`, and `tools/web_scraper.py`: generated artifact shape and install-time assumptions.
- `origin/multi-agent:.cursorrules`: Planner/Executor role contract and shared scratchpad sections.
- `origin/multi-agent:tools/plan_exec_llm.py`: Planner helper, scratchpad-reading path, and patch-suggestion workflow.
- `origin/multi-agent:tools/token_tracker.py`: token/cost logging concept and side-effecting `token_logs/` behavior.
- `origin/multi-agent:tools/llm_api.py`, `CHANGELOG.md`, and `tests/test_plan_exec_llm.py`: multi-agent branch provider/token changes and tests.

## Excluded Paths

- `/tmp/myagents-research/grapeot-devin-cursorrules/.git/`: VCS internals; reviewed commit and branch SHAs captured separately.
- `/tmp/myagents-research/grapeot-devin-cursorrules/images/*.png`: tutorial screenshots; counted and sampled as PNG assets but excluded from semantic prompt/tool review.
- `/tmp/myagents-research/grapeot-devin-cursorrules/LICENSE`: license noted as MIT through repository metadata, not analyzed as agent workflow design.
- Full execution of cookiecutter `post_gen_project.py`: excluded because it would create a generated project, install dependencies, and potentially prompt for credentials; source behavior was reviewed instead.
- Live LLM, search, web-scrape, and screenshot tool calls from the candidate repo: excluded because they require external services, browser installs, credentials, or network side effects; scripts and mocked tests were reviewed instead.
- Exhaustive line-by-line diff across all branches: default branch was the reviewed commit; `template` and `multi-agent` were sampled where they directly affect install/use boundary and multi-agent design.
