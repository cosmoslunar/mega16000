Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::White
$form.Opacity = 0.5
$form.Show()

Start-Sleep -Seconds 1

$procs = Get-Process powershell, pwsh -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match "beta"
}

foreach ($proc in $procs) {
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").CommandLine
        if ($cmd -match '-File\s+\"?([^\s\"]+)\"?') {
            $scriptPath = $Matches[1]
            if (Test-Path $scriptPath) {
                Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            }
        }
    } catch {}
}