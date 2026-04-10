const express = require('express');
const cors = require('cors');
const path = require('path');

// Initialize DB on startup
const { getDb } = require('./db/init');
getDb(); // triggers schema creation + seeding

const authRoutes = require('./routes/auth');
const propertiesRoutes = require('./routes/properties');

const app = express();
const PORT = process.env.PORT || 5000;

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:5500', 'http://127.0.0.1:5500', 'null'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ─── Serve Frontend (static) ──────────────────────────────────────────────────
const frontendPath = path.join(__dirname, '..', 'frontend');
app.use(express.static(frontendPath));

// ─── API Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api', propertiesRoutes);

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', message: 'Techcraft Buyer Portal API is running.' });
});

// ─── 404 Handler ─────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found.' });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[Error]', err.message);
  res.status(500).json({ error: 'Internal server error. Please try again.' });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\nTechcraft Buyer Portal API`);
  console.log(`Server running at: http://localhost:${PORT}`);
  console.log(`Auth endpoints:    /api/auth/register | /api/auth/login`);
  console.log(`Property routes:   /api/properties | /api/favourites\n`);
});
