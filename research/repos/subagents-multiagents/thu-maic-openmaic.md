# THU-MAIC/OpenMAIC

- URL: https://github.com/THU-MAIC/OpenMAIC
- Category: subagents-multiagents
- Stars snapshot: 17,753 (GitHub REST API `stargazers_count`, captured 2026-05-20)
- Reviewed commit: d9aecf8052048f9608c3aa4397494aff631ab51a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for an interactive multi-agent classroom: LangGraph director routing, role-aware agents, stateless per-turn orchestration, shared whiteboard action ledgers, structured action streaming, and PBL question/judge agents. Conditional fit for Agentic Coding Lab because the runtime targets education scenes rather than coding tasks, and several safety guarantees are prompt/filter based rather than typed, sandboxed, or verifier-backed.

## Why It Matters

OpenMAIC is useful because it shows a working multi-agent interaction pattern in a concrete product, not only a prompt pack. It turns a lesson into scenes, assigns teacher/assistant/student personas, starts discussions from generated classroom actions, streams agent speech and visual actions, and lets agents mutate a shared classroom surface.

For Agentic Coding Lab, the reusable pieces are the orchestration contracts: a director decides one next speaker at a time; each agent receives role, peer, scene, user, and whiteboard state context; actions are emitted as structured JSON and executed by a separate engine; and a client-held `DirectorState` carries turn summaries and whiteboard ledger between stateless server calls.

The repo also includes a second multi-agent shape in PBL scenes. PBL generation uses mode-gated MCP-like tool classes to build project info, roles, and issueboards. Runtime PBL chat routes `@question` and `@judge` mentions to per-issue system agents, then advances the issueboard when a judge verdict says completion is reached. That is a useful classroom-specific analogue for task coach/reviewer handoff.

## What It Is

OpenMAIC is a Next.js 16 / React 19 / TypeScript app for generating and playing AI classrooms. The app has two main paths:

- Offline classroom generation: `/api/generate-classroom` creates an async job, resolves a server-configured model, optionally runs web search, generates outlines, optionally generates agent profiles, creates scenes, generates media/TTS, persists the classroom, and exposes polling state.
- Live classroom interaction: `/api/chat` receives full client state, runs a stateless LangGraph director/agent graph, and streams SSE events (`agent_start`, `text_delta`, `action`, `cue_user`, `done`, `error`) back to the frontend.

Default agents include one teacher, one teaching assistant, and four student personas. `agentMode: "generate"` can create a course-specific teacher/assistant/student set, requiring exactly one teacher. Generated agents are embedded into stages or passed request-scoped to `/api/chat`; default agents come from the registry.

The core interaction surface is not arbitrary tool execution. Agents output a JSON array of text and action objects. The frontend buffer paces text reveal and hands actions to `ActionEngine`, which can spotlight or laser slide elements, open/draw/edit/clear/delete whiteboard elements, play videos, send widget iframe messages, or trigger discussion sessions.

PBL scenes are a separate project-based learning subsystem. Generation creates student roles, issues, and per-issue Question/Judge agents. Runtime chat resolves mentions to those agents and appends messages into the PBL project config.

## Research Themes

