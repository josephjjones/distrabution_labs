ruleset lab_one{ 
  meta{
    author "Joseph Jones"
    shares getEntries
    shares hello
  }

  global{
    //Things defined here are static/cannot be mutated
    my_name = "Joseph J Jones"
    getEntries = function(){
      ent:entries.defaultsTo([])
    }

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
    
  
  rule createEntry{
    select when journal new_entry
    pre {
      text = event:attr("text")
      currentTime = time:now()
      newEntry = {
        "text" : text,
        "time" : currentTime
      }
    }
    if text then
      send_directive("Creating new journal entry!")
      
    fired {
      ent:entries := getEntries().append([newEntry])
    }else {
      //do nothing
    }
  }
  
  rule trimEntry{
    select when journal new_entry
    if getEntries().length() > 8 then
      send_directive("Trimming")
    fired{
      ent:entries := getEntries().tail()
    }
  }
  
  rule clearEntries {
    select when journal clear_entries_requested
    send_directive("Clearing entries!")
    always{
      clear ent:entries
    }
  }
  
}

