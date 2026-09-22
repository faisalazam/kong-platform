import json
import urllib.request


def lambda_handler(event, context):
    url = "http://kong:8000/poc/localstack/test"

    with urllib.request.urlopen(url, timeout=10) as response:
        body = response.read().decode("utf-8")

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "status": response.status,
                    "response": body,
                }
            ),
        }
