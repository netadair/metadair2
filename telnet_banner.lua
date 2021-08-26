    do
       print("Welcome to NodeMCU on " .. wifi.sta.gethostname() .. " (" .. wifi.sta.getmac() .. ")")

        local now = rtctime.get()
        local tm = rtctime.epoch2cal(boottime)
        print(string.format("Boot: %04d-%02d-%02d %02d:%02d:%02d UTC", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
        tm = rtctime.epoch2cal(now)
        print(string.format("Time: %04d-%02d-%02d %02d:%02d:%02d UTC", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))

        print(string.format("Uptime: %d sec", now-boottime))

        print("Free heap memory: " .. heapsize)

        local sta_config=wifi.sta.getconfig(true)
        print(string.format("Connected AP: SSID:\"%s\" BSSID:\"%s\"", sta_config.ssid, sta_config.bssid))

        local RSSI=wifi.sta.getrssi()
        print("RSSI: " .. RSSI)
        print("> ")
        
    end
