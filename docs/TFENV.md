# tfenv — Terraform Version Manager

[tfenv](https://github.com/tfutils/tfenv) manages multiple Terraform versions, similar to `rbenv` or `nvm`.

---

## How It Works

```
.terraform-version    ← Pin file at repo root (committed to git)
       │
       ▼
    tfenv use         ← Reads pin file, activates that version
       │
       ▼
  ~/.tfenv/versions/  ← Installed versions live here
```

When you `cd` into this repo, tfenv automatically selects the version in `.terraform-version`.

---

## Installation

### Linux / macOS (manual)

```bash
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
sudo ln -s ~/.tfenv/bin/* /usr/local/bin/
```

### macOS (Homebrew)

```bash
brew install tfenv
```

### Via this template

```bash
make dev-setup    # Installs tfenv + pins terraform version
```

---

## Common Commands

```bash
# List available versions
tfenv list-remote

# Install a specific version
tfenv install 1.11.3

# Install the version from .terraform-version
tfenv install

# Switch to a version
tfenv use 1.11.3

# Show current version
tfenv version-name

# List installed versions
tfenv list

# Uninstall a version
tfenv uninstall 1.9.0
```

---

## The `.terraform-version` File

This repo includes a `.terraform-version` file at the root:

```
1.11.3
```

**This file:**
- Is committed to git (team-wide version consistency)
- Is read by tfenv automatically when you enter the directory
- Should match `TF_VERSION` in `.env.example` and `required_version` in `versions.tf`
- Supports special values:
  - `latest` — Always use latest stable
  - `latest:^1.9` — Latest matching constraint
  - `min-required` — Use minimum from `required_version`

---

## Version Pinning Strategy

| File | Purpose | Who reads it |
|------|---------|--------------|
| `.terraform-version` | Developer workstation version | tfenv |
| `versions.tf` → `required_version` | Minimum compatible version | terraform CLI |
| `.env` → `TF_VERSION` | Makefile override | Makefile |
| CI workflow → `TF_VERSION` env | CI pinned version | GitHub Actions |

### Keeping them in sync

When upgrading Terraform:

1. Update `.terraform-version` → `1.12.0`
2. Update `versions.tf` → `required_version = ">= 1.12.0"`
3. Update `.env.example` → `TF_VERSION=1.12.0`
4. Update `.github/workflows/ci.yml` → `TF_VERSION: "1.12.0"`
5. Run `make dev-setup` to install new version
6. Run `make all` to validate everything passes
7. Commit all files together

---

## tfenv vs. Direct Install

| Aspect | tfenv | Direct binary |
|--------|-------|---------------|
| Multiple versions | ✅ Switch instantly | ❌ Manual swap |
| Team consistency | ✅ `.terraform-version` | ❌ Hope everyone matches |
| Upgrade path | `tfenv install X` | Download + replace |
| CI usage | Optional (CI uses setup-terraform action) | ✅ Direct download |
| Auto-switch on cd | ✅ Built-in | ❌ Not possible |

---

## Troubleshooting

### "tfenv: command not found"

```bash
# Check if installed
ls ~/.tfenv/bin/tfenv

# Add to PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$HOME/.tfenv/bin:$PATH"

# Or create symlinks
sudo ln -sf ~/.tfenv/bin/* /usr/local/bin/
```

### "Version X not installed"

```bash
tfenv install    # Installs version from .terraform-version
```

### Conflict with Homebrew terraform

```bash
# Unlink the homebrew version
brew unlink terraform

# tfenv takes over
tfenv use 1.11.3
```

---

## Further Reading

- [tfenv GitHub](https://github.com/tfutils/tfenv)
- [Terraform version constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints)
