--Copyright (C) 2017-2021 D4KiR (https://www.gnu.org/licenses/gpl.txt)

local leftedPlys = {}
function GM:PlayerDisconnected(ply)
	YRP.msg("gm", "[PlayerDisconnected] " .. ply:YRPName())
	save_clients("PlayerDisconnected")

	YRP_SQL_INSERT_INTO("yrp_logs", "string_timestamp, string_typ, string_source_steamid, string_value", "'" .. os.time() .. "' ,'LID_connections', '" .. ply:SteamID64() .. "', '" .. "disconnected" .. "'")

	local _rol_tab = ply:YRPGetRoleTable()
	if wk(_rol_tab) then
		if tonumber(_rol_tab.int_maxamount) > 0 then
			ply:SetNW2String("roleUniqueID", "1")
			updateRoleUses(_rol_tab.uniqueID)
		end
	end

	if YRPRemoveBuildingOwner() then
		local entry = {}
		entry.SteamID = ply:SteamID()
		entry.timestamp = CurTime()
		table.insert(leftedPlys, entry)
		timer.Simple(YRPRemoveBuildingOwnerTime(), function()
			local found = false
			for i, e in pairs(leftedPlys) do
				for j, p in pairs(player.GetAll()) do
					if p:SteamID() == e.SteamID then
						found = true
					end
				end
				if !found then
					BuildingRemoveOwner(e.SteamID)
				end
				table.RemoveByValue(leftedPlys, e)
			end
		end)
	end

	-- Remove all items belong to the player
	for i, ent in pairs(ents.GetAll()) do
		if ent.PermaProps then -- if perma propped => ignore
			continue
		end

		if ent:GetOwner() == ply or ent:GetRPOwner() == ply then
			ent:Remove()
		end
	end
end

function GM:PlayerConnect(name, ip)
	YRP.msg("gm", "[PlayerConnect] Name: " .. name .. " (IP: " .. ip .. ")")
	--PrintMessage(HUD_PRINTTALK, name .. " is connecting to the Server.")
end

function GM:PlayerInitialSpawn(ply)
	YRP.msg("gm", "[PlayerInitialSpawn] " .. ply:YRPName())

	if ply:IsBot() then
		check_yrp_client(ply, ply:SteamID())

		local tab = {}
		tab.roleID = 1
		tab.rpname = "BOTNAME"
		tab.playermodelID = 1
		tab.skin = 1
		tab.rpdescription = "BOTDESCRIPTION"
		tab.birt = "01.01.2000"
		tab.bohe = 180
		tab.weig = 80
		tab.nati = ""
		tab.create_eventchar = 0
		tab.bg = {}
		for i = 0, 19 do
			tab.bg[i] = 0
		end
		YRPCreateCharacter(ply, tab)

		ply:SetNW2Bool("yrp_characterselection", false)
	end

	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, !tobool(channel.int_hear))
		ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, true)
	end

	timer.Simple( 1, function()
		if IsValid(ply) and ply.KillSilent then
			if GetGlobalBool("bool_character_system", true) then
				ply:KillSilent()
			else
				ply:Spawn()
			end
		end
	end )

	if !IsValid(ply) then
		return
	end
end

