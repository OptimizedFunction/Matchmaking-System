--local statusTracker = require(script.Parent.Matchmaker.PlayerMatchmakingStatusTracker)
--local matchmaker = require(script.Parent.Matchmaker)
--local RS = game:GetService("ReplicatedStorage")
--local pushRemote = RS.PushRemote

--matchmaker.InitialiseMatchmaker({""})

--pushRemote.OnServerInvoke = function(plr : Player, gamemode : string)
--	if not statusTracker[plr.UserId] then
--		local queued = matchmaker.AddPlayerToQueue(plr, gamemode) 
--		return queued
--	else
--		local queued = matchmaker.RemovePlayerFromQueue(plr, gamemode)
--		return not queued
--	end
--end

--game:GetService("Players").PlayerAdded:Connect(function(plr : Player)
--	wait(10)
--	local isReserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
	
--	if isReserved then return end

--	local TeleportService = game:GetService("TeleportService")
--	local serverAccessCode = TeleportService:ReserveServer(game.PlaceId)
--	TeleportService:TeleportToPrivateServer(game.PlaceId, serverAccessCode, {plr}, nil, "hi")
--end)

--while true do
--	task.wait(5)
--	matchmaker.MatchPlayers("1", 2, 10)
--end

local module = require(game.ServerScriptService.ModuleScript)
print(module.getMyTable())