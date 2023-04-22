#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [string]
    $ProcessNameRegEx = 'iexplore',

    [string]
    $WindowTitleRegEx = 'unt'
)

$cs = @" 
using System; 
using System.Runtime.InteropServices;

namespace User32
{
    public static class WindowManagement
    {
        [DllImport("user32.dll", EntryPoint = "SetWindowPos")]
        public static extern IntPtr SetWindowPos(IntPtr hWnd, int hWndInsertAfter, int x, int Y, int cx, int cy, int wFlags);

        public const int SWP_NOSIZE = 0x01, SWP_NOMOVE = 0x02, SWP_SHOWWINDOW = 0x40, SWP_HIDEWINDOW = 0x80;

        public static void SetWindowPosWrappoer(IntPtr handle, int x, int y, int width, int height)
        {
            if (handle != null)
            { 
                SetWindowPos(handle, 0, x, y, 0, 0, SWP_NOSIZE | SWP_HIDEWINDOW);

                if (width > -1 && height > -1)
                    SetWindowPos(handle, 0, 0, 0, width, height, SWP_NOMOVE);

                SetWindowPos(handle, 0, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
            }
        }

        [DllImport("user32.dll", EntryPoint = "ShowWindow")]
        public static extern IntPtr ShowWindow(IntPtr hWnd, int nCmdShow);

        public static void ShowWindowWrapper(IntPtr handle, int nCmdShow)
        {
            if (handle != null)
            { 
                ShowWindow(handle, nCmdShow);
            }
        }

        [DllImport("user32.dll", EntryPoint = "SetForegroundWindow")]
        public static extern IntPtr SetForegroundWindow(IntPtr hWnd);

        public static void SetForegroundWindowWrapper(IntPtr handle)
        {
            if (handle != null)
            { 
                SetForegroundWindow(handle);
            }
        }
    }
}
"@ 

Add-Type -TypeDefinition $cs -Language CSharp -ErrorAction SilentlyContinue


function Move-Window
{
    param (
        [int]$MainWindowHandle,
        [int]$PosX,
        [int]$PosY,
        [int]$Height,
        [int]$Width
    )

    if($MainWindowHandle -ne [System.IntPtr]::Zero)
    {
        [User32.WindowManagement]::SetWindowPosWrappoer($MainWindowHandle, $PosX, $PosY, $Width, $Height);
    }
    else
    {
      throw "Couldn't find the MainWindowHandle, aborting (your process should be still alive)"
    }
}


function Show-Window
{
    param (
        [int]$MainWindowHandle,
        [int]$CmdShow
    )

    if($MainWindowHandle -ne [System.IntPtr]::Zero)
    {
        [User32.WindowManagement]::ShowWindowWrapper($MainWindowHandle, $CmdShow);
        [User32.WindowManagement]::SetForegroundWindowWrapper($MainWindowHandle);
    }
    else
    {
      throw "Couldn't find the MainWindowHandle, aborting (your process should be still alive)"
    }
}



$windows = Get-Process | ? {$_.ProcessName -match $ProcessNameRegEx } | Select -Last 100 | Select Id, MainWindowTitle, MainWindowHandle | Sort MainWindowTitle
#-and $_.MainWindowTitle -match $WindowTitleRegEx

$h = ([system.windows.forms.screen]::PrimaryScreen).WorkingArea.Height
$w = ([system.windows.forms.screen]::PrimaryScreen).WorkingArea.Width
$x = 0
$y = 0

Foreach($window in $windows){
    Move-Window $window.MainWindowHandle $x $y $h $w
    Show-Window $window.MainWindowHandle 5
}
