# trailofbits/skills

- URL: https://github.com/trailofbits/skills
- Category: domain-specific-coding
- Stars snapshot: 5,301 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: a56045e9ae00b3506cacefea0f672aab0a1a6e3c
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: in-scope
- Verdict: Very strong pattern source for security-domain skill packaging. The best reusable parts are phase-gated audit workflows, evidence artifacts, false-positive gates, deterministic plan generation, SARIF/JSON outputs, Codex sidecar packaging, ownership metadata, and CI validators. Do not copy the whole marketplace shape blindly: quality and automation depth vary by plugin, several guarantees are prompt-enforced, and some high-risk workflows still depend on manual review, host-specific hooks, or mutating files in the target repo.

## Why It Matters

`trailofbits/skills` is a large, security-heavy Claude Code plugin marketplace from Trail of Bits. It is directly relevant to domain-specific coding because it turns security audit practices into reusable skills, commands, agents, hooks, scripts, schemas, and output artifacts rather than one-off prompts. The repo contains 39 plugins, 73 plugin skills, 29 agents, 11 commands, 4 hook bundles, 74 Codex skill entries, and more than 160 reference files.

For Agentic Coding Lab, this is one of the richest examples of domain expertise packaged for coding agents. It shows multiple maturity levels: lightweight checklist skills, tool wrappers, artifact-first orchestrators, multi-agent audits, SARIF-producing review systems, and self-improvement loops for skill quality. The strongest security pattern is not "ask the model to audit"; it is "force the model through preflight, evidence collection, scoped delegation, verification, gate review, and report generation."

## What It Is

The repo is a Claude Code plugin marketplace with a root `.claude-plugin/marketplace.json`, per-plugin `.claude-plugin/plugin.json` manifests, installable `skills/`, optional `commands/`, optional `agents/`, optional `hooks/`, scripts, references, resources, tests, and top-level CI validators.

Most plugins target security or reliability work:

- Code auditing: `agentic-actions-auditor`, `audit-context-building`, `c-review`, `differential-review`, `fp-check`, `insecure-defaults`, `sharp-edges`, `static-analysis`, `variant-analysis`, `zeroize-audit`.
- Domain security: `building-secure-contracts`, `firebase-apk-scanner`, `yara-authoring`, `burpsuite-project-parser`, `dwarf-expert`, `constant-time-analysis`.
- Verification and testing: `property-based-testing`, `mutation-testing`, `testing-handbook-skills`, `spec-to-code-compliance`.
- Workflow and tool support: `gh-cli`, `seatbelt-sandboxer`, `second-opinion`, `skill-improver`, `workflow-skill-design`, `devcontainer-setup`, `modern-python`.

The repo primarily targets Claude plugins, but it also ships `.codex/skills/` as a Codex-native sidecar. Most entries in `.codex/skills/` are symlinks to plugin skill directories. `.codex/scripts/install-for-codex.sh` installs those entries into `~/.codex/skills` with `trailofbits-` prefixes. `gh-cli` is a Codex-only wrapper entry because that plugin is hook/command oriented rather than skill oriented.

## Research Themes

