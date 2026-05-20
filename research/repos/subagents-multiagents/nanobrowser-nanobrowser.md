# nanobrowser/nanobrowser

- URL: https://github.com/nanobrowser/nanobrowser
- Category: subagents-multiagents
- Stars snapshot: 13,016 (GitHub REST API `stargazers_count`, captured 2026-05-20)
- Reviewed commit: 322384f8b4d48d8614343e51efca68c85e64f90b
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal browser-automation reference for planner/navigator role split, browser-state-to-action contracts, DOM-index action grounding, prompt-injection wrapping, firewall URL policy, replayable action history, and extension-runtime event streaming. Conditional fit because it is an end-user Chrome extension rather than a coding-agent framework, has broad browser permissions, no true sandbox beyond Chrome extension boundaries and URL filtering, no parallel subagents, no durable multi-worker task ledger, and little test coverage around the planner/navigator execution loop.

## Why It Matters

Nanobrowser is useful for Agentic Coding Lab because it turns web automation into a small multi-agent runtime: a planner reasons about strategy and task completion, a navigator acts against a structured browser state, and a host executor owns task state, tool execution, pause/cancel, failure budgets, and event reporting.

The most reusable pattern is the browser/tool boundary. The model does not receive raw browser control. It receives a typed action schema plus an indexed, filtered DOM view, then the host validates action arguments and performs Chrome/Puppeteer operations. This is directly relevant to coding-agent tools: let agents propose structured operations, keep authority in the host runtime, and feed back compact action results and state deltas.

The caution is also important. The repo runs inside a user browser with `debugger`, `scripting`, `tabs`, `activeTab`, `webNavigation`, `unlimitedStorage`, and `<all_urls>` permissions. It relies heavily on prompt rules, tag wrapping, a simple sanitizer, and a configurable firewall. Those are useful defense layers, but not enough as a general sandbox or permission model for arbitrary coding-agent side effects.

## What It Is

Nanobrowser is a TypeScript monorepo for a Manifest V3 Chrome/Edge extension. The main user experience is a side panel chat interface, options pages for model/firewall/analytics settings, and a background service worker that runs the automation loop.

The reviewed runtime has two active agents despite `CLAUDE.md` still describing three. `PlannerAgent` produces structured JSON with `observation`, `challenges`, `done`, `next_steps`, `final_answer`, `reasoning`, and `web_task`. `NavigatorAgent` produces structured JSON with `current_state` and an action array. Legacy validator settings are explicitly removed from storage, and side-panel code only keeps validator event handling for historical messages.

The executor wires one `AgentContext`, one `MessageManager`, one `EventManager`, one `BrowserContext`, a planner LLM, a navigator LLM, and an action registry. The background service keeps a single `currentExecutor`, `browserContext`, and side-panel port, so tasks are serial and global within the extension instance.

## Research Themes

- Token efficiency: Browser state is reduced to an indexed list of interactive elements, selected attributes, tab metadata, scroll info, optional screenshot, and recent action results. DOM formatting removes duplicated attributes and caps attribute text. However, `maxInputTokens` and `MessageManager.cutMessages()` exist but are not called in the execution path, so there is no active history compaction beyond state-message removal.
- Context control: User requests are wrapped in `<nano_user_request>` tags; page content, cached findings, and attachments are wrapped in `<nano_untrusted_content>` tags; planner outputs are inserted as `<plan>...</plan>` messages. The navigator removes transient browser state messages after model output, while durable action results enter memory only when `includeInMemory` is true.
- Sub-agent / multi-agent: The system is a sequential planner/actor workflow, not a swarm. Planner runs every `planningInterval` steps or whenever navigator claims done. Navigator executes action batches, and planner alone confirms final completion. There is no parallel subagent execution, no agent handoff graph, and no per-worker workspace isolation.
- Domain-specific workflow: Strong browser automation workflow. The runtime includes search, navigation, tab management, click/input, scrolling, keyboard, dropdown, cache, wait, and done actions. Extraction behavior is mostly prompt-driven: analyze visible state, cache findings, scroll one page, repeat up to a limit, then answer.
- Error prevention: Useful controls include Zod schemas for action/model outputs, dynamic tool schemas, structured-output fallback parsing, URL allow/deny filtering, dangerous URL prefixes blocked even when firewall is disabled, DOM-change interruption in multi-action sequences, max steps, max failures, abort-based cancellation, auth/bad-request/forbidden error classification, and replay retries.
- Self-learning / memory: No adaptive learning. Chat messages and optional agent step history are stored in Chrome local storage. Replay can reuse prior action history by remapping old interacted elements to current DOM indexes. Follow-up tasks reuse prior message history and keep only action results marked for memory.
- Popular skills: Planner/navigator role split, indexed DOM action grounding, transient state-message lifecycle, action-result memory flags, simple prompt-injection wrappers, firewall-backed browser policy, event stream with actor/state/details, and replay-by-history with element remapping.

