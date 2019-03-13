ruleset sensor_profile{
    meta{
        author "Joseph Jones"
        provides getThresholds, getProfile, getPhoneNumber
        shares getThresholds, getProfile, getPhoneNumber, getSensor

    }
    global{
        getThresholds = function(){
            {"min": ent:min_threshold.defaultsTo(60),
             "max": ent:max_threshold.defaultsTo(90)}
        };

        getProfile = function(){
            {"name":ent:sensor_name.defaultsTo("Wovyn Sensor"),
             "location":ent:location.defaultsTo("home")}
        };

        getPhoneNumber = function(){
            {"number":ent:phone_number.defaultsTo("+12567634268")}
        };

        getSensor = function(){
            getThresholds().put(getProfile()).put(getPhoneNumber())
        };
    }

    rule update_profile{
        select when sensor profile_updated 
        if event:attr("location") && event:attr("name")
        then
            send_directive("updated",{"property":"profile"})

        fired{
            ent:location := event:attr("location");
            ent:sensor_name := event:attr("name")
        }
    }

    rule update_thresholds{
        select when sensor threshold_updated
        pre{
            new_min = (event:attr("min") => event:attr("min") | 
                                            ent:min_threshold)
            new_max = (event:attr("max") => event:attr("max") | 
                                            ent:max_threshold)
        }

        always{
            ent:min_threshold := new_min;
            ent:max_threshold := new_max
        }
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

    rule autoAccept {
      select when wrangler inbound_pending_subscription_added
      pre{
        attributes = event:attrs().klog("subcription :");
      }
      always{
        raise wrangler event "pending_subscription_approval"
            attributes attributes;       
        log info "auto accepted subcription.";
      }
    }
}
