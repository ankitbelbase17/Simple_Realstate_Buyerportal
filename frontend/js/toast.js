/**
 * toast.js — show elegant toast notifications
 * Usage: showToast('message', 'success' | 'error' | 'info')
 */

const ICONS = { success: '✅', error: '❌', info: 'ℹ️' };

function showToast(message, type = 'info', duration = 3500) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${ICONS[type] || 'ℹ️'}</span>
    <span class="toast-msg">${message}</span>
  `;
  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('toast-out');
    toast.addEventListener('animationend', () => toast.remove(), { once: true });
  }, duration);
}
