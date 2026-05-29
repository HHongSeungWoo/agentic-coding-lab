# luckyPipewrench/pipelock

- URL: https://github.com/luckyPipewrench/pipelock
- Category: error-prevention
- Stars snapshot: 651 on 2026-05-29 via GitHub web page
- Reviewed commit: c957ff2d4bca398f03a0c7f2cc6caccc26278cba
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong in-scope reference for agent firewall design. The most reusable pieces are the boundary-mediated egress model, immutable DLP/SSRF safety floor, bidirectional MCP scanning, tool policy normalization, fail-closed parsing, redaction, signed receipts, mediation envelopes, and explicit unsupported-path documentation. Do not copy it as a whole platform or treat its pattern scanners as sufficient without mandatory traffic containment.

## Why It Matters

Pipelock targets the exact class of failures that turn coding agents from helpful automation into unsafe operators: credential exfiltration, prompt-injection-driven tool misuse, SSRF, unmediated MCP tool calls, malicious tool descriptions, request-body leakage, and weak auditability. It is framed as an "AI agent firewall" rather than a prompt library, which makes it valuable for Agentic Coding Lab because the enforcement point sits at transport and tool boundaries.

The repo is especially useful because it does not limit itself to HTTP URL filtering. The reviewed code and docs cover forward proxy traffic, fetch proxy behavior, WebSocket frames, CONNECT tunnels, request bodies, headers, response content, MCP stdio, MCP streamable HTTP, MCP reverse proxy mode, tool-list poisoning, tool-call policy, provenance, binary integrity, containment, receipts, and SIEM-style audit logs. That breadth creates operational complexity, but it also shows what an agent firewall has to consider once coding agents gain network and MCP capabilities.

The most important lesson is architectural: safety needs a mandatory mediation boundary. Pipelock can scan, redact, block, warn, and record only traffic that is routed through its proxy, wrapper, sidecar, containment user, or MCP transport. Its own docs explicitly call out raw sockets, non-proxied browsers, unwrapped stdio servers, processes that ignore proxy variables, UDP/direct DNS, and custom CA trust as unsupported unless the integrator adds OS, container, or CNI enforcement. That honesty is a reusable error-prevention pattern by itself.

## What It Is

Pipelock is a Go-based local and deployable proxy/firewall for AI agents and MCP clients. The OSS runtime is centered on `cmd/pipelock` and internal packages for configuration, scanning, proxying, MCP mediation, audit, receipts, redaction, containment, request policy, and session enforcement. It ships multiple policy presets, public specs, examples, Helm packaging, and a verifier CLI.

At the reviewed commit, the system exposes several enforcement surfaces:

- HTTP/fetch and forward proxy paths for outbound requests.
- CONNECT tunnel handling, with optional TLS interception for inner HTTP inspection.
- WebSocket scanning with frame and fragmentation limits.
- MCP stdio proxying around child server processes.
- MCP HTTP upstream client mode and HTTP reverse proxy mode.
- Request body and header DLP, with optional redaction before forwarding.
- Response scanning for prompt injection and data leakage.
- MCP input scanning for JSON-RPC requests, tool call arguments, malformed JSON, duplicate keys, and split secrets.
- MCP response scanning for `tools/list`, tool poisoning, tool drift, provenance, session binding, and confused-deputy request ID checks.
- Containment tooling that can create separate operator/proxy/agent users and force an agent Unix user through a loopback proxy with nftables owner-match rules.

The public docs are unusually extensive for this category. They include a policy spec, security assurance notes, bypass-resistance notes, containment guide, redaction guide, mediation envelope guide, receipt specs, canary token guide, learn-and-lock guide, MCP integrity guidance, metrics/SIEM guidance, and explicit unsupported paths. Those docs sometimes describe optional or mode-dependent features, so the source paths are still the authority for enforcement behavior.

## Research Themes