- Token efficiency: Mixed. Prompts summarize slide elements, quiz questions, recent peer turns, and whiteboard changes instead of replaying only raw chat. PBL chat trims recent context to the last five messages server-side. However, the live chat request sends full `storeState` from the client each iteration, so large classrooms can still be expensive without a hard token budget or artifact-reference layer.
- Context control: Strong for classroom state, weak for durable memory. `DirectorState` carries only turn count, agent response previews, and whiteboard action ledger. `buildStateContext`, `buildPeerContextSection`, `buildVirtualWhiteboardContext`, and `convertMessagesToOpenAI` isolate what each agent sees. Generated agents are stage-bound or request-scoped. There is no long-term self-learning memory beyond persisted chats/stage data.
- Sub-agent / multi-agent: Strong. The LangGraph topology is `START -> director -> agent_generate -> director`, with single-agent fast path, discussion trigger fast path, LLM director routing for multi-agent mode, max-turn limits, `USER` cueing, and content-dedup/role-diversity prompt rules. PBL adds role/project/issue agents plus question/judge system agents.
- Domain-specific workflow: Strong but education-specific. The workflow covers outline generation, slide/quiz/interactive/PBL scene generation, lecture actions, roundtable discussion, shared whiteboard, TTS/ASR, and classroom export. Coding-agent relevance comes from orchestration mechanics, not the domain content.
- Error prevention: Moderate. The repo uses required-field API validation, model/provider resolution, access-code middleware, SSRF guards for proxy media/client base URLs, SSE heartbeat, abort propagation, JSON repair/partial parsing, scene-type action stripping, role action allowlists, turn caps, empty-turn detection, stale job detection, and whiteboard conflict summaries. Param-level action validation and task-completion verification are still thin.
- Self-learning / memory: Limited. Runtime memory is session-local and client-maintained. PBL stores issue state and generated questions. Agent profiles persist per stage, but there is no adaptive memory from prior runs, no retrieval layer for past classrooms, and no measured improvement loop.
- Popular skills: No broad skill marketplace. The checked-in `skills/openmaic` OpenClaw skill is a guided SOP for setup, provider config, health checks, classroom generation, and polling. It is useful as an external-agent integration pattern with confirmation gates and server-side provider boundaries.

## Core Execution Path

Classroom generation starts at `app/api/generate-classroom/route.ts`. The route validates `requirement`, creates a file-backed job, and schedules `runClassroomGenerationJob` with `after()`. The job store records queued/running/succeeded/failed state, progress, stale-job failure after 30 minutes without updates, and final classroom URL.

`lib/server/classroom-generation.ts` is the generation spine. It resolves the server model, optionally enriches the requirement with web search, generates outlines, then resolves agents. In default mode it uses registry defaults. In generated mode it calls an LLM to produce 3-5 agents with exactly one teacher. The stage stores either `agentIds` or embedded `generatedAgentConfigs`.

Scene generation runs outline by outline. `generateSceneContent` creates slide, quiz, interactive, or PBL content. `generateSceneActions` then builds an action prompt that includes the classroom agent list; slide and quiz prompts can emit a `discussion` action, which must be last and can name a student agent initiator. `processActions` repairs invalid discussion `agentId` values by picking a student or non-teacher agent.

Live Q&A or discussion starts in `components/chat/use-chat-sessions.ts`. The frontend creates a session, reads selected agent ids, collects user profile and current stage/canvas state, then calls the shared `runAgentLoop` in `lib/chat/agent-loop.ts`. The loop repeatedly posts to `/api/chat`, processes one SSE stream, waits for UI/action drain, carries forward `DirectorState`, and stops on `cue_user`, director end, max turns, abort, missing `done`, or repeated empty agent turns.

`app/api/chat/route.ts` validates state, resolves the model, sets heartbeat SSE, and delegates to `statelessGenerate`. `statelessGenerate` builds a LangGraph with `createOrchestrationGraph`. The director node is code-only for single-agent sessions; for multi-agent sessions it uses fast-path dispatch for the first triggered discussion agent, otherwise asks an LLM to output `{"next_agent":"..."}`, `USER`, or `END`.

The agent node builds a role-specific system prompt from persona, role guideline, user profile, peer context, language directive, current state summary, virtual whiteboard state, and allowed action descriptions. The model streams a JSON array. `parseStructuredChunk` incrementally parses text/action items with `jsonrepair` and `partial-json`, emits text deltas in order, strips disallowed actions, and records `wb_*` actions in the whiteboard ledger.

The frontend `StreamBuffer` turns SSE into chat messages and paced playback. Actions are sent to `ActionEngine`, which executes slide effects, speech, whiteboard operations, video playback, widget iframe messages, and discussion triggers. The `done` event carries a compact director state for the next loop iteration.

PBL generation uses `generatePBLContent`. An LLM calls Zod-schema tools for `set_mode`, project info, agent creation, and issueboard management. Tool handlers are backed by `ModeMCP`, `ProjectMCP`, `AgentMCP`, and `IssueboardMCP` instances over shared `PBLProjectConfig`. Each issue auto-creates a Question Agent and Judge Agent. Post-processing activates the first issue and asks its Question Agent to generate initial questions.

