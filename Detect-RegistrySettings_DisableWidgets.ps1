<#
.SYNOPSIS
    Detect application installation status
.DESCRIPTION
    This script detects whether an application is installed
    Returns exit code 0 if installed, 1 if not installed
.NOTES
    Author: Generated Template
    Date: 2025-10-29
    Usage: Update the detection method section with your application-specific detection logic
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION - UPDATE THESE VALUES FOR YOUR APPLICATION
# ============================================================================
# Registry settings for detecting disabled widgets
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$regValueName = "AllowNewsAndInterests"
$expectedValue = 0  # 0 = Disabled (installed), 1 = Enabled (not installed)
# ============================================================================

try {
    Write-Host "Detecting DisableWidgets configuration..."
    Write-Host "Checking registry: $regPath"

    # Check if the registry path exists
    if (Test-Path $regPath) {
        Write-Host "Registry path found: $regPath"

        # Check if the registry value exists and has the expected value
        $regProperty = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue

        if ($regProperty) {
            $actualValue = $regProperty.$regValueName
            Write-Host "Registry value found: $regValueName = $actualValue"

            if ($actualValue -eq $expectedValue) {
                Write-Host "Widgets are disabled (value = $actualValue)"
                Write-Host "DisableWidgets is installed (exit code 0)"
                exit 0
            }
            else {
                Write-Host "Widgets are not disabled (value = $actualValue, expected = $expectedValue)"
                Write-Host "DisableWidgets is not installed (exit code 1)"
                exit 1
            }
        }
        else {
            Write-Host "Registry value $regValueName not found"
            Write-Host "DisableWidgets is not installed (exit code 1)"
            exit 1
        }
    }
    else {
        Write-Host "Registry path not found: $regPath"
        Write-Host "DisableWidgets is not installed (exit code 1)"
        exit 1
    }
}
catch {
    Write-Host "Error during detection: $($_.Exception.Message)"
    exit 1
}
