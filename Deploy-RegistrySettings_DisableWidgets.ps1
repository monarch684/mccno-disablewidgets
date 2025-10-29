<#
.SYNOPSIS
    Deploy Application
.DESCRIPTION
    This script deploys an application with install/uninstall/repair functionality
.NOTES
    Author: Generated Template
    Date: 2025-10-29
    Usage: Update the configuration section and deployment logic with your application-specific values
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [string]$DeploymentType = 'Install',

    [Parameter()]
    [string]$LogPath = "$env:TEMP\Application_Deployment.log"
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION - UPDATE THESE VALUES FOR YOUR APPLICATION
# ============================================================================
$applicationName = "DisableWidgets"

# Registry settings for disabling Windows taskbar widgets
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$regValueName = "AllowNewsAndInterests"
$disabledValue = 0  # 0 = Disabled, 1 = Enabled
# ============================================================================

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage
}

# ============================================================================
# DEPLOYMENT FUNCTIONS - UPDATE THESE WITH YOUR APPLICATION LOGIC
# ============================================================================

# Function to install application
function Install-Application {
    try {
        Write-Log "Installing $applicationName..."
        Write-Log "Disabling Windows taskbar widgets via registry..."

        # Create the registry path if it doesn't exist
        if (-not (Test-Path $regPath)) {
            Write-Log "Creating registry path: $regPath"
            New-Item -Path $regPath -Force | Out-Null
        }

        # Set the registry value to disable widgets
        Write-Log "Setting $regValueName to $disabledValue (Disabled)"
        New-ItemProperty -Path $regPath -Name $regValueName -Value $disabledValue -PropertyType DWord -Force | Out-Null

        Write-Log "Taskbar widgets have been disabled"
        Write-Log "$applicationName installed successfully"
        return 0
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# Function to uninstall application
function Uninstall-Application {
    try {
        Write-Log "Uninstalling $applicationName..."
        Write-Log "Re-enabling Windows taskbar widgets..."

        # Check if the registry path exists
        if (Test-Path $regPath) {
            # Check if the registry value exists
            $regValue = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue

            if ($regValue) {
                Write-Log "Removing registry value: $regValueName"
                Remove-ItemProperty -Path $regPath -Name $regValueName -Force
                Write-Log "Taskbar widgets have been re-enabled"
            }
            else {
                Write-Log "Registry value $regValueName not found, nothing to remove"
            }
        }
        else {
            Write-Log "Registry path $regPath not found, nothing to remove"
        }

        Write-Log "$applicationName uninstalled successfully"
        return 0
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# Function to repair application
function Repair-Application {
    try {
        Write-Log "Repairing $applicationName..."
        Write-Log "Re-applying registry settings to disable widgets..."

        # Create the registry path if it doesn't exist
        if (-not (Test-Path $regPath)) {
            Write-Log "Creating registry path: $regPath"
            New-Item -Path $regPath -Force | Out-Null
        }

        # Set the registry value to disable widgets
        Write-Log "Setting $regValueName to $disabledValue (Disabled)"
        New-ItemProperty -Path $regPath -Name $regValueName -Value $disabledValue -PropertyType DWord -Force | Out-Null

        Write-Log "Registry settings have been reapplied"
        Write-Log "$applicationName repaired successfully"
        return 0
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# ============================================================================
# MAIN DEPLOYMENT LOGIC
# ============================================================================

try {
    Write-Log "=========================================="
    Write-Log "$applicationName Deployment"
    Write-Log "Deployment Type: $DeploymentType"
    Write-Log "=========================================="

    $exitCode = 0

    # Process deployment
    switch ($DeploymentType) {
        'Install' {
            $exitCode = Install-Application
        }
        'Uninstall' {
            $exitCode = Uninstall-Application
        }
        'Repair' {
            $exitCode = Repair-Application
        }
    }

    # Return appropriate exit code
    if ($exitCode -eq 3010) {
        Write-Log "=========================================="
        Write-Log "Deployment completed - Reboot required"
        Write-Log "=========================================="
        exit 3010
    }
    elseif ($exitCode -ne 0) {
        Write-Log "=========================================="
        Write-Log "Deployment failed with exit code: $exitCode"
        Write-Log "=========================================="
        exit $exitCode
    }
    else {
        Write-Log "=========================================="
        Write-Log "Deployment completed successfully"
        Write-Log "=========================================="
        exit 0
    }
}
catch {
    Write-Log "=========================================="
    Write-Log "Deployment failed: $($_.Exception.Message)"
    Write-Log "=========================================="
    exit 1
}
