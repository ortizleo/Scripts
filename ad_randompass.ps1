# Script pra definir uma senha randomica para usuários de um .csv (coluna "Conta" contendo somente o sAMAccountName)
# Função pra definir senha: https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/
# Leonardo Ortiz

Import-Csv -Path “c:\temp\users.csv” | ForEach-Object {

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
function Scramble-String([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}
 
$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 3 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 3 -characters '1234567890'
$password += Get-RandomCharacters -length 3 -characters '!$%&/()=?}][{@#*+'
 

$password = Scramble-String $password



Write-Host "$_.’Conta’ senha: $password"

Set-ADAccountPassword -Identity $_.’Conta’ -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$password" -Force)

}
