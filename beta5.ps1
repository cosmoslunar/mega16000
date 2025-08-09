Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false
$form.DoubleBuffered = $true

$rand = New-Object System.Random
$width = $form.ClientSize.Width
$height = $form.ClientSize.Height

$cursorPos = [System.Drawing.Point]::new($width/2, $height/2)
$cursorVel = [System.Drawing.Point]::new(10, 7)
$cursorToggle = $true
$cursorSize = 20

$mosaicPoints = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
$mosaicMax = 300

function Get-HexagonPoints($center, $radius, $angleDeg) {
    $points = @()
    for ($i=0; $i -lt 6; $i++) {
        $theta = [Math]::PI/3 * $i + $angleDeg * [Math]::PI/180
        $x = $center.X + $radius * [Math]::Cos($theta)
        $y = $center.Y + $radius * [Math]::Sin($theta)
        $points += [System.Drawing.PointF]::new($x, $y)
    }
    return $points
}

$hexagons = @()
for ($i=0; $i -lt 6; $i++) {
    $pos = [System.Drawing.PointF]::new($rand.Next($width), $rand.Next($height))
    $vel = [System.Drawing.PointF]::new((Get-Random -Minimum -8 -Maximum 8), (Get-Random -Minimum -8 -Maximum 8))
    $angle = $rand.Next(360)
    $rotSpeed = (Get-Random -Minimum -10 -Maximum 10)
    $hexagons += [PSCustomObject]@{ Pos=$pos; Vel=$vel; Angle=$angle; RotSpeed=$rotSpeed; Radius=40 }
}

$imageUrls = @(
    "https://cdn.pixabay.com/photo/2013/07/12/16/24/space-151227_960_720.png",
    "https://cdn.pixabay.com/photo/2016/11/21/17/06/space-1846314_960_720.jpg",
    "https://cdn.pixabay.com/photo/2016/12/15/12/28/nebula-1909531_960_720.jpg",
    "https://cdn.pixabay.com/photo/2015/05/10/16/21/space-762520_960_720.jpg"
)
$images = @()
foreach ($url in $imageUrls) {
    try {
        $req = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $ms = New-Object System.IO.MemoryStream(,$req.RawContent)
        $bmp = New-Object System.Drawing.Bitmap $ms
        $images += $bmp
    } catch {}
}

$imageIndex = 0
$angleImg = 0
$brightness = 1.0
$brightInc = 0.02

$form.Add_Shown({
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 30
    $timer.Add_Tick({
        $g = $form.CreateGraphics()
        $g.Clear([System.Drawing.Color]::Black)

        if ($images.Count -gt 0) {
            $bmpOrig = $images[$imageIndex]
            $w, $h = $bmpOrig.Width, $bmpOrig.Height
            $bmp = New-Object System.Drawing.Bitmap $w, $h
            for ($x=0; $x -lt $w; $x++) {
                for ($y=0; $y -lt $h; $y++) {
                    $c = $bmpOrig.GetPixel($x,$y)
                    $r = [Math]::Min(255, ([Math]::Max(0,(255 - $c.R) * $brightness)))
                    $g_ = [Math]::Min(255, ([Math]::Max(0,(255 - $c.G) * $brightness)))
                    $b = [Math]::Min(255, ([Math]::Max(0,(255 - $c.B) * $brightness)))
                    $bmp.SetPixel($x,$y,[System.Drawing.Color]::FromArgb($r,$g_,$b))
                }
            }
            $matrix = New-Object System.Drawing.Drawing2D.Matrix
            $matrix.Translate($width/2, $height/2)
            $matrix.Rotate($angleImg)
            $scale = 0.8 + 0.4 * [Math]::Sin($angleImg * [Math]::PI/180)
            $matrix.Scale($scale, $scale)
            $matrix.Translate(-$w/2, -$h/2)
            $g.Transform = $matrix
            $g.DrawImage($bmp, [System.Drawing.Point]::Empty)
            $g.ResetTransform()
        }

        foreach ($hex in $hexagons) {
            $hex.Pos = [System.Drawing.PointF]::new($hex.Pos.X + $hex.Vel.X, $hex.Pos.Y + $hex.Vel.Y)
            if ($hex.Pos.X -lt $hex.Radius -or $hex.Pos.X -gt $width - $hex.Radius) { $hex.Vel = [System.Drawing.PointF]::new(-$hex.Vel.X, $hex.Vel.Y) }
            if ($hex.Pos.Y -lt $hex.Radius -or $hex.Pos.Y -gt $height - $hex.Radius) { $hex.Vel = [System.Drawing.PointF]::new($hex.Vel.X, -$hex.Vel.Y) }
            $hex.Angle = ($hex.Angle + $hex.RotSpeed) % 360
            $points = Get-HexagonPoints $hex.Pos $hex.Radius $hex.Angle
            $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, $rand.Next(256), $rand.Next(256), $rand.Next(256)))
            $g.FillPolygon($brush, $points)
        }

        foreach ($pt in $mosaicPoints) {
            $rect = New-Object System.Drawing.Rectangle ($pt.X, $pt.Y, 15, 15)
            $color = [System.Drawing.Color]::FromArgb(120, $rand.Next(256), $rand.Next(256), $rand.Next(256))
            $brush = New-Object System.Drawing.SolidBrush $color
            $g.FillRectangle($brush, $rect)
        }

        $mosaicPoints.Enqueue([System.Drawing.Point]::new($cursorPos.X - 7, $cursorPos.Y - 7))
        if ($mosaicPoints.Count -gt $mosaicMax) { $mosaicPoints.Dequeue() }

        $cursorColor = if ($cursorToggle) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
        $cursorToggle = -not $cursorToggle
        $cursorPen = New-Object System.Drawing.Pen $cursorColor, 3
        $cursorBrush = New-Object System.Drawing.SolidBrush $cursorColor
        $g.FillEllipse($cursorBrush, $cursorPos.X - $cursorSize/2, $cursorPos.Y - $cursorSize/2, $cursorSize, $cursorSize)
        $g.DrawEllipse($cursorPen, $cursorPos.X - $cursorSize/2, $cursorPos.Y - $cursorSize/2, $cursorSize, $cursorSize)

        $nextX = $cursorPos.X + $cursorVel.X
        $nextY = $cursorPos.Y + $cursorVel.Y
        if ($nextX -lt 0 -or $nextX -gt $width) { $cursorVel = [System.Drawing.Point]::new(-$cursorVel.X, $cursorVel.Y) }
        if ($nextY -lt 0 -or $nextY -gt $height) { $cursorVel = [System.Drawing.Point]::new($cursorVel.X, -$cursorVel.Y) }
        $cursorPos = [System.Drawing.Point]::new($cursorPos.X + $cursorVel.X, $cursorPos.Y + $cursorVel.Y)

        $angleImg = ($angleImg + 3) % 360
        $brightness += $brightInc
        if ($brightness -ge 2 -or $brightness -le 0.3) { $brightInc = -$brightInc }

        $g.Dispose()
    })
    $timer.Start()
})

[System.Windows.Forms.Application]::Run($form)