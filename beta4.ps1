Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$forms = @()

function New-ColorForm {
    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'Manual'
    $form.Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $form.BackColor = [System.Drawing.Color]::FromArgb((Get-Random -Min 0 -Max 256),(Get-Random -Min 0 -Max 256),(Get-Random -Min 0 -Max 256))
    $form.FormBorderStyle = 'None'
    $form.TopMost = $true
    $form.Show()
    $forms += $form
}

function RandomSmallForm {
    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'Manual'
    $form.Size = New-Object System.Drawing.Size (Get-Random -Min 50 -Max 400),(Get-Random -Min 50 -Max 400)
    $form.Location = New-Object System.Drawing.Point (Get-Random -Min 0 -Max ([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width - 100)),(Get-Random -Min 0 -Max ([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height - 100))
    $form.BackColor = [System.Drawing.Color]::FromArgb((Get-Random -Min 0 -Max 256),(Get-Random -Min 0 -Max 256),(Get-Random -Min 0 -Max 256))
    $form.FormBorderStyle = 'None'
    $form.TopMost = $true
    $form.Show()
    $forms += $form
}

$timerFull = New-Object System.Windows.Forms.Timer
$timerFull.Interval = 100
$timerFull.Add_Tick({
    New-ColorForm
    if ($forms.Count -gt 200) {
        $forms[0..49] | ForEach-Object { $_.Close() }
        $forms = $forms[50..($forms.Count-1)]
    }
})

$timerSmall = New-Object System.Windows.Forms.Timer
$timerSmall.Interval = 100
$timerSmall.Add_Tick({
    for ($i=0; $i -lt 10; $i++) {
        RandomSmallForm
    }
    if ($forms.Count -gt 2000) {
        $forms[0..199] | ForEach-Object { $_.Close() }
        $forms = $forms[200..($forms.Count-1)]
    }
})

$timerInvert = New-Object System.Windows.Forms.Timer
$timerInvert.Interval = 300
$timerInvert.Add_Tick({
    $sig = '[DllImport("user32.dll")] public static extern bool InvertRect(IntPtr hDC, ref RECT lpRect); struct RECT { public int Left; public int Top; public int Right; public int Bottom; }'
    Add-Type -MemberDefinition $sig -Name 'Native' -Namespace 'Win32'
    $rect = New-Object Win32.Native+RECT
    $rect.Left = 0
    $rect.Top = 0
    $rect.Right = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $rect.Bottom = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    $graphics = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
    $hdc = $graphics.GetHdc()
    [Win32.Native]::InvertRect($hdc, [ref]$rect) | Out-Null
    $graphics.ReleaseHdc($hdc)
    $graphics.Dispose()
})

$timerFull.Start()
$timerSmall.Start()
$timerInvert.Start()

[System.Windows.Forms.Application]::Run()