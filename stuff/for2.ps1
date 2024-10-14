$nomes = @("Alice", "Alec", "Glória", "Lara", "Jorje")

$adicionarNomes = read-host "Deseja adicionar mais nomes? (sim/não): "

while ($adicionarNomes -eq "sim")
{
	$novoNome = read-host "Digite um nome: "
	$nomes += $novoNome
	$adicionarNomes = read-host "Deseja adicionar mais nomes? (sim/não): "
}

$menorQue5 = 0
$maiorOuIgual5 = 0

for ($i = 0; $i -lt $nomes.length; $i++)
{
	if ($nomes[$i].length -lt 5)
	{
		echo "$($nomes[$i]) tem menos de 5 caracteres"
		$menorQue5++
	}
	else 
	{
		echo $nomes[$i].ToUpper()
		$maiorOuIgual5++
	}
}

echo "Foram encontrados $($nomes.length) nomes na array."
echo "$menorQue5 dos nomes possuem menos de 5 letras."
echo "$maiorOuIgual5 dos nomes possuem 5 letras ou mais."