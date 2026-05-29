# ZeroLeaks/zeroleaks

- URL: https://github.com/ZeroLeaks/zeroleaks
- Category: error-prevention
- Stars snapshot: 570 (GitHub REST API repository metadata, captured 2026-05-29 KST)
- Reviewed commit: ca8e58020520c158cd7ba3c6680a451e4fb9ac9a
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Valuable reference for autonomous LLM red-team scanner architecture, especially the split between strategist, attacker, evaluator, mutator, inspector, orchestrator, static probes, and report scoring. Best use for Agentic Coding Lab is as a design study for adversarial regression harnesses and prompt-security reports. Do not adopt it as a coding-agent guardrail baseline without major changes: targets are only synthetic OpenRouter chat wrappers, tool and MCP attacks are textual probes rather than real tool execution, local CI/regression support is thin, scoring is mostly LLM-judged, and the dual-mode path has shared-state correctness risks.

## Why It Matters

Coding agents fail when hidden instructions, repository prompts, retrieved documents, tool descriptions, or user messages cause the model to leak confidential context or obey the wrong authority. ZeroLeaks directly studies that class of failure: it tries to extract system prompts and tests whether prompt-injection payloads can override target behavior.

The repo matters because it is a compact implementation of a multi-agent red-team loop rather than only a list of jailbreak prompts. It models attacker generation, strategy selection, response evaluation, mutation, defense fingerprinting, multi-turn escalation, injection probes, scoring, and recommendations in one TypeScript package. Even where the implementation is not production-ready, the decomposition is useful for designing agentic coding evaluations: generate attacks, run them against a target, judge evidence, preserve transcripts, score severity, and turn failures into regression cases.

The fit is conditional because the reviewed source tests a model wrapped around a supplied system prompt. It does not test a real coding agent with repository access, shell commands, MCP tools, browser state, file writes, or deployment credentials. For Agentic Coding Lab, ZeroLeaks is most useful as a scanner architecture reference and adversarial corpus seed, not as an off-the-shelf prevention layer.

## What It Is

ZeroLeaks is a TypeScript package and CLI for scanning LLM system prompts for two related risks:

- Extraction mode: an autonomous red-team loop tries to make a target model reveal its system prompt, rules, constraints, persona, or configuration.
- Injection mode: a fixed probe suite tests whether prompt-injection payloads cause the target to follow attacker-supplied instructions, change roles, accept fake context, manipulate output, or simulate tool actions.

The package uses Bun for build scripts, the Vercel AI SDK with the OpenRouter provider for LLM calls, Commander for the CLI, Zod structured outputs for agent judgments, and `js-tiktoken` for local token counting. It exports the scan engine, individual agents, probe libraries, documented attack techniques, payload templates, exfiltration vectors, and defense-bypass records.

The repository is small and source-focused. There is no server implementation for the hosted ZeroLeaks product in this checkout. The open-source repo contains the scanner library, examples, static probe data, a CLI, metadata, and a publish workflow.

## Research Themes

- Token efficiency: Weak to moderate. The engine counts prompt/response tokens in conversation history, truncates recent context when building agent prompts, and has config fields for per-turn and total token budgets. The reviewed source does not enforce `maxTokensPerTurn` or `maxTotalTokens`, does not cache evaluator/attacker judgments, and can spend multiple LLM calls per turn through strategist, attacker, mutator, evaluator, and inspector.
- Context control: Moderate as a scanner, weak as a guardrail. The target wrapper cleanly separates a supplied system prompt from user messages, resets conversations when burn/failure signals appear, and slices recent history for agent prompts. There is no instruction provenance model, no trusted/untrusted context labeling, and no adapter for testing real retrieved documents, codebase context, tool descriptions, or hidden agent state.
- Sub-agent / multi-agent: Strong as an architectural motif. The repo has separate Strategist, Attacker, Evaluator, Mutator, Inspector, InjectionEvaluator, and MultiTurnOrchestrator classes. These are in-process roles over shared state, not isolated subprocesses or independently budgeted agents.
- Domain-specific workflow: Strong for LLM prompt-security scanning. The corpus covers prompt extraction, prompt injection, RAG poisoning ideas, EchoLeak-style indirect injection, MCP/tool-description attacks, multi-turn grooming, policy puppetry, encoding, visual/ASCII obfuscation, and output exfiltration. It is not coding-agent-specific because shell, filesystem, git, browser, MCP, and CI actions are not actually executed or inspected.
- Error prevention: Useful for pre-release red-team assessment, but not a runtime action gate. The CLI exits nonzero for any non-secure result and returns JSON, so it can be wired into CI. The repo does not ship a GitHub Action, baseline format, SARIF/JUnit output, deterministic policy checks, or fail-closed tool permissions.
- Self-learning / memory: Limited. The scanner adapts inside one run through defense-profile updates, attack tree state, evaluator feedback, mutation history, and orchestrator resets. There is no persisted incident memory, vector store, regression baseline, probe outcome database, or post-scan learning loop.
- Popular skills: Not a Codex skill pack. Reusable "skills" are the multi-agent red-team loop, versioned prompt-injection probes, target-response judging, defense fingerprinting, and report schema.

