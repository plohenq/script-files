Write-Host "=====================`n=                   =`n=    AUTOV v0.5.    =`n=                   =`n=====================" -ForegroundColor Red
Write-Host "`n.NET Framework 4 e Edge WebView2 necessarios. Programa projetado para sistemas Windows 10+ recem-formatados.`n" -ForegroundColor Red
Read-Host

# INÍCIO TRANSCRIÇÃO DO LOG
Start-Transcript -Path "$env:UserProfile\Desktop\AutoV_Log.txt" -Append
Write-Host "Log de execução iniciado. Todas as ações serão registradas em $env:UserProfile\Desktop\AutoV_Log.txt" -ForegroundColor Cyan

# CONFIGURAÇÕES INICIAIS
# Verifica se o script está sendo executado como administrador
if (-not ([bool](New-Object Security.Principal.WindowsPrincipal [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "Por favor, execute o script como administrador." -ForegroundColor Red
    exit
}

# Salva a política original e altera para Bypass
$originalExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Cria pasta no desktop para os setups
$desktopPath = [Environment]::GetFolderPath("Desktop")
$installerPath = Join-Path $desktopPath "Instaladores"
if (-not (Test-Path $installerPath)) {
    New-Item -ItemType Directory -Path $installerPath | Out-Null
}

# URLs para os setups
$officeRemoverUrl = "https://outlookdiagnostics.azureedge.net/sarasetup/SetupProd_OffScrub.exe"
$officeSetupUrl = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/pt-br/HomeBusiness2021Retail.img"
$officeRemoverPath = Join-Path $installerPath "SetupProd_OffScrub.exe"
$officeSetupPath = Join-Path $installerPath "OfficeSetup.exe"

# DOWNLOAD E INSTALAÇÃO
# Função para baixar arquivos com várias tentativas
function Download-FileWithRetries {
    param (
        [string]$Url,
        [string]$Destination,
        [int]$MaxRetries = 5
    )
    $attempt = 0
    $success = $false

    while (-not $success -and $attempt -lt $MaxRetries) {
        $attempt++
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -ErrorAction Stop
            $success = $true
        } catch {
            Start-Sleep -Seconds 5 # Pausa antes da próxima tentativa
        }
    }

    if (-not $success) {
        Write-Host "Não foi possível baixar o arquivo após $MaxRetries tentativas." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Baixa os setups com tentativas de repetição
Write-Host "Baixando Removedor do Office..." -ForegroundColor Yellow
if (-not (Download-FileWithRetries -Url $officeRemoverUrl -Destination $officeRemoverPath -MaxRetries 5)) {
    Write-Host "Erro ao baixar o Removedor do Office. Encerrando o script." -ForegroundColor Red
    exit
}

Write-Host "Baixando Office 2021 Setup..." -ForegroundColor Yellow
if (-not (Download-FileWithRetries -Url $officeSetupUrl -Destination $officeSetupPath -MaxRetries 5)) {
    Write-Host "Erro ao baixar o Office. Encerrando o script." -ForegroundColor Red
    exit
}

# Verifica se o Chocolatey está instalado e instala caso necessário
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# ATIVAÇÃO 1
# Executa o comando remoto pela primeira vez
Write-Host "Ative o Windows..." -ForegroundColor Yellow
Invoke-Expression -Command "irm https://get.activated.win | iex"
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

# INSTALAÇÃO OFFICE - ATIVAÇÃO 2
# Executa o instalador do Office
Write-Host "Iniciando instalação do Office 2024..." -ForegroundColor Yellow
Start-Process -FilePath $officeSetupPath -Wait
Write-Host "Confirme para continuar após a instalação do Office..." -ForegroundColor Cyan
Read-Host

# Executa o comando remoto novamente
Write-Host "Executando comando remoto novamente..." -ForegroundColor Yellow
Invoke-Expression -Command "irm https://get.activated.win | iex"
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

# Recomenda execução do Removedor do Office
Write-Host "Se houver problemas com a instalação, execute o removedor manualmente: $officeRemoverPath" -ForegroundColor Red

# INSTALAÇÃO DE PROGRAMAS VIA CHOCOLATEY
# Solicitar ao usuário a lista de programas que ele deseja instalar, separados por vírgula
$programsInput = Read-Host "Digite os nomes dos programas para instalar, separados por vírgula (exemplo: googlechrome, 7zip, adobereader)"

# Dividir a entrada do usuário em uma lista de programas
$softwareList = $programsInput -split ',' | ForEach-Object { $_.Trim() }

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
    $newUserPATH = ($userPath -split ';' | Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }) -join ';'
    $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
}

if ($machinePath -like "*$env:ChocolateyInstall*") {
    Write-Verbose "Removendo o Chocolatey do PATH do sistema..."
    $newMachinePATH = ($machinePath -split ';' | Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }) -join ';'
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

# Remover os arquivos do Chocolatey
Write-Verbose "Removendo os arquivos do Chocolatey de $env:ChocolateyInstall"
Remove-Item -Path $env:ChocolateyInstall -Recurse -Force -ErrorAction SilentlyContinue

# Limpar variáveis de ambiente relacionadas ao Chocolatey
'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
    foreach ($scope in 'User', 'Machine') {
        Write-Verbose "Removendo a variável de ambiente: $_ do escopo $scope"
        [Microsoft.Win32.Registry]::CurrentUser.DeleteValue($_, $true)
        [Microsoft.Win32.Registry]::LocalMachine.DeleteValue($_, $true)
    }
}

# Fechar as chaves do registro
$machineKey.Close()
$userKey.Close()

Write-Host "O Chocolatey foi removido com sucesso. Backup do PATH disponível em $backupFile." -ForegroundColor Green

# Restaura a política de execução original
Set-ExecutionPolicy $originalExecutionPolicy -Scope Process -Force

# FIM TRANSCRIÇÃO DO LOG
Stop-Transcript
Write-Host "Script concluído com sucesso! Verifique o log em $env:UserProfile\Desktop\AutoV_Log.txt para detalhes." -ForegroundColor Green