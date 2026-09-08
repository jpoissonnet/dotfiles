# Dotfiles

chezmoi source for macOS and Arch Linux. Work tooling lives in a separate
private source; see [docs/architecture.md](docs/architecture.md) for why and for
the rest of the design.

## Requirements

Only git, and chezmoi itself. Everything else is installed by `chezmoi apply`.

On Arch, bootstrap the handful of packages needed to run chezmoi at all:

```bash
sudo pacman -S --needed git openssh chezmoi zsh
```

On macOS, install [Homebrew](https://brew.sh) first, then `brew install chezmoi`.

## Install

```bash
chezmoi init git@github.com:jpoissonnet/dotfiles.git
chezmoi apply
chsh -s "$(command -v zsh)"
```

`init` asks for a git name, a git email, and whether this is a work machine. It
asks once per machine and caches the answers in
`~/.config/chezmoi/chezmoi.toml`, which is never committed.

`apply` installs packages with pacman or brew, then fills the gaps those cannot:
deno and bun on Arch, where there is no aarch64 package, plus a Rust toolchain,
a Node version via fnm, and pnpm via corepack. Re-run it any time.

To change the work answer later, edit `work` in
`~/.config/chezmoi/chezmoi.toml`. Re-running `init` will not change it, because
the prompt only fires when the key is absent.

## After apply

1. Generate an SSH key and add it to GitHub. Commit signing uses
   `~/.ssh/id_ed25519.pub`.
2. `gh auth login`.
3. Put tokens in `~/.secrets.zsh`, mode 600. `.zshrc` sources it if it exists
   and chezmoi never tracks it.
4. First `nvim` launch installs the LazyVim plugins and mason LSPs.
5. Optional: `atuin login` to sync shell history.

Not copied by design: `~/.ssh`, Cursor MCP and oauth config, `~/.claude.json`.

## Work machines

Work config is a separate private source that this one applies on top of, so
clone it to the path the chain expects:

```bash
git clone <private-url> ~/.local/share/chezmoi-work
```

Then `chezmoi apply`. Until that clone exists the chain prints a warning and
skips, so a fresh work machine can bootstrap before it has SSH access to the
private remote.

Never `chezmoi apply --source` that clone by hand. It shares this source's
config on purpose and expects to run as the second half of one apply.

## What this repo owns

zsh under `$ZDOTDIR`, antidote, p10k, nvim/LazyVim, kitty, git and delta, Cursor
user settings, the package lists, and aerospace on macOS only.

## Checking state

```bash
chezmoi status --exclude scripts   # must be empty
chezmoi verify --exclude scripts
```

`--exclude scripts` matters on a work machine: the chain that applies the
private source runs on every apply, so it always shows as pending.