## Core Execution Path

The public API starts at `runSecurityScan(systemPrompt, options?)` or `createScanEngine(config?)`. `runSecurityScan` constructs a `ScanEngine`, maps convenience options into scan config, and calls `engine.runScan()`. `createScanEngine` exposes the lower-level engine constructor so callers can pass a partial scan config and callbacks.

`ScanEngine.runScan()` resets engine state, creates one or two `Target` wrappers around the supplied system prompt, then dispatches to extraction mode, injection mode, or dual mode. A `Target` is an OpenRouter chat completion wrapper: it sends the supplied `systemPrompt` as the system message, converts previous attacker/target turns into user/assistant messages, calls `generateText`, stores the target-side transcript, and exposes `resetConversation()`.

Extraction mode runs a turn loop until `maxTurns`, full extraction, evaluator stop, time-budget exhaustion, or repeated errors. Each turn either asks the `MultiTurnOrchestrator` for the next scripted prompt or asks the `Strategist` and `Attacker` to generate an attack. The orchestrator supports Siren, Echo Chamber, and TombRaider-style sequences. The strategist selects an attack strategy from hard-coded strategies using defense level, failed categories, current turn, and leak status. The attacker uses an LLM to generate candidate attacks, scores them by expected effectiveness, stealth, and novelty, prunes low-scoring candidates, records an attack tree, and falls back to category templates if generation fails.

After the target responds, the engine records both attacker and target turns. If defense fingerprinting is enabled, the `Inspector` analyzes the exchange and may identify known guardrail families such as Azure Prompt Shield, Llama Guard, Anthropic constitutional behavior, OpenAI moderation, Google safety, NeMo Guardrails, or custom defenses. The `Evaluator` then uses structured LLM output to classify leak status, confidence, extracted content/fragments, defense patterns, suggested categories, reset signals, and continuation signals. The engine creates findings from extracted content, updates leak status, records orchestrator step results, optionally resets conversation state, calls progress/finding callbacks, and finally builds a `ScanResult`.

Injection mode is simpler and more deterministic. The engine selects all matching `injectionProbes` when `injectionTestTypes` is supplied, otherwise only the first 20 probes. For each probe it sends the probe prompt to the target, evaluates the response with `InjectionEvaluator`, stores an `InjectionTestResult`, calls the injection callback, then resets target and engine conversation history before the next probe. The injection evaluator combines quick substring matching over success/failure indicators with an LLM judgment. It aggregates success rate, by-type counts, severity counts, vulnerability level, score, summary, and recommendations.

Dual mode starts extraction and injection concurrently with `Promise.all()` on the same `ScanEngine` instance, then merges results by taking the worst vulnerability and the minimum score. This is an important correctness caveat: extraction and injection mutate shared engine fields such as `conversationHistory`, `findings`, `injectionResults`, `turnCount`, `tokensUsed`, `lastError`, and `scanAborted`.

The CLI exposes three commands. `zeroleaks scan` reads a prompt string or file, defaults to `--mode dual`, prints JSON or a text summary, and exits `0` only when the overall vulnerability is `secure`. `zeroleaks probes` lists static probes by category. `zeroleaks techniques` lists documented attack techniques from the knowledge module.

