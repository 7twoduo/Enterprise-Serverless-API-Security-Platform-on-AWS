# 🔐 Enterprise Serverless API Security Platform on AWS

**Production-inspired serverless API project with API Gateway, AWS Lambda, AWS WAF, API keys, CloudWatch, SNS, EventBridge, and Terraform**

<br/>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=700&size=24&pause=1200&color=58A6FF&center=true&vCenter=true&width=980&lines=Secure+Serverless+API+on+AWS;API+Gateway+%2B+Lambda+%2B+WAF+%2B+CloudWatch;Terraform-Based+Production-Inspired+API+Platform" alt="Typing SVG" />
</p>

<p align="center">
  A production-inspired AWS serverless API project that demonstrates secure API exposure, Lambda-backed routing, API key enforcement, WAF protection, access logging, monitoring, and advanced alerting.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/AWS-Serverless%20Architecture-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white" />
  <img src="https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/API%20Gateway-REST%20API-FF4F8B?style=for-the-badge" />
  <img src="https://img.shields.io/badge/AWS%20WAF-Managed%20Rules-DC2626?style=for-the-badge" />
  <img src="https://img.shields.io/badge/CloudWatch-Logs%20%2B%20Alarms-FF9900?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Production%20Inspired-success?style=for-the-badge" />
</p>

---

## 📌 Overview

This project deploys a **secure serverless REST API platform on AWS** using Terraform.

The API exposes two Lambda-backed routes:

* `/py` — served by a Python Lambda function
* `/js` — served by a JavaScript/Node.js Lambda function

Both routes return styled dynamic HTML pages and are protected with API Gateway controls, AWS WAF managed rule sets, API key enforcement, usage plan throttling, and CloudWatch-based observability.

The project also includes an advanced alerting workflow where CloudWatch alarm state changes are routed through EventBridge into a Lambda formatter, which sends actionable troubleshooting messages through SNS.

This project is intentionally small, but it demonstrates practical production-style API engineering patterns:

* REST API design with API Gateway
* serverless compute with AWS Lambda
* Infrastructure as Code with Terraform
* API key-based client access control
* usage plans, throttling, and quotas
* WAF managed rule protection
* CloudWatch access logging and alarms
* SNS-based notifications
* EventBridge-driven alert processing
* custom Lambda-based alert formatting

---

## 🧠 Problem Statement

Public APIs need more than a working endpoint.

A real API should be protected, observable, controlled, and supportable. Many beginner serverless projects stop at:

* one Lambda function
* one public endpoint
* no WAF protection
* no API key controls
* no usage plan
* no access logs
* no alarms
* no alerting workflow
* no operational troubleshooting path

That creates problems in production-style environments:

* anyone can call the API without control
* abusive traffic can overload the backend
* attacks may reach the application layer unchecked
* failures are hard to troubleshoot
* logs are not structured around request visibility
* alarms do not provide actionable guidance

This project addresses those gaps by building a small but realistic secure API platform.

---

## 🎯 Project Objective

Build a Terraform-managed AWS serverless API that demonstrates how to expose Lambda functions through API Gateway while applying practical production controls:

* secure the API entry point with AWS WAF
* require API key access through API Gateway
* control traffic with usage plans and throttling
* log API requests for troubleshooting
* monitor errors and latency with CloudWatch alarms
* send alert notifications through SNS
* use EventBridge and Lambda to generate actionable alert messages

---

## 🏗️ Architecture Diagram

> Save your architecture image as:
>
> `Evidence/01-architecture/architecture-diagram.png`

<img width="1200" alt="Architecture Diagram" src="./Evidence/01-architecture/architecture-diagram.png" />

---

## 🔄 Architecture Flow

```text
Client / Browser / curl
        ↓
API Gateway REST API
        ↓
AWS WAF evaluates the request
        ↓
API Gateway checks for x-api-key header
        ↓
Usage plan applies throttling and quota controls
        ↓
API Gateway routes request to /py or /js
        ↓
Python Lambda or JavaScript Lambda executes
        ↓
Lambda returns styled HTML response
        ↓
API Gateway sends response back to client
        ↓
API Gateway, Lambda, and WAF logs go to CloudWatch
        ↓
CloudWatch alarms monitor errors and latency
        ↓
EventBridge captures alarm state changes
        ↓
Advanced alerting Lambda formats the incident message
        ↓
SNS sends the alert email
```

---

