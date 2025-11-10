# Local Testing Script for Windows
# Run this before pushing to GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Terraform Local Checks" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0

# Navigate to terraform directory
Set-Location -Path "$PSScriptRoot\infrastructure\terraform"

# 1. Format Check
Write-Host "[1/3] Checking Terraform format..." -ForegroundColor Yellow
$formatOutput = terraform fmt -check -recursive 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED - Code formatting issues found" -ForegroundColor Red
    Write-Host "Run: terraform fmt -recursive" -ForegroundColor Yellow
    $ErrorCount++
} else {
    Write-Host "PASSED" -ForegroundColor Green
}
Write-Host ""

# 2. Validation
Write-Host "[2/3] Validating Terraform configuration..." -ForegroundColor Yellow
terraform init -backend=false | Out-Null
$validateOutput = terraform validate 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED - Validation errors found" -ForegroundColor Red
    Write-Host $validateOutput
    $ErrorCount++
} else {
    Write-Host "PASSED" -ForegroundColor Green
}
Write-Host ""

# 3. Security Scan (if tfsec is installed)
Write-Host "[3/3] Running security scan..." -ForegroundColor Yellow
if (Get-Command tfsec -ErrorAction SilentlyContinue) {
    # Use config file if exists, otherwise use command line args
    if (Test-Path ".tfsec.yml") {
        $tfsecOutput = tfsec . --config-file .tfsec.yml 2>&1
    } else {
        $tfsecOutput = tfsec . --minimum-severity HIGH 2>&1
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED - Security issues found" -ForegroundColor Red
        Write-Host $tfsecOutput
        $ErrorCount++
    } else {
        Write-Host "PASSED" -ForegroundColor Green
    }
} else {
    Write-Host "SKIPPED - tfsec not installed" -ForegroundColor Yellow
    Write-Host "Install from: https://github.com/aquasecurity/tfsec/releases" -ForegroundColor Cyan
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "You can safely push your changes" -ForegroundColor Green
} else {
    Write-Host "CHECKS FAILED: $ErrorCount error(s)" -ForegroundColor Red
    Write-Host "Please fix the errors before pushing" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan

# Return to root directory
Set-Location -Path $PSScriptRoot

exit $ErrorCount
