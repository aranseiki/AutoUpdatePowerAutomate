Function Compare-Versions {
    Param(
        [string] $CurrentVersion,
        [string] $InstallFileVersion
    )
    $CurrentVersionWithoutBuild = (
        ($CurrentVersion -isplit '\.') | Select-Object -First 3
    ) -join '.'
    $InstallFileVersionWithoutBuild = (
        ($InstallFileVersion -isplit '\.') | Select-Object -First 3
    ) -join '.'

    return ($CurrentVersionWithoutBuild, $InstallFileVersionWithoutBuild)
}

Export-ModuleMember -Function Compare-Versions
