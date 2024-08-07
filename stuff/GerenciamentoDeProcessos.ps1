# Variáveis e teste
$folder = Join-Path "$env:USERPROFILE" -ChildPath "Desktop\dir"

if (-not (Test-Path -Path $folder)) {
    New-Item -Path $folder -ItemType Directory
    Write-Host "Diretório criado: $folder" -ForegroundColor Green
}

$file = Join-Path $folder -ChildPath "file.txt"

if (-not (Test-Path -Path $file)) {
    New-Item -Path $file -ItemType File
    Write-Host "Arquivo criado: $file" -ForegroundColor Green
}

$arquivoProcessos = Join-Path $folder -ChildPath "arquivo_processos.txt"

if (-not (Test-Path -Path $arquivoProcessos)) {
    New-Item -Path $arquivoProcessos -ItemType File
    Write-Host "Arquivo criado: $arquivoProcessos" -ForegroundColor Green
}

# Escreve no arquivo e mostra o conteúdo
Set-Content -Path $file -Value "Primeira linha"
Add-Content -Path $file -Value "Segunda linha"

$content = Get-Content -Path $file
echo $content

# Salvar os processos num arquivo de texto
$processos = Get-Process | Where-Object { $_.WorkingSet -gt 100MB }
$processos | Select-Object Name, ID, @{Name="Memory (MB)"; Expression = {[math]::round($_.WorkingSet / 1MB, 2)}} | 
    Format-Table -AutoSize | Out-File -FilePath $arquivoProcessos

# Exibir no console
Get-Content -Path $arquivoProcessos | Write-Host
