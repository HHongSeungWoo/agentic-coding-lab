# microsoft/mcp-for-beginners

- URL: https://github.com/microsoft/mcp-for-beginners
- Category: mcp
- Stars snapshot: 16.1k on GitHub repository page, checked 2026-05-11
- Reviewed commit: 4a17ce80a974e7d9a9f8d36106f2798d09b966d0
- Reviewed at: 2026-05-11 (Asia/Seoul)
- Status: reviewed
- Scope fit: in-scope
- Verdict: Strong MCP education corpus for agents, with reusable curriculum structure, security taxonomy, transport guidance, Inspector-based verification, and several server/client patterns. Treat as teaching material, not a production reference implementation, because examples vary in freshness and some stdio samples violate their own stdout guidance.

## Why It Matters

This is a Microsoft-maintained, high-signal MCP curriculum with broad language coverage and a full path from "what is MCP" to host setup, stdio and Streamable HTTP transports, auth, testing, Inspector debugging, context engineering, production database labs, and enterprise security. For Agentic Coding Lab, its value is less in any single sample and more in its reusable learning scaffold: small first server, explicit client, LLM client, host integration, debug loop, advanced patterns, production lab.

It is also useful because it teaches MCP through workflows a coding agent actually performs: list capabilities, inspect schemas, call tools, validate inputs, request user consent, constrain filesystem roots, manage long-running operations, and verify server behavior before trusting agent/tool output.

## What It Is

`mcp-for-beginners` is an open curriculum for Model Context Protocol. It includes Markdown lessons, multi-language examples in Python, TypeScript/JavaScript, C#, Java, and Rust, and larger labs around AI Toolkit, PostgreSQL-backed MCP servers, Azure deployment, security, monitoring, and semantic search.

The repo is organized as modules:

- `00-Introduction` through `03-GettingStarted`: MCP concepts, first server, first client, LLM client, VS Code host config, stdio, Streamable HTTP, testing, auth, hosts, Inspector, sampling, MCP Apps.
- `04-PracticalImplementation`: SDK usage, samples, API management, pagination.
- `05-AdvancedTopics`: context engineering, roots, OAuth2, routing, sampling, scaling, security, Entra ID, custom transports, protocol features, adversarial multi-agent reasoning.
- `08-BestPractices`: tool design, consent, validation, rate limiting, logging, progress, cancellation.
- `10-StreamliningAIWorkflowsBuildingAnMCPServerWithAIToolkit`: AI Toolkit labs, custom weather/GitHub clone MCP server examples.
- `11-MCPServerHandsOnLabs`: PostgreSQL retail analytics lab with RLS, schema introspection, query validation, semantic search, testing, monitoring, and deployment.

## Research Themes

- Token efficiency: Explicitly covers pagination, progressive context loading, context chunking, context compression, cursor-based `tools/list` / `resources/list` / `prompts/list`, and lazy clients for large result sets. Good patterns for preventing MCP tools from dumping unbounded context into an LLM.
- Context control: Strong coverage of resources, resource templates, roots, root contexts, context engineering, RLS-backed data isolation, allowed directories, and "single shared context vs fragmented agents" tradeoffs. Useful for designing agent-visible context boundaries.
- Sub-agent / multi-agent: Mostly educational, not a framework. The adversarial multi-agent lesson and context engineering chapter argue for shared context and careful sequencing; this is more useful as design caution than as reusable orchestration code.
- Domain-specific workflow: Excellent progression from calculator/weather toy tools to database retail analytics, web search, GitHub clone, Azure API Management, and AI Toolkit workflows. Domain examples translate well into "small safe tool plus verification loop" agent skills.
- Error prevention: Repeated patterns: Pydantic/Zod/schema validation, Inspector first, unit/integration/performance tests, SQL query validation, RLS tests, auth middleware, token audience checks, rate limits, logging, progress, cancellation, and structured errors.
- Self-learning / memory: Root contexts and context engineering sections cover persistence, summaries, metadata, context state, and archival, but examples are conceptual. No durable agent memory subsystem to reuse directly.
- Popular skills: Strong candidates are "MCP server smoke test with Inspector", "stdio-safe logging check", "MCP tool schema review", "query validator/RLS review", "host config validation", and "context budget/pagination review".

## Core Execution Path

The curriculum's main execution path is deliberately progressive:

1. Build a minimal MCP server exposing tools, resources, and prompts.
2. Connect a client over stdio or HTTP, initialize a session, list capabilities, and call tools/resources/prompts.
3. Add an LLM-facing client that converts discovered tool schemas into model-callable capabilities.
4. Configure a host such as VS Code, Claude Desktop, Cursor, or AI Toolkit to launch or connect to the MCP server.
5. Verify behavior with MCP Inspector, CLI mode, unit tests, and custom client scripts.
6. Move from direct registration to scalable low-level handlers with a tool registry, schema validation, and centralized call dispatch.
7. Add production concerns: auth, RBAC/JWT/OAuth2, token audience validation, RLS, pagination, progress notifications, cancellation, monitoring, and deployment.

The strongest reusable execution pattern is: server registers focused tools with typed schemas; client initializes and lists capabilities; Inspector validates schemas and calls; unit tests assert tool behavior; production versions add auth, least privilege, audit logs, and bounded result sets.

## Architecture

The repo teaches MCP as a client-server protocol with hosts creating one client per server. Servers expose primitives:

- Tools for executable actions.
- Resources for data/context by URI.
- Prompts for reusable templates/workflows.

It separates local and remote transports:

- `stdio`: preferred for local MCP servers launched as child processes; JSON-RPC over stdin/stdout; logs must go to stderr.
- Streamable HTTP: preferred for remote/cloud servers and progress/notification-heavy scenarios.
- Custom transports: advanced conceptual examples using Event Grid/Event Hubs, with emphasis on preserving JSON-RPC ordering, session identity, security, reliability, and bidirectional messaging.

