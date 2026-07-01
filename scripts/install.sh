#!/usr/bin/env bash
# Bootstrap a fresh WSL (Ubuntu) or macOS dev environment from this repo.
# Idempotent-ish: safe to re-run. Review before executing on a real machine.
#
# Usage:
#   ./scripts/install.sh            # full setup
#   ./scripts/install.sh --core     # packages only (apt or brew)
#   ./scripts/install.sh --dotfiles # symlink dotfiles only
#   ./scripts/install.sh --external # gh, az, terraform, kubectl
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac
  log "Detected OS: $OS"
}

# ── macOS: Homebrew ────────────────────────────────────────────────────────────

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi
  log "Xcode Command Line Tools not found; triggering install"
  xcode-select --install 2>/dev/null || true
  warn "A GUI installer should have opened. Finish it, then re-run this script."
  exit 1
}

install_homebrew() {
  ensure_xcode_clt
  if ! command -v brew >/dev/null; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Apple Silicon: /opt/homebrew; Intel: /usr/local
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_core_macos() {
  install_homebrew
  log "Installing core Homebrew packages"
  grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/brew-core.txt" | xargs brew install
}

install_external_macos() {
  log "Installing external tooling via Homebrew"
  command -v gh        >/dev/null || brew install gh
  if ! command -v terraform >/dev/null; then
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
  fi
  command -v az        >/dev/null || brew install azure-cli
  command -v kubectl   >/dev/null || brew install kubectl
}

# ── Linux (WSL/Ubuntu): apt ───────────────────────────────────────────────────

install_core_linux() {
  log "Installing core apt packages"
  sudo apt-get update
  grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/apt-core.txt" | xargs sudo apt-get install -y
}

install_external_linux() {
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
    local arch
    arch=$(dpkg --print-architecture)
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm -f kubectl
  fi

  warn "Microsoft repo tools (powershell, dotnet-sdk, azure-functions-core-tools, sqlcmd) and Go/cosign:"
  warn "  see packages/external-tools.md for the per-tool repo setup."
}

# ── Shared ─────────────────────────────────────────────────────────────────────

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
  backup() {
    if [ -e "$1" ] && [ ! -L "$1" ]; then
      mv "$1" "$1.bak.$(date +%s)" && warn "backed up $1"
    fi
  }
  ln_s() { backup "$2"; ln -sfn "$1" "$2"; echo "  $2 -> $1"; }

  ln_s "$REPO_DIR/shell/zshrc"             "$HOME/.zshrc"
  ln_s "$REPO_DIR/shell/bashrc"            "$HOME/.bashrc"
  ln_s "$REPO_DIR/shell/p10k.zsh"          "$HOME/.p10k.zsh"
  ln_s "$REPO_DIR/git/gitconfig"           "$HOME/.gitconfig"
  ln_s "$REPO_DIR/git/gitconfig-work"      "$HOME/.gitconfig-work"
  ln_s "$REPO_DIR/git/gitconfig-personal"  "$HOME/.gitconfig-personal"
}

set_shell() {
  local zsh_path current_shell
  zsh_path="$(command -v zsh)"
  if [[ "$OS" == "macos" ]]; then
    current_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  else
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
  fi
  if [[ "$current_shell" != "$zsh_path" ]]; then
    log "Setting zsh as default shell"
    chsh -s "$zsh_path" || warn "chsh failed; run manually: chsh -s \$(which zsh)"
  fi
}

apply_wsl_conf() {
  log "Applying /etc/wsl.conf (needs sudo)"
  sudo cp "$REPO_DIR/wsl/wsl.conf" /etc/wsl.conf
  warn "Run 'wsl --shutdown' from Windows for wsl.conf changes to take effect."
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

install_core() {
  if [[ "$OS" == "macos" ]]; then install_core_macos; else install_core_linux; fi
}
install_external() {
  if [[ "$OS" == "macos" ]]; then install_external_macos; else install_external_linux; fi
}

main() {
  detect_os
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
      if [[ "$OS" == "linux" ]]; then apply_wsl_conf; fi
      set_shell
      log "Done. Restart your shell (or 'exec zsh')."
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
}
main "$@"
