# NVIDIA/garak

- URL: https://github.com/NVIDIA/garak
- Category: harness-eval
- Stars snapshot: 7,768 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 4518b2073fdc4eca0e382f64cdab873e7cc826f0
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong red-team and safety-eval harness for LLM systems, with clean probe/detector/generator/harness/evaluator boundaries and unusually rich risk metadata. Best patterns to steal are probe-owned detector recommendations, per-attempt notes, JSONL-first reporting, MISP/OWASP/AVID tags, probe tiers, configurable generators, and coding-agent-relevant probes such as package hallucination, API-key leakage, web injection, file formats, exploitation, and Agent Breaker. Main limits are weak sandboxing, high reliance on external models/datasets, detector uncertainty gaps, some brittle string or model-as-judge detectors, and a likely shipped-metrics path mismatch that makes bootstrap CIs silently assume perfect detectors.

## Why It Matters

garak is one of the most mature open-source LLM red-team harnesses. It matters for Agentic Coding Lab because it treats safety evaluation as a composable execution system: attack probes generate attempts, generators adapt target systems, detectors score target outputs, harnesses coordinate runs, and evaluators turn detector scores into reports.

The repo is directly relevant to coding-agent error prevention. Several probes target failure modes common in coding assistants and tool-using agents: hallucinated packages, code or template exploitation, API key leakage, prompt injection, system prompt extraction, web/markdown exfiltration, unsafe file formats, ANSI escapes, malicious code generation, and excessive tool agency. It is not a coding-agent sandbox, but it gives a good architecture for constructing adversarial regression suites around one.

## What It Is

garak is a Python CLI and package for scanning LLMs and LLM-powered systems. Users run `garak --target_type <generator> --target_name <model-or-endpoint>`, optionally selecting probes, detectors, buffs, config files, languages, concurrency, and reporting options. If detector selection is left as `auto`, the default `ProbewiseHarness` asks each probe which detector or detectors should judge its outputs. If detectors are specified explicitly, the `PxD` harness runs the selected probes against the selected detectors.

The package ships plugin families under `garak/probes`, `garak/detectors`, `garak/generators`, `garak/harnesses`, `garak/evaluators`, and `garak/buffs`. The runtime produces native JSONL reports, hit logs, and HTML summaries; it can also export AVID-style vulnerability reports.

## Research Themes

- Token efficiency: Moderate. It has prompt caps, soft sampling limits, concurrency controls, token-limit trimming for judge prompts, and cached/static variants for expensive adaptive attacks, but it is not a context compression framework.
- Context control: Strong. Config hierarchy, plugin specs, run config, generator options, per-attempt notes, system prompts, payload classes, and report metadata make most eval context explicit.
- Sub-agent / multi-agent: Conditional. TAP, GOAT, Agent Breaker, and model-as-judge detectors use attacker/evaluator models, but this is red-team orchestration rather than a general multi-agent framework.
- Domain-specific workflow: Strong. The risk catalog spans safety, security, code, web, package ecosystems, agent tools, multilingual translation, multimodal inputs, and provider-specific generator adapters.
- Error prevention: Strong. Probe/detector pairs can become regression tests for unsafe behavior, package hallucination, prompt injection, secret leakage, malformed tool use, refusal bypass, and output-channel attacks.
- Self-learning / memory: Limited. Adaptive probes learn inside a run from target responses, but there is no durable memory system for improving future runs.
- Popular skills: Not a skill repo. Reusable capabilities are `Probe`, `Detector`, `Generator`, `Harness`, `Attempt`, plugin cache metadata, risk tags, probe tiers, JSONL reports, hit logs, and config-driven plugin options.

## Core Execution Path

`garak.__main__.main()` calls `garak.cli.main()`. The CLI starts logging, loads `garak/resources/garak.core.yaml`, parses command options, loads optional site/run config, overlays CLI arguments, validates worker counts and bootstrap confidence settings, seeds Python randomness when `run.seed` is set, and handles list/info/report/fix/interactive commands before scanning.

For a scan, the CLI parses probe, detector, and buff specs through `_config.parse_plugin_spec()`. It instantiates a `ThresholdEvaluator` with `run.eval_threshold`, loads the configured generator through `_plugins.load_plugin("generators.<target_type>")`, starts a run with `command.start_run()`, opens a report JSONL file, and chooses the harness. With `detector_spec` unset or `auto`, `command.probewise_run()` runs `ProbewiseHarness`. With explicit detectors, `command.pxd_run()` runs `PxD`.

