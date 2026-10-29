# dotfiles

Yifei's macOS development environment, managed with [chezmoi](https://www.chezmoi.io).

One command to restore everything on a new Mac:

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply ahighmoon
```

Or, if your terminal is sandboxed and cannot write under `~/.local` (macOS TCC),
use a writable source dir:

```bash
git clone https://github.com/ahighmoon/dotfiles.git ~/dev/dotfiles
chezmoi init  --source ~/dev/dotfiles --persistent-state ~/dev/dotfiles/.chezmoistate.boltdb
chezmoi apply --source ~/dev/dotfiles --persistent-state ~/dev/dotfiles/.chezmoistate.boltdb
```

## What's managed

Config is split into three layers:

- **Shared**: identical on every machine, committed as-is.
- **Machine type**: templates keyed on `isWork` (work = ByteDance machine).
- **Machine-private**: never committed. Shared files load these if they exist.

| Source file | Target | Layer / notes |
|-------------|--------|---------------|
| `dot_zshrc` | `~/.zshrc` | shared: oh-my-zsh + Powerlevel10k, toolchains (guarded); sources `~/.zshrc.local` |
| `dot_zprofile`, `dot_zlogin` | `~/.zprofile`, `~/.zlogin` | shared: login-shell PATH; `.zlogin` loads `~/.profile` |
| `dot_profile` | `~/.profile` | shared: brew, Android SDK; sources `~/.profile.local` |
| `dot_p10k.zsh` | `~/.p10k.zsh` | shared: prompt config |
| `dot_tmux.conf` | `~/.tmux.conf` | shared |
| `dot_config/ghostty/config` | `~/.config/ghostty/config` | shared |
| `dot_config/git/config.tmpl` | `~/.config/git/config` | machine type: identity; shared: aliases, VS Code diff/merge |
| `dot_config/git/ignore` | `~/.config/git/ignore` | shared |
| `dot_gitconfig-ahighmoon.tmpl` | `~/.gitconfig-ahighmoon` | work machines only: personal identity under `~/personal/dev/` |
| `create_dot_npmrc.tmpl` | `~/.npmrc` | machine type: registry; created once, never overwritten (login tokens live there) |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | shared: GitHub key; machine type: work host + GSSAPI; includes `~/.ssh/config.local` |

`iterm2/Default.json` is a saved iTerm2 profile (colors + `ComicShannsMonoNF` font);
import it manually via iTerm2 → Preferences → Profiles → Import JSON Profiles.

## Machine-private files (not in this repo)

| File | What goes there |
|------|-----------------|
| `~/.zshrc.local` | credentials, company tools and aliases, machine-specific paths |
| `~/.profile.local` | JDK paths, company tool init |
| `~/.ssh/config.local` | internal hosts, jump hosts |
| `~/.gitconfig` | whatever tools write: `git lfs install`, hooksPath, `git maintenance` |

Git reads `~/.config/git/config` first and `~/.gitconfig` after it, so never put
`[user]` in `~/.gitconfig`: it would override the identity rules.

## Machine types

On `chezmoi init`, you're prompted for your personal name and email, whether this
is a work (ByteDance) machine, and on work machines the work Git name and email.
The answers are stored in the local chezmoi config, not in this repo.

## Agent-assisted setup

This repo ships a TRAE skill at `.trae/skills/setup-dev-env/`. On a new machine,
after cloning, just tell the agent: "use the setup-dev-env skill to restore my
environment", and it will walk through chezmoi install, apply, oh-my-zsh plugins,
SSH keys, and verification.

## Daily use

```bash
chezmoi edit ~/.zshrc && chezmoi apply   # edit a config
chezmoi add ~/.somerc                    # track a new file
chezmoi update                           # git pull + apply
chezmoi diff                             # preview changes
```

## Security

This repo is public. Never commit plaintext secrets or SSH private keys; put
machine secrets in `~/.zshrc.local` (or a mode-600 file it sources). `isWork` only
changes what gets rendered: the templates themselves are visible to everyone.
