# Tencent/AI-Infra-Guard

- URL: https://github.com/Tencent/AI-Infra-Guard
- Category: harness-eval
- Stars snapshot: 3,800 (GitHub REST API, captured 2026-05-29)
- Reviewed commit: 5361c8c1ec8319fb7c5aa3406b63982fe2190db9
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong full-stack AI red-team platform for AI infrastructure, agents, MCP servers, agent skills, and jailbreak evaluation. The most reusable patterns are the Go task API plus WebSocket agent runner, structured scan events, provider-configured agent targets, staged MCP and skill audit prompts, exact prompt/response evidence artifacts, and a chat-skill wrapper for launching scans. Do not copy the open-source default deployment posture, unsandboxed shell tool, unsigned remote plugin execution path, or model-judge-heavy conclusions without deterministic CI fixtures.

## Why It Matters

AI-Infra-Guard is directly relevant to an agentic coding lab because it treats AI security scanning as an executable harness rather than a static checklist. It scans the surfaces that matter for tool-using agents: deployed AI infra, agent endpoints, MCP tools, agent skill packages, prompt injection, tool poisoning, tool abuse, secret leakage, and jailbreak behavior.

The repo is useful as a reference for how to turn red-team research into a runnable service. It has a public task API, a Go task manager, WebSocket worker agents, Python scanner engines, structured progress events, report artifacts, and ClawHub-style skills that let an AI assistant launch and poll scans. That makes it especially valuable for designing safety harnesses around coding agents, MCP servers, and local skill ecosystems.

## What It Is

AI-Infra-Guard is a Go and Python platform named A.I.G. The Go side provides the web service, task API, database/session handling, WebSocket task dispatch, AI infra fingerprint and vulnerability scanning, and release packaging. The Python side provides LLM-driven scanners for MCP and skills, agent endpoint testing, and jailbreak or model safety evaluation.

The main scan families are:

- AI infra scan: network/service probing, AI component fingerprinting, vulnerability matching, optional screenshot and AI analysis.
- MCP and skills scan: static code audit for MCP servers and agent skill packages, remote MCP URL probing, tool-call red teaming, and vulnerability review.
- Agent scan: provider-configured testing of Dify, Coze, OpenAI-compatible, custom HTTP, and WebSocket agents with endpoint reconnaissance plus dialogue-based attack prompts.
- Prompt security / jailbreak evaluation: DeepTeam-derived attack generation and evaluator loops over datasets, scenarios, techniques, and target/evaluator model pairs.

## Research Themes

- Token efficiency: Moderate. The scanners use stage boundaries, stop-after-confirmation rules, max iteration caps, context compaction in `mcp-scan` and `agent-scan`, and asynchronous/concurrent evaluation, but the core approach is still LLM-heavy.
- Context control: Strong. Task payloads, provider YAML, scanner prompts, local skills, model configs, report schemas, and structured JSON events keep most run context explicit and auditable.
- Sub-agent / multi-agent: Strong for red-team orchestration. The platform has Go worker agents, LLM stage agents, attacker/target/evaluator loops, simulator/evaluator model roles, and a TAP tree strategy for attack search.
- Domain-specific workflow: Very strong. The repo has dedicated workflows for AI infra fingerprints, MCP tools, agent skills, prompt injection, OWASP Agentic Security Initiative categories, jailbreak scenarios, and AI component CVEs.
- Error prevention: Strong as a manual or scheduled scan harness. It captures exact test prompts, target responses, tool calls, scores, and vulnerability reports. CI coverage for scanner behavior is much weaker than the runtime design.
- Self-learning / memory: Limited. Runs produce logs, reports, and persisted task sessions, but there is no durable learning loop that improves future scanners from past failures.
- Popular skills: `skills/aig-scanner` is a practical assistant-facing wrapper for scan submission and polling. `skills/edgeone-skill-scanner` is a local static skill audit workflow focused on malicious skill behavior, hidden instructions, command injection, and secret access.

## Core Execution Path

The service-facing path starts at the task API. `common/websocket/api.go` maps `mcp_scan`, `ai_infra_scan`, `agent_scan`, and `model_redteam_report` requests into internal task types, validates required model/provider fields, stores parameters, and hands the task to the task manager.

