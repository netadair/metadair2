--
-- MetAdair 2 
-- ESP8266-based wifi-connected meter reader for
--   Kamstrup/KMP
--   SML
--   D0
--   RS485/ModBus
--
-- 20180217 - Michael Rausch <mr@netadair.de> 
--

----------------------------------------------------------------------

--assert(loadfile("config.lua"))
require("config")

----------------------------------------------------------------------

-- set uart to defined start value and disable console    
uart.setup(0, UART_BAUD, UART_BITS, UART_PARITY, UART_STOP, 
 0 ) -- no echo

function skipdata (data) end

uart.on("data", 0, skipdata, 0) -- no run_input, for SML meter not to confuse lua

----------------------------------------------------------------------

-- blue gpio#2 on pin index 4
BLUE_LED_PIN = 4
-- red gpio#0 on pin index 3
RED_LED_PIN = 3

gpio.mode(RED_LED_PIN, gpio.OUTPUT)
gpio.write(RED_LED_PIN, gpio.HIGH) -- aus

gpio.mode(BLUE_LED_PIN, gpio.OUTPUT)
gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus

telnet_srv = nil
uart_srv   = nil
  
function breakoninterrupt(level, when)
    dofile("break.lc")
end

gpio.mode(RED_LED_PIN,gpio.INT)
gpio.trig(RED_LED_PIN, "up", breakoninterrupt)


redcnt=nil
bluecnt=nil

function blinkredled ()
  if redcnt==nil then
    redcnt = 0 -- beim ersten mal an
  end

  -- trigger on next level's change
  gpio.trig(RED_LED_PIN, (redcnt == 0) and "up" or "down", breakoninterrupt)
  
  gpio.write(RED_LED_PIN, redcnt)  
  redcnt = 1-redcnt
end

blinkredtmr = tmr.create()
blinkredtmr:alarm(500, tmr.ALARM_AUTO, blinkredled )

heartbeattmr = tmr.create()

ping_count=0
ping_failed=0
function external_ping()
    net.dns.resolve("localhost", function(sk, ip)
        if (ip == nil) then
            ping_failed=ping_failed+1
        else
            ping_failed=0
        end
    end)
end

function beep0()
    redcnt=1 -- mache es jetzt aus
    blinkredled()
    heartbeattmr:alarm(10 * 1000, tmr.ALARM_SINGLE, beep1 )

    -- hier könnte man noch den watchdog zurücksetzen!?
end
function beep1()

    blinkredled()
    heartbeattmr:alarm(70, tmr.ALARM_SINGLE, beep2 )    
end
function beep2()
    blinkredled()
    heartbeattmr:alarm(70, tmr.ALARM_SINGLE, beep3 )    
end
function beep3()
    blinkredled()

    if(ping_count==0) then external_ping() end
    
    -- watchdog check on wifi connection
    -- currentip, currentnm, currentgw = wifi.sta.getip()
    --if (wifi.sta.status() == wifi.STA_GOTIP and telnet_srv and uart_srv) then

    if (wifi.sta.status() == wifi.STA_GOTIP and ping_failed<3) then
        tmr.softwd(60)
    end

    ping_count=(ping_count+1) % 6
    
    heartbeattmr:alarm(140, tmr.ALARM_SINGLE, beep4 )    
end
function beep4()
    blinkredled()
    heartbeattmr:alarm(140, tmr.ALARM_SINGLE, beep0 )
end

----------------------------------------------------------------------

-- only once
if(wifi.getdefaultmode()~=wifi.NULLMODE) then wifi.setmode(wifi.NULLMODE, true) end

wifi.setmode(wifi.STATION, false)

wifi.setphymode(wifi.PHYMODE_G)

-- wifi.setmaxtxpower(max_tpw) -- max_tpw maximum value of RF Tx Power, unit: 0.25 dBm, range [0, 82]. 
        
wifi.sta.config({ssid=SSID, pwd=SSID_PASSWORD, save=false})

tmr.softwd(60)
--rebootnowlan = tmr.create()
--rebootnowlan:alarm(60 * 1000, tmr.ALARM_SINGLE, function()
--        node.restart()
--    end
--)

checkwlantimer = tmr.create()
checkwlantimer:alarm(500, tmr.ALARM_AUTO, function()
        if (wifi.sta.status() == wifi.STA_GOTIP) then

            tmr.softwd(-1)
            --rebootnowlan:unregister()
            --rebootnowlan = nil

            checkwlantimer:unregister()
            checkwlantimer = nil

             coroutine.resume(main_co)
        end
    end
)

----------------------------------------------------------------------

require("telnet_proto")

----------------------------------------------------------------------


function main()
----------------------------------------------------------------------

boottime = 0
dofile("ip_service_setup.lc")

----------------------------------------------------------------------

-- netzwerk ok: ap gefunden und ip per dhcp bekommen, mdns announce erfolgreich

blinkredtmr:unregister()
blinkredtmr = nil

gpio.trig(RED_LED_PIN, "none") -- will be re-enabled in the beep()s
gpio.write(RED_LED_PIN, gpio.HIGH) -- aus
redcnt=0

-- heart beat beaglebone style
beep0()

----------------------------------------------------------------------

-- arm system watchdog!
tmr.softwd(60)

-- save for later watchdog check
startip, startnm, startgw = wifi.sta.getip()
--boottime = rtctime.get()

