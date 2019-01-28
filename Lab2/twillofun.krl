ruleset messenger{ 
  meta{
    author "Joseph Jones"
    name "Lab Two"
  }

  global{
    //Things defined here are static/cannot be mutated
    my_name = "Joseph J Jones"

    send_sms = defaction(to, from, message, account_sid, auth_token){
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
      http:post(base_url + "Messages.json", form =
                {"From":from,
                 "To":to,
                 "Body":message
                })
    }
    
  }
    rule test_send_sms {
      select when test new_message
      send_sms(event:attr("to"),
               event:attr("from"),
               event:attr("message"),
               event:attr("account_sid"),
               event:attr("auth_token"))
    }
  
}

