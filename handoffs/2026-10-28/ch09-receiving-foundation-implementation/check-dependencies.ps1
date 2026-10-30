$ErrorActionPreference = 'Stop'
$chapter = $PSScriptRoot
$root = (Resolve-Path -LiteralPath "$chapter/../../..").Path
function Read-LockedPackages([string]$path) {
    $result = @{}
    $raw = Get-Content -LiteralPath $path -Raw
    foreach ($entry in [regex]::Matches($raw, '(?ms)^  ([a-zA-Z0-9_]+):\r?\n(.*?)(?=^  [a-zA-Z0-9_]+:|^sdks:|\z)')) {
        $body = $entry.Groups[2].Value
        $version = [regex]::Match($body, '(?m)^    version: "([^"]+)"').Groups[1].Value
        $hash = [regex]::Match($body, '(?m)^      sha256: "?([a-f0-9]+)').Groups[1].Value
        $result[$entry.Groups[1].Value] = @{ version = $version; sha256 = $hash }
    }
    return $result
}
$before = Read-LockedPackages "$chapter/baseline/pubspec.lock"
$after = Read-LockedPackages "$root/app_flutter/pubspec.lock"
$changedExisting = @($before.Keys | Where-Object { -not $after.ContainsKey($_) -or $after[$_].version -ne $before[$_].version -or $after[$_].sha256 -ne $before[$_].sha256 })
if ($changedExisting.Count) { throw 'Existing dependency versions or archive hashes changed' }
$added = @($after.Keys | Where-Object { -not $before.ContainsKey($_) } | Sort-Object)
$allowed = @('cryptography','idb_shim','sembast','sqflite','sqflite_android','sqflite_common','sqflite_darwin','sqflite_platform_interface','synchronized')
if (@(Compare-Object $added $allowed).Count) { throw 'Unexpected dependency addition' }
$rows = foreach ($name in @($added) + @('web')) {
    $locked = $after[$name]
    $versionPath = [Uri]::EscapeDataString($locked.version)
    $metadata = Invoke-RestMethod -Uri "https://pub.dev/api/packages/$name/versions/$versionPath"
    if ($metadata.archive_sha256 -ne $locked.sha256) { throw "Archive metadata mismatch: $name" }
    $licensePath = "D:/dev/pub-cache/hosted/pub.dev/$name-$($locked.version)/LICENSE"
    $license = Get-Content -LiteralPath $licensePath -Raw
    [pscustomobject]@{ name=$name; version=$locked.version; archive_sha256=$locked.sha256; source='pub.dev'; license_sha256=(Get-FileHash -LiteralPath $licensePath).Hash; license_heading=($license -split "`n" | Select-Object -First 4) -join ' '; dependencies=$metadata.pubspec.dependencies; environment=$metadata.pubspec.environment }
}
$queries = @($rows | ForEach-Object { @{ package=@{ name=$_.name; ecosystem='Pub' }; version=$_.version } })
$advisories = Invoke-RestMethod -Uri 'https://api.osv.dev/v1/querybatch' -Method Post -ContentType 'application/json' -Body (@{ queries=$queries } | ConvertTo-Json -Depth 6)
@{ date='2026-10-28 Australia/Perth'; existingPackagesUnchanged=$before.Count; added=$rows; advisories=$advisories; advisoryOrder=@($rows.name); limitation='Public advisory matches are not a source security audit or platform test.' } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath "$chapter/DEPENDENCY_REVIEW.json"
Write-Output "Verified $($before.Count) existing packages unchanged; $($added.Count) additions plus web promotion. Registry hashes and OSV results recorded."
