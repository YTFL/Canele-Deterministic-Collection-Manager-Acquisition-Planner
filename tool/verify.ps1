<#
.SYNOPSIS
    Canelé Quality & Validation Runner (PowerShell / Windows)
.DESCRIPTION
    Runs code formatting verification, static analysis, and automated tests.
    Exits with code 0 if all quality gates pass.
#>

$ErrorActionPreference = "Stop"

Write-Host "`n==> Starting Canelé Validation Suite..." -ForegroundColor Cyan

# 1. Dependency check
Write-Host "`n[1/4] Checking dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install dependencies." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Dart formatting
Write-Host "`n[2/4] Checking code formatting (dart format)..." -ForegroundColor Yellow
dart format --output=none --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Formatting check failed! Please run 'dart format .' to automatically format your code." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Formatting passed." -ForegroundColor Green

# 3. Static analysis
Write-Host "`n[3/4] Running static analysis (flutter analyze)..." -ForegroundColor Yellow
flutter analyze --fatal-infos --fatal-warnings
if ($LASTEXITCODE -ne 0) {
    Write-Host "Static analysis found errors or warnings. Please resolve them." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Static analysis passed." -ForegroundColor Green

# 4. Automated tests
Write-Host "`n[4/4] Running automated test suite (flutter test)..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "One or more tests failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "All tests passed successfully!" -ForegroundColor Green

Write-Host "`n[SUCCESS] All Canelé validation checks passed cleanly! Ready for PR submission.`n" -ForegroundColor Green
exit 0
