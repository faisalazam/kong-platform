"""
PURPOSE
-------
Replicates the successful Chalice compatibility fix.

Relevant curl:

  curl -i 'http://localhost:8000/poc/chalice-fixed'

Expected:

  Success
"""

import json


def normalize_kong_event(event):
    event.setdefault("stageVariables", None)
    event.setdefault("resource", event.get("path"))

    return event


def lambda_handler(event, context):
    event = normalize_kong_event(event)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "stageVariables": event["stageVariables"],
                "resource": event["resource"],
            }
        ),
    }
