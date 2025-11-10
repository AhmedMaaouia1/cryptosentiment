# Pre-push Checklist

Run this before pushing your Terraform changes:

## Windows (PowerShell)

```powershell
# Quick test
.\test-terraform.ps1

# Or manual checks
cd infrastructure\terraform
.\Makefile.ps1 fmt       # Auto-fix formatting
.\Makefile.ps1 validate  # Check syntax
.\Makefile.ps1 security  # Scan security issues
```

## Git Bash / WSL / Linux

```bash
# Quick test from root
cd infrastructure/terraform
make check

# Or individual commands
make fmt       # Auto-fix formatting
make validate  # Check syntax
make security  # Scan security issues
```

## What gets checked?

1. Terraform format (auto-fixable)
2. Terraform validation (syntax errors)
3. Security issues (tfsec scan)

## What happens in CI/CD?

Same checks run automatically on:
- Every Pull Request
- Every push to main
- Every push to feat/* branches

## If checks fail locally:

### Format issues
```powershell
terraform fmt -recursive
```

### Validation issues
Check Terraform syntax and module references

### Security issues
Review tfsec output and fix before committing

## Installing tools (optional)

### Windows
- tfsec: Download from https://github.com/aquasecurity/tfsec/releases
- checkov: `pip install checkov`
- pre-commit: `pip install pre-commit && pre-commit install`

### Linux/macOS
```bash
brew install tfsec
pip install checkov pre-commit
pre-commit install
```

## Questions?

See:
- `docs/TERRAFORM_SECURITY.md` - Full documentation
- `infrastructure/terraform/SECURITY_CHECKS.md` - Quick reference
- `.github/workflows/terraform-validation.yml` - CI/CD workflow
