# agentsmd/agents.md

- URL: https://github.com/agentsmd/agents.md
- Category: ai-coding-workflow
- Stars snapshot: 21,815 stars, 1,599 forks from GitHub REST API on 2026-05-29
- Reviewed commit: d1ac7f063d20e70015ed6732664049ae4ba9d74e
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: in-scope
- Verdict: High-value portability reference for project-level agent instructions. AGENTS.md is strongest as a shared naming, discovery, and precedence convention for reusable project-instruction contracts; it is weak as an enforcement, safety, or verification system because the repo intentionally keeps the format as plain Markdown and delegates behavior to agent clients.

## Why It Matters

AGENTS.md attacks a common failure mode in AI coding workflows: each agent product historically asked teams to maintain a different rules file, while project-specific instructions were scattered across READMEs, contribution docs, hidden IDE settings, and chat memory. The repo proposes a simple shared contract: put coding-agent guidance in `AGENTS.md`, keep it human-readable, and let compatible agents discover it consistently.

For Agentic Coding Lab, the most reusable pattern is not the website implementation. The important artifact is the project-instruction contract: a predictable file name, Markdown as the interchange format, nearest-file precedence for monorepos, explicit user prompts as the top instruction layer, and examples that normalize build/test/security/PR guidance as agent-facing project context. This gives labs, tools, and teams a low-friction way to publish instructions once and have many agents consume them.

The repo also matters because it exposes the boundary between convention and runtime. The public site says agents can parse the text, choose the nearest file, and run listed checks, but the repository does not implement a loader, parser, schema, validator, sandbox, or test harness for those claims. Any adoption should preserve the portable file contract while adding local enforcement where correctness or safety matters.

## What It Is

`agentsmd/agents.md` is a small Next.js site and README that promote AGENTS.md as an open format for guiding coding agents. The format itself is deliberately minimal: an `AGENTS.md` file is standard Markdown with arbitrary headings. The examples emphasize dev-environment tips, setup commands, code style, testing instructions, PR title format, and security or deployment notes that an agent would need while editing a repo.

The website documents expected usage: add `AGENTS.md` at the repository root, add sections that help agents work effectively, use nested `AGENTS.md` files in large monorepos, and rely on nearest-file precedence so subprojects can override root-level guidance. The FAQ states two important precedence rules: the closest AGENTS.md to the edited file wins among AGENTS.md files, and explicit user chat prompts override everything.

The repository is not a reference implementation for agent-side loading. It contains no CLI, parser, linter, MCP server, package, tests, JSON schema, or compliance suite. Its own root `AGENTS.md` is a practical project instruction file for maintaining the Next.js site, including dev-server guidance, dependency lockfile reminders, TypeScript conventions, and a warning not to run production builds inside interactive agent sessions.

## Research Themes

- Token efficiency: Indirect but useful. AGENTS.md gives agents a predictable context file, reducing repeated discovery of build/test/style instructions. The repo does not define context budgets, output caps, summarization rules, or machine-readable sections.
- Context control: Strong at the convention layer. Root and nested instruction files let projects scope context by directory, and nearest-file precedence gives monorepos a simple override model. There is no implementation showing ancestor traversal, merge order, caching, or conflict diagnostics.
- Sub-agent / multi-agent: No subagent runtime. The contribution is portability across many agent clients, not multi-agent coordination. A shared instruction file can still reduce drift when several agents or workers operate in one repository.
- Domain-specific workflow: General AI coding workflow. Example sections cover setup, package navigation, tests, lint, PR titles, code style, security considerations, large datasets, deployment steps, and local project gotchas.
- Error prevention: Moderate at the instruction-design level. The examples normalize "run relevant checks", "fix test/type errors", and "add or update tests for changed code"; the repo itself has no automated verification, permission boundary, or stale-instruction detection.
- Self-learning / memory: None. The format is living documentation edited by humans or agents, not an autonomous memory store.
- Popular skills: No skill registry. The portable artifact is the Markdown contract itself, plus a compatibility list showing broad ecosystem adoption by coding-agent products and projects.

## Core Execution Path

The intended workflow starts with a repository owner adding `AGENTS.md` at the repo root. The file contains practical instructions an agent needs while making changes: how to install dependencies, locate packages, run tests, follow style rules, format PRs, avoid project-specific pitfalls, and handle security or deployment concerns.

In a monorepo, teams can place additional `AGENTS.md` files inside packages or subprojects. The expected agent behavior is to find the closest applicable file for the file being edited, with that local file taking precedence over broader instructions. User chat instructions remain higher priority than the file content.

