# Multi-Node K8s GPU Management System

A comprehensive GPU management system designed for multi-node Kubernetes clusters, specifically optimized for environments with 4x NVIDIA RTX 5090 GPUs per node.

## System Architecture

This system consists of four core components managed as Git Submodules:

### 1. [k8s-cluster-setup](https://github.com/linskybing/k8s-multicast-setting)
**K8s Cluster Infrastructure**

- Responsible for building multi-node K8s clusters
- Configures multi-GPU resource pool sharing mechanisms
- Sets up networking and storage infrastructure
- Integrates with k8s-device-plugin for GPU scheduling support

### 2. [k8s-device-plugin](https://github.com/linskybing/k8s-device-plugin)
**GPU Device Plugin (Custom Build)**

- Custom modified version based on NVIDIA Device Plugin
- **Core Feature**: Supports multi-GPU scheduling within a single Pod
- Enables Multi-GPU CUDA workloads
- Provides GPU MPS (Multi-Process Service) support
- Implements fine-grained GPU resource allocation

### 3. [frontend](https://github.com/ted1204/frontend-go)
**User Interface Layer**

- Provides the **sole interface** for users to access the K8s cluster
- Web UI for cluster management and monitoring
- Offers multiple functionalities:
  - GPU resource visualization
  - Pod/Job management
  - User access control
  - Real-time monitoring dashboard

### 4. [backend](https://github.com/linskybing/platform-go)
**API Server**

- Provides backend API services
- Handle all API requests from frontend
- Interacts with K8s API Server
- Manages user authentication and authorization
- Handles GPU resource allocation logic

## Component Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   User Access                        │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │   frontend           │ (Web UI)
            └──────────┬───────────┘
                       │ API Calls
                       ▼
            ┌──────────────────────┐
            │   backend            │ (API Server)
            └──────────┬───────────┘
                       │ K8s API
                       ▼
            ┌──────────────────────┐
            │  K8s Cluster         │
            │  k8s-cluster-setup   │ (Infrastructure)
            └──────────┬───────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │ k8s-device-plugin    │ (GPU Scheduler)
            │ (Multi-GPU Support)  │
            └──────────────────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │  4x RTX 5090 GPUs    │ (Per Node)
            └──────────────────────┘
```

## Quick Start

### 1. Clone Repository (with all submodules)

```bash
# Clone main repo with all submodules
git clone --recurse-submodules <main-repo-url>
cd k8s

# Or if already cloned, initialize submodules
git submodule update --init --recursive
```

### 2. Update All Submodules to Latest

```bash
# Update all submodules to their latest remote state
git submodule update --remote --merge

# Or update individually
cd k8s-cluster-setup && git pull origin master && cd ..
cd k8s-device-plugin && git pull origin mps-individual-gpu && cd ..
cd frontend && git pull origin main && cd ..
cd backend && git pull origin main && cd ..
```

### 3. Deployment Order

1. **Build K8s Cluster**
   ```bash
   cd k8s-cluster-setup
   # Follow its README.md to deploy K8s cluster
   ```

2. **Deploy GPU Device Plugin**
   ```bash
   cd k8s-device-plugin
   # Build and deploy custom GPU plugin (mps-individual-gpu branch)
   make build
   kubectl apply -f deployments/
   ```

3. **Deploy API Server**
   ```bash
   cd backend
   # Deploy backend API service
   ```

4. **Deploy Frontend UI**
   ```bash
   cd frontend
   # Deploy Web UI
   ```

## Development Workflow

### Working Within Submodules

```bash
# Enter submodule
cd k8s-device-plugin

# Create new branch and develop
git checkout -b feature/new-feature
# ... make changes ...
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# Return to main repo and update submodule reference
cd ..
git add k8s-device-plugin
git commit -m "Update k8s-device-plugin to latest"
```

### Keep All Modules Synchronized

```bash
# One-command update all submodules to latest
./scripts/update-all-submodules.sh
```

## Hardware Requirements

- **Node Configuration**: Each node requires 4x NVIDIA RTX 5090 GPUs
- **Network**: High-speed interconnect network (recommended 10GbE or higher)
- **Storage**: Shared storage system (e.g., NFS, Ceph)

## Technology Stack

- **Infrastructure**: Kubernetes, Containerd
- **GPU Management**: NVIDIA Device Plugin (Custom), CUDA, MPS
- **Backend**: Go (backend)
- **Frontend**: TypeScript, React, Vite (frontend)
- **Build Tools**: Docker, Helm

## Maintainers

- k8s-cluster-setup: @linskybing
- k8s-device-plugin: @linskybing (mps-individual-gpu branch)
- backend: @linskybing
- frontend: @ted1204

## License

Please refer to individual LICENSE files in each submodule.

## FAQ

### How to verify GPUs are configured correctly?

```bash
kubectl describe nodes | grep nvidia.com/gpu
```

### How to test multi-GPU Pods?

Refer to example YAML files in `k8s-device-plugin/tests/`.

### How to update a single submodule?

```bash
cd <submodule-name>
git pull origin <branch-name>
cd ..
git add <submodule-name>
git commit -m "Update <submodule-name>"
```

---

**Last Updated**: 2026-01-04