`common/websocket/task_manager.go` creates a session, selects an available WebSocket agent, dispatches a `task_assign` message, forwards live events to the browser/API clients, stores messages in the database, and marks the session complete when a `resultUpdate` event arrives. The agent side in `common/agent/agent.go` registers task capabilities, receives assignments, runs the task in a goroutine, and emits callbacks.

Each task has a separate execution path:

- MCP scan: `common/agent/mcp_task.go` decides whether the input is uploaded code, a GitHub repo, or a remote MCP URL. Code inputs are downloaded or cloned under a temp directory, then `uv run --no-project main.py` starts `mcp-scan`. Static code scans run Info Collection, Code Audit, and Vulnerability Review. Remote URL scans add Malicious Testing and Vulnerability Testing stages.
- Agent scan: `common/agent/agent_task.go` writes the submitted provider YAML to a temp file, then runs `agent-scan/main.py` with evaluator model credentials. The Python scanner validates provider connectivity, gathers endpoint information, probes with dialogue prompts, reviews findings, and writes an `agent-security-report@1` artifact.
- Prompt evaluation: `common/agent/prompt_tasks.go` runs `AIG-PromptSecurity/cli_run.py` with target model, evaluator model, scenarios, datasets, and attack techniques. The DeepTeam-derived runner generates attacks, calls the target model, grades outputs, and emits CSV/JSON-style result attachments.
- AI infra scan: `common/agent/tasks.go` prepares target hosts or files, optionally probes common AI service ports with nmap, then runs the Go fingerprint/vulnerability engine in `common/runner`. The runner loads fingerprints and vulnerability templates, expands targets, sends HTTP requests, extracts versions, matches CVE/GHSA rules, and returns scored results.

The event boundary is a useful harness pattern. Python scanners emit JSON log lines such as `newPlanStep`, `statusUpdate`, `toolUsed`, `actionLog`, `error`, and `resultUpdate`. `common/agent/parse_cmdline.go` parses those stdout lines and converts them into task-manager callbacks. This lets a heterogeneous scanner fleet behave like one service-level protocol.

## Architecture

The architecture has six practical layers:

- Go web platform: `cmd`, `common/websocket`, database models, API routes, static UI hosting, task sessions, and release packaging.
- Go worker agent: `common/agent` owns WebSocket registration, task dispatch, task-specific wrappers, stdout event parsing, and Python subprocess execution.
- Go AI infra scanner: `common/runner`, `common/fingerprints`, `pkg/vulstruct`, and `data` implement fingerprints, version extraction, vulnerability matching, scoring, screenshots, and optional AI analysis.
- Python MCP/skills scanner: `mcp-scan` implements staged LLM agents, local repository tools, MCP client tools, dynamic MCP tool-call testing, XML vulnerability extraction, and a separate multi-turn red-team engine.
- Python agent scanner: `agent-scan` implements provider adapters, endpoint reconnaissance, dialogue tools, prompt skills, OWASP ASI review, report models, and structured result emission.
- Python prompt security engine: `AIG-PromptSecurity` implements red-team datasets, attack operators, simulator/evaluator roles, metrics, plugin loading, and run reports.

The repo also ships user-facing automation through `skills/aig-scanner`, `skills/edgeone-skill-scanner`, and `skills/edgeone-clawscan`. These are important because they show how a scan harness can be exposed as an agent skill with explicit parameter collection, local file handling, task polling, and credential hygiene instructions.

## Design Choices

The most important design choice is separating orchestration from scanner engines. Go handles service concerns and high-concurrency network scanning. Python handles LLM loops and red-team evaluation. That boundary keeps the task API stable while allowing scanners to evolve independently.

The scanner stages are explicit. MCP code scans run summary, code audit, and vulnerability review. MCP URL scans add malicious testing and vulnerability testing. Agent scans run info collection, vulnerability detection, and security review. Prompt evaluation separates attack generation, target calls, evaluator metrics, and assessment summaries. These stage names become UI progress events and report sections.

The agent scanner is evidence-first. Detection prompts require exact test prompts and exact agent responses, avoid reporting mere tool invocation as a confirmed exploit, stop after one confirmed finding per vulnerability type, and skip categories when the target lacks the relevant capability. The reviewer prompt deduplicates, filters placeholders, and requires conversation evidence.

