# Architecture Documentation

## Project: Enterprise Serverless API Security Platform on AWS

## Overview

This document explains the architecture for a production-inspired serverless REST API built on AWS.

The project exposes two API routes through Amazon API Gateway:

* `/py` — backed by a Python Lambda function
* `/js` — backed by a JavaScript/Node.js Lambda function

The API is protected by AWS WAF, requires API key access, applies usage plan throttling, writes access logs to CloudWatch, monitors failures with CloudWatch alarms, and sends formatted incident-style alerts through EventBridge, Lambda, and SNS.

The goal is to demonstrate how a small serverless API can be designed with real production patterns: security, observability, traffic control, alerting, and Infrastructure as Code.

---

## Architecture Goals

The architecture was designed around five practical goals:

1. **Secure API exposure** — expose Lambda functions through API Gateway while protecting the public entry point.
2. **Controlled client access** — require API keys and apply usage plan limits.
3. **Operational visibility** — capture request logs, Lambda logs, WAF logs, metrics, and alarms.
4. **Actionable alerting** — convert alarm events into readable messages with possible causes and suggested fixes.
5. **Repeatable deployment** — provision the full stack through Terraform.

---

## High-Level Architecture

```text
Client / Browser / curl
        ↓
Amazon API Gateway REST API
        ↓
AWS WAF Web ACL
        ↓
API Key Validation
        ↓
Usage Plan Throttling and Quota
        ↓
API Gateway Resource + Method
        ↓
Lambda Proxy Integration
        ↓
Python Lambda or JavaScript Lambda
        ↓
HTML Response Returned to Client
        ↓
CloudWatch Logs and Metrics
        ↓
CloudWatch Alarms
        ↓
EventBridge Alarm State Change Rule
        ↓
Advanced Alerting Lambda
        ↓
SNS Email Notification
```

---

## Architecture Diagram

> Save the architecture image in the repository at:
>
> `Evidence/01-architecture/architecture-diagram.png`

```text
                              ┌─────────────────────────────┐
                              │     Client / Browser / CLI   │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │   API Gateway REST API       │
                              │   Stage: prod                │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │          AWS WAF             │
                              │ Common Rules / SQLi / Rate   │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ API Key + Usage Plan         │
                              │ Throttling + Monthly Quota   │
                              └──────────────┬──────────────┘
                                             │
                   ┌─────────────────────────┴─────────────────────────┐
                   │                                                   │
                   ▼                                                   ▼
        ┌──────────────────────┐                          ┌──────────────────────┐
        │ /py API Resource      │                          │ /js API Resource      │
        │ ANY Method            │                          │ ANY Method            │
        └──────────┬───────────┘                          └──────────┬───────────┘
                   │                                                   │
                   ▼                                                   ▼
        ┌──────────────────────┐                          ┌──────────────────────┐
        │ Python Lambda         │                          │ JavaScript Lambda     │
        │ Dynamic HTML Response │                          │ Dynamic HTML Response │
        └──────────┬───────────┘                          └──────────┬───────────┘
                   │                                                   │
                   └─────────────────────────┬─────────────────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ CloudWatch Logs + Metrics   │
                              │ API / Lambda / WAF Logs     │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ CloudWatch Alarms           │
                              │ 5XX / Latency / Errors      │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ EventBridge Rule            │
                              │ Alarm State Change          │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ Advanced Alerting Lambda    │
                              │ Formats Cause + Fix Steps   │
                              └──────────────┬──────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │ SNS Topic + Email Alert     │
                              └─────────────────────────────┘
```

---

## Core Components

## 1. Amazon API Gateway REST API

API Gateway acts as the public HTTP entry point for the application.

It provides:

* REST API routing
* `/py` and `/js` resources
* `ANY` HTTP method support
* Lambda proxy integration
* API key enforcement
* stage-level method settings
* access logging
* throttling controls

The API is deployed to a `prod` stage. The stage is what makes the deployed API callable through a URL such as:

```text
https://<api-id>.execute-api.<region>.amazonaws.com/prod/py
https://<api-id>.execute-api.<region>.amazonaws.com/prod/js
```

---

## 2. API Gateway Deployment and Stage

API Gateway REST APIs require a deployment before routes become callable.

