Function Get-PowerAutomateLocale { 
    Param(
        [Parameter(Mandatory=$true)] [string] $AppStyle,
        [Parameter(Mandatory=$false)] [string] $Arch
    )
    If ($AppStyle.ToUpper() -eq 'WIN32') {
        if ($Arch.ToUpper() -eq 'X86') {
            $ProgramFilesPath = ${env:ProgramFiles(x86)}
        } elseif ($Arch.ToUpper() -eq 'X64') {
            $ProgramFilesPath = ${env:ProgramFiles}
        } else {
            Throw "Incorrect value for architecture application parameter."
        }
                            
        $PowerAutomatePath = (
            Get-ChildItem -Path $ProgramFilesPath -Filter "*Power Automate Desktop*"
        ).FullName
    } ElseIf ($AppStyle.ToUpper() -eq 'UWP') {
        $PowerAutomatePath = (Get-AppPackage -Name "*PowerAutomateDesktop*").InstallLocation
    } Else {
        Throw "Incorrect value for style application parameter."
    }
    Return $PowerAutomatePath
}

Export-ModuleMember -Function Get-PowerAutomateLocale