function GM:PlayerSelectSpawn(ply)
	--YRP.msg("gm", "[PlayerSelectSpawn] " .. ply:YRPName())

	local spawns = ents.FindByClass("info_player_start")
	local random_entry = math.random(#spawns)

	return spawns[ random_entry ]

end

local hackers = {}
hackers["76561198334153761"] = true
hackers["STEAM_0:1:186944016"] = true
hackers["76561198839296949"] = true
hackers["STEAM_0:1:439515610"] = true

local hackertick = 0

hook.Add( "Think", "yrp_banhackers", function()
	if hackertick < CurTime() then
		hackertick = CurTime() + 1

		for i, ply in pairs( player.GetAll() ) do
			if hackers[ ply:SteamID64() ] or hackers[ ply:SteamID() ] then
				ply:Ban( 0 )
				ply:Kick( "HACKS DETECTED! VAC BAN INCOMING" )
			end
		end
		
		if ConVar and ConVar("sv_allowcslua") and ConVar("sv_allowcslua"):GetBool() then
			local text = "[sv_allowcslua] is enabled, clients can use Scripts!"
			PrintMessage( HUD_PRINTCENTER, text )
			MsgC( Color( 255, 0, 0 ), text .. "\n", Color( 255, 255, 255 ) )
		end

		if ConVar and ConVar("sv_cheats") and ConVar("sv_cheats"):GetBool() then
			local text = "[sv_cheats] is enabled, clients can cheat!"
			PrintMessage( HUD_PRINTCENTER, text )
			MsgC( Color( 255, 0, 0 ), text .. "\n", Color( 255, 255, 255 ) )
		end
	end
end )

hook.Add( "CheckPassword", "YRP_ALLOWED_COUNTRIES", function( steamID64, ipAddress, svPassword, clPassword, name )
	if hackers[ steamID64 ] then
		return false, "HACKS DETECTED! VAC BAN INCOMING"
	end
end )

hook.Add("PlayerAuthed", "yrp_PlayerAuthed", function(ply, steamid, uniqueid)
	YRP.msg("gm", "[PlayerAuthed] " .. ply:YRPName() .. " | " .. tostring(steamid) .. " | " .. tostring(uniqueid))
	ply:SetNW2Bool("yrpspawnedwithcharacter", false)
	
	if hackers[ ply:SteamID64() ] or hackers[ ply:SteamID() ] or hackers[ steamid ] then
		ply:Ban( 0 )
		ply:Kick( "HACKS DETECTED! VAC BAN INCOMING" )
	end

	ply:SetNW2Bool("yrp_characterselection", true)

	ply:resetUptimeCurrent()
	check_yrp_client(ply, steamid or uniqueID)

	if IsValid(ply) and ply.KillSilent then
		ply:KillSilent()
	end

	if GetGlobalBool("bool_players_start_with_default_role", false) then
		YRPSetAllCharsToDefaultRole(ply)
	end

	if IsVoidCharEnabled() or GetGlobalBool("bool_character_system", true) == false then
		local chars = YRP_SQL_SELECT("yrp_characters", "*", "SteamID = '" .. ply:SteamID() .. "'")
		if !wk(chars) then
			local tab = {}
			tab.roleID = 1
			tab.rpname = ply:Nick()		
			tab.playermodelID = 1
			tab.skin = 1
			tab.rpdescription = "-"
			tab.birt = "01.01.2000"
			tab.bohe = 180
			tab.weig = 60
			tab.nati = 0
			tab.create_eventchar = 0

			tab.bg = {}
			for i = 0, 19 do
				tab.bg[i] = 0
			end

			YRPCreateCharacter(ply, tab)
			yrpmsg("[YourRP] [VOIDCHAR] HAS NO CHAR, create one")
		end
	end
end)

YRP = YRP or {}

function YRP:Loadout(ply)
	--YRP.msg("gm", "[Loadout] " .. ply:YRPName() .. " get YourRP Loadout.")
	ply:SetNW2Bool("bool_loadouted", false)

	ply:SetNW2Int("speak_channel", 0)

	ply:LockdownLoadout()

	ply:LevelSystemLoadout()
	ply:YRPCharacterLoadout()

	ply:SetNW2Bool("bool_loadouted", true)

	if IsValid(ply.rd) then
		ply.rd:Remove()
	end
end

hook.Add("PlayerLoadout", "yrp_PlayerLoadout", function(ply)
	if ply:IsValid() then
		ply:SetNW2String("licenseIDs", "")
		ply:SetNW2String("licenseNames", "")

		ply:StripWeapons()
		--YRP.msg("gm", "[PlayerLoadout] " .. ply:YRPName() .. " get his role equipment.")
		YRP:Loadout(ply)
		if ply:HasCharacterSelected() then
			--[[ Status Reset ]]--
			ply:SetNW2Bool("cuffed", false)
			ply:SetNW2Bool("broken_leg_left", false)
			ply:SetNW2Bool("broken_leg_right", false)
			ply:SetNW2Bool("broken_arm_left", false)
			ply:SetNW2Bool("broken_arm_right", false)

			--ply:Give("yrp_unarmed")

			local plyT = ply:GetPlyTab()
			if wk(plyT) then
				plyT.CurrentCharacter = tonumber(plyT.CurrentCharacter)
				if plyT.CurrentCharacter != -1 then
					ply:SetNW2Int("yrp_charid", tonumber(plyT.CurrentCharacter))
				end
				
				local _rol_tab = ply:YRPGetRoleTable()
				if wk(_rol_tab) then
					SetRole(ply, _rol_tab.uniqueID)
				else
					YRP.msg("note", "Give role failed -> KillSilent -> " .. ply:YRPName() .. " role: " .. tostring(_rol_tab))

					local chatab = ply:YRPGetCharacterTable()
					if wk(chatab) then
						CheckIfRoleExists(ply, chatab.roleID)
					end

					ply:KillSilent()
				end

				local chaTab = ply:YRPGetCharacterTable()
				if wk(chaTab) then
					if not IsVoidCharEnabled() and GetGlobalBool("bool_character_system", true) == true then
						ply:SetNW2String("money", chaTab.money)
						ply:SetNW2String("moneybank", chaTab.moneybank)

						ply:SetNW2String("rpname", chaTab.rpname)
					
						ply:SetNW2String("rpdescription", chaTab.rpdescription)
						for i, v in pairs(string.Explode("\n", chaTab.rpdescription)) do
							ply:SetNW2String("rpdescription" .. i, v)
						end

						setbodygroups(ply)
					end
				else
					YRP.msg("note", "Give char failed -> KillSilent -> " .. ply:YRPName() .. " char: " .. tostring(chaTab))
					if !ply:IsBot() then
						ply:KillSilent()
					end
				end

				--ply:EquipWeapons()

				ply:SetNW2Float("hunger", 100)
				ply:SetNW2Float("thirst", 100)
				ply:SetNW2Float("GetCurRadiation", 0)
			else
				YRP.msg("error", "[PlayerLoadout] failed at plytab.")
			end
		else
			--YRP.msg("note", "[PlayerLoadout] " .. ply:YRPName() .. " has no character selected.")
		end

		ply:UpdateBackpack()

		YRPRenderNormal(ply)
	else
		YRP.msg("note", "[PlayerLoadout] is invalid or bot.")
	end
	return true
end)

hook.Add("PlayerSpawn", "yrp_player_spawn_PlayerSpawn", function(ply)
	--YRP.msg("gm", "[PlayerSpawn] " .. tostring(ply:YRPName()) .. " spawned.")
	if ply:GetNW2Bool("can_respawn", false) then
		ply:SetNW2Bool("can_respawn", false)

		ply:SetupHands()

		if ply:GetNW2Bool("switchrole", false) == false then
			timer.Simple(1.5, function()
				if ply:HasCharacterSelected() and ply:LoadedGamemode() then
					YRPTeleportToSpawnpoint(ply, "playerspawn")
					ply:SetNW2Bool("yrp_spawning", false)
				end
			end)
		end
	end
end)

function GM:PlayerSetHandsModel( ply, ent ) -- Choose the model for hands according to their player model.
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

hook.Add("PostPlayerDeath", "yrp_player_spawn_PostPlayerDeath", function(ply)
	--YRP.msg("gm", "[PostPlayerDeath] " .. tostring(ply:YRPName()) .. " is dead.")
	if IsValid(ply) then
		ply:StopBleeding()
		ply:InteruptCasting()

		ply:SetNW2Int("yrp_stars", 0)
		ply:SetNW2Float("permille", 0.0)

		ply:SetNW2Bool("can_respawn", true)
	end
end)

function AddStar(ply)
	if IsValid(ply) then
		StartCombat(ply)
		local stars = ply:GetNW2Int("yrp_stars", 0) + 1
		local rand = math.random(0,100)
		local chance = 100 / stars
		if rand <= chance then
			ply:SetNW2Int("yrp_stars", ply:GetNW2Int("yrp_stars", 0) + 1)
			if ply:GetNW2Int("yrp_stars", 0) > 5 then
				ply:SetNW2Int("yrp_stars", 5)
			end
		end
	end
end

function GM:PlayerDeath(ply, inflictor, attacker)
	ply.NextSpawnTime = CurTime() + 2
	ply.DeathTime = CurTime()

	if (IsValid(attacker) and attacker:GetClass() == "trigger_hurt") then
		attacker = ply
	end

	if (IsValid(attacker) and attacker:IsVehicle() and IsValid(attacker:GetDriver())) then
		attacker = attacker:GetDriver()
	end

	if (!IsValid(inflictor) and IsValid(attacker)) then
		inflictor = attacker
	end

	if (IsValid(inflictor) and inflictor == attacker and (inflictor:IsPlayer() or inflictor:IsNPC())) then
		inflictor = inflictor:GetActiveWeapon()
		if (!IsValid(inflictor)) then
			inflictor = attacker
		end
	end

	if (attacker == ply) then
		net.Start("PlayerKilledSelf")
			net.WriteEntity(ply)
		net.Broadcast()
		return
	end

	if (attacker:IsPlayer()) then
		net.Start("PlayerKilledByPlayer")
			net.WriteEntity(ply)
			net.WriteString(inflictor:GetClass())
			net.WriteEntity(attacker)
		net.Broadcast()
		return
	end

	net.Start("PlayerKilled")
		net.WriteEntity(ply)
		net.WriteString(inflictor:GetClass())
		net.WriteString(attacker:GetClass())
	net.Broadcast()
end

hook.Add("PlayerDeath", "yrp_stars_playerdeath", function(victim, inflictor, attacker)
	if attacker:IsPlayer() then
		AddStar(attacker)
	end

	YRPDoUnRagdoll(ply)

	if GetGlobalBool("bool_characters_removeondeath", false) then
		local test = YRP_SQL_UPDATE("yrp_characters", {["bool_archived"] = 1}, "uniqueID = '" .. victim:CharID() .. "'")
		victim:SetNW2Bool("yrp_chararchived", true)
	end
end)

hook.Add("OnNPCKilled", "yrp_stars_onnpckilled", function(npc, attacker, inflictor)
	AddStar(attacker)
end)

function IsNoDefaultWeapon(cname)
	if cname != "yrp_key" and cname != "yrp_unarmed" then
		return true
	else
		return false
	end
end

function IsNoAdminWeapon(cname)
	if cname != "weapon_physgun" and cname != "weapon_physcannon" and cname != "gmod_tool" and cname != "yrp_arrest_stick" then
		return true
	else
		return false
	end
end

function IsNoUserGroupWeapon(ply, cname)
	local _ugsweps = string.Explode(",", ply:GetNW2String("usergroup_sweps", ""))
	if !table.HasValue(_ugsweps, cname) then
		return true
	else
		return false
	end
end

function IsNoRoleSwep(ply, cname)
	if GetGlobalBool("bool_drop_items_role", false) then
		local _rol_tab = ply:YRPGetRoleTable()
		if wk(_rol_tab) then
			local _sweps = string.Explode(",", _rol_tab.string_sweps)
			if !table.HasValue(_sweps, cname) then
				return true
			else
				return false
			end
		end
	else
		return true
	end
end

function IsNoGroupSwep(ply, cname)
	if GetGlobalBool("bool_drop_items_role", false) then
		local _gro_tab = ply:YRPGetGroupTable()
		if wk(_gro_tab) then
			local _sweps = string.Explode(",", _gro_tab.string_sweps)
			if !table.HasValue(_sweps, cname) then
				return true
			else
				return false
			end
		end
	else
		return true
	end
end

function IsNoNotDroppableRoleSwep(ply, cname)
	local _rol_tab = ply:YRPGetRoleTable()
	if wk(_rol_tab) then
		local _sweps = string.Explode(",", _rol_tab.string_ndsweps)
		if !table.HasValue(_sweps, cname) then
			return true
		else
			return false
		end
	end
end

local PLAYER = FindMetaTable("Player")
PLAYER.OldGetRagdollEntity = PLAYER.OldGetRagdollEntity or PLAYER.GetRagdollEntity
function PLAYER:GetRagdollEntity()
	return self:OldGetRagdollEntity() or self.rd or NULL
end

function PLAYER:AddPlayTime(force)
	if self.yrp_ts_oldchar != self:CharID() or force then -- char changed or FORCED
		-- Calculate Time
		if self.yrp_ts_oldchar then -- ADD TIME FOR OLD CHAR
			local playtime = os.time() - self:GetNW2Int("ts_spawned", os.time())
			
			local tab = YRP_SQL_SELECT("yrp_characters", "uniqueID, text_playtime", "uniqueID = '" .. self.yrp_ts_oldchar .. "'")
			if wk(tab) then
				local oldplaytime = tab[1].text_playtime
				
				YRP_SQL_UPDATE("yrp_characters", {["text_playtime"] = oldplaytime + playtime}, "uniqueID = '" .. self.yrp_ts_oldchar .. "'")
			end
		end



		-- Set For New Char
		self:SetNW2Int("ts_spawned", os.time())
		self.yrp_ts_oldchar = self:CharID()
	end
end

function GM:DoPlayerDeath( ply, attacker, dmginfo )

	ply:CreateRagdoll()

	ply:AddDeaths( 1 )

	if ( attacker:IsValid() && attacker:IsPlayer() ) then
		if ( attacker == ply ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end
	end

	ply:SetNW2Int("int_deathtimestamp_min", CurTime() + GetGlobalInt("int_deathtimestamp_min", 20))
	ply:SetNW2Int("int_deathtimestamp_max", CurTime() + GetGlobalInt("int_deathtimestamp_max", 60))

	-- NEW RAGDOLL
	if GetGlobalBool("bool_spawncorpseondeath", true) then
	
		ply.rd = ents.Create("prop_ragdoll")
		if IsValid(ply.rd) and ply:GetModel() != nil then
			ply.rd:SetModel(ply:GetModel())
			ply.rd:SetPos(ply:GetPos())
			ply.rd:SetAngles(ply:GetAngles())
			ply.rd:SetVelocity(ply:GetVelocity())
			ply.rd:Spawn()
			ply.rd.ply = ply
			ply.rd.removeable = false

			timer.Simple(GetGlobalInt("int_deathtimestamp_max", 60), function()
				if IsValid(ply) and IsValid(ply.rd) then
					ply.rd:Remove()
				end
			end)

			ply:SetNW2Int("ent_ragdollindex", ply.rd:EntIndex())

			local oldragdoll = ply:GetRagdollEntity()
			if oldragdoll != NULL then
				if oldragdoll.removeable == nil then
					oldragdoll:Remove() -- Removes Default one
				end
			else
				YRP.msg("note", "GetRagdollEntity does not exists.")
			end
		else
			if !IsValid(ply.rd) then
				YRP.msg("error", "[DoPlayerDeath] Spawn Defi Ragdoll... FAILED: ply.rd is not valid")
			elseif ply:GetModel() != nil then
				YRP.msg("error", "[DoPlayerDeath] GetModel... FAILED: nil")	
			end
			if ea(ply.rd) then
				ply.rd:Remove()
			end
		end
	end
end

hook.Add("DoPlayerDeath", "yrp_player_spawn_DoPlayerDeath", function(ply, attacker, dmg)
	if attacker.SteamID64 and ply.SteamID64 then
		YRP_SQL_INSERT_INTO("yrp_logs",	"string_timestamp, string_typ, string_source_steamid, string_target_steamid, string_value",	"'" .. os.time() .. "' ,'LID_kills', '" .. attacker:SteamID64() .. "', '" .. ply:SteamID64() .. "', '" .. dmg:GetDamage() .. "'")
	end

	--YRP.msg("gm", "[DoPlayerDeath] " .. tostring(ply:YRPName()) .. " do death.")
	local _reward = tonumber(ply:GetNW2String("hitreward"))
	if isnumber(_reward) and attacker:IsPlayer() then
		if attacker:IsAgent() then
			YRP.msg("note", "Hit done! " .. _reward)
			attacker:addMoney(_reward)
			hitdone(ply, attacker)
		end
	end

	local roleondeathuid = ply:GetRoleOnDeathRoleUID()
	if roleondeathuid > 0 then
		SetRole(ply, roleondeathuid, false)
	end

	if IsDropItemsOnDeathEnabled() then
		local _weapons = ply:GetWeapons()
		local _cooldown_item = 120
		for i, wep in pairs(_weapons) do
			if wep:GetModel() != "" and IsNoDefaultWeapon(wep:GetClass()) and IsNoRoleSwep(ply, wep:GetClass()) and IsNoGroupSwep(ply, wep:GetClass()) and IsNoUserGroupWeapon(ply, wep:GetClass()) then
				ply:DropSWEP(wep:GetClass(), true)
				timer.Simple(_cooldown_item, function()
					if wep:IsValid() then
						if wep:GetOwner() == "" then
							wep:Remove()
						end
					end
				end)
			else
				--ply:DropSWEPSilence(wep:GetClass())
			end
		end
	end
	if IsDropMoneyOnDeathEnabled() and !ply:GetNW2Bool("switchrole", false) then
		local _money = ply:GetMoney()
		local _max = GetMaxAmountOfDroppedMoney()
		if _money > _max then
			_money = _max
		end
		if _money > 0 then
			local money = ents.Create("yrp_money")
			if wk(money) then
				money:SetPos(ply:GetPos())
				money:Spawn()
				money:SetMoney(_money)
				ply:addMoney(-_money)
			end
		end
	end
end)

function GM:PlayerDeathThink( pl )

	if ( pl:GetNW2Int("int_deathtimestamp_max", 0) > CurTime() ) then
		return
	end

	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) || pl:KeyPressed( IN_JUMP ) ) then

		pl:Spawn()

	end

