# luongnv89/claude-howto

- URL: https://github.com/luongnv89/claude-howto
- Category: skills-instructions
- Stars snapshot: 32,300 via GitHub REST API, captured in `research/index.md` on 2026-05-11
- Reviewed commit: b3571e8def64149e21f7440efb9ac844bcb44d2a
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a broad Claude Code how-to and template mine, especially for progressive learning, context controls, hooks, checkpoints, and command/agent/skill packaging; adopt selectively because many concrete examples are tutorial-grade, some safety hooks do not enforce what their names imply, and several configs appear illustrative rather than copy-paste-safe.

## Why It Matters

`claude-howto` is a large, current Claude Code tutorial repository with copy-paste artifacts for slash commands, memory files, skills, subagents, MCP, hooks, checkpoints, plugins, advanced modes, and CLI usage. It matters because it shows how a tutorial author packages Claude Code practices into a numbered curriculum plus ready-to-install templates.

For Agentic Coding Lab, the strongest value is not the examples as production code. The value is the reusable teaching and artifact shape: thin workflow commands, skill folders with support files, isolated subagents, event hooks, permission baselines, checkpoint/rewind patterns, and learner-facing assessment skills. The repo also exposes common failure modes in this space: stale fast-moving feature references, overly generic templates, broad side-effect workflows, and hooks that warn when users may expect them to block.

## What It Is

`claude-howto` is a documentation and tutorial repo, not an app or agent runtime. Root `CLAUDE.md` states that the numbered modules `01-` through `10-` are the product and that scripts exist to validate docs or build an EPUB.

The canonical English module set covers:

- `01-slash-commands/`: legacy command templates such as `/commit`, `/pr`, `/push-all`, `/optimize`, and `/unit-test-expand`.
- `02-memory/`: project, directory, and personal `CLAUDE.md` examples plus memory hierarchy docs.
- `03-skills/`: six example skills with `SKILL.md`, references, templates, and helper scripts.
- `04-subagents/`: role prompts for code review, testing, debugging, performance, documentation, security, and implementation.
- `05-mcp/`: JSON MCP config snippets and docs for GitHub, database, filesystem, and multi-server workflows.
- `06-hooks/`: shell and Python hook examples for safety checks, formatting, security scans, dependency checks, context tracking, logging, and session-end progress.
- `07-plugins/`: three example plugin bundles: PR review, DevOps automation, and documentation.
- `08-checkpoints/`: rewind and branching workflow examples.
- `09-advanced-features/`: planning mode, auto mode, permission modes, background tasks, Monitor, scheduling, remote/web/desktop, and config examples.
- `10-cli/`: Claude Code CLI reference for print mode, sessions, agents, permissions, JSON output, MCP, plugins, and cleanup.

The repo also includes `.claude/skills/self-assessment` and `.claude/skills/lesson-quiz`, which turn the tutorial into interactive learning workflows.

## Research Themes

- Token efficiency: Strong conceptually. The skills guide explains progressive disclosure as metadata, `SKILL.md`, then on-demand resources; MCP docs cover tool search and a 2 KB tool-description cap; advanced docs promote Monitor over polling because it consumes no tokens while streams are quiet; root `CLAUDE.md` includes explicit token-efficiency rules for repo maintenance.
- Context control: Strong. Memory docs cover hierarchy, `@` imports, `.claude/rules`, `claudeMdExcludes`, auto memory, and `--add-dir`; subagent docs emphasize separate context windows, forked contexts, worktree isolation, and subagent memory; checkpoint docs explain summarizing from a selected point.
- Sub-agent / multi-agent: Broad reference coverage, moderate concrete examples. The docs cover clean subagents, forked subagents, background agents, persistent memory, worktree isolation, spawn allowlists, and experimental agent teams. The checked-in subagent examples are mostly single-role prompt files rather than full orchestrated workflows.
- Domain-specific workflow: Good as teaching material. Code review, refactor, documentation, DevOps, PR review, and testing workflows are represented as commands, skills, agents, plugins, and hooks.
- Error prevention: Mixed. Good patterns include `/push-all` secret checks, read-only `secure-reviewer`, refactor stop points, pre-tool destructive-command checks, security scanning, dependency scans, checkpoint recovery, and conservative permission seeding. Weaknesses include non-blocking or incorrectly blocking hooks, broad deployment examples, and illustrative configs with unsafe or outdated permission names.
- Self-learning / memory: Good tutorial coverage. The repo explains project/user/local/auto memory and ships assessment/quiz skills, but it does not provide a mature self-learning agent memory workflow beyond examples.
- Popular skills: Local examples include `code-review-specialist`, `code-refactor`, `claude-md`, `api-documentation-generator`, `brand-voice`, `blog-draft`, `self-assessment`, and `lesson-quiz`. Built-in Claude Code skills are cataloged separately.