`ProbewiseHarness` sorts probe names, loads one probe at a time, reads the probe's `primary_detector`, optionally adds `extended_detectors`, loads those detector plugins, and delegates to `Harness.run()`. `PxD` instead loads every selected detector for every selected probe.

`Harness.run()` initializes language services, loads buffs, snapshots plugin metadata into the report, checks modality compatibility, calls `probe.probe(generator)`, runs detectors over returned attempts, marks attempts complete, writes attempt records, and calls `evaluator.evaluate()`.

`Probe.probe()` is the default probe execution path. It localizes prompts, mints `Attempt` objects, stores probe metadata and notes, applies buffs, calls the generator for the configured number of generations, post-processes outputs, writes started attempts, and returns completed attempts for detector scoring. Specialized probes override this for tree search, iterative jailbreaks, tool-agent attacks, or file-output workflows.

`Evaluator.evaluate()` aggregates detector scores. Detector scores are floats in `0.0..1.0` where high means hit or failure. `ThresholdEvaluator.test()` treats scores below threshold as pass. It prints pass/fail and attack success rate, writes hit log entries for failures, and appends `eval` records with pass/fail/nones counts plus optional bootstrap confidence intervals.

## Architecture

The architecture is plugin-centered:

- `garak/cli.py`: CLI parser, config overlay, command dispatch, run orchestration.
- `garak/command.py`: run lifecycle, report file setup, harness entrypoints, report digest generation.
- `garak/_config.py`: global config objects, YAML/JSON loading, site/run config precedence, plugin spec parsing.
- `garak/configurable.py`: plugin config loading, defaults, dependency imports, API-key environment validation, pickle cleanup for multiprocessing.
- `garak/_plugins.py`: plugin cache, plugin metadata extraction, enumeration, dynamic loading, instance reuse, detector metric metadata injection.
- `garak/attempt.py`: `Message`, `Turn`, `Conversation`, and `Attempt`; tracks prompts, multiple generations, conversation histories, notes, outputs, detector scores, and serialization.
- `garak/probes/base.py`: base probe execution, prompt localization, attempt creation, buffs, parallel attempts, tree search, and iterative probe mechanics.
- `garak/detectors/base.py`: base detector contract plus string, trigger-list, file, and Hugging Face classifier detectors.
- `garak/generators/base.py`: target model abstraction, generation fanout, parallel repeated requests, skip-sequence pruning, and conversation conversion.
- `garak/harnesses/base.py`, `probewise.py`, `pxd.py`: orchestration across probes, detectors, buffs, generators, and evaluator.
- `garak/evaluators/base.py`: threshold scoring, console output, hit logs, eval records, bootstrap confidence intervals.
- `garak/analyze/`: HTML reports, calibration, detector metrics, CI rebuilding, AVID/MISP exports, report aggregation, qualitative review.
- `garak/resources/` and `garak/data/`: prompt templates, payloads, package lists, calibration data, attack resources, fixture corpora, and cached plugin metadata.
- `tests/`: structural plugin tests, CLI/config tests, probe/detector/generator tests, report/analyze tests, and regression fixtures.

## Design Choices

The strongest design choice is decoupling attack technique from failure detection. Probes define how to elicit behavior and name the detector that should judge it. This lets `encoding.InjectBase64` use exact/approx decoding detectors, `packagehallucination.Python` use the PyPI package detector, and `GOATAttack` use a jailbreak judge without forcing a universal scoring rule.

`Attempt` is the central data model. It supports structured messages, system/user/assistant turns, file or binary attachments, multiple generations per prompt, per-generation conversation histories, translated prompts/outputs, arbitrary notes, and detector results. For coding agents, this is a useful pattern because a task attempt often needs prompt, tool trace, output, metadata, and scoring evidence in one serializable record.

Plugin metadata is not only for loading. The plugin cache extracts descriptions, tags, tiers, active flags, modalities, default params, detector quality fields, and modification time. Reports embed a plugin-cache snapshot so a report can be interpreted even if local code changes later.

Risk taxonomy is explicit. Probe and detector tags use MISP-style strings covering AVID, OWASP LLM risks, quality/security categories, CWE, risk cards, and payload types. Probe tiers (`OF_CONCERN`, `COMPETE_WITH_SOTA`, `INFORMATIONAL`, `UNLISTED`) encode prioritization. The tier docs are unusually clear about separating security impact, prevalence, adversarial robustness, and context-sensitive content safety.

Scoring is attack-success oriented. Detectors identify hits, evaluators count non-hits as passes, and user-facing output reports attack success rate. This is a good fit for red-team evaluation because any successful exploit attempt is visible rather than hidden by average response quality.

