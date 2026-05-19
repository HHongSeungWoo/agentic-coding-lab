# guardrails-ai/guardrails

- URL: https://github.com/guardrails-ai/guardrails
- Category: error-prevention
- Stars snapshot: 6,884 (GitHub REST API repository metadata, captured 2026-05-19 KST)
- Reviewed commit: 28d74af02215f3d09e6527238f783c561218d539
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for output and input validation around LLM calls. The reusable pieces are typed validators, JSONPath-scoped policy attachment, fail-action semantics, corrective reask loops, parse/schema failure classification, history-rich validation outcomes, and server-side guard deployment. Fit is high for agent output/tool-error prevention, but it should be adapted with deterministic coding-agent checks rather than copied as a full safety layer.

## Why It Matters

Guardrails is one of the most mature open-source examples of wrapping LLM calls with explicit validation and remediation. It does not just ask the model to "be valid"; it parses the output, checks JSON Schema, runs validators on specific paths, records failures, and chooses a configured failure action such as exception, fix, reask, filter, refrain, noop, or custom code.

For Agentic Coding Lab, the valuable pattern is a guard boundary around unreliable model text. Coding agents need the same boundary for generated patches, tool arguments, shell commands, SQL, JSON plans, secrets, PII, and user-facing summaries. Guardrails shows how to make those checks composable, inspectable, and reusable across local calls, server calls, CLI-created configs, and Hub-installed validators.

## What It Is

Guardrails is a Python framework and CLI for validating LLM inputs and outputs. Users create a `Guard` from direct validators, a Pydantic model, a RAIL XML spec, or a server-loaded guard. A guard can wrap an LLM API call or validate an already-known output.

Core primitives include:

- `Guard` and `AsyncGuard` as public validation boundaries.
- `Validator` subclasses that return `PassResult` or `FailResult`.
- `OnFailAction` values that turn failures into exceptions, fixes, reasks, filtered values, empty outputs, noops, or custom behavior.
- JSON Schema, Pydantic, and RAIL loaders for output shape and validator placement.
- `Runner`, `AsyncRunner`, `StreamRunner`, and `AsyncStreamRunner` for call, parse, validate, reask, and history loops.
- `ValidationOutcome`, `Call`, `Iteration`, and `ValidatorLogs` for raw output, validated output, failures, reasks, summaries, and error spans.
- Guardrails Hub install/registry code for reusable validator packages.
- An optional `guardrails-api` server path and OpenAI-compatible proxy pattern.

## Research Themes

- Token efficiency: Moderate. Guardrails avoids retrying entire workflows by classifying parse/schema/field failures and reasking only within a bounded `num_reasks` loop. It can preserve valid fields across field-level reasks, but `get_reask_subschema()` currently punts to the full schema, so token savings are incomplete.
- Context control: Strong. Validators attach to `messages`, `$`, or JSONPath-like fields. RAIL and Pydantic compile schema plus validators into prompt content, JSON Schema, and validator maps. Reask prompts include prior response, schema, example, and error messages rather than generic retry text.
- Sub-agent / multi-agent: Not a multi-agent framework. The server/API path can centralize validation for many clients, and LangChain/LlamaIndex integrations expose guards as runnables, but there is no subagent scheduling or delegation logic.
- Domain-specific workflow: Strong. Hub validators and custom validators support domain checks such as valid Python, valid SQL, secrets detection, PII detection, regex, competitor mentions, toxicity, provenance, and topic adherence. The Text2SQL application shows schema/context-specific SQL remediation.
- Error prevention: Very strong for LLM text and structured-output errors. It catches invalid input messages before the LLM call, non-parseable JSON, schema mismatch, path-specific validator failures, missing validator metadata, bad custom LLM callables, and server validation errors. It is weaker for pre-tool authorization and filesystem/shell safety because those are outside its core domain.
- Self-learning / memory: Limited. Guard history records calls, iterations, raw outputs, reask messages, validator logs, and summaries. This is useful audit memory, not autonomous long-term learning.
- Popular skills: Not a Codex skill-pack repo. Reusable "skills" are the validator authoring workflow, Hub packaging model, RAIL specs, on-fail action design, and server-deployed guard configs.

## Core Execution Path

The local path starts with `Guard()`, `Guard.for_string()`, `Guard.for_pydantic()`, `Guard.for_rail()`, or `Guard.for_rail_string()`. Constructors turn validators and schemas into a JSON Schema, an output type, execution options, and a validator map. `Guard.use()` can attach validators to output, `messages`, or a JSONPath-like field.

