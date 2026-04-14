
require("awtxReqConstants")


local function create()
  
  -- Turn on RPN Mode in firmware
  awtx.keypad.set_RPN_mode(awtx.keypad.RPN_MODE_ENABLED)

  -- register the RPN complete Event
  awtx.keypad.registerNumberEntryRPN(onRpnComplete)
end


function GetValue(keynumbers)

if keynumbers == "80.1" then
    mySequenceNo = 1
    variableSetup("Incrmt","No",storedVariables.incrementingNo)
    return
end
if keynumbers == "80.2" then
    mySequenceNo = 2
    variableSetup(wt.unitsStr,"TrukOn",storedVariables.truckOnScaleWeight)
    return
end
if keynumbers == "80.3" then
    mySequenceNo = 3
    variableSetup(wt.unitsStr,"to Red",storedVariables.switchToRed)
    return
end
if keynumbers == "80.4" then
    mySequenceNo = 4
    variableSetup(wt.unitsStr,"to Red",storedVariables.stp22Reset)
    return
end
if keynumbers == "80.5" then
    mySequenceNo = 5
    variableSetup("Set to","UnMand",storedVariables.unManed)
    return
end

  awtxReq.display.displayCant(500)
  if mySequenceNo > 0 then
    GetValue("80." .. mySequenceNo)
  else
    clearGraphics()
  end

end


function awtxReq.keypad.onRpnPrint(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  local newFmt = tonumber(enteredValue)
  -- Need to Refresh the Print information
  wt = awtx.weight.getRefreshLastPrint()
  --Print the Format that was specified.
  awtx.printer.PrintFmt(newFmt)
end

--[[
Description:
-- Function that gets called when an RPN event for the Tare key gets called
    Performs a keypad Tare with the entered value
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnTare(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  if config.keyTareFlag then
    newTare = tonumber(enteredValue)
    awtx.weight.requestKeyboardTare(newTare)  -- Tell the Indicator to requestKeyboardTare with the value entered
  end
end

--[[
Description:
-- Function that gets called when an RPN event for the Units key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnUnits(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the Zero key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnZero(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the Select key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnSelect(enteredValue)
 if enteredValue ~= nil then
   GetValue(tostring(enteredValue))
  end
end

--[[
Description:
-- Function that gets called when an RPN event for the Sample key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnSample(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the Start key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnStart(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the Stop key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnStop(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the ScaleSelect key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnScaleSelect(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  if awtx.weight.setActiveScale(tonumber(enteredValue)) ~= 0 then 
    awtxReq.display.displayCant()
  end
    
end

--[[
Description:
-- Function that gets called when an RPN event for the F1 key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
-- F1 doesn't have an RPN function in 2.2.0.0 firmware
--function awtxReq.keypad.onRpnF1(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
--  awtxReq.display.displayCant()
--end

--[[
Description:
-- Function that gets called when an RPN event for the Target key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
function awtxReq.keypad.onRpnTarget(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
  awtxReq.display.displayCant()
end

--[[
Description:
-- Function that gets called when an RPN event for the Setup key gets called
    By default RPN does nothing for this key.
Parameters:
  enteredValue = the value that was entered 
  
Returns:
  None
]]--
-- SETUP doesn't have an RPN function in 2.2.0.0 firmware
--function awtxReq.keypad.onRpnSetup(enteredValue)
  -- Default functionality.
  -- Redefine function to change functionality
--  awtxReq.display.displayCant()
--end


--[[
Description:
-- callback function when the attempted RPN operation completes

Parameters:
  None
  
Returns:
  None
]]--
function onRpnComplete(lastKey, enteredValue)
  -- This allows overides of the onRpnXxxx() functions outside this file.
  if tostring(lastKey) == "TARE" then  
    awtxReq.keypad.onRpnTare(enteredValue) 
  elseif tostring(lastKey) == "PRINT" then  
    awtxReq.keypad.onRpnPrint(enteredValue) 
  elseif tostring(lastKey) == "SELECT" then  
    awtxReq.keypad.onRpnSelect(enteredValue) 
  elseif tostring(lastKey) == "SCL SEL" then  
    awtxReq.keypad.onRpnScaleSelect(enteredValue) 
  elseif tostring(lastKey) == "SAMPLE" then 
    awtxReq.keypad.onRpnSample(enteredValue) 
  elseif tostring(lastKey) == "UNITS" then  
    awtxReq.keypad.onRpnUnits(enteredValue) 
  elseif tostring(lastKey) == "TARGET" then  
    awtxReq.keypad.onRpnTarget(enteredValue) 
  elseif tostring(lastKey) == "START" then  
    awtxReq.keypad.onRpnStart(enteredValue) 
  elseif tostring(lastKey) == "STOP" then  
    awtxReq.keypad.onRpnStop(enteredValue) 
  elseif tostring(lastKey) == "ZERO" then  
    awtxReq.keypad.onRpnZero(enteredValue)
-- F1 and SETUP keys don't have RPN functionality in version 2.2.0.0 firmware
--  elseif tostring(lastKey) == "F1" then  
--    awtxReq.keypad.onRpnF1(enteredValue) 
--  elseif tostring(lastKey) == "SETUP" then  
--    awtxReq.keypad.onRpnSetup(enteredValue) 
  else
    awtxReq.display.displayCant()
  end
end


create()