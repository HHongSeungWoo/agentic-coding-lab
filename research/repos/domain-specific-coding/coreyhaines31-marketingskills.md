# coreyhaines31/marketingskills

- URL: https://github.com/coreyhaines31/marketingskills
- Category: domain-specific-coding
- Stars snapshot: 30,989 (GitHub REST API repository search, captured 2026-05-29)
- Reviewed commit: 692b76118c6b379f89c0fba987a228a40f58b418
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Strong pattern source for domain skill packaging, shared domain context, source-lineage requirements, compliance guardrails, and cross-agent skill distribution. Fit is conditional because most workflows are marketing advisory workflows rather than coding workflows, and the repository's evals, tool integrations, and verification remain mostly packaging-level rather than executable end-to-end harnesses.

## Why It Matters

`marketingskills` shows how a broad non-code domain can be decomposed into installable agent skills without becoming one giant prompt. It covers conversion optimization, copywriting, SEO, AI search, analytics, ads, prospecting, cold email, product marketing, pricing, customer research, RevOps, sales enablement, SMS, image/video marketing, and related growth workflows.

For Agentic Coding Lab, the strongest lesson is not marketing content itself. It is the packaging pattern: a common `SKILL.md` shape, trigger-rich descriptions, shared product context, reference files loaded on demand, task-specific output formats, local eval specs, install paths for multiple agent hosts, and a registry that maps domain workflows to tools, MCP options, CLIs, and integration docs.

## What It Is

The reviewed checkout contains 42 Agent Skills under `skills/`, one eval file per skill, 85 skill reference files, 64 zero-dependency Node.js CLI files under `tools/clis/`, and 93 integration guides under `tools/integrations/`. The root README advertises compatibility with Claude Code, OpenAI Codex, Cursor, Windsurf, SkillKit, and hosts that support the Agent Skills spec.

The repo is both an Agent Skills pack and a Claude Code plugin marketplace. `.claude-plugin/marketplace.json` points to a single `marketing-skills` plugin, while `.claude-plugin/plugin.json` exposes `"skills": "./skills"` at version `2.2.0`. Installation paths include `npx skills add coreyhaines31/marketingskills`, Claude `/plugin marketplace add`, manual copy to `.agents/skills/`, git submodule, fork/customize, and SkillKit.

The pack is content-first. There is no application runtime, root package manifest, or host-side dispatcher. A few workflows include executable helpers through standalone CLIs, but most domain behavior is expressed as Markdown instructions, reference docs, and static eval specifications.

## Research Themes

- Token efficiency: Good progressive disclosure. Each skill keeps its main `SKILL.md` under 500 lines, and larger bodies such as platform specs, compliance details, tool references, templates, and experiment lists live in `references/`. The README and sync script keep a compact catalog table instead of requiring users to inspect all skills.
- Context control: Strong domain memory pattern. `product-marketing` creates `.agents/product-marketing.md`, and nearly every other skill checks `.agents/product-marketing.md`, `.claude/product-marketing.md`, and legacy filenames before asking repeated product/audience questions.
- Sub-agent / multi-agent: Minimal. The repo does not implement subagents, worker manifests, or merge/judge phases. Workflows sometimes branch by mode, platform, or motion, but execution remains single-agent and prompt-directed.
- Domain-specific workflow: Strong. Skills encode concrete marketing workflows: CRO audits, Google RSA generation, prospect scoring, competitor profiles, customer research synthesis, SEO/AI SEO audits, lifecycle emails, SMS compliance, lead magnets, launch planning, pricing, RevOps, and sales enablement.
- Error prevention: Moderate to strong at prompt level. Prospecting, SMS, ads, SEO, competitor profiling, and customer research include compliance checks, source requirements, character limits, confidence labels, and "common mistakes" lists. Enforcement is mostly instructions rather than a runtime gate.
- Self-learning / memory: Limited to shared product context and durable task artifacts. There is no feedback loop that updates skills from outcomes, no repo-local memory database, and no adaptive retrieval beyond references.
- Popular skills: Most transferable patterns are in `product-marketing`, `prospecting`, `competitor-profiling`, `customer-research`, `ads`, `seo-audit`, `ai-seo`, `analytics`, `cro`, `copywriting`, `ab-testing`, `sms`, `video`, and `free-tools`.

