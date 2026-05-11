# Caveman Upstream

This directory vendors the upstream `JuliusBrussee/caveman` skill without the installer, hooks, plugins, or tests from that repository.

Rules:

- `SKILL.upstream.md` is the upstream snapshot. Do not edit it by hand.
- `../../skills/caveman/SKILL.md` is the local derivative used by this lab.
- `local.patch` must equal `git diff --no-index -- SKILL.upstream.md ../../skills/caveman/SKILL.md`.
- `.github/workflows/vendor-skills.yml` enforces the patch invariant on every push and pull request.

Refresh flow:

1. Replace `SKILL.upstream.md` with the new upstream `skills/caveman/SKILL.md`.
2. Update `upstream.json` with the upstream commit, URL, fetch time, and SHA-256.
3. Review upstream changes and apply wanted changes to `../../skills/caveman/SKILL.md`.
4. Regenerate `local.patch`:

   ```bash
   git diff --no-index --abbrev=40 -- shared/upstreams/caveman/SKILL.upstream.md shared/skills/caveman/SKILL.md > shared/upstreams/caveman/local.patch || test $? -eq 1
   ```

5. Run the same vendor guard used by CI.