- Token efficiency: Not a primary project goal. The useful token-efficiency pattern is moving safety decisions out of long prompt instructions and into compact structured verdicts, block reasons, policy hashes, receipts, and audit events. Pipelock also uses bounded body/frame sizes, scanner caps, entropy windows, and prefilter-style normalized scans to keep enforcement predictable instead of asking the model to reason through every payload.
- Context control: Strong. Context is controlled at egress, response, and MCP boundaries through request policies, scanner results, taint, session binding, tool baselines, mediation envelopes, redaction, learn-and-lock contracts, and airlock/adaptive modes. The system treats tool descriptions, JSON-RPC metadata, headers, request bodies, responses, and agent identity as context that can be poisoned.
- Sub-agent / multi-agent: Moderate. Pipelock is not a multi-agent orchestrator, but it supports agent identities, agent-specific configs, actor trust levels in mediation envelopes, A2A scanning, MCP session binding, and conductor/learn-lock concepts. The reusable pattern is identity-bound mediation between agents and tools, not task delegation.
- Domain-specific workflow: Strong for AI agent network and MCP operations. The docs and CLI target Claude/Codex/Cursor/Zed-style agent setup, MCP transport wrapping, proxy deployment, host containment, policy verification, SIEM export, and receipt verification.
- Error prevention: Core theme. It blocks or warns on secret exfiltration, high-entropy payloads, prompt injection, MCP tool poisoning, dangerous tool calls, SSRF, request-body/header leakage, malformed parser edge cases, untrusted provenance, tool drift, and contract violations before data crosses the mediated boundary.
- Self-learning / memory: Present but cautious. Learn-and-lock can observe behavior, compile contracts, shadow decisions, then promote signed active manifests. Behavioral baselines, session profiling, flight recorder capture, and tool drift detection also act as memory. Most of these are default-off, shadow, or warn-oriented because enforcing learned behavior can create availability and false-positive risk.
- Popular skills: This is not a prompt-skill or agent-skill catalog. The relevant reusable "skills" are security workflows: boundary containment, policy validation, MCP tool-risk normalization, receipt generation, redaction, canary token handling, and unsupported-path checklists.

## Core Execution Path

The normal path starts with configuration loading, defaults, validation, and runtime profile resolution. `internal/config/schema.go`, `defaults.go`, `validate.go`, and `runtime.go` define a large policy surface: allowlists, forward/fetch/WebSocket proxies, DLP, canaries, response scanning, MCP input and tool scanning, MCP tool policy, request body scanning, request policy, kill switch, tool-chain detection, TLS interception, cross-request detection, reverse proxy, scan API, SSRF, DNS, sandbox, flight recorder, binary integrity, tool provenance, behavioral baseline, airlock, media policy, A2A scanning, taint, mediation envelopes, redaction, learn-and-lock, conductor, agents, and identity binding.

Once a request reaches Pipelock, URL scanning runs before outbound network use. The scanner canonicalizes hostnames and alternative IP forms, checks scheme and CRLF/path traversal, evaluates allowlists/blocklists, applies core SSRF literal blocking, runs immutable core DLP and configured DLP, checks entropy and subdomain entropy, then performs DNS-based SSRF checks with safe timeouts. A key design choice is scanning hostname content for DLP before DNS resolution so DNS exfiltration is not triggered by the scanner itself. Trusted domains can bypass internal-IP SSRF checks only when explicitly configured; otherwise allowlisted names resolving to internal addresses become config-mismatch blocks.

The forward proxy path adds transport-specific gates. HTTP requests can pass through request-policy checks, request-body scanning, header DLP, redaction, cross-request detection, session/adaptive decisions, airlock behavior, taint, budgets, and contract gates before forwarding. CONNECT requests are scanned before tunneling; if TLS interception is enabled, Pipelock terminates and inspects inner HTTP with a safe dialer, otherwise opaque tunnels keep residual blind spots. WebSocket handling applies message-size and frame controls plus scanning for text payloads.

The MCP stdio path wraps a child server process and mediates both directions. Before spawning, optional MCP binary integrity verification can warn or block. Client messages are routed through input gates even when some scanning is disabled so request IDs, policy, chain, and session state are still tracked. Server messages are scanned on the way back: `tools/list` gets a tool-poisoning scanner, provenance verification, baseline/session binding, and drift handling before general response scanning. The proxy also validates response IDs against tracked requests to reduce confused-deputy behavior.

The MCP HTTP paths add their own transport controls. The HTTP client disables compression, disables redirects, strips caller-supplied `Mcp-Session-Id`, tracks session IDs only from successful responses, rejects 3xx, and caps body size. The reverse proxy accepts bounded POST requests, validates JSON-RPC shape, uses shared baselines, and applies upstream contract gates. The WebSocket MCP client rejects binary frames, invalid UTF-8, and oversized fragments.

