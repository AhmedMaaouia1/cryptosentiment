# Terraform Security & Quality Checks

## Overview

This document describes the security and quality checks implemented for the Terraform infrastructure code.

## Tools Used

### 1. terraform fmt
- **Purpose**: Automatic code formatting
- **Command**: `terraform fmt -recursive`
- **Blocking**: No (auto-fixable)
- **Runs**: Local and CI/CD

### 2. terraform validate
- **Purpose**: Syntax and configuration validation
- **Command**: `terraform validate`
- **Blocking**: Yes
- **Runs**: Local and CI/CD

### 3. tfsec
- **Purpose**: Security scanning (100+ AWS rules)
- **Command**: `tfsec . --minimum-severity MEDIUM`
- **Blocking**: Yes (if CRITICAL/HIGH/MEDIUM)
- **Runs**: Local and CI/CD
- **Documentation**: https://aquasecurity.github.io/tfsec/

### 4. checkov
- **Purpose**: Policy and compliance scanning
- **Command**: `checkov -d terraform`
- **Blocking**: No (warnings only)
- **Runs**: CI/CD only
- **Documentation**: https://www.checkov.io/

## Security Checks

### S3 Bucket
- Encryption enabled
- Public access blocked
- Versioning (optional)
- Lifecycle policies configured

### DynamoDB
- Point-in-time recovery (production)
- Encryption at rest
- Deletion protection (production)
- TTL configured

### IAM
- Least privilege policies
- No wildcard permissions
- Specific resource ARNs

### SNS
- Encryption in transit
- Restrictive access policies

## Local Workflow

### Windows (PowerShell)
```powershell
# Navigate to terraform directory
cd infrastructure\terraform

# Run all checks
.\Makefile.ps1 check

# Fix formatting
.\Makefile.ps1 fmt

# Run security scan
.\Makefile.ps1 security

# Run validation
.\Makefile.ps1 validate
```

### Linux/macOS or Git Bash
```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Run all checks
make check

# Fix formatting
make fmt

# Run security scan
make security

# Run validation
make validate
```

## CI/CD Workflow

```
Pull Request
  |
  v
GitHub Actions
  |- terraform fmt -check
  |- terraform validate
  |- tfsec scan
  |- checkov scan
  |
  v
Automatic PR comment
  |
  v
Merge (if all checks pass)
```

## Ignoring Checks

Use sparingly and only with justification:

```hcl
# tfsec:ignore:AWS001
resource "aws_s3_bucket" "example" {
  # Justification: Temporary bucket for testing
  bucket = "test-bucket"
}
```

## Configuration Files

- `.tfsec.yml` - tfsec configuration
- `.pre-commit-config.yaml` - Pre-commit hooks
- `Makefile` - Unix/Linux commands
- `Makefile.ps1` - Windows PowerShell commands

## Installing Tools Locally

### Windows
```powershell
# Install tfsec
choco install tfsec

# Or download from GitHub releases
# https://github.com/aquasecurity/tfsec/releases

# Install checkov
pip install checkov

# Install pre-commit
pip install pre-commit
pre-commit install
```

### Linux/macOS
```bash
# Install tfsec
brew install tfsec

# Install checkov
pip install checkov

# Install pre-commit
pip install pre-commit
pre-commit install
```

## Troubleshooting

### tfsec not found
Install tfsec from: https://github.com/aquasecurity/tfsec/releases

### checkov not found
Install with: `pip install checkov`

### Format check fails
Run: `terraform fmt -recursive` to auto-fix

### Validation fails
Check Terraform syntax and module references

### Security issues found
Review tfsec output and fix issues before committing

## Best Practices

1. Always run `make check` (or `.\Makefile.ps1 check`) before committing
2. Fix formatting issues immediately (auto-fixable)
3. Address security issues before pushing
4. Use pre-commit hooks to catch issues early
5. Review GitHub Security tab regularly
6. Keep Terraform and tools updated

## Resources

- [tfsec Rules](https://aquasecurity.github.io/tfsec/)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
