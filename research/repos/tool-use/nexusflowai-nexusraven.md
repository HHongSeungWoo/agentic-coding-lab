# nexusflowai/NexusRaven

- URL: https://github.com/nexusflowai/NexusRaven
- Category: tool-use
- Stars snapshot: 322 (GitHub repository page, captured 2026-05-20)
- Reviewed commit: f32882763bb3e220722883821919c14abdd3d156
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a compact function-calling model/eval reference, especially for Python-signature prompt schemas, context-scoped tool lists, and exact-match evaluation. Not suitable as an Agentic Coding Lab runtime because execution uses `eval`/`exec`, vendor ToolBench scripts run broad shell/network setup, and the repo has no permission layer, sandbox, regression tests, or durable error taxonomy.

## Why It Matters

NexusRaven is relevant because it shows a very small, model-facing tool-use contract: serialize callable Python functions into prompt options, ask the model for one Python call, stop before reflection text, parse the call, and compare it against a reference call. This is close to the core failure mode Agentic Coding Lab must handle: models can often choose a tool and arguments, but the host must decide which schemas are visible, how to parse calls, where execution is allowed, and how errors become evidence for repair.

The repo is also a useful warning. The demo and evaluation paths blur prompt formatting, generated Python functions, model output parsing, and execution. That makes reproduction easy for benchmarks, but unsafe as a general coding-agent substrate.

## What It Is

The repository contains the NexusRaven-13B function-calling prompt format, example LangChain and non-LangChain usage, scripts to reproduce evaluations against several baselines, static query datasets, and conversion utilities for standardizing API/function descriptions.

There are three main parts:

- Prompt examples: `README.md`, `docs/prompting_readme.md`, `scripts/non_langchain_example.py`, and `scripts/langchain_example.py`.
- Evaluation runtime: `raven/eval/evaluator.py`, `raven/eval/raven_utils.py`, `raven/utils.py`, and shell wrappers in `scripts/evaluate_*.sh`.
- Dataset and ToolLLM conversion: `raven/data/*.py` plus API/query resources under `raven/data/resources`.

The repo is not a production agent runtime. It is an evaluation harness and data-processing package for single-turn function-call selection.

## Research Themes

- Token efficiency: Medium. The prompt uses compact delimiters around only the candidate function signatures/docstrings for the current task, and the runtime stops generation at `"\nReflection:"` to avoid paying for post-call reflection. It does not implement output truncation except in copied ToolBench observation logic.
- Context control: Medium. Each sample carries `context_functions`, and `Evaluator.run()` rebuilds an agent with only those tools per sample. README notes retrieval is needed when many functions saturate context, but this repo does not implement retrieval for NexusRaven itself.
- Sub-agent / multi-agent: None. No subagents, delegation, or multi-agent orchestration.
- Domain-specific workflow: Medium. Cybersecurity-flavored datasets cover CVE/CPE, VirusTotal, and EmailRep, with ToolAlpaca and ToolLLM conversions for broader APIs. The reusable pattern is domain API normalization into Python signatures and docstrings.
- Error prevention: Low to medium. There is some deterministic parsing with `ast.literal_eval`, exact function/argument comparison, LangChain `max_iterations=1` for baseline agents, and broad exception capture during eval. There is no sandbox, permission gate, schema validator before execution, or adversarial tool-output handling.
- Self-learning / memory: None. State is limited to per-run datasets, cache path, and printed evaluation traces.
- Popular skills: Function schema serialization, prompt grammar design, context-scoped tool registry, model-output parsing, benchmark normalization, exact-match call evaluation, stop-sequence control.

## Core Execution Path

NexusRaven direct prompt path:

1. A host builds a prompt beginning with `<human>:` and one `OPTION` block per available function.
2. Each tool is represented as `<func_start>def ...<func_end>` plus `<docstring_start>...<docstring_end>`.
3. The user request is appended as `User Query: Question: ...`, followed by a fixed instruction to pick a function and fill arguments.
4. The model generates text containing `Initial Answer: <python_call>`, sometimes followed by `Reflection:`.
5. Examples slice or parse the text to keep the initial call only.
6. Demo code executes the call with `eval()` or `exec()`, which is acceptable for a toy script but not for untrusted model output.

LangChain evaluation path:

1. `scripts/evaluate_nexusraven.sh` calls `raven/eval/evaluator.py` with `llm_name=nexusraven`, `agent_name=NEXUSRAVEN`, and the Hugging Face dataset config names.
2. `Evaluator.__post_init__()` creates a `ToolLLMEvaluationDataHelper` for the special ToolLLM dataset.
3. `Evaluator.build_functions()` loads standardized API rows from Hugging Face and calls `raven.utils.build_functions()`.
4. `build_functions()` constructs Python function strings from dataset fields and `exec()`s them into local scope. Each generated function returns `(name, locals())` instead of calling a real API.
5. `Evaluator.run()` creates LangChain `StructuredTool` wrappers for generated functions, then iterates over eval samples.
6. For each sample, `context_tools = [tools[k] for k in sample["context_functions"]]` restricts the visible registry to functions relevant to that sample.
7. `build_agent(..., "NEXUSRAVEN")` creates a `RavenPromptTemplate`, `LLMChain`, `RavenOutputParser`, and `LLMSingleActionAgent` with stop sequence `"\nReflection:"`.
8. The agent returns a string call. If execution did not already return a tuple, `parse_function_call_to_name_and_args()` parses the call with `ast.parse` and `ast.literal_eval`, then the matching generated function is invoked by name.
9. Reference calls are loaded from either dataset fields or `reference_function_call`; one branch uses `eval(reference_function_call)`.
10. Accuracy is exact match on predicted function name and normalized argument dict.

Baseline/eval orchestration:

1. `Evaluator.build_llm()` selects OpenAI chat/completion models, Hugging Face Text Generation Inference, or a saved response config.
2. `build_agent()` supports OpenAI Functions, LangChain structured chat/react baselines, NexusRaven prompt parsing, ToolLLM replay, and ToolAlpaca replay.
3. ToolLLM and ToolAlpaca baselines are not live agents in the main evaluator. They are `MagicMock` agents that map prompts to previously captured function-call strings.
4. `run_toolllm.py` handles the expensive ToolBench path: delete old outputs, clone OpenBMB/ToolBench into `cache/ToolBench`, install requirements, download data, write customized API files, run ToolBench inference, parse `results.txt`, then push responses to Hugging Face.

Dataset standardization path:

1. `upload_raw_queries.py` packages local JSON query files for `cve_cpe`, `emailrep`, `virustotal`, `toolalpaca`, and `toolllm`.
2. `upload_standardized_api_list.py` converts API definitions into rows with `dataset`, `name`, `description`, and `args_dicts`, then validates generated functions by calling `build_functions()`.
3. CVE/CPE and VirusTotal definitions are parsed from Python files with `ast.parse`; EmailRep definitions are hand-authored; ToolAlpaca definitions are extracted from prompt/docstring blocks.
4. `upload_standardized_queries.py` converts references into `python_function_name`, `python_args_dict`, and `context_functions`.
5. `upload_queries_in_toolllm_format.py` converts standardized rows into ToolLLM JSON descriptions and Python files, lowercases/sanitizes names through `xxx` markers, and includes copied ToolBench `rapidapi.py`/`server.py` custom files.

## Architecture

The architecture is dataset-driven rather than registry-driven. The "tool registry" is the standardized API list dataset; each row becomes a generated Python function. The per-sample `context_functions` field is the selection layer. There is no long-lived registry service, capability metadata store, approval system, or runtime policy engine.

The model-facing schema is deliberately Pythonic. Function signatures carry argument names, Python type annotations, and defaults. Docstrings carry descriptions. This is friendly to code-trained models and easy to author by hand, but it is not a strict interchange schema. Types are normalized with string heuristics, not a complete JSON Schema or Pydantic model.

Execution boundaries are weak. The safe part of the eval path is that generated benchmark functions return a tuple instead of performing side effects. The unsafe part is that function definitions, reference calls, ToolAlpaca outputs, ToolLLM function strings, and demo model outputs are all processed through `exec()` or `eval()` in at least one path.

The copied ToolBench files are a second runtime embedded as resources. `rapidapi.py` defines an OpenAI-functions-style environment, a `Finish` tool, status-code mapping, optional retrieval, DFS/CoT execution, and result logging. `server.py` dynamically imports tool modules, builds call strings, `eval()`s them, maps common API errors, truncates observations to 2048 characters, and writes captured function calls to `results.txt`.

## Design Choices

- Python signatures as schema. This keeps prompts compact and natural for coding models, but loses machine-enforceable constraints such as enum validation, nested object schemas, and explicit side-effect policy.
- Context-scoped tools per sample. `context_functions` narrows visible tools for each evaluation sample and is the most reusable registry pattern in the repo.
- Single-turn call selection. NexusRaven is evaluated as one call, not ReAct. This makes latency and scoring simpler, but it does not cover multi-step coding workflows.
- Stop before reflection. The model may produce reflection text, but callers stop at `"\nReflection:"` and treat `Initial Answer` as the executable call.
- Exact-match scoring. The evaluator compares function name and argument dict exactly, with a float-to-int normalization hack to avoid representation drift.
- Baseline replay through mocks. ToolLLM and ToolAlpaca outputs can be replayed as prompt-to-call maps, separating expensive generation from scoring.
- Hugging Face datasets as artifact storage. Query sets, standardized API lists, ToolLLM custom files, and generated outputs are pushed to hub configs.
- ToolBench compatibility over local simplicity. The ToolLLM path copies and patches ToolBench files rather than building a small in-repo executor.

