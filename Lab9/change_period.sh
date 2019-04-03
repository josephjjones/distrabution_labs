#!/bin/bash

gossip_names=("Shadrach" "Joseph" "Angie" "Mom" "Megan" "Jonny" "Kattie" "Jacob")
gossip_group=("7jT5Lqy4SbfDf5FdcMgq5s" "FhjdoqykYuWfy3cMHBCfhH" "RViP2qRZbaNR4tSz5VZdXw" "76LCHQ4TGbvSdUhg6aZRu9" "FzUWc74HR1JZFqykP1S8Mt" "S4kw5DdWVFGcQXSzGvPs9Q" "Sas9JYSLPD29tM2AaLGEbi" "6tZYRzAjML4Wzv1FRUYjH2")

#host="127.0.0.1"
host="http://localhost:8080"
event_prefix="http://localhost:8080/sky/event/"
query_prefix="http://localhost:8080/sky/cloud/"

eid="/period_script"
echo "Update period to $1"
for sensor in "${gossip_group[@]}"
do
    curl -s --request POST "$event_prefix$sensor$eid/gossip/settings?period=$1" > temp
done
