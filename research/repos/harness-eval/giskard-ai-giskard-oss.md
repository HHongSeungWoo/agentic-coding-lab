# Giskard-AI/giskard-oss

- URL: https://github.com/Giskard-AI/giskard-oss
- Category: harness-eval
- Stars snapshot: 5,342 (GitHub REST API, captured 2026-05-12 KST)
- Reviewed commit: 820893a6ee5ca2bfdee034db2f8888cc25526a5e
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a lightweight, async-first eval harness reference for agentic systems, but not as a current open-source vulnerability scanner. At the reviewed commit, `giskard-checks` is the real implemented surface; `giskard-scan` is roadmap text, and the legacy v2 Scan/RAGET code is not present in this repo's current `main` tree.

## Why It Matters

Giskard is publicly positioned around evals, red teaming, and test generation for agentic systems. That makes this repo important to review for harness/eval patterns, especially because its current v3 rewrite has changed the center of gravity: the implemented code is now a modular set of small Python packages for traces, scenarios, LLM judges, model routing, and reports, while the older automatic scanner remains external to the current v3 source.

For Agentic Coding Lab, the main lesson is the contrast between branding and execution path. The current repo is a good reference for making evals look like typed, async test scenarios. It is not enough if we need turnkey prompt-injection, data-leakage, jailbreak, or model-bias scanning probes. Those would need to be built on top of the scenario/check primitives or sourced from legacy v2/future `giskard-scan`.

## What It Is

`giskard-oss` is a Python 3.12+ monorepo for the alpha v3 Giskard ecosystem:

- Root `giskard` package `3.0.0a1`: a meta package depending on `giskard-core`, `giskard-agents`, and `giskard-checks`.
- `giskard-core`: shared discriminated-union registration, rate limiting, telemetry, and utility types.
- `giskard-llm`: provider routing over OpenAI, Google/Gemini, Anthropic, Azure OpenAI, and Azure AI Foundry for completions, embeddings, and stateful response APIs.
- `giskard-agents`: chat workflows, provider-backed generators, tools, Jinja prompt templates, retry/rate-limit middleware, structured output parsing, and simple tool-call loops.
- `giskard-checks`: the eval harness: `Scenario`, `Suite`, `Interact`, immutable `Trace`, deterministic checks, LLM-as-judge checks, user simulation, rich reports, and JUnit export.

The README explicitly says v2 Scan and RAGET are not available in v3. It includes a legacy install hint, `pip install "giskard[llm]>2,<3"`, and a `giskard.scan(...)` sample for v2 users, but the reviewed commit has no root `giskard/` package tree, no `docs/` directory, and no scanner implementation under `giskard/scanner`.

## Research Themes

- Token efficiency: Moderate. The v3 rewrite splits heavy functionality into smaller packages and optional provider extras. Scenarios stop after the first failing step, structured output retries are capped, and generator middleware supports rate limiting. There is no token-budget manager, context compactor, or evaluator-side prompt-cost optimizer.
- Context control: Strong for eval traces. `Trace` is immutable, `trace.last` is exposed to Python, JSONPath, and Jinja templates, and all check JSONPath fields must use `JSONPathStr` with a required `trace.` prefix. Custom `Trace` subclasses can expose `messages` or `transcript` computed fields for agent conversations.
- Sub-agent / multi-agent: Conditional. Giskard does not orchestrate multiple agents. It can test agentic workflows, tool loops, user-simulator turns, and black-box systems by binding a target SUT to `Scenario`, `Suite`, or `run(target=...)`.
- Domain-specific workflow: Good for LLM app eval basics: groundedness, answer relevance, conformity, toxicity, semantic similarity, string/regex matching, equality/comparison, custom function checks, and custom registered checks. Weak for vulnerability scanning because there are no in-repo prompt-injection/data-leakage/jailbreak probe generators.
- Error prevention: Good local primitives: Pydantic validation, JSONPath syntax enforcement, regex timeout, strict structured output retries, exception capture via `return_exception`, JUnit reporting, `pip-audit`, pinned GitHub Actions, and zizmor workflow scanning. Risk remains because empty/no-check scenarios pass and some LLM checks stringify missing JSONPath values instead of failing before judge invocation.
- Self-learning / memory: Minimal. `Trace` and `RunContext` are per-run structures, not long-term memory. Telemetry captures coarse usage analytics, but it is product analytics, not self-learning.
- Popular skills: The repo has `AGENTS.md` for coding-agent contributors and an expedited agent-PR convention, but no standalone agent skill library. The reusable "skill" idea is mostly the documented workflow: run `make format`, `make check`, `make test-unit`, and use targeted package commands.

