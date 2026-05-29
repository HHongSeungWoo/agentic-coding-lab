# kubernetes-sigs/agent-sandbox

- URL: https://github.com/kubernetes-sigs/agent-sandbox
- Category: agent-support-systems
- Stars snapshot: 2,642 (GitHub REST API `stargazers_count`, captured 2026-05-29)
- Reviewed commit: 8d3d11cca3a6e0b05127bd70ba4b053058d00be5
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong Kubernetes-native reference for isolated, stateful, singleton agent workloads: a `Sandbox` CRD reconciles one pod plus optional PVCs and service, while extension CRDs add templates, claims, warm pools, lifecycle cleanup, default network policy, and Python/Go client access. Treat it as an orchestration and policy layer, not a standalone isolation primitive: hard security still depends on Kubernetes runtime classes such as gVisor/Kata, admission policy, CNI enforcement, image hardening, and cluster operations.

## Why It Matters

Agent Sandbox is directly relevant to coding-agent infrastructure because it expresses an agent runtime as a Kubernetes object instead of an ad hoc pod, shell, or container. The core abstraction is a single long-running workload with stable identity and optional persistent storage. That shape fits coding agents well: an agent can write files, install dependencies, run code, inspect errors, retry across turns, pause by scaling to zero, and clean up after a deadline without losing all state.

The project is especially useful for Agentic Coding Lab because it is not another hosted sandbox SDK only. It shows how to model the execution substrate inside Kubernetes: CRDs, controllers, controller-runtime reconciliation, status conditions, ownership references, shared network policy, warm-pool preallocation, and e2e tests against a real cluster. The design lesson is that "agent sandbox" is an orchestration contract plus a runtime isolation contract. This repo implements much of the former and delegates much of the latter to Kubernetes, CNI, admission policy, and runtime classes.

## What It Is

Agent Sandbox is a Kubernetes SIG Apps project for managing isolated, stateful singleton workloads, including AI agent runtimes. The reviewed repo contains:

- `api/v1beta1`: core `Sandbox` API with pod template, `volumeClaimTemplates`, `replicas` limited to 0 or 1, optional headless service, shutdown time, shutdown policy, status conditions, selector, and pod IPs.
- `controllers`: core reconciler that creates/adopts/deletes a pod, optional service, and PVCs, updates readiness/suspension/finished/expired conditions, and performs expiry cleanup.
- `extensions/api/v1beta1`: `SandboxTemplate`, `SandboxClaim`, and `SandboxWarmPool` APIs for reusable runtime templates, user-facing allocation, TTL-after-finished, env injection policy, network policy management, and pre-warmed pools.
- `extensions/controllers`: claim/template/warm-pool reconcilers, in-memory warm-pool queue, template-level shared `NetworkPolicy`, secure defaults, metadata validation, env injection, warm adoption, and rollout logic.
- `clients/python/agentic-sandbox-client`: Python SDK for creating claims, resolving adopted sandboxes, waiting for readiness, routing through a sandbox router/gateway/local tunnel/in-cluster direct connection, running commands, and reading/writing/listing files.
- `clients/go/sandbox`: Go client helpers for lifecycle, command, file, gateway, tunnel, and tracing paths.
- `examples` and `site/content/docs`: runtime templates and examples for code execution, coding agents, ADK, LangChain/LangGraph, browser/computer use, gVisor, Kata, network policy, VAP/Kyverno/OPA policy, and persistent volumes.
- `test/e2e` and controller tests: unit and cluster tests for lifecycle, warm pools, shutdown policy, Python SDK, volume claim templates, readiness, and exclusivity regressions.

The project currently exposes v1beta1 CRDs in generated manifests and client constants. Some documentation and examples still show `v1alpha1`, so consumers should verify API version examples before copying them into a cluster.

## Research Themes

