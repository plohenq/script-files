Write-Host "=====================`n=                   =`n=    AUTOV v0.7.    =`n=                   =`n=====================" -ForegroundColor Red
Write-Host "`n.NET Framework 4 e Edge WebView2 necessarios. Projetado para sistemas Windows 10+ recem-formatados.`n" -ForegroundColor Red
Read-Host

# CONFIGURAÇÕES INICIAIS 1
# Verifica se o script está sendo executado como administrador
if (-not ([bool](New-Object Security.Principal.WindowsPrincipal [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "Por favor, execute o script como administrador." -ForegroundColor Red
    exit
}

# INÍCIO TRANSCRIÇÃO DO LOG
Start-Transcript -Path "$env:UserProfile\Desktop\AutoV_Log.txt" -Append
Write-Host "Log de execução iniciado. Todas as ações serão registradas em $env:UserProfile\Desktop\AutoV_Log.txt" -ForegroundColor Cyan

# FUNÇÕES UTILITÁRIAS
# Função para baixar arquivos usando BITS
function Download-FileWithBits {
    param (
        [string]$Url,
        [string]$Destination
    )
    try {
        Write-Host "Iniciando download de $Url usando BITS..." -ForegroundColor Yellow
        Start-BitsTransfer -Source $Url -Destination $Destination -Priority Foreground
        Write-Host "Download concluído com sucesso!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erro durante o download: $_" -ForegroundColor Red
        return $false
    }
}

# Função para ativação do Windows/Office
function Ativar-WindowsOffice {
    param (
        [int]$Tentativas = 3
    )

    for ($i = 1; $i -le $Tentativas; $i++) {
        try {
            Write-Host "Tentativa $i de ativação..." -ForegroundColor Yellow
            Invoke-Expression -Command "irm https://get.activated.win | iex"
            Write-Host "Ativação concluída com sucesso!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Erro durante a ativação: $_" -ForegroundColor Red
        }
        Start-Sleep -Seconds 3
    }
    Write-Host "Falha na ativação após $Tentativas tentativas." -ForegroundColor Red
    return $false
}

# Função para remover o Chocolatey do PATH
function Remover-ChocolateyDoPATH {
    param (
        [string]$Path,
        [string]$ChocolateyPath
    )
    if ([string]::IsNullOrEmpty($ChocolateyPath)) {
        Write-Host "Caminho do Chocolatey não especificado. Pulando remoção do PATH." -ForegroundColor Yellow
        return $Path
    }
    $newPath = [string]::Join(';', ($Path -split ';' | Where-Object { $_ -and $_ -ne "$ChocolateyPath\bin" }))
    Write-Verbose "PATH atualizado: $newPath"
    return $newPath
}

# Função para desinstalar o Chocolatey
function Desinstalar-Chocolatey {
    if (Test-Path "$env:ProgramData\Chocolatey\choco.exe") {
        Write-Host "Desinstalando Chocolatey..." -ForegroundColor Yellow
        choco uninstall -y chocolatey
        Start-Sleep -Seconds 5
    }
}

# Função para limpar variáveis de ambiente relacionadas ao Chocolatey
function Limpar-VariaveisAmbiente {
    'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
        foreach ($scope in 'User', 'Machine') {
            Write-Verbose "Removendo a variável de ambiente: $_ do escopo $scope"
            try {
                if ($scope -eq 'User') {
                    [Microsoft.Win32.Registry]::CurrentUser.DeleteValue($_, $true)
                } else {
                    [Microsoft.Win32.Registry]::LocalMachine.DeleteValue($_, $true)
                }
            } catch {
                Write-Verbose "Chave $_ não encontrada no escopo $scope. Pulando..."
            }
        }
    }
}

# CONFIGURAÇÕES INICIAIS 2
# Salva a política original e altera para Bypass
$originalExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Cria pasta no desktop para os setups
$desktopPath = [Environment]::GetFolderPath("Desktop")
$installerPath = Join-Path $desktopPath "Instaladores"
if (-not (Test-Path $installerPath)) {
    New-Item -ItemType Directory -Path $installerPath | Out-Null
}

# DOWNLOAD E INSTALAÇÃO
# URLs para os setups
$officeRemoverUrl = "https://outlookdiagnostics.azureedge.net/sarasetup/SetupProd_OffScrub.exe"
$officeSetupUrl = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-br/HomeBusiness2021Retail.img"
$officeRemoverPath = Join-Path $installerPath "SetupProd_OffScrub.exe"
$officeSetupPath = Join-Path $installerPath "OfficeSetup.exe"

# Baixa os setups
Write-Host "Baixando Removedor do Office..." -ForegroundColor Yellow
if (-not (Download-FileWithBits -Url $officeRemoverUrl -Destination $officeRemoverPath -MaxRetries 5)) {
    Write-Host "Erro ao baixar o Removedor do Office. Encerrando o script." -ForegroundColor Red
    exit
}

Write-Host "Baixando Office 2021 Setup..." -ForegroundColor Yellow
if (-not (Download-FileWithBits -Url $officeSetupUrl -Destination $officeSetupPath -MaxRetries 5)) {
    Write-Host "Erro ao baixar o Office. Encerrando o script." -ForegroundColor Red
    exit
}

# VERIFICAÇÃO DO CHOCOLATEY
$chocoInstalled = $false

# Verifica se o comando 'choco' está disponível no PATH
if (Get-Command choco -ErrorAction SilentlyContinue) {
    $chocoInstalled = $true
}
# Verifica se o executável do Chocolatey está no caminho padrão
elseif (Test-Path "$env:ProgramData\Chocolatey\choco.exe") {
    $chocoInstalled = $true
}
# Se o Chocolatey não estiver instalado, ele será instalado
if (-not $chocoInstalled) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# ATIVAÇÃO DO WINDOWS
# Executa o comando remoto pela primeira vez
Write-Host "Ative o Windows..." -ForegroundColor Yellow
Ativar-WindowsOffice
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

# INSTALAÇÃO DO OFFICE
Write-Host "Iniciando instalação do Office..." -ForegroundColor Yellow
Start-Process -FilePath $officeSetupPath -Wait
Write-Host "Instalação do Office concluída! Confirme para continuar..." -ForegroundColor Green
Read-Host

# ATIVAÇÃO DO OFFICE
# Executa o comando remoto pela segunda vez
Write-Host "Ative o Office..." -ForegroundColor Yellow
Ativar-WindowsOffice
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

# Recomendação do removedor do Office
Write-Host "Se houver problemas com a instalação, execute o removedor manualmente: $officeRemoverPath" -ForegroundColor Red

# INSTALAÇÃO DE PROGRAMAS VIA CHOCOLATEY
# Listar a lista de programas que ele deseja instalar, separados por vírgula
$programsInput = Read-Host "Digite os nomes dos programas para instalar, separados por vírgula (exemplo: googlechrome, 7zip, adobereader)"

# Dividir a entrada do usuário em uma lista de programas
$softwareList = $programsInput -split ',' | ForEach-Object { $_.Trim() }

# Verificar se a lista de programas está vazia
if ($softwareList.Count -eq 0) {
    Write-Host "Nenhum programa foi selecionado. Pulando instalação de programas." -ForegroundColor Yellow
} else {
    # Exibir os programas que o usuário escolheu
    Write-Host "`nVocê escolheu os seguintes programas para instalação:"
    $softwareList

    # Validar e instalar os programas escolhidos
    foreach ($software in $softwareList) {
        Write-Host "`nVerificando a existência do programa: $software..."
        
        # Verifica se o pacote existe no repositório do Chocolatey
        $packageInfo = choco search $software --exact -r
        if ($packageInfo -like "*$software|*") {
            Write-Host "Instalando $software..." -ForegroundColor Yellow
            choco install $software -y
        } else {
            Write-Host "O programa '$software' não foi encontrado no repositório do Chocolatey. Pulando..." -ForegroundColor Red
        }
    }
}

Write-Host "`nInstalação concluída!" -ForegroundColor Green

# LIMPEZA E RESTAURAÇÃO
# Move os setups para a lixeira
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace(10) # Lixeira
Get-ChildItem -Path $installerPath | ForEach-Object { $folder.CopyHere($_.FullName) }
Remove-Item -Path $installerPath -Recurse -Force

# Porra de Chocolatey
$VerbosePreference = 'Continue'

# Verificar a variável de ambiente ChocolateyInstall
if (-not $env:ChocolateyInstall) {
    Write-Warning "O Chocolatey não foi detectado como instalado. Nenhuma ação necessária."
    return
}

if (-not (Test-Path $env:ChocolateyInstall)) {
    Write-Warning "Nenhuma instalação do Chocolatey foi detectada no caminho '$env:ChocolateyInstall'. Nenhuma ação necessária."
    return
}

# Backup do PATH
$userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
$userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

$machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment', $true)
$machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

$backupFile = Join-Path $desktopPath "PATH_backups_ChocolateyUninstall.txt"
@(
    "User PATH: $userPath"
    "Machine PATH: $machinePath"
) | Out-File -FilePath $backupFile -Force

Write-Verbose "Backup do PATH criado em: $backupFile"

# Remover referências ao Chocolatey do PATH
if ($userPath -like "*$env:ChocolateyInstall*") {
    Write-Verbose "Removendo o Chocolatey do PATH do usuário..."
    $newUserPATH = Remover-ChocolateyDoPATH -Path $userPath -ChocolateyPath $env:ChocolateyInstall
    $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
}

if ($machinePath -like "*$env:ChocolateyInstall*") {
    Write-Verbose "Removendo o Chocolatey do PATH do sistema..."
    $newMachinePATH = Remover-ChocolateyDoPATH -Path $machinePath -ChocolateyPath $env:ChocolateyInstall 
    $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
}

# Parar serviços relacionados ao Chocolatey
$services = @("chocolatey-agent") # Adicione serviços adicionais aqui, se necessário
foreach ($serviceName in $services) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Verbose "Parando o serviço: $serviceName"
        Stop-Service -Name $serviceName -Force
    }
}

