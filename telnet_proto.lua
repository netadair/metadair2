-- telnet commands

IAC=255
WILL=251
--WONT=252
DO=  253
--DONT=254
SB=  250
SE=  240
SUSP=237-- for us: defaults for uart
INTP=244-- for us: 115200 8n1 for uart
EOR=239 -- for us: default IEC 61107/IEC 62056-21/D0 mode A uart parameters
EOF=236 -- for us: default Kamstrup uart parameters
GOH=249 -- for us: default SML uart parameters
--NOP= 241
--BRK= 243
--AYT= 246
ABORTPROCESS=238 -- for us: reboot
COMPORTOPTION=0x2C -- RFC2217


function handle_telnet(l, input_function, printanswer, telnetsession)
            -- handle telnet protocol

            local iaclevel=0
            local willwontdodont=0
            local specialseq={}
            for i = 1, #l do
                local code = l:byte(i)

                    if(iaclevel==0 and code==IAC) then
                        iaclevel=1
                    elseif(iaclevel==0) then
                        input_function(string.char(code))
                    elseif(iaclevel==1 and code==IAC) then
                        input_function(string.char(IAC))
                        iaclevel=0
                    elseif (iaclevel==1 and code>=WILL) then
                        -- WILL etc
                        willwontdodont=code 
                        iaclevel=2
                    elseif (iaclevel==1 and code==SB) then
                        -- here, special negotiation
                        iaclevel=3
                    elseif (iaclevel==1) then

                        if(code==ABORTPROCESS) then
                            node.restart()
                        end

                        if(code==EOR) then
                            uart.setup(0,300,7,uart.PARITY_EVEN,uart.STOPBITS_1,0)
                        elseif(code==EOF) then
                            uart.setup(0,9600,8,uart.PARITY_NONE,uart.STOPBITS_2,0)
                        elseif(code==GOH) then
                            uart.setup(0,9600,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
                        elseif(code==INTP) then
                            uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
                        elseif(code==SUSP) then
                            uart.setup(0, UART_BAUD, UART_BITS, UART_PARITY, UART_STOP, 0)
                        else
                            if (telnetsession) then printanswer("Telnet command ".. code .." ignored\n") end
                        end
                        
                        iaclevel=0
                    elseif (iaclevel==2) then

                        if(willwontdodont==WILL and code==COMPORTOPTION) then
                            printanswer(string.char(IAC, DO, COMPORTOPTION))
                        else
                            if (telnetsession) then printanswer("Telnet neg option ".. willwontdodont .. " " .. code .. " ignored \n") end
                        end
                        
                        iaclevel=0
                    elseif (iaclevel==3 and code==SE) then
                        -- here, special end, officially IAC SE though

                        if (specialseq[1] == COMPORTOPTION) then

                            local baud, databits, parity, stopbits = uart.getconfig(0)

                            if (specialseq[2] == 1) then -- SET-BAUDRATE
                                    local newbaud = (((specialseq[3]*256)+specialseq[4])*256+specialseq[5])*256+specialseq[6]
                                    if newbaud ~= 0 then baud=newbaud end
                            elseif (specialseq[2] == 2) then -- SET-DATASIZE
                                    if(specialseq[3] >= 5 and specialseq[3] <= 8) then
                                        databits=specialseq[3]
                                    end
                            elseif (specialseq[2] == 3) then -- SET-PARITY
                                    if(specialseq[3] == 1) then 
                                        parity=uart.PARITY_NONE
                                    elseif(specialseq[3] == 2) then 
                                        parity=uart.PARITY_ODD
                                    elseif(specialseq[3] == 3) then 
                                        parity=uart.PARITY_EVEN
                                    end
                            elseif (specialseq[2] == 4) then -- SET-STOPSIZE
                                    if(specialseq[3] == 1) then 
                                        stopbits=uart.STOPBITS_1
                                    elseif(specialseq[3] == 2) then 
                                        stopbits=uart.STOPBITS_2
                                    elseif(specialseq[3] == 3) then 
                                        stopbits=uart.STOPBITS_1_5
                                    end       
                            end
                            
                            uart.setup(0, baud, databits, parity, stopbits ,0)

                        elseif (telnetsession) then 
                            printanswer("Telnet special seq\n")
                            for i,v in ipairs(specialseq) do printanswer(v .. "\n") end
                        end

                        specialseq={}
                        iaclevel=0
                    elseif (iaclevel==3) then
                        table.insert(specialseq, code)
                    end
                    
                    -- capture if an escape was ever used.
                    if(iaclevel>0 and uarthasrfc2217 == nil) then
                        uarthasrfc2217=true
                    end
            end
end
