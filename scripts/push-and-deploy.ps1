# ============================================================================
# push-and-deploy.ps1 - Push to GitHub + Auto-Deploy Locally
# ============================================================================
# Combines git push + docker compose rebuild in one command.
# GitHub Actions CI runs in parallel on the cloud while your local
# containers are rebuilt with the latest code.
#
# Usage:
#   .\scripts\push-and-deploy.ps1
#   .\scripts\push-and-deploy.ps1 -Message "your commit message"
# ============================================================================

param(
    [string]$Message = ""
)

$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$COMPOSE_FILE = Join-Path $PROJECT_ROOT "docker-compose.yml"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  PUSH + DEPLOY PIPELINE" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# -- Step 1: Check for uncommitted changes --
$status = git -C $PROJECT_ROOT status --porcelain 2>$null
if ($status) {
    if (-not $Message) {
        $Message = "update: auto-deploy $(Get-Date -Format 'HH:mm:ss')"
    }
    Write-Host "  [1/4]  Staging and committing changes..." -ForegroundColor White
    git -C $PROJECT_ROOT add .
    git -C $PROJECT_ROOT commit -m $Message
    Write-Host "  [OK]   Committed: $Message" -ForegroundColor Green
} else {
    Write-Host "  [1/4]  No new changes to commit (pushing existing commits)" -ForegroundColor DarkGray
}

# -- Step 2: Push to GitHub --
Write-Host "  [2/4]  Pushing to GitHub..." -ForegroundColor White

$ErrorActionPreference = "Continue"
git -C $PROJECT_ROOT push origin main 2>&1 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Push failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK]   Pushed to GitHub (CI pipeline triggered)" -ForegroundColor Green

# -- Step 3: Rebuild and redeploy locally --
Write-Host "  [3/4]  Rebuilding and deploying locally..." -ForegroundColor White

docker compose -f $COMPOSE_FILE up -d --build 2>&1 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Deploy failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK]   Containers rebuilt and restarted" -ForegroundColor Green

# -- Step 4: Health check --
Write-Host "  [4/4]  Waiting for health check (8s)..." -ForegroundColor White
Start-Sleep -Seconds 8

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  [OK]   App is healthy: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Health check pending (app may still be starting)" -ForegroundColor DarkYellow
}

$ErrorActionPreference = "Stop"

# -- Done --
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  DONE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "  GitHub Actions: https://github.com/ankitbelbase17/Simple_Realstate_Buyerportal/actions" -ForegroundColor DarkGray
Write-Host "  Local App:      http://localhost:5000" -ForegroundColor White
Write-Host "  Grafana:        http://localhost:3001" -ForegroundColor White
Write-Host ""
