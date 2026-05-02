const DEFAULT_PAGE_TITLE = "${page_title}";
const DEFAULT_ROUTE_PATH = "${route_path}";
const DEFAULT_OTHER_ROUTE_PATH = "${other_route_path}";
const DEFAULT_OTHER_PAGE_TITLE = "${other_page_title}";
const DEFAULT_LANGUAGE = "${language_name}";

function getHeader(headers, name, fallback = undefined) {
  if (!headers) return fallback;

  const lowerName = name.toLowerCase();

  for (const [key, value] of Object.entries(headers)) {
    if (key.toLowerCase() === lowerName) {
      return value;
    }
  }

  return fallback;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#039;");
}

function buildRouteUrl(event, routePath) {
  const headers = event.headers || {};
  const requestContext = event.requestContext || {};

  const protocol = getHeader(headers, "X-Forwarded-Proto", "https");
  const domain = requestContext.domainName || getHeader(headers, "Host");
  const stage = requestContext.stage || process.env.API_STAGE || "";

  if (!domain) {
    return "/" + routePath;
  }

  if (stage && stage !== "$default") {
    return protocol + "://" + domain + "/" + stage + "/" + routePath;
  }

  return protocol + "://" + domain + "/" + routePath;
}

exports.handler = async (event) => {
  console.log("Incoming event:", JSON.stringify(event));

  const queryParams = event.queryStringParameters || {};
  const requestContext = event.requestContext || {};
  const identity = requestContext.identity || {};

  const name = queryParams.name || "Unknown";

  const pageTitle = process.env.PAGE_TITLE || DEFAULT_PAGE_TITLE;
  const routePath = process.env.ROUTE_PATH || DEFAULT_ROUTE_PATH;
  const otherRoutePath = process.env.OTHER_ROUTE_PATH || DEFAULT_OTHER_ROUTE_PATH;
  const otherPageTitle = process.env.OTHER_PAGE_TITLE || DEFAULT_OTHER_PAGE_TITLE;
  const languageName = process.env.LANGUAGE_NAME || DEFAULT_LANGUAGE;

  const currentUrl = buildRouteUrl(event, routePath);
  const otherUrl = buildRouteUrl(event, otherRoutePath);

  const safeName = escapeHtml(name);
  const safePageTitle = escapeHtml(pageTitle);
  const safeOtherPageTitle = escapeHtml(otherPageTitle);
  const safeLanguageName = escapeHtml(languageName);
  const safeCurrentUrl = escapeHtml(currentUrl);
  const safeOtherUrl = escapeHtml(otherUrl);

  const method = escapeHtml(event.httpMethod || "GET");
  const path = escapeHtml(event.path || "/" + routePath);
  const sourceIp = escapeHtml(identity.sourceIp || "Unknown");
  const userAgent = escapeHtml(identity.userAgent || "Unknown");
  const timestamp = new Date().toISOString();

  const html = [
    "<!DOCTYPE html>",
    "<html lang='en'>",
    "<head>",
    "  <meta charset='UTF-8' />",
    "  <meta name='viewport' content='width=device-width, initial-scale=1.0' />",
    "  <title>" + safePageTitle + "</title>",
    "  <style>",
    "    * { box-sizing: border-box; }",
    "    body {",
    "      margin: 0;",
    "      min-height: 100vh;",
    "      font-family: Arial, Helvetica, sans-serif;",
    "      background:",
    "        radial-gradient(circle at top right, rgba(59,130,246,0.26), transparent 30%),",
    "        radial-gradient(circle at bottom left, rgba(236,72,153,0.18), transparent 35%),",
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
    "    body::before { top: -120px; left: -80px; background: #3b82f6; }",
    "    body::after { right: -100px; bottom: -140px; background: #10b981; animation-delay: -6s; }",
    "    .shell { width: 100%; max-width: 1050px; position: relative; z-index: 1; }",
    "    .card {",
    "      border: 1px solid rgba(255,255,255,0.12);",
    "      background: rgba(15,23,42,0.72);",
    "      backdrop-filter: blur(18px);",
    "      border-radius: 28px;",
    "      overflow: hidden;",
    "      box-shadow: 0 30px 90px rgba(0,0,0,0.45);",
    "      animation: cardFloat 6s ease-in-out infinite;",
    "    }",
    "    .hero { padding: 44px 38px 28px; border-bottom: 1px solid rgba(255,255,255,0.1); }",
    "    .badge {",
    "      display: inline-flex;",
    "      align-items: center;",
    "      padding: 9px 14px 9px 34px;",
    "      border-radius: 999px;",
    "      background: rgba(59,130,246,0.16);",
    "      border: 1px solid rgba(96,165,250,0.42);",
    "      color: #bfdbfe;",
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
    "    h1 { margin: 0; font-size: clamp(34px, 6vw, 62px); line-height: 1; letter-spacing: -1.8px; }",
    "    .accent { color: #60a5fa; }",
    "    .subtitle { margin-top: 18px; max-width: 760px; color: #cbd5e1; font-size: 18px; line-height: 1.7; }",
    "    .content { padding: 32px 38px 40px; }",
    "    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 18px; margin-bottom: 24px; }",
    "    .panel {",
    "      background: rgba(2,6,23,0.42);",
    "      border: 1px solid rgba(255,255,255,0.1);",
    "      border-radius: 20px;",
    "      padding: 20px;",
    "      transition: transform 0.22s ease, border-color 0.22s ease, box-shadow 0.22s ease;",
    "    }",
    "    .panel:hover { transform: translateY(-4px); border-color: rgba(255,255,255,0.18); box-shadow: 0 12px 32px rgba(0,0,0,0.18); }",
    "    .label { color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 9px; }",
    "    .value { color: #f8fafc; font-size: 17px; font-weight: 700; word-break: break-word; }",
    "    .description { color: #cbd5e1; line-height: 1.75; margin: 0 0 18px; }",
    "    .button-row { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 24px; }",
    "    .btn {",
    "      text-decoration: none;",
    "      color: #ffffff;",
    "      background: linear-gradient(135deg, #3b82f6, #2563eb);",
    "      padding: 13px 18px;",
    "      border-radius: 14px;",
    "      font-weight: 800;",
    "      box-shadow: 0 12px 32px rgba(59,130,246,0.25);",
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
    "    .btn.secondary { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.16); box-shadow: none; }",
    "    code { color: #bfdbfe; background: rgba(255,255,255,0.08); padding: 3px 8px; border-radius: 8px; }",
    "    .footer { margin-top: 24px; text-align: center; color: #94a3b8; font-size: 14px; }",
    "    @keyframes pulseDot {",
    "      0% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.65); transform: translateY(-50%) scale(1); }",
    "      70% { box-shadow: 0 0 0 12px rgba(34, 197, 94, 0); transform: translateY(-50%) scale(1.08); }",
    "      100% { box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); transform: translateY(-50%) scale(1); }",
    "    }",
    "    @keyframes shimmer { 0% { left: -120%; } 100% { left: 150%; } }",
    "    @keyframes cardFloat { 0% { transform: translateY(0px); } 50% { transform: translateY(-6px); } 100% { transform: translateY(0px); } }",
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
    "        <h1>" + safePageTitle + ": <span class='accent'>" + safeLanguageName + "</span></h1>",
    "        <p class='subtitle'>HELLO <strong>" + safeName.toUpperCase() + "</strong>. This page is rendered dynamically by a " + safeLanguageName + " Lambda function. The buttons route between the Java and Python function pages.</p>",
    "      </div>",
    "      <div class='content'>",
    "        <div class='grid'>",
    "          <div class='panel'><div class='label'>Current Route</div><div class='value'>/" + routePath + "</div></div>",
    "          <div class='panel'><div class='label'>Method</div><div class='value'>" + method + "</div></div>",
    "          <div class='panel'><div class='label'>Path</div><div class='value'>" + path + "</div></div>",
    "          <div class='panel'><div class='label'>Timestamp UTC</div><div class='value'>" + timestamp + "</div></div>",
    "        </div>",
    "        <div class='panel'>",
    "          <p class='description'>This endpoint returns <code>text/html</code> instead of plain JSON. The page is generated inside Lambda and protected by API Gateway plus WAF.</p>",
    "          <div class='grid'>",
    "            <div class='panel'><div class='label'>Current URL</div><div class='value'>" + safeCurrentUrl + "</div></div>",
    "            <div class='panel'><div class='label'>Other Function URL</div><div class='value'>" + safeOtherUrl + "</div></div>",
    "            <div class='panel'><div class='label'>Source IP</div><div class='value'>" + sourceIp + "</div></div>",
    "            <div class='panel'><div class='label'>User Agent</div><div class='value'>" + userAgent + "</div></div>",
    "          </div>",
    "          <div class='button-row'>",
    "            <a class='btn' href='" + safeCurrentUrl + "?name=" + encodeURIComponent(name) + "'>Java Function</a>",
    "            <a class='btn secondary' href='" + safeOtherUrl + "?name=" + encodeURIComponent(name) + "'>Python Function</a>",
    "          </div>",
    "        </div>",
    "        <div class='footer'>Region-stable • API-ID-stable • Stage-aware</div>",
    "      </div>",
    "    </section>",
    "  </main>",
    "</body>",
    "</html>"
  ].join("");

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8"
    },
    body: html
  };
};