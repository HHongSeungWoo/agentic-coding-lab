# BerriAI/litellm

- URL: https://github.com/BerriAI/litellm
- Category: error-prevention
- Stars snapshot: 46,533 (GitHub REST API repository search, captured 2026-05-11)
- Reviewed commit: cff3e0b75eeb836e9fafbcbf73fd4c968b001def
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong reference for gateway-level prevention around coding-agent model calls: centralized auth, fallback validation, guardrails, per-session iteration caps, tool controls, Redis-backed budgets/rate limits, cost reconciliation, cooldown routing, and sanitized observability. Conditional fit because LiteLLM is a broad production AI gateway, not an agent-coding framework; borrow the invariants and execution contracts, not the provider/UI surface.

## Why It Matters

LiteLLM is useful for Agentic Coding Lab because it handles the failure modes that appear when many agents share model access: callers try unauthorized fallback models, budgets race under concurrent requests, retries hide provider failures, guardrail metadata can be spoofed, tool calls need policy checks, streaming responses can fail after partial output, and logs must explain what happened without leaking secrets.

The strongest pattern is not any single guardrail. It is the request lifecycle: authenticate once, enrich request metadata with proxy-owned identity, strip caller-forged control fields, enforce model/tool/vector-store/budget permissions, reserve rate and budget capacity before the provider call, route only through allowed deployments, run input and output guardrails, reconcile real cost after the response, and write structured success/failure logs.

## What It Is

LiteLLM is an OpenAI-compatible AI gateway and Python SDK for routing requests to many LLM providers. The reviewed path is the proxy/gateway path: FastAPI endpoints, virtual-key auth, router selection, fallback and cooldown handling, guardrail callbacks, spend tracking, rate limiting, response headers, logging, and tests.

The repo also contains provider adapters, an admin dashboard, deployment assets, examples, generated reference data, and enterprise hooks. Those are useful context, but the reusable evidence for error prevention is concentrated in the proxy, auth, router, guardrail, spend, and hook modules.

## Research Themes

- Token efficiency: Indirect. Router context-window checks, fallback groups, cache controls, prompt caching support, and cost accounting reduce waste, but LiteLLM is not a context-compression system.
- Context control: Strong. The proxy strips untrusted metadata, injects trusted key/team/project/user metadata, validates vector store access, restricts cache controls, carries trace/session IDs, and filters model deployments by team, access group, region, health, cooldown, and request parameters.
- Sub-agent / multi-agent: Moderate. Agent-specific controls include `agent_id`, per-session max iterations, agent/session rate descriptors, and tool/MCP guardrails, but LiteLLM does not implement a coding-agent planner.
- Domain-specific workflow: Strong AI gateway workflow. It has provider adapters, deployment routing, guardrail integration, budgets, spend logs, auth/RBAC, and observability around shared LLM traffic.
- Error prevention: Primary fit. The codebase includes auth/model allow-lists, fallback-smuggling protection, budget reservation, atomic rate limits, tool policies, code-execution guardrails, prompt injection checks, response-id isolation, cooldown failover, and failure-path logging.
- Self-learning / memory: Limited. Redis/Postgres caches and spend logs are operational memory; there is no self-improving agent memory loop in the reviewed path.
- Popular skills: Virtual key governance, pre-call metadata sanitation, model routing, retries/fallbacks, guardrails, budget/rate admission control, per-session limits, tool allow-lists, cost logging, trace headers, and failover observability.

## Core Execution Path

Proxy requests enter `litellm/proxy/proxy_server.py`. Chat completion routes such as `/v1/chat/completions` depend on `user_api_key_auth`, then inject authenticated user/team/org/project/agent metadata and delegate to `ProxyBaseLLMRequestProcessing.base_process_llm_request`.

`user_api_key_auth` is the central invariant gate. It parses tokens and JWT/OAuth variants, resolves key/team/user/project/end-user/global spend objects, applies route checks, validates primary and fallback models, runs common checks, and reserves budget before the request reaches the provider path. The comments explicitly mark `_run_centralized_common_checks` as the shared gate so builder-specific auth paths do not skip common authorization.

