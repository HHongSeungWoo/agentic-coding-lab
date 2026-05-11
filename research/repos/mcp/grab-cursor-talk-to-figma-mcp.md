# grab/cursor-talk-to-figma-mcp

- URL: https://github.com/grab/cursor-talk-to-figma-mcp
- Category: mcp
- Stars snapshot: 6,746 (GitHub REST API, captured 2026-05-11)
- Reviewed commit: 1c46823f08af9e5da54e78f36b018e95491b33e1
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful design-tool MCP bridge reference for coding agents that need live Figma reading and mutation. Steal the local relay, channel join, progress update, chunked design scans, and workflow-prompt patterns. Do not copy the unauthenticated WebSocket trust model, analytics defaults, packaging gaps, or all-powerful live document mutation surface without a permission layer.

## Why It Matters

Figma is a real source of UI context for coding agents: selected frames, text, layout, fills, strokes, components, annotations, prototype flows, and exported images often carry the design intent that code alone cannot show. This repo is a concrete MCP bridge from an AI coding client to the Figma Plugin API, not just a REST wrapper around Figma file JSON.

The interesting pattern is the execution boundary. MCP cannot directly call Figma plugin APIs, so the repo splits control into a stdio MCP server, a local WebSocket relay, and a Figma plugin UI/main-thread pair. That gives an agent live document access while the human has Figma open.

## What It Is

The repo implements "Talk to Figma MCP" with three runtime pieces:

- `src/talk_to_figma_mcp/server.ts`: Node/Bun MCP stdio server using `@modelcontextprotocol/sdk`, `ws`, `uuid`, and `zod`.
- `src/socket.ts`: Bun WebSocket relay on port 3055 that groups connected clients by channel.
- `src/cursor_mcp_plugin/`: Figma plugin. `ui.html` owns WebSocket connection/channel state and analytics; `code.js` owns Figma API command execution.

The MCP server exposes 40 tools and 6 prompts. Tools cover document and selection reads, node info, creation, text replacement, color/stroke/layout edits, deletion, cloning, components, annotations, prototype reactions, FigJam connectors, focus/selection, and base64 PNG export. Prompts encode design strategy, read strategy, text replacement, annotation conversion, instance override transfer, and reaction-to-connector conversion.

## Research Themes

- Token efficiency: Mixed. `filterFigmaNode()` strips vectors, image refs, bound variables, and converts colors to hex; `scan_text_nodes` returns compact text node records with path/bbox/font info. But full node JSON, base64 image exports, and broad tool schemas can still flood context.
- Context control: Moderate. The user must select a Figma node, join a channel, and request specific scans. Chunked text scans and type scans avoid dumping the whole file by default, but there is no MCP roots-like scope or per-tool capability gating.
- Sub-agent / multi-agent: Weak to conditional. Channels allow multiple clients in one relay, but the relay broadcasts to every other client in the channel and has no ownership, locking, or role model.
- Domain-specific workflow: Strong. The tool surface is specific to Figma design work: auto layout, annotation migration, component instances, prototype reactions, connector visualization, text replacement, and visual export.
- Error prevention: Moderate. Zod schemas, required channel join, request IDs, timeouts, progress-based timeout resets, chunking, and Figma node-type checks help. Destructive live mutations, deletion tools, and no dry-run/approval model are major gaps.
- Self-learning / memory: Weak. Figma `clientStorage` persists server settings, analytics client ID, and default connector ID, but no agent memory or learned design rules.
- Popular skills: Conditional. There are no external skill packages, but the 6 MCP prompts act like embedded workflow skills for repeatable design operations.

## Core Execution Path

A typical run starts the WebSocket relay with `bun socket`, which executes `src/socket.ts` and listens on port 3055. The user runs the Figma plugin; `ui.html` opens `ws://localhost:3055`, generates an 8-character random channel, sends a `join` message, and displays the channel. The coding agent starts the MCP server with `bunx cursor-talk-to-figma-mcp@latest` or local `bun src/talk_to_figma_mcp/server.ts`, then calls `join_channel` with the channel shown by the plugin.

