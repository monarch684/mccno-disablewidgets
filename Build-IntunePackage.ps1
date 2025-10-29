<#
.SYNOPSIS
    Builds Intune package for application deployment
.DESCRIPTION
    This script packages the deployment scripts into an .intunewin file for Intune deployment
.NOTES
    Author: Generated Template
    Date: 2025-10-29
    Requires: IntuneWinAppUtil.exe (located at C:\Intune\IntuneWinAppUtil.exe)
    Usage: Update the variables section with your application-specific values
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION - UPDATE THESE VALUES FOR YOUR APPLICATION
# ============================================================================
$setupFile = "Deploy-RegistrySettings_DisableWidgets.ps1"
$intuneToolPath = "C:\Intune\IntuneWinAppUtil.exe"

# TODO: Update this list with your required files
$requiredFiles = @(
    "Deploy-RegistrySettings_DisableWidgets.ps1",
    "Detect-RegistrySettings_DisableWidgets.ps1",
    "Remove-RegistrySettings_DisableWidgets.ps1"
    # Add your installation files here
    # "YourApplication.exe"
    # "config.json"
)
# ============================================================================

try {
    Write-Host "=========================================="
    Write-Host "Building Intune Package"
    Write-Host "=========================================="

    # Define paths
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourceFolder = $scriptPath
    $outputFolder = Join-Path -Path $scriptPath -ChildPath "Output"

    # Validate IntuneWinAppUtil.exe exists
    if (-not (Test-Path $intuneToolPath)) {
        throw "IntuneWinAppUtil.exe not found at: $intuneToolPath`nPlease download from: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
    }

    # Validate source files exist
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $sourceFolder -ChildPath $file
        if (-not (Test-Path $filePath)) {
            Write-Host "WARNING: Required file not found: $file"
        }
    }

    # Create output folder if it doesn't exist
    if (-not (Test-Path $outputFolder)) {
        Write-Host "Creating output folder: $outputFolder"
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Build the .intunewin package
    Write-Host "`nPackaging files..."
    Write-Host "Source folder: $sourceFolder"
    Write-Host "Setup file: $setupFile"
    Write-Host "Output folder: $outputFolder"

    $arguments = @(
        "-c", "`"$sourceFolder`""
        "-s", "`"$setupFile`""
        "-o", "`"$outputFolder`""
        "-q"
    )

    Write-Host "`nRunning IntuneWinAppUtil.exe..."
    $process = Start-Process -FilePath $intuneToolPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        # The tool creates the file without .ps1 extension
        $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($setupFile)
        $intunewinFile = Join-Path -Path $outputFolder -ChildPath "$baseFileName.intunewin"

        if (Test-Path $intunewinFile) {
            Write-Host "`n=========================================="
            Write-Host "SUCCESS: Intune package created"
            Write-Host "Package location: $intunewinFile"
            Write-Host "=========================================="
            exit 0
        }
        else {
            throw "Package creation completed but .intunewin file not found at: $intunewinFile"
        }
    }
    else {
        throw "IntuneWinAppUtil.exe failed with exit code: $($process.ExitCode)"
    }
}
catch {
    Write-Host "`n=========================================="
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "=========================================="
    exit 1
}
