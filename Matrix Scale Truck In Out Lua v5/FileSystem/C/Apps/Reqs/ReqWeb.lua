

function onCreate()
  local result = awtx.fmtPrint.registerVarChangeReqEvent(luaVarChangeFunc)
  --buildVersionString()
  awtx.os.createTimer(updateWeb,300)
 -- awtx.os.registerFtpFileReceivedEvent(FTPtoWeb) 
 -- awtx.os.registerFtpFileAddedEvent(FTPtoWeb)
  
end


function luaVarChangeFunc(scaleNum, slotNum, varValue)
--    awtx.display.doBeep()
 if slotNum==11 then 
--    awtx.serial.send(1,varValue)
    awtx.weight.requestPresetTare(1,tonumber(varValue))
  elseif slotNum==30 then 
    varValue = string.gsub(varValue,"+"," ")    --replace + with spaces
    varValue = string.gsub(varValue,"%%2C",",") --remove html , with comma
    local myReturned = ParseCSVLine(varValue)
    if myReturned[1] == nil then
        myReturned[1] = " "
    end
    if myReturned[2] == nil then
        myReturned[2] = " "
    end
    if myReturned[3] == nil then
        myReturned[3] = " "
    end
    webFields(myReturned[1], myReturned[2] , myReturned[3])
  elseif slotNum==23 then 
    field2=varValue
  elseif slotNum==95 then -- app var 95 -PB Tare
    awtx.weight.requestTare(1)
  elseif slotNum == 94 then           -- app var 94  - Print
    awtx.weight.requestPrint(1)   
  elseif  slotNum == 93 then            -- app var 93  - Zero
    awtx.weight.requestZero(1)
  elseif slotNum == 92 then              -- app var 92  - Cycle Units
    awtx.weight.cycleUnits(1)
  elseif slotNum == 91 then            -- app var 91  - Cycle Active Value
    awtx.weight.cycleActiveValue(1)
  end
end

function getDecPlaces()
wt = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.
local myDivision = wt.curDivision
local myString = tostring(myDivision)
local myLength = string.len(myString)
local start,stop = string.find(myString, ("%."))
if start == nil then
   answer = 0
else
   answer = (myLength - start)
end
return answer
end




--[[
Description:
  This function creates a delimiter string with setpoint info. The string is stored into an application variable
  read by the web client 
  This function is called by a timer
  
Parameters:
  None
  
Returns:
  None
]]
function updateWeb()
  local activeValueNames= {"Gross","Net","Tare"}
  local activeValue = awtx.weight.getActiveValue() +1
  local displayedWeight
    wt = awtx.weight.getCurrent(1) 
  if activeValue == 1 then 
    displayedWeight = wt.gross 
  elseif activeValue == 2 then 
    displayedWeight = wt.net
  elseif activeValue == 3 then
    displayedWeight = wt.tare
  else
    displayedWeight = 0
  end
     
  if math.abs(displayedWeight) == 0 then 
     displayedWeight = 0 
  end

  local stpt1Stat 
  weightFormat = string.format ("%%.%df",wt.curDigitsRight) 

  local tStr = string.format("%d|%d|%d",awtx.setpoint.getState(11),awtx.setpoint.getState(12),awtx.setpoint.getState(13))
  tStr = tStr .. string.format("|%d|%d|%d",awtx.setpoint.getState(1),awtx.setpoint.getState(2),awtx.setpoint.getState(3))
  
 -- if awtx.display.getMode() == 1 then
 --   tStr = tStr .. string.format("|%s|%s|%s",myEntry, " "," ")
  if wt.underRange == true then
    local myUnder = "UL  "
    tStr = tStr .. string.format("|%s|%s|%s",myUnder,wt.unitsStr,activeValueNames[activeValue])
  elseif wt.overRange == true then
    local myOver = "OL  "
    tStr = tStr .. string.format("|%s|%s|%s",myOver,wt.unitsStr,activeValueNames[activeValue])
  else
    dp = getDecPlaces()
    tStr = tStr .. string.format("|%." ..dp .. "f|%s|%s",displayedWeight,wt.unitsStr,activeValueNames[activeValue])
  end
  if wt.motion == true then
    tStr = tStr .. string.format("|%d",1)
  else
    tStr = tStr .. string.format("|%d",0)
  end
  if wt.centerZero == true then
    tStr = tStr .. string.format("|%d",1)
  else
    tStr = tStr .. string.format("|%d",0)
  end
  
  awtx.fmtPrint.varSet(99, tStr, "Web",awtx.fmtPrint.TYPE_STRING)
end

--[[
Description:
  This function is called when a file is added ob the FTP. The file is then copied to the flash drive
  
  
Parameters:
  None
  
Returns:
  None
]]
function FTPtoWeb(fileName)
  local baseFileName = string.sub(fileName,4) 
  local destFile = "C:\\Apps\\WebFiles\\"..baseFileName 
 
  awtx.os.copyFile(fileName, destFile) 
  awtx.os.deleteFile(fileName)
end


--[[
Description:
  This function encodes non-printable characters in an HTML string.
 
Parameters:
  str : string to encode
  
Returns:
  str : encoded string
]]
function urlEncode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
  end
  return str	
end



onCreate()