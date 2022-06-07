local RS = game:GetService("ReplicatedStorage")
local statusTracker = require(RS.Matchmaker.PlayerMatchmakingStatusTracker)
local matchmaker = require(RS.Matchmaker)
local ServerList = require(RS.Matchmaker.ServerList)
local ServerObj = require(RS.Matchmaker.ServerObj)
local pushRemote = RS.PushRemote

matchmaker.InitialiseMatchmaker({""})

pushRemote.OnServerInvoke = function(plr : Player, gamemode : string)
	if not statusTracker[plr.UserId] then
		local queued = matchmaker.AddPlayerToQueue(plr, gamemode)
		return queued
	else
		local queued = matchmaker.RemovePlayerFromQueue(plr, gamemode)
		return not queued
	end
end

--the TeleportData is of the form {gamemode : string, ServerAccessCode : string}
function FetchTeleportData(plr : Player) : {string}
	local DS = game:GetService("DataStoreService"):GetDataStore("TeleportData")
	local data = DS:GetAsync(plr.UserId)
	return data
end

game:GetService("Players").PlayerAdded:Connect(function(plr : Player)

	local data = FetchTeleportData(plr)
	if data then
		ServerObj.Initialise("", data[2])
	end

	wait(10)
	-- local isReserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

	-- if isReserved then return end

	-- local TeleportService = game:GetService("TeleportService")
	-- local serverAccessCode = TeleportService:ReserveServer(game.PlaceId)
	-- TeleportService:TeleportToPrivateServer(game.PlaceId, serverAccessCode, {plr}, nil, "hi")
end)

while true do
	matchmaker.MatchPlayers("", 1, 10)
	ServerList.UpdateLocalList()
	ServerList.UpdateUI()
	task.wait(8)
end