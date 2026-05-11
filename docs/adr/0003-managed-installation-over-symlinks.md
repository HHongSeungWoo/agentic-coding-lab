# Use Managed Installation Instead of Live Symlinks

Bootstrap behavior uses explicit install, update, and uninstall actions instead of making local agent-tool paths live symlinks to the repository. This preserves a boundary between editing authoritative artifacts and changing the active Codex environment, while still allowing the bootstrap tooling to keep local state reproducible from the repository.
