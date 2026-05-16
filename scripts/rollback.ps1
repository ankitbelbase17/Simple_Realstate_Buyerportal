# ============================================================================
# rollback.ps1 — Rollback to Last Known Working Deployment
# ============================================================================
# Reverts to the most recent deploy/pre-* tag and redeploys
#
# Usage:
#   .\scripts\rollback.ps1              # Auto-rollback to latest tag
#   .\scripts\rollback.ps1 -Tag "deploy/pre-20260516-140000"  # Specific tag
# ============================================================================

param(
    [string]$Tag = ""
)

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$COMPOSE_FILE = Join-Path $PROJECT_ROOT "docker-compose.yml"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Red
Write-Host "  ROLLBACK — Reverting to Previous Working Version" -ForegroundColor Red
Write-Host ("=" * 60) -ForegroundColor Red
Write-Host ""

# Find latest deploy tag if not specified
if (-not $Tag) {
    $tags = git -C $PROJECT_ROOT tag -l "deploy/pre-*" --sort=-creatordate 2>$null
    if (-not $tags) {
        Write-Host "  ❌  No rollback tags found!" -ForegroundColor Red
        Write-Host "      No previous deployments to roll back to." -ForegroundColor DarkGray
        exit 1
    }
    # Get the most recent tag
    $Tag = ($tags -split "`n")[0].Trim()
}

Write-Host "  🏷️  Rolling back to: $Tag" -ForegroundColor Yellow

# Get current HEAD for reference
$currentSHA = git -C $PROJECT_ROOT rev-parse --short HEAD 2>$null
Write-Host "  📌  Current HEAD:    $currentSHA" -ForegroundColor DarkGray

# Checkout the tag
try {
    git -C $PROJECT_ROOT checkout $Tag 2>&1 | Out-Null
    Write-Host "  ✅  Checked out $Tag" -ForegroundColor Green
} catch {
    Write-Host "  ❌  Failed to checkout tag!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Rebuild and redeploy
Write-Host ""
Write-Host "  🔨  Rebuilding from rolled-back code..." -ForegroundColor White
docker compose -f $COMPOSE_FILE build app 2>&1 | Out-Null
docker compose -f $COMPOSE_FILE up -d --no-deps --force-recreate app 2>&1 | Out-Null

# Wait and health check
Write-Host "  ⏳  Waiting for container to start (10s)..." -ForegroundColor White
Start-Sleep -Seconds 10

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅  Health check PASSED — App is running" -ForegroundColor Green
} catch {
    Write-Host "  ❌  Health check FAILED even after rollback!" -ForegroundColor Red
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  ROLLBACK COMPLETE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "  To return to main branch:" -ForegroundColor DarkGray
Write-Host "    git checkout main" -ForegroundColor DarkGray
Write-Host ""