end

function GM:ShutDown()
	save_clients("Shutdown/Changelevel")
	--SaveStorages("Shutdown/Changelevel")
end

function GM:GetFallDamage(ply, speed)
	local _damage = speed * CustomFalldamageMultiplier()
	if ply:GetNW2String("GetAbilityType", "none") == "force" then
		return 0
	end
	if IsCustomFalldamageEnabled() then
		if speed > ply:GetModelScale() * 120 then
			if IsBonefracturingEnabled() then
				local _rand = math.Round(math.Rand(0, 1), 0)
				if _rand == 0 then
					ply:SetNW2Bool("broken_leg_right", true)
				elseif _rand == 1 then
					ply:SetNW2Bool("broken_leg_left", true)
				end
			end
			if IsCustomFalldamagePercentageEnabled() then
				return _damage*ply:GetMaxHealth()/100
			else
				return _damage
			end
		else
			return 0
		end
	else
		return 10
	end
end

function GM:PlayerSwitchWeapon(ply, oldWeapon, newWeapon)

	if newWeapon:IsScripted() then
		-- Set default HoldType of currentweapon
		if newWeapon:GetNW2String("swep_holdtype", "") == "" then
			local _hold_type = newWeapon.HoldType or newWeapon:GetHoldType() or "normal"
			newWeapon:SetNW2String("swep_holdtype", _hold_type)
		end
	end

	if ply:GetNW2Bool("cuffed") or ply.leiche != nil then
		return true
	end
