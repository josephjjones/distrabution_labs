ruleset manage_sensors{
    meta{
        author "Joseph Jones"
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias Subscriptions
        shares sensors, all_temperatures
        provides sensors, all_temperatures
    }

    global{
        sensors = function(){
            ent:sensor_list.defaultsTo({})
        }
        all_temperatures = function(){
            Subscriptions:established().filter(
                function(v){
                    v.get("Tx_role") == "sensor"
                }
            ).map(
                function(v){
                    sensor_name = sensors().get(v.get(["Tx","sensor_name"]));
                    temperature = wrangler:skyQuery(v.get("Tx"),"temperature_store","temperatures",{});
                    {}
                }
            )
        }
        get_channel = function(sensor_name){
            sensors().filter(function(v,k){
                v.get("sensor_name") == sensor_name
            }).keys()
        }
    }

    rule add_sensor{
        select when sensor new_sensor where event:attr("sensor_name")
        pre{
            sensor = event:attr("sensor_name")
            exists = sensors() >< sensor
        }
        if exists
        then send_directive("Status",{"new_sensor":"Sensor already created"})
        notfired{
            raise wrangler event "child_creation"
                attributes { "name": sensor,
                             "color": "#fe50d2",
                             "section_id": sensor,
                             "rids": ["temperature_store",
                                      "wovyn_base",
                                      "sensor_profile",
                                      "twilio.keys",
                                      "twilio.methods",
                                      "io.picolabs.subscription"] }
        }
    }

    rule store_new_section {
      select when wrangler child_initialized
      pre {
        id = event:attr("id")
        eci = event:attr("eci")
        sensor_name = event:attr("rs_attrs"){"section_id"}
      }
      if sensor_name.klog("found section_id")
      then every{
        send_directive("Status",{"new_sensor":"Created new Sensor"});
        event:send(
           { "eci": eci, "eid": "parent",
             "domain": "sensor", "type": "profile_updated",
             "attrs": { "name": section_id,
                        "location": "Unknown" } } )}

      fired {
        raise sensor event "subscription"
            attributes{
                "eci":eci,
                "name":sensor_name
            }
      }
     }

    rule add_subscription{
        select when sensor subscription
            where event:attr("eci") && event:attr("name")
 
        pre{
            Tx = event:attr("eci")
            nm = event:attr("name")
            Tx_host = event:attr("host").defaultsTo(meta:host)
        }

        always{
            ent:sensor_list := sensors();
            ent:sensor_list{[Tx]} := {"sensor_name":nm,"status":"pending"};

            raise wrangler event "subscription"
                attributes{
                    "name":nm,
                    "Tx_host":Tx_host,
                    "wellKnown_Tx":Tx,
                    "Rx_role":"sensor_manager",
                    "Tx_role":"sensor",
                    "channel_type":"subscription"
                }
        }
    }

    rule finish_add_subscription{
        select when wrangler subscription_added
        pre{
            e = event:attrs().klog("Sub Added");
            Tx = event:attr("Tx").klog("Channel")
        }

        always{
            ent:sensor_list := sensors.put([Tx,"status"],"accepted")
        }
    }

    rule remove_sensor{
        select when sensor unneeded_sensor
            where event:attr("sensor_name")

        pre{
            sensor = event:attr("sensor_name")
            exists = wrangler:children(sensor)
            Tx = (exists => get_channel(sensor)| "None")
        }
        if exists then
            send_directive("deleting_section", {"section_id":sensor})
        fired {
          raise wrangler event "child_deletion"
            attributes {"name": sensor};
          ent:sensor_list := ent:sensor_list.delete(Tx)
        }
    }
}
