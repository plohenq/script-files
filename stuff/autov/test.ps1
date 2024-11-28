# Verificando se o Chocolatey está instalado
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

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

# Desinstalando o Chocolatey
Write-Host "Desinstalando o Chocolatey..."
choco uninstall chocolatey -y

Write-Host "Chocolatey foi desinstalado com sucesso!"