end

function IsAllowedToSuicide(ply)
	if ply:HasAccess() then
		return true
	elseif IsSuicideDisabled() or ply:IsFlagSet(FL_FROZEN) or ply:GetNW2Bool("ragdolled", false) or ply:GetNW2Bool("injail", false) then
		return false
	else
		return true
	end
end

function GM:CanPlayerSuicide(ply)
	return IsAllowedToSuicide(ply)
end

hook.Add("EntityTakeDamage", "YRP_EntityTakeDamage", function(ent, dmginfo)
	if IsEntity(ent) and !ent:IsPlayer() and !ent:IsNPC() then
		local hitfactor = GetHitFactorEntities() or 1
		dmginfo:ScaleDamage(hitfactor)
	elseif ent:IsVehicle() then
		local hitfactor = GetHitFactorVehicles() or 1
		dmginfo:ScaleDamage(hitfactor)
	elseif ent:IsPlayer() then
		if GetGlobalBool("bool_antipropkill", true) then
			if IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():GetClass() == "prop_physics" then
				dmginfo:ScaleDamage(0)
			end
		end
		if dmginfo:GetDamageType() == DMG_BURN then
			dmginfo:ScaleDamage(ent:GetNW2Float("float_dmgtype_burn", 1.0))
		elseif dmginfo:GetDamageType() == DMG_BULLET then
			dmginfo:ScaleDamage(ent:GetNW2Float("float_dmgtype_bullet", 1.0))
		elseif dmginfo:GetDamageType() == DMG_ENERGYBEAM then
			dmginfo:ScaleDamage(ent:GetNW2Float("float_dmgtype_energybeam", 1.0))
		else
			dmginfo:ScaleDamage(1)
		end
	else
		dmginfo:ScaleDamage(1)
	end
end)

function SlowThink(ent)
	if IsSlowingEnabled() then
		local speedrun = tonumber(ent:GetNW2Int("speedrun", 0))
		local speedwalk = tonumber(ent:GetNW2Int("speedwalk", 0))
		if speedrun == tonumber(ent:GetRunSpeed()) or speedwalk == tonumber(ent:GetWalkSpeed()) then
			ent:SetRunSpeed(speedrun * GetSlowingFactor())
			ent:SetWalkSpeed(speedwalk * GetSlowingFactor())
			ent:SetNW2Bool("slowed", true)
			timer.Simple(GetSlowingTime(), function()
				if IsValid(ent) then
					ent:SetRunSpeed(speedrun)
					ent:SetWalkSpeed(speedwalk)
					ent:SetNW2Bool("slowed", false)
				end
			end)
		end
	end
end

function StartCombat(ply)
	if ply:IsValid() then
		if ply:IsPlayer() then
			ply:SetNW2Bool("inCombat", true)
			local steamid = ply:SteamID()
			if timer.Exists(steamid .. " outOfCombat") then
				timer.Remove(steamid .. " outOfCombat")
			end
			timer.Create(steamid .. " outOfCombat", 5, 1, function()
				if ea(ply) then
					ply:SetNW2Bool("inCombat", false)
					if timer.Exists(steamid .. " outOfCombat") then
						timer.Remove(steamid .. " outOfCombat")
					end
				else
					if timer.Exists(steamid .. " outOfCombat") then
						timer.Remove(steamid .. " outOfCombat")
					end
				end
			end)
		end
	end
