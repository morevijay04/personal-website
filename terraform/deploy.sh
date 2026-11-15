#!/usr/bin/env bash
# deploy.sh — Upload site files to S3 and invalidate the CloudFront cache.
#
# Usage:
#   ./terraform/deploy.sh
#
# Prerequisites:
#   - AWS CLI installed and configured (aws configure or environment variables)
#   - Terraform state must exist (run `terraform apply` first)
#
# The script reads all required values from Terraform outputs so there are
# no hardcoded bucket names or distribution IDs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../src" && pwd)"

echo "==> Fetching Terraform outputs..."
cd "${SCRIPT_DIR}"

BUCKET=$(terraform output -raw s3_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)

if [[ -z "${BUCKET}" ]] || [[ -z "${DISTRIBUTION_ID}" ]]; then
  echo "ERROR: Could not read Terraform outputs. Have you run 'terraform apply'?"
  exit 1
fi

echo "    Bucket:          ${BUCKET}"
echo "    Distribution ID: ${DISTRIBUTION_ID}"
echo ""

# ── Sync files ─────────────────────────────────────────────────────────────────
# --delete removes objects from S3 that no longer exist locally.
# Content-type is inferred automatically by the AWS CLI.
echo "==> Syncing ${SRC_DIR}/ → s3://${BUCKET}/ ..."
aws s3 sync "${SRC_DIR}/" "s3://${BUCKET}/" \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "*.json"

# HTML and JSON files get a shorter TTL so content updates propagate quickly
# even before CloudFront is invalidated.
aws s3 sync "${SRC_DIR}/" "s3://${BUCKET}/" \
  --delete \
  --cache-control "public, max-age=0, must-revalidate" \
  --include "*.html" \
  --include "*.json" \
  --exclude "*"

echo ""

# ── CloudFront invalidation ────────────────────────────────────────────────────
echo "==> Creating CloudFront invalidation for /* ..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "    Invalidation ID: ${INVALIDATION_ID}"
echo ""

# Wait until the invalidation completes (usually < 60 s).
echo "==> Waiting for invalidation to complete..."
aws cloudfront wait invalidation-completed \
  --distribution-id "${DISTRIBUTION_ID}" \
  --id "${INVALIDATION_ID}"

echo ""
echo "==> Done! Your site is live."

# Print the URL for convenience.
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || terraform output -raw cloudfront_url)
echo "    ${WEBSITE_URL}"
