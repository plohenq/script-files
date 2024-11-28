Write-Host "=====================`n=                   =`n=    AUTOV v0.3.    =`n=                   =`n=====================" -ForegroundColor Red
Write-Host "`n.NET Framework 4 e Edge WebView2 necessarios.`n" -ForegroundColor Red
Read-Host

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
$officeSetupUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=Home2024Retail&platform=x64&language=pt-br&version=O16GA"
$officeRemoverPath = Join-Path $installerPath "SetupProd_OffScrub.exe"
$officeSetupPath = Join-Path $installerPath "OfficeSetup.exe"

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
        Write-Host "Tentativa $attempt de $MaxRetries para baixar o arquivo..."

        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -ErrorAction Stop
            $success = $true
            Write-Host "Download bem-sucedido!" -ForegroundColor Green
        } catch {
            Write-Host "Falha ao baixar o arquivo. Tentando novamente..." -ForegroundColor Red
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

Write-Host "Baixando Office 2024 Setup..." -ForegroundColor Yellow
if (-not (Download-FileWithRetries -Url $officeSetupUrl -Destination $officeSetupPath -MaxRetries 5)) {
    Write-Host "Erro ao baixar o Office. Encerrando o script." -ForegroundColor Red
    exit
}

# Verifica se o Chocolatey está instalado e instala caso necessário
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Executa o comando remoto pela primeira vez
Write-Host "Ative o Windows..." -ForegroundColor Yellow
Invoke-Expression -Command "irm https://get.activated.win | iex"
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

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
$programsInput = Read-Host "Digite os nomes dos programas para instalar, separados por vírgula (exemplo: googlechrome, vscode, git)"

# Dividir a entrada do usuário em uma lista de programas
$softwareList = $programsInput -split ',' | ForEach-Object { $_.Trim() }

# Exibir os programas que o usuário escolheu
Write-Host "`nVocê escolheu os seguintes programas para instalação:"
$softwareList

# Instalando os programas escolhidos
foreach ($software in $softwareList) {
    Write-Host "`nInstalando $software..."
    choco install $software -y
}

Write-Host "`nTodos os programas foram instalados com sucesso!"

# LIMPEZA E FIM DO SCRIPT
# Move os setups para a lixeira
Write-Host "Movendo setups para a lixeira..." -ForegroundColor Yellow
Remove-Item -Path $installerPath -Recurse -Force

# Desinstala o Chocolatey
Write-Host "Desinstalando Chocolatey..." -ForegroundColor Yellow
choco uninstall all -y

# Restaura a política de execução original
Set-ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
Write-Host "Script concluído com sucesso!" -ForegroundColor Green