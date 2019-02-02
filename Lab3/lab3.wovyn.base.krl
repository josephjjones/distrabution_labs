ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 3 Wovyn"
//        use module twilio.keys
//        use module twilio.methods alias twil
//            with account_sid = keys:twilio{"account_sid"}
//                 auth_token  = keys:twilio{"auth_token"}
    }

    global{
        //ent:temperature_threshold := 100.0
        //ent:to := "+12567634268"
        //ent:from := "+12567332433"
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
            i = event:attrs().klog("Read Temp ---->")
        }
        send_directive("reading",{"Temp_and_Time":event:attrs()})
        fired{
        }
    }

    rule find_high_temps{
        select when wovyn new_temperature_reading
        
        fired{
            raise wovyn event "threshold_violation" attributes event:attrs()
                if ent:temperature_threshold < event:attr("temperature")
        }
    }

    rule threshold_notification{
        select when wovyn threshold_violation
 //       twil:send_sms(ent:to, ent:from, high_temp_message(
  //          event:attr("tempurature"), event:attr("time")))
    }
}
