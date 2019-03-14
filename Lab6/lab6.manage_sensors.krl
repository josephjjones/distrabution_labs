ruleset manage_sensors{
    meta{
        author "Joseph Jones"
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias Subscriptions
        shares sensors, all_temperatures, channels
        provides sensors, all_temperatures, channels
    }

    global{
        sensors = function(){
            //list of subscriptions by name
            ent:sensor_list.defaultsTo({})
        };
        channels = function(){
            //provides map from Tx channels to sensor names
            ent:channel_list.defaultsTo({})
        };
        all_temperatures = function(){
            Subscriptions:established().filter(
                function(v){
                    v.get("Tx_role") == "sensor"
                }
            ).map(
                function(v){
                    sensor_name = channels().get(v.get("Tx"));
                    temperatures = wrangler:skyQuery(v.get("Tx"),"temperature_store","temperatures",{});
                    {"sensor_name":sensor_name,"temperatures":temperatures}
                }
            )
        };
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
      if sensor_name
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
            ent:sensor_list := sensors().put(nm, {"eci":Tx,"status":"pending"});
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
            Tx = event:attr("Tx").klog("Channel")
            nm = event:attr("name").klog("Name")
        }

        always{
            ent:sensor_list := sensors().put(nm, {"eci":Tx,"status":"accepted"});
            ent:channel_list := channels().put(Tx, nm)
        }
    }

    rule remove_sensor{
        select when sensor unneeded_sensor
            where event:attr("sensor_name")
        pre{
            sensor = event:attr("sensor_name")
            exists = wrangler:children(sensor)
        }
        if exists then
            send_directive("deleting_section", {"section_id":sensor})
        fired {
          raise wrangler event "child_deletion"
            attributes {"name": sensor};
        }
    }
}
