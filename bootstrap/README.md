# Bootstrap

This directory contains tooling for explicit install, update, and uninstall actions.

## Codex

Commands:

```bash
bootstrap/codex.sh install
bootstrap/codex.sh update
bootstrap/codex.sh uninstall
```

These commands manage active Codex profile artifacts in local Codex paths.
`CODEX_HOME` defaults to `~/.codex`.

`install` captures original local state in `myagents-installation.json`, then:

- checks whether `rtk` is available and writes `rtk-install-guide.txt` if not
- merges the managed inline `SessionStart` hook into `hooks.json`
- installs the local `caveman` skill into `$CODEX_HOME/skills/caveman`

It does not edit `config.toml`; enable Codex hook support separately if your
Codex version still requires a feature flag.

`update` reapplies the current repository artifacts without duplicating hook entries
or changing the recorded original state. It also repeats the RTK availability
check.

`uninstall` removes only the managed caveman hook and managed files. It restores the
previous caveman skill file based on the installation manifest.

Run lifecycle tests with:

```bash
bootstrap/test_codex.sh
```