## Core Execution Path

The side panel opens a long-lived `side-panel-connection` port. The background service rejects unauthorized port senders, then handles messages such as `new_task`, `follow_up_task`, `cancel_task`, `pause_task`, `resume_task`, `state`, `screenshot`, `speech_to_text`, and `replay`.

For a new task, `setupExecutor()` loads providers, cleans up legacy validator settings, loads planner/navigator model configs, creates LangChain chat models, applies firewall settings to `BrowserContext`, maps general settings into agent options, and creates an `Executor`. The executor creates a fresh `MessageManager`, `EventManager`, `AgentContext`, `NavigatorPrompt`, `PlannerPrompt`, `ActionBuilder`, `NavigatorActionRegistry`, `NavigatorAgent`, and `PlannerAgent`.

`Executor.execute()` emits `task.start`, tracks analytics, resets `nSteps`, and loops up to `maxSteps`. At each iteration it checks pause/stop, optionally runs planner, then runs navigator. Planner runs on step 0, every configured interval, and immediately after navigator returns `done`. Planner completion is authoritative: navigator's `done` only triggers a validating planner pass.

`runPlanner()` optionally asks navigator to add current browser state to memory, invokes planner with a planner system prompt plus all messages after the navigator system prompt, inserts the planner JSON as a `<plan>` message near the state message, and stores `finalAnswer` when `done` is true. If planner returns a recoverable error, consecutive failures increase; auth, bad request, forbidden, URL policy, cancellation, and extension-conflict errors bubble up.

`NavigatorAgent.execute()` adds a browser state message, snapshots `BrowserStateHistory`, calls the model, fixes malformed action arrays or JSON strings where possible, removes the transient state message, records model output as a tool-call-like AI message, and executes `doMultiAction()`. Action results become `context.actionResults`, and the final action's `isDone` flag drives navigator's local done signal.

`doMultiAction()` executes proposed actions sequentially. For each action it gets the single action name, validates it exists in the registry, checks whether indexed DOM actions are still safe after earlier actions, calls the host action handler, stores interacted element history for indexed actions, waits briefly, and records recoverable action errors as memory-visible `ActionResult`s. If more than three action errors occur in one action batch, the batch fails.

`BrowserContext` owns tab selection and page attachment. It creates `Page` objects over Chrome tabs, attaches Puppeteer over `ExtensionTransport.connectTab`, switches/open/closes tabs through Chrome APIs, checks URL policy before navigation/open, collects all tabs, and returns current `BrowserState`.

`Page` waits for page/network stability, injects DOM scripts, builds a clickable element tree, collects scroll metadata, optionally takes screenshots, and exposes browser operations. For element actions it resolves the indexed DOM element to CSS/XPath selectors, handles iframe traversal, scrolls elements into view, clicks or types through Puppeteer/evaluate, and re-checks URL policy after navigation.

Completion emits `task.ok` only when planner marks done. Max steps emits `task.fail`. Stop/cancel emits `task.cancel`. Errors are categorized for analytics and surfaced to the side panel. If replay history is enabled, executor serializes `AgentStepHistory` to Chrome storage for later replay.

## Architecture

The repo is a pnpm/Turbo monorepo. Runtime code is split across `chrome-extension/`, `pages/`, and `packages/`. The important execution layer is in `chrome-extension/src/background`, with storage contracts in `packages/storage`.

The background service worker is the orchestration host. It owns the global browser context and current executor, validates the side-panel port origin, converts user messages into executor calls, forwards `AgentEvent`s back to UI, and cleans up browser attachments on terminal states or debugger detach.

