# Security Controls Documentation

## Project: Enterprise Serverless API Security Platform on AWS

## Overview

This document explains the security controls used in the serverless API platform.

The project uses Amazon API Gateway, AWS Lambda, AWS WAF, API keys, usage plans, IAM roles, CloudWatch logging, CloudWatch alarms, EventBridge, SNS, and Terraform to create a production-inspired API security design.

The purpose of this document is to show how the project reduces risk through layered security controls, operational visibility, and controlled access.

---

## Security Objective

The main security objective is to expose serverless API routes while applying practical controls around:

* public entry point protection
* API client access control
* abuse prevention
* least-privilege permissions
* logging and monitoring
* alerting and incident visibility
* repeatable infrastructure deployment

This project does not claim to be a complete enterprise security platform, but it demonstrates important security engineering patterns used in real cloud environments.

---

## Threat Scenario

The API is publicly reachable through API Gateway.

Potential risks include:

* unauthorized clients attempting to call API routes
* abusive clients sending too many requests
* malicious requests containing SQL injection or known bad input patterns
* unexpected API Gateway 4XX or 5XX errors
* Lambda runtime failures
* high latency affecting availability
* missing visibility during incidents
* weak operational response when alarms fire

The security design addresses these risks using WAF, API key controls, throttling, logging, alarms, and advanced alerting.

---

## Security Control Summary

| Security Area         | Control Implemented            | Purpose                                                                       |
| --------------------- | ------------------------------ | ----------------------------------------------------------------------------- |
| Public API Protection | AWS WAF web ACL                | Inspect and block risky request patterns before backend execution.            |
| Common Web Threats    | AWS managed rule groups        | Protect against common attacks, known bad inputs, and SQL injection attempts. |
| Abuse Prevention      | WAF rate-based rule            | Block or limit excessive requests from a single source IP.                    |
| Client Access Control | API Gateway API key            | Require approved clients to send an `x-api-key` header.                       |
| Traffic Governance    | Usage plan                     | Apply rate limits, burst limits, and monthly quotas.                          |
| Runtime Permissions   | IAM roles                      | Grant each service only the permissions needed for its role.                  |
| Request Visibility    | API Gateway access logs        | Record request metadata for investigation and troubleshooting.                |
| Function Visibility   | Lambda logs                    | Capture application behavior and runtime errors.                              |
| WAF Visibility        | WAF logs                       | Review blocked traffic and matched rules.                                     |
| Failure Detection     | CloudWatch alarms              | Detect API 5XX errors, latency, and Lambda failures.                          |
| Alert Notifications   | SNS                            | Send email alerts when monitored issues occur.                                |
| Actionable Alerts     | EventBridge + Lambda formatter | Convert raw alarm events into useful troubleshooting guidance.                |
| Repeatability         | Terraform                      | Build the environment consistently as code.                                   |

---

## Control 1 — AWS WAF Protection

## Purpose

AWS WAF protects the API Gateway stage before requests reach the backend Lambda functions.

It provides an application-layer inspection point for public API traffic.

## Implemented Rules

The WAF web ACL includes:

* AWS Managed Rules Common Rule Set
* AWS Managed Rules Known Bad Inputs Rule Set
* AWS Managed Rules SQLi Rule Set
* custom rate-based rule by source IP

## Risk Reduced

This helps reduce risk from:

* common web exploit patterns
* known malicious input patterns
* SQL injection attempts
* repeated abusive requests from the same source IP

## Interview Explanation

> “I attached AWS WAF to the API Gateway stage so requests are inspected before they reach Lambda. I used AWS managed rule sets for common threats, known bad inputs, and SQL injection, plus a rate-based rule to reduce abusive traffic.”

---

## Control 2 — API Key Enforcement

## Purpose

The `/py` and `/js` API routes require clients to provide an API key.

Clients must send the key in the request header:

```http
x-api-key: YOUR_API_KEY
```

## Risk Reduced

This reduces risk from:

* completely open public access
* unknown clients calling the API freely
* uncontrolled client usage
* lack of API consumer identification

## Important Note

API keys are not full user authentication.

They are best used for:

* identifying API clients
* applying usage plans
* enforcing throttling
* applying quotas

For full enterprise authentication, a future version should add Cognito, IAM authorization, or a Lambda authorizer.

## Interview Explanation

> “I used API keys to model controlled client access. The API key identifies approved clients and allows API Gateway to apply usage plan limits. I would not treat API keys as full identity authentication; for that I would add Cognito or a Lambda authorizer.”

---

## Control 3 — Usage Plan and Throttling

## Purpose

The API Gateway usage plan controls how much traffic an API client can send.

It applies:

* rate limit
* burst limit
* monthly quota

## Risk Reduced

This helps reduce risk from:

* accidental traffic spikes
* noisy clients
* backend overload
* excessive API consumption
* cost growth from uncontrolled calls

## Design Reasoning

WAF and usage plans serve different purposes:

| Layer                 | Purpose                                               |
| --------------------- | ----------------------------------------------------- |
| **WAF**               | Blocks malicious or suspicious traffic patterns.      |
| **Usage Plan**        | Controls approved client consumption.                 |
| **Method Throttling** | Applies runtime throttling behavior at the API stage. |

## Interview Explanation

> “I used both WAF rate protection and API Gateway throttling. WAF helps defend against abusive or suspicious traffic, while the usage plan controls legitimate client consumption through rate limits, burst limits, and quotas.”

---

## Control 4 — IAM Least Privilege

## Purpose

Each AWS service needs permissions to perform its specific job.

IAM roles are used to keep responsibilities separated.

## IAM Roles Used

| Role                          | Purpose                                                       |
| ----------------------------- | ------------------------------------------------------------- |
| Lambda execution role         | Allows Lambda functions to run and write logs to CloudWatch.  |
| API Gateway CloudWatch role   | Allows API Gateway to push logs to CloudWatch.                |
| Advanced alerting Lambda role | Allows the formatter Lambda to write logs and publish to SNS. |
| Lambda invoke permission      | Allows API Gateway to invoke the backend Lambda functions.    |
| EventBridge invoke permission | Allows EventBridge to invoke the alerting Lambda.             |

## Risk Reduced

This reduces risk from:

* overprivileged services
* unclear permissions
* broad manual access
* accidental access to unrelated AWS resources

## Interview Explanation

> “I separated IAM permissions by service responsibility. Lambda has logging permissions, API Gateway has a role to push logs to CloudWatch, API Gateway has explicit permission to invoke the backend Lambda functions, and the alerting Lambda only has permission to publish to the SNS topic it needs.”

---

## Control 5 — API Gateway Access Logs

## Purpose

API Gateway access logs capture request-level metadata.

Logged fields include:

* request ID
* extended request ID
* source IP
* request time
* HTTP method
* resource path
* full path
* response status
* protocol
* response length
* response latency
* user agent
* API key ID

## Risk Reduced

This improves detection and investigation for:

* failed requests
* suspicious clients
* high latency
* repeated 403 responses
* missing API key issues
* unexpected route behavior

## Interview Explanation

> “I enabled structured API Gateway access logs so I can trace requests by request ID, source IP, route, status code, latency, user agent, and API key ID. This makes troubleshooting much easier than relying only on Lambda logs.”

---

## Control 6 — Lambda Logs

## Purpose

Lambda logs capture function-level behavior.

They help answer questions such as:

* Did the Lambda receive the event?
* Did the function run successfully?
* Did the handler fail?
* Was there an import or packaging error?
* Did the function return the correct proxy response?

## Risk Reduced

Lambda logs reduce investigation time for:

* runtime errors
* handler mismatches
* malformed responses
* unexpected exceptions
* packaging mistakes

## Interview Explanation

> “Each Lambda function writes logs to CloudWatch. These logs help me troubleshoot runtime errors, request handling, and Lambda proxy response issues.”

---

## Control 7 — WAF Logs

## Purpose

WAF logs show inspected requests and rule matches.

They help identify:

* blocked requests
* rule group matches
* rate-limited IPs
* SQL injection attempts
* known bad input matches

## Risk Reduced

WAF logs improve security visibility by showing which requests were blocked or inspected before reaching the backend.