## Core Execution Path

1. A user installs all or selected skills with `npx skills`, Claude plugin commands, SkillKit, manual copy, submodule, or fork.
2. The agent host discovers skills by `SKILL.md` frontmatter. Descriptions include use cases, trigger phrases, and related-skill boundaries.
3. For a new project, the `product-marketing` skill creates `.agents/product-marketing.md` with product overview, audience, personas, pain points, competitors, differentiation, objections, customer language, brand voice, proof points, and goals.
4. Task skills read product context first, ask only for missing information, then choose a domain framework or branch. Examples: `prospecting` chooses SaaS, B2B, or Local SMB; `customer-research` chooses existing-asset analysis or online research; `competitor-profiling` chooses quick scan or deep profile.
5. Skills route heavy details to reference files. For example, `prospecting` points to branch references and compliance/data-source docs, while `ads` has a mandatory Google RSA output spec and references conversion tracking/tool guides.
6. Tool-backed workflows use `tools/REGISTRY.md` and per-tool integration docs to choose APIs, MCPs, CLIs, SDKs, or Composio. The standalone CLIs output JSON and commonly support `--dry-run`.
7. Evidence-heavy workflows require durable artifacts. `competitor-profiling` saves raw scrapes, SEO responses, and review data under dated `competitor-profiles/raw/...` folders before synthesis. `prospecting` requires source URLs, collection dates, confidence labels, and deliverability checks before outreach lists. `customer-research` requires source, date, verbatim quotes, context, sentiment, and confidence levels.
8. Local quality checks are packaging-oriented: `validate-skills.sh` validates frontmatter, names, descriptions, and line counts; GitHub Actions validate changed `SKILL.md` files and sync README/plugin manifests.

## Architecture

The architecture is a static skill corpus with supporting tool docs:

- `README.md`: positioning, skill dependency diagram, skill catalog, install options, upgrade notes, usage examples, and category map.
- `AGENTS.md` plus `CLAUDE.md` symlink: contributor and agent instructions, Agent Skills spec constraints, writing style, tool registry guidance, update-check policy, and host-specific notes.
- `CONTRIBUTING.md`: new skill structure, naming rules, testing expectations, and PR checklist.
- `VERSIONS.md`: version table and release notes for all skills.
- `.claude-plugin/marketplace.json`: Claude plugin marketplace metadata and plugin source.
- `.claude-plugin/plugin.json`: installable plugin metadata with `"skills": "./skills"`.
- `skills/<skill>/SKILL.md`: required runtime instructions and frontmatter.
- `skills/<skill>/references/`: optional deeper guidance, templates, specs, compliance docs, and examples.
- `skills/<skill>/evals/evals.json`: static prompt, expected-output, and assertion cases; 263 cases total across 42 skills.
- `tools/REGISTRY.md`: broad tool catalog with API/MCP/CLI/SDK/guide columns and category recommendations.
- `tools/integrations/*.md`: per-tool setup, auth, operations, MCP/API/CLI notes, pricing/rate-limit caveats, and relevant skills.
- `tools/clis/*.js`: zero-dependency Node 18+ CLIs for marketing platforms.
- `tools/composio/*.md`: Composio MCP setup and toolkit mapping for OAuth-heavy tools.
- `.github/workflows/validate-skill.yml`: validates changed skills on PR/push through `Flash-Brew-Digital/validate-skill@v1`.
- `.github/workflows/sync-skills.yml` and `.github/scripts/sync-skills.js`: regenerate README skill table, strip invalid marketplace skill arrays, and sync `plugin.json` version to marketplace metadata.
- `validate-skills.sh` and `validate-skills-official.sh`: local validation scripts; the first is Bash-specific, the second installs the official `skills-ref` validator.

## Design Choices

The most important design choice is using `product-marketing` as shared domain memory. Instead of making every marketing skill rediscover ICP, positioning, objections, and proof points, the pack creates a canonical `.agents/product-marketing.md` and keeps `.claude` fallbacks for older Claude installs. This is a simple transferable pattern for any domain where repeated tasks depend on the same business context.

