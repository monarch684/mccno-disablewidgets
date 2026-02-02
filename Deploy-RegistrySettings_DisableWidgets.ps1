<#
.SYNOPSIS
    Deploy DisableWidgets Registry Settings
.DESCRIPTION
    This script disables Windows taskbar widgets via registry settings
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
Initialize-EventLog -SourceName "Deploy-RegistrySettings_DisableWidgets"

# ============================================================================
# CONFIGURATION
# ============================================================================
$applicationName = "DisableWidgets"
$scriptPath = $PSScriptRoot

# Registry settings for disabling Windows taskbar widgets
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$regValueName = "AllowNewsAndInterests"
$disabledValue = 0  # 0 = Disabled, 1 = Enabled

# Installation timeout in seconds (30 minutes)
$installTimeout = 1800
# ============================================================================

try {
    Write-AppEventLog -EventType ScriptStarted -Message "$applicationName Deployment" -Data @{
        ScriptPath = $scriptPath
        Computer = $env:COMPUTERNAME
    }

    Write-AppEventLog -EventType InstallStarted -Message "Installing $applicationName"
    Write-AppEventLog -EventType Information -Message "Disabling Windows taskbar widgets via registry..."

    # Create the registry path if it doesn't exist
    if (-not (Test-Path $regPath)) {
        Write-AppEventLog -EventType Information -Message "Creating registry path: $regPath"
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set the registry value to disable widgets
    Write-AppEventLog -EventType Information -Message "Setting $regValueName to $disabledValue (Disabled)"
    New-ItemProperty -Path $regPath -Name $regValueName -Value $disabledValue -PropertyType DWord -Force | Out-Null

    Write-AppEventLog -EventType InstallCompleted -Message "$applicationName installed successfully - Taskbar widgets disabled"
    Write-AppEventLog -EventType ScriptCompleted -Message "Deployment completed successfully"
    exit 0
}
catch {
    Write-AppEventLog -EventType ScriptFailed -Message "Deployment failed: $($_.Exception.Message)" -Data @{
        Error = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
    }
    exit 1
}