## Interview Explanation

> “I enabled WAF logging so blocked traffic can be reviewed. If a legitimate user is blocked, I can inspect which managed rule matched instead of blindly disabling protections.”

---

## Control 8 — CloudWatch Alarms

## Purpose

CloudWatch alarms detect operational problems.

The project includes alarms for:

* API Gateway 5XX errors
* API Gateway high latency
* JavaScript Lambda errors
* Python Lambda errors

## Risk Reduced

This reduces risk from silent failures.

Without alarms, failures may only be noticed after users complain.

## Interview Explanation

> “I added CloudWatch alarms so failures are not just logged; they are actively detected. The alarms watch for API 5XX errors, high latency, and Lambda runtime errors.”

---

## Control 9 — SNS Notifications

## Purpose

SNS sends email notifications when alerts are generated.

This creates a notification path for operational events.

## Risk Reduced

SNS reduces the chance that failures go unnoticed.

## Interview Explanation

> “SNS is used as the notification layer. When the alerting workflow generates a message, SNS sends it to the subscribed email address.”

---

## Control 10 — EventBridge and Advanced Alert Formatting

## Purpose

Default CloudWatch alarm emails can be hard to act on.

This project uses EventBridge to route alarm state changes to a Lambda formatter.

The formatter creates an alert message with:

* alarm name
* state transition
* region
* account
* timestamp
* metric name
* dimensions
* alarm reason
* possible cause
* suggested fix steps
* recommended investigation flow

## Risk Reduced

This improves response quality by making alerts more actionable.

Instead of receiving a raw alarm notification, the engineer receives troubleshooting guidance.

## Interview Explanation

> “I used EventBridge and a Lambda formatter to turn raw CloudWatch alarm events into incident-style messages. The Lambda checks the alarm type, maps it to a possible cause, adds troubleshooting steps, and sends the formatted alert through SNS.”

---

## Control 11 — Terraform Infrastructure as Code

## Purpose

Terraform manages the infrastructure as code.

This makes the environment:

* repeatable
* reviewable
* easier to destroy and recreate
* easier to document
* less dependent on manual console steps

## Risk Reduced

Terraform reduces risk from:

* configuration drift
* manual misconfiguration
* undocumented infrastructure
* inconsistent deployments

## Interview Explanation

> “I used Terraform so the entire API platform can be deployed consistently. That includes API Gateway, Lambda, WAF, CloudWatch, SNS, EventBridge, IAM, and usage plan resources.”

---

## Security Boundaries

## Boundary 1 — Public Client to API Gateway

The client is outside the AWS environment.

Controls at this boundary:

* API Gateway endpoint
* AWS WAF inspection
* API key requirement
* usage plan throttling

## Boundary 2 — API Gateway to Lambda

API Gateway invokes Lambda through explicit permission.

Controls at this boundary:

* Lambda invoke permission scoped to API Gateway
* Lambda proxy integration
* API Gateway deployment and stage controls

## Boundary 3 — Lambda to CloudWatch

Lambda writes logs to CloudWatch.

Controls at this boundary:

* Lambda execution role
* CloudWatch log group retention
* JSON log format

## Boundary 4 — EventBridge to Alerting Lambda

EventBridge invokes the alerting Lambda only when alarm state changes match the rule.

Controls at this boundary:

* EventBridge event pattern
* Lambda permission for EventBridge invoke

## Boundary 5 — Alerting Lambda to SNS

The alerting Lambda publishes formatted notifications to SNS.

Controls at this boundary:

* IAM policy scoped to SNS publish
* SNS topic subscription confirmation

---

## Common Security and Operational Scenarios

## Scenario 1 — Missing API Key

Expected behavior:

* client receives `403 Forbidden`
* API Gateway access logs show request metadata
* API does not invoke the backend Lambda function

Investigation:

1. Confirm the client sent the `x-api-key` header.
2. Confirm the API key is enabled.
3. Confirm the key is associated with the correct usage plan.
4. Confirm the usage plan is attached to the `prod` stage.

---

## Scenario 2 — WAF Blocks a Request

Expected behavior:

* request is blocked before backend Lambda execution
* WAF logs show the matched rule