The second major choice is trigger-rich frontmatter. Descriptions are long enough to include casual user phrases, formal domain terms, and boundary redirects to related skills. This helps host-side skill selection and reduces accidental use of the wrong domain module.

The third choice is progressive disclosure. Main skills stay concise, while references hold detailed specs such as SMS TCPA/A2P guidance, ASO platform specs, prospecting compliance, competitor profile templates, AB test sample-size guidance, AI video prompting, and ad platform limits.

The fourth choice is separating domain workflow instructions from tool capability discovery. Skills tell the agent what to do; `tools/REGISTRY.md`, integration docs, Composio docs, and CLIs tell it how to reach external systems. That makes the skill layer portable across agents with different tool availability.

The fifth choice is cross-agent compatibility. The repo uses `.agents/skills` as the default install target, keeps `.claude/skills` compatibility, provides a Claude plugin manifest, mentions Codex/Cursor/Windsurf/SkillKit in docs, and explicitly tells authors not to put Claude-only dynamic command injection inside cross-agent `SKILL.md` files.

The sixth choice is compliance as workflow material, especially in prospecting, SMS, ads, SEO, and competitor research. The strongest examples define what data may be gathered, where raw evidence should be stored, how confidence is assigned, and which sources or scraping behaviors are forbidden.

## Strengths

- Broad and coherent domain taxonomy. The 42 skills cover a real marketing operating model rather than isolated prompt snippets.
- Strong shared-context pattern through `.agents/product-marketing.md`, with backward-compatible `.claude` and legacy filename checks.
- Good workflow boundaries. Skills frequently redirect adjacent tasks to the right skill, such as `ads` -> `ad-creative`, `cro` -> `signup`, `prospecting` -> `cold-email`, and `competitor-profiling` -> `competitors`.
- Evidence handling is unusually concrete for a marketing skill pack. Competitor profiles require raw scrape/SEO/review folders; prospecting requires source URL plus date; customer research requires verbatim quotes, source dates, frequency, intensity, and confidence.
- Compliance guidance is practical rather than decorative. Prospecting draws a line between manual platform discovery and extraction from a business's own site; SMS covers consent, STOP/HELP, A2P 10DLC, and jurisdiction differences; ads includes hard RSA character limits and medical/CFM constraints.
- Cross-host packaging is mature for a content repo: `.agents` default, Claude plugin manifests, SkillKit support, manual copy/submodule path, and guidance for Codex-compatible skill content.
- Static eval coverage is broad. Every skill has an `evals/evals.json` with realistic prompts, expected behaviors, and assertions; total reviewed count was 263 cases.
- Tooling surface is extensive. The registry plus 93 integration guides and 64 CLI files give agents a decision surface for APIs, MCP servers, CLIs, SDKs, Composio, and manual fallbacks.
- Manifest sync automation reduces catalog drift. The sync script derives the README skills table from `skills/`, updates marketplace skill count, removes invalid explicit skill arrays, and syncs plugin version from marketplace metadata.
- Local validation passed with `bash validate-skills.sh`: all 42 skills met the repository's frontmatter/name/description/line-count checks.

## Weaknesses

- Coding fit is indirect. Some skills touch implementation work (`analytics`, `schema`, `free-tools`, `programmatic-seo`, CLIs), but most workflows produce marketing strategy, copy, research, or campaign artifacts rather than code changes or coding-agent verification loops.
- The eval files are specifications, not an executable harness. There is no reviewed runner that feeds prompts to a model, checks assertions, or blocks regressions across all 263 cases.
- CI coverage is narrow. The reviewed workflow validates changed `SKILL.md` files and syncs catalog metadata, but it does not run evals, validate all references, syntax-check CLIs, or test integration docs.
- Verification scripts have rough edges. `validate-skills.sh` is Bash-specific, so `sh validate-skills.sh` fails despite the repo otherwise being shell-light. `validate-skills-official.sh` is path-sensitive because it changes directories during dependency install and then returns using `dirname "$0"`.
- Tool and MCP claims are mostly documentation-level. The registry identifies MCP availability and integration options, but the repo does not ship MCP server configs, contract tests, or live auth checks for those integrations.
- The zero-dependency CLIs vary in safety ergonomics. Many are useful JSON wrappers, but dry-run previews often still require credential environment variables because token checks happen before command dispatch.
- Temporal facts are volatile. AI model names, platform character limits, pricing, OAuth/MCP availability, app-store policies, Google AI search behavior, and compliance summaries can age quickly. The repo has `VERSIONS.md`, but most skills do not enforce live official-doc lookup before advising.
- Some artifact writes are prompt-managed rather than host-enforced. Skills may create `.agents/product-marketing.md`, `competitor-profiles/`, CSVs, or other outputs in the user's project, but there is no common overwrite policy, owned-output policy, or permission gate.
- Documentation counts drift in small places. For example, `AGENTS.md` says `tools/clis/` contains 51 tools, while the reviewed checkout contains 64 `.js` CLIs.

