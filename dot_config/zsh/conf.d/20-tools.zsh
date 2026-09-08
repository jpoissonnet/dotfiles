export UV_NATIVE_TLS=1

# Node ships its own CA list and ignores the system trust store, so a
# TLS-inspecting proxy (corp SSE) breaks `fetch` while curl and the package
# manager keep working — corepack fails with "self-signed certificate in
# certificate chain". Point Node at the system bundle where there is one. No-op
# on macOS, which has no such file; left alone if something already set it.
if [[ -z ${NODE_EXTRA_CA_CERTS:-} && -r /etc/ssl/certs/ca-certificates.crt ]]; then
  export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
fi

(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"

[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
[[ -x "$HOME/.local/bin/terraform" ]] && complete -o nospace -C "$HOME/.local/bin/terraform" terraform
