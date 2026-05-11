#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: bootstrap/codex.sh install|update|uninstall

Installs, updates, or uninstalls active Codex profile artifacts in local Codex paths.
EOF
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

checksum_file() {
  if [ -f "$1" ]; then
    sha256sum "$1" | awk '{ print $1 }'
  else
    printf ''
  fi
}

backup_file() {
  path=$1
  label=$2

  if [ ! -f "$path" ]; then
    printf ''
    return 0
  fi

  ts=$(date -u +%Y%m%d%H%M%S)
  backup_dir=$codex_home/backups
  backup=$backup_dir/$label.$ts.bak
  mkdir -p "$backup_dir"
  cp "$path" "$backup"
  printf '%s' "$backup"
}

check_rtk() {
  guide=$codex_home/rtk-install-guide.txt

  if command -v rtk >/dev/null 2>&1; then
    rm -f "$guide"
    echo "RTK found: $(command -v rtk)"
    echo "RTK manages its own Codex instructions; bootstrap will not modify them."
    return 0
  fi

  cat >"$guide" <<'EOF'
RTK not found.

RTK is recommended for this Codex profile, but bootstrap does not install it automatically.
Install RTK for your OS, then run:

  rtk init -g --codex

Guide:
  https://www.rtk-ai.app/guide

Repo:
  https://github.com/rtk-ai/rtk
EOF

  cat "$guide" >&2
}

install_caveman_skill() {
  skill_src=$repo_root/shared/skills/caveman/SKILL.md
  skill_dest=$codex_home/skills/caveman/SKILL.md

  mkdir -p "$codex_home/skills/caveman"
  cp "$skill_src" "$skill_dest"
}