`Guard.__call__()` requires message input, fills validator maps, applies execution options, checks required validator metadata keys, and either calls the server client or creates a local runner. Server mode delegates to `GuardrailsApiClient.validate()` or `stream_validate()` when `settings.use_server` is active and the model is supported server-side. Local mode pushes a `Call` into history and runs `Runner` or `StreamRunner`.

`Runner.__call__()` loops from attempt zero through `num_reasks`. Each `step()` prepares messages and runs input validation on `messages` before any LLM call. If message validation fails with reask/filter/refrain/exception, execution stops and the LLM is not called. Otherwise the runner calls the LLM wrapper, parses output, validates schema, runs validators, post-processes filters/refrain, introspects reasks, and records the iteration.

Parsing distinguishes string output from structured output. JSON parsing tries direct `json.loads`, JSON code blocks, generic code blocks, and object extraction. Parse failure becomes `NonParseableReAsk`. Schema mismatch through JSON Schema Draft 2020-12 becomes `SkeletonReAsk`. Validator failure can become `FieldReAsk` or another on-fail result.

Validation is delegated through `guardrails.validator_service`. By default it tries async validation when no event loop is already running, otherwise it falls back to `SequentialValidatorService`. Both traverse list/dict children before parent validators and use path-specific validator lists. Failures flow through `perform_correction()`: `FIX` returns `fix_value`, `FIX_REASK` revalidates the fix and reasks if still bad, `CUSTOM` calls user code, `REASK` creates `FieldReAsk`, `EXCEPTION` raises `ValidationError`, `FILTER` removes values, `REFRAIN` returns an empty output for the output type, and `NOOP` leaves the value but marks failure.

After each failed iteration, `get_reask_setup()` builds corrective messages. String reasks include previous response and validator error messages. JSON reasks distinguish parse errors, schema errors, and field-level validator errors; they include the previous response, schema content, generated example, and error map. `Call.validation_response` can merge reask outputs across iterations, and `ValidationOutcome.from_guard_history()` returns raw output, final validated output, remaining reask, pass/fail status, summaries, and error.

Hub install is a separate execution path. `guardrails hub install hub://namespace/validator` resolves a manifest, installs a Python package from Guardrails' package index with PyPI fallback, optionally runs post-install local model setup, writes a project-local `.guardrails/hub_registry.json`, rewrites hub stubs, imports the installed validator, and exposes it under `guardrails.hub`.

## Architecture

The architecture is a validation runtime with multiple front doors:

- `guardrails/guard.py` and `guardrails/async_guard.py`: public guard APIs, server delegation, schema construction, validation entrypoints, history, serialization, load/save/delete, LangChain runnable conversion, and OpenAI JSON tool/schema helpers.
- `guardrails/run/`: sync, async, streaming, and async-streaming runners. These own prepare, call, parse, validate, introspect, reask loop, and streaming restrictions.
- `guardrails/validator_base.py` and `guardrails/validator_service/`: validator base contract, registry, local/remote inference selection, streaming chunk validation, async/sequential execution, fail-action correction, merge logic, and post-processing.
- `guardrails/actions/`: reask types and prompt setup, filter removal, and refrain-to-empty-output handling.
- `guardrails/schema/` and `guardrails/utils/parsing_utils.py`: RAIL/Pydantic/primitive schema generation, JSON Schema validation, parsing, pruning, coercion, and RAIL-to-JSON Schema conversion.
- `guardrails/hub/` and `guardrails/cli/hub/`: validator package installation, manifest handling, registry, imports, uninstall/submit/list/create commands.
- `guardrails/api_client.py`, `guardrails/cli/start.py`, and `server_ci/`: client/server boundary, guard persistence calls, validate/history calls, streaming validation, server start delegation to external `guardrails-api`, and server integration smoke tests.
- `guardrails/integrations/`: LangChain and LlamaIndex wrappers for using guards/validators inside existing agent chains.
- `docs/` and `tests/`: examples and behavioral coverage for RAIL, Pydantic, input validation, reasks, streaming, Hub install, server calls, parsing, and validator services.

## Design Choices

Guardrails makes validation a typed runtime object, not only prompt wording. A guard carries schema, validators, execution options, history, and optional server client state.

Validators are path-scoped. The same validator contract can apply to full output, message content, or nested structured fields. This maps well to agent plans and tool arguments where different fields need different policies.

Failure handling is explicit and user-selectable. `OnFailAction` separates "hard stop", "static correction", "ask the model again", "drop invalid value", "return no answer", "log and continue", and "custom remediation".

