#!/usr/bin/env bash
set -euo pipefail

work="${CHEZMOI_WORK_SOURCE:-$HOME/.local/share/chezmoi-work}"

if [ ! -d "$work" ]; then
  echo "no work source at $work" >&2
  exit 0
fi

# Only dest paths the private source owns. A full apply would replace nvim,
# zshrc, and git templates rendered from the public chezmoi config.
# Work CLI filenames are assembled so this public file does not name them.
cli="$(printf '%s%s-cli' bed rock)"
pairs=(
  "$HOME/.config/git/work.config:dot_config/git/work.config"
  "$HOME/.zshrc.d/${cli}.zsh:dot_zshrc.d/${cli}.zsh"
  "$HOME/.zshrc.d/cert.zsh:dot_zshrc.d/empty_cert.zsh"
  "$HOME/.zshrc.d/work.zsh:dot_zshrc.d/work.zsh"
)

applied=0
for pair in "${pairs[@]}"; do
  dest="${pair%%:*}"
  src="${pair##*:}"
  if [ -e "$work/$src" ] || [ -e "$work/${src}.tmpl" ]; then
    chezmoi apply --source "$work" "$dest"
    applied=$((applied + 1))
  fi
done

if [ "$applied" -eq 0 ]; then
  echo "work source has none of the overlay files" >&2
  exit 1
fi
