$URLList = @(
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.47.119.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.46.181.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.45.404.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.44.55.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.43.249.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.43.217.24141.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.42.331.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.42.323.24143.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.41.178.24249.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.41.175.24145.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.40.173.24144.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.39.320.24144.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.38.212.24149.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.37.133.24071.exe",
    "https://download.microsoft.com/download/3/4/8/34844e6f-7bdd-4734-8b60-6b4d0e92f051/Setup.Microsoft.PowerAutomate_2.36.148.24073.exe"
)

$DownloadPath = "$($PSScriptRoot)\download"
if ((Test-Path -Path $DownloadPath) -eq $false) {
    New-Item -Path $DownloadPath -ItemType 'Directory'
}

$FileNumber = 1
$URLListNumber = $URLList.Count
foreach ($URL in $URLList) {
    try {
        Write-Host `n

        Write-Host "Executing file $FileNumber from $URLListNumber."
        $FileNumber = $FileNumber + 1

        Write-Host $URL
        $Response = Invoke-WebRequest -Uri $URL -Method Head -UseBasicParsing
        if ($Response.StatusCode -eq 200) {
            Write-Host "The URL is accessible."

            $FileName = $($url -Split '/')[-1]
            $FilePath = "$DownloadPath\$FileName"

            $Response = Invoke-WebRequest -Uri $URL -UseBasicParsing -OutFile $FilePath
            Write-Host "Download completed."
        } else {
            Write-Host "The URL is not accessible. Status code: $($Response.StatusCode)"
        }
    } catch {
        Write-Host "Error trying to access URL: $($_.Exception.Message)"
    }
}
