Function Confirm-Parameter {
    Param(
        [string] $ParamValue,
        [string] $ParamName
    )
    If ([String]::IsNullOrEmpty($ParamValue)) {
        Throw "$ParamName parameter is empty."
    }
}

Export-ModuleMember -Function Confirm-Parameter