## 🧰 Technology Stack

<p align="center">
  <img src="https://img.shields.io/badge/AWS-Cloud%20Provider-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white" />
  <img src="https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/API%20Gateway-REST%20API-FF4F8B?style=for-the-badge" />
  <img src="https://img.shields.io/badge/AWS%20Lambda-Serverless%20Compute-FF9900?style=for-the-badge&logo=awslambda&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-Lambda%20Runtime-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-JavaScript%20Runtime-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS%20WAF-API%20Protection-DC2626?style=for-the-badge" />
  <img src="https://img.shields.io/badge/CloudWatch-Logs%20%2B%20Alarms-FF9900?style=for-the-badge" />
  <img src="https://img.shields.io/badge/SNS-Email%20Notifications-FF9900?style=for-the-badge" />
  <img src="https://img.shields.io/badge/EventBridge-Alarm%20Routing-8C4FFF?style=for-the-badge" />
  <img src="https://img.shields.io/badge/IAM-Least%20Privilege-DD6B20?style=for-the-badge" />
</p>

| Category                   | Technologies                                       |
| -------------------------- | -------------------------------------------------- |
| **Cloud Provider**         | AWS                                                |
| **Infrastructure as Code** | Terraform                                          |
| **API Layer**              | Amazon API Gateway REST API                        |
| **Compute**                | AWS Lambda                                         |
| **Runtime 1**              | Python 3.12                                        |
| **Runtime 2**              | Node.js / JavaScript                               |
| **Security**               | AWS WAF, API keys, IAM roles                       |
| **Traffic Control**        | API Gateway usage plans, throttling, quotas        |
| **Logging**                | CloudWatch Logs, API Gateway access logs, WAF logs |
| **Monitoring**             | CloudWatch alarms                                  |
| **Notifications**          | Amazon SNS                                         |
| **Event Routing**          | Amazon EventBridge                                 |
| **Alert Automation**       | Advanced alerting Lambda                           |

---

## ✨ What This Project Demonstrates

<table>
  <tr>
    <td align="center" width="25%">
      <h3>🚪 Secure API Exposure</h3>
      API Gateway exposes controlled REST endpoints backed by Lambda functions.
    </td>
    <td align="center" width="25%">
      <h3>⚡ Serverless Compute</h3>
      Python and JavaScript Lambda functions serve dynamic API responses.
    </td>
    <td align="center" width="25%">
      <h3>🛡️ WAF Protection</h3>
      AWS managed rule groups help protect the API from common web threats.
    </td>
    <td align="center" width="25%">
      <h3>🔑 API Key Control</h3>
      API clients must send an API key through the <code>x-api-key</code> header.
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <h3>📊 Usage Plans</h3>
      API Gateway usage plans control throttling and monthly request quotas.
    </td>
    <td align="center" width="25%">
      <h3>📋 Access Logging</h3>
      API Gateway access logs capture request ID, status code, latency, IP, and route.
    </td>
    <td align="center" width="25%">
      <h3>🚨 Monitoring</h3>
      CloudWatch alarms detect API 5XX errors, high latency, and Lambda failures.
    </td>
    <td align="center" width="25%">
      <h3>📨 Advanced Alerting</h3>
      EventBridge and Lambda create actionable SNS alert messages with suggested fixes.
    </td>
  </tr>
</table>

---

## ✅ What This Builds

* A Regional API Gateway REST API
* A `/py` route backed by a Python Lambda function
* A `/js` route backed by a JavaScript Lambda function
* Lambda proxy integrations for full request/response handling
* API Gateway deployment and `prod` stage
* API key requirement for protected API access
* Usage plan with throttling and monthly quota
* AWS WAF web ACL attached to the API Gateway stage
* AWS managed WAF rule groups for common attacks, known bad inputs, and SQL injection
* WAF rate-based rule for basic abuse protection
* API Gateway access logs in CloudWatch
* Lambda execution logs in CloudWatch
* WAF logs in CloudWatch
* CloudWatch alarms for API and Lambda issues
* SNS topic and email subscription for notifications
* EventBridge rule for CloudWatch alarm state changes
* Advanced alerting Lambda that formats actionable alert emails

---

## 🧱 Core AWS Resources

