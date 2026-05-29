# Imbad0202/academic-research-skills

- URL: https://github.com/Imbad0202/academic-research-skills
- Category: domain-specific-coding
- Stars snapshot: 23,667 stars from GitHub REST API repository search, captured 2026-05-29
- Reviewed commit: f0bfc594c452abca755f5292fc672ac72a1ffb77
- Reviewed at: 2026-05-29
- Status: reviewed
- Scope fit: conditional
- Verdict: High-value pattern mine for evidence-heavy agent workflows, especially literature corpus provenance, staged integrity gates, claim-faithfulness artifacts, and peer-review/revision loops. Do not copy wholesale: the repo is academic-writing oriented, CC BY-NC licensed, and several important controls are prompt-level or design-stage rather than hard runtime enforcement.

## Why It Matters

This repo treats academic research as a long-running agent workflow rather than a single "write my paper" prompt. That makes it useful for Agentic Coding Lab even though the domain is not software engineering: academic research and serious coding both need source provenance, reproducible handoffs, review gates, revision traceability, and explicit handling of weak or stale evidence.

The strongest transferable idea is that every stage leaves artifacts behind. Literature searches emit search strategies and screened-source blocks. Reviewers emit reports and decisions. Revision rounds emit traceability matrices and response letters. Integrity checks emit audit trails, schema-backed passport fields, and hard/soft warnings. This is exactly the kind of evidence surface coding agents need when they claim a bug is fixed, a dependency is safe, a benchmark improved, or a migration preserved parity.

## What It Is

`academic-research-skills` is a source-available Claude Code skill/plugin suite for noncommercial academic research workflows. It packages four top-level skills: `deep-research`, `academic-paper`, `academic-paper-reviewer`, and `academic-pipeline`. The plugin surface also includes `/ars-*` commands, agent prompt files, shared schemas/contracts, reference protocols, Python validators, adapter utilities, CI workflows, and example pipeline outputs.

The reviewed snapshot is versioned as v3.9.4.2 in plugin metadata and README badges, with additional unreleased work on `/ars-mark-read` and v3.10 measurement infrastructure. The project is not a general coding-agent framework. It is a domain-specific workflow system for research planning, literature review, manuscript drafting, simulated peer review, revision, compliance checking, source verification, and finalization.

## Research Themes

- Token efficiency: Mixed. The suite uses mode routing, slash commands, staged skills, reset-boundary design, and reference files to avoid loading every detail at once. However, many `SKILL.md`, agent, and design files are long, and a full pipeline can involve dozens of conceptual agents and large artifact payloads.
- Context control: Strong as a design pattern. The repo declares `data_access_level`, phase boundaries, Material Passport handoffs, corpus-first reading rules, reset boundaries, and sidecar artifacts. The caveat is enforcement: many boundaries are prompt-level or advisory, with deterministic conductor work explicitly deferred to v3.10.
- Sub-agent / multi-agent: Strong workflow vocabulary. The system defines 13 research agents, 12 writing agents, 7 reviewer agents, and 5 pipeline agents, plus independent reviewer panels and re-review teams. In the repo, these are mostly prompt/dispatch contracts for Claude Code rather than a standalone scheduler with isolated processes.
- Domain-specific workflow: Very strong. The suite encodes academic workflows end to end: FINER research question framing, PRISMA-style screening, source grading, literature matrices, manuscript structure, citation compliance, AI disclosure, simulated peer review, response-to-reviewers, re-review, and final integrity checks.
- Error prevention: Very strong in artifacts and checks. Notable surfaces include 100% reference verification rules, gray-zone elimination, claim-intent manifests, citation anchors, claim-audit aggregates, temporal audit sidecars, contamination signals, sprint contracts, compliance reports, schema validators, mutation tests, and CI drift guards.
- Self-learning / memory: Moderate. The Material Passport, `repro_lock`, `compliance_history`, reset ledger, human-read peer file, and calibration reports carry run memory. There is no broad autonomous memory that learns across projects; most persistence is explicit artifact state.
- Popular skills: The most reusable parts are `academic-pipeline`, `deep-research`, `academic-paper-reviewer`, `bibliography_agent`, `literature_strategist_agent`, `source_verification_agent`, `integrity_verification_agent`, `claim_ref_alignment_audit_agent`, `compliance_agent`, `revision_coach_agent`, and the shared contracts under `shared/contracts/`.