## Core Execution Path

The main eval path starts with user code building a `Scenario`:

1. Add interactions with `Scenario(...).interact(inputs, outputs)` or `add_interaction(Interact(...))`. Inputs and outputs can be static values, sync/async callables, or generators. If outputs are omitted, a target SUT can be bound at scenario, suite, or run level.
2. Add checks with `.check(...)` or `.checks(...)`. Consecutive interactions before a check are grouped into a step; adding a new interaction after checks creates a new step.
3. `Scenario.run()` delegates to the singleton `ScenarioRunner`. The runner creates a fresh immutable `Trace`, binds missing `Interact.outputs` to the target, materializes interactions, then wraps each step into a `TestCase`.
4. `TestCaseRunner` executes every check in that step. It annotates result details with duration, check kind, name, and description. If `return_exception` is false, check exceptions propagate; if true, they become `CheckResult.error`.
5. If a step fails or errors, later steps are skipped with explicit skip results. If `multiple_runs` is greater than one, the whole scenario reruns with a fresh trace until the first non-pass or until the run cap is reached.
6. A `Suite` runs scenarios serially, optionally sharing a target. `SuiteResult` computes pass/fail/error/skip counts, pass rate, rich console output, and JUnit XML.

LLM checks are a second path inside the same harness. `BaseLLMCheck.run()` builds a `ChatWorkflow` from a prompt or template reference, injects template inputs from the trace, sets the structured output model to `LLMCheckResult`, runs the configured generator, and maps `passed: true/false` into `CheckResult.success` or `CheckResult.failure`.

Reports are local and test-runner friendly. `print_report()` uses Rich output for check, scenario, and suite results. `SuiteResult.to_junit_xml()` writes a `<testsuite>` where each scenario is a testcase, with `final_trace`, per-step payloads, metrics, failure/error/skip nodes, and a rendered scenario report in `system-out`.

## Architecture

The current architecture is small and layered:

- `libs/giskard-checks/src/giskard/checks/core/`: core harness models: `Check`, `Scenario`, `Step`, `TestCase`, `Trace`, `Interaction`, `Interact`, extraction helpers, result classes, and JSONPath validation.
- `libs/giskard-checks/src/giskard/checks/builtin/`: deterministic checks: comparisons, string matching, regex matching, semantic similarity, composition (`AllOf`, `AnyOf`, `Not`), and `FnCheck`.
- `libs/giskard-checks/src/giskard/checks/judges/`: LLM checks: `BaseLLMCheck`, `LLMJudge`, `Groundedness`, `AnswerRelevance`, `Conformity`, and `Toxicity`.
- `libs/giskard-checks/src/giskard/checks/prompts/`: bundled Jinja prompts for judges and the user simulator.
- `libs/giskard-checks/src/giskard/checks/generators/`: `UserSimulator`, an LLM-powered `InputGenerator` for multi-turn scenarios.
- `libs/giskard-checks/src/giskard/checks/export/`: JUnit export.
- `libs/giskard-checks/src/giskard/checks/testing/`: `WithSpy`, a wrapper that patches a Python target and stores mock call data in interaction metadata.
- `libs/giskard-agents/src/giskard/agents/`: `BaseGenerator`, provider-backed generators, `ChatWorkflow`, `Tool`, prompt template manager, `RunContext`, and middleware.
- `libs/giskard-llm/src/giskard/llm/`: provider registry, routing, unified error hierarchy, retry eligibility, provider adapters, translators, and typed chat/response/embedding models.
- `libs/giskard-core/src/giskard/core/`: discriminated type registration, telemetry, rate limiters, and shared errors/utilities.

Tests mirror these packages. `giskard-checks/tests` covers built-in checks, JSONPath enforcement, scenarios, suites, trace behavior, JUnit export, user simulation, and integration examples with tool-using mock agents. `giskard-llm/tests` covers routing, provider translation, no-provider behavior, and functional provider calls. `giskard-agents/tests` covers generator behavior, workflows, templates, tools, retry, serialization, and functional backends.

There is no implemented scanner package at the reviewed commit. `rg --files -g '*scan*'` only found the README GIF asset. Searches for scanner/security/vulnerability terms found README roadmap text, `SECURITY.md`, CI security checks, and `Toxicity`, but no vulnerability-probe engine.

## Design Choices

Giskard v3 chooses a modular rewrite over preserving the full v2 monolith. The implemented packages are focused and dependency-light: checks depend on agents/core, agents depend on llm/core, and provider SDKs are optional extras.

