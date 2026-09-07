# Dotfiles

Public chezmoi source for a Mac or Arch Linux machine.

Work tooling lives in a private extra source. Do not add it here.

## New machine

```bash
# Arch first-boot pieces chezmoi will also install
sudo pacman -S --needed git openssh chezmoi zsh unzip base-devel

# SSH key for github.com, then
chezmoi init git@github.com:jpoissonnet/dotfiles.git
chezmoi apply
chsh -s /bin/zsh
```

`chezmoi init` asks for git name and email once. `chezmoi apply` installs Arch packages with pacman (sudo), then rustup, bun, deno, fnm, Node, pnpm, uv, and stylua. The script exits if any of those are missing after install. Darwin still uses Homebrew if `brew` exists. Linux does not use brew.

Re-run `chezmoi apply` any time. Scripts are `run_once` or `run_onchange`.

## After apply

1. Generate an SSH key and add it to GitHub. Signing uses `~/.ssh/id_ed25519.pub`.
2. `gh auth login` for github.com.
3. Put tokens in `~/.secrets.zsh` (mode 600). chezmoi never tracks that file.
4. Log into Cursor and Claude. This repo does not copy MCP, oauth, skills, or Cursor settings.
5. Reinstall Cursor plugins and clone personal skills into `~/.agents/skills` from their upstreams. Skip company-named skills.
6. Optional: `atuin login` to pull shell history.

## Work overlay

Do not `chezmoi apply --source` the whole private clone. That replaces nvim and zsh and renders git templates from the public config, so work email never wins.

Clone the private source, then apply only the overlay files:

```bash
git clone <private-dotfiles-url> ~/.local/share/chezmoi-work
# The clone must include the commit that removed tracked secrets from HEAD.
~/.local/share/chezmoi/scripts/apply-work.sh
```

`apply-work.sh` writes work aliases, company CLI hooks, and `~/.config/git/work.config`. Public `~/.gitconfig` includes that file when it exists.

Keep this Mac's existing chezmoi clone as that overlay. Do not push it to github.com.

## What this repo owns

- zsh, antidote, p10k
- nvim / LazyVim
- kitty
- git + delta
- Arch and Darwin package lists
- aerospace on Darwin only

## What you copy or log into

- `~/.secrets.zsh`
- `~/.ssh/` (new keys on the new laptop)
- Cursor MCP and oauth
- `~/.claude.json`. Do not copy it.
- Personal skills under `~/.agents/skills`
- Bitwarden, `gh` hosts other than github.com, AWS SSO
- nvim mason LSPs. First `nvim` launch installs them.

## Checks

```bash
./scripts/check-public.sh
```

That script must stay green before a push. It scans the worktree and git history, and it rejects work-internal names.
