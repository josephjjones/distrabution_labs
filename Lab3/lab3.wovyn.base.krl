ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 2 Wovyn"
    }

    global{
        get_max_temp = function(){
            ent:max_temp.defaultsTo(-400.0)
        }
    }

    rule process_heartbeat{
        select when wovyn heartbeat where event:attr("genericThing")
        send_directive("heartbeat",{"event":"recieved heartbeat"})
        fired{
            raise wovyn event "new_temperature_reading" attributes 
              {"temperature":event:attr("genericThing")["data"]
                                ["temperature"]["temperatureF"],
               "time":time:now()}
        }
    }

    rule read_temp{
        select when wovyn new_temperature_reading
        pre{
            i = event:attrs().klog("Read Temp ---->")
        }
        send_directive("reading",{"Temp_and_Time":event:attrs()})
        fired{
        }
    }

    rule check_max_temp{
        select when wovyn new_temperature_reading
        fired{
            ent:max_temp :=(get_max_temp() > event:attr("tempurature") =>
                        get_max_temp() | 
                        event:attr("tempurature"))
        }
    }

    rule hello_world{
        select when echo hello
        pre{
            nam = event:attr("name").defaultsTo("World")
        }
        send_directive("say", {"something": "Hello " + nam + "!"})
    }
}