## Core Execution Path

The repo's user path is curriculum first, artifact copy second:

1. User reads root `README.md` or `LEARNING-ROADMAP.md`.
2. User chooses a level through the roadmap or runs `/self-assessment`.
3. User works through numbered modules in order: commands, memory, checkpoints, CLI, skills, hooks, MCP, subagents, advanced features, plugins.
4. For each module, user copies example artifacts into `.claude/commands`, `.claude/skills`, `.claude/agents`, `.mcp.json`, or hook settings.
5. User checks understanding with `/lesson-quiz <topic>`.

Representative executable patterns:

- Slash command path: `/commit` injects `git status`, `git diff HEAD`, branch name, and recent commits through `!`command`` substitutions, then asks Claude to create a conventional commit. `/push-all` adds a stronger sequence with explicit secret/large-file/build-artifact checks and requires an explicit `yes` before `git add .`, commit, and push.
- Skill path: `code-review-specialist` loads its `SKILL.md`, optionally reads `templates/review-checklist.md` and `finding-template.md`, and may run metric scripts. `code-refactor` follows six phases: research, test assessment, smell identification, plan creation, incremental implementation, and review.
- Subagent path: `secure-reviewer` is read/search only for security audit, while `implementation-agent` has full read/write/edit/bash/search access. The docs explain that these files install under `.claude/agents/` and can be selected automatically or explicitly.
- Hook path: `pre-tool-check.sh` receives hook JSON on stdin, extracts a Bash command, blocks a small destructive-command set with exit 2, logs warnings, and allows the rest. `security-scan.sh` reads a written file path, scans for common secret patterns, and returns `additionalContext`.
- Verification path: repo maintenance is handled by pre-commit, Python tests under `scripts/tests/`, cross-reference validation, link checks, Mermaid checks, and EPUB generation through `scripts/build_epub.py`.

## Architecture

The architecture is static, file-based, and curriculum-shaped:

- Root docs (`README.md`, `INDEX.md`, `CATALOG.md`, `QUICK_REFERENCE.md`, `LEARNING-ROADMAP.md`) are navigation and feature inventory.
- Numbered module directories are the canonical content and reusable artifact source.
- `.claude/skills/` contains tutorial meta-skills for assessment and quizzes.
- `07-plugins/*/.claude-plugin/plugin.json` manifests describe plugin bundles, with commands, agents, MCP configs, hooks, scripts, and templates alongside each plugin.
- `scripts/` contains validation and EPUB tooling, not product runtime code.
- `.pre-commit-config.yaml` wires lint, type, security, cross-reference, link, Mermaid, and EPUB checks for English and translated docs.
- Translation directories (`vi/`, `zh/`, `ja/`, `uk/`) mirror most canonical content.
- `assets/`, `resources/`, `slides/`, and `local-progress/` support presentation, branding, and offline materials.

There is no central loader, orchestrator, registry, or harness beyond Claude Code's expected filesystem conventions.

## Design Choices

The strongest design choice is progressive curriculum plus copy-paste artifacts. Users can either read concept docs or lift files directly into a Claude Code setup.

The second strong choice is multi-level progressive disclosure. The docs teach keeping skill metadata cheap, loading `SKILL.md` only on trigger, and moving large checklists, references, templates, and scripts into adjacent files.

The third choice is separation by Claude Code primitive. Commands own manual entrypoints, memory owns persistent context, skills own reusable capabilities, subagents own isolated roles and tool surfaces, MCP owns live integrations, hooks own event gates, plugins bundle workflows, checkpoints protect exploration, and CLI docs support automation.

The fourth choice is learner feedback as first-class workflow. `self-assessment` and `lesson-quiz` are practical examples of using skills to guide onboarding, not just coding.

