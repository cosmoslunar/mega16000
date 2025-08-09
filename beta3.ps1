Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$msgs = @(
    "마이크 권한 허용이 필요합니다.",
    "카메라 권한 허용이 필요합니다.",
    "마이크와 카메라 권한이 필요합니다.",
    "권한 요청: 마이크 권한이 필요합니다.",
    "권한 요청: 카메라 권한이 필요합니다."
)

$index = 0

function New-RandomColorForm {
    param(
        [int]$W = 200,
        [int]$H = 150
    )
    $color = [System.Drawing.Color]::FromArgb(255, (Get-Random -Minimum 0 -Maximum 256), (Get-Random -Minimum 0 -Maximum 256), (Get-Random -Minimum 0 -Maximum 256))
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $x = Get-Random -Minimum $screen.Left -Maximum ($screen.Right - $W)
    $y = Get-Random -Minimum $screen.Top -Maximum ($screen.Bottom - $H)
    $form.Location = New-Object System.Drawing.Point($x, $y)
    $form.Size = New-Object System.Drawing.Size($W, $H)
    $form.BackColor = $color
    $form.TopMost = $true
    $form.Show()
    return $form
}

$forms = @()

$flashTimer = New-Object System.Windows.Forms.Timer
$flashTimer.Interval = 100
$flashTimer.Add_Tick({
    for ($i=0; $i -lt 10; $i++) {
        $forms += New-RandomColorForm
    }
    if ($forms.Count -gt 1000) {
        $old = $forms[0..99]
        foreach ($f in $old) { $f.Close() }
        $forms = $forms[100..($forms.Count - 1)]
    }
})
$flashTimer.Start()

$msgTimer = New-Object System.Windows.Forms.Timer
$msgTimer.Interval = 1000
$msgTimer.Add_Tick({
    [System.Windows.Forms.MessageBox]::Show($msgs[$index], "권한 요청", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    $index = ($index + 1) % $msgs.Count
})
$msgTimer.Start()

[System.Windows.Forms.Application]::Run()