---
name: setup-dev-env
description: Bootstrap a new macOS development machine from Yifei's dotfiles repo using chezmoi. Use when setting up a fresh Mac, restoring a dev environment, or applying these dotfiles on a new machine. Handles chezmoi install, dotfiles apply, SSH key setup, Homebrew packages, and verification. Do not use for routine single-file config edits.
---

# Setup Dev Environment (chezmoi + dotfiles)

This skill bootstraps Yifei's macOS development environment from this dotfiles repository using [chezmoi](https://www.chezmoi.io). Follow the steps in order. Stop and ask the user whenever a prompt requires their input (passwords, emails, GitHub actions).

## Repository layout

- `dot_zshrc`, `dot_profile` — shell config (portable, use `$HOME`)
- `dot_gitconfig.tmpl` — Git config; work-only sections gated behind `isWork`
- `dot_npmrc.tmpl` — npm registry (bnpm for work, npmjs for personal)
- `private_dot_ssh/config.tmpl` — SSH config (mode 600, no private keys)
- `.chezmoi.toml.tmpl` — prompts on init to fill name/email/isWork
- `.chezmoiignore` — files not deployed to home

## Step 0: Pre-flight checks

1. Confirm this is macOS on Apple Silicon: `uname -m` should print `arm64`.
2. Install Xcode Command Line Tools if missing:
   ```bash
   xcode-select -p >/dev/null 2>&1 || xcode-select --install
   ```
   Wait for the GUI installer to finish before continuing.
3. Verify network / GitHub reachability: `ping -c1 github.com`.

## Step 1: Install Homebrew (if missing)

```bash
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Step 2: Install chezmoi

```bash
brew install chezmoi
```

## Step 3: Init + apply dotfiles

Initialize from the GitHub repo. chezmoi will clone the repo and, because of
`.chezmoi.toml.tmpl`, prompt for name / personal email / whether this is a
work machine / work email.

```bash
chezmoi init --apply ahighmoon
```

IMPORTANT environment note: On some sandboxed terminals, chezmoi cannot write
under `~/.local` or `~/.config` due to macOS TCC. If `chezmoi init` fails with
`operation not permitted`, use a source dir under a writable location and pass
an explicit persistent-state path, e.g.:

```bash
git clone https://github.com/ahighmoon/dotfiles.git ~/dev/dotfiles
chezmoi init --source ~/dev/dotfiles --persistent-state ~/dev/dotfiles/.chezmoistate.boltdb
chezmoi apply --source ~/dev/dotfiles --persistent-state ~/dev/dotfiles/.chezmoistate.boltdb
```

When prompts appear, guide the user:
- "是否公司机器" → answer based on the machine's purpose
- personal / work email → enter the correct addresses
- sudo password (if any) → the user's login password

Preview before applying if unsure: `chezmoi diff`.

## Step 4: oh-my-zsh + plugins

The `.zshrc` expects oh-my-zsh, Powerlevel10k, and three plugins. Install them:

```bash
# oh-my-zsh
[ -d "$HOME/.oh-my-zsh" ] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Powerlevel10k theme
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# plugins
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
```

(The `z` plugin ships with oh-my-zsh.)

## Step 4.5: iTerm2 profile (colors + font)

The repo ships a saved iTerm2 profile at `iterm2/Default.json` (light/dark ANSI
colors, transparency, font `ComicShannsMonoNF-Regular 16`).

1. Install the Nerd Font it uses (needed for Powerlevel10k glyphs too):
   ```bash
   brew install --cask font-comic-shanns-mono-nerd-font font-meslo-lg-nerd-font
   ```
2. Import the profile in iTerm2: Preferences → Profiles → Other Actions →
   Import JSON Profiles → select `~/dev/dotfiles/iterm2/Default.json`.
3. Set it as the default profile if desired.
4. Note: the profile's `Working Directory` is hardcoded to `/Users/bytedance`;
   change it under Profiles → General → Working Directory if the username differs.

## Step 5: SSH key setup

1. Check for an existing key: `ls ~/.ssh/id_ed25519 2>/dev/null`.
2. If missing, generate one (ed25519, not the legacy id_rsa):
   ```bash
   ssh-keygen -t ed25519 -C "yifei-$(scutil --get LocalHostName 2>/dev/null || hostname)-$(date +%Y)" -f ~/.ssh/id_ed25519 -N ""
   ```
3. Print the public key and ask the user to add it to GitHub → Settings → SSH keys:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   URL: https://github.com/settings/keys
4. For a work machine, also add the key to the internal GitLab (code.byted.org).
5. Verify: `ssh -T git@github.com` (expect a success greeting).

## Step 6: Node via nvm (optional, if the user needs Node)

```bash
[ -d "$HOME/.nvm" ] || (git clone https://github.com/nvm-sh/nvm.git ~/.nvm && cd ~/.nvm && git checkout $(git describe --abbrev=0 --tags))
# then in a new shell:
nvm install --lts
```

## Step 7: Verification checklist

Run through and report each item:
- [ ] `chezmoi status` is clean (no pending diffs)
- [ ] Open a new terminal — Powerlevel10k renders, no errors
- [ ] `git config user.email` shows the expected address
- [ ] `cat ~/.npmrc` shows the correct registry for this machine type
- [ ] `ssh -T git@github.com` succeeds
- [ ] `brew --version` works
- [ ] For work machine: `ssh -T git@code.byted.org` succeeds

## Daily workflow (tell the user)

- Edit a config:  `chezmoi edit ~/.zshrc && chezmoi apply`
- Add a new file: `chezmoi add ~/.somerc`
- Pull updates:   `chezmoi update`  (git pull + apply)
- Preview:        `chezmoi diff`
- The source repo lives at the source dir (`chezmoi source-path`).

## Safety rules

1. NEVER commit plaintext secrets or SSH private keys. Use `chezmoi add --encrypt` for secrets, or keep them out of the repo entirely.
2. If `chezmoi apply` reports conflicts, show the diff and let the user decide (overwrite / keep / merge).
3. Company-internal settings (bnpm, code.byted.org, iDevops LFS paths) are gated behind `isWork`; do not enable them on a personal machine.
4. Homebrew/oh-my-zsh installs can take a while — show progress, do not interrupt.
