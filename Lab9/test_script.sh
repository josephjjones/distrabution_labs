#!/bin/bash

gossip_names=("Shadrach" "Joseph" "Angie" "Mom" "Megan" "Jonny" "Kattie" "Jacob")
gossip_group=("SPkzGEeZqaaZPQwADbKF1T" "Y9WDYvCvCA6Ub6cnrBDuox" "EVWt6enfGRGz9yT2xmH8Ab" "SkFnPo91qF9LLoqrkq3x1g" "6rsqok79DL4aVwTjArncYK" "3vV4N13Ap2AYGwKjQ9xppw" "S2AP48WnFEmKFuRohoPt2R" "VyQ6xPohSZFKvoHZFzTb2Q")

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
    curl -s --request POST "$event_previx$sensor$eid/gossip/destroy" > temp
done
sleep 5
echo "Setup Network"

curl -s --request POST "$event_previx${gossip_group[0]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_previx${gossip_group[0]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[3]}" > temp
curl -s --request POST "$event_previx${gossip_group[0]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[5]}" > temp
curl -s --request POST "$event_previx${gossip_group[1]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[2]}" > temp
curl -s --request POST "$event_previx${gossip_group[2]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[4]}" > temp
curl -s --request POST "$event_previx${gossip_group[2]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[6]}" > temp
curl -s --request POST "$event_previx${gossip_group[3]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_previx${gossip_group[5]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_previx${gossip_group[6]}$eid/gossip/add_peer?host=localhost&eci=${gossip_group[7]}" > temp

index=1
while 1
do
    sleep 5
    clear
    echo "Shadrach ======================================================="
    curl -s "$query_prefix${gossip_group[0]}$eid/gossip/get_gossip" > temp
    echo "Jacob =========================================================="
    curl -s "$query_prefix${gossip_group[7]}$eid/gossip/get_gossip" > temp
    send_fake_temperature "${gossip_group[$index]}"
    index=`expr ( $index + 1 ) % 8`
done
