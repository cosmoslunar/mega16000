param(
    [string]$watchPath = "D:\I"
)

function Wipe-And-Delete($filePath) {
    try {
        $fileInfo = Get-Item $filePath -ErrorAction Stop
        $length = $fileInfo.Length
        $fs = [System.IO.File]::Open($filePath, 'Open', 'Write')
        $rand = New-Object byte[] $length
        (New-Object System.Random).NextBytes($rand)
        $fs.Write($rand, 0, $length)
        $fs.Close()
        Remove-Item $filePath -Force
    } catch {}
}

$fsw = New-Object IO.FileSystemWatcher $watchPath -Property @{
    IncludeSubdirectories = $false
    NotifyFilter = [IO.NotifyFilters]'LastAccess, FileName, LastWrite'
}

Register-ObjectEvent $fsw Changed -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Start-Sleep -Milliseconds 100
    Wipe-And-Delete $filePath
}

while ($true) {
    Start-Sleep -Seconds 5
}