# Use Codex SessionStart Hook for Default Caveman Mode

Codex should activate caveman response style at session startup through a profile-owned `SessionStart` hook instead of relying on conversation memory or a manual `$caveman` invocation.

The hook emits concise developer context that applies the visible-response style by default. It does not attempt to alter hidden reasoning. Bootstrap registers the hook in the local Codex home as a **Managed Installation**, while leaving Codex feature flags to the user's local Codex configuration.

This keeps the default behavior reproducible after the conversation is forgotten while preserving the repository boundary: the **Codex Profile** owns the hook artifacts, and the **Bootstrap Script** applies them to Codex's local runtime paths.
