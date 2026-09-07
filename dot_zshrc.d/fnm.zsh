alias nvm='fnm'
eval "$(fnm env --use-on-cd --shell=zsh --corepack-enabled --resolve-engines=true --version-file-strategy=recursive --log-level=quiet)"

# Keep fnm's node ahead of any distro or Homebrew node in PATH.
if [[ -n "$FNM_MULTISHELL_PATH" ]]; then
  path=("$FNM_MULTISHELL_PATH/bin" ${path:#"$FNM_MULTISHELL_PATH/bin"})
fi
