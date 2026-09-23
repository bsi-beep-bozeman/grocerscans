/* Wiring. Demo build — see PLAN.md for the Phase 1 scope this stands in for. */

import { CATEGORIES, category, TRANSITIONS, lookupOpenFoodFacts } from './catalog.js';
import * as db from './store.js';
import * as scanner from './scanner.js';
import * as ui from './ui.js';

const $ = (id) => document.getElementById(id);
const screens = ['scan', 'alerts', 'rounds', 'stock'];
let pending = null; /* { upc, name, brand, known } awaiting confirmation */

/* --- navigation ------------------------------------------------------------ */

function show(name) {
  screens.forEach((s) => {
    $(`screen-${s}`).hidden = s !== name;
    $(`nav-${s}`).setAttribute('aria-selected', String(s === name));
  });
  if (name !== 'scan') scanner.stop();
  $('topbar-sub').textContent = {
    scan: 'Receiving', alerts: 'Packaged', rounds: 'Fresh · today', stock: 'All batches',
  }[name];
  refresh();
}

/* --- rendering ------------------------------------------------------------- */

function refresh() {
  const alerts = db.batchesFor('alert').filter((b) => db.urgency(b) !== 'ok');
  const rounds = db.batchesFor('round');
  const stock = db.batchesFor('alert').concat(db.batchesFor('round'))
    .sort((a, b) => db.daysUntil(a.expiry) - db.daysUntil(b.expiry));

  ui.renderList($('list-alerts'), alerts, 'Nothing approaching expiry. Checked just now.');
  ui.renderRounds($('list-rounds'), rounds, 'No fresh items logged.');
  ui.renderList($('list-stock'), stock, 'No batches yet. Scan something to begin.');

  $('count-alerts').textContent = `${alerts.length} of ${db.batchesFor('alert').length}`;
  $('count-rounds').textContent = `${rounds.length} to check`;
  $('count-stock').textContent = `${stock.length} active`;

  ui.setBadge($('nav-alerts'), alerts.filter((b) =>
    ['urgent', 'expired'].includes(db.urgency(b))).length);
  ui.setBadge($('nav-rounds'), rounds.filter((b) =>
    ['urgent', 'expired'].includes(db.urgency(b))).length);
}

/* --- scanning -------------------------------------------------------------- */

async function beginScan() {
  const stage = $('scan-stage');
  try {
    $('scan-start').disabled = true;
    stage.classList.add('live');
    $('scan-idle').hidden = true;
    $('scan-video').hidden = false;
    $('scan-reticle').hidden = false;
    await scanner.start($('scan-video'), onDetected);
    ui.toast('Scanning — point at a barcode');
  } catch (err) {
    endScan();
    ui.toast(err.message || 'Could not start the camera');
  } finally {
    $('scan-start').disabled = false;
  }
}

function endScan() {
  scanner.stop();
  $('scan-video').hidden = true;
  $('scan-reticle').hidden = true;
  $('scan-idle').hidden = false;
  $('scan-stage').classList.remove('live');
}

async function onDetected(upc) {
  endScan();
  if (navigator.vibrate) navigator.vibrate(40);
  await identify(upc);
}

/* First scan of an unknown UPC costs one typed name. Every scan after is free —
   the store's catalog becomes the source of truth. */
async function identify(upc) {
  const known = db.getProduct(upc);
  if (known) {
    pending = { upc, name: known.name, category: known.category, known: true };
    ui.toast(`Known product — ${known.name}`);
  } else {
    ui.toast('New product — checking public catalog…');
    const found = await lookupOpenFoodFacts(upc);
    pending = {
      upc,
      name: found ? [found.brand, found.name].filter(Boolean).join(' ') : '',
      category: 'dry',
      known: false,
    };
    ui.toast(found ? 'Found — confirm the details' : 'Not in public catalog — type the name once');
  }
  openForm();
}

/* --- the receiving form ---------------------------------------------------- */

function openForm() {
  $('form-upc').textContent = pending.upc;
  $('f-name').value = pending.name;
  $('f-category').value = pending.category;
  $('f-qty').value = '1';
  $('f-lot').value = '';
  syncExpiryMode();
  $('scan-form').hidden = false;
  $('scan-capture').hidden = true;
  (pending.name ? $('f-qty') : $('f-name')).focus();
}

function closeForm() {
  pending = null;
  $('scan-form').hidden = true;
  $('scan-capture').hidden = false;
}

/* Printed categories ask for the date on the package. Computed categories ask
   when it arrived and derive the rest — nobody prints an expiry on ground beef. */
