# Architecture

Why this repo is shaped the way it is. Mostly a record of decisions, plus the
chezmoi behaviour I got wrong the first time.

## One source, one private overlay

This repo used to have a twin: a work copy on the company GitHub Enterprise.
The two drifted. When I finally diffed them, 10 tracked files differed, and 4 of
those differed only because a fix had landed on one side and not the other.
Meanwhile `dot_p10k.zsh` at 1720 lines, all of nvim, kitty and aerospace were
byte identical. I was carrying roughly 2000 duplicated lines to keep about 20
lines private.

So this repo is the single source of truth for both machines. Work config lives
in a private source at `~/.local/share/chezmoi-work`, five files, applied on top
by `.chezmoiscripts/run_after_90-work.sh`.

chezmoi has one source of truth by design, and its FAQ is blunt about it. The
three documented workarounds all involve scripting around chezmoi. This is the
third one, a `run_` script invoking a second instance. The alternative, a shell
wrapper that runs `apply` twice, is what the old `apply-work.sh` did, and it
needed a file whitelist because a full second apply re-renders shared templates
from the wrong config.

Two details in that chain are load bearing. The second invocation gets its own
`--persistent-state`, because the outer apply holds a lock on the default boltdb
while the script runs and sharing it deadlocks. It deliberately shares the
config file, because the private templates want the same `work`, `git_name` and
`git_email` that this apply already resolved. That means no second config to
keep in sync.

Rejected: `.chezmoiexternal.toml` with a `git-repo` type, because externals are
not chezmoi managed. No templates, no `dot_` prefixes, and chezmoi cannot manage
any other file in that directory. Also rejected: a private branch, which you
rebase forever until one `git push` typo publishes it.

## What counts as private

Internal information only. Company and product names, internal hosts and URLs,
the corp CA path, internal CLI wrappers, work aliases. Anything structurally
generic stays here even if it is only ever useful at work.

That rule exists because the last boundary drifted. A `work.zsh` in the private
repo redefined three aliases that the public `aliases.zsh` already had, so the
work strings never actually left the public file. The overlay added a copy and
nobody removed the original.

The same rule decided two live cases. `awscli` is public, because installing the
aws CLI reveals nothing. The corp CA path is private, because it names the
vendor doing the TLS inspection.

## Machine class

`.chezmoi.toml.tmpl` asks `promptBoolOnce . "work" "Is this a work machine"` and
caches the answer. Everything work shaped reads that flag.

Hostname matching was the obvious alternative and it is worse. This Mac's
hostname is a corp asset tag that IT changes when they re-image, and hardcoding
it would put a work machine identifier in a public repo.

One sharp edge: the flag is sticky. `promptBoolOnce` only prompts when the key is
absent, so re-running `chezmoi init` will not change your answer. Edit
`~/.config/chezmoi/chezmoi.toml`.

## Packages first

pacman and brew both ship rustup, uv, fnm, stylua and the CLI tools, so they are
package names now. What used to be a 75 line curl bootstrap is two small
scripts. One installs deno and bun on Arch, which have no aarch64 package. The
other does the state no package carries: a Rust toolchain, a Node version, pnpm.

Every curl installer needed its own `export PATH`, and each of those got
mirrored into a `conf.d` file. That mirroring is where the file sprawl came from
and where four of five bugs lived. It also had a `cargo install stylua --locked`
that ran unconditionally, compiling from source on every fresh Mac, while
`stylua` sat in the brew list two files away.

nodejs and pnpm stay out of the package lists on purpose. fnm owns the Node
version with `--version-file-strategy=recursive --resolve-engines`, corepack owns
pnpm, and a distro node would fight both.

I looked at mise, which would collapse the remaining per tool files into one
config. Not yet. Packages get 80% of the win for an hour of work and no new
tool.

## Secrets

None in either repo. Credentials stay where their tool puts them, or in the
untracked `~/.secrets.zsh` that `.zshrc` sources. Anything that genuinely has to
be inlined comes from Proton Pass at apply time via `protonPass`, which needs
`pass-cli login` to have happened first.

Being a private repo already gives internal config confidentiality, so
`encrypted_` on top would add key management for nothing. It also leaks
filenames, paths and sizes.

## OS scoping

chezmoi has no OS or hostname filename attribute. The full prefix set is
`after_ before_ create_ dot_ empty_ encrypted_ exact_ executable_ external_
literal_ modify_ once_ onchange_ private_ readonly_ remove_ run_ symlink_`. That
leaves three tools, and the rule for picking between them is:

