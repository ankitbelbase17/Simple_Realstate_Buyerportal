/**
 * dashboard.js — Buyer Portal Dashboard
 * Handles: auth guard, user info, property listing, favouriting
 */

/* ── Auth Guard ────────────────────────────────────────────────────────────── */
const token = localStorage.getItem('tc_token');
if (!token) window.location.replace('index.html');

let currentUser = null;
try { currentUser = JSON.parse(localStorage.getItem('tc_user')); } catch (_) {}

let allProperties  = [];
let currentFilter  = 'all';
let favouritedIds  = new Set();
let pendingToggles = new Set(); // prevent double-clicks

/* ── Init ──────────────────────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', async () => {
  populateUserInfo();
  await loadAll();
});

function populateUserInfo() {
  if (!currentUser) return;
  const initial = (currentUser.name || '?')[0].toUpperCase();

  setText('user-avatar',      initial);
  setText('sidebar-name',     currentUser.name);
  setText('sidebar-email',    currentUser.email);
  setRoleBadge('sidebar-role', currentUser.role);

  setText('profile-avatar',   initial);
  setText('profile-name',     currentUser.name);
  setText('profile-email',    currentUser.email);
  setRoleBadge('profile-role', currentUser.role);

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  setText('topbar-greeting', `${greeting}, ${currentUser.name.split(' ')[0]}!`);
}

function setRoleBadge(id, role) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = role;
  el.className = `badge badge-${role}`;
}

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

/* ── Load data ─────────────────────────────────────────────────────────────── */
async function loadAll() {
  const [propsRes, favsRes] = await Promise.all([
    api.get('/properties'),
    api.get('/favourites'),
  ]);

  if (!propsRes.ok) {
    // Token expired
    if (propsRes.status === 401) { handleLogout(); return; }
    showToast('Failed to load properties.', 'error');
    return;
  }

  allProperties = propsRes.data.properties || [];
  const favs    = favsRes.ok ? (favsRes.data.favourites || []) : [];
  favouritedIds = new Set(favs.map(f => f.id));

  // Update stat cards
  setText('stat-total', allProperties.length);
  setText('stat-favs',  favouritedIds.size);
  const types = new Set(allProperties.map(p => p.type));
  setText('stat-types', types.size);

  // Favourites count badge
  updateFavCount(favouritedIds.size);

  // Profile fav count
  setText('profile-favcount', `${favouritedIds.size} propert${favouritedIds.size === 1 ? 'y' : 'ies'}`);

  // Member since
  if (favsRes.ok) {
    const meRes = await api.get('/auth/me');
    if (meRes.ok && meRes.data.user) {
      const d = new Date(meRes.data.user.created_at + 'Z');
      setText('profile-joined', d.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }));
    }
  }

  renderProperties(allProperties);
  renderFavourites(favs);
}

/* ── Render property cards ─────────────────────────────────────────────────── */
function renderProperties(properties) {
  const grid = document.getElementById('property-grid');
  if (!grid) return;

  if (!properties.length) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column:1/-1">
        <div class="empty-icon">🔍</div>
        <h3>No properties found</h3>
        <p>Try selecting a different filter.</p>
      </div>`;
    return;
  }

  grid.innerHTML = properties.map(p => propertyCardHTML(p, favouritedIds.has(p.id))).join('');
}

function renderFavourites(favs) {
  const grid = document.getElementById('favourites-grid');
  if (!grid) return;

  setText('fav-subtitle', `${favs.length} saved propert${favs.length === 1 ? 'y' : 'ies'}`);
  setText('profile-favcount', `${favs.length} propert${favs.length === 1 ? 'y' : 'ies'}`);

  if (!favs.length) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column:1/-1">
        <h3>No favourites yet</h3>
        <p>Browse properties and tap the heart icon to save your favourites here.</p>
        <button class="btn btn-primary btn-sm" onclick="showSection('browse')">Browse Properties</button>
      </div>`;
    return;
  }

  grid.innerHTML = favs.map(p => propertyCardHTML(p, true)).join('');
}

