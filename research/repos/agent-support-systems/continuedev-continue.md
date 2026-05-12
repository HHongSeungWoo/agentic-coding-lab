# continuedev/continue

- URL: https://github.com/continuedev/continue
- Category: agent-support-systems
- Stars snapshot: 33,123 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: cb273098d968906d25ee737b454f0b5f13ea2482
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for source-controlled AI checks and coding-agent workflow enforcement. The best parts are the Markdown check format, GitHub status-check integration, local `cn review` worktree isolation, layered rules, and broad tests. Copy the source-controlled contract and verification shape, but not the broad auto-mode tool access, hosted-platform coupling, or stale command naming.

## Why It Matters

Continue is directly in scope because it treats AI review behavior as source-controlled project material. Checks are Markdown files committed under `.continue/checks/`; agents and rules live in adjacent source-controlled folders; the CLI can run those review agents locally; and the hosted product turns each check into a GitHub PR status check.

This makes the repo a useful example of how an agent-support system can move beyond prompt snippets: it defines check files, resolves them, constrains their review scope to diffs, runs them in isolated worktrees, captures patches, exposes status/check APIs, and backs the workflow with CI and permission tests.

## What It Is

Continue is an open-source AI coding platform with IDE extensions, a CLI, config packages, rules, MCP integration, and hosted services. For this review, the important surface is the source-controlled checks system:

- `.continue/checks/*.md` define PR checks with YAML frontmatter and a body prompt.
- `.continue/agents/*.md` define reusable agents with model, tool, and rule hints.
- `.continue/rules/*.md`, colocated `rules.md`, root instruction files, and config YAML shape the agent system prompt.
- `cn review` runs local review agents against a Git diff and reports pass/fail/error.
- `cn checks` reads hosted check status and accepts or rejects pending suggestions.
- GitHub workflows demonstrate both hosted Continue agent runs and a local reusable agent-check workflow.

## Research Themes

- Token efficiency: The review path narrows context to changed files, diff stats, and a capped diff body. CLI diff context truncates very large diffs around 50 KB, and the prompt repeatedly says to inspect only changed lines. This is pragmatic, but it is truncation rather than a deeper context-compression strategy.
- Context control: Continue has many layered controls: check prompt, agent file, `.continue/rules`, colocated `rules.md`, root instruction files such as `AGENTS.md`/`CLAUDE.md`, config YAML rules, MCP tools, and command-line permission flags.
- Sub-agent and multi-agent workflow: `cn review` resolves multiple checks and runs each in its own worker and temporary worktree. The reusable GitHub workflow also matrices over agent Markdown files. `.continue/prompts/sub-agent-*` shows local sub-agent patterns using nested `cn -p` calls.
- Domain-specific workflow: Example checks cover security audit, stale comments, React best practices, setup scripts, docs sync, dependency security, input validation, error message quality, and test coverage.
- Error prevention: The system combines strict diff-scoping prompts, per-check isolated worktrees, patch capture, GitHub status checks, terminal command classification, permissions, and required CI aggregators.
- Self-learning and feedback: Hosted checks track acceptance/rejection metrics; rejected suggestions feed future prompts, and sensitivity can be tuned. That feedback loop is useful but mostly platform-side rather than fully source-controlled.
- Skill reuse: The `skills/cn-check` skill and docs reference check-writing workflows, but this area shows naming drift: docs mention `/check`, the skill says `cn check`, and current CLI code exposes `cn review` plus `cn checks`.

## Core Execution Path

For local review, `extensions/cli/src/commands/review.ts` computes the diff, resolves review agents, forks one worker per review unless `--fail-fast` is set, and aggregates pass/fail/error results. `resolveReviews.ts` sources checks from explicit `--review-agents`, the Continue Hub API when logged in, and local `.continue/agents/*.md` or `.continue/checks/*.md`.

Each review creates a temporary detached Git worktree. `worktree.ts` applies committed, uncommitted, and untracked user changes into that worktree, commits the initial state with `--no-verify`, lets the agent act there, and captures only the agent-created patch. This is one of the repo's strongest implementation patterns because it allows destructive or noisy agent edits to be reviewed as a patch before touching the user's real working tree.

`reviewWorker.ts` builds a strict review prompt. It tells the agent to review only changed lines, avoid pre-existing issues, make edits only in changed files, and skip general refactors. It then runs the agent in the worktree with tool permission mode set to `auto`. A non-empty patch becomes a failed review; an empty patch becomes pass; worker failure becomes error. `--patch` emits patches and exits nonzero on fail/error, while `--fix` applies patches to the real tree only after `git apply --check`.

For hosted checks, docs describe a GitHub integration that reads `.continue/checks/` from the default branch, turns every check file into a GitHub status check, and displays suggested diffs for accept/reject. The `cn checks` command queries `api/checks/status`, lists check status and diffs, and can accept or reject pending suggestions.

## Architecture

The architecture separates source-controlled definitions, local execution, and hosted orchestration.

Source-controlled definitions live in `.continue/checks`, `.continue/agents`, `.continue/rules`, `.continue/prompts`, `.continue/mcpServers`, root instruction files, and colocated `rules.md`. These files define review intent, allowed tools, applicable rules, prompt snippets, and external tool servers.

