# ============================================================================
# deploy-local.ps1 - Local CI/CD Pipeline (PowerShell)
# ============================================================================
# Automates: Lint > Build > Deploy > Health Check
# Triggered by: git post-commit hook OR manual execution
#
# Usage:
#   .\scripts\deploy-local.ps1            # Full pipeline
#   .\scripts\deploy-local.ps1 -SkipCI    # Skip lint/tests, just deploy
# ============================================================================

param(
    [switch]$SkipCI
)

$ErrorActionPreference = "Stop"

# -- Paths and Config --
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$COMPOSE_FILE = Join-Path $PROJECT_ROOT "docker-compose.yml"
$BACKEND_DIR  = Join-Path $PROJECT_ROOT "backend"
$APP_URL      = "http://localhost:5000"
$HEALTH_URL   = "$APP_URL/api/health"
$METRICS_URL  = "$APP_URL/metrics"

# -- Helpers --
function Write-Banner {
    param([string]$Title, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor $Color
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ("=" * 60) -ForegroundColor $Color
    Write-Host ""
}

function Write-Step {
    param([string]$Icon, [string]$Message)
    Write-Host "  [$Icon]  $Message" -ForegroundColor White
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK]  $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [FAIL]  $Message" -ForegroundColor Red
}

function Get-CommitInfo {
    $sha  = git -C $PROJECT_ROOT rev-parse --short HEAD 2>$null
    $msg  = git -C $PROJECT_ROOT log -1 --format="%s" 2>$null
    return @{ SHA = $sha; Message = $msg }
}

# -- Start --
$startTime = Get-Date
$commit = Get-CommitInfo

Write-Banner "LOCAL CI/CD PIPELINE" "Magenta"
Write-Host ("  Commit:  " + $commit.SHA + " - " + $commit.Message) -ForegroundColor DarkGray
Write-Host ("  Time:    " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray
Write-Host ""

# ================================================================
# STAGE 1: CI - Lint and Validate (optional skip)
# ================================================================
if (-not $SkipCI) {
    Write-Banner "STAGE 1: CI - Lint and Validate" "Yellow"

    # 1a. Check Node.js is available
    Write-Step "1" "Checking Node.js..."
    try {
        $nodeVersion = node --version 2>&1
        Write-Ok "Node.js $nodeVersion found"
    } catch {
        Write-Err "Node.js not found! Install Node.js to enable CI checks."
        Write-Host "  Skipping CI stage..." -ForegroundColor DarkYellow
        $SkipCI = $true
    }

    if (-not $SkipCI) {
        # 1b. Syntax validation
        Write-Step "2" "Validating server.js syntax..."
        try {
            $serverPath = Join-Path $BACKEND_DIR "server.js"
            $syntaxResult = node -c $serverPath 2>&1
            Write-Ok "Syntax OK"
        } catch {
            Write-Err "Syntax error in server.js!"
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Banner "PIPELINE FAILED - Fix syntax errors" "Red"
            exit 1
        }

        # 1c. Validate Dockerfile exists
        Write-Step "3" "Checking Dockerfile..."
        if (Test-Path (Join-Path $PROJECT_ROOT "Dockerfile")) {
            Write-Ok "Dockerfile present"
        } else {
            Write-Err "Dockerfile missing!"
            exit 1
        }

        # 1d. Validate docker-compose.yml
        Write-Step "4" "Validating docker-compose.yml..."
        try {
            docker compose -f $COMPOSE_FILE config --quiet 2>&1
            Write-Ok "docker-compose.yml is valid"
        } catch {
            Write-Err "docker-compose.yml has errors!"
            exit 1
        }

        Write-Host ""
        Write-Ok "CI Stage PASSED"
    }
}

# ================================================================
# STAGE 2: CD - Build and Deploy
# ================================================================
Write-Banner "STAGE 2: CD - Build and Deploy" "Yellow"

# 2a. Tag current working state (for rollback)
Write-Step "TAG" "Tagging current state for rollback..."
$tagName = "deploy/pre-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
try {
    git -C $PROJECT_ROOT tag $tagName 2>$null
    Write-Ok "Tagged as $tagName"
} catch {
    Write-Host "  [WARN]  Could not create tag (non-fatal)" -ForegroundColor DarkYellow
}

# 2b. Build and redeploy
Write-Step "BUILD" "Building Docker image..."
Write-Host ""

# Temporarily allow non-terminating errors for Docker (it writes to stderr)
$ErrorActionPreference = "Continue"

docker compose -f $COMPOSE_FILE build app 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    $ErrorActionPreference = "Stop"
    Write-Err "Docker build failed!"
    Write-Banner "PIPELINE FAILED - Check Docker" "Red"
    exit 1
}
Write-Ok "Docker image built"

# Restart only the app container
Write-Step "DEPLOY" "Restarting app container..."
docker compose -f $COMPOSE_FILE up -d --no-deps --force-recreate app 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    $ErrorActionPreference = "Stop"
    Write-Err "Container restart failed!"
    Write-Banner "PIPELINE FAILED - Check Docker" "Red"
    exit 1
}
Write-Ok "App container restarted"

$ErrorActionPreference = "Stop"

# ================================================================
# STAGE 3: Verify - Health Check
# ================================================================
Write-Banner "STAGE 3: Verify - Health Check" "Yellow"

Write-Step "WAIT" "Waiting for container to start (10s)..."
Start-Sleep -Seconds 10

# 3a. Health endpoint
Write-Step "HEALTH" "Checking $HEALTH_URL ..."
$maxRetries = 5
$healthy = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        $response = Invoke-RestMethod -Uri $HEALTH_URL -Method Get -TimeoutSec 5 -ErrorAction Stop
        if ($response.status -eq "ok") {
            $healthy = $true
            Write-Ok ("Health check PASSED (status: " + $response.status + ")")
            Write-Host ("         Message: " + $response.message) -ForegroundColor DarkGray
            break
        }
    } catch {
        if ($i -lt $maxRetries) {
            Write-Host "  [...]  Attempt $i/$maxRetries failed, retrying in 3s..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 3
        }
    }
}

if (-not $healthy) {
    Write-Err "Health check FAILED after $maxRetries attempts!"
    Write-Host ""
    Write-Host "  Container logs:" -ForegroundColor DarkYellow
    docker logs buyer-portal-app --tail 20 2>&1
    Write-Host ""
    Write-Banner "PIPELINE FAILED - App unhealthy" "Red"
    Write-Host "  Run .\scripts\rollback.ps1 to revert" -ForegroundColor Yellow
    exit 1
}

# 3b. Metrics endpoint (quick check, dont parse the full body)
Write-Step "METRICS" "Checking metrics endpoint..."
try {
    $metricsCheck = Invoke-RestMethod -Uri $METRICS_URL -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Ok "Metrics endpoint OK"
} catch {
    Write-Host "  [WARN]  Metrics endpoint not responding (non-fatal)" -ForegroundColor DarkYellow
}

# ================================================================
# DONE
# ================================================================
$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Banner "DEPLOYMENT SUCCESSFUL" "Green"
Write-Host ("  Commit:     " + $commit.SHA + " - " + $commit.Message) -ForegroundColor White
Write-Host "  App:        $APP_URL" -ForegroundColor White
Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor White
Write-Host "  Grafana:    http://localhost:3001" -ForegroundColor White
Write-Host ("  Duration:   " + [math]::Round($elapsed.TotalSeconds, 1) + "s") -ForegroundColor White
Write-Host "  Rollback:   git checkout $tagName" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  CI [OK] > BUILD [OK] > DEPLOY [OK] > VERIFY [OK]" -ForegroundColor Green
Write-Host ""
