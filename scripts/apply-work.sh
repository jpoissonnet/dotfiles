#!/usr/bin/env bash
set -euo pipefail

work="${CHEZMOI_WORK_SOURCE:-$HOME/.local/share/chezmoi-work}"

if [ ! -d "$work" ]; then
  exit 0
fi

exec chezmoi apply --source "$work" "$@"
