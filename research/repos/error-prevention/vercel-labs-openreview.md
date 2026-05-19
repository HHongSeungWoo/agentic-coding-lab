# vercel-labs/openreview

- URL: https://github.com/vercel-labs/openreview
- Category: error-prevention
- Stars snapshot: 1,393 (GitHub REST API, captured 2026-05-19)
- Reviewed commit: 672deb21e70e471e0536d5ad7a67c14b8359e97e
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong reference for a self-hosted PR review worker: GitHub webhook, durable workflow, sandboxed repo checkout, LLM tools, and PR comments/commits. Adopt its staged workflow, sandbox boundary, prompt budget controls, and progressive skill loading pattern. Do not copy its current write/push safeguards without tightening them; several implementation bugs and loose approval semantics weaken reliability.

## Why It Matters

OpenReview is a compact implementation of an AI code review bot that runs against real GitHub PRs. It is useful for Agentic Coding Lab because it shows how to turn a PR comment into a durable review job with repository context, command execution, optional code edits, and GitHub feedback.

For error prevention, the important pattern is not just "ask an LLM to review code." The useful pattern is a full execution loop: collect PR thread context, clone the PR branch into an isolated sandbox, expose a small tool surface, force the agent to inspect the diff, let it run project tooling, post findings with file/line context, and clean up the environment.

## What It Is

OpenReview is a Next.js app deployed to Vercel. A GitHub App webhook is handled by `app/api/webhooks/route.ts`, delegated to a `chat` GitHub adapter in `lib/bot.ts`, and then dispatched into a Vercel Workflow in `workflow/index.ts`.

The workflow creates a Vercel Sandbox from the PR branch, installs dependencies, configures `git` and `gh`, runs a Claude Sonnet 4.6 durable agent from `lib/agent.ts`, then commits and pushes any detected modifications. The agent can run bash, read files, write files, load domain skills, and post PR replies.

## Research Themes

- Token efficiency: The agent sees only skill names/descriptions until it calls `loadSkill`. `workflow/steps/run-agent.ts` truncates large tool results to 10,000 characters and stops after total step usage exceeds 200,000 tokens.
- Context control: The main prompt requires `gh pr diff <PR>` as the first action and offers `gh pr view --json files`, but diff selection is model-driven rather than precomputed or chunked by the host.
- Sub-agent / multi-agent: No sub-agent architecture. A single durable agent loops through tools for up to 20 steps.
- Domain-specific workflow: The workflow is tightly shaped around GitHub PR review: mention trigger, PR branch checkout, `gh` commands, inline comments, suggestions, review comments, and optional commits.
- Error prevention: The prompt asks for bugs, security vulnerabilities, performance issues, code quality, missing error handling, and race conditions, with "Don't nitpick style or formatting" as the main noise guard.
- Self-learning / memory: Thread state stores PR metadata in Redis or memory, but there is no long-term learning, repo memory, reviewer calibration, or finding de-duplication layer.
- Popular skills: Bundled skills cover Next.js best practices, Cache Components, Next.js upgrades, React performance, React composition, React Native/Expo, and web design review. Runtime discovery likely ignores skills with multi-line YAML descriptions because `parseFrontmatter` only accepts single-line `description:` values.

## Core Execution Path

1. GitHub sends a webhook to `app/api/webhooks/route.ts`.
2. `getBot()` builds a `Chat` instance with the GitHub adapter, webhook secret, GitHub App credentials, and Redis or in-memory state.
3. `handleMention()` reacts with eyes, collects the full thread, reads PR metadata via Octokit, stores `baseBranch`, `prBranch`, `prNumber`, and `repoFullName`, then starts `botWorkflow`.
4. `botWorkflow()` checks push access, gets a GitHub installation token, creates a shallow Vercel Sandbox clone of the PR branch, installs dependencies, configures Git and `gh`, and extends sandbox time.
5. `runAgent()` discovers `.agents/skills`, creates the durable agent, starts a "Reviewing..." typing status, and streams the LLM/tool loop.
6. The agent prompt tells the model to start with `gh pr diff`, inspect changed files if needed, run linters/tests when asked, post inline comments via `gh api`, use GitHub suggestion blocks for fixes, and always reply.
7. After the agent completes, `hasUncommittedChanges()` checks `git diff --name-only`; if true, `commitAndPush()` runs `git add -A`, commits `openreview: apply changes`, and pushes to the PR branch.
8. Errors are posted back to the thread, and `stopSandbox()` runs in `finally`.
9. A thumbs-up or heart reaction on a bot-authored message starts a new workflow with saved thread state; thumbs-down or confused posts a skip acknowledgement.

## Architecture

The architecture is a thin webhook shell around a durable workflow state machine:

- `app/api/webhooks/route.ts`: Next.js route handler that forwards GitHub webhooks to the chat adapter.
- `lib/bot.ts`: Chat adapter setup, mention handling, reaction handling, thread state, and workflow dispatch.
- `workflow/index.ts`: Ordered orchestration, failure comments, and cleanup.
- `workflow/steps/*`: Workflow steps for GitHub token retrieval, sandbox creation, dependency install, Git configuration, agent execution, dirty-checking, commit/push, comments, typing state, timeout extension, and sandbox stop.
- `lib/agent.ts`: Main system prompt and tool registration.
- `lib/tools/*`: AI SDK tools for bash, read, write, reply, and skill loading.
- `.agents/skills/*`: Domain instruction packs loaded on demand.