PBL runtime uses `components/scene-renderers/pbl/use-pbl-chat.ts` and `app/api/pbl/chat/route.ts`. Messages route by `@question`, `@judge`, or direct agent-name match, defaulting to the current issue's Question Agent. Judge responses containing `COMPLETE` but not `NEEDS_REVISION` mark the issue done, activate the next issue, and generate next questions.

## Architecture

The app layer is `app/`: generation routes, chat routes, PBL routes, classroom playback pages, and health/provider verification endpoints.

The orchestration layer is `lib/orchestration/`: director graph, prompt builder, director prompt, structured JSON streaming parser, action schemas, agent registry, and summarizers for state, peer context, conversation, whiteboard ledger, and whiteboard geometry conflicts.

The runtime loop layer is split between `lib/chat/agent-loop.ts` and `components/chat/use-chat-sessions.ts`. The shared loop is framework-neutral; the React hook wires it to sessions, buffers, abort controllers, stage state, agent registry, and UI callbacks.

The action boundary is `lib/types/action.ts` plus `lib/action/engine.ts`. Agents do not directly call functions; they emit action objects. The engine translates those into stage API calls, canvas store mutations, audio playback, whiteboard updates, or widget messages.

The agent registry is `lib/orchestration/registry/`. It defines default personas, role priorities, allowed actions, persistence rules, stage-bound generated agents, and conversion to roundtable participants. Teachers get slide plus whiteboard actions; assistants/students get whiteboard actions, then prompts further restrict behavior.

The generation layer is `lib/generation/` plus `lib/server/classroom-generation.ts`. It handles outline generation, slide/quiz/interactive/PBL content, action generation, prompt formatting, JSON repair, scene building, async job progress, media generation, TTS, and persistence.

The PBL layer is `lib/pbl/`, `app/api/pbl/chat/route.ts`, and `components/scene-renderers/pbl/`. It has its own project config, agents, issueboard, chat messages, mode-gated MCP classes, question/judge prompt templates, and role-selection/workspace UI.

The verification/eval layer includes unit tests under `tests/`, Playwright tests under `e2e/`, prompt structural tests, SSRF/provider/settings tests, and LLM/VLM eval harnesses under `eval/whiteboard-layout` and `eval/outline-language`.

The OpenClaw integration is `skills/openmaic/`. It is not part of the classroom runtime; it is an external SOP skill for setup, hosted/self-hosted mode selection, provider config, service health checks, job submission, and polling.

## Design Choices

The backend chat path is stateless by design. Session history, stage state, selected agents, generated agent configs, and director state are supplied by the client on each request. This simplifies server scaling and interruption, but shifts consistency and token control to the frontend loop.

Only one agent turn is generated per server call. The frontend owns the repeated loop. This makes action execution and state refresh happen between agent turns, so the next agent can see updated whiteboard/canvas state.

The director is a separate role but not always an LLM. Single-agent sessions avoid a director LLM call. Multi-agent sessions use deterministic fast paths for the first triggered discussion turn and turn limits, then use an LLM only for routing.

Agent handoff is summary-based. The next agent sees prior `contentPreview`, `actionCount`, and whiteboard action summaries rather than the full internal reasoning of peers. `message-converter` maps other agents' assistant messages into attributed user-role content, reducing role confusion for the current agent.

Tool use is represented as structured output, not provider-native tool calls, in live classroom chat. This keeps the stream interleaved and frontend-executable, but means action schemas are enforced by prompt, parser, filters, and engine behavior rather than by a fully typed runtime validator before execution.

Whiteboard coordination is unusually explicit. The system summarizes current elements, replays ledger changes by agent, detects overlap/line-crossing/out-of-canvas conflicts, and gives different whiteboard policies to teacher, assistant, and student roles.

PBL generation uses real tool calls with mode gating. The model must switch through `project_info`, `agent`, `issueboard`, and `idle`. Each tool checks the current mode and returns structured `success:false` errors on invalid calls. Issue creation auto-spawns question/judge agents, separating coaching from judging.

The repo separates generated stage agents from global default agents. Generated agents are loaded on demand for a stage and cleared when switching stages to avoid stale generated personas leaking into preset classrooms.

Classroom generation is async and file-backed. Jobs have polling URLs, progress steps, atomic JSON writes, a per-job mutex, and stale-running detection. This is a useful long-running-agent pattern for chat-integrated systems.

