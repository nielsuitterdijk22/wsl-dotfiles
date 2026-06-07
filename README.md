# dotfiles

Cross-platform dev environment for **WSL (Ubuntu 24.04)** and **macOS**. Shell
config, git setup, package lists, and env-management tooling — one script to
bootstrap a fresh machine.

## Quick start

### WSL (Ubuntu)
```bash
git clone https://github.com/<you>/wsl-dotfiles.git ~/dotfiles
cd ~/dotfiles
less scripts/install.sh   # review first
./scripts/install.sh
exec zsh
```

### macOS
```bash
git clone https://github.com/<you>/wsl-dotfiles.git ~/dotfiles
cd ~/dotfiles
less scripts/install.sh   # review first
./scripts/install.sh      # installs Homebrew if missing, then packages
exec zsh
```

Partial runs (work on both platforms):

```bash
./scripts/install.sh --core      # packages only (apt on Linux, brew on macOS)
./scripts/install.sh --external  # gh, az, terraform, kubectl
./scripts/install.sh --dotfiles  # symlink configs only
```

## What's in here

| Path | What |
|------|------|
| `shell/zshrc` | zsh config: Oh My Zsh plugins, aliases (git/az/tf/docker/k8s), nvm, direnv, conda hook; Homebrew init on macOS |
| `shell/bashrc` | bash fallback (history, completion, conda init) |
| `shell/p10k.zsh` | Powerlevel10k prompt configuration |
| `git/gitconfig` | global git config (rebase pulls, autosetup remote, rerere, gh credential helper) |
| `git/gitconfig-work` · `git/gitconfig-personal` | per-context identity includes |
| `wsl/wsl.conf` | `/etc/wsl.conf` — systemd on, default user (Linux only) |
| `packages/apt-core.txt` | core apt packages (Linux) |
| `packages/brew-core.txt` | core Homebrew packages (macOS) |
| `packages/external-tools.md` | third-party tools with install commands for both platforms |
| `scripts/install.sh` | idempotent bootstrap: detects OS → deps → omz/p10k → nvm → symlinks → shell |

## How the install works

`install.sh` detects the OS at runtime and uses `brew` on macOS or `apt` on
Linux. It symlinks the tracked files into `$HOME` (backing up any existing real
file as `*.bak.<timestamp>`), so edits made in `~/.zshrc` etc. flow straight
back into the repo.

## Manual / host-side bits (not automated)

- **Docker**: Docker Desktop on macOS (Homebrew Cask: `docker`), or Docker
  Desktop's WSL integration on Windows.
- **Miniconda**: optional — the shell rc files auto-source it *if present* at
  `~/miniconda3` / `~/miniconda`. Install separately if you want it.
- **Microsoft-repo tools** (PowerShell, .NET SDK, Azure Functions Core Tools,
  sqlcmd), **Go**, and **cosign**: see `packages/external-tools.md`.

## Notes / caveats

- The global `git/gitconfig` uses `helper = store`, which writes credentials in
  **plaintext** to `~/.git-credentials`. The GitHub-specific helper delegates to
  `gh auth git-credential` instead. Adjust to taste on a new box.
- `[maintenance] repo` in the gitconfig points at a machine-specific path —
  harmless, but repoint or drop it on a new device.
- Authenticate after install: `gh auth login`, `az login`.
