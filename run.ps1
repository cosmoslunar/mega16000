param(
    [string]$AlphaName = "alpha.ps1",
    [string]$SearchRoot = "C:\",
    [string]$ShortcutPath = "$env:USERPROFILE\Desktop\MyApp.lnk",
    [string]$EdgeIconPath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
)

function Test-IsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Relaunch-Elevated {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $scriptPath = $MyInvocation.MyCommand.Definition
    $escaped = $scriptPath -replace '"','\"'
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$escaped`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Exit
    } catch {
        Exit 1
    }
}

function Find-Alpha {
    param($root, $name)
    try {
        Get-ChildItem -Path $root -Filter $name -Recurse -ErrorAction SilentlyContinue -Force -Depth 4
    } catch {
        Get-ChildItem -Path $root -Filter $name -Recurse -ErrorAction SilentlyContinue -Force
    }
}

function Run-Alpha {
    param($fullpath)
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fullpath
    } catch {}
}

function Set-ShortcutIcon {
    param($lnkPath, $iconSourceExe)
    if (-not (Test-Path $lnkPath)) { return }
    if (-not (Test-Path $iconSourceExe)) { return }
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnkPath)
    $shortcut.IconLocation = "$iconSourceExe,0"
    $shortcut.Save()
}

if (-not (Test-IsElevated)) {
    Relaunch-Elevated
    return
}

if ($ShortcutPath -and (Test-Path $EdgeIconPath)) {
    Set-ShortcutIcon -lnkPath $ShortcutPath -iconSourceExe $EdgeIconPath
}

$found = @()
$cwdCandidate = Join-Path -Path (Get-Location) -ChildPath $AlphaName
if (Test-Path $cwdCandidate) {
    $found += (Get-Item $cwdCandidate)
}

if ($found.Count -eq 0) {
    $results = Find-Alpha -root $SearchRoot -name $AlphaName
    if ($results) { $found += $results }
}

if ($found.Count -eq 0) {
    Exit 2
}

$alphaPath = $found[0].FullName
Run-Alpha -fullpath $alphaPath