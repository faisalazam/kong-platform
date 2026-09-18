"""
PURPOSE
-------
Validates Kong route path handling.

Used to prove:

  strip_path: true

Relevant curl:

  curl -i 'http://localhost:8000/poc/echo-path/ad/groups'

Expected:

  {
    "path": "/ad/groups"
  }
"""

import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "path": event.get("path"),
                "httpMethod": event.get("httpMethod"),
            }
        ),
    }
