ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 3 Wovyn"
        provides get_threshold
        use module sensor_profile
        use module io.picolabs.subscription alias Subscriptions
    }
 
    global{
        check_threshold = function(temp){
            temp < sensor_profile:getThresholds()["max"] &&
            temp > sensor_profile:getThresholds()["min"]
        }
        get_threshold = function(){
            ent:temperature.defaultsTo(100.0)
        }
        get_from = function(){
            ent:from.defaultsTo("+12567332433")
        }
        high_temp_message = function(temp, time){
            "At "+time+" temperature of "+temp.as("String")+" was read"
        }
    }

    rule process_heartbeat{
        select when wovyn heartbeat where event:attr("genericThing")
            foreach event:attr("genericThing")["data"]["temperature"]
                setting(temp)
        pre{
        }
        every{
            send_directive("heartbeat",{"event":"Recieved heartbeat"})
        }
        fired{
            raise wovyn event "new_temperature_reading" attributes 
              {"temperature":temp["temperatureF"],
               "time":time:now()}
        }
    }

    rule read_temp{
        select when wovyn new_temperature_reading
        pre{
            i = event:attrs.klog("Read Temp ---->")
        }
        send_directive("reading",{"Temp_and_Time":event:attrs})
        fired{
        }
    }

    rule find_high_temps{
        select when wovyn new_temperature_reading
        pre{
            directive_message = 
                 (check_threshold(event:attr("temperature")) => 
                    "Safe temperature" | "Warning unsafe temperature detected")
        }
        send_directive("safety",{"rating":directive_message})
        fired{
            raise wovyn event "threshold_violation" attributes event:attrs
                if not check_threshold(event:attr("temperature"))
        }
    }

    rule threshold_notification{
        select when wovyn threshold_violation
            foreach Subscriptions:established().filter(
                function(v){ v.get("Tx_role") == "sensor_manager" }).map(
                function(v){ v.get("Tx") })
                    setting(Tx)
        event:send(
            { "eci":Tx, "eid":"threshold",
              "domain": "sensor", "type": "threshold_violation",
              "attrs": event:attrs })
    }
}
