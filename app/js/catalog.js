/* Category profiles and product identification.
   See PLAN.md §4 — expiry is either *printed* on the package (recorded) or
   *computed* from the date received. That split drives everything else. */

export const CATEGORIES = {
  dry:      { name: 'Dry & Packaged', mode: 'printed',  alerts: [30, 7],     flow: 'alert' },
  frozen:   { name: 'Frozen',         mode: 'printed',  alerts: [30, 7],     flow: 'alert' },
  dairy:    { name: 'Dairy',          mode: 'printed',  alerts: [7, 2],      flow: 'alert' },
  cheese:   { name: 'Soft Cheese',    mode: 'printed',  alerts: [7, 2],      flow: 'alert', ftl: true },
  eggs:     { name: 'Shell Eggs',     mode: 'printed',  alerts: [10, 3],     flow: 'alert', ftl: true },
  otc:      { name: 'OTC / Pharmacy', mode: 'printed',  alerts: [120, 30],   flow: 'alert',
              note: 'Distributor return window closes months before expiry' },

  greens:   { name: 'Leafy Greens',   mode: 'computed', life: 3, flow: 'round', ftl: true },
  produce:  { name: 'Produce',        mode: 'computed', life: 5, flow: 'round', ftl: true },
  meat:     { name: 'Fresh Meat',     mode: 'computed', life: 3, flow: 'round' },
  seafood:  { name: 'Seafood',        mode: 'computed', life: 2, flow: 'round', ftl: true },
  deli:     { name: 'Deli / RTE',     mode: 'computed', life: 3, flow: 'round', ftl: true },
  bakery:   { name: 'Bakery',         mode: 'computed', life: 2, flow: 'round' },
};

export const category = (id) => CATEGORIES[id] ?? CATEGORIES.dry;

/* Transitions available to a fresh batch at its decision point. Freeze and
   convert *spawn a new batch* with a new clock — they don't close the record. */
export const TRANSITIONS = [
  { id: 'freeze',   label: 'Freeze',    spawns: { category: 'frozen', life: 90, relabel: true } },
  { id: 'convert',  label: 'Convert',   spawns: { category: 'deli',   life: 3,  relabel: true } },
  { id: 'markdown', label: 'Markdown' },
  { id: 'donate',   label: 'Donate' },
  { id: 'discard',  label: 'Discard' },
];

/* --- product identification -------------------------------------------------
   The store's own catalog is the source of truth. Open Food Facts is a
   convenience layer used only on first encounter with an unknown UPC. */

const OFF_ENDPOINT = 'https://world.openfoodfacts.org/api/v2/product';

export async function lookupOpenFoodFacts(upc, { timeout = 4000 } = {}) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), timeout);
  try {
    const res = await fetch(
      `${OFF_ENDPOINT}/${encodeURIComponent(upc)}.json?fields=product_name,brands`,
      { signal: ctl.signal }
    );
    if (!res.ok) return null;
    const data = await res.json();
    if (data.status !== 1 || !data.product) return null;
    const name = (data.product.product_name || '').trim();
    const brand = (data.product.brands || '').split(',')[0].trim();
    if (!name) return null;
    return { name, brand, source: 'openfoodfacts' };
  } catch {
    return null; /* offline, timeout, or not found — staff types it instead */
  } finally {
    clearTimeout(timer);
  }
}
