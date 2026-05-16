# Real Estate Buyer Portal — Automated CI/CD Pipeline with Containers

A DevOps project demonstrating an automated CI/CD pipeline for a containerized web application with monitoring using Prometheus and Grafana.

---

## Architecture

```
Developer → GitHub Push → GitHub Actions CI/CD
                              ├── Stage 1: Lint & Test (syntax + health check)
                              ├── Stage 2: Build Docker Image (build + container test)
                              └── Stage 3: Deploy (docker compose / Ansible)
                                    ├── App Container (Node.js + Express)
                                    ├── Prometheus (metrics scraping)
                                    └── Grafana (visualization dashboards)
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Web Application | Node.js, Express, SQLite, HTML/CSS/JS |
| Containerization | Docker, Docker Compose |
| CI/CD | GitHub Actions (3-stage pipeline) |
| Monitoring | Prometheus + Grafana |
| Configuration Management | Ansible |
| Infrastructure as Code | Terraform (Docker provider) |
| VM Provisioning | Vagrant + VirtualBox |

## Project Structure

```
Simple_Realstate_Buyerportal/
├── .github/workflows/ci-cd.yml     # GitHub Actions CI/CD pipeline
├── ansible/
│   ├── deploy.yml                   # Ansible playbook for deployment
│   ├── inventory.ini                # Target hosts inventory
│   └── ansible.cfg                  # Ansible configuration
├── terraform/
│   └── main.tf                      # Terraform Docker infrastructure
├── monitoring/
│   ├── prometheus.yml               # Prometheus scrape config
│   └── grafana/
│       ├── provisioning/
│       │   ├── datasources/         # Auto-configured Prometheus source
│       │   └── dashboards/          # Dashboard auto-loader config
│       └── dashboards/
│           └── buyer-portal.json    # Pre-built monitoring dashboard
├── scripts/
│   ├── deploy-local.ps1             # Local CI/CD pipeline (PowerShell)
│   ├── deploy-local.sh              # Local CI/CD pipeline (Bash)
│   ├── install-hooks.ps1            # Git hook installer
│   └── rollback.ps1                 # Rollback to previous deployment
├── backend/                         # Express.js API (auth, properties, metrics)
├── frontend/                        # HTML/CSS/JS buyer portal UI
├── Dockerfile                       # Multi-stage container build
├── .dockerignore                    # Docker build exclusions
├── docker-compose.yml               # Multi-service orchestration
├── Vagrantfile                      # VirtualBox VM provisioning
└── README.md
```

## Quick Start

### Prerequisites
- Docker Desktop installed and running
- Git

### Run Locally
```bash
cd Simple_Realstate_Buyerportal
docker compose up -d --build
```

### Access Services
| Service | URL | Credentials |
|---------|-----|-------------|
| Buyer Portal App | http://localhost:5000 | Register a new account |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin / admin |

> Grafana datasource and dashboard are **auto-provisioned** — no manual setup needed.

---

## CI/CD Pipeline (GitHub Actions)

On every push/PR to `main` or `master`:

1. **Test Stage** — Installs dependencies, validates syntax, starts server and checks `/api/health` and `/metrics`
2. **Build Stage** — Builds Docker image, runs test container, verifies health
3. **Deploy Stage** — Validates docker-compose config; actual deployment via `docker compose up` or Ansible

---

## Local CI/CD Pipeline (Automated Deployment)

Automatic local deployment on every `git commit` — no cloud infrastructure needed.

### One-Time Setup
```powershell
.\scripts\install-hooks.ps1
```

This installs a Git `post-commit` hook that triggers the pipeline automatically.

### How It Works
```
git commit → post-commit hook fires automatically
                │
                ├── Stage 1: CI (Lint & Validate)
                │   ├── Node.js syntax check
                │   ├── Dockerfile present
                │   └── docker-compose.yml valid
                │
                ├── Stage 2: CD (Build & Deploy)
                │   ├── Tag for rollback
                │   ├── Docker image rebuild
                │   └── App container restart
                │
                └── Stage 3: Verify (Health Check)
                    ├── /api/health → 200 OK
                    └── /metrics → 200 OK
```

Changes are live at `http://localhost:5000` within ~15 seconds.

### Manual Deployment
```powershell
.\scripts\deploy-local.ps1            # Full pipeline (CI + CD)
.\scripts\deploy-local.ps1 -SkipCI    # Skip lint, just build & deploy
```

### Rollback
```powershell
.\scripts\rollback.ps1                # Revert to last working deployment
```

### Skip Auto-Deploy on a Commit
```bash
git commit --no-verify -m "message"
```


## Monitoring

- **Prometheus** scrapes the `/metrics` endpoint every 15 seconds
- Metrics include: HTTP request duration, request count by status code, CPU usage, memory
- **Grafana** dashboard auto-loads with 6 panels showing app health

---

## Ansible Deployment

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

This automates: Docker installation → repo clone → container build → health verification.

---

## Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Provisions all 3 Docker containers with a shared network using Infrastructure as Code.
