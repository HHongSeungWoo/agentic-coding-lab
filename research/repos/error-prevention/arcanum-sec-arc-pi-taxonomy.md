# Arcanum-Sec/arc_pi_taxonomy

- URL: https://github.com/Arcanum-Sec/arc_pi_taxonomy
- Category: error-prevention
- Stars snapshot: 621 (GitHub REST API repository metadata, captured 2026-05-29 KST)
- Reviewed commit: 61d37139e313ce27f73322b60b6b8d559bb44f08
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful prompt-injection taxonomy and test-case seed corpus for agentic error prevention. Its strongest value is the multi-axis split across attack inputs, intents, techniques, and evasions, especially for prompt-leak, tool-enumeration, data-poisoning, multi-chain, business-integrity, and obfuscation tests. Do not treat it as a maintained benchmark, validated ontology, or defensive implementation: source files drift from the GitHub Pages data, labels lack evidence metadata, and there is no executable test harness or schema.

## Why It Matters

Coding agents are exposed to prompt injection through user messages, repository files, issue text, webpages, dependency metadata, command output, images, RAG snippets, generated code comments, and downstream tool results. A useful error-prevention system needs more than one generic "ignore previous instructions" test. It needs a vocabulary for attacker goals, delivery surfaces, execution techniques, and obfuscation variants.

This repo matters because it separates those axes. A coding-agent lab can use the taxonomy to generate richer negative tests: combine a harmful intent such as tool enumeration, system prompt leakage, internal-system access, or data poisoning with a delivery surface such as file upload, indirect input, or collaboration content, then mutate it through evasions such as Base64, Markdown, homoglyphs, invisible text, URL encoding, or nested JSON.

For Agentic Coding Lab, the practical value is not that the repo blocks attacks. It does not. The value is that it supplies a broad adversarial vocabulary for designing guard tests, triage labels, red-team prompts, and review checklists for agents that read untrusted context before using tools.

## What It Is

`Arcanum-Sec/arc_pi_taxonomy` is a Markdown and static-site taxonomy for prompt injection. The repository includes:

- Markdown folders for `attack_intents`, `attack_techniques`, and `attack_evasions`.
- A richer static-site dataset in `docs/data/taxonomy.js`.
- A GitHub Pages UI in `docs/index.html`, `docs/app.js`, and `docs/styles.css`.
- A large `in_md.md` mind-map export focused heavily on business-integrity prompt injections.
- Supporting security-assessment documents: an AI app defense checklist, an AI security questionnaire, LLM threat-model questions, and an AI DevOps infrastructure table.
- A CC BY 4.0 license requiring attribution to Jason Haddix and Arcanum Information Security.

The static-site dataset is the most complete current artifact. Parsed at the reviewed commit, it contains 107 entries: 10 input vectors, 18 attack intents, 28 techniques, and 51 evasions. The Markdown folders are useful explanatory notes but are smaller and not synchronized with the static dataset.

It is not a library, model, detector, MCP server, benchmark runner, schema package, or evaluation harness.

## Research Themes

- Token efficiency: Limited directly. The repo does not optimize context use, but the four-axis taxonomy can help avoid dumping unstructured attack examples into prompts. Agentic Coding Lab could store compact labels such as `intent=tool_enumeration`, `surface=indirect_input`, `technique=end_sequences`, and `evasion=homoglyphs` instead of carrying large raw prompt strings through every step.
- Context control: Strong as a threat-model source. The input-vector section covers direct API requests, chat, collaboration platforms, uploads, forms, indirect data, audio, images, productivity apps, and video. That maps well to agent context boundaries and taint labeling.
- Sub-agent / multi-agent: Moderate. The taxonomy includes multi-chain attacks, Russian-doll nesting, downstream model handoff, and cleanup/summarization model compromise. It does not prescribe sub-agent architecture, but it highlights why untrusted-content summarizers and privileged tool-using agents need separate trust boundaries.
- Domain-specific workflow: Moderate to strong for AI security and agent workflows. The business-integrity branch is especially concrete for customer-service, billing, account, booking, subscription, and commerce agents. Coding-agent-specific cases such as shell edits, git operations, dependency installation, and CI secrets need additional categories.
- Error prevention: Strong as a test and label source, weak as a control. It helps enumerate ways agents can be steered into wrong actions, data leakage, policy override, tool misuse, or persistent-memory poisoning. It provides no enforcement mechanism.
- Self-learning / memory: Moderate as a threat source. The data-poisoning and memory-exploitation entries call out persistent memory, RAG corruption, MCP memory, feedback poisoning, and context manipulation. The repo does not define safe memory-update workflows or incident learning loops.
- Popular skills: Not a skill-pack repo. Reusable "skills" are taxonomy-derived test generation, prompt-injection labeling, business-action threat modeling, input-surface inventory, and evasion mutation.

