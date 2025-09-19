#!/usr/bin/env bash
set -euo pipefail

# ================== CONFIG ==================
PROJECT_ID="cnn-hybrid-experiments-infra"
REGION="us-central1"
BUCKET_STATE="tf-state-${PROJECT_ID}"
POOL="github-oidc-pool"
PROVIDER="github-oidc"
REPO_FULL="octavioeac/cnn-hybrid-experiments-infra"
BRANCH_REF="refs/heads/main"

# SA: must be >= 6 chars
TF_CI_SA_NAME="terraform-ci"
TF_CI_SA="${TF_CI_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud config set project "${PROJECT_ID}" >/dev/null
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

gcloud config set compute/region us-central1

echo "PROJECT_ID=${PROJECT_ID}"
echo "PROJECT_NUMBER=${PROJECT_NUMBER}"

# ======== APIS ========
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  compute.googleapis.com \
  bigquery.googleapis.com \
  aiplatform.googleapis.com \
  pubsub.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  secretmanager.googleapis.com \

# ======== STATE BUCKET (create if missing) ========
if ! gcloud storage buckets describe "gs://${BUCKET_STATE}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET_STATE}" --location "${REGION}"
  gcloud storage buckets update "gs://${BUCKET_STATE}" --versioning
  echo "Bucket gs://${BUCKET_STATE} created with versioning."
else
  echo "Bucket gs://${BUCKET_STATE} already exists; continuing."
fi

# ======== SERVICE ACCOUNT ========
if ! gcloud iam service-accounts describe "${TF_CI_SA}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${TF_CI_SA_NAME}" --display-name="Terraform CI"
  echo "Service Account ${TF_CI_SA} created."
else
  echo "Service Account ${TF_CI_SA} already exists; continuing."
fi

# ======== MINIMUM ROLES ========
# A) Access to the Terraform state bucket
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_STATE}" \
  --member="serviceAccount:${TF_CI_SA}" \
  --role="roles/storage.objectAdmin" >/dev/null

# B) Artifact Registry (if you will push images)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/artifactregistry.writer" >/dev/null

# C) Cloud Run / Networking / SA User (adjust to your Terraform needs)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/run.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/compute.networkAdmin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/iam.serviceAccountUser" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/storage.admin" >/dev/null 
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/artifactregistry.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/bigquery.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/aiplatform.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/pubsub.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/logging.admin" >/dev/null
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" --role="roles/monitoring.admin" >/dev/null
# IAM básico (crear/borrar Service Accounts y bindings)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" \
  --role="roles/iam.serviceAccountAdmin" >/dev/null
# Habilitar servicios/APIs desde Terraform (serviceusage)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" \
  --role="roles/serviceusage.serviceUsageAdmin" >/dev/null
# (Opcional) Secret Manager si guardas claves/tokens
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_CI_SA}" \
  --role="roles/secretmanager.admin" >/dev/null
  
echo "Roles applied."

# ======== WORKLOAD IDENTITY FEDERATION ========
# Pool
if ! gcloud iam workload-identity-pools describe "${POOL}" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${POOL}" \
    --location=global \
    --display-name="GitHub OIDC Pool"
  echo "WIF Pool created."
else
  echo "WIF Pool already exists; continuing."
fi

# Provider (restricted only by repo; no branch check so PRs also work)
if ! gcloud iam workload-identity-pools providers describe "${PROVIDER}" \
  --location=global --workload-identity-pool="${POOL}" >/dev/null 2>&1; then

  gcloud iam workload-identity-pools providers create-oidc "${PROVIDER}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL}" \
    --display-name="GitHub Actions Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository=='${REPO_FULL}'"

  echo "OIDC Provider created."

else
  echo "OIDC Provider already exists; updating configuration..."

  gcloud iam workload-identity-pools providers update-oidc "${PROVIDER}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL}" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository=='${REPO_FULL}'"
fi



# (Optional) Stricter condition: repo + branch on GCP side
# gcloud iam workload-identity-pools providers update-oidc "${PROVIDER}" \
#   --location=global --workload-identity-pool="${POOL}" \
#   --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
#   --attribute-condition="assertion.repository=='${REPO_FULL}' && assertion.ref=='${BRANCH_REF}'"

# Binding to allow YOUR REPO to impersonate the SA
gcloud iam service-accounts add-iam-policy-binding "${TF_CI_SA}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${REPO_FULL}"

echo "Done: IAM, bucket, roles, WIF and binding are ready."