- Token efficiency: Not a prompt/token system. It reduces context pressure indirectly by moving execution state, generated files, dependency caches, logs, and model artifacts into a sandbox filesystem or PVC instead of repeatedly serializing them through chat context.
- Context control: Strong operational context boundary: `Sandbox`, `SandboxClaim`, template name, claim UID labels, pod IPs, service FQDN, annotations, warm-pool labels, PVCs, and lifecycle status. No semantic memory or prompt-context filtering layer.
- Sub-agent / multi-agent: Supports many isolated sandboxes and warm pools; no native multi-agent planner. The Kubernetes namespace/template/claim model can allocate per-agent or per-user workspaces, and claims can adopt prewarmed sandboxes under a one-claim-one-sandbox invariant.
- Domain-specific workflow: Strong for code execution and stateful agent runtimes: command execution, file transfer, templates, warm pools, persistent volumes, gVisor/Kata examples, ADK/LangGraph examples, and router/gateway access.
- Error prevention: Uses status conditions, owner-reference checks before adoption/deletion, metadata validation, env injection policies, network default deny, DNS hardening, TTL cleanup, e2e tests, readiness probes, tracing, and metrics. Does not by itself enforce all pod security controls.
- Self-learning / memory: No learning system. Durable memory is operational state: PVCs, long-running pods, warm pools, and future/planned snapshots or hibernation-like work.
- Popular skills: Create sandbox from template, claim/adopt warm sandbox, run command, write/read/list files, connect through router/gateway/local tunnel, attach persistent volume, set shutdown deadline, scale to zero/one, apply template-level egress/ingress policy, select gVisor/Kata runtime class, and verify readiness through CRD conditions.

## Core Execution Path

The core flow starts with a `Sandbox` custom resource. `SandboxReconciler.Reconcile` loads the object, defaults `spec.replicas` to 1, checks `shutdownTime`, then reconciles PVCs, a pod, and an optional service. The pod is selected with an `agents.x-k8s.io/sandbox-name-hash` label derived from the sandbox name. `volumeClaimTemplates` create PVCs named `<claim-template-name>-<sandbox-name>`, and matching pod volumes are injected with StatefulSet-like semantics. If `spec.service` is true, the controller creates a headless service and writes `status.service` and `status.serviceFQDN`.

Pod lifecycle is intentionally singleton. `spec.replicas` is constrained to 0 or 1. When replicas is 0, the controller deletes only pods owned by that sandbox and marks `Suspended`. When replicas is 1, it creates a pod named after the sandbox unless a warm-pool-adopted pod is tracked by the `agents.x-k8s.io/pod-name` annotation. Readiness is computed from pod phase, pod Ready condition, pod IPs, and service existence when service readiness is required. Terminal pod phases set a `Finished` condition. Expiry sets `Ready=False` with `SandboxExpired`, deletes owned pod/service resources, and deletes or retains the `Sandbox` depending on shutdown policy.

The higher-level agent allocation flow starts with a `SandboxTemplate` and `SandboxClaim`. The claim controller validates additional pod metadata, resolves or creates a sandbox, and mirrors sandbox readiness into claim status. On a cold start, it copies the template pod spec, service setting, volume claim templates, claim identity labels, and template hash into a new `Sandbox`. It applies extension secure defaults before creation: service account token automount defaults to false, and strict secure-default network mode changes unset DNS policy to `DNSNone` with public resolvers.

On a warm start, `SandboxWarmPoolReconciler` maintains a target number of ready sandbox CRs for a template. It builds generated-name sandboxes from the template, labels them with warm-pool and template hashes, optionally marks them safe to evict, and creates/deletes them in slow-start parallel batches bounded by `--sandbox-warm-pool-max-batch-size`. `SandboxClaimReconciler` watches adoptable warm sandboxes through an in-memory synchronized queue keyed by template hash. Adoption removes warm-pool labels, transfers owner reference from pool to claim, records the adopted sandbox name on the claim, propagates claim identity metadata, and ensures the sandbox records its actual pod name.

The Python SDK wraps this Kubernetes flow. `SandboxClient.create_sandbox()` creates a `SandboxClaim`, waits for claim status to reveal the backing sandbox name, waits for the `Sandbox` Ready condition, and returns a `Sandbox` handle. The handle exposes `commands.run()` and `files.*` APIs through a `SandboxConnector`. Connection modes include local `kubectl port-forward` to `svc/sandbox-router-svc`, direct router URL, Gateway API discovery, and in-cluster direct pod DNS/IP. Router-backed modes send `X-Sandbox-ID`, namespace, port, and optionally pod IP headers to a FastAPI router, which proxies to `http://<sandbox>.<namespace>.svc.<cluster-domain>:<port>` or directly to the pod IP.

