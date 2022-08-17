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

$prefs = @"
{
    "homepage": "https://www.office.com",
    "homepage_is_newtabpage": false,
    "browser": {
        "show_home_button": true
    },
    "session": {
        "restore_on_startup": 4,
        "startup_urls": []
    },
    "bookmark_bar": {
        "show_on_all_tabs": false
    },
    "sync_promo": {
        "show_on_first_run_allowed": false
    },
    "distribution": {
        "ping_delay": 60,
        "suppress_first_run_bubble": true,
        "do_not_create_desktop_shortcut": true,
        "do_not_create_quick_launch_shortcut": true,
        "do_not_launch_chrome": true,
        "do_not_register_for_update_launch": true,
        "make_chrome_default": false,
        "make_chrome_default_for_user": false,
        "suppress_first_run_default_browser_prompt": true,
        "system_level": true,
        "verbose_logging": true
    },
    "first_run_tabs": []
}
"@

try {
    New-Item -Path "$env:ProgramData\PackageFactory\Logs" -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null
    $Installer = Get-ChildItem -Path $PWD -Filter "googlechromestandaloneenterprise64.msi" -Recurse -ErrorAction "SilentlyContinue"
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($Installer.FullName)`" ALLUSERS=1 /quiet /log `"C:\ProgramData\PackageFactory\logs\GoogleChrome.log`""
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
    }
    $result = Start-Process @params

    # Create the initial_preferences file
    $params = @{
        FilePath    = "$Env:ProgramFiles\Google\Chrome\Application\initial_preferences"
        Encoding    = "Utf8"
        Force       = $True
        NoNewline   = $True
        ErrorAction = "SilentlyContinue"
    }
    $prefs | Out-File @params
}
catch {
    throw $_
}
finally {
    if ($result.ExitCode -eq 0) {
        $Files = @("$env:PUBLIC\Desktop\Google Chrome.lnk")
        Remove-Item -Path $Files -Force -ErrorAction "SilentlyContinue"
    }
    exit $result.ExitCode
}