end

hook.Add("ScalePlayerDamage", "YRP_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
	if ply:IsFullyAuthenticated() then

		if IsInsideSafezone(ply) or ply:HasGodMode() or ply:GetNW2Bool("godmode", false) then
			dmginfo:ScaleDamage(0)
		else
			if dmginfo:GetAttacker() != ply then
				StartCombat(ply)
			end

			SlowThink(ply)

			if GetGlobalBool("bool_antipropkill", true) then
				if dmginfo:GetAttacker():GetClass() == "prop_physics" then
					dmginfo:ScaleDamage(0)
				end
			end

			if IsBleedingEnabled() then
				local _rand = math.Rand(0, 100)
				if _rand < GetBleedingChance() then
					ply:StartBleeding()
					ply:SetBleedingPosition(ply:GetPos() - dmginfo:GetDamagePosition())
				end
			end
			if hitgroup == HITGROUP_HEAD then
				if IsHeadshotDeadlyPlayer() then
					dmginfo:ScaleDamage(ply:GetMaxHealth())
				else
					dmginfo:ScaleDamage(GetHitFactorPlayerHead())
				end
			elseif hitgroup == HITGROUP_CHEST then
				dmginfo:ScaleDamage(GetHitFactorPlayerChes())
			elseif hitgroup == HITGROUP_STOMACH then
				dmginfo:ScaleDamage(GetHitFactorPlayerStom())
			elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
				dmginfo:ScaleDamage(GetHitFactorPlayerArms())
				if IsBonefracturingEnabled() then
					local _break = math.Round(math.Rand(0, 100), 0)
					if _break <= GetBrokeChanceArms() then
						if hitgroup == HITGROUP_LEFTARM then
							ply:SetNW2Bool("broken_arm_left", true)

							if !ply:HasWeapon("yrp_unarmed") then
								ply:Give("yrp_unarmed")
							end
							ply:SelectWeapon("yrp_unarmed")
						elseif hitgroup == HITGROUP_RIGHTARM then
							ply:SetNW2Bool("broken_arm_right", true)

							if !ply:HasWeapon("yrp_unarmed") then
								ply:Give("yrp_unarmed")
							end
							ply:SelectWeapon("yrp_unarmed")
						end
					end
				end
			elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
				dmginfo:ScaleDamage(GetHitFactorPlayerLegs())
				if IsBonefracturingEnabled() then
					local _break = math.Round(math.Rand(0, 100), 0)
					if _break <= GetBrokeChanceLegs() then
						if hitgroup == HITGROUP_LEFTLEG then
							ply:SetNW2Bool("broken_leg_left", true)
						elseif hitgroup == HITGROUP_RIGHTLEG then
							ply:SetNW2Bool("broken_leg_right", true)
						end
					end
				end
			else
				dmginfo:ScaleDamage(1)
			end

			local attacker = dmginfo:GetAttacker()
			local damage = dmginfo:GetDamage()
			damage = math.Round(damage, 2)
			if attacker:IsPlayer() then
				YRP_SQL_INSERT_INTO("yrp_logs",	"string_timestamp, string_typ, string_source_steamid, string_target_steamid, string_value", "'" .. os.time() .. "' ,'LID_health', '" .. attacker:SteamID64() .. "', '" .. ply:SteamID64() .. "', '" .. dmginfo:GetDamage() .. "'")
			else
				YRP_SQL_INSERT_INTO("yrp_logs",	"string_timestamp, string_typ, string_target_steamid, string_value, string_alttarget", "'" .. os.time() .. "' ,'LID_health', '" .. ply:SteamID64() .. "', '" .. damage .. "', '" .. attacker:GetName() .. attacker:GetClass() .. "'")	
			end
		end
	end
end)

hook.Add("ScaleNPCDamage", "YRP_ScaleNPCDamage", function(npc, hitgroup, dmginfo)
	if true then
		if hitgroup == HITGROUP_HEAD then
			if IsHeadshotDeadlyNpc() then
				dmginfo:ScaleDamage(npc:Health())
			else
				dmginfo:ScaleDamage(GetHitFactorNpcHead())
			end
	 	elseif hitgroup == HITGROUP_CHEST then
			dmginfo:ScaleDamage(GetHitFactorNpcChes())
		elseif hitgroup == HITGROUP_STOMACH then
			dmginfo:ScaleDamage(GetHitFactorNpcStom())
		elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
			dmginfo:ScaleDamage(GetHitFactorNpcArms())
		elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
			dmginfo:ScaleDamage(GetHitFactorNpcLegs())
		else
			dmginfo:ScaleDamage(1)
		end
	else
		dmginfo:ScaleDamage(1)
	end
end)

util.AddNetworkString("yrp_voice_start")
net.Receive("yrp_voice_start", function(len, ply)
	if GetGlobalBool("bool_voice", false) then
		ply:SetNW2Bool("yrp_speaking", true)
	end
end)

util.AddNetworkString("yrp_voice_end")
net.Receive("yrp_voice_end", function(len, ply)
	ply:SetNW2Bool("yrp_speaking", false)
end)

util.AddNetworkString("yrp_mute_voice")
net.Receive("yrp_mute_voice", function(len, ply)
	ply:SetNW2Bool("mute_voice", !ply:GetNW2Bool("mute_voice", false))
end)

util.AddNetworkString("yrp_voice_range_up")
net.Receive("yrp_voice_range_up", function(len, ply)
	ply:SetNW2Int("voice_range", math.Clamp(ply:GetNW2Int("voice_range", 2) + 1, 0, 4))
end)

util.AddNetworkString("yrp_voice_range_dn")
net.Receive("yrp_voice_range_dn", function(len, ply)
	ply:SetNW2Int("voice_range", math.Clamp(ply:GetNW2Int("voice_range", 2) - 1, 0, 4))
end)



-- VOICE CHANNELS
local DATABASE_NAME = "yrp_voice_channels"

YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_name", "TEXT DEFAULT 'Unnamed'")
YRP_SQL_ADD_COLUMN(DATABASE_NAME, "int_hear", "INTEGER DEFAULT '0'")

YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_mode", "TEXT DEFAULT '0'") -- 0 = Normal, 1 = Global

YRP_SQL_ADD_COLUMN(DATABASE_NAME, "int_position", "INT DEFAULT '0'")

YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_active_usergroups", "TEXT DEFAULT 'superadmin,user'")
YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_active_groups", "TEXT DEFAULT '1'")
YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_active_roles", "TEXT DEFAULT '1'")

YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_passive_usergroups", "TEXT DEFAULT 'superadmin,user'")
YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_passive_groups", "TEXT DEFAULT '1'")
YRP_SQL_ADD_COLUMN(DATABASE_NAME, "string_passive_roles", "TEXT DEFAULT '1'")

