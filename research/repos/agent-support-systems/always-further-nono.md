# always-further/nono

- URL: https://github.com/always-further/nono
- Category: agent-support-systems
- Stars snapshot: 2,518 (GitHub REST API repository search, captured 2026-05-29 in `research/index.md`)
- Reviewed commit: 6ae3502030b9038a9fd5ac96505f3dfdc4e04fdc
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-fit reference for capability-based local agent execution. The strongest reusable material is the policy-to-capability compiler, trusted supervisor for brokered file/network/open-url access, reverse proxy credential injection, signed instruction-file trust policy, audit ledger, and rollback snapshots. Treat the repo as a security design reference, not a turnkey portable boundary: the strongest transparent expansion path depends on Linux Landlock plus seccomp-notify, macOS has different enforcement tradeoffs, WSL2 degrades by kernel support, and resource exhaustion/covert-channel defenses are intentionally out of scope.

## Why It Matters

Nono is directly relevant to Agentic Coding Lab because it starts from the threat model that AI agents should not inherit a developer's whole account. It models the runtime as a capability set over filesystem paths, network destinations, Unix sockets, environment variables, credentials, process operations, browser-opening origins, rollback paths, and signed instruction files.

The repo is especially useful because it does not stop at configuration schemas. It implements the runtime boundary in Rust with Landlock on Linux, Seatbelt on macOS, a trusted supervisor process, a localhost proxy with session tokens, credential brokering, prompt-injection-oriented trust verification, audit integrity, and rollback metadata. That makes it a strong candidate for concrete patterns around policy compilation, brokered access, and forensic evidence in local coding-agent runtimes.

## What It Is

Nono is a Rust workspace for running agents and developer tools under least-privilege policies. The reviewed workspace contains:

- `crates/nono`: core policy-free capability types, sandbox builders, trust/undo primitives, host filters, keystore helpers, and platform enforcement.
- `crates/nono-cli`: user-facing CLI, profile and policy loading, manifest handling, launch planning, supervisor runtime, audit and rollback commands, trust CLI, credential preparation, and integration with sandbox/proxy/trust layers.
- `crates/nono-proxy`: localhost HTTP proxy, CONNECT forwarding, reverse proxy credential injection, endpoint filtering, OAuth2 support, TLS interception support, proxy audit events, and token validation.
- `docs/cli`: feature and internals documentation for capabilities, networking, credential injection, audit, rollback, supervisor behavior, trust policy, profile authoring, and the security model.
- `tests/integration`: shell integration suites for filesystem access, network blocking, trust CLI, audit, rollback, sensitive path protection, bypass protection, WSL2 behavior, URL opening, and policy queries.
- `bindings/c`: C FFI surface around selected core behavior; not the primary agent runtime path.

## Research Themes

- Token efficiency: Not a token or context-compression system. It reduces prompt pressure indirectly by letting durable filesystem state, audit sessions, rollback snapshots, and capability profiles carry operational context instead of repeatedly describing state in prompts.
- Context control: Strong runtime context control. Profiles, manifests, embedded policy groups, CLI flags, trust policies, protected roots, credential routes, network profiles, and redaction policies compile into a concrete launch plan. The child process sees only granted paths, selected env, proxy settings, and explicitly injected credentials or phantom tokens.
- Sub-agent / multi-agent: No planner or multi-agent orchestration. It supports multiple isolated sessions, session attach/detach/inspect/prune, and explicit localhost/Unix-socket permissions that can be used to connect sandboxes, MCP clients, or MCP servers under policy.
- Domain-specific workflow: Very strong for local coding-agent execution: controlled cwd/project access, policy-defined agent profiles, credential-safe API calls, browser/open-url brokering, signed instruction files, audit trails, and rollback of modified workspace paths.
- Error prevention: Capability validation, deny-overlap checks, protected `~/.nono` state, sensitive path groups, default-deny trust enforcement, endpoint rules, metadata/link-local network denial, proxy tokens, fd brokering, terminal prompt sanitization, audit integrity, and integration tests target common AI-agent failure modes.
- Self-learning / memory: No learning layer. Memory is operational: session metadata, audit logs, rollback snapshots, trust bundles, profiles, and policy files.
- Popular skills: Run a command under a profile, grant specific paths, block or proxy network, inject credentials without exposing real secrets to the child, sign and verify instruction files, inspect `why` a path/host is allowed or denied, attach to a supervised session, review/restore rollback changes, and verify audit evidence.

