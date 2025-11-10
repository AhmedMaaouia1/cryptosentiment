# Quick Start - Terraform Security Checks

## For Windows Users (PowerShell)

### Run all checks before committing
```powershell
cd infrastructure\terraform
.\Makefile.ps1 check
```

### Individual commands
```powershell
# Format code
.\Makefile.ps1 fmt

# Validate configuration
.\Makefile.ps1 validate

# Run security scan
.\Makefile.ps1 security

# Clean cache
.\Makefile.ps1 clean
```

## For Git Bash / WSL Users

### Run all checks before committing
```bash
cd infrastructure/terraform
make check
```

### Individual commands
```bash
# Format code
make fmt

# Validate configuration
make validate

# Run security scan
make security

# Clean cache
make clean
```

## Required Tools

### Mandatory (already installed)
- Terraform 1.8.0+

### Optional (for local checks)
- tfsec: https://github.com/aquasecurity/tfsec/releases
- checkov: `pip install checkov`
- pre-commit: `pip install pre-commit`

## CI/CD

All checks run automatically on:
- Pull requests
- Push to main or feat/terraform-modularisation
- Manual workflow dispatch

Check results in:
- GitHub Actions tab
- Security tab (SARIF reports)
- PR comments (automatic)

## Documentation

See `docs/TERRAFORM_SECURITY.md` for detailed information.