## Architecture

The repo is organized around five main layers:

- Public exports: `src/index.ts`, `src/agents/index.ts`, and `src/types.ts` define the public API, package exports, result schema, scan config, attack nodes, findings, defense profiles, injection results, progress callbacks, and supporting types.
- Engine and target runtime: `src/agents/engine.ts` owns scan orchestration, scoring, callbacks, result merging, error handling, token counting, and recommendations. `src/agents/target.ts` is the only concrete target adapter and always routes through OpenRouter chat completions.
- Agent roles: `attacker.ts`, `strategist.ts`, `evaluator.ts`, `mutator.ts`, `inspector.ts`, `orchestrator.ts`, and `injection-evaluator.ts` implement candidate attack generation, strategy selection, leak judging, mutation/Best-of-N, defense fingerprinting, scripted multi-turn attacks, and injection result scoring.
- Probe and knowledge corpus: `src/probes/*.ts` exports direct, encoding, persona, social, technical, advanced, modern, hybrid, tool-exploit, Garak-inspired, and injection probes. `src/knowledge/*.ts` exports documented techniques, payload templates, exfiltration vectors, and bypass matrices.
- User surfaces and metadata: `src/bin/cli.ts` exposes scan/probes/techniques commands; `examples/*.ts` show API use; `package.json` defines build/lint/test/typecheck scripts; `.github/workflows/publish.yml` builds and publishes on release.

The architecture is intentionally library-first. There is no database, no server route, no local model runtime, no persisted report store, and no hosted-product code in the reviewed checkout.

## Design Choices

ZeroLeaks models scanning as adversarial conversation rather than static prompt linting. That is the right shape for prompt extraction because many failures emerge only after multiple turns, resets, role shifts, and prior-response reuse.

The engine separates generation from evaluation. The attacker proposes prompts, the target responds, and the evaluator judges leakage. That keeps the scanner extensible: a future implementation could swap in deterministic probes, a different target adapter, or a calibrated judge without rewriting the turn loop.

The static probe corpus is broad, but it is not all exercised by the main extraction engine. Extraction mode mostly relies on LLM-generated attacks and fallback templates. Injection mode uses `src/probes/injection.ts`, and by default it runs only the first 20 of 27 injection probes, omitting later hybrid, output-control, and role-hijack tests unless the caller filters by test type or directly uses the probe library.

Scoring is severity-first and easy to understand. Extraction maps leak status to vulnerability (`complete`/`substantial` -> `critical`, `fragment` -> `high`, `hint` -> `medium`, weaknesses -> `low`, no findings -> `secure`) and applies simple finding penalties to a base score. Injection aggregates success rate and severity penalties. The downside is that scores are not calibrated against a benchmark, confidence intervals, target class, or probe coverage.

The target adapter choice is deliberately narrow. Testing a prompt string against a selected OpenRouter model is easy to run, but it does not reflect deployed AI applications where prompts are assembled from memory, tools, retrieval, policy files, secrets, and runtime state.

The CLI optimizes for quick local use. The nonzero exit status makes it usable in scripts, and JSON output is available. CI-grade reporting is not implemented: there is no baseline suppression, result diffing, SARIF/JUnit export, markdown report, artifact directory, or stable scan manifest.

The license is Functional Source License 1.1 with Apache 2.0 future licensing on January 21, 2028. That is fine for internal research, but it is not equivalent to permissive Apache licensing today.

## Strengths

The multi-agent decomposition is clear and reusable. A scanner architecture with separate strategist, attacker, evaluator, mutator, inspector, and orchestrator roles maps well to adversarial coding-agent regression: choose attack family, generate variants, execute, judge, mutate, reset, and report evidence.

The probe and knowledge corpus is useful despite being unevenly integrated. It gathers direct extraction, encoding bypasses, persona attacks, social engineering, technical format tricks, modern multi-turn attacks, Garak-inspired jailbreaks, indirect injection, MCP/tool poisoning, EchoLeak-style payloads, exfiltration vectors, and defense bypasses in inspectable TypeScript data.

