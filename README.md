# fraud-detector-infra-aws

Infrastructure as code (Terraform) for the shared AWS resources of the **fraud-detector** system - a portfolio project demonstrating Java + AWS + event-driven architecture + asynchronous processing + NoSQL persistence + decoupled notifications.

## Where This Repository Fits

The system is divided into three repositories:

| Repository | Responsibility |
|---|---|
| `fraud-detector-api` | Java/Spring Boot API. Validates transactions and publishes them to SQS. It **never** decides whether a transaction is suspicious. |
| `fraud-detector-lambda` | Consumes the SQS queue, queries the user's history in DynamoDB, applies fraud rules, persists the result, and publishes an SNS alert when suspicious. |
| **`fraud-detector-infra-aws`** (this repository) | Terraform for the shared infrastructure: DynamoDB tables, SQS queue, and SNS topic. |

This repository **does not contain** the Lambda-specific infrastructure (IAM role, function, and trigger). That infrastructure lives in the `fraud-detector-lambda` repository, which references these resources by name through Terraform data sources. See that repository's `README.md` for details.

## What This Repository Creates

- **DynamoDB** - `users` table (`userId` key) and `transactions` table (`transactionId` key, with the `userId-occurredAt-index` GSI for user history and time-window queries)
- **SQS** - `transaction-queue` and dead-letter queue, with automatic redrive after 3 attempts
- **SNS** - `fraud-alerts` topic, with a configurable email subscription

## Structure

```
terraform/
├── dynamodb.tf
├── sqs.tf
├── sns.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── local.tfvars.example
└── local_override.tf.example
docker-compose.localstack.yml
```

## Deploy to Real AWS

Prerequisites: AWS credentials configured (`aws configure` or environment variables), with permission to create DynamoDB, SQS, SNS, and **IAM** resources (the Lambda creates its own IAM role in its repository, but the user or role running Terraform must be allowed to manage these services).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

After applying, confirm the SNS subscription. An email with a confirmation link will be sent, and alerts will only work after confirmation.

Make sure `local_override.tf` **does not exist** in the directory before running this. Its presence redirects the provider to LocalStack. See the section below.

## Local Development with LocalStack

The local environment runs Terraform against LocalStack without creating resources in your AWS account. The `local_override.tf` file redirects services to `http://localhost:4566` and uses dummy credentials accepted by LocalStack.

### Prerequisites

- Docker Desktop running with Docker Compose support
- Terraform `>= 1.7`
- Git to clone the repository

AWS credentials are not required for the local environment.

### Start the Infrastructure

From the repository root, start LocalStack:

```bash
docker compose -f docker-compose.localstack.yml up -d
```

Confirm that the container is healthy:

```bash
docker compose -f docker-compose.localstack.yml ps
curl http://localhost:4566/_localstack/health
```

Then create the local files from the examples and apply the infrastructure:

```bash
cd terraform
cp local_override.tf.example local_override.tf
cp local.tfvars.example local.tfvars

terraform init
terraform validate
terraform plan -var-file=local.tfvars
terraform apply -var-file=local.tfvars
```

In PowerShell, use these equivalent copy commands:

```powershell
Copy-Item local_override.tf.example local_override.tf
Copy-Item local.tfvars.example local.tfvars
```

The `local_override.tf`, `local.tfvars`, Terraform state, and LocalStack data files are local and already protected by `.gitignore`. Never add real credentials or email addresses to `.example` files before publishing them.

### Inspect the Resources

After `apply`, inspect the Terraform outputs:

```bash
terraform output
terraform output transaction_queue_url
terraform output users_table_name
terraform output transactions_table_name
terraform output fraud_alerts_topic_arn
```

You can also inspect the services directly in LocalStack using the AWS CLI with dummy credentials:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws dynamodb list-tables --endpoint-url=http://localhost:4566
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws sqs list-queues --endpoint-url=http://localhost:4566
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws sns list-topics --endpoint-url=http://localhost:4566
```

### Stop and Recreate

To remove the Terraform resources and stop LocalStack:

```bash
terraform destroy -var-file=local.tfvars
cd ..
docker compose -f docker-compose.localstack.yml down
```

To also delete data persisted by LocalStack, remove the `.localstack/` directory after stopping the container. The environment will be recreated from scratch on the next run.

To point to real AWS again, remove `local_override.tf` before running Terraform. Use the deployment flow from the previous section and never run `terraform apply` while the local override is present.

**Apply order between repositories**: this repository must be applied **before** `fraud-detector-lambda`, because the Lambda looks up the queue, tables, and topic by name through data sources. If they do not exist yet, the Lambda apply fails with a resource-not-found error.

## Variables

| Variable | Description | Required |
|---|---|---|
| `aws_region` | AWS region | No (default `us-east-1`) |
| `environment` | `dev` or `prod` | Yes |
| `project_name` | Prefix used in all resource names | No (default `fraud-detector`) |
| `alert_email` | Email address that receives fraud alerts | Yes |

`project_name` and `environment` **must exactly match** the values used in `fraud-detector-lambda`. This is how that repository's data sources find the resources created here.

## Outputs

After applying, use `terraform output` to get the values required by the API and Lambda (queue URL, table names, and topic ARN):

```bash
terraform output transaction_queue_url
terraform output users_table_name
terraform output transactions_table_name
terraform output fraud_alerts_topic_arn
```

## About `.gitignore`

`*.tfvars` (except `.example` files), `local_override.tf` (except the `.example` file), and Terraform state files (`*.tfstate*`) are never committed. They may contain sensitive or machine-specific values such as real email addresses, credentials, and provisioned infrastructure state. Only the `.example` files are versioned as templates.
