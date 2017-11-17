--Copyright (C) 2017 Arno Zura ( https://www.gnu.org/licenses/gpl.txt )

local Player = FindMetaTable( "Player" )

AddCSLuaFile( "client.lua" )

if CLIENT then
  include( "client.lua" )
else
  include( "server.lua" )
end

function Player:getAgendaTable()
  --Description: Get the agenda a player can see. Note: when a player is not the manager of an agenda, it returns the agenda of the manager.
  printGM( "darkrp", "getAgendaTable()" )
  printGM( "darkrp", g_yrp._not )
  return {}
end

local DarkRPVars = {}
function Player:getDarkRPVar( var )
  --Description: Get the value of a DarkRPVar, which is shared between server and client.
  printGM( "darkrp", "getDarkRPVar( " .. var .. " )" )
  local vars = DarkRPVars[self:UserID()]
  return "fail"
end

function Player:getEyeSightHitEntity( searchDistance, hitDistance, filter )
  --Description: Get the entity that is closest to a player's line of sight and its distance.
  printGM( "darkrp", "getEyeSightHitEntity( searchDistance, hitDistance, filter )" )
  printGM( "darkrp", g_yrp._not )
  return NULL, 0
end

function Player:getHitPrice()
  --Description: Get the price the hitman demands for his work.
  printGM( "darkrp", "getHitPrice()" )
  printGM( "darkrp", g_yrp._not )
  return 0
end

function Player:getHitTarget()
  --Description: Get the target of a hitman.
  printGM( "darkrp", "getHitTarget()" )
  printGM( "darkrp", g_yrp._not )
  return NULL
end

function Player:getJobTable()
  --Description: Get the job table of a player.
  printGM( "darkrp", "getJobTable()" )
  printGM( "darkrp", g_yrp._not )
  return {}
end

function Player:getPocketItems()
  --Description: Get a player's pocket items.
  printGM( "darkrp", "getPocketItems()" )
  printGM( "darkrp", g_yrp._not )
  return {}
end

function Player:getWantedReason()
  --Description: Get the reason why someone is wanted
  printGM( "darkrp", "getWantedReason()" )
  printGM( "darkrp", g_yrp._not )
  return "old getWantedReason"
end

function Player:hasDarkRPPrivilege( priv )
  --Description: Whether the player has a certain privilege.
  printGM( "darkrp", "hasDarkRPPrivilege( " .. tostring( priv ) .. " )" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:hasHit()
  --Description: Whether this hitman has a hit.
  printGM( "darkrp", "hasHit()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isArrested()
  --Description: Whether this player is arrested
  --printGM( "darkrp", "isArrested()" )
  return self:GetNWBool( "inJail", false )
end

function Player:isChief()
  --Description: Whether this player is a Chief.
  printGM( "darkrp", "isChief()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isCook()
  --Description: Whether this player is a cook. This function is only available if hungermod is enabled.
  printGM( "darkrp", "isCook()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isCP()
  --Description: Whether this player is part of the police force (mayor, cp, chief).
  printGM( "darkrp", "isCP()" )
  printGM( "darkrp", g_yrp._not )
  return true
end

function Player:isHitman()
  --Description: Whether this player is a hitman.
  printGM( "darkrp", "isHitman()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isMayor()
  --Description: Whether this player is a mayor.
  printGM( "darkrp", "isMayor()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isMedic()
  --Description: Whether this player is a medic.
  printGM( "darkrp", "isMedic()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:isWanted()
  --Description: Whether this player is wanted
  printGM( "darkrp", "isWanted()" )
  printGM( "darkrp", g_yrp._not )
  return false
end

function Player:nickSortedPlayers()
  --Description: A table of players sorted by RP name.
  printGM( "darkrp", "nickSortedPlayers()" )
  printGM( "darkrp", g_yrp._not )
  return {}
end