* **API resources, methods, and integrations** define the API blueprint.
* **Deployment** creates a snapshot of that blueprint.
* **Stage** serves that snapshot through a stable URL path such as `/prod`.

The Terraform deployment uses a trigger hash so changes to routes, methods, or integrations force a new deployment.

This prevents a common issue where Terraform changes API Gateway resources but the live stage still serves an older deployment.

---

## 3. Lambda Proxy Integrations

Both `/py` and `/js` use Lambda proxy integration.

This means API Gateway forwards the full HTTP request into Lambda as an event containing:

* request path
* HTTP method
* headers
* query string parameters
* request context
* source IP metadata

The Lambda function then returns the full HTTP response:

```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "text/html; charset=utf-8"
  },
  "body": "<html>...</html>"
}
```

This gives the Lambda functions full control over the response body and headers.

---

## 4. Python Lambda Function

The Python Lambda backs the `/py` route.

Responsibilities:

* receive the API Gateway event
* read query string parameters such as `name`
* derive runtime request context
* generate a styled HTML response
* return the response through Lambda proxy format

The function is deployed with a handler similar to:

```text
index.lambda_handler
```

That means Lambda loads `index.py` and runs the `lambda_handler` function.

---

## 5. JavaScript Lambda Function

The JavaScript Lambda backs the `/js` route.

Responsibilities:

* receive the API Gateway event
* read query string parameters such as `name`
* derive runtime request context
* generate a styled HTML response
* return the response through Lambda proxy format

The function is deployed with a handler similar to:

```text
index.handler
```

That means Lambda loads `index.js` and runs the exported `handler` function.

---

## 6. AWS WAF

AWS WAF is attached to the API Gateway stage.

The WAF web ACL includes:

* AWS Managed Common Rule Set
* AWS Managed Known Bad Inputs Rule Set
* AWS Managed SQL Injection Rule Set
* rate-based rule by source IP

WAF provides the first layer of request inspection before requests are processed by the backend Lambda integrations.

The purpose is to reduce exposure to common web attack patterns and abusive request behavior.

---

## 7. API Key and Usage Plan

The API requires clients to send an API key using the `x-api-key` header.

Example:

```bash
curl -H "x-api-key: YOUR_API_KEY" \
"https://<api-id>.execute-api.<region>.amazonaws.com/prod/py?name=Gavin"
```

The usage plan applies:

* rate limiting
* burst limiting
* monthly quota

This models controlled client access for an internal service, partner application, or approved consumer.

API keys are not full user authentication. They are used here for client identification, usage control, and throttling.

---

## 8. CloudWatch Logging

The project writes logs at multiple layers.

| Log Source                  | Purpose                                                                                        |
| --------------------------- | ---------------------------------------------------------------------------------------------- |
| **API Gateway Access Logs** | Tracks request ID, source IP, route, method, status code, latency, user agent, and API key ID. |
| **Lambda Logs**             | Captures function execution details, incoming events, runtime issues, and application logs.    |
| **WAF Logs**                | Records inspected requests, blocked requests, and matched WAF rules.                           |

This makes it possible to investigate failures across the full request path.

---

## 9. CloudWatch Alarms

CloudWatch alarms monitor production-style failure conditions, including:

* API Gateway 5XX errors
* high API Gateway latency
* Python Lambda errors
* JavaScript Lambda errors

These alarms represent core health indicators for a serverless API.

---

## 10. EventBridge Alarm Routing

CloudWatch alarm state changes are captured by an EventBridge rule.

Instead of sending raw CloudWatch alarm emails directly to SNS, EventBridge routes `ALARM` state changes to a Lambda function.

This allows alert messages to be customized before they are sent.

---

## 11. Advanced Alerting Lambda

The advanced alerting Lambda receives the CloudWatch alarm event from EventBridge.

It extracts:

* alarm name
* alarm state
* previous state
* reason
* metric namespace
* metric name
* dimensions
* AWS account
* region
* timestamp

Then it maps the alarm type to a possible cause and suggested troubleshooting steps.

Example alert categories:

* API Gateway 5XX errors
* API Gateway high latency
* Lambda runtime errors
* throttling events
* WAF blocked request patterns
* API Gateway 4XX client errors