| AWS Resource               | Purpose                                                                                   |
| -------------------------- | ----------------------------------------------------------------------------------------- |
| **Amazon API Gateway**     | Public REST API entry point for `/py` and `/js` routes.                                   |
| **AWS Lambda**             | Runs the Python, JavaScript, and advanced alerting functions.                             |
| **AWS WAF**                | Protects the API Gateway stage using managed rules and rate limiting.                     |
| **API Gateway Usage Plan** | Applies client-level throttling and monthly request quotas.                               |
| **API Gateway API Key**    | Requires clients to send an `x-api-key` header before accessing protected routes.         |
| **CloudWatch Logs**        | Stores Lambda logs, API Gateway access logs, and WAF logs.                                |
| **CloudWatch Alarms**      | Detects API 5XX errors, high latency, and Lambda function failures.                       |
| **Amazon SNS**             | Sends email notifications for production-style alerts.                                    |
| **Amazon EventBridge**     | Routes CloudWatch alarm state changes to the advanced alerting Lambda.                    |
| **IAM Roles and Policies** | Provides least-privilege permissions for Lambda, API Gateway logging, and SNS publishing. |
| **Terraform**              | Provisions and manages the full infrastructure stack.                                     |

---

## 📂 Project Structure

```text
Enterprise-Serverless-API-Security-Platform-on-AWS/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── advanced-alerting.py
├── lambda-js/
│   └── index.js.tpl
├── lambda-py/
│   └── index.py.tpl
├── Evidence/
│   └── 01-architecture/
│       └── architecture-diagram.png
└── docs/
    ├── architecture.md
    ├── security-controls.md
    ├── troubleshooting.md
    └── interview-talking-points.md
```

---

## 🖥️ API Routes

| Route | Method | Access           | Description                                                        |
| ----- | -----: | ---------------- | ------------------------------------------------------------------ |
| `/py` |  `ANY` | API key required | Runs the Python Lambda and returns a styled dynamic HTML page.     |
| `/js` |  `ANY` | API key required | Runs the JavaScript Lambda and returns a styled dynamic HTML page. |

```text
/prod/py  → Python Function page
/prod/js  → Java Function page
```

Both routes require the API key to be sent through the request header:

```http
x-api-key: YOUR_API_KEY
```

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd Enterprise-Serverless-API-Security-Platform-on-AWS
```

### 2. Configure variables

Create a `terraform.tfvars` file:

```hcl
alert_email = "your-email@example.com"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Validate Terraform

```bash
terraform validate
```

### 5. Review the deployment plan

```bash
terraform plan
```

### 6. Deploy the infrastructure

```bash
terraform apply -auto-approve
```

### 7. Confirm SNS email subscription

After deployment, AWS SNS sends a confirmation email.

Click **Confirm subscription** before expecting alert emails.

---

## 🧪 Validation & Testing

### Get the API key

```bash
terraform output -raw api_key_value
```

### Test the Python route

```bash
API_KEY=$(terraform output -raw api_key_value)

curl -H "x-api-key: $API_KEY" \
"https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/py?name=Gavin"
```

### Test the JavaScript route

```bash
API_KEY=$(terraform output -raw api_key_value)

curl -H "x-api-key: $API_KEY" \
"https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/js?name=Gavin"
```

### Test the advanced alerting workflow

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "<project-name>-api-5xx-errors" \
  --state-value ALARM \
  --state-reason "Testing advanced formatted API Gateway 5XX alert"
```

Expected result:

1. CloudWatch alarm enters `ALARM` state.
2. EventBridge captures the state change.
3. Advanced alerting Lambda runs.
4. Lambda formats the message with likely cause and suggested fixes.
5. SNS sends an email notification.

Reset test alarm:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "<project-name>-api-5xx-errors" \
  --state-value OK \
  --state-reason "Testing complete"
```

---

## 🔐 Security Architecture

### AWS WAF Protection

The API Gateway stage is protected by an AWS WAF web ACL using managed rule groups:

* AWS Managed Common Rule Set
* AWS Managed Known Bad Inputs Rule Set
* AWS Managed SQL Injection Rule Set
* Rate-based rule by source IP

### API Key Enforcement

The `/py` and `/js` routes require an API key through the `x-api-key` header.

This models controlled client access for partner, internal, or application consumers.

### Usage Plan Controls

The usage plan applies:

* request rate limits
* burst limits
* monthly quota controls

This prevents uncontrolled client usage and helps protect the backend Lambda functions.

### IAM Least Privilege

IAM roles are scoped by service responsibility:

* Lambda execution role writes function logs
* API Gateway role pushes logs to CloudWatch
* advanced alerting Lambda publishes to SNS
* API Gateway receives permission to invoke Lambda

---

## 📊 Observability and Monitoring

This project includes multiple layers of visibility:

| Layer                        | What It Captures                                                                   |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| **API Gateway Access Logs**  | request ID, source IP, route, method, status code, latency, user agent, API key ID |
| **Lambda Logs**              | function execution details, incoming events, application logs, runtime errors      |
| **WAF Logs**                 | inspected requests, matched rules, blocked traffic, rate-based activity            |
| **CloudWatch Alarms**        | API 5XX errors, high latency, Lambda errors                                        |
| **SNS Alerts**               | email notifications for operational events                                         |
| **Advanced Alerting Lambda** | formatted alarm messages with possible causes and suggested fixes                  |

---

## 🚨 Advanced Alerting Workflow

Instead of relying only on raw CloudWatch alarm emails, this project uses an advanced alerting path:

```text
CloudWatch Alarm
        ↓
EventBridge Alarm State Change Rule
        ↓
Advanced Alerting Lambda
        ↓
SNS Topic
        ↓
Email Notification
```

The `advanced-alerting.py` function reads the alarm event and dynamically generates:

* alarm name
* state transition
* AWS region
* account ID
* metric namespace and metric name
* alarm reason
* likely cause
* suggested troubleshooting steps
* recommended investigation workflow

This makes alerts more actionable and closer to what an operations team would expect in a production environment.

---

## ⚙️ Engineering Challenges and Key Architectural Decisions

| Problem                                | Why It Mattered                                                           | Architectural Decision                                             | Implementation                                                                                |
| -------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| Exposing Lambda functions through HTTP | Lambda functions need an HTTP entry point for users and API clients.      | Use API Gateway REST API with Lambda proxy integration.            | Created `/py` and `/js` API Gateway resources, methods, and integrations.                     |
| Supporting two runtimes                | The project needed to show more than one Lambda runtime.                  | Use separate Python and JavaScript Lambda functions.               | Deployed independent Lambda functions with separate handlers and packaging.                   |
| Lambda packaging errors                | Lambda requires the handler file to exist at the root of the zip package. | Package files as `index.py` and `index.js` inside deployment zips. | Used Terraform archive packaging and corrected handler mappings.                              |
| Securing public API access             | A public API should not be exposed without protection.                    | Add WAF, API key enforcement, and usage plan throttling.           | Attached WAF to the API stage and required `x-api-key` for route access.                      |
| Preventing abusive traffic             | APIs need protection against request spikes and repeated calls.           | Use WAF rate limiting and API Gateway throttling.                  | Added WAF rate-based rule and API Gateway method settings.                                    |
| Making the API observable              | Production APIs need request visibility for troubleshooting.              | Enable API Gateway access logs and Lambda logs.                    | Sent structured access logs and function logs to CloudWatch.                                  |
| Detecting operational failures         | Logs are useful, but production systems need alarms.                      | Add CloudWatch alarms for API and Lambda failure modes.            | Created alarms for 5XX errors, high latency, and Lambda errors.                               |
| Making alerts actionable               | Default alarm notifications often lack troubleshooting context.           | Route alarm events through EventBridge into a formatter Lambda.    | Built `advanced-alerting.py` to generate SNS messages with likely causes and suggested fixes. |
| Keeping infrastructure reproducible    | Manual cloud configuration is hard to repeat and review.                  | Manage the full stack through Terraform.                           | Defined API Gateway, Lambda, WAF, CloudWatch, SNS, EventBridge, IAM, and usage plans as code. |

---

## 📈 Production Roadmap

This project is production-inspired but intentionally scoped to stay understandable and demo-ready.

Future improvements could include:

### Phase 1 — Identity and Authorization

* Add Cognito User Pool authorizer
* Add Lambda authorizer for custom token validation
* Separate public, partner, and admin routes
* Replace API keys with identity-aware authorization for user-level access

### Phase 2 — Delivery and Release Maturity

* Add GitHub Actions or GitLab CI/CD
* Add Terraform plan/apply workflow with manual approval
* Add Checkov or tfsec scanning
* Add canary deployments for safer API releases

### Phase 3 — API Documentation and Client Experience

* Add OpenAPI specification
* Add `/health` and `/status` routes
* Add structured JSON error responses
* Add developer-facing API documentation

