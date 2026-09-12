param([switch]$Render, [switch]$Export, [switch]$Network)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$godotPath = Join-Path $projectPath '.tools/godot45/Godot_v4.5.2-stable_win64_console.exe'

function Run-GodotCheck([string]$Name, [string[]]$Arguments, [int]$Timeout = 60000) {
    $stdoutPath = Join-Path $projectPath "build/$Name.log"
    $stderrPath = Join-Path $projectPath "build/${Name}_error.log"
    $quoted = @('--path', ('"' + $projectPath + '"')) + $Arguments
    $process = Start-Process -FilePath $godotPath -ArgumentList $quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    # Cache the handle before exit (Windows PowerShell otherwise loses ExitCode).
    $processHandle = $process.Handle
    if (-not $process.WaitForExit($Timeout)) {
        Stop-Process -Id $process.Id
        throw "$Name timed out."
    }
    $stderr = Get-Content -LiteralPath $stderrPath -Raw
    $stdout = Get-Content -LiteralPath $stdoutPath -Raw
    # Match failure markers, not a passing test named "failed mapping cleanup".
    if (($null -ne $process.ExitCode -and $process.ExitCode -ne 0) -or $stderr -match 'ERROR:|SCRIPT ERROR' -or $stdout -match '(?im)^\s*(?:FAIL(?:ED)?\b|[A-Z0-9_]*RESULT[^\r\n]*\bFAIL(?:ED)?\b)') {
        Write-Output $stdout
        Write-Output $stderr
        throw "$Name failed."
    }
    Write-Output "PASS $Name"
}

