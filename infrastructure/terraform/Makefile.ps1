# PowerShell Makefile alternative for Windows
# Usage: .\Makefile.ps1 <target>

param(
    [Parameter(Mandatory=$false)]
    [string]$Target = "help"
)

function Show-Help {
    Write-Host "Available targets:" -ForegroundColor Green
    Write-Host "  fmt       - Format Terraform files"
    Write-Host "  validate  - Validate Terraform configuration"
    Write-Host "  security  - Run tfsec security scan"
    Write-Host "  checkov   - Run Checkov policy scan"
    Write-Host "  check     - Run all checks (fmt, validate, security)"
    Write-Host "  test      - Run terraform plan"
    Write-Host "  plan      - Run terraform plan with variables"
    Write-Host "  apply     - Apply Terraform configuration"
    Write-Host "  destroy   - Destroy Terraform resources"
    Write-Host "  clean     - Clean Terraform cache files"
}

function Invoke-Format {
    Write-Host "Formatting Terraform files..." -ForegroundColor Yellow
    terraform fmt -recursive
    Write-Host "Formatting complete" -ForegroundColor Green
}

function Invoke-Validate {
    Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
    terraform init -backend=false
    terraform validate
    Write-Host "Validation complete" -ForegroundColor Green
}

function Invoke-Security {
    Write-Host "Running tfsec security scan..." -ForegroundColor Yellow
    if (Get-Command tfsec -ErrorAction SilentlyContinue) {
        if (Test-Path ".tfsec.yml") {
            tfsec . --config-file .tfsec.yml
        } else {
            tfsec . --minimum-severity HIGH
        }
        Write-Host "Security scan complete" -ForegroundColor Green
    } else {
        Write-Host "tfsec not found. Install from: https://github.com/aquasecurity/tfsec/releases" -ForegroundColor Red
    }
}

function Invoke-Checkov {
    Write-Host "Running Checkov policy scan..." -ForegroundColor Yellow
    if (Get-Command checkov -ErrorAction SilentlyContinue) {
        checkov -d . --framework terraform
        Write-Host "Checkov scan complete" -ForegroundColor Green
    } else {
        Write-Host "Checkov not found. Install with: pip install checkov" -ForegroundColor Red
    }
}

function Invoke-Check {
    Invoke-Format
    Invoke-Validate
    Invoke-Security
    Write-Host "All checks passed" -ForegroundColor Green
}

function Invoke-Plan {
    Write-Host "Running Terraform plan..." -ForegroundColor Yellow
    terraform plan -var-file=terraform.tfvars
    Write-Host "Plan complete" -ForegroundColor Green
}

function Invoke-Apply {
    Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
    terraform apply -var-file=terraform.tfvars
    Write-Host "Apply complete" -ForegroundColor Green
}

function Invoke-Destroy {
    Write-Host "WARNING: This will destroy all resources!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure? [y/N]"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        terraform destroy -var-file=terraform.tfvars
    } else {
        Write-Host "Destroy cancelled" -ForegroundColor Yellow
    }
}

function Invoke-Clean {
    Write-Host "Cleaning Terraform files..." -ForegroundColor Yellow
    Get-ChildItem -Path . -Filter ".terraform" -Recurse -Directory | Remove-Item -Recurse -Force
    Get-ChildItem -Path . -Filter "*.tfstate*" -Recurse -File | Remove-Item -Force
    Get-ChildItem -Path . -Filter ".terraform.lock.hcl" -Recurse -File | Remove-Item -Force
    Write-Host "Cleanup complete" -ForegroundColor Green
}

# Execute target
switch ($Target.ToLower()) {
    "help"     { Show-Help }
    "fmt"      { Invoke-Format }
    "validate" { Invoke-Validate }
    "security" { Invoke-Security }
    "checkov"  { Invoke-Checkov }
    "check"    { Invoke-Check }
    "test"     { Invoke-Plan }
    "plan"     { Invoke-Plan }
    "apply"    { Invoke-Apply }
    "destroy"  { Invoke-Destroy }
    "clean"    { Invoke-Clean }
    default    {
        Write-Host "Unknown target: $Target" -ForegroundColor Red
        Show-Help
    }
}
