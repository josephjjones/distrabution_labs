ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 2 Wovyn"
    }

    global{

    }

    rule process_heartbeat{
        select when wovyn heartbeat
        send_directive("heartbeat",event:attrs())
    }


}
