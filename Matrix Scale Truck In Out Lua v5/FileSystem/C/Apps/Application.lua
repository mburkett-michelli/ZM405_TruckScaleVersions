
--create the awtxReq namespace
awtxReq = {}

require("awtxReqConstants")
require("awtxReqVariables")

--Global Memory Sentinel ... Define this in your app to a different value to clear
-- the Variable table out.
MEMORYSENTINEL = "B1_220001072016Q2"         -- APP_Time_Day_Month_Year
MemorySentinel = awtxReq.variables.SavedVariable('MemorySentinel', "0", true)
-- if the memory sentinel has changed clear out the variable tables.
if MemorySentinel.value ~= MEMORYSENTINEL then
    -- Clears everything
    awtx.variables.clearTable()
    MemorySentinel.value = MEMORYSENTINEL
end

system = awtx.hardware.getSystem(1) -- Used to identify current hardware type.
config = awtx.weight.getConfig(1)   -- Used to get current system configuration information.
wt = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.

myCalUnits = config.calwtunit
currentUnits = wt.units
--require("awtxReqAppMenu")         
require("awtxReqScaleKeys")       
require("awtxReqScaleKeysEvents")
require("awtxReqRpnEntry")
--require("ReqSetpoint")
--require("ReqPresetTare")
--require("ReqWeb")
require("awtxReqDisplayMessages")   -- Provides display message support

-- AppName is displayed when escaping from password entry and entering a password of '0'
AppName = "M 475"
awtx.display.writeLine(AppName, 500)
  
scr1 = nil
lbl1 = nil
lbl2 = nil
segLabel = nil
myId = " " 
opEntered = ""
goingOut = false
opEntered = ""
myFloat = 0
myPBTare = false

idDisplayIndex = 0
fleetTare = 0
tareDisplay = false
lights = "&"
whichPrint = 1
unManed = 0
truckOnScaleWeight = 0  --80.2
switchToRed = 0                 --80.3
stp22Reset = 0                   --80.4

--saved variables
storedVariables = {}
storedVariables.incrementingNo = 0
storedVariables.truckOnScaleWeight = 2000
storedVariables.switchToRed = 5000
storedVariables.stp22Reset = 500
storedVariables.unManed = 0
mySequenceNo = 0
fromWeb = " "

myLine1 = ""
myLine2 = ""

--create storage for variables in the structure
--storedStructure = awtxReq.variables.SavedVariable ("storedStructure",storedVariables, true)
  
function createDatabase()
awtx.os.makeDirectory([[C:\Apps\Database]])
local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])

local result = dbFile:exec("CREATE TABLE IF NOT EXISTS Vehicles (\
  VehicleID VARCHAR NOT NULL,\
  TareExpDate VARCHAR,\
  Line1 VARCHAR, \
  Line2 VARCHAR, \
  MaxGross DOUBLE,\
  TareWeight DOUBLE, \
  TareTime VARCHAR, \
  TareDate VARCHAR) ;" ) 
--  print ("Result=",result) 
  
--  for truckRecord in dbFile:rows("SELECT VehicleID, Line1, Line2,MaxGross, TareWeight, TareExpDate FROM Vehicles") do
-- for i = 1,#truckRecord ,6 do
--    print (truckRecord[i] .. "," ..  truckRecord[i+1] .. "," .. truckRecord[i+2] ..",".. truckRecord[i+3] ..",".. truckRecord[i+4])
--  end
--end
dbFile:close()
end

function buildGraphicScreen()
scr1 = awtx.graphics.screens.new("scr1")
lbl1 = awtx.graphics.label.new("lbl1")
lbl1:setLocation(0,1)
lbl1:reSize(40,5)
lbl1:setFont(3)
lbl1:setText("DOT")
lbl1:setVisible(true)

lbl2 = awtx.graphics.label.new("lbl2")
lbl2:setLocation(0,10)
lbl2:reSize(40,5)
lbl2:setFont(3)
lbl2:setText("Matrix")
lbl2:setVisible(true)

segLabel = awtx.display.getLabelControl()

scr1:addControl(lbl1)
scr1:addControl(lbl2)
scr1:addControl(segLabel)

end

--local function onUsbKeyboardEvent(keycode, shift, Control, Alt)
--if keycode == 4096 then
--  print ("F1 pressed")
--  awtx.keypad.unregisterUsbKeyboardEvent()
--  checkIfOK()
--end
--end

  
function onStart()
if unManed > 0 then  
  awtx.setpoint.activate(2)     --turn on Green light
  awtx.setpoint.deactivate(1)   --turn off Red light
  lights = "&"
  awtx.setpoint.unregisterOutputEvent(23)
  awtx.setpoint.activate(3)      --turn on relay for buzzer
  
else 
  awtx.setpoint.activate(1)     --turn on red light
  awtx.setpoint.deactivate(2)   --turn off green light
  lights = "*"
  awtx.setpoint.registerOutputEvent(23,truckOnScale)
