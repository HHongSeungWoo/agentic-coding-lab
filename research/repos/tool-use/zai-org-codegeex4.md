# zai-org/CodeGeeX4

- URL: https://github.com/zai-org/CodeGeeX4
- Category: tool-use
- Stars snapshot: 2,506 (GitHub REST API, captured 2026-05-20)
- Reviewed commit: 480f792bf9a57cfa8ccad84ea4366badab99bee3
- Reviewed at: 2026-05-20
- Status: reviewed
- Scope fit: conditional
- Verdict: Useful as a model-and-demo source for tool-use prompt formats, repository context packaging, code-interpreter observation loops, and retrieval-augmented code Q&A. Not directly adoptable as an Agentic Coding Lab subsystem because most behavior is demo code around CodeGeeX4 weights/API, with brittle parsing, limited validation, incomplete safety boundaries, and non-reproducible evaluation assets.

## Why It Matters

CodeGeeX4 is a coding-model repository, not an agent framework, but it concentrates several tool-use patterns that appear in coding assistants: function-call selection, repository-level Q&A/edit prompts, code interpreter execution, online search grounding, local OpenAI-compatible serving, and RAG over project files. The value for Agentic Coding Lab is not the model itself. The value is seeing how the repo uses explicit prompt grammars and observation tokens to steer one model across multiple software-development modes.

## What It Is

The repository packages CodeGeeX4-ALL-9B documentation, launch examples, and demos. The README describes a 9B multilingual coding model with 128K context and support for code completion, code generation, code interpreter, web search, function calling, and repository-level Q&A. The code includes Python demos for function calling, interpreter sandboxing, LangChain/LlamaIndex RAG, web search, Chainlit repository Q&A, and local-mode serving for IDE extensions. It also includes a Rust Candle inference demo and an unfinished Actix API-server skeleton.

## Research Themes

- Token efficiency: The repository recommends BM25 and embedding recall, truncating inputs above 128K, and choosing shorter `max_length` settings such as 16K or 32K for constrained hardware. The Chainlit repo demo uses a rough `len(prompt) / 4 < 120000` budget gate and summarizes only the five shortest-path files at upload time.
- Context control: Repository files are serialized with `###PATH:` sections, cross-file completion uses `###REFERENCE:` blocks, infilling uses `<|code_suffix|>`, `<|code_prefix|>`, and `<|code_middle|>`, and RAG demos format retrieved chunks as numbered `[[citation:n]]` blocks.
- Sub-agent / multi-agent: No multi-agent runtime. The closest reusable idea is role separation through prompts: a tool selector prompt chooses `online_query` or `project_qa`, while Chainlit step annotations expose tool-like operations for directory loading and Bing search.
- Domain-specific workflow: Strongest coverage is coding-assistant modes: code comments, explanation, translation, review, fixing, unit-test generation, file Q&A, cross-file completion, repository Q&A, repository file generation, web-grounded answers, and Python code interpretation.
- Error prevention: Prompt-level instructions ask for accurate and secure code, the interpreter sandbox has a timeout and typed error events, and the Dockerfile runs as a non-root user with setuid bits removed. Runtime validation remains thin and several safety gaps remain.
- Self-learning / memory: No durable memory or self-improvement loop. Multi-turn history is manually serialized into prompt tokens, and interpreter observations are appended back into the prompt for up to five rounds.
- Popular skills: The prompt guide effectively behaves like a coding skill catalog: comments, unit tests, explanation, translation, code review, code fixing, candidate questions, file Q&A, infilling, and repository file editing.

## Core Execution Path

