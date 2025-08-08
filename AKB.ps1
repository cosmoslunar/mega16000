$targets = @("V3Lite.exe", "V3Engn.exe", "V3Main.exe", "AYUpdSrv.exe")

foreach ($proc in $targets) {
    try {
        Stop-Process -Name ($proc -replace ".exe","") -Force -ErrorAction SilentlyContinue
        taskkill /f /im $proc | Out-Null
    } catch {}
}

$services = Get-Service | Where-Object { $_.DisplayName -like "*Ahn*" }
foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        sc.exe delete $svc.Name | Out-Null
    } catch {}
}

$paths = @(
    "C:\Program Files\AhnLab",
    "C:\Program Files (x86)\AhnLab"
)
foreach ($path in $paths) {
    try {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
}