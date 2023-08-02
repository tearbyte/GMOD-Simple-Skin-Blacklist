SSB = SSB or {}

util.AddNetworkString( 'ssb_refresh' )
util.AddNetworkString( 'ssb_death' )
CreateConVar('simple_skin_blacklist_enable', 1, FCVAR_ARCHIVE, 'Should be blacklist system be enabled?')
CreateConVar('simple_skin_blacklist_supress_admin', 1, FCVAR_ARCHIVE, 'Should be admins allow to use blacklisted skins?')
CreateConVar('simple_skin_blacklist_supress_superadmin', 1, FCVAR_ARCHIVE, 'Should be superadmins allow to use blacklisted skins?')

function SSB:Load()

	if !file.Exists('simple_skin_blacklist.json', 'DATA') then

		SSB.data = {
			disallowed_skins = {},
			alternative_skins = {"kleiner"}
		}

		SSB.data.disallowed_skins["charple"] = true

		file.Write('simple_skin_blacklist.json', util.TableToJSON(SSB.data, true))
		return 
	end

	SSB.data = util.JSONToTable(file.Read('simple_skin_blacklist.json', 'DATA'))

end

function SSB.ShutDown()
	file.Write('simple_skin_blacklist.json', util.TableToJSON(SSB.data, true))
end

function SSB.SkinChange(ply)
    if !GetConVar('simple_skin_blacklist_enable'):GetBool() then return end
    if GetConVar('simple_skin_blacklist_supress_admin'):GetBool() && ply:IsAdmin() then return end
    if GetConVar('simple_skin_blacklist_supress_superadmin'):GetBool() && ply:IsSuperAdmin() then return end

	net.Start('ssb_death')
	net.Send(ply)
end

net.Receive('ssb_refresh', function ( len, ply )

	if net.ReadBit() == 1 then
		SSB.data = net.ReadTable()
	end

	net.Start('ssb_refresh')
	net.WriteTable(SSB.data)

	if net.ReadBit() == 1 then
		net.Broadcast()
	else
		net.Send(ply)
	end
end)

net.Receive('ssb_death', function (len, ply) if ply:Alive() then ply:KillSilent() end end)


--hook.Add('Initialize', 'SSB_Load', SSB.Init)
hook.Add('ShutDown', 'SSB_ShutDown', SSB.ShutDown)
--hook.Add('PlayerSpawn', 'SSB_Skin_Check_Spawn', SSB.SkinChange)
hook.Add('PlayerDeath', 'SSB_Skin_Check_Death', SSB.SkinChange)
hook.Add('PlayerSetModel', 'SSB_Skin_Check_Change', SSB.SkinChange)
hook.Add('PlayerInitialSpawn', 'SSB_Skin_Check_InSpawn', function ( ply )

	net.Start('ssb_refresh')
	net.WriteTable(SSB.data)
	net.Send(ply)

	net.Start('ssb_death')
	net.Send(ply)

	timer.Simple(2, function() ply:Spawn() end)
end)

SSB:Load()