The MCP server connects to the relay at `ws://localhost:3055` by default. `join_channel` sends a special `type: "join"` message; every other tool goes through `sendCommandToFigma()`, which creates a UUID, requires `currentChannel`, stores a pending promise with a 30s timeout, and sends a `type: "message"` payload containing `{ id, command, params }`.

The relay stores clients in `Map<string, Set<WebSocket>>`. Join creates or reuses the channel. Message events are broadcast to all other clients in the same channel, not back to the sender. Progress updates are forwarded separately so long operations can reset the MCP timeout.

The Figma plugin UI receives a broadcast command and posts `{ type: "execute-command", id, command, params }` to plugin main code with `parent.postMessage`. `code.js` dispatches through `handleCommand()`, calls Figma Plugin API methods such as `figma.getNodeByIdAsync`, `node.exportAsync({ format: "JSON_REST_V1" })`, `figma.createFrame`, `figma.loadFontAsync`, `figma.annotations`, `figma.currentPage.selection`, and `figma.viewport.scrollAndZoomIntoView`, then posts `command-result` or `command-error` back to UI.

The UI serializes the result onto the WebSocket with the same request ID. The MCP server matches that ID in `pendingRequests`, clears the timeout, resolves or rejects, and returns MCP `text` content. For long operations, plugin code sends `command_progress` to UI; UI forwards `progress_update` over the relay; the MCP server updates `lastActivity` and extends inactivity timeout to 60s.

## Architecture

The repo is small but dense:

- Root `package.json` publishes `dist/server.js` as the MCP binary `cursor-talk-to-figma-mcp` and defines `socket`, `setup`, and `build` scripts.
- `tsup.config.ts` bundles only `src/talk_to_figma_mcp/server.ts`; the Figma plugin is not bundled.
- `src/talk_to_figma_mcp/server.ts` registers MCP tools/prompts, validates tool parameters with Zod, manages the WebSocket client, tracks pending requests, filters Figma node responses, and starts `StdioServerTransport`.
- `src/socket.ts` is a local relay only; it has no MCP awareness beyond routing JSON messages by channel.
- `src/cursor_mcp_plugin/manifest.json` declares Figma/FigJam support, dynamic-page document access, no explicit plugin permissions, and network access to `ws://localhost:3055` plus Google Analytics.
- `src/cursor_mcp_plugin/ui.html` is both UI and WebSocket client. It also sends GA4 Measurement Protocol events for plugin open, channel join, command name, success/error, and duration.
- `src/cursor_mcp_plugin/code.js` is the runtime command executor. It is over 4,000 lines and includes duplicated text/font helper logic also present in `setcharacters.js`.

There are no tests or lint scripts. `rtk npm run build` succeeded after installing dependencies in the temp clone, producing `dist/server.js`, `dist/server.cjs`, sourcemaps, and declarations. Full runtime verification was not possible in this shell because Bun and a live Figma plugin session were unavailable.

## Design Choices

The local relay is the central design choice. It avoids embedding credentials for Figma REST APIs and gives the agent access to the currently open Figma document, but it makes user presence and local process trust mandatory.

The channel join is a lightweight pairing mechanism. The plugin generates a short random channel and the MCP client must explicitly join it. This prevents accidental cross-talk between default clients but is not authentication.

The server uses typed tools rather than a single `execute_code` escape hatch. That is good for agent planning, discoverability, and parameter validation. The downside is a large always-visible schema surface.

Context extraction is lossy by design. `filterFigmaNode()` removes vectors and large image refs, keeps IDs/names/types/layout/text/style fields, converts colors to hex, and recurses children. Text scans return path, depth, bbox, font, and characters. This is useful for design-to-code because the agent sees semantic-ish layers instead of raw canvas data.

