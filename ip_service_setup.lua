
-- uhrzeit synchen über ntp-anycast

--sntp.sync("224.0.1.1",
sntp.sync(net.dns.getdnsserver(0), -- ugly workaround and constraint

    -- async!
  function(sec, usec, server, info)
    --print('NTP sync', sec, usec, server)
    boottime = sec -- rtctime.get()
  end,
  function()
   --print('NTP sync failed!')
  end
  -- ,1 -- repeat all over
)

-- per mdns announcen
do
    local mdns_location="Meter cabinet"
    local hostname=wifi.sta.gethostname()
    -- mdns.register(hostname, { description=hostname, service="telnet", port=TELNET_PORT, location=mdns_location } ) -- doesnt support two services at the same time
    mdns.register(hostname, { description=hostname, service="uart",   port=UART_PORT,   location=mdns_location } )
end
