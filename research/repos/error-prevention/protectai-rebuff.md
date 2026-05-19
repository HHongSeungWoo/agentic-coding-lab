# protectai/rebuff

- URL: https://github.com/protectai/rebuff
- Category: error-prevention
- Stars snapshot: 1,485 (GitHub REST API repository metadata, captured 2026-05-19 KST; repository archived)
- Reviewed commit: 4d2fe064abf164e7381556d23e48e210080f8afa
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful prototype reference for prompt-injection gates, canary-token leak detection, and self-hardening attack memory. Best value for Agentic Coding Lab is conceptual: combine cheap heuristics, vector memory, LLM judging, and post-response canary signals into an auditable risk boundary. Do not adopt as a production dependency: the repo is archived, contracts drift between SDK/server/client paths, failure handling is uneven, and core defenses are too narrow for coding-agent tool safety.

## Why It Matters

Rebuff is an early open-source attempt to put a security boundary around LLM user input before that input reaches the main application model. It is directly relevant to error prevention because it treats prompt injection as a runtime signal, not only prompt wording. The design also closes a feedback loop: if a canary token leaks, the triggering input is logged into a vector store so similar attacks can be caught later.

For Agentic Coding Lab, the practical pattern is a layered pre-action gate plus a post-action leakage signal. Coding agents need the same shape around untrusted user text, tool arguments, hidden context, secrets, repository instructions, shell commands, and generated patches. Rebuff is too old and narrow to copy wholesale, but it gives a concrete execution path for "detect, block, canary, log confirmed failures, harden future checks."

## What It Is

Rebuff is a TypeScript/Python prompt-injection detection project with four advertised layers:

- Heuristic matching over common override phrases such as "ignore previous instructions".
- LLM-based scoring where a dedicated model returns a numeric injection likelihood.
- Vector similarity against known attack inputs stored in Pinecone or Chroma.
- Canary tokens inserted into prompts so prompt/context leakage can be detected from model output and stored as future attack memory.

The repository contains a JavaScript SDK, a Python SDK, a Next.js API/playground server, Supabase SQL setup, tests, quickstart/self-hosting docs, and a PlantUML sequence diagram. GitHub marks the repository archived, so it is best read as a design snapshot rather than an active library.

## Research Themes

- Token efficiency: Limited. The heuristic check is cheap, but the main SDK strategy still runs heuristic, vector, and LLM tactics sequentially unless a tactic override disables one. There is no short-circuit after a high-confidence cheap hit, so default detection can spend tokens on the LLM judge even after another layer would already block.
- Context control: Moderate. Canary tokens mark hidden prompt/context leakage, and `userInputBase64` transports input without direct JSON/string mutation, although the field is actually hex encoding. There is no broader context assembly or instruction-priority system.
- Sub-agent / multi-agent: Not a multi-agent framework. The useful analogy is that a detector service can act as a shared guard for many clients or agents.
- Domain-specific workflow: Moderate. The playground wraps a text-to-SQL demo, checks for prompt injection before SQL generation, inserts a canary, then flags SQL breaches by scanning generated SQL for writes, `users`, or `passwords`. The detector itself is not coding-domain aware.
- Error prevention: Strong concept, weak implementation maturity. It prevents some malicious inputs before the application LLM call, catches canary leaks after output, and stores confirmed bad inputs. It does not prevent unsafe shell/filesystem/git/tool actions, and several failure paths can break or fail open.
- Self-learning / memory: Good as a small pattern. Canary leaks and SQL breaches become vector-store documents, so future similar inputs can be blocked. There is no evaluation loop, decay policy, deduplication, or human review queue.
- Popular skills: Not a Codex skill repo. Reusable "skills" are the layered detector strategy, per-tactic threshold overrides, canary insertion/leak logging, and server-backed shared attack memory.

## Core Execution Path