The harness is async-first. Scenarios, checks, generators, workflows, and provider calls all use coroutines. Multi-turn interactions are modeled with async generators that yield an `Interaction` and receive the updated immutable `Trace` through `asend()`.

Serialization uses Pydantic plus local discriminated registries. `Check`, `InteractionSpec`, `InputGenerator`, `BaseGenerator`, `CompletionMiddleware`, and rate limiters register concrete kinds. This is useful for saved eval configs, but custom classes must be imported before deserialization.

Trace access is explicit. Built-in checks read data from `trace.last.outputs`, `trace.last.metadata.context`, or user-provided JSONPath keys. A repo-level enforcement test ensures all check fields named `key` or ending in `_key` use `JSONPathStr`.

LLM judge prompts are file-backed Jinja templates. The prompt environment is a `SandboxedEnvironment` with `StrictUndefined`, and `MessageExtension` supports multi-message templates. Inline `as_template=True` is intentionally warned as unsafe for untrusted strings.

Agent workflows separate orchestration from providers. `ChatWorkflow` renders messages, runs pending tool calls, calls the generator, validates structured output when requested, and returns a `Chat`. `GiskardLLMGenerator` serializes tools into OpenAI-style function definitions and delegates to `giskard-llm`.

Security posture is mostly engineering hygiene, not scanner logic. CI uses `permissions: {}`, pinned actions, `persist-credentials: false`, `pip-audit`, and zizmor SARIF. The `pull_request_target` integration workflow is guarded by an authorization job and a maintainer-applied `safe for build` label for external contributors.

Telemetry is a first-class product feature. `giskard-core` can create `~/.giskard/id` and send coarse package/version/environment/run-shape events to PostHog EU. Docs say prompts, outputs, trace content, scenario names, exception strings, and file paths should not be sent. Opt-out requires env vars such as `DO_NOT_TRACK` or `GISKARD_TELEMETRY_DISABLED` before import, or `disable_telemetry()` at runtime.

## Strengths

The scenario/check/trace model is compact and understandable. A coding agent can generate a scenario, bind a target, run it, and read pass/fail details without learning a large framework.

The trace model is well-suited to multi-turn agent tests. Interactions can carry inputs, outputs, metadata, tool-call spy data, conversation IDs, and custom computed transcript fields.

LLM checks are implemented as ordinary checks rather than a separate product path. This means deterministic checks, LLM judges, user simulation, and tool-call assertions can be mixed in one scenario or suite.

The result contract is practical for CI. `CheckResult`, `ScenarioResult`, and `SuiteResult` expose status helpers, rich reports, assertion helpers, durations, metrics, and JUnit output with trace payloads.

Provider isolation is clean. `giskard-llm` handles provider-specific message constraints, error mapping, and optional SDK imports; `giskard-agents` only speaks internal message/tool types.

Security and CI workflows show mature defaults: pinned actions, no default workflow permissions, checkout credentials disabled, protected functional tests, dependency audit, and GitHub Actions security analysis.

## Weaknesses

The biggest gap is scanner absence. The README still leads with red teaming and describes `giskard-scan`, prompt injection, and data leakage, but the current reviewed tree contains no scanner package, probe catalog, adversarial prompt generator, vulnerability registry, or scan report model.

The built-in safety surface is thin. `Toxicity` is a judge prompt over an existing response; it does not generate attacks. `Conformity` can enforce a plain-language rule, but the user must supply the policy and scenarios. There are no built-in probes for secrets, prompt leakage, indirect prompt injection, over-permissive tools, jailbreaks, PII leakage, or unsafe code execution.

Missing extracted values can become judge input. For example, `Groundedness.get_inputs()` converts `NoMatch` to strings like `"No match for key: trace.last.outputs"` and then asks the LLM judge. For reliable CI gates, missing answer/context should usually fail before making an LLM call.

Empty evals can look green. A scenario with no checks, or a step with interactions only, passes by design. This is convenient for tracing but risky for automation unless callers add a no-empty-check guard.

LLM-as-judge defaults are provider dependent. The default generator is `openai/gpt-4o-mini`; the default embedding model is `text-embedding-3-small`. Users need API keys, calibration, retries, and cost controls for stable gates.

Telemetry defaults require attention in private coding-agent harnesses. The collected payload is intentionally coarse, but local agents may still need env-based opt-out before import to avoid writing `~/.giskard/id` or sending environment metadata.

`WithSpy` is useful for tests but patch-based. It records Python mock call data in metadata, which works for local functions but is not a general tracing strategy for distributed tools, subprocesses, MCP calls, or browser actions.

## Ideas To Steal

Use a small, typed `Scenario -> Step -> Interact -> Trace -> CheckResult` contract. It is easy for a coding agent to synthesize and easy for humans to inspect.

