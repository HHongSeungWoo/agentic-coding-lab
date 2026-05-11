# Defer a Root Manifest

The repository starts with profile-owned manifests and no root manifest. A root manifest would force repository-wide orchestration semantics before multiple tool profiles or shared activation rules exist, so it should be introduced only when profile-level manifests are no longer enough.
