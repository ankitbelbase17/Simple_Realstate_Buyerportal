# Real Estate Buyer Portal

A Simple buyer portal where users can register, login, browse properties, and save their favorite properties.

## What's Included

**User Authentication** — Register and login with email/password  
**JWT Security** — Secure session tokens (passwords are hashed)  
**Property Listings** — Browse 8 sample properties with filters  
**Favorites** — Add/remove properties to your favorites list  
**Dashboard** — View your profile and saved favorites  

## Password Requirements

- **Minimum 6 characters**
- No special characters needed
- Simple and easy

---

## How to Run

### 1. Install Node.js

Download [Node.js](https://nodejs.org/) (v18 or higher)

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Start the Server

```bash
npm start
```

The server runs at: **http://localhost:5000**

### 4. Open in Browser

Go to: **http://localhost:5000**

8 sample properties will load automatically.

---

## Quick Start for New User

1. Click **"Create Account"**
2. Enter name, email, and password (min 6 chars)
3. Click **"Create Account"**
4. Now user is in . Browse the properties
5. Click the heart icon to save favorites
6. Click **"My Favourites"** to see your saved properties

---

## Project Files

```
backend/
├── server.js              # Main server
├── db/init.js            # Database with 8 sample properties
├── middleware/auth.js    # Security
└── routes/
    ├── auth.js           # Register & Login
    └── properties.js     # Properties & Favorites

frontend/
├── index.html            # Login page
├── dashboard.html        # Main app
└── js/ & css/            # Styling & logic
```


---

## Tech Stack

- **Backend**: Node.js + Express
- **Database**: SQLite
- **Security**: JWT + bcrypt
- **Frontend**: HTML + CSS + JavaScript

---

## Example Flows

### Sign Up → Login → Add Favourite

```
1. Open frontend/index.html
2. Click "Create Account"
3. Fill in name, email, and password (min 6 chars) → submit
4. You are redirected to the dashboard automatically

5. Browse the property grid
6. Click the 🤍 heart button on any property card
7. Toast: "Added to favourites! ❤️"
8. The heart turns red (❤️) and the count in the sidebar updates

9. Click "My Favourites" in the sidebar
10.Only your saved properties appear here

11. Click ❤️ on a favourited card to remove it
12. → Toast: "Removed from favourites."

13. Click "Sign Out" to logout
```

### API via `curl`

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Smith","email":"ankitb@.com","password":"abcdef"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com","password":"secret123"}'

# List properties (use token from login response)
curl http://localhost:5000/api/properties \
  -H "Authorization: Bearer <TOKEN>"

# Add property #1 to favourites
curl -X POST http://localhost:5000/api/favourites/1 \
  -H "Authorization: Bearer <TOKEN>"

# Remove property #1 from favourites
curl -X DELETE http://localhost:5000/api/favourites/1 \
  -H "Authorization: Bearer <TOKEN>"
```

---

## Security Notes

- Passwords are **not stored in plain text** — hashed with `bcrypt` (12 salt rounds)
- JWTs expire after **7 days**
- Each user can only view and modify **their own** favourites (enforced server-side via JWT user ID)
- Input is **validated** on both client and server
- CORS is restricted to localhost development origins

---

## Database Schema

```sql
users       (id, name, email, password_hash, role, created_at)
properties  (id, title, location, price, type, bedrooms, bathrooms, area_sqft, image_url, description)
favourites  (id, user_id → users.id, property_id → properties.id, created_at)  [UNIQUE user+property]
```

The SQLite database file (`portal.db`) is created automatically in the `backend/db/` folder on first run.