## Core Execution Path

1. Install through Claude Code plugin commands or symlink the four skill directories into `.claude/skills/`.
2. Invoke a command such as `/ars-full`, `/ars-lit-review`, `/ars-plan`, `/ars-reviewer`, `/ars-revision`, `/ars-citation-check`, or `/ars-disclosure`.
3. The active skill or `academic-pipeline` orchestrator chooses a mode from `MODE_REGISTRY.md` and dispatches the appropriate stage.
4. Stage 1 research produces an RQ brief, methodology blueprint, bibliography, source verification, synthesis, and optional systematic-review artifacts.
5. Stage 2 writing produces configuration, literature search report, outline, argument map, draft, citations, abstract, figures, and formatting artifacts.
6. Stage 2.5 integrity checks references, citation context, statistical data, originality samples, factual claims, compliance, and AI research failure modes before review.
7. Stage 3 review runs field analysis, independent reviewer reports, Devil's Advocate critique, editorial synthesis, and a revision roadmap. Reviewer sprint contracts split paper-blind scoring commitments from paper-visible review in selected modes.
8. Stage 4 revision and Stage 3' re-review use response checklists, R&R traceability, residual-issue coaching, and now commitment-fulfillment fields in unreleased work.
9. Stage 4.5 final integrity re-runs stricter checks, including 100% claim verification in final-check mode.
10. Stage 5 and 6 finalize output and generate process summaries, disclosure records, and collaboration/process documentation.

The repo's newer audit layers add more specialized paths: `ARS_CLAIM_AUDIT=1` enables claim-to-reference alignment after cite-time anchors have been emitted; v3.9.4 adds temporal sidecars and a deterministic temporal audit; `/ars-mark-read` records a user-owned human-read signal in a peer YAML file rather than mutating the adapter-owned corpus.

## Architecture

The repo is organized as a Claude Code skill/plugin distribution plus validation tooling:

- `deep-research/`: research skill, research agents, examples, templates, and source-quality references.
- `academic-paper/`: writing skill, draft/revision/citation/formatting agents, paper templates, and revision examples.
- `academic-paper-reviewer/`: peer-review skill, reviewer agents, quality rubrics, sprint-contract protocol, calibration mode, and re-review protocol.
- `academic-pipeline/`: orchestrator skill, state/integrity/claim-audit/collaboration agents, pipeline state machine, passport reset, adapters, and failure-mode protocols.
- `shared/`: cross-skill contracts, schemas, compliance protocols, RAISE/PRISMA material, reproducibility pattern, ground-truth isolation pattern, and cross-model verification.
- `scripts/`: deterministic validators, audit pipelines, adapter implementations, API clients, migration tools, and test suites.
- `evals/`: emerging gold-set infrastructure; in the reviewed commit, citation-extraction gold data exists, while the generalized `run_evals.py` harness and ranking-lift gate are still future work.
- `.github/workflows/`: spec consistency, adapter pytest, freshness checks, release/test-count discipline, and related CI gates.
- `commands/` and `.claude-plugin/`: slash-command and plugin metadata surface.

The architecture is artifact-centric. The Material Passport and companion sidecars act as the durable state boundary between stages. JSON Schema handles local shape constraints; Python lints handle cross-field invariants that JSON Schema cannot express; prompt instructions define the higher-level workflow and human checkpoints.

## Design Choices

The repo makes human-in-the-loop research a core invariant. Mandatory checkpoints, integrity gates, review decisions, and revision choices are designed to keep the researcher involved. This is a useful counter-pattern to fully autonomous paper generation and maps well to coding-agent workflows where a human should review high-risk claims before merge or release.

It separates research data layers with `data_access_level`: `deep-research` consumes raw inputs, `academic-paper` works on redacted/sanitized material, and reviewer/pipeline components are `verified_only`. The project is honest that this is declarative and linted, not a runtime permission system.

It turns source quality into structured artifacts. `literature_corpus[]` entries carry CSL-style metadata and source pointers; adapters emit both `passport.yaml` and `rejection_log.yaml`; consumers emit PRE-SCREENED reproducibility blocks; trust-chain fields record source acquisition and verification; contamination signals use S2/OpenAlex/Crossref lookup outcomes as advisory evidence.

