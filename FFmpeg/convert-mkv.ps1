$files = Get-ChildItem -Filter *.mp4

foreach ($file in $files) {
    $output = $file.Name -replace '\.mp4$', '.mkv'
    ffmpeg -i $file.FullName -c:v copy -c:a copy -map_metadata 0 $output
    Write-Host "Arquivo $($file.Name) convertido para $output"
}
