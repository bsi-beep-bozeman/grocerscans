import { supa } from '../../supa.js';

export async function render(view) {
  const [suppliers, response, waste] = await Promise.all([
    supa.from('v_supplier_scorecard').select('*').order('discarded_cost_dollars', { ascending: false }),
    supa.from('v_alert_response_times').select('*').order('week', { ascending: false }).limit(8),
    supa.from('v_waste_recovery').select('*').order('week', { ascending: false }).limit(8),
  ]);

  view.innerHTML = `
    <section class="stack">
      ${section('Supplier scorecard', suppliers.error?.message, `
        <table><thead><tr>
          <th>Supplier</th><th style="text-align:right">Batches</th>
          <th style="text-align:right">Avg shelf life received</th>
          <th style="text-align:right">Short-dated</th>
          <th style="text-align:right">Discarded $</th>
        </tr></thead><tbody>
          ${(suppliers.data ?? []).map(s => `
            <tr>
              <td>${escapeHtml(s.supplier_name)}</td>
              <td style="text-align:right">${s.batches_received}</td>
              <td style="text-align:right">${s.avg_days_shelf_life_received ?? '—'} d</td>
              <td style="text-align:right">${s.short_dated_batches}</td>
              <td style="text-align:right">$${Number(s.discarded_cost_dollars ?? 0).toFixed(2)}</td>
            </tr>
          `).join('')}
        </tbody></table>
      `)}

      ${section('Alert response times (last 8 weeks)', response.error?.message, `
        <table><thead><tr>
          <th>Week</th><th>Branch</th>
          <th style="text-align:right">Fired</th>
          <th style="text-align:right">Resolved</th>
          <th style="text-align:right">Avg hrs</th>
        </tr></thead><tbody>
          ${(response.data ?? []).map(r => `
            <tr>
              <td class="small">${r.week}</td>
              <td>${escapeHtml(r.branch_name)}</td>
              <td style="text-align:right">${r.alerts_fired}</td>
              <td style="text-align:right">${r.alerts_resolved}</td>
              <td style="text-align:right">${r.avg_hours_to_resolve ?? '—'}</td>
            </tr>
          `).join('')}
        </tbody></table>
      `)}

      ${section('Waste recovery (last 8 weeks)', waste.error?.message, `
        <table><thead><tr>
          <th>Week</th><th>Branch</th>
          <th style="text-align:right">Sold</th>
          <th style="text-align:right">Markdown</th>
          <th style="text-align:right">Donated</th>
          <th style="text-align:right">Discarded</th>
        </tr></thead><tbody>
          ${(waste.data ?? []).map(w => `
            <tr>
              <td class="small">${w.week}</td>
              <td>${escapeHtml(w.branch_name)}</td>
              <td style="text-align:right">${w.sold_before_expiry_count}</td>
              <td style="text-align:right">${w.markdown_count}</td>
              <td style="text-align:right">${w.donation_count}</td>
              <td style="text-align:right">${w.discard_count}</td>
            </tr>
          `).join('')}
        </tbody></table>
      `)}
    </section>
  `;
}

function section(title, error, tableHtml) {
  return `
    <div class="card">
      <h3 style="margin-bottom:12px">${escapeHtml(title)}</h3>
      ${error ? `<div class="banner error">${escapeHtml(error)}</div>` : tableHtml}
    </div>
  `;
}
function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
