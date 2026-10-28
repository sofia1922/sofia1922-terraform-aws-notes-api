# Simple Notes API — Terraform + AWS

A minimal serverless REST API built using AWS-compatible services and deployed locally with Terraform and Floci.

## Technologies

- Terraform — Infrastructure as Code
- AWS API Gateway — HTTP API endpoint
- AWS Lambda — Python backend
- Amazon S3 — JSON data storage
- Floci — Local AWS emulator
- Docker — Containerized environment

## Architecture

Client → API Gateway → AWS Lambda → Amazon S3

## API Endpoint

**Method:** GET

**Path:** `/notes`

**Local URL:**

`http://localhost:4566/restapis/<api-id>/dev/_user_request_/notes`

The API returns a JSON object containing notes stored in an S3 bucket.

## Deployment

1. Install Docker Desktop and Terraform.
2. Start the local AWS emulator:

   `docker compose up -d`

3. Initialize Terraform:

   `terraform init`

4. Deploy the infrastructure:

   `terraform apply`

5. Confirm deployment by typing `yes`.

6. Test the API:

   `curl.exe -i "$(terraform output -raw api_url)"`

## Example Response

```json
{
  "notes": [
    {
      "id": 1,
      "title": "First note",
      "content": "Hello from AWS Lambda!"
    },
    {
      "id": 2,
      "title": "DevOps Lab",
      "content": "Terraform, API Gateway, Lambda and S3"
    },
    {
      "id": 3,
      "title": "Cloud Computing",
      "content": "This data is stored in Amazon S3"
    }
  ]
}
```

## Infrastructure

Terraform automatically provisions:

- S3 bucket with `notes.json`
- IAM role and access policy
- AWS Lambda function
- API Gateway REST API
- GET `/notes` endpoint
- API Gateway deployment and stage

## Testing

The infrastructure was successfully deployed using Terraform.

- Resources created: 12
- HTTP response: 200 OK
- Data source: S3
- Runtime: Python 3.12

**Note:** This project runs locally using Floci. The API URL is accessible only when the Docker environment is running on the local machine.