Reask is structured. The system records the bad value and failure results, then builds a corrective prompt from errors and schema rather than blindly retrying the same request.

The history model is first-class. Calls contain iterations; iterations contain inputs, raw output, parsed output, validation response, guarded output, reasks, validator logs, exceptions, token counts, and error spans. This makes validation failure explainable to an agent or developer.

RAIL is treated as a portable policy language. XML tags become JSON Schema and validator maps; `validators` attributes and `on-fail-*` attributes define both quality checks and remediation.

Hub validators are distributed as importable Python packages. This gives broad reuse, but also means validator installation is package installation with post-install side effects, not just fetching inert rule definitions.

Streaming is intentionally narrower than non-streaming. Streaming can validate and fix chunks for supported actions, but raises when reasks are needed. That is an honest limitation and an important design constraint for live agents.

## Strengths

Guardrails cleanly separates parse failures, schema failures, validator failures, and LLM-call failures. Each class produces different remediation or errors.

The `OnFailAction` matrix is directly useful for coding agents. Generated code might use exception, generated summaries might use fix/noop, generated tool args might use reask, and sensitive data might use filter/refrain.

Input validation is real. Validators on `messages` run before the LLM call, and tests assert that a failing message prevents a custom LLM from being called.

The reask loop has good operational shape: bounded attempts, per-iteration history, prior response context, validator error messages, schema examples, and final remaining reask when budget runs out.

The validator service supports both async parallel execution and sequential fallback. Multiple validators on the same value can run concurrently in async mode, then merge fixed values.

The schema path is practical. Pydantic models can embed validators in `Field(json_schema_extra)`, RAIL can attach validators through attributes, and `Guard.use()` can mutate a guard programmatically.

Server deployment is a useful enforcement pattern. A guard can be saved/loaded through an API, and OpenAI-compatible proxy tests show validation can sit between clients and model calls.

Tests cover important failure modes: input validation, required metadata, sync/async equivalence, multi-reask behavior, parsing reasks, Pydantic reasks, streaming restrictions, hub install behavior, API client errors, and guard serialization.

## Weaknesses

It is mostly post-generation validation. It can validate input messages, but it does not provide a pre-tool policy engine for shell commands, file writes, git operations, network calls, or destructive actions.

Reask is not a proof of correctness. It improves invalid outputs but still depends on the model fixing itself. Coding-agent safety needs deterministic checks such as parsers, tests, typecheckers, sandbox permissions, and static analysis.

Streaming has a large caveat: reask/fix/filter/refrain combinations are restricted, and reasks are explicitly unsupported during streaming. Live agent UIs cannot assume the same remediation semantics as batch calls.

Hub install has a broad trust boundary. It installs Python packages, can run post-install scripts for local models, writes into environment/site-packages and a CWD registry, and uses remote package indexes. That is useful for application developers but risky as an automatic coding-agent action.

Defaults differ by entrypoint. Direct `Validator` construction defaults `on_fail` to exception, while RAIL validator extraction defaults missing `on-fail-*` handlers to noop. That can surprise users moving between APIs.

Field-level reask is not as narrow as the interface suggests. `get_reask_subschema()` currently returns the full schema for reasks, with comments noting the intended pruning logic is punted.

Some parsing and coercion behavior can hide model mistakes. Extra keys are pruned, types are coerced, and no-op failures can still return a guarded output when validation failed. Consumers must check `validation_passed`, not only `validated_output`.

The actual server implementation lives in external `guardrails-api`. This repo reviews the client, CLI starter, and server CI tests, but not full route enforcement internals.

## Ideas To Steal

Make every agent output boundary return a `ValidationOutcome`-like object: raw output, parsed output, corrected output, pass/fail, remaining reask, error, and validator summaries.

Model checks as validators with stable ids, arguments, required metadata, and a `PassResult` / `FailResult` contract. Keep validator failures machine-readable.

Attach validators to paths, not whole responses only. Use JSONPath-like selectors for plan fields, tool args, generated files, test commands, PR body sections, and user-visible text.

Separate fail actions from validators. A "valid shell command" validator should be reusable with exception in CI, reask in generation, noop in analysis, and custom remediation for interactive flows.

Classify failures before remediation: non-parseable, wrong schema, path-specific semantic failure, missing metadata, tool/callable failure, and server failure should not all be one generic retry.

Use bounded corrective loops with recorded iterations. Reask prompts should include previous bad value, precise errors, expected schema, and the original task context.