It adds pre-commitment to subjective review. Reviewer sprint contracts and generator/evaluator contracts ask agents to commit scoring criteria before seeing the paper/draft, then evaluate later under structural lint. This is one of the best transferable patterns for coding: review rubrics should be fixed before the reviewer sees the patch.

It distinguishes hard gates from advisory measurements. Reference fabrication and unresolved high-warn claim-audit classes can refuse output; temporal findings and contamination signals are advisory in the reviewed version; PRISMA-trAIce mandatory items block only in systematic-review mode. This avoids pretending every weak signal deserves the same policy response.

It documents what is not reproducible. The `repro_lock` pattern explicitly says LLM outputs are not byte-reproducible and records configuration rather than promising replay. This honesty is worth copying for agentic coding artifacts that depend on live APIs, evolving models, and non-deterministic generation.

## Strengths

- End-to-end academic workflow coverage from research question formation to final integrity report, with concrete artifacts at each stage.
- Strong source-provenance design: Material Passport, corpus adapters, rejection logs, PRE-SCREENED blocks, trust-chain fields, human-read peer files, and contamination signals.
- Rich literature-review mechanics: PRISMA-style counts, same-criteria corpus screening, search-fills-gap flow, distributional skew advisory, source quality matrices, and literature matrices.
- Mature peer-review/revision model: independent panel roles, Devil's Advocate preservation, editorial synthesis, calibration mode, re-review mode, traceability matrix, and commitment-fulfillment checks.
- Advanced evidence-audit surface: cite-time anchors, claim-intent manifests, claim-audit results, drift/uncited/constraint aggregates, temporal sidecars, and deterministic lint scripts.
- Strong schema and CI discipline for a prompt-heavy repo. The project uses JSON Schema, Python cross-field lints, mutation tests, spec-consistency CI, test-count monotonic checks, and changelog-linked design records.
- Good distinction between artifact documentation and true reproducibility. The docs repeatedly avoid overstating replay, source verification, or advisory signals.
- Strong transfer value for coding-agent lab work: the same patterns can apply to issue claims, dependency provenance, migration parity, benchmark changes, and code-review commitments.

## Weaknesses

- Scope is only conditional for Agentic Coding Lab. The repo improves agent workflows, but its domain is academic research and manuscript production, not coding tasks or software artifacts.
- Many controls are prompt-level or advisory. Phase boundaries, data-access layers, multi-agent separation, and some anti-leakage rules depend on the host agent following instructions; deterministic PreToolUse/conductor enforcement is repeatedly deferred.
- Several v3.10 mechanisms are design-stage in the reviewed commit. `run_evals.py`, `check_ranking_lift.py`, `verification_gate`, and epistemic-status enforcement are discussed in specs, but not present as shipped runtime scripts.
- The suite is large and maintenance-heavy. Four skills, 25 modes, 38 conceptual agents, many schemas, and a long changelog create a high cognitive load for adopters.
- Claim-faithfulness audit still relies on LLM-as-judge behavior and retrieval wiring. The synthetic 20-tuple calibration fixture validates tooling shape, but does not prove performance across real disciplines.
- External API verification is inherently unstable. Semantic Scholar, OpenAlex, Crossref, DOI pages, and WebSearch results can change; the repo records protocols and fallbacks but does not snapshot all evidence.
- Examples are useful demonstrations, not proof. Some example citations and reports are illustrative, and the showcase itself documents a post-publication audit that found 21/68 reference issues after prior automated checks.
- License limits adoption. CC BY-NC 4.0 is intentionally source-available for noncommercial use, not open source in the permissive software sense.

## Ideas To Steal