## Strengths

- Very clear model-facing prompt grammar for function-call selection.
- Good example of using docstrings and signatures as lightweight tool schemas.
- Per-query `context_functions` is a useful pattern for keeping tool context small.
- Evaluation flow separates API normalization, query normalization, model generation, and exact-match scoring.
- `parse_function_call_to_name_and_args()` uses `ast.parse` and `ast.literal_eval` for generated calls instead of raw eval in the main prediction parser.
- LangChain adapter shows how to wire a custom prompt/output parser into a standard agent executor with one allowed call.
- README is explicit about major model limitations: reflection should usually be stopped, many tools need retrieval, and generated calls can be wrong.
- Dataset tooling documents several practical normalization problems: invalid Python names, mixed type strings, defaults, camelCase/lowercase conversions, and benchmark-specific gaps.

## Weaknesses

- Demo execution is unsafe. `scripts/non_langchain_example.py` calls `eval(function_call)`, and `scripts/langchain_example.py` ends with `print(exec(call))`.
- Benchmark construction also relies on dynamic code. `raven.utils.build_functions()`, `ToolLLMEvaluationDataHelper.build_functions()`, copied `server.py`, and ToolAlpaca/ToolLLM parsing paths use `exec()` or `eval()`.
- No permission or sandbox model exists. Tools can represent network APIs, reports, comments, votes, or local code execution, but there is no approval boundary around side effects.
- No runtime validation layer rejects unknown/extra arguments before dispatch beyond Python/AST failures.
- Error handling is broad and print-oriented. Exceptions become text in evaluation output; there is no typed diagnostic envelope for automated repair.
- No tests or CI-style regression suite are present in the checked-out repo.
- ToolLLM setup path uses `os.system()` with `rm -rf`, `git clone`, `pip install`, `wget`, and `unzip` inside a generated multi-line shell command.
- Prompt parsing is brittle. `RavenOutputParser` assumes the answer is on line 2 and contains `Initial Answer:`.
- The repo includes API-key-like strings in static evaluation queries. They appear to be dummy values, but the pattern would be risky with real user traces.
- Some evaluation code is intentionally incomplete or hardcoded, especially ToolAlpaca reproduction and ToolLLM data integration.

## Ideas To Steal

- Represent small tool sets as Python signatures plus docstrings when targeting coding-specialized models, but compile that representation from a stricter source schema.
- Add a per-task `context_functions` field to tool-use traces so evaluation can distinguish registry selection from call generation.
- Stop generation before reflection/scratchpad sections and execute only a narrow final-call channel.
- Keep benchmark functions as pure stubs that return `(tool_name, args)` so scoring never needs real API side effects.
- Build replayable baselines by storing prompt-to-call outputs and scoring them later through the same evaluator.
- Normalize API definitions into a common table: dataset/domain, function name, description, args, required flag, default, and type.
- Use exact-match function/argument scoring as a first-pass harness, then add richer semantic validators for coding tools where exact values can differ.
- Record failed parse/execution details next to prompt, reference, prediction, and sample index. The print format is crude, but the evidence bundle is useful.
- Treat tool retrieval as a required front-end for large registries. README calls this out even though the NexusRaven path does not implement it.

## Do Not Copy

- Do not execute model-generated calls with `eval()` or `exec()`. Parse into an AST or JSON call envelope, validate against a registry, then dispatch by function ID through a permissioned executor.
- Do not use Python signatures/docstrings as the sole authority. Keep JSON Schema/Pydantic/protobuf-style specs as source of truth and generate prompt text from them.
- Do not let benchmark datasets contain real secrets. Add redaction and synthetic-secret checks before storing user-like queries.
- Do not run setup commands through large `os.system()` blobs. Use explicit subprocess calls, pinned revisions, timeouts, and a cache policy.
- Do not map ToolLLM/ToolAlpaca outputs with `eval()` during scoring. Use literal parsers plus schema validation.
- Do not rely on line-position parsing for model outputs. Require a structured final-call block or provider-native tool-call object.
- Do not equate a pure benchmark stub with a safe production tool. Side-effecting APIs need approvals, audit logs, rate limits, and rollback/compensation policy.
- Do not copy vendored ToolBench runtime code into Agentic Coding Lab without isolating network execution and deleting dynamic import/eval paths.

## Fit For Agentic Coding Lab

Fit is conditional and pattern-level. NexusRaven is valuable for studying function-call prompt schemas and evaluation traces, not for adopting runtime code.

Best-fit artifacts:

- A prompt schema generator that can render tool definitions as Python signatures/docstrings for coding models.
- A `context_functions` or `visible_tools` field in every eval sample and trace.
- A pure-stub scoring harness where tools return normalized `(name, args)` without side effects.
- A benchmark converter that can ingest API definitions from Python, JSON, and benchmark-specific formats into one canonical registry.
- A replay mode for stored model outputs so scoring and reporting do not require live model/API calls.

Required changes before reuse:

- Replace `eval`/`exec` with a validated call envelope and controlled dispatch table.
- Add strict schema validation, unknown-argument rejection, enum validation, and clear error codes.
- Add permission classes for read-only, write, network, credentials, filesystem, and shell tools.
- Add regression tests for prompt rendering, parser failures, schema conversion, context filtering, and scoring.
- Add provenance fields to tool definitions and query rows so copied/vendor/generated data is distinguishable.

## Reviewed Paths

- `README.md`: project purpose, setup, prompt format, model usage, evaluation commands, supported datasets, future-release gaps, limitations, and license notes.
- `docs/prompting_readme.md`: detailed prompt grammar, ChatML-like tags, function/docstring blocks, zero-shot and few-shot query formatting, and `Initial Answer`/`Reflection` extraction.
- `pyproject.toml`: package metadata, dependencies, Python version, lint settings, and ignored resource paths.
- `scripts/non_langchain_example.py`: direct Transformers path, prompt construction from `inspect.getsource`, generated-call slicing, and unsafe `eval()` execution.
- `scripts/langchain_example.py`: LangChain `StructuredTool` path, custom prompt template, output parser, stop sequence, and unsafe `exec()` demo ending.
- `scripts/evaluate_*.sh`: thin model/agent wrappers around `raven/eval/evaluator.py`.
- `raven/__init__.py`: cache directory setup through `HF_DATASETS_CACHE`.
- `raven/utils.py`: dynamic function generation, Python-call parsing with `ast`, literal argument extraction, and float normalization.
- `raven/eval/raven_utils.py`: NexusRaven prompt template and output parser used by the evaluator.
- `raven/eval/evaluator.py`: main evaluation loop, LLM selection, agent construction, context-scoped tool filtering, exact-match scoring, ToolLLM/ToolAlpaca replay, and broad error capture.
- `raven/eval/run_toolllm.py`: ToolBench clone/install/download orchestration, custom file injection, ToolLLM inference command, result parsing, and Hugging Face output upload.
- `raven/data/upload_raw_queries.py`: local JSON query packaging into Hugging Face dataset configs.
- `raven/data/upload_standardized_api_list.py`: API definition normalization for CVE/CPE, EmailRep, VirusTotal, and ToolAlpaca.
- `raven/data/upload_standardized_queries.py`: reference-call parsing, context-function construction, and query normalization.
- `raven/data/upload_queries_in_toolllm_format.py`: conversion into ToolLLM Python/API JSON files, name casing transforms, query IDs, and custom ToolBench file injection.
- `raven/data/toolllm_evaluation_data_utils.py`: ToolLLM raw-query parsing, generated function construction, and special eval dataset assembly.
- `raven/data/process_toolalpaca_evaluation_data.py`: ToolAlpaca fetch/postprocess, function signature extraction, type mapping, golden-answer conversion, and local JSON output.
- `raven/data/resources/cve_cpe_function_definitions.py`: two NVD-style function definitions and docstring schema source.
- `raven/data/resources/virustotal_function_definitions.py`: VirusTotal function definition/docstring schema source.
- `raven/data/resources/*_queries.json`: static benchmark query/reference data; reviewed shape and representative examples, not every query line.
- `raven/data/resources/server.py`: copied ToolBench server with dynamic import/eval, error classification, observation shortening, and function-call logging.
- `raven/data/resources/rapidapi.py`: copied ToolBench runtime with OpenAI-function schema conversion, `Finish` tool, optional retrieval, DFS/CoT orchestration, status codes, output files, and call logging.
- `CODE_LICENSE` and `DATA_LICENSE`: code/data licensing split relevant to reuse decisions.

## Excluded Paths

- `.git/`: repository metadata only; used only to identify reviewed commit.
- `cache/.gitignore`: empty cache placeholder, not runtime logic.
- `docs/*.png`: README/marketing diagrams and screenshots. Excluded as UI/binary assets with no execution, schema, permission, or error-handling logic.
- `raven/data/resources/*_queries.json` exhaustive contents: treated as static/generated benchmark data. I reviewed counts, schema shape, and representative samples, but did not inspect every query because the execution patterns live in the processors/evaluator.
- Vendored/copy-derived ToolBench files `raven/data/resources/server.py` and `raven/data/resources/rapidapi.py`: reviewed only for integration-relevant execution boundaries, dynamic execution, error handling, and orchestration. Not treated as original NexusRaven architecture.
- Generated outputs from running evaluations: not present in the checked-out tree and not reviewed.
- Test paths: none found with `rg --files -g '*test*' -g '*pytest*'`.