## Ideas To Steal

- Use a foundational domain-context skill as shared memory. For coding domains, this could be `project-context.md`, `architecture-context.md`, or `domain-model.md`, read by all downstream skills before asking questions.
- Put trigger phrases and boundary redirects in every frontmatter description. Selection quality depends heavily on description quality.
- Keep `SKILL.md` under a hard line budget and move domain detail into named `references/` files.
- Pair every workflow skill with local eval prompts, expected behaviors, and assertion lists, even before a full automated harness exists.
- Require source lineage for research-heavy agent work: source URL, capture date, raw artifact path, confidence level, and clearly labeled inference.
- Use branch-specific workflow forks when a domain has different operating modes. `prospecting` does this well with SaaS, B2B, and Local SMB branches.
- Encode output contracts directly in skills: tables, CSV columns, profile folders, sidecar artifacts, required counts, character limits, and final checklist.
- Maintain a tool registry separate from skills. Skills should reference capabilities without inlining every API operation.
- Ship small zero-dependency helper CLIs where platform APIs are repetitive and agent-host tools are inconsistent.
- Add manifest sync automation so catalog tables and plugin metadata are generated from the skill directory rather than hand-maintained.
- Document host-specific affordances separately from cross-agent skill files. The repo's warning against Claude-only `!command` injection in portable `SKILL.md` files is a good compatibility rule.

## Do Not Copy

- Do not copy marketing facts, AI model lists, platform specs, pricing, or compliance summaries into durable lab skills without a freshness policy and official-source check.
- Do not treat static eval JSON as sufficient verification. Add an executable runner, fixtures, assertion checks, and CI gating before relying on evals for quality.
- Do not expose external API/CLI wrappers without consistent dry-run behavior, redaction, auth checks, and syntax tests in CI.
- Do not rely only on prompt text to enforce artifact-write boundaries. Define owned output paths, overwrite rules, and permission requirements at the host/workflow layer.
- Do not label a tool as MCP-ready in a registry unless there is enough setup detail, contract shape, and failure behavior for an agent to use it safely.
- Do not import all 42 skills into a coding-agent system. Curate the patterns and the coding-adjacent skills; most marketing copy workflows are not directly useful for code review or implementation.
- Do not copy broad source-lineage guidance without adapting it to the legal and privacy profile of the target domain.
- Do not let README, manifest, and contributor docs diverge on counts or capabilities; add consistency checks for generated docs.

## Fit For Agentic Coding Lab

Fit is conditional but worthwhile. The repo is not a coding-agent harness, yet it is one of the better examples of packaging a broad business domain into cross-agent skills with shared context, progressive disclosure, reference docs, eval specs, and tool boundaries.

Best direct adaptations:

- A reusable "domain skill pack" template with `SKILL.md`, `references/`, `evals/`, optional `scripts/`, and optional `assets/`.
- A foundational context skill that creates a canonical project/domain context file consumed by all other skills.
- An evidence-artifact policy for research skills: raw data first, dated snapshot folders, source URLs, confidence labels, and inference labels.
- A tool registry pattern that separates tool discovery from domain workflow instructions.
- A cross-host compatibility checklist for Codex, Claude, Cursor, Windsurf, and generic Agent Skills hosts.
- Static eval specs as seed data for a future automated skill-evaluation harness.

Less direct fits:

