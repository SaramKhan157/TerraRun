import express from 'express';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const landingHtml = readFileSync(join(__dirname, 'landing.html'), 'utf8');
const apiPageHtml = readFileSync(join(__dirname, 'api-page.html'), 'utf8');

const app = express();
const port = parseInt(process.env.PORT, 10) || 8080;

const serviceInfo = () => ({
  service: 'terrarun-app',
  revision: process.env.K_REVISION || 'local',
  region: process.env.REGION || process.env.K_REGION || 'local',
});

const wantsHtml = (req) => {
  const accept = req.get('accept') || '';
  // Browsers send "text/html,application/xhtml+xml,..." and we want HTML for them.
  // curl with no -H sends "*/*" which we treat as JSON-preferred.
  return accept.includes('text/html');
};

const escapeHtml = (s) =>
  String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const colourizeJson = (value, indent = 2) => {
  const json = JSON.stringify(value, null, indent);
  // Tokenise and wrap each token in a span. Order matters: strings first, then numbers, then bools/null.
  return json
    .replace(/("(\\u[\da-fA-F]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g, (match) => {
      let cls = 'n';
      if (/^"/.test(match)) {
        cls = /:$/.test(match) ? 'k' : 's';
      } else if (/true|false/.test(match)) {
        cls = 'b';
      } else if (/null/.test(match)) {
        cls = 'b';
      }
      return `<span class="${cls}">${escapeHtml(match)}</span>`;
    });
};

const renderApiPage = ({ endpoint, description, data }) =>
  apiPageHtml
    .replaceAll('{{ENDPOINT}}', endpoint)
    .replaceAll('{{DESCRIPTION}}', description)
    .replaceAll('{{JSON_HTML}}', colourizeJson(data));

const sendDual = (req, res, { endpoint, description, data }) => {
  if (wantsHtml(req)) {
    res
      .set('Content-Type', 'text/html; charset=utf-8')
      .send(renderApiPage({ endpoint, description, data }));
  } else {
    res.json(data);
  }
};

app.get('/', (_req, res) => {
  const { revision, region } = serviceInfo();
  const html = landingHtml
    .replaceAll('{{REVISION}}', revision)
    .replaceAll('{{REGION}}', region);
  res.set('Content-Type', 'text/html; charset=utf-8').send(html);
});

app.get('/health', (req, res) => {
  sendDual(req, res, {
    endpoint: '/health',
    description: 'Liveness probe used by the load balancer and Cloud Run. Returns 200 OK whenever the process is up.',
    data: { status: 'ok' },
  });
});

app.get('/api/info', (req, res) => {
  sendDual(req, res, {
    endpoint: '/api/info',
    description: 'Service metadata: the Cloud Run revision currently serving traffic and the region it runs in.',
    data: { ...serviceInfo(), message: 'Hello from Cloud Run' },
  });
});

app.get('/api/time', (req, res) => {
  sendDual(req, res, {
    endpoint: '/api/time',
    description: 'Current server-side time, ISO-8601, UTC.',
    data: { now: new Date().toISOString() },
  });
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`terrarun-app listening on :${port}`);
});

const shutdown = (signal) => {
  console.log(`Received ${signal}, closing server.`);
  server.close(() => process.exit(0));
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