Function calling is prompt-driven. `function_call_demo/main.py` loads `THUDM/codegeex4-all-9b`, passes candidate tool schemas in `history=[{"role": "tool", "content": tool_content}]`, and asks the model to emit one or more fenced JSON blocks. `post_process()` extracts ```json fences with a regex, then tries `json.loads()` plus a few format repairs. The demo demonstrates single-tool and multi-tool selection, but it stops at parsed JSON. It does not dispatch tools, validate arguments against a schema, execute functions, or feed results back.

The interpreter demo is the most transferable tool-use loop. `interpreter_demo/app.py` constructs a prompt with `<|system|>`, user/history turns, uploaded-file metadata, and `<|assistant|>`. It streams from a TGI endpoint until the model emits `<|observation|>`. At that point it extracts the first Python code block, posts it to `/execute`, appends a fenced `result` block back into the prompt, and lets the model continue for up to five rounds. `interpreter_demo/sandbox.py` wraps a Jupyter kernel behind Tornado endpoints for `/execute`, `/files/upload`, and `/files/download`, returning structured events for stdout/stderr, display data, execution results, errors, and timeouts.

Repository tasks use a flat prompt grammar rather than a patch engine. `guides/Repository_tasks_guideline.md` shows repository Q&A by concatenating files as repeated `###PATH:` sections, then adding the user query. Repository edits use a separate system prompt that asks the model to output `###PATH: {PATH}` followed by full file code. `repodemo/run.py` implements a Chainlit demo that accepts a zip or GitHub URL, collects files through an extension allowlist, builds a directory tree, summarizes a small file subset, optionally asks the model for a Mermaid architecture diagram, then answers project questions by injecting repository content into the prompt if the estimated token budget fits.

RAG demos provide a second repository-Q&A path. `langchain_demo` traverses selected extensions, splits files with language-aware splitters, embeds chunks through Zhipu `embedding-2`, stores vectors in FAISS, retrieves chunks, formats them with citation IDs, and passes them to CodeGeeX. `llamaindex_demo` does the same with LlamaIndex `CodeSplitter`, a FAISS vector store, and a custom synthesizer.

Web search is a simple external-tool path. `web_demo` and `repodemo/utils/bingsearch.py` call Bing Search, keep recent Chinese-market snippets, format snippets as numbered citations, and ask the model to answer with citation references. Local mode exposes `/v1/chat/completions` through FastAPI so IDE extensions can connect to a locally deployed model through an OpenAI-like API shape.

## Architecture

The architecture is demo-oriented and model-centric:

- A shared model assumption: either local `transformers`/Ollama/vLLM/Candle inference or an OpenAI-compatible CodeGeeX API.
- Prompt grammars for each mode: chat, code review, unit tests, infill, repo Q&A, repo edits, function calling, search grounding, and interpreter execution.
- Thin adapters around frameworks: LangChain, LlamaIndex, Chainlit, Gradio, FastAPI, TGI, Bing Search, FAISS, Zhipu embeddings, Jupyter, and Candle.
- Tool-use boundaries are mostly conventions: role `tool`, fenced JSON, `<|observation|>`, `###PATH`, and citation blocks.
- Runtime boundaries exist only in demos: interpreter sandbox API, Chainlit `@cl.step(type="tool")` display hooks, local server request/response schemas, and external API wrappers.

## Design Choices

The strongest design choice is explicit serialization. File paths, language, completion mode, references, suffix/prefix, tool candidates, citations, and observations all get stable textual markers. This makes behavior portable across raw model APIs, vLLM, local servers, and extension contexts.

The repo favors model-native output protocols over programmatic orchestration. Function calls are not an API call feature in the demo; they are JSON blocks generated by the model. Repository edits are not diffs; they are full file outputs labeled by path. Interpreter execution is triggered by a special token rather than by a typed tool-call object.

Long context and retrieval are treated as complementary. The documentation says 128K can hold about 10,000 lines of code, but still recommends BM25/embedding recall and truncation. The demos show both direct all-file stuffing with a budget gate and vector retrieval with citations.

The interpreter API uses event-shaped execution results instead of returning only stdout. This is worth copying in spirit: separate stream text, display data, generated files, errors, and timeout status so the model and UI can react differently.

## Strengths

- Clear, reusable prompt grammars for coding modes, infilling, cross-file context, repository Q&A, repository edits, and observations.
- Demonstrates both single and parallel tool-call selection through one schema format.
- Interpreter loop captures a practical pattern: generate code, execute in sandbox, append structured observation, retry or refine for bounded rounds.
- Repository-context patterns cover direct long-context packing and RAG-based retrieval, which is useful for comparing context strategies.
- Local OpenAI-compatible server pattern makes IDE integration and model swapping easier.
- The sandbox has useful basics: non-root Docker user, setuid removal, timeout handling, Jupyter event capture, file upload/download API, and display-data support.

