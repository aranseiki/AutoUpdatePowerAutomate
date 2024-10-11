function Get-ConfigParameters {
    param (
        [string] $ConfigFilePath
    )

    $ConfigFileContent = Get-Content -Path $ConfigFilePath
    $ConfigParameterList = @{}
    $CurrentSection = ""

    foreach ($Row in $ConfigFileContent) {
        $Row = $Row.Trim()
        # substitua as barras invertidas
        $Row = $Row -replace '\\', '/'

        # Ignora linhas vazias ou comentários
        if (-not $Row -or $Row.StartsWith(";")) {
            continue
        }

        # Verifica se é uma seção
        if ($Row.StartsWith("[") -and $Row.EndsWith("]")) {
            $CurrentSection = $Row.Trim('[', ']')
            $ConfigParameterList[$CurrentSection] = @{}
        }
        else {
            # Trata o formato nome=valor
            $ConvertedText = ConvertFrom-StringData -StringData $Row

            # Adiciona os parâmetros dentro da seção atual
            if ($CurrentSection) {
                $ConfigParameterList[$CurrentSection] += $ConvertedText
            }
        }
    }

    return $ConfigParameterList
}

function Set-ConfigVariables {
    param (
        [hashtable] $ConfigData, 
        [bool] $AppendSectionToVariableName = $false
    )

    # Criação dinâmica de variáveis com base nas chaves e valores
    foreach ($Section in $ConfigData.Keys) {
        foreach ($Key in $ConfigData[$Section].Keys) {
            # Nome simples da variável, apenas a chave
            $VariableName = $Key

            # Verifica se já existe uma variável com o nome simples
            if ($AppendSectionToVariableName) {
                if (Get-Variable -Name $VariableName -ErrorAction SilentlyContinue) {
                    # Se já existir, interpola o nome com a seção
                    $VariableName = $Section + $Key
                }
            }

            $ConfigDataValue = $ConfigData[$Section][$Key]
            # Definindo o valor da variável dinamicamente
            Set-Variable -Name $VariableName -Value $ConfigDataValue -Scope Global
        }
    }
}

Export-ModuleMember -Function `
    Get-ConfigParameters, `
    Set-ConfigVariables
