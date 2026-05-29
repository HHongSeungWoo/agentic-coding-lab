# Skill Management And Routing At Scale

- Topic: skill-management-routing
- Captured at: 2026-05-29
- Status: reviewed synthesis

## Problem

Progressive disclosure solves only the second half of skill context cost. It keeps full `SKILL.md`, references, scripts, and assets out of context until activation, but it does not solve the first-hop selection problem when the agent owns hundreds or thousands of skills.

The hard problems are:

- Startup context bloat from skill names and descriptions alone.
- False-positive activation from vague descriptions.
- False-negative activation because the right skill is hidden behind weak wording.
- Duplicate or overlapping skills from personal, project, marketplace, and host-specific locations.
- Untrusted skills that can instruct the agent to run high-risk tools.
- Stale skills whose trigger text, host compatibility, APIs, or commands have drifted.
- Missing feedback loop: no evidence for which skills were useful, misrouted, ignored, or too expensive.

The winning pattern across reviewed repos is not "load fewer files". It is "treat skills as a governed capability registry, retrieve a short candidate set, then activate one skill with evidence".

## Source Notes

High-signal existing reviews:

- `agentskills/agentskills`: minimal `SKILL.md` contract, progressive disclosure, trigger-description discipline, client implementation guidance, collision/trust/compaction concerns.
- `anthropics/skills`: production-like skill corpus with trigger-rich descriptions, helper scripts, references, plugin bundle metadata, and skill eval loops.
- `vercel-labs/skills`: cross-agent installer, canonical `.agents/skills`, bounded discovery, lock files, GitHub tree hashes, well-known digest-pinned hosted skills, path and terminal sanitization.
- `anthropics/claude-plugins-official`: marketplace index, plugin manifests, SHA-pinned external entries, frontmatter/license/MCP/policy validation, hook review gates.
- `github/awesome-copilot`: large generated catalog from frontmatter, separate primitives for instructions, agents, skills, hooks, workflows, and plugin bundles.
- `trailofbits/skills`: domain marketplace with CODEOWNERS, Codex sidecar, validators, engineered workflow skills, and clear need for maturity labels.
- `PrefectHQ/fastmcp`: provider/transform/component architecture, session visibility, BM25/regex tool search transforms, and skills-as-resources provider.
- `aipotheosis-labs/aci`: semantic tool discovery, model-facing schema projections, layered permission checks, credential brokering, and execution telemetry.
- `modelcontextprotocol/registry`: canonical metadata feed with publisher fields separated from registry-managed metadata, incremental sync, namespace/package ownership checks, and explicit trust limitations.
- `lastmile-ai/mcp-agent`: MCP server allowlists, per-request tool filters, server-name namespaces, request-scoped context, and token accounting.

Direct skill-management reviews added on 2026-05-29:

- `cli/cli`: `gh skill` is a supply-chain and catalog retrieval layer, using query-time GitHub Code Search, bounded enrichment, preview/install/update/publish, provenance injection, lock metadata, and pinning. It does not solve session-time routing.
- `tech-leads-club/agent-skills`: strong catalog package, CLI, cache/lock/audit flow, validation/security scans, cross-agent paths, and MCP progressive disclosure through `search_skills`, `read_skill`, and `fetch_skill_files`. Routing still leans on long descriptions.
- `iflytek/skillhub`: strong enterprise registry: namespaces, RBAC, audit logs, publish-review-promote lifecycle, labels, version tags, package validation, scanner hooks, and install target resolution. It is registry governance, not a runtime router.
- `luongnv89/asm`: strong local manager for installed skills: cross-host path registry, local/remote catalogs, audit, eval, token counts, bundles, dedupe, and pinned registry resolution. It helps prune/organize but does not decide per-task skill shortlists.
- `letta-ai/skills`: useful corpus plus strong meta guidance for category-first discovery and dynamic `skills` memory-block updates. The repo itself has no router, registry generator, trust metadata, or CI validation.
- `netresearch/claude-code-marketplace`: good curated marketplace and package-style distribution pattern, including generated discovery site and coordinator-backed lightweight `AGENTS.md` indexes. It does not implement semantic routing.
- `dmgrok/agent_skills_directory`: most directly aligned with search-first routing: unified catalog schema, provider aggregation, quality/maintenance scoring, exports, bundles, and shortlist generation. Installation and security claims are not yet production-grade.

## Main Finding

No reviewed repository fully solves the end-to-end problem. The field is converging on three partial layers:

