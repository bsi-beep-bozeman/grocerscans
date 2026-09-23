import { supa } from '../../supa.js';

export async function render(view) {
  await supa.rpc('refresh_alerts').catch(() => {}); // best-effort; kiosk/manager only
  const { data, error } = await supa
    .from('alerts')
    .select(`
      id, threshold_days, fired_at, status, resolution,
      batches!inner (
        id, quantity_remaining, expiry_date,
        products!inner (name),
        branches!inner (name)
      )
    `)
    .eq('status', 'open')
    .order('fired_at', { ascending: false });

  if (error) {
    view.innerHTML = `<div class="banner error">${error.message}</div>`;
    return;
  }
  if (!data?.length) {
    view.innerHTML = `<div class="banner ok">All clear — no open alerts.</div>`;
    return;
  }

  view.innerHTML = `
    <div class="list">
      ${data.map(a => {
        const b = a.batches;
        const days = Math.round((new Date(b.expiry_date) - new Date(new Date().toDateString())) / 86400000);
        const cls = days < 0 ? 'expired' : days <= 2 ? 'urgent' : days <= 7 ? 'warn' : 'ok';
        return `
          <div class="row">
            <div>
              <div>${escapeHtml(b.products.name)}</div>
              <div class="meta">
                ${escapeHtml(b.branches.name)} · ${b.quantity_remaining} left ·
                threshold ${a.threshold_days}d
              </div>
            </div>
            <div class="days ${cls}">${days}d</div>
          </div>
        `;
      }).join('')}
    </div>
    <p class="small muted" style="margin-top:12px">
      Resolution actions land in the next iteration — kiosk PIN gate + resolution picker.
    </p>
  `;
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