- Marketing copy, campaign strategy, and growth playbooks should not be copied into Agentic Coding Lab unless the lab explicitly supports marketing-agent workflows.
- The external marketing CLIs are useful examples of lightweight wrappers, but their endpoint coverage and auth behavior need stronger tests before becoming a general lab pattern.
- Compliance language is useful structurally, but legal content must be rewritten and kept current for any new domain.

## Reviewed Paths

- `README.md`: skill catalog, dependency diagram, install options, upgrade path, usage examples, and category map.
- `AGENTS.md` and `CLAUDE.md`: Agent Skills spec rules, contributor guidance, tool integration guidance, cross-agent compatibility notes, and update-check policy.
- `CONTRIBUTING.md`: new-skill workflow and quality checklist.
- `VERSIONS.md`: version table, release history, current `2.2.0` notes, and tool/eval changes.
- `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json`: Claude plugin marketplace and plugin metadata.
- `.github/workflows/validate-skill.yml`, `.github/workflows/sync-skills.yml`, `.github/scripts/sync-skills.js`: validation and generated-catalog automation.
- `validate-skills.sh` and `validate-skills-official.sh`: local validation scripts.
- `skills/product-marketing/SKILL.md`: canonical product context memory workflow.
- `skills/cro/SKILL.md`: concise CRO audit framework and related-skill boundaries.
- `skills/prospecting/SKILL.md`, `skills/prospecting/references/compliance.md`, `skills/prospecting/references/data-sources.md`: branch selection, source lineage, deliverability validation, and compliance guardrails.
- `skills/competitor-profiling/SKILL.md`: raw scrape/SEO/review artifact layout and profile template.
- `skills/customer-research/SKILL.md`: source capture, quote extraction, confidence levels, and synthesis templates.
- `skills/ads/SKILL.md`: Google RSA mandatory output spec, character-limit checks, sidecar artifacts, and compliance branch.
- `skills/seo-audit/SKILL.md` and selected references: audit priority, schema-detection caveat, international SEO guidance, and source/evidence output expectations.
- `skills/ai-seo/SKILL.md`, `skills/sms/SKILL.md`, `skills/analytics/SKILL.md`, `skills/ab-testing/SKILL.md`, `skills/free-tools/SKILL.md`, `skills/video/SKILL.md`: sampled for references, tool routing, compliance, and workflow boundaries.
- `skills/*/evals/evals.json`: sampled and counted across all 42 skills for prompt/assertion eval coverage.
- `tools/REGISTRY.md`: tool discovery surface, MCP/API/CLI/SDK columns, categories, and recommendations.
- `tools/clis/README.md`: CLI install, auth, dry-run, output, and security conventions.
- `tools/clis/github-prospects.js`, `tools/clis/ga4.js`, `tools/clis/meta-ads.js`: representative CLI implementations and safety/auth behavior.
- `tools/integrations/composio.md`, `tools/composio/README.md`, `tools/composio/marketing-tools.md`: Composio MCP mapping and limitations.
- `tools/integrations/firecrawl.md`: scraping boundary and allowed/disallowed extraction patterns.
- Directory-level and search-based review across `skills/*/SKILL.md`, `skills/*/references/*`, `tools/integrations/*`, and `tools/clis/*.js` for packaging, artifact handling, compatibility, and verification patterns.

## Excluded Paths

- `.git/**`: VCS internals; only remote, branch, status, and reviewed commit were needed.
- Exhaustive line-by-line review of all 42 skills, 85 reference files, 93 integration guides, and 64 CLI files: representative reads plus targeted searches covered the requested research themes.
- External Agent Skills spec, GitHub issue/PR pages, Composio docs, platform API docs, pricing pages, and compliance authorities: the review focused on checked-in workflow contracts and did not verify every mutable external fact.
- Live API execution for marketing platforms: skipped because it would require credentials and could mutate external accounts or consume paid API quota.
- `validate-skills-official.sh` live install path: inspected but not executed because it downloads the official validator into `/tmp/agentskills`; the repo's local validator and Node syntax checks were sufficient for this candidate review.
- Real model evaluation of `skills/*/evals/evals.json`: not available in the repo; eval files were inspected as static specifications, not executed.
