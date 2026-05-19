# tldrsec/prompt-injection-defenses

- URL: https://github.com/tldrsec/prompt-injection-defenses
- Category: error-prevention
- Stars snapshot: 692 (GitHub REST API repository metadata, captured 2026-05-19 KST)
- Reviewed commit: 423a2f36a979858223ba5c6dfede8409c8d0fb63
- Reviewed at: 2026-05-19
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong curated defense map for prompt-injection threat modeling, especially blast-radius reduction, least privilege, action guards, taint tracking, dual-LLM quarantine, structured transfer, and guardrail families. Best used as a defensive pattern catalog for coding agents, not as an implementation, benchmark, or authoritative freshness source.

## Why It Matters

Prompt injection is one of the central error-prevention problems for coding agents because agents routinely ingest untrusted repository files, issues, documentation, command output, test logs, webpages, package metadata, and model-generated intermediate text. Any of those artifacts can try to redirect the agent toward unsafe commands, wrong files, secret disclosure, bad patches, skipped tests, or unauthorized network actions.

This repo matters because it collects the control families that have emerged around that threat. It does not propose one silver-bullet prompt. Its strongest recurring message is defense in depth: assume some prompt injection will succeed, minimize what the model can do afterward, inspect model outputs before they drive tools, and separate trusted instructions from untrusted content.

For Agentic Coding Lab, the repo is most valuable as a checklist for agent threat modeling. It helps convert "model might be tricked" into concrete design questions: what content is tainted, what tools are available after taint, which actions need approval, which outputs are parsed by software, and which validators run before side effects.

## What It Is

`tldrsec/prompt-injection-defenses` is a single-README curated resource list. It centralizes links and short summaries for practical and proposed prompt-injection defenses, then groups them into control families:

- Blast radius reduction.
- Input preprocessing such as paraphrasing, retokenization, mutation, and backtranslation.
- Guardrails, overseers, firewalls, filters, input/output classifiers, and canary tokens.
- Taint tracking.
- Secure threads and dual-LLM quarantine patterns.
- Ensemble decisions and mixture-of-experts checks.
- Prompt engineering and instructional defenses.
- Robustness, fine-tuning, instruction hierarchy, and related model-level defenses.
- Preflight injection tests.
- Tool references, general references, papers, and critiques of controls.

The repo is not a library, CLI, benchmark, dataset, policy schema, or test suite. It is a curated taxonomy and reading list maintained in Markdown.

## Research Themes

- Token efficiency: Limited. The repo mentions cost/latency tradeoffs indirectly through guardrails, ensembles, re-execution, and preprocessing, but it does not provide token-minimizing mechanisms or measurements. For coding agents, the token lesson is to avoid dumping tainted raw content into privileged context when structured extraction or quarantine would do.
- Context control: Strong as a conceptual resource. The README repeatedly separates trusted instructions, user intent, external data, model outputs, tool calls, and downstream services. It surfaces structured queries, spotlighting/provenance signals, role/API segmentation, signed prompts, templated output, and dual-LLM patterns.
- Sub-agent / multi-agent: Moderate. The secure-thread and dual-LLM sections map to privileged versus quarantined model roles. The repo does not discuss full subagent orchestration, but it gives a useful basis for separating untrusted-content summarizers from privileged coding/editing agents.
- Domain-specific workflow: Moderate. The controls are general LLM-application controls, not coding-agent-specific workflows. Several patterns translate well to coding work: least-privilege tools, action guards, task-alignment checks, structured tool arguments, SQL guard examples, canaries, and output validators.
- Error prevention: Strong. This is the core theme. The repo emphasizes limiting damage, filtering inputs/outputs, validating action relevance, tracking taint, constraining tools, and treating model outputs as potentially malicious when they are influenced by untrusted text.
- Self-learning / memory: Limited. The list mentions vector memory in tools such as Rebuff for remembering attack-like inputs, but it does not define agent memory hygiene, durable lessons, or learning loops.
- Popular skills: Not a skill-pack repo. Reusable "skills" are defensive patterns: blast-radius review, least-privilege tool design, taint-aware permissions, action guards, dual-lane processing, structured output, and control critique.

## Core Execution Path

There is no executable path. The reviewed artifact is a Markdown taxonomy.

The user path starts at `README.md`, whose table of contents leads to major defense categories. Each category has a short description followed by a table of linked papers, blog posts, docs, tools, or proposals and a concise summary. Later sections list tools, references, papers, and critiques.

The curation path appears issue- and commit-driven. The git history has 24 commits. The repo was created in early April 2024 from an initial commit dated 2024-03-31, had additions through May 2024, then a large update burst on 2025-02-22 that added or fixed entries for Granite Guardian, Martin Fowler guardrails, MELON, GuardReasoner, InjecGuard, Task Shield, CAMLIS 2023, JailGuard, and formatting. The latest reviewed commit is `423a2f36a979858223ba5c6dfede8409c8d0fb63`, dated 2025-02-22.

