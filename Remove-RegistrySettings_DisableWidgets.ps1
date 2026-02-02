<#
.SYNOPSIS
    Remove DisableWidgets Registry Settings
.DESCRIPTION
    This script removes/reverses the DisableWidgets registry settings
.NOTES
    Author: IT Department
    Date: 2025-10-29
    Application: DisableWidgets
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Dot-source event logging template
. "$PSScriptRoot\EventLog-Template.ps1"
Initialize-EventLog -SourceName "Remove-RegistrySettings_DisableWidgets"

# ============================================================================
# CONFIGURATION
# ============================================================================
$applicationName = "DisableWidgets"
# Uninstall timeout in seconds (15 minutes)
$uninstallTimeout = 900

# Registry settings
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$regValueName = "AllowNewsAndInterests"
# ============================================================================

try {
    Write-AppEventLog -EventType ScriptStarted -Message "$applicationName Removal" -Data @{
        Computer = $env:COMPUTERNAME
    }

    Write-AppEventLog -EventType UninstallStarted -Message "Removing $applicationName - Re-enabling Windows taskbar widgets"

    # Check if the registry path exists
    if (Test-Path $regPath) {
        # Check if the registry value exists
        $regValue = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue

        if ($regValue) {
            Write-AppEventLog -EventType Information -Message "Removing registry value: $regValueName"
            Remove-ItemProperty -Path $regPath -Name $regValueName -Force
            Write-AppEventLog -EventType UninstallCompleted -Message "Taskbar widgets have been re-enabled"
        }
        else {
            Write-AppEventLog -EventType Information -Message "Registry value $regValueName not found, nothing to remove"
        }
    }
    else {
        Write-AppEventLog -EventType Information -Message "Registry path $regPath not found, nothing to remove"
    }

    Write-AppEventLog -EventType ScriptCompleted -Message "Removal completed successfully"
    exit 0
}
catch {
    Write-AppEventLog -EventType ScriptFailed -Message "Removal failed: $($_.Exception.Message)" -Data @{
        Error = $_.Exception.Message
    }
    exit 1
}