The risky choice is mixing precise, current Claude Code claims with tutorial examples and speculative/illustrative configs. `CATALOG.md`, `09-advanced-features/config-examples.json`, and some module READMEs include fast-moving feature names and settings. They are useful as a current map but should be verified against official docs before being copied into production.

## Strengths

- Very broad coverage of Claude Code primitives in one repo, organized by learning order instead of feature sprawl.
- Good token/context-control explanations: progressive disclosure, skill description budget, MCP tool search, `claudeMdExcludes`, auto memory limits, `/context`, checkpoints, Monitor, and subagent isolation.
- Concrete safety and verification patterns: destructive Bash hook, secret scanner, dependency check, read-only security agent, planning mode, checkpoints, and conservative auto-mode-equivalent permission seeding.
- `claude-md` skill has high-signal CLAUDE.md guidance: under 300 lines, universal applicability, deterministic tools over style rules, no code snippets, and progressive docs.
- Refactor skill encodes useful stop points: test status before refactor, user approval for priorities, one small change at a time, test after each step, stop on red.
- Interactive assessment and lesson quiz skills are reusable onboarding patterns for any agent workflow curriculum.
- Repo-level validation exists through pre-commit, CI docs, cross-reference checks, link checks, Mermaid checks, tests, and EPUB generation.
- `/push-all` is a useful cautionary example for side-effect commands because it requires summary, safety checks, and explicit confirmation.

## Weaknesses

- Many concrete artifacts are shallow templates. Several slash commands and plugin commands are short checklists with little executable rigor.
- Some examples conflict with the repo's own best practices. `claude-md` says to avoid style rules and code snippets in CLAUDE.md, while `02-memory/project-CLAUDE.md` and `directory-api-CLAUDE.md` include extensive style rules, contacts, snippets, and generic standards.
- `06-hooks/pre-commit.sh` exits with code 1 on test failure, but the hook documentation says blocking hook failures require exit 2. In Claude Code hook semantics described by this repo, that script may warn instead of block.
- `07-plugins/pr-review/hooks/pre-review.js` and `devops-automation/hooks/pre-deploy.js` also exit 1 on failure despite being described as prerequisite checks; they may not block if wired as Claude Code command hooks without adaptation.
- `09-advanced-features/config-examples.json` uses illustrative keys and old-looking modes such as `unrestricted` and `confirm`, plus simplified hook syntax like `PreToolUse:Write`; it should not be treated as valid Claude Code settings without verification.
- Plugin examples are mostly skeletal. Manifests have minimal metadata, commands are short prose, agents use lowercase tool names such as `read` and `grep`, and there is no plugin validation test.
- MCP examples use package names such as `@modelcontextprotocol/server-database` and a placeholder filesystem path; these are teaching snippets, not verified integration recipes.
- The repo is large because it includes four translation mirrors and many visual assets, which adds noise for researchers trying to isolate reusable execution patterns.

## Ideas To Steal

- Structure agent-training material as a numbered curriculum plus installable examples; users learn one primitive at a time and can copy artifacts as they go.
- Use assessment skills to turn documentation into an adaptive onboarding path.
- Use quiz skills with a question bank to verify tutorial comprehension after each module.
- Teach skills with the three-level loading model: metadata always loaded, `SKILL.md` on trigger, support files on demand.
- Keep side-effect commands user-invoked only and require explicit confirmation before broad git mutations.
- Give security review agents read/search-only tools by default.
- Add `claudeMdExcludes` and path-specific `.claude/rules` guidance for monorepos to prevent context bloat.
- Prefer Monitor/event streams over polling loops for long-running waits.
- Provide conservative permission seeding scripts that start read-only and add edits/tests/git/packages only through explicit flags.
- Pair checkpoint docs with concrete branching examples so users learn to compare approaches instead of pushing through bad context.

## Do Not Copy

- Do not copy `config-examples.json` into `.claude/settings.json` as-is; treat it as pseudocode and verify every key.
- Do not rely on hook scripts that exit 1 for blocking safety gates; use the documented exit 2 convention and structured hook output.
- Do not copy plugin examples as production plugins without adding valid manifests, exact tool names, hook configs, tests, and versioned dependencies.
- Do not put broad style rules, personal contacts, and long JSON response examples into always-loaded `CLAUDE.md` files; use deterministic tooling and progressive docs.
- Do not give deployment examples broad Kubernetes write access without explicit environment targeting, dry-run, approval, rollback, and audit logs.
- Do not assume tutorial MCP package names or placeholder endpoints exist; verify real server packages and auth behavior.
- Do not use `.claude/commands/*.md` as the primary new pattern when a skill folder would provide invocation control, support files, and progressive loading.
- Do not treat current feature inventory tables as stable API; fast-moving Claude Code commands and settings need date-stamped verification.

