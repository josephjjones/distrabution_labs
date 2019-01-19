ruleset lab_one{ 
  meta{
    author "Joseph Jones"
    name "Lab One"
    shares hello
  }

  global{
    //Things defined here are static/cannot be mutated
    my_name = "Joseph J Jones"

    hello = function(nam){
        msg = "Hello " + nam + "!";
        msg
    }
    
  }

  rule hello_world{
    select when echo hello
    pre{
        nam = event:attr("name")
        nam = nam => nam | "World";
    }
    send_directive("say", {"something": hello(nam)})
  }
    
  rule hello_monkey{
    select when echo monkey
    pre{
        nam = event:attr("name").defaultsTo("Monkey").klog("Name is ")
        //nam = nam => nam | "Monkey";
    }
    send_directive("say", {"something": hello(nam)})
  }
  
}

