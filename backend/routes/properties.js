const express = require('express');
const { getDb } = require('../db/init');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require auth
router.use(authenticate);

// ─── GET /api/properties ──────────────────────────────────────────────────────
// List all available properties with a flag indicating if current user favourited them
router.get('/properties', (req, res) => {
  const db = getDb();
  const properties = db.prepare(`
    SELECT p.*,
      CASE WHEN f.id IS NOT NULL THEN 1 ELSE 0 END AS is_favourited
    FROM properties p
    LEFT JOIN favourites f ON f.property_id = p.id AND f.user_id = ?
    ORDER BY p.id ASC
  `).all(req.user.id);

  return res.json({ properties });
});

// ─── GET /api/favourites ──────────────────────────────────────────────────────
router.get('/favourites', (req, res) => {
  const db = getDb();
  const favourites = db.prepare(`
    SELECT p.*, f.created_at AS favourited_at
    FROM favourites f
    JOIN properties p ON p.id = f.property_id
    WHERE f.user_id = ?
    ORDER BY f.created_at DESC
  `).all(req.user.id);

  return res.json({ favourites });
});

// ─── POST /api/favourites/:propertyId ────────────────────────────────────────
router.post('/favourites/:propertyId', (req, res) => {
  const db = getDb();
  const propertyId = parseInt(req.params.propertyId, 10);

  if (!propertyId || isNaN(propertyId)) {
    return res.status(400).json({ error: 'Invalid property ID.' });
  }

  const property = db.prepare('SELECT id FROM properties WHERE id = ?').get(propertyId);
  if (!property) {
    return res.status(404).json({ error: 'Property not found.' });
  }

  // Check if already favourited
  const existing = db.prepare(
    'SELECT id FROM favourites WHERE user_id = ? AND property_id = ?'
  ).get(req.user.id, propertyId);

  if (existing) {
    return res.status(409).json({ error: 'Property is already in your favourites.' });
  }

  db.prepare('INSERT INTO favourites (user_id, property_id) VALUES (?, ?)').run(req.user.id, propertyId);

  return res.status(201).json({ message: 'Property added to favourites!' });
});

// ─── DELETE /api/favourites/:propertyId ─────────────────────────────────────
router.delete('/favourites/:propertyId', (req, res) => {
  const db = getDb();
  const propertyId = parseInt(req.params.propertyId, 10);

  if (!propertyId || isNaN(propertyId)) {
    return res.status(400).json({ error: 'Invalid property ID.' });
  }

  const result = db.prepare(
    'DELETE FROM favourites WHERE user_id = ? AND property_id = ?'
  ).run(req.user.id, propertyId);

  if (result.changes === 0) {
    return res.status(404).json({ error: 'This property is not in your favourites.' });
  }

  return res.json({ message: 'Property removed from favourites.' });
});

module.exports = router;
