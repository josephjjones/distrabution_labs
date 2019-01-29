ruleset twilio.methods{ 
  meta{
    author "Joseph Jones"
    name "Lab Two"
    configure using acount_sid = ""
                    auth_token = ""

    provides
        send_sms, get_sms 
  }
    //, autoraise = "twillio_response"
    //select when http post label re#asdfasdfasdf#
    //page information
  global{
    //Things defined here are static/cannot be mutated
    send_sms = defaction(to, from, message){
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
      http:post(base_url + "Messages.json", form =
                {"From":from,
                 "To":to,
                 "Body":message
                }, autoraise = "finish_send")
    }

    get_sms = function(from, to, page, page_size, page_uri){
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>;
        http:get(base_url, form = 
            {"From":from,
             "To":to,
             "Page":page,
             "PageSize":page_size,
             "uri":page_uri})
    }
    
  }

    rule finish_send_sms{
        select when http post label re#finish_send#
        //page information
        send_directive(event:attr("content"))
    }
  
}

