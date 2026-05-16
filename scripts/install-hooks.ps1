# ============================================================================
# install-hooks.ps1 - Install Git Hooks for Local CI/CD
# ============================================================================
# Run this once to set up automatic deployment on every commit.
#
# Usage:
#   .\scripts\install-hooks.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$HOOKS_DIR = Join-Path (Join-Path $PROJECT_ROOT ".git") "hooks"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  Installing Local CI/CD Git Hooks" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# -- Post-commit hook ---
$hookFile = Join-Path $HOOKS_DIR "post-commit"

# Build hook content line by line to avoid here-string issues
$lines = @()
$lines += '#!/bin/bash'
$lines += '# post-commit hook - Automatic Local CI/CD Pipeline'
$lines += '# To disable temporarily: git commit --no-verify'
$lines += '# To remove permanently:  delete .git/hooks/post-commit'
$lines += ''
$lines += 'echo ""'
$lines += 'echo "======================================================="'
$lines += 'echo "  Local CI/CD Pipeline Triggered (post-commit)"'
$lines += 'echo "======================================================="'
$lines += 'echo ""'
$lines += ''
$lines += '# Get project root (parent of .git/hooks/)'
$lines += 'HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"'
$lines += 'PROJECT_ROOT="$(dirname "$(dirname "$HOOK_DIR")")"'
$lines += ''
$lines += '# Check if deploy script exists'
$lines += 'DEPLOY_SCRIPT="$PROJECT_ROOT/scripts/deploy-local.sh"'
$lines += 'if [ -f "$DEPLOY_SCRIPT" ]; then'
$lines += '    bash "$DEPLOY_SCRIPT"'
$lines += 'else'
$lines += '    echo "  Bash script not found, trying PowerShell..."'
$lines += '    powershell.exe -ExecutionPolicy Bypass -File "$PROJECT_ROOT/scripts/deploy-local.ps1"'
$lines += 'fi'
$lines += ''
$lines += 'EXIT_CODE=$?'
$lines += 'if [ $EXIT_CODE -ne 0 ]; then'
$lines += '    echo ""'
$lines += '    echo "  Deployment failed (exit code: $EXIT_CODE)"'
$lines += '    echo "  Your commit is safe. Fix the issue and commit again."'
$lines += '    echo ""'
$lines += 'fi'
$lines += ''
$lines += 'exit 0  # Never block the commit'

$hookContent = $lines -join "`n"

# Write the hook file with Unix line endings (LF)
[System.IO.File]::WriteAllText($hookFile, $hookContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "  post-commit hook installed" -ForegroundColor Green
Write-Host ("  Path: " + $hookFile) -ForegroundColor DarkGray
Write-Host ""

# -- Verify ---
Write-Host "  Verification:" -ForegroundColor White
Write-Host ("  Hook file exists: " + (Test-Path $hookFile)) -ForegroundColor DarkGray
Write-Host ""

Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  SETUP COMPLETE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "  How it works:" -ForegroundColor White
Write-Host "    1. You make code changes" -ForegroundColor DarkGray
Write-Host "    2. You commit (git commit)" -ForegroundColor DarkGray
Write-Host "    3. The post-commit hook AUTOMATICALLY:" -ForegroundColor DarkGray
Write-Host "       - Lints your code" -ForegroundColor DarkGray
Write-Host "       - Rebuilds the Docker image" -ForegroundColor DarkGray
Write-Host "       - Redeploys the app container" -ForegroundColor DarkGray
Write-Host "       - Verifies health check" -ForegroundColor DarkGray
Write-Host "    4. Changes visible at http://localhost:5000" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  To skip deployment on a commit:" -ForegroundColor Yellow
Write-Host "    git commit --no-verify -m 'message'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  To uninstall:" -ForegroundColor Yellow
Write-Host ("    Delete: " + $hookFile) -ForegroundColor DarkGray
Write-Host ""
