# Terraform Commands & Flags Reference

A practical reference for the terraform CLI flags used in this template's Makefile and CI pipelines.

---

## `terraform init`

Initializes the working directory — downloads providers, modules, and configures backends.

| Flag | Default | Description |
|------|---------|-------------|
| `-backend=false` | `true` | Skip backend configuration (used for local validation/testing) |
| `-input=false` | `true` | Disable interactive prompts (required for CI) |
| `-upgrade` | off | Force download of latest provider/module versions within constraints |
| `-reconfigure` | off | Reconfigure backend, ignoring any saved configuration |
| `-migrate-state` | off | Migrate state to a new backend configuration |

### When to use `-upgrade`

```bash
# Provider version bumped in versions.tf — need to pull new version
terraform init -upgrade

# Or via Makefile
TF_UPGRADE=true make init
make init-upgrade
```

**Use when:**
- You've updated version constraints in `versions.tf`
- A provider released a bugfix you need
- Dependabot opened a PR bumping providers

**Don't use when:**
- Running in CI (lock file should pin versions — use `terraform init` without upgrade)
- You want reproducible builds (the lock file `.terraform.lock.hcl` ensures this)

---

## `terraform plan` / `terraform apply`

### The `-refresh` Flag

| Flag | Default | Description |
|------|---------|-------------|
| `-refresh=true` | `true` | Query cloud APIs to detect drift before planning |
| `-refresh=false` | — | Skip refresh, use cached state only |
| `-refresh-only` | — | Only refresh state, don't propose changes |

### How Refresh Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      terraform plan                               │
│                                                                   │
│  1. Read .tfstate ─────── What Terraform thinks exists           │
│  2. Refresh (API calls) ─ What actually exists (drift detection) │
│  3. Compare with .tf ──── What you declared                      │
│  4. Generate plan ─────── Actions to reconcile                   │
└─────────────────────────────────────────────────────────────────┘
```

With `-refresh=false`:
```
┌─────────────────────────────────────────────────────────────────┐
│  1. Read .tfstate ─────── Trust state as-is (skip API calls)    │
│  2. Compare with .tf ──── What you declared                      │
│  3. Generate plan ─────── Actions to reconcile                   │
└─────────────────────────────────────────────────────────────────┘
```

### When to use `-refresh=false`

```bash
# Fast plan in CI when state was just applied
terraform plan -refresh=false

# Via Makefile
TF_REFRESH=false make example-plan
```

**Use when:**
- CI pipeline where state was just written (e.g., apply then plan for drift check)
- Large infrastructure where refresh takes minutes
- You only care about code changes, not drift

**Don't use when:**
- You suspect drift (someone changed resources manually)
- Running `terraform apply` in production (always refresh in prod)
- First plan after importing resources

### When to use `-refresh-only`

```bash
# Detect drift without proposing any changes
terraform plan -refresh-only

# Apply just the refresh (update state to match reality)
terraform apply -refresh-only
```

**Use when:**
- Investigating drift without making changes
- Syncing state after manual changes were intentionally made
- Baseline check before a big refactor

---

## Flag Combinations in This Template

### Via `.env` file

```bash
# .env (git-ignored, local overrides)
TF_UPGRADE=false    # default: don't upgrade on every init
TF_REFRESH=true     # default: always refresh
```

### Via command line

```bash
# Normal workflow
make init                              # init (no upgrade)
make example-plan                      # plan (with refresh)
make example-apply                     # apply (with refresh)

# Fast CI mode
TF_REFRESH=false make example-plan     # skip refresh

# Update providers
make init-upgrade                      # explicit upgrade
TF_UPGRADE=true make init              # upgrade via flag

# Combined
TF_UPGRADE=true TF_REFRESH=false make example-plan
```

### How Makefile computes flags

```makefile
# TF_INIT_FLAGS is used by: make init, make example-init
TF_INIT_FLAGS := -backend=false -input=false
ifeq ($(TF_UPGRADE),true)
  TF_INIT_FLAGS += -upgrade              # → -backend=false -input=false -upgrade
endif

# TF_CMD_FLAGS is used by: make example-plan, make example-apply
TF_CMD_FLAGS :=
ifeq ($(TF_REFRESH),false)
  TF_CMD_FLAGS += -refresh=false         # → -refresh=false
endif
```

---

## Other Useful Flags

### `terraform plan`

| Flag | Description |
|------|-------------|
| `-out=plan.tfplan` | Save plan to file for exact apply |
| `-target=resource.name` | Plan only specific resources (use sparingly) |
| `-destroy` | Plan a destroy operation |
| `-parallelism=N` | Limit concurrent operations (default 10) |
| `-compact-warnings` | Show warnings in compact form |

### `terraform apply`

| Flag | Description |
|------|-------------|
| `-auto-approve` | Skip interactive confirmation (CI only!) |
| `-parallelism=N` | Limit concurrent operations |
| `plan.tfplan` | Apply a saved plan file (recommended for prod) |

### `terraform validate`

| Flag | Description |
|------|-------------|
| `-no-color` | Disable colour output (CI log readability) |
| `-json` | Output in JSON format (machine parsing) |

---

## Best Practices

1. **Lock your providers** — Commit `.terraform.lock.hcl` so everyone gets identical versions
2. **Use `-upgrade` intentionally** — Don't auto-upgrade; review changes in lock file
3. **Refresh in production** — Always use `-refresh=true` for prod apply
4. **Skip refresh in CI validation** — Format/validate/lint don't need cloud access
5. **Save plans for apply** — Use `terraform plan -out=plan.tfplan` then `terraform apply plan.tfplan`
6. **Never `-auto-approve` locally** — Only in CI after plan review

---

## Further Reading

- [Terraform CLI docs — init](https://developer.hashicorp.com/terraform/cli/commands/init)
- [Terraform CLI docs — plan](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [Terraform CLI docs — apply](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [tfenv — Terraform version manager](https://github.com/tfutils/tfenv)
