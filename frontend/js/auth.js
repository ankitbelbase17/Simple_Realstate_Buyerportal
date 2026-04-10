/**
 * auth.js — Login / Register page logic
 */

// Redirect to dashboard if already logged in
(function checkAlreadyLoggedIn() {
  if (localStorage.getItem('tc_token')) {
    window.location.replace('dashboard.html');
  }
})();

/* ── Tab switching ─────────────────────────────────────────────────────────── */
function switchTab(tab) {
  const loginForm = document.getElementById('form-login');
  const regForm   = document.getElementById('form-register');
  const tabLogin  = document.getElementById('tab-login');
  const tabReg    = document.getElementById('tab-register');

  const isLogin = tab === 'login';
  loginForm.classList.toggle('active', isLogin);
  regForm.classList.toggle('active', !isLogin);
  tabLogin.classList.toggle('active', isLogin);
  tabReg.classList.toggle('active', !isLogin);
  tabLogin.setAttribute('aria-selected', String(isLogin));
  tabReg.setAttribute('aria-selected', String(!isLogin));

  // Clear errors when switching
  clearFormErrors('form-login');
  clearFormErrors('form-register');
}

/* ── Field validation helpers ──────────────────────────────────────────────── */
function setError(groupId, errorId, message) {
  document.getElementById(groupId).classList.add('has-error');
  document.getElementById(errorId).textContent = message;
}
function clearError(groupId) {
  document.getElementById(groupId).classList.remove('has-error');
}
function clearFormErrors(formId) {
  document.querySelectorAll(`#${formId} .form-group`).forEach(g => g.classList.remove('has-error'));
}

function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/* ── Set button loading state ──────────────────────────────────────────────── */
function setLoading(btnId, loading, text = 'Submit') {
  const btn = document.getElementById(btnId);
  btn.disabled = loading;
  btn.innerHTML = loading
    ? `<span class="spinner"></span> <span>Please wait…</span>`
    : `<span>${text}</span>`;
}

/* ── Login handler ─────────────────────────────────────────────────────────── */
async function handleLogin(e) {
  e.preventDefault();
  clearFormErrors('form-login');

  const email    = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  let hasError   = false;

  if (!email || !validateEmail(email)) {
    setError('fg-login-email', 'err-login-email', 'Please enter a valid email address.');
    hasError = true;
  }
  if (!password) {
    setError('fg-login-password', 'err-login-password', 'Password is required.');
    hasError = true;
  }
  if (hasError) return;

  setLoading('btn-login', true, 'Sign In');
  const { ok, data } = await api.post('/auth/login', { email, password });
  setLoading('btn-login', false, 'Sign In');

  if (!ok) {
    showToast(data.error || 'Login failed. Please try again.', 'error');
    if (data.error && data.error.toLowerCase().includes('password')) {
      setError('fg-login-password', 'err-login-password', data.error);
    } else {
      setError('fg-login-email', 'err-login-email', data.error || 'Login failed.');
    }
    return;
  }

  localStorage.setItem('tc_token', data.token);
  localStorage.setItem('tc_user', JSON.stringify(data.user));
  showToast(`Welcome back, ${data.user.name}! 🎉`, 'success');
  setTimeout(() => window.location.replace('dashboard.html'), 800);
}

/* ── Register handler ──────────────────────────────────────────────────────── */
async function handleRegister(e) {
  e.preventDefault();
  clearFormErrors('form-register');

  const name     = document.getElementById('reg-name').value.trim();
  const email    = document.getElementById('reg-email').value.trim();
  const password = document.getElementById('reg-password').value;
  const confirm  = document.getElementById('reg-confirm').value;
  let hasError   = false;

  if (!name || name.length < 2) {
    setError('fg-reg-name', 'err-reg-name', 'Full name must be at least 2 characters.');
    hasError = true;
  }
  if (!email || !validateEmail(email)) {
    setError('fg-reg-email', 'err-reg-email', 'Please enter a valid email address.');
    hasError = true;
  }
  if (!password || password.length < 6) {
    setError('fg-reg-password', 'err-reg-password', 'Password must be at least 6 characters.');
    hasError = true;
  }
  if (password !== confirm) {
    setError('fg-reg-confirm', 'err-reg-confirm', 'Passwords do not match.');
    hasError = true;
  }
  if (hasError) return;

  setLoading('btn-register', true, 'Create Account');
  const { ok, data } = await api.post('/auth/register', { name, email, password });
  setLoading('btn-register', false, 'Create Account');

  if (!ok) {
    showToast(data.error || 'Registration failed. Please try again.', 'error');
    if (data.error && data.error.toLowerCase().includes('email')) {
      setError('fg-reg-email', 'err-reg-email', data.error);
    }
    return;
  }

  localStorage.setItem('tc_token', data.token);
  localStorage.setItem('tc_user', JSON.stringify(data.user));
  showToast(`Account created! Welcome, ${data.user.name}! 🏠`, 'success');
  setTimeout(() => window.location.replace('dashboard.html'), 800);
}
