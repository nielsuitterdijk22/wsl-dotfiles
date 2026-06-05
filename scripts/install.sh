#!/usr/bin/env bash
# Bootstrap a fresh WSL (Ubuntu) dev environment from this repo.
# Idempotent-ish: safe to re-run. Review before executing on a real machine.
#
# Usage:
#   ./scripts/install.sh            # full setup
#   ./scripts/install.sh --core     # apt core packages only
#   ./scripts/install.sh --dotfiles # symlink dotfiles only
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

install_core() {
  log "Installing core apt packages"
  sudo apt-get update
  grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/apt-core.txt" | xargs sudo apt-get install -y
}

install_external() {
  log "Installing external-repo tooling (gh, az, terraform, ...)"

  # GitHub CLI
  if ! command -v gh >/dev/null; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update && sudo apt-get install -y gh
  fi

  # HashiCorp / Terraform
  if ! command -v terraform >/dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | \
      sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
      sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update && sudo apt-get install -y terraform
  fi

  # Azure CLI
  command -v az >/dev/null || curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

  # kubectl (latest stable, binary)
  if ! command -v kubectl >/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm -f kubectl
  fi

  warn "Microsoft repo tools (powershell, dotnet-sdk, azure-functions-core-tools, sqlcmd) and Go/cosign:"
  warn "  see packages/external-tools.md for the per-tool repo setup."
}

install_omz() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyz.sh/main/tools/install.sh 2>/dev/null || \
         curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$custom/themes/powerlevel10k" ] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
  [ -d "$custom/plugins/zsh-autosuggestions" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
}

install_nvm() {
  if [ ! -d "$HOME/.nvm" ]; then
    log "Installing NVM"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
    nvm install 20 && nvm alias default 20
  fi
}

link_dotfiles() {
  log "Symlinking dotfiles"
  backup() { [ -e "$1" ] && [ ! -L "$1" ] && mv "$1" "$1.bak.$(date +%s)" && warn "backed up $1"; }
  ln_s() { backup "$2"; ln -sfn "$1" "$2"; echo "  $2 -> $1"; }

  ln_s "$REPO_DIR/shell/zshrc"             "$HOME/.zshrc"
  ln_s "$REPO_DIR/shell/bashrc"            "$HOME/.bashrc"
  ln_s "$REPO_DIR/shell/p10k.zsh"          "$HOME/.p10k.zsh"
  ln_s "$REPO_DIR/git/gitconfig"           "$HOME/.gitconfig"
  ln_s "$REPO_DIR/git/gitconfig-work"      "$HOME/.gitconfig-work"
  ln_s "$REPO_DIR/git/gitconfig-personal"  "$HOME/.gitconfig-personal"
}

set_shell() {
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    log "Setting zsh as default shell"
    chsh -s "$(command -v zsh)" || warn "chsh failed; run manually: chsh -s \$(which zsh)"
  fi
}

apply_wsl_conf() {
  log "Applying /etc/wsl.conf (needs sudo)"
  sudo cp "$REPO_DIR/wsl/wsl.conf" /etc/wsl.conf
  warn "Run 'wsl --shutdown' from Windows for wsl.conf changes to take effect."
}

main() {
  case "${1:-all}" in
    --core)     install_core ;;
    --dotfiles) link_dotfiles ;;
    --external) install_external ;;
    all|"")
      install_core
      install_external
      install_omz
      install_nvm
      link_dotfiles
      apply_wsl_conf
      set_shell
      log "Done. Restart your shell (or 'exec zsh')."
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
}
main "$@"
