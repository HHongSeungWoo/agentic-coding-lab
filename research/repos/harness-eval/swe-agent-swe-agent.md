# SWE-agent/SWE-agent

- URL: https://github.com/SWE-agent/SWE-agent
- Category: harness-eval
- Stars snapshot: 19,188 (GitHub REST API, captured 2026-05-12)
- Reviewed commit: 0f4f3bba990e01ca8460b9963abdcd89e38042f2
- Reviewed at: 2026-05-12
- Status: reviewed
- Scope fit: conditional
- Verdict: High-signal coding-agent harness and SWE-bench runner. Best reusable parts are the instance-source abstraction, SWE-ReX sandbox boundary, YAML-configured tool bundles, trajectory/replay artifacts, staged submit review, diff-state autosubmission, history processors, and sb-cli evaluation hook. Conditional because it is a full coding-agent application, and the README says current development has moved to mini-SWE-agent.

## Why It Matters

SWE-agent is one of the canonical open-source coding-agent systems built around SWE-bench. It is useful for this research track because it shows a complete path from benchmark instance selection to sandbox startup, repo reset, tool installation, agent loop, patch extraction, trajectory storage, prediction merging, and SWE-bench submission.

The repo matters less as a library to embed wholesale and more as a reference harness. Its strongest lessons are about making the environment and agent-computer interface explicit: every task gets a concrete deployment, repo source, problem statement, tool interface, prompt template, output directory, trajectory, patch file, and prediction record.

## What It Is

SWE-agent is a Python package and CLI named `sweagent`. It can run a single issue with `sweagent run`, run a benchmark batch with `sweagent run-batch`, replay trajectories with `sweagent run-replay`, inspect trajectories, merge predictions, and submit/evaluate SWE-bench runs.

The current 1.1.0 code delegates execution to SWE-ReX. `SWEEnv` starts a Docker, local, dummy, or remote deployment, creates a bash session, copies or selects the repo, resets it to the base commit, installs configured tool bundles into the environment, and executes model actions. `DefaultAgent` formats prompts, queries a LiteLLM-backed model or test/human/replay model, parses one action, executes it through `SWEEnv`, captures state, updates history, and writes `.traj` files.

## Research Themes

- Token efficiency: Strong practical patterns. `LastNObservations`, `ClosedWindowHistoryProcessor`, `RemoveRegex`, `CacheControlHistoryProcessor`, max observation truncation, filemap elision, and compact tool observations reduce repeated context.
- Context control: Very strong. YAML config owns templates, tools, parser type, demonstrations, history processors, environment variables, model settings, and instance sources. Trajectories save prompts/history/actions/observations/state for audit and replay.
- Sub-agent / multi-agent: Moderate. `RetryAgent` runs multiple full attempts and uses score/chooser loops to pick the best patch. `ActionSampler` can sample "colleague" actions or compare candidate actions. This is multi-attempt orchestration, not independent collaborative agents.
- Domain-specific workflow: Very strong for coding-agent benchmarks. SWE-bench, SWE-bench Verified/Lite/Full/Multimodal/Multilingual, SWE-Smith, file/HuggingFace/expert instances, repo reset, patch extraction, and sb-cli integration are first-class.
- Error prevention: Strong but mixed. Format errors, blocklisted actions, bash syntax errors, timeouts, context/cost limits, optional edit-time flake8, staged submit review, autosubmission after failure, dirty-local-repo checks, and CI tests all help. It still relies heavily on prompt compliance and model-run tests.
- Self-learning / memory: Conditional. No durable self-learning loop. Useful artifacts are trajectories, demos derived from trajectories, run replay, registry state inside tools, and logs.
- Popular skills: Not a skill repo. Reusable subsystems are `RunBatch`, `SWEBenchInstances`, `SWEEnv`, `ToolHandler`, `DefaultAgent`, `RetryAgent`, history processors, `SaveApplyPatchHook`, `SweBenchEvaluate`, and trajectory inspectors.

## Core Execution Path

The CLI entrypoint is `sweagent.run.run:main`, with `sweagent/__main__.py` forwarding into it. `sweagent run` loads merged YAML and CLI settings through `BasicCLI`, builds a `RunSingleConfig`, creates a `SWEEnv`, creates an agent from `AgentConfig`, starts the environment, runs the agent, saves predictions, and closes the environment.

