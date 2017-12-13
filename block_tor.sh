#!/bin/bash
#Funcao: Bloquear exit nodes da rede TOR
CHECK_FORWARD=$(iptables -n --list FORWARD | grep BLOCK_TOR)
DIR_LOG="/marisol/log/block_tor"
DATA_HORA=$(date "+%d-%m-%Y %H:%M")
LOG_FILE_IPS=$DIR_LOG/"$(basename $0)-$(date +%d-%m-%Y_%H%M)_IPs.log"
LOG_FILE_SCRIPT=$DIR_LOG/"$(basename $0)-$(date +%d-%m-%Y_%H%M).log"
COUNT_OK=0
COUNT_ERRO=0
WORK_DIR=/tmp

LIBERAR_IPTABLES(){
#Libera consulta DNS no 8.8.8.8 e porta 443 para o endereco check.torproject.org
echo "$(basename $0) - Iniciado execucao do script - $DATA_HORA" >> $LOG_FILE_SCRIPT
iptables -I INPUT -p udp --sport 53 -s 8.8.8.8 -j ACCEPT
iptables -I INPUT -p tcp --sport 443 -s check.torproject.org -j ACCEPT
iptables -I INPUT -p tcp --sport 443 -s www.spamhaus.org -j ACCEPT
}


LISTA_SPAMHAUS(){
cd $WORK_DIR

wget -q  https://www.spamhaus.org/drop/drop.txt --output-document=spamhaus_drop
wget -q  https://www.spamhaus.org/drop/edrop.txt --output-document=spamhaus_edrop
grep -v "^;" spamhaus_drop | cut -d ";" -f -1 > spamhaus_drop_address
grep -v "^;" spamhaus_edrop | cut -d ";" -f -1 > spamhaus_edrop_address
}

LISTA_TOR(){
#Faz download da lista de exit nodes
wget -q https://check.torproject.org/exit-addresses --output-document=tor-exit-addresses

if [ "$?" -ne "0" ]; then
        echo "$(basename $0) - $DATA_HORA - ERRO - Erro ao baixar a lista de IP's TOR!" >> $LOG_FILE_SCRIPT
        rm -rf tor-exit-addresses
        LIMPEZA
        exit 1
else
        echo "$(basename $0) - $DATA_HORA - OK - Lista baixada com sucesso, adicionando IPs no iptables..." >> $LOG_FILE_SCRIPT
fi


#Limpa a lista deixando somente IPs e jogando para outro arquivo
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' tor-exit-addresses | sed '/^$/d'  > tor_address

if [ "$?" -ne "0" ]; then
        exit 1
fi
}

APLICAR_BLOQUEIO(){
#Verifica a existencia da chain BLOCK_TOR, caso nao exista ele cria
#Limpa a chain BLOCK_TOR
#Adiciona como primeira regra o RETURN, enderecos que n batem na regra retornam para a chan FORWARD, as regras de bloqueio vao ficar acima dessa
iptables -nvL BLOCK_TOR &> /dev/null || iptables -N BLOCK_TOR
iptables -F BLOCK_TOR
iptables -I BLOCK_TOR -j RETURN

#Adiciona redirecionamento como primeira regra da chain FORWARD levando pra chain BLOCK_TOR
if [ -z "$CHECK_FORWARD" ]; then
        iptables -I FORWARD -j BLOCK_TOR
fi

#Merge das listas
cat spamhaus_drop_address >> tor_address
cat spamhaus_edrop_address >> tor_address
#Loop para adicionar linha por linha da lista como regra de drop no iptables
#As regras serao inseridas acima da RETURN, sendo essa a ultima regra
while read line; do
        iptables -I BLOCK_TOR -s $line -j DROP &> /dev/null

        if [ "$?" = "0" ]; then
                echo "OK: $line" >> $LOG_FILE_IPS
                COUNT_OK=$(($COUNT_OK+1))

        else
                echo "ERRO: $line" >> $LOG_FILE_IPS
                echo "$(basename $0) - $DATA_HORA - ERRO: Erro ao adicionar IP $line" >> $LOG_FILE_SCRIPT
                COUNT_ERRO=$(($COUNT_ERRO+1))
        fi
done < tor_address

echo "Adicionados com sucesso: $COUNT_OK"  >> $LOG_FILE_IPS
echo "Adicionados com erro(Verificar log IPs!!): $COUNT_ERRO" >> $LOG_FILE_IPS
echo "$(basename $0) - $DATA_HORA - Finalizado execucao do Script, lista de IPs adicionados em $LOG_FILE_IPS" >> $LOG_FILE_SCRIPT
}

LIMPEZA(){
#Remove as regras criadas para acesso a lista
iptables -D INPUT -p tcp --sport 443 -s check.torproject.org -j ACCEPT
iptables -D INPUT -p tcp --sport 443 -s www.spamhaus.org -j ACCEPT
iptables -D INPUT -p udp --sport 53 -s 8.8.8.8 -j ACCEPT

#Remover arquivos baixados e limpa arquivos com mais de 20 dias
cd $WORK_DIR
rm -rf tor_address tor-exit-addresses spamhaus_edrop_address spamhaus_drop_address spamhaus_drop spamhaus_edrop
find $DIR_LOG  -mtime +20 -exec rm -f {} \;
}

LIBERAR_IPTABLES
LISTA_SPAMHAUS
LISTA_TOR
APLICAR_BLOQUEIO
LIMPEZA
