# wsl-dotfiles

My WSL (Ubuntu 24.04) development environment, captured so a fresh machine is one
script away. Shell config, git setup, Linux deps, and env-management tooling.

> **Source machine:** Ubuntu 24.04.2 LTS on WSL2 · zsh + Oh My Zsh + Powerlevel10k

## Quick start (new device)

```bash
# 1. Clone
git clone https://github.com/<you>/wsl-dotfiles.git ~/wsl-dotfiles
cd ~/wsl-dotfiles

# 2. Review, then bootstrap everything
less scripts/install.sh
./scripts/install.sh

# 3. New shell
exec zsh
```

Partial runs:

```bash
./scripts/install.sh --core      # apt packages only
./scripts/install.sh --external  # gh, az, terraform, kubectl
./scripts/install.sh --dotfiles  # symlink configs only
```

## What's in here

| Path | What |
|------|------|
| `shell/zshrc` | zsh config: Oh My Zsh plugins, aliases (git/az/tf/docker/k8s), nvm, direnv, conda hook |
| `shell/bashrc` | bash fallback (history, completion, conda init) |
| `shell/p10k.zsh` | Powerlevel10k prompt configuration |
| `git/gitconfig` | global git config (rebase pulls, autosetup remote, rerere, gh credential helper) |
| `git/gitconfig-work` · `git/gitconfig-personal` | per-context identity includes |
| `wsl/wsl.conf` | `/etc/wsl.conf` — systemd on, default user |
| `packages/apt-core.txt` | core apt packages, consumed by the installer |
| `packages/external-tools.md` | third-party repos & manual installers (az, terraform, dotnet, etc.) |
| `scripts/install.sh` | idempotent bootstrap: deps → omz/p10k → nvm → symlinks → wsl.conf → default shell |

## How the install works

`install.sh` symlinks the tracked files into `$HOME` (backing up any existing real
file as `*.bak.<timestamp>`), so edits made later in `~/.zshrc` flow straight back
into the repo. Pull the repo, `git diff`, commit — that's the update loop.

## Manual / host-side bits (not automated)

- **Docker** comes from Docker Desktop's WSL integration on the Windows host, not
  installed in-distro.
- **Miniconda** is optional — the shell rc files auto-source it *if present* at
  `~/miniconda3` / `~/miniconda`. Install separately if you want it.
- **Microsoft-repo tools** (PowerShell, .NET SDK 9/10, Azure Functions Core Tools,
  sqlcmd), **Go**, and **cosign**: see `packages/external-tools.md`.

## Notes / caveats

- The global `git/gitconfig` uses `helper = store`, which writes credentials in
  **plaintext** to `~/.git-credentials`. The GitHub-specific helper delegates to
  `gh auth git-credential` instead. Adjust to taste on a new box.
- `[maintenance] repo` in the gitconfig points at a machine-specific path — harmless,
  but repoint or drop it on a new device.
- Authenticate after install: `gh auth login`, `az login`.