The JavaScript local SDK path starts at `RebuffSdk.init(config)`. It initializes a vector store from either Pinecone or Chroma, creates a fixed `standard` strategy, and wires three tactics: `Heuristic(0.75)`, `Vector(0.9)`, and `OpenAI(0.9)`. `detectInjection()` accepts `userInput` or hex-encoded `userInputBase64`, applies per-tactic `tacticOverrides`, executes each tactic, records `{name, score, threshold, detected, additionalFields}`, and returns `injectionDetected` if any tactic score exceeds its threshold.

The heuristic tactic normalizes input, generates combinations of verbs/adjectives/objects/prepositions, slides same-length substrings across the input, and scores exact word matches adjusted by string similarity. It is simple and explainable, but only covers a small family of instruction-override attacks.

The vector tactic embeds/query-matches against an existing vector store. In JavaScript it queries top 20, uses the highest similarity score as the tactic score, and counts matches above threshold. The Chroma wrapper converts cosine distance into similarity with `1 - score`; Pinecone is used directly. Python follows the same idea with Pinecone and `text-embedding-ada-002`.

The LLM tactic renders the user input into a detector prompt that asks a model to return only a floating-point score from `0.0` to `1.0`. JavaScript parses the first completion with `parseFloat`; Python casts the returned string with `float()`. There is no robust structured-output parser, numeric clamp, or NaN handling.

The canary path is separate from pre-input detection. `addCanaryWord()` generates random hex and prepends it as an HTML comment by default. The caller sends the protected prompt to the application model. `isCanaryWordLeaked()` checks exact substring presence in the completion. On leak, `logLeakage()` writes the original user input plus metadata into the vector store, or the API client posts it to `/api/log`.

The Next.js `/api/detect` route accepts POST, requires `Authorization: Bearer <key>`, deducts credits through Supabase unless a master key is used, then calls the Rebuff SDK. The `/api/log` route validates an API key, stores canary leak rows in Supabase `leak_logs`, and writes the input to the vector store. The `/api/playground` route shows full application flow: detect user input, block if detected, otherwise canary-wrap the prompt, call OpenAI for SQL, check for canary leakage and basic SQL breach strings, log confirmed breaches, and store each attempt.

Failure handling is mixed. API routes return 401 for missing/invalid keys, 405 for wrong methods, 400 for detection errors, and 500 for server errors. JavaScript vector/LLM tactics throw `RebuffError`; Python local SDK generally lets provider errors propagate. An older server helper catches vector and LLM provider errors and returns zero scores, which is a fail-open pattern.

## Architecture

The repository splits into four relevant layers:

- `javascript-sdk/src/`: public `RebuffSdk`, API client, config types, tactic interface, heuristic/vector/LLM tactics, prompt rendering, vector DB initialization, and OpenAI client construction.
- `python-sdk/rebuff/`: local Python SDK, hosted API client, heuristic detector, OpenAI detector, Pinecone vector detector, canary helpers, and response models.
- `server/pages/api/` and `server/lib/`: Next.js API routes for detection, leak logging, playground requests, account stats/API keys, Supabase clients, billing helpers, vector/OpenAI clients, SQL prompt demo, and account/attempt logging.
- `docs/`, `README.md`, `detection.puml`, and tests: product contract, quickstart, self-hosting, sequence diagram, SDK behavior tests, Chroma setup tests, Python integration tests, and LangChain canary tests.

The JavaScript SDK has the cleanest internal abstraction: each tactic implements `{name, defaultThreshold, execute()}` and returns a score plus optional fields. The server and API clients, however, still carry an older flat response contract with `heuristicScore`, `modelScore`, and `vectorScore`, so there is visible contract drift between local SDK results and hosted API expectations.

## Design Choices

Rebuff uses OR semantics across independent detectors: any tactic above threshold means prompt injection. This is conservative for blocking, but can raise false positives when one detector is noisy.

The detector pipeline is policy-configurable at call time through thresholds and tactic toggles in JavaScript. Python exposes booleans and max scores. This maps well to risk modes, such as stricter checks before destructive tool use and lighter checks for low-risk chat.

