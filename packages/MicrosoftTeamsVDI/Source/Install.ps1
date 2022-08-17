<#
    .SYNOPSIS
    Installs the application
#>
[CmdletBinding()]
param ()

#region Restart if running in a 32-bit session
if (!([System.Environment]::Is64BitProcess)) {
    if ([System.Environment]::Is64BitOperatingSystem) {
        $Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Definition)`""
        $ProcessPath = $(Join-Path -Path $Env:SystemRoot -ChildPath "\Sysnative\WindowsPowerShell\v1.0\powershell.exe")
        $params = @{
            FilePath     = $ProcessPath
            ArgumentList = $Arguments
            Wait         = $True
            WindowStyle  = "Hidden"
        }
        Start-Process @params
        exit 0
    }
}
#endregion

if (Test-Path -Path "${env:ProgramFiles(x86)}\Microsoft\Teams\current\Teams.exe") {

    try {
        Get-Process -ErrorAction "SilentlyContinue" | `
            Where-Object { $_.Path -like "${env:ProgramFiles(x86)}\Microsoft\Teams*" } | `
            Stop-Process -Force -ErrorAction "SilentlyContinue"
    }
    catch {
        Write-Warning -Message "Failed to stop Teams processes."
    }

    try {
        New-Item -Path "$env:ProgramData\PackageFactory\Logs" -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null
        $Product = Get-CimInstance -Class "Win32_Product" | Where-Object { $_.Caption -like "Teams Machine-Wide Installer" }
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/uninstall `"$($Product.IdentifyingNumber)`" /quiet /log `"C:\ProgramData\PackageFactory\logs\MicrosoftTeams.log`""
            NoNewWindow  = $True
            PassThru     = $True
            Wait         = $True
        }
        $result = Start-Process @params
        Remove-Item -Path "${env:ProgramFiles(x86)}\Microsoft\Teams" -Recurse -Force -ErrorAction "SilentlyContinue"
        Remove-Item -Path "${env:ProgramFiles(x86)}\Microsoft\TeamsPresenceAddin" -Recurse -Force -ErrorAction "SilentlyContinue"
    }
    catch {
        throw $_
    }
    finally {
        exit $result.ExitCode
    }
}

try {
    $Installer = Get-ChildItem -Path $PWD -Filter "Teams_windows_x64.msi" -Recurse -ErrorAction "SilentlyContinue"
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($Installer.FullName)`" OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1 /quiet /log `"C:\ProgramData\PackageFactory\logs\MicrosoftTeams.log`""
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
    }
    $result = Start-Process @params
}
catch {
    throw $_
}
finally {
    exit $result.ExitCode
}
