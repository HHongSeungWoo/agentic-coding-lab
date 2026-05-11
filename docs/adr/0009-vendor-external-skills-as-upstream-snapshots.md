# Vendor External Skills as Upstream Snapshots

External skills that may be useful across more than one tool profile are **Shared Artifacts**, not profile-owned artifacts. Their local optimized form lives under `shared/skills/<name>/`, while the upstream source snapshot lives under `shared/upstreams/<name>/`.

Each vendored skill must keep three files together:

- `SKILL.upstream.md`: the upstream snapshot, never edited by hand.
- `upstream.json`: upstream repository, source path, commit, URL, fetch time, and hash.
- `local.patch`: the canonical diff from the upstream snapshot to the local derivative.

The repository enforces this invariant:

```text
git diff --no-index --abbrev=40 SKILL.upstream.md shared/skills/<name>/SKILL.md == local.patch
```

This keeps upstream updates reviewable without depending on conversation memory. A maintainer can refresh the upstream snapshot, inspect the upstream diff, choose which changes belong in the local derivative, regenerate `local.patch`, and let CI catch drift.
