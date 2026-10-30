$ErrorActionPreference = 'Stop'
$packet = Join-Path (Get-Location) 'handoffs/2026-10-12/ch04-scope-acceptance'
git status --short | Set-Content -LiteralPath (Join-Path $packet 'GIT_STATUS_AFTER.txt') -Encoding utf8
$baseline = Get-Content (Join-Path $packet 'PROTECTED_BASELINE.json') -Raw | ConvertFrom-Json
foreach ($item in $baseline) { if ((Get-FileHash -LiteralPath $item.Path -Algorithm SHA256).Hash -ne $item.SHA256) { throw "Protected file changed: $($item.Path)" } }
$before = Get-Content (Join-Path $packet 'prior-current-docs/STATUS_LEDGER.md')
$oldRows = @($before | Where-Object { $_ -match '^\| (2026-|Next /)' })
$current = Get-Content STATUS_LEDGER.md -Raw
$position = 0
foreach ($row in $oldRows) { $found = $current.IndexOf($row,$position,[StringComparison]::Ordinal); if ($found -lt 0) { throw "Historical row changed/missing: $row" }; $position = $found + $row.Length }
$docs = @('IMPLEMENTATION_PLAN.md','STATUS_LEDGER.md','SESSION_INDEX.md','NEXT_CONVERSATION_HANDOFF.md','docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md') + @(Get-ChildItem -LiteralPath $packet -Filter '*.md' | ForEach-Object FullName)
$linkCount = 0
foreach ($file in $docs) {
  $absolute = (Resolve-Path -LiteralPath $file).Path
  $body = Get-Content -LiteralPath $absolute -Raw
  foreach ($m in [regex]::Matches($body,'\[[^\]]*\]\(([^)]+)\)')) {
    $ref = $m.Groups[1].Value
    if ($ref -match '^(https?://|codex://|#)') { continue }
    $ref = ($ref -split '#')[0]
    $resolved = Join-Path (Split-Path $absolute -Parent) $ref
    if (-not (Test-Path -LiteralPath $resolved)) { throw "Missing link in $file : $ref" }
    $linkCount++
  }
  if ($body -match '(?m)[ \t]+$') { throw "Trailing whitespace: $file" }
}
$agents = Get-Content AGENTS.md -Raw
$gate = ($agents -split "`r?`n" | Where-Object { $_ -match '^.Wait for the human' } | Select-Object -First 1)
$opening = Get-Content (Join-Path $packet 'NEXT_CHAT_OPENING.md') -Raw
if (-not $gate -or -not $opening.Contains($gate)) { throw 'Mandatory gate mismatch' }
$plan = Get-Content 'docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md' -Raw
foreach ($number in 1..12) { if (-not $plan.Contains(('S1-{0:D2}' -f $number))) { throw "Missing S1 acceptance $number" } }
foreach ($number in 0..10) { if (-not $plan.Contains(('R{0:D2}' -f $number))) { throw "Missing approval row $number" } }
if ($plan -match '\b(TODO|TBD)\b') { throw 'Unresolved placeholder' }
git status --short | Set-Content -LiteralPath (Join-Path $packet 'GIT_STATUS_AFTER.txt') -Encoding utf8
$summary = "PASS: $($baseline.Count) protected hashes unchanged; $($oldRows.Count) prior ledger rows preserved in order; $linkCount local references across $($docs.Count) current/packet documents resolve; whitespace clean; exact mandatory gate preserved; S1-01–12 and R00–R10 present; no unresolved placeholder markers."
$summary | Set-Content -LiteralPath (Join-Path $packet 'DOCUMENT_CHECK_RESULT.txt') -Encoding utf8
Write-Output $summary
