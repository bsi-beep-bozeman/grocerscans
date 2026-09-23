/* Data layer. Demo build persists to localStorage; Phase 1 swaps this module
   for Supabase with an IndexedDB offline queue behind the same interface. */

import { category } from './catalog.js';

const KEY = 'shelflife.v1';

const DAY = 86400000;
export const today = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };

/* Local calendar date, NOT toISOString(). toISOString() converts to UTC, so in
   any timezone ahead of UTC local midnight serialises as the previous day —
   shifting every computed expiry a day early. */
export const iso = (d) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

export const addDays = (d, n) => new Date(d.getTime() + n * DAY);
export const daysUntil = (dateStr) =>
  Math.round((new Date(dateStr + 'T00:00:00') - today()) / DAY);
export const daysSince = (dateStr) => -daysUntil(dateStr);

export const fmtDate = (dateStr) => {
  const [y, m, d] = dateStr.split('-');
  return `${m}/${d}/${y}`;
};

let state = { products: {}, batches: [] };

/* --- urgency ---------------------------------------------------------------
   A batch's urgency is relative to its category's thresholds, not an absolute
   number of days. Seven days is comfortable for canned soup and far too late
   for ground beef. */
export function urgency(batch) {
  const cat = category(batch.category);
  const days = daysUntil(batch.expiry);
  if (days < 0) return 'expired';

  if (cat.mode === 'computed') {
    const life = cat.life ?? 3;
    if (days <= 0) return 'expired';
    if (days <= 1) return 'urgent';
    if (days <= Math.ceil(life / 2)) return 'warn';
    return 'ok';
  }

  const [outer, inner] = cat.alerts ?? [30, 7];
  if (days <= inner) return 'urgent';
  if (days <= outer) return 'warn';
  return 'ok';
}

const RANK = { expired: 0, urgent: 1, warn: 2, ok: 3 };

/* --- persistence ----------------------------------------------------------- */

function persist() {
  try { localStorage.setItem(KEY, JSON.stringify(state)); } catch { /* quota */ }
}

export function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) { state = JSON.parse(raw); return; }
  } catch { /* corrupt — reseed */ }
  state = seed();
  persist();
}

export function reset() { state = seed(); persist(); }

/* --- products -------------------------------------------------------------- */

export const getProduct = (upc) => state.products[upc] ?? null;

export function saveProduct(upc, { name, brand = '', category: cat = 'dry' }) {
  state.products[upc] = { upc, name, brand, category: cat };
  persist();
  return state.products[upc];
}

/* --- batches --------------------------------------------------------------- */

export const allBatches = () => state.batches.filter((b) => b.state === 'active');

export function batchesFor(flow) {
  return allBatches()
    .filter((b) => category(b.category).flow === flow)
    .sort((a, b) => {
      const d = RANK[urgency(a)] - RANK[urgency(b)];
      return d !== 0 ? d : daysUntil(a.expiry) - daysUntil(b.expiry);
    });
}

export function actionable() {
  return allBatches().filter((b) => ['expired', 'urgent', 'warn'].includes(urgency(b)));
}

export function addBatch({ upc, name, category: cat, qty, expiry, received, lot = '', location = '' }) {
  const batch = {
    id: crypto.randomUUID(),
    upc, name, category: cat,
    qty: Number(qty) || 0,
    expiry,
    received: received ?? iso(today()),
    lot, location,
    state: 'active',
    parentId: null,
  };
  state.batches.unshift(batch);
  persist();
  return batch;
}

export function resolveBatch(id, resolution, spawn = null) {
  const batch = state.batches.find((b) => b.id === id);
  if (!batch) return null;

  batch.state = resolution;
  batch.resolvedAt = new Date().toISOString();

  let child = null;
  if (spawn) {
    child = {
      id: crypto.randomUUID(),
      upc: batch.upc,
      name: spawn.relabel ? `${batch.name} (previously frozen)` : batch.name,
      category: spawn.category,
      qty: batch.qty,
      expiry: iso(addDays(today(), spawn.life)),
      received: iso(today()),
      lot: batch.lot,
      location: spawn.category === 'frozen' ? 'Freezer' : batch.location,
      state: 'active',
      parentId: batch.id,
    };
    state.batches.unshift(child);
  }
  persist();
  return child;
}

/* --- seed -------------------------------------------------------------------
   Realistic East Coast grocery mix, spread across urgency levels so every
   screen has something to show on first load. */

function seed() {
  const t = today();
  const on = (n) => iso(addDays(t, n));
  const ago = (n) => iso(addDays(t, -n));

  const rows = [
    ['0073214000012', 'Potato Salad, 1 lb',            'deli',    'Boar\'s Head',  6,  on(1),   ago(2), 'LOT-8841-A', 'Deli case'],
    ['0085239000045', 'Organic Baby Spinach, 5 oz',    'greens',  'Earthbound',   14,  on(2),   ago(1), 'LOT-2207-C', 'Produce 3'],
    ['0002200000019', 'Ground Beef 80/20, 1 lb',       'meat',    'Store packed',  9,  on(1),   ago(2), '',           'Meat case'],
    ['0072036000024', 'Atlantic Salmon Fillet',        'seafood', 'Store packed',  4,  on(0),   ago(2), 'LOT-5519-F', 'Seafood'],
    ['0071700000031', 'Large Eggs, Dozen',             'eggs',    'Eggland\'s',   24,  on(9),   ago(3), 'LOT-3390-B', 'Dairy 1'],
    ['0007840000502', 'Sharp Cheddar Bar, 8 oz',       'dry',     'Cabot',        18,  on(210), ago(9), '',           'Dairy 2'],
    ['0003410000167', 'Fresh Mozzarella, 8 oz',        'cheese',  'BelGioioso',    7,  on(5),   ago(2), 'LOT-7712-D', 'Dairy 2'],
    ['0005100001251', 'Tomato Soup, 10.75 oz',         'dry',     'Campbell\'s',  48,  on(240), ago(21), '',          'Aisle 6'],
    ['0030573001628', 'Ibuprofen 200mg, 200 ct',       'otc',     'Advil',        12,  on(96),  ago(30), '',          'HBA 2'],
    ['0001860000114', 'Sourdough Boule',               'bakery',  'In-store',      8,  on(1),   ago(1), '',           'Bakery'],
    ['0004128000097', 'Vine Tomatoes, lb',             'produce', 'Local',        22,  on(4),   ago(1), 'LOT-9004-E', 'Produce 1'],
  ];

  return {
    products: Object.fromEntries(rows.map(([upc, name, cat, brand]) =>
      [upc, { upc, name, brand, category: cat }])),
    batches: rows.map(([upc, name, cat, , qty, expiry, received, lot, location]) => ({
      id: crypto.randomUUID(),
      upc, name, category: cat, qty, expiry, received, lot, location,
      state: 'active', parentId: null,
    })),
  };
}