## Fit For Agentic Coding Lab

Fit is conditional but useful. The repo is too broad and tutorial-oriented to serve as a production baseline, but it is a strong pattern mine for skills-instructions research. It gives Agentic Coding Lab examples of how to teach and package context control, skill templates, subagent roles, hook safety, checkpoint workflows, permission baselines, and verification culture.

Best adoption path: extract the `claude-md`, `code-refactor`, `self-assessment`, `lesson-quiz`, `pre-tool-check`, `security-scan`, checkpoint examples, and Monitor guidance into stricter lab artifacts. Pair them with a validation harness that catches invalid hook exits, missing support files, stale settings keys, broad permissions, and unverified MCP package names.

## Reviewed Paths

- `/tmp/myagents-research/luongnv89-claude-howto/README.md`: project purpose, learning path, installation snippets, feature overview.
- `/tmp/myagents-research/luongnv89-claude-howto/CLAUDE.md`: repo maintenance rules, quality gates, architecture map, token-efficiency rules.
- `/tmp/myagents-research/luongnv89-claude-howto/INDEX.md`: full file/component inventory.
- `/tmp/myagents-research/luongnv89-claude-howto/CATALOG.md`: command, permission, skill, subagent, MCP, hook, plugin, and memory feature catalog.
- `/tmp/myagents-research/luongnv89-claude-howto/LEARNING-ROADMAP.md`: guided curriculum and self-assessment path.
- `/tmp/myagents-research/luongnv89-claude-howto/QUICK_REFERENCE.md`: install commands and use-case matrix.
- `/tmp/myagents-research/luongnv89-claude-howto/01-slash-commands/README.md`, `commit.md`, `pr.md`, `push-all.md`, `optimize.md`, `generate-api-docs.md`, `setup-ci-cd.md`, `unit-test-expand.md`, `doc-refactor.md`: command model, arguments, dynamic context, and workflow templates.
- `/tmp/myagents-research/luongnv89-claude-howto/02-memory/README.md`, `project-CLAUDE.md`, `directory-api-CLAUDE.md`, `personal-CLAUDE.md`: memory hierarchy, rules, imports, auto memory, and memory templates.
- `/tmp/myagents-research/luongnv89-claude-howto/03-skills/README.md`, `code-review/SKILL.md`, `code-review/templates/*`, `code-review/scripts/analyze-metrics.py`, `refactor/SKILL.md`, `refactor/templates/refactoring-plan.md`, `refactor/scripts/*`, `claude-md/SKILL.md`, `doc-generator/SKILL.md`, `doc-generator/generate-docs.py`: skill structure, progressive disclosure, review/refactor/context templates, and helper scripts.
- `/tmp/myagents-research/luongnv89-claude-howto/04-subagents/README.md`, `code-reviewer.md`, `secure-reviewer.md`, `test-engineer.md`, `implementation-agent.md`, `debugger.md`, `performance-optimizer.md`, `clean-code-reviewer.md`, `documentation-writer.md`: subagent configuration, tool surfaces, role prompts, memory/worktree/fork/team docs.
- `/tmp/myagents-research/luongnv89-claude-howto/05-mcp/README.md`, `github-mcp.json`, `multi-mcp.json`: MCP transport, OAuth, tool search, resources, scopes, and example configs.
- `/tmp/myagents-research/luongnv89-claude-howto/06-hooks/README.md`, `pre-tool-check.sh`, `security-scan.sh`, `pre-commit.sh`, `dependency-check.sh`, `validate-prompt.sh`, `format-code.sh`, `context-tracker.py`, `context-tracker-tiktoken.py`, `session-end.sh`: hook events, types, JSON I/O, exit codes, and concrete hook scripts.
- `/tmp/myagents-research/luongnv89-claude-howto/07-plugins/README.md`, `pr-review/**`, `devops-automation/**`, `documentation/**`, including hidden `.claude-plugin/plugin.json` manifests: plugin structure, bundle examples, manifests, commands, agents, hooks, MCP configs, scripts, and templates.
- `/tmp/myagents-research/luongnv89-claude-howto/08-checkpoints/README.md`, `checkpoint-examples.md`: checkpoint/rewind options, branching workflows, limitations, and context monitoring.
- `/tmp/myagents-research/luongnv89-claude-howto/09-advanced-features/README.md`, `planning-mode-examples.md`, `config-examples.json`, `setup-auto-mode-permissions.py`: planning, auto mode, Monitor, scheduling, permission modes, config snippets, and safe permission seeding.
- `/tmp/myagents-research/luongnv89-claude-howto/10-cli/README.md`: CLI packaging, print mode, sessions, agents, permissions, output formats, MCP, plugins, cleanup, and automation flags.
- `/tmp/myagents-research/luongnv89-claude-howto/.claude/skills/self-assessment/SKILL.md`, `.claude/skills/lesson-quiz/SKILL.md`, `.claude/skills/lesson-quiz/references/question-bank.md`: interactive learning and quiz skill patterns.
- `/tmp/myagents-research/luongnv89-claude-howto/scripts/README.md`, `check_cross_references.py`, `check_links.py`, `check_mermaid.py`: docs validation and EPUB support.
- `/tmp/myagents-research/luongnv89-claude-howto/.pre-commit-config.yaml`, `.github/TESTING.md`: local and CI quality-gate descriptions.
- `/tmp/myagents-research/luongnv89-claude-howto/docs/ROADMAP-20260401.md`, `docs/TASKS-20260401.md`, `STYLE_GUIDE.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`: sampled for maintenance context and scope.

