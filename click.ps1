$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$extensions = "*.ps1","*.exe","*.bat"
foreach ($ext in $extensions) {
    Get-ChildItem -Path $folder -Filter $ext | ForEach-Object {
        if ($_.FullName -ne $MyInvocation.MyCommand.Path) {
            Start-Process $_.FullName -Wait
        }
    }
}