# Real Estate Buyer Portal - DevOps Submission Version

This version is tailored for an academic DevOps project with **free-tier tools only**.

## What is implemented

- Containerized application (`Dockerfile`)
- Multi-service orchestration (`docker-compose.yml`)
- Monitoring stack with Prometheus + Grafana
- Metrics endpoint in app (`/metrics`)
- CI/CD workflow using GitHub Actions (`.github/workflows/ci-cd.yml`)
- Health endpoint (`/api/health`) for pipeline checks

## Quick Run (for demo)

```bash
# from project root
cd Simple_Realstate_Buyerportal
docker compose up -d --build
```

Services:
- App: http://localhost:5000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (admin/admin)

## Grafana setup (2 minutes)

1. Open Grafana at `http://localhost:3001`
2. Login: `admin` / `admin`
3. Add data source -> Prometheus -> URL: `http://prometheus:9090`
4. Import dashboard ID `1860` (Node Exporter Full) as baseline, or create custom panels using metrics starting with `buyer_portal_`

## CI/CD flow (as required)

On every push to `main/master`:
1. GitHub Actions installs dependencies
2. Starts backend and checks `/api/health`
3. Builds Docker image
4. Marks deployment stage for free-tier local/VPS execution

This demonstrates automated build + verification without paid cloud.

## Suggested architecture statement for report

Developer -> GitHub push -> GitHub Actions CI (test + build) -> Docker image validated -> Local/VPS Docker Compose deployment -> Prometheus scrapes `/metrics` -> Grafana visualizes system health.


