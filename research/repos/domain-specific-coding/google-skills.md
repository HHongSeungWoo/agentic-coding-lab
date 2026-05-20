# google/skills

- URL: https://github.com/google/skills
- Category: domain-specific-coding
- Stars snapshot: 10,088 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: bae2a366cb6f4812cb86f6626d564fdaba03e53a
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for first-party domain skill packaging: copy the progressive disclosure, tool-preference boundaries, golden-path artifacts, and validation gates; do not copy Google Cloud product facts or mutable cloud operations without freshness checks, host permissions, and eval coverage.

## Why It Matters

`google/skills` is a first-party Google Agent Skills corpus for Google products and technologies. It is useful because it shows how a large vendor packages cloud-domain guidance as installable agent skills: small triggerable `SKILL.md` files, heavier reference packs, MCP-first tool routing, CLI/IaC fallbacks, and safety guardrails for real infrastructure. The repo is less useful as a runtime implementation because loading, dispatch, and installation are handled by external skill hosts such as `skills.sh` and `npx skills add`.

## What It Is

The repository contains 16 Google Cloud and Gemini-focused skills under `skills/cloud/`. Most skills are Markdown-only packages with a required `SKILL.md` and optional `references/` files. A few include richer artifacts: `gke-basics` ships `assets/` YAML examples and a golden-path Autopilot cluster config, while `agent-platform-skill-registry` ships Python helper scripts for Skill Registry CRUD, revision lookup, and operation polling.

README installation is via `npx skills add google/skills`, where the installer lets users choose specific skills. The repo itself has no package manifest, no host-side loader, no `.github` workflows, and no public automated eval suite. `CONTRIBUTING.md` says external code contributions are not accepted because skills go through internal Google verification and approval.

## Research Themes

- Token efficiency: Best skills keep `SKILL.md` short and route details to `references/` only when needed. `gke-basics` uses a trigger-keyword table to choose one reference. `gemini-api` and WAF skills are more monolithic, so the pattern is present but uneven.
- Context control: Frontmatter descriptions are the main selection surface. Reference directories, "read when needed" instructions, Developer Knowledge MCP fallbacks, and exact source-of-truth links prevent loading every product doc into context.
- Sub-agent / multi-agent: The repo does not implement subagents. The closest pattern is `gemini-managed-agents-api`, which describes server-managed agent resources with mounted skills/files/tools and later execution through `gemini-interactions-api`.
- Domain-specific workflow: Strongest area. Skills encode Google Cloud workflows for GKE, BigQuery, Cloud Run, Cloud SQL, AlloyDB, Firebase, authentication, networking observability, Gemini APIs, and Well-Architected Framework pillars.
- Error prevention: Repeated guardrails cover environment validation, least privilege, schema checks, SQL dry runs, Day-0 vs Day-1 decisions, cleanup of diagnostic resources, avoiding discrepancy loops, and use of MCP before shell tools.
- Self-learning / memory: No project-local memory or learning loop. Registry revisions and Interactions API `previous_interaction_id` are cloud-state patterns, not repo-local self-improvement.
- Popular skills: Most reusable patterns are in `gke-basics`, `google-cloud-networking-observability`, `agent-platform-skill-registry`, `gemini-api`, `gemini-interactions-api`, `gemini-managed-agents-api`, `firebase-basics`, `bigquery-basics`, and `cloud-run-basics`.

## Core Execution Path

1. User installs selected skills with `npx skills add google/skills` or the `skills.sh` flow.
2. The agent host discovers each skill through `SKILL.md` frontmatter, mainly `name` and `description`; `gke-basics` also includes `license` and `metadata`, and `gemini-api` adds `compatibility`.
3. When a task matches a skill, the `SKILL.md` gives a quick path, mandatory prerequisites, and a reference directory.
4. For service work, the skill prefers structured MCP tools where available, then falls back to `gcloud`, `bq`, `kubectl`, `curl`, Terraform, or client libraries.
5. For the Skill Registry path, `validate_env.py` checks `GCP_PROJECT_ID` and `GCP_LOCATION`, then `skill_registry_ops.py` uses Application Default Credentials and REST calls to search/list/get/upload/update/delete skills, list revisions, and poll long-running operations.
6. Verification is task-local and cloud-specific: examples include `bq --dry_run`, schema inspection, `get_operation`, `get_cluster`, `check_k8s_auth`, cleanup proof for connectivity tests, and deployment/log checks. There is no repo-wide test harness for these workflows.

## Architecture

The architecture is intentionally simple:

- `README.md`: install command, available-skill index, support and license notes.
- `CONTRIBUTING.md`: contribution policy and internal verification statement.
- `skills/cloud/<skill>/SKILL.md`: required triggerable instruction file.
- `skills/cloud/<skill>/references/` or `reference/`: detailed product guidance, CLI snippets, MCP usage, IAM/security, IaC, and troubleshooting.
- `skills/cloud/gke-basics/assets/`: reusable Kubernetes/YAML artifacts, including golden-path Autopilot settings, HPA/VPA examples, default-deny policy, and Workload Identity pod.
- `skills/cloud/agent-platform-skill-registry/scripts/`: Python helpers plus `requirements.txt`.

There is no top-level manifest listing all skills in machine-readable form beyond the README, no schema validation code, and no public runtime dispatcher.

## Design Choices