`common_request_processing.py` then calls `add_litellm_data_to_request`, `function_setup`, `ProxyLogging.pre_call_hook`, and hierarchical router settings. It starts `during_call_hook` guardrails in parallel with the provider call, routes through `route_request`, and gathers guardrail and LLM tasks. Non-streaming responses run `post_call_success_hook`, deferred logging flush, model-name normalization, custom headers, and response-size checks. Streaming responses are wrapped so first-chunk errors can be converted into JSON errors and post-call guardrail logging can fire after the stream completes.

`route_llm_request.py` chooses the final model path. It strips mock-testing controls, maps team model aliases, validates per-request router setting overrides, allows only specific override keys, and only routes through router deployments, aliases, default models, wildcard routes, or A2A agent models. Unknown models raise `ProxyModelNotFoundError`.

`router.py` owns deployment selection, retries, fallback handling, health/cooldown filtering, pre-call context-window/RPM/region/parameter checks, admin-paused deployment filtering, and response content-policy fallback triggers. Failures stamp deployment IDs and per-deployment retry settings onto exceptions so fallback/cooldown logic can avoid reusing the same broken deployment in the same request.

Cost and rate prevention run around that path. The budget reservation module estimates worst-case request cost and reserves spend counters before the provider call; the rate limiter atomically reserves RPM/TPM/max-parallel descriptors before dispatch; the cost callback reconciles reservations to actual cost or releases them on failure.

## Architecture

The proxy layer is a set of cross-cutting control modules around the SDK/router:

- FastAPI endpoints in `proxy_server.py` expose OpenAI-compatible routes, management routes, health routes, and streaming/non-streaming response handling.
- Auth modules under `litellm/proxy/auth/` enforce virtual-key identity, route access, model access, budgets, metadata restrictions, tool allow-lists, vector-store access, org/team/user/project checks, and RBAC.
- `litellm_pre_call_utils.py` is the metadata hardening layer. It strips untrusted root and metadata controls, removes spoofed `user_api_key_*` fields from both `metadata` and `litellm_metadata`, rejects or merges caller tags according to policy, and injects trusted key/team/project fields.
- `ProxyLogging` in `proxy/utils.py` is the hook dispatcher for guardrails and custom loggers. It runs pre-call, during-call, post-call, streaming-iterator, and response-header hooks, with cached callback capability detection for hot paths.
- `router.py` and `route_llm_request.py` separate proxy request authorization from deployment selection, fallback, retry, cooldown, and model access-group filtering.
- Spend modules under `proxy/spend_tracking`, `proxy/db`, and `proxy/hooks/proxy_track_cost_callback.py` implement budget reservation, Redis-first spend counters, DB reseeding, cost callbacks, spend log writes, and failure spend logs.
- Rate-limit hooks use Redis/DualCache descriptors for key, user, team, team member, end user, model, project, org, agent, and session scopes.
- Guardrails live under `proxy/guardrails`, `integrations/custom_guardrail.py`, and provider guardrail translation paths. They can be request-time, during-call, post-call, streaming, default-on, requested per call, key/team/project metadata driven, or policy-engine driven.

## Design Choices

LiteLLM puts proxy-owned identity into request metadata only after removing caller-owned values with the same shape. This is the right shape for coding agents: user input may contain fields named like internal controls, but the gateway must be the only writer of trusted identity, budget, route, and policy slots.

Fallbacks are authorization-sensitive. `_enforce_key_and_fallback_model_access` validates the primary model and every top-level or `router_settings_override` fallback model for `fallbacks`, `context_window_fallbacks`, and `content_policy_fallbacks`. `route_llm_request.py` then only promotes a small allowed set of override keys. This directly prevents restricted-model smuggling through fallback config.

Budgets are admission-control counters, not just after-the-fact accounting. `reserve_budget_for_request` estimates max cost, atomically reserves each applicable counter, shrinks a reservation to remaining budget when possible, and releases already-applied entries on error. `increment_spend_counters` reconciles reservation to actual cost, and `proxy_track_cost_callback` releases or invalidates reservations on DB/counter failures.

Rate limits use upfront reservations. `parallel_request_limiter_v3.py` strips internal reservation stash keys from user metadata, estimates TPM, atomically increments descriptors with Redis Lua scripts, stashes reservation metadata, then refunds/reconciles on success or failure. This closes the classic read-check-then-increment race.