The agent layer has clear internal contracts:

- `AgentContext`: task id, abort controller, browser context, message manager, event manager, options, pause/stop flags, failure count, step count, action results, state-message marker, step history, and final answer.
- `BaseAgent`: LangChain model invocation, structured-output setup, provider/model capability quirks, manual JSON extraction, think-tag removal, and Zod validation.
- `PlannerAgent`: strategy and completion validator with a fixed output schema.
- `NavigatorAgent`: browser-state-driven actor with dynamic action schema and replay support.
- `ActionBuilder`: host-side action implementations over `BrowserContext` and `Page`.

The browser layer separates tabs/pages from model reasoning. `BrowserContext` handles tab lifecycle and URL policy. `Page` handles Puppeteer attachment, DOM state, screenshots, navigation, scrolling, text input, clicks, dropdowns, and key events. DOM services build a tree of interactive elements and map highlight indexes to `DOMElementNode`s.

The context layer uses LangChain messages but models browser actions as AI tool calls for history consistency. `MessageManager` stores token estimates, task messages, state messages, planner messages, model outputs, tool placeholders, optional sensitive-data replacement, and optional file path hints. The active runtime uses the default settings and does not pass sensitive data maps or file paths.

The event layer is lightweight. `EventManager` stores callbacks by event type and emits `AgentEvent`s with `actor`, `state`, `taskId`, `step`, `maxSteps`, `details`, timestamp, and type. The side panel converts these events into visible progress, final answers, and chat history records.

## Design Choices

Planner and navigator are deliberately asymmetric. Planner does strategic reasoning and final validation; navigator does step-level browser actions. This avoids giving the action agent unilateral completion authority and creates a useful review point after `done`.

Planner cadence is periodic, not continuous. `planningInterval` controls cost and latency, while navigator can force planner review by returning done. This is a practical pattern for long browser tasks where strategy does not need to be recomputed after every click.

Browser state is a host-produced observation, not model-discovered raw HTML. The state message includes current tab, other tabs, scroll info, page bounds, action results, and a formatted interactive-element list. This keeps the model's action space grounded in indexes.

Actions are model-facing JSON but host-owned code. Zod schemas define allowed arguments; `Action.call()` validates input before invoking the handler; the registry limits action names. This is a good tool boundary even though the underlying extension permissions are broad.

Multi-action batching is allowed but guarded. The navigator can return several actions, which helps form filling and simple sequential operations. If later actions depend on element indexes and the page's branch-path hash set changes, execution stops and feeds back that something new appeared.

Context isolation combines tags, sanitizer, and prompt rules. Web content is labeled as untrusted and repeated warnings tell the model not to treat it as instructions. A regex sanitizer blocks common prompt-injection and sensitive-data patterns before content is wrapped.

URL policy is enforced in host code. Dangerous protocols and Chrome extension pages are always blocked. Optional firewall allow/deny lists are loaded from settings and checked before navigation/open and after page changes.

Replay stores model output, action results, and browser history. During replay, the navigator parses prior actions, uses historical interacted elements to update current indexes, retries failed steps, and can skip or stop on failures.

Analytics is separated from task content by design. The privacy policy says optional analytics records task timing, error categories, visited domains, and anonymous usage statistics, not full URLs, page content, screenshots, or task instructions. Code categorizes common error classes and tracks domain visits.

## Strengths

- Clear planner/navigator division with planner-owned final validation.
- Single `AgentContext` makes execution state explicit and easy to inspect.
- Typed planner schema and dynamically generated navigator action schema reduce free-form output risk.
- Host-side action registry is a concrete browser/tool boundary.
- Browser observations are compact and action-grounded through highlighted DOM indexes.
- Multi-action guard detects page changes before executing stale indexed actions.
- URL filtering is enforced in runtime code, not only in prompts.
- Dangerous URL prefixes are blocked even when the user firewall is disabled.
- Side-panel port origin check prevents arbitrary extension contexts from driving the background port.
- Pause, stop, and cancel use explicit flags plus `AbortController`.
- Max steps and max consecutive failures bound runaway tasks.
- Authentication, bad request, forbidden, abort, extension-conflict, and URL-policy errors are classified separately.
- Prompt-injection defenses are integrated at message construction and action-cache boundaries.
- Replay history can remap DOM element indexes instead of blindly reusing stale indexes.
- Browser cleanup detaches Puppeteer sessions and removes highlights on terminal task states.

