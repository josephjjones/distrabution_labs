ruleset sensor_profile{
    meta{

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
        when (event:attr("location") && event:attr("name"))

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
        when (event:attr("number"))
        fired{
            ent:phone_number := event:attr("number")
        } 
    }
}
