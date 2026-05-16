#!/bin/bash
# ============================================================================
# deploy-local.sh — Local CI/CD Pipeline (Bash / Git Bash / WSL)
# ============================================================================
# Automates: Lint → Build → Deploy → Health Check
# Triggered by: git post-commit hook OR manual execution
#
# Usage:
#   ./scripts/deploy-local.sh            # Full pipeline
#   ./scripts/deploy-local.sh --skip-ci  # Skip lint/tests, just deploy
# ============================================================================

set -e

SKIP_CI=false
if [ "$1" = "--skip-ci" ]; then
    SKIP_CI=true
fi

# ── Paths & Config ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
BACKEND_DIR="$PROJECT_ROOT/backend"
APP_URL="http://localhost:5000"
HEALTH_URL="$APP_URL/api/health"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
GRAY='\033[0;90m'

banner()  { echo -e "\n${2:-$CYAN}$(printf '=%.0s' {1..60})\n  $1\n$(printf '=%.0s' {1..60})${NC}\n"; }
step()    { echo -e "  $1  $2"; }
success() { echo -e "  ${GREEN}✅  $1${NC}"; }
fail()    { echo -e "  ${RED}❌  $1${NC}"; }

# ── Start ───────────────────────────────────────────────────────────────────
START_TIME=$(date +%s)
COMMIT_SHA=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
COMMIT_MSG=$(git -C "$PROJECT_ROOT" log -1 --format="%s" 2>/dev/null || echo "unknown")

banner "LOCAL CI/CD PIPELINE" "$MAGENTA"
echo -e "  ${GRAY}Commit:  $COMMIT_SHA — $COMMIT_MSG${NC}"
echo -e "  ${GRAY}Time:    $(date '+%Y-%m-%d %H:%M:%S')${NC}"

# ════════════════════════════════════════════════════════════════════════════
# STAGE 1: CI — Lint & Validate
# ════════════════════════════════════════════════════════════════════════════
if [ "$SKIP_CI" = false ]; then
    banner "STAGE 1: CI — Lint & Validate" "$YELLOW"

    # Syntax check
    step "📝" "Validating server.js syntax..."
    if node -c "$BACKEND_DIR/server.js" 2>/dev/null; then
        success "Syntax OK"
    else
        fail "Syntax error in server.js!"
        banner "PIPELINE FAILED — Fix syntax errors" "$RED"
        exit 1
    fi

    # Dockerfile check
    step "🐳" "Checking Dockerfile..."
    if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
        success "Dockerfile present"
    else
        fail "Dockerfile missing!"
        exit 1
    fi

    # docker-compose validation
    step "📋" "Validating docker-compose.yml..."
    if docker compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null; then
        success "docker-compose.yml is valid"
    else
        fail "docker-compose.yml has errors!"
        exit 1
    fi

    echo ""
    success "CI Stage PASSED"
fi

# ════════════════════════════════════════════════════════════════════════════
# STAGE 2: CD — Build & Deploy
# ════════════════════════════════════════════════════════════════════════════
banner "STAGE 2: CD — Build & Deploy" "$YELLOW"

# Tag for rollback
TAG_NAME="deploy/pre-$(date '+%Y%m%d-%H%M%S')"
step "🏷️" "Tagging current state for rollback..."
git -C "$PROJECT_ROOT" tag "$TAG_NAME" 2>/dev/null && success "Tagged as $TAG_NAME" || echo -e "  ${YELLOW}⚠️  Could not create tag (non-fatal)${NC}"

# Build and redeploy
step "🔨" "Building Docker image..."
docker compose -f "$COMPOSE_FILE" build app 2>&1
success "Docker image built"

step "🚀" "Restarting app container..."
docker compose -f "$COMPOSE_FILE" up -d --no-deps --force-recreate app 2>&1
success "App container restarted"

# ════════════════════════════════════════════════════════════════════════════
# STAGE 3: Verify — Health Check
# ════════════════════════════════════════════════════════════════════════════
banner "STAGE 3: Verify — Health Check" "$YELLOW"

step "⏳" "Waiting for container to start (10s)..."
sleep 10

step "🏥" "Checking $HEALTH_URL ..."
HEALTHY=false

for i in $(seq 1 5); do
    HTTP_STATUS=$(curl -s -o /tmp/health_response.json -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        HEALTHY=true
        HEALTH_MSG=$(cat /tmp/health_response.json 2>/dev/null)
        success "Health check PASSED (HTTP $HTTP_STATUS)"
        echo -e "         ${GRAY}Response: $HEALTH_MSG${NC}"
        break
    else
        if [ "$i" -lt 5 ]; then
            echo -e "  ${YELLOW}⏳  Attempt $i/5 failed (HTTP $HTTP_STATUS), retrying in 3s...${NC}"
            sleep 3
        fi
    fi
done

if [ "$HEALTHY" = false ]; then
    fail "Health check FAILED after 5 attempts!"
    echo ""
    echo -e "  ${YELLOW}Container logs:${NC}"
    docker logs buyer-portal-app --tail 20 2>&1
    banner "PIPELINE FAILED — App unhealthy" "$RED"
    echo -e "  ${YELLOW}Run ./scripts/rollback.sh to revert${NC}"
    exit 1
fi

# ════════════════════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════════════════════
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

banner "DEPLOYMENT SUCCESSFUL" "$GREEN"
echo -e "  📦  Commit:     $COMMIT_SHA — $COMMIT_MSG"
echo -e "  🌐  App:        $APP_URL"
echo -e "  📊  Prometheus: http://localhost:9090"
echo -e "  📈  Grafana:    http://localhost:3001"
echo -e "  ⏱️  Duration:   ${ELAPSED}s"
echo -e "  ${GRAY}🏷️  Rollback:   git checkout $TAG_NAME${NC}"
echo ""
echo -e "  ${GREEN}CI ✅ → BUILD ✅ → DEPLOY ✅ → VERIFY ✅${NC}"
echo ""
