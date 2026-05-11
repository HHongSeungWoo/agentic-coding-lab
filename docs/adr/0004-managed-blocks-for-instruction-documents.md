# Use Managed Blocks for Instruction Documents

Bootstrap actions may insert marked **Managed Blocks** into user-owned instruction documents such as `AGENTS.md` instead of overwriting the whole file. This keeps install, update, and uninstall safe for documents that users may already maintain manually, while structured configuration files still follow a fail-closed conflict policy unless the user explicitly adopts or overwrites them.
