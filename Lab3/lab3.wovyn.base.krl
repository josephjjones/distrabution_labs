ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 2 Wovyn"
    }

    global{
        //send_info = defaction(genericInfo){
        //send_info(event:attr("genericThing"))
        //    //collects temperature and time stamp to send on
        //}
    }

    rule process_heartbeat{
        select when wovyn heartbeat where event:attr("genericThing")
        fired{
            raise explicit event "new_temperature_reading" attributes 
              {"temperature":event:attr("genericThing")("data")("temperature"),
               "time":time:now()};
            send_directive("heartbeat",event:attrs())
        }
    }

    rule read_temp{
        select when wovyn new_temperature_reading
        pre{
            i = event:attrs().klog("Read Temp ---->")
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
