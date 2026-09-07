# Dotfiles

Public chezmoi source for a Mac or Arch Linux machine. Clone it, apply it, get a shell and nvim that work.

Work tooling lives in a private extra source. Do not add it here.

## New machine

```bash
# Arch first-boot pieces chezmoi will also install, if you want them early
sudo pacman -S --needed git openssh chezmoi zsh

# SSH key for github.com, then
chezmoi init git@github.com:jpoissonnet/dotfiles.git
chezmoi apply
chsh -s /bin/zsh
```

`chezmoi apply` installs Arch packages with pacman (sudo), then rustup, bun, deno, fnm, and stylua when they are missing. Darwin still uses Homebrew if `brew` exists. Linux does not use brew.

Re-run `chezmoi apply` any time. Scripts are `run_once` or `run_onchange`.

## After apply

1. Generate an SSH key and add it to GitHub. Signing uses `~/.ssh/id_ed25519.pub`.
2. `gh auth login` for github.com.
3. Put tokens in `~/.secrets.zsh` (mode 600). chezmoi never tracks that file.
4. Log into Cursor and Claude. MCP, skills, and hooks are not in this repo.
5. Optional: `atuin login` to pull shell history.

## Work overlay

If you have the private extra source:

```bash
git clone <private-dotfiles-url> ~/.local/share/chezmoi-work
chezmoi apply --source ~/.local/share/chezmoi-work
```

Or `scripts/apply-work.sh` after the public apply. Last apply wins for overlapping files. The private source owns work email, work aliases, and company CLI hooks.

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
- Cursor (`~/.cursor` has machine ids and a work MCP URL, leave it)
- Claude (`~/.claude.json` has credentials)
- Personal skills under `~/.claude/skills` and `~/.agents/skills`. Reinstall from their upstreams. Skip company-named skills here.
- Bitwarden / 1Password, `gh` hosts other than github.com, AWS SSO

## Checks

```bash
./scripts/check-public.sh
```

That script must stay green before a push. It runs gitleaks and rejects work-internal names.

## Rotate

A Turbo remote-cache token lived in the old private tree. Treat `TURBO_TOKEN` and `TURBO_REMOTE_CACHE_SIGNATURE_KEY` as leaked. Rotate them even if the private remote stays private. They now live only in `~/.secrets.zsh` on this Mac.