## Core Execution Path

There is no runtime execution path beyond the static web UI.

The content path starts with `README.md`, which explains the three original folders: attack intents, attack techniques, and attack evasions. It also points to the GitHub Pages version and additional security resources.

The richer user path is the static site. `docs/index.html` loads `docs/data/taxonomy.js` and `docs/app.js`. The JavaScript renders cards for each category, updates counts, supports category filters, supports title/description search, and opens modal details. The data object stores each taxonomy entry as a title, description, ideas list, and examples list. Inputs do not include example prompts; intents, techniques, and evasions usually do.

The source-material path is split:

1. Topic Markdown files under `attack_intents`, `attack_techniques`, and `attack_evasions` give short descriptions and example prompts.
2. Business-integrity subfiles provide more structured sections with description, scope assumptions, attack surfaces, ten sample injections, and defensive notes.
3. `in_md.md` appears to be a larger mind-map export. It expands business-integrity cases such as coupon codes, fees, store credit, returns, refunds, cancellations, loyalty benefits, warranty manipulation, unauthorized account users, trial manipulation, paid-feature access, shipping perks, contract language, embargoed product leakage, regional pricing, exchange rates, bookings, paywalls, and payment extensions.
4. `docs/data/taxonomy.js` consolidates and expands the public taxonomy for the GitHub Pages UI.

For Agentic Coding Lab, the executable adaptation would be external: parse the static dataset, normalize categories into a schema, generate cross-product test cases, run them against agent workflows, and score whether the agent preserves instruction hierarchy and tool policy.

## Architecture

The architecture is intentionally minimal:

- `README.md`: project overview, usage description, live-site link, contribution invitation, license attribution wording.
- `docs/data/taxonomy.js`: primary structured dataset for the UI, with `inputs`, `techniques`, `evasions`, and `intents` arrays.
- `docs/app.js`: browser-only renderer, filters, search, modal display, and HTML escaping for modal list content.
- `docs/index.html` and `docs/styles.css`: static GitHub Pages interface.
- `attack_intents/*.md`: intent notes for API enumeration, tool enumeration, system prompt leak, prompt-secret extraction, jailbreak, data poisoning, denial of service, multi-chain attacks, business integrity, bias testing, user attacks, harmful discussion, and image-generation misuse.
- `attack_intents/business_integrity/**`: more detailed business-action prompt-injection notes.
- `attack_techniques/*.md`: technique notes such as end sequences, act-as-interpreter, Russian-doll nesting, memory exploitation, narrative smuggling, contradiction, rule addition, variable expansion, and cognitive overload.
- `attack_evasions/*.md`: evasion notes such as Base64, JSON, XML, Markdown, spaces, reverse text, case changing, metacharacter confusion, link smuggling, steganography, and phonetic substitution.
- `in_md.md`: large mind-map-style taxonomy export, partly polished and partly rough notes.
- `ai_enabled_app_defense_checklist.md`, `ai_sec_questionnaire.md`, `ai_threat_model_questions.md`, and `ecosystem/README.MD`: supporting assessment/checklist material.
- `Arcanum PI Taxonomy.xmind`: binary mind-map source or export, not reviewed as text.