Long operations are chunked inside the plugin, not streamed as MCP partial results. Chunking prevents Figma UI freezes and progress updates keep the MCP request alive, but the final MCP response still arrives after completion.

Workflow prompts encode multi-step procedures around tools. The most transferable examples are text replacement with chunk/export verification, annotation conversion via scan/match/apply, component override propagation, and prototype reaction conversion into connector lines.

## Strengths

It bridges the real live Figma document, including current selection, local components, annotations, prototype reactions, and viewport selection/focus. That is more actionable for UI agents than static screenshots or exported design files alone.

The request-response path is simple and inspectable: request ID, channel, command, params, result/error. This is easy to debug and easy to port to another design tool.

The design context filters are practical. Removing vectors and image refs while preserving layout, style, text, and hierarchy keeps many reads usable by an LLM.

Chunked scanning and batch mutation are strong patterns. `scan_text_nodes`, `set_multiple_text_contents`, `delete_multiple_nodes`, and component scans show how to keep long Figma plugin tasks responsive and report progress.

The prompt layer is domain-aware. It does not just expose tools; it tells the agent which sequence to use for design reading, text replacement, annotation migration, instance override transfer, and prototype connector generation.

The build for the MCP server succeeds with `tsup`, so the TypeScript server path is at least mechanically valid at the reviewed commit.

## Weaknesses

The trust boundary is weak. Any local process that can connect to the relay and guess or learn a channel can issue live Figma mutations. If users uncomment `hostname: "0.0.0.0"` for WSL, the risk extends beyond localhost.

There is no per-tool permission model. Read, write, delete, export, and component mutation tools are all available after channel join. MCP tool annotations for destructive/read-only behavior are not used.

The relay has no authentication, no origin checks, no message schema validation, and logs full JSON payloads. Exported images, text content, layer names, and design data can appear in relay logs.

Analytics are default-on in the plugin UI. The GA4 measurement ID and API secret are hardcoded, and the plugin tracks command names, durations, channel, port, success, and truncated error strings. The UI text says no file content or personal data is collected, but there is no opt-out in the plugin UI.

Packaging is inconsistent. Root `package.json` publishes only `dist` and README, with a bin for the MCP server but no `cursor-talk-to-figma-socket` bin. The plugin UI tells users to run `bunx cursor-talk-to-figma-socket`, while the repo script is `bun socket`. `Dockerfile` exposes 3055 but runs the MCP stdio server, not the socket relay.

Port configurability is inconsistent. The relay is hardcoded to port 3055. The plugin UI lets users enter a port, but the production manifest only allows `ws://localhost:3055`. AGENTS/CLAUDE claim the relay port is configurable via `PORT`, but `src/socket.ts` does not read it.

The MCP response matcher only resolves when `myResponse.result` is truthy. A legitimate `null`, `false`, `0`, or empty-string result could hang until timeout.

Progress percentages are inconsistent in some paths. `get_reactions` and `create_connections` send progress as fractions from 0 to 1, while the UI expects 0 to 100.

There is no automated test suite. `npm audit` and `npm audit --omit=dev` report one high-severity production advisory cluster through `@modelcontextprotocol/sdk@1.13.1` with no fix available.

## Ideas To Steal

Use a local relay when the real automation API only exists inside a desktop/plugin sandbox.

Make pairing explicit with a channel join and require join before every non-join command.

Use command IDs end to end, including progress updates, so long-running plugin tasks can keep MCP requests alive.

Filter design-tool node trees before returning them to the agent. Keep IDs, names, type, text, layout, bbox, fills, strokes, and typography; strip binary/image/vector-heavy fields.

Prefer domain tools over arbitrary plugin code execution. The schema surface is large, but it is still easier to audit than free-form code.

Add embedded workflow prompts for multi-step design tasks. Tools alone do not teach the agent that text replacement should scan, chunk, apply, export, and verify.

Batch repetitive design mutations and emit progress. Figma plugin code needs chunking and short delays to avoid UI lockups.