## Excluded Paths

- `/tmp/myagents-research/luongnv89-claude-howto/.git/**`: VCS internals; only commit SHA and latest commit metadata were needed.
- `/tmp/myagents-research/luongnv89-claude-howto/vi/**`, `zh/**`, `ja/**`, `uk/**`: translated mirrors of the canonical English docs and examples; excluded from deep review after confirming they duplicate the same module structure.
- `/tmp/myagents-research/luongnv89-claude-howto/assets/**`, `resources/**`, root logo files, and `claude-howto-logo.png`: logo, favicon, icon, and design assets; not part of reusable agent workflow logic.
- `/tmp/myagents-research/luongnv89-claude-howto/02-memory/*.png`, `01-slash-commands/pr-slash-command.png`: screenshots; useful for tutorial UX but not needed for instruction-system analysis.
- `/tmp/myagents-research/luongnv89-claude-howto/slides/*.pdf`: presentation-only binary assets; excluded because the research focus is repo-native commands, skills, hooks, agents, and templates.
- `/tmp/myagents-research/luongnv89-claude-howto/local-progress/index.html`: UI-only local progress tracker; excluded as unrelated to reusable coding-agent instructions.
- `/tmp/myagents-research/luongnv89-claude-howto/coverage.xml`: generated test coverage output; not architecture or template source.
- `/tmp/myagents-research/luongnv89-claude-howto/RELEASE_NOTES.md`, translated release notes, and long changelog mirrors: sampled only for version context; excluded from deep pattern analysis because they are history/output artifacts.
- `/tmp/myagents-research/luongnv89-claude-howto/resources/INDEX.txt`, `MANIFEST.txt`, `resources/README.md`, `resources/QUICK-START.md`, `resources/DESIGN-SYSTEM.md`: packaging/branding support; lower signal than root and numbered-module docs.
- `/tmp/myagents-research/luongnv89-claude-howto/scripts/tests/**`, `scripts/build_epub.py`, `scripts/sync_translations.py`: acknowledged as validation/build support; not deeply reviewed because the task focus was Claude Code how-to patterns rather than EPUB generation internals.
- `/tmp/myagents-research/luongnv89-claude-howto/prompts/remotion-video.md` and `claude_concepts_guide.md`: ancillary prompt/guide material; excluded after canonical module docs covered the relevant concepts.
- `/tmp/myagents-research/luongnv89-claude-howto/LICENSE`, `CODE_OF_CONDUCT.md`, `.github/ISSUE_TEMPLATE/**`, `.github/FUNDING.yml`, and legal/community metadata: not relevant to execution path or reusable agent instructions.