The example Python runtime is a FastAPI server with `/execute`, `/upload`, `/download`, `/list`, and `/exists`. Commands are parsed with `shlex.split` and executed with `subprocess.run(..., cwd="/app")`; richer shell behavior requires explicit commands such as `sh -c`. The SDK's file client normalizes upload/read paths to prevent absolute paths, `..`, NUL, and control characters unless `allow_unsafe_paths=True`. The sample runtime protects download/list/exists with a `/app` common-path check, but its upload handler joins `/app` with `file.filename` directly, so direct non-SDK clients should not be trusted without server-side upload path hardening.

## Architecture

The architecture has three layers:

- Kubernetes API layer: `Sandbox`, `SandboxTemplate`, `SandboxClaim`, and `SandboxWarmPool` resources form the durable desired-state API.
- Controller layer: controller-runtime reconcilers create pods, services, PVCs, shared network policies, warm-pool sandboxes, ownership transfers, status conditions, events, traces, and metrics.
- Runtime access layer: Python/Go SDKs plus the sandbox router/gateway/local tunnel connect agents to HTTP servers running inside sandbox pods.

The actual process/filesystem/network boundary is Kubernetes, not a bespoke hypervisor in this repo. A sandbox pod has normal Kubernetes pod isolation unless its `podTemplate.spec.runtimeClassName` selects gVisor, Kata, or another hardened runtime. The repo provides gVisor and Kata guides, overlays, and policy examples, but the controller does not force a runtime class by default. Admission examples under `examples/policy` show how to require gVisor, non-root, resource limits, disabled host namespaces, no hostPath, dropped capabilities, no service account token, and node selector/toleration constraints.

Network policy is template-level. `SandboxTemplateReconciler` creates one `<template-name>-network-policy` per managed template, selecting pods by `agents.x-k8s.io/sandbox-template-ref-hash`. With no custom policy, the secure default allows ingress only from pods labeled `app=sandbox-router` and allows public IPv4/IPv6 egress while excluding RFC1918/private ranges, link-local, metadata-server ranges, IPv6 ULA, and IPv6 link-local. Custom rules replace the defaults completely. `networkPolicyManagement: Unmanaged` deletes the generated policy and leaves enforcement to external CNI/service-mesh policy.

Policy has two important limitations. First, Kubernetes `NetworkPolicy` is L3/L4, not L7, so HTTP method/path/domain policy requires an external system such as Cilium or a mesh. Second, the default ingress rule assumes the router is in the same namespace and has the expected label. If a deployment bypasses the router with in-cluster direct pod access, separate network policy must authorize that path.

Persistence is Kubernetes-native. PVCs survive pod restarts and suspend/resume cycles; a sandbox can be scaled to zero while retaining PVC data. Warm pools reduce startup latency by preallocating sandboxes, but they are not snapshots: adopted pods already exist and may carry preloaded runtime state defined by the template. Roadmap items mention deep hibernation, automatic resume, scale-to-zero, snapshots/PodSnapshot integrations, richer routing, MCP server support, and portable backends; those should be treated as roadmap or example integrations unless the exact path is present in the reviewed source.

## Design Choices

The project chooses declarative Kubernetes CRDs over a custom hosted control plane. This makes it easy to compose with namespaces, RBAC, admission control, runtime classes, NetworkPolicies, HPAs, PDBs, Gateway API, metrics, and existing cluster operations. It also means the safety model inherits Kubernetes complexity.

The core `Sandbox` API is intentionally small: one pod, optional service, optional PVCs, lifecycle fields, and conditions. Higher-level multi-tenant ergonomics live in extensions. This split is useful. Low-level users can manage sandboxes directly; platforms can expose only `SandboxClaim` and templates to users.

The claim/template model centralizes policy. Templates decide pod spec, network policy, service creation, volume claim templates, and env injection policy. Claims can request lifecycle and metadata, but metadata overrides are validated and restricted. Env injection defaults to disallowed unless the template permits injection or overrides. This is the right direction for hosted coding-agent systems where users should request a runtime without being able to loosen the template owner's security posture.

Warm-pool allocation uses an in-memory queue rather than listing all candidate sandboxes on every claim. This is a pragmatic scale choice, reinforced by controller watches, deduplication, deletion cleanup, and fallback validation when popping candidates. The tradeoff is controller-local state: restarts rebuild queue state through watched sandbox updates rather than a durable queue.

Network policy is shared per template instead of per claim. That reduces policy-object churn and makes updates apply across current and future sandboxes. The tradeoff is less per-user flexibility: per-claim egress rules are not supported, and advanced policy must target the template hash label externally.

