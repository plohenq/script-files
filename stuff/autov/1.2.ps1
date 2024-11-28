# INÍCIO
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

# DOWNLOAD DE SETUP
# Função para baixar arquivos
function Download-File($url, $outputPath) {
    Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
}

# Baixa os setups
Write-Host "Baixando Removedor do Office..." -ForegroundColor Yellow
Download-File -url $officeRemoverUrl -outputPath $officeRemoverPath
Write-Host "Baixando Office 2024 Setup..." -ForegroundColor Yellow
Download-File -url $officeSetupUrl -outputPath $officeSetupPath

# Verifica se o Chocolatey está instalado e instala caso necessário
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# ATIVAÇÃO DO WINDOWS
# Executa o comando remoto pela primeira vez
Write-Host "Executando comando remoto..." -ForegroundColor Yellow
Invoke-Expression -Command "irm https://get.activated.win | iex"
Write-Host "Confirme para continuar..." -ForegroundColor Cyan
Read-Host

# INSTALAÇÃO E ATIVAÇÃO DO OFFICE
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
