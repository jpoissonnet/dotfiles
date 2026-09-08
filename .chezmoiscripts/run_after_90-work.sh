#!/bin/bash
set -euo pipefail

# Chains the private source on top of this one. chezmoi has a single source of
# truth by design; this is the FAQ's third workaround, a run_ script invoking a
# second instance. Gated by the `work` flag in .chezmoiignore, not in here.
#
# The second invocation MUST get its own --persistent-state: the outer apply
# holds a lock on the default boltdb for the duration of this script, so sharing
# it would deadlock. It deliberately does NOT get its own --config, because the
# private templates need the same data (work, git_name, git_email) that this
# apply already has.
#
# The private source must not contain a 90-work script of its own.

src="$HOME/.local/share/chezmoi-work"
state="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi-work/chezmoistate.boltdb"

if [[ ! -d "$src" ]]; then
  echo "work source not cloned; skipping the private overlay." >&2
  echo "  git clone <private-url> $src" >&2
  exit 0
fi

mkdir -p "$(dirname "$state")"
exec chezmoi apply --source "$src" --persistent-state "$state"