When a decision is made, Pipelock can log structured JSON audit events, emit metrics, redacted block details, flight-recorder checkpoints, and signed receipts. Receipt emission includes policy hash, verdict, transport, layer, pattern, redaction summary, taint/contract context, and hash-chain state. Mediation envelopes can add signed boundary metadata to HTTP headers or MCP `_meta`, while inbound stripping prevents callers from forging the envelope.

## Architecture

The repo is a broad Go security product with a few central layers:

- CLI and deployment layer: `cmd/pipelock`, `cmd/pipelock-verifier`, config presets, install/doctor/containment flows, Dockerfiles, and Helm chart packaging.
- Configuration and policy layer: `internal/config`, `internal/reqpolicy`, `configs/*.yaml`, and `docs/policy-spec-v0.1.md`.
- Scanner layer: `internal/scanner`, including URL scanning, core DLP, response prompt-injection scanning, text DLP, canaries, entropy trackers, fragment buffers, normalization, and result classification.
- Transport/proxy layer: `internal/proxy`, including forward/fetch proxy behavior, CONNECT, TLS interception, request body scanning, redaction integration, WebSocket handling, mediation envelopes, request policy, A2A, taint, airlock, and session controls.
- MCP layer: `internal/mcp`, including stdio proxying, HTTP upstream/reverse modes, input scanning, pipeline gates, tool scanning, tool policy, transport readers/writers, provenance, binary integrity, session binding, and redaction for tool-call arguments.
- Evidence layer: `internal/audit`, `internal/receipt`, `internal/recorder`, and related metrics/logging packages.
- Runtime safety adjuncts: sandbox/containment, file sentry, address protection, learn-and-lock, behavioral baselines, media policy, and enterprise-only fleet/control-plane pieces.

The boundary model is explicit. Pipelock is strongest when it is the only path between the agent and the network/tool server. The containment guide turns that into a host pattern by separating `pipelock-operator`, `pipelock-proxy`, and `pipelock-agent` users, then using nftables owner-match rules to force the agent user's egress through the loopback proxy. The Kubernetes chart includes NetworkPolicy templates, but those are deployment boundaries rather than application enforcement logic.

The security model is layered rather than single-detector. URL, body, header, response, MCP input, MCP tool metadata, MCP tool arguments, provenance, session binding, learned contracts, request routes, redaction, taint, and audit are independent modules that meet at proxy decision points. That makes the product complex, but it also avoids depending on one regex pass as the whole safety story.

## Design Choices

Pipelock keeps an immutable safety floor. `internal/scanner/core.go` defines core DLP patterns for major credential classes, core response prompt-injection patterns, and core internal CIDRs. The scanner applies those even when configurable sections are disabled, which prevents an operator from accidentally removing the baseline protections through a weak preset.

Scanning is ordered to avoid making attacks worse. URL DLP runs before DNS lookup, so a DNS-exfil hostname containing encoded secrets can be blocked without resolving the attacker-controlled name. Core SSRF literal checks run before DNS-based SSRF. Request-body redaction can happen before forwarding, and redaction receipts store classes and counts instead of plaintext.

The parser stance is fail-closed. Response scanning fails closed on context cancellation. MCP input scanning detects duplicate JSON keys before unmarshal, blocks malformed JSON by default, and still scans raw malformed payloads if a compatibility mode permits forwarding parse errors. MCP redaction blocks malformed JSON, duplicate method/params/arguments keys, invalid params, and unparseable argument structures. Body scanning blocks unsupported content encodings and over-limit payloads instead of silently skipping them in enforcement paths.

The MCP layer treats tool metadata as hostile input. `tools/list` scanning extracts descriptions, nested JSON schema descriptions/titles/defaults/const/patterns/comments/extensions, enum/example values, and parameter names. It applies response scanning plus tool-specific patterns for instruction tags, exfiltration, cross-tool manipulation, dangerous capabilities, and data routing. Parameter names such as context-leak or file-exfil fields are scanned because malicious tools can hide instructions in schema names rather than descriptions.

Tool policy normalization is intentionally aggressive. The MCP policy layer normalizes tool names for confusables and arguments for Unicode, octal/hex escapes, command substitution, shell quotes, backslash escapes, positional parameters, variable assignment, `${IFS}`, HOME/PWD forms, brace expansion, joined tokens, individual tokens, and pairwise token combinations. Default rules cover destructive file operations, credential file access, network exfiltration, reverse shells, disk wipe, package installs, destructive Git, encoded command execution, persistence, shell profile changes, detached processes, and audit log tampering.

