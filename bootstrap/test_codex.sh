#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

codex_home=$tmp_root/codex
agents_home=$tmp_root/agents
no_rtk_path=$tmp_root/no-rtk-path
mkdir -p "$no_rtk_path"
for cmd in jq sha256sum awk date grep cat cp chmod dirname mkdir mktemp mv printf rm rmdir sed sort; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ln -s "$(command -v "$cmd")" "$no_rtk_path/$cmd"
  fi
done

assert_file() {
  if [ ! -f "$1" ]; then
    echo "Expected file: $1" >&2
    exit 1
  fi
}

assert_no_file() {
  if [ -e "$1" ]; then
    echo "Expected absent path: $1" >&2
    exit 1
  fi
}

assert_eq() {
  actual=$1
  expected=$2
  label=$3
  if [ "$actual" != "$expected" ]; then
    echo "$label: expected '$expected', got '$actual'" >&2
    exit 1
  fi
}

run_bootstrap() {
  PATH=$no_rtk_path CODEX_HOME=$codex_home AGENTS_HOME=$agents_home "$repo_root/bootstrap/codex.sh" "$1"
}

mkdir -p "$codex_home" "$codex_home/skills/caveman"

cat >"$codex_home/config.toml" <<'EOF'
model = "gpt-5.5"

[features]
other_feature = true
EOF

cat >"$codex_home/hooks.json" <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/bin/true"
          }
        ]
      }
    ]
  }
}
EOF

cat >"$codex_home/skills/caveman/SKILL.md" <<'EOF'
original skill
EOF

run_bootstrap install

assert_file "$codex_home/myagents-installation.json"
assert_file "$codex_home/rtk-install-guide.txt"
assert_file "$codex_home/skills/caveman/SKILL.md"
assert_no_file "$codex_home/hooks/caveman-session-start.sh"
assert_eq "$(grep -c '^hooks = true$' "$codex_home/config.toml" || true)" "0" "hooks flag not managed on install"
assert_eq "$(grep -c 'codex_hooks' "$codex_home/config.toml" || true)" "0" "no stale codex_hooks install"
assert_eq "$(jq '[.hooks.SessionStart[].hooks[] | select(.statusMessage == "Activating caveman")] | length' "$codex_home/hooks.json")" "1" "caveman hook install count"
assert_eq "$(jq '.hooks.Stop | length' "$codex_home/hooks.json")" "1" "user hook preserved"
assert_eq "$(grep -c '^name: caveman$' "$codex_home/skills/caveman/SKILL.md")" "1" "skill installed"
assert_eq "$(jq -r '.version' "$codex_home/myagents-installation.json")" "1" "manifest version"
assert_eq "$(jq -r '.original.config.managed' "$codex_home/myagents-installation.json")" "false" "config is not managed"
assert_eq "$(jq -r '.original.skill.existed' "$codex_home/myagents-installation.json")" "true" "original skill existence recorded"
assert_eq "$(jq '.managed_files | length' "$codex_home/myagents-installation.json")" "2" "managed file count"
assert_eq "$(grep -c 'rtk init -g --codex' "$codex_home/rtk-install-guide.txt")" "1" "rtk guide includes init"
assert_eq "$(jq -r '.hooks.SessionStart[0].matcher' "$codex_home/hooks.json")" "startup|clear" "resume excluded from matcher"
hook_output=$(/bin/sh -c "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$codex_home/hooks.json")")
printf '%s\n' "$hook_output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
printf '%s\n' "$hook_output" | jq -e '.hookSpecificOutput.additionalContext | contains("Caveman mode active")' >/dev/null

jq '.hooks.UserPromptSubmit = [{"hooks":[{"type":"command","command":"/bin/echo user"}]}]' "$codex_home/hooks.json" >"$codex_home/hooks.json.tmp"
mv "$codex_home/hooks.json.tmp" "$codex_home/hooks.json"

run_bootstrap update

assert_eq "$(jq '[.hooks.SessionStart[].hooks[] | select(.statusMessage == "Activating caveman")] | length' "$codex_home/hooks.json")" "1" "caveman hook update count"
assert_eq "$(jq '.hooks.UserPromptSubmit | length' "$codex_home/hooks.json")" "1" "user-added hook preserved on update"

run_bootstrap uninstall

assert_file "$codex_home/config.toml"
assert_file "$codex_home/hooks.json"
assert_file "$codex_home/skills/caveman/SKILL.md"
assert_eq "$(grep -c 'hooks' "$codex_home/config.toml" || true)" "0" "hooks still unmanaged on uninstall"
assert_eq "$(jq '[.. | objects | select((.command? // "") | contains("caveman-session-start.sh"))] | length' "$codex_home/hooks.json")" "0" "caveman hook removed on uninstall"
assert_eq "$(jq '.hooks.Stop | length' "$codex_home/hooks.json")" "1" "original user hook still present"
assert_eq "$(jq '.hooks.UserPromptSubmit | length' "$codex_home/hooks.json")" "1" "post-install user hook still present"
assert_eq "$(cat "$codex_home/skills/caveman/SKILL.md")" "original skill" "original skill restored"
assert_no_file "$codex_home/myagents-installation.json"

codex_home=$tmp_root/codex-rtk-found
agents_home=$tmp_root/agents-rtk-found
rtk_path=$tmp_root/rtk-path
mkdir -p "$codex_home" "$rtk_path"
cat >"$rtk_path/rtk" <<'EOF'
#!/bin/sh
printf 'rtk mock\n'
EOF
chmod 0755 "$rtk_path/rtk"

