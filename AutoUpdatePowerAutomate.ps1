Import-Module "$PSScriptRoot/src/Compare-Versions.psm1"
Import-Module "$PSScriptRoot/src/Download-PowerAutomateFile.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateDesktopVersions.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateLocale.psm1"
Import-Module "$PSScriptRoot/src/Validate-Params.psm1"


# --------------------------------------------------------------------------------------------------------
# ----------------------------------------- DEFINED BY USER DATA -----------------------------------------
# --------------------------------------------------------------------------------------------------------

$Task = 'update'
$AppStyle = 'win32'
$Arch = 'x86'
$UserDownloadPath = "C:\Users\$env:USERNAME\Downloads"
$PowerAutomateInstallFileName = 'Setup.Microsoft.PowerAutomate.exe'

# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------- DEFINED BY USER CODE -------------------------------------------
# ----------------------------------------------------------------------------------------------------------

$PowerAutomateDownloadFile = 'https://go.microsoft.com/fwlink/?linkid=2102613'

# ----------------------------------------------------------------------------------------------------------
# -------------------------------- INSTALLED APPLICATION DETAILS VALIDATION --------------------------------
# ----------------------------------------------------------------------------------------------------------

Clear-Host

Validate-Params -ParamValue $Task -ParamName 'Task'
Validate-Params -ParamValue $AppStyle -ParamName 'AppStyle'
Validate-Params -ParamValue $Arch -ParamName 'Arch'
Validate-Params -ParamValue $UserDownloadPath -ParamName 'UserDownloadPath'

Write-Host "INSTALLED APPLICATION DETAILS VALIDATION" `n

If ($Task.ToUpper() -eq 'INSTALL') {
    Write-Host "ACTION: INSTALL" `n

    $PowerAutomateInstallFile = Download-PowerAutomateFile `
        -UserDownloadPath $UserDownloadPath `
        -PowerAutomateInstallFileName $PowerAutomateInstallFileName `
        -PowerAutomateDownloadFile $PowerAutomateDownloadFile

    $PowerAutomateHostFile = (
        Get-ChildItem -Path $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
    ).FullName

    If ($PowerAutomateHostFile) {
        Throw "Power Automate already Installed under this path."
    }
} ElseIf ($Task.ToUpper() -eq 'UPDATE') {
    Write-Host "ACTION: UPDATE" `n

    $PowerAutomateInstallFile = Download-PowerAutomateFile `
        -UserDownloadPath $UserDownloadPath `
        -PowerAutomateInstallFileName $PowerAutomateInstallFileName `
        -PowerAutomateDownloadFile $PowerAutomateDownloadFile

    $PowerAutomatePath = Get-PowerAutomateLocale `
        -AppStyle $AppStyle.ToUpper() `
        -Arch $Arch.ToUpper()
    
    Validate-Params -ParamValue $PowerAutomatePath -ParamName 'PowerAutomatePath'

    $PowerAutomateHostFile = (
        Get-ChildItem -Path $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
    ).FullName
    Validate-Params -ParamValue $PowerAutomateHostFile -ParamName 'PowerAutomateHostFile'

    $PowerAutomateCurrentVersion = $(
        Get-Item $PowerAutomateHostFile
    ).VersionInfo.FileVersion.ToString()
    $PowerAutomateInstallFileVersion = $(
        Get-Item $PowerAutomateInstallFile
    ).VersionInfo.FileVersion.ToString()

    Write-Host "PowerAutomateCurrentVersion: $PowerAutomateCurrentVersion"
    Write-Host "PowerAutomateInstallFileVersion: $PowerAutomateInstallFileVersion" `n

    $Versions = Compare-Versions -CurrentVersion $PowerAutomateCurrentVersion `
        -InstallFileVersion $PowerAutomateInstallFileVersion
    Write-Host "PowerAutomateCurrentVersionWithoutBuild: $($Versions[0])"
    Write-Host "PowerAutomateInstallFileVersionWithoutBuild: $($Versions[1])" `n

    If ($Versions[0] -lt $Versions[1]) {
        Write-Host 'Newer version available, proceeding with update.'
    }
} ElseIf ($Task.ToUpper() -eq 'UNINSTALL') {
    Write-Host "ACTION: UNINSTALL" `n

    $PowerAutomateInstallFile = Download-PowerAutomateFile `
        -UserDownloadPath $UserDownloadPath `
        -PowerAutomateInstallFileName $PowerAutomateInstallFileName `
        -PowerAutomateDownloadFile $PowerAutomateDownloadFile
} Else {
    Throw "Task parameter value not defined."
}

# ----------------------------------------------------------------------------------------------------------
# ----------------------------------------- INSTALLATION PROCESS -------------------------------------------
# ----------------------------------------------------------------------------------------------------------

Write-Host "INSTALLATION PROCESS" `n

If ($Task.ToUpper() -eq 'INSTALL' -or $Task.ToUpper() -eq 'UPDATE') {
    If ($Versions[0] -eq $Versions[1]) {
        Throw "Power Automate already Installed in this version."
    }

    If ($Versions[0] -gt $Versions[1]) {
        Throw "Power Automate Installed in a higher version."
    }

    . $PowerAutomateInstallFile `
        -Install `
        -ACCEPTEULA `
        -ADDGATEWAYSUPPORT `
        -INSTALLPATH: $PowerAutomatePath
} ElseIf ($Task.ToUpper() -eq 'UNINSTALL') {
    Write-Host "ACTION: UNINSTALL" `n
    . $PowerAutomateInstallFile -Silent -Uninstall
}
