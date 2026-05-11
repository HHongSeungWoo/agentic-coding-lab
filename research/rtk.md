---
title: RTK - Rust Token Killer
status: implemented
source: https://github.com/rtk-ai/rtk
implemented_artifacts:
  - profiles/codex/tools/rtk.yaml
  - profiles/codex/instructions/rtk.md
---

# RTK - Rust Token Killer

RTK is a command-line proxy that filters and compresses shell command output before it reaches an AI coding agent's context.

## Expected Value

RTK has strong agentic relevance because Codex frequently needs shell output from file listing, search, Git, build, lint, and test commands. Routing those commands through RTK can preserve the signal Codex needs while reducing context consumed by noisy command output.

## Decision

Implement RTK as the first active Codex profile artifact. The repository records RTK guidance and metadata, but it does not directly run RTK's global Codex initializer; applying the artifact to local Codex state remains the responsibility of future managed bootstrap tooling.

## Current Local Verification

- `rtk --version` reports `rtk 0.39.0`.
- `which rtk` resolves to `<HOME>/.local/bin/rtk`.
- `rtk gain` works outside the sandbox and reported `700.5K` tokens saved at `74.9%` savings on May 11, 2026.