- Token efficiency: Strong progressive-disclosure pattern. `CLAUDE.md` requires `SKILL.md` under 500 lines, heavy material in `references/` and `workflows/`, and one-hop reference loading. `workflow-skill-design` makes this rule explicit. Reality is mixed: many skills are compact routers, while some security scanners still carry long examples and large checklists.
- Context control: Strongest in orchestrated skills. `c-review` renders worker prompts from a deterministic plan, embeds a shared context block, writes per-worker shard files, and keeps finding scope separate from broader read-only context. `zeroize-audit` stores run state in `/tmp/zeroize-audit-*` and passes file paths between agents instead of inline blobs. `agentic-actions-auditor` uses one-level cross-file resolution and scoped workflow discovery.
- Sub-agent / multi-agent: Very strong. `c-review`, `zeroize-audit`, `cosmos-vulnerability-scanner`, `semgrep`, `fp-check`, and `audit-context-building` all define subagent roles, tool sets, output contracts, and merge/verification phases. The better workflows distinguish parallel worker phases from sequential judge phases.
- Domain-specific workflow: Excellent breadth. The repo encodes concrete security methods for GitHub Actions agentic CI, CodeQL/Semgrep, C/C++ review, Cosmos/Solana/Cairo/Substrate/TON, zeroization, constant-time crypto, supply chain review, YARA, Burp Suite projects, DWARF, Firebase APKs, macOS Seatbelt, and unsafe defaults.
- Error prevention: Strongest reusable theme. Many skills include "Rationalizations to Reject", hard gates, preflight checks, exact success criteria, false-positive checklists, SARIF generation, artifact verification, and CI validation for plugin metadata/Codex mappings. Several hook bundles block premature stops or unsafe GitHub-fetch patterns.
- Self-learning / memory: Limited durable learning, but good per-run memory. `skill-improver` creates session state files and iterates review/fix cycles until an explicit marker appears. `zeroize-audit`, `c-review`, and Cosmos workflows persist context, findings, manifests, and run summaries. There is no evidence of repository-level learning from past audits beyond curated skills and fixtures.
- Popular skills: Most relevant to Agentic Coding Lab are `c-review`, `zeroize-audit`, `static-analysis`, `fp-check`, `agentic-actions-auditor`, `audit-context-building`, `differential-review`, `variant-analysis`, `building-secure-contracts`, `constant-time-analysis`, `sharp-edges`, `workflow-skill-design`, `gh-cli`, and `skill-improver`.

## Core Execution Path

The marketplace execution path is:

1. Root `README.md` instructs Claude users to add the marketplace with `/plugin marketplace add trailofbits/skills`; Codex users clone the repo and run `.codex/scripts/install-for-codex.sh`.
2. Root `.claude-plugin/marketplace.json` lists plugin names, versions, descriptions, authors, and local sources.
3. Each plugin owns `.claude-plugin/plugin.json`, `README.md`, and optional `skills/`, `commands/`, `agents/`, and `hooks/`.
4. The host selects a skill by `SKILL.md` frontmatter description. Skills load only the needed references/workflows via `{baseDir}` paths.
5. Higher-risk skills then run domain-specific workflows: preflight, tool discovery, scope selection, evidence collection, worker spawning, finding-file generation, deduplication, false-positive review, SARIF/JSON rendering, and final report.
6. CI validates frontmatter, hardcoded paths, personal emails, plugin metadata consistency, and Codex sidecar mappings.

The strongest concrete execution paths:

- `c-review`: Collect threat model, worker model, severity filter, and scope; detect language/platform flags; write `context.md`; call `scripts/build_run_plan.py` to select clusters and render worker prompts; spawn cluster workers in parallel; collect per-worker finding shards; run dedup and false-positive judges sequentially; unconditionally regenerate SARIF from finding frontmatter with `scripts/generate_sarif.py`.
- `zeroize-audit`: Validate C/C++ compile DB or Rust manifest; create `/tmp/zeroize-audit-{run_id}`; run C/C++ and Rust source analyzers, compiler analyzers, report assembler, PoC generator, validator, verifier, and optional test generator; maintain `orchestrator-state.json`; emit `findings.json` and `final-report.md` with evidence files.
- `fp-check`: Restate each suspected vulnerability; route simple claims through a linear standard path and complex claims through data-flow, exploitability, impact, PoC, devil's-advocate, and six-gate review phases; use Stop/SubagentStop hooks to block incomplete verification.
- `semgrep`: Detect languages, choose scan mode and rulesets, require explicit approval before scanning, spawn parallel scanner tasks, preserve raw outputs, and merge SARIF.
- `agentic-actions-auditor`: Discover GitHub workflow files locally or remotely, identify AI agent actions, resolve local/reusable workflow references one level deep, capture security context, apply nine attack-vector heuristics, and report concrete data-flow evidence.
- `cosmos-vulnerability-scanner`: Run a discovery agent that creates a technical inventory/threat model, then spawn pattern-specific scanning agents and verify that every expected pattern was assessed before writing finding files.

## Architecture

