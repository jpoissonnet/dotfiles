#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

fail=0

if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks detect --source "$root" --no-git --redact --exit-code 1; then
    echo "gitleaks found secrets" >&2
    fail=1
  fi
else
  echo "gitleaks is not installed. Install it before publishing." >&2
  fail=1
fi

# Work-internal names and live-token assignments must not appear in this tree.
if matches="$(rg -n -i --hidden \
  --glob '!.git/**' \
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

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "public tree is clean"