end  
  createDatabase()
  buildGraphicScreen()
  awtx.setpoint.registerOutputEvent(22,resetScale)
  storedVariables = awtxReq.variables.SavedVariable ("storedVariables",storedVariables, true)
  local b = awtx.weight.getCalibWeightUnits(1)
  local c = awtx.weight.getCurrentUnits(1)
  incrementingNo = tonumber(storedVariables.incrementingNo)        --80.1
  truckOnScaleWeight = tonumber(storedVariables.truckOnScaleWeight)  --80.2
  truckOnScaleWeight = awtx.weight.convertWeight(1,c,truckOnScaleWeight, b,1)
  switchToRed = tonumber(storedVariables.switchToRed)                 --80.3
  switchToRed = awtx.weight.convertWeight(1,c,switchToRed,b,1)
  stp22Reset = tonumber(storedVariables.stp22Reset)                   --80.4
  stp22Reset = awtx.weight.convertWeight(1,c,stp22Reset,b,1)
  
  unManed = storedVariables.unManed                                   --80.5
  awtx.fmtPrint.varSet(20,lights,"Lights", awtx.fmtPrint.TYPE_STRING)
  awtx.fmtPrint.varSet(30,fromWeb,"Webd", awtx.fmtPrint.TYPE_STRING)
  awtx.setpoint.registerOutputEvent(1, switchLights)
end
  
function switchLights()
  
  if awtx.setpoint.getState(1) == 1 then
     lights = "*" 
  end
  if awtx.setpoint.getState(2) == 1 then
     lights = "&"
     beepAtUser = awtx.os.createTimer(beeperOff,1000) 
     awtx.display.doBeep()
     awtx.setpoint.activate(3)
  end
  
  awtx.fmtPrint.varSet(20,lights,"Lights", awtx.fmtPrint.TYPE_STRING)

end
  
  
function beeperOff()
  
  awtx.setpoint.deactivate(3)
  awtx.os.killTimer(beepAtUser)
  
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
  
function roundToScaleB(currentValue)
wt = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.
local myRounding = tonumber(currentValue) / wt.curDivision  
local myWhole, myRemainder = math.modf(myRounding)
--myRemainder = myRemainder / wt.curDivision
myRemainder = myRemainder * wt.curDivision

if myRemainder > 1 then
  myWhole = myWhole + 1
end
currentValue = myWhole * wt.curDivision

dp = getDecPlaces()
local tStr = string.format("%." ..dp .. "f",currentValue)  
return tStr  
end
 
function roundToScale(currentValue)
wt = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.

local myRounding = tonumber(currentValue) / config.division  
local myWhole, myRemainder = math.modf(myRounding)
myRemainder = myRemainder / config.division

if myRemainder > 1 then
  myWhole = myWhole + 1
end
--tStr = myWhole * wt.curDivision
currentValue = myWhole * config.division

dp = getDecPlaces()
local tStr = string.format("%." ..dp .. "f",currentValue)  
return tStr  
end
 
--used to parse comma delimited file into usable format
function ParseCSVLine (line) 
	local res = {}
	local pos = 1
	sep = ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

 
 
function incNumber()
    incrementingNo = incrementingNo + 1
    if incrementingNo > 999999 then
      incrementingNo = 1
    end
    storedVariables.incrementingNo = incrementingNo          --80.1
--check if exists
 local i = 0
 local aa = 0
 local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
 for Records in dbFile:rows("SELECT VehicleID,MaxGross,TareWeight FROM Vehicles WHERE VehicleID = '" .. incrementingNo .. "';") do
  for i = 1,#Records,3 do
    aa = 1
  end
 end
 dbFile:close()
if aa == 1 then
  incNumber()
  return
end
returnedAfterEnter(incrementingNo)
  
end
  

  
function idEntry(myKey)
print ("id entry " .. myKey .. " + " .. opEntered) 

if myKey == 29 then
  opEntered = ""
  clearGraphics()
  return
end

--if numeric key entry
if myKey > 5 and myKey < 16 and string.len(opEntered) < 7 then
  opEntered = opEntered .. (myKey - 6)
  segLabel:setText(opEntered)
  return
end  

--if CLR key entry
if myKey == 16 then
  opEntered = ""
  segLabel:setText(opEntered)
end

--no entry made just pressed Enter
if myKey == 22 and opEntered =="" then
    incNumber()
    return
end

if myKey == 22 and tonumber(opEntered) > 0 then
    myId = opEntered
    opEntered = ""
    returnedAfterEnter(myId)
end
--if myKey == 26 and tonumber(opEntered) > 80 then
if myKey == 26 then
    if opEntered == "" and runMenu == false then
      clearGraphics()
      return
    end
    if tonumber(opEntered) > 80 then
      local temp = tonumber(opEntered)
      opEntered = ""
      GetValue(temp)
      return
    end
end

--tare key pressed
if myKey == 30 then
    wt = awtx.weight.getCurrent(1)
    myId = ""
    lbl1:setText("Press")
    lbl2:setText("Tare")
    segLabel:setText(wt.gross)
    awtx.display.setMode(1)
    scr1:show()
 --   awtx.keypad.unregisterAlternateKeyEvent()
    awtx.keypad.registerAlternateKeyEvent(tareEntry)
  --awtx.keypad.registerUsbKeyboardEvent(usbKeys)
  awtx.keypad.useAlternateLuaKeyboardEvents()
  tareDisplayTimer = awtx.os.createTimer(toggleDisplay,2000)
  tareDisplay = false
end
end
 
 
 function toggleDisplay()
  wt = awtx.weight.getCurrent(1)
 
   if tareDisplay == false then
    tareDisplay = true
    lbl1:setText("Or")
    lbl2:setText("Key in")
    segLabel:setText(wt.gross)
    awtx.display.setMode(1)
    scr1:show()
    return
  else
    lbl1:setText("Press")
    lbl2:setText("Tare")
    segLabel:setText(wt.gross)
    awtx.display.setMode(1)
    scr1:show()
    tareDisplay = false
  end