## Core Execution Path

The main runtime path begins in `crates/nono-cli/src/main.rs`, which dispatches `nono run`, `shell`, `wrap`, `audit`, `rollback`, `trust`, `why`, and related commands. `command_runtime.rs` loads a profile or direct capability manifest. Built-in and registry profiles cannot silently override the target binary; only user-authored profiles or explicit file paths can set `binary`, which is a useful guard against remote profile command hijacking.

`launch_runtime.rs` builds the launch plan. It prepares redaction policy, validates audit signing requirements, loads profile or manifest capabilities, detects WSL2 limitations, runs trust scanning unless `--trust-override` is present, prepares write protection for verified instruction files, grants read caps for verified files, configures the network proxy and credentials, initializes rollback/audit state, and currently selects supervised execution by default.

`sandbox_prepare.rs` compiles either a direct capability manifest or a profile plus CLI flags. The compiler expands profile groups, filesystem grants, deny groups, network modes, command restrictions, Unix sockets, process/signals/IPC settings, credential sources, open-url policy, and rollback paths into a `CapabilitySet`. It then validates protected-root and deny-overlap behavior after adding implicit grants such as cwd, profile pack, GPU, or LaunchServices paths.

In supervised mode, `exec_strategy.rs` forks before sandboxing. The child applies Landlock or Seatbelt and then execs the requested command. The parent remains unsandboxed but is treated as trusted: it hardens itself where possible, owns the PTY/session/audit state, serves capability-expansion requests, mediates seccomp notifications, brokers URL opening, drains proxy network audit events, and finalizes audit/rollback metadata.

On Linux, `exec_strategy/supervisor_linux.rs` handles seccomp-notify for `openat` and `openat2`. If static capabilities are sufficient, the supervisor may allow the syscall to continue or inject a supervisor-opened fd. If not, it checks protected roots, trust policy, rate limits, and terminal approval before opening the canonical path with `O_NOFOLLOW` traversal and fd injection. Network notifications mediate AF_UNIX sockets and proxy-only connect/bind cases when kernel support requires supervisor help.

When network proxying or credential brokering is enabled, `proxy_runtime.rs` starts `crates/nono-proxy` on `127.0.0.1` with a fresh 256-bit session token. The child receives proxy environment variables and, for managed services, base URLs plus phantom API tokens. The proxy enforces host/route/endpoint policy, validates tokens, injects real credentials only upstream, records network audit events, and can install a session CA bundle for TLS interception when L7 policy requires it.

## Architecture

The architecture has four security-relevant planes.

The policy plane is profiles, direct capability manifests, embedded policy groups, user/project trust policies, network profiles, credential routes, and redaction policy. The core `nono` crate keeps capability types mostly policy-free; the CLI owns profile inheritance, group resolution, deny defaults, and CLI overrides.

The kernel-enforcement plane is Landlock on Linux and Seatbelt on macOS. Linux enforcement detects Landlock ABI support, applies filesystem and network/scoped rules with hard requirements where available, and uses seccomp fallback or seccomp-notify for gaps. macOS generates a Seatbelt profile with default deny, explicit file/process/network rules, and targeted platform allowances.

The broker plane is the trusted supervisor plus the trusted proxy. The supervisor can approve and inject file descriptors, mediate AF_UNIX sockets, sanitize terminal prompts, serve controlled URL opening, record audit events, and maintain session lifecycle. The proxy can narrow network access to allowed domains/routes, protect against metadata/link-local SSRF, inject credentials, validate phantom tokens, enforce endpoint globs, and audit network decisions.

The evidence plane is audit, rollback, trust, and session state under `~/.nono`. Audit logs are append-only NDJSON with chained and Merkle hashes when integrity is enabled. A global audit ledger chains completed session digests. Rollback snapshots store content hashes and manifests for tracked writable paths. Trust bundles and policies sign instruction files and optional audit attestations.

The most important boundary is explicit in the security docs and code: the child is untrusted, kernel primitives are trusted, supervisor/proxy are trusted, and CLI/profile/policy code is trusted configuration plumbing. This is the right model for an agent-support system, because the child can include prompt-injected tools, shell scripts, language runtimes, package installers, or MCP clients.

## Design Choices

Nono compiles human-friendly policy into fully resolved capabilities before launch. Profiles can inherit defaults and groups, but the actual sandbox receives concrete path, socket, network, credential, and process rules. Direct manifests are schema-first and avoid inheritance or hooks, which makes them easier to inspect and version.