`sweagent run-batch` loads a `BatchInstanceSourceConfig`, commonly `SWEBenchInstances`. SWE-bench instances are loaded from HuggingFace datasets, converted into `SimpleBatchInstance`, mapped to Docker image names like `docker.io/swebench/sweb.eval.x86_64.<instance>:latest`, paired with a preexisting `/testbed` repo at the base commit, filtered/shuffled/sliced, and executed serially or in a `ThreadPoolExecutor`.

For each batch instance, `RunBatch` creates a per-instance `RunSingleConfig` replay file, starts a fresh `SWEEnv`, installs tools, calls `agent.run()`, saves `.traj`, `.pred`, `.patch`, logs, and then merges per-instance predictions into `preds.json`. If `instances.evaluate` is true and the source is SWE-bench, `SweBenchEvaluate` submits `preds.json` to `sb-cli` and moves the result report to `results.json`.

Inside the agent loop, `DefaultAgent.setup()` installs tools, writes registry variables and state files, sets `PROBLEM_STATEMENT`, adds system/demo/instance messages, and records version hashes. Each `step()` runs history processors, queries the model, parses exactly one action, runs it in the SWE-ReX bash session, captures state commands, handles submission tokens, updates history and trajectory, and writes the trajectory after every step.

## Architecture

The architecture is split into clear layers:

- `sweagent/run/`: CLI commands, single/batch/replay execution, prediction merging, quick stats, progress UI, and run hooks.
- `sweagent/run/batch_instances.py`: instance-source adapters for SWE-bench, HuggingFace, local files, expert files, and SWE-Smith.
- `sweagent/environment/`: `SWEEnv` wrapper over SWE-ReX deployment/runtime plus repo copy/reset strategies.
- `sweagent/agent/`: default/retry/shell agents, model wrappers, problem statements, history processors, reviewer/chooser loops, and action samplers.
- `sweagent/tools/`: bundle loader, command schema, parser implementations, tool handler, blocklist, install/reset/state logic.
- `tools/`: executable tool bundles such as registry, Anthropic-style editor, review-on-submit, diff state, search/windowed legacy tools, image viewing, and browser automation.
- `config/`: default, multimodal, benchmark, bash-only, historical, human, and demo configs.
- `trajectories/` and `tests/test_data/trajectories/`: result artifacts, examples, and replay fixtures.
- `sweagent/inspector/`: terminal/web trajectory viewers.

## Design Choices

YAML config is the primary control plane. It merges default and user configs, then feeds Pydantic settings for agent, environment, tools, model, templates, instances, and hooks. This makes benchmark runs reproducible and easy to perturb.

SWE-ReX is the runtime boundary. SWE-agent itself does not implement Docker isolation; it asks SWE-ReX to start deployments, create shell sessions, upload tool bundles, execute commands, read/write files, and stop containers. This gives a clean boundary, but security depends on the deployment config and SWE-ReX behavior.

Tooling is modeled as installable bundles. A bundle has `config.yaml`, executable files in `bin/`, optional `install.sh`, and optional state commands. `ToolHandler` uploads bundles into `/root/tools`, adds them to `PATH`, validates command availability, writes `/root/.swe-agent-env`, and aggregates state from `/root/state.json`.

The default modern ACI uses function calling with built-in bash plus `str_replace_editor`, registry, and staged submit review. Older configs use a windowed file viewer, search tools, line-based editing, demos, and `last_n_observations`.

Trajectories are first-class. They record actions, observations, responses, thoughts, state, history, environment name, model stats, version hashes, and replay config. `run-replay` reconstructs actions from trajectory history and executes them again for debugging or demo generation.

The submission path is patch-based. The submit tool writes `/root/model.patch`, emits a sentinel token, and the agent reads the patch as `submission`. Hooks save `.patch` files and per-instance `.pred` JSON usable by SWE-bench. The diff-state tool can keep the current patch in state for autosubmission after environment failure.

## Strengths

The SWE-bench harness path is concrete and reproducible: dataset source, Docker image, base commit, reset commands, tool config, trajectory, prediction file, and sb-cli evaluation are all explicit.

