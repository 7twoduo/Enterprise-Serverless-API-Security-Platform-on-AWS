import os
import json
import html
from urllib.parse import quote
from datetime import datetime, timezone


DEFAULT_PAGE_TITLE = "${page_title}"
DEFAULT_ROUTE_PATH = "${route_path}"
DEFAULT_OTHER_ROUTE_PATH = "${other_route_path}"
DEFAULT_OTHER_PAGE_TITLE = "${other_page_title}"
DEFAULT_LANGUAGE = "${language_name}"


def get_header(headers, name, default=None):
    if not headers:
        return default

    lower_name = name.lower()

    for key, value in headers.items():
        if key.lower() == lower_name:
            return value

    return default


def build_route_url(event, route_path):
    headers = event.get("headers") or {}
    request_context = event.get("requestContext") or {}

    protocol = get_header(headers, "X-Forwarded-Proto", "https")
    domain = request_context.get("domainName") or get_header(headers, "Host")
    stage = request_context.get("stage") or os.environ.get("API_STAGE", "")

    if not domain:
        return "/" + route_path

    if stage and stage != "$default":
        return protocol + "://" + domain + "/" + stage + "/" + route_path

    return protocol + "://" + domain + "/" + route_path


def lambda_handler(event, context):
    print("Incoming event:", json.dumps(event))

    query_params = event.get("queryStringParameters") or {}
    request_context = event.get("requestContext") or {}
    identity = request_context.get("identity") or {}

    name = query_params.get("name", "Unknown")

    page_title = os.environ.get("PAGE_TITLE", DEFAULT_PAGE_TITLE)
    route_path = os.environ.get("ROUTE_PATH", DEFAULT_ROUTE_PATH)
    other_route_path = os.environ.get("OTHER_ROUTE_PATH", DEFAULT_OTHER_ROUTE_PATH)
    other_page_title = os.environ.get("OTHER_PAGE_TITLE", DEFAULT_OTHER_PAGE_TITLE)
    language_name = os.environ.get("LANGUAGE_NAME", DEFAULT_LANGUAGE)

    current_url = build_route_url(event, route_path)
    other_url = build_route_url(event, other_route_path)

    safe_name = html.escape(name)
    safe_name_upper = html.escape(name.upper())
    encoded_name = quote(name)

    safe_page_title = html.escape(page_title)
    safe_other_page_title = html.escape(other_page_title)
    safe_language_name = html.escape(language_name)
    safe_current_url = html.escape(current_url)
    safe_other_url = html.escape(other_url)

    method = html.escape(event.get("httpMethod", "GET"))
    path = html.escape(event.get("path", "/" + route_path))
    source_ip = html.escape(identity.get("sourceIp", "Unknown"))
    user_agent = html.escape(identity.get("userAgent", "Unknown"))
    timestamp = datetime.now(timezone.utc).isoformat()

    html_body = [
        "<!DOCTYPE html>",
        "<html lang='en'>",
        "<head>",
        "  <meta charset='UTF-8' />",
        "  <meta name='viewport' content='width=device-width, initial-scale=1.0' />",
        "  <title>" + safe_page_title + "</title>",
        "  <style>",
        "    * { box-sizing: border-box; }",
        "    body {",
        "      margin: 0;",
        "      min-height: 100vh;",
        "      font-family: Arial, Helvetica, sans-serif;",
        "      background:",
        "        radial-gradient(circle at top left, rgba(52, 211, 153, 0.25), transparent 30%),",
        "        radial-gradient(circle at bottom right, rgba(59, 130, 246, 0.25), transparent 35%),",
        "        linear-gradient(135deg, #020617, #0f172a, #111827);",
        "      color: #e5e7eb;",
        "      display: flex;",
        "      align-items: center;",
        "      justify-content: center;",
        "      padding: 32px;",
        "      position: relative;",
        "      overflow-x: hidden;",
        "    }",
        "    body::before, body::after {",
        "      content: '';",
        "      position: fixed;",
        "      width: 420px;",
        "      height: 420px;",
        "      border-radius: 999px;",
        "      filter: blur(70px);",
        "      opacity: 0.22;",
        "      z-index: 0;",
        "      animation: orbFloat 12s ease-in-out infinite;",
        "      pointer-events: none;",
        "    }",
        "    body::before {",
        "      top: -120px;",
        "      left: -80px;",
        "      background: #3b82f6;",
        "    }",
        "    body::after {",
        "      right: -100px;",
        "      bottom: -140px;",
        "      background: #10b981;",
        "      animation-delay: -6s;",
        "    }",
        "    .shell {",
        "      width: 100%;",
        "      max-width: 1050px;",
        "      position: relative;",
        "      z-index: 1;",
        "    }",
        "    .card {",
        "      border: 1px solid rgba(255,255,255,0.12);",
        "      background: rgba(15,23,42,0.72);",
        "      backdrop-filter: blur(18px);",
        "      border-radius: 28px;",
        "      overflow: hidden;",
        "      box-shadow: 0 30px 90px rgba(0,0,0,0.45);",
        "      animation: cardFloat 6s ease-in-out infinite;",
        "    }",
        "    .hero {",
        "      padding: 44px 38px 28px;",
        "      border-bottom: 1px solid rgba(255,255,255,0.1);",
        "    }",
        "    .badge {",
        "      display: inline-flex;",
        "      align-items: center;",
        "      padding: 9px 14px 9px 34px;",
        "      border-radius: 999px;",
        "      background: rgba(16,185,129,0.14);",
        "      border: 1px solid rgba(16,185,129,0.4);",
        "      color: #a7f3d0;",
        "      font-size: 13px;",
        "      font-weight: 700;",
        "      letter-spacing: 0.4px;",
        "      margin-bottom: 18px;",
        "      position: relative;",
        "      overflow: hidden;",
        "    }",
        "    .badge::before {",
        "      content: '';",
        "      position: absolute;",
        "      left: 14px;",
        "      top: 50%;",
        "      width: 10px;",
        "      height: 10px;",
        "      border-radius: 999px;",
        "      transform: translateY(-50%);",
        "      background: #22c55e;",
        "      animation: pulseDot 1.8s infinite;",
        "    }",
        "    h1 {",
        "      margin: 0;",
        "      font-size: clamp(34px, 6vw, 62px);",
        "      line-height: 1;",
        "      letter-spacing: -1.8px;",
        "    }",
        "    .accent { color: #34d399; }",
        "    .subtitle {",
        "      margin-top: 18px;",
        "      max-width: 760px;",
        "      color: #cbd5e1;",
        "      font-size: 18px;",
        "      line-height: 1.7;",
        "    }",
        "    .content { padding: 32px 38px 40px; }",
        "    .grid {",
        "      display: grid;",
        "      grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));",
        "      gap: 18px;",
        "      margin-bottom: 24px;",
        "    }",
        "    .panel {",
        "      background: rgba(2,6,23,0.42);",
        "      border: 1px solid rgba(255,255,255,0.1);",
        "      border-radius: 20px;",
        "      padding: 20px;",
        "      transition: transform 0.22s ease, border-color 0.22s ease, box-shadow 0.22s ease;",
        "    }",
        "    .panel:hover {",
        "      transform: translateY(-4px);",
        "      border-color: rgba(255,255,255,0.18);",
        "      box-shadow: 0 12px 32px rgba(0,0,0,0.18);",
        "    }",
        "    .label {",
        "      color: #94a3b8;",
        "      font-size: 12px;",
        "      text-transform: uppercase;",
        "      letter-spacing: 0.8px;",
        "      margin-bottom: 9px;",
        "    }",
        "    .value {",
        "      color: #f8fafc;",
        "      font-size: 17px;",
        "      font-weight: 700;",
        "      word-break: break-word;",
        "    }",
        "    .description {",
        "      color: #cbd5e1;",
        "      line-height: 1.75;",
        "      margin: 0 0 18px;",
        "    }",
        "    .button-row {",
        "      display: flex;",
        "      flex-wrap: wrap;",
        "      gap: 12px;",
        "      margin-top: 24px;",
        "    }",
        "    .btn {",
        "      text-decoration: none;",
        "      color: #ffffff;",
        "      background: linear-gradient(135deg, #10b981, #059669);",
        "      padding: 13px 18px;",
        "      border-radius: 14px;",
        "      font-weight: 800;",
        "      box-shadow: 0 12px 32px rgba(16,185,129,0.25);",
        "      position: relative;",
        "      overflow: hidden;",
        "      transition: transform 0.22s ease, box-shadow 0.22s ease;",
        "    }",
        "    .btn:hover { transform: translateY(-3px); }",
        "    .btn::after {",
        "      content: '';",
        "      position: absolute;",
        "      top: 0;",
        "      left: -120%;",
        "      width: 65%;",
        "      height: 100%;",
        "      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.22), transparent);",
        "      transform: skewX(-20deg);",
        "      animation: shimmer 3.2s linear infinite;",
        "    }",
        "    .btn.secondary {",
        "      background: rgba(255,255,255,0.08);",
        "      border: 1px solid rgba(255,255,255,0.16);",
        "      box-shadow: none;",
        "    }",
        "    code {",
        "      color: #bbf7d0;",
        "      background: rgba(255,255,255,0.08);",
        "      padding: 3px 8px;",
        "      border-radius: 8px;",
        "    }",
        "    .footer {",
        "      margin-top: 24px;",
        "      text-align: center;",
        "      color: #94a3b8;",
        "      font-size: 14px;",
        "    }",
        "    @keyframes pulseDot {",
        "      0% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.65); transform: translateY(-50%) scale(1); }",
        "      70% { box-shadow: 0 0 0 12px rgba(34, 197, 94, 0); transform: translateY(-50%) scale(1.08); }",
        "      100% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); transform: translateY(-50%) scale(1); }",
        "    }",
        "    @keyframes shimmer {",
        "      0% { left: -120%; }",
        "      100% { left: 150%; }",
        "    }",
        "    @keyframes cardFloat {",
        "      0% { transform: translateY(0px); }",
        "      50% { transform: translateY(-6px); }",
        "      100% { transform: translateY(0px); }",
        "    }",
        "    @keyframes orbFloat {",
        "      0% { transform: translate3d(0, 0, 0) scale(1); }",
        "      50% { transform: translate3d(20px, -18px, 0) scale(1.08); }",
        "      100% { transform: translate3d(0, 0, 0) scale(1); }",
        "    }",
        "  </style>",
        "</head>",
        "<body>",
        "  <main class='shell'>",
        "    <section class='card'>",
        "      <div class='hero'>",
        "        <div class='badge'>LIVE AWS LAMBDA ROUTE</div>",
        "        <h1>" + safe_page_title + ": <span class='accent'>" + safe_language_name + "</span></h1>",
        "        <p class='subtitle'>",
        "          Hello <strong>" + safe_name + "</strong>. This page is rendered dynamically by a " + safe_language_name + " Lambda function.",
        "          The buttons route between the Python and Java function pages.",
        "        </p>",
        "      </div>",
        "      <div class='content'>",
        "        <div class='grid'>",
        "          <div class='panel'><div class='label'>Current Route</div><div class='value'>/" + route_path + "</div></div>",
        "          <div class='panel'><div class='label'>Method</div><div class='value'>" + method + "</div></div>",
        "          <div class='panel'><div class='label'>Path</div><div class='value'>" + path + "</div></div>",
        "          <div class='panel'><div class='label'>Timestamp UTC</div><div class='value'>" + timestamp + "</div></div>",
        "        </div>",
        "        <div class='panel'>",
        "          <p class='description'>",
        "            This endpoint returns <code>text/html</code> instead of plain JSON. The page is generated inside Lambda and protected by API Gateway plus WAF.",
        "          </p>",
        "          <div class='grid'>",
        "            <div class='panel'><div class='label'>Current URL</div><div class='value'>" + safe_current_url + "</div></div>",
        "            <div class='panel'><div class='label'>Other Function URL</div><div class='value'>" + safe_other_url + "</div></div>",
        "            <div class='panel'><div class='label'>Source IP</div><div class='value'>" + source_ip + "</div></div>",
        "            <div class='panel'><div class='label'>User Agent</div><div class='value'>" + user_agent + "</div></div>",
        "          </div>",
        "          <div class='button-row'>",
        "            <a class='btn' href='" + safe_current_url + "?name=" + encoded_name + "'>Python Function</a>",
        "            <a class='btn secondary' href='" + safe_other_url + "?name=" + encoded_name + "'>Java Function</a>",
        "          </div>",
        "        </div>",
        "        <div class='footer'>Region-stable • API-ID-stable • Stage-aware</div>",
        "      </div>",
        "    </section>",
        "  </main>",
        "</body>",
        "</html>"
    ]

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html; charset=utf-8"
        },
        "body": "".join(html_body)
    }