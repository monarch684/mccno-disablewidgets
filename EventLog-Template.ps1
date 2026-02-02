<#
.SYNOPSIS
    Event Logging Template - Intune Edition

.DESCRIPTION
    Self-contained event logging template designed for Intune Win32 packages.
    Copy the TEMPLATE REGION into the top of any Intune deployment or detection script.

    USAGE:
    1. Set $Script:EventLogName to your desired log name (e.g., 'MCCNO', 'MyCompany')
    2. Copy everything between "BEGIN TEMPLATE" and "END TEMPLATE"
    3. Paste at the top of your Intune script (after #Requires and param blocks)
    4. Call Initialize-EventLog -SourceName "YourScriptName" at the start of your script logic
    5. Use Write-AppEventLog throughout your script

    CRITICAL: Always use -SourceName parameter!
    Intune copies scripts to temp locations with GUID filenames (e.g., "41c5-86da-c0cb46f71e3f_4").
    Auto-detection will NOT work correctly. Always explicitly specify the source name.

.NOTES
    Version: 1.0.0 (Intune Edition)

    EVENT ID RANGES:
    - 1000-1099: Information
    - 2000-2099: Warning
    - 3000-3099: Error
    - 9000-9999: Custom (script-specific)

    PREDEFINED EVENT IDS:
    | ID   | EventType          | Level       | Use Case                    |
    |------|--------------------|-------------|-----------------------------|
    | 1000 | ScriptStarted      | Information | Script execution began      |
    | 1001 | ScriptCompleted    | Information | Script completed OK         |
    | 3000 | ScriptFailed       | Error       | Script failed               |
    | 1010 | ActionStarted      | Information | Action/task began           |
    | 1011 | ActionCompleted    | Information | Action/task completed       |
    | 1012 | ActionSkipped      | Information | Action/task skipped         |
    | 1020 | ValidationPassed   | Information | Validation check passed     |
    | 2020 | ValidationWarning  | Warning     | Validation passed w/warning |
    | 3020 | ValidationFailed   | Error       | Validation check failed     |
    | 1030 | InstallStarted     | Information | Installation began          |
    | 1031 | InstallCompleted   | Information | Installation succeeded      |
    | 3031 | InstallFailed      | Error       | Installation failed         |
    | 1040 | UninstallStarted   | Information | Uninstallation began        |
    | 1041 | UninstallCompleted | Information | Uninstallation succeeded    |
    | 3041 | UninstallFailed    | Error       | Uninstallation failed       |
    | 1050 | Information        | Information | General info message        |
    | 2050 | Warning            | Warning     | General warning message     |
    | 3050 | Error              | Error       | General error message       |
    DETECTION EVENTS (1060-1079):
    | ID   | EventType              | Level       | Use Case                    |
    |------|------------------------|-------------|-----------------------------|
    | 1060 | DetectionFound         | Information | Generic: item found         |
    | 1061 | DetectionNotFound      | Information | Generic: item not found     |
    | 3060 | DetectionError         | Error       | Detection script error      |
    | 1062 | DetectionFileFound     | Information | File detected               |
    | 1063 | DetectionFileNotFound  | Information | File not found              |
    | 1064 | DetectionFolderFound   | Information | Folder detected             |
    | 1065 | DetectionFolderNotFound| Information | Folder not found            |
    | 1066 | DetectionRegFound      | Information | Registry key/value found    |
    | 1067 | DetectionRegNotFound   | Information | Registry key/value not found|
    | 1068 | DetectionExeFound      | Information | Executable detected         |
    | 1069 | DetectionExeNotFound   | Information | Executable not found        |
    | 1070 | DetectionVersionMatch  | Information | Version matches requirement |
    | 1071 | DetectionVersionMismatch| Information| Version doesn't match       |
#>

#region ========== BEGIN TEMPLATE (Copy from here) ==========

# CONFIGURATION - Set your log name here
$Script:EventLogName = 'MCCNO'

$Script:EventLogSource = $null
$Script:EventLogInitialized = $false

# Predefined Event IDs
$Script:EventId = @{
    # Script Lifecycle
    ScriptStarted      = 1000
    ScriptCompleted    = 1001
    ScriptFailed       = 3000
    # Operations
    ActionStarted      = 1010
    ActionCompleted    = 1011
    ActionSkipped      = 1012
    # Validation
    ValidationPassed   = 1020
    ValidationWarning  = 2020
    ValidationFailed   = 3020
    # Install
    InstallStarted     = 1030
    InstallCompleted   = 1031
    InstallFailed      = 3031
    # Uninstall
    UninstallStarted   = 1040
    UninstallCompleted = 1041
    UninstallFailed    = 3041
    # General
    Information        = 1050
    Warning            = 2050
    Error              = 3050
    # Detection - Generic
    DetectionFound            = 1060
    DetectionNotFound         = 1061
    DetectionError            = 3060
    # Detection - Specific Types
    DetectionFileFound        = 1062
    DetectionFileNotFound     = 1063
    DetectionFolderFound      = 1064
    DetectionFolderNotFound   = 1065
    DetectionRegFound         = 1066
    DetectionRegNotFound      = 1067
    DetectionExeFound         = 1068
    DetectionExeNotFound      = 1069
    DetectionVersionMatch     = 1070
    DetectionVersionMismatch  = 1071
}

# Event ID to Level mapping
$Script:EventLevelMap = @{
    1000='Information';1001='Information';3000='Error'
    1010='Information';1011='Information';1012='Information'
    1020='Information';2020='Warning';3020='Error'
    1030='Information';1031='Information';3031='Error'
    1040='Information';1041='Information';3041='Error'
    1050='Information';2050='Warning';3050='Error'
    1060='Information';1061='Information';3060='Error'
    1062='Information';1063='Information';1064='Information';1065='Information'
    1066='Information';1067='Information';1068='Information';1069='Information'
    1070='Information';1071='Information'
}

function Initialize-EventLog {
    <#
    .SYNOPSIS
        Initializes event logging. Call once at script start.
    .PARAMETER SourceName
        Optional. Override auto-detected source name.
    #>
    param([string]$SourceName)

    # Determine source name
    if ([string]::IsNullOrWhiteSpace($SourceName)) {
        # Auto-detect from script name
        if ($PSCommandPath) {
            $Script:EventLogSource = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        } else {
            $callStack = Get-PSCallStack
            foreach ($frame in $callStack) {
                if ($frame.ScriptName) {
                    $Script:EventLogSource = [System.IO.Path]::GetFileNameWithoutExtension($frame.ScriptName)
                    break
                }
            }
        }
        if (-not $Script:EventLogSource) { $Script:EventLogSource = "$($Script:EventLogName)-Script" }
    } else {
        $Script:EventLogSource = $SourceName
    }

    try {
        # Check if source exists and is registered to our log
        if ([System.Diagnostics.EventLog]::SourceExists($Script:EventLogSource)) {
            $registeredLog = [System.Diagnostics.EventLog]::LogNameFromSourceName($Script:EventLogSource, '.')
            if ($registeredLog -eq $Script:EventLogName) {
                $Script:EventLogInitialized = $true
                return $true
            }
        }

        # Need to create - Intune runs as SYSTEM so we have admin rights
        $sourceData = New-Object System.Diagnostics.EventSourceCreationData($Script:EventLogSource, $Script:EventLogName)
        [System.Diagnostics.EventLog]::CreateEventSource($sourceData)
        $Script:EventLogInitialized = $true
        return $true
    }
    catch {
        Write-Warning "EventLog: Failed to initialize - $_"
        return $false
    }
}

function Write-AppEventLog {
    <#
    .SYNOPSIS
        Writes an event to the application event log.
    .PARAMETER EventType
        Predefined event type (ScriptStarted, InstallCompleted, etc.)
    .PARAMETER EventId
        Custom event ID (use 9000-9999 range). Requires -Level.
    .PARAMETER Level
        Event level: Information, Warning, or Error. Required with -EventId.
    .PARAMETER Message
        The event message.
    .PARAMETER Data
        Optional hashtable of additional data to include.
    #>
    [CmdletBinding(DefaultParameterSetName='ByType')]
    param(
        [Parameter(Mandatory,ParameterSetName='ByType')]
        [ValidateSet('ScriptStarted','ScriptCompleted','ScriptFailed',
                     'ActionStarted','ActionCompleted','ActionSkipped',
                     'ValidationPassed','ValidationWarning','ValidationFailed',
                     'InstallStarted','InstallCompleted','InstallFailed',
                     'UninstallStarted','UninstallCompleted','UninstallFailed',
                     'Information','Warning','Error',
                     'DetectionFound','DetectionNotFound','DetectionError',
                     'DetectionFileFound','DetectionFileNotFound',
                     'DetectionFolderFound','DetectionFolderNotFound',
                     'DetectionRegFound','DetectionRegNotFound',
                     'DetectionExeFound','DetectionExeNotFound',
                     'DetectionVersionMatch','DetectionVersionMismatch')]
        [string]$EventType,

        [Parameter(Mandatory,ParameterSetName='ByCustomId')]
        [ValidateRange(1,65535)]
        [int]$EventId,

        [Parameter(Mandatory,ParameterSetName='ByCustomId')]
        [ValidateSet('Information','Warning','Error')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [hashtable]$Data
    )

    # Auto-initialize if needed
    if (-not $Script:EventLogInitialized) {
        if (-not (Initialize-EventLog)) { return }
    }

    # Resolve Event ID and Level
    if ($PSCmdlet.ParameterSetName -eq 'ByType') {
        $resolvedEventId = $Script:EventId[$EventType]
        $resolvedLevel = $Script:EventLevelMap[$resolvedEventId]
    } else {
        $resolvedEventId = $EventId
        $resolvedLevel = $Level
    }

    # Map to EntryType
    $entryType = switch ($resolvedLevel) {
        'Information' { [System.Diagnostics.EventLogEntryType]::Information }
        'Warning'     { [System.Diagnostics.EventLogEntryType]::Warning }
        'Error'       { [System.Diagnostics.EventLogEntryType]::Error }
    }

    # Build message with optional data
    $fullMessage = $Message
    if ($Data -and $Data.Count -gt 0) {
        $fullMessage += "`n`n--- Details ---"
        foreach ($key in $Data.Keys) { $fullMessage += "`n$($key): $($Data[$key])" }
    }

    # Write event
    try {
        Write-EventLog -LogName $Script:EventLogName -Source $Script:EventLogSource `
                       -EventId $resolvedEventId -EntryType $entryType -Message $fullMessage
    }
    catch {
        Write-Warning "EventLog: Failed to write event - $_"
    }
}

#endregion ========== END TEMPLATE (Copy to here) ==========


# ============================================================================
# EXAMPLE INTUNE SCRIPT BELOW - Replace with your actual deployment logic
# ============================================================================

# Initialize logging - ALWAYS specify SourceName explicitly!
# Intune copies scripts to temp locations with GUID filenames, so auto-detection won't work.
Initialize-EventLog -SourceName "Deploy-Script_MyApplication"

# Script start
Write-AppEventLog -EventType ScriptStarted -Message "Intune package deployment started" -Data @{
    Computer = $env:COMPUTERNAME
    User     = $env:USERNAME
}

try {
    # Your deployment logic here
    Write-AppEventLog -EventType InstallStarted -Message "Installing application"

    # Example: Install an MSI
    # $msiPath = "$PSScriptRoot\MyApp.msi"
    # Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow

    Write-AppEventLog -EventType InstallCompleted -Message "Installation successful"
    Write-AppEventLog -EventType ScriptCompleted -Message "Deployment finished successfully"
    exit 0
}
catch {
    Write-AppEventLog -EventType ScriptFailed -Message "Deployment failed: $($_.Exception.Message)" -Data @{
        Error      = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
    }
    exit 1
}