Implementation patterns range from high-level SDK registration (`FastMCP`, `McpServer.tool`, C# attributes) to low-level request handlers (`list_tools`, `call_tool`, `ListToolsRequestSchema`, `CallToolRequestSchema`). The production database lab uses layered architecture: protocol layer, business logic layer, data access layer, infrastructure/monitoring layer.

## Design Choices

The curriculum chooses breadth and repetition over minimalism. Many lessons show the same concept in multiple languages, then revisit it with more production constraints. That works well for education and for extracting patterns, but it creates version drift and mixed code quality.

Strong design choices:

- Starts with concrete tiny tools before moving to complex MCP features.
- Keeps Inspector and host integration near the beginning, so users learn a verification loop early.
- Treats security as a full module and returns to it in auth, advanced security, Entra ID, APIM, RLS, and best-practice labs.
- Explains transport selection in operational terms: stdio for local subprocesses, Streamable HTTP for remote/cloud.
- Encourages schema-first tool descriptions and validation with Pydantic/Zod/JSON Schema.
- Gives context-control primitives their own lessons: roots, root contexts, pagination, context engineering.

Risky design choices:

- Some examples mix current MCP spec references with older 2025-06-18 wording while top-level docs claim 2025-11-25 alignment.
- Several JavaScript/TypeScript stdio examples use `console.log` for operational logging, despite the stdio lesson correctly saying stdout must contain only MCP messages.
- Some advanced/security code is conceptual and references classes or APIs that look illustrative rather than runnable as-is.
- The breadth of translations, screenshots, notebooks, and UI samples makes the checkout very large and noisy for coding agents unless sparse checkout is used.

## Strengths

- Comprehensive MCP path from concepts to production-ish database/server operations.
- Clear reusable lesson sequence for agent education: concept, server, client, LLM client, host, stdio, HTTP, testing, auth, advanced primitives.
- Security coverage is unusually broad for a beginner repo: prompt injection, tool poisoning, confused deputy, token passthrough, session hijacking, OWASP MCP Top 10, Entra ID, OAuth2, RBAC, APIM, Key Vault, Content Safety, RLS.
- Verification guidance is practical: MCP Inspector, CLI mode, custom clients, unit tests, integration tests, performance tests, RLS validation, Application Insights.
- Context control gets explicit treatment: roots, resource templates, pagination, context engineering, progressive loading, context compression, RLS-backed tenant context.
- The PostgreSQL hands-on labs contain the most reusable production patterns: layered server, connection pool, RLS context setting, schema introspection, query validation, semantic search, telemetry, and test fixtures.
- Good host-configuration examples for coding-agent-adjacent tools such as VS Code, Claude Desktop, Cursor, and AI Toolkit.

## Weaknesses

- Not a single cohesive application; it is a curriculum. Reusing code requires choosing a sample and hardening it.
- Version drift exists across lessons: top-level says MCP Specification 2025-11-25, while several transport/security lessons still center 2025-06-18 or deprecated SSE language.
- Stdio safety is inconsistent. C# sample correctly sends logs to stderr, but JavaScript/TypeScript examples log via `console.log`, and low-level Python examples use `print`, both of which can corrupt JSON-RPC stdout.
- Some security examples intentionally hardcode demo secrets (`secret123`, `secret-token`, sample JWT secrets) while warning not to use them in production. Good for pedagogy, unsafe to copy.
- Web-search and GitHub clone samples show useful external-tool patterns, but need more guardrails: rate-limit handling, URL allowlisting, path allowlisting, subprocess timeouts, and command permission review.
- Generated translations and images dominate repository size and can distract agents from the primary English execution path.

## Ideas To Steal

- Build an MCP learning skill as a staged checklist: first server, first client, LLM client, host config, Inspector verification, auth, pagination, context boundaries.
- Add a "stdio hygiene" verifier to agent workflows: fail if MCP server code writes operational logs to stdout instead of stderr.
- Create a reusable MCP note pattern that records transport, tools/resources/prompts, auth model, context boundaries, result-size controls, and verification commands.
- Use the database lab's layered architecture for production MCP reviews: protocol, business logic, data access, infrastructure, security, tests.
- Adopt cursor-based pagination and lazy client iteration for any large `tools/list`, `resources/list`, `prompts/list`, or search result tool.
- Use the security taxonomy as review checklist: token audience, no token passthrough, no sessions as auth, explicit consent, least privilege, tool metadata integrity, RLS/tenant isolation, prompt injection defenses, audit logs.
- Promote MCP Inspector as the default first verification step before integrating a server into coding agents.
- Add tool annotations / destructive hints to review criteria, even when samples do not implement them deeply.

## Do Not Copy

- Do not copy hardcoded auth tokens, JWT secrets, demo API keys, or "placeholder values for demonstration purposes".
- Do not copy `console.log` / `print` patterns into stdio MCP servers; use stderr or structured server logging outside stdout.
- Do not copy broad file/database tools without roots, path allowlists, query allowlists, result caps, and explicit user consent.
- Do not treat conceptual advanced transport/root-context examples as SDK-accurate production code without checking current official docs.
- Do not import the whole repo as context for an agent. Use sparse checkout or targeted paths because translations and images are large.
- Do not let a model infer production readiness from "Microsoft" branding; several samples are teaching examples and need threat modeling.

## Fit For Agentic Coding Lab

High fit as an MCP education and review-pattern source. It should feed practical artifacts rather than be vendored:

- MCP server review checklist.
- MCP stdio transport safety checker.
- MCP Inspector verification workflow.
- MCP security review prompt/skill.
- Context-boundary and pagination checklist for agent tools.
- Production MCP architecture note template.

The best coding-agent applicability is in turning lessons into guardrails: agents should verify server capability schemas, keep logs off stdout, demand bounded outputs, enforce roots and tenant context, and run Inspector/client smoke tests before trusting a new MCP server.

## Reviewed Paths

- `README.md`, `study_guide.md`, `SECURITY.md`, `AGENTS.md`
- `00-Introduction/README.md`
- `01-CoreConcepts/README.md`
- `02-Security/README.md`
- `03-GettingStarted/README.md`
- `03-GettingStarted/01-first-server/README.md` and selected solution files
- `03-GettingStarted/02-client/README.md` and selected solution files
- `03-GettingStarted/03-llm-client/README.md` and selected solution files
- `03-GettingStarted/04-vscode/README.md`
- `03-GettingStarted/05-stdio-server/README.md`
- `03-GettingStarted/06-http-streaming/README.md`
- `03-GettingStarted/08-testing/README.md`
- `03-GettingStarted/10-advanced/README.md`
- `03-GettingStarted/10-advanced/code/python/server.py`
- `03-GettingStarted/10-advanced/code/python/tools/add.py`
- `03-GettingStarted/11-simple-auth/README.md`
- `03-GettingStarted/12-mcp-hosts/README.md`
- `03-GettingStarted/13-mcp-inspector/README.md`
- `03-GettingStarted/14-sampling/README.md`
- `04-PracticalImplementation/README.md`
- `04-PracticalImplementation/pagination/README.md`
- `04-PracticalImplementation/samples/python/README.md`
- `04-PracticalImplementation/samples/python/server.py`
- `04-PracticalImplementation/samples/python/client.py`
- `04-PracticalImplementation/samples/typescript/README.md`
- `04-PracticalImplementation/samples/typescript/src/index.ts`
- `04-PracticalImplementation/samples/javascript/index.js`
- `04-PracticalImplementation/samples/csharp/src/Calculator/Program.cs`
- `04-PracticalImplementation/samples/csharp/src/Calculator/Tools/CalculatorTool.cs`
- `04-PracticalImplementation/samples/java/containerapp/README.md`
- `04-PracticalImplementation/samples/java/containerapp/src/main/java/com/microsoft/cognitiveservices/ContentSafetyUtil.java`
- `04-PracticalImplementation/samples/java/containerapp/src/main/java/com/microsoft/cognitiveservices/LangChain4jClient.java`
- `05-AdvancedTopics/README.md`
- `05-AdvancedTopics/mcp-contextengineering/README.md`
- `05-AdvancedTopics/mcp-root-contexts/README.md`
- `05-AdvancedTopics/mcp-transport/README.md`
- `05-AdvancedTopics/mcp-protocol-features/README.md`
- `05-AdvancedTopics/mcp-security/README.md`
- `05-AdvancedTopics/mcp-scaling/README.md`
- `05-AdvancedTopics/mcp-routing/README.md`
- `05-AdvancedTopics/mcp-oauth2-demo/README.md`
- `05-AdvancedTopics/mcp-security-entra/README.md`
- `05-AdvancedTopics/web-search-mcp/README.md`
- `05-AdvancedTopics/web-search-mcp/server.py`
- `05-AdvancedTopics/web-search-mcp/client.py`
- `08-BestPractices/README.md`
- `10-StreamliningAIWorkflowsBuildingAnMCPServerWithAIToolkit/README.md`
- `10-StreamliningAIWorkflowsBuildingAnMCPServerWithAIToolkit/lab3/code/weather_mcp/src/server.py`
- `10-StreamliningAIWorkflowsBuildingAnMCPServerWithAIToolkit/lab4/code/github_mcp_server/src/server.py`
- `11-MCPServerHandsOnLabs/README.md`
- `11-MCPServerHandsOnLabs/01-Architecture/README.md`
- `11-MCPServerHandsOnLabs/02-Security/README.md`
- `11-MCPServerHandsOnLabs/05-MCP-Server/README.md`
- `11-MCPServerHandsOnLabs/06-Tools/README.md`
- `11-MCPServerHandsOnLabs/08-Testing/README.md`
- `11-MCPServerHandsOnLabs/11-Monitoring/README.md`
- `11-MCPServerHandsOnLabs/12-Best-Practices/README.md`

## Excluded Paths

- `.git/**`: clone metadata, not research content.
- `research/index.md`: explicitly not edited or reviewed for this assigned note because user requested no index edits.
- `translations/**`: generated/localized mirrors of primary English lessons; very large and duplicative. I sampled tree shape only to confirm duplication.
- `translated_images/**`: generated localized image assets; visual support, no unique implementation pattern.
- `images/**`, `**/assets/*.png`, `**/images/*.png`: screenshots, thumbnails, and UI walkthrough images. Useful for learners, not needed for code-pattern review except where adjacent docs described the flow.
- `*.ipynb` and translated notebook copies: notebook demos with large JSON/output metadata; reviewed surrounding Foundry/advanced docs instead of notebook internals.
- `package-lock.json`, `Cargo.lock`, `uv.lock`: generated dependency lockfiles. Not useful for curriculum/pattern review beyond noting ecosystem dependencies.
- `mvnw`, `mvnw.cmd`, `.mvn/wrapper/**`: Maven wrapper/bootstrap files, not MCP logic.
- `03-GettingStarted/15-mcp-apps/code/typescript/my-app/dist/**`: generated UI build output/declarations; source and README were enough to classify MCP Apps as UI-oriented.
- `03-GettingStarted/15-mcp-apps/ext-apps/examples/basic-host/**`: UI host/sandbox implementation; excluded from deep review because this note focuses on MCP education, server/client examples, security, verification, context control, and coding-agent applicability.
- `.github/**`, `CODE_OF_CONDUCT.md`, `SUPPORT.md`, `LICENSE`, badges, and community boilerplate: project hygiene, not execution path.
- Most `09-CaseStudy/**`: useful downstream examples but not core reusable implementation pattern for this note; covered at study-guide level only.