## Weaknesses

- This is not a robust tool-use framework. Most paths are demos with minimal tests, minimal validation, and little separation between prompt protocol, tool registry, execution, and UI.
- Function calling parses fenced JSON with regex and repair heuristics, but does not validate names, arguments, required fields, or schema conformance before use.
- The Chainlit tool selector asks a model to choose tools and retries until JSON parses, but still trusts the output shape and uses coarse membership checks.
- Repository editing asks for full-file `###PATH` outputs and does not provide a patch parser, diff validation, test loop, or safe apply workflow.
- Repository context packing is rough. The Chainlit path can stuff all selected files into one prompt, uses a char/4 estimate, and leaves ranking/chunking as a separate demo rather than a unified context builder.
- Safety boundaries are incomplete. Zip extraction uses `extractall`, GitHub cloning accepts user URLs, sandbox file paths are joined against `/`, FAISS loading enables dangerous deserialization, Bing fetching has little provenance control, and Docker has no explicit network, CPU, memory, or filesystem policy in the checked-in command.
- Interpreter docs/tests and implementation drift: the API docs mention upload conflict status, and tests expect it, but the current upload handler overwrites through a streamed write path and always returns success.
- Evaluation is mostly README tables and images. The repo does not include runnable evaluation scripts for BigCodeBench, NaturalCodeBench, Berkeley Function Calling Leaderboard, NIAH, or cross-file completion.
- Code and model licensing differ: source code is Apache-2.0, while model weights use a custom license requiring registration for commercial use and imposing extra attribution/restriction terms.

## Ideas To Steal

- Define a small, stable text grammar for repository context: `###PATH`, `###REFERENCE`, `###LANGUAGE`, and mode markers. Pair it with a parser and strict budget accounting.
- Treat code-interpreter execution as an observation loop: model emits code, sandbox returns typed events, result is appended as an observation, and the loop has a hard round limit.
- Store tool candidates as structured data in a dedicated tool/context turn, but add an actual dispatcher with schema validation, allowlists, permissions, and result turns.
- Use event-shaped sandbox outputs for stdout, stderr, rich display data, files, errors, and timeouts. This gives downstream agents enough structure to decide whether to retry, inspect an artifact, or stop.
- Build a repository Q&A context packer with two modes: long-context direct packing for small repos and BM25/vector recall for large repos. Always explain which files were included or excluded.
- Keep skill-style prompt templates for common coding workflows, but wrap them in typed task definitions and verification hooks rather than plain prompt snippets.
- For web/search tools, preserve citation IDs at the context boundary and require answer sentences to point back to cited snippets.
- Expose local model backends through OpenAI-compatible endpoints, but keep core agent behavior independent of a specific model family.

## Do Not Copy

- Do not adopt the model weights or CodeGeeX-specific API as a hard dependency; licensing, hardware, and behavior assumptions do not fit a general Agentic Coding Lab tool-use system.
- Do not copy regex-only JSON extraction or format-repair parsing for tool calls. Use strict JSON/schema parsing, typed errors, and no execution on ambiguous output.
- Do not use full-file repository edit outputs as the only apply format. Require diffs or structured edits, validate paths, and run tests before applying.
- Do not expose upload, clone, download, or sandbox execution paths without path normalization, network policy, resource caps, and permission checks.
- Do not load FAISS/vector indexes with dangerous deserialization from untrusted paths.
- Do not treat evaluation screenshots or README claims as reproducible evidence.
- Do not make Chainlit/Gradio UI code the core orchestration layer. Keep UI, tool registry, sandbox, context packing, and model adapter as separate modules.

## Fit For Agentic Coding Lab

Conditional fit. CodeGeeX4 should be mined for prompt protocol and execution-loop ideas, not reused as a library. The best Agentic Coding Lab artifact would be a tool-use harness that combines this repo's explicit context markers and observation-loop design with stricter engineering: typed tool registry, schema validation, permission model, sandbox policy, patch application, verification commands, and reproducible evals. The repository also supports a useful design rule: long-context coding models still need retrieval, truncation, and path-aware serialization because real repositories exceed model windows and because the agent must explain what context it used.