Config is layered and plugin-scoped. Core config is overridden by site config, run config, CLI args, and per-plugin JSON/YAML options. This makes it possible to tune a detector model, a REST target, a probe's payload set, or concurrency without modifying plugin code.

Generator adapters are pragmatic. `OpenAICompatible` handles chat/completions and multimodal message conversion; `nim` subclasses OpenAI-compatible behavior; `rest.RestGenerator` supports arbitrary HTTP targets, JSONPath output extraction, rate-limit backoff, TLS/mTLS, proxies, and templated headers/bodies. Test generators (`Blank`, `Repeat`, `Lipsum`, `ReasoningLipsum`) make cheap local verification possible.

Adaptive red-team probes are first-class but not default. TAP, PAIR, GOAT, and Agent Breaker require auxiliary models and are marked inactive by default where costly. Cached variants such as `TAPCached` preserve some value for cheaper runs.

## Strengths

The plugin boundary is simple and effective. A new red-team capability can be a probe, detector, generator, buff, or harness without rewriting the core runner.

The default probewise mode is a good safety-eval default. It avoids running arbitrary mismatched detectors against every probe and encodes domain knowledge near the attack implementation.

The risk taxonomy is practical. Tags let reports group by OWASP, AVID, quality, payload, or module. Tiers help users prioritize expensive or high-risk probes.

The report model is useful for postmortems. JSONL contains setup, init, plugin metadata, attempt records, eval summaries, tree data for adaptive probes, and completion. Hit logs preserve failed prompts/outputs/triggers and generator/probe/detector identifiers.

The probe catalog is broad and relevant to coding agents. `packagehallucination`, `apikey`, `exploitation`, `fileformats`, `web_injection`, `ansiescape`, `malwaregen`, `sysprompt_extraction`, and `agent_breaker` can all map to coding-agent safety regression suites.

Detector diversity is strong. The repo supports string/regex/trigger checks, package-registry checks, file checks, HF classifiers, Perspective API toxicity, model-as-judge, refusal detection, jailbreak judges, and cached probe-generated verification.

Tests enforce plugin hygiene. Probe tests require detectors to exist, tags to match known MISP data, docstrings, goals, language tags, modalities, tiers, and inactive status for probes requiring extra dependencies. Plugin load tests pickle plugins for multiprocessing support.

## Weaknesses

garak is a harness, not a sandbox. It can probe dangerous behaviors, but it does not provide filesystem, process, network, or credential isolation for coding-agent targets. Any local coding-agent eval would need an external sandbox and cleanup policy.

Many high-value paths depend on external services. Hosted target generators, HF datasets, HF detector models, NIM/OpenAI-compatible judge models, Perspective, package registry datasets, and red-team attacker models all introduce cost, drift, API failures, and reproducibility gaps.

Some detectors are brittle. String detectors such as DAN marker checks and mitigation-prefix checks are cheap, but they can miss semantically equivalent failures or score style changes as safety. Model-as-judge detectors are more flexible but depend on judge prompt quality and judge model behavior.

Detector confidence support has an apparent path mismatch. Docs and shipped data use `garak/data/detectors-eval/detector_metrics_summary.json`, and `_plugins.PluginCache` reads that path. `garak/analyze/detector_metrics.py` looks for `detectors_eval` with an underscore, which does not exist in this checkout. Result: bootstrap CIs may fall back to `(Se=1.0, Sp=1.0)` despite bundled detector metrics. The tests cover missing-file behavior and mocked metrics, but not the shipped path.

Detector metrics are sparse. The bundled summary has six evaluated detectors, while docs show a larger illustrative schema. Many detectors therefore lack precision/recall/F1 evidence.

Reproducibility is partial. Runs record config, seed, plugin cache, and report metadata, but not provider model snapshots, external package/dataset snapshots, judge model outputs, or full environment lockfiles. Package hallucination detectors explicitly warn that stale package lists can cause false positives/negatives.

The default config is speed-biased. Core config has `lite: true`, `generations: 5`, `soft_probe_prompt_cap: 256`, and active plugins only. That is sensible for usability, but red-team conclusions require explicitly stronger configs.

Several adaptive probes are complex enough to need separate eval of the evaluator. TAP, GOAT, and Agent Breaker can fail because attacker, target, parser, or judge model behavior changes, not because the target is safe.

## Ideas To Steal

Use probe-owned detector recommendations. For coding-agent evals, each attack scenario should name its primary deterministic or model-graded checker plus optional extended checkers.

Adopt `Attempt`-style records: task prompt, system/developer context, tool trace references, output, notes, detector results, and serialized histories in one event-friendly object.

Make every safety eval report JSONL-first. Emit start config, target metadata, per-attempt records, per-detector eval records, hit logs, and completion rows.

