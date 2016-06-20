#!/bin/bash
#Responsavel: Leonardo Ortiz
#Objetivo: Automatizar criacao de objetos no Fortigate com os alertas recebidos por e-mail
#Uso: Copiar o conteudo dos e-mails e jogar em um arquivo de texto chamado "fw"
#Problemas: Não consigo colocar o arquivo como parametro, o bash simplesmente não aceita

teste=$1

data=$(date "+%d/%m/%Y - %H:%M:%S")

INF(){
echo > FIREWALL_TMP
        while read line; do

motivo=$(echo "$line" | grep -o "observed.*" | sed "s/observed\://g")
ip=$(echo "$line" | grep -o "srcip=[0-9]*.[0-9]*.[0-9]*.[0-9]*.[0-9]*" | tr -d "srcip=")

if [ -n "$ip" ]; then
        echo "IP: $ip" >> FIREWALL_TMP
elif [ -n "$motivo" ]; then
        echo -n  "Motivo: $motivo " >> FIREWALL_TMP
fi
                echo "$line"
        done < fw > /dev/null

cat FIREWALL_TMP | sort | uniq | sed '/^$/d' > FIREWALL_TMP_FMT
}




REGRA(){


enderecos=$(wc -l FIREWALL_TMP_FMT | awk '{print $1}')
final=$(($teste+$enderecos-1))
contador=0


for i in $(seq $teste $final); do

contador=$(($contador+1))
pegar_linha=$(sed ''$contador'!d' FIREWALL_TMP_FMT | sed 's/ *$//g')
motivo=$(echo "$pegar_linha" | cut -d ":" -f 2 | sed "s/IP//g" | sed 's/ *$//g')
ip=$(echo "$pegar_linha" | cut -d ":" -f 3| sed 's/ *$//g')

#        pegar_motivo=$(sed ''$contador'!d' $2 | sed 's/ *$//g')

        echo "
        edit \"ext-quarentena-grupo2-$i\"
        set comment \"Add: Leonardo Ortiz
        Data: $data
        Motivo: $motivo\"
          set subnet $ip 255.255.255.255
          next "
done
}

CLEAN(){
rm -rf $(pwd)/FIREWALL_TMP
rm -rf $(pwd)/FIREWALL_TMP_FMT
rm -rf $(pwd)/fw
}


INF
REGRA
CLEAN