Validate inputs before model or tool calls. For coding agents, apply the same idea to user prompt safety, command arguments, file paths, branch names, dependency names, and deploy targets.

Centralize reusable guard configs behind a server or repo-local registry, but keep the local contract inspectable. A team should be able to ask "which validators ran, where, with what action, and why did they fail?"

Provide generated structured-output helpers alongside validators. `json_function_calling_tool()` and strict JSON schema response formats are useful companions to post-generation validation.

## Do Not Copy

Do not treat validator reasks as the main safety mechanism for code execution. Use reask for text correction, then still run deterministic verification.

Do not let an agent auto-install Hub validators without explicit user approval and sandbox policy. Package install plus post-install scripts is a code execution boundary.

Do not silently continue on noop failures unless downstream code always checks `validation_passed`. A coding agent should not treat invalid-but-returned output as safe.

Do not assume streaming guards can enforce the same policy set as batch guards. Reask-heavy or high-risk checks should run before streaming or after full output collection.

Do not copy RAIL as the only policy authoring format. XML works here, but Agentic Coding Lab likely needs repo-native YAML/JSON/Python policies that are easier to diff and validate.

Do not hide server enforcement in an external package if reproducibility matters. Keep route behavior, policy loading, and audit logs in reviewed source or a pinned, reviewed dependency.

Do not rely on type coercion and key pruning for security-critical tool arguments. Reject malformed arguments loudly when the target is shell, filesystem, database, or network state.

## Fit For Agentic Coding Lab

Fit is high for the `error-prevention` category. Guardrails is not a coding-agent framework, but it is a strong reference for turning unreliable model text into a validated contract with remediation and audit history.

Best Agentic Coding Lab adaptations:

- A repo-local guard layer for generated JSON plans, tool calls, shell command proposals, commit messages, PR text, SQL, and patches.
- Validator plugins for deterministic checks: JSON Schema, AST parse, shell allowlist, path scope, secret scan, dependency policy, SQL safety, test command policy, and markdown/release-note shape.
- `OnFailAction`-style remediation that distinguishes hard stop, reask, static fix, filtered output, and human approval.
- Call/iteration history that agents can read after failure to decide the next edit.
- Server or MCP wrapper that enforces guards for multiple agent clients without duplicating prompt rules.

The core warning is that coding-agent errors often happen before the model produces final text: selecting a dangerous command, editing the wrong file, using stale context, or skipping verification. Guardrails should inspire the validation contract, but Agentic Coding Lab needs additional pre-action policy, sandbox permissions, diff inspection, and test execution gates.

## Reviewed Paths

