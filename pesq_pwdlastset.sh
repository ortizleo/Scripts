#!/bin/bash
#Script para verificar atributo LastPWDChange no AD a partir de uma lista de usuários
#Resp.: Leonardo Ortiz
#Data: 08/05/2015
#Obs.: Precisa pacote openldap-clients - LDAP client utilities
#Testado para CentOS
#Uso: script.sh listadeusuarios

if [ -z $1 ]; then
        echo "$(basename $0): Favor indicar o arquivo ou o caminho absoluto do arquivo com os CPF's como parametro para o script. Ex.: pesq_user_ad users ou  pesq_user_ad /tmp/users.
        Favor inserir somente numeros no arquivo, do contrario a pesquisa não ocorrera para o CPF incorreto."
        exit
fi


##Dados para conectar no AD##
host_ad="HOST AD"
user_ad="domainname\user"
senha_ad="senha"

##Variaveis de controle e coleta de dados
pegar_num=$(cat $1 | sed '/^$/d' | wc -l)
count_ativ=0
count_desl=0
count_inv=0
for i in $(seq 1 "$pegar_num"); do

#Só CPF
#pegar_linha=$(sed ''$i'!d' $1 | sed 's/ *$//g' | egrep '^[0-9]{11}$')
#todos
pegar_linha=$(sed ''$i'!d' $1 | sed 's/ *$//g')

if [ -z "$pegar_linha" ]; then
        count_inv=$((count_inv+1))
        continue
fi


pesq=$(ldapsearch -x -LLL -h $host_ad -D "$user_ad" -w $senha_ad -b "dc="ENTRAR COM O DC",dc=net" -s sub "(sAMAccountName=$pegar_linha)" | grep -i -w "pwdLastSet" | cut -d " " -f 2)
get_name=$(ldapsearch -x -LLL -h $host_ad -D "$user_ad" -w $senha_ad -b "dc="ENTRAR COM O DC",dc=net" -s sub "(sAMAccountName=$pegar_linha)" | grep -i -w "displayname" | cut -d ":" -f 2)
date=$(echo $((($pesq/10000000)-11644473600)) | perl -p -e 's/^([0-9]*)/"[".localtime($1)."]"/e')

if [ $pesq = '0' ]; then
echo "Usuário: $get_name - Data de alteração da senha: Senha nunca definida"
else
echo "Usuário: $get_name - Data de alteração da senha: $date"
fi
done