The SDK chooses HTTP runtime servers inside pods instead of relying only on Kubernetes exec. That is agent-friendly because commands/files become normal API calls through a router/gateway. It also creates a second security surface: the in-pod runtime server and router must be authenticated, reachable only through intended paths, and hardened against path traversal, SSRF, request smuggling, and long-running command/resource abuse.

## Strengths

The core abstraction matches coding-agent state well. A sandbox is not just a one-shot function call; it has a stable identity, pod, optional service, optional PVCs, status, and lifecycle operations. That supports iterative code generation, dependency installation, artifact persistence, and debug loops.

The Kubernetes ownership model is used carefully. Controllers check owner references before deleting or adopting pods, services, PVCs, sandboxes, and network policies. This reduces the chance that a claim or sandbox deletes unrelated user resources with a colliding name.

The extension API has practical multi-tenant controls. Templates can block env injection, reject env overrides, centrally define network policy, disable service account token automount by default, and validate claim-provided labels/annotations so users cannot spoof restricted domains or the `app=sandbox-router` label.

Warm pools are a concrete latency-reduction pattern. The project handles adoption, template hash matching, specific-pool selection, staleness detection, update strategies (`OnReplenish` and `Recreate`), stuck warm sandbox cleanup, HPA-friendly scale status, and a regression test for one sandbox being adopted by at most one claim.

Default network posture is stronger than ordinary pod defaults. Managed templates get default-deny ingress, metadata/private-range egress blocks, and DNS override to public resolvers when no DNS policy is set. The docs explain Google Cloud metadata/DNS gotchas and how custom policies replace defaults.

Verification is meaningful. The repo includes controller unit tests, envtest-style tests, and e2e tests for core sandbox lifecycle, volume claim templates, shutdown policies including foreground deletion, warm-pool rollout, warm-pool adoption exclusivity, Python SDK flows, and policy controller behavior. The test docs explicitly cover unit, e2e, benchmarks, and race detector modes.

## Weaknesses

The controller is not itself a hardened sandbox boundary. If a template uses ordinary runc pods with broad privileges, host networking, hostPath, root, or no resource limits, Agent Sandbox will faithfully orchestrate that unsafe pod unless external admission policy blocks it. The secure VAP/Kyverno/OPA examples are examples, not required controller behavior.

Secure defaults mostly live in the extension path. Direct `Sandbox` users can specify arbitrary pod specs, and the core reconciler does not default `automountServiceAccountToken` to false or force DNS/network policy. Platforms should expose claims/templates rather than unrestricted direct `Sandbox` creation to untrusted users.

The router is header-directed. It proxies based on `X-Sandbox-ID`, namespace, port, and optional pod IP. That is convenient, but production deployments need authentication/authorization around who may set those headers, namespace restrictions, request size/time limits, and a policy that prevents users from routing to arbitrary internal services.

The sample Python runtime has mixed hardening. Command execution avoids direct shell interpolation with `shlex.split`, and the SDK sanitizes file paths. But the runtime upload endpoint itself does not call the same safe path resolver used by download/list/exists, so direct clients could potentially write outside `/app` if the server receives unsafe multipart filenames. That should be fixed before using the example as a production runtime.

Some docs/examples lag the current API. The checked-in CRDs and SDK constants use `v1beta1`, while multiple docs/examples still show `v1alpha1`. That is normal in a fast-moving Kubernetes project but risky for copy-paste onboarding.

Deep hibernation, automatic resume on traffic, first-class router, MCP server, TypeScript SDK, portable backend, scale-to-zero automation, dynamic per-claim network attachment, and advanced snapshots are roadmap or partial examples rather than uniformly implemented core behavior at the reviewed commit.

## Ideas To Steal

Model a coding-agent runtime as a durable CRD handle, not as a local subprocess. Store the handle, template, claim, namespace, lifecycle, and policy metadata; keep large state in the sandbox filesystem/PVC.

Separate low-level runtime from user-facing allocation. Let `Sandbox` be the primitive and `SandboxClaim` be the safe allocator that applies template policy, lifecycle, metadata rules, and warm-pool adoption.

Use singleton semantics explicitly. Constrain replicas to 0/1, expose status replicas and selector, and define suspend/resume through pod deletion/recreation while keeping PVCs.

