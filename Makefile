# Makefile for Terraform operations# PowerShell Makefile for Windows

# Usage: make <target>

# For Windows: Use Git Bash, WSL, or use Makefile.ps1 in PowerShellparam(

    [Parameter(Position=0)]

.PHONY: help fmt validate security checkov check test plan apply destroy clean    [ValidateSet('fmt', 'validate', 'security', 'check', 'clean', 'help')]

    [string]$Command = 'help'

TERRAFORM_DIR := infrastructure/terraform)



help:function Show-Help {

	@echo "Available targets:"    Write-Host ""

	@echo "  fmt       - Format Terraform files"    Write-Host "Terraform Makefile - Available commands:" -ForegroundColor Cyan

	@echo "  validate  - Validate Terraform configuration"    Write-Host ""

	@echo "  security  - Run tfsec security scan"    Write-Host "  fmt       " -ForegroundColor Green -NoNewline

	@echo "  checkov   - Run Checkov policy scan"    Write-Host "Format Terraform files"

	@echo "  check     - Run all checks (fmt, validate, security)"    Write-Host "  validate  " -ForegroundColor Green -NoNewline

	@echo "  test      - Run terraform plan"    Write-Host "Validate Terraform configuration"

	@echo "  plan      - Run terraform plan with dev variables"    Write-Host "  security  " -ForegroundColor Green -NoNewline

	@echo "  apply     - Apply Terraform configuration (dev)"    Write-Host "Run security checks (tfsec)"

	@echo "  destroy   - Destroy Terraform resources (dev)"    Write-Host "  check     " -ForegroundColor Green -NoNewline

	@echo "  clean     - Clean Terraform cache files"    Write-Host "Run all checks (fmt + validate + security)"

    Write-Host "  clean     " -ForegroundColor Green -NoNewline

fmt:    Write-Host "Clean Terraform files"

	@echo "Formatting Terraform files..."    Write-Host "  help      " -ForegroundColor Green -NoNewline

	@cd $(TERRAFORM_DIR) && terraform fmt -recursive    Write-Host "Show this help message"

	@echo "Formatting complete"    Write-Host ""

}

validate:

	@echo "Validating Terraform configuration..."function Invoke-Format {

	@cd $(TERRAFORM_DIR) && terraform init -backend=false && terraform validate    Write-Host "Formatting Terraform files..." -ForegroundColor Yellow

	@echo "Validation complete"    terraform fmt -recursive

    if ($LASTEXITCODE -eq 0) {

security:        Write-Host "Formatting complete" -ForegroundColor Green

	@echo "Running tfsec security scan..."    } else {

	@cd $(TERRAFORM_DIR) && if [ -f .tfsec.yml ]; then \        Write-Host "Formatting failed" -ForegroundColor Red

		tfsec . --config-file .tfsec.yml; \        exit 1

	else \    }

		tfsec . --minimum-severity HIGH; \}

	fi

	@echo "Security scan complete"function Invoke-Validate {

    Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow

checkov:    terraform init -backend=false | Out-Null

	@echo "Running Checkov policy scan..."    terraform validate

	@checkov -d $(TERRAFORM_DIR) --framework terraform    if ($LASTEXITCODE -eq 0) {

	@echo "Checkov scan complete"        Write-Host "Validation complete" -ForegroundColor Green

    } else {

check: fmt validate security        Write-Host "Validation failed" -ForegroundColor Red

	@echo "All checks passed"        exit 1

    }

test:}

	@echo "Running Terraform plan (dry-run)..."

	@cd $(TERRAFORM_DIR) && terraform plan -var-file=terraform.tfvarsfunction Invoke-Security {

	@echo "Plan complete"    Write-Host "Running tfsec security scan..." -ForegroundColor Yellow

    if (Get-Command tfsec -ErrorAction SilentlyContinue) {

plan:        if (Test-Path ".tfsec.yml") {

	@echo "Running Terraform plan..."            tfsec . --config-file .tfsec.yml

	@cd $(TERRAFORM_DIR) && terraform plan -var-file=terraform.tfvars        } else {

	@echo "Plan complete"            tfsec . --minimum-severity HIGH

        }

apply:        if ($LASTEXITCODE -eq 0) {

	@echo "Applying Terraform configuration..."            Write-Host "Security scan complete" -ForegroundColor Green

	@cd $(TERRAFORM_DIR) && terraform apply -var-file=terraform.tfvars        } else {

	@echo "Apply complete"            Write-Host "Security scan failed" -ForegroundColor Red

            exit 1

destroy:        }

	@echo "WARNING: This will destroy all resources!"    } else {

	@read -p "Are you sure? [y/N] " -n 1 -r; \        Write-Host "tfsec not installed - skipping security scan" -ForegroundColor Yellow

	echo; \        Write-Host "Install from: https://github.com/aquasecurity/tfsec/releases" -ForegroundColor Cyan

	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \    }

		cd $(TERRAFORM_DIR) && terraform destroy -var-file=terraform.tfvars; \}

	fi

function Invoke-Check {

clean:    Write-Host "Running all checks..." -ForegroundColor Cyan

	@echo "Cleaning Terraform files..."    Write-Host ""

	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true    Invoke-Format

	@find . -type f -name "*.tfstate*" -delete 2>/dev/null || true    Write-Host ""

	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true    Invoke-Validate

	@echo "Cleanup complete"    Write-Host ""

    Invoke-Security
    Write-Host ""
    Write-Host "All checks passed!" -ForegroundColor Green
}

function Invoke-Clean {
    Write-Host "Cleaning Terraform files..." -ForegroundColor Yellow
    Get-ChildItem -Path . -Directory -Filter ".terraform" -Recurse | Remove-Item -Recurse -Force
    Get-ChildItem -Path . -File -Filter "*.tfstate*" -Recurse | Remove-Item -Force
    Get-ChildItem -Path . -File -Filter ".terraform.lock.hcl" -Recurse | Remove-Item -Force
    Write-Host "Cleanup complete" -ForegroundColor Green
}

switch ($Command) {
    'fmt'      { Invoke-Format }
    'validate' { Invoke-Validate }
    'security' { Invoke-Security }
    'check'    { Invoke-Check }
    'clean'    { Invoke-Clean }
    'help'     { Show-Help }
}