## Weaknesses

- Multi-agent design is sequential two-agent orchestration, not parallel subagents or a general multi-agent workflow engine.
- Documentation still mentions a Validator agent, but runtime storage and event handling show validator is legacy/removed.
- `chrome-extension/src/background/task/manager.ts` is empty, and task state lives mainly in one global `currentExecutor`, one `BrowserContext`, and in-memory `AgentContext`.
- The extension requires broad powers: `<all_urls>`, `debugger`, `scripting`, `tabs`, `activeTab`, `webNavigation`, and `unlimitedStorage`.
- There is no per-action human approval gate for risky browser operations beyond prompt instructions such as checkout/password cautions.
- The firewall is URL/domain based; it does not classify action side effects, data sensitivity, form submission risk, or site trust.
- Prompt-injection protection is simple regex sanitization plus wrappers. It helps, but it is not a robust content security proof.
- `MessageManager.cutMessages()` and `maxInputTokens` are not wired into the active execution path, so long histories can still grow until model/provider limits fail.
- Sensitive-data placeholder replacement exists in `MessageManagerSettings`, but the executor constructs the default manager without passing a sensitive data map.
- Planner and navigator share the same message history, so roles are separated by prompts and schemas rather than isolated context stores.
- Page-action methods sometimes continue after timeouts or non-critical preparation failures, which is practical but can hide flaky page state.
- Action retry is mostly limited to replay and click fallback; normal execution relies on the next planner/navigator cycle after failures.
- Unit tests found in the reviewed paths focus on guardrail sanitization. There is no comparable checked-in test coverage for executor loop, planner/navigator orchestration, URL policy edge cases, DOM-index remapping, or browser action failure modes.
- Analytics is optional and content-limited, but enabled by default according to `PRIVACY.md`; privacy-sensitive deployments should revisit that default.

## Ideas To Steal

Use planner-confirmed completion. Let an actor propose `done`, but require a separate planner/reviewer role to validate completion and produce the final answer.

Use indexed observations plus typed actions for browser or coding tools. The model should pick from host-generated handles and schemas; the host should validate and execute.

Keep transient state messages transient. Add current state for a model call, then remove it before appending durable model output and action results. This reduces stale observation reuse.

Use `includeInMemory` flags on tool results. Not every action result deserves long-term context; let tools decide what should feed future steps.

Stop action batches when the world changes. DOM branch-path hashes are a browser-specific version of a more general rule: if an indexed target set changed after action one, ask the model to re-observe before action two.

Insert planner output as a first-class plan message. A `<plan>` artifact in history gives the actor explicit strategy without merging planner and actor prompts.

Treat replay as a separate host capability. Store model output, action result, interacted element identity, and step state, then remap current handles at replay time.

Enforce URL/tool policy in host code. Prompt rules are necessary context, but the runtime should still block forbidden targets even when the model requests them.

Stream structured actor/state events to UI. A small event contract with task/step/action states is enough to drive progress, logs, history, and cancellation UX.

## Do Not Copy

Do not treat a broad browser extension permission set as a safe sandbox. Coding-agent tools need process, filesystem, network, credential, and approval boundaries that are stricter than extension host permissions.

Do not rely only on prompt instructions for sensitive actions such as login, checkout, destructive forms, or data exfiltration. Add host-side action classification and approval gates.

Do not copy regex-only prompt-injection filtering as the full defense. Keep tags and sanitization, but add source provenance, taint tracking, stricter tool argument policies, and adversarial tests.

Do not leave token budgeting unused. If `maxInputTokens` exists, call the compaction/trimming path and test it under long histories and screenshots.

Do not use one global executor/context model for workflows that need concurrent tasks, isolated tenants, or multiple browser sessions.

Do not document removed agents as active architecture. Stale role docs are especially costly in multi-agent systems because they change how users reason about responsibility and verification.

