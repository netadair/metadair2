# metadair2
Lua firmware and code for MetAdair2 Kamstrup/D0 probes as shown on https://wiki.volkszaehler.org/hardware/controllers/metadair2

## Installation

* Flash firmware, eg using with NodeMCU-PyFlasher
* Reboot, let Lua initialize the flash
* Change the `config.lua` to contain your SSID and password. If access to the meter is planned primarily with D0 only, you could change the default RS232 parameters to D0 like to not always change the parameters inline with each request.
  ```
  UART_BAUD = 300
  UART_BITS = 7
  UART_PARITY = uart.PARITY_EVEN
  UART_STOP = uart.STOPBITS_1
  ```
* Customize ESPlorer, adding some Snipplets
  * `Reset` 
    ```
    =node.restart()
    ```
  * `feed dog` 
    ```
    f()
    f=nil
    collectgarbage()
    collectgarbage()
    ```
  * `heap space`
     ```
     =node.heap()
     ```
  * `compile` 
    ```
    node.compile("metadair2.lua") 
    
    node.compile("telnet_banner.lua")
    node.compile("telnet_proto.lua")
    node.compile("ip_service_setup.lua")
    node.compile("break.lua")

    wifi.setmode(wifi.NULLMODE, true)
    ```
* Upload files using ESPlorer's pload feature. Please do not copy&paste on the console or the like. This will barf on large files.
This list can be used in the file selector box of ESPlorer
  > "break.lua" "config.lua" "init.lua" "ip_service_setup.lua" "list_ap.lua" "metadair2.lua" "telnet_banner.lua" "telnet_proto.lua"
After the upload, please reboot or do garbage collection to free memory for compiling the large core source file.
* Compile the code. This leaves lot of heap space eaten up, so done in two steps, the snipplet shown above breaks when run in one row. So first compile the core file, then reboot, feed the dog, the compile the rest and reset the wifi.

## Usage

When running the code, it (tries as far as the firmware allows) to check for unusual conditions, ie crash. NB: Does not work with this firmware version fully, though.
If so, it reboots into the console and awaits commands, first one expected would be to disable the watchdog which would otherwise do a regular reboot in 30sec.
Otherwise, you can just "feed" the dog, both best down with the prepared snipplets, or copy&paste. 

After the firmware is up, it retries a DHCP address and announces itself via MDNS/Bonjour.
You can access the Lua console on tcp port 23 (alas, no error messages though, does not work with this firmware)
or the serial port on tcp port 9600. 

Access is straight-through with telnet protocol (please adhere when transfering binary data!), and you can use either some telnet commands to set RS232 parameters or use RFC2217.
Short cuts are:

Telnet command | means for us
-------------- | ------------
SUSP=237 | defaults for uart
INTP=244 | 115200 8n1 for uart
EOR=239 | default IEC 61107/IEC 62056-21/D0 mode A uart parameters
EOF=236 | default Kamstrup uart parameters
GOH=249 | default SML uart parameters
ABORTPROCESS=238 | reboot
COMPORTOPTION=0x2C | RFC2217

## Nota bene
The actual reading and parsing is not done on the ESP! Depending if you want plain D0 output or full-blown KMP Kamstrup protocol support, you can access the meter from your Smarthome machine (Raspberry, Beaglebone or the like) with relevant scripts to process the data.

This can be a single liner like
```
(/bin/echo -n -e '\xff\xef'; sleep 1; /bin/echo -n -e '/?!\r\n'; sleep ${TIMEOUT:-10} ) | /usr/local/bin/socat -t${TIMEOUT:-2} stdio tcp:${IP}:${PORT} 2>/dev/null
```
for D0 output, with some IP retrieved by mDNS before, or using the plain DNS name `NODE-<yourespserialhere>` the device used to retrieve it's adress via DHCP.

