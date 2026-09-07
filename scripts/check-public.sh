#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail=0

# Needles are assembled at runtime so this file does not contain them.
needles=(
  "$(printf '%s%s' bed rock)"
  "$(printf '%s%s' m6 web)"
  "$(printf '%s%s%s' bed rock streaming)"
  "$(printf '%s%s' TURBO_ TOKEN=)"
  "$(printf '%s%s' TURBO_ API=)"
)
needles+=("$(printf 'services.%s.tech' "$(printf '%s%s' bed rock)")")

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is not installed. Install it before publishing." >&2
  fail=1
else
  if [ -d "$root/.git" ]; then
    if ! gitleaks detect --source "$root" --redact --exit-code 1; then
      echo "gitleaks found secrets in git history" >&2
      fail=1
    fi
  fi
  if ! gitleaks detect --source "$root" --no-git --redact --exit-code 1; then
    echo "gitleaks found secrets in the worktree" >&2
    fail=1
  fi
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is not installed. Install it before publishing." >&2
  fail=1
else
  rg_args=(-n -i --hidden --no-ignore --glob '!.git/**' --glob '!.audit/**')
  for n in "${needles[@]}"; do
    rg_args+=(-e "$n")
  done
  if matches="$(rg "${rg_args[@]}" .)"; then
    echo "forbidden public-repo pattern:" >&2
    echo "$matches" >&2
    fail=1
  fi
fi

if [ -d "$root/.git" ]; then
  tracked_audit="$(git -C "$root" ls-files .audit)"
  if [ -n "$tracked_audit" ]; then
    echo ".audit is tracked and must not be published:" >&2
    echo "$tracked_audit" >&2
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "public tree is clean"