## Strengths

The repo has a concrete, end-to-end multi-agent loop with user-visible handoff, not just static agent definitions. Director decisions, agent turns, action execution, and state refresh are connected.

The role model is simple and reusable: teacher leads, assistant supplements, students react/question/summarize, and priorities influence routing. Generated profiles extend that without changing the runtime contract.

Action boundaries are clear. Allowed actions live in agent config, prompts list only effective actions, runtime strips slide-only actions from non-slide scenes, and the agent node skips disallowed actions before streaming them.

Whiteboard context handling is strong. The ledger and geometry conflict detector address a common multi-agent shared-surface failure mode: agents writing over each other or duplicating existing content.

The stateless per-turn loop is a good pattern for agents that must execute UI/tool actions between model calls. It makes the next prompt reflect actual post-action state, not assumed state.

PBL's question/judge split is a useful handoff pattern. Coaching agents guide without giving direct answers; judge agents ask for evidence and produce completion feedback; issue state advances only after judge verdict.

The OpenClaw skill demonstrates a careful external-agent boundary: confirmation before state changes, no API key pasted into chat by default, server-side config over request-time overrides, and resilient polling.

The eval harness reuses production loop code for whiteboard layout evaluation. That reduces drift between eval and runtime and gives a path to measure prompt/whiteboard policy changes.

## Weaknesses

Fit is conditional because the system is a classroom app, not a coding-agent platform. Agents manipulate lesson scenes, whiteboards, widgets, and PBL issues rather than repositories, patches, tests, or review artifacts.

Token control is incomplete. Each live chat iteration sends full stage/scenes state from the client, then summarizes selected parts inside prompts. Large classrooms or media-heavy scenes could exceed budget without an artifact-id or diff-based state protocol.

Several boundaries are prompt/filter based. Action params are not fully Zod-validated before `ActionEngine` execution, and many invalid actions silently return. For coding agents, this would need typed validation, permission policy, and auditable failures.

The LLM director is not independently verified. It can end early, route poorly, or skip useful agents. The prompt has strong routing rules, but there is no deterministic policy layer beyond existence checks, trigger fast path, and max turns.

PBL completion is string-driven. The runtime marks an issue complete when a judge message contains `COMPLETE` and not `NEEDS_REVISION`. That is too brittle for high-stakes task orchestration without structured verdict output.

There is little durable memory or learning. Chats and stage data persist, but there is no retrieval of prior classrooms, no user-specific long-term learning model, no agent performance memory, and no self-improving prompt loop.

The generated-agent fallback path deserves scrutiny. `tests/server/classroom-agent-mode.test.ts` describes resetting `agentMode` to `default` after profile-generation failure, but the reviewed `lib/server/classroom-generation.ts` keeps `const agentMode = input.agentMode || 'default'` and only falls back `agents = getDefaultAgents()`. That means production can still build `generatedAgentConfigs` from default agents after profile failure; the test duplicates intended logic instead of importing the production branch.

Test coverage is strongest for prompt structure, store/settings invariants, SSRF, parsing, exports, and whiteboard conflict detection. The LangGraph director loop, streaming parser edge cases, generated-agent fallback, and PBL judge advancement have less direct deterministic coverage.

## Ideas To Steal

Use a compact `DirectorState` across stateless server calls: turn count, agent response previews, action counts, and shared-surface ledger.

Run one agent turn per request when actions mutate shared state. Execute actions, refresh state, then prompt the next agent.

Use a director prompt that sees agent roles/priorities, responded agents, conversation summary, user profile, and shared-surface state, with explicit `USER` and `END` exits.

Keep role-aware action allowlists at three levels: agent config, prompt-visible action descriptions, and runtime filtering before execution.

Adopt a whiteboard/action ledger for multi-agent shared artifacts. Attribute changes by agent, replay current content, and detect conflicts deterministically before asking the next model to act.

Use `discussion` as a generated action that hands off from preauthored content into a live multi-agent session, with a specified initiator agent.

Use PBL-style mode-gated tool groups for structured creation tasks. Make the model switch modes and expose only the tools relevant to the current phase.

Split coach and judge roles. Coaching agents help users think; judge agents evaluate completion against task context; state transitions should be explicit and logged.