The tool-bundle model is practical. It allows small tools with typed schemas, executable implementations, install scripts, state commands, and hidden-tool filtering without changing agent core code.

The environment lifecycle is disciplined. Each task starts from a deployment, repo copy/preexisting repo, hard reset/clean, startup commands, tool reset, and shutdown. Batch mode avoids old completed trajectories unless `redo_existing` is set.

Trajectory and replay support are excellent for harness debugging. A failed run can be inspected, converted into a demo, or replayed under a modified config.

Error handling covers real agent failure modes: malformed model output, multiple/missing function calls, blocked interactive tools, bash syntax errors, command timeouts, context window overflow, cost limits, model API retry failures, and environment death.

The staged submit-review tool is a strong prompt-level guard. It forces the agent to inspect its diff, rerun reproduction when needed, remove reproduction scripts, and avoid test-file edits before final submission.

## Weaknesses

The repo is now partly legacy. The README explicitly recommends mini-SWE-agent going forward, and several configs/tooling paths reflect older ACIs or benchmark-era experiments.

Sandboxing is not a complete security story. Docker/SWE-ReX provides the main boundary, while the tool blocklist only prevents common interactive commands. Tools run with broad shell/file access inside the container, and `install.sh` plus propagated environment variables need policy.

Verification is mostly agent-directed. Default prompts tell the model to write and rerun reproduction scripts, and submit review asks for checks, but there is no generic deterministic test-selection/verifier loop before patch extraction. SWE-bench scoring is an external post-run step through `sb-cli`.

Context control is powerful but fragmented across configs. `cache_control`, `last_n_observations`, filemap elision, diff removal, and image parsing are useful, but the right combination is config-specific and easy to misconfigure.

Batch parallelism is thread-based and practical, but shared global model stats/API-key rotation and external Docker resource pressure require care. The docs recommend multiple API keys, memory limits, random startup delay, and sentinel cleanup scripts.

Trajectories and logs can contain full prompts, observations, patches, and possibly secrets if users propagate environment variables or tools print sensitive content.

## Ideas To Steal

Make benchmark instances a typed source that returns `{env, problem_statement}` pairs. Keep filter, slice, and deterministic shuffle at the source layer.

Save a replayable per-instance config next to every trajectory, and make replay a first-class debugging command.

Use tool bundles as the ACI unit: schema, executable, install step, state command, docs, and tests.

Add a staged submit guard that shows the cumulative diff and requires a second explicit submit after review.

Keep a diff-state command so autosubmission after context/cost/environment failure can still recover the last patch.

Separate history processors from agent logic. Chain processors for observation elision, cache-control marks, regex removal, closed-window compaction, and image parsing.

Write `.pred`, `.patch`, `preds.json`, exit-status YAML, logs, and trajectory files in a stable per-run layout.

Use external benchmark submission as a hook, not as core agent logic, so local runs and competitive runs share the same execution path.

## Do Not Copy

Do not copy the full application as an agent-support layer; it is larger than needed for most local harnesses and upstream now points users to mini-SWE-agent.

Do not treat a command blocklist as a security boundary. Keep sandbox policy in the runtime/deployment layer.

Do not propagate host secrets into tools without log redaction. The tool config itself warns that propagated values can appear in debug logs.

Do not rely on the model to run verification just because the prompt says so. Add harness-level verifier hooks for critical workflows.

Do not assume one-tool-call-per-turn is always optimal. It simplifies parsing and execution, but can be slow for safe independent reads.

Do not keep unredacted trajectories forever if they may contain proprietary code, issue text, secrets, or full model prompts.

## Fit For Agentic Coding Lab

Fit is conditional but high value. SWE-agent is a full coding-agent system, not a narrow harness library, yet its harness pieces are directly relevant to Agentic Coding Lab.

Agentic Coding Lab should adapt its typed instance-source layer, sandbox/repo reset lifecycle, tool-bundle ACI contract, trajectory/replay format, staged submit review, autosubmission recovery, and output layout. It should not inherit the full CLI/app surface or assume SWE-bench is the only evaluation target.

Best immediate artifact candidates are a small `BatchInstance` schema, a replayable run manifest, a tool-bundle convention, and a submit-review hook that can be used by Codex-like agents.

## Reviewed Paths

