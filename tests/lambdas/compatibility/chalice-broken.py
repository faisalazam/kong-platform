"""
PURPOSE
-------
Replicates the Chalice failure discovered during the PoC.

Kong OSS 3.9.3 omits:

  stageVariables
  resource

This Lambda intentionally assumes those fields exist.

Relevant curl:

  curl -i 'http://localhost:8000/poc/chalice-broken'

Expected:

  Failure
"""

import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "stageVariables": event["stageVariables"],
                "resource": event["resource"],
            }
        ),
    }
