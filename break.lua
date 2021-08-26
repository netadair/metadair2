
  gpio.trig(RED_LED_PIN, "none")
  gpio.write(RED_LED_PIN, gpio.LOW) -- an

  -- stop watchdog and blinking  
  if(blinkredtmr ~= nil) then blinkredtmr:unregister() end
  if(heartbeattmr ~= nil) then heartbeattmr:unregister() end
  
  --tmr.softwd(-1)
  tmr.softwd(5*60) -- just in case of accidental break

  mdns.close()

  -- reset tty
  if(uart_srv ~= nil) then uart_srv:close() end  
  uart.on("data")
  uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

  -- and telnet
  if(telnet_srv ~= nil) then telnet_srv:close() end
  node.output(nil)

  print("Console ready after break\n>")