**Whole file differs by OS.** One line in the templated `.chezmoiignore`. Never a
whole body `{{ if }}`. An ignored file still shows up in `chezmoi managed`,
whereas a script that renders to zero bytes is invisible and exits 0.

**Three lines or fewer differ.** Keep the `{{ if }}` in the file.
`kitty.conf.tmpl` swapping cmd for ctrl is the right size. So is the zephyr
macos plugin line. `30-cursor.sh.tmpl` keeps its if/else at four lines as a
deliberate exception, because moving two values into a data file buys nothing.

**A value differs by OS.** Put it in `.chezmoidata` keyed by OS and read it with
`index`, guarded by `fail`.

**Gate on the package manager, never the distro.** `lookPath "pacman"` and
`lookPath "brew"`. Immune to arch versus archarm versus every derivative.

**Any surviving body gate gets a loud else** that writes to stderr and exits 1.
There are no smoke tests here, so that guard is the whole safety net.

### Three things I had to learn the hard way

`.chezmoiignore` patterns match target names, not source names. The old entry
read `dot_aerospace.toml`, which matches nothing, so the non-darwin gate never
fired and a macOS window manager config was sitting in `$HOME` on the Arch box.

`index` on a missing key is not an error. It renders `<no value>` and exits 0.
Direct field access is the loud form, so `.work` on a config without that key
aborts with `map has no entry for key "work"`, but it cannot take a dynamic key.
Hence `index` plus `fail`. `required` does not exist; chezmoi ships only part of
sprig.

`.git/**` and `.gitignore` need no ignore entry. chezmoi already skips dotfiles
in the source directory.

## Layout

zsh lives under `ZDOTDIR`, so `$HOME` holds one zsh file. `~/.zshenv` sets
`ZDOTDIR=~/.config/zsh` and everything else moved under it. In the source that
is one `dot_config/zsh/` tree instead of six `dot_zsh*` entries at the top
level.

`.zshrc` sources `conf.d/*.zsh(N)` in a three line loop. It used to rely on
zephyr's `confd` plugin, which hooks that work to `precmd`, so no non prompt
shell ever got the PATH ordering or the aliases. `zsh -ic 'alias oc'` reported
the alias missing. That also made the config close to untestable, since any
check ran in a different environment than the one you use. The loop runs after
`antidote load` to preserve the order confd produced.

Ten drop-in files holding eight lines of PATH exports are now four: `10-path`,
`20-fnm`, `20-tools`, `30-aliases`. The private source drops `90-work-*.zsh`
into the same directory, sorting last by construction.

Scripts live in `.chezmoiscripts/` with numeric prefixes. chezmoi does not
document how it orders scripts within a phase, and the old names had
`install-tools.sh` sorting before `linux-install-packages.sh`, so the tool
bootstrap looked for a C toolchain that `base-devel` had not installed yet.
Numbers make that explicit. `.chezmoiscripts/` also keeps scripts out of the
target namespace, where renaming one had left a stale state entry.

## Verification

No CI, no smoke script. Checks are `chezmoi status --exclude scripts` and a real
login shell.

CI would not have caught the bug that mattered. The distro gate rendered empty
on darwin and exited 0, and an x86 runner renders `arch` and passes, so
reproducing it needs an aarch64 runner plus sudo pacman plus an interactive
login shell. The Arch VM is the only thing that ever found these, and it found
another one after the restructure: Node ignores the system trust store, so
behind a TLS-inspecting corporate proxy corepack dies with "self-signed
certificate in certificate chain" while curl and pacman are fine. Under `set -e`
that aborts the apply. It looked healthy only because node and pnpm already
existed and the block was skipped.

## Known consequences

Nothing needs a secret today, so the Proton Pass wiring is speculative until
something does.

Now that `ZDOTDIR` moved, tool installers that append to `~/.zshrc` write to a
file nothing reads. Good for drift, but their PATH lines vanish silently, so
`conf.d/10-path.zsh.tmpl` has to be complete.

There is no publish gate. The old `check-public.sh` assembled internal strings at
runtime to grep for them, backed by three separate guards over one temp file. The
boundary rule and a `gitleaks` pass replaced it. That leaves review as the only
thing between a careless `chezmoi add` and a permanent public commit.

On a brand new Mac while the proxy is active, the before phase corepack step has
no CA fix available. macOS has no `/etc/ssl/certs` bundle and the corp CA path is
private, so export `NODE_EXTRA_CA_CERTS` yourself before the first apply.
