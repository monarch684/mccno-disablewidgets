# Intune Registry Settings Deployment

This repository contains PowerShell deployment scripts for deploying registry-based configurations via Microsoft Intune Win32 application packages.

## Overview

This project uses the RegistrySettings deployment type to manage registry configurations through Intune. The deployment scripts provide a standardized framework for:
- Installing registry settings
- Detecting registry configuration status
- Removing/uninstalling registry settings
- Packaging for Intune deployment

## Project Structure

```
mccno-disablewidgets/
├── Deploy-RegistrySettings_DisableWidgets.ps1    # Main deployment script
├── Detect-RegistrySettings_DisableWidgets.ps1    # Detection script for Intune
├── Remove-RegistrySettings_DisableWidgets.ps1    # Removal script
├── Build-IntunePackage.ps1                       # Package builder
├── README.md                                     # This file
└── Output/                                       # Created by build script
    └── Deploy-RegistrySettings_DisableWidgets.intunewin
```

## Files Description

| File | Description |
|------|-------------|
| **Deploy-RegistrySettings_DisableWidgets.ps1** | Main deployment script with Install/Uninstall/Repair functionality |
| **Detect-RegistrySettings_DisableWidgets.ps1** | Detection script for Intune to verify registry settings |
| **Remove-RegistrySettings_DisableWidgets.ps1** | Removal script that calls the deployment script with Uninstall parameter |
| **Build-IntunePackage.ps1** | Script to package files into `.intunewin` format for Intune deployment |

## Quick Start

### 1. Configure Settings

Edit the scripts to add your specific registry settings (detailed configuration instructions coming after initial setup).

### 2. Test Locally

Test the deployment script before packaging:

```powershell
# Test installation
.\Deploy-RegistrySettings_DisableWidgets.ps1 -DeploymentType Install

# Test detection
.\Detect-RegistrySettings_DisableWidgets.ps1
echo $LASTEXITCODE  # Should return 0 if installed

# Test uninstallation
.\Deploy-RegistrySettings_DisableWidgets.ps1 -DeploymentType Uninstall
```

### 3. Build Intune Package

Run the build script to create the `.intunewin` package:

```powershell
.\Build-IntunePackage.ps1
```

**Prerequisites:**
- Download IntuneWinAppUtil.exe from [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)
- Place it at `C:\Intune\IntuneWinAppUtil.exe`

### 4. Deploy via Intune

Upload the generated `.intunewin` package to Microsoft Intune and deploy to your target devices.

## Configuration

### Deployment Script ([Deploy-RegistrySettings_DisableWidgets.ps1](Deploy-RegistrySettings_DisableWidgets.ps1))

Update the following sections:

1. **Application Name** (line 28):
   ```powershell
   $applicationName = "ApplicationName"  # Update with your application name
   ```

2. **Install Function** (starting at line 46):
   Add your registry creation logic

3. **Uninstall Function** (starting at line 67):
   Add your registry removal logic

### Detection Script ([Detect-RegistrySettings_DisableWidgets.ps1](Detect-RegistrySettings_DisableWidgets.ps1))

Choose your detection method and configure:

- **File/Folder Detection** (line 35)
- **Registry Detection** (line 46) - Most common for RegistrySettings
- **Product Code Detection** (line 64)

### Build Script ([Build-IntunePackage.ps1](Build-IntunePackage.ps1))

Update the required files list if you add additional files to the deployment.

## Deployment Features

### Logging
- Logs written to `%TEMP%\Application_Deployment.log` by default
- Custom log path can be specified via `-LogPath` parameter
- Timestamps included in all log entries

### Exit Codes
- `0` - Success
- `3010` - Success with reboot required
- `1` - Failure

### Deployment Types
The main deployment script supports three modes:
- `Install` - Apply registry settings
- `Uninstall` - Remove registry settings
- `Repair` - Reapply/fix registry settings

## Example: Registry Settings Deployment

```powershell
function Install-Application {
    try {
        Write-Log "Installing $applicationName..."

        # Create registry key
        $regPath = "HKLM:\SOFTWARE\YourCompany\YourApp"
        New-Item -Path $regPath -Force | Out-Null

        # Set registry values
        New-ItemProperty -Path $regPath -Name "Setting1" -Value "Value1" -PropertyType String -Force
        New-ItemProperty -Path $regPath -Name "Setting2" -Value 1 -PropertyType DWord -Force

        Write-Log "$applicationName installed successfully"
        return 0
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}
```

## Configuration Status

Settings configuration is pending. Update the deployment scripts with your specific registry settings before use.

## Requirements

- PowerShell 5.1 or later
- Microsoft Intune subscription
- IntuneWinAppUtil.exe for package creation
- Appropriate permissions in Intune admin center

## Git Configuration

The repository includes a `.gitignore` file that excludes:
- `.claude` directory (Claude Code configuration)
- `Output/` directory and `.intunewin` files
- Log files
- Windows system files

## Next Steps

1. Update the `$applicationName` variable in the deployment script
2. Implement the registry settings logic in the Install/Uninstall functions
3. Configure the detection method in the detection script
4. Test the scripts locally
5. Build the Intune package
6. Deploy via Intune

---

**Created:** 2025-10-29
**Deployment Type:** RegistrySettings
