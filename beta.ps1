Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-ColorForm {
    param(
        [System.Drawing.Color]$BackColor,
        [int]$X,
        [int]$Y,
        [int]$W = 200,
        [int]$H = 150
    )
    $form = New-Object System.Windows.Forms.Form
    $form.StartPosition = 'Manual'
    $form.FormBorderStyle = 'None'
    $form.BackColor = $BackColor
    $form.Size = New-Object System.Drawing.Size($W,$H)
    $form.Location = New-Object System.Drawing.Point($X,$Y)
    $form.TopMost = $true
    $form.Show()
    return $form
}

$rand = New-Object System.Random
$forms = @()

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $w = 1000; $h = 1000
    $x = $rand.Next($screen.Left, [Math]::Max($screen.Left, $screen.Right - $w))
    $y = $rand.Next($screen.Top, [Math]::Max($screen.Top, $screen.Bottom - $h))
    $color = if ($rand.Next(2) -eq 0) { [System.Drawing.Color]::Red } else { [System.Drawing.Color]::Blue }
    $forms += New-ColorForm -BackColor $color -X $x -Y $y -W $w -H $h
})
$timer.Start()

[System.Windows.Forms.Application]::Run()