ruleset temperature_store{
    meta{
        author "Joseph Jones"
        name "Lab 4 Persistance"
        use module wovyn_base
        use module sensor_profile
//Add a provides pragma to the meta block of the temperature_store ruleset 
//that lists the three functions.
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
//Also add a shares pragma to the meta block with the same list of functions.

    }

    global{

//A function called temperatures that 
//    returns the contents of the temperature entity variable.
        temperatures = function(){
            ent:temperature_list.defaultsTo([])
        }

//A function called threshold_violations that 
//    returns the contents of the threshold violation entity variable.
        threshold_violations = function(){
            ent:violations_list.defaultsTo([])
        }

//A function called inrange_temperatures that 
//    returns all the temperatures in the temperature entity variable
//     that aren't in the threshold violation entity variable.
//    (Note: I expect you to solve this without adding a rule 
//        that collects in-range temperatures)
        inrange_temperatures = function(){
            temperatures().filter(function(x){
                x["temperature"] < sensor_profile:getThresholds()["max"] &&
                x["temperature"] > sensor_profile:getThresholds()["min"]
            })
        }

    }

//A rule named collect_temperatures 
//    that looks for wovyn:new_temperature_reading events 
//    and stores the temperature and timestamp event attributes 
//        in an entity variable. 
//    The entity variable should contain all the temperatures 
//        that have been processed.
    rule collect_temperatures{
        select when wovyn new_temperature_reading
        always{
            ent:temperature_list := [event:attrs].append(temperatures())
        }
    }


//A rule named collect_threshold_violations
//     that looks for wovyn:threshold_violation events
//     and stores the violation temperature
//     and a timestamp in a different entity variable
//         that collects threshold violations.
    rule collect_threshold_violations{
        select when wovyn threshold_violation
        fired{
            ent:violations_list := [event:attrs].append(threshold_violations())
        }
    }

//A rule named clear_temeratures 
//    that looks for a sensor:reading_reset event 
//    and resets both of the entity variables from the rules in (1) and (2).
    rule clear_temeratures{
        select when sensor reading_reset
        always{
            ent:temperature_list := [];
            ent:violations_list := []
        }
    }

}
