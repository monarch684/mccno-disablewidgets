<#
.SYNOPSIS
    Detect DisableWidgets configuration status
.DESCRIPTION
    This script detects whether DisableWidgets registry settings are applied
    Returns exit code 0 if applied, 1 if not applied
.NOTES
    Author: IT Department
    Date: 2025-10-29
    Application: DisableWidgets
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

#region ========== EVENT LOGGING ==========
$Script:EventLogName = 'MCCNO'
$Script:EventLogSource = $null
$Script:EventLogInitialized = $false
$Script:EventId = @{
    DetectionFound=1060;DetectionNotFound=1061;DetectionError=3060
    DetectionFileFound=1062;DetectionFileNotFound=1063
    DetectionFolderFound=1064;DetectionFolderNotFound=1065
    DetectionRegFound=1066;DetectionRegNotFound=1067
    DetectionExeFound=1068;DetectionExeNotFound=1069
    DetectionVersionMatch=1070;DetectionVersionMismatch=1071
}
$Script:EventLevelMap = @{
    1060='Information';1061='Information';3060='Error'
    1062='Information';1063='Information';1064='Information';1065='Information'
    1066='Information';1067='Information';1068='Information';1069='Information'
    1070='Information';1071='Information'
}
function Initialize-EventLog {
    param([string]$SourceName)
    if ([string]::IsNullOrWhiteSpace($SourceName)) {
        if ($PSCommandPath) { $Script:EventLogSource = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) }
        else { $Script:EventLogSource = "$($Script:EventLogName)-Detect" }
    } else { $Script:EventLogSource = $SourceName }
    try {
        if ([System.Diagnostics.EventLog]::SourceExists($Script:EventLogSource)) {
            if ([System.Diagnostics.EventLog]::LogNameFromSourceName($Script:EventLogSource, '.') -eq $Script:EventLogName) {
                $Script:EventLogInitialized = $true; return $true
            }
        }
        $sourceData = New-Object System.Diagnostics.EventSourceCreationData($Script:EventLogSource, $Script:EventLogName)
        [System.Diagnostics.EventLog]::CreateEventSource($sourceData)
        $Script:EventLogInitialized = $true; return $true
    } catch { return $false }
}
function Write-AppEventLog {
    [CmdletBinding(DefaultParameterSetName='ByType')]
    param(
        [Parameter(Mandatory,ParameterSetName='ByType')]
        [ValidateSet('DetectionFound','DetectionNotFound','DetectionError',
                     'DetectionFileFound','DetectionFileNotFound',
                     'DetectionFolderFound','DetectionFolderNotFound',
                     'DetectionRegFound','DetectionRegNotFound',
                     'DetectionExeFound','DetectionExeNotFound',
                     'DetectionVersionMatch','DetectionVersionMismatch')]
        [string]$EventType,
        [Parameter(Mandatory,ParameterSetName='ByCustomId')][ValidateRange(1,65535)][int]$EventId,
        [Parameter(Mandatory,ParameterSetName='ByCustomId')][ValidateSet('Information','Warning','Error')][string]$Level,
        [Parameter(Mandatory)][string]$Message,
        [hashtable]$Data
    )
    if (-not $Script:EventLogInitialized) { if (-not (Initialize-EventLog)) { return } }
    if ($PSCmdlet.ParameterSetName -eq 'ByType') {
        $resolvedEventId = $Script:EventId[$EventType]; $resolvedLevel = $Script:EventLevelMap[$resolvedEventId]
    } else { $resolvedEventId = $EventId; $resolvedLevel = $Level }
    $entryType = switch ($resolvedLevel) { 'Information'{[System.Diagnostics.EventLogEntryType]::Information}'Warning'{[System.Diagnostics.EventLogEntryType]::Warning}'Error'{[System.Diagnostics.EventLogEntryType]::Error} }
    $fullMessage = $Message
    if ($Data -and $Data.Count -gt 0) { $fullMessage += "`n`n--- Details ---"; foreach ($key in $Data.Keys) { $fullMessage += "`n$($key): $($Data[$key])" } }
    try { Write-EventLog -LogName $Script:EventLogName -Source $Script:EventLogSource -EventId $resolvedEventId -EntryType $entryType -Message $fullMessage } catch { }
}
#endregion ========== EVENT LOGGING ==========

Initialize-EventLog -SourceName "Detect-RegistrySettings_DisableWidgets"

# ============================================================================
# CONFIGURATION
# ============================================================================
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$regValueName = "AllowNewsAndInterests"
$expectedValue = 0  # 0 = Disabled (installed), 1 = Enabled (not installed)
# ============================================================================

try {
    # Check if the registry path exists
    if (Test-Path $regPath) {
        # Check if the registry value exists and has the expected value
        $regProperty = Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue

        if ($regProperty) {
            $actualValue = $regProperty.$regValueName

            if ($actualValue -eq $expectedValue) {
                Write-AppEventLog -EventType DetectionRegFound -Message "DisableWidgets detected - Widgets are disabled" -Data @{
                    RegistryPath = $regPath
                    ValueName = $regValueName
                    Value = $actualValue
                }
                Write-Output "DisableWidgets is installed"
                exit 0
            }
            else {
                Write-AppEventLog -EventType DetectionRegNotFound -Message "DisableWidgets not configured correctly" -Data @{
                    RegistryPath = $regPath
                    ValueName = $regValueName
                    ActualValue = $actualValue
                    ExpectedValue = $expectedValue
                }
                exit 1
            }
        }
        else {
            Write-AppEventLog -EventType DetectionRegNotFound -Message "DisableWidgets registry value not found" -Data @{
                RegistryPath = $regPath
                ValueName = $regValueName
            }
            exit 1
        }
    }
    else {
        Write-AppEventLog -EventType DetectionRegNotFound -Message "DisableWidgets registry path not found" -Data @{
            RegistryPath = $regPath
        }
        exit 1
    }
}
catch {
    Write-AppEventLog -EventType DetectionError -Message "Detection failed: $($_.Exception.Message)"
    exit 1
}