The architecture is file-system native and host-driven. There is no monolithic application runtime. Important pieces:

- `README.md`: marketplace overview, installation, plugin catalog, trophy-case bug list, contribution pointer, and license.
- `CLAUDE.md`: authoring standards, Codex compatibility rules, plugin structure, frontmatter conventions, hook guidance, security-skill requirements, progressive disclosure guidance, and PR checklist.
- `.claude-plugin/marketplace.json`: root marketplace registry for 39 plugins.
- `plugins/<name>/.claude-plugin/plugin.json`: per-plugin metadata and version contract.
- `plugins/<name>/skills/<skill>/SKILL.md`: activation and workflow entry point.
- `plugins/<name>/skills/<skill>/references/`, `workflows/`, `resources/`, `schemas/`, `tools/`, `scripts/`: progressive-disclosure and executable support files.
- `plugins/<name>/commands/*.md`: slash-command wrappers that route into skills or scripts.
- `plugins/<name>/agents/*.md`: subagent contracts with narrower tool sets and output formats.
- `plugins/<name>/hooks/hooks.json` plus shell hooks: Claude lifecycle and tool interception logic.
- `.codex/skills/`: Codex-native sidecar entries, mostly symlinked to plugin skill directories.
- `.github/scripts/validate_plugin_metadata.py`: verifies every plugin is present in plugin JSON, marketplace, README, and CODEOWNERS with matching names/versions/descriptions.
- `.github/scripts/validate_codex_skills.py`: verifies every plugin skill has a Codex mapping and every Codex-only entry has `SKILL.md`.
- `.github/workflows/validate.yml` and `lint.yml`: metadata validation, frontmatter checks, hardcoded-path checks, Ruff/shfmt/shellcheck, bats, and Python tests.

Artifact formats are mostly Markdown, JSON, SARIF, YAML, shell scripts, and Python scripts. The best workflows use durable intermediate artifacts such as `plan.json`, `context.md`, `findings-index.txt`, `REPORT.sarif`, `orchestrator-state.json`, `preflight.json`, `findings.json`, `poc_manifest.json`, `poc_verification.json`, and generated finding Markdown with YAML frontmatter.

## Design Choices

The main design choice is to package security judgment as workflow discipline. Many skills explicitly forbid common shortcuts: "zero findings means secure", "the database built so it is good", "scan request means approval", "pattern recognition is analysis", "docs are enough", or "just write a report from partial workers." These rationalization lists are practical guardrails against predictable agent failure modes.

Another important choice is to separate orchestration from worker judgment. `c-review` delegates cluster selection and prompt rendering to a script, then worker agents only analyze assigned clusters. `zeroize-audit` separates source analysis, compiler evidence, report assembly, PoC generation, validation, and verification into explicit phases. `fp-check` separates data-flow tracing, exploitability proof, PoC creation, and gate review. This reduces ambiguous handoffs.

The repo favors evidence artifacts over chat-only claims. Security outputs are expected to contain file paths, line references, data-flow paths, compiler evidence, SARIF entries, PoC validation status, or explicit skip reasons. Several workflows include a safety net that regenerates machine-readable output even if an LLM judge partially fails.

Progressive disclosure is treated as an authoring standard, not an incidental style. `workflow-skill-design` says descriptions are the trigger surface, `SKILL.md` should stay compact, and long domain knowledge belongs in references/workflows/resources. `CLAUDE.md` enforces the same pattern for contributors.

Compatibility is intentionally dual-host. Claude marketplace is the primary form, but the `.codex/skills/` symlink sidecar and validator show how to make one skill corpus visible to Codex without copying every file.

Tool and safety boundaries are partly encoded at host level. `allowed-tools` and agent `tools` constrain skills/subagents. `gh-cli` uses PreToolUse hooks and PATH shims to redirect unauthenticated GitHub fetches to `gh`. `seatbelt-sandboxer` teaches least-privilege macOS profiles. `second-opinion` runs external LLM reviewers in read-only Codex mode where possible, but flags Gemini `--yolo` as a safety tradeoff.

## Strengths