Reuse production loops in eval harnesses. The whiteboard eval runner's shared `runAgentLoop` plus ActionEngine execution is a good anti-drift pattern.

Package external-agent workflows as progressive SOP skills with confirmation gates and server-side credential boundaries.

## Do Not Copy

Do not copy the full application as a coding-agent runtime. The useful parts are orchestration contracts and shared-surface coordination, not the education UI or media pipeline.

Do not rely on prompt-only action discipline for coding tools. Add typed schemas, workspace permissions, path policies, command allowlists, timeouts, and verification records.

Do not send large full application state to models by default. For coding workflows, send artifact ids, diffs, summaries, and explicit read requests instead.

Do not use substring verdicts such as `COMPLETE` to advance task state. Require structured judge output with task id, verdict enum, evidence, and confidence.

Do not let an LLM director be the only router for high-stakes work. Add deterministic constraints around role capability, task graph state, ownership, and allowed transitions.

Do not write tests that reimplement production logic instead of exercising it. The generated-agent fallback test is a warning example.

Do not treat client-supplied model credentials and base URLs as safe in shared deployments without explicit trust boundaries. OpenMAIC has SSRF checks for production client base URLs, but a coding lab should prefer server-held credentials and audited provider policies.

Do not silently swallow invalid tool/action params in a coding-agent environment. Silent no-ops are acceptable UX smoothing in a classroom whiteboard, but they hide orchestration failures during coding.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. OpenMAIC is best mined for interaction and orchestration patterns: director-mediated turn-taking, compact per-round handoff state, role-aware action scopes, shared whiteboard ledger/conflict summaries, discussion triggers, coach/judge split, and eval reuse of production loops.

The closest Agentic Coding Lab adaptation would replace classroom scenes with coding artifacts. A director would route among planner, implementer, reviewer, tester, debugger, and user; `DirectorState` would carry patch summaries, file ownership, test results, and open risks; actions would become typed repo/tool operations; and the whiteboard ledger idea would become an artifact/action ledger for files, commands, and verification evidence.

Before adoption, the lab would need stronger guardrails: deterministic task graph state, typed action validation, fail-closed tool permissions, durable artifact storage, explicit verification commands, structured judge verdicts, and server-side trace logs. The current repo is a strong design reference, not a drop-in agentic coding substrate.

## Reviewed Paths

