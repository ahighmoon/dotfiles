# dotfiles

Yifei's cross-platform development environment (macOS, WSL/Linux, and Windows), managed with [chezmoi](https://www.chezmoi.io).

## Quick start

### macOS

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

### Windows (PowerShell)

```powershell
winget install --id twpayne.chezmoi Microsoft.PowerShell
git clone https://github.com/ahighmoon/dotfiles.git D:\personal\dotfiles
chezmoi init --source D:\personal\dotfiles
chezmoi apply
```

### WSL / Linux

If `D:\personal\dotfiles` is already cloned on the Windows host, share it directly via a hidden symlink:

```bash
ln -sfn /mnt/d/personal/dotfiles ~/.dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
~/.local/bin/chezmoi init --source ~/.dotfiles
~/.local/bin/chezmoi apply
```

## What's managed

Config is split into three layers:

- **Shared**: identical on every machine (filtered by OS via `.chezmoiignore`), committed as-is.
- **Machine type**: templates keyed on `isWork` (work = ByteDance machine) and `.chezmoi.os`.
- **Machine-private**: never committed. Shared files load these if they exist.

| Source file | Target | OS / Layer / notes |
|-------------|--------|--------------------|
| `dot_zshrc` | `~/.zshrc` | macOS & Linux/WSL: oh-my-zsh + Powerlevel10k, toolchains (guarded); sources `~/.zshrc.local` |
| `dot_zprofile`, `dot_zlogin` | `~/.zprofile`, `~/.zlogin` | macOS & Linux/WSL: login-shell PATH; `.zlogin` loads `~/.profile` |
| `dot_profile` | `~/.profile` | macOS & Linux/WSL: brew (guarded), Android SDK; sources `~/.profile.local` |
| `dot_p10k.zsh` | `~/.p10k.zsh` | macOS & Linux/WSL: prompt config |
| `dot_tmux.conf` | `~/.tmux.conf` | macOS & Linux/WSL: tmux config |
| `dot_vimrc` | `~/.vimrc` | macOS & Linux/WSL: vim config |
| `private_dot_config/ghostty/config` | `~/.config/ghostty/config` | macOS only: Ghostty terminal config |
| `private_dot_config/powershell/profile.ps1` | `~/.config/powershell/profile.ps1` | Windows only: shared PowerShell 7 & 5.1 profile (PSReadLine predictions, syntax colors, async `posh-git`); sources `~/.profile.local.ps1` |
| `run_onchange_windows-install-profile.ps1.tmpl` | `$PROFILE` (loader) | Windows only: points both `PowerShell` and `WindowsPowerShell` `$PROFILE` to `~/.config/powershell/profile.ps1` |
| `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Windows Terminal `settings.json` | Windows only: GitHub Dark theme, 83% opacity, `ComicShannsMono Nerd Font`, Ghostty-style split shortcuts |
| `private_dot_config/git/config.tmpl` | `~/.config/git/config` | All OS: identity (`isWork`), aliases, VS Code diff/merge |
| `private_dot_config/git/ignore` | `~/.config/git/ignore` | All OS: global gitignore |
| `dot_gitconfig-ahighmoon.tmpl` | `~/.gitconfig-ahighmoon` | Work machines only: personal identity under `~/personal/dev/` |
| `create_private_dot_npmrc.tmpl` | `~/.npmrc` | All OS: registry (`isWork`); created once, never overwritten (login tokens live there) |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | All OS: GitHub key (auto-detects `id_ed25519_ahighmoon` / `id_ed25519` / `id_rsa`); work host + GSSAPI; includes `~/.ssh/config.local` |

`iterm2/Default.json` is a saved iTerm2 profile (colors + `ComicShannsMonoNF` font);
import it manually via iTerm2 → Preferences → Profiles → Import JSON Profiles.

## Machine-private files (not in this repo)

| File | What goes there |
|------|-----------------|
| `~/.zshrc.local` | macOS / Linux / WSL: credentials, conda, company tools and aliases, machine-specific paths |
| `~/.profile.local` | macOS / Linux / WSL: JDK paths, Python site-packages, company tool init |
| `~/.profile.local.ps1` | Windows: machine-specific PowerShell aliases, env vars, credentials |
| `~/.ssh/config.local` | All OS: internal hosts, jump hosts, university / cloud servers |
| `~/.gitconfig` | All OS: whatever tools write (`git lfs install`, hooksPath, `git maintenance`, OS-specific `core.autocrlf`) |

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
machine secrets in `~/.zshrc.local` or `~/.profile.local.ps1` (or a mode-600 file it sources). `isWork` only
changes what gets rendered: the templates themselves are visible to everyone.
