const express = require('express');
const cors = require('cors');
const path = require('path');
const client = require('prom-client');

// Initialize DB on startup
const { getDb } = require('./db/init');
getDb(); // triggers schema creation + seeding

const authRoutes = require('./routes/auth');
const propertiesRoutes = require('./routes/properties');

const app = express();
const PORT = process.env.PORT || 5000;

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'buyer_portal_' });

const httpRequestDuration = new client.Histogram({
  name: 'buyer_portal_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [register]
});

app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    const route = req.route && req.route.path ? req.route.path : req.path;
    end({ method: req.method, route, status_code: res.statusCode });
  });
  next();
});

app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:5500', 'http://127.0.0.1:5500', 'null'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const frontendPath = path.join(__dirname, '..', 'frontend');
app.use(express.static(frontendPath));

app.use('/api/auth', authRoutes);

// Public health endpoint for CI checks and uptime monitoring
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', message: 'Techcraft Buyer Portal API is running - v2 demo change again.' });
});

// Protected API routes
app.use('/api', propertiesRoutes);

app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found.' });
});

app.use((err, _req, res, _next) => {
  console.error('[Error]', err.message);
  res.status(500).json({ error: 'Internal server error. Please try again.' });
});

app.listen(PORT, () => {
  console.log(`\nTechcraft Buyer Portal API`);
  console.log(`Server running at: http://localhost:${PORT}`);
  console.log(`Auth endpoints:    /api/auth/register | /api/auth/login`);
  console.log(`Property routes:   /api/properties | /api/favourites`);
  console.log(`Metrics endpoint:  /metrics\n`);
});
