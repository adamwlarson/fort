param([string]$Godot = ".tools/godot45/Godot_v4.5.2-stable_win64_console.exe", [switch]$Packaged, [ValidateSet('network_driver','weapons_network_driver','lobby_network_driver','progression_network_driver','construction_network_driver','frontier_network_driver','balance_network_driver','expedition_network_driver','wilderness_network_driver','forestry_network_driver')][string]$Driver = 'network_driver', [ValidatePattern('^(\d{1,3}\.){3}\d{1,3}$')][string]$JoinAddress = '127.0.0.1')
$ErrorActionPreference = "Stop"
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotPath = (Resolve-Path (Join-Path $projectPath $Godot)).Path
if ($Packaged) { $godotPath = Join-Path $projectPath "build/Fort.exe" }
$processes = @()
$logPaths = @()
try {
    foreach ($role in @("server", "client1", "client2", "client3")) {
        $stdoutPath = Join-Path $projectPath ".tools/${Driver}_$role.out"
        $stderrPath = Join-Path $projectPath ".tools/${Driver}_$role.err"
        $arguments = @("--headless", "--path", $projectPath, "--script", "res://tests/$Driver.gd", "--")
        if ($Packaged) { $arguments = @("--headless", "--script", ('"' + (Join-Path $PSScriptRoot "$Driver.gd") + '"'), "--") }
		$arguments = $arguments[0..($arguments.Count-2)] + @('--log-file',('"' + (Join-Path $projectPath ".tools/${Driver}_$role.combined.log") + '"'),'--')
		$arguments += '--fort-test'
		$arguments += "--role=$role"
		$arguments += "--join-ip=$JoinAddress"
        if ($role -eq "server") { $arguments += "--server" }
        $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
        $processes += $process
        $logPaths += @($stdoutPath, $stderrPath)
        Start-Sleep -Milliseconds 650
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(35000)) { throw "Network test process timed out." }
    }
    $failed = $false
    $completed = 0
    foreach ($logPath in $logPaths) {
        $content = Get-Content -LiteralPath $logPath
        if ($content) { Write-Output ($content | Select-Object -First 70) }
        if ($content -match "FAILED|SCRIPT ERROR|^ERROR:|NETWORK_RESULT.+FAIL") { $failed = $true }
        $completed += @($content | Select-String -Pattern "NETWORK_RESULT (SERVER|CLIENT) PASS").Count
    }
    if ($completed -ne 4) { Write-Output "Missing successful completion from one or more processes."; $failed = $true }
    if ($failed) { exit 1 }
    Write-Output "FOUR_PLAYER_TEST_PASS"
} finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }
    }
}
exit 0
