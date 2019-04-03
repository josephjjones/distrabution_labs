#!/bin/bash

gossip_names=("Shadrach" "Joseph" "Angie" "Mom" "Megan" "Jonny" "Kattie" "Jacob")
gossip_group=("7jT5Lqy4SbfDf5FdcMgq5s" "FhjdoqykYuWfy3cMHBCfhH" "RViP2qRZbaNR4tSz5VZdXw" "76LCHQ4TGbvSdUhg6aZRu9" "FzUWc74HR1JZFqykP1S8Mt" "S4kw5DdWVFGcQXSzGvPs9Q" "Sas9JYSLPD29tM2AaLGEbi" "6tZYRzAjML4Wzv1FRUYjH2")

#host="127.0.0.1"
host="http://localhost:8080"
event_prefix="http://localhost:8080/sky/event/"
query_prefix="http://localhost:8080/sky/cloud/"

eid="/test_script"

send_fake_temperature(){
    temperature=$RANDOM
    temperature=`expr $temperature % 32 + 59`
    echo "Sent $temperature to $2"
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

if [ $1 == "reinstall" ]; then
    echo "Uninstall Rulesets"
    for sensor in "${gossip_group[@]}"
    do
        curl -s --request POST "$event_prefix$sensor$eid/wrangler/uninstall_rulesets_requested?rids=gossip" > temp
    done
    sleep 6
    echo "Install Rulesets"
    for sensor in "${gossip_group[@]}"
    do
        curl -s --request POST "$event_prefix$sensor$eid/wrangler/install_rulesets_requested?rids=gossip" > temp
    done
fi

echo "Reset gossip network"
for sensor in "${gossip_group[@]}"
do
    curl -s --request POST "$event_prefix$sensor$eid/gossip/destroy" > temp
    curl -s --request POST "$event_prefix$sensor$eid/sensor/reading_reset" > temp
done
sleep 5 
echo "Setup Network"

curl -s --request POST "$event_prefix${gossip_group[0]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_prefix${gossip_group[0]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[3]}" > temp
curl -s --request POST "$event_prefix${gossip_group[0]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[5]}" > temp
curl -s --request POST "$event_prefix${gossip_group[1]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[2]}" > temp
curl -s --request POST "$event_prefix${gossip_group[2]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[4]}" > temp
curl -s --request POST "$event_prefix${gossip_group[2]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[6]}" > temp
curl -s --request POST "$event_prefix${gossip_group[3]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_prefix${gossip_group[5]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[1]}" > temp
curl -s --request POST "$event_prefix${gossip_group[6]}$eid/gossip/add_peer?host=$host&eci=${gossip_group[7]}" > temp

index=0
while true
do
    sleep 2
  framebuffer=$(
    clear
    echo "Shadrach ======================================================="
    echo -e `curl -s "$query_prefix${gossip_group[0]}/gossip/get_gossip"`
    echo -e `curl -s "$query_prefix${gossip_group[0]}/gossip/get_peers"`
    echo "Jacob =========================================================="
    echo -e $(curl -s "$query_prefix${gossip_group[7]}/gossip/get_gossip")
    echo -e $(curl -s "$query_prefix${gossip_group[7]}/gossip/get_peers")
    send_fake_temperature "${gossip_group[$index]}" "${gossip_names[$index]}"
  )
    printf "%s" "$framebuffer"
    index=`expr \(  $index + 1 \) % 8`
done
