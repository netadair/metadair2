--
-- restart the MetAdair2 code unless external reset was pressed
--

----------------------------------------------------------------------

-- "shell" commands

--[[
function listap()
  dofile("list_ap.lua")
end

function reset()
  node.restart()
end

function free()
  print(node.heap())
end
--]]

function f() -- feeddog
  tmr.softwd(-1)
end

--[[
function c() -- compile
  node.compile("telnet_banner.lua")
  node.compile("telnet_proto.lua")
  node.compile("ip_service_setup.lua")
  node.compile("metadair2.lua")  
end
--]]

----------------------------------------------------------------------

do
    local _, reset_reason = node.bootreason()
    tmr.softwd(30)
    if reset_reason ~= 6 then 
        local cleanlua = tmr.create()        
        cleanlua:alarm(500, tmr.ALARM_SINGLE, function() 
            local s,err = pcall(function() dofile("metadair2.lc") end)
            if not s then
                print("Error:",err)
                node.restart()
            else
                tmr.softwd(-1)
            end
        end)
    else
      print("Not booting MetAdair2, boot reason",reset_reason)
      print("f() feeddog within 30 seconds to prevent watchdog reboot")
    end
end