- Security-domain breadth is unusually high. The repo covers application security, smart contracts, static analysis, native code review, crypto side channels, supply chain, CI agent risks, reverse engineering, mobile misconfigurations, and audit-context building.
- The strongest skills define real execution systems: phased workflows, subagent roles, output directories, schema-like artifacts, status files, judges, validators, and final reports.
- `c-review` is a standout reusable pattern for multi-agent review: deterministic run-plan generation, byte-identical cache primer, foreground parallel workers, finding frontmatter, dedup judge, FP/severity judge, and SARIF safety net.
- `zeroize-audit` is a standout evidence workflow: source findings require source evidence; optimized-away findings require IR/assembly evidence; Rust analysis combines rustdoc JSON, MIR, LLVM IR, and optional assembly; PoCs are validated and then independently verified.
- `fp-check` strongly counters security false positives with trace requirements, mathematical bounds proofs, attacker-control proof, negative PoCs, devil's-advocate review, and six gate reviews before a verdict.
- CI and ownership are better than most skill repos: plugin metadata consistency, Codex mapping validation, pinned GitHub Actions, pre-commit, shell tests, Python tests, and CODEOWNERS per plugin.
- Codex compatibility is concrete rather than aspirational. The sidecar symlinks are validated and the installer creates namespaced skill links under `~/.codex/skills`.
- The repo contains reusable authoring guidance for future skill packs: frontmatter quality, progressive disclosure, scope boundaries, security-skill rationalizations, hook performance, and review checklists.
- Several skills produce interoperable artifacts. SARIF appears in static-analysis and c-review workflows; JSON appears in zeroize and Vercel-like pipeline patterns; Markdown frontmatter creates a simple database of findings.

## Weaknesses

- Quality is uneven across 39 plugins. Some are highly engineered orchestrators with scripts and tests; others are mostly checklist prompts with long examples and no executable validation.
- Many guarantees are prompt-level. Hooks and CI help, but most domain-skill correctness still depends on the host model following instructions exactly.
- The repo-wide test suite validates packaging and some scripts, not every skill's security methodology. There is no unified eval harness proving that each audit skill finds seeded bugs or avoids false positives.
- Some workflows intentionally write into the target repo. For example, the Cosmos scanner's discovery phase writes `CLAUDE.md` to the target repo root. That may be useful for context, but it is a mutation boundary future lab workflows should gate explicitly.
- PoC generation in `zeroize-audit` often emits manual-adjustment stubs with incomplete function calls and marks them as requiring manual work. The later verification phase catches this, but the generation stage is not fully autonomous for many categories.
- Some safety tradeoffs are host-specific. `gh-cli` hooks require Claude hook support and shell/JQ behavior; Codex sidecar users do not get those hook protections automatically. `second-opinion` documents Gemini `--yolo`, which is necessary for headless operation but a broad auto-approval mode.
- Large domain references can still overload context if loaded wholesale. The repo teaches one-hop references, but very large scanner pattern files need careful selective reading.
- Several skills contain temporally fragile facts or hard-coded model/tool names. External tool names, model names, cloud/security APIs, and action references can age faster than the skill release cycle.
- Reuse has license implications: the repository is CC-BY-SA-4.0, which may be awkward for directly copying prompt bodies or reference text into differently licensed agent systems.
- Some plugins rely on external tools or credentials without portable dry-run substitutes. That is acceptable for expert users, but less ideal for automated evaluation and onboarding.

## Ideas To Steal