- `/tmp/myagents-research/SWE-agent-SWE-agent/README.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/pyproject.toml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/background/architecture.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/background/aci.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/cli.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/batch_mode.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/competitive_runs.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/trajectories.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/inspector.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/usage/adding_custom_tools.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/config.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/tools.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/environments.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/env.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/templates.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/docs/config/demonstrations.md`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/default.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/default_mm_with_images.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/bash_only.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/sweagent_0_7/07.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/benchmarks/250212_sweagent_heavy_sbl.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/benchmarks/250526_anthropic_filemap_simple_review_sbl.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/__init__.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/__main__.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/run.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/run_single.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/run_batch.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/batch_instances.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/run_replay.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/common.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/hooks/apply_patch.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/run/hooks/swe_bench_evaluate.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/environment/swe_env.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/environment/repo.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/environment/hooks/abstract.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/agents.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/models.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/history_processors.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/problem_statement.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/reviewer.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/agent/action_sampler.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/tools/bundle.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/tools/commands.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/tools/parsing.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/tools/tools.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/registry/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/edit_anthropic/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/review_on_submit_m/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/diff_state/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/image_tools/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/web_browser/config.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/web_browser/lib/browser_manager.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/windowed/config.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/search/config.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/submit/config.yaml`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_run_batch.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_run_single.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_run_replay.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_agent.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_env.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_batch_instance.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_parsing.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_models.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_history_processors.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_problem_statement_multimodal.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_run_hooks.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/tools/test_default_utils.py`
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_data/trajectories/`
- `/tmp/myagents-research/SWE-agent-SWE-agent/.github/workflows/pytest.yaml`

## Excluded Paths

- `/tmp/myagents-research/SWE-agent-SWE-agent/.git/`: VCS internals; exact commit recorded separately.
- `/tmp/myagents-research/SWE-agent-SWE-agent/assets/` and `/tmp/myagents-research/SWE-agent-SWE-agent/docs/assets/`: images, logos, screenshots, CSS, and static docs assets; not core harness architecture.
- `/tmp/myagents-research/SWE-agent-SWE-agent/sweagent/inspector/`: trajectory viewer UI; docs were reviewed, but static HTML/CSS/JS/icons were not line-reviewed because they are UI-only.
- `/tmp/myagents-research/SWE-agent-SWE-agent/.agents/`, `/tmp/myagents-research/SWE-agent-SWE-agent/.codex/`, `/tmp/myagents-research/SWE-agent-SWE-agent/.cursor/`, and `/tmp/myagents-research/SWE-agent-SWE-agent/.devcontainer/`: local agent/editor/devcontainer metadata; not runtime harness behavior.
- `/tmp/myagents-research/SWE-agent-SWE-agent/.github/` except `workflows/pytest.yaml`: issue templates, PR template, link-check/docs workflows, and dependabot config; not execution architecture.
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_data/data_sources/ctf/`: CTF fixtures, Dockerfiles, pcap/zip/executable binaries, and challenge assets; useful for EnIGMA but unrelated to SWE-bench harnessing.
- `/tmp/myagents-research/SWE-agent-SWE-agent/tests/test_data/trajectories/*/patches/` beyond sampled patch/pred files: generated benchmark outputs; structure reviewed, not every generated artifact.
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/forfeit/`, `/tmp/myagents-research/SWE-agent-SWE-agent/tools/filemap/`, `/tmp/myagents-research/SWE-agent-SWE-agent/tools/multilingual_setup/`, and `/tmp/myagents-research/SWE-agent-SWE-agent/tools/windowed_edit_*`: peripheral or historical tool variants; default and benchmark tool paths were prioritized.
- `/tmp/myagents-research/SWE-agent-SWE-agent/tools/web_browser/bin/` and most browser helper files: multimodal/browser surface sampled through config and browser manager; individual wrappers are thin UI automation commands.
- `/tmp/myagents-research/SWE-agent-SWE-agent/config/demo/`, `/tmp/myagents-research/SWE-agent-SWE-agent/config/exotic/`, and `/tmp/myagents-research/SWE-agent-SWE-agent/config/human/`: scenario-specific variants; representative default, benchmark, bash-only, multimodal, and v0.7 configs were reviewed.
