import json
import os

import boto3

cloudtrail = boto3.client("cloudtrail")
sns = boto3.client("sns")

TRAIL_NAME = os.environ["TRAIL_NAME"]
ALERT_TOPIC_ARN = os.environ["ALERT_TOPIC_ARN"]


def lambda_handler(event, context):
    """Restart CloudTrail when a StopLogging event is detected."""

    detail = event.get("detail", {})
    user_identity = detail.get("userIdentity", {})

    actor = user_identity.get("arn", "Unknown identity")
    event_time = detail.get("eventTime", "Unknown time")
    source_ip = detail.get("sourceIPAddress", "Unknown IP")

    # Containment action: restore audit logging immediately.
    cloudtrail.start_logging(Name=TRAIL_NAME)

    # Send a clear incident-response notification.
    message = (
        "SecureCloud Sentinel automatically restored CloudTrail logging.\n\n"
        f"Trail: {TRAIL_NAME}\n"
        "Detected action: StopLogging\n"
        f"Actor: {actor}\n"
        f"Source IP: {source_ip}\n"
        f"Event time: {event_time}\n\n"
        "Action performed: CloudTrail StartLogging was called automatically."
    )

    sns.publish(
        TopicArn=ALERT_TOPIC_ARN,
        Subject="SecureCloud Sentinel - CloudTrail restored",
        Message=message,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "CloudTrail logging restored successfully",
                "trail_name": TRAIL_NAME,
            }
        ),
    }