- Require every high-stakes domain skill to define `When to Use`, `When NOT to Use`, `Rationalizations to Reject`, explicit success criteria, and evidence requirements.
- Use a `candidate / worker / judge / renderer` architecture for security audits. Let scripts or deterministic logic define the plan; let agents analyze scoped units; let judges dedupe/verify; let renderers produce reports from artifacts.
- Adopt `c-review`'s finding-file pattern: one Markdown file per finding with YAML frontmatter, then machine generation of SARIF from those files.
- Adopt `fp-check`'s six-gate verdict model for suspected vulnerabilities: process, reachability, real impact, PoC validation, mathematical bounds, and environment protections.
- Adopt `zeroize-audit`'s evidence gating: claims about compiler optimization require compiler artifacts; claims about source cleanup require source/control-flow artifacts; final reports link to evidence files.
- Use deterministic plan generators for complex multi-agent skills. `build_run_plan.py` prevents the orchestrator from hand-recreating cluster paths and dropping required fields.
- Ship a Codex sidecar as symlinks plus a validator instead of duplicating skill directories.
- Enforce marketplace consistency with CI: plugin manifest, root registry, README, CODEOWNERS, Codex mappings, hardcoded path scan, and frontmatter checks.
- Store per-run state and intermediate artifacts in an output directory, not chat memory. This supports resume, auditability, and post-run inspection.
- Use hooks sparingly for hard safety boundaries: blocking incomplete verification, redirecting unauthenticated GitHub fetches, and cleaning session-scoped clones.
- Treat "no findings" as an artifact state, not an omitted phase. Run empty-report generators so downstream tooling sees stable outputs.
- Add "do not scan tests/docs/examples unless scoped" and "production-reachable only" rules directly to security skills to reduce noisy findings.

## Do Not Copy

- Do not copy long prompt bodies or vulnerability pattern catalogs wholesale. Extract the workflow shape and artifact contracts; write domain content independently.
- Do not rely on prompt-level enforcement for high-assurance workflows. Add seeded fixtures, smoke tests, and machine validators where possible.
- Do not copy manual PoC generation that emits unfinished bodies unless the downstream workflow explicitly tracks `requires_manual_adjustment` and blocks unverified claims.
- Do not let a skill mutate the target repo without a visible permission gate and owned output path.
- Do not assume Claude hooks protect Codex, CLI-only, or other hosts. Safety boundaries need host-specific adapters or explicit fallbacks.
- Do not use `--yolo`-style external-agent execution without clear sandbox, scope, and disclosure.
- Do not publish a large skill marketplace without category curation and maturity labels. Users need to know which plugins are engineered, which are checklist-only, and which require credentials/tools.
- Do not hard-code fast-moving tool/model/API details without a freshness check or official-doc lookup path.
- Do not treat all security domains as the same. `c-review`'s multi-agent rigor is useful for native-code audits; a lightweight authoring helper does not need that complexity.

## Fit For Agentic Coding Lab

Fit is strongly in-scope for `domain-specific-coding`. This repo should be mined as a pattern library for security skills, not consumed as a black-box dependency.

Best direct fits:

- A reusable "security skill template" with rationalizations, preflight, evidence artifacts, verification gates, and report generation.
- A multi-agent audit harness modeled on `c-review` but with repo-local evaluation fixtures.
- A finding artifact schema that can render Markdown, SARIF, and index entries from the same frontmatter/JSON.
- A cross-host packaging contract: primary skill directories plus Codex symlink sidecar and validation.
- A skill quality CI suite that checks metadata, references, path hygiene, ownership, and generated sidecars.

Less direct fits:

- Domain catalogs such as Cosmos, Solana, YARA, DWARF, and Firebase are useful examples but too specialized to copy.
- Claude-specific hook behavior and plugin marketplace metadata need adapters for other hosts.
- Some prompts are optimized for expert security consultants, not for general coding-agent users. A lab version should separate beginner-safe flows from expert-only flows.

## Reviewed Paths

