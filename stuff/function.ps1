function Saudação 
{
	param ([string] $nome)
	write-host "Ola, $nome! Você está no programa de contagem de nomes"
}

function adicionarNomes
{
	param ([array]$nomes)

	$adicionarNomes = read-host "Deseja adicionar mais nomes? (sim/não)"

	while ($adicinarNomes -eq "sim")
	{
		$novoNome = read-host "Digite um nome: "
		$nomes =+ $novoNome
		$adicionarNomes = read-host "Desea adicionar mais nomes? (sim/não)"
	}

	return $nomes

}

function ContarNomes
{
	param ([array]$nomes)

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
}

# Saudação inicial
Saudação -nome "Maria"

# Lista inicial de nomes
$nomes = @("Alice", "Alec", "Glória", "Lara", "Jorje")

# Adicionar novos nomes
$nomes = AdicionarNomes -nomes $nomes

# Contar e exibir os resultados
ContarNomes -nomes $nomes