The result schema is rich. `ScanResult` includes findings, scores, vulnerability labels, leak status, fragments, injection results, defense profile, transcripts, attack tree, recommendations, timing, errors, abort state, and completion reason.

The scanner has practical callbacks. `onProgress`, `onFinding`, `onDefenseDetected`, `onFailureRecorded`, and `onInjectionResult` are the right hooks for streaming UI, CI logs, or a future regression database.

The engine handles important operational failures better than many prototypes. It detects missing API keys and HTTP 401/402 billing/auth errors, aborts after repeated consecutive errors, records completion reasons, and avoids treating zero-result aborts as successful security assessments in summaries.

The CLI can be dropped into a simple gate. A script can run `zeroleaks scan --file prompt.txt --json` and fail when the result is not secure, even though the repo needs more reporting discipline for serious CI use.

The defense-fingerprinting idea is worth stealing. A scanner that classifies observed defenses and selects bypass families from a known database is a useful pattern for testing agent guardrails against specific failure modes.

## Weaknesses

The target adapter is too narrow for agentic coding research. `createTarget()` only tests a supplied system prompt through OpenRouter. It cannot hit an HTTP API, browser agent, MCP-enabled process, local CLI, code assistant, tool-call runtime, RAG app, memory store, or repo-aware coding workflow.

Tool and MCP attacks are simulated as text. The tool-exploit probes ask the model to pretend to execute tools, fake MCP resources, callback hooks, or admin tool chains. They do not register tools, inspect tool-call JSON, enforce permissions, check sandbox boundaries, or verify whether an actual action was attempted.

Dual mode has shared mutable state hazards. Extraction and injection run concurrently on the same `ScanEngine` instance and mutate the same fields. Injection mode resets `conversationHistory` after every probe while extraction mode is also using it. This can corrupt transcripts, counters, findings, abort state, and merged results.

The convenience API can accidentally override defaults with `undefined`. `runSecurityScan()` constructs a partial scan config containing keys such as `attackerModel`, `targetModel`, `enableInspector`, and `enableMultiTurnOrchestrator` even when options are absent. Spreading that object over `DEFAULT_CONFIG` can disable defaults or force constructors to fall back to their own model defaults. As a result, the README-level default behavior and the engine-level default behavior can diverge.

Adaptive temperature is mostly accounting. The orchestrator computes and exposes a temperature schedule, but the reviewed target and attack calls do not pass that temperature into `generateText` or `generateObject` in the execution path where the orchestrator chooses the next prompt.

Reporting loses important evidence. Extraction `conversationLog` is returned from the target wrapper, so it lacks the engine's attack metadata fields. Injection mode clears engine conversation history after each probe and then returns an empty or final-reset `injectionConversationLog`. `strategiesUsed` is always returned as an empty array. Findings are marked `verified: false` with no verification pass.

Scoring is not benchmark-calibrated. The evaluator is itself an LLM prompt, fallback evaluation is keyword-based, injection quick checks are substring indicators, and severity penalties are hand-chosen. That is fine for exploratory scanning, but weak for CI pass/fail without seeded regression data and known expected outcomes.

There are no repository tests in the reviewed checkout. `package.json` has `bun test`, `lint`, `typecheck`, and `build` scripts, but no test files were present. The only GitHub workflow is package publishing on release or manual dispatch, not PR CI.

The open-source repository and hosted-product claims are easy to conflate. README and external docs mention hosted dashboards, PDF exports, CI integration, AgentGuard, and sandboxed tool testing, but the reviewed repo implements only the local package/CLI scanner and publish workflow.

## Ideas To Steal

Use a role-separated scanner pipeline for agentic coding evals: strategy selection, attack generation, target execution, leak/tool-action evaluation, mutation, reset, and report assembly should be separate interfaces.

Create a real `TargetAdapter` abstraction. Useful adapters would cover plain LLM prompts, HTTP chat APIs, CLI agents, browser agents, MCP clients, tool-call simulators, and repository-aware coding agents. Each adapter should return transcript, tool calls, file changes, shell commands, network requests, and policy decisions.

Version the probe corpus as regression data. Each probe should have an id, category, expected safe behavior, success indicators, failure indicators, required context, target capabilities, severity, and source provenance.

