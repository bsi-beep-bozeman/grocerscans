export async function render(view) {
  view.innerHTML = `
    <div class="card">
      <h3>Scan → log batch</h3>
      <p class="muted small">
        Next iteration: PIN gate, BarcodeDetector (with ZXing fallback for iOS),
        product lookup by UPC, batch entry form, offline queue via IndexedDB.
      </p>
      <p class="muted small" style="margin-top:8px">
        Reference scanner in <code>app/js/scanner.js</code> ports directly here —
        wired via <code>kiosk_log_batch</code> RPC.
      </p>
    </div>
  `;
}