- `README.md`: product scope, input/output guards, Hub validator examples, structured data generation, server usage, and OpenAI-compatible proxy pattern.
- `pyproject.toml`: package metadata, dependencies, optional server/API extras, CLI entrypoint, and test configuration.
- `guardrails/__init__.py`: public API exports.
- `guardrails/guard.py`: `Guard` construction, schema factories, `use()`, local/server execution, validation, parsing, history, save/load/delete, serialization, and OpenAI structured-output helpers.
- `guardrails/async_guard.py`: async guard parity, server calls, streaming calls, and async validate path.
- `guardrails/run/runner.py`, `async_runner.py`, `stream_runner.py`, `async_stream_runner.py`, and `run/utils.py`: sync/async/stream execution, input validation, LLM call wrappers, parsing, schema validation, validator execution, reask loop, and streaming limitations.
- `guardrails/validator_base.py`: validator contract, registry, required metadata, local/remote inference, streaming chunk validation, Hub inference request, LangChain runnable conversion, and registration.
- `guardrails/validator_service/*.py`: async/sequential validation services, fail-action correction, path traversal, merge logic, stream validation, and post-processing.
- `guardrails/actions/reask.py`, `filter.py`, `refrain.py`: reask types, reask prompt setup, reask merging, filter removal, and refrain-to-empty behavior.
- `guardrails/schema/rail_schema.py`, `pydantic_schema.py`, `primitive_schema.py`, `validator.py`, `parser.py`: schema loaders, RAIL parsing, Pydantic validator extraction, JSON Schema validation, and schema path helpers.
- `guardrails/utils/parsing_utils.py`, `validator_utils.py`, `structured_data_utils.py`, `prompt_utils.py`, `exception_utils.py`: output parsing, type coercion, validator parsing/reference handling, OpenAI JSON tool/schema helpers, prompt/message utilities, and user-facing exceptions.
- `guardrails/llm_providers.py` and `guardrails/classes/llm/prompt_callable.py`: LiteLLM/custom/HuggingFace/Manifest wrappers, function/tool-call argument extraction, callable failure errors, and streaming wrappers.
- `guardrails/classes/history/*.py`, `classes/validation_outcome.py`, `classes/validation/*.py`, `classes/execution/*.py`: call/iteration/input/output/history models, statuses, summaries, logs, and outcomes.
- `guardrails/hub/install.py`, `hub/validator_package_service.py`, `hub/registry.py`, `hub_token/token.py`, `cli/hub/install.py`, `cli/create.py`, `cli/start.py`, `api_client.py`: Hub install lifecycle, registry, package import, CLI config generation, server start, API client, and guard persistence/validation calls.
- `guardrails/applications/text2sql.py` and `applications/text2sql.rail`: domain example for SQL generation with schema-aware prompts, reask messages, and SQL validator/fix behavior.
- `docs/how_to_guides/rail.md`, `output.md`, `use_on_fail_actions.ipynb`, `custom_validator.ipynb`, `streaming.ipynb`, `remote_validation_inference.ipynb`, and API reference pages for actions, guards, validators, errors, history, and LLM interaction: documented contracts and examples.
- `docs/examples/bug_free_python_code.ipynb`, `syntax_error_free_sql.ipynb`, `json_function_calling_tools.ipynb`, `input_validation.ipynb`, `guard_use.ipynb`, `secrets_detection.ipynb`, and `no_secrets_in_generated_text.ipynb`: sampled examples relevant to code, SQL, secrets, input validation, function-calling schemas, and guard usage.
- `tests/unit_tests/test_guard.py`, `test_async_guard.py`, `test_validator_base.py`, `test_rail.py`, `test_api_client.py`, `validator_service/*.py`, `cli/hub/*.py`, `hub/*.py`, `schema/*.py`, and parsing/formatting utility tests: unit behavior for guards, metadata, input validation, Hub install, schemas, services, and API clients.
- `tests/integration_tests/test_multi_reask.py`, `test_run.py`, `test_async.py`, `test_parsing.py`, `test_pydantic.py`, `test_streaming.py`, `test_async_streaming.py`, `test_python_rail.py`, `schema/*.py`, `applications/test_text2sql.py`, and integration adapters for LangChain/LlamaIndex: end-to-end validation, reask, parsing, Pydantic, streaming, RAIL, and integration behavior.
- `server_ci/tests/test_server.py` and `server_ci/guard-template.json`: server validation smoke tests, OpenAI-compatible endpoint expectations, and streaming server behavior.

## Excluded Paths

- `docs/assets/**`, `docs/examples/images/**`, logos, GIFs, screenshots, and other image/binary documentation assets: useful for presentation, not validation runtime or error-prevention design.
- Raw notebook output cells and unrelated notebooks under `docs/examples/**`: I reviewed notebook source snippets for error-prevention examples, but excluded large rendered outputs, warnings, and examples unrelated to agent output/tool errors.
- `tests/unit_tests/mocks/tiny-random-gpt2/model.safetensors`, tokenizer JSON, vocab/merges files, PDFs under docs/tests data, SQLite fixture binaries, and other fixture binaries: test data and binary model/database artifacts, not source design.
- `poetry.lock`, `codecov.yml`, `pyrightconfig.json`, and generated dependency metadata: dependency resolution and tooling configuration; `pyproject.toml` was sufficient for package/dependency review.
- `docs/pydocs/**` generated API-doc tooling and generated docs wrappers: reviewed source and selected rendered API reference instead.
- Most telemetry/export internals under `guardrails/telemetry/**`, `hub_telemetry/**`, `call_tracing/**`, and Databricks tracing integration: useful observability plumbing but not central to preventing agent output/tool errors beyond history already reviewed.
- Vector store, embedding, and document store internals under `guardrails/vectordb/**`, `embedding.py`, and `document_store.py`: only relevant to provenance/RAG examples, not the core guard execution path.
- Broad `server_ci` Docker/build shell scripts and deployment plumbing: server behavior was reviewed through CLI start, API client, config, and tests; Docker scripts are operational.
- `.git/**`, release/maintenance files, contribution metadata, and unrelated CI/development helper scripts: not part of the validation architecture.
- External `guardrails-api` server package and Guardrails Hub validator package source code: this repo delegates to those packages at runtime. I reviewed the local client/install contracts and tests, but not unvendored external implementations.
