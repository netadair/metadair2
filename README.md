# metadair2
Lua firmware and code for MetAdair2 Kamstrup/D0 probes as shown on https://wiki.volkszaehler.org/hardware/controllers/metadair2

## Installation

* Flash firmware, eg using with NodeMCU-PyFlasher
* Reboot, let Lua initialize the flash
* Change the <config.lua> to contain your SSID and password.
* Customize ESPlorer, adding some Snipplets
**
**
**
**
* Upload files using ESPlorer's pload feature. Please do not copy&paste on the console or the like. This will barf on large files.
This list can be used in the file selector box of ESPlorer
> "break.lua" "config.lua" "init.lua" "ip_service_setup.lua" "list_ap.lua" "metadair2.lua" "telnet_banner.lua" "telnet_proto.lua"
* Compile the code. This leaves lot of heap space eaten up, so done in two steps

## Usage

When running the code, it (tries as far as the firmware allows) to check for unusual conditions, ie crash. NB: Does not work with this firmware version fully, though.
If so, it reboots into the console and awaits commands, first one expected would be to disable the watchdog which would otherwise do a regular reboot in 30sec.
Otherwise, you can just "feed" the dog, both best down with the prepared snipplets, or copy&paste. 

After the firmware is up, it retries a DHCP address and announces itself via MDNS/Bonjour.
You can access the Lua console on tcp port 23 (alas, no error messages though, does not work with this firmware)
or the serial port on tcp port 9600. 


