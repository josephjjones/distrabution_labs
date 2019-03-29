ruleset gossip{

    meta{
        author "Joseph Jones"
    }

    rule init{
        select when wrangler ruleset_added
            where event:attr("rids") >< meta:rid
        
        always{
            raise gossip event "heartbeat"
                attributes {}
        }
    }

    rule heartbeat{
        select when gossip heartbeat

        always{
            schedule gossip event "heartbeat"
                at time:add(time:now(), {"seconds": 5})
                attributes event:attrs
        }
    }

}