Local execution lives mostly under `extensions/cli/src`. It parses commands, resolves agent files, loads config, builds system messages, connects MCP servers, enforces permission policies, computes diffs, creates worktrees, streams model responses, captures patches, and renders reports.

Config and rules are shared through `packages/config-yaml` and `core/config/markdown`. Markdown rules support frontmatter such as `globs`, `regex`, `alwaysApply`, and `invokable`; colocated `rules.md` files apply by path; config YAML can add models, docs, context providers, MCP servers, rules, prompts, and data policies.

Hosted orchestration is represented by docs, `cn checks`, GitHub status APIs, and workflows such as `run-continue-agent.yml`. This layer supplies PR check status, accept/reject flows, feedback metrics, cloud triggers, and Mission Control configuration.

## Design Choices

Checks are plain Markdown with required `name` and `description` frontmatter. This keeps review behavior code-reviewable and easy to author without custom syntax.

Continue makes review agents patch-producing by default. This turns ambiguous "AI review comments" into concrete diffs that can be applied, rejected, or used as failing CI evidence.

The local review runtime isolates each check in a temporary worktree. That allows parallel check execution, clean patch capture, and a safer `--fix` path.

The rule system is layered rather than singular. Project instructions, config rules, `.continue/rules`, prompts, and colocated `rules.md` can all affect behavior. That gives teams precise control, but it also increases precedence complexity.

Tool permissions use policy objects with `allow`, `ask`, and `exclude`; terminal commands also pass through security classification. Agent files can specify tools, but their policy precedence is high enough to override runtime CLI flags.

The product accepts hosted-platform coupling for CI checks. Source-controlled check files are local, but the documented PR status-check loop depends on Continue's GitHub integration and APIs.

## Strengths

- Markdown checks are small, reviewable, version-controlled contracts for agent behavior.
- The local `cn review` path has real engineering behind it: diff resolution, worktree isolation, forked workers, patch capture, fail-fast, JSON output, patch output, and checked patch application.
- The prompt scope is explicit about changed lines, changed files, and pre-existing issues, which directly targets common AI review failure modes.
- Rules are flexible: global rules, `.continue/rules`, config rules, colocated `rules.md`, glob/regex matching, invokable prompts, and agent file references cover many context-control needs.
- The repo has tests for review discovery, agent-file parsing, tool permission behavior, terminal command classification, config unrolling, secret resolution, and rule applicability.
- CI is comprehensive. Main workflows include lint/type/test matrices, fork/dependabot secret gating, all-green aggregator jobs, and CLI smoke/e2e checks.
- Hosted check UX includes status checks, suggested diffs, accept/reject, metrics, and rejection feedback.

## Weaknesses

- There is visible naming and documentation drift. Current CLI code exposes `cn review` and `cn checks`; docs also describe `/check`; `skills/cn-check/SKILL.md` still says `cn check`.
- The docs say checks can live under `.continue/checks/` or `.agents/checks/`, but the reviewed local CLI fallback reads `.continue/agents/*.md` and `.continue/checks/*.md`. I did not find equivalent local `.agents/checks` fallback in `resolveReviews.ts`.
- `reviewWorker.ts` forces tool permission mode to `auto`. In practice this means review agents get broad tool access; high-risk terminal commands that would normally require permission can be allowed, while only commands classified as disabled remain blocked.
- The reusable `.github/workflows/continue-agents.yml` grants `contents: write`, `checks: write`, and `pull-requests: write` by default. That is convenient for autonomous agents but broad for a reusable workflow that discovers Markdown files recursively.
- Hosted checks, feedback metrics, accept/reject state, and trigger configuration depend on Continue's platform. The source-controlled repo alone does not fully reproduce that CI product loop.
- Pass/fail for local review is based on whether the agent produced a patch. That works well for auto-fixable checks but is weaker for evidence-only findings, architectural concerns, or checks where comments should fail CI without edits.
- MCP stdio transports inherit process environment, and remote transports can disable SSL verification through config. Teams need explicit policy around what MCP servers can run in CI.

## Ideas To Steal

- Define AI checks as Markdown files with required frontmatter and a body prompt.
- Prepend a standard diff-scoping prompt that says changed lines only, changed files only for edits, and no pre-existing issues.
- Run each check in a temporary worktree and capture its patch instead of letting it edit the real checkout.
- Keep local review execution separate from hosted status management: `review` for producing patches, `checks` for reading or applying CI check state.
- Add rule files with `globs`, `regex`, `alwaysApply`, and `invokable` controls.
- Store acceptance/rejection feedback and show per-check metrics so teams can tune noisy checks.
- Use a required all-green aggregator job for CI suites with optional/skipped secret-dependent jobs.

## Do Not Copy

- Do not grant review workers full auto-mode tool access by default, especially for PR code.
- Do not ship broad reusable workflow permissions as the easiest default.
- Do not let command names drift across docs, skills, and code.
- Do not make hosted feedback or trigger configuration the only durable enforcement surface.
- Do not base all review failure semantics on patch existence.
- Do not let stdio MCP processes inherit broad CI secrets without an explicit allowlist.

