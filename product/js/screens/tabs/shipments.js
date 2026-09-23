import { supa } from '../../supa.js';

export async function render(view) {
  const { data, error } = await supa
    .from('v_upcoming_shipments')
    .select('*')
    .order('expected_delivery_date', { nullsLast: true });

  if (error) {
    view.innerHTML = `<div class="banner error">${error.message}</div>`;
    return;
  }
  if (!data?.length) {
    view.innerHTML = `<div class="banner info">No upcoming shipments.</div>`;
    return;
  }

  view.innerHTML = `
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>Expected</th>
            <th>Supplier</th>
            <th>Branch</th>
            <th>PO</th>
            <th>Status</th>
            <th style="text-align:right">Progress</th>
          </tr>
        </thead>
        <tbody>
          ${data.map(s => `
            <tr>
              <td>${etaCell(s.expected_delivery_date)}</td>
              <td>${escapeHtml(s.supplier_name)}</td>
              <td>${escapeHtml(s.branch_name)}</td>
              <td class="small">${escapeHtml(s.po_number)}</td>
              <td><span class="badge ${statusBadge(s.status)}">${s.status}</span></td>
              <td style="text-align:right">${s.units_received} / ${s.units_ordered}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function etaCell(dateStr) {
  if (!dateStr) return '<span class="muted">—</span>';
  const d = Math.round((new Date(dateStr) - new Date(new Date().toDateString())) / 86400000);
  const label = d < 0 ? `${-d}d overdue` : d === 0 ? 'today' : `in ${d}d`;
  const cls = d < 0 ? 'expired' : d <= 1 ? 'urgent' : d <= 3 ? 'warn' : 'ok';
  return `<span class="badge ${cls}">${label}</span> <span class="small muted">${dateStr}</span>`;
}
function statusBadge(status) {
  return status === 'sent' ? 'warn' : status === 'partial' ? 'urgent' : 'ok';
}
function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
