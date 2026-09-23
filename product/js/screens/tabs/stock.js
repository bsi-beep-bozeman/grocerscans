import { supa } from '../../supa.js';

export async function render(view) {
  const { data, error } = await supa
    .from('v_stock_by_product')
    .select('*')
    .order('next_expiry', { nullsLast: true });

  if (error) {
    view.innerHTML = `<div class="banner error">${error.message}</div>`;
    return;
  }
  if (!data?.length) {
    view.innerHTML = `<div class="banner info">No stock on hand yet.</div>`;
    return;
  }

  view.innerHTML = `
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Branch</th>
            <th style="text-align:right">On hand</th>
            <th>Next expiry</th>
            <th>Last received</th>
          </tr>
        </thead>
        <tbody>
          ${data.map(s => `
            <tr>
              <td>${escapeHtml(s.product_name)}<div class="meta small">${escapeHtml(s.category_name)}</div></td>
              <td>${escapeHtml(s.branch_name)}</td>
              <td style="text-align:right">${s.units_on_hand}</td>
              <td>${expiryCell(s.next_expiry)}</td>
              <td class="small muted">${s.last_received ?? '—'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function expiryCell(dateStr) {
  if (!dateStr) return '<span class="muted">—</span>';
  const d = Math.round((new Date(dateStr) - new Date(new Date().toDateString())) / 86400000);
  const cls = d < 0 ? 'expired' : d <= 2 ? 'urgent' : d <= 7 ? 'warn' : 'ok';
  const label = d < 0 ? `expired ${-d}d ago` : d === 0 ? 'today' : `in ${d}d`;
  return `<span class="badge ${cls}">${label}</span> <span class="small muted">${dateStr}</span>`;
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