The repo treats deny rules as first-class. Sensitive path groups and protected internal state are not merely absent from allowlists; the compiler detects grants that overlap denies and fails hard on Linux because Landlock cannot express deny-under-allow. macOS can emit explicit Seatbelt deny rules in some parent-grant cases, so the platform behavior is intentionally different.

The supervisor uses fd injection rather than handing the child broad filesystem permissions after an approval. That is a valuable pattern: the child requests a path, the trusted parent verifies and opens a canonical object, and only that fd is delivered. The code also rechecks procfs-sensitive paths, blocks dangerous procfs targets, and avoids `O_CREAT`/`O_TRUNC` in the supervisor open path.

Credential access is brokered through the proxy whenever possible. The child can receive a phantom token and service-specific base URL, while the real secret stays in the parent/proxy process. Routes can declare endpoint rules, injection modes, OAuth2, mTLS/TLS settings, and proxy-side token validation.

Prompt-injection mitigation is modeled as supply-chain trust for instruction files. Project and user trust policies declare included instruction paths, publishers, blocklists, and enforcement. Startup scanning verifies signed files, runtime interception can verify matching files when they are opened, and `--trust-override` exists only as a CLI flag rather than a profile setting.

Audit is part of normal supervised execution, not an afterthought. Plain `nono run` creates an audit session by default; `--no-audit` opts out; rollback requires audit. Commands are scrubbed with a redaction policy before being written. Network events, open-url events, capability decisions, exit status, Merkle roots, optional DSSE audit attestations, and a chained ledger all build toward verifiable session history.

## Strengths

The capability model is concrete and broad enough for real coding agents. It covers filesystem, network, Unix sockets, commands, processes, signals, IPC, credentials, browser opens, trust policy, and rollback paths rather than relying on a single "sandbox on/off" switch.

The Linux supervised path is unusually specific about kernel boundary details. It detects Landlock ABI levels, handles WSL2 limitations, uses seccomp-notify for transparent expansion, validates `openat2` arguments, handles procfs symlinks carefully, rate-limits requests, injects fds, and avoids known seccomp `CONTINUE` footguns for sensitive opens.

The proxy is a strong brokered-secret pattern. It uses a per-session 256-bit token, constant-time token comparisons, route-level credential loading, phantom API keys, endpoint-rule default-deny semantics, metadata/link-local protections, DNS resolution reuse to avoid rebinding, and fail-closed behavior when managed credentials are unavailable.

Trust policy directly targets prompt injection through mutable instruction files. Signed `AGENTS.md`/`SKILLS.md`-style files, publisher policies, blocklists, runtime digest rechecks, and write protection are reusable primitives for AI coding systems where repo-local instructions can steer tool behavior.

Audit and rollback are productized. Default audit sessions, event hash chains, Merkle roots, ledger chaining, optional audit signing, network event capture, session discovery, rollback snapshots, and verification commands create a better forensic trail than typical local agent wrappers.

The integration tests align with the threat model. The reviewed tests cover network blocking/proxy behavior, TLS intercept wiring, sensitive paths, path-collision bypass regressions, targeted bypass protection, `nono why`, trust signing/verification/startup enforcement, audit defaults and opt-out, rollback lifecycle, and WSL2 degradation.

## Weaknesses

The strongest transparent expansion story is Linux-specific. macOS Seatbelt can enforce many file/network rules but cannot mirror the Linux seccomp-notify fd-injection behavior exactly. WSL2 behavior depends on kernel features and explicitly degrades or fails secure for proxy-only cases when per-port enforcement is missing.

Resource exhaustion is not a core boundary. The security docs call out that CPU, memory, disk, process count, and other resource limits are outside the current sandbox model. Agentic Coding Lab should pair this style of local capability runtime with cgroups, job objects, containers, or another quota layer.

The supervisor and proxy are large trusted components. That is normal for brokered access, but it means parsing bugs in request handling, path resolution, proxy routing, TLS interception, or audit plumbing matter. The design minimizes child power but increases the importance of hardening and fuzzing the broker surface.

Network policy has unavoidable platform and protocol tradeoffs. CONNECT authentication is deliberately lenient for ordinary proxy CONNECT in some cases because common clients such as Node's `undici` omit proxy auth; host filtering still applies, but the proxy token is not uniformly mandatory for every CONNECT path. L7 endpoint enforcement requires reverse proxy or TLS interception, and custom proxy/bypass behavior must be configured carefully.