Canary tokens are embedded in the prompt instead of only relying on input classifiers. This catches one class of real failure: the model reveals hidden or system prompt content. The feedback loop stores confirmed leak inputs as future vector signatures.

The vector memory is incident-driven. Rebuff does not predefine every attack; it tries to learn from leaks and breaches. That is a useful design for agent labs if paired with review, labels, provenance, and retention controls.

The server adds account/API-key and billing boundaries around detection. That makes detection a shared service, but also introduces operational dependencies on Supabase, OpenAI, Pinecone/Chroma, and environment-variable setup.

The LLM judge is prompted as a numeric classifier. This is easy to add, but brittle: input is interpolated directly into the classifier prompt, and the model is trusted to obey output formatting.

## Strengths

Layering is the main strength. Heuristics, vector memory, LLM judging, and canaries cover different failure signals, so the system is not only a single prompt or regex.

The canary workflow is concrete and portable. A coding agent can place canaries in hidden context, tool credentials, repo-private instructions, or prompt templates and detect whether generated output leaked them.

The self-hardening loop is small but compelling: only confirmed leaks or application breaches are written into attack memory, so future vector checks improve from observed failures.

The JavaScript tactic abstraction is simple enough to adapt. New tactics could be added for AST parse errors, shell command policy, path scope, secret detection, dependency policy, or diff risk scoring.

Per-tactic thresholds and run toggles are useful for experiments. Tests show heuristic-only, vector-only, and LLM-related assertions, plus Chroma/Pinecone paths and canary leakage cases.

The playground demonstrates a full prevention boundary, not only a library call: detect input, block risky requests, canary-wrap safe-looking input, run application LLM, check generated output, log breach, and update memory.

## Weaknesses

The project is archived and explicitly described as prototype/alpha. Dependencies and model choices are stale, and current production OpenAI, LangChain, Pinecone, and Chroma APIs have moved on.

API contracts drift. The JavaScript SDK now returns `tacticResults`, while the API client, server type definitions, Python hosted client, and Python integration tests expect flat `heuristicScore`, `modelScore`, and `vectorScore` fields. The Next.js `/api/detect` route passes legacy run/max-score fields into the new SDK shape, so the reviewed source does not present one coherent wire contract.

The LLM detector is prompt-injection-sensitive itself. It embeds untrusted user input in a classifier prompt and trusts a model to return one floating-point number. JavaScript has an explicit comment noting `parseFloat` NaN is not handled; Python `float()` can throw on malformed output.

Failure handling can fail open in duplicated server helpers. `detectPiUsingVectorDatabase()` catches errors and returns zero scores, and `callOpenAiToDetectPI()` catches provider errors and returns an empty completion. A safety boundary should distinguish "safe" from "detector unavailable."

Python vector counting has a logic bug: it updates `top_score` before checking `score > top_score`, so `count_over_max_vector_score` cannot increment in that branch. The score still works, but secondary evidence is wrong.

The heuristic detector is narrow and English-pattern-heavy. It will miss obfuscated, indirect, multilingual, role-play, data exfiltration, tool misuse, and coding-agent-specific attacks.

Canary detection is exact substring matching. It can miss paraphrased leaks, transformed tokens, spacing/case changes, partial leaks, screenshots, file writes, tool calls, or model actions that exploit hidden context without echoing the canary.

There is no deterministic tool-safety layer. Rebuff can say an input looks risky, but it does not inspect shell commands, file paths, git operations, diffs, network calls, SQL ASTs, or permissions before an agent acts.

Tests depend heavily on live OpenAI/Pinecone/Chroma behavior and a local Next.js server. There are limited hermetic tests for parser failure, provider outage, API contract compatibility, or high-risk false negatives.

## Ideas To Steal

Build agent safety as layered tactics with names, thresholds, scores, and evidence. Keep output like `tacticResults` so an agent can explain which guard fired and why.

Use cheap checks first, but add explicit short-circuit modes. For coding agents, a deterministic high-confidence block should avoid unnecessary model calls and reduce both latency and token spend.