1. Registry and marketplace governance: `iflytek/skillhub`, `anthropics/claude-plugins-official`, `modelcontextprotocol/registry`, and `netresearch/claude-code-marketplace` organize source, ownership, review, and publication.
2. Install and inventory management: `gh skill`, `vercel-labs/skills`, `asm`, and `tech-leads-club/agent-skills` install, update, lock, dedupe, and expose skills across many hosts.
3. Search-first runtime access: `tech-leads-club/agent-skills` MCP, `dmgrok/agent_skills_directory`, FastMCP search transforms, and ACI-style semantic tool discovery narrow a large catalog before full content is loaded.

The missing product layer is a host-facing skill router that combines all three: governed registry, installed/enabled policy, query-time retrieval, compact shortlist, skill activation, permission enforcement, compaction retention, and telemetry feedback.

That means Agentic Coding Lab should not copy any single repo wholesale. The correct architecture is a small local registry plus a retrieval router, borrowing supply-chain and governance ideas from the managers and search/visibility ideas from MCP/tool registries.

## Design Pattern

Use a four-layer system instead of a flat skill directory.

1. Human marketplace

This is the browsing and curation surface. It can be README-heavy and category-rich, but it is not the agent-facing routing index. Good examples are `anthropics/claude-plugins-official`, `github/awesome-copilot`, and `trailofbits/skills`.

2. Machine registry

This is compact, schema-validated, and source-of-truth for routing. It should store normalized skill identity, source, version, digest, category, trigger hints, negative trigger hints, host compatibility, tool/permission needs, risk level, maturity, owner, reviewed commit, and enabled scopes.

3. Search and filter layer

This layer narrows the registry before the LLM sees anything. Use deterministic filters first: project enabled set, host compatibility, language/file globs, trust level, risk approvals, stale-source status, and active workspace facts. Then run lexical or semantic retrieval over compact trigger text.

4. Activation layer

Only the shortlist enters model context. The selected skill loads full `SKILL.md`, then resources/scripts/assets only by explicit reference. Activated skill content must survive compaction and be deduplicated if requested again.

## Router Algorithm

Recommended activation flow:

1. Build a task descriptor from the user request, current files, repo language, command intent, risk level, and explicit skill mentions.
2. Apply hard filters:
   - enabled in current scope;
   - compatible with current host;
   - trusted enough for this workspace;
   - not stale or blocked;
   - risk permissions satisfiable;
   - file globs or language tags match when present.
3. Retrieve top candidates from the compact registry using BM25 plus optional embeddings.
4. Re-rank with deterministic boosts:
   - explicit user mention;
   - project-local over global;
   - recently successful for this repo;
   - lower activation cost;
   - higher maturity/trust label;
   - exact file glob or task tag match.
5. Show the model only a tiny shortlist, ideally 3-7 skills. Include `name`, one-line trigger, negative trigger, risk, and activation cost.
6. Let the model select one or request none. If confidence is low, use a search/refine tool rather than dumping more descriptions.
7. Load the selected skill body and resource manifest. Do not load references until the skill or user asks for them.
8. Log activation evidence: query, shortlist, selected skill, reason, loaded files, result, verification, and whether the skill was useful.

This mirrors FastMCP search transforms and ACI semantic function search more than classic prompt-pack loading.

## Registry Fields

Minimum useful `skills.index.json` shape:

```json
{
  "schema_version": 1,
  "skills": [
    {
      "id": "org.skill-name",
      "name": "skill-name",
      "title": "Human title",
      "description": "Short trigger contract.",
      "when_to_use": ["specific task phrases"],
      "when_not_to_use": ["near misses"],
      "categories": ["coding", "testing"],
      "task_tags": ["frontend", "playwright"],
      "file_globs": ["**/*.tsx", "**/*.css"],
      "hosts": ["codex", "claude-code", "copilot"],
      "source": {
        "type": "git",
        "url": "https://github.com/owner/repo",
        "ref": "commit-or-tag",
        "path": "skills/name"
      },
      "integrity": {
        "folder_sha256": "sha256:...",
        "reviewed_commit": "...",
        "reviewed_at": "2026-05-29"
      },
      "trust": {
        "owner": "team",
        "maturity": "experimental|reviewed|hardened",
        "risk": "read-only|workspace-write|network|exec|secrets",
        "allowed_tools": ["..."]
      },
      "budget": {
        "catalog_tokens": 40,
        "activation_tokens": 1200,
        "resource_tokens_estimate": 5000
      },
      "status": "enabled|disabled|blocked|stale"
    }
  ]
}
```

Keep this index compact. The full `SKILL.md` should not be duplicated into it.