register_hook() {
  hooks_json=$codex_home/hooks.json
  hook_template=$repo_root/profiles/codex/hooks/hooks.json
  input=$hooks_json
  tmp_in=$hooks_json.in.$$
  tmp_out=$hooks_json.tmp.$$
  managed_group=$hooks_json.managed.$$

  mkdir -p "$codex_home"

  if [ ! -f "$hooks_json" ]; then
    printf '{"hooks":{}}\n' >"$tmp_in"
    input=$tmp_in
  fi

  jq '.hooks.SessionStart[0]' "$hook_template" >"$managed_group"

  jq -e . "$input" >/dev/null
  jq --slurpfile managed "$managed_group" '
    if type != "object" then
      error("hooks.json top-level must be object")
    else . end
    | .hooks = (.hooks // {})
    | if (.hooks | type) != "object" then
      error("hooks must be object")
    else . end
    | .hooks.SessionStart = (
      (
        if ((.hooks.SessionStart // []) | type) == "array" then
          (.hooks.SessionStart // [])
        else
          error("hooks.SessionStart must be array")
        end
      )
      | map(
        .hooks = (
          (.hooks // [])
          | map(select((((.statusMessage // "") == "Activating caveman") | not)))
        )
      )
      | map(select(((.hooks // []) | length) > 0))
      + $managed
    )
  ' "$input" >"$tmp_out"

  mv "$tmp_out" "$hooks_json"
  rm -f "$tmp_in" "$managed_group"
}

unregister_hook() {
  hooks_json=$codex_home/hooks.json
  tmp=$hooks_json.tmp.$$

  [ -f "$hooks_json" ] || return 0

  jq '
    if type != "object" then
      error("hooks.json top-level must be object")
    else . end
    | .hooks = (.hooks // {})
    | if (.hooks | type) != "object" then
      error("hooks must be object")
    else . end
    | .hooks.SessionStart = (
      (
        if ((.hooks.SessionStart // []) | type) == "array" then
          (.hooks.SessionStart // [])
        else
          error("hooks.SessionStart must be array")
        end
      )
      | map(
        .hooks = (
          (.hooks // [])
          | map(select((((.statusMessage // "") == "Activating caveman") | not)))
        )
      )
      | map(select(((.hooks // []) | length) > 0))
    )
    | if (.hooks.SessionStart | length) == 0 then
      del(.hooks.SessionStart)
    else . end
    | if (.hooks | length) == 0 then
      del(.hooks)
    else . end
  ' "$hooks_json" >"$tmp"

  original_hooks_existed=$(jq -r '.original.hooks_json.existed' "$manifest")
  if [ "$original_hooks_existed" = "false" ] && jq -e '(.hooks // {}) | length == 0' "$tmp" >/dev/null; then
    rm -f "$hooks_json" "$tmp"
  else
    mv "$tmp" "$hooks_json"
  fi
}

restore_managed_file() {
  path=$1
  expected_sha=$2
  original_existed=$3
  backup_path=$4

  if [ -f "$path" ]; then
    current_sha=$(checksum_file "$path")
    if [ "$current_sha" != "$expected_sha" ]; then
      echo "Refusing to change modified managed file: $path" >&2
      exit 1
    fi
  fi

  if [ "$original_existed" = "true" ]; then
    if [ ! -f "$backup_path" ]; then
      echo "Missing backup for original file: $backup_path" >&2
      exit 1
    fi
    mkdir -p "$(dirname -- "$path")"
    cp "$backup_path" "$path"
  else
    rm -f "$path"
    rmdir "$(dirname -- "$path")" 2>/dev/null || true
  fi
}

capture_originals() {
  hooks_json_path=$codex_home/hooks.json
  skill_path=$codex_home/skills/caveman/SKILL.md

  if [ -f "$hooks_json_path" ]; then
    original_hooks_existed=true
  else
    original_hooks_existed=false
  fi

  if [ -f "$skill_path" ]; then
    original_skill_existed=true
    original_skill_backup=$(backup_file "$skill_path" caveman-skill)
  else
    original_skill_existed=false
    original_skill_backup=
  fi
}

apply_artifacts() {
  install_caveman_skill
  register_hook
}

write_manifest_from_captured_originals() {
  manifest=$codex_home/myagents-installation.json
  skill_path=$codex_home/skills/caveman/SKILL.md
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq -n \
    --arg repo "$repo_root" \
    --arg installed_at "$now" \
    --arg updated_at "$now" \
    --arg hooks "$codex_home/hooks.json" \
    --arg skill "$skill_path" \
    --arg original_hooks_existed "$original_hooks_existed" \
    --arg original_skill_existed "$original_skill_existed" \
    --arg original_skill_backup "$original_skill_backup" \
    --arg skill_sha "$(checksum_file "$skill_path")" \
    '{
      version: 1,
      profile: "codex",
      repo: $repo,
      installed_at: $installed_at,
      updated_at: $updated_at,
      paths: {
        hooks_json: $hooks,
        skill: $skill
      },
      original: {
        config: {
          managed: false
        },
        hooks_json: {
          existed: ($original_hooks_existed == "true")
        },
        skill: {
          existed: ($original_skill_existed == "true"),
          backup: $original_skill_backup
        }
      },
      managed: {
        skill: {
          sha256: $skill_sha
        }
      },
      managed_files: [$hooks, $skill]
    }' >"$manifest"
}

write_manifest_for_update() {
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  tmp=$manifest.tmp.$$
  skill_path=$codex_home/skills/caveman/SKILL.md

  jq \
    --arg repo "$repo_root" \
    --arg updated_at "$now" \
    --arg hooks "$codex_home/hooks.json" \
    --arg skill "$skill_path" \
    --arg skill_sha "$(checksum_file "$skill_path")" \
    '.version = 1
      | .repo = $repo
      | .updated_at = $updated_at
      | .paths = {
          hooks_json: $hooks,
          skill: $skill
        }
      | .original.config = { managed: false }
      | .managed = {
          skill: { sha256: $skill_sha }
        }
      | .managed_files = [$hooks, $skill]' \
    "$manifest" >"$tmp"
  mv "$tmp" "$manifest"
}

require_manifest_v1() {
  if [ ! -f "$manifest" ]; then
    echo "No managed Codex installation found: $manifest" >&2
    exit 1
  fi

  if ! jq -e '.version == 1 and (.original.hooks_json | type == "object")' "$manifest" >/dev/null; then
    echo "Unsupported or legacy installation manifest: $manifest" >&2
    echo "Uninstall legacy local state manually, then run install again." >&2
    exit 1
  fi
}

remove_legacy_hook_from_file() {
  hooks_json=$1
  tmp=$hooks_json.tmp.$$

  [ -n "$hooks_json" ] || return 0
  [ -f "$hooks_json" ] || return 0

  jq '
    if type != "object" then
      error("hooks.json top-level must be object")
    else . end
    | .hooks = (.hooks // {})
    | if (.hooks | type) != "object" then
      error("hooks must be object")
    else . end
    | .hooks.SessionStart = (
      (
        if ((.hooks.SessionStart // []) | type) == "array" then
          (.hooks.SessionStart // [])
        else
          error("hooks.SessionStart must be array")
        end
      )
      | map(
        .hooks = (
          (.hooks // [])
          | map(select(((((.command // "") | contains("caveman-session-start.sh")) or ((.statusMessage // "") == "Activating caveman")) | not)))
        )
      )
      | map(select(((.hooks // []) | length) > 0))
    )
    | if (.hooks.SessionStart | length) == 0 then
      del(.hooks.SessionStart)
    else . end
    | if (.hooks | length) == 0 then
      del(.hooks)
    else . end
  ' "$hooks_json" >"$tmp"

  if jq -e '(.hooks // {}) | length == 0' "$tmp" >/dev/null; then
    rm -f "$hooks_json" "$tmp"
  else
    mv "$tmp" "$hooks_json"
  fi
}

remove_legacy_managed_file() {
  path=$1
  expected_sha=$2

  [ -n "$path" ] || return 0
  [ -f "$path" ] || return 0
  [ -n "$expected_sha" ] || return 0

  current_sha=$(checksum_file "$path")
  if [ "$current_sha" != "$expected_sha" ]; then
    echo "Refusing to remove modified legacy managed file: $path" >&2
    exit 1
  fi

  rm -f "$path"
  rmdir "$(dirname -- "$path")" 2>/dev/null || true
}

remove_legacy_codex_hooks_flag() {
  config=$1
  tmp=$config.tmp.$$

  [ -n "$config" ] || return 0
  [ -f "$config" ] || return 0

  awk '
    BEGIN {
      in_features = 0
    }
    /^[[:space:]]*\[features\][[:space:]]*$/ {
      in_features = 1
      print
      next
    }
    /^[[:space:]]*\[/ {
      in_features = 0
    }
    in_features && /^[[:space:]]*codex_hooks[[:space:]]*=/ {
      next
    }
    { print }
  ' "$config" >"$tmp"

  mv "$tmp" "$config"
}

cleanup_previous_managed_skill_path() {
  previous_skill_path=$(jq -r '.paths.skill // empty' "$manifest")
  current_skill_path=$codex_home/skills/caveman/SKILL.md

  [ -n "$previous_skill_path" ] || return 0
  [ "$previous_skill_path" != "$current_skill_path" ] || return 0
  [ -f "$previous_skill_path" ] || return 0

  expected_sha=$(jq -r '.managed.skill.sha256 // empty' "$manifest")
  current_sha=$(checksum_file "$previous_skill_path")
  if [ -n "$expected_sha" ] && [ "$current_sha" != "$expected_sha" ]; then
    echo "Refusing to remove modified previous managed skill: $previous_skill_path" >&2
    exit 1
  fi

  rm -f "$previous_skill_path"
  rmdir "$(dirname -- "$previous_skill_path")" 2>/dev/null || true
}

cleanup_previous_managed_hook_script_path() {
  previous_hook_script_path=$(jq -r '.paths.hook_script // empty' "$manifest")

  [ -n "$previous_hook_script_path" ] || return 0
  [ -f "$previous_hook_script_path" ] || return 0

  expected_sha=$(jq -r '.managed.hook_script.sha256 // empty' "$manifest")
  current_sha=$(checksum_file "$previous_hook_script_path")
  if [ -n "$expected_sha" ] && [ "$current_sha" != "$expected_sha" ]; then
    echo "Refusing to remove modified previous managed hook script: $previous_hook_script_path" >&2
    exit 1
  fi

  rm -f "$previous_hook_script_path"
  rmdir "$(dirname -- "$previous_hook_script_path")" 2>/dev/null || true
}

uninstall_legacy_cmd() {
  config_path=$(jq -r 'if (.managed_files | length) == 4 then .managed_files[0] else empty end // empty' "$manifest")
  hooks_json_path=$(jq -r 'if (.managed_files | length) == 4 then .managed_files[1] else .managed_files[0] end // empty' "$manifest")
  hook_script_path=$(jq -r '
    if (.managed_files | length) == 4 then .managed_files[2]
    elif (.paths.hook_script // "") != "" then .paths.hook_script
    else empty end // empty
  ' "$manifest")
  skill_path=$(jq -r '
    if (.managed_files | length) == 4 then .managed_files[3]
    elif (.managed_files | length) == 3 then .managed_files[2]
    elif (.managed_files | length) == 2 then .managed_files[1]
    else empty end // empty
  ' "$manifest")

  remove_legacy_codex_hooks_flag "$config_path"
  remove_legacy_hook_from_file "$hooks_json_path"
  hook_script_sha=$(jq -r '.managed.hook_script.sha256 // empty' "$manifest")
  if [ -z "$hook_script_sha" ]; then
    hook_script_sha=$(checksum_file "$hook_script_path")
  fi

  remove_legacy_managed_file "$hook_script_path" "$hook_script_sha"
  remove_legacy_managed_file "$skill_path" "$(checksum_file "$repo_root/shared/skills/caveman/SKILL.md")"
  rm -f "$manifest"

  echo "Uninstalled legacy Codex profile from $codex_home"
}

install_cmd() {
  mkdir -p "$codex_home"
  manifest=$codex_home/myagents-installation.json

  if [ -f "$manifest" ]; then
    echo "Managed Codex installation already exists. Use update or uninstall." >&2
    exit 1
  fi

  capture_originals
  check_rtk
  apply_artifacts
  write_manifest_from_captured_originals
  echo "Installed Codex profile into $codex_home"
}

update_cmd() {
  mkdir -p "$codex_home"
  manifest=$codex_home/myagents-installation.json

  if [ ! -f "$manifest" ]; then
    install_cmd
    return 0
  fi

  if ! jq -e '.version == 1 and (.original.hooks_json | type == "object")' "$manifest" >/dev/null; then
    uninstall_legacy_cmd
    install_cmd
    return 0
  fi

  require_manifest_v1
  cleanup_previous_managed_hook_script_path
  cleanup_previous_managed_skill_path
  check_rtk
  apply_artifacts
  write_manifest_for_update
  echo "Updated Codex profile in $codex_home"
}

uninstall_cmd() {
  manifest=$codex_home/myagents-installation.json

  if [ ! -f "$manifest" ]; then
    echo "No managed Codex installation found: $manifest" >&2
    exit 1
  fi

  if ! jq -e '.version == 1 and (.original.hooks_json | type == "object")' "$manifest" >/dev/null; then
    uninstall_legacy_cmd
    return 0
  fi

  require_manifest_v1

  skill_path=$(jq -r '.paths.skill' "$manifest")
  skill_sha=$(jq -r '.managed.skill.sha256' "$manifest")
  skill_original_existed=$(jq -r '.original.skill.existed' "$manifest")
  skill_backup=$(jq -r '.original.skill.backup // empty' "$manifest")

  unregister_hook
  restore_managed_file "$skill_path" "$skill_sha" "$skill_original_existed" "$skill_backup"
  rm -f "$manifest"

  echo "Uninstalled Codex profile from $codex_home"
}

main() {
  action=${1:-}
  if [ -z "$action" ]; then
    usage >&2
    exit 2
  fi

  need_cmd jq
  need_cmd sha256sum

  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
  codex_home=${CODEX_HOME:-"$HOME/.codex"}
  manifest=$codex_home/myagents-installation.json

  case "$action" in
    install)
      install_cmd
      ;;
    update)
      update_cmd
      ;;
    uninstall)
      uninstall_cmd
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
