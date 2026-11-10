param([switch]$Render)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$godotPath = Join-Path $projectPath '.tools/godot45/Godot_v4.5.2-stable_win64_console.exe'
$testNames = @('fort26_test','improvements25_test','crew24_test','crew24_role_test','gate24_test','gate24_edge_test','planner21_test','navigation21_test','gameplay_test','raid_test','interface_test','weapons_test','fort5_test','fort7_test','fort9_test','arsenal9_test','wilderness11_test','castle13_test','save14_test','save14_edge_test','remodel15_test')
$failedTests = @()
foreach ($testName in $testNames) {
    $stdoutPath = Join-Path $projectPath "build/verify25_$testName.log"
    $stderrPath = Join-Path $projectPath "build/verify25_${testName}_error.log"
    $arguments = @('--path', ('"' + $projectPath + '"'), '--log-file', ('"' + (Join-Path $projectPath "build/verify25_${testName}_engine.log") + '"'), '--script', "res://tests/$testName.gd", '--', '--fort-test')
    if (-not $Render) { $arguments = @('--headless') + $arguments }
    $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(60000)) { Stop-Process -Id $process.Id; $failedTests += $testName; Write-Output "FAIL $testName timed out"; continue }
    $stdout = Get-Content -LiteralPath $stdoutPath -Raw
    $stderr = Get-Content -LiteralPath $stderrPath -Raw
    # Realtime sky radiance buffers are reported by the GL driver at shutdown; not a game error.
    if ($stderr) { $stderr = (($stderr -split "`n") | Where-Object { $_ -notmatch 'Texture with GL ID of \d+: leaked|drivers/gles3/storage/utilities.cpp' }) -join "`n" }
    if ($process.ExitCode -ne 0 -or $stderr -match 'ERROR:|SCRIPT ERROR' -or $stdout -match '(?im)^\s*FAIL(?:ED)?\b|RESULT[^\r\n]*\bFAIL(?:ED)?\b') {
        $failedTests += $testName
        Write-Output "FAIL $testName"
        Write-Output (($stdout -split "`n" | Where-Object { $_ -match '^FAIL|RESULT' }) -join "`n")
        Write-Output $stderr
    } else { Write-Output "PASS $testName" }
}
if ($failedTests.Count -gt 0) { throw ('Failed checks: ' + ($failedTests -join ', ')) }
Write-Output 'IMPROVEMENTS_REGRESSION_PASS'
