ruleset manage_sensors{
    meta{
        author "Joseph Jones"
        use module io.picolabs.wrangler alias wrangler
        shares sensors, all_temperatures
        provides sensors, all_temperatures
    }

    global{
        sensors = function(){
            ent:sensors.defaultsTo({})
        }
        all_temperatures = function(){
            sensors().map(function(v,k){
              wrangler:skyQuery(v.get("eci"),"temperature_store","temperatures",{})
            })
        }
        nameFromID = function(section_id) {
          "Section " + section_id + " Pico"
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
                attributes { "name": nameFromID(sensor),
                             "color": "#fe50d2",
                             "section_id": sensor,
                             "rids": ["temperature_store",
                                      "wovyn_base",
                                      "sensor_profile",
                                      "twilio.keys",
                                      "twilio.methods"] }
        }
    }

    rule store_new_section {
      select when wrangler child_initialized
      pre {
        the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
        section_id = event:attr("rs_attrs"){"section_id"}
      }
      if section_id.klog("found section_id")
      then every{
        send_directive("Status",{"new_sensor":"Created new Sensor"});
        event:send(
           { "eci": the_section{"eci"}, "eid": "parent",
             "domain": "sensor", "type": "profile_updated",
             "attrs": { "name": section_id,
                        "location": "Unknown" } } )}

      fired {
        ent:sensors := sensors();
        ent:sensors{[section_id]} := the_section
      }
    }

    rule remove_sensor{
        select when sensor unneeded_sensor
            where event:attr("sensor_name")

        pre{
            sensor = event:attr("sensor_name")
            exists = sensors() >< sensor
            child = nameFromID(sensor)
        }
        if exists then
            send_directive("deleting_section", {"section_id":sensor})
        fired {
          raise wrangler event "child_deletion"
            attributes {"name": child};
          ent:sensors := ent:sensors.delete(sensor)
        }

    }
}