Trust enforcement depends on users bootstrapping keys and policies correctly. Unsigned or missing instruction files can be denied under enforcement, but initial project policy anchoring, publisher distribution, and safe use of `--trust-override` remain operational risks. The file-backed key identity is path-dependent in tests, which is useful but can surprise users who relocate keys.

Direct capabilities can still be dangerous if granted too broadly. If a user grants a workspace, the agent can damage anything inside that workspace unless rollback/audit catches it. Sensitive defaults protect common home-directory secrets and `~/.nono`, but they do not replace careful profile design.

## Ideas To Steal

Compile profiles into a normalized capability manifest before launch. Keep inheritance and user-friendly groups at authoring time, but make the runtime consume a resolved, inspectable capability set.

Use a trusted parent as a broker instead of trying to predict every future path. Let the child request specific file/socket/open-url access, validate in the parent, then deliver an fd or deny with an audited decision.

Make protected internal state non-negotiable. Store sessions, rollbacks, credentials, trust material, and proxy CA bundles under a protected root; reject grants that overlap it; add platform-specific deny rules when possible.

Broker credentials through a reverse proxy. Give the child service base URLs and phantom tokens; validate those tokens at the proxy; inject real secrets only on allowed upstream endpoints.

Treat agent instruction files like signed supply-chain inputs. Sign instruction files, merge user and project policy additively, block revoked publishers/digests, enforce startup verification, and recheck runtime opens before the child reads instructions.

Put `why` queries next to enforcement. A policy explainer for filesystem and network decisions is valuable for debugging least-privilege profiles and for teaching users why a capability is missing or denied.

Record auditable runtime facts by default. Chain event logs, store Merkle roots, include network and capability decisions, scrub secrets from commands, and make verification a command rather than a manual process.

## Do Not Copy

Do not assume a local OS sandbox also solves resource isolation. Add explicit CPU, memory, disk, process, file descriptor, and wall-clock controls if untrusted agents may run arbitrary code.

Do not copy Linux behavior directly to macOS or WSL2. The exact Landlock, seccomp-notify, Seatbelt, and WSL2 semantics differ enough that each platform needs its own tests and documented security posture.

Do not let profiles disable trust enforcement or protected-state policy. Nono keeps `--trust-override` as a CLI-only escape hatch; preserve that separation.

Do not expose a proxy without a clear token and route model. If L7 policy or credential injection is required, reject CONNECT bypasses to route upstreams unless interception or reverse proxying is active.

Do not rely on client-side SDK behavior for credential safety. The proxy must validate phantom tokens, strip proxy artifacts, filter hop-by-hop/auth headers, and fail closed when credentials are missing.

Do not use broad home-directory grants as the normal agent profile. Sensitive path denies reduce blast radius, but least-privilege project/worktree grants plus explicit bypasses are safer and easier to audit.

## Fit For Agentic Coding Lab

Fit is high for the `agent-support-systems` category. Nono offers one of the clearest local implementations of a capability-based agent runtime with brokered access. Its patterns are directly reusable for a lab that wants agents to operate inside a developer workstation or project checkout without inheriting all user privileges.

The strongest Agentic Coding Lab takeaways are: resolved capability manifests, path/socket/network/credential policy as runtime inputs, trusted supervisor fd brokering, proxy-side credential injection, signed instruction-file trust, audit integrity, rollback snapshots, and policy explanation. These are portable design patterns even if the exact Landlock/Seatbelt implementation is not.

The main adaptation is to separate boundary layers explicitly. Use nono-style capabilities and brokers for least privilege, but add a resource-isolation layer, strengthen broker fuzzing/tests, define platform-specific security claims, and decide whether local OS sandboxing is sufficient or should be wrapped by containers, microVMs, or remote sandboxes for high-risk workloads.

## Reviewed Paths

