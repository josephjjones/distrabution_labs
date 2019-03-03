#!/bin/bash

parent_eci="XytyHAqLVubBnVUB6YjcAJ"

children=("Joseph" "Jacob" "Jones")
channels=("" "" "")
indices=(0 1 2)

echo "Create Children ${children[@]}"

for child in "${children[@]}"
do
    curl -s --request POST "http://localhost:8080/sky/event/$parent_eci/postman/sensor/new_sensor?sensor_name=$child" > temp
done

sensors=`curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/sensors"`
echo -e "Show sensor children"
echo "$sensors"

for i in "${indices[@]}"
do
    channels[i]=`echo "$sensors" | python3 -c "import sys, json; print(json.load(sys.stdin)['${children[i]}']['eci'])"`
done

echo "Chlidrens channels"
for i in "${channels[@]}"
do
    echo "$i"
done

echo -e "\nTemperatures Before"
curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/all_temperatures"
echo -e "\n\nSend 3 Hearbeats to fill temperatures"
for channel in "${channels[@]}"
do
for i in "${indices[@]}"
do
    temperature=$RANDOM
    temperature=`expr $temperature % 32 + 59`
    echo "Sent $temperature to ${children[i]}"
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
    "http://localhost:8080/sky/event/${channels[i]}/postman/wovyn/heartbeat" > temp
done
done

echo "Get Temperatures from all children "
curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/all_temperatures"

echo -e "\n\nDelete Jacob"
curl -s --request POST "http://localhost:8080/sky/event/$parent_eci/postman/sensor/unneeded_sensor?sensor_name=Jacob"

echo -e "\n\nChildren after"
curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/sensors"

echo -e "\nTemperatures after"
curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/all_temperatures"

echo -e "\n\nDelete All Children"
##for child in "${children[@]}"
#do
#    curl -s --request POST "http://localhost:8080/sky/event/$parent_eci/postman/sensor/unneeded_sensor?sensor_name=$child" > temp
#done
echo -e "\nChildren after deletion"
curl -s "http://localhost:8080/sky/cloud/$parent_eci/manage_sensors/sensors"
echo -e "Done"
rm temp