end

function tareEntry(myKey)
  awtx.os.killTimer(tareDisplayTimer)
 --  print ("tare test " .. myKey .. " + " .. opEntered) 

--if numeric key entry
if myKey > 5 and myKey < 16 and string.len(opEntered) < 7 then
  opEntered = opEntered .. (myKey - 6)
  segLabel:setText(opEntered)
  return
end  

--if CLR key entry
if myKey == 16 then
  opEntered = ""
  segLabel:setText(opEntered)
end

if myKey == 29 then
  opEntered = ""
  clearGraphics()
  return
end

--no entry made just pressed Tare
if myKey == 30 and opEntered =="" then
--if awtx.setpoint.getState(11) == 1 or awtx.setpoint.getState(12) == 1 then
--  awtx.display.writeLine("Loop",500)
--  awtx.display.writeLine("Can't",500)
--  return
--end 
if awtx.setpoint.getState(23) == 0 then
  awtx.display.writeLine("NoTruck",500)
  return
end
    myId = ""
    wt = awtx.weight.getCurrent(1)
    fleetTare = wt.gross
    myPBTare = false
    lbl1:setText("Enter")
    lbl2:setText("ID")
    segLabel:setText(myId)
    awtx.display.setMode(1)
    scr1:show()
    awtx.keypad.registerAlternateKeyEvent(idEntry)
  --awtx.keypad.registerUsbKeyboardEvent(usbKeys)
  awtx.keypad.useAlternateLuaKeyboardEvents()
  opEntered =""
  return
end

if myKey == 30 and tonumber(opEntered) > 0 then
--if awtx.setpoint.getState(11) == 1 or awtx.setpoint.getState(12) == 1 then
--  awtx.display.writeLine("Loop",500)
--  awtx.display.writeLine("Can't",500)
--    return
--end 
if awtx.setpoint.getState(23) == 0 then
  awtx.display.writeLine("NoTruck",500)
  return
end
    myId = ""
    fleetTare = tonumber(opEntered)
    myPBTare = true
    lbl1:setText("Enter")
    lbl2:setText("ID")
    segLabel:setText(myId)
    awtx.display.setMode(1)
    scr1:show()
    awtx.keypad.registerAlternateKeyEvent(idEntry)
  --awtx.keypad.registerUsbKeyboardEvent(usbKeys)
  awtx.keypad.useAlternateLuaKeyboardEvents()
  opEntered = ""

end
  
end
 
function returnedAfterEnter(myId)
awtx.keypad.unregisterAlternateKeyEvent()
findRecord(myId)
clearGraphics() 
end

function findRecord(TruckId)
 local i = 0
 local aa = 0
 local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
 -- for truckRecord in dbFile:rows("SELECT VehicleID, Owner, MaxGross, TareWeight, TareExpDate FROM Vehicles WHERE VehicleID = 1") do
 -- end
 local outId = " "
 local outWeight = 0.0
 local outTare = 0.0
 for Records in dbFile:rows("SELECT VehicleID,MaxGross,TareWeight FROM Vehicles WHERE VehicleID = '" .. TruckId .. "';") do
  for i = 1,#Records,3 do
--    print("Found " .. Records[i] .. " ," .. Records[i +1] .. " ," .. Records[i +2])
      outId = Records[i]
      outWeight = tonumber(Records[i +1])
      outTare = tonumber(Records[i+2])
    aa = 1
  end
 end
 dbFile:close()
 if aa == 0 and myPBTare == true then 
     myPBTare = false
      fleetIn(TruckId)
 elseif aa == 0 then
     truckIn(TruckId)
 else
    truckOut(outId,outWeight, outTare)
  end
end

function waitForMotion()
  local loop = 0
  local curScale = awtx.weight.getCurrent(1)
  
  while curScale.motion do
    awtx.display.writeLine("Mot'n",50)
    loop = loop + 1
    if loop > 100 then
      return false
    end
    curScale = awtx.weight.getCurrent(1)
  end
  return true
end



function truckIn(truckId)
--  local myOwner = "Test"
timeout = waitForMotion()  
if timeout == false then
  return
end
  wt = awtx.weight.getCurrent(1)
  myGross = wt.gross
  myTare = 0
--  wt = awtx.weight.getCurrent(1)
--  local myGross = wt.gross
  local storedGross = awtx.weight.convertToInternalCalUnit(1,wt.gross,1)
  local myUnits = wt.unitsStr
--  local myTare = 0
  local myDate = os.date("%x")
  local myTareExpDate = os.date("%x")
  local abc = tostring(myTareExpDate)
  local def = tostring(myDate)
  local myTime = os.date("%X")


--if myCalUnits ~=  wt.units then
--    storedGross = storedGross / wt.curUnitsFactor
--    storedGross = roundToScale(storedGross)
--    storedGross = tonumber(storedGross)
--end
if fleetTare > 1 then
  myTare = fleetTare
  fleetTare = 0
end

dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])

