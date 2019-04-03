ruleset gossip{

  meta{
    author "Joseph Jones"
    provides get_gossip, get_peers
    use module io.picolabs.subscription alias Subscriptions
    shares get_gossip, get_peers
  }

  global{

    get_gossip = function(){
      //just sequence numbers
      ent:gossip_messages.map(function(v,k){
        v.get("messages").map(function(v){v.get("sequence")}).encode()}).encode(8);
      
      //whole message
      // ent:gossip_messages.map(function(v,k){v{"messages"}.encode()}).encode(8)
        
        
    }
    
    get_peers = function(){
        ent:peers.map(function(v,k){v.get("seen").encode()}).encode(8)
    }

    seen_messages = function(){
      ent:gossip_messages.map(function(v,k){
        v.get("seen")
      })
    }

    getPeer = function(){
      my_seen = seen_messages();
      need = ent:peers.filter(function(v,k){
          their_seen = v.get("seen");
          they_need = my_seen.filter(function(v,k){
            (not v.isnull() => v > their_seen.get(k).defaultsTo(-1) | false)});
          (they_need.length() => true | false)
        });
      sensor = need.keys().klog("peers_that_need"); //get only the sensor id
      (sensor.length() => sensor[random:integer(sensor.length()-1)] | false)
    }
    
    random_peer = function(){
      (ent:peers.length() => ent:peers.keys()[random:integer(ent:peers.length()-1)] | false)
    }

    prepareAllMessages = function(their_seen){
      my_seen = seen_messages();
      need = my_seen.filter(
               function(v,k){ v.as("Number") > their_seen{k}.defaultsTo(-1).as("Number") });
      from = need.keys();
      from.map(function(v){
        last_seen = their_seen{v}.defaultsTo(-1).as("Number");
        ent:gossip_messages.get([v,"messages"]).filter(function(v){
              (v.length() => v.get("sequence").as("Number") > last_seen | false)
          })
      }).klog("all messages")
    }
    
    prepareMessage = function(peer){
      // all_rumors = prepareAllMessages(ent:peers.get([peer,"seen"])) //alt way decided against
      
      their_seen = ent:peers{[peer,"seen"]}.defaultsTo({});
      my_seen = seen_messages();
      need = my_seen.filter(
               function(v,k){ v.as("Number") > their_seen{k}.defaultsTo(-1).as("Number") });
      k = need.keys();
      from = k[random:integer(k.length()-1)];
      last_seen = their_seen{from}.defaultsTo(-1).as("Number");
      ent:gossip_messages.get([from,"messages"]).filter(function(v){
            (v.length() => v.get("sequence").as("Number") > last_seen | false)
        })
    }

    send_rumors = defaction(peer, m){
      event:send({
        "eci":ent:peers{[peer,"eci"]},
        "host":ent:peers{[peer,"host"]},
        "eid":meta:picoId,
        "domain":"gossip","type":"rumor",
        "attrs": {"rumors":m,"sensorID":meta:picoId}.klog("rumor attrs")
        })
    }
    
    send_seen = defaction(peer){
      event:send({
        "eci":ent:peers{[peer,"eci"]},
        "host":ent:peers{[peer,"host"]},
        "eid":meta:picoId,
        "domain":"gossip","type":"seen",
        "attrs": {"seen":seen_messages(),"sensorID":meta:picoId}.klog("seen attrs")
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
      raise gossip event "destroy"
        attributes {}
    }finally{
      raise gossip event "heartbeat"
        attributes {}
    }
  }

  rule gossip_heartbeat{
    select when gossip heartbeat
    pre{
      peer = (ent:is_on => getPeer() | false);
      rumors = (peer => prepareMessage(peer) | []);
      from = (peer => rumors[0]{"sensorID"} | null);
      last_seen =
        rumors.map(function(v){v.get("sequence")})
              .sort("numeric")
              .reduce(function(a,b){(b==a+1 => b | a)},
                      ent:peers{[peer,"seen",from]}.defaultsTo(-1))
    }
    if ent:is_on && peer
    then
      send_rumors(peer, rumors);

    fired{
      ent:peers{[peer,"seen",from]} := last_seen
    }else{
      raise gossip event "send_seen"
    }finally{
      schedule gossip event "heartbeat"
        at time:add(time:now(), {"seconds": ent:period})
        attributes event:attrs
    }
  }
  
  rule send_seen_set{
    select when gossip send_seen
    pre{
      peer = random_peer();
    }
    if ent:is_on && peer
    then
      send_seen(peer);
  }

  rule gossip_message{
    select when gossip rumor
        where ent:is_on
        foreach event:attr("rumors") setting(rumor)
    pre{
        from = rumor{"sensorID"};
        is_old = ent:gossip_messages{[from,"messages"]}.reduce(
            function(a,b){a || (b{"messageID"} == rumor{"messageID"})},
            false);
        messages = (ent:gossip_messages{[from,"messages"]} => 
                      ent:gossip_messages.get([from,"messages"]).append(rumor) | 
                      [rumor] )
    }

    if not is_old
    then noop()

    fired{
      ent:gossip_messages{[from,"messages"]} := messages
    }finally{
      raise gossip event "update"
        attributes {"sensor":from} on final
    }

  }

  rule gossip_message_update{
    select when gossip rumor
      where ent:is_on && ent:peers >< event:attr("sensorID")

    pre{
      peer = event:attr("sensorID")
      m = event:attr("rumors")
      from = m[0]{"sensorID"} //origin of the rumors
      last_seen = 
        m.map(function(v){v.get("sequence")})
         .sort("numeric")
         .reduce(function(a,b){(b==a+1 => b | a)},
                 ent:peers{[peer,"seen",from]}.defaultsTo(-1))
    }
    
    if ent:peers >< peer
    then
      noop()

    fired{
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
                      ent:gossip_messages{[from,"seen"]}.defaultsTo(-1))
    }

    always{
      ent:gossip_messages{[from,"seen"]} := last_seen
    }
  }

//add functionality where all messages that you know are sent
  rule gossip_seen{
    select when gossip seen
        where ent:is_on && ent:peers >< event:attr("sensorID")
    pre{
        sensor = event:attr("sensorID")
        rumors = prepareAllMessages(event:attr("seen"))
    }

    always{
        ent:peers{[sensor,"seen"]} := event:attr("seen");
        raise gossip event "send_rumor_group"
          attributes {"peer":sensor,"rumors":rumors}
    }
  }
  
  rule send_rumor_group{
    select when gossip send_rumor_group
      foreach event:attr("rumors") setting(rumors)
    
    pre{
      peer = event:attr("peer");
      from = rumors[0]{"sensorID"};
      last_seen =
        rumors.map(function(v){v.get("sequence")})
         .sort("numeric")
         .reduce(function(a,b){(b==a+1 => b | a)},
                 ent:peers{[peer,"seen",from]}.defaultsTo(-1))
    }
    
    if ent:is_on
    then
      send_rumors(peer, rumors)
    
    fired{
      ent:peers{[peer,"seen",from]} := last_seen
    }
  }

  rule new_temp_check{
    select when wovyn new_temperature_reading
    pre{
        new_rumor = 
            {"messageID": random:uuid(),
             "sequence": ent:sequence_number,
             "sensorID": meta:picoId,
             "message": event:attrs}
        in_gossip = ent:gossip_messages >< meta:picoId
    }
    if in_gossip
    then
        noop()

    fired{
      ent:gossip_messages{[meta:picoId,"seen"]} := ent:sequence_number;
      ent:gossip_messages{[meta:picoId,"messages"]} := 
        ent:gossip_messages.get([meta:picoId,"messages"]).append(new_rumor)
    }else{
        ent:gossip_messages{meta:picoId} :=
            {"seen":0, "messages":[new_rumor]}
    }finally{
      ent:sequence_number := ent:sequence_number+1
    }
  }
  
  rule gossip_settings{
    select when gossip settings
    pre{
      is_on = (event:attr("is_on") => event:attr("is_on") == "true" | ent:is_on);
      period = (event:attr("period") => event:attr("period").as("Number") | ent:period)
    }
    
    always{
      ent:is_on := is_on;
      ent:period := period
    }
  }

  rule add_peer{
    select when gossip add_peer
        where event:attr("eci") && event:attr("host")

    fired{
      raise wrangler event "subscription"
        attributes{
          "name":meta:picoId,
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
      eci = event:attr("bus"){"Tx"};
      host = event:attr("bus"){"Tx_host"}
    }

    event:send({
        "eci"   : eci,
        "host"  : host,
        "eid"   : "gossip_ruleset",
        "domain": "gossip","type":"new_peer",
        "attrs" : {
            "id"  :meta:picoId,
            "eci" :event:attr("bus"){"Rx"},
            "host":meta:host,
            "seen":seen_messages()}.klog("new peer attr")
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
        "seen":event:attr("seen")
        }
    }
    
    always{
      ent:peers{sensorID} := newPeer
    }
  }

  rule clear_everything{
    select when gossip destroy

    fired{
      ent:gossip_role := "gossip_partner"; //subscription role
      ent:period := 2; //in seconds
      ent:is_on  := true;
      ent:sequence_number := 0;
      ent:gossip_messages := {};
      ent:peers := {};
      raise gossip event "remove_peers"
        attributes {}
    }
  }

  rule clear_peers{
    select when gossip remove_peers
      foreach Subscriptions:established().filter(function(v){v.get("Tx_role") == ent:gossip_role}) setting (peer)

    fired{
      raise wrangler event "subscription_cancellation"
        attributes {"Rx":peer{"Rx"},"Tx":peer{"Tx"}}
    }
  }
  rule clear_nonpeers{
    select when gossip remove_peers
      foreach Subscriptions:outbound() setting(peer)

    fired{
      raise wrangler event "outbound_cancellation"
        attributes {"Id":peer{"Id"}}
    }
  }
}