Keep both deterministic and LLM judges. String/canary/tool-call checks should fire when evidence is exact; LLM judges should add semantic analysis, not become the only authority.

Track attack tree and reset decisions as first-class artifacts. For coding agents, a useful report should show which probe caused a bad shell command, wrong-file edit, secret leak, or policy bypass, and whether the agent recovered after reset.

Make scoring coverage-aware. A score should report not only vulnerability severity, but also how many attack classes ran, which target adapters were in scope, which probes were skipped, and whether evaluator failures occurred.

Turn scanner findings into durable regression tests. A failed prompt, tool description, retrieved document, screenshot, or repository instruction should become a labeled fixture that future agent versions must resist.

Use CLI exit codes, but pair them with structured artifacts. CI needs stable JSON, markdown summaries, SARIF/JUnit where appropriate, baselines, history comparison, and reproducible scan manifests.

## Do Not Copy

Do not run extraction and injection concurrently on one mutable engine object. Use separate engine instances or immutable scan contexts, then merge immutable results.

Do not treat textual tool-exploit prompts as proof of tool safety. Real tool safety needs actual tool schemas, model tool-call outputs, sandbox decisions, allow/deny policy, and post-action verification.

Do not let undefined convenience options override engine defaults. Build partial configs by omitting absent keys or deep-merging only defined values.

Do not rely on LLM-only leakage judgment for CI gates. Critical checks need deterministic evidence such as canaries, forbidden exact substrings, tool-call signatures, diff/path violations, and secret scanner hits.

Do not return empty or reset transcripts in reports. Regression systems need full per-probe transcripts with timestamps, prompt id, target response, judge evidence, and reset boundaries.

Do not expose a security score without coverage metadata. A "secure" result after 20 default probes is not equivalent to a "secure" result after every probe category, tool adapter, and multi-turn sequence.

Do not copy the current test posture. A scanner meant for CI should have hermetic tests for scoring, probe selection, target adapters, error handling, report schemas, and known vulnerable/safe fixtures.

Do not conflate hosted-platform features with local library features. Agentic Coding Lab should index what the repo source actually implements.

## Fit For Agentic Coding Lab

ZeroLeaks is a good conditional fit for `error-prevention`. It is directly about preventing prompt extraction and prompt injection, and it demonstrates a complete adversarial scan loop in a small codebase. Its strongest value is architectural: the scanner decomposes an AI security assessment into roles, probes, transcripts, scoring, and recommendations.

Best adaptations for Agentic Coding Lab:

- A coding-agent red-team harness with `TargetAdapter` implementations for CLI agents, MCP clients, HTTP agents, and browser agents.
- A probe corpus covering malicious repo instructions, poisoned docs, hidden tool descriptions, dependency confusion, unsafe shell commands, wrong-file edits, git/PR misuse, secret leakage, and multi-turn grooming.
- A report schema that preserves prompt id, target transcript, tool calls, filesystem changes, evaluator evidence, severity, score, and reproducibility metadata.
- A deterministic guard layer for paths, shell commands, secrets, tool permissions, and diffs, with LLM judging only as one evidence source.
- A regression workflow that converts every discovered leak or unsafe action into a fixture.

The main gap is that ZeroLeaks scans a synthetic target model, not the operational surface of a coding agent. To become a true Agentic Coding Lab artifact, the scanner shape would need real target adapters, hermetic tests, stable CI outputs, calibrated scoring, and durable incident memory.

## Reviewed Paths