Make target binding explicit and layered: `run(target=...)` overrides `Suite(target=...)`, which overrides `Scenario(target=...)`. This lets the same eval suite run against multiple implementations.

Require structured selectors. Giskard's `JSONPathStr` convention catches bad paths early and keeps checks pointed at trace data rather than arbitrary globals.

Keep LLM judges as checks, not as the harness itself. Deterministic checks, regex/schema checks, semantic checks, and LLM judges should all share one result format.

Export JUnit from local results. Including final trace and step payloads as properties makes CI failures readable by humans and parseable by agents.

Use full conversation trace in safety judges. The `Toxicity` prompt explicitly scores a response in context, catching cases where a short answer like "Yes" endorses harmful prior content.

Model multi-turn test input as generators that receive the updated trace. This is a clean fit for simulated users, follow-up probes, and stateful agent workflows.

Adopt the CI hardening pattern: pinned actions, `permissions: {}`, `persist-credentials: false`, separate secret-backed functional workflows, and an authorization gate for `pull_request_target`.

## Do Not Copy

Do not present a scanner as implemented unless the repo contains probe generation, vulnerability taxonomy, execution, severity scoring, and reports. Giskard's current README mixes v3 roadmap and v2 examples in a way that can confuse users.

Do not let missing trace fields silently flow into LLM judges. For coding-agent CI, unresolved selectors should fail fast with structured diagnostics.

Do not treat "no checks" as pass in an automated gate. A harness for agents should distinguish trace-only dry runs from asserted eval runs.

Do not make external LLM defaults or telemetry defaults invisible. Require explicit model config and explicit analytics policy in privacy-sensitive agent infrastructure.

Do not use Jinja templating on untrusted user-controlled strings. Giskard warns about `as_template=True`; an Agentic Coding Lab harness should make the safe literal path the only default.

Do not rely on patch-based spies as the primary tool-audit mechanism. Prefer explicit tool adapters, event logs, command records, or spans that work across process and network boundaries.

Do not copy v2 Scan/RAGET assumptions from the README without reviewing the actual legacy code. The current v3 source is a different architecture and does not contain those modules.

## Fit For Agentic Coding Lab

Fit is medium-high for `harness-eval` primitives and low for immediate vulnerability scanning.

Best reusable patterns:

- Async scenario runner with immutable trace state.
- Target binding that lets the same scenarios run against multiple agents or revisions.
- Deterministic and LLM checks sharing one result model.
- JUnit output with embedded trace diagnostics.
- Custom trace subclasses for agent transcripts and metadata.
- LLM user simulator as an input generator.
- Provider abstraction with unified errors and retry eligibility.

Missing pieces for Agentic Coding Lab:

- Probe catalog for coding-agent failure modes: tool misuse, unsafe shell commands, secret exfiltration, policy bypass, prompt leakage, stale context, bad patch behavior, false test success, and permission escalation.
- First-class command/file diff tracing rather than Python-only interaction records.
- Deterministic CI guardrails for eval suite emptiness, missing fields, schema mismatch, and unsafe prompts.
- Calibration and repeatability controls for LLM judges.
- Local-first telemetry policy suitable for private workspaces.

The best use is as a design reference for a repo-native eval harness. Start from its `Scenario`, `Trace`, `Check`, and JUnit ideas, then add coding-agent-specific probes, command/file event collection, explicit privacy defaults, and no-empty-eval enforcement.

## Reviewed Paths

