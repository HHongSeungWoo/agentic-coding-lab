# RTK

Use RTK for shell commands so command output is filtered before it enters context.

## Rule

Prefix shell commands with `rtk` by default.

Examples:

```bash
rtk git status
rtk git diff
rtk rg "pattern"
rtk sed -n '1,220p' path/to/file
rtk npm run test
```

## Raw Output

Use `rtk proxy <command>` only when the unfiltered command output is required.

Examples:

```bash
rtk proxy git diff
rtk proxy npm run test
```

## Verification

Use these commands to verify the local RTK installation:

```bash
rtk --version
rtk gain
which rtk
```