For a coding-agent user, the practical execution path is to use the taxonomy as a design checklist:

1. Start with blast-radius reduction and least privilege before prompt tricks.
2. Mark all external content and tool output as tainted.
3. Choose controls for each stage: input, retrieval/context, plan, tool call, tool result, patch, final response.
4. Use deterministic checks where possible, then model-based checks as supplemental guardrails.
5. Treat prompt engineering defenses as helpful friction, not a security boundary.

## Architecture

The repo architecture is intentionally minimal:

- `README.md`: all taxonomy, summaries, tool links, paper links, references, and critiques.
- GitHub repository metadata: issue count, stars, topics, creation/push dates, and commit history provide update/provenance context.
- `.git/**`: local clone metadata used only to record the reviewed commit and update pattern.

The README itself uses broad defense families rather than a matrix. It organizes by control type, not by attack type, agent stage, maturity level, cost, or implementation difficulty. That makes it easy to scan as a reading list, but weaker as an operational selection guide.

Provenance is mostly external-link based. The list mixes peer-reviewed or preprint papers, company docs, open-source tools, blog posts, slides, tweets, and research proposals. Some entries quote or paraphrase authors directly; others are one-line summaries. There is no explicit evidence grade, date-added field, maintainer review policy, or reproducibility status per item.

## Design Choices

The most important design choice is putting "Blast Radius Reduction" first. That ordering nudges readers toward least privilege, parameterized tool calls, scoped credentials, and high-stakes operation fences before less reliable prompt-level defenses.

The taxonomy separates preprocessing from guardrails. Preprocessing tries to disrupt attack text before the main model sees it; guardrails/overseers inspect inputs, outputs, canaries, and action effects around the model. That separation is useful for coding agents because command validation and output parsing should live outside the model prompt.

The list includes both practical controls and speculative research. Taint tracking, secure threads, ensemble decisions, and preflight injection tests are framed as proposals or patterns, while guardrails, canaries, least privilege, and parameterized APIs have clearer implementation paths.

The repo includes critiques of controls as a first-class section. That is valuable because prompt-injection defenses are often oversold. The critique links reinforce that simple "ignore malicious instructions" wording, last-word prompting, and model-only filtering can fail under adaptive attacks.

Tooling is listed separately from papers and techniques. This helps readers identify implementable components such as LLM Guard, Rebuff, Vigil, NeMo Guardrails, Guardrails AI, LangKit, Granite Guardian, and HeimdaLLM without confusing tool availability with proof of effectiveness.

The README does not include exploit prompts except brief examples or identifiers inside summaries. The note here intentionally avoids reproducing attack strings and summarizes attack categories safely.

## Strengths

The repo's strongest pattern is threat-model realism. It repeatedly points toward assuming compromise is possible and reducing what a compromised model can do.

The defense categories cover multiple layers: design-time least privilege, input transformation, runtime filtering, output validation, taint-aware permissions, privileged/quarantined model split, ensemble review, structured prompts, model-level robustness, and control critiques.

Several entries are directly relevant to agentic systems, not only chatbots. Action guards, Task Shield, MELON-style re-execution comparison, dual LLMs, structured queries, tool-call parameterization, canaries, and output overseers all apply to agents with tools.

The list captures useful provenance breadth. It points to academic papers, engineering blogs, vendor docs, OWASP-like guidance, MITRE ATLAS mitigations, tool repos, and critiques, giving researchers many starting points.

It is compact enough to scan. A coding-agent designer can quickly extract a layered checklist without reading dozens of papers first.

Recent 2025 additions show the maintainer did update the list after the initial 2024 wave, including agent-specific defenses such as Task Shield and MELON plus newer guard models.

## Weaknesses

The repo is not executable. It provides no library, schemas, tests, benchmark harness, comparison table, maturity scoring, or sample policy implementation.

The taxonomy is control-family based, not agent-stage based. A coding-agent builder must still map controls onto specific transitions such as user request to plan, plan to shell command, command output to context, patch to tests, and final response to user.

Provenance is uneven. Papers, blog posts, docs, tweets, vendor pages, and tools sit beside one another without evidence grading, date-reviewed fields, adoption notes, or reproduction status.

Update discipline is bursty. The repo has 24 commits, mostly one maintainer, initial work in 2024, no commits after May 2024 until a one-day burst on 2025-02-22, and no pushed commits after that reviewed date. GitHub metadata showed 9 open issues and no license at review time.

Some categories risk false confidence if used alone. Prompt engineering, post-prompting, sandwiching, random delimiters, paraphrasing, retokenization, ensembles, and preflight tests can reduce attack success in some settings, but they are not reliable security boundaries for coding-agent side effects.