function syncExpiryMode() {
  const cat = category($('f-category').value);
  const computed = cat.mode === 'computed';

  $('wrap-expiry').hidden = computed;
  $('wrap-received').hidden = !computed;
  $('wrap-lot').hidden = !cat.ftl;

  /* the hints live outside their fields (full width under the row), so they
     need toggling too — otherwise the previous category's hint lingers */
  $('hint-expiry').hidden = computed;
  $('hint-received').hidden = !computed;

  if (computed) {
    $('f-received').value = db.iso(db.today());
    $('hint-received').textContent =
      `${cat.name} — ${cat.life}-day shelf life. Expiry is calculated, not typed.`;
  } else {
    const def = db.iso(db.addDays(db.today(), cat.alerts?.[0] > 90 ? 365 : 60));
    if (!$('f-expiry').value) $('f-expiry').value = def;
    $('hint-expiry').textContent = cat.note
      ? `${cat.name} — alerts at ${cat.alerts.join(' and ')} days. ${cat.note}.`
      : `${cat.name} — alerts at ${cat.alerts.join(' and ')} days before expiry.`;
  }
  $('hint-lot').textContent = cat.ftl
    ? 'On the FDA Food Traceability List — lot code is a recordkeeping requirement.'
    : '';
}

function submitForm(event) {
  event.preventDefault();
  const name = $('f-name').value.trim();
  if (!name) { ui.toast('Product name is required'); return; }

  const catId = $('f-category').value;
  const cat = category(catId);
  const qty = Math.max(1, Number($('f-qty').value) || 1);

  let expiry, received;
  if (cat.mode === 'computed') {
    received = $('f-received').value || db.iso(db.today());
    expiry = db.iso(db.addDays(new Date(received + 'T00:00:00'), cat.life ?? 3));
  } else {
    expiry = $('f-expiry').value;
    received = db.iso(db.today());
    if (!expiry) { ui.toast('Expiry date is required'); return; }
  }

  db.saveProduct(pending.upc, { name, category: catId });
  db.addBatch({
    upc: pending.upc, name, category: catId, qty, expiry, received,
    lot: $('f-lot').value.trim(),
  });

  ui.toast(cat.mode === 'computed'
    ? `Logged — expires ${db.fmtDate(expiry)} (${cat.life}-day shelf life)`
    : `Logged — ${qty} ea, expires ${db.fmtDate(expiry)}`);

  closeForm();
  show(cat.flow === 'round' ? 'rounds' : 'stock');
}

/* --- fresh-goods transitions ------------------------------------------------
   Freeze and convert spawn a linked child batch with a new clock. The original
   isn't deleted — it's resolved, and the chain stays auditable. */

function onRoundAction(event) {
  const btn = event.target.closest('[data-act]');
  if (!btn) return;

  const transition = TRANSITIONS.find((t) => t.id === btn.dataset.act);
  const child = db.resolveBatch(btn.dataset.id, transition.id, transition.spawns);

  if (child) {
    ui.toast(`${transition.label} — new batch, expires ${db.fmtDate(child.expiry)}. Relabel required.`);
  } else {
    ui.toast(`Marked ${transition.label.toLowerCase()}`);
  }
  refresh();
}

/* --- init ------------------------------------------------------------------ */

function init() {
  db.load();

  $('f-category').innerHTML = Object.entries(CATEGORIES)
    .map(([id, c]) => `<option value="${id}">${c.name}${c.ftl ? ' · FTL' : ''}</option>`)
    .join('');

  ui.renderDiagnostic($('diagnostic'), scanner.diagnose());

  screens.forEach((s) => $(`nav-${s}`).addEventListener('click', () => show(s)));
  $('scan-start').addEventListener('click', beginScan);
  const manual = () => {
    const upc = $('f-manual').value.trim();
    if (!upc) { ui.toast('Enter a UPC first'); return; }
    $('f-manual').value = '';
    identify(upc);
  };
  $('scan-manual').addEventListener('click', manual);
  $('f-manual').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); manual(); }
  });
  $('f-category').addEventListener('change', syncExpiryMode);
  $('scan-form').addEventListener('submit', submitForm);
  $('form-cancel').addEventListener('click', closeForm);
  $('list-rounds').addEventListener('click', onRoundAction);
  $('reset').addEventListener('click', () => {
    if (confirm('Reset demo data back to the seeded inventory?')) { db.reset(); refresh(); }
  });

  window.addEventListener('pagehide', scanner.stop);
  show('scan');
}

init();
