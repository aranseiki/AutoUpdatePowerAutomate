# Importing necessary modules for the script
Import-Module "$PSScriptRoot/src/Compare-Versions.psm1"
Import-Module "$PSScriptRoot/src/Confirm-Parameter.psm1"
Import-Module "$PSScriptRoot/src/Download-PowerAutomateInstallFile.psm1"
Import-Module "$PSScriptRoot/src/Get-ConfigParameters.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateDesktopVersions.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateLocale.psm1"
Import-Module "$PSScriptRoot/src/Get-UtilityFunctions.psm1"

# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------- DEFINED BY USER CODE -------------------------------------------
# ----------------------------------------------------------------------------------------------------------

# Defines the version identifier for the Power Automate file
$VersionIdentifier = 'VERSIONNUMBER'

# Sets the base filename for the Power Automate installation file using the version identifier
$InstallFileNameBase = "Setup.Microsoft.PowerAutomate_$VersionIdentifier.exe"

# The base URL to download the Power Automate installation file from
$URLBase = "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/$InstallFileNameBase"

# Placeholder variable to store the comparison result between installed and target versions
$ComparisonResult = ''

# Variable to store the path where Power Automate is installed (initialized as null)
$PowerAutomatePath = $null

# Configuration file path and filename for storing configuration settings
$ConfigFilePath = "$PSScriptRoot/config"
$ConfigFileName = 'Config-AutoUpdatePowerAutomate.ini'

# Full path to the configuration file (joining directory path and filename)
$ConfigFile = $ConfigFilePath, $ConfigFileName -join '/'

# Retrieves parameters from the configuration file using the imported function
$ConfigData = Get-ConfigParameters -ConfigFilePath $configFile

# Set configuration variables based on the data retrieved from the config file
Set-ConfigVariables -ConfigData $ConfigData

# Convert values for several variables to ensure they are in the correct format
$AppStyle = Convert-Value -Value $AppStyle
$Arch = Convert-Value -Value $Arch
$DownloadPath = Convert-Value -Value $DownloadPath
$VerifyFileFirstAtDownload = Convert-Value -Value $VerifyFileFirstAtDownload

# Check if the $DownloadPath variable is empty or null
# If it is, set a default download path inside the "bin" folder of the script root
if ([string]::IsNullOrEmpty($DownloadPath)) {
    $DownloadPath = "$($PSScriptRoot)/bin"
}

# Define the maximum number of attempts for a retry operation, limiting to 10 attempts
$maxAttempts = 10

# Initializes the attempt counter to track the number of retry attempts made
$attempt = 0

# Sets the value for the wait time in seconds between each retry attempt, allowing for a delay of 60 seconds
$secondsValue = 60

# ----------------------------------------------------------------------------------------------------------
# -------------------------------- INSTALLED APPLICATION DETAILS VALIDATION --------------------------------
# ----------------------------------------------------------------------------------------------------------

# Clears the current console screen
Clear-Host

# Validates that the parameter $Task has been provided, throws an error if it's null or empty
Confirm-Parameter -ParamValue $Task -ParamName 'Task'

# Validates that the parameter $AppStyle has been provided
Confirm-Parameter -ParamValue $AppStyle -ParamName 'AppStyle'

# Validates that the parameter $Arch (architecture) has been provided
Confirm-Parameter -ParamValue $Arch -ParamName 'Arch'

# Validates that the parameter $DownloadPath has been provided
Confirm-Parameter -ParamValue $DownloadPath -ParamName 'DownloadPath'

# Output header for validating installed application details
Write-Host "INSTALLED APPLICATION DETAILS VALIDATION" `n

# Retrieves the Power Automate installation path based on the specified app style and architecture
$PowerAutomatePath = Get-PowerAutomateLocale `
    -AppStyle $AppStyle.ToUpper() `
    -Arch $Arch.ToUpper()

# Retrieves the full path of the Power Automate file (RPA.UpdateService.exe) if it exists
$PowerAutomateHostFile = (
    Get-File -FilePath $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
).FullName

# Initialize variables for storing the current and installation file versions
$PowerAutomateCurrentVersion = $null
$PowerAutomateInstallFileVersion = $null

# Converts the task value to uppercase for case-insensitive comparison
$UpperTask = $Task.ToUpper()

# Checks if the task is "INSTALL"
If ($UpperTask -eq 'INSTALL') {
    Write-Host "ACTION: INSTALL" `n

    # If the Power Automate file exists (indicating it is already installed), throw an error
    If ($PowerAutomateHostFile) {
        Throw "Power Automate already Installed under this path."
    }