### Phase 4 — Enterprise Operations

* Add CloudWatch dashboard
* Add DynamoDB audit table for structured request metadata
* Add custom domain with ACM TLS certificate
* Add Route 53 DNS mapping
* Add multi-environment Terraform structure for dev, stage, and prod

---

## 🚧 Current Limitations

This project intentionally does not include:

```text
Cognito authentication
custom domain
CI/CD pipeline
OpenAPI specification
DynamoDB audit table
CloudWatch dashboard
multi-region failover
canary deployments
full admin portal
```

These are known future improvements. The current version focuses on building and securing the API foundation first.

---

## 🚀 Why This Project Matters

> [!IMPORTANT]
> This project demonstrates practical cloud engineering by turning a simple Lambda API into a secured, observable, and production-inspired serverless API platform.

Instead of stopping at a basic public Lambda endpoint, this project adds the controls that matter in real environments:

<br>

<table>
  <tr>
    <td align="center" width="33%">
      <h3>🛡️ Protected Entry Point</h3>
      AWS WAF inspects requests before they reach the backend Lambda functions.
    </td>
    <td align="center" width="33%">
      <h3>🔑 Controlled Client Access</h3>
      API keys and usage plans control who can call the API and how often.
    </td>
    <td align="center" width="33%">
      <h3>📊 Operational Visibility</h3>
      CloudWatch logs and alarms make the API easier to troubleshoot and monitor.
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <h3>🚨 Actionable Alerting</h3>
      EventBridge and Lambda turn alarm events into useful troubleshooting messages.
    </td>
    <td align="center" width="33%">
      <h3>🏗️ Repeatable Infrastructure</h3>
      Terraform provisions the full AWS stack consistently as code.
    </td>
    <td align="center" width="33%">
      <h3>⚡ Serverless Design</h3>
      Lambda and API Gateway provide a lightweight, scalable API backend.</h3>
    </td>
  </tr>
</table>

<br>

### 🔁 Production-Style API Flow

```text
Request API
     ↓
WAF Inspection
     ↓
API Key Validation
     ↓
Usage Plan Throttling
     ↓
Lambda Execution
     ↓
CloudWatch Logging
     ↓
Alarm Detection
     ↓
EventBridge Routing
     ↓
SNS Alert Notification
```

## ✨ What This Project Proves

| Area                   | Value Shown                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| API Engineering        | REST API routes backed by serverless compute                              |
| Cloud Security         | WAF, API keys, IAM roles, and controlled access                           |
| Infrastructure as Code | Full AWS deployment managed through Terraform                             |
| Observability          | Access logs, Lambda logs, WAF logs, and alarms                            |
| Operations             | SNS notifications and actionable alert formatting                         |
| Interview Readiness    | Clear explanation of request flow, security layers, and monitoring design |

### This is not just a Lambda demo.

### It shows how to design a small API with real production controls.

---

## 👨‍💻 About the Author

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=600&size=22&pause=1000&color=58A6FF&center=true&vCenter=true&width=760&lines=Cloud+Engineer+focused+on+AWS%2C+Terraform%2C+and+automation;Building+production-inspired+infrastructure+projects;Turning+cloud+concepts+into+real-world+implementations" alt="Typing SVG" />
</p>

<p align="center">
  I build hands-on cloud projects designed to reflect practical engineering work rather than simple demos. My focus is on <b>AWS infrastructure</b>, <b>Infrastructure as Code</b>, <b>automation</b>, <b>security-minded design</b>, and <b>real implementation patterns</b> that translate into production environments.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/AWS-Architecting-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white" />
  <img src="https://img.shields.io/badge/Terraform-Infrastructure-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/Cloud-Engineering-1F6FEB?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Automation-Building-success?style=for-the-badge" />
</p>

<p align="center">
  <a href="https://www.linkedin.com/in/gavin-fogwe/">
    <img src="https://img.shields.io/badge/LinkedIn-Let's%20Connect-blue?style=for-the-badge&logo=linkedin" />
  </a>
  <a href="https://github.com/gavinxenon0-arch">
    <img src="https://img.shields.io/badge/GitHub-See%20More%20Projects-black?style=for-the-badge&logo=github" />
  </a>
  <a href="https://gavinfogwe.win/">
    <img src="https://img.shields.io/badge/Portfolio-Explore-orange?style=for-the-badge&logo=googlechrome&logoColor=white" />
  </a>
</p>
