const Database = require('better-sqlite3');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Store DB outside OneDrive to avoid WAL locking issues on synced drives
const DB_DIR  = path.join(os.tmpdir(), 'techcraft_portal');
if (!fs.existsSync(DB_DIR)) fs.mkdirSync(DB_DIR, { recursive: true });
const DB_PATH = path.join(DB_DIR, 'portal.db');
console.log('[DB] SQLite path:', DB_PATH);

let db;

function getDb() {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma('journal_mode = DELETE');
    db.pragma('foreign_keys = ON');
    initSchema();
  }
  return db;
}

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      name      TEXT    NOT NULL,
      email     TEXT    NOT NULL UNIQUE,
      password  TEXT    NOT NULL,
      role      TEXT    NOT NULL DEFAULT 'buyer',
      created_at TEXT   DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS properties (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      title       TEXT    NOT NULL,
      location    TEXT    NOT NULL,
      price       TEXT    NOT NULL,
      type        TEXT    NOT NULL,
      bedrooms    INTEGER,
      bathrooms   INTEGER,
      area_sqft   INTEGER,
      image_url   TEXT,
      description TEXT
    );

    CREATE TABLE IF NOT EXISTS favourites (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
      created_at  TEXT    DEFAULT (datetime('now')),
      UNIQUE(user_id, property_id)
    );
  `);

  // Seed sample properties if empty
  const count = db.prepare('SELECT COUNT(*) as c FROM properties').get();
  if (count.c === 0) {
    const insert = db.prepare(`
      INSERT INTO properties (title, location, price, type, bedrooms, bathrooms, area_sqft, image_url, description)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const seedMany = db.transaction((rows) => {
      rows.forEach(r => insert.run(...r));
    });
    seedMany([
      ['Skyline Residency', 'Kathmandu, Baneshwor', 'NPR 1.85 Cr', 'Apartment', 3, 2, 1450, 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600', 'Modern high-rise apartment with panoramic city views and premium finishes.'],
      ['Green Valley Villa', 'Lalitpur, Patan', 'NPR 3.20 Cr', 'Villa', 4, 3, 2800, 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600', 'Spacious villa nestled in a lush green neighbourhood with private garden.'],
      ['City Center Studio', 'Kathmandu, New Road', 'NPR 75 Lakh', 'Studio', 1, 1, 550, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600', 'Compact, stylish studio perfect for young professionals in the heart of the city.'],
      ['Sunrise Heights', 'Bhaktapur, Suryabinayak', 'NPR 2.10 Cr', 'House', 5, 4, 3200, 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=600', 'Expansive family home with mountain views and modern amenities.'],
      ['Lakeside Retreat', 'Pokhara, Lakeside', 'NPR 4.50 Cr', 'Villa', 6, 5, 4100, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600', 'Luxurious lake-facing villa with infinity pool and breathtaking Annapurna views.'],
      ['Urban Nest', 'Kathmandu, Thamel', 'NPR 1.20 Cr', 'Apartment', 2, 2, 980, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600', 'Chic 2-bedroom apartment in the vibrant Thamel district, fully furnished.'],
      ['Heritage Bungalow', 'Patan, Mangalbazar', 'NPR 5.80 Cr', 'Bungalow', 4, 3, 3600, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600', 'Restored heritage bungalow blending traditional Newari architecture with modern comforts.'],
      ['Cliff View Condo', 'Nagarkot', 'NPR 2.95 Cr', 'Condo', 3, 2, 1700, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=600', 'Stunning condo perched on the Nagarkot cliff with Himalayan sunrise views.'],
    ]);
  }
}

module.exports = { getDb };