Audit logs and receipts try to avoid becoming exfiltration channels. `internal/audit/logger.go` redacts URLs/targets/resources for content scanners such as DLP, body, header, MCP, response, address, seed, and cross-request detection. It strips control characters and ANSI escape sequences to prevent terminal log injection. The receipt emitter signs canonical action records with Ed25519 and hash-chains events through the flight recorder, but records classes, rule IDs, policy hashes, and redaction summaries rather than raw secret bytes.

The project documents unsupported paths in the same voice as its protections. `docs/security/current-unsupported-paths.md` and `docs/bypass-resistance.md` name raw socket egress, processes ignoring proxy variables, unwrapped MCP stdio servers, UDP/direct DNS, custom CA trust, non-HTTP exfiltration, model compromise, pixel steganography, CONNECT body blindness without TLS interception, DNS rebinding TOCTOU, very slow exfiltration, custom regex ReDoS, HITL flooding, and identity spoofing unless bound. This is a strong pattern for any agent security project because it gives operators a deployment checklist instead of vague confidence.

## Strengths

The biggest strength is boundary-first thinking. Pipelock does not ask the model to remember safety rules; it puts code on the request and MCP transport paths. When deployed with containment or proxy enforcement, it can prevent a payload from leaving before a model or tool has a chance to rationalize it.

The MCP support is much deeper than generic HTTP filtering. It scans both client-to-server and server-to-client JSON-RPC, detects duplicate-key parser differentials, scans split secrets across fields, applies prompt-injection scanning to MCP inputs, validates response IDs, scans tool metadata, detects tool drift, supports session binding, applies tool-call policy, handles tool provenance, and can redact `tools/call` arguments. That makes it one of the more relevant repos for agentic coding systems that rely on MCP servers.

DLP and SSRF design show useful defensive sequencing. DLP before DNS, core private-range literals, alternative IP canonicalization, trusted-domain validation, DNS lookup timeouts, explicit IP allowlists, and config-mismatch classifications are all reusable. The scanner's distinction between threat, protective, infrastructure, and config-mismatch result classes is also useful because adaptive enforcement should not treat DNS timeouts the same way as confirmed exfiltration attempts.

The redaction model is practical. It rewrites matched secrets before the request leaves, covers HTTP bodies, WebSocket messages, and MCP tool-call arguments, blocks ambiguous parser states, and emits class/count summaries. The duplicate-key detector for JSON redaction is a particularly good parser-differential guard.

The evidence model is stronger than a typical guardrail library. Structured audit logs, external emitters, sanitized fields, block-detail classification, signed action receipts, hash-chain state, policy hashes, and mediation envelopes can support incident review and downstream trust decisions. The in-toto receipt spec is directly reusable for agent action attestations.

Tests and security assurance are broad. The repo includes many unit and integration tests around scanner, DLP, MCP input, MCP tool scanning, policy validation, request policy, redaction, envelope spoofing, WebSocket behavior, CONNECT/TLS paths, taint, airlock, and audit logging. CI runs Go tests with race detection, enterprise-tag coverage, vulnerability and static analysis jobs, and ClusterFuzzLite fuzzers for scanners, audit sanitization, git protection, and MCP response scanning.

The docs are unusually candid about residual risk. The public bypass-resistance and unsupported-path docs make clear that Pipelock is not a magic sandbox. That makes it easier to reuse the ideas correctly: deploy the boundary first, then enable scanners, receipts, and policy.

## Weaknesses

The product is only as strong as the traffic boundary. Raw sockets, direct DNS, non-proxied browsers, agents that ignore `HTTPS_PROXY`, unwrapped MCP stdio servers, and processes that mint their own CA trust can bypass large parts of the design unless the host/container/network environment enforces containment. The repo recognizes this, but any adopter has to solve it operationally.

The feature surface is large. Configuration includes many interacting sections: DLP, response scanning, request bodies, MCP input, MCP tools, tool policy, provenance, binary integrity, session binding, taint, airlock, adaptive enforcement, learn-and-lock, mediation, redaction, sandbox, request policy, and more. A lab adaptation should extract smaller patterns rather than copy the full product shape.

