import { supa, signOut } from '../supa.js';

// Post-login shell. Routes vary by role. For MVP we render a role-appropriate
// landing page with a top bar and a bottom tab bar.
export async function renderShell(root, session, onSignOut) {
  const isKiosk = session.kind === 'kiosk';
  const label = isKiosk
    ? `${session.kiosk.label} · ${session.kiosk.branches?.name ?? ''}`
    : `${session.profile.display_name} · ${session.profile.role}${session.profile.branches ? ' · ' + session.profile.branches.name : ''}`;

  const tabs = isKiosk
    ? [
        { key: 'scan',      label: 'Scan' },
        { key: 'alerts',    label: 'Alerts' },
        { key: 'rounds',    label: 'Rounds' },
        { key: 'stock',     label: 'Stock' },
      ]
    : session.profile.role === 'admin'
      ? [
          { key: 'dashboard', label: 'Overview' },
          { key: 'stock',     label: 'Stock' },
          { key: 'shipments', label: 'Shipments' },
          { key: 'revops',    label: 'Rev ops' },
          { key: 'admin',     label: 'Admin' },
        ]
      : session.profile.role === 'manager'
      ? [
          { key: 'dashboard', label: 'Overview' },
          { key: 'stock',     label: 'Stock' },
          { key: 'shipments', label: 'Shipments' },
          { key: 'alerts',    label: 'Alerts' },
        ]
      : [ // viewer
          { key: 'dashboard', label: 'Overview' },
          { key: 'stock',     label: 'Stock' },
          { key: 'shipments', label: 'Shipments' },
          { key: 'revops',    label: 'Rev ops' },
        ];

  root.innerHTML = `
    <div class="shell">
      <header class="topbar">
        <h1>ShelfLife</h1>
        <div class="row-h" style="gap:12px">
          <span class="who">${escapeHtml(label)}</span>
          <button id="signout" class="ghost small">Sign out</button>
        </div>
      </header>
      <main id="view"></main>
      <nav class="tabbar">
        ${tabs.map(t => `<button data-tab="${t.key}">${t.label}</button>`).join('')}
      </nav>
    </div>
  `;

  root.querySelector('#signout').addEventListener('click', async () => {
    await signOut();
    onSignOut();
  });

  const view = root.querySelector('#view');
  const tabbar = root.querySelector('.tabbar');

  async function select(key) {
    tabbar.querySelectorAll('button').forEach((b) => {
      b.setAttribute('aria-current', b.dataset.tab === key ? 'page' : 'false');
    });
    await renderTab(key, view, session);
  }

  tabbar.addEventListener('click', (e) => {
    const b = e.target.closest('button[data-tab]');
    if (b) select(b.dataset.tab);
  });

  await select(tabs[0].key);
}

async function renderTab(key, view, session) {
  view.innerHTML = `<div class="banner info">Loading…</div>`;
  const mod = await import(`./tabs/${key}.js`).catch(() => null);
  if (mod?.render) {
    await mod.render(view, session);
  } else {
    view.innerHTML = `<div class="banner info">Tab "${escapeHtml(key)}" not implemented yet.</div>`;
  }
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
