#Requires -RunAsAdministrator
# register-autostart.ps1
# Register logon scheduled tasks for the apps that don't run as Windows services.
# Run from an ELEVATED PowerShell (the SABnzbd task needs RunLevel Highest).
# Adjust the launcher paths to match your install, then run once.

$tasks = @(
    @{ Name = 'Bazarr';       Launcher = 'C:\ProgramData\Bazarr\start-bazarr.vbs';             RunLevel = 'Limited' }
    @{ Name = 'Seerr';        Launcher = 'C:\seerr\start-seerr.vbs';                           RunLevel = 'Limited' }
    @{ Name = 'FlareSolverr'; Launcher = 'C:\ProgramData\FlareSolverr\start-flaresolverr.vbs'; RunLevel = 'Limited' }
    @{ Name = 'SABnzbd';      Launcher = 'C:\ProgramData\SABnzbd\start-sabnzbd.vbs';           RunLevel = 'Highest' }
)

foreach ($t in $tasks) {
    if (-not (Test-Path $t.Launcher)) {
        Write-Warning "launcher missing: $($t.Launcher) — skipping $($t.Name)"
        continue
    }
    $action    = New-ScheduledTaskAction  -Execute 'wscript.exe' -Argument ('"{0}"' -f $t.Launcher)
    $trigger   = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel $t.RunLevel
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $t.Name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Host ("registered logon task: {0}  (RunLevel {1})" -f $t.Name, $t.RunLevel)
}

Write-Host 'Done. Tasks start the apps at next logon; run their launchers now to start immediately.'
