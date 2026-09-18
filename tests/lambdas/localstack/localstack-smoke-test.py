import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "content-type": "application/json"
        },
        "body": json.dumps(
            {
                "message": "hello from localstack",
                "event": event,
            }
        ),
    }
