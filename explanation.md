# Flow Diagram — 5 Minute Explanation Script

> Point at each part of the diagram as you explain it.

---

## 1. The Problem (45 sec)

"In traditional software development, when a developer writes code, the process to get it to users is completely manual. You test it locally, copy files to the server, restart services, and hope nothing breaks. There's no automated testing — so bugs slip through. There's no standardized environment — so you get the classic 'it works on my machine' problem. And there's no monitoring — so if something breaks after deployment, you don't know until users complain.

This is exactly the problem DevOps solves."

---

## 2. The Solution + DevOps Principles (45 sec)

"Our solution applies five core DevOps principles:

First — **Continuous Integration**. Every code change is automatically tested the moment it's pushed. No manual testing.

Second — **Continuous Delivery**. The tested code is automatically built into a Docker image and deployed. No manual deployment.

Third — **Infrastructure as Code**. Our entire infrastructure — containers, monitoring, networking — is defined in code files like Dockerfile, docker-compose.yml, and Terraform configs. Nothing is configured manually.

Fourth — **Containerization**. The app runs inside Docker containers, so it works the same everywhere — my machine, your machine, any server.

Fifth — **Continuous Monitoring**. Prometheus and Grafana give us real-time visibility into the app's health after every deployment.

Now let me show you how all of this comes together in our architecture."

---

## 3. Developer → GitHub (20 sec)

*Point at Developer box and arrow to GitHub*

"It starts here. The developer makes a change and runs git push. GitHub stores the code and — this is the key part — automatically triggers our CI/CD pipeline. No manual step needed."

---

## 4. CI/CD Pipeline — Stage 1: Test (45 sec)

*Point at Stage 1 inside the orange box*

"This is our Continuous Integration in action. Stage 1 runs on GitHub's cloud servers automatically. It installs dependencies, validates the code syntax, then actually starts the server and hits the health endpoint to verify it returns HTTP 200. It also checks the metrics endpoint. If anything fails — pipeline stops, developer gets notified, bad code never gets deployed."

---

## 5. Stage 2: Build (30 sec)

*Point at Stage 2*

"Stage 2 applies the containerization principle. It builds a Docker image from our code, runs a test container, and performs a health check inside that container. This catches environment-specific bugs — code that works locally but breaks in a container."

---

## 6. Stage 3: Deploy (20 sec)

*Point at Stage 3*

"Stage 3 is Continuous Delivery. It validates our docker-compose configuration and triggers the deployment. Everything from push to deploy happens without any manual intervention."

---

## 7. Docker Compose + Containers (45 sec)

*Point at Docker Compose box, then three containers*

"Docker Compose brings up three containers. The App on port 5000 — our Node.js buyer portal. Prometheus on port 9090 — it scrapes the app's /metrics endpoint every 15 seconds. And Grafana on port 3001 — it visualizes all metrics in a pre-built dashboard. All of this is Infrastructure as Code — defined in YAML files, version controlled, reproducible."

---

## 8. Monitoring Flow + Closing (30 sec)

*Point at bottom arrows: app → prometheus → grafana*

"Finally, Continuous Monitoring. The app exposes metrics, Prometheus collects them, Grafana visualizes them. If the app slows down or errors spike after a deployment, we see it immediately.

So — code push triggers automated testing, builds a container, deploys it, and monitors it. All five DevOps principles working together. Let me now demonstrate this live..."

*Switch to demo*
