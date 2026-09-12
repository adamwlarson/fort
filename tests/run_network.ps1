param([string]$Godot = ".tools/godot45/Godot_v4.5.2-stable_win64_console.exe", [switch]$Packaged, [ValidateSet('network_driver','weapons_network_driver','lobby_network_driver','progression_network_driver','construction_network_driver','frontier_network_driver','balance_network_driver','expedition_network_driver','wilderness_network_driver','forestry_network_driver','castle_network_driver','save_network_driver','remodel_network_driver','readability_network_driver','clearance_network_driver','recovery_network_driver','siege_network_driver','gate_network_driver','crew_network_driver')][string]$Driver = 'network_driver', [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')][string]$JoinAddress = '127.0.0.1', [ValidateRange(2,8)][int]$Players=4, [switch]$Overflow)
$ErrorActionPreference = "Stop"
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotPath = (Resolve-Path (Join-Path $projectPath $Godot)).Path
if ($Packaged) { $godotPath = Join-Path $projectPath "build/Fort.exe" }
$processes = @()
$logPaths = @()
try {
    $roles = @('server') + @(1..($Players-1) | ForEach-Object { "client$_" })
    if ($Overflow) { $roles += 'overflow' }
    foreach ($role in $roles) {
        $stdoutPath = Join-Path $projectPath ".tools/${Driver}_$role.out"
        $stderrPath = Join-Path $projectPath ".tools/${Driver}_$role.err"
        $arguments = @("--headless", "--path", $projectPath, "--script", "res://tests/$Driver.gd", "--")
        if ($Packaged) { $arguments = @("--headless", "--script", ('"' + (Join-Path $PSScriptRoot "$Driver.gd") + '"'), "--") }
		$arguments = $arguments[0..($arguments.Count-2)] + @('--log-file',('"' + (Join-Path $projectPath ".tools/${Driver}_$role.combined.log") + '"'),'--')
		$arguments += '--fort-test'
		$arguments += "--role=$role"
		$arguments += "--join-ip=$JoinAddress"
		$arguments += "--expected-players=$Players"
        if ($role -eq "server") { $arguments += "--server" }
        $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
        $processes += $process
        $logPaths += @($stdoutPath, $stderrPath)
        Start-Sleep -Milliseconds 650
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(60000)) { throw "Network test process timed out." }
    }
    $failed = $false
    $completed = 0
    foreach ($logPath in $logPaths) {
        $content = Get-Content -LiteralPath $logPath
        if ($content) { Write-Output ($content | Select-Object -First 70) }
        if ($content -match "FAILED|SCRIPT ERROR|^ERROR:|NETWORK_RESULT.+FAIL") { $failed = $true }
        $completed += @($content | Select-String -Pattern "NETWORK_RESULT (SERVER|CLIENT) PASS").Count
    }
    if ($completed -ne $roles.Count) { Write-Output "Missing successful completion from one or more processes."; $failed = $true }
    if ($failed) { exit 1 }
    if ($Players -eq 4) { Write-Output "FOUR_PLAYER_TEST_PASS" } else { Write-Output "${Players}_PLAYER_TEST_PASS" }
} finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }
    }
}
exit 0