Some strong controls are optional, mode-dependent, warn-mode, enterprise-only, or deployment-dependent. For example, TLS interception is needed for deep CONNECT inspection, learn-and-lock starts shadow/off, some integrity/provenance defaults warn rather than block, and enterprise fleet/control-plane paths were not evaluated as OSS runtime enforcement. A config that looks secure can still be advisory if traffic routing and actions are not strict.

Pattern and normalization defenses require continuous maintenance. The response scanner, DLP patterns, MCP tool-poisoning patterns, and tool-policy rules are broad, but they remain detector logic with false-positive and false-negative tradeoffs. The docs mention private adversarial corpora and evasion coverage, but those private tests cannot be independently reviewed from the public repo.

CONNECT and encrypted traffic retain residual blind spots when TLS interception is disabled or impossible. The code scans CONNECT destinations and headers and uses safe dialers, but opaque tunnel contents remain unavailable. The bypass docs also call out DNS rebinding TOCTOU and very slow exfiltration as residual challenges.

Identity and trust are hard to make real. Mediation envelopes distinguish bound, matched, config-default, and self-declared actors, and the docs warn about spoofing unless identity is bound by listener or sidecar. That means agent identity fields are not enough unless the deployment binds them to a process, user, socket, or mTLS/SPIFFE-style identity.

## Ideas To Steal

Build an immutable safety floor underneath configurable policy. Operators should be able to add and tune rules, but not accidentally turn off private-network SSRF literals, common credential classes, and the highest-risk prompt-injection indicators.

Run exfiltration scans before any resolver, redirect, or network side effect. Pipelock's DLP-before-DNS order is a clean, reusable rule for agent egress control.

Treat MCP `tools/list` as untrusted code-adjacent input. Scan descriptions, schemas, parameter names, enum values, examples, comments, defaults, and extension fields. Track tool baselines, detect drift, and bind responses to known request IDs.

Use parser-differential guards. Duplicate JSON keys, malformed JSON, unsupported encodings, oversized frames, mixed encodings, split secrets, and ambiguous redaction states should block or require explicit compatibility modes.

Normalize tool-call arguments like shell attackers write them. Unicode/confusable handling, escape decoding, shell quote stripping, `${IFS}` normalization, brace expansion, command substitution, variable assignment, and pairwise token joins are good patterns for command-like tool policies.

Separate redaction from audit. Redact data before forwarding where possible, and record classes, counts, hashes, rule IDs, and policy versions rather than raw matched secrets.

Emit signed, hash-linked action receipts. A small receipt containing action, verdict, policy hash, finding class, transport, layer, and previous hash is more useful for incident response than a free-form log line.

Document unsupported paths as first-class security artifacts. A guardrail should ship with a bypass checklist that operators can map to OS users, containers, network policies, DNS settings, proxy variables, MCP launchers, and TLS trust.

Classify non-threat blocks separately from confirmed attacks. Infrastructure timeout, protective guard, config mismatch, and structural exemption should not feed the same adaptive escalation loop as credential exfiltration.

Make learned behavior opt-in and staged. Observe, compile, shadow, ratify, and promote with signed manifests is a better pattern than immediately enforcing a model-derived baseline.

## Do Not Copy

Do not copy the whole proxy/product shape into Agentic Coding Lab. The useful pieces are smaller primitives: mandatory egress boundary, MCP input/output gates, tool-policy normalization, redaction, receipts, unsupported-path docs, and a test matrix.

Do not rely on warning-mode or audit-mode policy as a safety guarantee. Several Pipelock presets and features can observe without blocking; that is useful for rollout but not sufficient for autonomous agents.

Do not assume self-declared agent identity is trustworthy. Bind identity to a listener, user, process wrapper, sidecar, mTLS/SPIFFE identity, or other enforcement boundary before using it for policy.

Do not treat regex/pattern scanning as a complete prompt-injection solution. It is a useful layer at the boundary, but high-impact tools still need least privilege, typed policies, restricted tool surfaces, and human approval for dangerous actions.

Do not let "trusted domain" become a broad bypass. Pipelock's validation rejects weak domain forms, and that discipline should be preserved. Broad trust lists would undo SSRF and egress guarantees.

Do not hide unsupported paths from operators. If raw sockets, direct DNS, custom CA stores, or unwrapped MCP servers remain possible, the lab should say so in the same artifact that describes the protection.

