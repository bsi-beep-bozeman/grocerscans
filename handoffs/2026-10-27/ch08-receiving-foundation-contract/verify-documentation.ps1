param([string]$OutputName = 'DOCUMENTATION_CHECK.json')
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$packet = Join-Path $root 'handoffs/2026-10-27/ch08-receiving-foundation-contract'
$failures = [System.Collections.Generic.List[string]]::new()
$protected = @(Get-Content -LiteralPath (Join-Path $packet 'PRESERVATION_BASELINE.json') -Raw | ConvertFrom-Json)
foreach ($entry in $protected) {
  if (!(Test-Path -LiteralPath $entry.path)) { $failures.Add('Missing protected: ' + $entry.path); continue }
  if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.sha256) { $failures.Add('Changed protected: ' + $entry.path) }
}
$source = @(Get-Content -LiteralPath 'handoffs/2026-10-26/ch07-acceptance-receiving-scope/SOURCE_COMPARISON.json' -Raw | ConvertFrom-Json)
foreach ($entry in $source) {
  if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.expected) { $failures.Add('Historical source mismatch: ' + $entry.path) }
}
$before = Get-Content -LiteralPath (Join-Path $packet 'prior-current-docs/STATUS_LEDGER.md') -Raw
$after = Get-Content -LiteralPath 'STATUS_LEDGER.md' -Raw
$marker = 'The following prior entries and approval notes'
$oldHistory = $before.Substring($before.IndexOf($marker))
if (!$after.Contains($oldHistory)) { $failures.Add('Original ledger history changed') }
$priorEvents = @([regex]::Matches($oldHistory, '(?m)^\| (?:2026-|Next /)')).Count
$docs = @(Get-ChildItem -LiteralPath $packet -File -Filter '*.md') + @(
  Get-Item -LiteralPath 'docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md',
    'docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md',
    'IMPLEMENTATION_PLAN.md','STATUS_LEDGER.md','SESSION_INDEX.md','NEXT_CONVERSATION_HANDOFF.md'
)
$links = 0
foreach ($doc in $docs) {
  $body = Get-Content -LiteralPath $doc.FullName -Raw
  if ([regex]::IsMatch($body, '(?m)[ \t]+\r?$')) { $failures.Add('Trailing whitespace: ' + $doc.Name) }
  foreach ($match in [regex]::Matches($body, '\[[^\]\r\n]*\]\(([^)\r\n]+)\)')) {
    $target = $match.Groups[1].Value.Trim('<','>')
    if ($target -match '^(https?://|codex://|#|mailto:)') { continue }
    $target = [uri]::UnescapeDataString(($target -split '#')[0])
    if ($target -eq '') { continue }
    $resolved = [IO.Path]::GetFullPath((Join-Path $doc.DirectoryName $target))
    $links++
    if (!(Test-Path -LiteralPath $resolved)) { $failures.Add('Broken link in ' + $doc.Name + ': ' + $target) }
  }
}
$rules = Get-Content -LiteralPath 'AGENTS.md' -Raw
$gate = ([regex]::Match($rules, '(?m)^.*Wait for the human user.*$')).Value.Trim()
$opening = Get-Content -LiteralPath (Join-Path $packet 'CONTINUATION_OPENING.md') -Raw
if (!$gate -or !$opening.Contains($gate)) { $failures.Add('Exact gate missing') }
$contract = Get-Content -LiteralPath 'docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md' -Raw
foreach ($term in @('begin_staff_session_v1','recover_receiving_partition_v1','get_receiving_catalog_v1','get_receiving_policy_v1','eight-hour','blocked_until','idb_shim 2.10.1+1','sqflite 2.4.5','cryptography 2.9.0','current_staff','private.receiving_vault_keys','admin recovery')) {
  if (!$contract.Contains($term)) { $failures.Add('Contract coverage missing: ' + $term) }
}
$amendment = Get-Content -LiteralPath 'docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md' -Raw
foreach ($id in @('S2A-R01','S2A-R02','S2A-R03','S2A-R06','R05-ANDROID','R05-WEB')) {
  if (!$amendment.Contains($id)) { $failures.Add('Approval missing: ' + $id) }
}
foreach ($n in 1..12) {
  $id = 'A' + $n.ToString('00')
  if (!$amendment.Contains('| ' + $id + ' ')) { $failures.Add('Acceptance case missing: ' + $id) }
}
$result = [ordered]@{
  date_perth='2026-10-27'; scope='Documentation verification only';
  passed=($failures.Count -eq 0); protected_files=$protected.Count;
  source_hashes=$source.Count; prior_ledger_events=$priorEvents;
  ledger_history_verbatim=$after.Contains($oldHistory); documents=$docs.Count;
  local_links=$links; exact_start_gate=$opening.Contains($gate);
  application_tests_executed=0; failures=@($failures)
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $packet $OutputName) -Encoding UTF8
$result | ConvertTo-Json -Depth 5
if ($failures.Count -gt 0) { exit 1 }