Guardrail controls are admin-owned by default. `auth_checks.py` rejects request attempts to modify or disable guardrails unless team metadata permits it, and `CustomGuardrail` reads `disable_global_guardrails` and opted-out global guardrails from admin metadata rather than raw caller fields.

Streaming is treated as a separate failure surface. The proxy peeks the first stream chunk for errors, runs iterator-level guardrails over full streams when needed, defers logging until post-call stream guardrails complete, and suppresses success logging when a post-call guardrail raises.

Observability is included in the execution contract. Responses can include call IDs, selected model/deployment info, response cost and cost breakdown, key spend/max budget, timing, timeout, and rate-limit headers. Failure hooks write sanitized failure logs with response cost zero.

## Strengths

The strongest reusable pattern is a single pre-provider gate that combines auth, route access, model allow-listing, fallback validation, guardrail mutation checks, tool allow-listing, object permissions, and budget reservation. Coding agents need the same "no model/tool call before these invariants pass" boundary.

Budget and rate limiting are race-aware. Redis-first counters, Lua check-and-increment, spend counter reseeding from DB, reservation reconciliation, and tests for TOCTOU failures show real attention to concurrent gateway behavior.

Fallback safety is unusually practical. The router validates fallback shapes, denies fallback when access groups were the reason candidates disappeared, filters cooldown and blocked deployments, and only raises content-policy fallback errors when a matching fallback exists.

Guardrails cover both general LLM safety and coding-agent concerns. Reviewed hooks include prompt injection checks, code-execution blocking/masking, response rejection detection, tool permission rules, tool trust-chain policy, response-id isolation, and max-iteration limits for agent sessions.

Failure handling is explicit. Provider failures trigger post-call failure hooks; budget reservations are released on proxy/provider failure; streaming first-chunk errors become structured JSON responses; guardrail passthrough violations can become a safe 200-style content-filter response; DB spend update failures release or invalidate reservations.

The test suite includes focused regressions for the important safety claims: fallback model smuggling, atomic rate-limit TOCTOU, budget reservation races, zero-cost budget bypass boundaries, block-code guardrails, max iterations, response-id/cooldown behavior, deferred guardrail logging, and tool policy.

## Weaknesses

The useful behavior is spread across many modules with mutable request dictionaries and global proxy/router state. It works as a gateway, but it is too large and stateful to copy into an agent lab without narrowing the contracts.

Some protections degrade when infrastructure is unavailable. Spend counters are Redis-first and DB-reseeded, but fallback paths use in-memory cache or read-time enforcement when Redis/DB/cost estimation is unavailable. Agentic Coding Lab should declare which checks are fail-closed.

Unknown or missing model cost data weakens pre-call reservation. LiteLLM treats explicitly zero-cost models specially and tests that unknown sparse cost entries are not treated as free in budget checks, but the reservation path cannot reserve a precise cost when pricing cannot be estimated.

Guardrail configuration has a large metadata attack surface. The code strips and validates many fields, which is good evidence, but also proof that `metadata`, `litellm_metadata`, root fields, headers, key metadata, team metadata, project metadata, and policy metadata can be easy to confuse.

Some guardrails are heuristic or policy-provider dependent. Prompt-injection phrase matching and block-code intent detection are useful safety nets, not formal command safety. For coding agents, deterministic shell/file/git policies must remain primary.

Many features are enterprise, provider-specific, UI-driven, or operational. They help the product, but they are not directly reusable as Agentic Coding Lab primitives.

## Ideas To Steal

Build a single `AgentCallGate` before any model or tool call. It should validate actor, repo scope, route/tool type, model allow-list, fallback list, budget, rate descriptors, session ID, and requested guardrails before execution starts.

Validate fallback targets at auth time. A user allowed to call `small-model` should not be able to put `restricted-model` into a context-window, content-policy, or router override fallback.

Reserve scarce resources before the expensive action. Estimate max tokens/cost/tool budget, atomically reserve it, then reconcile or release it when the call finishes or fails.

Use Redis-or-equivalent atomic scripts for multi-agent concurrency. Do not implement rate limits as "read current usage, await, then increment."

Strip caller-supplied internal metadata before injecting trusted metadata. Prefix-based stripping for internal fields is more robust than a hand-maintained list.

