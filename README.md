# Production-Ready DevOps Pipeline

A production-grade Node.js application with full CI/CD automation, containerization, and AWS infrastructure provisioned via Terraform.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Running Locally](#running-locally)
- [Running Tests](#running-tests)
- [Accessing the App](#accessing-the-app)
- [Deploying the Application](#deploying-the-application)
- [Project Structure](#project-structure)
- [Key Decisions](#key-decisions)
- [Cost Estimate](#cost-estimate)

---

## Architecture Overview

```
GitHub Push
    │
    ▼
GitHub Actions
    ├── Install & Test
    ├── Build & Push image → ghcr.io
    ├── Manual Approval Gate (production environment)
    └── Trigger AWS ASG Instance Refresh (rolling, zero-downtime)
                │
                ▼
    Application Load Balancer (HTTP:80)
                │
                ▼
    EC2 Instance (public subnet)
    └── Docker network: appnet
        ├── devops_app container (port 3000, non-root user)
        └── postgres container (port 5432)
```

---

## Prerequisites

| Tool | Version |
|---|---|
| Node.js | v20+ |
| Docker | v24+ |
| Docker Compose | v2+ |
| Terraform | v1.6+ |
| AWS CLI | v2+ |

---

## Running Locally

### Option A — Node.js directly

```bash
cd src

# Install dependencies
npm install

# Create a local .env file
cp .env.example .env

# Start the app
npm start

# Or with hot reload
npm run dev
```

### Option B — Docker Compose (recommended)

```bash
cp .env.example .env

# Build and start all services (app + postgres)
docker compose up --build -d

# Check all services are healthy
docker compose ps

# View logs
docker compose logs -f app
```

App will be available at `http://localhost:3000` either way.

### Environment Variables

Create a `.env` file in the project root — never commit this file:

```env
NODE_ENV=development
PORT=3000
DB_NAME=yourappdb
DB_USER=yourappuser
DB_PASSWORD=your_db_password
```

---

## Running Tests

```bash
cd src
npm test
```

Tests cover:

| Test | Endpoint | Assertion |
|---|---|---|
| Health check | `GET /health` | 200, status field exists |
| Status check | `GET /status` | 200, status field exists |
| Process valid data | `POST /process` | 200, processed: true |
| Process missing data | `POST /process` | 400 error |

> Jest automatically sets `NODE_ENV=test` during test runs, overriding any value in your `.env`. 
---

## Accessing the App

### Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/health` | GET | Health check — used by ALB target group |
| `/status` | GET | App status, uptime, memory usage |
| `/process` | POST | Process a data payload |

### Locally

```bash
curl http://localhost:3000/health

curl http://localhost:3000/status

curl -X POST http://localhost:3000/process \
  -H "Content-Type: application/json" \
  -d '{"data": "hello world"}'
```

### Production

After deploying, retrieve the ALB DNS from Terraform outputs:

```bash
cd terraform
terraform output alb_dns_name
```

Then hit the app at `http://<alb_dns_name>`:

```bash
curl http://<alb_dns_name>/health
curl http://<alb_dns_name>/status
curl -X POST http://<alb_dns_name>/process \
  -H "Content-Type: application/json" \
  -d '{"data": "hello world"}'
```

---

## Deploying the Application

### First-Time Setup

#### 1. Configure GitHub Secrets

In your repo go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `DB_PASSWORD` | PostgreSQL password |

#### 2. Configure GitHub Environment (Manual Approval)

1. Go to **Settings → Environments**
2. Create an environment named `production`
3. Enable **Required reviewers** and add yourself
4. Every push to `main` will now pause and wait for your approval before deploying

#### 3. Provision Infrastructure

```bash
cd terraform

# Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars

# Initialise providers and remote state
terraform init

# Preview what will be created
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

Note the `alb_dns_name` output — this is your app's URL.

> The first time you run `terraform apply`, the EC2 instance pulls the Docker image from GHCR on startup via `user_data.sh`. Make sure at least one successful CI/CD run has pushed an image to GHCR before applying.

#### 4. Subsequent Deployments

Every push to `main` automatically:

1. Runs tests
2. Builds and pushes a new Docker image to GHCR tagged with `latest` and the commit SHA
3. Pauses for manual approval
4. Triggers a rolling ASG instance refresh — zero downtime

> If the ASG does not exist yet (infrastructure not provisioned), the deploy step detects this and exits gracefully with a message to run `terraform apply` first.

### Rollback

To roll back to a previous build, update `app_image` in `terraform.tfvars` to a specific commit SHA tag:

```hcl
app_image = "ghcr.io/gerald-izuchukwu/production-ready-devops-pipeline:sha-b44a69e"
```

Then re-run:

```bash
terraform apply
```

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml               # GitHub Actions pipeline
├── src/
│   ├── app.js                      # Express application
│   ├── app.test.js                 # Jest tests
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── docker-compose.yml          # Local dev stack (app + postgres)
│   ├── package.json
│   ├── package-lock.json
│   └── .env.example
├── terraform/
│   ├── main.tf                     # Root module
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars            # gitignored — fill in locally
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/
│       ├── security_groups/
│       ├── alb/
│       └── ec2/                    # includes user_data.sh
└── README.md
```

---

## Key Decisions

### Security

**Non-root container user**
The Docker container runs as a dedicated non-root user (`devuser`) created at build time. This is security best practice.

**Secrets management**
No secrets are stored in code, Dockerfiles, or Terraform files. All sensitive values (AWS credentials, DB password) are stored in GitHub Actions Secrets and injected at runtime as environment variables. `terraform.tfvars` and `.env` are gitignored.

**Least-privilege security groups**
EC2 instances only accept traffic on port 3000 from the ALB security group — not from the public internet. The ALB is the only publicly exposed entry point. PostgreSQL is only accessible from within the Docker bridge network on the instance itself and is never exposed externally.

**SSM over SSH**
EC2 instances are configured with the SSM managed instance policy, enabling shell access via AWS Systems Manager without opening port 22 or managing SSH keys.

**HTTPS / SSL**
SSL termination via AWS ACM is supported by the architecture but was omitted from this deployment as it requires an owned domain for DNS validation. To enable it:
1. Uncomment the `aws_acm_certificate` resource in `terraform/main.tf`
2. Add a `domain_name` variable to `terraform.tfvars`
3. Run `terraform apply`
4. Add the output `acm_validation_records` as CNAME records in your DNS provider

---

### CI/CD

**PR safety**
The pipeline runs tests on every pull request but does not build or push an image. Image pushes only happen on merges to `main`, keeping GHCR clean.

**Commit SHA tagging**
Every image is tagged with both `latest` and the commit SHA (e.g. `sha-b44a69e`). `latest` always points to the current build while every previous build remains pullable for rollbacks.

**Layer caching**
Docker layer caching via GitHub Actions cache (`type=gha`) reduces build times on subsequent runs by reusing unchanged layers.

**Manual approval gate**
A required reviewer step using GitHub Environments prevents any code from reaching production without explicit human sign-off, even if all tests pass.

**Graceful deploy step**
The instance refresh step checks whether the ASG exists before attempting a refresh. If infrastructure has not yet been provisioned via Terraform, the step exits cleanly with an informational message rather than failing the pipeline.

---

### Infrastructure

**Modular Terraform**
Infrastructure is split into focused modules (`vpc`, `security_groups`, `alb`, `ec2`) making each component independently readable and reusable. Modules communicate only through explicit input variables and outputs — resources are private to their module by default.

**Remote state with locking**
Terraform state is stored in S3 with DynamoDB locking to prevent concurrent applies from corrupting state in team environments.

**Zero-downtime rolling deployments**
The ASG is configured with a minimum of 2 instances and an instance refresh policy (`MinHealthyPercentage: 50`). When a new image is deployed, AWS replaces instances one at a time, keeping at least one healthy instance serving traffic throughout.

**PostgreSQL on EC2 (cost trade-off)**
PostgreSQL runs as a Docker container on the same EC2 instance as the app, connected via a Docker bridge network (`appnet`). This mirrors the local docker-compose setup and avoids the ~$15/month cost of RDS. In a production environment with stricter requirements, PostgreSQL would be replaced with AWS RDS for managed backups, automated failover, and high availability.


**Health-check driven traffic**
The ALB target group uses the `/health` endpoint to determine instance health. The ASG uses `ELB` health check type, meaning unhealthy instances are automatically terminated and replaced without manual intervention.

---

## Cost Estimate

| Resource | Monthly Cost |
|---|---|
| EC2 t3.micro × 2 | ~$15 |
| Application Load Balancer | ~$7 |
| S3 + DynamoDB (Terraform state) | ~$1 |
| Data transfer | ~$1 |
| **Total** | **~$24/month** |

> NAT Gateway (~$32/month) and RDS (~$15/month) are intentionally excluded in favour of a simplified, cost-effective setup appropriate for this assessment. Both would be included in a full production deployment.