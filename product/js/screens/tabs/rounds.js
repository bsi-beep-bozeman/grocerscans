export async function render(view) {
  view.innerHTML = `
    <div class="card">
      <h3>Daily rounds</h3>
      <p class="muted small">
        Next iteration: pair-audit start (lead + second staff PIN), scan/mark items
        (ok / flagged / pulled / relabeled / frozen / discarded), close-out. Backed by
        <code>kiosk_start_round</code>, <code>kiosk_add_round_item</code>, <code>kiosk_complete_round</code>.
      </p>
      <p class="muted small" style="margin-top:8px">
        Three slots per day: opening · mid · closing. Uniqueness enforced at the schema level.
      </p>
    </div>
  `;
}