There is no separate review planner, deterministic diff filter, rules engine, or finding database. The LLM controls review traversal after the host gives it GitHub CLI access and a starting command.

## Design Choices

OpenReview uses mention-gated execution instead of reviewing every PR update. This keeps cost and noise lower and lets humans provide instructions such as "check for security vulnerabilities" or "run the linter."

It uses a full repository sandbox rather than sending only a diff to the model. That enables commands, dependency installation, codebase exploration, and direct fixes. The cost is a much larger trust and runtime surface.

It treats GitHub CLI as the GitHub integration layer inside the agent. Host code handles setup and authentication, while the prompt teaches the model exact `gh pr diff`, `gh pr review`, and `gh api ... pulls/<PR>/comments` commands.

It keeps specialized knowledge out of the base prompt. The base prompt lists available skills, and `loadSkill` returns full instructions only when the model chooses a matching skill.

It makes code changes an ordinary tool action. The agent can call `writeFile`; the workflow later detects dirty worktree state and pushes a bot commit.

It relies mostly on prompt constraints for review quality. The explicit safeguards are "Don't nitpick style or formatting," require path/line specificity, and ask each issue to include problem, impact, and fix.

## Strengths

The execution path is easy to understand and reuse. Webhook handling, durable workflow steps, sandbox lifecycle, agent loop, and GitHub feedback are separated cleanly.

The sandbox model gives the reviewer real project context and the ability to run verification commands, not just inspect raw patches.

The workflow has basic operational safeguards: missing GitHub App config fails early, push access is checked before work, archived repos are skipped, branch restrictions are inspected, errors are commented back to the PR, and sandbox cleanup runs in `finally`.

Token controls are practical: skill summaries keep the base prompt smaller, large tool outputs are truncated, and the agent has both a 20-step cap and a 200,000-token stop condition.

The prompt is concrete. It names commands, expected output shape, inline comment syntax, suggestion block format, and a starting action.

The built-in skill idea is strong for Agentic Coding Lab: ship reusable review packs with frontmatter metadata and let the agent load detailed instructions only when relevant.

## Weaknesses

`lib/tools/write-file.ts` appears to pass `content` as the path and `path` as the content when calling `writeFileStep(sandboxId, content, path)`. Because `writeFileStep` expects `(sandboxId, path, content)`, direct agent edits are likely broken or can attempt to write to a path made from file contents.

`workflow/steps/has-uncommitted-changes.ts` checks only `git diff --name-only`. It misses untracked files, so new-file-only agent edits would not trigger commit/push even though `commitAndPush()` would have added them.

`lib/skills.ts` parses frontmatter with regexes for single-line `name:` and `description:`. Several bundled skills use multi-line YAML descriptions, so `discoverSkills()` silently drops them. The lockfile advertises more skills than the runtime likely exposes.

The reaction approval flow is loose. A thumbs-up or heart on a bot message restarts the entire workflow with thread history; it does not bind to a specific suggestion, parse the suggested patch, or apply only that reviewed change.

The auto-commit path is broad. If the agent changes files for any reason and `git diff --name-only` is non-empty, the workflow commits and pushes without a host-side policy check for allowed paths, diff size, generated files, or human approval.

Diff selection is not deterministic. The host does not precompute changed files, filter generated files, mark risky files, or provide a reduced diff bundle. The model is told to call `gh pr diff`, but review scope and prioritization are left to the LLM.

Noise control is mostly prompt text. There is no severity schema, duplicate detection, confidence threshold, required reproduction command, or post-processing validator for comments.

`checkBranchRestrictions()` hardcodes the app slug `openreview`. Self-hosted GitHub Apps may have different slugs, so the branch restriction check can reject valid installs or miss intended policy.

Dependency installation runs from the PR branch before review. The sandbox helps, but running package manager install scripts from untrusted PR code is still a meaningful supply-chain surface, especially before strict policy gates are applied.

The README requires `ANTHROPIC_API_KEY`, but `lib/env.ts` validates only GitHub and Redis variables. Missing model credentials will surface later through the AI SDK rather than in the app's explicit config validation.

No tests or examples beyond README usage snippets were present. The implementation has several small bugs that focused unit tests would catch.

## Ideas To Steal

Use a durable PR-review pipeline with explicit stages: trigger, collect PR metadata, preflight permissions, create isolated checkout, install/prepare, run agent, collect output, optionally apply edits, report, cleanup.

Give the agent a concrete GitHub command cookbook rather than abstract "review this PR" instructions. Exact commands lower orchestration ambiguity and make behavior easier to inspect.

Represent skills as small metadata cards in the base prompt, with full instruction bodies loaded by tool call. This is a good pattern for domain-specific review without bloating every run.

