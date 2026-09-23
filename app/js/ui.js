/* Rendering. Days-remaining is the hero element; everything else is subdued.
   Colour is used only to signal urgency — see PLAN.md §7. */

import { category } from './catalog.js';
import { urgency, daysUntil, daysSince, fmtDate } from './store.js';

const esc = (s) => String(s ?? '').replace(/[&<>"']/g,
  (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function countdown(days) {
  if (days < 0) return { n: Math.abs(days), unit: days === -1 ? 'day past' : 'days past' };
  if (days === 0) return { n: 0, unit: 'today' };
  return { n: days, unit: days === 1 ? 'day' : 'days' };
}

export function batchCard(batch) {
  const cat = category(batch.category);
  const u = urgency(batch);
  const { n, unit } = countdown(daysUntil(batch.expiry));

  const bits = [
    `<span class="num">${esc(fmtDate(batch.expiry))}</span>`,
    `<span class="dot">·</span>`,
    `<span class="num">${esc(batch.qty)} ea</span>`,
  ];
  if (batch.location) bits.push(`<span class="dot">·</span><span>${esc(batch.location)}</span>`);
  if (cat.ftl) bits.push(`<span class="pill ftl">FTL</span>`);
  if (batch.lot) bits.push(`<span class="pill lot">${esc(batch.lot)}</span>`);

  return `
    <button class="card" data-u="${u}" data-id="${esc(batch.id)}" type="button">
      <i class="edge"></i>
      <div class="body">
        <div class="name">${esc(batch.name)}</div>
        <div class="meta">${bits.join('')}</div>
      </div>
      <div class="days"><b class="num">${n}</b><span>${unit}</span></div>
    </button>`;
}

export function roundCard(batch) {
  const cat = category(batch.category);
  const u = urgency(batch);
  const age = daysSince(batch.received);
  const life = cat.life ?? 3;

  const bits = [
    `<span class="num">${esc(batch.qty)} ea</span>`,
    `<span class="dot">·</span>`,
    `<span>${esc(batch.location || cat.name)}</span>`,
  ];
  if (cat.ftl) bits.push(`<span class="pill ftl">FTL</span>`);
  if (batch.lot) bits.push(`<span class="pill lot">${esc(batch.lot)}</span>`);

  const actions = ['freeze', 'convert', 'markdown', 'donate', 'discard']
    .map((id) => {
      const label = id[0].toUpperCase() + id.slice(1);
      return `<button class="btn sm ghost" data-act="${id}" data-id="${esc(batch.id)}" type="button">${label}</button>`;
    }).join('');

  return `
    <div class="round-card" data-u="${u}">
      <div class="top">
        <div class="name">${esc(batch.name)}</div>
        <div class="age num">Day ${age} of ${life}</div>
      </div>
      <div class="meta">${bits.join('')}</div>
      <div class="btn-row">${actions}</div>
    </div>`;
}

export function renderList(el, batches, emptyMsg) {
  el.innerHTML = batches.length
    ? batches.map(batchCard).join('')
    : `<p class="empty">${esc(emptyMsg)}</p>`;
}

export function renderRounds(el, batches, emptyMsg) {
  el.innerHTML = batches.length
    ? batches.map(roundCard).join('')
    : `<p class="empty">${esc(emptyMsg)}</p>`;
}

export function renderDiagnostic(el, result) {
  el.className = result.ok ? 'diag ok' : 'diag';
  el.innerHTML = `<h3>${esc(result.title)}</h3><p>${result.detail}</p>`;
}

let toastTimer = null;
export function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
}

export function setBadge(el, count) {
  const existing = el.querySelector('.badge');
  if (!count) { existing?.remove(); return; }
  const badge = existing ?? Object.assign(document.createElement('span'), { className: 'badge' });
  badge.textContent = count > 99 ? '99+' : String(count);
  if (!existing) el.appendChild(badge);
}