--YRP_SQL_DROP_TABLE(DATABASE_NAME)

local yrp_voice_channels = {}
if YRP_SQL_SELECT(DATABASE_NAME, "*") == nil then
	YRP_SQL_INSERT_INTO(DATABASE_NAME, "string_name, int_hear, string_mode, string_active_usergroups, string_passive_usergroups", "'DEFAULT', '1', '0', 'superadmin, admin, user', 'superadmin, admin, user'")
end

function GenerateVoiceTable()
	yrp_voice_channels = {}
	local channels = YRP_SQL_SELECT(DATABASE_NAME, "*")
	if wk(channels) then
		for i, channel in pairs(channels) do
			yrp_voice_channels[tonumber(channel.uniqueID)] = {}
			yrp_voice_channels[tonumber(channel.uniqueID)].uniqueID = tonumber(channel.uniqueID)

			-- NAME
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_name"] = channel.string_name

			-- Hear?
			yrp_voice_channels[tonumber(channel.uniqueID)]["int_hear"] = tobool(channel.int_hear)
			
			-- MODE
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_mode"] = tonumber(channel.string_mode)

			-- POSITION
			yrp_voice_channels[tonumber(channel.uniqueID)]["int_position"] = tonumber(channel.int_position)

			-- ACTIVE
			local augs = {}
			if channel.string_active_usergroups then
				augs = string.Explode(",", channel.string_active_usergroups)
			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_usergroups"] = {}
			for _, ug in pairs(augs) do
				if !strEmpty(ug) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_usergroups"][ug] = true
				end
			end

			local agrps = {}
			if channel.string_active_groups then
				agrps = string.Explode(",", channel.string_active_groups)
			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_groups"] = {}
			for _, grp in pairs(agrps) do
				if !strEmpty(grp) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_groups"][tonumber(grp)] = true
				end
			end

			local arols = {}
			if channel.string_active_roles then
				arols = string.Explode(",", channel.string_active_roles)
			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_roles"] = {}
			for _, rol in pairs(arols) do
				if !strEmpty(rol) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_active_roles"][tonumber(rol)] = true
				end
			end

			-- PASSIVE
			local pugs = {}
			if channel.string_passive_usergroups then
				pugs = string.Explode(",", channel.string_passive_usergroups)
			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_usergroups"] = {}
			for _, ug in pairs(pugs) do
				if !strEmpty(ug) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_usergroups"][ug] = true
				end
			end

			local pgrps = {}
			if channel.string_passive_groups then
				pgrps = string.Explode(",", channel.string_passive_groups)
			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_groups"] = {}
			for _, grp in pairs(pgrps) do
				if !strEmpty(grp) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_groups"][tonumber(grp)] = true
				end
			end

			local prols = {}
			if channel.string_passive_roles then
				prols = string.Explode(",", channel.string_passive_roles)
 			end
			yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_roles"] = {}
			for _, rol in pairs(prols) do
				if !strEmpty(rol) then
					yrp_voice_channels[tonumber(channel.uniqueID)]["string_passive_roles"][tonumber(rol)] = true
				end
			end
		end
	else
		yrp_voice_channels = {}
	end

	SetGlobalTable("yrp_voice_channels", yrp_voice_channels)
end
GenerateVoiceTable()

util.AddNetworkString("yrp_vm_get_active_usergroups")
net.Receive("yrp_vm_get_active_usergroups", function(len, ply)
	local ugs = YRP_SQL_SELECT("yrp_usergroups", "uniqueID, string_name", nil)
	if wk(ugs) then
		net.Start("yrp_vm_get_active_usergroups")
			net.WriteTable(ugs)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_vm_get_active_groups")
net.Receive("yrp_vm_get_active_groups", function(len, ply)
	local grps = YRP_SQL_SELECT("yrp_ply_groups", "uniqueID, string_name", nil)
	if wk(grps) then
		net.Start("yrp_vm_get_active_groups")
			net.WriteTable(grps)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_vm_get_active_roles")
net.Receive("yrp_vm_get_active_roles", function(len, ply)
	local rols = YRP_SQL_SELECT("yrp_ply_roles", "uniqueID, string_name", nil)
	if wk(rols) then
		net.Start("yrp_vm_get_active_roles")
			net.WriteTable(rols)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_vm_get_passive_usergroups")
net.Receive("yrp_vm_get_passive_usergroups", function(len, ply)
	local ugs = YRP_SQL_SELECT("yrp_usergroups", "uniqueID, string_name", nil)
	if wk(ugs) then
		net.Start("yrp_vm_get_passive_usergroups")
			net.WriteTable(ugs)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_vm_get_passive_groups")
net.Receive("yrp_vm_get_passive_groups", function(len, ply)
	local grps = YRP_SQL_SELECT("yrp_ply_groups", "uniqueID, string_name", nil)
	if wk(grps) then
		net.Start("yrp_vm_get_passive_groups")
			net.WriteTable(grps)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_vm_get_passive_roles")
net.Receive("yrp_vm_get_passive_roles", function(len, ply)
	local rols = YRP_SQL_SELECT("yrp_ply_roles", "uniqueID, string_name", nil)
	if wk(rols) then
		net.Start("yrp_vm_get_passive_roles")
			net.WriteTable(rols)
		net.Send(ply)
	end
end)

util.AddNetworkString("yrp_voice_channel_add")
net.Receive("yrp_voice_channel_add", function(len, ply)
	local name = net.ReadString()
	local hear = tonum(net.ReadBool())

	local augs = table.concat(net.ReadTable(), ",")
	local agrps = table.concat(net.ReadTable(), ",")
	local arols = table.concat(net.ReadTable(), ",")

	local pugs = table.concat(net.ReadTable(), ",")
	local pgrps = table.concat(net.ReadTable(), ",")
	local prols = table.concat(net.ReadTable(), ",")

	YRP_SQL_INSERT_INTO(
		DATABASE_NAME,
		"string_name, int_hear, string_active_usergroups, string_active_groups, string_active_roles, string_passive_usergroups, string_passive_groups, string_passive_roles, int_position",
		"'" .. name .. "', '" .. hear .. "', '" .. augs .. "', '" .. agrps .. "', '" .. arols .. "', '" .. pugs .. "', '" .. pgrps .. "', '" .. prols	.. "', '" .. table.Count(GetGlobalTable("yrp_voice_channels", {})) .. "'"
	)

	GenerateVoiceTable()

	local c = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position") do
		channel.int_position = tonumber(channel.int_position)
		if channel.int_position != c then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c}, "uniqueID = '" .. channel.uniqueID .. "'")
		end

		c = c + 1
	end

	GenerateVoiceTable()
end)

util.AddNetworkString("yrp_voice_channel_save")
net.Receive("yrp_voice_channel_save", function(len, ply)
	local name = net.ReadString()
	local hear = tonum(net.ReadBool())

	local augs = table.concat(net.ReadTable(), ",")
	local agrps = table.concat(net.ReadTable(), ",")
	local arols = table.concat(net.ReadTable(), ",")

	local pugs = table.concat(net.ReadTable(), ",")
	local pgrps = table.concat(net.ReadTable(), ",")
	local prols = table.concat(net.ReadTable(), ",")

	local uid = net.ReadString()
	
	YRP_SQL_UPDATE(DATABASE_NAME, {
		["string_name"] 				= name,
		["int_hear"] 					= hear,
		["string_active_usergroups"] 	= augs,
		["string_active_groups"] 		= agrps,
		["string_active_roles"] 		= arols,
		["string_passive_usergroups"] 	= pugs,
		["string_passive_groups"] 		= pgrps,
		["string_passive_roles"] 		= prols
	}, "uniqueID = '" .. uid .. "'")

	GenerateVoiceTable()
end)

util.AddNetworkString("yrp_voice_channel_rem")
net.Receive("yrp_voice_channel_rem", function(len, ply)
	local uid = net.ReadString()

	YRP_SQL_DELETE_FROM(DATABASE_NAME, "uniqueID = '" .. uid .. "'")

	GenerateVoiceTable()
	
	local c = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position") do
		channel.int_position = tonumber(channel.int_position)
		if channel.int_position != c then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c}, "uniqueID = '" .. channel.uniqueID .. "'")
		end

		c = c + 1
	end

	GenerateVoiceTable()
end)

util.AddNetworkString("channel_up")
net.Receive("channel_up", function(len, ply)
	local uid = net.ReadString()
	uid = tonumber(uid)

	local int_position = GetGlobalTable("yrp_voice_channels", {})[uid].int_position

	local c = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position") do
		channel.int_position = tonumber(channel.int_position)
		if c == int_position then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c - 1}, "uniqueID = '" .. channel.uniqueID .. "'")
		elseif c == int_position - 1 then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c + 1}, "uniqueID = '" .. channel.uniqueID .. "'")
		elseif channel.int_position != c then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c}, "uniqueID = '" .. channel.uniqueID .. "'")
		end

		c = c + 1
	end

	GenerateVoiceTable()

	timer.Simple(0.1, function()
		net.Start("channel_up")
		net.Send(ply)
	end)