The MCP/skills scanner uses domain-specific risk prompts instead of generic code review. The code audit prompt names MCP risks such as auth bypass, command injection, credential theft, indirect prompt injection, name confusion, rug pull, tool poisoning, and tool shadowing. Skill mode compares `SKILL.md` against scripts/configs and flags hidden behavior, exfiltration, backdoors, arbitrary file access, and destructive actions.

The red-team engines use model roles. `mcp-scan/redteam` has Attacker, Target, and Evaluator roles with Crescendo and TAP strategies. `AIG-PromptSecurity` has attack simulators, target callbacks, evaluator models, and metrics. This is flexible, but it also makes reproducibility depend on judge prompts, judge models, parser behavior, and external model drift.

## Strengths

The task protocol is a strong integration pattern. Different scanners emit the same structured event types and result events, so UI, API clients, and assistant skills can consume scan progress uniformly.

Agent Scan is highly reusable for coding-agent safety. Provider YAML adapts Dify, Coze, HTTP, WebSocket, and OpenAI-compatible targets into one dialogue interface. Endpoint scanning detects leaked API keys, DB URIs, JWTs, bearer tokens, private keys, internal network addresses, system-prompt fragments, and other sensitive patterns before dialogue attacks even begin.

The MCP/skills scanner is directly relevant to tool ecosystems. It understands local code, remote MCP tools, tool schemas, prompts, resources, and agent skill packages. Its static skill audit pattern is valuable for checking whether advertised skill behavior matches hidden script behavior.

The evidence model is practical. Reports carry risk titles, levels, OWASP categories, descriptions, suggestions, conversations, test prompts, target responses, tool usage, and scores. This is more actionable than a single pass/fail safety score.

The ClawHub skill wrapper is a good adoption model. `skills/aig-scanner/scripts/aig_client.py` normalizes GitHub URLs, uploads local files, submits tasks, polls status, and keeps API keys in environment variables. It demonstrates how a scan system can become a usable assistant command without giving the assistant direct scanner internals.

The data-driven AI infra scanner gives the platform breadth. Fingerprint YAML, vulnerability YAML, version parsing, and CI YAML validation make AI component scanning maintainable without hardcoding every rule in Go.

## Weaknesses

The README warns that the open-source version has no authentication mechanism and should not be deployed directly on a public network. That is a major operational caveat for a web task system that accepts scan targets, uploads, model credentials, and task artifacts.

`mcp-scan/tools/execute/execute_actions.py` registers an `execute_shell` tool that calls `subprocess.run(..., shell=True)` with no visible repo boundary or sandbox enforcement in the dispatcher. The tool registry carries a `sandbox_execution` flag, but the reviewed dispatcher path does not enforce isolation. This should not be copied into a local coding-agent harness without a real sandbox, cwd policy, network policy, and command allowlist.

The prompt-security plugin system is powerful but risky. Remote plugins can be downloaded from HTTP(S) URLs, zip files are checked for path traversal, and validators use Python import machinery that executes plugin modules during validation/loading. There is no reviewed signing, checksum pinning, HTTPS-only policy, or sandbox boundary for plugin code.

Several conclusions are model-judged. Agent Scan, MCP dynamic tests, TAP/Crescendo red teaming, and PromptSecurity evaluator metrics can all drift with attacker, target, and evaluator model changes. The reports are useful, but critical CI gates would need deterministic fixtures, canaries, parser tests, and calibrated judge regression suites.

The CI workflows reviewed focus on YAML data validation and Docker/release packaging. There is no reviewed GitHub workflow that runs Go tests, Python tests, scanner golden cases, task API integration tests, or end-to-end agent/MCP scan fixtures.

The agent scanner contains a parallel per-skill detection scaffold for data leakage, tool abuse, indirect injection, and authorization bypass, but the current `Agent.scan()` path uses a sequential vulnerability detector stage instead. That is not a blocker, but it shows some architecture drift.

The MCP red-team target runner can simulate an MCP server from source context rather than starting the actual MCP process. That is useful for cheap exploration, but exploit evidence from that mode is not equivalent to a real tool-call execution trace.

