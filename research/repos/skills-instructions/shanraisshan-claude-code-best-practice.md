# shanraisshan/claude-code-best-practice

- URL: https://github.com/shanraisshan/claude-code-best-practice
- Category: skills-instructions
- Stars snapshot: 52,321 via GitHub API on 2026-05-11
- Reviewed commit: 4527f4d4e749acd3609329be47b984f668f40052
- Reviewed at: 2026-05-11
- Status: reviewed
- Scope fit: in-scope
- Verdict: Useful as a Claude Code pattern catalog and live example repo, but adopt selectively; several checked-in settings and example agents are too permissive or too demo-specific for a production baseline.

## Why It Matters

This repo is a high-signal map of current Claude Code primitives: `CLAUDE.md`, `.claude/rules`, commands, subagents, skills, hooks, MCP, agent memory, and agent teams. It matters less as a polished framework and more as a concrete specimen of how a Claude Code power user encodes workflows as repo-native files.

For Agentic Coding Lab, the useful part is the shape: commands are user-triggered entrypoints, agents isolate noisy work, skills package reusable domain procedures, hooks enforce or observe lifecycle events, and docs explain context management. The risky part is that the repository mixes reference docs, marketing tables, presentation assets, broad permissions, and small runnable demos in one large repo.

## What It Is

`claude-code-best-practice` is a reference/course repository, not an application. The runnable examples are small Claude Code workflows:

- A root weather workflow in `.claude/commands/weather-orchestrator.md`, `.claude/agents/weather-agent.md`, and `.claude/skills/weather-*`.
- A simple PKT time command/agent/skill triplet in root `.claude`.
- A self-contained `agent-teams/` Dubai time workflow built to demonstrate agent teams.
- Workflow-maintenance commands under `.claude/commands/workflows/` that spawn research agents to refresh README tables and changelogs.
- Python hook scripts under `.claude/hooks/scripts/` and `.codex/hooks/scripts/`.

The rest is mostly best-practice documentation, reports, tips, presentations, images, audio assets, and changelog records.

## Research Themes

- Token efficiency: Strong coverage. The repo documents `/context`, `/compact`, `/clear`, `/rewind`, skill description budgets, on-demand full skill loading, nested skill discovery, and subagents as a way to keep intermediate search output out of the parent context.
- Context control: Strong conceptual model. `CLAUDE.md` explains ancestor/descendant loading, `.claude/rules/markdown-docs.md` and `.claude/rules/presentation.md` show `paths:` lazy loading, and the weather agent uses separate context plus `maxTurns`.
- Sub-agent / multi-agent: Strong. The weather workflow uses Command -> Agent -> Skill, workflow commands dispatch research agents, and `agent-teams/` demonstrates parallel teammate sessions coordinated by a shared task list and a data contract.
- Domain-specific workflow: Strong for docs and demos. The repo turns repeatable maintenance tasks into slash commands and specialized research agents, but most workflows are repo-maintenance workflows rather than general software delivery pipelines.
- Error prevention: Mixed. The weather command has fail-closed sequencing and the weather agent denies direct network tools, but `.claude/settings.json` broadly allows `Bash(*)`, `Edit(*)`, `Write(*)`, `WebFetch(domain:*)`, and `mcp__*`, while `.codex/config.toml` sets `sandbox_mode = "danger-full-access"` and `approval_policy = "never"`.
- Self-learning / memory: Useful example. `weather-agent` has `memory: project` and checked-in `.claude/agent-memory/weather-agent/` files, plus docs explaining user/project/local memory scopes.
- Popular skills: The repo tracks bundled skills such as `simplify`, `batch`, `debug`, `loop`, `claude-api`, and `fewer-permission-prompts`; local example skills include `weather-fetcher`, `weather-svg-creator`, `time-skill`, `agent-browser`, and presentation-specific skills.

## Core Execution Path

The clearest execution path is the weather orchestrator:

1. User runs `/weather-orchestrator`.
2. Command asks the user for Celsius or Fahrenheit with `AskUserQuestion`.
3. Command invokes `weather-agent` through the Agent tool.
4. `weather-agent` is a `sonnet` subagent with `Read` and `Skill` only, `maxTurns: 5`, `permissionMode: acceptEdits`, `memory: project`, and preloaded `weather-fetcher`.
5. `weather-fetcher` contains Open-Meteo URLs and permits `WebFetch(*)`.
6. Agent returns a numeric temperature and unit.
7. Command invokes `weather-svg-creator` through the Skill tool.
8. Skill uses `reference.md` and `examples.md` templates to write `orchestration-workflow/weather.svg` and `orchestration-workflow/output.md`.

This path has useful fail-closed language: the command forbids fetching weather directly, forbids calling the renderer before the fetch returns, and stops if the agent does not return a numeric value. The agent similarly forbids direct network/API calls and tells itself to use `Skill(weather-fetcher)`.

There is one important inconsistency: implementation docs describe `weather-fetcher` as preloaded domain knowledge, not directly invoked, while the current agent file explicitly requires invoking the `weather-fetcher` skill via the Skill tool. That tension is worth fixing before using this as teaching material.

The second execution path is the agent-team Dubai time example:

1. `agent-teams/agent-teams-prompt.md` assigns Command Architect, Agent Engineer, and Skill Designer teammates in parallel.
2. They create a self-contained `.claude` tree under `agent-teams/`.
3. `/time-orchestrator` invokes `time-agent`, waits for `{time, timezone, formatted}`, then invokes `time-svg-creator`.
4. Outputs land in `agent-teams/output/dubai-time.svg` and `agent-teams/output/output.md`.

The workflow-maintenance commands use a different pattern: coordinator commands spawn broad research agents, read prior changelogs while the agents run, then append changelog entries and update badges before offering to apply changes.

## Architecture

The repository is organized around Claude Code file conventions:

- Root `CLAUDE.md`: repository guide, key components, configuration hierarchy, workflow best practices, and git commit rules.
- `.claude/settings.json`: shared permissions, status line, attribution, MCP auto-enable, hook registrations for 27 hook events, and environment settings.
- `.claude/commands/`: user-triggered slash workflows, including weather, time, and README/changelog refresh workflows.
- `.claude/agents/`: specialized subagents for weather, time, presentation maintenance, and research.
- `.claude/skills/`: reusable procedures and reference folders. Some are direct user skills; some are `user-invocable: false` agent-only knowledge.
- `.claude/rules/`: lazy-loaded markdown and presentation rules using `paths:` frontmatter.
- `.claude/hooks/`: Python lifecycle hook handler, config toggles, and sound assets.
- `.claude/agent-memory/`: checked-in project memory for the weather agent.
- `.mcp.json`: project MCP servers for Playwright, Context7, and DeepWiki.
- `.codex/`: separate Codex hook and config example.
- `best-practice/`, `implementation/`, `reports/`, `tips/`: reference docs and claims that explain the hidden config.
- `agent-teams/`: self-contained multi-agent demo.

There are only two Python source files, both hook handlers. No package manifest, app runtime, or automated test suite is present.

## Design Choices

The best design choice is treating workflow primitives as separate boundaries:

- Command files own user interaction and sequencing.
- Agent files own isolated context, tool surface, memory, and model choice.
- Skill folders own reusable instructions, examples, and templates.
- Hook scripts own deterministic lifecycle side effects.
- Rules own path-scoped instruction loading.

The repo repeatedly uses explicit data contracts. The weather command waits for temperature plus unit; the agent-team time command waits for `time`, `timezone`, and `formatted`. This is a good pattern because it gives the next component a checkable interface.

Progressive disclosure is used both in docs and examples. Skills point to `reference.md` and `examples.md`; docs emphasize that skill descriptions enter context first and full content loads on invocation. The repo also records the character-budget risk of verbose skill descriptions.

The hook handler chooses non-blocking behavior: it catches JSON and runtime errors, exits with code 0, supports local config overrides, detects audio players, blocks path traversal in sound names, and can special-case `git commit`. This is appropriate for notification hooks, but not enough for safety enforcement.

The risky design choice is broad permissions. The repo teaches pre-allowing common operations, but the checked-in settings go much further than a conservative default. The development research agent also has `Write`, `Edit`, broad `Bash(*)`, `mcp__*`, and `permissionMode: bypassPermissions` despite its instructions saying read-only.