During work, compatible agents are expected to parse the Markdown as text, apply the relevant guidance, run listed programmatic checks when appropriate, and fix failures before finishing. The repo does not specify whether agents should load all ancestor files, only the nearest file, or a merged stack. It also does not specify how to handle contradictory instructions beyond the nearest-file and user-prompt precedence statements.

The migration path for existing instruction files is intentionally low ceremony: rename an old agent instruction file to `AGENTS.md` and optionally keep symbolic links for backward compatibility. The FAQ includes short adapter snippets for clients that need explicit configuration, such as Aider and Gemini CLI.

## Architecture

The repository has two layers:

- Public format materials: `README.md`, the landing page, the FAQ, examples, compatibility list, and explanatory sections.
- Website implementation: a small Next.js app with React components, static logo assets, Tailwind-style CSS, package metadata, and a GitHub contributor fetch in `getStaticProps`.

`README.md` is the concise source of the core claim and a sample AGENTS.md structure. `components/CodeExample.tsx` carries the reusable example blocks shown on the site. `components/HowToUseSection.tsx` documents root placement, recommended content categories, extra project instructions, and nested monorepo files. `components/FAQSection.tsx` contains the clearest format semantics: arbitrary Markdown headings, closest-file precedence, user-prompt override, automatic test-command expectation, migration, and client-specific configuration snippets.

`components/CompatibilitySection.tsx` is an adoption signal rather than executable logic. It lists many agent clients and tools that the site positions as compatible with the convention. `components/ExampleListSection.tsx` hard-codes example repositories and links to a GitHub code search for public AGENTS.md usage.

The root `AGENTS.md` doubles as a self-example. It shows how an instruction file can encode operational constraints for an agent working in the repo, including using the dev server instead of production builds to preserve hot module replacement.

## Design Choices

The strongest design choice is using plain Markdown with no required fields. That keeps adoption cheap, lets teams copy existing contributor guidance, and avoids inventing a tool-specific schema. The cost is that agents cannot rely on typed sections, machine-checkable commands, or structured safety metadata.

The second strong choice is naming and placement over configuration. A single predictable filename is easier for agents to discover than many client-specific config paths. Nested `AGENTS.md` files give large repos a familiar scope model similar to local README or editorconfig behavior.

The precedence model is intentionally simple. The closest instruction file wins for edited files, and explicit user chat instructions override file instructions. This is easy to teach, but the repo leaves open important runtime details such as whether broader parent files still apply, how to report conflicts, and how agents should behave when a task touches files covered by multiple nested instruction files.

The examples treat verification as a normal part of project instructions. Instead of putting tests only in CI docs, AGENTS.md examples tell agents which commands to run, when lint/type checks matter, and that changed code should usually have tests updated. This is a useful contract pattern even when the format remains unstructured.

The site also chooses social portability over hard compliance. Compatibility logos, public examples, and migration snippets are meant to drive ecosystem convergence. There is no conformance test ensuring those agents interpret the same file the same way.

## Strengths

- Very low adoption cost: a team can add one Markdown file without installing a package or choosing a vendor-specific rules system.
- Clear project-instruction boundary: AGENTS.md separates agent-only operational detail from human-oriented README material while keeping both in the repository.
- Useful monorepo model: nested files and closest-file precedence let teams scope instructions to packages, languages, or deployment surfaces.
- Portable across clients: the compatibility section and adapter snippets encourage one shared instruction source for many coding agents.
- Good example categories: setup, package navigation, build/test commands, lint/type checks, code style, PR format, security gotchas, and deployment steps cover common agent needs.
- Strong convention for reusable contracts: the file can become a stable interface between repositories, agents, CI harnesses, and project-specific skills.

## Weaknesses

- No reference loader or parser. The repo does not define ancestor traversal, merge behavior, cache invalidation, conflict reporting, or task-to-file scope resolution.
- No schema or validation. Agents and teams cannot automatically detect missing test commands, unsafe shell instructions, stale paths, malformed headings, or contradictory rules.
- Safety is only prose. Security considerations are suggested as content, but there are no boundaries for secrets, destructive commands, network access, prompt injection, untrusted files, or permission prompts.
- Verification semantics are underspecified. The FAQ says agents will attempt relevant checks if listed, but the repo does not define what counts as relevant, how failures are reported, or when checks may be skipped.
- Compatibility is not compliance. The site lists many tools, but the repository does not test whether they implement the same precedence and loading behavior.
- The format can accumulate vague or stale guidance. Because headings are arbitrary Markdown, quality depends on project maintainers and reviewing agents.

## Ideas To Steal