## Fit For Agentic Coding Lab

Fit is high. Continue is one of the clearest source examples of AI review checks as repository artifacts. It is especially useful for designing a coding-agent lab that wants source-controlled rules, CI-enforced agent checks, scoped diff review, and patch-producing automation.

The most applicable patterns are the Markdown check contract, strict scope prompt, isolated worktree execution, patch-first reporting, status-check integration, and rule layering. The main adaptations should be stronger default sandboxing, clearer permission precedence, fully source-controlled trigger configuration, and a failure model that supports both patches and structured findings.

## Reviewed Paths

- `README.md`
- `SECURITY.md`
- `docs/checks/*.mdx`
- `docs/agents/*.mdx`
- `docs/cli/tool-permissions.mdx`
- `docs/guides/run-agents-locally.mdx`
- `docs/customize/deep-dives/rules.mdx`
- `docs/customize/deep-dives/mcp.mdx`
- `docs/customize/deep-dives/development-data.mdx`
- `docs/customize/telemetry.mdx`
- `.continue/checks/*.md`
- `.continue/agents/*.md`
- `.continue/prompts/*.prompt`
- `.continue/rules/*.md`
- `skills/cn-check/SKILL.md`
- `extensions/cli/AGENTS.md`
- `extensions/cli/src/index.ts`
- `extensions/cli/src/commands/checks.ts`
- `extensions/cli/src/commands/review.ts`
- `extensions/cli/src/commands/review/diffContext.ts`
- `extensions/cli/src/commands/review/renderReport.ts`
- `extensions/cli/src/commands/review/resolveReviews.ts`
- `extensions/cli/src/commands/review/reviewWorker.ts`
- `extensions/cli/src/commands/review/worktree.ts`
- `extensions/cli/src/permissions/defaultPolicies.ts`
- `extensions/cli/src/permissions/permissionChecker.ts`
- `extensions/cli/src/services/AgentFileService.ts`
- `extensions/cli/src/services/ToolPermissionService.ts`
- `extensions/cli/src/services/MCPService.ts`
- `extensions/cli/src/services/mcpTransports.ts`
- `extensions/cli/src/systemMessage.ts`
- `extensions/cli/spec/modes.md`
- `extensions/cli/spec/permissions.md`
- `extensions/cli/spec/mcp.md`
- `packages/config-yaml/src/markdown/agentFiles.ts`
- `packages/config-yaml/src/schemas/mcp/index.ts`
- `packages/config-yaml/src/load/unroll.ts`
- `packages/terminal-security/src/evaluateTerminalCommandSecurity.ts`
- `core/config/markdown/loadMarkdownRules.ts`
- `core/config/markdown/loadCodebaseRules.ts`
- `core/llm/rules/getSystemMessageWithRules.ts`
- `core/tools/applyToolOverrides.ts`
- `core/tools/implementations/createRuleBlock.ts`
- `core/tools/implementations/requestRule.ts`
- `core/tools/implementations/readSkill.ts`
- `core/util/sanitization.ts`
- `core/util/sentry/anonymization.ts`
- `.github/workflows/continue-agents.yml`
- `.github/workflows/run-continue-agent.yml`
- `.github/workflows/snyk-agent.yaml`
- `.github/workflows/auto-fix-failed-tests.yml`
- `.github/workflows/cli-pr-checks.yml`
- `.github/workflows/pr-checks.yaml`
- `actions/general-review/**`
- `extensions/cli/src/commands/review/resolveReviews.test.ts`
- `extensions/cli/src/permissions/permissionChecker.test.ts`
- `extensions/cli/src/services/ToolPermissionService.agentfile.test.ts`
- `packages/config-yaml/src/markdown/agentFiles.test.ts`
- `packages/config-yaml/src/__tests__/index.test.ts`
- `packages/config-yaml/src/load/unroll.test.ts`
- `packages/terminal-security/test/terminalCommandSecurity.test.ts`
- `core/config/markdown/ruleCollocationApplication.vitest.ts`

## Excluded Paths

- `core/vendor/**`: vendored third-party transformer code; excluded as non-native implementation material.
- `docs/images/**`, `media/**`, `extensions/cli/media/**`: binary screenshots, videos, and visual assets; not relevant to source-controlled checks or enforcement.
- `gui/**`: large UI application surface; excluded except where CI and rules referenced it because this review targets agent workflow enforcement rather than product UI.
- `extensions/vscode/**` and `extensions/intellij/**`: IDE integration surfaces; sampled only docs/CI context, excluded from deep review because the core check workflow is in CLI/config packages.
- `binary/**`: packaging/distribution support; not relevant to check semantics.
- `packages/continue-sdk/python/api/**`: generated OpenAPI client code; excluded as generated.
- Lockfiles such as `package-lock.json`: dependency snapshots; not reviewed line by line.
- `docs/customize/model-providers/**` and provider-specific docs: useful for model setup but unrelated to checks, permissions, CI enforcement, or agent workflow control.
- Release, changelog, marketplace, and manual sandbox paths: operational or documentation support outside this review scope.
