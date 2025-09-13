# Infrastructure with Terraform on GCP + GitHub Actions (OIDC)

This repository is configured to use **Terraform** with **Google Cloud Platform (GCP)** in a secure and automated way through **GitHub Actions**, leveraging **Workload Identity Federation (OIDC)**. The goal is to avoid static JSON keys and follow the **principle of least privilege**. Below is an explanation of **why each step is done this way**.

## Mental map for memorization

**Light → Box → Robot → Keys → Bridge → Guard → Pass → Usage**

- **Light (APIs):** enable GCP services.  
- **Box (Bucket):** store `terraform.tfstate` in GCS.  
- **Robot (SA):** a dedicated Service Account for Terraform.  
- **Keys (Roles):** minimum permissions for that SA.  
- **Bridge (WIF Pool):** trust link with GitHub.  
- **Guard (OIDC Provider):** validates repo and branch.  
- **Pass (Binding):** authorizes the repo to use the SA.  
- **Usage (Actions):** the workflow authenticates and executes Terraform.

---

## Step-by-step explanation

1. **Enable APIs**  
   In GCP, each service is an independent API (IAM, Storage, Run, Compute, etc.). If they are not explicitly enabled, Terraform cannot manage them. Enabling only what you need improves security and cost control.  

   ```bash
   gcloud services enable iam.googleapis.com iamcredentials.googleapis.com cloudresourcemanager.googleapis.com storage.googleapis.com artifactregistry.googleapis.com run.googleapis.com compute.googleapis.com
   ```

2. **Create a GCS bucket for Terraform state**  
   Terraform stores its infrastructure state in a `terraform.tfstate` file. Saving it in **GCS** allows collaboration, prevents state corruption, and with **versioning** you can roll back if something fails.  

   ```bash
   gcloud storage buckets create gs://tf-state-<PROJECT_ID> --location us-central1
   gcloud storage buckets update gs://tf-state-<PROJECT_ID> --versioning
   ```

3. **Create a Service Account for Terraform**  
   In GCP everything runs under an identity. A **Service Account (SA)** is a “robot” identity for Terraform. Using a dedicated SA instead of human accounts separates permissions, enables auditing, and applies granular security.  

   ```bash
   gcloud iam service-accounts create terraform-ci --display-name="Terraform CI"
   ```

4. **Assign minimum roles (least privilege principle)**  
   Each role corresponds to an action Terraform needs:  
   - `roles/storage.objectAdmin`: read/write Terraform state in GCS.  
   - `roles/artifactregistry.writer`: push images to Artifact Registry.  
   - `roles/run.admin`: manage Cloud Run services.  
   - `roles/compute.networkAdmin`: create/modify networks and firewalls.  
   - `roles/iam.serviceAccountUser`: attach SAs to created resources.  

   ```bash
   gcloud storage buckets add-iam-policy-binding gs://tf-state-<PROJECT_ID> --member="serviceAccount:terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/storage.objectAdmin"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/run.admin"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/compute.networkAdmin"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"
   ```

5. **Configure Workload Identity Federation (WIF)**  
   This allows GitHub Actions to authenticate into GCP without JSON keys.  
   - The *Pool* is the container for external identities.  
   - The *Provider* defines GitHub OIDC as the identity source.  
   - The condition restricts access to a specific repo and branch.  

   ```bash
   gcloud iam workload-identity-pools create github-oidc-pool --location=global
   gcloud iam workload-identity-pools providers create-oidc github-oidc      --location=global      --workload-identity-pool=github-oidc-pool      --issuer-uri="https://token.actions.githubusercontent.com"      --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.repository_owner=assertion.repository_owner"      --attribute-condition="assertion.repository=='naatlabia-lang/naatlab-infra-monorepo' && assertion.ref=='refs/heads/main'"
   ```

6. **Bind the repo to the SA**  
   This authorizes only the specified repo to impersonate the SA.  

   ```bash
   gcloud iam service-accounts add-iam-policy-binding terraform-ci@<PROJECT_ID>.iam.gserviceaccount.com      --role="roles/iam.workloadIdentityUser"      --member="principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/github-oidc-pool/attribute.repository/naatlabia-lang/naatlab-infra-monorepo"
   ```

7. **Authentication in GitHub Actions**  
   The workflow uses OIDC to obtain temporary GCP credentials without JSON keys.  

   ```yaml
   permissions:
     id-token: write
     contents: read

   jobs:
     terraform:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: google-github-actions/auth@v2
           with:
             workload_identity_provider: projects/${{ secrets.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/github-oidc-pool/providers/github-oidc
             service_account: terraform-ci@${{ secrets.GCP_PROJECT_ID }}.iam.gserviceaccount.com
   ```

---

## Summary

1. **APIs:** enabled because each GCP service is independent.  
2. **GCS Bucket:** centralizes and versions Terraform state.  
3. **Service Account:** separates identity and avoids human accounts.  
4. **Minimum roles:** enforce the principle of least privilege.  
5. **WIF:** secure authentication from GitHub without JSON keys.  
6. **Binding:** ensures only your repo/branch can use the SA.  
7. **Actions:** runs `plan/apply` in pipelines with temporary credentials.  

This flow guarantees **security, auditability, and full automation** in GCP with Terraform.