Investigation:

1. Review WAF sampled requests.
2. Check WAF logs for the matched rule group.
3. Confirm whether the request was malicious or legitimate.
4. Tune only a narrow exception if legitimate traffic is blocked.

---

## Scenario 3 — Lambda Runtime Error

Expected behavior:

* API Gateway may return a 5XX response
* Lambda logs show the runtime exception
* CloudWatch alarm may enter ALARM state
* advanced alerting workflow sends troubleshooting guidance

Investigation:

1. Check API Gateway access logs for request ID and route.
2. Check Lambda CloudWatch logs for the same time window.
3. Confirm handler configuration.
4. Confirm deployment package file structure.
5. Confirm Lambda proxy response format.

---

## Scenario 4 — High API Latency

Expected behavior:

* CloudWatch latency alarm may trigger
* alerting Lambda sends recommended troubleshooting steps

Investigation:

1. Review API Gateway access logs for high response latency.
2. Check Lambda Duration metrics.
3. Review function code for slow execution paths.
4. Check request volume and throttling behavior.
5. Consider increasing Lambda memory if runtime duration is consistently high.

---

## Security Design Decisions

| Decision                                        | Reason                                                                                                    |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Use API Gateway instead of Lambda Function URLs | API Gateway provides WAF integration, API keys, usage plans, throttling, stage settings, and access logs. |
| Require API keys                                | Adds controlled client access and enables usage plan enforcement.                                         |
| Add WAF                                         | Adds application-layer request inspection before Lambda execution.                                        |
| Disable data tracing                            | Avoids logging full request/response payloads that may contain sensitive data.                            |
| Use structured logs                             | Makes production troubleshooting easier.                                                                  |
| Use EventBridge for alert routing               | Allows custom alert formatting instead of raw alarm emails.                                               |
| Use IAM roles per service                       | Reduces unnecessary permissions and separates responsibilities.                                           |
| Use Terraform                                   | Keeps security controls repeatable and reviewable as code.                                                |

---

## Limitations

This project is production-inspired but not fully enterprise-hardened.

Current limitations:

* API keys are not full authentication.
* No Cognito or Lambda authorizer is currently implemented.
* No custom domain or ACM TLS certificate is currently configured.
* No OpenAPI specification is included yet.
* No DynamoDB audit table is currently storing structured request history.
* No CI/CD pipeline is currently enforcing security scans or deployment approvals.
* No CloudWatch dashboard is currently included.
* No multi-region failover is currently implemented.

---

## Recommended Future Security Improvements

1. Add Cognito User Pool authorizer for identity-based access.
2. Add Lambda authorizer for custom token validation.
3. Add OpenAPI documentation with security scheme definitions.
4. Add DynamoDB audit table for structured request history.
5. Add CloudWatch dashboard for visual security and operations monitoring.
6. Add CI/CD pipeline with Terraform scanning tools such as Checkov or tfsec.
7. Add custom domain with ACM TLS certificate.
8. Add route-level authorization boundaries.
9. Add `/health` and `/status` routes.
10. Add canary deployment and rollback controls.

---

## Security Interview Summary

Use this summary when explaining the security design:

> “This project secures a serverless API using layered controls. AWS WAF protects the public entry point, API Gateway requires API keys and usage plans for controlled client access, throttling limits request volume, IAM roles keep permissions scoped, and CloudWatch logs provide visibility across API Gateway, Lambda, and WAF. I also added CloudWatch alarms, EventBridge, SNS, and a custom alerting Lambda so operational failures generate actionable notifications with likely causes and suggested fixes.”

---

## What This Security Design Proves

| Area                      | Value Demonstrated                                                |
| ------------------------- | ----------------------------------------------------------------- |
| API Security              | WAF, API keys, usage plans, throttling                            |
| Cloud Security            | IAM roles, service permissions, logging boundaries                |
| Monitoring                | CloudWatch logs and alarms                                        |
| Incident Response         | EventBridge, SNS, advanced alert formatting                       |
| Infrastructure Discipline | Terraform-managed security controls                               |
| Production Thinking       | Defense-in-depth, visibility, alerting, and future hardening path |