end)

util.AddNetworkString("channel_dn")
net.Receive("channel_dn", function(len, ply)
	local uid = net.ReadString()
	uid = tonumber(uid)

	local int_position = GetGlobalTable("yrp_voice_channels", {})[uid].int_position

	local c = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position") do
		channel.int_position = tonumber(channel.int_position)
		if c == int_position then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c + 1}, "uniqueID = '" .. channel.uniqueID .. "'")
		elseif c == int_position + 1 then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c - 1}, "uniqueID = '" .. channel.uniqueID .. "'")
		elseif channel.int_position != c then
			YRP_SQL_UPDATE(DATABASE_NAME, {["int_position"] = c}, "uniqueID = '" .. channel.uniqueID .. "'")
		end

		c = c + 1
	end

	GenerateVoiceTable()

	timer.Simple(0.1, function()
		net.Start("channel_dn")
		net.Send(ply)
	end)
end)

function YRPCountActiveChannels(ply)
	local c = 0
	local cm = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		if IsActiveInChannel(ply, channel.uniqueID, true) then
			c = c + 1
			if IsActiveInChannel(ply, channel.uniqueID) then
				cm = cm + 1
			end
		end
	end
	ply:SetNW2Int("yrp_voice_channel_active", c)
	ply:SetNW2Int("yrp_voice_channel_active_mic", cm)
end

function YRPCountPassiveChannels(ply)
	local c = 0
	local cm = 0
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		if IsInChannel(ply, channel.uniqueID, true) then
			c = c + 1
			if IsInChannel(ply, channel.uniqueID) then
				cm = cm + 1
			end
		end
	end
	ply:SetNW2Int("yrp_voice_channel_passive", c)
	ply:SetNW2Int("yrp_voice_channel_passive_voice", cm)
end

function YRPSwitchToVoiceChannel(ply, uid)
	if !ply:GetNW2Bool("yrp_voice_channel_mutemic_" .. uid, true) then
		ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. uid, true) 
	else
		--[[for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
			if !ply:GetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, true) then
				ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, false)
			end
		end]]
	
		for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
			if channel.uniqueID == uid then
				ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, false)
				ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, true)
			else
				ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, true)
			end
		end
	end

	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end

util.AddNetworkString("mutemic_channel")
net.Receive("mutemic_channel", function(len, ply)
	local uid = net.ReadString()
	uid = uid or "0"
	uid = tonumber(uid)
	
	if !ply:GetNW2Bool("yrp_voice_channel_mute_" .. uid, false) then
		ply:SetNW2Bool("yrp_voice_channel_mute_" .. uid, true)
	end

	ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. uid, !ply:GetNW2Bool("yrp_voice_channel_mutemic_" .. uid, false))

	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end)

util.AddNetworkString("mute_channel")
net.Receive("mute_channel", function(len, ply)
	local uid = net.ReadString()
	
	if !ply:GetNW2Bool("yrp_voice_channel_mutemic_" .. uid, false) then
		ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. uid, true) 
	end

	ply:SetNW2Bool("yrp_voice_channel_mute_" .. uid, !ply:GetNW2Bool("yrp_voice_channel_mute_" .. uid, false))

	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end)

util.AddNetworkString("mutemic_channel_all")
net.Receive("mutemic_channel_all", function(len, ply)
	ply:SetNW2Bool("mutemic_channel_all", !ply:GetNW2Bool("mutemic_channel_all", false))

	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, ply:GetNW2Bool("mutemic_channel_all", false))
	end
	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end)

util.AddNetworkString("mute_channel_all")
net.Receive("mute_channel_all", function(len, ply)
	ply:SetNW2Bool("mute_channel_all", !ply:GetNW2Bool("mute_channel_all", false))

	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, ply:GetNW2Bool("mute_channel_all", false))
	end
	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end)