Adopt template-level shared network policy. Use a controller-managed selector label so all sandboxes from a template inherit the same policy and updates apply immediately.

Default to secure networking for untrusted agents: deny internal ingress, allow only router ingress, block private/metadata/link-local egress, and document DNS behavior. Require users to opt into any internal network reachability.

Make warm pools first-class. Maintain ready pool status, use update strategies, remove stale warm instances, and make adoption atomic enough that each claim owns exactly one sandbox.

Expose SDK primitives that match agent needs: create/get/list/delete sandbox, run command with structured stdout/stderr/exit code, write/read/list/exists files, choose connection mode, set TTL, and close local connection without deleting remote state.

Pair controller code with admission policies. Provide ready-to-apply policies for runtimeClass, non-root, no hostPath, no host network/PID/IPC, dropped capabilities, resource limits, no service account tokens, and namespace-specific constraints.

## Do Not Copy

Do not treat a Kubernetes pod as sufficient isolation for untrusted code. Require gVisor, Kata, microVMs, hardened nodes, or another audited runtime boundary for high-risk agents.

Do not expose direct `Sandbox` creation to untrusted users without admission policy. Use templates and claims so users cannot loosen runtime, volume, host namespace, service account, or network settings.

Do not deploy a header-routed sandbox router without auth and namespace authorization. Header-based routing is a mechanism, not an access-control model.

Do not assume default network policy covers custom rules. Supplying `spec.networkPolicy` replaces secure defaults, so templates must re-add router ingress and safe egress rules explicitly.

Do not rely on client-side path sanitization alone. File servers inside sandbox images should enforce their own workspace root and reject absolute/traversal paths on every read and write.

Do not copy broad example images into sensitive production use. Build task-specific images with pinned dependencies, non-root users, resource limits, minimal tools, and clear secret handling.

Do not ignore API version drift in examples. Verify CRD versions, generated clients, and docs before writing reusable artifacts.

## Fit For Agentic Coding Lab

Agent Sandbox is a high-fit `agent-support-systems` candidate when the lab wants to learn from Kubernetes-native sandbox orchestration. It is weaker as a self-contained secure execution product because the isolation implementation is intentionally delegated to cluster configuration and runtime classes.

The best reusable ideas are the CRD shape, claim/template split, warm-pool adoption workflow, singleton lifecycle status, PVC persistence, shared network policy, and SDK connection modes. For Agentic Coding Lab, this would pair well with a stricter local policy layer: default-deny network by template, required runtime class, required resource limits, workspace-only file API, authenticated router, and tests that verify blocked egress, metadata-server denial, no service account token, no hostPath, and cleanup after failures.

For coding agents specifically, the project is a good foundation for "stateful tool workspace per task/user/agent." It can support long-running sessions, iterative test loops, dependency caches, and low-latency warm starts. It does not yet provide a complete coding-agent platform out of the box: no built-in planner, no memory layer, no policy-aware command broker, no per-tool authorization, and no finished MCP server in the reviewed commit.

## Reviewed Paths