- `README.md`, `Cargo.toml`, workspace crate manifests: project scope, Rust workspace layout, dependencies, feature areas, and package boundaries.
- `docs/cli/internals/security-model.mdx`, `docs/cli/internals/overview.mdx`, `docs/cli/internals/capability-manifest.mdx`: threat model, trusted/untrusted components, capability manifest design, Landlock/Seatbelt/seccomp behavior, limitations, and schema principles.
- `docs/cli/features/networking.mdx`, `credential-injection.mdx`, `supervisor.mdx`, `trust.mdx`, `audit.mdx`, `session-lifecycle.mdx`: network proxying, credential routes, supervisor behavior, signed instruction policies, audit/rollback evidence, and session operations.
- `crates/nono/src/capability.rs`, `sandbox/linux.rs`, `sandbox/macos.rs`, `sandbox/mod.rs`, `supervisor/mod.rs`, `net_filter.rs`, `scrub.rs`, `manifest.rs`, `trust/**`, `undo/**`: core capability types, platform sandboxing, supervisor protocol, host filtering, redaction, manifest/trust/rollback primitives.
- `crates/nono-cli/src/main.rs`, `cli.rs`, `command_runtime.rs`, `launch_runtime.rs`, `sandbox_prepare.rs`, `execution_runtime.rs`, `exec_strategy.rs`, `exec_strategy/supervisor_linux.rs`: CLI dispatch, profile/manifest launch planning, supervised execution, fd brokering, procfs handling, AF_UNIX/network mediation, and direct/wrap behavior.
- `crates/nono-cli/src/capability_ext.rs`, `policy.rs`, `protected_paths.rs`, `profile/**`, `profile_resolver.rs`, `credential_runtime.rs`, `proxy_runtime.rs`, `open_url_runtime.rs`, `terminal_approval.rs`: policy compilation, sensitive/protected path rules, profile inheritance, credential loading, proxy env wiring, browser-open policy, and approval UI sanitization.
- `crates/nono-cli/src/trust_scan.rs`, `trust_intercept.rs`, `instruction_deny.rs`, trust command modules: startup trust scanning, runtime file verification, write protection of verified files, policy merging, blocklists, publisher matching, and CLI signing/verification.
- `crates/nono-cli/src/audit_integrity.rs`, `audit_session.rs`, `audit_ledger.rs`, `audit_attestation.rs`, `rollback_runtime.rs`, `rollback_session.rs`, `rollback_ui.rs`: audit event hashing, session discovery, ledger chaining, DSSE audit attestation, rollback snapshot initialization/finalization, and review/restore flow.
- `crates/nono-proxy/src/config.rs`, `server.rs`, `connect.rs`, `reverse.rs`, `credential.rs`, `filter.rs`, `token.rs`, `route.rs`, `audit.rs`, `tls_intercept/**`, `external.rs`, `forward.rs`, `oauth2.rs`: proxy config, token generation, CONNECT/reverse paths, credential store, endpoint filtering, metadata/link-local protection, TLS interception, OAuth2, external proxy support, and network audit events.
- `tests/integration/test_network.sh`, `test_tls_intercept.sh`, `test_sensitive_paths.sh`, `test_bypass_protection.sh`, `test_audit.sh`, `test_rollback.sh`, `test_trust_cli.sh`, `test_policy_queries.sh`, `test_wsl2.sh`: integration coverage for network, TLS intercept wiring, sensitive/protected paths, bypass controls, audit defaults, rollback lifecycle, trust enforcement, policy explainers, and WSL2 behavior.
- Unit tests embedded in `crates/nono/src/net_filter.rs`, `crates/nono-proxy/src/server.rs`, `token.rs`, `reverse.rs`, and audit/trust modules: route/env behavior, token validation, phantom token modes, endpoint/path/query transforms, metadata SSRF protections, audit hashing, ledger verification, and attestation verification.

## Excluded Paths

- `docs/cli/.vitepress/**`, documentation theme/config/assets, screenshots, GIFs, PNG/WebP/SVG media, badges, and marketing images: UI/static presentation only.
- `bindings/c/**`: FFI wrapper surface around core behavior; sampled as workspace context but excluded from runtime/security deep review because the CLI/core/proxy paths implement the agent boundary.
- `docker/**`, `tools/docker/**`, package/release helper scripts, install scripts, shell completions, and packaging metadata: useful for distribution but not the primary capability, sandbox, proxy, trust, audit, or rollback model.
- Generated schema and lock-style files such as JSON schema snapshots, `Cargo.lock`, and generated docs artifacts: reviewed only where they confirmed manifest/profile shape, not line-by-line.
- `target/**`, `node_modules/**`, `vendor/**`, build outputs, and dependency caches: not present as source review targets; trust scanning code explicitly skips common generated/vendor directories such as `.git`, `target`, `node_modules`, and `vendor`.
- Test harness helper boilerplate under `tests/lib/**` and repetitive fixture data: read only enough to understand integration-test assertions; detailed runtime evidence came from the tested CLI/core/proxy paths.
