# Obtém a API Key da variável de ambiente
$apiKey = $env:OPENAI_API_KEY

# URL da API de completions do ChatGPT
$apiUrl = "https://api.openai.com/v1/chat/completions"

# Função principal para enviar mensagens ao ChatGPT
Function Ask-ChatGPT {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserMessage
    )

    # Define o payload da requisição
    $body = @{
        model = "gpt-3.5-turbo"
        messages = @(
            @{
                role = "system"
                content = "Você é um assistente útil."
            },
            @{
                role = "user"
                content = $UserMessage
            }
        )
    } | ConvertTo-Json -Depth 10

    # Define os headers da requisição
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    # Faz a requisição POST para a API
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
        $response.choices[0].message.content
    } catch {
        Write-Error "Erro ao conectar à API: $_"
    }
}

# Interface interativa no terminal
Write-Host "Bem-vindo ao ChatGPT no PowerShell! Digite 'sair' para encerrar." -ForegroundColor Green

while ($true) {
    $userInput = Read-Host "Você"
    if ($userInput -eq "sair") {
        Write-Host "Até logo!" -ForegroundColor Yellow
        break
    }

    # Chama a função e exibe a resposta do ChatGPT
    $response = Ask-ChatGPT -UserMessage $userInput
    Write-Host "ChatGPT: $response" -ForegroundColor Cyan
}
