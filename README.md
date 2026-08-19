# 🚀 CloudDevOpsProject
### Production-Grade Microservices Platform on Azure — Terraform · AKS · GitOps · DevSecOps

> A self-driven, end-to-end DevOps engineering project: taking a 3-tier microservices application from a local Docker Compose stack to a fully automated, secured, and observable deployment on **Azure Kubernetes Service (AKS)** — built and hardened entirely from scratch, on my own initiative, as a hands-on demonstration of production DevOps/Cloud practices.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Services](#-services)
- [Infrastructure (Terraform)](#-infrastructure-terraform)
- [Security](#-security)
- [CI Pipeline (GitHub Actions)](#-ci-pipeline-github-actions)
- [CD / GitOps (ArgoCD)](#-cd--gitops-argocd)
- [Observability Stack](#-observability-stack)
- [Local Development](#-local-development)
- [Deployment Guide](#-deployment-guide)
- [Screenshots / Proof of Work](#-screenshots--proof-of-work)
- [Engineering Challenges & Fixes](#-engineering-challenges--fixes)
- [Roadmap / Future Improvements](#-roadmap--future-improvements)
- [Author](#-author)

---

## 🧭 Overview

This project rebuilds a 3-tier microservices application (**Frontend**, **Auth Service**, **Roadmap Service**, **MySQL**) with a production-grade cloud-native platform around it. The original reference application/task used AWS + Jenkins — this implementation was independently redesigned and re-engineered to run on **Azure**, using **GitHub Actions** instead of Jenkins, with additional security and observability layers that go beyond the original scope, built purely for personal learning and portfolio purposes.

**What this project demonstrates:**

- Infrastructure as Code with modular, reusable Terraform on Azure
- Secure secrets management with Azure Key Vault (no plaintext credentials, anywhere)
- A real CI pipeline: build → vulnerability scan → push → manifest update
- GitOps-based continuous deployment with ArgoCD (auto-sync + self-heal)
- A full observability stack: metrics, logs, and (in-progress) distributed tracing
- Container hardening: non-root users, multi-stage builds, minimal base images

---

## 🏗 Architecture

```
                                   ┌────────────────────────┐
                                   │      GitHub Repo        │
                                   │  (source + k8s + IaC)   │
                                   └───────────┬──────────────┘
                                               │ push
                                               ▼
                                   ┌────────────────────────┐
                                   │   GitHub Actions (CI)   │
                                   │  Build → Trivy → Push   │
                                   │   → Update k8s tags     │
                                   └───────────┬──────────────┘
                                               │ image push
                                               ▼
                                   ┌────────────────────────┐
                                   │   Azure Container       │
                                   │   Registry (ACR)        │
                                   └───────────┬──────────────┘
                                               │ pull (AcrPull role)
                                               ▼
 ┌──────────────┐   watches k8s/   ┌────────────────────────────────────────────┐
 │   ArgoCD     │◄─────────────────│         Azure Kubernetes Service (AKS)      │
 │  (GitOps)    │   auto-sync      │                                             │
 └──────────────┘                  │   ┌─────────────┐   ┌──────────────────┐   │
                                    │   │  Ingress    │──▶│    Frontend       │   │
                                    │   │  (NGINX)    │   │   (Node.js)       │   │
                                    │   └─────────────┘   └────────┬──────────┘   │
                                    │                                │            │
                                    │                    ┌───────────┴──────────┐ │
                                    │                    ▼                       ▼ │
                                    │         ┌─────────────────┐   ┌──────────────────┐
                                    │         │  Auth Service    │   │ Roadmap Service   │
                                    │         │  (Python/Flask)  │   │  (Java/Spring)    │
                                    │         └────────┬─────────┘   └──────────────────┘
                                    │                    │                              │
                                    │                    ▼                              │
                                    │         ┌─────────────────────┐                   │
                                    │         │  MySQL (StatefulSet)│                   │
                                    │         │  + Headless Service  │                  │
                                    │         └──────────┬───────────┘                  │
                                    │                    │ password via CSI Driver      │
                                    │                    ▼                              │
                                    │         ┌─────────────────────┐                   │
                                    │         │  Azure Key Vault     │                   │
                                    │         └─────────────────────┘                   │
                                    └────────────────────────────────────────────┘

     ┌───────────────────────────── Observability (namespace: monitoring) ─────────────────────────────┐
     │   Prometheus  ──▶  Grafana  ◀──  Loki + Promtail   │   Jaeger (tracing UI — instrumentation WIP)  │
     └────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

| Layer               | Technology                                              |
|----------------------|----------------------------------------------------------|
| Cloud Provider        | Microsoft Azure                                          |
| IaC                   | Terraform (modular: network / acr / aks)                |
| Container Registry     | Azure Container Registry (ACR)                          |
| Orchestration          | Azure Kubernetes Service (AKS) — 2 worker nodes          |
| Secrets Management     | Azure Key Vault + Secrets Store CSI Driver               |
| CI                     | GitHub Actions                                            |
| Security Scanning       | Trivy (image vulnerability scanning)                     |
| CD / GitOps             | ArgoCD (auto-sync, self-heal, pruning)                    |
| Ingress                 | NGINX Ingress Controller                                  |
| Metrics                 | Prometheus + kube-state-metrics + node-exporter           |
| Dashboards               | Grafana                                                    |
| Log Aggregation           | Loki + Promtail                                            |
| Distributed Tracing        | Jaeger (OpenTelemetry auto-instrumentation — in progress)  |
| Backend Services            | Node.js (Frontend), Python/Flask (Auth), Java/Spring (Roadmap) |
| Database                     | MySQL 8.0 (StatefulSet + Azure Disk-backed persistent storage) |
| Local Dev                     | Docker Compose                                              |

---

## 📂 Repository Structure

```
.
├── frontend/                  # Node.js frontend service
│   └── Dockerfile
├── auth-service/               # Python/Flask authentication service
│   └── Dockerfile
├── roadmap-service/             # Java/Spring roadmap service
│   └── Dockerfile
├── docker-compose.yml            # Local development stack
├── terraform/                     # Infrastructure as Code
│   ├── main.tf
│   ├── providers.tf                # Azure Blob remote backend
│   └── modules/
│       ├── network/                  # VNet + Subnet
│       ├── acr/                       # Azure Container Registry
│       └── aks/                        # AKS cluster + AcrPull role binding
├── k8s/                                # Kubernetes manifests (GitOps source of truth)
│   ├── namespace-storage.yaml            # Namespace + Azure Disk StorageClass
│   ├── keyvault-provider.yaml             # SecretProviderClass (Key Vault CSI)
│   ├── mysql-statefulset.yaml              # MySQL StatefulSet + Headless Service
│   ├── configmap.yaml                       # Shared environment configuration
│   ├── auth-service.yaml                     # Auth Deployment + Service
│   ├── roadmap-service.yaml                   # Roadmap Deployment + Service
│   ├── frontend-service.yaml                   # Frontend Deployment + Service
│   └── ingress.yaml                              # NGINX Ingress rules
├── argo-app.yaml                                  # ArgoCD Application definition
├──  screenshots/                                 # Proof-of-work screenshots (see below)
└── .github/
    └── workflows/
        └── ci.yml                                      # CI pipeline definition
```

---

## 🧩 Services

| Service            | Tech               | Responsibility                                  | Port  |
|----------------------|----------------------|---------------------------------------------------|-------|
| **Frontend**           | Node.js / Express      | Web UI, routes requests to backend services         | 3000  |
| **Auth Service**        | Python / Flask           | User signup/login, credential validation             | 5000  |
| **Roadmap Service**       | Java / Spring Boot         | Serves the core DevOps roadmap application data       | 8080  |
| **MySQL**                  | MySQL 8.0                     | Persistent user data storage (StatefulSet)              | 3306  |

Services communicate over the cluster's internal DNS. The frontend never talks to MySQL directly — all data access goes through the backend services, keeping a clean separation of concerns.

---

## 🏗 Infrastructure (Terraform)

Infrastructure is fully codified and modular:

- **`network` module** — provisions a dedicated VNet and Subnet for the cluster.
- **`acr` module** — provisions Azure Container Registry to store built images.
- **`aks` module** — provisions the AKS cluster (2 nodes, `Standard_D2s_v3`), assigns a `SystemAssigned` managed identity, and grants it the **AcrPull** role on the registry — no static credentials involved in image pulls.
- **Remote state** — the Terraform state is stored remotely in an **Azure Blob Storage** backend (not committed to Git), enabling safe collaboration and preventing state drift/loss.

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🔐 Security

Security wasn't an afterthought — it's built into every layer:

- **No plaintext secrets anywhere.** Database credentials live in **Azure Key Vault** and are mounted into pods via the **Secrets Store CSI Driver**, exposed to the cluster only as a synced Kubernetes Secret — never committed to the repo, never in a ConfigMap.
- **Least-privilege identity access.** The AKS cluster's managed identity is granted only the specific RBAC roles it needs (`AcrPull` on the registry, `Key Vault Secrets User` on the vault) — no shared credentials, no service principal secrets floating around.
- **Vulnerability scanning in CI.** Every image is scanned with **Trivy** for `CRITICAL`/`HIGH` CVEs before being pushed to the registry.
- **Hardened Dockerfiles:**
  - All containers run as **non-root users**.
  - **Multi-stage builds** (Java service) keep the final image lean and dependency-cache-optimized.
  - `.dockerignore` files exclude build artifacts, `node_modules`, `__pycache__`, and `.env` files from build context.
- **Isolated remote Terraform state**, separate from application infrastructure, stored in its own resource group.

---

## ⚙️ CI Pipeline (GitHub Actions)

On every push to `main` (excluding changes to `terraform/`, `k8s/`, and docs — to avoid pipeline loops), the pipeline:

1. **Authenticates** to Azure using federated credentials (`AZURE_CREDENTIALS` secret).
2. **Builds** each service's Docker image.
3. **Scans** each image with **Trivy** for known vulnerabilities.
4. **Pushes** the image to ACR, tagged with the Git commit SHA (`${{ github.sha }}`) — never `latest` — so every deployed version is traceable back to an exact commit.
5. **Updates the Kubernetes manifests** in `k8s/` with the new image tags and pushes that change back to the repo.

This last step is what closes the loop with ArgoCD — the CI pipeline never touches the cluster directly; it only updates the *desired state* in Git.

---

## 🔁 CD / GitOps (ArgoCD)

ArgoCD continuously watches the `k8s/` directory of this repo and reconciles the live cluster state against it:

- **Automated sync** — any change pushed to `k8s/` (by the CI pipeline or manually) is picked up and applied automatically.
- **Self-heal** — if someone manually changes something in the cluster (drift), ArgoCD reverts it back to match Git.
- **Pruning** — resources removed from the manifests are automatically removed from the cluster.

This means the Git repository is the **single source of truth** for what's running in production — a core GitOps principle.

---

## 📊 Observability Stack

Deployed on the cluster (namespace: `monitoring`) via Helm:

| Component     | Purpose                                                         |
|----------------|---------------------------------------------------------------------|
| **Prometheus**   | Scrapes metrics from nodes, pods, and cluster components               |
| **Grafana**       | Unified dashboards for metrics + logs (pre-built Kubernetes dashboards) |
| **Loki + Promtail** | Centralized log aggregation across all pods, queryable via LogQL     |
| **Jaeger**          | Distributed tracing backend — deployed and reachable; full auto-instrumentation via the OpenTelemetry Operator is a work in progress |

Grafana ships with pre-built dashboards for pod-level CPU/memory/network usage, and Loki is wired in as a data source for live log exploration by namespace and container.

---

## 💻 Local Development

The full stack can be run locally with Docker Compose for fast iteration before touching the cloud:

```bash
docker-compose up -d --build
```

This spins up MySQL, Auth Service, Roadmap Service, and Frontend, wired together with the same environment variable contracts used in the Kubernetes manifests — so behavior stays consistent between local and cloud environments.

---

## 🚀 Deployment Guide

```bash
# 1. Provision infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 2. Connect kubectl to the new cluster
az aks get-credentials --resource-group <rg-name> --name <aks-name>

# 3. Bootstrap the cluster
kubectl apply -f k8s/namespace-storage.yaml
kubectl apply -f k8s/keyvault-provider.yaml
kubectl apply -f k8s/mysql-statefulset.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/auth-service.yaml
kubectl apply -f k8s/roadmap-service.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/ingress.yaml

# 4. Install ArgoCD and hand off deployment management to it
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argo-app.yaml
```

From this point on, deployments are managed entirely through Git — push a change, ArgoCD syncs it.

---

## 📸 Screenshots / Proof of Work

All screenshots live in [`screenshots/`](./screenshots). Suggested naming and what each one demonstrates:

| File                          | What it shows                                                                 |
|---------------------------------|-----------------------------------------------------------------------------------|
| `01-argocd-healthy-synced.png`    | ArgoCD Application — `Healthy` & `Synced`, GitOps loop confirmed end-to-end        |
| `02-app-live-ingress.png`           | The application running live, reached through the public Ingress IP                 |
| `03-grafana-k8s-dashboard.png`        | Grafana's Kubernetes Compute Resources dashboard — pod memory/network metrics       |
| `04-grafana-loki-logs.png`               | Grafana Explore — live application logs queried via Loki (LogQL, namespace filter)   |
| `05-kubectl-cluster-state.png`             | Terminal output — all pods/services healthy across `ivolve`, `ingress-nginx`, `monitoring` |
| `06-azure-keyvault-secrets.png`              | Azure Key Vault — `mysql-password` secret, never stored in Git                          |
| `07-azure-acr-repositories.png`                | Azure Container Registry — pushed images for all three services                          |
| `08-azure-resource-group.png`                    | Azure Resource Group — full provisioned infrastructure (AKS, ACR, VNet, Key Vault, etc.) |
| `09-azure-tfstate-blob.png`                        | Azure Blob Storage — remote Terraform state, safely stored outside the repo               |
| `10-github-actions-runs.png`                         | GitHub Actions — CI pipeline run history, all green                                        |

---

## 🧩 Engineering Challenges & Fixes

A few real problems hit during the build — documenting them here because working through them was half the value of the project:

| Problem | Root Cause | Fix |
|---|---|---|
| `ServiceCidrOverlapExistingSubnetsCidr` on `terraform apply` | AKS's default service CIDR (`10.0.0.0/16`) overlapped with the VNet's own address space | Explicitly set a non-overlapping `service_cidr` (`10.1.0.0/16`) in the AKS `network_profile` |
| `RequestDisallowedByAzure` creating the Storage Account | Subscription policy restricted resource creation in `eastus` | Re-created the backend storage account in `switzerlandnorth`, matching the rest of the infrastructure |
| `ForbiddenByRbac` writing to Key Vault | Key Vault used RBAC authorization mode — vault creation doesn't grant access by default | Explicitly assigned `Key Vault Secrets Officer` (self) and `Key Vault Secrets User` (AKS managed identity) roles |
| App failing with `Missing database environment variables: DB_USER` | Mismatch between the variable names in the app code and the ones set in `docker-compose.yml`/manifests | Traced the actual env var the app read from source and aligned the Compose/K8s config to match |
| Ingress never got a public IP | No Ingress Controller was installed — the `Ingress` resource alone is just a routing spec, not a load balancer | Installed the NGINX Ingress Controller, which provisions the actual Azure Load Balancer + public IP |
| OpenTelemetry Collector stuck in `CrashLoopBackOff` | The default Operator-managed Collector image version had a config-parsing incompatibility | Pinned an older, stable Collector image version — later removed pending a cleaner instrumentation pass |
| `git push` hanging at ~90% | Terraform provider binaries (`.terraform/`) were being committed — hundreds of MBs | Added `.gitignore`, purged the binaries from the last commit with `git rm -r --cached`, and reset history before the bloated commit |

---

## 🗺 Roadmap / Future Improvements

Things I'd add next to push this further toward true production-readiness:

- [ ] **Complete OpenTelemetry auto-instrumentation** end-to-end so Jaeger shows real request traces across Frontend → Auth → Roadmap
- [ ] **SonarCloud** integration in CI for static code quality/security analysis (SAST)
- [ ] **checkov / tfsec** in CI to scan Terraform code for misconfigurations before `apply`
- [ ] **NetworkPolicies** to restrict pod-to-pod traffic by default (currently open within the cluster)
- [ ] **HTTPS via cert-manager + Let's Encrypt** on the Ingress, instead of plain HTTP
- [ ] **Backup & Disaster Recovery** for the MySQL StatefulSet (e.g., Velero-based volume snapshots)

---

## 👤 Author

**Mazen Hassan**
Cloud / DevSecOps Engineer — Electronics & Electrical Communications Engineering, Tanta University
GitHub: [@mazenhassan20](https://github.com/mazenhassan20)

---

> This project was built independently as a hands-on learning exercise — not affiliated with, or submitted as part of, any bootcamp or graduation requirement. Every design decision, bug, and fix documented here reflects real, self-directed engineering work.