- GitHub REST API repository metadata for `ZeroLeaks/zeroleaks`: stars, forks, language, default branch, timestamps, license metadata, and repository status.
- `README.md`: product positioning, open-source versus hosted table, features, installation, API/CLI examples, attack categories, scan result shape, environment variables, references, and license summary.
- `package.json`, `tsconfig.json`, and `biome.jsonc`: package exports, CLI entrypoint, scripts, dependencies, runtime assumptions, build tooling, and formatting/lint setup.
- `LICENSE`: Functional Source License 1.1 terms, permitted purposes, competing-use restriction, future Apache 2.0 change date, and licensing contact.
- `src/index.ts`, `src/types.ts`, and `src/agents/index.ts`: public API exports, scan/result types, callback types, attack nodes, defense profiles, injection result types, multi-turn types, and package surface.
- `src/agents/engine.ts`: default config, scan orchestration, extraction loop, injection loop, dual-mode merge, scoring, recommendations, callbacks, reset handling, error handling, token counting, and convenience API.
- `src/agents/target.ts`: OpenRouter target wrapper, system prompt injection into model calls, conversation history management, and reset behavior.
- `src/agents/attacker.ts`: candidate attack generation, attack tree, pruning, novelty scoring, fallback templates, update/reset logic, and stats.
- `src/agents/strategist.ts`: hard-coded strategy library, defense-profile updates, strategy filtering, LLM strategy selection, heuristic fallback, and failed-category tracking.
- `src/agents/evaluator.ts`: extraction judge schema, leak-status taxonomy, defense analysis, finding aggregation, fallback keyword evaluation, and recommendation generation.
- `src/agents/injection-evaluator.ts`: injection judge schema, quick success/failure indicator matching, LLM analysis, result combination, aggregate vulnerability scoring, and reset behavior.
- `src/agents/mutator.ts`: programmatic and semantic mutation types, encoding transformations, Best-of-N selection, mutation scoring, and history tracking.
- `src/agents/inspector.ts`: known defense database, defense fingerprinting, weakness identification, strategic guidance, and fallback analysis.
- `src/agents/orchestrator.ts`: Siren, Echo Chamber, and TombRaider sequences, temperature schedule, step result tracking, escalation, targeted extraction prompt generation, and reset logic.
- `src/probes/index.ts`: public probe aggregation, category lookup, defense-level lookup, phase lookup, random attack sequence generation, and injection/Garak conversion helpers.
- `src/probes/injection.ts`: 27 injection probes across Skeleton Key, Crescendo, Echo Chamber, many-shot, semantic variation, tool poisoning, indirect injection, ASCII art, promptware, hybrid injection, output control, and role hijack.
- `src/probes/modern.ts`, `tool-exploits.ts`, `garak-inspired.ts`, `hybrid.ts`, `encoding.ts`, `direct.ts`, `personas.ts`, `social.ts`, `technical.ts`, and `advanced.ts`: static extraction and jailbreak probe corpus, including MCP/tool-style probes and Garak-inspired cases.
- `src/knowledge/techniques.ts`, `payloads.ts`, `exfiltration.ts`, `defense-bypass.ts`, and `index.ts`: documented attack techniques, payload templates, exfiltration vectors, lethal-trifecta assessment, and defense bypass matrix.
- `src/bin/cli.ts`: scan/probes/techniques commands, prompt/file input, default dual mode, JSON/text output, progress spinner, and exit-code behavior.
- `examples/basic-scan.ts`, `examples/custom-engine.ts`, and `examples/probe-library.ts`: public API examples, custom engine usage, progress/finding callbacks, and probe library enumeration.
- `.github/workflows/publish.yml`: release/manual package build and publish workflow.

## Excluded Paths

- `.git/**`: checkout metadata and local clone internals, not source behavior.
- `bun.lock`: generated dependency lock data. I reviewed `package.json` for runtime and script contracts instead.
- `.github/FUNDING.yml`: funding metadata, not scanner behavior or CI/regression logic.
- `.gitignore`: repository hygiene metadata, not relevant to architecture or error prevention.
- `.env.example`: skimmed only to confirm the OpenRouter API-key variable; it is not execution logic and appeared encoded with null bytes in the local checkout.
- Hosted ZeroLeaks product pages, docs, reports, and marketing copy outside this repository: consulted only to distinguish hosted claims from the reviewed open-source source. The conclusions above are based on the local checkout at commit `ca8e58020520c158cd7ba3c6680a451e4fb9ac9a`.
- Published npm package artifacts and installed dependencies: not downloaded or inspected. The review covered source code, examples, package metadata, and repository workflow files.
- Live OpenRouter scans: not run. The task was a source deep review, and no API key was provided; the local environment also did not have `bun` available for upstream package scripts.