The repo has no package manifest, CI workflow, schema validation, data-generation script, test suite, or release artifact. GitHub metadata at review time showed it was not archived, had 621 stars, 106 forks, 2 open issues, no repository topics, and `main` as the default branch.

## Design Choices

The main design choice is axis separation. Inputs describe where injection enters, intents describe what the attacker wants, techniques describe how the attacker steers model behavior, and evasions describe how the attack is hidden or transformed. This is more useful for test generation than a flat list of jailbreak strings.

The taxonomy favors concrete examples over formal definitions. Most static-site entries include several "ideas" and example prompts. This makes it easy for a red team or agent-eval designer to create variations, but it also means labels are not rigorously bounded.

The `docs/data/taxonomy.js` dataset is richer than the Markdown folders. It includes newer categories such as attack external/internal systems, attack external/internal users, unauthorized professional advice, CBRNE information, gradient-based attacks, anti-refusal, chunking, competition, priming, reorientation, urgency, and many Unicode/encoding evasions. That suggests the static site is now the canonical practical artifact, but the repo does not state that explicitly.

Business-integrity prompt injection gets unusual depth. The `in_md.md` export and nested Markdown files move beyond classic prompt leakage into unauthorized discounts, refunds, account access, contracts, regional pricing, paywalls, reservations, and payment terms. This is valuable because agent safety often fails around business side effects, not only model refusals.

The supporting checklist uses a layered defense frame: ecosystem, model, prompt, data, and application. It is high-level, but it correctly points to scoped roles, read-only tools where possible, context-window management, no secrets in system prompts, rate limiting, input validation, output encoding, and sandboxing.

The project intentionally serves as a public knowledge artifact. The README emphasizes security researchers, red teams, developers, and academics, and the license is CC BY 4.0. There is no attempt to hide attack examples or package them as safe fixtures.

## Strengths

The four-axis taxonomy is directly useful for prompt-injection eval design. Inputs, intents, techniques, and evasions can be combined into test matrices that are more realistic than single-string jailbreak checks.

The static dataset has broad coverage. The reviewed commit includes 10 input surfaces, 18 intents, 28 techniques, and 51 evasions, covering direct and indirect injection, multimodal inputs, tool misuse, persistent memory, RAG poisoning, chain handoff, prompt leakage, business action manipulation, and many encoding tricks.

The agentic-tooling categories are relevant. Tool enumeration, API enumeration, attack internal systems, attack external systems, attack internal users, attack external users, data poisoning, multi-chain attacks, memory exploitation, and Russian-doll nesting all map to coding agents with filesystem, shell, browser, network, MCP, or memory capabilities.

The business-integrity branch is a good reminder that "safe answer" is not the only outcome. Agents can cause harm by applying discounts, issuing refunds, modifying accounts, overriding contract terms, leaking internal pricing, or granting paid features.

The examples are practical enough to seed tests. Many entries can be converted into adversarial prompts, transformed through evasions, and then evaluated against expected behavior such as refusal, clarification, approval request, or tool-call block.

The defense checklist and questionnaire provide a bridge from attack taxonomy to system review. They are not deep controls, but they help turn taxonomy labels into architecture questions about tools, APIs, IAM, logs, data stores, RAG, rate limits, and incident response.

Maintenance is not dormant. The repo was created on 2025-02-26, has 47 commits, and was last pushed on 2026-01-20 at the reviewed commit. The project is not archived, and the README says active development is welcome.

## Weaknesses

The taxonomy is not validated as a benchmark. There are no expected outcomes, pass/fail criteria, model versions, success rates, severity levels, sample weights, false-positive controls, or negative examples.

The source of truth is unclear. `docs/data/taxonomy.js` contains many entries missing from the Markdown folders, while the Markdown folders contain some names that are absent or renamed in the static dataset. For example, the static dataset has 18 intents while the top-level Markdown folder has 13 intent files; the static dataset includes many evasion categories that have no Markdown file; and Markdown names such as `attack_users`, `framing`, `narrative_smuggling`, and `fictional_language` do not map one-to-one to static-site IDs.