## Ideas To Steal

Build a single task protocol for heterogeneous scanners. Keep event names small and stable: plan step, status, tool used, action log, error, and result.

Use provider YAML for agent targets. A coding-agent harness should adapt HTTP, WebSocket, MCP, CLI, and hosted-agent targets through config instead of bespoke code for every target.

Capture exact evidence in reports. For each finding, store the attack prompt, target response, tool call or endpoint, category, severity, reviewer reasoning, and suggested mitigation.

Separate reconnaissance from exploitation. The agent scanner's Scan tool and one-light-probe policy help avoid expensive or irrelevant attacks when a target lacks the capability.

Add a skill audit mode that compares declarative instructions to executable files. For local agent skills, the key question is not only whether the code is dangerous, but whether the `SKILL.md` hides or misrepresents that behavior.

Treat MCP as both code and protocol. Static code audit catches hidden behavior; dynamic tool-call testing catches schema, resource, prompt, and runtime behaviors. A good harness should support both.

Expose scan harnesses as assistant skills with strict parameter collection. The `aig-scanner` skill shows a useful pattern for scanning local paths, GitHub URLs, saved agents, target model configs, and polling results without leaking tokens.

Make scanner prompts domain-specific. Generic "review for security" prompts are weaker than prompts that name tool poisoning, rug pull, indirect prompt injection, skill backdoors, command injection, auth bypass, and data exfiltration.

## Do Not Copy

Do not deploy a task API that accepts scans, uploads, and credentials without authentication, authorization, rate limits, and artifact access controls.

Do not give an LLM scanner an unsandboxed shell tool. If shell execution is needed, isolate it in a disposable workspace with command allowlists, egress controls, resource limits, and audit logs.

Do not execute downloaded plugins during validation unless the plugin source is trusted and pinned. Prefer declarative plugin metadata, static validation, signatures, checksums, and process isolation.

Do not treat model-judge success as release-blocking truth by itself. Pair judges with deterministic assertions, replayable fixtures, golden traces, and explicit parse-failure policy.

Do not scan real private repos, production agents, or internal MCP servers with broad credentials unless the task runner and artifact store are isolated from normal development state.

Do not let dynamic MCP simulation replace real execution evidence when the finding depends on tool behavior, filesystem access, network egress, or command execution.

## Fit For Agentic Coding Lab

Fit is strong for `harness-eval`. AI-Infra-Guard is not a coding-agent benchmark suite, but it is a practical reference for building an AI red-team harness around agents, MCP servers, and skills.

Agentic Coding Lab should adapt the task protocol, structured event stream, provider adapters, evidence-first report schema, domain-specific MCP/skill prompts, skill wrapper UX, and combined static/dynamic scanning model. It should add sandboxed workspaces, deterministic fixtures, CI golden tests, trace capture from real tool execution, signed plugin policies, and a narrower release-gate profile for coding-agent workflows.

The best near-term artifact would be a local "agent surface scanner" that accepts a repo or MCP server, runs static skill/MCP checks, launches a sandboxed target adapter, replays a small prompt-injection/tool-abuse suite, and emits one JSONL report with exact evidence and reproducibility metadata.

## Reviewed Paths