- `README.md`: v3 package scope, `giskard-checks` quickstart, scanner/RAG roadmap, legacy v2 Scan/RAGET install guidance, and explicit statement that v2 Scan/RAGET are not available in v3.
- `libs/giskard-checks/README.md`: scenario API, suite target binding, built-in checks, LLM checks, serialization caveats, custom check/spec examples, and testing notes.
- `libs/giskard-agents/README.md`: generator/workflow concepts, retries, rate limiting, middleware, structured output, templates, tools, development commands, and security audit notes.
- `libs/giskard-llm/README.md`, `libs/giskard-llm/docs/design.md`: provider routing, aliases, tool format decisions, response/tool-result conventions, and public input/output type split.
- `pyproject.toml`, `libs/giskard-core/pyproject.toml`, `libs/giskard-llm/pyproject.toml`, `libs/giskard-agents/pyproject.toml`, `libs/giskard-checks/pyproject.toml`: package boundaries, dependencies, optional provider extras, Python versions, pytest markers, and build setup.
- `Makefile`: install, check, test, functional-test, security, and agent setup commands.
- `AGENTS.md`: coding-agent contribution workflow, setup commands, PR title convention, functional-test secret requirements, and minimal-diff discipline.
- `SECURITY.md`: vulnerability disclosure process.
- `.github/workflows/ci.yml`, `.github/workflows/integration-tests.yml`, `.github/workflows/zizmor.yml`: CI gates, unit matrix, provider functional tests, protected `pull_request_target` authorization, pinned actions, and workflow security scan.
- `libs/giskard-core/src/giskard/core/telemetry/telemetry.py`, `libs/giskard-core/README.md`: telemetry payload policy, opt-out env vars, anonymous ID behavior, exception-type-only capture, and PostHog EU host.
- `libs/giskard-core/src/giskard/core/rate_limiter/*.py`: shared rate limiter model used by generators.
- `libs/giskard-checks/src/giskard/checks/core/*.py`, `core/interaction/*.py`, `scenarios/runner.py`, `scenarios/suite.py`, `testing/runner.py`: scenario, step, test case, trace, interaction, runner, target binding, and result execution paths.
- `libs/giskard-checks/src/giskard/checks/builtin/*.py`: deterministic checks, semantic similarity, regex timeout, function-backed checks, and composition.
- `libs/giskard-checks/src/giskard/checks/judges/*.py`, `prompts/judges/*.j2`: LLM judge architecture and prompts for groundedness, answer relevance, conformity, toxicity, and custom judge.
- `libs/giskard-checks/src/giskard/checks/generators/user.py`, `prompts/generators/user_simulator.j2`: user simulator input generation.
- `libs/giskard-checks/src/giskard/checks/export/junit.py`: CI report format.
- `libs/giskard-checks/src/giskard/checks/testing/spy.py`: patch-based tool-call spy wrapper.
- `libs/giskard-agents/src/giskard/agents/generators/*.py`, `workflow.py`, `chat.py`, `tools/tool.py`, `templates/*.py`, `context.py`, `errors/*.py`: generator middleware, workflow execution, tool schema/run behavior, prompt rendering, structured output retries, and error policies.
- `libs/giskard-llm/src/giskard/llm/routing.py`, `providers/*.py`, `errors.py`, `retry.py`, `types/*.py`, `translators/*.py`: provider routing, optional SDK loading, error mapping, retryable error taxonomy, and message/tool/response types.
- `libs/giskard-checks/tests/**`: sampled tests for scenarios, suites, interaction generators, JSONPath enforcement, LLM judges, toxicity context, user simulation, JUnit export, and integration examples with tool-using mock agents.
- `libs/giskard-agents/tests/**`, `libs/giskard-llm/tests/**`: sampled tests for generator serialization, workflows, templates, tools, retry behavior, routing, providers, and functional backend markers.
- Search results for `scanner`, `scan`, `vulnerability`, `red team`, `prompt injection`, `data leakage`, `jailbreak`, `RAGET`, and `generate_testset`: confirmed current code has README/roadmap references but no implemented scanner/probe package.

## Excluded Paths

- `uv.lock`: dependency lockfile. Useful for reproducibility, but not eval/scanner architecture.
- `readme/*.png`, `readme/*.gif`: binary README/logo/demo assets, including the Scan and RAGET GIFs. They illustrate legacy behavior but do not define execution paths.
- `.git/**`: clone metadata, not reviewed as source.
- `.github/ISSUE_TEMPLATE/**`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/labeler.yml`, `.github/release-drafter.yml`, `.github/dependabot.yml`, `.github/FUNDING.yml`, `.github/CODEOWNERS`, `.github/.stale.yml`: contribution, labels, funding, ownership, release, and dependency-management metadata. I reviewed workflow files relevant to CI/security.
- `.github/workflows/release.yml`, `.github/workflows/pr-labeler.yml`, `.github/workflows/reset-safe-for-build-label.yml`: release and label automation, lower priority than CI/integration/zizmor for harness usage.
- `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `ISSUES.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `renovate.json`, `pyrightconfig.json`: governance, license, issue, dependency, and type-check metadata. I sampled only where commands/security overlapped with harness behavior.
- Provider implementation details beyond representative files in `libs/giskard-llm/src/giskard/llm/providers/` and translators: important for SDK correctness, but secondary to eval/scanner architecture.
- Exhaustive unit-test bodies outside sampled files: tests were used to confirm architecture and edge cases; I did not read every assertion in every provider/translator/tool test.
- Legacy v2 Scan/RAGET code: not present in this reviewed `main` tree. The README links legacy docs and install instructions, but this note records the architecture of commit `820893a6ee5ca2bfdee034db2f8888cc25526a5e`.
