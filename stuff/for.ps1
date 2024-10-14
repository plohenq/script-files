for ($i = 0; $i -le 10; $i++) # variaveis começam com '$', '-le' "Less than" or "Equals to". Em C seria '<='.
{
    write "O valor de i é $i"
}   # Alias write-host.

$nomes = @("Alice", "Dianna", "Rebecca", "Lucy")
      # Como '\n' em C.
echo "`n"
# Alias write-host.       # o ponto (.) é usado para acessar propriedades e métodos de um objeto.
for ($i = 0; $i -lt $nomes.length; $i++) # '-lt' Apenas "Less than". 
{                          # Acessa a propriedade de comprimento (número de elementos) de uma array ou string.
    write-host "Nome: $($nomes[$i])" 
}                # A subexpressão $() permite avaliar uma expressão dentro de uma string.