Add hard context guardrails around agent tool loops: max steps, aggregate token budget, and large-output truncation.

Separate host-owned operations from model-owned operations. The host owns credentials, sandbox lifecycle, push setup, and cleanup; the model owns exploration and review narrative.

Post user-visible skip/error comments when preflight fails. It converts silent automation failure into actionable PR feedback.

Store thread/PR state so follow-up mentions and reactions can continue a review without rebuilding all metadata from scratch.

## Do Not Copy

Do not allow arbitrary file writes plus automatic push without a host-side change policy. Agentic Coding Lab should require path allowlists/denylists, diff-size caps, generated-file filters, and explicit approval for code modifications.

Do not treat reaction approval as a generic rerun. If reactions are used, bind them to a specific proposed patch or finding ID and apply exactly that artifact.

Do not parse YAML frontmatter with ad hoc regexes. Use a YAML parser and add fixture tests for single-line, multi-line, quoted, and missing fields.

Do not rely on `git diff --name-only` as the only dirty check. Use `git status --porcelain` and classify modified, deleted, renamed, and untracked files.

Do not leave diff selection entirely to the model for high-signal reviews. Precompute changed files, exclude generated/vendor/binary paths, chunk large diffs, and label files by risk.

Do not use prompt-only noise control. Add a structured finding schema with severity, evidence, changed-line anchor, suggested fix, and confidence, then validate before posting.

Do not hardcode app slugs in permission checks. Read the installed app slug from GitHub app metadata or configuration.

Do not install untrusted PR dependencies with scripts enabled unless the sandbox and credentials model are designed for that threat. Prefer `--ignore-scripts` for review-only runs or separate install from privileged GitHub token setup.

## Fit For Agentic Coding Lab

OpenReview is a good in-scope reference for the "PR review worker" shape of error prevention. Its strongest contribution is the end-to-end operational skeleton: webhook trigger, durable execution, sandboxed repo, tool-using review agent, GitHub feedback, and cleanup.

For Agentic Coding Lab, the best adaptation is a stricter version of this design: deterministic diff intake, explicit generated-file exclusion, structured findings, confidence/severity filtering, test-backed tool wrappers, and approval-bound patch application.

It is less useful as a direct quality bar. The repo is beta, compact, and currently lacks tests. Several correctness bugs are exactly the kind of failures an error-prevention system should prevent.

## Reviewed Paths

- `README.md`: Product behavior, setup, usage examples, built-in skill list, and claimed reaction flow.
- `package.json`, `next.config.ts`, `tsconfig.json`, `.oxlintrc.json`, `.oxfmtrc.jsonc`, `.vscode/settings.json`: Runtime stack, workflow plugin, scripts, strict TypeScript, Ultracite/Oxlint/Oxfmt config, and `.agents` lint ignore.
- `app/api/webhooks/route.ts`: Webhook entrypoint.
- `lib/bot.ts`: GitHub adapter setup, mention handling, reaction handling, state storage, and workflow dispatch.
- `lib/agent.ts`: Main LLM prompt, model selection, GitHub review instructions, and tool registration.
- `lib/github.ts`, `lib/env.ts`, `lib/error.ts`: GitHub App auth, environment validation, and error stringification.
- `lib/tools/bash.ts`, `lib/tools/read-file.ts`, `lib/tools/write-file.ts`, `lib/tools/load-skill.ts`, `lib/tools/reply.ts`: Agent tool surface and tool wrapper behavior.
- `workflow/index.ts`: Main durable workflow, skip/error comments, commit decision, and cleanup.
- `workflow/steps/*.ts`: Sandbox lifecycle, dependency install, GitHub token setup, push access checks, agent run, dirty check, commit/push, PR comments, and typing status.
- `skills-lock.json`, `.agents/skills/*/SKILL.md`, selected `.agents/skills/*/rules/*.md`, `.claude/CLAUDE.md`: Skill metadata, bundled instruction packs, and local coding standards. I sampled rule bodies and frontmatter enough to assess runtime loading and review guidance.
- Test/example scan: no dedicated test files, spec files, example app, or docs directory were present; README usage snippets are the only examples.

## Excluded Paths

- `bun.lock`: Generated dependency lockfile. I used it only as evidence of package manager/dependency state, not as design source.
- `.git/**`: Clone metadata, irrelevant to system design.
- `.vscode/settings.json`: Reviewed only as editor/tooling config; excluded from execution-path analysis.
- `app/favicon.ico`, `app/opengraph-image.png`: Binary/static assets, unrelated to review workflow.
- `app/globals.css`: UI styling for the README-rendering site, not part of PR review execution.
- `app/page.tsx`, `app/components/readme.tsx`: UI-only README rendering. Reviewed briefly to confirm they do not participate in webhook/review execution.
- `lib/utils.ts`: Generic UI class-name helper, unrelated to review workflow.
- Most `.agents/skills/*/rules/*.md`: Domain knowledge content is useful as sample skill material, but individual React/Next/React Native rules are not the OpenReview execution mechanism. I sampled representative rules and skill entrypoints rather than treating every rule file as core architecture.
