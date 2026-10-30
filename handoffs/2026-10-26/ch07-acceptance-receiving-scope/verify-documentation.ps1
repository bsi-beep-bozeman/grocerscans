$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location -LiteralPath $repoRoot
$failures = [Collections.Generic.List[string]]::new()
$baseline = Get-Content -LiteralPath "$PSScriptRoot/PRESERVATION_BASELINE.json" -Raw | ConvertFrom-Json
foreach ($item in $baseline) {
    if (-not (Test-Path -LiteralPath $item.path)) { $failures.Add("Missing protected file: $($item.path)"); continue }
    if ((Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash -ne $item.sha256) { $failures.Add("Changed protected file: $($item.path)") }
}
$oldLedger = [IO.File]::ReadAllText("$PSScriptRoot/prior-current-docs/STATUS_LEDGER.md")
$newLedger = [IO.File]::ReadAllText((Join-Path $repoRoot 'STATUS_LEDGER.md'))
$historyIndex = $oldLedger.IndexOf('The following prior entries')
if ($historyIndex -lt 0 -or -not $newLedger.Contains($oldLedger.Substring($historyIndex))) { $failures.Add('Original ledger history block was not preserved verbatim') }
$oldEvents = @($oldLedger -split '\r?\n' | Where-Object { $_ -match '^\| (2026-|Next /)' })
$newEvents = @($newLedger -split '\r?\n' | Where-Object { $_ -match '^\| (2026-|Next /)' })
$eventCursor = 0
foreach ($event in $oldEvents) {
    while ($eventCursor -lt $newEvents.Count -and $newEvents[$eventCursor] -ne $event) { $eventCursor++ }
    if ($eventCursor -ge $newEvents.Count) { $failures.Add('Original ledger event order mismatch'); break }
    $eventCursor++
}
$docs = @('IMPLEMENTATION_PLAN.md','STATUS_LEDGER.md','SESSION_INDEX.md','NEXT_CONVERSATION_HANDOFF.md','docs/testing/2026-10-26-admin-setup-acceptance-review.md','docs/superpowers/plans/2026-10-26-receiving-identity-queue-scope.md') + @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.md' -File | ForEach-Object { $_.FullName })
$linkCount = 0
foreach ($doc in $docs) {
    $fullPath = (Resolve-Path -LiteralPath $doc).Path
    $content = [IO.File]::ReadAllText($fullPath)
    foreach ($match in [regex]::Matches($content, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim('<','>')
        if ($target -match '^(https?://|codex://|#|mailto:)') { continue }
        $target = [Uri]::UnescapeDataString(($target -split '#')[0])
        if (-not $target) { continue }
        $resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $fullPath) $target))
        $linkCount++
        if (-not (Test-Path -LiteralPath $resolved)) { $failures.Add("Broken link in ${doc}: $target") }
    }
    if ($content -match '(?m)[ \t]+\r?$') { $failures.Add("Trailing whitespace in $doc") }
    if ($content -match '(?m)^(<<<<<<<|=======|>>>>>>>)') { $failures.Add("Conflict marker in $doc") }
    if ($content -match '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{10,}') { $failures.Add("Potential secret in $doc") }
}
$gateSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'AGENTS.md'))
$gate = @($gateSource -split '\r?\n' | Where-Object { $_.Contains('Wait for the human') -and $_.Contains('IN THIS CHAT') })[0]
if (-not $gate -or -not ([IO.File]::ReadAllText("$PSScriptRoot/CONTINUATION_OPENING.md").Contains($gate))) { $failures.Add('Exact mandatory gate missing') }
$matrix = [IO.File]::ReadAllText((Join-Path $repoRoot 'docs/testing/2026-10-26-admin-setup-acceptance-review.md'))
for ($n=1; $n -le 12; $n++) { if ($matrix -notmatch ('(?m)^\| S1-' + $n.ToString('00') + ' ')) { $failures.Add("Missing S1 row $n") } }
$sources = Get-Content -LiteralPath "$PSScriptRoot/SOURCE_COMPARISON.json" -Raw | ConvertFrom-Json
foreach ($entry in $sources) { if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.expected) { $failures.Add("Source mismatch: $($entry.path)") } }
$oldCheckpoint = Get-Content -LiteralPath 'handoffs/2026-10-26/ch06-browser-completion/DATABASE_CHECKPOINT.json' -Raw | ConvertFrom-Json
foreach ($entry in $oldCheckpoint.migrations) { if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.expected) { $failures.Add("Migration mismatch: $($entry.path)") } }
$diffOutput = git diff --check 2>&1
$diffExit = $LASTEXITCODE
$diffOutput | Set-Content -LiteralPath "$PSScriptRoot/GIT_DIFF_CHECK.txt" -Encoding utf8
if ($diffExit -ne 0) { $failures.Add('Tracked git diff whitespace check failed') }
$result = [ordered]@{date='2026-10-26 Australia/Perth';scope='Documentation and source integrity only; no application/runtime tests';status=$(if ($failures.Count -eq 0) {'PASS'} else {'FAIL'});protectedFiles=$baseline.Count;priorLedgerEvents=$oldEvents.Count;priorLedgerHistoryVerbatim=$newLedger.Contains($oldLedger.Substring($historyIndex));documents=$docs.Count;localLinks=$linkCount;sourceHashes=$sources.Count;migrationHashes=$oldCheckpoint.migrations.Count;s1Rows=12;mandatoryStartGateVerbatim=$true;gitDiffCheckExit=$diffExit;failures=@($failures)}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$PSScriptRoot/DOCUMENTATION_CHECK.json" -Encoding utf8
$result | ConvertTo-Json -Depth 5
if ($failures.Count -gt 0) { exit 1 }
