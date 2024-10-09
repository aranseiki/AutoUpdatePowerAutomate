Import-Module "$PSScriptRoot/src/Compare-Versions.psm1"
Import-Module "$PSScriptRoot/src/Download-PowerAutomateInstallFile.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateDesktopVersions.psm1"
Import-Module "$PSScriptRoot/src/Get-PowerAutomateLocale.psm1"
Import-Module "$PSScriptRoot/src/Confirm-Parameter.psm1"


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
$URLBase = 'https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_VERSIONNUMBER.exe'

# ----------------------------------------------------------------------------------------------------------
# -------------------------------- INSTALLED APPLICATION DETAILS VALIDATION --------------------------------
# ----------------------------------------------------------------------------------------------------------

Clear-Host

Confirm-Parameter -ParamValue $Task -ParamName 'Task'
Confirm-Parameter -ParamValue $AppStyle -ParamName 'AppStyle'
Confirm-Parameter -ParamValue $Arch -ParamName 'Arch'
Confirm-Parameter -ParamValue $UserDownloadPath -ParamName 'UserDownloadPath'

Write-Host "INSTALLED APPLICATION DETAILS VALIDATION" `n
<#
$PowerAutomateInstallFile = Download-PowerAutomateFile `
    -UserDownloadPath $UserDownloadPath `
    -PowerAutomateInstallFileName $PowerAutomateInstallFileName `
    -PowerAutomateDownloadFile $PowerAutomateDownloadFile
''
#>

$VersionList = Get-PowerAutomateDesktopVersions -Descending
$DownloadPath = "$($PSScriptRoot)/bin"

# <#
$FileNumber = 1
$VersionListNumber = $VersionList.Count
foreach ($Version in $VersionList) {
    Write-Host `n

    Write-Host "Verifying verion $FileNumber from $VersionListNumber."
    $FileNumber = $FileNumber + 1

    $CurrentVersion = $Version.ToString()
    $URL = $URLBase -Replace 'VERSIONNUMBER', $CurrentVersion
    Write-Host $URL

    $TestResult = Test-URLAccessibility -URL $URL

    if (-not $TestResult) {
        continue
    }
    
    $FileName = $($url -Split '/')[-1]
    $ExecutableFilePath = "$DownloadPath/$FileName"
    New-ParentDirectory -Path $ExecutableFilePath -ItemType 'Directory'

    $FileSizeInBytes = Get-FileSizeFromUrl $URL 
    Write-Host "File size: $FileSizeInBytes bytes"
    
    $DownloadResult = DownloadExecutableFile -URL $URL -FilePath $ExecutableFilePath
    if ($DownloadResult) {
        break
    }
}

if (-not $DownloadResult) {
    Write-Error "No executable is present for download."
}
#>

<#
If ($Task.ToUpper() -eq 'INSTALL') {
    Write-Host "ACTION: INSTALL" `n

    $PowerAutomateHostFile = (
        Get-ChildItem -Path $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
    ).FullName

    If ($PowerAutomateHostFile) {
        Throw "Power Automate already Installed under this path."
    }
} ElseIf ($Task.ToUpper() -eq 'UPDATE') {
    Write-Host "ACTION: UPDATE" `n

    $PowerAutomatePath = Get-PowerAutomateLocale `
        -AppStyle $AppStyle.ToUpper() `
        -Arch $Arch.ToUpper()
    
    Confirm-Parameter -ParamValue $PowerAutomatePath -ParamName 'PowerAutomatePath'

    $PowerAutomateHostFile = (
        Get-ChildItem -Path $PowerAutomatePath -Filter '*RPA.UpdateService.exe'
    ).FullName
    Confirm-Parameter -ParamValue $PowerAutomateHostFile -ParamName 'PowerAutomateHostFile'

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
#>