Label boundaries are uneven. Some entries describe attacker goals, some describe delivery mechanisms, some describe content-safety categories, some describe parser confusion, and some describe evaluation techniques. Without annotation guidelines, two reviewers could label the same prompt differently.

The Markdown quality is inconsistent. A few files are detailed, especially `attack_intents/tool_enumeration.md` and `attack_techniques/end_sequences.md`. Many other Markdown files are 8 to 16 lines and contain only a short description plus a bullet list of attack ideas.

There is no machine-readable schema beyond a JavaScript global constant. The data is easy to render in a browser, but there are no stable IDs documented as public API, no JSON export, no type definitions, no validation script, and no changelog for category changes.

Provenance is light. Some files and notes include links to external examples or tools, but most entries do not cite origin, first-seen date, related papers, confirmed exploit contexts, or evidence quality. The `ecosystem/README.MD` even labels itself as AI-generated with RAG from security sources, which makes independent verification important before relying on its CVE assertions.

It is offensive-content heavy. That is expected for a red-team taxonomy, but an agent-lab adaptation should avoid blindly injecting raw attack strings into privileged prompts, documentation, or user-visible examples without safety framing and access controls.

There is no implementation safety boundary. The repo does not enforce tool policy, taint tracking, sandboxing, command validation, memory hygiene, output scanning, or approval gates.

## Ideas To Steal

Use the four-axis model as an eval schema: `input_surface`, `intent`, `technique`, `evasion`, plus `expected_agent_behavior`, `risk_tier`, `tool_scope`, and `source_provenance`.

Generate cross-product tests for coding agents. Pair intents such as tool enumeration, data poisoning, system prompt leak, internal-system access, and business-integrity override with evasions such as Base64, Markdown, JSON, homoglyphs, invisible text, URL encoding, and reverse text.

Add business-side-effect categories to agent safety tests. A coding agent equivalent might be unauthorized dependency installation, file deletion, secret exposure, CI bypass, generated contract changes, incorrect migration execution, or permission broadening.

Treat multi-chain and Russian-doll attacks as mandatory tests for subagents. A summarizer, formatter, code-cleanup model, documentation writer, or review agent should not pass hidden instructions to a privileged executor as if they were user intent.

Use the input-vector taxonomy to drive context tainting. A policy engine should know whether text came from a direct user request, repo file, uploaded document, external webpage, issue comment, command output, OCR result, audio transcript, or generated intermediate artifact.

Adapt the `end_sequences` pattern library into parser-boundary tests. Coding agents need tests for fake role headers, Markdown fence breaks, JSON/YAML closure, shell terminators, SQL terminators, and nested boundary compositions in files and tool output.

Turn the AI security questionnaire into preflight review prompts for agent deployments: what tools exist, which are read/write, where data is stored, whether RAG is present, what memory persists, how authentication works, and what incident response exists.

Build a normalized JSON export with stable IDs, aliases, parent categories, examples, evidence source, date added, maturity, and allowed-use notes. The current repo has enough content to seed that artifact but not enough structure to serve it directly.

## Do Not Copy

Do not copy the raw taxonomy into an agent prompt as "things to watch for." That increases prompt size and can expose attack instructions to the model without enforcing any boundary.

Do not treat every entry as equally proven. A common prompt-leak technique, a speculative gradient-based attack, a business policy override, a Unicode evasion, and an AI-generated infrastructure table need different evidence weights.

Do not use the examples as a benchmark without labels and expected outcomes. A useful eval must specify whether the correct behavior is refusal, safe completion, tool-call denial, human approval, structured warning, or memory-update rejection.

Do not rely on the Markdown folders as complete. The static-site dataset is broader, while `in_md.md` contains business-integrity detail not fully split into files.

Do not adopt the category names without aliases and normalization. There are spelling and naming inconsistencies such as `phoenetic_substitution`, `attack_users` versus internal/external users, `framing` versus narrative injection, and `fictional_language` versus fictional constructed languages.

Do not equate "detect prompt injection" with "prevent agent error." Coding agents need deterministic controls around shell, filesystem, git, package managers, network, browser, MCP tools, memory, and final user-visible output.