## Ideas To Steal

Use `.agents/skills` as the canonical project directory, then add host-specific symlinks or manifests only where necessary. This reduces duplicate global installs and makes team review feasible.

Separate human catalog from agent catalog. Human catalogs can contain long READMEs, examples, screenshots, and marketing copy. Agent catalogs need terse, validated, budgeted routing metadata.

Make description quality testable. Maintain should-trigger and should-not-trigger query sets for every important skill, like `anthropics/skills` and `agentskills/agentskills` suggest.

Use bounded discovery. Do not recursively scan every `SKILL.md` under examples, tests, fixtures, or vendored dependencies unless an explicit full-depth mode is requested.

Store locks and provenance. Copy Vercel's folder-hash/update model and MCP Registry's publisher-vs-registry metadata split.

Use namespaces and scopes. Resolve collisions with project > workspace > user > marketplace > built-in precedence, but expose the namespace in logs and activation evidence.

Treat risk as routing metadata. Skills that require shell, network, secrets, write access, browser automation, or MCP servers should not compete equally with read-only guidance skills.

Expose search as a tool. A `search_skills(query, filters)` plus `read_skill(id)` pattern lets the model refine instead of carrying a huge skill menu.

Keep activated skill content durable through compaction. Losing a skill mid-task is worse than not activating it, because the agent may continue with partial rules.

Add usage telemetry. Track activations, skips, false positives, false negatives, verification outcomes, token cost, and per-repo success. Use this to prune, disable, merge, or rewrite descriptions.

Add maturity labels. Trail of Bits shows why large skill marketplaces need to distinguish engineered workflow skills from checklist-only prompts and experimental examples.

## Do Not Copy

Do not put every installed skill description in the base prompt. At scale, even descriptions become a second system prompt.

Do not use long prose descriptions as the only routing key. Long descriptions consume context and often increase false positives.

Do not make "installed" mean "enabled". Installed skills are inventory. Enabled skills are the current project's approved routing set.

Do not trust README popularity, stars, or install counts as safety signals. They can seed discovery, not authorization.

Do not rely on `allowed-tools` or frontmatter alone for safety. Host-side policy must enforce permissions.

Do not bulk import marketplaces. Curate by domain, maturity, overlap, and actual activation evals.

Do not expose hidden or dangerous skill resources through generic recursive file reads. Resource loading needs path containment, size limits, and audit logs.

Do not let search transforms become security controls. Search narrows context; policy and permissions still decide what can execute.

## Artifact Candidates

- `skills.index.json`: compact machine registry for routing.
- `skills-lock.json`: installed skill source, ref, path, hash, reviewed commit, and enabled scopes.
- `skill-router` MCP or local tool: `search_skills`, `read_skill`, `list_active_skills`, `record_skill_feedback`.
- `skill-lint`: validate frontmatter, description length, negative triggers, resource paths, tool/risk metadata, stale source refs, and size budgets.
- `skill-trigger-evals/`: per-skill positive and negative activation prompts with expected shortlist/selection.
- `skill-review.md`: review note format for installed third-party skills, analogous to current research repo notes.
- `skill-budget-policy.md`: catalog token budget, shortlist size, activation token cap, resource load cap, and compaction retention rule.
- `skill-maturity-labels.md`: experimental, reviewed, hardened, deprecated, blocked.
- `skill-usage-report.md`: activations, misses, token cost, verification outcome, stale/duplicate candidates.
- Host adapters: Codex, Claude Code, Copilot, Cursor sidecars generated from the same registry.

## Open Questions

- Should routing be mostly deterministic search plus a model decision, or should a classifier model choose skills before the main model sees them?
- What is the right shortlist size for coding tasks: 3, 5, or 7?
- Should high-risk skills require explicit user activation even if the router is confident?
- How should duplicate skills be merged: aliasing, precedence, or skill families with variants?
- What activation telemetry can be stored without leaking user/project secrets?
- How should project teams review marketplace skill updates: automatic hash checks, PRs, or manual review notes?
- Can `when_not_to_use` examples reduce false positives enough to justify their catalog-token cost?

## Current Direction

The local design should not be a larger prompt pack. It should be a small governed registry plus a retrieval router.

The first practical milestone is:

1. Create `skills.index.json` from installed skills.
2. Enforce compact routing metadata and negative triggers.
3. Search the index at runtime instead of loading all descriptions.
4. Load only the selected `SKILL.md`.
5. Log activation evidence and feed it back into description evals.

This directly addresses the user's core concern: even with progressive loading, too many owned skills make selection itself expensive and unreliable.
