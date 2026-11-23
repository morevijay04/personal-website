#!/usr/bin/env bash
# One-time script to register vijaymore.com via AWS CLI.
# After registration completes, import into Terraform:
#   terraform import 'aws_route53domains_registered_domain.website[0]' vijaymore.com

set -euo pipefail

CONTACT='{
  "FirstName": "Vijay",
  "LastName": "More",
  "ContactType": "PERSON",
  "Email": "more.vijayb04@gmail.com",
  "PhoneNumber": "+65.85252629",
  "AddressLine1": "205 River Valley Road 0357",
  "City": "Singapore",
  "CountryCode": "SG",
  "ZipCode": "238274"
}'

echo "==> Submitting domain registration for vijaymore.com ..."

OPERATION_ID=$(aws route53domains register-domain \
  --region us-east-1 \
  --domain-name vijaymore.com \
  --duration-in-years 1 \
  --auto-renew \
  --admin-contact      "$CONTACT" \
  --registrant-contact "$CONTACT" \
  --tech-contact       "$CONTACT" \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact \
  --query OperationId \
  --output text)

echo "    OperationId: ${OPERATION_ID}"
echo ""
echo "==> Waiting for registration to complete (this can take 15-30 min)..."

while true; do
  STATUS=$(aws route53domains get-operation-detail \
    --region us-east-1 \
    --operation-id "${OPERATION_ID}" \
    --query Status \
    --output text)

  echo "    Status: ${STATUS}"

  if [[ "${STATUS}" == "SUCCESSFUL" ]]; then
    echo ""
    echo "==> Domain registered! Now run:"
    echo "    terraform import 'aws_route53domains_registered_domain.website[0]' vijaymore.com"
    echo "    terraform apply"
    break
  elif [[ "${STATUS}" == "FAILED" || "${STATUS}" == "ERROR" ]]; then
    echo "ERROR: Registration failed."
    aws route53domains get-operation-detail --region us-east-1 --operation-id "${OPERATION_ID}"
    exit 1
  fi

  sleep 30
done
