#!/bin/bash
# Script simples para verificar ip address em listas da ipvoid informada como parametro
# Resp.: Leonardo Ortiz
# Data: 05/03/2021

while read line; do

rep=$(curl -s -k --location --request POST 'https://www.ipvoid.com/ip-blacklist-check/' --form ip=$line | grep "Blacklist Status" | awk -F ">" '{print $6}' | sed 's/<\/span//g')

echo "$line - $rep"

done < $1