The README does not distinguish direct prompt injection, indirect prompt injection, jailbreaks, data exfiltration, prompt leakage, tool misuse, RAG poisoning, and downstream parser attacks as separate threat models. Those boundaries matter for coding agents.

There is no coding-agent-specific treatment of filesystem writes, shell execution, git operations, dependency installation, CI credentials, network egress, patch application, or repository-local malicious instructions.

## Ideas To Steal

Start every coding-agent threat model with blast-radius reduction. Before adding model prompts, define least-privilege tokens, writable roots, allowed commands, network policy, approval gates, and irreversible-action fences.

Track taint through context. Any content from repo files, generated code, command output, test logs, issue bodies, webpages, dependency metadata, and prior unvalidated model output should raise taint and lower allowed capability.

Use a privileged/quarantined split. Let a quarantined worker summarize or structure untrusted content without tools. Pass only typed, bounded fields to the privileged editor or command runner.

Add action guards before side effects. Before shell, file write, git commit, package install, network call, or deploy, check that the action matches the user's task, uses approved paths, has bounded arguments, and is not derived solely from tainted content.

Prefer structured transfer over raw text forwarding. Convert untrusted pages, logs, and repository snippets into schemas with source labels, capped strings, and explicit uncertainty. Do not let arbitrary external text become next-step instructions.

Treat model output as untrusted when it has seen tainted input. Parse generated commands, SQL, JSON, patches, and config through deterministic validators before execution or application.

Use canaries and leak checks for privileged prompts, secrets, and hidden policy text. A canary hit should trigger incident-style handling, not just another prompt retry.

Build a control matrix with columns missing from this repo: threat class, agent stage, control type, deterministic versus model-based, maturity, cost, failure mode, and required tests.

Keep critiques close to controls. Any Agentic Coding Lab defense doc should state where each control fails, especially prompt-only defenses and model self-checks.

## Do Not Copy

Do not copy the taxonomy as an implementation roadmap without adding agent stages. Coding agents need separate controls for planning, command execution, file edits, dependency changes, test interpretation, and commits.

Do not treat prompt engineering defenses as security boundaries. Use them as friction alongside sandboxing, allowlists, parsers, schema validation, tests, and human approval.

Do not flatten all external links into equal authority. A vendor product page, tweet, position paper, peer-reviewed result, and reproducible tool need different trust weights.

Do not rely on model-based guardrails where deterministic checks are available. Shell command policy, path scope, JSON schema, AST parsing, secret scanning, and test execution should be software checks.

Do not let "input preprocessing" mutate developer-visible source, diffs, or commands without traceability. Paraphrasing and retokenization can lose semantics that matter in code.

Do not pass quarantined model output into privileged context as free-form text. Use schemas and source labels, or the quarantine boundary collapses.

Do not assume the list is current because GitHub `updated_at` is recent. The reviewed repository `pushed_at` date is 2025-02-22; metadata can update for non-code activity.

## Fit For Agentic Coding Lab

Fit is high for the `error-prevention` category as a threat-modeling and design-pattern source. It is not a direct artifact to adopt, but it sharpens the defensive vocabulary Agentic Coding Lab needs.

Best adaptations:

- A prompt-injection defense checklist for coding agents organized by workflow stage.
- A taint model for untrusted repo/context/tool-output text.
- Mandatory action guards for shell, filesystem, git, package, network, and deploy actions.
- Privileged/quarantined agent roles for reading untrusted material versus making edits.
- Structured handoff schemas between agents and tools.
- Deterministic validators for commands, paths, patches, SQL, JSON, secrets, and tests.
- Defense cards that include "when this fails" beside each proposed control.

The main caveat is that this repo is a map, not a gate. Agentic Coding Lab should steal the taxonomy and skepticism, then build enforceable policy, tests, and review loops around actual coding-agent side effects.

## Reviewed Paths

- `README.md`: complete resource taxonomy, table of contents, defense categories, tool list, papers, general references, and critiques.
- Git metadata for the cloned repository: reviewed commit, commit count, commit dates, contributor distribution, and update pattern.
- GitHub REST API repository metadata: star snapshot, pushed date, updated date, open issues, topics, fork count, license state, and repository status.

## Excluded Paths

- `.git/**`: excluded as repository metadata rather than research content, except for commit/update provenance needed to record the reviewed snapshot.
- External linked papers, blog posts, docs, tools, tweets, PDFs, and product pages: treated as provenance pointers and summarized only through the repo's README. A full review of each linked defense would require separate paper/tool notes.
- Remote README banner image and GitHub-hosted image assets referenced in Markdown: presentation-only assets, not defense taxonomy or implementation logic.
- Generated/vendor/binary/UI-only paths: none were present in the checkout beyond Git internals and remote image references. The repository consists of one Markdown content file plus git metadata.