Use design-tool "focus" and "set selection" tools so the human and agent can share visual attention in the same canvas.

## Do Not Copy

Do not treat a random channel name as authentication. Add local tokens, explicit pairing, or client identity checks before allowing live document mutation.

Do not expose destructive tools such as delete, overwrite annotation, text replacement, and component swap without read-only/destructive annotations and a client approval policy.

Do not log full command payloads by default when payloads can contain design text, image exports, or proprietary component names.

Do not hardcode third-party analytics secrets or make telemetry default-on in a design bridge for coding agents.

Do not rely on one huge plugin command file as the system grows. Split command families, shared validation, and response shaping before the surface expands further.

Do not ship docs and UI instructions for package binaries that are not present in `package.json`.

Do not assume the Figma plugin manifest allows arbitrary local ports. Keep UI port controls aligned with manifest `networkAccess`.

## Fit For Agentic Coding Lab

Fit is conditional but valuable. This is not a general agent runtime, but it is a strong reference for one specific gap: connecting coding agents to design-tool state and letting agents make or verify UI changes in the source design surface.

Agentic Coding Lab should borrow the bridge topology and context extraction patterns, then add a stricter permission model. A safer lab version would split read-only and mutating servers or tool groups, annotate destructive tools, require explicit per-session pairing, hide risky tools until activated, and route large exports to files instead of inline text.

For coding-agent UI work, the best use cases are reading selected frames before implementation, extracting text/layout/style details, verifying that generated copy fits a design, annotating designs from audit findings, and turning prototype reactions into a graph. It is less useful as-is for autonomous code verification because it has no browser/app side, no screenshot diff harness, and no automated Figma test fixture.

## Reviewed Paths

- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/README.md`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/AGENTS.md`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/CLAUDE.md`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/DRAGME.md` (sampled setup, WebSocket, and verification guidance)
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/package.json`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/tsconfig.json`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/tsup.config.ts`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/smithery.yaml`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/Dockerfile`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/scripts/setup.sh`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/socket.ts`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/talk_to_figma_mcp/server.ts`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/talk_to_figma_mcp/package.json`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/talk_to_figma_mcp/tsconfig.json`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/cursor_mcp_plugin/manifest.json`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/cursor_mcp_plugin/ui.html`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/cursor_mcp_plugin/code.js`
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/cursor_mcp_plugin/setcharacters.js`

Verification commands run against the temp clone:

- `rtk npm install`: first sandboxed run failed because the user npm cache under `~/.npm` was read-only; escalated run succeeded.
- `rtk npm run build`: passed and generated `dist/server.js`, `dist/server.cjs`, sourcemaps, and declaration files.
- `rtk npm audit` and `rtk npm audit --omit=dev`: reported one high-severity production vulnerability cluster in `@modelcontextprotocol/sdk` with no fix available.
- `rtk bun --version`: failed because Bun is not installed in this environment, so `bun socket` and a live Figma plugin run were not tested.

## Excluded Paths

- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/.git/`: VCS internals; reviewed commit recorded separately.
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/LICENSE`: legal text, not runtime design.
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/bun.lock` and `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/src/talk_to_figma_mcp/bun.lock`: generated dependency locks; dependency intent reviewed through package files and audit.
- `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/node_modules/`, `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/dist/`, and `/tmp/myagents-research/grab-cursor-talk-to-figma-mcp/package-lock.json`: generated locally by verification, not part of the reviewed source commit.
- CSS-only styling inside `src/cursor_mcp_plugin/ui.html`: skimmed only enough to distinguish UI chrome from WebSocket, analytics, and command routing behavior.
- Long AI-agent installation recipes in later `DRAGME.md`: sampled for setup and verification implications; excluded repetitive environment branches and progress-template content from deep runtime review.
- External video links, LinkedIn/YouTube demos, GitHub user attachments, and the Figma Community plugin page linked from README: marketing or hosted distribution context, not source execution path.
