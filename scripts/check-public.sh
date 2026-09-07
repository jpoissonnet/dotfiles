#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail=0

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is not installed. Install it before publishing." >&2
  fail=1
elif ! gitleaks detect --source "$root" --no-git --redact --exit-code 1; then
  echo "gitleaks found secrets" >&2
  fail=1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is not installed. Install it before publishing." >&2
  fail=1
else
  # --no-ignore so a gitignored leak still fails. .audit stays local and names
  # the private remote, so exclude it. git ls-files below refuses to track it.
  if matches="$(rg -n -i --hidden --no-ignore \
    --glob '!.git/**' \
    --glob '!.audit/**' \
    --glob '!scripts/check-public.sh' \
    -e 'bedrock' \
    -e 'm6web' \
    -e 'bedrockstreaming' \
    -e 'TURBO_TOKEN=' \
    -e 'TURBO_API=' \
    -e 'services\.bedrock\.tech' \
    .)"; then
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
