#!/bin/bash
NOTIFICACAO=
echo > /var/log/letsencrypt/letsencrypt.log

certbot renew --noninteractive --quiet

if [ "$?" -ne "0" ]; then
        echo "Falha na atualizacao dos certificado LentsEncrypt." | mailx -s " - Renovacao LetsEncrypt .net - FALHA" $NOTIFICACAO
        exit
fi


VERIFICAR=$(grep "Cert not yet due for renewal" /var/log/letsencrypt/letsencrypt.log)

if [ -n "$VERIFICAR" ]; then
        echo "Certificado nao esta proximo do vencimento"
        exit
else
        cp -pr /etc/letsencrypt/archive/folder/* /ansible/certificados/ssl/folder/
        if ! out=`ansible-playbook /ansible/certificados/certificados.yml`; then echo $out; fi

        if [ "$?" -eq "0" ]; then
             echo "Certificado LentsEncrypt atualizado com sucesso" | mailx -s "atualizacao LetsEncrypt marisolsa.net - OK" $NOTIFICACAO
        else
             echo "Falha na atualizacao dos certificado LentsEncrypt." | mailx -s " atualizacao LetsEncrypt marisolsa.net - FALHA" $NOTIFICACAO
        fi
fi
