<#
.SYNOPSIS
    Remove Application
.DESCRIPTION
    This script removes/uninstalls an application from the system
.NOTES
    Author: Generated Template
    Date: 2025-10-29
    Usage: Update the variables section with your application-specific values
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$LogPath = "$env:TEMP\Application_Removal.log"
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION - UPDATE THESE VALUES FOR YOUR APPLICATION
# ============================================================================
$deployScriptName = "Deploy-RegistrySettings_DisableWidgets.ps1"
# Alternative: Product Code for direct uninstall
# $productCode = "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}"  # TODO: Update with your application's product code
# ============================================================================

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage
}

try {
    Write-Log "=========================================="
    Write-Log "Application Removal"
    Write-Log "=========================================="

    # Method 1: Use the Deploy script with Uninstall parameter (recommended)
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $deployScript = Join-Path -Path $scriptPath -ChildPath $deployScriptName

    if (Test-Path $deployScript) {
        Write-Log "Calling deployment script with Uninstall mode..."
        & $deployScript -DeploymentType 'Uninstall' -LogPath $LogPath
        $exitCode = $LASTEXITCODE

        Write-Log "=========================================="
        Write-Log "Removal completed with exit code: $exitCode"
        Write-Log "=========================================="

        exit $exitCode
    }
    else {
        throw "Deploy script not found: $deployScript"
    }

    # Method 2: Alternative - Direct uninstall by product code (if deployment script is not available)
    # Uncomment the code below if you need to uninstall using product code:
    # Write-Log "Attempting to uninstall using product code: $productCode"
    # $arguments = @("/x", $productCode, "/qn", "/norestart", "/l*v", "`"$env:TEMP\Application_Uninstall.log`"")
    # $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    # exit $process.ExitCode
}
catch {
    Write-Log "=========================================="
    Write-Log "Removal failed: $($_.Exception.Message)"
    Write-Log "=========================================="
    exit 1
}
