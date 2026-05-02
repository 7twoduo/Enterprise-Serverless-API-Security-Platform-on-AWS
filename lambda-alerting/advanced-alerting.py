import json
import os
from datetime import datetime, timezone

import boto3


sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
PROJECT_NAME = os.environ.get("PROJECT_NAME", "serverless-api")


def get_solution(alarm_name, metric_name, namespace):
    alarm_lower = alarm_name.lower()
    metric_lower = (metric_name or "").lower()
    namespace_lower = (namespace or "").lower()

    if "5xx" in alarm_lower or metric_lower == "5xxerror":
        return {
            "summary": "API Gateway is returning 5XX server errors.",
            "steps": [
                "Check API Gateway access logs for the requestId, route, status code, and response latency.",
                "Check the Lambda function logs during the same time window.",
                "Verify the Lambda proxy response includes statusCode, headers, and body.",
                "Confirm API Gateway has permission to invoke the Lambda function.",
                "Review recent Terraform changes to API Gateway integrations, deployments, or Lambda handlers."
            ]
        }

    if "latency" in alarm_lower or metric_lower == "latency":
        return {
            "summary": "API Gateway latency is higher than expected.",
            "steps": [
                "Check API Gateway access logs for routes with high responseLatency.",
                "Check Lambda Duration metrics for the backend function.",
                "Look for slow code paths, large HTML responses, cold starts, or downstream delays.",
                "Consider increasing Lambda memory if duration is consistently high.",
                "Check whether throttling, WAF inspection, or backend errors are slowing responses."
            ]
        }

    if "lambda" in alarm_lower and "error" in alarm_lower:
        return {
            "summary": "A Lambda function is throwing runtime errors.",
            "steps": [
                "Open the Lambda CloudWatch log group for the function named in the alarm.",
                "Search for ERROR, Runtime.ImportModuleError, timeout, permission denied, or handler mismatch.",
                "Confirm the handler name matches the deployed file and function name.",
                "Confirm the zip package contains index.py or index.js at the root.",
                "Redeploy after fixing the code or Terraform package settings."
            ]
        }

    if "throttle" in alarm_lower or "throttl" in metric_lower:
        return {
            "summary": "The API or Lambda is being throttled.",
            "steps": [
                "Check API Gateway usage plan and stage throttling settings.",
                "Check Lambda reserved concurrency and account concurrency limits.",
                "Review recent traffic spikes in CloudWatch metrics.",
                "Increase throttling limits only if the backend can safely handle the traffic.",
                "Use WAF rate limits to block abusive clients if needed."
            ]
        }

    if "waf" in alarm_lower or "blocked" in alarm_lower:
        return {
            "summary": "AWS WAF is blocking or rate-limiting requests.",
            "steps": [
                "Review WAF sampled requests to identify the rule that blocked traffic.",
                "Check whether the request matched SQLi, KnownBadInputs, CommonRuleSet, or rate-limit rules.",
                "Confirm the blocked request is malicious before tuning exclusions.",
                "If legitimate traffic is blocked, create a narrow exception instead of disabling the full rule group.",
                "Review WAF logs in CloudWatch for source IP, URI, and rule match details."
            ]
        }

    if "4xx" in alarm_lower or metric_lower == "4xxerror":
        return {
            "summary": "API Gateway is returning 4XX client errors.",
            "steps": [
                "Check whether clients are missing the x-api-key header.",
                "Confirm the usage plan is attached to the correct API stage.",
                "Check whether the request path and method are valid.",
                "Review API Gateway access logs for 403, 404, or 429 status codes.",
                "If 429 errors are present, review throttling and quota settings."
            ]
        }

    return {
        "summary": "A monitored API alarm changed to ALARM state.",
        "steps": [
            "Open the CloudWatch alarm details and review the metric, threshold, and timestamp.",
            "Review API Gateway access logs around the alarm timestamp.",
            "Review Lambda logs for backend errors.",
            "Review WAF logs if the request may have been blocked.",
            "Check recent Terraform, Lambda, API Gateway, WAF, or usage plan changes."
        ]
    }


def format_dimensions(dimensions):
    if not dimensions:
        return "None"

    lines = []

    for item in dimensions:
        name = item.get("name", "Unknown")
        value = item.get("value", "Unknown")
        lines.append(f"- {name}: {value}")

    return "\n".join(lines)


def extract_metric_info(detail):
    configuration = detail.get("configuration", {})
    metrics = configuration.get("metrics", [])

    metric_name = "Unknown"
    namespace = "Unknown"
    dimensions = []

    if metrics:
        first_metric = metrics[0]
        metric_stat = first_metric.get("metricStat", {})
        metric = metric_stat.get("metric", {})

        metric_name = metric.get("name", "Unknown")
        namespace = metric.get("namespace", "Unknown")
        dimensions = metric.get("dimensions", [])

    return metric_name, namespace, dimensions


def lambda_handler(event, context):
    print("Incoming EventBridge event:", json.dumps(event))

    detail = event.get("detail", {})

    alarm_name = detail.get("alarmName", "Unknown alarm")
    state = detail.get("state", {})
    previous_state = detail.get("previousState", {})

    new_state = state.get("value", "UNKNOWN")
    previous_state_value = previous_state.get("value", "UNKNOWN")
    reason = state.get("reason", "No reason provided")

    region = event.get("region", "Unknown")
    account = event.get("account", "Unknown")
    timestamp = event.get("time", datetime.now(timezone.utc).isoformat())

    metric_name, namespace, dimensions = extract_metric_info(detail)
    solution = get_solution(alarm_name, metric_name, namespace)

    subject = f"🚨 {PROJECT_NAME} Alarm: {alarm_name}"

    suggested_fix_steps = "\n".join(
        [f"{index + 1}. {step}" for index, step in enumerate(solution["steps"])]
    )

    message = f"""
🚨 PRODUCTION API ALARM TRIGGERED

Project:
{PROJECT_NAME}

Alarm:
{alarm_name}

State:
{previous_state_value} → {new_state}

Region:
{region}

AWS Account:
{account}

Time:
{timestamp}

Metric:
{namespace}/{metric_name}

Dimensions:
{format_dimensions(dimensions)}

Reason:
{reason}

Possible Cause:
{solution["summary"]}

Suggested Fix:
{suggested_fix_steps}

Recommended Investigation Flow:
1. Open the CloudWatch alarm: {alarm_name}
2. Check API Gateway access logs for the same timestamp.
3. Check Lambda logs for backend runtime errors.
4. Check WAF logs if the request may have been blocked.
5. Check recent Terraform changes to API Gateway, Lambda, usage plans, WAF, or permissions.

This alert was generated dynamically by the advanced alerting Lambda.
"""

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject[:100],
        Message=message
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Formatted alert sent",
            "alarm": alarm_name,
            "state": new_state
        })
    }