- Build a "Task Passport" for coding agents: issue context, files touched, test evidence, dependency versions, review decisions, unresolved risks, and reset boundaries.
- Use corpus adapters plus rejection logs for user-owned source sets. For coding, this could adapt docs, ADRs, tickets, incident reports, API specs, and legacy code inventories into a validated project corpus.
- Make source screening reproducible. The PRE-SCREENED block pattern should become a standard section for any agent that consumes curated context: included, excluded, skipped, why, snapshot date, adapter origin.
- Split claim intent from emitted prose/code. Claim-intent manifests are transferable to coding as "planned changes / expected invariants / negative constraints" before implementation.
- Add cite/claim anchors for every important assertion. In coding, assertions about behavior should anchor to tests, source lines, logs, docs, or benchmark output.
- Use reviewer sprint contracts. Before code review, have reviewer agents commit to acceptance dimensions and failure conditions, then evaluate the patch against the pre-committed rubric.
- Add re-review traceability. A response-to-reviewers matrix maps naturally to PR review comments: original concern, author's claim, changed location, independent verification, residual issue.
- Treat advisory and blocking signals differently. Do not let weak heuristics block merges by default, but do record them visibly with a path to stricter opt-in policy.
- Preserve "not reproducible" honesty. A lockfile for model, prompt, tool, and material configuration is useful even when exact replay is impossible.
- Pair prompt contracts with deterministic lints wherever possible. The repo's best controls are not the prose rules alone, but the schema and Python checks that make drift visible.

## Do Not Copy

- Do not copy the end-to-end paper-writing posture into coding work. The useful part is the audit/review machinery, not automated manuscript production.
- Do not rely on prompt-only phase fences for high-risk boundaries. If a coding workflow needs "reviewer did not see answer key" or "writer cannot edit verification artifacts", enforce that with process isolation or a tool boundary.
- Do not treat design specs as shipped behavior. This repo contains many careful future specs; adoption should distinguish implemented scripts from planned mechanisms.
- Do not import CC BY-NC content into commercial or permissively licensed products without legal review.
- Do not use synthetic gold sets as the whole evaluation story. They are good for regression testing shape and obvious failures, but real domain corpora and human-labeled cases are still needed.
- Do not create a giant mode surface unless routing is controlled. The suite's breadth is powerful, but a coding-agent workflow should keep command entrypoints smaller and more machine-checkable.
- Do not let a same-model verifier be the only integrity gate. The repo's own docs show same-model citation checks missed serious issues until manual/cross-model/deterministic layers were added.

## Fit For Agentic Coding Lab

Fit is conditional but strong as a pattern source. The repo is not a coding framework, yet it is one of the richest public examples of a domain-specific agent workflow that treats evidence, review, revision, and integrity as first-class artifacts.

The highest-value adoption path is to translate concepts rather than content:

- Material Passport -> task/run passport for coding work.
- Literature corpus -> project evidence corpus with docs, tickets, logs, specs, and code inventories.
- Integrity gate -> test/build/static-analysis/provenance gate before review.
- Peer review panel -> pre-committed review rubric plus independent reviewer roles.
- Re-review matrix -> PR comment resolution verification.
- Claim audit -> assertion-to-evidence audit for changelogs, migration parity, benchmark claims, and security claims.
- Temporal audit -> release/version/date consistency checks for migration and dependency work.
- Calibration and gold sets -> regression harnesses for agent claims and tool outputs.

Agentic Coding Lab should not copy the full academic package. It should mine ARS for artifact schemas, gate taxonomy, and review-loop mechanics, then rebuild them around code-native evidence and enforceable tool/runtime boundaries.

## Reviewed Paths

