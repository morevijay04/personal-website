# Vijay More — Personal Website

A minimal personal website hosted on AWS (S3 + CloudFront), managed with Terraform.

## Directory structure

```
personal-website/
├── src/                    # Website source files (what gets deployed)
│   ├── index.html
│   ├── css/styles.css
│   ├── js/app.js
│   └── data/
│       ├── talks.json      # Conference talks
│       ├── articles.json   # Writing / articles
│       └── work.json       # Selected work items
└── terraform/              # Infrastructure as code
    ├── providers.tf
    ├── variables.tf
    ├── s3.tf
    ├── cloudfront.tf
    ├── acm.tf
    ├── route53.tf
    ├── outputs.tf
    └── deploy.sh           # Deployment script
```

---

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) v2 — configured with credentials that can manage S3, CloudFront, ACM, and Route 53.
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.
- An AWS account. The free tier covers most usage for a low-traffic personal site.

Configure AWS credentials before running anything:

```bash
aws configure
# or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_DEFAULT_REGION
```

---

## First deploy

1. **Initialise Terraform** (download providers, set up state):

   ```bash
   cd terraform
   terraform init
   ```

2. **Review and apply** the infrastructure plan:

   ```bash
   terraform plan
   terraform apply
   ```

   Terraform will create an S3 bucket, a CloudFront distribution, and all supporting resources. At the end it prints the live URL:

   ```
   cloudfront_url = "https://d1234abcd.cloudfront.net"
   ```

3. **Upload the site files**:

   ```bash
   ./terraform/deploy.sh
   ```

   The script syncs `src/` to S3 and invalidates the CloudFront cache automatically.

---

## Deploying site changes

After editing any file inside `src/`, run:

```bash
./terraform/deploy.sh
```

That's it. The script reads the bucket name and distribution ID from Terraform outputs — no hardcoded values anywhere.

---

## Adding a new talk

Edit `src/data/talks.json`. Each entry is a JSON object:

```jsonc
{
  "year": "2027",          // Display year — set to null to omit
  "event": "XConf APAC",  // Conference name
  "location": "Singapore", // City / country
  "title": "Talk title",   // Required
  "description": "One or two sentences about what the talk covered.",
  "recordingUrl": null,    // Full URL string, or null
  "slidesUrl": null        // Full URL string, or null
}
```

Then run `./terraform/deploy.sh`.

---

## Adding a new article

Edit `src/data/articles.json`. Each entry:

```jsonc
{
  "title": "Article title",           // Required
  "subtitle": "One-line description", // Shown below the title
  "url": "https://...",               // Link to the article, or null
  "date": "2027"                      // Display date string
}
```

Then run `./terraform/deploy.sh`.

---

## Adding a new work item

Edit `src/data/work.json`. Each entry:

```jsonc
{
  "title": "Project or product name", // Required
  "org": "Organisation",              // e.g. "Thoughtworks" or "Creator"
  "period": "2027–",                  // Date range string, or null
  "description": "...",               // 1–3 sentences, or null
  "tags": ["Tag one", "Tag two"]      // Array of short label strings
}
```

Then run `./terraform/deploy.sh`.

---

## Custom domain

To serve the site from your own domain (e.g. `vijaymore.com`):

1. Make sure the domain's **hosted zone already exists in Route 53** (created when you registered or transferred the domain).

2. Set the `TF_VAR_domain_name` environment variable before running `terraform apply`:

   ```bash
   export TF_VAR_domain_name="vijaymore.com"
   terraform apply
   ```

   Terraform will:
   - Issue an ACM certificate in `us-east-1` (required by CloudFront)
   - Create DNS validation CNAME records in Route 53
   - Wait for ACM to validate the certificate
   - Add `A` and `AAAA` alias records pointing to CloudFront for both `vijaymore.com` and `www.vijaymore.com`

3. Run `./terraform/deploy.sh` to upload the files and invalidate the cache.

> **Note:** ACM certificate validation typically completes within a few minutes but can occasionally take up to 30 minutes. Terraform waits automatically.

---

## Infrastructure overview

| Resource | Details |
|---|---|
| **S3 bucket** | Private. All public access blocked. Files served only via CloudFront OAC. |
| **CloudFront** | HTTPS-only. Redirect HTTP → HTTPS. Gzip / Brotli compression enabled. 404s rewritten to `index.html` (SPA routing). |
| **ACM certificate** | Provisioned in `us-east-1` (CloudFront requirement). DNS validation via Route 53. Only created when `domain_name` is set. |
| **Route 53** | `A` + `AAAA` alias records for apex and `www`. Only created when `domain_name` is set. |

---

## Terraform variables

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `ap-southeast-1` | Primary AWS region. |
| `domain_name` | `null` | Custom domain. Null = use CloudFront URL. |
| `project_name` | `vijay-website` | Prefix for resource names. |