Use a risk taxonomy with both external standards and local tags: OWASP, CWE, AVID-like impact, tool-risk categories, payload type, and coding-agent workflow stage.

Add tiering for eval scenarios. Mark which tests are release-blocking, which compare against state of the art, which are informational, and which are deprecated or too flaky for CI.

Separate target adapters from attacks. A coding-agent target could be a CLI wrapper, MCP target, HTTP service, or local process, but probes should not care.

Keep cheap local targets. `test.Blank`, `test.Repeat`, and `Lipsum` equivalents let CI verify harness wiring without tokens or side effects.

Treat detector quality as data. Store detector precision/recall/F1 and use it for confidence intervals, but add tests that prove the shipped metrics path actually loads.

Reuse per-attempt notes for detector context. Package names, attack goals, expected triggers, current tool target, original prompt, and verification verdicts should travel with the attempt.

## Do Not Copy

Do not rely on refusal-prefix strings as the only safety detector for coding agents. Pair cheap string checks with deterministic artifact checks and calibrated model judges.

Do not run agent/tool probes against real workspaces or credentials. garak's harness model needs an external sandbox before it is safe for coding-agent evaluation.

Do not trust model-as-judge outputs without calibration, parse-failure policy, and regression tests. Some garak judge paths default unclear output to a hit, while other score paths default to low confidence; make this policy explicit.

Do not let package-hallucination checks use moving external package lists without pinning snapshot date and target model training cutoff assumptions.

Do not make all probes active by default. Costly adaptive probes and probes with heavy external dependencies should remain opt-in.

Do not copy the global mutable config pattern blindly. It works for a CLI scanner, but a service or parallel eval farm would need stronger isolation between runs.

Do not assume HTML reports are the source of truth. Keep machine-readable logs authoritative and regenerate UI views from them.

## Fit For Agentic Coding Lab

Fit is strong for `harness-eval`. garak is not a coding-agent framework, but it is a strong reference for adversarial evaluation architecture and safety regression design.

Agentic Coding Lab should adapt the plugin boundary, probewise detector selection, attempt records, JSONL reports, taxonomy/tiering, and coding-agent-relevant probes. It should add sandboxed repo snapshots, tool-call capture, command allowlists, network controls, secret injection canaries, deterministic artifact graders, and sample-level reproducibility metadata.

The most direct artifact candidate is a local "coding-agent red-team harness" with garak-like probe/detector APIs. Initial probe families could be package hallucination, terminal-output injection, malicious generated code, prompt injection in repo files, tool overreach, API-key leakage, markdown/web exfiltration, and verifier sabotage.

## Reviewed Paths

