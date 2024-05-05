$dir = "~\Music\"
$arquivos = get-childitem -path $dir

foreach ($arquivo in $arquivos){
	write-host $arquivo.name
}
