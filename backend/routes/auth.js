const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDb } = require('../db/init');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

// ─── Validation helpers ───────────────────────────────────────────────────────
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function validatePassword(password) {
  return typeof password === 'string' && password.length >= 6;
}

// ─── POST /api/auth/register ──────────────────────────────────────────────────
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body || {};

  // Validation
  if (!name || typeof name !== 'string' || name.trim().length < 2) {
    return res.status(400).json({ error: 'Name must be at least 2 characters.' });
  }
  if (!email || !validateEmail(email)) {
    return res.status(400).json({ error: 'A valid email address is required.' });
  }
  if (!validatePassword(password)) {
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });
  }

  const db = getDb();

  // Check duplicate
  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase().trim());
  if (existing) {
    return res.status(409).json({ error: 'An account with this email already exists.' });
  }

  // Hash password
  const hash = await bcrypt.hash(password, 12);

  const result = db.prepare(
    'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)'
  ).run(name.trim(), email.toLowerCase().trim(), hash, 'buyer');

  const token = jwt.sign(
    { id: result.lastInsertRowid, email: email.toLowerCase().trim(), name: name.trim(), role: 'buyer' },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  return res.status(201).json({
    message: 'Account created successfully!',
    token,
    user: { id: result.lastInsertRowid, name: name.trim(), email: email.toLowerCase().trim(), role: 'buyer' }
  });
});

// ─── POST /api/auth/login ─────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !validateEmail(email)) {
    return res.status(400).json({ error: 'A valid email address is required.' });
  }
  if (!password) {
    return res.status(400).json({ error: 'Password is required.' });
  }

  const db = getDb();
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase().trim());

  if (!user) {
    return res.status(401).json({ error: 'Invalid email or password.' });
  }

  const match = await bcrypt.compare(password, user.password);
  if (!match) {
    return res.status(401).json({ error: 'Invalid email or password.' });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, name: user.name, role: user.role },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  return res.status(200).json({
    message: 'Login successful!',
    token,
    user: { id: user.id, name: user.name, email: user.email, role: user.role }
  });
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────
const { authenticate } = require('../middleware/auth');
router.get('/me', authenticate, (req, res) => {
  const db = getDb();
  const user = db.prepare('SELECT id, name, email, role, created_at FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found.' });
  return res.json({ user });
});

module.exports = router;
