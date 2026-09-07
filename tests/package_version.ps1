param([Parameter(Mandatory=$true)][ValidateRange(1,9999)][int]$Version)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildPath = Join-Path $projectPath 'build'
$folderPath = Join-Path $buildPath "Fort_$Version"
$archivePath = Join-Path $buildPath "Fort_$Version.zip"
if ((Test-Path -LiteralPath $folderPath) -or (Test-Path -LiteralPath $archivePath)) {
    throw "Version $Version already exists. Saved versions are never overwritten."
}
$executablePath = Join-Path $buildPath 'Fort.exe'
if (-not (Test-Path -LiteralPath $executablePath)) { throw 'Export Fort.exe first.' }
New-Item -ItemType Directory -Path $folderPath | Out-Null
Copy-Item -LiteralPath $executablePath,(Join-Path $projectPath 'README.md') -Destination $folderPath
foreach ($document in @('NETWORK_HELP.md','Network-Diagnostics.ps1')) {
    $documentPath = Join-Path $projectPath $document
    if (Test-Path -LiteralPath $documentPath) { Copy-Item -LiteralPath $documentPath -Destination $folderPath }
}
$notesPath = Join-Path $projectPath "RELEASE_NOTES_$Version.md"
if (Test-Path -LiteralPath $notesPath) { Copy-Item -LiteralPath $notesPath -Destination $folderPath }
if ($Version -ge 10) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_9.md') -Destination $folderPath }
if ($Version -ge 11) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_10.md') -Destination $folderPath }
if ($Version -ge 12) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_11.md') -Destination $folderPath }
if ($Version -ge 13) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_12.md') -Destination $folderPath }
if ($Version -ge 14) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_13.md') -Destination $folderPath }
if ($Version -ge 15) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_14.md') -Destination $folderPath }
if ($Version -ge 16) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_15.md') -Destination $folderPath }
if ($Version -ge 17) { Copy-Item -LiteralPath (Join-Path $projectPath 'RELEASE_NOTES_16.md') -Destination $folderPath }
Compress-Archive -LiteralPath $folderPath -DestinationPath $archivePath -CompressionLevel Optimal
$sourceHash = (Get-FileHash -LiteralPath $executablePath -Algorithm SHA256).Hash
if ((Get-FileHash -LiteralPath (Join-Path $folderPath 'Fort.exe') -Algorithm SHA256).Hash -ne $sourceHash) {
    throw 'Copied executable hash mismatch.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $entry = $archive.Entries | Where-Object { $_.Name -eq 'Fort.exe' }
    if ($null -eq $entry) { throw 'Executable missing from ZIP.' }
    $stream = $entry.Open()
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')
        if ($hash -ne $sourceHash) { throw 'ZIP executable hash mismatch.' }
    } finally { $stream.Dispose(); $sha.Dispose() }
    $archive.Entries | Select-Object FullName,Length
} finally { $archive.Dispose() }
Write-Output "VERSION_${Version}_ARCHIVE_VERIFIED"
