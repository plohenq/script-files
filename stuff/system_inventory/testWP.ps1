# Função para obter programas instalados usando Get-CimInstance
function Get-InstalledPrograms {
    $programs = Get-CimInstance -ClassName Win32_Product
    return $programs
}

# Exibindo informações do sistema primeiro
$systemInfo = @{
    'Nome do Computador' = $env:COMPUTERNAME
    'Sistema Operacional' = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    'Versao do SO' = (Get-CimInstance -ClassName Win32_OperatingSystem).Version  # Retirando acento em 'Versão'
    'Processador' = (Get-CimInstance -ClassName Win32_Processor).Name
    'Memoria RAM' = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory  # Retirando acento em 'Memória'
}

Write-Host "`n=== Informacoes do Sistema ===" -ForegroundColor Yellow  # Retirando acento em 'Informações'
foreach ($key in $systemInfo.Keys) {
    Write-Host ("{0}: {1}" -f $key, $systemInfo[$key]) -ForegroundColor Green
}

# Coletando os programas instalados
$installedPrograms = Get-InstalledPrograms

# Verificando se a lista de programas não é nula ou vazia
if ($installedPrograms -ne $null -and $installedPrograms.Count -gt 0) {
    # Agrupar programas por prefixo, verificando se Name não é nulo
    $groupedPrograms = $installedPrograms | Where-Object { $_.Name -ne $null } | Group-Object { $_.Name.Split(' ')[0] }

    # Exibir os programas agrupados
    Write-Host "`n=== Programas Instalados ===" -ForegroundColor Yellow

    foreach ($group in $groupedPrograms) {
        $prefix = $group.Name
        Write-Host ("`n" + $prefix + ":") -ForegroundColor Yellow  # Concatenando a string

        foreach ($program in $group.Group) {
            Write-Host ("- {0} - Versao: {1}" -f $program.Name, $program.Version) -ForegroundColor Cyan  # Retirando acento em 'Versão'
        }
    }
} else {
    Write-Host "Nenhum programa instalado encontrado." -ForegroundColor Red
}
