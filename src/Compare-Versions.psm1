Function Compare-Versions {
    Param(
        [System.Version] $CurrentVersion,
        [System.Version] $InstallFileVersion,
        [int] $Level
    )

    if ($Level -lt 1 -or $Level -gt 4) {
        Write-Error 'Level value invalid. Try a number between 1 and 4'
    }
    
    $CurrentVersionFormatted = $CurrentVersion.ToString($Level)
    $InstallFileVersionFormatted = $InstallFileVersion.ToString($Level)
    
    $ComparisonResult = ''
    If ($CurrentVersionFormatted -lt $InstallFileVersionFormatted) {
        $ComparisonResult = 'Newer version available, proceeding with update.'
    }
    ElseIf ($CurrentVersionFormatted -eq $InstallFileVersionFormatted) {
        $ComparisonResult = 'The current version is up to date. No update is needed.'
    }
    ElseIf ($CurrentVersionFormatted -gt $InstallFileVersionFormatted) {
        $ComparisonResult = 'The current version is newer than the install file version. No action taken.'
    }

    return $ComparisonResult
}

Export-ModuleMember -Function Compare-Versions
