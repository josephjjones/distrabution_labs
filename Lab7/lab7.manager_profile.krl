ruleset manager_profile{
    meta{
        author "Joseph Jones"
        use module twilio.keys
        use module twilio.methods alias twil
            with account_sid = keys:twilio{"account_sid"}
                 auth_token  = keys:twilio{"auth_token"}
    }

    global{
        getPhoneNumber = function(){
            {"number":ent:phone_number.defaultsTo("+1257634268")}
        };
        
        high_temp_message = function(temp, time){
            "At "+time+" temperature of "+temp.as("String")+" was read"
        };
        get_from = function(){
            ent:from.defaultsTo("+12567332433")
        };  
    }

    rule update_phone_number{
        select when sensor phone_updated
        if event:attr("number")
        then
            send_directive("updated",{"property":"number"})
        fired{
            ent:phone_number := event:attr("number")
        }
    }

    rule threshold_notification{
        select when wovyn threshold_violation
        twil:send_sms(getPhoneNumber()["number"], get_from(),
            high_temp_message(event:attr("temperature"), event:attr("time")))
    }

}