# Checks if the task is "UPDATE"
}  ElseIf ($UpperTask -eq 'UPDATE') {
    Write-Host "ACTION: UPDATE" `n
    
    # Ensures that the Power Automate file path is provided for updating
    Confirm-Parameter -ParamValue $PowerAutomateHostFile -ParamName 'PowerAutomateHostFile'

    # Retrieves the current installed version of Power Automate from the file's version info
    $PowerAutomateCurrentVersion = [System.Version] $(
        Get-Item $PowerAutomateHostFile
    ).VersionInfo.FileVersion.ToString()

    # Removes the build number from the version (keeping only major, minor, and revision numbers)
    $CurrentVersionWithoutBuild = $([System.Version] $PowerAutomateCurrentVersion.ToString(3))

# Checks if the task is "UNINSTALL"
} ElseIf ($UpperTask -eq 'UNINSTALL') {
    Write-Host "ACTION: UNINSTALL" `n
    
    # Ensures that the Power Automate file path is provided for uninstalling
    Confirm-Parameter -ParamValue $PowerAutomateHostFile -ParamName 'PowerAutomateHostFile'

    # If the Power Automate file does not exist (indicating it's not installed), throw an error
    If (-not $PowerAutomateHostFile) {
        Throw "Power Automate is not installed at the specified path."
    }

# If the task is not "INSTALL", "UPDATE", or "UNINSTALL", throw an error for an invalid task
} Else {
    Throw "Invalid task specified. Please use 'INSTALL', 'UPDATE' or 'UNINSTALL'."
}

# ----------------------------------------------------------------------------------------------------------
# -------------------------------------------- DOWNLOAD PROCESS --------------------------------------------
# ----------------------------------------------------------------------------------------------------------

# Flag indicating whether the manual installer mode is enabled
$ManualInstaller = $false

# If manual installer mode is enabled, output a message indicating so
if ($ManualInstaller) {
    Write-Host 'MANUAL INSTALLER ENABLED.'
}

