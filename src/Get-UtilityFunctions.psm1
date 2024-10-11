function Convert-Value {
    param (
        [string] $Value
    )

    switch ($Value) {
        # Verifica se o valor é um booleano
        { $_ -eq 'true' -or $_ -eq 'false' } {
            return [bool]::Parse($Value)
        }

        # Tenta converter para um inteiro
        { [int]::TryParse($_, [ref]$null) } {
            return [int]$Value
        }

        # Tenta converter para um decimal
        { [decimal]::TryParse($_, [ref]$null) } {
            return [decimal]$Value
        }

        # Tenta converter para uma data
        { 
            # Normaliza a string da data
            $normalizedValue = $_ -replace '/', '-'
            $dateValue = [datetime]::MinValue
            [datetime]::TryParse($normalizedValue, [ref]$dateValue) -and $dateValue -ne [datetime]::MinValue
        } {
            return $dateValue
        }

        # Verifica se o valor é uma URL
        { $_ -match '^(http|https|ws)://' } {
            return [uri]$Value
        }

        # Verifica se o valor é um caminho de pasta válido
        {
            [System.IO.Path]::IsPathRooted($_)
        } {
            return [System.IO.DirectoryInfo]::new($Value)
        }

        # Verifica se o valor é uma lista (delimitada por vírgulas)
        { $_ -match ';' } {
            return $Value -split ';'
        }

        # Retorna como string por padrão, removendo aspas simples se existirem
        default {
            return $Value
        }
    }
}

function Get-File {
    param (
        [string]$FilePath,
        [string]$Filter
    )

    return $(
        Get-ChildItem `
            -Path $FilePath `
            -Filter $Filter | `
        Sort-Object {
            [version]($_.Name -replace '^[^\d]*|[^\d]*$', '')
        } -Descending | `
        Select-Object `
            -First 1 `
            -ExpandProperty 'FullName'
    )
}


Export-ModuleMember -Function Convert-Value, Get-File