- `README.md`: marketplace overview, installation, plugin catalog, trophy case, and license.
- `CLAUDE.md`: contributor and skill-authoring standards, Codex compatibility, plugin structure, quality rules, and PR checklist.
- `CODEOWNERS`: plugin-specific ownership.
- `.claude-plugin/marketplace.json`: root marketplace registry.
- `.codex/INSTALL.md`, `.codex/scripts/install-for-codex.sh`, `.codex/skills/`: Codex sidecar packaging.
- `.github/workflows/validate.yml`, `.github/workflows/lint.yml`: validation and test coverage.
- `.github/scripts/validate_plugin_metadata.py`, `.github/scripts/validate_codex_skills.py`: metadata and sidecar validators.
- `.pre-commit-config.yaml`, `ruff.toml`: local linting/test standards.
- `plugins/agentic-actions-auditor/README.md`, `skills/agentic-actions-auditor/SKILL.md`, selected references: AI agent CI attack vectors, cross-file workflow resolution, and data-flow heuristics.
- `plugins/static-analysis/README.md`, `skills/codeql/SKILL.md`, `skills/semgrep/SKILL.md`, `skills/sarif-parsing/SKILL.md`, `skills/semgrep/scripts/merge_sarif.py`: static-analysis workflows and SARIF handling.
- `plugins/c-review/README.md`, `skills/c-review/SKILL.md`, `scripts/build_run_plan.py`, `scripts/generate_sarif.py`, `prompts/clusters/manifest.json`, selected agent docs: multi-agent native-code review architecture.
- `plugins/zeroize-audit/README.md`, `skills/zeroize-audit/SKILL.md`, selected workflows, schemas, tools, scripts, agents, and Rust regression README: evidence-heavy zeroization audit workflow.
- `plugins/fp-check/README.md`, `skills/fp-check/SKILL.md`, `hooks/hooks.json`, agents, and references: false-positive verification gates.
- `plugins/differential-review/README.md`, `skills/differential-review/SKILL.md`, `methodology.md`, `reporting.md`, `agents/adversarial-modeler.md`: security diff review and adversarial modeling.
- `plugins/variant-analysis/README.md`, `skills/variant-analysis/SKILL.md`, `METHODOLOGY.md`, `commands/variants.md`, resource inventory: bug-variant workflow and query templates.
- `plugins/audit-context-building/README.md`, `skills/audit-context-building/SKILL.md`, `agents/function-analyzer.md`, resource checklists: pure context-building workflow.
- `plugins/building-secure-contracts/README.md`, selected smart-contract scanner skills and resources: platform-specific scanner packaging.
- `plugins/constant-time-analysis/skills/constant-time-analysis/SKILL.md`, analyzer inventory, selected analyzer/test files: executable timing-side-channel support.
- `plugins/gh-cli/README.md`, `hooks/hooks.json`, selected hook scripts: GitHub tool-boundary and cleanup pattern.
- `plugins/seatbelt-sandboxer/skills/seatbelt-sandboxer/SKILL.md`: least-privilege sandbox profile generation workflow.
- `plugins/second-opinion/skills/second-opinion/SKILL.md`: external LLM review invocation and safety note.
- `plugins/skill-improver/README.md`, `skills/skill-improver/SKILL.md`, setup script, stop hook, command wrapper: iterative skill-quality loop.
- `plugins/workflow-skill-design/README.md`, `skills/designing-workflow-skills/SKILL.md`: reusable workflow-skill structure guidance.
- `plugins/sharp-edges/skills/sharp-edges/SKILL.md`, `plugins/insecure-defaults/skills/insecure-defaults/SKILL.md`, `plugins/supply-chain-risk-auditor/skills/supply-chain-risk-auditor/SKILL.md`: security domain checklist patterns and reporting constraints.

## Excluded Paths

- `.git/**`: VCS internals; commit SHA and status were captured separately.
- Long prompt bodies and vulnerability catalogs beyond sampled sections: reviewed for structure, workflows, evidence requirements, and artifact contracts without reproducing full prompt text.
- `plugins/let-fate-decide/**`, `plugins/culture-index/**`, and other non-security/team-management content: inventoried but not deeply reviewed because the requested focus was security/domain coding patterns.
- Full smart-contract pattern resources for every chain: sampled representative scanners (`Solana`, `Cosmos`, workflow guide) rather than exhaustively reading every vulnerability example.
- Full constant-time instruction tables and all language references: sampled analyzer, skill, and tests; exhaustive opcode catalog review was unnecessary for packaging assessment.
- Full `plugins/zeroize-audit/tests/**` fixture bodies: reviewed README and inventory; fixtures were not exhaustively inspected beyond relevance to evidence/testing patterns.
- External linked docs, external tool documentation, and hosted resources: not needed to assess the checked-in workflow contracts.