# If manual installer mode is disabled, proceed with automatic installation process
if (-not $ManualInstaller) {
    Write-Host 'MANUAL INSTALLER DISABLED.'

    # Retrieves a list of Power Automate Desktop versions, filtering by the minimum version 
    # (removes builds older than the current version) and sorting in descending order
    $VersionList = Get-PowerAutomateDesktopVersions `
        -MinVersion $CurrentVersionWithoutBuild `
        -Descending

    # Initialize the counter for version tracking and the total number of versions found
    $FileNumber = 1
    $VersionListNumber = $VersionList.Count

    # Output the total number of versions found
    Write-Host "VERSIONS FOUND: $VersionListNumber"

    # Loop through each version in the version list
    foreach ($Version in $VersionList) {
        # Output the progress of verifying the current version
        Write-Host "VERIFYING VERSION $FileNumber FROM $VersionListNumber."
        $FileNumber = $FileNumber + 1
        
        # Convert the current version to a string for use in the URL
        $CurrentVersion = $Version.ToString()

        # Replace 'VERSIONNUMBER' in the base URL with the actual version number
        $URL = $URLBase -Replace 'VERSIONNUMBER', $CurrentVersion

        # Output the constructed URL for verification
        Write-Host $URL

        # Test if the constructed URL is accessible
        $TestResult = Test-URLAccessibility -URL $URL

        # If the URL is not accessible, skip to the next version in the loop
        if (-not $TestResult) {
            # Insert a blank line in the output for readability
            Write-Host `n
            continue
        }

        # Extract the file name from the URL by splitting it at '/' and taking the last part
        $FileName = $($url -Split '/')[-1]

        # Set the path for where the executable will be saved
        $ExecutableFilePath = "$DownloadPath/$FileName"

        # Create the necessary parent directories for the file path if they don't exist
        New-ParentDirectory -Path $ExecutableFilePath -ItemType 'Directory'

        # Get the file size of the executable from the URL
        $FileSizeInBytes = Get-FileSizeFromUrl $URL 
        Write-Host "FILE SIZE: $FileSizeInBytes BYTES."

        # Download the executable file from the URL and save it to the specified file path
        $DownloadResult = Save-ExecutableFile -URL $URL `
            -FilePath $ExecutableFilePath `
            -VerifyFileFirst $VerifyFileFirstAtDownload # Option to verify the file before download

        
        # Insert a blank line for better readability in the output
        Write-Host `n

        # If the download is successful, exit the loop
        if ($DownloadResult) {
            break
        }
    }

    # If no version was successfully downloaded, throw an error
    if (-not $DownloadResult) {
        Write-Error "No executable is present for download."
    }
}

# ----------------------------------------------------------------------------------------------------------
# ------------------------------------ INSTALL FILE DETAILS VALIDATION  ------------------------------------
# ----------------------------------------------------------------------------------------------------------

# Replaces the placeholder 'VERSIONNUMBER' in the base install file name with a wildcard '*' 
# to create a filter that can be used to search for files of any version in the specified directory
$InstallFileNameFilter = $InstallFileNameBase -Replace $VersionIdentifier, '*'

# Retrieves the Power Automate installation file from the specified download path
# using the filter created above to match any version of the file
$PowerAutomateInstallFile = Get-File -FilePath $DownloadPath -Filter $InstallFileNameFilter

# Confirms that the 'PowerAutomateInstallFile' parameter is valid (i.e., not null or empty)
Confirm-Parameter -ParamValue $PowerAutomateInstallFile -ParamName 'PowerAutomateInstallFile'

# Retrieves the version information of the installation file as a string
$PowerAutomateInstallFileVersion = [System.Version] $(Get-Item $PowerAutomateInstallFile).VersionInfo.FileVersion.ToString()

# Outputs the version of the install file to the console
Write-Host "INSTALL FILE VERSION: $PowerAutomateInstallFileVersion"

# ----------------------------------------------------------------------------------------------------------
# ------------------------------------------- VERSION COMPARISON -------------------------------------------
# ----------------------------------------------------------------------------------------------------------

# If the task specified is 'UPDATE', proceed with the following actions
If ($UpperTask -eq 'UPDATE') {
    
    # Output the current installed version of Power Automate to the console
    Write-Host "PowerAutomateCurrentVersion: $PowerAutomateCurrentVersion"
    
    # Output the version of the installation file that is about to be used for the update
    Write-Host "PowerAutomateInstallFileVersion: $PowerAutomateInstallFileVersion" `n

    # Compare the current installed version of Power Automate with the version of the installation file.
    # The '-Level 3' argument specifies that the comparison should go up to the third level of versioning (e.g., major.minor.build).
    $ComparisonResult = Compare-Versions -CurrentVersion $PowerAutomateCurrentVersion `
        -InstallFileVersion $PowerAutomateInstallFileVersion `
        -Level 3

    # Output the result of the version comparison to the console
    Write-Host $ComparisonResult
}

# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------- INSTALLATION PROCESS -------------------------------------------
# ----------------------------------------------------------------------------------------------------------

# Display the beginning of the installation process
Write-Host "INSTALLATION PROCESS" `n

# Initialize the validation process variable
$ValidationProcess = $false

# Check if the task is either 'INSTALL' or 'UPDATE'
If ($UpperTask -eq 'INSTALL' -or $UpperTask -eq 'UPDATE') {

    # If the current version is up to date, throw an error and stop the process
    If ($ComparisonResult.Contains('CURRENT VERSION IS UP TO DATE')) {
        Throw "Power Automate already installed in this version."
    }

    # If the installed version is newer than the one in the installer, throw an error
    If ($ComparisonResult.Contains('CURRENT VERSION IS NEWER')) {
        Throw "Power Automate installed in a higher version."
    }

    # Execute the installer with the appropriate flags for installation
    . $PowerAutomateInstallFile `
        -Install `
        -ACCEPTEULA `
        -ADDGATEWAYSUPPORT `
        -Silent `
        -INSTALLPATH:$PowerAutomatePath

    # Set the validation process to true
    $ValidationProcess = $true

# If the task is 'UNINSTALL', execute the uninstallation process
} ElseIf ($UpperTask -eq 'UNINSTALL') {
    Write-Host "ACTION: UNINSTALL" `n

    # Execute the uninstaller silently
    . $PowerAutomateInstallFile `
        -ArgumentList `
        -Silent `
        -Uninstall `
        -INSTALLPATH:$PowerAutomatePath

    # Set the validation process to true
    $ValidationProcess = $true
}

# If the validation process has started
if ($ValidationProcess) {
    
    # Inform the user that the process is being waited upon
    Write-Host "Waiting for process to complete..."

    # If the task is 'INSTALL', verify the installation by checking for the required executable file
    if ($UpperTask -eq 'INSTALL') {
        # Retry up to 10 times or until the file is found
        while (-not $PowerAutomateHostFile -and $attempt -lt $maxAttempts) {
            $PowerAutomateHostFile = Get-File -FilePath $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
            Start-Sleep -Seconds $secondsValue
            $attempt++
        }

        # If the file is found, get the current version of Power Automate and display it
        if (-not [string]::IsNullOrWhiteSpace($PowerAutomateHostFile)) {
            $PowerAutomateCurrentVersion = [System.Version] $(
                Get-Item $PowerAutomateHostFile
            ).VersionInfo.FileVersion.ToString()
            Write-Host "PowerAutomate Version: $PowerAutomateCurrentVersion"
        } else {
            # If the file is not found after all attempts, display an error
            Write-Host "Failed to find RPA.UpdateService.exe after $attempt attempts."
        }

    # If the task is 'UPDATE', retry checking for version updates
    } elseif ($UpperTask -eq 'UPDATE') {
        # Retry up to 10 times or until the installed version matches the installation file version
        while ($PowerAutomateCurrentVersion -ne $PowerAutomateInstallFileVersion -and $attempt -lt $maxAttempts) {
            $PowerAutomateHostFile = Get-File -FilePath $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
            
            # If the file is found, get and display the current version of Power Automate
            if (-not [string]::IsNullOrWhiteSpace($PowerAutomateHostFile)) {
                $PowerAutomateCurrentVersion = [System.Version] $(
                    Get-Item $PowerAutomateHostFile
                ).VersionInfo.FileVersion.ToString()
                Write-Host "PowerAutomate Version: $PowerAutomateCurrentVersion"
            }
            Start-Sleep -Seconds $secondsValue
            $attempt++
        }

        # If the update fails after all attempts, display an error message
        if ($PowerAutomateCurrentVersion -ne $PowerAutomateInstallFileVersion) {
            Write-Host "Failed to update to version $PowerAutomateInstallFileVersion after $attempt attempts."
        }

    # If the task is 'UNINSTALL', retry checking if the uninstall process completed
    } elseif ($UpperTask -eq 'UNINSTALL') {
        # Retry up to 10 times or until the file is no longer found
        while ($PowerAutomateHostFile -and $attempt -lt $maxAttempts) {
            $PowerAutomateHostFile = Get-File -FilePath $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
            Start-Sleep -Seconds $secondsValue
            $attempt++
        }

        # If the file is no longer found, confirm the uninstallation
        if (-not [string]::IsNullOrWhiteSpace($PowerAutomateHostFile)) {
            $PowerAutomateCurrentVersion = [System.Version] $(
                Get-Item $PowerAutomateHostFile
            ).VersionInfo.FileVersion.ToString()
            Write-Host "PowerAutomate Version: $PowerAutomateCurrentVersion"
        } else {
            Write-Host "Power Automate uninstalled successfully."
        }
    }
}

# After the process is finished, output a completion message
Write-Host "Process completed."
