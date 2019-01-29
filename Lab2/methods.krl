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
        extra = "";
        extra = (to => "?To="+to | extra);
        extra = (from => "&From="+from | extra);
        extra = (page_size => (extra => "&"|"?")+"PageSize="+page_size | extra);
        extra = (page => (extra => "&"|"?")+"Page="+page | extra);
        extra = (page_uri => (extra => "&"|"?")+"PageToken="+page_uri | extra).klog("Extra: ");
        http:get(base_url+extra)
    }
    
  }

    rule finish_send_sms{
        select when http post label re#finish_send#
        //page information
        send_directive(event:attr("content"))
    }
  
}