Run-GodotCheck 'art_import' @('--headless', '--editor', '--quit')
Run-GodotCheck 'gate24_test' @('--headless', '--script', 'res://tests/gate24_test.gd', '--', '--fort-test')
Run-GodotCheck 'gate24_edge_test' @('--headless', '--script', 'res://tests/gate24_edge_test.gd', '--', '--fort-test')
Run-GodotCheck 'crew24_test' @('--headless', '--script', 'res://tests/crew24_test.gd', '--', '--fort-test')
Run-GodotCheck 'crew24_role_test' @('--headless', '--script', 'res://tests/crew24_role_test.gd', '--', '--fort-test')
Run-GodotCheck 'minimap23_test' @('--headless', '--script', 'res://tests/minimap23_test.gd', '--', '--fort-test')
Run-GodotCheck 'siege22_test' @('--headless', '--script', 'res://tests/siege22_test.gd', '--', '--fort-test')
Run-GodotCheck 'planner21_test' @('--headless', '--script', 'res://tests/planner21_test.gd', '--', '--fort-test')
Run-GodotCheck 'navigation21_test' @('--headless', '--script', 'res://tests/navigation21_test.gd', '--', '--fort-test')
Run-GodotCheck 'recovery20_test' @('--headless', '--script', 'res://tests/recovery20_test.gd', '--', '--fort-test')
Run-GodotCheck 'escape19_test' @('--headless', '--script', 'res://tests/escape19_test.gd', '--', '--fort-test')
Run-GodotCheck 'terrain19_test' @('--headless', '--script', 'res://tests/terrain19_test.gd', '--', '--fort-test')
Run-GodotCheck 'clearance18_test' @('--headless', '--script', 'res://tests/clearance18_test.gd', '--', '--fort-test')
Run-GodotCheck 'shared_castle17_test' @('--headless', '--script', 'res://tests/shared_castle17_test.gd', '--', '--fort-test')
Run-GodotCheck 'readability16_test' @('--headless', '--script', 'res://tests/readability16_test.gd', '--', '--fort-test')
foreach ($test in @('asset_test', 'gameplay_test', 'raid_test', 'world_test', 'particles_test', 'interface_test', 'weapons_test', 'fort4_test', 'fort5_test', 'fort6_test', 'fort7_test', 'fort8_test', 'fort9_test', 'arsenal9_test', 'internet10_test', 'wilderness11_test', 'foliage12_test', 'castle13_test', 'cast13_test', 'save14_test', 'save14_edge_test', 'remodel15_test')) {
    Run-GodotCheck $test @('--headless', '--script', "res://tests/$test.gd", '--', '--fort-test')
}
if ($Render) {
	Run-GodotCheck 'gate24_render' @('--script', 'res://tests/gate24_test.gd', '--', '--fort-test')
	Run-GodotCheck 'crew24_render' @('--script', 'res://tests/crew24_test.gd', '--', '--fort-test')
	Run-GodotCheck 'gate24_review' @('--script', 'res://tests/gate24_review.gd', '--', '--fort-test')
	Run-GodotCheck 'minimap23_render' @('--script', 'res://tests/minimap23_test.gd', '--', '--fort-test')
	Run-GodotCheck 'siege22_render' @('--script', 'res://tests/siege22_test.gd', '--', '--fort-test')
	Run-GodotCheck 'planner21_render' @('--script', 'res://tests/planner21_test.gd', '--', '--fort-test')
	Run-GodotCheck 'navigation21_render' @('--script', 'res://tests/navigation21_test.gd', '--', '--fort-test')
	Run-GodotCheck 'recovery20_render' @('--script', 'res://tests/recovery20_test.gd', '--', '--fort-test')
	Run-GodotCheck 'terrain19_render' @('--script', 'res://tests/terrain19_test.gd', '--', '--fort-test')
	Run-GodotCheck 'escape19_render' @('--script', 'res://tests/escape19_test.gd', '--', '--fort-test')
	Run-GodotCheck 'clearance18_render' @('--script', 'res://tests/clearance18_test.gd', '--', '--fort-test')
	Run-GodotCheck 'readability16_render' @('--script', 'res://tests/readability16_test.gd', '--', '--fort-test')
    foreach ($test in @('art_gallery', 'visual_review', 'particles_review', 'interface_test', 'weapons_test', 'fort4_test', 'fort5_test', 'fort6_test', 'fort7_test', 'fort8_test', 'fort9_test', 'internet10_test', 'wilderness11_test', 'foliage12_test', 'castle13_test', 'cast13_test', 'save14_test', 'save14_edge_test', 'remodel15_test', 'swarm_test')) {
        Run-GodotCheck $test @('--script', "res://tests/$test.gd", '--', '--fort-test')
    }
}
if ($Export) {
    Run-GodotCheck 'art_export' @('--headless', '--export-release', '"Windows Desktop"', 'build/Fort.exe')
}
if ($Network) {
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver crew_network_driver -Players 8 -Overflow }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver crew_network_driver -Players 8 -Overflow }
	if ($LASTEXITCODE -ne 0) { throw 'Eight-player crew and capacity test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver gate_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver gate_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player gatehouse test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver siege_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver siege_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player siege indicator test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver recovery_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver recovery_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player recovery test failed.' }
    if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged }
    else { & (Join-Path $PSScriptRoot 'run_network.ps1') }
    if ($LASTEXITCODE -ne 0) { throw 'Four-player test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver weapons_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver weapons_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player weapon test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver lobby_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver lobby_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player lobby test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver progression_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver progression_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player progression test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver construction_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver construction_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player construction test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver frontier_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver frontier_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player frontier test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver balance_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver balance_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player balance test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver expedition_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver expedition_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player expedition test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver wilderness_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver wilderness_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player wilderness test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver forestry_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver forestry_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player forestry test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver castle_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver castle_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player castle test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver save_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver save_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player save/load test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver remodel_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver remodel_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player remodeling test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver readability_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver readability_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player readability test failed.' }
	if ($Export) { & (Join-Path $PSScriptRoot 'run_network.ps1') -Packaged -Driver clearance_network_driver }
	else { & (Join-Path $PSScriptRoot 'run_network.ps1') -Driver clearance_network_driver }
	if ($LASTEXITCODE -ne 0) { throw 'Four-player castle clearance test failed.' }
}
if ($Export) {
    Compress-Archive -LiteralPath (Join-Path $projectPath 'build/Fort.exe'), (Join-Path $projectPath 'README.md') -DestinationPath (Join-Path $projectPath 'build/Fort-Windows.zip') -Force
}
Write-Output 'ART_PASS_CHECKS_OK'
