Function Download-PowerAutomateFile {
    Param(
        [string] $UserDownloadPath,
        [string] $PowerAutomateInstallFileName,
        [string] $PowerAutomateDownloadFile
    )
    $PowerAutomateInstallFile = "$UserDownloadPath\$PowerAutomateInstallFileName"
    If (-not (Test-Path -Path $PowerAutomateInstallFile)) {
        Invoke-WebRequest -UseBasicParsing $PowerAutomateDownloadFile `
            -OutFile $PowerAutomateInstallFile
    }
    return $PowerAutomateInstallFile
}