Do not emit matched secrets into client errors, logs, receipts, or metrics. The audit path must be treated as a possible exfiltration channel.

## Fit For Agentic Coding Lab

Pipelock is a very strong reference candidate for the `error-prevention` category. It is most useful as a source of design patterns for an agent firewall and MCP security boundary, not as a direct dependency to drop into the lab. The repo shows how many layers are needed once coding agents can call arbitrary tools, browse the network, fetch URLs, stream WebSockets, and talk to MCP servers.

The most immediately reusable lab artifact would be an "agent boundary checklist" derived from this review:

- Every agent egress path must route through a proxy, wrapper, sidecar, container policy, or OS user boundary.
- URL DLP must run before DNS resolution.
- SSRF protection must canonicalize alternative IP forms and include private, loopback, link-local, multicast, and reserved ranges.
- Request body/header scanning must fail closed on unsupported encodings and size overflows.
- MCP clients must scan both requests and responses, including malformed JSON, duplicate keys, split secrets, tool metadata, tool-call arguments, and response IDs.
- Tool-list drift and provenance should be recorded before trusting a tool surface.
- Redaction should happen before forwarding, and audit should never contain raw secrets.
- Signed receipts should bind verdicts to policy hashes and transport/layer context.
- Unsupported paths must be documented and tested as deployment requirements.

For Agentic Coding Lab, this review suggests a smaller implementable pattern: a mandatory local "agent firewall" interface for shell, network, and MCP calls. It should expose a typed verdict, redacted reason, receipt, and audit record for every action. It should also have a test harness that replays exfiltration, SSRF, prompt-injection, tool-poisoning, split-secret, duplicate-key, and malformed-encoding fixtures.

## Reviewed Paths