- Use vendor-authored domain skills instead of generic cloud advice.
- Keep heavy reference material out of top-level skill instructions when possible.
- Make tool boundaries explicit, especially MCP-first routing and CLI fallbacks.
- Encode "golden path" defaults for risky infrastructure domains such as GKE.
- Treat some product operations as workflows with preconditions, update masks, LRO polling, and cleanup.
- Use executable helpers only where repeatability matters, as with Skill Registry packaging and API calls.
- Link to official docs or Developer Knowledge MCP for freshness when product details may change.

## Strengths

- Strong domain packaging: skills map directly to concrete product families and operational workflows.
- Good progressive disclosure in GKE, networking observability, basic service skills, and registry management.
- Runtime-relevant tool boundaries are unusually explicit: several references label MCP tools by read/mutate/destructive mode and document fallback order.
- Safety guidance is practical for cloud work: least privilege, private connectivity, no static keys, schema verification, dry runs, cleanup, and Day-0 warning language.
- `agent-platform-skill-registry` demonstrates a real artifact workflow: folder or zip -> base64 `zippedFilesystem` -> registry upload/update -> LRO monitor -> revision inspection.
- GKE assets show how a skill can ship canonical config artifacts instead of only prose.

## Weaknesses

- No public automated evals, CI, linting, Markdown schema checks, or smoke tests for examples.
- Metadata is inconsistent. Most skills only have `name` and `description`; only a few add `license`, `metadata`, or `compatibility`.
- README is the only visible catalog; there is no machine-readable root manifest with skill paths, versions, safety level, required tools, or ownership.
- Many snippets mutate real cloud resources, but the repo does not provide a host-level permission model or approval protocol.
- Some examples use broad or placeholder-risky settings, such as wildcard network allowlists, public Cloud Run examples, and password placeholders, relying on nearby prose to soften risk.
- Product/model names and cloud API details age quickly; skills point to docs in places, but not every workflow enforces live documentation lookup.

## Ideas To Steal

- Standard skill package shape: `SKILL.md` plus optional `references/`, `scripts/`, and `assets/`.
- Reference router table with scenario, trigger keywords, and exact reference file.
- MCP tool mode table with `READ`, `MUTATE`, and `DESTRUCTIVE` labels.
- Golden-path config artifact paired with prose guardrails and deviation handling.
- Mandatory preflight validation before state-changing registry/cloud operations.
- Explicit "stop conditions" for investigations to avoid tool loops and wasteful cross-checking.
- Registry helper pattern: package skill folder, upload as `zippedFilesystem`, track revisions, and poll LROs.
- Product freshness fallback: official docs or Developer Knowledge MCP when local references do not cover the needed detail.

## Do Not Copy

- Do not copy cloud product facts verbatim into durable instructions without a freshness policy.
- Do not copy the lack of public evals; domain skills that can mutate infrastructure need fixture-based tests, dry-run examples, and policy checks.
- Do not rely only on prose warnings for destructive operations; host/runtime should enforce permissions.
- Do not expose broad tool/network examples as defaults in a general agent environment.
- Do not use a README-only catalog if agents need dependable selection, versioning, ownership, or safety metadata.
- Do not ship large product-reference bodies as always-loaded skill text.

## Fit For Agentic Coding Lab

Conditional fit. This is one of the better references for domain-specific skill packaging, especially for cloud, infrastructure, and vendor SDK workflows. Agentic Coding Lab should adopt the structure and runtime patterns, not the content wholesale. Best next artifact would be a repo-local domain skill template with:

- required `SKILL.md` frontmatter plus optional version/owner/safety metadata,
- `references/`, `scripts/`, and `assets/` directories,
- a machine-readable root catalog,
- tool boundary tables,
- verification sections with dry-run or fixture commands,
- permission labels for mutating operations.

## Reviewed Paths

- `README.md`
- `CONTRIBUTING.md`
- `skills/cloud/*/SKILL.md`
- `skills/cloud/agent-platform-skill-registry/scripts/validate_env.py`
- `skills/cloud/agent-platform-skill-registry/scripts/skill_registry_ops.py`
- `skills/cloud/agent-platform-skill-registry/references/*.md`
- `skills/cloud/gke-basics/references/gke-golden-path.md`
- `skills/cloud/gke-basics/references/mcp-usage.md`
- `skills/cloud/gke-basics/references/gke-security.md`
- `skills/cloud/gke-basics/assets/golden-path-autopilot.yaml`
- `skills/cloud/google-cloud-networking-observability/SKILL.md`
- `skills/cloud/google-cloud-networking-observability/references/mcp-usage.md`
- `skills/cloud/google-cloud-networking-observability/references/connectivity-tests.md`
- `skills/cloud/bigquery-basics/references/mcp-usage.md`
- `skills/cloud/cloud-run-basics/SKILL.md`
- `skills/cloud/cloud-run-basics/references/mcp-usage.md`
- `skills/cloud/cloud-run-basics/references/iam-security.md`
- `skills/cloud/firebase-basics/SKILL.md`
- `skills/cloud/firebase-basics/references/additional-skills.md`
- `skills/cloud/gemini-api/SKILL.md`
- `skills/cloud/gemini-api/references/safety.md`
- `skills/cloud/gemini-api/references/structured_and_tools.md`
- `skills/cloud/gemini-api/references/advanced_features.md`
- `skills/cloud/gemini-agents-api/SKILL.md`
- `skills/cloud/gemini-interactions-api/SKILL.md`

## Excluded Paths

No generated, vendored, binary, or UI-only paths were present. Long product reference files for WAF pillars and service-specific CLI/client/IaC examples were sampled for packaging, tool-boundary, safety, and verification patterns rather than reproduced line-by-line. Cloud commands and API examples were not executed because they would require credentials and could mutate external Google Cloud resources.
