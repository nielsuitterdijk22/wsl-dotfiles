# External tooling (third-party apt repos & manual installers)

These are **not** in the default Ubuntu repos. `scripts/install.sh` wires up the
repos and installs them. Listed here for reference / manual reproduction.

| Tool | Source | Notes |
|------|--------|-------|
| **GitHub CLI** (`gh`) | `cli.github.com` apt repo | Auth with `gh auth login` after install |
| **Azure CLI** (`az`) | `packages.microsoft.com` | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| **Azure Functions Core Tools 4** | `packages.microsoft.com` | pkg: `azure-functions-core-tools-4` |
| **Terraform** | HashiCorp apt repo | pkg: `terraform` |
| **PowerShell** (`pwsh`) | `packages.microsoft.com` | pkg: `powershell` |
| **.NET SDK 9 & 10** | `packages.microsoft.com` | pkgs: `dotnet-sdk-9.0`, `dotnet-sdk-10.0` |
| **Go** | apt | pkg: `golang-go` |
| **sqlcmd** | `packages.microsoft.com` | pkg: `sqlcmd` |
| **cosign** | sigstore apt repo | container signing |
| **kubectl** | binary in `/usr/local/bin` | `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"` |
| **NVM + Node** | `github.com/nvm-sh/nvm` | manages Node versions (see below) |
| **Docker** | Docker Desktop WSL integration | usually exposed from Windows host, not installed in-distro |
| **Miniconda** | `repo.anaconda.com` | optional Python env manager; `.zshrc`/`.bashrc` auto-source it if present |

## Node (via NVM)
Currently installed Node versions on the source machine:
- v20.18.3  (default / active)
- v19.9.0
- v16.20.2

After installing nvm: `nvm install 20 && nvm alias default 20`

## Oh My Zsh + Powerlevel10k
- Framework: [Oh My Zsh](https://ohmyz.sh)
- Theme: [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (config in `shell/p10k.zsh`)
- Custom plugins: `zsh-autosuggestions`, `azure-cli`
