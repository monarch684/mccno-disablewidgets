# Intune Deployment Guide - Disable Windows Taskbar Widgets

This guide provides step-by-step instructions for deploying the DisableWidgets configuration via Microsoft Intune as a Win32 app.

## Package Information

**Package File:** `Deploy-RegistrySettings_DisableWidgets.intunewin`
**Location:** `Output/Deploy-RegistrySettings_DisableWidgets.intunewin`
**Registry Path:** `HKLM:\SOFTWARE\Policies\Microsoft\Dsh`
**Registry Value:** `AllowNewsAndInterests = 0`

---

## Prerequisites

- Access to Microsoft Intune admin center
- Global Administrator or Intune Administrator role
- The `.intunewin` package file from the Output folder
- Target devices running Windows 10 or Windows 11

---

## Deployment Steps

### 1. Upload the Application Package

1. Sign in to the **Microsoft Intune admin center** (https://intune.microsoft.com)
2. Navigate to **Apps** > **Windows** > **Add**
3. Select **Windows app (Win32)** from the app type dropdown
4. Click **Select**

### 2. App Information

Click **Select app package file** and upload:
- **File:** `Deploy-RegistrySettings_DisableWidgets.intunewin`

Fill in the following details:

| Field | Value |
|-------|-------|
| **Name** | Disable Windows Taskbar Widgets |
| **Description** | Disables the Windows taskbar widgets feature via registry policy |
| **Publisher** | IT Department |
| **App version** | 1.0 |
| **Category** | Business |
| **Show this as a featured app in the Company Portal** | No |
| **Information URL** | (Optional) |
| **Privacy URL** | (Optional) |
| **Developer** | IT Department |
| **Owner** | IT Department |
| **Notes** | Registry-based configuration to disable Windows taskbar widgets (News and Interests) |

Click **Next**

### 3. Program Configuration

Configure the installation and uninstallation commands:

| Field | Value |
|-------|-------|
| **Install command** | `powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySettings_DisableWidgets.ps1" -DeploymentType Install` |
| **Uninstall command** | `powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySettings_DisableWidgets.ps1" -DeploymentType Uninstall` |
| **Install behavior** | System |
| **Device restart behavior** | No specific action |
| **Return codes** | Use default values (0 = Success, 3010 = Soft reboot, 1 = Hard reboot) |

Click **Next**

### 4. Requirements

Set the minimum requirements for installation:

| Field | Value |
|-------|-------|
| **Operating system architecture** | 64-bit |
| **Minimum operating system** | Windows 10 1809 |

**Additional requirement rules (Optional):**
- No additional requirements needed

Click **Next**

### 5. Detection Rules

Configure how Intune detects if the configuration is applied:

1. **Rules format:** Use a custom detection script
2. Click **Add** under Detection rules
3. Select **Use a custom detection script**
4. **Script file:** Upload `Detect-RegistrySettings_DisableWidgets.ps1`
5. **Run script as 32-bit process on 64-bit clients:** No
6. **Enforce script signature check:** No
7. Click **OK**

Click **Next**

### 6. Dependencies

No dependencies are required for this configuration.

Click **Next**

### 7. Supersedence

No supersedence needed for this configuration.

Click **Next**

### 8. Assignments

Assign the configuration to groups:

**Required Assignments:**
- Click **Add group** under Required
- Search for and select the target group(s) that should have widgets disabled
- Click **Select**

**Available for enrolled devices:**
- (Optional) Not typically needed for policy configurations

**Uninstall:**
- (Optional) Add groups that should have widgets re-enabled

**End user notifications:**
- Show all toast notifications

**Installation deadline:**
- As soon as possible (or set a custom deadline)

Click **Next**

### 9. Review + Create

1. Review all settings to ensure they are correct
2. Click **Create**

---

## Monitoring Deployment

### Check Deployment Status

1. Navigate to **Apps** > **Windows**
2. Find **Disable Windows Taskbar Widgets** in the list
3. Click on the application
4. Select **Device install status** or **User install status** to monitor deployment

### View Installation Logs on Client Devices

Logs can be found at:
- **Intune Management Extension Log:** `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- **Deployment Log:** `%TEMP%\Application_Deployment.log`

---

## Verification

After deployment, verify the configuration:

### On the Client Device:

1. **Check registry value:**
   ```powershell
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests"
   ```
   Should return: `AllowNewsAndInterests : 0`

2. **Verify widgets are hidden:**
   - Check the Windows taskbar - the widgets icon should not be visible
   - Right-click the taskbar and verify "Widgets" option is grayed out or missing

3. **Run detection script manually:**
   ```powershell
   cd "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming\*\*"
   powershell.exe -ExecutionPolicy Bypass -File "Detect-RegistrySettings_DisableWidgets.ps1"
   echo $LASTEXITCODE  # Should return 0 if configured
   ```

---

## Troubleshooting

### Common Issues

**Issue:** Configuration shows as "Not Installed" in Intune
- **Solution:** Check that the detection script is uploaded correctly and returns exit code 0 when the registry value is set
- Verify the registry path exists and the value equals 0

**Issue:** Installation fails
- **Solution:** Check the deployment log in `%TEMP%\Application_Deployment.log` for detailed error information
- Verify PowerShell execution policy allows script execution
- Ensure the device has proper permissions to modify HKLM registry

**Issue:** Widgets still appear after deployment
- **Solution:** The change may require the user to log off and log back in
- Verify the registry value was set correctly using the verification steps above
- Check if a conflicting Group Policy is overriding the setting

**Issue:** Installation succeeds but detection fails
- **Solution:** Verify the registry path and value using PowerShell
- Check if the value type is correct (should be DWORD)
- Run the detection script manually to see detailed output

### Getting Support

1. Check Intune deployment logs on the client device
2. Review deployment logs in `%TEMP%\Application_Deployment.log`
3. Verify registry changes using `regedit` or PowerShell
4. Contact IT support with log files if issues persist

---

## Rebuilding the Package

If you need to update the scripts and rebuild the package:

1. Edit the PowerShell scripts as needed
2. Run the build script:
   ```powershell
   .\Build-IntunePackage.ps1
   ```
3. Upload the new `.intunewin` file from the Output folder to Intune
4. Update the app version in Intune if applicable

---

## Uninstallation

To re-enable widgets via Intune, assign the application to a group with **Uninstall** intent. The uninstall command will remove the registry value, allowing Windows to use its default behavior.

**Manual uninstallation:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySettings_DisableWidgets.ps1" -DeploymentType Uninstall
```

**Manual registry removal:**
```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Force
```

---

## Additional Information

- **Install behavior:** System (runs as SYSTEM account)
- **Reboot required:** No
- **User experience:** Silent configuration, no user interaction required
- **Detection method:** Custom PowerShell script checking registry value
- **Impact:** Disables the taskbar widgets/News and Interests feature
- **Reversible:** Yes, uninstalling removes the registry value and restores default behavior

---

## Technical Details

### Registry Configuration

The deployment configures the following registry setting:

```
Key: HKLM:\SOFTWARE\Policies\Microsoft\Dsh
Value Name: AllowNewsAndInterests
Value Type: DWORD
Value Data: 0 (Disabled)
```

This is the same registry location used by Group Policy to control the Windows taskbar widgets feature.

### Script Functions

- **Install:** Creates the registry path (if needed) and sets `AllowNewsAndInterests` to `0`
- **Uninstall:** Removes the `AllowNewsAndInterests` registry value
- **Repair:** Re-applies the registry setting to ensure it remains disabled
- **Detect:** Checks if the registry value exists and equals `0`

---

**Created:** 2025-10-29
**Version:** 1.0
**Package Type:** Registry Settings