Add canaries to hidden context and secrets that should never surface in final answers, patches, logs, tool calls, or PR text. Treat canary leaks as incidents, not just warnings.

Turn confirmed incidents into memory. If a prompt causes secret leakage, bad SQL, unsafe command generation, or wrong-file edits, store a normalized signature with provenance and reuse it in future detection.

Make detector failure a first-class outcome. Agent gates should return `blocked`, `allowed`, or `unavailable`, with unavailable defaulting to human approval or hard stop for high-risk actions.

Keep per-policy thresholds overrideable by risk tier. Reading files, editing source, deleting files, installing packages, pushing commits, and deploying should not share one risk threshold.

Use a shared service or MCP guard for teams, but keep local policy source reviewable. Every route should show which checks ran, which version of policy ran, and what evidence was logged.

Adapt the playground pattern for coding workflows: pre-check request, run task with canaries, inspect generated output/diff/tool calls, classify breach, log incident, and harden future tasks.

## Do Not Copy

Do not depend on an LLM judge as the final authority for tool safety. Shell, git, SQL, filesystem, and dependency actions need deterministic parsers and permission checks.

Do not let guard outages produce safe scores. If OpenAI, embeddings, vector DB, or policy loading fails, the result should be "guard unavailable" with risk-aware handling.

Do not store raw user prompts, completions, canaries, or repository context in a vector DB without retention, privacy, deduplication, redaction, and review policy.

Do not expose two response schemas for the same detector. Agentic Coding Lab should pin one schema and test every SDK/server/client boundary against it.

Do not rely on exact canary substring matching alone. Use it as a strong signal when it fires, but pair it with secret scanners, output filters, tool-call inspection, and audit logs.

Do not run all expensive tactics unconditionally. A coding agent should order checks by cost and confidence, with clear short-circuit rules and escalation to human approval when needed.

Do not copy the narrow heuristic phrase list as a complete prompt-injection defense. Coding-agent attacks include malicious repo instructions, dependency confusion, unsafe patches, hidden tests, poisoned docs, and command injection.

## Fit For Agentic Coding Lab

Fit is high as an error-prevention pattern and low as an adoptable dependency. Rebuff directly targets prompt injection, one of the main ways an agent can be steered into bad actions, and it shows a compact architecture for layered detection plus confirmed-incident memory.

Best adaptations:

- A `GuardTactic` interface for coding-agent checks: prompt injection, path scope, shell policy, secret leakage, AST parse, SQL safety, dependency risk, diff risk, and test-command policy.
- A canary system for hidden instructions and sensitive context, checked in final answers, patch text, command strings, logs, and PR bodies.
- An incident memory store that captures only confirmed failures, with labels, source commit, task context, redaction, and review status.
- A server or MCP boundary that can enforce the same guard policy across Codex, CI, review bots, and local scripts.
- Risk-tiered thresholds and short-circuit behavior so high-risk tool actions get stricter gates than ordinary explanation or summarization.

The main adjustment is scope. Rebuff protects the application LLM from unsafe user input; Agentic Coding Lab must protect the repository and developer workflow from unsafe actions. That means adding deterministic pre-tool policy, sandbox integration, diff review, test verification, and failure-state semantics on top of the Rebuff-style detector pipeline.

## Reviewed Paths

