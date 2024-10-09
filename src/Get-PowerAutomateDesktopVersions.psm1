function Get-PowerAutomateDesktopVersions {
    param (
        # URL of the site to query for Power Automate Desktop versions
        [string]$Url = 'https://learn.microsoft.com/en-us/power-platform/released-versions/power-automate-desktop',

        # Identifier of the table to find on the page
        [string]$TableIdentifier = 'INSTALLER VERSION',

        # Minimum version to filter on
        [System.Version]$MinVersion,

        # Maximum version to filter on
        [System.Version]$MaxVersion,

        # Indicator for sorting in descending order
        [switch]$Descending
    )

    # Make the HTTP request to the website
    $response = Invoke-WebRequest -UseBasicParsing -Uri $Url

    # Access the HTML content returned by the request
    $htmlContent = $response.Content

    # Create an object HTML for content manipulation
    $parsedHtml = New-Object -ComObject "HTMLfile"
    $parsedHtml.IHTMLDocument2_write($htmlContent)

    # Get all tables from the HTML document
    $tables = $parsedHtml.getElementsByTagName("table")

    # Initialize a list to store the table data
    $contentTableData = @()

    # Iterate over each table found to locate the desired table
    foreach ($table in $tables) {
        # Check if the table text contains the desired table identifier
        if (($table.textContent.ToUpper().Contains($TableIdentifier.ToUpper())) -eq $false) {
            # If not, continue to the next table
            Continue
        }

        # Get the rows of the current table
        $rows = $table.getElementsByTagName("tr")

        # Iterate over each row in the table
        foreach ($row in $rows) {
            # Get the cells in the current row
            $cells = $row.getElementsByTagName("td")

            # Initialize a list to store the row data
            $rowData = @()

            # Iterate over each cell and store the text in the row data list
            foreach ($cell in $cells) {
                $rowData += $cell.innerText
            }

            # Add the row data to the table data list
            $contentTableData += [PSCustomObject]@{
                Data = $rowData
            }
        }
    }

    # Extract the versions from the second column (index 2) of the collected data
    $versions = $contentTableData | ForEach-Object {
        $_.Data | Select-Object -Index 2
    }

    if ($versions) {
        # Filter and convert the extracted versions to the [System.Version] type
        $versions = $versions.Trim() | Where-Object {
            try {
                # Attempt to convert the string to a version
                [void][System.Version]$_

                # If the conversion succeeds, returns true
                $true
            }
            catch {
                # If it fails, returns false
                $false
            }
        }

        # Convert valid versions to the [System.Version] type
        $versions = $versions | ForEach-Object { [System.Version]$_ }
    }

    # Apply filters for MinVersion if provided
    if ($MinVersion) {
        # Filter versions greater than or equal to MinVersion
        $versions = $versions | Where-Object { $_ -ge $MinVersion }
    }

    # Apply filters to MaxVersion if provided
    if ($MaxVersion) {
        # Filter versions less than or equal to MaxVersion
        $versions = $versions | Where-Object { $_ -le $MaxVersion }
    }

    # Sort versions according to Descending parameter
    if ($Descending) {
        # Sort in descending order
        $OrderedVersionList = $versions | Sort-Object -Descending
    }
    else {
        # Sort in ascending order
        $OrderedVersionList = $versions | Sort-Object
    }

    # Return the ordered list of versions
    return $OrderedVersionList
}

# Example function call
Get-PowerAutomateDesktopVersions -MinVersion 2.47 -MaxVersion 2.48.152 -Descending
