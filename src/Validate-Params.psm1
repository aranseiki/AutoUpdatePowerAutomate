Function Validate-Params {
    Param(
        [string] $ParamValue,
        [string] $ParamName
    )
    If ([String]::IsNullOrEmpty($ParamValue)) {
        Throw "$ParamName parameter is empty."
    }
}
