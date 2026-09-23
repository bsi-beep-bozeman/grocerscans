import { supa } from '../../supa.js';

export async function render(view) {
  const [staff, kiosks] = await Promise.all([
    supa.from('staff_profiles')
      .select('id, display_name, role, is_shift_lead, email, branches(name)')
      .order('role').order('display_name'),
    supa.from('kiosk_devices')
      .select('id, label, last_seen_at, branches(name)')
      .order('label'),
  ]);

  view.innerHTML = `
    <section class="stack">
      <div class="card">
        <h3 style="margin-bottom:12px">Staff (${staff.data?.length ?? 0})</h3>
        ${staff.error
          ? `<div class="banner error">${staff.error.message}</div>`
          : `<table><thead><tr>
              <th>Name</th><th>Role</th><th>Branch</th><th>Lead?</th><th>Email</th>
            </tr></thead><tbody>
              ${staff.data.map(s => `
                <tr>
                  <td>${escapeHtml(s.display_name)}</td>
                  <td><span class="badge ok">${s.role}</span></td>
                  <td>${escapeHtml(s.branches?.name ?? '—')}</td>
                  <td>${s.is_shift_lead ? 'yes' : ''}</td>
                  <td class="small muted">${escapeHtml(s.email ?? '—')}</td>
                </tr>
              `).join('')}
            </tbody></table>`
        }
      </div>

      <div class="card">
        <h3 style="margin-bottom:12px">Kiosk devices (${kiosks.data?.length ?? 0})</h3>
        ${kiosks.error
          ? `<div class="banner error">${kiosks.error.message}</div>`
          : `<table><thead><tr>
              <th>Label</th><th>Branch</th><th>Last seen</th>
            </tr></thead><tbody>
              ${kiosks.data.map(k => `
                <tr>
                  <td>${escapeHtml(k.label)}</td>
                  <td>${escapeHtml(k.branches?.name ?? '—')}</td>
                  <td class="small muted">${k.last_seen_at ?? 'never'}</td>
                </tr>
              `).join('')}
            </tbody></table>`
        }
      </div>

      <div class="card">
        <p class="small muted">
          Next iteration: invite by email · assign role/branch · rotate staff PIN
          (via <code>set_staff_pin</code> RPC) · rotate kiosk device credentials.
        </p>
      </div>
    </section>
  `;
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
