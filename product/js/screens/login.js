import { supa } from '../supa.js';

export function renderLogin(root, onSuccess) {
  root.innerHTML = `
    <div class="center-page">
      <div class="card">
        <h1>ShelfLife</h1>
        <div id="login-banner"></div>
        <form id="login-form" class="stack">
          <div class="field">
            <label for="email">Email</label>
            <input type="email" id="email" required autocomplete="username"
                   placeholder="you@alsafa.local" />
          </div>
          <div class="field">
            <label for="password">Password</label>
            <input type="password" id="password" required autocomplete="current-password" />
          </div>
          <button type="submit" class="primary" style="width:100%">Sign in</button>
          <p class="small muted" style="text-align:center; margin-top:12px">
            Kiosk devices sign in with their assigned account.<br />
            Staff use PIN after the kiosk is signed in.
          </p>
        </form>
      </div>
    </div>
  `;

  const form = root.querySelector('#login-form');
  const banner = root.querySelector('#login-banner');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    banner.innerHTML = '';
    const email = form.email.value.trim();
    const password = form.password.value;
    const btn = form.querySelector('button[type="submit"]');
    btn.disabled = true; btn.textContent = 'Signing in…';

    const { error } = await supa.auth.signInWithPassword({ email, password });
    if (error) {
      banner.innerHTML = `<div class="banner error">${escapeHtml(error.message)}</div>`;
      btn.disabled = false; btn.textContent = 'Sign in';
      return;
    }
    onSuccess();
  });
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