## Strengths

- Concrete end-to-end examples of Command -> Agent -> Skill instead of only prose.
- Good explanation of when to use commands vs agents vs skills.
- Strong context-management material: subagents for noisy exploration, manual compact hints, rewind over correction, fresh sessions for new tasks.
- Useful monorepo guidance for `CLAUDE.md`, `.claude/rules`, and nested `.claude/skills`.
- Agent memory example is small but real: project-scoped memory files are checked in and tied to the weather agent.
- Hook handler is more than a snippet: it handles platform audio differences, config fallback, log suppression, agent-specific hooks, and safe exits.
- Agent-team example shows parallel work with a shared data contract and self-contained output directory.
- README maps many current Claude Code features in one place, useful for discovery.

## Weaknesses

- Security defaults are not production-safe. Broad allow rules, `enableAllProjectMcpServers: true`, and Codex danger-full-access should not be copied into a team repo.
- Weather skill semantics are inconsistent: docs say `weather-fetcher` is preloaded and not directly invoked, while the agent's current execution contract mandates `Skill(weather-fetcher)`.
- `agent-browser` skill references `references/` and `templates/` files that are not present in the repo, so that skill is not a complete progressive-disclosure example.
- Workflow research agents have write/edit/bypass permissions while their body says they are read-only. That weakens the error-prevention story.
- Most verification is manual or artifact-based. There is no automated harness that runs `/weather-orchestrator` or validates generated SVG/output paths.
- README and reports mix durable patterns with fast-moving Claude Code feature inventory, so stale data risk is high.
- Presentation agents and memory files contain many session-specific notes; useful as a self-learning example but noisy as reusable instruction material.
- The repo is asset-heavy, with many images/audio files that do not help analyze workflow execution.

## Ideas To Steal

- Use Command -> Agent -> Skill as a default shape for multi-step workflows: command orchestrates, agent isolates noisy fetch/research, skill renders or transforms output.
- Put explicit fail-closed guards in command bodies before each irreversible or dependent step.
- Define data contracts between components in plain fields and require validation before proceeding.
- Use `user-invocable: false` for agent-only skills so helper knowledge does not clutter the user menu.
- Pair each skill with small `reference.md` and `examples.md` files; keep `SKILL.md` as the trigger and top-level procedure.
- Use `.claude/rules` with `paths:` for file-type or subsystem-specific instructions instead of one giant `CLAUDE.md`.
- Treat subagents as context garbage collection for exploration-heavy tasks.
- Give long-lived agents project/user/local memory only when they have a clear curation duty.
- Keep hook config local-overridable and fail-open for notification hooks; reserve blocking hooks for explicit safety policies.
- Maintain a short "when to use command/agent/skill" report in our own docs to reduce primitive misuse.

## Do Not Copy

- Do not copy `.claude/settings.json` permissions wholesale. Start from deny/ask-first rules and add allow rules only for specific safe commands.
- Do not copy `.codex/config.toml` with `danger-full-access` and `approval_policy = "never"` into shared repos.
- Do not give read-only research agents `Write`, `Edit`, and `permissionMode: bypassPermissions`.
- Do not rely on prompt text alone for safety when a hook, permission deny rule, or sandbox can enforce it.
- Do not ship skills that reference missing `references/` or `templates/` paths.
- Do not bundle presentation assets, screenshots, and audio into a workflow package unless the workflow actually consumes them.
- Do not force every maintenance command to append changelogs and update badges before reporting if the user asked for read-only research.
- Do not use motivational prompt gimmicks in agent instructions; they add noise without creating a verifiable contract.

## Fit For Agentic Coding Lab

Fit is high as a pattern source and medium as an artifact source.

The repo gives Agentic Coding Lab a useful vocabulary for Claude Code-native workflow design: thin commands, isolated agents, reusable skills, memory scopes, path-scoped rules, hooks, and explicit data contracts. Its best contribution is showing how these pieces compose in checked-in files.

It should not be treated as a baseline config. A lab-quality version would strip broad permissions, separate docs from runnable artifacts, add a test harness for sample workflows, keep examples internally consistent, and enforce missing-reference checks for skill folders.