- `/tmp/myagents-research/tencent-ai-infra-guard/README.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/CHANGELOG.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/API_en.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/go.mod`
- `/tmp/myagents-research/tencent-ai-infra-guard/.github/workflows/yaml-lint.yml`
- `/tmp/myagents-research/tencent-ai-infra-guard/.github/workflows/docker-publish.yml`
- `/tmp/myagents-research/tencent-ai-infra-guard/.github/workflows/create-release.yml`
- `/tmp/myagents-research/tencent-ai-infra-guard/docs/architecture_evolution.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/cmd/agent/main.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/cmd/yamlcheck/main.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/api.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/task_manager.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/aigdocs/docs/agent-scan_openSource_en.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/aigdocs/docs/mcp-scan_en.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/aigdocs/docs/prompt-eval_openSource_en.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/agent.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/types.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/parse_cmdline.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/mcp_task.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/agent_task.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/prompt_tasks.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/agent/tasks.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/runner/runner.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/common/fingerprints/preload/preload.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/pkg/vulstruct/scanner.go`
- `/tmp/myagents-research/tencent-ai-infra-guard/data/fingerprints/mcp.yaml`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/README.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/main.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/agent/agent.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/agent/base_agent.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/tools/registry.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/tools/file/read_file.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/tools/file/write_file.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/tools/execute/execute_actions.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/tools/mcp_tool/mcp_tool.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/utils/mcp_tools.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/prompt/system_prompt.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/prompt/agents/code_audit.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/prompt/agents/dynamic/malicious_behaviour_testing.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/README.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/orchestrator.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/attacker.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/evaluator.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/strategy.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/target.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/redteam/report.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/README.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/main.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/core/agent.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/core/base_agent.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/core/agent_adapter/adapter.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/core/report/models.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/core/report/report.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/prompt/system/project_summary.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/prompt/system/agent_vulnerability_detector.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/prompt/system/agent_security_reviewer.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/prompt/skills/indirect-injection-detection/SKILL.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/tools/dialogue/dialogue.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/tools/dialogue/scan.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/tools/skill/skill.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/utils/aig_logger.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/utils/extract_vuln.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/README.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/cli_run.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/cli/red_team_runner.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/red_teamer/red_teamer.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/red_teamer/risk_assessment.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/attacks/attack_simulator/attack_simulator.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/attacks/single_turn/prompt_injection/prompt_injection.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/attacks/multi_turn/tree_jailbreaking/tree_jailbreaking.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/metrics/shell_injection/shell_injection.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/deepteam/vulnerabilities/excessive_agency/excessive_agency.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/plugins/manager.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/plugins/loader.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/plugins/validator.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/plugins/registry.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/AIG-PromptSecurity/plugins/remote_downloader.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/skills/aig-scanner/SKILL.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/skills/aig-scanner/scripts/aig_client.py`
- `/tmp/myagents-research/tencent-ai-infra-guard/skills/edgeone-skill-scanner/SKILL.md`
- `/tmp/myagents-research/tencent-ai-infra-guard/skills/edgeone-clawscan/SKILL.md`

## Excluded Paths

- `/tmp/myagents-research/tencent-ai-infra-guard/.git/`: VCS internals; commit captured separately.
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/assets/**`: bundled UI JavaScript, CSS, fonts, and browser assets; not core scanner logic.
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/index.html`: UI shell only.
- `/tmp/myagents-research/tencent-ai-infra-guard/common/websocket/static/aigdocs/docs/assets/**`: documentation site assets and screenshots.
- `/tmp/myagents-research/tencent-ai-infra-guard/img/**`: images and marketing screenshots.
- `/tmp/myagents-research/tencent-ai-infra-guard/*.pdf`: binary papers/slides/manuals; not needed for source architecture review.
- `/tmp/myagents-research/tencent-ai-infra-guard/docs/swagger.json`, `/tmp/myagents-research/tencent-ai-infra-guard/docs/swagger.yaml`, `/tmp/myagents-research/tencent-ai-infra-guard/docs/docs.go`: generated Swagger artifacts; API behavior reviewed through source routes and API docs.
- `/tmp/myagents-research/tencent-ai-infra-guard/data/vuln/**`, `/tmp/myagents-research/tencent-ai-infra-guard/data/vuln_en/**`, `/tmp/myagents-research/tencent-ai-infra-guard/data/fingerprints/**`, `/tmp/myagents-research/tencent-ai-infra-guard/data/eval/**`: large rule and dataset corpus; schema/parsers and representative MCP fingerprint data were reviewed, not every rule.
- `/tmp/myagents-research/tencent-ai-infra-guard/readme/**` and localized `api_*.md` files: translations and localized docs; English/root docs were reviewed.
- `/tmp/myagents-research/tencent-ai-infra-guard/go.sum`, Python lock/requirements files, and package metadata: dependency manifests were skimmed only for ecosystem context.
- `/tmp/myagents-research/tencent-ai-infra-guard/agent-scan/test_*`, `/tmp/myagents-research/tencent-ai-infra-guard/mcp-scan/pytests/**`, and scattered Go test files: test presence was sampled to assess coverage, but tests were not reviewed line-by-line.