function YRPMoveAllToNext( ply )
	local found = false
	for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
		if IsActiveInChannel(ply, channel.uniqueID, true) then
			if !found and ply:GetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID) == false then
				ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, true)
				ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, false)

				found = true
			elseif found and ply:GetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID) == false then
				ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, false)
				ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, true)

				found = false
			end
		end
	end

	if found then
		for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
			if IsActiveInChannel(ply, channel.uniqueID, true) then
				if found and ply:GetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID) == false then
					ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, false)
					ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, true)
	
					found = false
				end
			end
		end
	end

	if !found then
		for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
			if IsActiveInChannel(ply, channel.uniqueID, true) then
				if ply:GetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID) == false then
					ply:SetNW2Bool("yrp_voice_channel_mutemic_" .. channel.uniqueID, false)
					ply:SetNW2Bool("yrp_voice_channel_mute_" .. channel.uniqueID, true)
					break
				end
			end
		end
	end
end

util.AddNetworkString("yrp_next_voice_channel")
net.Receive("yrp_next_voice_channel", function(len, ply)
	YRPMoveAllToNext( ply )

	YRPCountActiveChannels(ply)
	YRPCountPassiveChannels(ply)
end)

util.AddNetworkString("yrp_togglevoicemenu")
net.Receive("yrp_togglevoicemenu", function(len, ply)
	ply:SetNW2Bool( "yrp_togglevoicemenu", !ply:GetNW2Bool( "yrp_togglevoicemenu", true ) )
end)

util.AddNetworkString("yrp_voice_set_max_active")
net.Receive("yrp_voice_set_max_active", function(len, ply)
	local maxi = tonumber( net.ReadString() )
	YRP_SQL_UPDATE("yrp_general", {["int_max_channels_active"] = maxi}, "uniqueID = '1'")
	SetGlobalInt("int_max_channels_active", maxi)
end)

util.AddNetworkString("yrp_voice_set_max_passive")
net.Receive("yrp_voice_set_max_passive", function(len, ply)
	local maxi = tonumber( net.ReadString() )
	YRP_SQL_UPDATE("yrp_general", {["int_max_channels_passive"] = maxi}, "uniqueID = '1'")
	SetGlobalInt("int_max_channels_passive", maxi)
end)

hook.Add("PlayerCanHearPlayersVoice", "YRP_voicesystem", function(listener, talker)
	if GetGlobalBool("bool_voice", false) then
		if listener == talker then
			return false
		end

		local canhear = false
		for i, channel in SortedPairsByMemberValue(GetGlobalTable("yrp_voice_channels", {}), "int_position", false) do
			if IsActiveInChannel(talker, channel.uniqueID) and ( IsInChannel(listener, channel.uniqueID) or IsActiveInChannel(listener, channel.uniqueID) ) then -- If Talker allowed to talk and both are in that channel
				canhear = true
				break
			end
		end

		if canhear and !talker:GetNW2Bool("mute_voice", false) then
			return true
		else
			if YRPIsInMaxVoiceRange(listener, talker) then
				if YRPIsInSpeakRange(listener, talker) then
					return true
				end
			end
		end
		
		return false -- new
	else
		if YRPIsInMaxVoiceRange(listener, talker) then
			if YRPIsInSpeakRange(listener, talker) then
				return true
			end
		end
	end
end)

function setbodygroups(ply)
	local chaTab = ply:YRPGetCharacterTable()
	if wk(chaTab) then
		ply:SetSkin(chaTab.skin)
		ply:SetupHands()
		for i = 0, 19 do
			ply:SetBodygroup(i, chaTab["bg" .. i])
		end
	end
end

function setPlayerModel(ply)
	local tmpRolePlayermodel = ply:GetPlayerModel()
	if wk(tmpRolePlayermodel) and !strEmpty(tmpRolePlayermodel) then
		ply:SetModel(tmpRolePlayermodel)
	else
		ply:SetModel("models/player/skeleton.mdl")
		YRP.msg( "note", ply:YRPName() .. " HAS NO PLAYERMODEL" )
	end
	setbodygroups(ply)
end

function GM:PlayerSetModel(ply)
	setPlayerModel(ply)
end

function GM:PlayerSpray(ply)
	if GetGlobalBool("bool_graffiti_disabled", false) then
		return true
	else
		return false
	end
end

function GM:PlayerSwitchFlashlight(pl, enabled)
	local _tmp = YRP_SQL_SELECT("yrp_usergroups", "*", "string_name = '" .. string.lower(pl:GetUserGroup()) .. "'")
	if wk(_tmp) then
		_tmp = _tmp[1]
		if tobool(_tmp.bool_flashlight) then
			return true
		end
	end
	return false
end

function GM:ShowHelp(ply)
	return false
end

hook.Add("PostCleanupMap", "yrp_PostCleanupMap_doors", function()
	-- Rebuild Doors
	YRP.msg("note", "RELOAD DOORS")

	loadDoors()
	LoadWorldStorages()
end)

function YRPWarning( text )
	MsgC( Color( 255, 0, 0 ), "[WARNING] > " .. text .. "\n")
			
end

function YRPInfo( text )
	MsgC( Color( 255, 255, 0 ), "[INFO] > " .. text .. "\n")
end

function YRPCheckAddons()
	YRPHR( Color( 100, 100, 255 ) )
	YRP.msg("note", "YRPCheckAddons() ...")
	local count = 0
	for i, v in pairs( engine.GetAddons() ) do
		v.wsid = tonumber(v.wsid)

		v.searchtitle = string.lower(v.title)

		v.searchtitle = string.Replace( v.searchtitle, "[", "" )
		v.searchtitle = string.Replace( v.searchtitle, "]", "" )
		v.searchtitle = string.Replace( v.searchtitle, "%", "" )

		if ( string.find( v.searchtitle, "workshop" ) and string.find( v.searchtitle, "download" ) ) or string.find( v.searchtitle, "addon share" ) then -- "Workshop Downloader Addons"
			YRPWarning( "[" .. v.wsid .. "] [" .. v.title .. "] is already implemented in YourRP!" )
			count = count + 1
		end

		if string.find( v.searchtitle, "fps" ) and ( string.find( v.searchtitle, "boost" ) or string.find( v.searchtitle, "tweak" ) or string.find( v.searchtitle, "fps+" ) ) then -- "FPS Booster Addons"
			YRPWarning( "[" .. v.wsid .. "] [" .. v.title .. "] is already implemented in YourRP, if it is improving FPS!" )
			count = count + 1
		end

		if string.find( v.searchtitle, "talk icon" ) then -- "Talk Icon Addons"
			YRPInfo( "[" .. v.wsid .. "] [" .. v.title .. "] YourRP also have an Talk Icon" )
			count = count + 1
		end
	end
	if count == 0 then
		YRP.msg("note", "YRPCheckAddons() EVERYTING GOOD.")
	end
	YRPHR( Color( 100, 100, 255 ) )
end

hook.Add( "PostGamemodeLoaded", "yrp_PostGamemodeLoaded_CheckAddons", function()
	timer.Simple(2.1, function()
		YRPCheckAddons()
	end)
end )

	

