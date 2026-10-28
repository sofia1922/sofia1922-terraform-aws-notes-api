
import json
import boto3
import os

s3 = boto3.client(
    "s3",
    endpoint_url=os.environ.get("S3_ENDPOINT_URL")
)

def lambda_handler(event, context):
    try:
        bucket_name = os.environ["BUCKET_NAME"]

        response = s3.get_object(
            Bucket=bucket_name,
            Key="notes.json"
        )

        notes = json.loads(
            response["Body"].read().decode("utf-8")
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(notes)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            })
        }