PATH=$rtk_path:$no_rtk_path CODEX_HOME=$codex_home AGENTS_HOME=$agents_home "$repo_root/bootstrap/codex.sh" install >"$tmp_root/rtk-found.out"

assert_file "$codex_home/myagents-installation.json"
assert_no_file "$codex_home/rtk-install-guide.txt"
assert_eq "$(grep -c 'RTK found:' "$tmp_root/rtk-found.out")" "1" "rtk found message"

codex_home=$tmp_root/codex-clean
agents_home=$tmp_root/agents-clean
mkdir -p "$codex_home"
cat >"$codex_home/config.toml" <<'EOF'
[features]
hooks = false
EOF

run_bootstrap install
assert_eq "$(grep -c '^hooks = false$' "$codex_home/config.toml")" "1" "original false flag untouched on install"
run_bootstrap uninstall

assert_file "$codex_home/config.toml"
assert_no_file "$codex_home/hooks.json"
assert_no_file "$codex_home/skills/caveman/SKILL.md"
assert_eq "$(grep -c '^hooks = false$' "$codex_home/config.toml")" "1" "original false flag untouched"

codex_home=$tmp_root/codex-legacy
agents_home=$tmp_root/agents-legacy
mkdir -p "$codex_home/hooks" "$agents_home/skills/caveman"
cat >"$codex_home/config.toml" <<'EOF'
[features]
codex_hooks = true
EOF
cat >"$codex_home/hooks/caveman-session-start.sh" <<'EOF'
#!/bin/sh
printf '%s\n' legacy
EOF
cp "$repo_root/shared/skills/caveman/SKILL.md" "$agents_home/skills/caveman/SKILL.md"
jq -n --arg config "$codex_home/config.toml" \
  --arg hooks "$codex_home/hooks.json" \
  --arg hook_script "$codex_home/hooks/caveman-session-start.sh" \
  --arg skill "$agents_home/skills/caveman/SKILL.md" \
  '{
    profile: "codex",
    repo: "legacy",
    installed_at: "2026-05-11T00:00:00Z",
    managed_files: [$config, $hooks, $hook_script, $skill]
  }' >"$codex_home/myagents-installation.json"
jq -n --arg cmd "$codex_home/hooks/caveman-session-start.sh" \
  '{
    hooks: {
      SessionStart: [
        {
          matcher: "startup|resume|clear",
          hooks: [
            {
              type: "command",
              command: $cmd,
              timeout: 5,
              statusMessage: "Activating caveman"
            }
          ]
        }
      ]
    }
  }' >"$codex_home/hooks.json"

run_bootstrap uninstall

assert_file "$codex_home/config.toml"
assert_no_file "$codex_home/hooks.json"
assert_no_file "$codex_home/hooks/caveman-session-start.sh"
assert_no_file "$agents_home/skills/caveman/SKILL.md"
assert_no_file "$codex_home/myagents-installation.json"
assert_eq "$(grep -c 'codex_hooks' "$codex_home/config.toml" || true)" "0" "legacy codex_hooks removed"

codex_home=$tmp_root/codex-migrate
agents_home=$tmp_root/agents-migrate
mkdir -p "$codex_home/hooks" "$agents_home/skills/caveman"
cat >"$codex_home/hooks/caveman-session-start.sh" <<'EOF'
#!/bin/sh
printf '%s\n' legacy
EOF
cp "$repo_root/shared/skills/caveman/SKILL.md" "$agents_home/skills/caveman/SKILL.md"
jq -n --arg hooks "$codex_home/hooks.json" \
  --arg hook_script "$codex_home/hooks/caveman-session-start.sh" \
  --arg old_skill "$agents_home/skills/caveman/SKILL.md" \
  --arg hook_sha "$(sha256sum "$codex_home/hooks/caveman-session-start.sh" | awk '{ print $1 }')" \
  --arg skill_sha "$(sha256sum "$repo_root/shared/skills/caveman/SKILL.md" | awk '{ print $1 }')" \
  '{
    version: 1,
    profile: "codex",
    repo: "old",
    installed_at: "2026-05-11T00:00:00Z",
    updated_at: "2026-05-11T00:00:00Z",
    paths: {
      hooks_json: $hooks,
      hook_script: $hook_script,
      skill: $old_skill
    },
    original: {
      config: { managed: false },
      hooks_json: { existed: false },
      hook_script: { existed: false, backup: "" },
      skill: { existed: false, backup: "" }
    },
    managed: {
      hook_script: { sha256: $hook_sha },
      skill: { sha256: $skill_sha }
    },
    managed_files: [$hooks, $hook_script, $old_skill]
  }' >"$codex_home/myagents-installation.json"
jq -n --arg cmd "$codex_home/hooks/caveman-session-start.sh" \
  '{
    hooks: {
      SessionStart: [
        {
          matcher: "startup|resume|clear",
          hooks: [
            {
              type: "command",
              command: $cmd,
              timeout: 5,
              statusMessage: "Activating caveman"
            }
          ]
        }
      ]
    }
  }' >"$codex_home/hooks.json"

run_bootstrap update

assert_no_file "$agents_home/skills/caveman/SKILL.md"
assert_no_file "$codex_home/hooks/caveman-session-start.sh"
assert_file "$codex_home/skills/caveman/SKILL.md"
assert_eq "$(jq -r '.paths.skill' "$codex_home/myagents-installation.json")" "$codex_home/skills/caveman/SKILL.md" "skill path migrated"
assert_eq "$(jq '.managed_files | length' "$codex_home/myagents-installation.json")" "2" "migrated managed file count"

echo "codex bootstrap lifecycle tests passed"
