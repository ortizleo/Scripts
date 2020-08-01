#!/bin/bash

API=

curl --compressed https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1 > IPS_STAMPARM1

egrep -v "146.88.240.*" IPS_STAMPARM1 > IPS_STAMPARM


total=$(wc -l IPS_STAMPARM  | awk '{print $1}')
count=0


IPS=$(while read line;do
 count=$(($count+1))

if [ "$count" -eq "$total" ]; then
 echo "\"$line\""
else
 echo "\"$line\","
fi
done < IPS_STAMPARM
)


echo "{
\"ips\": [
        "$IPS"
      ]
}" > ips_json.txt


curl -H "X-Api-Key: $API" -H "Content-Type: application/json" -d @ips_json.txt ENDERECO DA API ADDRESS
