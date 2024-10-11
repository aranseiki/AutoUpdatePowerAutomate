function Save-ExecutableFile {
    param (
        [string] $URL,
        [string] $FilePath,
        [bool] $VerifyFileFirst = $true
    )

    try {
        if ($VerifyFileFirst) {
            $TestPathResult = Test-Path -Path $FilePath
            if ($TestPathResult) {
                Write-Host "File already exists at: $FilePath. Skipping download."
                return $true
            }
        }

        Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile $FilePath | Out-Null
        Write-Host "Download completed: $FilePath"
        return $true
    } catch {
        Write-Host "Error during download: $($_.Exception.Message)"
        return $false
    }
}

function Test-URLAccessibility {
    param (
        [string] $URL
    )
    
    try {
        $Response = Invoke-WebRequest -Uri $URL -Method Head -UseBasicParsing
        if ($Response.StatusCode -eq 200) {
            Write-Host "The URL is accessible."
            return $true
        } else {
            Write-Host "The URL is not accessible. Status code: $($Response.StatusCode)"
            return $false
        }
    } catch {
        Write-Host "Error trying to access URL: $($_.Exception.Message)"
        return $false
    }
}

function New-ParentDirectory {
    param (
        [string] $Path,
        [string] $ItemType
    )
    
    $ParentPath = Split-Path -Path $Path -Parent
    
    if ((Test-Path -Path $ParentPath) -eq $false) {
        New-Item -Path $ParentPath -ItemType $ItemType
    }
}

function Get-FileSizeFromUrl {
    param (
        [string] $URL
    )

    # Send a HEAD request to get the file header
    $Response = Invoke-WebRequest -Uri $URL -Method Head

    $FileSizeInBytes = 0
    # Check if the Content-Length field exists and show the file size
    if ($Response.Headers["Content-Length"]) {
        $FileSizeInBytes = [int64]$Response.Headers["Content-Length"]
    }

    return $FileSizeInBytes 
}

Export-ModuleMember -Function Get-FileSizeFromUrl, `
    New-ParentDirectory, `
    Save-ExecutableFile, `
    Test-URLAccessibility