Best adoption path: extract the weather/time examples into a minimal fixture, keep the command/agent/skill comparison report, and build our own stricter permissions and verification layer around the same concepts.

## Reviewed Paths

- `README.md`: feature map, tips index, workflow tables, and high-level how-to path.
- `CLAUDE.md`: repository guidance, execution contracts, configuration hierarchy, and workflow best practices.
- `.claude/settings.json`: permissions, hooks, MCP enablement, status line, attribution, and environment settings.
- `.mcp.json`: project MCP server configuration.
- `.claude/commands/weather-orchestrator.md`: primary command execution path.
- `.claude/agents/weather-agent.md`: subagent tool restrictions, memory, skill preload, and fail-closed contract.
- `.claude/skills/weather-fetcher/SKILL.md`: API-fetch skill instructions.
- `.claude/skills/weather-svg-creator/SKILL.md`, `reference.md`, `examples.md`: rendering skill and support files.
- `orchestration-workflow/orchestration-workflow.md`, `weather.svg`, `output.md`: documented and generated weather outputs.
- `.claude/agent-memory/weather-agent/MEMORY.md`, `readings.md`: project agent memory example.
- `.claude/commands/time-command.md`, `.claude/agents/time-agent.md`, `.claude/skills/time-skill/SKILL.md`: command/agent/skill comparison fixture.
- `.claude/commands/workflows/**` and `.claude/agents/workflows/**`: research/update workflow orchestration.
- `.claude/agents/development-workflows-research-agent.md`: broad research agent design and permissions.
- `.claude/rules/markdown-docs.md`, `.claude/rules/presentation.md`: path-scoped rule loading.
- `.claude/hooks/scripts/hooks.py`, `.claude/hooks/config/hooks-config.json`, `.claude/hooks/HOOKS-README.md`: hook implementation and docs.
- `.codex/config.toml`, `.codex/hooks.json`, `.codex/hooks/scripts/hooks.py`: Codex-side comparison config.
- `best-practice/claude-skills.md`, `claude-subagents.md`, `claude-commands.md`, `claude-memory.md`, `claude-settings.md`, `claude-mcp.md`: core reference docs.
- `implementation/claude-commands-implementation.md`, `claude-subagents-implementation.md`, `claude-skills-implementation.md`, `claude-agent-teams-implementation.md`: implementation docs for demos.
- `reports/claude-agent-command-skill.md`, `claude-skills-for-larger-mono-repos.md`, `claude-agent-memory.md`, `why-harness-is-important.md`, `llm-day-to-day-degradation.md`: conceptual reports relevant to context, memory, and harness design.
- `tips/claude-thariq-tips-16-apr-26.md`, `tips/claude-thariq-tips-17-mar-26.md`, `tips/claude-boris-13-tips-03-jan-26.md`, `tips/claude-boris-15-tips-30-mar-26.md`: sourced workflow and context-management tips.
- `agent-teams/agent-teams-prompt.md`, `agent-teams/.claude/**`, `agent-teams/output/output.md`: multi-agent demo path and generated artifact.

## Excluded Paths

- `!/`, `presentation/assets/`, `tips/assets/`, `reports/assets/`, `best-practice/assets/`, `implementation/assets/`: binary/image/media-heavy assets; reviewed only where a markdown file directly explained the workflow.
- `.claude/hooks/sounds/**` and `.codex/hooks/sounds/**`: audio notification assets; not relevant to design beyond confirming hook side effects.
- `presentation/**/*.html`: UI slide decks; excluded as presentation-only output except for understanding why presentation agents exist.
- `videos/*.md`: long transcript-derived content; not needed after reviewing the higher-signal tips, reports, and README workflow summaries.
- `tutorial/day0/**` and `tutorial/day1/**`: onboarding/tutorial material unrelated to command/subagent/skill execution design.
- `changelog/**`: generated/append-only maintenance history; sampled indirectly through workflow commands but not deeply reviewed because it is output rather than architecture.
- `LICENSE`, `.gitignore`, `.claude/.gitignore`: checked only for provenance and ignored local/log paths, not analyzed as workflow design.