----------------------------------------------------------------------


telnet_srv = net.createServer(net.TCP, 10)
uart_srv   = net.createServer(net.TCP, 10)

if telnet_srv and uart_srv then

global_telnet=nil

telnet_srv:listen(TELNET_PORT, function(socket)
    local socket=socket     
    local fifo = {}
    local fifo_drained = true

    -- interim, bis ausgabe-multiplexer da ist
    if global_telnet~=nil then

        global_telnet:on("receive", nil)
        global_telnet:on("sent", nil)
   
        local old_telnet = global_telnet
        global_telnet = socket
        old_telnet:close()
        
        old_telnet:on("disconnection", nil)
        old_telnet=nil
    end
    -- marks to not redirect node output to nirwana
    global_telnet = socket

    local function sender(sck)
        if #fifo > 0 then
            gpio.write(BLUE_LED_PIN, gpio.LOW) -- an
            --c:send(table.remove(fifo, 1))
            local cf=table.concat(fifo)
            fifo={}
            sck:send(cf)
            gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus
        else
            --gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus
            fifo_drained = true
        end
    end

    socket:on("sent", sender)

    local function s_output(str)
        table.insert(fifo, str)
        if socket ~= nil and fifo_drained then
            fifo_drained = false
            sender(socket)
        end
    end

    node.output(s_output, 0)   -- re-direct output to function s_ouput; last connection gets this output

    socket:on("receive", function(c, l)
        gpio.write(BLUE_LED_PIN, gpio.LOW) -- an
        
        if(l:find(string.char(IAC))~=nil) then
            handle_telnet(l, node.input, s_output, 1)
        else
            -- no escape, shortcut
            node.input(l)           -- works like pcall(loadstring(l)) but support multiple separate line
        end
        gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus
        end
    )
    socket:on("disconnection", function(sck, err)
        fifo=nil
        fifo_drained = nil
        -- only direct back if there is no fresh connetion sittig there just now
        if(global_telnet==sck) then
            node.output(nil)        -- un-regist the redirect output function, output goes to serial
            global_telnet = nil
        end
        collectgarbage()
        collectgarbage()
        end
    )

    --c:on("reconnection", ) -- ????
    --c:on("connection", ) -- ist für tcp client sockets?!

    heapsize=node.heap()

    local s,err = pcall(function() dofile("telnet_banner.lc") end)
    if not s then
       print("Error printing telnet banner:",err)
    end

    end
)

    function uartwrite(pl) uart.write(0,pl) end

    -- one global uart connection
    global_c = nil
    -- escape answers?
    uarthasrfc2217 = nil

    uart_srv:listen(UART_PORT, function(c)

            local fifo = {}
            local fifo_drained = true
    
            if global_c~=nil then   -- schliesse alte verbindung

                global_c:on("receive", nil)
                global_c:on("sent", nil)

                local c_c=global_c
                global_c:close()

                c_c:on("disconnection", nil)
                c_c=nil

                --c_c=global_c
                --global_c=c
                --node.task.post(node.task.MEDIUM_PRIORITY, function() c_c:close() c_c=nil end)
            end
            global_c=c
            uarthasrfc2217 = nil

            local function sender(sck)
                if #fifo > 0 then
                    gpio.write(BLUE_LED_PIN, gpio.LOW) -- an
                    --c:send(table.remove(fifo, 1))
                    local cf=table.concat(fifo) 
                    fifo={}
                    sck:send(cf)
                    gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus
                else
                    --gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus
                    fifo_drained = true
                end
            end

            local function fifo_output(str)
                table.insert(fifo, str)
                if c ~= nil and fifo_drained then
                    fifo_drained = false
                    sender(c)
                end
            end

            c:on("sent", sender)

            c:on("receive", function (sck,pl)
                    gpio.write(BLUE_LED_PIN, gpio.LOW) -- an

                    if(pl:find(string.char(IAC))~=nil) then
                        handle_telnet(pl, uartwrite , fifo_output, nil)
                    else
                        -- no escape, shortcut
                        uart.write(0,pl)
                    end
                                    
                    gpio.write(BLUE_LED_PIN, gpio.HIGH) -- aus            
                end
            )
            
            --c:on("reconnection", ) -- ????
            c:on("disconnection", function (sck, err)
                    fifo=nil
                    fifo_drained = nil

                    sck:on("receive", nil)
                    sck:on("sent", nil)
                    sck:on("disconnection", nil)

                    if(global_c==sck) then
                        --uart.on("data") -- reset old direction
                        uart.on("data", 0, skipdata, 0) -- no run_input, for SML meter not to confuse lua
                    end
                    global_c=nil
                    collectgarbage()
                    collectgarbage()
            end
            )
            --c:on("connection", ) -- ist für tcp client sockets?!

            uart.on("data") -- reset old direction

            local function uartdata(data) -- expects single chars
                   if global_c~=nil then
                        -- if telnet detected, escape answers as well
                        if (uarthasrfc2217 and string.byte(data) == IAC) then
                           fifo_output(data)
                           fifo_output(data)
                        else
                           fifo_output(data)
                        end
                   end
            end            
            uart.on("data", 0, uartdata, 0 -- no run_input
            )

        end
    )



else
    print("net.createServer failed")
end


-- warte auf connection, nach gewisser zeit restart?

----------------------------------------------------------------------
end -- main

main_co=coroutine.create(main)

----