- `README.md`: product scope, install flow, feature summary, workflow modes, showcase, and changelog.
- `POSITIONING.md`, `LICENSE`, `NOTICE.md`, `SECURITY.md`: license posture, noncommercial constraints, human-in-loop positioning, vulnerability scope.
- `.claude-plugin/plugin.json`, `commands/ars-full.md`, `commands/ars-mark-read.md`: plugin metadata and command surface.
- `MODE_REGISTRY.md`: 25-mode registry and oversight levels.
- `docs/ARCHITECTURE.md`: stage matrix, data-access flow, skill graph, literature corpus flow, and quality gates.
- `CHANGELOG.md`: recent release history, bug-fix evidence, CI/test-count claims, and shipped/deferred feature boundaries.
- `deep-research/SKILL.md`, `academic-paper/SKILL.md`, `academic-paper-reviewer/SKILL.md`, `academic-pipeline/SKILL.md`: core skill definitions, agent teams, orchestration, modes, and checkpoint rules.
- `deep-research/agents/bibliography_agent.md`, `academic-paper/agents/literature_strategist_agent.md`, `deep-research/agents/source_verification_agent.md`: literature search, corpus-first screening, distributional skew advisory, source grading, and S2/DOI/WebSearch verification.
- `academic-pipeline/agents/integrity_verification_agent.md`: reference verification, citation context, originality, claim verification, gray-zone prevention, and cross-model option.
- `academic-pipeline/agents/claim_ref_alignment_audit_agent.md`: claim-faithfulness audit flow, retrieval/judge/cache behavior, sampling, defect stages, drift, uncited assertions, and constraint violations.
- `academic-pipeline/agents/pipeline_orchestrator_agent.md`: stage detection, checkpoint management, passport reset, and resume obligations.
- `academic-paper-reviewer/SKILL.md`, `academic-paper-reviewer/references/sprint_contract_protocol.md`, `academic-paper-reviewer/references/re_review_mode_protocol.md`, `academic-paper-reviewer/references/calibration_mode_protocol.md`, `academic-paper-reviewer/references/review_quality_thinking.md`: reviewer panel, pre-commitment, re-review traceability, calibration, and review heuristics.
- `shared/handoff_schemas.md`, `shared/ground_truth_isolation_pattern.md`, `shared/artifact_reproducibility_pattern.md`, `shared/cross_model_verification.md`: cross-stage contracts, data isolation, reproducibility honesty, and optional second-model review.
- `shared/prisma_trAIce_protocol.md`, `shared/compliance_checkpoint_protocol.md`, `shared/agents/compliance_agent.md`, `shared/compliance_report.schema.json`: compliance gates, PRISMA-trAIce/RAISE behavior, override ladder, and disclosure addendum flow.
- `shared/contracts/passport/*.schema.json`, `shared/sprint_contract.schema.json`, `shared/contracts/reviewer/*.json`, `shared/contracts/writer/full.json`, `shared/contracts/evaluator/full.json`: schema-backed passport and sprint-contract surfaces.
- `scripts/claim_audit_pipeline.py`, `scripts/check_claim_audit_consistency.py`, `scripts/claim_audit_calibration.py`, `scripts/test_claim_audit_calibration.py`: executable claim-audit implementation, invariants, calibration runner, and tests.
- `scripts/temporal_integrity_audit.py`, `docs/design/2026-05-18-ars-v3.9.4-temporal-verification-spec.md`: deterministic temporal audit and design boundaries.
- `scripts/adapters/README.md`, `scripts/adapters/{folder_scan,zotero,obsidian}.py`, `scripts/check_literature_corpus_schema.py`: literature corpus adapter architecture and validation.
- `.github/workflows/pytest.yml`, `.github/workflows/spec-consistency.yml`, `.github/workflows/freshness-check.yml`, `.github/workflows/test-count-monotonic.yml`: CI coverage and drift gates.
- `evals/gold/citation_extraction/*`, `scripts/check_evals_gold_set.py`, `scripts/test_check_evals_gold_set.py`, `docs/design/2026-05-21-v3.10-184-extend-eval-harness-spec.md`: emerging eval harness design and shipped citation-extraction gold subset.
- `examples/showcase/README.md`, `deep-research/examples/systematic_review.md`, `academic-paper/examples/revision_mode_example.md`, `academic-paper-reviewer/examples/hei_paper_review_example.md`: example artifact shapes and demonstration outputs.

## Excluded Paths

- Binary PDFs under `examples/showcase/` were not opened in full because the review focused on workflow design, schemas, and text artifacts; the showcase README was sufficient to understand artifact coverage and caveats.
- Localized README translations (`README.zh-CN.md`, `README.zh-TW.md`, `README.ja-JP.md`) were not reviewed deeply because they mirror the English user-facing content and do not materially change execution design.
- The full license text after the CC BY-NC summary was not analyzed beyond adoption implications; legal interpretation is outside this research note.
- Most generated fixtures under `tests/fixtures/**` and all 50 individual citation-extraction tuple files were sampled through manifests, validators, and tests rather than exhaustively read one by one.
- External source claims in the repo documentation were not independently re-verified against the cited papers or websites during this review; the note evaluates the repository's workflow artifacts and implementation surfaces.
- The sibling Codex distribution referenced by the README was not cloned because the owned candidate is the Claude Code reference repo.
