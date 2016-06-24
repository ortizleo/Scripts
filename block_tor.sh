#!/bin/bash
#Funcao: Bloquear exit nodes da rede TOR
#Obs: Fazer ajustes de acordo com necessidade(regras, lista etc)
#Resp: Leonardo Ortiz
CHECK_FORWARD=$(iptables -n --list FORWARD | grep BLOCK_TOR)
DIR_LOG="/DIRETORIO DE LOGS/log/block_tor"
DATA_HORA=$(date "+%d-%m-%Y %H:%M")
LOG_FILE_IPS=$DIR_LOG/"$(basename $0)-$(date +%d-%m-%Y_%H%M)_IPs.log"
LOG_FILE_SCRIPT=$DIR_LOG/"$(basename $0)-$(date +%d-%m-%Y_%H%M).log"
COUNT_OK=0
COUNT_ERRO=0


LIBERAR_IPTABLES(){
#Libera consulta DNS no 8.8.8.8 e porta 443 para o endereco check.torproject.org
echo "$(basename $0) - Iniciado execucao do script - $DATA_HORA" >> $LOG_FILE_SCRIPT
iptables -I INPUT -p udp --sport 53 -s 8.8.8.8 -j ACCEPT
iptables -I INPUT -p tcp --sport 443 -s check.torproject.org -j ACCEPT
}


DOWNLOAD_LISTA(){
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
}

BLOQUEAR_TOR(){
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

#Limpa a lista deixando somente IPs e jogando para outro arquivo
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' tor-exit-addresses | sed '/^$/d'  > tor_address

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
iptables -D INPUT -p udp --sport 53 -s 8.8.8.8 -j ACCEPT

#Remover arquivos baixados e limpa arquivos com mais de 10 dias
rm -rf tor_address tor-exit-addresses
find $DIR_LOG  -mtime +10 -exec rm -f {} \;
}

LIBERAR_IPTABLES
DOWNLOAD_LISTA
BLOQUEAR_TOR
LIMPEZA
