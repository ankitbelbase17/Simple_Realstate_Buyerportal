/**
 * api.js — lightweight API wrapper
 * Sets the base URL and attaches JWT from localStorage automatically.
 */

const API_BASE = 'http://localhost:5000/api';

async function apiRequest(endpoint, options = {}) {
  const token = localStorage.getItem('tc_token');
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data };
}

// Convenience methods
const api = {
  get:    (ep)           => apiRequest(ep, { method: 'GET' }),
  post:   (ep, body)     => apiRequest(ep, { method: 'POST',   body }),
  delete: (ep)           => apiRequest(ep, { method: 'DELETE' }),
};