function propertyCardHTML(p, isFav) {
  const typeClass = { Apartment: 'apt', Villa: 'villa', Studio: 'studio', House: 'house', Condo: 'apt', Bungalow: 'villa' }[p.type] || 'apt';
  const heartIcon = isFav ? '❤️' : '🤍';
  const favClass  = isFav ? 'favourited' : '';

  return `
    <article class="property-card" data-id="${p.id}" data-type="${p.type}">
      <div class="property-img" style="overflow:hidden; position:relative;">
        <img src="${escHtml(p.image_url)}" alt="${escHtml(p.title)}" loading="lazy"
             onerror="this.src='https://images.unsplash.com/photo-1560184897-ae75f418493e?w=600'" />
        <button
          class="fav-btn ${favClass}"
          id="fav-btn-${p.id}"
          aria-label="${isFav ? 'Remove from' : 'Add to'} favourites"
          onclick="toggleFavourite(${p.id}, this)">
          ${heartIcon}
        </button>
      </div>
      <div class="property-body">
        <h3 class="property-title">${escHtml(p.title)}</h3>
        <div class="property-location">${escHtml(p.location)}</div>
        <p class="property-desc">${escHtml(p.description || '')}</p>
        <div class="property-meta">
          ${p.bedrooms  ? `<span class="meta-item">${p.bedrooms} bed</span>` : ''}
          ${p.bathrooms ? `<span class="meta-item">${p.bathrooms} bath</span>` : ''}
          ${p.area_sqft ? `<span class="meta-item">${p.area_sqft.toLocaleString()} sqft</span>` : ''}
        </div>
        <div class="property-footer">
          <span class="property-price">${escHtml(p.price)}</span>
          <span class="badge badge-${typeClass}">${escHtml(p.type)}</span>
        </div>
      </div>
    </article>`;
}

/* ── Toggle Favourite ──────────────────────────────────────────────────────── */
async function toggleFavourite(propertyId, btn) {
  if (pendingToggles.has(propertyId)) return;
  pendingToggles.add(propertyId);
  btn.classList.add('loading');

  const isFav = favouritedIds.has(propertyId);

  if (isFav) {
    const { ok, data } = await api.delete(`/favourites/${propertyId}`);
    if (ok) {
      favouritedIds.delete(propertyId);
      showToast('Removed from favourites.', 'info');
    } else {
      showToast(data.error || 'Could not remove.', 'error');
    }
  } else {
    const { ok, data } = await api.post(`/favourites/${propertyId}`);
    if (ok) {
      favouritedIds.add(propertyId);
      showToast('Added to favourites! ❤️', 'success');
    } else {
      showToast(data.error || 'Could not add.', 'error');
    }
  }

  pendingToggles.delete(propertyId);
  btn.classList.remove('loading');

  // Update all heart buttons with this id
  document.querySelectorAll(`[id="fav-btn-${propertyId}"]`).forEach(b => {
    const nowFav = favouritedIds.has(propertyId);
    b.textContent = nowFav ? '❤️' : '🤍';
    b.classList.toggle('favourited', nowFav);
    b.setAttribute('aria-label', (nowFav ? 'Remove from' : 'Add to') + ' favourites');
  });

  // Update counts
  updateFavCount(favouritedIds.size);
  setText('stat-favs', favouritedIds.size);
  setText('profile-favcount', `${favouritedIds.size} propert${favouritedIds.size === 1 ? 'y' : 'ies'}`);

  // Refresh favourites section data
  refreshFavouritesSection();
}

async function refreshFavouritesSection() {
  const { ok, data } = await api.get('/favourites');
  if (ok) renderFavourites(data.favourites || []);
}

/* ── Filter ────────────────────────────────────────────────────────────────── */
function applyFilter(btn) {
  currentFilter = btn.dataset.filter;
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.toggle('active', b === btn));
  const filtered = currentFilter === 'all'
    ? allProperties
    : allProperties.filter(p => p.type === currentFilter);
  renderProperties(filtered);
}

/* ── Navigation ────────────────────────────────────────────────────────────── */
const SECTION_TITLES = { browse: 'Browse Properties', favourites: 'My Favourites', profile: 'My Profile' };

function showSection(name) {
  document.querySelectorAll('.page-section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => {
    n.classList.remove('active');
    n.removeAttribute('aria-current');
  });

  document.getElementById(`section-${name}`).classList.add('active');
  const navBtn = document.getElementById(`nav-${name}`);
  if (navBtn) { navBtn.classList.add('active'); navBtn.setAttribute('aria-current', 'page'); }
  setText('topbar-title', SECTION_TITLES[name] || name);
}

/* ── Logout ────────────────────────────────────────────────────────────────── */
function handleLogout() {
  localStorage.removeItem('tc_token');
  localStorage.removeItem('tc_user');
  showToast('You have been signed out.', 'info');
  setTimeout(() => window.location.replace('index.html'), 600);
}

/* ── Fav count badge ───────────────────────────────────────────────────────── */
function updateFavCount(count) {
  setText('fav-count', count);
}

/* ── Utility ───────────────────────────────────────────────────────────────── */
function escHtml(str) {
  return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
