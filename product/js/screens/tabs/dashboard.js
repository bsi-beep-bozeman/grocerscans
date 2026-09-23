import { supa } from '../../supa.js';

export async function render(view, session) {
  const scope = session.kind === 'user' && session.profile.branch_id
    ? { branch_id: session.profile.branch_id }
    : null;

  const [{ data: shipments }, { data: openAlerts }, { data: stock }] = await Promise.all([
    supa.from('v_upcoming_shipments').select('*').order('expected_delivery_date').limit(5),
    supa.from('alerts').select('id, threshold_days, batch_id, branch_id').eq('status', 'open'),
    supa.from('v_stock_by_product').select('*').order('next_expiry', { nullsLast: true }).limit(5),
  ]);

  const shipRows = (shipments ?? []).map(s => `
    <div class="row">
      <div>
        <div>${escapeHtml(s.supplier_name)} → ${escapeHtml(s.branch_name)}</div>
        <div class="meta">${escapeHtml(s.po_number)} · ${s.units_ordered - s.units_received} units pending</div>
      </div>
      <div class="days">${daysFromNow(s.expected_delivery_date)}</div>
    </div>
  `).join('');

  const stockRows = (stock ?? []).map(s => `
    <div class="row">
      <div>
        <div>${escapeHtml(s.product_name)} <span class="meta">· ${escapeHtml(s.branch_name)}</span></div>
        <div class="meta">${s.units_on_hand} on hand · last received ${s.last_received ?? '—'}</div>
      </div>
      <div class="days ${urgencyClass(s.next_expiry)}">${daysFromNow(s.next_expiry)}</div>
    </div>
  `).join('');

  view.innerHTML = `
    <section class="stack">
      <div class="card">
        <div class="row-h" style="justify-content:space-between; margin-bottom:12px">
          <strong>Open alerts</strong>
          <span class="days ${openAlerts?.length > 0 ? 'urgent' : 'ok'}">${openAlerts?.length ?? 0}</span>
        </div>
        <p class="small muted">Head to the Alerts tab to resolve.</p>
      </div>

      <div class="card">
        <div class="row-h" style="justify-content:space-between; margin-bottom:12px">
          <strong>Next shipments</strong>
          <a href="#" class="small muted" data-goto="shipments">See all</a>
        </div>
        <div class="list">${shipRows || '<div class="banner info">No shipments scheduled.</div>'}</div>
      </div>

      <div class="card">
        <div class="row-h" style="justify-content:space-between; margin-bottom:12px">
          <strong>Stock expiring soon</strong>
          <a href="#" class="small muted" data-goto="stock">See all</a>
        </div>
        <div class="list">${stockRows || '<div class="banner info">No stock on hand.</div>'}</div>
      </div>
    </section>
  `;

  view.addEventListener('click', (e) => {
    const goto = e.target.closest('[data-goto]');
    if (goto) {
      e.preventDefault();
      document.querySelector(`.tabbar button[data-tab="${goto.dataset.goto}"]`)?.click();
    }
  });
}

function daysFromNow(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const diff = Math.round((d - new Date(new Date().toDateString())) / 86400000);
  return diff;
}

function urgencyClass(dateStr) {
  const d = daysFromNow(dateStr);
  if (d === '—') return '';
  if (d < 0) return 'expired';
  if (d <= 2) return 'urgent';
  if (d <= 7) return 'warn';
  return 'ok';
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