Make guardrail mutation permissions explicit. Requests can ask for guardrails, but disabling global guardrails or changing admin policy should require team/key permission.

Add per-session iteration counters for agent loops. A `session_id` plus `max_iterations` guard is a simple way to stop runaway coding agents without relying on the agent prompt.

Attach trace/cost/rate headers or fields to every model/tool step. Debugging agent failures is much easier when each step records call ID, selected target, retry/fallback count, cost, rate state, and policy outcomes.

Treat streaming as a separate contract. If a guardrail needs full output, buffer or defer success logging until the full stream has passed validation.

Add a tool trust-chain guard. A tool that requires trusted inputs should not consume untrusted output from a previous tool without an explicit sanitizer or approval step.

## Do Not Copy

Do not copy the whole gateway into Agentic Coding Lab. The provider matrix, admin UI, enterprise hooks, deployment assets, and management APIs are much larger than the needed prevention kernel.

Do not use heuristic prompt or code-block filters as the final authority for shell execution. They should complement deterministic command allow-lists, sandbox checks, path policies, and human approval.

Do not let fallback hide authorization or configuration errors. Local policy failures should stop, not retry on a more privileged model.

Do not rely on post-call spend tracking alone. The key transferable idea is pre-call reservation plus post-call reconciliation.

Do not log raw prompts, headers, secrets, tool outputs, or patches by default. LiteLLM has many sanitization paths, but an agent lab should start with redaction-first traces.

Do not allow fail-open safety plugins unless the policy says so at the check level. Availability callbacks and observability can fail open; security and filesystem checks should normally fail closed.

Do not represent agent state only as mutable dictionaries. LiteLLM's shape is pragmatic for a gateway, but coding-agent internals should use typed request/policy/outcome objects where possible.

## Fit For Agentic Coding Lab

Fit is conditional and high-value. LiteLLM is not an agent framework, but it is a strong implementation reference for the control plane around agents: auth, model access, fallback safety, guardrail enforcement, session limits, budgets, rate limits, routing health, cost tracking, and auditability.

The best Agentic Coding Lab adaptation is a thin model/tool gateway with a typed policy object. It should expose a small set of invariants: allowed models, allowed fallback models, allowed tools, repo/path scope, max iterations, budget/cost limit, rate descriptors, required metadata, guardrail set, and logging redaction mode.

For coding-agent errors specifically, LiteLLM's patterns map to: prevent unauthorized stronger-model fallback, stop runaway loops, cap cost before concurrent calls race, block or rewrite disallowed tool calls, quarantine response IDs/artifacts to the owning user/team, and make every failure explainable through structured traces.

## Reviewed Paths

