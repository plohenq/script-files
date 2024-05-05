$filePath = Read-Host "Digite o caminho completo para o arquivo de texto:"
$content = Get-Content $filePath -Raw
$words = $content -split '\s+'

$wordCount = @{}
foreach ($word in $words) {
    if ($wordCount.ContainsKey($word)) {
        $wordCount[$word]++
    } else {
        $wordCount[$word] = 1
    }
}

foreach ($word in $wordCount.Keys) {
    Write-Host "$word $($wordCount[$word])"
}
