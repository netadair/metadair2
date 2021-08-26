
do

if(wifi.getmode()~=wifi.STATION) then wifi.setmode(wifi.STATION, false) end

  -- Print AP list that is easier to read
  local function list_ap(t) -- (SSID : Authmode, RSSI, BSSID, Channel)
  
local authmodemapping={
[tostring(wifi.OPEN)]        ="OPEN        ",
["1"]                        ="WEP         ",
[tostring(wifi.WPA_PSK)]     ="WPA_PSK     ",
[tostring(wifi.WPA2_PSK)]    ="WPA2_PSK    ",
[tostring(wifi.WPA_WPA2_PSK)]="WPA_WPA2_PSK",
["5"]                        ="EAP         "
}
  
     print("\n\t\t\tSSID\t\t\t\t\tBSSID               RSSI\tAUTHMODE\t CHANNEL")
     for bssid,v in pairs(t) do
       local ssid, rssi, authmode, channel = string.match(v, "([^,]*),([^,]+),([^,]+),([^,]*)")
         print(string.format("%32s",ssid).."\t"..bssid.."   "..rssi.."\t\t"..(authmodemapping[authmode] or authmode).." "..channel)
      end
  end
  
  wifi.sta.getap({channel=0, show_hidden=1}, 1, list_ap)

end

