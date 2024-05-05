$downloadFolder = join-path ~\ "Music\downloaded"

if (-not (test-path -path $downloadFolder)) {
    ni -path $downloadFolder -itemtype Directory
}

do {
    $input = read-host "Digite o link (ou 'sair' para encerrar)"

    if ($input -ne "sair") {
        $links = $input -split ","
        
        foreach ($link in $links) {
            $link = $link.Trim()
            
            if ($link -match "playlist") {
                $outputPath = join-path $downloadFolder "%(playlist_title)s/%(title)s.%(ext)s"
                yt-dlp --format bestaudio[ext=m4a] --yes-playlist -o $outputPath $link
                write-host "Playlist baixada e salva em '$downloadFolder'" -ForegroundColor Green
            }
            else {
                $info = yt-dlp --get-title $link
                $title = $info
                $outputPath = join-path $downloadFolder "$title.m4a"
                yt-dlp --format bestaudio[ext=m4a] -o $outputPath $link
                write-host "Música $title baixada e salva como $outputPath" -ForegroundColor Green
            }
        }
    }
} while ($input -ne "sair")

