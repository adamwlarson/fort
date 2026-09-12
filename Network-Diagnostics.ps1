param([ValidateRange(1,65535)][int]$Port = 24567)
$ErrorActionPreference = 'Continue'
$fortExecutable = Join-Path $PSScriptRoot 'Fort.exe'
Write-Output "Fort read-only diagnostics. Expected executable: $fortExecutable"
Write-Output "Selected UDP port: $Port"
Get-NetIPConfiguration | Select-Object InterfaceAlias,IPv4Address,IPv4DefaultGateway | Format-List
Get-NetConnectionProfile | Select-Object Name,InterfaceAlias,NetworkCategory | Format-Table -AutoSize
Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess | Format-Table -AutoSize
Get-NetFirewallApplicationFilter | Where-Object { $_.Program -eq $fortExecutable } | ForEach-Object {
    $_ | Get-NetFirewallRule | Select-Object DisplayName,Enabled,Direction,Action,Profile | Format-Table -AutoSize
}
Write-Output 'No firewall entries above means none matched this exact executable path.'
Write-Output 'A local listener is not proof of LAN reachability. Check the same IP/port from the second PC.'