The formatted message is then published to SNS.

---

## 12. Amazon SNS

SNS delivers the final alert notification by email.

The email subscription must be confirmed before notifications are delivered.

This completes the production-style monitoring path:

```text
CloudWatch Alarm → EventBridge → Alerting Lambda → SNS → Email
```

---

## Request Lifecycle

## Normal API Request

1. A client sends a request to `/prod/py` or `/prod/js`.
2. AWS WAF evaluates the request against managed rules.
3. API Gateway checks whether the request includes a valid `x-api-key` header.
4. API Gateway applies usage plan throttling and quota controls.
5. API Gateway routes the request to the correct resource and method.
6. Lambda proxy integration invokes the backend Lambda function.
7. Lambda generates a styled HTML response.
8. API Gateway returns the response to the client.
9. Logs are written to CloudWatch.

## Alerting Request Path

1. CloudWatch detects an alarm condition.
2. The alarm state changes to `ALARM`.
3. EventBridge captures the alarm state change event.
4. EventBridge invokes the advanced alerting Lambda.
5. The Lambda formats the alert message.
6. The Lambda publishes the formatted message to SNS.
7. SNS sends the email notification.

---

## Terraform Design

The infrastructure is managed through Terraform.

Major Terraform sections include:

* provider configuration
* local values
* Lambda IAM roles
* Lambda packaging
* API Gateway resources, methods, integrations, deployment, and stage
* Lambda permissions for API Gateway invocation
* WAF web ACL and rules
* WAF association with API Gateway stage
* CloudWatch log groups
* API Gateway account logging role
* API Gateway access logs
* method settings and throttling
* API key and usage plan
* CloudWatch alarms
* SNS topic and subscription
* EventBridge rule and target
* advanced alerting Lambda and IAM permissions

Terraform provides repeatability, reviewability, and a clean way to recreate the environment.

---

## Operational Troubleshooting Flow

## API Returns 403

Likely causes:

* missing `x-api-key` header
* invalid API key
* usage plan not attached to the API stage
* request blocked by WAF

Investigation path:

1. Confirm the request includes the `x-api-key` header.
2. Confirm the API key exists and is enabled.
3. Confirm the usage plan is attached to the correct API stage.
4. Check API Gateway access logs.
5. Check WAF logs for blocked requests.

## API Returns 500

Likely causes:

* Lambda runtime error
* handler mismatch
* malformed Lambda proxy response
* API Gateway permission issue
* broken integration mapping

Investigation path:

1. Check API Gateway access logs for the request ID and route.
2. Check Lambda logs for runtime errors.
3. Confirm Lambda handler settings.
4. Confirm the deployment package includes the correct root file.
5. Confirm API Gateway has permission to invoke Lambda.

## SNS Alert Not Received

Likely causes:

* email subscription not confirmed
* EventBridge rule not matching alarm event
* alerting Lambda failed
* Lambda lacks SNS publish permission

Investigation path:

1. Confirm SNS email subscription.
2. Check EventBridge rule target.
3. Check advanced alerting Lambda logs.
4. Confirm SNS publish IAM policy.
5. Test alarm state manually with `aws cloudwatch set-alarm-state`.

---

## Current Limitations

This architecture is production-inspired, not a complete enterprise platform.

Current limitations:

* no Cognito or user-level authentication
* no custom domain
* no OpenAPI specification
* no CI/CD pipeline
* no DynamoDB audit table
* no CloudWatch dashboard
* no multi-region failover
* no canary deployment strategy

These are intentional future improvements. The current architecture focuses on securing, monitoring, and operating a small serverless API foundation.

---

## Future Architecture Improvements

Recommended future enhancements:

1. Add Cognito or Lambda authorizer for real identity-based authentication.
2. Add a custom domain with ACM TLS certificate.
3. Add OpenAPI documentation for client-facing API contracts.
4. Add a CI/CD pipeline with Terraform validation and security scanning.
5. Add DynamoDB audit records for structured request history.
6. Add a CloudWatch dashboard for visual operations monitoring.
7. Add `/health` and `/status` routes.
8. Add canary deployment support for safer releases.
9. Split Terraform into modules and environments.
10. Add multi-region deployment and failover patterns.
