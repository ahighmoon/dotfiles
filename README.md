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

| Source file | Target | Notes |
|-------------|--------|-------|
| `dot_zshrc` | `~/.zshrc` | oh-my-zsh + Powerlevel10k, portable paths |
| `dot_profile` | `~/.profile` | brew, JAVA_HOME, Android SDK |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | user templated; work-only LFS/iDevops behind `isWork` |
| `dot_npmrc.tmpl` | `~/.npmrc` | bnpm for work, npmjs for personal |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | mode 600, no private keys |

## Machine types

On `chezmoi init`, you're prompted for name / personal email / whether this is a
work (ByteDance) machine / work email. Work-only settings (bnpm registry,
`code.byted.org` SSH host, iDevops Git LFS) are enabled only when `isWork = true`.

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

Never commit plaintext secrets or SSH private keys. Use `chezmoi add --encrypt`
for anything sensitive. Company-internal values are gated behind `isWork` and
kept out of the personal-machine render path.
