ruleset gossip{

  meta{
    author "Joseph Jones"
    provides get_gossip
    shares get_gossip
  }

  global{

    get_gossip = function(){
        ent:gossip_messages.encode(2)
    }

    seen_messages = function(){
      ent:gossip_meesages.map(function(v,k){
        v.get("seen")
      })
    }

    getPeer = function(){
      my_seen = seen_messages();
      need = ent:peers.filter(function(v,k){
          their_seen = v.get("seen");
          they_need = my_seen.filter(function(v,k){
            v > their_seen.get(k).defaultsTo(-1)});
          (they_need => True | False)
        });
      need = need.keys(); //get only the sensor id
      need.index(random:integer(need.length()-1))
    }

    prepareMessage = function(peer){
      their_seen = ent:peers.get([peer,"seen"]);
      my_seen = seen_messages();
      need = my_seen.filter(
               function(v,k){ v > their_seen.get(k).defaultsTo(-1) });
      k = need.keys();
      from = k.index(random:integer(k.length()-1));
      last_seen = their_seen.get(from);
      gossip_messages().get([from,"messages"]).filter(function(v){
            v.get("sequence") > last_seen
        })
    }

    send_rumors = defaction(peer, m){
      event:send({
        "eci":ent:peers{[peer,"eci"]},
        "host":ent:peers{[peer,"host"]},
        "eid":meta:picoID,
        "domain":"gossip","type":"rumor",
        "attrs": {"rumors":m,"sensorID":meta:picoID}
        })
    }
    send_seen = defaction(peer, extra){
      event:send({
        "eci":ent:peers{[peer,"eci"]},
        "host":ent:peers{[peer,"host"]},
        "eid":meta:picoID,
        "domain":"gossip","type":"seen",
        "attrs": {"seen":seen_messages(),"sensorID":meta:picoID}
        })
    }

  }

  rule init{
    select when wrangler ruleset_added
      where event:attr("rids") >< meta:rid
   
    if ent:peers.isnull()
    then
        noop()

    fired{
      ent:gossip_role := "gossip_partner"; //subscription role
      ent:period := 5; //in seconds
      ent:is_on  := True;
      ent:sequence_number := 0;
      ent:gossip_messages := {};
      ent:peers := {};
    }finally{
      raise gossip event "heartbeat"
        attributes {}
    }
  }

  rule gossip_heartbeat{
    select when gossip heartbeat
    pre{
      peer = (ent:is_on => getPeer().klog("peer") | False);
      action = (peer => send_rumors | send_seen) //could change to be random
      m = (peer => prepareMessage(peer) | []);
      from = (peer => m.index(0){"sensorID"} | "bogus");
      last_seen = (peer => ent:peers{[peer,"seen",from]} | -1);
      peer = (peer => peer | random_peer());
      last_seen =
        m.map(function(v){v.get("sequence")})
         .sort("numeric")
         .reduce(function(a,b){(b==a+1 => b | a)},
                 last_seen)
    }
    if ent:is_on
    then
      action(peer, m);

    fired{
      //make asumption until a seen message updates
      ent:peers{[peer,"seen",from]} := last_seen
    }finally{
      schedule gossip event "heartbeat"
        at time:add(time:now(), {"seconds": 5})
        attributes event:attrs
    }
  }

  rule gossip_message{
    select when gossip rumor
        //where from_peer
        foreach event:attr("rumors") setting(rumor)
    pre{
        from = rumor{"sensorID"};
        is_old = ent:gossip_messages{[from,"messages"]}.reduce(
            function(a,b){a || (b{"messageID"} == rumor{"messageID"})},
            False);
    }

    if not is_old
    then noop()

    fired{
      ent:gossip_messages{[from,"messages"]} := 
        ent:gossip_messages{[from,"messages"]}.append(rumor)
    }finally{
      raise gossip event "update"
        attributes {"sensor":from} on final
    }

  }

  rule gossip_message_update{
    select when gossip rumor
      where ent:peers >< event:attr("sensorID")

    pre{
      peer = event:attr("sensorID")
      m = event:attr("rumors")
      from = m.index(0){"sensorID"} //origin of the rumors
      last_seen = 
        m.map(function(v){v.get("sequence")})
         .sort("numeric")
         .reduce(function(a,b){(b==a+1 => b | a)},
                 ent:peers{[peer,"seen",from]})
    }

    always{
      ent:peers{[peer,"seen",from]} := last_seen
    }
  }

  rule gossip_update{ //called after a gossip message is recieved
    select when gossip update
        where event:attr("sensor")
    pre{
      from = event:attr("sensor")
      last_seen = ent:gossip_messages{[from,"messages"]}
                  .map(function(v){ v.get("sequence") })
                  .sort("numeric")
                  .reduce(
                      function(a,b){ (b == a+1 => b | a) },
                      ent:gossip_messages{[from,"seen"]})
    }

    always{
      ent:gossip_messages{[from,"seen"]} := last_seen
    }
  }

  rule gossip_seen{
    select when gossip seen
        where event:attr("sensorID") >< ent:peers
    pre{
        sensor = event:attr("sensorID")
    }

    always{
        ent:peers{[sensor,"seen"]} := event:attr("seen")
    }
  }

  rule new_temp_check{
    select when wovyn new_temperature_reading
    pre{
        new_rumor = 
            {"messageID": random:uuid(),
             "sequence": ent:sequence_number,
             "sensorID": meta:picoID,
             "message": event:attrs}
        in_gossip = gossip_messages() >< meta:picoID
    }
    if in_gossip
    then
        noop()

    fired{
      ent:gossip_messages{[meta:picoID,"seen"]} := ent:sequence_number;
      ent:gossip_messages{[meta:picoID,"messages"]} := 
        ent:gossip_messages.get([meta:picoID,"messages"]).append(new_rumor)
    }else{
        ent:gossip_messages{meta:picoID} :=
            {"seen":0, "messages":[new_rumor]}
    }finally{
      ent:sequence_number := sequence_number()+1
    }
  }

  rule add_peer{
    select when gossip add_peer
        where event:attr("eci") && event:attr("host")

    always{
      raise wrangler event "subscription"
        attributes{
          "name":meta:picoID,
          "Tx_host":event:attr("host"),
          "wellKnown_Tx":event:attr("eci"),
          "Rx_role":ent:gossip_role,
          "Tx_role":ent:gossip_role,
          "channel_type":"subscription"
        }
    }
  }

 rule new_peer_detected{
    select when wrangler subscription_added
        where event:attr("Rx_role") == ent:gossip_role

    pre{
      eci = event:attr("Tx");
      host = event:attr("Tx_host")
    }

    event:send({
        "eci"   : eci,
        "host"  : host,
        "eid"   : meta:picoID,
        "domain": "gossip","type":"new_peer",
        "attrs" : {
            "id"  :meta:picoID,
            "eci" :event:attr("Rx"),
            "host":event:attr("Rx_host"),
            "seen":seen_messages()}
        })
  }

  rule new_peer{
    select when gossip new_peer
    //this will also clear any memory of seen
    pre{ 
      sensorID = event:attr("id")
      newPeer = {
        "eci":event:attr("eci"),
        "host":event:attr("host"),
        "seen":event:attr("seen").put("bogus",-1)
        }
    }

    always{
      ent:peers{sensorID} := newPeer
    }
  }

}