- `README.md`, `roadmap.md`, `docs/api.md`, `docs/configuration.md`, `docs/testing.md`: project scope, install/config flags, API reference, strategic roadmap, and verification commands.
- `api/v1beta1/sandbox_types.go`, `api/v1beta1/groupversion_info.go`: core `Sandbox` schema, lifecycle, PVC templates, service field, status conditions, replicas scale subresource, and v1beta1 group version.
- `controllers/sandbox_controller.go`, `internal/lifecycle/expiry.go`, `cmd/agent-sandbox-controller/main.go`: core reconciliation, ownership checks, pod/service/PVC handling, suspend/resume, expiry cleanup, status computation, metrics/tracing/pprof flags, concurrency/QPS settings, and extension controller registration.
- `extensions/api/v1beta1/sandboxtemplate_types.go`, `sandboxclaim_types.go`, `sandboxwarmpool_types.go`: extension API contracts for templates, claims, warm pools, network policy, env injection, lifecycle, TTL-after-finished, warm-pool policy, update strategy, and status.
- `extensions/controllers/sandboxclaim_controller.go`, `sandboxtemplate_controller.go`, `sandboxwarmpool_controller.go`, `utils.go`, `queue/simple_sandbox_queue.go`: active/expired claim flow, cold creation, warm adoption, template network policy, secure defaults, metadata/env validation, warm-pool scaling, stale pool replacement, and in-memory adoption queue.
- `clients/python/agentic-sandbox-client/k8s_agent_sandbox/**`: Python SDK lifecycle, Kubernetes helper, connection strategies, router headers, command execution, file API path handling, async parallels, models, constants, tracing, metrics, and unit tests.
- `clients/python/agentic-sandbox-client/sandbox-router/**`: FastAPI router, Gateway/local tunnel integration, routing headers, proxy timeout, cluster-domain config, and router tests.
- `clients/go/sandbox/**`, `clients/go/README.md`: Go client command/file/tunnel/gateway lifecycle helpers and tests.
- `site/content/docs/use-cases/code-execution/_index.md`, `coding-agents/_index.md`, `gvisor-isolation/_index.md`, `kata-containers-isolation/_index.md`, `site/content/docs/filesystem/**`, `site/content/docs/volumes/volume-claim-template/_index.md`, `site/content/docs/sandbox/lifecycle/_index.md`: user-facing patterns for agent code execution, coding agents, isolation runtimes, file APIs, persistent storage, and scheduled cleanup.
- `examples/python-runtime-sandbox/**`, `examples/code-interpreter-agent-on-adk/README.md`, `examples/langchain/**`, `examples/sandboxed-tools/**`: concrete agent/runtime examples for FastAPI execution server, ADK tool integration, LangGraph coding agent with cached model PVC, and ephemeral tool-call sandboxes.
- `examples/policy/network-policy-management/**`, `examples/policy/vap/**`, `examples/policy/kyverno/**`, `examples/policy/opa-gatekeeper/**`, `extensions/examples/secure-sandboxtemplate.yaml`: network policy guidance and admission-policy examples for stronger runtime security.
- `controllers/*_test.go`, `extensions/controllers/*_test.go`, `test/e2e/**`, `clients/python/agentic-sandbox-client/k8s_agent_sandbox/test/unit/**`: unit, envtest, e2e, SDK, lifecycle, warm-pool, shutdown, metadata, network policy, and regression coverage.
- `helm/values.yaml`, `helm/templates/deployment.yaml`, `k8s/controller.yaml`, `k8s/extensions.controller.yaml`: sampled deployment flags and controller configuration only; generated RBAC/CRD detail was excluded.

## Excluded Paths

- `clients/k8s/**`: Kubernetes generated clientsets, informers, and listers for core and extension APIs. Reviewed the source API types and handwritten controllers instead.
- `api/v1beta1/zz_generated.deepcopy.go`, `extensions/api/v1beta1/zz_generated.deepcopy.go`: generated deepcopy boilerplate; not useful for architecture review.
- `k8s/crds/**`, `helm/crds/**`, `k8s/*rbac.generated.yaml`, `k8s/extensions-rbac.generated.yaml`, `helm/templates/*rbac.generated.yaml`: generated CRD/RBAC Kubernetes boilerplate. Sampled only enough to confirm served API version and install shape.
- `.github/**`, `OWNERS`, `SECURITY_CONTACTS`, `code-of-conduct.md`, `CONTRIBUTING.md`, `RELEASE.md`, `SECURITY.md`: project governance and release/security process docs; not central to runtime execution path.
- `site/layouts/**`, `site/assets/**`, `site/static/**`, `site/package*.json`, `site/go.*`, `netlify.toml`, `site/hugo.yaml`: documentation site UI/assets/build plumbing. Reviewed only content pages relevant to sandbox architecture.
- `go.sum`, `tools.sum`, `site/package-lock.json`, `clients/python/agentic-sandbox-client/sandbox-router/requirements.txt`, example `requirements.txt` files: dependency lock/snapshot files. Not reviewed beyond noting language/runtime dependencies.
- `dev/tools/**`, `dev/ci/**`, `dev/load-test/**` except high-level benchmark/test references: CI, release, load-test, and helper scripts are lower-signal than controller/runtime logic for this note.
- `test/e2e/framework/**` internals: Kubernetes e2e harness support code. Reviewed test cases and predicates conceptually, not every framework helper.
- Binary/static demo assets such as `site/content/featured-background.webp`, screenshots, notebooks, `examples/analytics-tool/imgs/**`, `examples/code-interpreter-agent-on-adk/example.png`, and SVG diagrams beyond policy-document context.
- No vendored dependency tree was present in the checkout; generated Kubernetes boilerplate was explicitly excluded as above.
