# Remote state lives in a GCS bucket with object versioning + state locking.
# Bootstrap once (outside Terraform):
#
#   gcloud storage buckets create gs://${PROJECT_ID}-tfstate \
#     --location=${REGION} --uniform-bucket-level-access
#   gcloud storage buckets update gs://${PROJECT_ID}-tfstate --versioning
#
# Then initialise with:
#   terraform init -backend-config="bucket=${PROJECT_ID}-tfstate"
terraform {
  backend "gcs" {
    prefix = "terrarun/state"
    # bucket supplied via -backend-config to keep this file project-agnostic
  }
}