-- insert values in the Vehicles table
local result = dbFile:exec("INSERT INTO  Vehicles (VehicleID, TareExpDate ,Line1,Line2, MaxGross, TareWeight, TareTime,TareDate) VALUES ('" ..truckId .. "','" .. myTareExpDate .. "','"  .. myLine1 .. "','" .. myLine2.. "','" .. storedGross  .. "','"  .. myTare .. "','" .. myTime .. "','".. myDate .."');")
  if result == 0 then
    awtx.display.writeLine("truckIN",500)
    lbl1:setText(" ")
    lbl2:setText(" ")
    segLabel:setText("truckIN")
    awtx.fmtPrint.varSet(21,truckId,"VehicleID", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(22,myDate,"Date", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(23,myTime,"Time", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(24,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(25,myUnits,"Units", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(26,myLine1,"Line1", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(27,myLine2,"Line2", awtx.fmtPrint.TYPE_STRING)
    awtx.printer.printFmt(2)
    whichPrint = 2
    awtx.setpoint.activate(10)    --required for reprint
    awtx.setpoint.deactivate(2)     --turn off red light
    awtx.setpoint.activate(1)   --turn on green light
  end
 dbFile:close()
 updateWebInbound()
 
 awtx.display.setMode(0)
end

function fleetIn(truckId)
--  local myOwner = "Test"
waitForMotion()  
  wt = awtx.weight.getCurrent(1)
  local myGross = fleetTare
  local storedGross = awtx.weight.convertToInternalCalUnit(1,fleetTare,1)
  local myUnits = wt.unitsStr
  local myTare = 0
  local myDate = os.date("%x")
  local myTareExpDate = os.date("%x")
  local myTime = os.date("%X")
 
--if myCalUnits ~=  wt.units then
--    storedGross = storedGross / wt.curUnitsFactor
--    storedGross = roundToScale(storedGross)
--    storedGross = tonumber(storedGross)
--end
if fleetTare > 1 then
  myTare = fleetTare
  fleetTare = 0
end
 
local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
local result = dbFile:exec("INSERT INTO  Vehicles (VehicleID, TareExpDate ,Line1,Line2, MaxGross, TareWeight, TareTime,TareDate) VALUES ('" ..truckId .. "','" .. myTareExpDate .. "','"  .. myLine1 .. "','" .. myLine2.. "','" .. storedGross  .. "','"  .. myTare .. "','" .. myTime .. "','".. myDate .."');")
  
  if result == 0 then
    awtx.display.writeLine("truckIN",500)
    lbl1:setText(" ")
    lbl2:setText(" ")
    segLabel:setText("truckIN")
    awtx.fmtPrint.varSet(21,truckId,"VehicleID", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(22,myDate,"Date", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(23,myTime,"Time", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(24,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(25,myUnits,"Units", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(26,myLine1,"Line1", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(27,myLine2,"Line2", awtx.fmtPrint.TYPE_STRING)
    awtx.printer.printFmt(2)
    whichPrint = 2
    awtx.setpoint.activate(10)    --required for reprint
    awtx.setpoint.deactivate(2)     --turn off red light
    awtx.setpoint.activate(1)   --turn on green light
  end
 dbFile:close()
 updateWebInbound()
 awtx.display.setMode(0)
end



function truckOut(truckId,inWeight,inTare)
--  local myOwner = "Test"
  waitForMotion()  
  wt = awtx.weight.getCurrent(1)
  local myGross = awtx.weight.convertToInternalCalUnit(1,wt.gross,1)
  local myUnits = wt.unitsStr
  local myDate = os.date("%x")
  local myTime = os.date("%X")

  if inWeight > myGross then    --always in cal units
    myTare = myGross
  else
    myTare = inWeight
    inWeight = myGross
  end
 --local myNet = inWeight - myTare
  local result = 0
if inTare < 1 then
  local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
  result = dbFile:exec("DELETE FROM Vehicles WHERE VehicleID = '" .. truckId .. "';")
  dbFile:close()

end
 if result == 0 then
    
      local unitNo = awtx.weight.getCurrentUnits(1)
      inWeight = awtx.weight.convertWeight(1,inWeight,unitNo ,1)
      myTare = awtx.weight.convertWeight(1,myTare,unitNo ,1)
 --     myNet = awtx.weight.convertWeight(1,myNet,unitNo ,1)
      local myNet = inWeight - myTare
  
    awtx.fmtPrint.varSet(11,truckId,"VehicleID", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(12,myDate,"Date", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(13,myTime,"Time", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(14,inWeight,"Gross", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(15,myTare,"Tare", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(16,myNet,"Net", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(17,myUnits,"Units", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(18,myLine1,"Line1", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(19,myLine2,"Line2", awtx.fmtPrint.TYPE_STRING)
    awtx.setpoint.activate(10)    --required for reprint
    awtx.printer.printFmt(1)
    whichPrint = 1
    awtx.display.writeLine("truckOu",500)
    lbl1:setText(" ")
    lbl2:setText(" ")
    segLabel:setText("truckOu")
    awtx.setpoint.deactivate(2)     --turn off red light
    awtx.setpoint.activate(1)   --turn on green light
end
--updateWebInbound()
local myDay = os.date("%A")   --get day of thge week
--reCall_LastDate(myDay)
--appendRecord(myDay,truckId,myDate,myTime,inWeight,myTare,myNet,myUnits,myLine1,myLine2)

end
 
function clearGraphics()
mySequenceNo = 0
awtx.keypad.useStandardLuaKeyboardEvents()
awtx.keypad.unregisterAlternateKeyEvent()
awtxReq.display.displayWord(" ",100)    --required or won't clear display properly
awtx.graphics.clearscreen()
awtx.display.setMode(0)
end
 
function resetScale()
if awtx.setpoint.getState(22) == 0 then
    if tonumber(unManed) > 0 then
    awtx.setpoint.activate(2)   --turn on red light
    awtx.setpoint.deactivate(1) --turn off green light
    else
    awtx.setpoint.activate(1)   --turn on red light
    awtx.setpoint.deactivate(2) --turn off green light
    end
    awtx.keypad.unregisterAlternateKeyEvent()
    clearGraphics() 
    goingOut = false

end
end
  
  
function truckOnScale()
if awtx.setpoint.getState(23) == 0 then
  return
end

--if awtx.setpoint.getState(11) == 1 then
--    awtx.setpoint.deactivate(23)
--    return
--end
--if awtx.setpoint.getState(12) == 1 then
--    awtx.setpoint.deactivate(23)
--    return
--end

if tonumber(unManed) > 0 then
    awtx.setpoint.unregisterOutputEvent(23)
end
awtx.setpoint.activate(2)     --turn on red light
awtx.setpoint.deactivate(1)   --turn off green light
goingOut = true

end

  
function falseAlarm()
awtx.os.killTimer(delayTimer)
if awtx.setpoint.getState(22) == 0 then
  awtx.setpoint.activate(2)     --turn on red light
  awtx.setpoint.deactivate(1)   --turn off green light
end  
end
  
function zeroDone()
awtx.weight.unregisterZeroCompleteEvent()
awtx.display.setMode(0)
awtx.setpoint.activate(1)     --turn on green light
awtx.setpoint.deactivate(2)   --turn off red light
awtx.fmtPrint.varSet(20,lights,"Lights", awtx.fmtPrint.TYPE_STRING)
delayTimer = awtx.os.createTimer(falseAlarm,5000)
awtx.setpoint.registerOutputEvent(23,truckOnScale)
end

local function onUsbKeyboardEvent(keycode, shift, Control, Alt)
--  print(keycode .. " " .. shift .. " " .. Control .. " " .. Alt) 
  print("USB keyboard " .. keycode) 
end
  

function awtx.keypad.KEY_F1_DOWN()
  myLine1 = ""
  myLine2 = ""
--if awtx.setpoint.getState(11) == 1 or awtx.setpoint.getState(12) == 1 then
--  lbl1:setText(" ")
--  lbl2:setText(" ")
--  segLabel:setText("Loop")
--  awtx.display.writeLine("Loop",500)
--  segLabel:setText("Can't")
--  awtx.display.writeLine("Can't",500)
--  return
--end 
if awtx.setpoint.getState(23) == 0 then
  lbl1:setText(" ")
  lbl2:setText(" ")
  segLabel:setText("NoTruck")
  awtx.display.writeLine("NoTruck",500)
  return
end
    myId = ""
    lbl1:setText("Enter")
    lbl2:setText("ID")
    segLabel:setText(myId)
    awtx.display.setMode(1)
    scr1:show()

  awtx.keypad.set_RPN_mode(awtx.keypad.RPN_MODE_DISABLED)
  awtx.keypad.unregisterUsbKeyboardEvent()
  awtx.keypad.registerUsbKeyboardEvent(onUsbKeyboardEvent)
  awtx.keypad.registerAlternateKeyEvent(idEntry)
  awtx.keypad.useAlternateLuaKeyboardEvents()
  
end


function variableSetup(entryLine1,entryLine2,mydata)
  myFloat = mydata
  opEntered = ""       --clear keypress
  awtx.graphics.clearscreen()
  lbl1:setText(entryLine1)
  lbl2:setText(entryLine2)
  segLabel:setText(mydata)
  awtx.display.setMode(1)
  scr1:show()
  awtx.keypad.registerAlternateKeyEvent(varKeys)
  awtx.keypad.useAlternateLuaKeyboardEvents()
  return 
end
  
function varKeys(myKey)
if varTimer ~= nil then
  awtx.os.killTimer(varTimer)
end

--if numeric key entry
if myKey > 5 and myKey < 16 then
  opEntered = opEntered .. (myKey - 6)
  segLabel:setText(opEntered)
  onOff = false
  varTimer = awtx.os.createTimer(flashDisplay,500)
  return
end  

--if CLR key entry
if myKey == 16 then
  if opEntered == "" then
    if mySequenceNo > 30 and mySequenceNo < 33 then
      myFloat = 0
      awtx.display.clrSegments(0,33554432)
      awtx.display.clrSegments(0,67108864)
      awtx.display.clrSegments(0,134217728)
      returnVarEntry()
    end
  else  
  opEntered = ""
--  segLabel:setText(opEntered)
  GetValue("80." .. mySequenceNo)

  end
end

--dec point entered
--if myKey == 17 and string.len(opEntered) < floatLength and entryType == "F" then
if myKey == 17 then
    if string.find(opEntered, string.char(46),1,true) == nil then
        opEntered = opEntered .. string.char(46)
        segLabel:setText(opEntered)
    end
  onOff = false
  varTimer = awtx.os.createTimer(flashDisplay,500)
end

if myKey == 22 then  -- backspace
  opEntered = opEntered:sub(1,string.len(opEntered) - 1)
   segLabel:setText(opEntered)
  onOff = false
  varTimer = awtx.os.createTimer(flashDisplay,500)
end


if myKey == 24 then
    awtx.display.clrSegments(0,33554432)
    awtx.display.clrSegments(0,67108864)
    awtx.display.clrSegments(0,134217728)
    if opEntered ~= "" then
        myFloat = opEntered
        opEntered = ""
        returnVarEntry()
    end
end

--Select key function
if myKey == 26 then
    awtx.display.clrSegments(0,33554432)
    awtx.display.clrSegments(0,67108864)
    awtx.display.clrSegments(0,134217728)
    if opEntered == "" then
      clearGraphics()
      return
    end
    if tonumber(opEntered) > 80 then
      local temp = tostring(opEntered)
      opEntered = ""
      GetValue(temp)
      return
    end
end
end

function flashDisplay()
if onOff == false then
  local myLastChar = string.sub(opEntered, string.len(opEntered),string.len(opEntered)) 
  local mydisplay = string.sub(opEntered, 1, string.len(opEntered) - 1)
  if myLastChar == "." then
    mydisplay = mydisplay .. ""
  else  
    mydisplay = mydisplay .. "_"
  end
  segLabel:setText(mydisplay)
  onOff = true
--    awtx.display.setSegments(0,8388608)
--    awtx.display.setSegments(0,16777216)
    awtx.display.setSegments(0,33554432)
    awtx.display.setSegments(0,67108864)
    awtx.display.setSegments(0,134217728)

else
  segLabel:setText(opEntered)
  onOff = false
--    awtx.display.clrSegments(0,8388608)
--    awtx.display.clrSegments(0,16777216)
    awtx.display.clrSegments(0,33554432)
    awtx.display.clrSegments(0,67108864)
    awtx.display.clrSegments(0,134217728)

end
end


function returnVarEntry()
  local b = awtx.weight.getCalibWeightUnits(1)
  local c = awtx.weight.getCurrentUnits(1)

if mySequenceNo == 1 then
  storedVariables.incrementingNo = tonumber(string.format("%d",myFloat))    --80.1
  segLabel:setText(storedVariables.incrementingNo)
  incrementingNo = tonumber(storedVariables.incrementingNo)        --80.1
end
if mySequenceNo == 2 then
  myFloat = roundToScale(myFloat)
  storedVariables.truckOnScaleWeight = tonumber(myFloat)    --80.2
  segLabel:setText(storedVariables.truckOnScaleWeight)
  truckOnScaleWeight = tonumber(storedVariables.truckOnScaleWeight)  --80.2
  truckOnScaleWeight = awtx.weight.convertWeight(1,c,truckOnScaleWeight, b,1)
end
if mySequenceNo == 3 then
  myFloat = roundToScale(myFloat)
  storedVariables.switchToRed = tonumber(myFloat)    --80.1
  segLabel:setText(storedVariables.switchToRed)
  switchToRed = tonumber(storedVariables.switchToRed)                 --80.3
  switchToRed = awtx.weight.convertWeight(1,c,switchToRed,b,1)
end
if mySequenceNo == 4 then
  myFloat = roundToScale(myFloat)
  storedVariables.stp22Reset = tonumber(myFloat)    --80.1
  segLabel:setText(storedVariables.stp22Reset)
  stp22Reset = tonumber(storedVariables.stp22Reset)                  --80.4
  stp22Reset = awtx.weight.convertWeight(1,c,stp22Reset,b,1)
end
if mySequenceNo == 5 then
  myFloat = myFloat
  storedVariables.unManed = tonumber(string.format("%d",myFloat))    --80.1
  segLabel:setText(storedVariables.unManed)
  unManed = storedVariables.unManed                                   --80.5
end

end

function updateWebInbound()
wt= awtx.weight.getCurrent(1)
awtx.os.makeDirectory([[C:\Apps\Database]])
local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])

fileHandle = io.open([[c:\Apps\Web\TruckIn.txt]],"w")    --open file in append mode
if fileHandle == nil then
  dbFile:close()
  return
end
 
  for truckRecord in dbFile:rows("SELECT VehicleID, MaxGross, TareWeight, TareDate, Line1, Line2 , TareTime FROM Vehicles") do
  for i = 1,#truckRecord ,7 do
    if myCalUnits ~=  wt.units then
      truckRecord[i+1] = truckRecord[i + 1] * wt.curUnitsFactor
      truckRecord[i+2] = truckRecord[i + 2] * wt.curUnitsFactor
      truckRecord[i+1] = roundToScaleB(truckRecord[i + 1])
      truckRecord[i+1] = tonumber(truckRecord[i + 1])
      truckRecord[i+2] = roundToScaleB(truckRecord[i+2])
      truckRecord[i+2] = tonumber(truckRecord[i+2])
    else
      truckRecord[i+1] = roundToScale(truckRecord[i + 1])
      truckRecord[i+1] = tonumber(truckRecord[i + 1])
      truckRecord[i+2] = roundToScale(truckRecord[i+2])
      truckRecord[i+2] = tonumber(truckRecord[i+2])
    end
    fileHandle:write(string.format("%-7s",truckRecord[i]) .. "," .. string.format("%-20s",truckRecord[i+4]) .. "," .. string.format("%-20s",truckRecord[i+5]) .. "," .. string.format("%10s",truckRecord[i+3]) .. "," .. string.format("%8s",truckRecord[i+6]) .."," .. truckRecord[i+1]  .. "\r\n")   -- write th buffer to the file
  end
end
fileHandle:close()
dbFile:close()
end



function awtx.keypad.KEY_SAMPLE_UP()
  idDisplayIndex = 0
  awtx.graphics.clearscreen()
  lbl1:setText("Print")
  lbl2:setText("ID #'s")
  segLabel:setText(" ")
  awtx.display.setMode(1)
  scr1:show()
  opEntered = ""
  awtx.keypad.registerAlternateKeyEvent(idSetup)
  awtx.keypad.useAlternateLuaKeyboardEvents()
end

function idSetup(myKey)

--print ("id's " .. myKey .. " + " .. opEntered) 

--if numeric key entry
if myKey > 5 and myKey < 16 and string.len(opEntered) < 7 and idDisplayIndex == 1 then
  opEntered = opEntered .. (myKey - 6)
  segLabel:setText(opEntered)
  return
end  

--if CLR key entry
if myKey == 16 and idDisplayIndex == 1 then
  opEntered = ""
  segLabel:setText(opEntered)
end

--if Print pressed
if myKey == 24 then
    if idDisplayIndex == 1 then
      if opEntered == "" then
        awtx.display.writeLine("Enter",500)
        awtx.display.writeLine("ID",500)
        awtx.graphics.clearscreen()
        lbl1:setText("Clr")
        lbl2:setText("ID #")
        segLabel:setText(" ")
        scr1:show()
        opEntered = ""
        return
      else
      clearId(opEntered)
      return
    end
    elseif idDisplayIndex == 2 then
      clearAllId()
      return
    else
      printIds()
    end
end
if myKey == 26 then
  if idDisplayIndex == 0 then
      idDisplayIndex = 1
      awtx.graphics.clearscreen()
      lbl1:setText("Clr")
      lbl2:setText("ID #")
      segLabel:setText(" ")
 --     awtx.display.setMode(1)
      scr1:show()
      opEntered = ""
      return
  elseif idDisplayIndex == 1 then
      idDisplayIndex = 2
      awtx.graphics.clearscreen()
      lbl1:setText("Clear")
      lbl2:setText("All #")
      segLabel:setText(" ")
 --     awtx.display.setMode(1)
      scr1:show()
      opEntered = ""
      return
    else
      idDisplayIndex = 0
      awtx.graphics.clearscreen()
      lbl1:setText("Print")
      lbl2:setText("ID #'s")
      segLabel:setText(" ")
 --     awtx.display.setMode(1)
      scr1:show()
      opEntered = ""
      return
    end
end      

--if myKey == 26 and tonumber(opEntered) > 80 then
if myKey == 29 then
      clearGraphics()
      return
end
end

function clearId(TruckId)
 local i = 0
 local result = 0
 local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
 for Records in dbFile:rows("SELECT VehicleID FROM Vehicles WHERE VehicleID = '" .. TruckId .. "';") do
  for i = 1,#Records,1 do
  segLabel:setText("Del 1")
  awtx.display.writeLine("Del 1",500)
--    print("Found and deleting " .. Records[i])
      result = dbFile:exec("DELETE FROM Vehicles WHERE VehicleID = '" .. Records[i] .. "';")
  end
 end
 dbFile:close()
 awtx.graphics.clearscreen()
--      lbl1:setText("Clr")
--      lbl2:setText("ID #")
      segLabel:setText(" ")
 --     awtx.display.setMode(1)
 scr1:show()
 opEntered = ""

end

function clearAllId()
  local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
  local result = dbFile:exec("DELETE FROM Vehicles;")
  segLabel:setText("Del All")
  awtx.display.writeLine("Del All",500)
  
  for truckRecord in dbFile:rows("SELECT VehicleID, Line1, Line2, MaxGross, TareWeight, TareExpDate FROM Vehicles") do
  for i = 1,#truckRecord ,5 do
--    print (truckRecord[i] .. "," ..  truckRecord[i+1] .. "," .. truckRecord[i+2] ..",".. truckRecord[i+3] ..",".. truckRecord[i+4])
  end
  end
dbFile:close()
awtx.graphics.clearscreen()
segLabel:setText(" ")
scr1:show()
opEntered = ""
  
end

function printIds()
wt= awtx.weight.getCurrent(1)
awtx.display.writeLine("Print",1000)
awtx.os.makeDirectory([[C:\Apps\Database]])
local dbFile = sqlite3.open([[C:\Apps\Database\TruckScaleDB.db]])
local answer = awtx.weight.getCurrentUnits(1)
--  c = awtx.weight.convertWeight(1,b,answer ,1)
 
  for truckRecord in dbFile:rows("SELECT VehicleID, MaxGross, TareWeight, TareExpDate FROM Vehicles") do
  for i = 1,#truckRecord ,4 do
      truckRecord[i+1] = awtx.weight.convertWeight(1,truckRecord[i + 1],answer ,1)
      truckRecord[i+2] = awtx.weight.convertWeight(1,truckRecord[i + 2],answer ,1)

    awtx.fmtPrint.varSet(31,truckRecord[i],"VehicleID", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(32,truckRecord[i+3],"Date", awtx.fmtPrint.TYPE_STRING)
    awtx.fmtPrint.varSet(33,truckRecord[i+1],"Gross", awtx.fmtPrint.TYPE_FLOAT )
    awtx.fmtPrint.varSet(34,truckRecord[i+2],"Tare", awtx.fmtPrint.TYPE_FLOAT)
    if tonumber(truckRecord[i+2]) > 1 then
        awtx.fmtPrint.varSet(35,"FLEET","Fleet", awtx.fmtPrint.TYPE_STRING)
      else
        awtx.fmtPrint.varSet(35," ","Fleet", awtx.fmtPrint.TYPE_STRING)
     end 
    awtx.printer.printFmt(10)
    awtx.os.systemEvents(300)
  end
end
dbFile:close()
awtx.keypad.KEY_SETUP_DOWN()
end


function awtx.keypad.KEY_STOP_DOWN()
  if awtx.setpoint.getState(10) == 0 then
    return
  end
  wt = awtx.weight.getCurrent(1)
  recallUnits1 = awtx.fmtPrint.varGet(17)
  recallUnits2 = awtx.fmtPrint.varGet(25)
  if wt.unitsStr == recallUnits1 and whichPrint == 1 then  --reprint outbound same units
    awtx.printer.printFmt(whichPrint)
    return
  end
  if wt.unitsStr == recallUnits2 and whichPrint == 2 then --reprint inbound same units
    awtx.printer.printFmt(whichPrint)
    return
  end
  if whichPrint == 2 and wt.units == 1 then   --if inbound and now in lb
        myGross = awtx.fmtPrint.varGet(24)
        myGross = awtx.weight.convertWeight(2,myGross,1 ,1)
        awtx.fmtPrint.varSet(24,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(25,wt.unitsStr,"Units", awtx.fmtPrint.TYPE_STRING )
        awtx.printer.printFmt(whichPrint)
        return
  end
  if whichPrint == 2 and wt.units == 2 then   --if inbound and now in lb
        myGross = awtx.fmtPrint.varGet(24)
        myGross = awtx.weight.convertWeight(1,myGross,2 ,1)
        awtx.fmtPrint.varSet(24,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(25,wt.unitsStr,"Units", awtx.fmtPrint.TYPE_STRING )
        awtx.printer.printFmt(whichPrint)
        return
  end
  if whichPrint == 1 and wt.units == 1 then   --if outbound and now in lb
        myGross = awtx.fmtPrint.varGet(14)
        myTare = awtx.fmtPrint.varGet(15)
        myGross = awtx.weight.convertWeight(2,myGross,1 ,1)
        myTare = awtx.weight.convertWeight(2,myTare,1 ,1)
        myNet = myGross - myTare
        awtx.fmtPrint.varSet(14,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(15,myTare,"Tare", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(16,myNet,"Net", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(17,wt.unitsStr,"Units", awtx.fmtPrint.TYPE_STRING )
        awtx.printer.printFmt(whichPrint)
        return
  end

  if whichPrint == 1 and wt.units == 2 then   --if outbound and now in lb
        myGross = awtx.fmtPrint.varGet(14)
        myTare = awtx.fmtPrint.varGet(15)
        myGross = awtx.weight.convertWeight(1,myGross,2 ,1)
        myTare = awtx.weight.convertWeight(1,myTare,2 ,1)
        myNet = myGross - myTare
        awtx.fmtPrint.varSet(14,myGross,"Gross", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(15,myTare,"Tare", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(16,myNet,"Net", awtx.fmtPrint.TYPE_FLOAT )
        awtx.fmtPrint.varSet(17,wt.unitsStr,"Units", awtx.fmtPrint.TYPE_STRING )
        awtx.printer.printFmt(whichPrint)
        return
  end

end

function webFields(a,b,c)
  myLine1 = b
  myLine2 = c
  findRecord(a)
  
end

function reCall_LastDate(NameofDay)
  local csvData

--  print ([[c:\Database\]] ..NameofDay ..[[.txt]])
  local fileHandle = io.open([[c:\Apps\Web\]]  ..NameofDay ..[[.txt]],"r")    --open file in read mode
  if fileHandle == nil then   -- check if file is not  found
      print ("File not Found\r\n")
      return
    end
  for line in fileHandle:lines() do
  
    csvData = ParseCSVLine(line) 
--    print (csvData[4] .. "," .. os.date("%m/%d/%y"))
    if (csvData[4]) == os.date("%m/%d/%y") then
--      print (csvData[1] .. " append " .. os.date("%Y/%m/%d").."\r\n")
      fileHandle:close()
    else
      fileHandle:close()
      awtx.os.deleteFile([[c:\Apps\Web\]] ..NameofDay ..[[.txt]])
--      print (csvData[1] .. " delete " .. os.date("%Y/%m/%d").."\r\n")
    end
--   end
  return
 end
end 


function appendRecord(NameofDay,truckId,myDate,myTime,inWeight,myTare,myNet,myUnits,myLine1,myLine2)
  
  wt = awtx.weight.getCurrent(1)      -- Used to hold current scale snapshot information.

--  local fileHandle = io.open([[c:\Apps\Web\]] ..NameofDay ..[[.txt]],"a")    --open file in read mode
--  fileHandle:write(truckId .."," .. myLine1 .."," .. myLine2 .. "," .. myDate .."," .. myTime .."," .. inWeight .."," .. myTare .."," .. myNet .."," .. myUnits .."\r\n")
--  fileHandle:close()
end
  




onStart()