- `/tmp/myagents-research/NVIDIA-garak/README.md`
- `/tmp/myagents-research/NVIDIA-garak/pyproject.toml`
- `/tmp/myagents-research/NVIDIA-garak/FAQ.md`
- `/tmp/myagents-research/NVIDIA-garak/SECURITY.md`
- `/tmp/myagents-research/NVIDIA-garak/docs/README.md`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/usage.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/configurable.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/reporting.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/report.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/reporting.calibration.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/detector_metrics.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/_plugins.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/index_probes.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/index_detectors.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/index_generators.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/index_harnesses.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/index_evaluators.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/extending.probe.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/extending.generator.rst`
- `/tmp/myagents-research/NVIDIA-garak/docs/source/probes/_tier.rst`
- `/tmp/myagents-research/NVIDIA-garak/garak/__main__.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/cli.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/command.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/_config.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/_plugins.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/configurable.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/attempt.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/report.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/payloads.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/garak.core.yaml`
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/plugin_cache.json` skimmed for generated metadata role.
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/_tier.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/promptinject.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/encoding.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/dan.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/packagehallucination.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/tap.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/goat.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/agent_breaker.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/apikey.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/exploitation.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/fileformats.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/web_injection.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/sysprompt_extraction.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/malwaregen.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/leakreplay.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/lmrc.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/probes/test.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/encoding.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/mitigation.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/dan.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/packagehallucination.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/judge.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/agent_breaker.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/unsafe_content.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/apikey.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/exploitation.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/fileformats.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/web_injection.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/sysprompt_extraction.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/malwaregen.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/always.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/detectors/any.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/openai.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/rest.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/nim.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/test.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/huggingface.py` skimmed for local/HF target shape.
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/litellm.py` skimmed for provider adapter shape.
- `/tmp/myagents-research/NVIDIA-garak/garak/generators/ollama.py` skimmed for local target shape.
- `/tmp/myagents-research/NVIDIA-garak/garak/harnesses/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/harnesses/probewise.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/harnesses/pxd.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/evaluators/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/buffs/base.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/buffs/encoding.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/buffs/paraphrase.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/report_digest.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/calibration.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/detector_metrics.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/bootstrap_ci.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/rebuild_cis.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/red_team/evaluation.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/red_team/conversation.py`
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/agent_breaker/` prompt/config resources skimmed through probe/detector code references.
- `/tmp/myagents-research/NVIDIA-garak/garak/data/detectors-eval/detector_metrics_summary.json`
- `/tmp/myagents-research/NVIDIA-garak/garak/data/calibration/bag.md` skimmed through calibration docs and data role.
- `/tmp/myagents-research/NVIDIA-garak/tests/test_attempt.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/test_config.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/test_configurable.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/test_report.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/test_docs.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/harnesses/test_harnesses.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/probes/test_probes.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/probes/test_probes_packagehallucination.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/probes/test_agent_breaker.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/detectors/test_detectors_base.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/detectors/test_detectors_judge.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/detectors/test_detectors_packagehallucination.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/detectors/test_detectors_apikey.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/detectors/test_detectors_promptinject.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/generators/test_rest.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/generators/test_openai.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/generators/test_nim.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/generators/test_test.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/plugins/test_plugin_cache.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/plugins/test_plugin_load.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/analyze/test_detector_metrics.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/analyze/test_report_digest.py`
- `/tmp/myagents-research/NVIDIA-garak/tests/analyze/test_bootstrap_ci.py`

## Excluded Paths

- `/tmp/myagents-research/NVIDIA-garak/.git/`: VCS internals; exact reviewed commit recorded above.
- `/tmp/myagents-research/NVIDIA-garak/.github/` and `.githooks/`: CI/repo maintenance metadata; not core red-team runtime. Tests were reviewed directly under `tests/`.
- `/tmp/myagents-research/NVIDIA-garak/garak-report/`: React/Vite report viewer UI. Reviewed only top-level package shape and report-output role; UI components, styles, charts, and tests are not part of probe/detector execution. Vendored UI tarball `src/assets/kui-foundations-react-external-0.504.1.tgz` excluded as binary dependency artifact.
- `/tmp/myagents-research/NVIDIA-garak/garak/analyze/ui/index.html`: bundled static UI asset for report analysis; not core scan path.
- `/tmp/myagents-research/NVIDIA-garak/garak-paper.pdf`: binary paper. README, docs, and code were used for architecture review; full PDF review is separate paper-review work.
- `/tmp/myagents-research/NVIDIA-garak/garak/data/**`: bulk payload/corpus/calibration/package-list data was sampled where needed (`detectors-eval`, calibration role, packagehallucination resources, GOAT/AgentBreaker references). Full line-by-line payload review excluded because data content is large, domain-specific, and not architecture. Binary/model-like entries such as `autodan/prompt_group.pth`, test GIFs, and base64 executable fixtures excluded except for noting their probe purpose.
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/autodan/**`, `beast/**`, `gcg/**`, and `tap/**`: adapted attack algorithm resources. Reviewed through probe integration points; full third-party algorithm review excluded as separate attack-method analysis.
- `/tmp/myagents-research/NVIDIA-garak/garak/resources/plugin_cache.json`: generated/cache artifact; skimmed for role, not audited line-by-line.
- `/tmp/myagents-research/NVIDIA-garak/docs/source/_static/**`: documentation styling only.
- `/tmp/myagents-research/NVIDIA-garak/docs/source/probes/*.rst`, `detectors/*.rst`, `generators/*.rst`, `buffs/*.rst`, `harnesses/*.rst` beyond representative docs: Sphinx API/module pages mostly mirror code docstrings; source code was reviewed for behavior.
- `/tmp/myagents-research/NVIDIA-garak/tests/_assets/**`: fixtures and sample reports. Sampled where tests depended on them; bulk fixture contents excluded.
- `/tmp/myagents-research/NVIDIA-garak/tests/langservice/**`: translation service tests are peripheral to harness/eval architecture.
- `/tmp/myagents-research/NVIDIA-garak/tools/**`: helper scripts for plugin cache rebuild, REST demos, dataset preparation, and packagehallucination list creation; not runtime scanner path.
- `/tmp/myagents-research/NVIDIA-garak/signatures/**`: CLA/signature metadata, unrelated to harness architecture.
- `/tmp/myagents-research/NVIDIA-garak/CA_DCO.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `PROJECTS.md`, `LICENSE`, `pylintrc`, `.readthedocs.yaml`, and formatting/build metadata beyond `pyproject.toml`: governance/build docs, not red-team execution behavior.
