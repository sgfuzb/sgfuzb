# VirtualDesktop

C# command line tool to manage virtual desktops in Windows 10<br><br> 
(look for a powershell version here: https://gallery.technet.microsoft.com/Powershell-commands-to-d0e79cc5)

**With Windows 10 1803 Microsoft changed the API (COM GUIDs) for accessing the functions for virtual desktops again. I provide two versions of virtualdesktop.cs now: virutaldesktop.cs is for Windows 10 1803, virtualdesktop1709.cs is for Windows 10 1607 to 1709 and Windows Server 2016. Using Compile.bat will generate both executables (thanks to [mzomparelli](https://github.com/mzomparelli/zVirtualDesktop/wiki) for investigating).**

**Generate:**<br>
Compile with Compile.bat (no visual studio needed, but obviously Windows 10)

**Description:**<br>
Command line tool to manage the virtual desktops of Windows 10.
Parameters can be given as a sequence of commands. The result - most of thetimes the number of the processed desktop - can be used as input for the next parameter. The result of the last command is returned as error level.
Virtual desktop numbers start with 0.

**Parameters (leading / can be omitted or - can be used instead):**<br>
/Help /h /?      this help screen.<br>
/Verbose /Quiet  enable verbose (default) or quiet mode (short: /v and /q).<br>
/Break /Continue break (default) or continue on error.<br>
/Count           get count of virtual desktops to pipeline (short: /c).<br>
/GetDesktop:(n)  get number of virtual desktop (n) to pipeline (short: /gd).<br>
/GetCurrentDesktop  get number of current desktop to pipeline (short: /gcd).<br>
/IsVisible[:(n)]  is desktop number (n) or number in pipeline visible (short: /iv)? Returns 0 for visible and 1 for invisible.<br>
/Switch[:(n)]    switch to desktop with number (n) or with number in pipeline (short: /s).<br>
/Left            switch to virtual desktop to the left of the active desktop.<br>
/Right           switch to virtual desktop to the right of the active desktop.<br>
/New             create new desktop (short: /n). Number is stored in pipeline.<br>
/Remove[:(n)]    remove desktop number (n) or desktop with number in pipeline (short: /r).<br>
/MoveWindow:(s)  move process with name (s) to desktop with number in pipeline (short: /mw).<br>
/MoveWindow:(n)  move process with id (n) to desktop with number in pipeline (short: /mw).<br>
/GetDesktopFromWindow:(s)  get desktop number where process with name (s) is displayed (short: /gdfw).<br>
/GetDesktopFromWindow:(n)  get desktop number where process with id (n) is displayed (short: /gdfw).<br>
/IsWindowOnDesktop:(s)  check if process with name (s) is on desktop with number in pipeline (short: /iwod). Returns 0 for yes, 1 for no.<br>
/IsWindowOnDesktop:(n)  check if process with id (n) is on desktop with number in pipeline (short: /iwod). Returns 0 for yes, 1 for no.<br>
/PinWindow:(s)   pin process with name (s) to all desktops (short: /pw).<br>
/PinWindow:(n)   pin process with id (n) to all desktops (short: /pw).<br>
/UnPinWindow:(s)  unpin process with name (s) from all desktops (short: /upw).<br>
/UnPinWindow:(n)  unpin process with id (n) from all desktops (short: /upw).<br>
/IsWindowPinned:(s)  check if process with name (s) is pinned to all desktops (short: /iwp). Returns 0 for yes, 1 for no.<br>
/IsWindowPinned:(n)  check if process with id (n) is pinned to all desktops (short: /iwp). Returns 0 for yes, 1 for no.<br>
/PinApplication:(s)  pin application with name (s) to all desktops (short: /pa).<br>
/PinApplication:(n)  pin application with process id (n) to all desktops (short: /pa).<br>
/UnPinApplication:(s)  unpin application with name (s) from all desktops (short: /upa).<br>
/UnPinApplication:(n)  unpin application with process id (n) from all desktops (short: /upa).<br>
/IsApplicationPinned:(s)  check if application with name (s) is pinned to all desktops (short: /iap). Returns 0 for yes, 1 for no.<br>
/IsApplicationPinned:(n)  check if application with process id (n) is pinned to all desktops (short: /iap). Returns 0 for yes, 1 for no.<br>
/WaitKey         wait for key press (short: /wk).<br>
/Sleep[:(n)]     wait for (n) milliseconds.<br>
<br>
**Examples:**<br>
Virtualdesktop.exe -New -Switch -GetCurrentDesktop<br>
Virtualdesktop.exe sleep:200 gd:1 mw:notepad s<br>
Virtualdesktop.exe /Count /continue /Remove /Remove /Count<br>