- `README.md`: project scope, prototype warning, four defense layers, quickstart, self-hosting dependencies, and roadmap.
- `docs/README.md`, `docs/quickstart.md`, `docs/self-hosting.md`, `docs/how-it-works.md`, and `docs/SUMMARY.md`: GitBook docs, alpha warning, Python quickstart, provider setup, and sequence-diagram reference.
- `detection.puml`: intended detection and canary-leak sequence across client, API, LLM, and vector DB.
- `javascript-sdk/src/sdk.ts`, `interface.ts`, `config.ts`, `index.ts`, and `api.ts`: local SDK strategy, public contracts, API client, tactic overrides, hosted detection request, canary helpers, and leakage logging.
- `javascript-sdk/src/tactics/Heuristic.ts`, `OpenAI.ts`, `Vector.ts`, and `Tactic.ts`: tactic contract, keyword/similarity heuristic, LLM classifier call, vector search, score thresholds, and error paths.
- `javascript-sdk/src/lib/prompts.ts`, `vectordb.ts`, `openai.ts`, and `Strategy.ts`: classifier prompt, normalization, Pinecone/Chroma initialization, Chroma distance-to-similarity conversion, OpenAI client, and strategy shape.
- `javascript-sdk/tests/index.test.ts`, `helpers.ts`, `setup-and-run-tests.sh`, `insert-chroma-vectors.ts`, and `wait-for-chroma.ts`: behavior coverage for request/response shapes, canaries, heuristics, LLM/vector checks, Chroma setup, and live-service assumptions.
- `javascript-sdk/package.json` and `javascript-sdk/README.md`: package metadata, scripts, dependencies, and SDK documentation status.
- `python-sdk/rebuff/sdk.py`, `rebuff.py`, `detect_pi_heuristics.py`, `detect_pi_openai.py`, `detect_pi_vectorbase.py`, `__init__.py`, and `_version.py`: local Python detector, hosted API client, response models, canary helpers, heuristic/vector/LLM detectors, and provider setup.
- `python-sdk/tests/test_sdk.py`, `test_integration.py`, `test_langchain.py`, `conftest.py`, and `utils.py`: local and server-backed behavior tests, canary LangChain examples, test server lifecycle, and environment requirements.
- `python-sdk/pyproject.toml` and `python-sdk/README.md`: Python package metadata, dependencies, test tooling, and quickstart.
- `server/pages/api/detect.ts`, `log.ts`, `playground.ts`, and account API routes: detection route, leak logging, playground prevention flow, auth errors, billing checks, and attempt logging.
- `server/lib/rebuff.ts`, `rebuff-api.ts`, `detect-helpers.ts`, `general-helpers.ts`, `openai.ts`, `pinecone-client.ts`, `supabase.ts`, `account-helpers.ts`, `templates.ts`, and `custom-error.ts`: server SDK/API wiring, duplicated detector helpers, SQL prompt demo, provider clients, account state, and error handling.
- `server/types/types.d.ts`: API response, prompt response, app state, and request types.
- `server/sql_setup/tables/*.sql` and `server/sql_setup/functions/*.sql`: account, attempt, leak-log tables, credit deduction, and aggregate stats.
- `server/README.md`, `server/package.json`, and `server/netlify.toml`: self-hosting setup, vector DB constraints, server scripts, runtime dependencies, and deployment config.

## Excluded Paths

- `server/public/**` favicon/logo/mobile icon binaries and `docs/.gitbook/assets/**`: visual assets only, not detector execution or error-prevention logic.
- `server/components/**`, `server/pages/index.tsx`, `server/pages/docs/**`, `server/pages/_app.tsx`, `server/pages/_document.tsx`, and `server/styles/**`: UI/playground presentation. I reviewed API/server behavior instead of React rendering and styling.
- `server/components/SequenceDiagram.tsx`: generated UI rendering of the sequence diagram; `detection.puml` was the source reviewed.
- `javascript-sdk/yarn.lock`, `server/package-lock.json`, `python-sdk/poetry.lock`, `server/tsconfig.tsbuildinfo`, and other lock/build metadata: dependency resolution or generated compiler cache, not design logic.
- `python-sdk/python-sdk-examples.ipynb`: notebook demo output. README, docs, and tests cover the execution path with less generated noise.
- `.github/workflows/**`: CI trigger/config metadata. The task focus was runtime detector behavior; test files and package scripts captured verification shape.
- `.git/**`, issue/release metadata, and remote-only branch content: repository internals or unreviewed branch snapshots, not the reviewed main-branch source at commit `4d2fe064abf164e7381556d23e48e210080f8afa`.