- `README.md`, `ARCHITECTURE.md`, `litellm/proxy/README.md`: product scope, gateway architecture, request flow, proxy hooks, Redis/Postgres roles, background jobs, and route layout.
- `docs/my-website/docs/proxy/guardrails/xecguard.md`: guardrail modes, fail-closed/fail-open behavior, default-on guardrails, logging-only mode, grounding, and full-history scanning.
- `litellm/proxy/proxy_server.py`: FastAPI route dependencies, chat endpoint body handling, metadata injection, guardrail passthrough handling, spend counter cache, current-spend lookup, and spend counter updates.
- `litellm/proxy/common_request_processing.py`: common pre-call processing, `base_process_llm_request`, guardrail task gather, streaming response creation, custom headers, response-size checks, failure exception mapping, and first-chunk stream error handling.
- `litellm/proxy/route_llm_request.py`: router dispatch, team model mapping, mock flag stripping, per-request router override promotion, model existence checks, and A2A model routing.
- `litellm/proxy/litellm_pre_call_utils.py`: metadata parsing, spoofed internal-field stripping, key/team/project metadata injection, trusted guardrail metadata, tag merge policy, client tag budget visibility, and policy-engine guardrail resolution.
- `litellm/proxy/auth/user_api_key_auth.py`, `auth_checks.py`, `route_checks.py`: token parsing, centralized common checks, fallback model authorization, model access helpers, RBAC, budgets, tool allow-list, guardrail modification check, vector store access, and route allow-lists.
- `litellm/router.py`: fallback validation, retry metadata, cooldown callbacks, content-policy fallback trigger, deployment health/cooldown filtering, access-group filtering, pre-call context/RPM/region/parameter checks, and admin-paused deployment filtering.
- `litellm/proxy/hooks/parallel_request_limiter_v3.py`, `max_budget_limiter.py`, `model_max_budget_limiter.py`, `max_iterations_limiter.py`, `cache_control_check.py`, `responses_id_security.py`, `prompt_injection_detection.py`: rate descriptors, atomic reservations/refunds, user/model budget gates, session loop caps, cache-control permissions, response-id ownership, and prompt-injection checks.
- `litellm/proxy/spend_tracking/budget_reservation.py`, `litellm/proxy/db/spend_counter_reseed.py`, `litellm/proxy/hooks/proxy_track_cost_callback.py`, `litellm/proxy/db/db_spend_update_writer.py`: pre-call budget reservation, DB reseed, cost callback reconciliation, spend/failure logs, and isolated DB update batching.
- `litellm/integrations/custom_guardrail.py`, `litellm/proxy/utils.py`, `litellm/proxy/guardrails/init_guardrails.py`, `guardrail_registry.py`, `guardrail_helpers.py`, `_content_utils.py`: guardrail lifecycle, event selection, sanitized guardrail logging, pre/during/post/stream hook dispatch, model-level guardrail merge, registry, metadata permissions, and Chat/Responses text normalization.
- `litellm/proxy/guardrails/guardrail_hooks/block_code_execution/block_code_execution.py`, `tool_permission.py`, `tool_policy/tool_policy_guardrail.py`: code-execution detection, tool allow/deny/rewrite rules, parameter patterns, response/stream tool-call checks, and tool trust-chain policy.
- `litellm/proxy/example_config_yaml/tool_permission_example.yaml`, `reject_clientside_metadata_tags_config.yaml`, `spend_tracking_config.yaml`, `otel_test_config.yaml`, `test_pipeline_config.yaml`: representative configs for tool guardrails, client tag rejection, spend tracking, guardrail logging, and guardrail pipelines.
- Tests sampled: `tests/test_litellm/proxy/auth/test_router_override_fallback_auth.py`, `tests/test_litellm/proxy/hooks/test_rate_limiter_toctou.py`, `tests/test_litellm/proxy/test_budget_reservation.py`, `tests/test_litellm/proxy/guardrails/guardrail_hooks/test_block_code_execution.py`, `test_tool_policy_guardrail.py`, `test_response_rejection_guardrail_code.py`, `tests/test_litellm/proxy/hooks/test_max_iterations_limiter.py`, `tests/test_litellm/proxy/guardrails/test_deferred_guardrail_logging.py`, and `tests/test_litellm/responses/test_responses_router_cooldown.py`.

## Excluded Paths

- `ui/`, `enterprise/enterprise_ui/`, frontend assets, screenshots, icons, CSS, and dashboard-only tests: presentation/admin UI surface, not the proxy execution path.
- `litellm/proxy/_experimental/out/`, `litellm/proxy/swagger/*`, generated OpenAPI/static bundles, and generated docs artifacts: generated output or UI/API reference snapshots.
- Large reference/generated data such as `model_prices_and_context_window.json`, `provider_endpoints_support.json`, `policy_templates.json`, `license_cache.json`, `package-lock.json`, `uv.lock`, and lockfiles: important as data inputs, but not line-reviewed as design code.
- `deploy/`, `helm/`, `terraform/`, `docker/`, `ci_cd/`, and most `.github/` workflows: operational packaging and CI rather than prevention logic. I used tests and source behavior instead.
- Broad provider adapter trees under `litellm/llms/**`: sampled only where guardrail translation or Responses/cooldown behavior was relevant; most files are repetitive provider payload translation.
- `cookbook/**/*.ipynb`, broad demos, and UI-heavy examples: skipped except representative proxy config YAML because notebooks are integration demos and rendered output, not core control-plane code.
- Binary fixtures, media assets, screenshots, logos, model files, and other non-source artifacts: not relevant to design choices for preventing coding-agent errors.
- Enterprise-only integrations not present in the open execution path: noted when docs/code referenced them, but not treated as reviewed reusable implementation.
