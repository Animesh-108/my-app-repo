# Automated CI/CD Pipeline for a Containerized Application on EKS

This repository contains a simple Node.js web application and the complete CI/CD configuration required to deploy it automatically to a multi-environment Kubernetes (EKS) setup on AWS.

This project represents the *application* half of a complete, end-to-end DevOps workflow. The corresponding infrastructure (VPCs, EKS clusters) is provisioned via Infrastructure as Code (IaC) in a separate repository: `my-eks-infra`.

## Target Architecture Overview

This pipeline follows modern GitOps and IaC best practices.

* **Source Control:** GitHub (this repository).
* **Infrastructure (IaC):** Terraform manages two separate EKS clusters (`my-app-non-prod`, `my-app-prod`) with dedicated VPCs.
* **CI/CD Orchestration:** AWS CodePipeline (`non-prod-pipeline`, `prod-pipeline`).
* **Build & Test:** AWS CodeBuild runs scripts defined in `buildspec-ci.yml` and `buildspec-cd.yml`.
* **Container Registry:** AWS ECR stores the built Docker images.
* **Deployment Target:** Amazon EKS (Kubernetes).
* **Kubernetes Manifests:** Kustomize is used to manage environment-specific configurations (`dev` vs. `prod`) on top of a common `base`.

---

## CI/CD Workflow

This project uses a GitFlow branching strategy to manage deployments. All new work is done on the `dev` branch and promoted to `main` only when ready for production.

### 1. Development Workflow (`dev` branch)

1.  A developer makes a feature change (e.g., edits `index.js`).
2.  The change is committed and pushed to the **`dev`** branch.
3.  This push automatically triggers the **`non-prod-pipeline`** in AWS CodePipeline.
4.  **Source Stage:** Pulls the `dev` branch from GitHub.
5.  **Build Stage:** Runs `buildspec-ci.yml` to:
    * Build the Docker image.
    * Tag it with the Git commit hash.
    * Push the image to the `my-app` ECR repository.
    * Create an `imagedefinitions.json` artifact to pass the image URI to the next stage.
6.  **Deploy Stage:** Runs `buildspec-cd.yml` to:
    * Install `kubectl` and `kustomize`.
    * Connect to the **`my-app-non-prod`** cluster.
    * Use `kustomize build` on the `k8s/overlays/dev` overlay.
    * Pipe the resulting manifest to `kubectl apply` to deploy the new image to the **`dev`** namespace.

### 2. Production Workflow (`main` branch)

1.  After the feature is verified in the `dev` environment, the `dev` branch is merged into the **`main`** branch.
2.  The push to `main` automatically triggers the **`prod-pipeline`**.
3.  **Source Stage:** Pulls the `main` branch from GitHub.
4.  **Build Stage:** Runs `buildspec-ci.yml` to build, tag, and push a *production-ready* image to ECR.
5.  **Manual-Approval Stage:** The pipeline **STOPS** and waits for a human to review the built artifact and approve the deployment via the AWS Console.
6.  **Deploy Stage:** (Only after approval) Runs `buildspec-cd.yml` to:
    * Connect to the **`my-app-prod`** cluster.
    * Use `kustomize build` on the `k8s/overlays/prod` overlay (which increases replicas to 3).
    * Pipe the manifest to `kubectl apply` to deploy the new image to the **`prod`** namespace.

---

## Repository Structure
```bash
├── k8s/
│      ├── base/ 
│      │       ├── deployment.yaml # Core app definition (uses YOUR_IMAGE_PLACEHOLDER) 
│      │       ├── service.yaml # Core ClusterIP service
│      │       └── kustomization.yaml # Lists base resources
│      └── overlays/
│              ├── dev/ 
│              │      └── kustomization.yaml # Adds 'dev-' prefix to resources
│              └── prod/
│                     ├── patch-replicas.yaml # Overrides replica count to 3 
│                     └── kustomization.yaml # Applies the replica patch 
│    
├── buildspec-ci.yml # CI Script: Docker build, tag, push, create artifact 
├── buildspec-cd.yml # CD Script: Install tools, connect to EKS, kustomize build & apply 
├── Dockerfile # Builds the Node.js app using ECR Public base image 
└── index.js # The simple Node.js "Hello World" application
```
---

## How to Test Deployed Applications

You can test the deployed application by port-forwarding from your local machine to the service running in EKS.

### Test Development Environment

1.  **Switch Context:**
    ```bash
    aws eks update-kubeconfig --name my-app-non-prod --region us-east-1
    ```
2.  **Port-Forward:**
    ```bash
    # Note: We use 'deployment/dev-my-app' because Kustomize prefixed the name
    kubectl port-forward deployment/dev-my-app 8080:80 -n dev
    ```
3.  **View:** Open `http://localhost:8080` in your browser.

### Test Production Environment

1.  **Switch Context:**
    ```bash
    aws eks update-kubeconfig --name my-app-prod --region us-east-1
    ```
2.  **Port-Forward:**
    ```bash
    # Note: We use 'service/my-app' as Kustomize did not prefix the name
    kubectl port-forward service/my-app 9090:80 -n prod
    ```
3.  **View:** Open `http://localhost:9090` in your browser.
