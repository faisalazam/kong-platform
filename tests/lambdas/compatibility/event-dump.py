"""
PURPOSE
-------
Dumps the complete Lambda event received from Kong.

Used to compare:

  Kong awsgateway_compatible=true

vs

  Real API Gateway events

Relevant curl:

  curl -i 'http://localhost:8000/poc/event-dump'

Expected:

  Full event JSON payload.
"""

import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps(
            event,
            indent=2,
            sort_keys=True,
        ),
    }