Do not let replay re-execute side-effectful actions without a policy layer. Replay is powerful, but it should know which actions are safe, idempotent, or require confirmation.

Do not assume structured output support is uniform across providers. Nanobrowser has provider-specific fallbacks; a coding-agent lab should make those compatibility paths explicit and test them.

## Fit For Agentic Coding Lab

Fit is conditional but high-value for browser/tool-boundary patterns. Nanobrowser is not a coding-agent support system directly, and it does not solve subagent delegation or multi-worker coordination. It is strongest as a reference for host-mediated tool execution, task-state lifecycle, observation/action contracts, and planner/actor validation.

Agentic Coding Lab should mine the repo for a hardened "planner plus actor plus verifier" workflow shape. The lab version should add per-tool permission metadata, command/file/network scopes, approval gates, durable traces, active token budgeting, stronger prompt-injection tests, and isolated task sessions.

A useful artifact would be a browser or UI automation harness with these pieces: host-generated element handles, typed model actions, transient observation messages, planner-confirmed completion, action-result memory flags, URL/action policy checks, replayable traces, and focused tests for stale handles, injected page text, forbidden URLs, cancellation, and max-failure behavior.

## Reviewed Paths

- `/tmp/myagents-research/nanobrowser-nanobrowser/README.md`: project positioning, multi-agent claim, model configuration, privacy positioning, browser support, build flow, and user-facing workflow examples.
- `/tmp/myagents-research/nanobrowser-nanobrowser/CLAUDE.md`: architecture notes, commands, claimed three-agent architecture, workspace layout, and test guidance.
- `/tmp/myagents-research/nanobrowser-nanobrowser/PRIVACY.md` and `SECURITY.md`: local processing claims, optional analytics scope, LLM-provider boundary, API key storage claims, and vulnerability reporting policy.
- `/tmp/myagents-research/nanobrowser-nanobrowser/package.json`, `chrome-extension/package.json`, `pnpm-workspace.yaml`, and `turbo.json`: monorepo shape, scripts, dependency stack, and test/build commands by reference.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/manifest.js`: Manifest V3 permissions, host permissions, side panel, background service worker, content scripts, and web-accessible resources.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/index.ts`: service-worker orchestration, side-panel port validation, message dispatch, executor setup, model creation, firewall/general settings application, event forwarding, debugger detach cleanup, and replay entrypoint.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/executor.ts`: planner/navigator loop, planning interval, completion validation, follow-up task handling, pause/cancel/stop, failure handling, analytics, history storage, cleanup, and replay.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/types.ts`: `AgentOptions`, defaults, `AgentContext`, `ActionResult`, `StepMetadata`, brain schema, and output contracts.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/agents/base.ts`: structured output, provider/model capability decisions, manual JSON extraction, think-tag removal, abort handling, and Zod validation.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/agents/planner.ts`: planner schema, planner prompt assembly, image stripping for planner, output sanitization, planner events, and model error classification.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/agents/navigator.ts`: navigator dynamic schema, browser state ingestion, model output repair, transient state-message removal, action execution, multi-action DOM-change guard, step history capture, replay parsing, retries, and index remapping.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/actions/schemas.ts` and `actions/builder.ts`: action schemas, Zod validation, default action registry, search/navigation/tab/click/input/scroll/dropdown/cache/wait/done action handlers, event emission, and memory inclusion flags.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/messages/service.ts`, `messages/views.ts`, and `messages/utils.ts`: task wrapping, untrusted content wrapping, sanitizer integration, message history, token estimates, state/model/plan/tool messages, sensitive-data replacement, and unused cut path.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/prompts/base.ts`, `prompts/navigator.ts`, `prompts/planner.ts`, and `prompts/templates/*.ts`: browser-state message construction, scroll/action result formatting, date context, planner/navigator role prompts, security rules, extraction workflow, login policy, and plan-following rule.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/agent/event/types.ts` and `event/manager.ts`: event actors, task/step/action states, event payload shape, subscriber management, and async emit behavior.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/browser/context.ts`, `browser/page.ts`, `browser/views.ts`, and `browser/util.ts`: tab/page lifecycle, Puppeteer attachment, Chrome API boundaries, URL policy, safe redirects, browser state, PageState/BrowserState types, screenshot and DOM state handling, element location, input/click/scroll/dropdown/key behavior, and cleanup.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/browser/dom/service.ts`, `dom/views.ts`, `dom/clickable/service.ts`, `dom/history/service.ts`, and `dom/history/view.ts`: clickable DOM extraction integration, iframe handling, compact DOM string formatting, attribute filtering, element hashing, and historical element matching.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/services/guardrails/*.ts` and `services/guardrails/__tests__/guardrails.test.ts`: threat types, sanitizer patterns, strictness options, wrapper integration tests, and sanitizer behavior.
- `/tmp/myagents-research/nanobrowser-nanobrowser/packages/storage/lib/settings/agentModels.ts`, `firewall.ts`, `generalSettings.ts`, `llmProviders.ts`, `analyticsSettings.ts`, and `types.ts`: planner/navigator model settings, legacy validator cleanup, firewall storage, general execution settings, provider config, and analytics defaults.
- `/tmp/myagents-research/nanobrowser-nanobrowser/packages/storage/lib/chat/history.ts` and `types.ts`: chat session metadata/messages, agent step history storage, history load/store behavior, and replay history boundary.
- `/tmp/myagents-research/nanobrowser-nanobrowser/pages/side-panel/src/SidePanel.tsx` and `pages/side-panel/src/types/event.ts`: runtime event consumption, chat-state updates, replay command path, new/follow-up task messages, and legacy validator event compatibility.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/src/background/services/analytics.ts` and `speechToText.ts`: error categorization, task/domain analytics boundaries, and speech-to-text provider boundary.

## Excluded Paths

- `/tmp/myagents-research/nanobrowser-nanobrowser/.git/**`: VCS internals. Used only through Git commands to record commit and date.
- `/tmp/myagents-research/nanobrowser-nanobrowser/README-*.md`: translations of the main README. Main English README was reviewed as canonical project docs.
- `/tmp/myagents-research/nanobrowser-nanobrowser/pages/options/**`: UI implementation for settings. Storage contracts and background consumption were reviewed instead; UI layout itself is not multi-agent runtime logic.
- `/tmp/myagents-research/nanobrowser-nanobrowser/pages/side-panel/src/components/**` and UI CSS/assets: chat rendering and controls were excluded except where `SidePanel.tsx` drives runtime task/event/replay messages.
- `/tmp/myagents-research/nanobrowser-nanobrowser/pages/content/**`: content-script plumbing was excluded; browser automation runtime was reviewed through background browser and DOM services.
- `/tmp/myagents-research/nanobrowser-nanobrowser/packages/ui/**`, `packages/shared/**`, `packages/i18n/**`, `packages/hmr/**`, `packages/vite-config/**`, `packages/tailwind-config/**`, `packages/dev-utils/**`, `packages/schema-utils/**`, `packages/zipper/**`, and `packages/tsconfig/**`: shared UI/build/i18n/package utilities. Reviewed only where imports affected runtime contracts.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/public/buildDomTree.js`: generated/runtime DOM extraction script. Its integration path and sandbox/cross-origin behavior were reviewed through `dom/service.ts` and targeted search, not by deep-reading the full generated file.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/public/*.png`, `public/bg.jpg`, and `pages/side-panel/public/icons/**`: static visual assets.
- `/tmp/myagents-research/nanobrowser-nanobrowser/chrome-extension/public/permission/**`: microphone permission page UI. Relevant permission behavior was reviewed only through side-panel and speech-to-text flow.
- `/tmp/myagents-research/nanobrowser-nanobrowser/packages/i18n/locales/**`: localized message strings. Error/state key patterns were sufficient from source usage.
- `/tmp/myagents-research/nanobrowser-nanobrowser/update_version.sh`, `UPDATE-PACKAGE-VERSIONS.md`, build configs, generated package outputs, lockfile internals, and release/zip plumbing: operational support, not agent orchestration.
- External systems and services: Chrome/Edge extension runtime, Chrome Web Store, LangChain providers, OpenAI/Anthropic/Gemini/Ollama/Groq/Cerebras/Llama/custom APIs, PostHog, Puppeteer internals, and linked Browser Use/Puppeteer projects were treated as boundaries; only local adapter code was reviewed.
