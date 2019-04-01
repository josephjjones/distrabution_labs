#!/bin/bash

gossip_names=("Shadrach" "Joseph" "Angie" "Mom" "Megan" "Jonny" "Kattie" "Jacob")
gossip_group=("eci1" "eci2" "eci3" "eci4" "5" "6" "7" "8")

event_prefix="http://localhost:8080/sky/event/"
query_prefix="http://localhost:8080/sky/cloud/"

eid="/test_script"

send_fake_temperature(){
    temperature=$RANDOM
    temperature=`expr $temperature % 32 + 59`
    echo "Sent $temperature to $1"
    curl -s \
    --header "Content-Type: application/json" \
    --request POST \
    --data "{\"eventName\":\"sensorHeartbeat\",
             \"genericThing\":{
                \"typeId\":\"2.1.2\",
                \"typeName\":\"generic.simple.temperature\",
                \"healthPercent\":56.89,
                \"heartbeatSeconds\":10,
                \"data\":{
                    \"temperature\":[
                        {  \"name\":\"ambient temperature\",
                           \"transducerGUID\":\"28E3A5680900008D\",
                           \"units\":\"degrees\",
                           \"temperatureF\":$temperature,
                           \"temperatureC\":24.06
                        }
                    ]
                }
            }
        }" \
    "$event_prefix$1$eid/wovyn/heartbeat" > temp
}

echo "Reset gossip network"
for sensor in "${gossip_group[@]}"
do
    curl -s --request POST "$event_prefix$sensor$eid/wrangler/uninstall_rulesets_requested?rids=gossip" > temp
done
for sensor in "${gossip_group[@]}"
do
    curl -s --request POST "$event_prefix$sensor$eid/wrangler/install_rulesets_requested?rids=gossip" > temp
done

index=1
while 1
do
    sleep 5
    echo "Shadrach ======================================================="
    curl -s "$query_prefix${gossip_group[0]}$eid/gossip/get_gossip" > temp
    echo "Jacob =========================================================="
    curl -s "$query_prefix${gossip_group[7]}$eid/gossip/get_gossip" > temp
    send_fake_temperature "${gossip_group[$index]}"
    index=`expr ( $index + 1 ) % 8`
done