# Verifica se o Chocolatey está instalado. Se sim, ele será desinstalado
if (Test-Path "$env:ProgramData\Chocolatey\choco.exe") {
    Desinstalar-Chocolatey
    # Verificar se o Chocolatey foi desinstalado corretamente
    if (Test-Path "$env:ProgramData\Chocolatey\choco.exe") {
        Write-Host "Falha ao desinstalar o Chocolatey. Removendo manualmente..." -ForegroundColor Red
    }
}

# Remoção dos arquivos do Chocolatey
Write-Host "Removendo os arquivos restantes do Chocolatey..." -ForegroundColor Yellow
Remove-Item -Path "$env:ProgramData\Chocolatey" -Recurse -Force -ErrorAction SilentlyContinue

# Limpar variáveis de ambiente relacionadas ao Chocolatey
Limpar-VariaveisAmbiente

# Fechar as chaves do registro
$machineKey.Close()
$userKey.Close()

Write-Host "O Chocolatey foi removido com sucesso. Backup do PATH disponível em $backupFile." -ForegroundColor Green

# Restaura a política de execução original
if ($originalExecutionPolicy -eq "Undefined") {
    Set-ExecutionPolicy Restricted -Scope Process -Force
} else {
    Set-ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
}

# FIM TRANSCRIÇÃO DO LOG
Stop-Transcript
Write-Host "Script concluído com sucesso! Verifique o log em $env:UserProfile\Desktop\AutoV_Log.txt para detalhes." -ForegroundColor Green