- Standardize a single project-instruction contract file and make agents look there before scanning scattered docs for build, test, style, and safety rules.
- Use nested instruction files for monorepos, with a documented nearest-file precedence rule and explicit handling for tasks that span multiple scopes.
- Keep the base format Markdown for human editability, but add optional local linting around common contract sections such as setup, verification, safety, ownership, generated files, and PR rules.
- Treat AGENTS.md as living operational documentation: update it when an agent discovers a recurring setup trap, flaky command, or local workflow rule.
- Include migration adapters for clients that cannot discover AGENTS.md natively, using symlinks or config snippets while preserving one source of truth.
- Pair portable instructions with a runtime harness. The convention supplies the file contract; a lab system should add loader tests, conflict diagnostics, command allowlists, sandbox policy, and verification reporting.

## Do Not Copy

- Do not rely on Markdown prose alone for high-stakes safety boundaries. Add explicit tool permissions, sandboxing, secret handling, destructive-command rules, and untrusted-input policy in the agent runtime.
- Do not assume all compatible agents implement identical precedence. Test or document the exact loading order for each supported client.
- Do not make every section required in the public format. The repo's adoption advantage comes from being lightweight; stricter schemas should be optional local overlays.
- Do not treat "run tests automatically" as sufficient verification policy. A useful implementation must define command selection, failure handling, skip reasons, and evidence expected in final responses.
- Do not copy long AGENTS.md examples verbatim into every repo. Extract the local contract shape and write project-specific instructions that match the actual build and ownership model.
- Do not let nested files drift silently. A large organization should have a small audit or lint pass for conflicting commands, stale package names, and outdated migration links.

## Fit For Agentic Coding Lab

Fit is high as a convention and contract source, not as an implementation reference. AGENTS.md is the simplest credible shared surface for project instructions that can travel across Codex, Gemini CLI, Aider, IDE agents, hosted coding agents, and future lab tools.

Agentic Coding Lab should adopt the naming and portability principles while adding enforcement around them. A practical local adaptation would define a Markdown contract profile with recommended sections, a deterministic loader for root and nested files, conflict reporting, safety metadata, and a verification summary format. The public AGENTS.md convention should remain the lowest common denominator; stricter behavior can live in a lab harness, skill, or CI check.

The most valuable research takeaway is that project instructions are an interface, not just documentation. Once a repo treats AGENTS.md as a stable interface, skills, subagents, MCP tools, review bots, and CI harnesses can all consume the same local rules instead of re-learning them from chat.

## Reviewed Paths

- `README.md`: core format explanation, sample structure, and local website run instructions.
- `AGENTS.md`: self-hosted project instruction example for the Next.js site, including dev-server, dependency, TypeScript, and command guidance.
- `components/HowToUseSection.tsx`: root placement, recommended content categories, nested monorepo files, and closest-file precedence wording.
- `components/FAQSection.tsx`: required-fields answer, conflict precedence, test-command behavior, migration guidance, and Aider/Gemini CLI configuration snippets.
- `components/CodeExample.tsx`: hero and full sample AGENTS.md examples, summarized for section structure and command categories.
- `components/CompatibilitySection.tsx`: supported-agent list and portability/adoption signal.
- `components/ExampleListSection.tsx`: public example repository cards and GitHub code-search link.
- `components/WhySection.tsx`, `components/AboutSection.tsx`, `components/Hero.tsx`: rationale, stewardship, adoption messaging, and "README for agents" framing.
- `pages/index.tsx`: page composition and GitHub contributor-fetch implementation for example cards.
- `package.json`: project type, scripts, package manager, and dependency surface.
- Git metadata and GitHub REST API response on 2026-05-29: reviewed commit, branch state, stars, forks, update time, license, and repository status.

## Excluded Paths

- `.git/**`: used only through Git commands for commit and branch metadata; not reviewed as source content.
- `public/logos/**`, favicon files, and `public/og.png`: branding and image assets; relevant only as evidence of the compatibility-list presentation.
- `styles/globals.css`, `components/icons/**`, `components/Footer.tsx`, `components/Section.tsx`, `pages/_app.tsx`, `pages/_document.tsx`, `next.config.ts`, `postcss.config.mjs`, `tsconfig.json`, and `next-env.d.ts`: routine website/UI plumbing with little bearing on the AGENTS.md contract.
- `pnpm-lock.yaml`: dependency lockfile; sampled only through package metadata and excluded from workflow conclusions.
- Remote linked documentation for individual compatible agents: not deep-reviewed in this note because the candidate under review is the AGENTS.md convention repo itself, not each client's implementation.