- `/tmp/myagents-research/THU-MAIC-OpenMAIC/README.md`, `README-zh.md`, `package.json`, and `CHANGELOG.md`: product scope, feature set, architecture overview, dependencies, scripts, and release context.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/app/api/generate-classroom/route.ts`, `app/api/generate-classroom/[jobId]/route.ts`, `lib/server/classroom-generation.ts`, `lib/server/classroom-job-store.ts`, and `lib/server/classroom-job-runner.ts`: async generation jobs, agent profile mode, progress/polling, stale-job handling, and scene generation orchestration.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/app/api/chat/route.ts`, `lib/chat/agent-loop.ts`, `components/chat/use-chat-sessions.ts`, `components/chat/chat-area.tsx`, and `lib/types/chat.ts`: stateless chat API, frontend-owned loop, session state, SSE processing, abort/error handling, director state, and session types.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/orchestration/director-graph.ts`, `stateless-generate.ts`, `prompt-builder.ts`, `director-prompt.ts`, `tool-schemas.ts`, and `types.ts`: LangGraph topology, director routing, agent prompt assembly, structured stream parser, action filtering, and whiteboard ledger types.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/orchestration/summarizers/state-context.ts`, `whiteboard-ledger.ts`, `whiteboard-conflicts.ts`, `peer-context.ts`, `message-converter.ts`, and `conversation-summary.ts`: context summarization, peer handoff, message role conversion, whiteboard replay, and geometric conflict detection.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/orchestration/registry/types.ts`, `registry/store.ts`, and `lib/constants/agent-defaults.ts`: agent config schema, default personas, role action mapping, generated-agent persistence/loading, and participant conversion.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/prompts/templates/director/system.md`, `agent-system/system.md`, `agent-system-wb-teacher/system.md`, `agent-system-wb-assistant/system.md`, `agent-system-wb-student/system.md`, `slide-actions/system.md`, `quiz-actions/system.md`, and `pbl-design/system.md`: role, routing, whiteboard, discussion, and PBL prompt contracts.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/action/engine.ts`, `lib/types/action.ts`, `lib/api/stage-api*.ts`, and `lib/generation/action-parser.ts`: action vocabulary, execution engine, stage API boundary, structured output parsing, and action post-processing.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/generation/scene-generator.ts`, `prompt-formatters.ts`, `outline-generator.ts`, `json-repair.ts`, and `scene-builder.ts`: lesson generation, agent prompt injection, PBL content routing, discussion action validation, and JSON repair.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/app/api/generate/agent-profiles/route.ts`, `app/api/generate/scene-actions/route.ts`, and related `app/api/generate/*` routes by path scan: generated classroom profiles, scene action route behavior, and API validation.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/pbl/generate-pbl.ts`, `types.ts`, `pbl-system-prompt.ts`, `mcp/mode-mcp.ts`, `mcp/project-mcp.ts`, `mcp/agent-mcp.ts`, `mcp/issueboard-mcp.ts`, `mcp/agent-templates.ts`, `app/api/pbl/chat/route.ts`, and `components/scene-renderers/pbl/use-pbl-chat.ts`: PBL tool loop, mode gating, role/issue management, question/judge agents, mention routing, and issue advancement.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/components/roundtable/index.tsx`, `components/roundtable/presentation-speech-overlay.tsx`, and `components/scene-renderers/pbl-renderer.tsx` by targeted read/search: classroom discussion UI state, speaking-agent display, and PBL scene runtime.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/server/provider-config.ts`, `resolve-model.ts`, `ssrf-guard.ts`, `middleware.ts`, `app/api/proxy-media/route.ts`, and `SECURITY.md`: provider/key boundaries, client/server model resolution, production SSRF checks, access-code middleware, media proxy, and security reporting.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/eval/whiteboard-layout/*`, `eval/outline-language/*`, `tests/prompts/templates.test.ts`, `tests/orchestration/whiteboard-conflicts.test.ts`, `tests/server/classroom-agent-mode.test.ts`, `tests/generation/json-repair.test.ts`, and targeted test inventory under `tests/`: available verification, eval reuse of runtime loops, and gaps.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/skills/openmaic/SKILL.md` and `skills/openmaic/references/*.md`: OpenClaw skill workflow, hosted/local setup, provider key guidance, generation job submission, and polling reliability rules.

## Excluded Paths

- `/tmp/myagents-research/THU-MAIC-OpenMAIC/.git/`: VCS internals. Used only through Git commands to record reviewed commit and latest commit metadata.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/assets/**`, `public/**`, `app/favicon.ico`, and image/GIF/media files: static marketing/demo/UI assets; excluded from code review except for noting avatar/static-asset dependencies.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/components/ui/**`, most `components/slide-renderer/**`, settings panels, visual-only chat/roundtable subcomponents, CSS, themes, and layout-only React components: UI-only paths outside multi-agent orchestration.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/packages/pptxgenjs/**` and `packages/mathml2omml/**`: bundled workspace export/math conversion packages; not agent orchestration, memory, or handoff logic.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/prosemirror/**`, `lib/export/**`, `lib/pdf/**`, `lib/audio/**`, `lib/media/adapters/**`, `lib/web-search/**`, and provider adapter internals: domain/provider implementation details; reviewed only at boundary files where they affect orchestration or security.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/lib/i18n/locales/*.json`, translation guides, fixture JSON, scenario data, and generated eval output directories: data/localization/eval inputs rather than runtime orchestration design.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/e2e/**` and most browser page objects/fixtures: end-to-end UI coverage was path-scanned, but not deeply reviewed because the requested focus was multi-agent roles, handoff, orchestration, memory, tools, verification, and error handling.
- `/tmp/myagents-research/THU-MAIC-OpenMAIC/.github/**`, community docs, Docker/Vercel metadata, lockfiles, formatting configs, and build/deploy metadata: operational metadata outside the core research focus.
- `node_modules`, `.next`, `dist`, `build`, generated output, and vendored dependency trees: absent from the reviewed checkout or intentionally excluded as generated/vendor material.
