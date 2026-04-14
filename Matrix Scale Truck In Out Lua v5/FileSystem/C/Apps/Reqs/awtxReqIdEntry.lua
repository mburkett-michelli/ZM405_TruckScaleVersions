--[[
*******************************************************************************

Filename:      awtxReqIdEntry.lua
Version:       1.0.0.0
Date:          2015-09-01
Customer:      Avery Weigh-Tronix
Description:
This lua file provides basic ID entry and recall functionality.

*******************************************************************************

*******************************************************************************
]]

require("awtxReqConstants")

ID = {}


local function create()
  ID.id = 0
  ID.initIDPrintTokens()
end


function ID.initIDPrintTokens()
  awtx.fmtPrint.varSet(1, ID.id, "ID", awtx.fmtPrint.TYPE_INTEGER)
end


function ID.setIDPrintToken()
  awtx.fmtPrint.varSet(1, ID.id, "ID", awtx.fmtPrint.TYPE_INTEGER)
end


function ID.enterID()
  local usermode
  local idminVal, idmaxVal, newID, isEnterKey
  usermode = awtx.display.setMode(awtx.display.MODE_MENU)
  newID = ID.id
  idminVal= 0
  idmaxVal= 9999999
  newID, isEnterKey = awtx.keypad.enterInteger(newID, idminVal, idmaxVal, entertime, "Enter", "  ID  ")
  awtx.display.setMode(usermode)
  if isEnterKey then
    ID.setID(newID)
  end
end


function ID.showID()
  local usermode = awtx.display.setMode(awtx.display.MODE_USER)
  awtx.display.writeLine("ID", 1000)
  awtx.display.writeLine(string.format("%d", ID.id), 1500)
  awtx.display.setMode(usermode)
end


function ID.setID(newID)
  local idminVal, idmaxVal
  idminVal= 0
  idmaxVal= 9999999
  if newID >= idminVal and newID <= idmaxVal then
    ID.id = tonumber(string.format("%d", newID))
    ID.setIDPrintToken()
  end
end


create()