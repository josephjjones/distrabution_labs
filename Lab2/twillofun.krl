ruleset messenger{ 
  meta{
    author "Joseph Jones"
    name "Lab Two"
    use module twilio.keys
    use module twilio.methods alias twil
        with account_sid = keys:twilio{"account_sid"}
             auth_token  = keys:twilio{"auth_token"} 
  }

  global{
    
  }
    rule test_send_sms {
      select when test new_message
      twil:send_sms(event:attr("to"),
               event:attr("from"),
               event:attr("message"))
    }

    rule get_messages {
        select when fetch message
        pre{
        response = twil:get_sms(
                event:attr("from").defaultsTo(""),//"12567632433",
                event:attr("to").defaultsTo(""),
                event:attr("page").defaultsTo(""),
                event:attr("page_size").defaultsTo(""),
                event:attr("uri").defaultsTo(""))
        }
        send_directive("Twilio Messages", response{"content"}.decode())
    }
  
}

