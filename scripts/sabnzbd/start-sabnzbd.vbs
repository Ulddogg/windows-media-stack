' start-sabnzbd.vbs — launch SABnzbd's CONSOLE exe hidden and windowless.
' Why the console exe: SABnzbd 5.x's native Windows service is broken (missing
' pythonservice.exe), and NSSM-wrapping SABnzbd.exe fails (it force-triggers its own
' service dispatcher, error 1063). Running SABnzbd-console.exe from a hidden launcher
' via a logon scheduled task is the reliable, reboot-safe approach.
'
' Adjust the two paths and the bind address/port to your install, then register this
' with ..\register-autostart.ps1 (RunLevel Highest).
'
' Run args:  -f <ini>   config file
'            -s host:port  listen address
'            -b 0        do not open a browser
CreateObject("WScript.Shell").Run _
  """C:\Program Files\SABnzbd\SABnzbd-console.exe"" -f ""C:\ProgramData\SABnzbd\sabnzbd.ini"" -s 127.0.0.1:8085 -b 0", 0, False
