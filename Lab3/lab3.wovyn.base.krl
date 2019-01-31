ruleset wovyn_base{
    meta{
        author "Joseph Jones"
        name "Lab 2 Wovyn"
    }

    global{

    }

    rule process_heartbeat{
        select when wovyn heartbeat where event:attr("genericThing")
        send_directive("heartbeat",event:attrs())
    }

    rule hello_world{
        select when echo hello
        pre{
            nam = event:attr("name").defaultsTo("World")
        }
        send_directive("say", {"something": "Hello " + nam + "!"})
    }
}
