#!/bin/bash
#Script para pesquisar usuários desligados no AD apartir de uma lista (arquivo) indicado pelo usuário.
#Resp.: Leonardo Ortiz
#Data: 30/04/2014
#Obs: Precisa do pacote openldap-clients
#Obs2: Fazer ajustes de acordo com necessidade(variaveis, DC, diretorios etc)
#Testado no Centos.

if [ -z $1 ]; then
        echo "$(basename $0): Favor indicar o arquivo ou o caminho absoluto do arquivo com os CPF's como parametro para o script. Ex.: pesq_user_ad users ou  pesq_user_ad /tmp/users.
        Favor inserir somente numeros no arquivo, do contrario a pesquisa não ocorrera para o CPF incorreto."
        exit
fi


##Dados para conectar no AD##
ad_host="DEFINIR O HOST DO CONTROLADOR DE DOMINIO"
user_ad="DEFINIR USUARIO AD"
senha_ad="DEFINIR SENHA AD"

##Variaveis de controle e coleta de dados
pegar_num=$(cat $1 | sed '/^$/d' | wc -l)
count_ativ=0
count_desl=0
count_inv=0

for i in $(seq 1 "$pegar_num"); do

pegar_linha=$(sed ''$i'!d' $1 | sed 's/ *$//g' | egrep '^[0-9]{11}$')

if [ -z "$pegar_linha" ]; then
        count_inv=$((count_inv+1))
        continue
fi


pesq=$(ldapsearch -x -LLL -h $ad_host -D "$user_ad" -w $senha_ad -b "dc="DEFINIR DC",dc=net" -s sub "(sAMAccountName=$pegar_linha)" | grep -i -w "UserAccountControl" | cut -d " " -f 2)


get_name=$(ldapsearch -x -LLL -h $ad_host -D "$user_ad" -w $senha_ad -b "dc="DEFINIR DC",dc=net" -s sub "(sAMAccountName=$pegar_linha)" | grep -i -w "displayname" | cut -d ":" -f 2)
#date=$(echo $((($pesq/10000000)-11644473600)) | perl -p -e 's/^([0-9]*)/"[".localtime($1)."]"/e')
        
        if [ -z $pesq ]; then
              echo "Usuário $pegar_linha : Não encontrado no AD no AD."
              count_inv=$((count_inv+1))
        elif [ "$pesq" = "66082" ] || [ "$pesq" = "66050" ] || [ "$pesq" = "546" ] || [ "$pesq" = "514" ] || [ "$pesq" = "262658" ] || [ "$pesq" = "262690" ] || [ "$pesq" = "328194" ] || [ "$pesq" = "328226" ]; then
        echo -e "Usuário $pegar_linha - $get_name: \\033[0;32mDESATIVADO\033[00;37m no AD."
        count_desl=$((count_desl+1))
        else
        count_ativ=$((count_ativ+1))
        echo -e "Usuário $pegar_linha - $get_name: \\033[0;41mATIVADO\033[00;37m no AD."

fi

done
echo "Numero de usuarios invalidos (CPF incorreto ou inexistente): $count_inv"
echo "Numero de usuarios ativos: $count_ativ"
echo "Numero de usuarios desativados: $count_desl"