Do not use the ecosystem CVE table as authoritative inventory without checking current upstream advisories. It is a useful threat-model seed, not a vulnerability database.

## Fit For Agentic Coding Lab

Fit is conditional but meaningful for `error-prevention`. The repo is not a guardrail or agent framework, but it is a good candidate for taxonomy-driven eval generation and threat labeling.

Best Agentic Coding Lab adaptations:

- A prompt-injection label ontology for coding-agent incidents and test cases.
- A compact fixture generator that combines input surface, intent, technique, and evasion.
- A set of business-side-effect analogs for coding work: unauthorized writes, unsafe commands, credential leakage, hidden instruction propagation, dependency risk, and policy override.
- A taint model that marks user text, repo text, external text, command output, OCR, RAG, and model-generated intermediate text separately.
- A red-team checklist for multi-agent handoffs, especially summarizer-to-executor and reviewer-to-committer transitions.
- A normalized dataset with stable IDs, source provenance, expected behavior, and severity.

The repo should remain a research source rather than an adopted dependency. The right move is to steal the taxonomy shape and selected examples, then build enforceable policy, deterministic validators, test harnesses, and review workflows around actual coding-agent side effects.

## Reviewed Paths

- `README.md`: repository purpose, live-site pointer, top-level taxonomy structure, audience, contribution invitation, and attribution requirements.
- `LICENSE.md`: CC BY 4.0 license and attribution wording.
- `docs/data/taxonomy.js`: primary structured static-site taxonomy, parsed for entry counts and category names.
- `docs/index.html`, `docs/app.js`, and `docs/styles.css`: static UI, search/filter/modal flow, and relationship to the data file.
- `attack_intents/*.md`: top-level intent descriptions and prompt examples, including API enumeration, tool enumeration, prompt secrets, system prompt leakage, data poisoning, multi-chain attacks, jailbreaks, denial of service, business integrity, bias testing, and harmful content categories.
- `attack_intents/business_integrity/**`: structured business-integrity subnotes for discounts, returns/refunds, account access, and confidential information.
- `attack_techniques/*.md`: technique notes, with closer review of `end_sequences.md`, `act_as_interpreter.md`, `memory_exploitation.md`, `russian_doll.md`, `rule_addition.md`, and related files.
- `attack_evasions/*.md`: evasion notes for encoding, formatting, Unicode, link, markup, steganographic, and phonetic transformations.
- `in_md.md`: large mind-map export, especially the expanded business-integrity taxonomy and rough notes with external references.
- `probes.md`: short API/form probe examples.
- `ai_enabled_app_defense_checklist.md`, `ai_sec_questionnaire.md`, and `ai_threat_model_questions.md`: defensive checklist and assessment-question material.
- `ecosystem/README.MD`: AI DevOps infrastructure assessment table, reviewed as supporting threat-model material rather than verified CVE authority.
- Git metadata for the cloned checkout: reviewed commit, branch, commit count, contributor distribution, creation/update pattern, and latest commit details.
- GitHub REST API repository metadata: stars, forks, open issues, archived status, default branch, creation date, push date, update date, license metadata, and topics.

## Excluded Paths

- `.git/**`: excluded as repository internals except for commit and maintenance provenance.
- `Arcanum PI Taxonomy.xmind`: binary mind-map artifact. I reviewed the exported Markdown and static-site data instead of reverse-engineering the binary file.
- `docs/styles.css`: skimmed only for UI role; visual styling is not relevant to taxonomy quality or agent error-prevention fit.
- External links in `in_md.md`, `ecosystem/README.MD`, and other notes: treated as provenance pointers, not independently deep-reviewed. Linked papers, tools, tweets, articles, and CVE records would require separate source-specific review.
- GitHub Pages live deployment: the static files in `docs/**` were reviewed from the pinned commit. I did not treat the live site as a separate mutable source.
- Generated browser DOM output: the static renderer was inspected, but no browser session was needed because the research question concerns taxonomy content, labels, provenance, and test-generation value.
