[CmdletBinding()]
param(
    [int]$TargetWidthPercent = 50,
    [int]$TargetHeightPercent = 55
)

$ErrorActionPreference = 'Stop'

Add-Type -Namespace TerminALL -Name NativeMethods -MemberDefinition @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
'@

Add-Type -AssemblyName System.Windows.Forms

$terminalProcess = $null
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $terminalProcess = Get-Process WindowsTerminal -ErrorAction SilentlyContinue |
        Sort-Object StartTime -Descending |
        Select-Object -First 1

    if ($terminalProcess -and $terminalProcess.MainWindowHandle -ne 0) {
        break
    }

    Start-Sleep -Milliseconds 300
    if ($terminalProcess) {
        $null = $terminalProcess.Refresh()
    }
}

if (-not $terminalProcess -or $terminalProcess.MainWindowHandle -eq 0) {
    exit 0
}

$null = $terminalProcess.Refresh()

for ($attempt = 0; $attempt -lt 12; $attempt++) {
    Start-Sleep -Milliseconds 350
    $null = $terminalProcess.Refresh()
    $workArea = [System.Windows.Forms.Screen]::FromHandle($terminalProcess.MainWindowHandle).WorkingArea
$rect = New-Object TerminALL.NativeMethods+RECT
$gotRect = [TerminALL.NativeMethods]::GetWindowRect($terminalProcess.MainWindowHandle, [ref]$rect)

    if ($gotRect) {
        $windowWidth = $rect.Right - $rect.Left
        $windowHeight = $rect.Bottom - $rect.Top
    }
    else {
        $windowWidth = [math]::Round($workArea.Width * ($TargetWidthPercent / 100))
        $windowHeight = [math]::Round($workArea.Height * ($TargetHeightPercent / 100))
    }

    $x = $workArea.Left + [math]::Round(($workArea.Width - $windowWidth) / 2)
    $y = $workArea.Top + [math]::Round(($workArea.Height - $windowHeight) / 2)

    [TerminALL.NativeMethods]::ShowWindow($terminalProcess.MainWindowHandle, 9) | Out-Null
    [TerminALL.NativeMethods]::MoveWindow($terminalProcess.MainWindowHandle, $x, $y, $windowWidth, $windowHeight, $true) | Out-Null
}
