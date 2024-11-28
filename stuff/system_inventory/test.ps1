# Função para coletar informações básicas do sistema
function Get-SystemInfo {
    Write-Host "`n=== Informações do Sistema ===" -ForegroundColor Cyan
    $systemInfo = @{
        "Nome do Computador" = $env:COMPUTERNAME
        "Sistema Operacional" = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        "Versão do SO" = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    }
    foreach ($key in $systemInfo.Keys) {
        Write-Host ("{0}: {1}" -f $key, $systemInfo[$key]) -ForegroundColor Yellow
    }
}

# Função para coletar informações do processador
function Get-ProcessorInfo {
    Write-Host "`n=== Informações do Processador ===" -ForegroundColor Cyan
    $cpu = Get-CimInstance -ClassName Win32_Processor
    Write-Host "Modelo: $($cpu.Name)" -ForegroundColor Yellow
    Write-Host "Núcleos: $($cpu.NumberOfCores)" -ForegroundColor Yellow
    Write-Host "Velocidade: $($cpu.MaxClockSpeed) MHz" -ForegroundColor Yellow
}

# Função para coletar informações de memória RAM
function Get-MemoryInfo {
    Write-Host "`n=== Informações de Memória RAM ===" -ForegroundColor Cyan
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host "Capacidade Total: $([math]::Round($os.TotalVisibleMemorySize / 1MB, 2)) GB" -ForegroundColor Yellow
    Write-Host "Em Uso: $([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)) GB" -ForegroundColor Yellow
    Write-Host "Disponível: $([math]::Round($os.FreePhysicalMemory / 1MB, 2)) GB" -ForegroundColor Yellow
}

# Função para listar programas instalados
function Get-InstalledPrograms {
    Write-Host "`n=== Programas Instalados ===" -ForegroundColor Cyan

    # Obter programas instalados
    $installedPrograms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, 
                                            HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                           Where-Object { $_.DisplayName } |
                           Select-Object @{Name='Nome'; Expression={$_.DisplayName}},
                                         @{Name='Versão'; Expression={$_.DisplayVersion}}
    
    # Agrupar programas que compartilham o mesmo prefixo (primeiras duas palavras do nome)
    $groupedPrograms = $installedPrograms | Group-Object {
        ($_.Nome -split '\s')[0..1] -join ' '
    }

    # Exibir os grupos com prefixo
    foreach ($group in $groupedPrograms) {
        $prefix = $group.Name
        Write-Host "`n${prefix}:" -ForegroundColor Yellow

        foreach ($program in $group.Group) {
            Write-Host ("- {0} - Versão: {1}" -f $program.Nome, $program.Versão)
        }
    }

    # Exibir programas que não têm prefixos compartilhados (os "solitários")
    $solitaryPrograms = $installedPrograms | Where-Object { 
        ($_.Nome -split '\s')[0..1] -join ' ' -notin $groupedPrograms.Name
    }

    if ($solitaryPrograms.Count -gt 0) {
        Write-Host "`nProgramas Solitários:" -ForegroundColor Yellow
        foreach ($program in $solitaryPrograms) {
            Write-Host ("- {0} - Versão: {1}" -f $program.Nome, $program.Versão)
        }
    }
}

# Função para listar serviços em execução
function Get-RunningServices {
    Write-Host "`n=== Serviços em Execução ===" -ForegroundColor Cyan
    $services = Get-CimInstance -ClassName Win32_Service | Where-Object {$_.State -eq "Running"}
    foreach ($service in $services) {
        Write-Host "$($service.DisplayName) - Status: $($service.Status)" -ForegroundColor Yellow
    }
}

# Função principal para rodar o inventário
function Run-SystemInventory {
    Get-SystemInfo
    Get-ProcessorInfo
    Get-MemoryInfo
    Get-InstalledPrograms
    Get-RunningServices
}

# Executar o inventário
Run-SystemInventory