- `README.md`: product framing, feature matrix, MCP tool-response injection demo, transport modes, signed receipts, DLP/SSRF/response/MCP claims, install notes, project layout, and CI/testing claims.
- `go.mod`, `go.sum`: module shape and dependency surface; lockfile was not reviewed line by line.
- `cmd/pipelock/**` and `cmd/pipelock-verifier/**`: CLI entry points, verifier surface, and runtime command organization were sampled for architecture, not every command flag.
- `internal/config/schema.go`, `defaults.go`, `validate.go`, `runtime.go`, and related config tests: policy schema, defaults, validation warnings/errors, core sections, trusted domain validation, learn-lock validation, runtime auto-enabling, and preset behavior.
- `configs/balanced.yaml`, `configs/strict.yaml`, `configs/audit.yaml`: representative policy presets and enforcement posture differences.
- `docs/policy-spec-v0.1.md`: portable policy model for egress, DLP, response scanning, MCP hooks, tool policy, session binding, chain detection, and audit events.
- `docs/security-assurance.md`: threat model, trust boundaries, scanner layers, fail-closed cases, limitations, verification layers, and supply-chain controls.
- `docs/security/current-unsupported-paths.md`: deployment bypass paths and required integrator controls.
- `docs/bypass-resistance.md`: tested evasion matrix and residual limitations.
- `docs/contain-cli.md`: host containment model, user separation, nftables owner-match egress forcing, systemd/unit setup, TOFU binary integrity, and verification probes.
- `docs/guides/mediation-envelope.md`: HTTP/MCP mediation metadata, inbound stripping, signed mode, replay protection, key binding, actor trust levels, and fail-closed key handling.
- `docs/guides/redaction.md`: request redaction scope, fail-closed body parsing, JSON handling, WebSocket fragments, MCP tool-call argument redaction, and receipt summaries.
- `docs/guides/canary-tokens.md`: canary matching after normalization, URL decode, subdomain dot stripping, separator collapse, encoding decode, and stated limits.
- `docs/guides/learn-and-lock.md`: observe/compile/shadow/ratify lifecycle, signed manifests, contract enforcement surfaces, scanner precedence, and default-off posture.
- `docs/specs/in-toto-agent-action-receipt-v0.1.md`: receipt predicate shape and action evidence model.
- `internal/scanner/scanner.go`, `core.go`, `response.go`, `text_dlp.go`, `canary.go`, `fragment_buffer.go`, `entropy_tracker.go`, and scanner tests/fuzzers: URL scan order, immutable core rules, SSRF handling, DLP normalization, prompt-injection scanning, canaries, split-fragment handling, entropy budgets, result classes, and context fail-closed behavior.
- `internal/proxy/forward.go`, `bodyscan.go`, `intercept.go`, `requestpolicy.go`, `proxy.go`, and proxy tests: forward proxy, CONNECT, safe dial, TLS interception, request body/header scanning, redaction integration, request policy, envelope handling, taint, adaptive/session behavior, WebSocket/CEE paths, and airlock interactions.
- `internal/reqpolicy/policy.go` and tests: route/operation predicates, method override handling, host/path/content-type normalization, body inspection, shadow rules, and fail-closed uninspectable body handling.
- `internal/audit/logger.go` and audit tests/fuzzers: structured logging, blocked-event redaction, scanner classification, external emitter behavior, control-character and ANSI sanitization.
- `internal/receipt/receipt.go`, `emitter.go`, and related tests: Ed25519 signing, canonical records, verification, hash-chain state, flight recorder emission, policy hash, transport/layer fields, and chain-sealing behavior.
- `internal/redact/redact.go`, `dupkey.go`, and redaction tests: redaction token design, per-request deduplication, duplicate JSON key detection, and parser-differential prevention.
- `internal/mcp/proxy.go`, `input_scan.go`, `pipeline_gates.go`, `redaction.go`, and MCP tests: stdio proxying, child process handling, kill switch, request tracking, input scanning, malformed JSON handling, duplicate keys, tool call argument redaction, pipeline gate order, response scanning, receipts, and blocked JSON-RPC error behavior.
- `internal/mcp/policy/policy.go` and tests: tool-call policy compilation, name/argument normalization, default dangerous-command rules, argument pair scanning, and arg-key-scoped rules.
- `internal/mcp/tools/tools.go` and tests: tool-list parsing, schema text extraction, tool poisoning detection, param-name scanning, baseline/session binding, drift detection, caps, and false-positive coverage.
- `internal/mcp/transport/transport.go`, `httpclient.go`, `wsclient.go`, and `mcp_http_reverse.go`: stdio line limits, oversized-message rejection, HTTP compression/redirect/session handling, WebSocket text-only limits, reverse proxy request caps, JSON-RPC validation, and shared tool baselines.
- `internal/mcp/provenance/**` and `internal/mcp/integrity/**`: tool provenance and binary integrity paths were sampled for enforcement placement and warn/block behavior.
- `.github/workflows/ci.yaml` and `.clusterfuzzlite/build.sh`: CI, race testing, enterprise-tag coverage, fuzz targets, static analysis, and vulnerability scanning posture.
- `charts/pipelock/templates/networkpolicy.yaml` and chart values: deployment boundary hints and Kubernetes NetworkPolicy packaging, reviewed only as containment context.

## Excluded Paths

- `docs/assets/**`, `assets/**`, screenshots, GIFs, casts, and other media/demo assets: generated or presentation-only material, not enforcement logic.
- `configs/grafana-dashboard.json`: visualization/dashboard content, not policy execution.
- `charts/pipelock/**` beyond sampled `templates/networkpolicy.yaml` and values: Helm packaging and Kubernetes deployment glue, not core scanner/proxy/MCP logic.
- `sdk/verifiers/ts/**`, `sdk/verifiers/rust/**`, `sdk/conformance/**`, and `sdk/audit-packet/**`: verifier SDK and conformance packaging; useful for ecosystem adoption but not the runtime firewall boundary reviewed here.
- `enterprise/**`, `cmd/license-service/**`, and `Dockerfile.license-service`: enterprise control-plane, licensing, and fleet-oriented code. I noted that these surfaces exist but did not treat them as OSS runtime evidence.
- `examples/**`, `bench/**`, and `test/secureiqlab/**`: demos, benchmark fixtures, and external-style labs. I sampled them only when they clarified README claims; source and tests under `internal/**` were treated as the behavior authority.
- HTML report templates and UI/reporting surfaces such as `internal/report/template.html`: output presentation, not scanner or enforcement logic.
- Dependency metadata and generated lock material such as `go.sum`, `package-lock.json`, and `Cargo.lock`: reviewed for project shape only, not line-by-line design.
- Exhaustive docs pages for install, SIEM, metrics, and every deployment variant: sampled where they affected policy, audit, or boundaries; the deep review focused on runtime egress, DLP, SSRF, MCP, receipts, tests, and unsupported paths.
