function Saudacao {
	param (
	[string] $nome
)
	write-host "Ola, "$nome

}
	Saudacao -nome "Maria"