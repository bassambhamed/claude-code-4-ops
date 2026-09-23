#!/usr/bin/env bash
# PreToolUse hook: blocks Write/Edit/MultiEdit when the new content looks like it contains a secret.
# Input: hook JSON on stdin. Exit 2 = block (stderr is sent back to Claude). Exit 0 = allow.

set -uo pipefail

input="$(cat)"

file_path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$input")"

# Text that is about to be written, for each tool shape.
content="$(jq -r '
  .tool_input
  | [ .content?, .new_string?, .new_source?, ((.edits? // [])[] | .new_string?) ]
  | map(select(. != null))
  | join("\n")
' <<<"$input")"

[ -z "$content" ] && exit 0

# Files that legitimately contain secret-like patterns (this script itself, docs of the hook).
case "$file_path" in
  */.claude/hooks/scan-secrets.sh) exit 0 ;;
esac

findings=""

check() {
  local label="$1" regex="$2" flags="${3:-}"
  local match
  match="$(grep -En $flags -e "$regex" <<<"$content" | head -n 3)"
  if [ -n "$match" ]; then
    # Show the line number only, not the secret itself.
    local lines
    lines="$(cut -d: -f1 <<<"$match" | paste -sd, -)"
    findings+="  - ${label} (line(s) ${lines} of the new content)"$'\n'
  fi
}

# Well-known token formats
check "Private key block"             '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
check "AWS access key ID"             '(AKIA|ASIA)[0-9A-Z]{16}'
check "GitHub token"                  '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}'
check "Slack token"                   'xox[abprs]-[A-Za-z0-9-]{10,}'
check "Stripe live key"               '(sk|rk)_live_[A-Za-z0-9]{20,}'
check "Anthropic API key"             'sk-ant-[A-Za-z0-9_-]{20,}'
check "OpenAI API key"                'sk-(proj-)?[A-Za-z0-9]{32,}'
check "Google API key"                'AIza[0-9A-Za-z_-]{35}'
check "Azure storage account key"     'AccountKey=[A-Za-z0-9+/=]{40,}'
check "JWT"                           'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'

# Connection strings with an inline password (appsettings.json, env vars, ...)
check "Connection string with password" '(password|pwd)=[^;"'"'"'[:space:]<$]{6,}' -i

# Generic "secret = literal" assignments (C#, JSON, YAML, env files).
# Skips placeholders like "", "<...>", "${VAR}", "changeme", "xxx".
generic="$(grep -Eni -e '(api[_-]?key|secret|token|password|passwd|client[_-]?secret)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']' <<<"$content" \
  | grep -Evi -e '["'"'"'](<[^>]*>|\$\{[^}]*\}|changeme|change-me|your[_-]|example|placeholder|dummy|x{6,}|\*{6,})' \
  | head -n 3)"
if [ -n "$generic" ]; then
  lines="$(cut -d: -f1 <<<"$generic" | paste -sd, -)"
  findings+="  - Hard-coded secret assignment (line(s) ${lines} of the new content)"$'\n'
fi

if [ -n "$findings" ]; then
  {
    echo "BLOCKED by scan-secrets hook: possible secret in ${file_path:-<unknown file>}"
    printf '%s' "$findings"
    echo "Do not hard-code secrets. Use 'dotnet user-secrets', environment variables, or Aspire parameters (builder.AddParameter(..., secret: true)) instead."
  } >&2
  exit 2
fi

exit 0