## Reviewed Paths

- `README.md`: model scope, launch options, tutorial map, evaluation claims, license split.
- `guides/System_prompt_guideline.md`: prompt templates for chat, comments, explanation, translation, review, fixing, unit tests, candidate questions, file Q&A, custom prompts, and multi-turn history.
- `guides/Infilling_guideline.md`: contextual completion, cross-file infilling, repository-level file generation, path/language/mode/reference markers.
- `guides/Repository_tasks_guideline.md`: repository Q&A and repository file add/delete/modify prompt formats, 128K context guidance, recall/truncation recommendations.
- `guides/Local_mode_guideline.md` and `local_mode/`: local extension flow and FastAPI OpenAI-compatible chat completion shim.
- `function_call_demo/`: candidate function schemas, single/multiple function-call examples, model output parsing.
- `interpreter_demo/`: Gradio interpreter loop, TGI streaming, `<|observation|>` handling, sandbox API, Dockerfile, and sandbox tests.
- `repodemo/`: Chainlit chat/project-Q&A app, tool selector prompt, Bing tool step, repository upload/clone, file filtering, directory tree generation, file summaries, Mermaid diagram generation, and prompt assembly.
- `langchain_demo/`: file traversal, language-aware splitting, Zhipu embeddings, FAISS vectorization, retrieval prompt, and model adapter.
- `llamaindex_demo/`: LlamaIndex code splitting, FAISS storage, custom synthesizer, and model adapter.
- `web_demo/`: Bing search wrapper, snippet-to-citation prompt, and Gradio online Q&A.
- `metric/README.md`: documented benchmark claims and available evaluation artifacts.
- `candle_demo/README.org`, `candle_demo/cli/src/main.rs`, `candle_demo/api-server/src/api.rs`, `candle_demo/api-server/src/server.rs`: Rust inference demo and incomplete API-server direction.
- `LICENSE` and `MODEL_LICENSE`: source-code and model-weight licensing constraints.

## Excluded Paths

- `README_zh.md`, `README_ja.md`, `guides/*_zh.md`, `function_call_demo/README_zh.md`, `interpreter_demo/README_zh.md`, `langchain_demo/README_zh.md`, `llamaindex_demo/README_zh.md`, `local_mode/README_zh.md`, `metric/README_zh.md`, `repodemo/readme_zh.md`, `web_demo/README_zh.md`: translated documentation duplicating the English paths reviewed above.
- `resources/*.jpg`, `resources/*.png`, `metric/pics/*`, `langchain_demo/resources/*`, `llamaindex_demo/resources/*`, `local_mode/resources/*`, `web_demo/resources/*`, `repodemo/public/*`, `repodemo/public/avatars/*`, `interpreter_demo/image.png`: logos, screenshots, diagrams, GIFs, icons, or sample visual assets; useful for demos but not tool-use architecture.
- `metric/.DS_Store`, `metric/pics/.DS_Store`: platform metadata.
- `interpreter_demo/data.csv`: small sample upload for the interpreter demo, not framework behavior.
- `repodemo/.chainlit/config.toml`, `repodemo/.chainlit/translations/*.json`, `repodemo/chainlit.md`, `repodemo/chainlit_zh-CN.md`: Chainlit UI configuration and copy, not core orchestration.
- `repodemo/utils/programming-languages-to-file-extensions.json`: large static extension map used by file filtering; reviewed through `filter_data()` behavior rather than line-by-line.
- `candle_demo/codegeex4/src/*`: Rust model implementation and tensor layers. Relevant to local inference, but not to transferable tool-use orchestration.
- `candle_demo/api-server/src/model.rs`, `candle_demo/api-server/src/main.rs`, `candle_demo/api-server/src/args.rs`, `candle_demo/codegeex4/Cargo.toml`, `candle_demo/Cargo.toml`, and package manifests/requirements files: build/dependency plumbing reviewed only enough to understand demo boundaries.
