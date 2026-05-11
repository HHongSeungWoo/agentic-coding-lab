# Agentic Coding Lab

This context defines the canonical home for improving coding workflows that use AI coding agents, with Codex as the first implemented tool profile.

## Language

**Agentic Coding Lab**:
The canonical repository for researching, documenting, and implementing improvements to coding workflows that use AI coding agents.
_Avoid_: dotfiles repo, bootstrap repo, Codex-only repo

**Authoritative Artifact**:
A configuration file, instruction document, skill, plugin, MCP configuration, or supporting tool whose canonical copy lives in the **Agentic Coding Lab**.
_Avoid_: generated file, local state, cache

**Agentic Coding Artifact**:
An **Authoritative Artifact** that improves an AI coding agent's behavior, available tools, workflow fit, or repeatability.
_Avoid_: unrelated development environment setting

**Agentic Relevance**:
The requirement that an artifact directly improves an AI coding agent's behavior, tool access, repeatability, or verification ability.
_Avoid_: general developer convenience

**Activation State**:
The marker that distinguishes whether an **Agentic Coding Artifact** should be applied by default, kept available, or treated as experimental.
_Avoid_: investigation status, implementation status, priority

**Research Note**:
A first-class document that records an investigated agentic coding technique, its expected value, and whether it should become an **Agentic Coding Artifact**.
_Avoid_: scratch note, bookmark, implementation plan

**Investigation Status**:
The maturity marker for a **Research Note**, distinguishing unproven candidates from validated, rejected, or implemented findings.
_Avoid_: priority, confidence score, task status

**Tool Profile**:
The set of **Agentic Coding Artifacts** that target a specific AI coding agent.
_Avoid_: tool, agent, config folder

**Meaning-Centered Structure**:
A repository layout that groups artifacts by their role in agentic coding rather than by their eventual installation path.
_Avoid_: path mirror, dotfile mirror

**Codex Profile**:
The first **Tool Profile**, targeting Codex as the currently used AI coding agent.
_Avoid_: whole repository, generic agent profile

**Profile Manifest**:
The profile-owned document that declares artifact activation, installation targets, and instruction fragment order for a **Tool Profile**.
_Avoid_: installation manifest, package manifest, generated config

**Shared Artifact**:
An **Agentic Coding Artifact** that is useful across more than one **Tool Profile** and can be adapted into tool-specific forms.
_Avoid_: global config, default profile

**Bootstrap Script**:
A helper that places **Authoritative Artifacts** into tool-specific local paths on a machine.
_Avoid_: source of truth, installer

**Managed Installation**:
The local applied state produced when a **Bootstrap Script** explicitly installs, updates, or uninstalls **Authoritative Artifacts**.
_Avoid_: symlink mirror, live workspace

**Installation Manifest**:
The local record of files placed by a **Managed Installation** so update and uninstall actions can distinguish managed files from user-owned files.
_Avoid_: artifact manifest, research index, package lock

**Safe Uninstall**:
The rule that uninstall removes only files recorded in the **Installation Manifest** and never deletes user-owned local files.
_Avoid_: cleanup, reset, prune

**Managed Block**:
A marked section inserted into a user-owned instruction document that can be updated or removed without owning the whole file.
_Avoid_: append, merge, overwrite

**Instruction Fragment**:
An ordered piece of instruction content that can be composed into a **Managed Block** for an AI coding agent.
_Avoid_: final prompt, snippet, note

**Instruction Composition**:
The process of combining active **Instruction Fragments** into the managed instruction text installed for a **Tool Profile**.
_Avoid_: concatenation, prompt merge

**Fail-Closed Conflict Policy**:
The rule that bootstrap actions stop instead of overwriting unmanaged local content unless a safe managed-block operation or explicit user choice applies.
_Avoid_: best-effort merge, automatic overwrite

## Relationships

- An **Agentic Coding Lab** contains one or more **Agentic Coding Artifacts**.
- An **Agentic Coding Lab** contains one or more **Research Notes**.
- An **Agentic Coding Artifact** must have **Agentic Relevance**.
- An **Agentic Coding Artifact** has exactly one **Activation State** before bootstrap can apply it.
- A **Research Note** can lead to one or more **Agentic Coding Artifacts**.
- A **Research Note** has exactly one **Investigation Status**.
- Every **Agentic Coding Artifact** is an **Authoritative Artifact**.
- A **Tool Profile** groups **Agentic Coding Artifacts** for one AI coding agent.
- A **Tool Profile** uses a **Meaning-Centered Structure** internally.
- A **Tool Profile** owns exactly one **Profile Manifest**.
- The **Codex Profile** is the initial **Tool Profile**.
- A **Shared Artifact** can support more than one **Tool Profile**.
- A **Bootstrap Script** places **Authoritative Artifacts** onto a local machine.
- A **Bootstrap Script** is not itself the source of truth for agent behavior.
- A **Managed Installation** changes only through explicit install, update, or uninstall actions.
- A **Managed Installation** writes an **Installation Manifest**.
- **Safe Uninstall** depends on the **Installation Manifest**.
- A **Managed Block** allows a **Managed Installation** to coexist with user-owned instruction documents.
- An **Instruction Composition** produces a **Managed Block** from one or more **Instruction Fragments**.
- A **Profile Manifest** defines the **Instruction Fragment** order for a **Tool Profile**.
- A **Fail-Closed Conflict Policy** protects unmanaged local files from implicit overwrite.

## Example dialogue

> **Dev:** "Should the bootstrap script generate my Codex instructions from scratch?"
> **Domain expert:** "No. The Codex instructions belong to the **Codex Profile** as an **Authoritative Artifact**; the **Bootstrap Script** only places them where Codex expects them."

> **Dev:** "If I edit this repository, should Codex immediately see the change?"
> **Domain expert:** "No. Codex should only see the change after the **Managed Installation** is updated."

> **Dev:** "Can uninstall remove everything under my Codex config directory?"
> **Domain expert:** "No. **Safe Uninstall** removes only paths recorded in the **Installation Manifest**."

> **Dev:** "Can we add our Codex guidance to an existing AGENTS.md?"
> **Domain expert:** "Yes, but only as a **Managed Block** so update and uninstall can touch that section without owning the whole file."

> **Dev:** "Where do we put notes about a promising workflow from another agent tool?"
> **Domain expert:** "Capture it as a **Research Note** first. If it proves useful, turn it into an **Agentic Coding Artifact**."

## Flagged ambiguities

- "repo for settings" could mean either a canonical config repository or a machine bootstrapper. Resolved: this repo is an **Agentic Coding Lab** first, with bootstrap behavior as a supporting capability.
- "Codex settings" was narrower than the intended domain. Resolved: the domain is agentic coding overall, and Codex is the first **Tool Profile**.
- "placing files" could mean live symlinking or explicit application. Resolved: local tool state is a **Managed Installation**, not a symlink mirror of the repository.
- "append to AGENTS.md" could mean uncontrolled text append. Resolved: instruction documents use **Managed Blocks** when coexisting with user-owned content.
