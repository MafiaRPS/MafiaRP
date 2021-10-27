--Copyright (C) 2017-2021 D4KiR (https://www.gnu.org/licenses/gpl.txt)

-- #SENDISREADY #READY #PLAYERISREADY #ISREADY

YRPStartDataStatus = YRPStartDataStatus or "WAITING"
YRPStartDataTab = YRPStartDataTab or {}
YRPRetryCounter = YRPRetryCounter or 0

YRPReceivedStartData = YRPReceivedStartData or false
local langonce = true

local function YRPReadyHR( col )
	MsgC( col, "-------------------------------------------------------------------------------" .. "\n" )
end

local function YRPReadyMSG( msg, col )
	col = col or Color( 255, 100, 100 )
	YRPReadyHR( col )
	MsgC( col, "> " .. msg .. "\n" )
	YRPReadyHR( col )
end

function YRPGetClientInfo()
	local info = {}
	if system.IsWindows() then
		info.os = 0
	elseif system.IsLinux() then
		info.os = 1
	elseif system.IsOSX() then
		info.os = 2
	else
		info.os = 3
	end
	info.country = system.GetCountry()
	info.branch = GetBranch()
	return info
end

local function YRPAddReadyStatusMsg( msg )
	YRPStartDataTab = YRPStartDataTab or {}
	if !table.HasValue( YRPStartDataTab, msg ) then
		table.insert( YRPStartDataTab, msg )
	end
	YRPStartDataStatus = table.concat( YRPStartDataTab, ", " )
end

function YRPSendAskData()
	YRPRetryCounter = YRPRetryCounter + 1
	if CurTime() <= 0 then
		YRPHR( Color( 255, 0, 0 ) )
		MsgC( Color( 255, 0, 0 ), "[START] CurTime() is 0, Retry..." .. "\n" )
		YRPHR( Color( 255, 0, 0 ) )
		return
	end

	if !IsValid( LocalPlayer() ) then
		YRPHR( Color( 255, 0, 0 ) )
		MsgC( Color( 255, 0, 0 ), "[START] LocalPlayer() is Invalid, Retry..." .. "\n" )
		YRPHR( Color( 255, 0, 0 ) )
		return
	end

	local info = YRPGetClientInfo()

	YRPAddReadyStatusMsg( "Send" )
	
	net.Start("sendstartdata")
		net.WriteUInt( info.os, 2 )
		net.WriteString( info.branch )
		net.WriteString( info.country )
	net.SendToServer()

	MsgC( Color( 0, 255, 0 ), "[START] Sended StartData" .. "\n" )

	timer.Simple( 1, function()
		if YRPReceivedStartData or LocalPlayer():GetNW2Bool( "yrp_received_ready", false ) then
			--
		elseif YRPReceivedStartData == false and LocalPlayer():GetNW2Bool( "yrp_received_ready", false ) == false then
			YRPAddReadyStatusMsg( "SERVER NOT RECEIVED -> RETRY" )
			local text = "[START] Server not received the StartData, retry..."
			MsgC( Color( 255, 255, 0 ), text .. "\n" )
		end
	end )

	if langonce then
		langonce = false
		YRP.initLang()
	end
end

net.Receive( "askforstartdata", function( len )
	YRPSendAskData()
end )

net.Receive( "YRPReceivedStartData", function( len )
	YRPReceivedStartData = true
	YRPHR( Color( 0, 255, 0 ) )
	MsgC( Color( 0, 255, 0 ), "[START] Server RECEIVED StartData" .. "\n" )

	YRPAddReadyStatusMsg( "SERVER RESPONDED" )
	YRPHR( Color( 0, 255, 0 ) )

	YRP.initLang()
end )
