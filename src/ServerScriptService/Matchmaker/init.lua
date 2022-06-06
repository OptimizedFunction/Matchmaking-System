--!nocheck
--Services
local MemoryStoreService : MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService : TeleportService = game:GetService("TeleportService")
local MessagingService : MessagingService = game:GetService("MessagingService")
local Players : Players = game:GetService("Players")

--Getting dependencies
local StatusTracker = require(script.PlayerMatchmakingStatusTracker)
local GameModesList : {string}

--Variables
local PLR_MATCHMAKING_TIMEOUT = 60 * 60  -- Time after which an entry in the Memory store will automatically expire.
local MAX_RETRIES = 3 -- maximum retries for an Async call. Don't make it too large.
local MAP_PLACE_ID = game.PlaceId --The place ID of the place which holds the maps.
local STRING_TEMPLATE = "List "

local time_list = {}

local module = {}

--Public interface
function module.InitialiseMatchmaker(gamemodes : {string})
	GameModesList = gamemodes
	for _,gameMode in gamemodes do
		MessagingService:SubscribeAsync(STRING_TEMPLATE..gameMode, HandleTeleportationRequest)
	end
end


function module.AddPlayerToQueue(plr : Player, gameMode : string) : (boolean, any?)
	local MatchmakingMap : MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(STRING_TEMPLATE..gameMode)
	local success, results = protectedCall(function()
		return MatchmakingMap:SetAsync(tostring(plr.UserId), {tostring(game.JobId)}, PLR_MATCHMAKING_TIMEOUT)
	end)
	
	time_list[plr.UserId] = os.time()
	StatusTracker[plr.UserId] = success
	return success, results
end

--pass the gameMode parameter to cancel matchmaking from the specfific list. If not passed, the 
--function goes through every gameMode and removes the plr associated key.
function module.RemovePlayerFromQueue(plr : Player, gameMode : string?) : (boolean, any?)
	local gamemodes = if gameMode then {gameMode} else GameModesList
	
	for _, gameMode in gamemodes do
		local MatchmakingMap : MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(STRING_TEMPLATE..gameMode)
		local success, err = false, nil
		success, err = protectedCall(function()
			return MatchmakingMap:RemoveAsync(tostring(plr.UserId))
		end)
		
		time_list[plr.UserId] = nil
		StatusTracker[plr.UserId] = false
		return success, err
	end
	
	return false, nil
	
end


function module.MatchPlayers(gameMode : string, minNumOfPlayers : number, maxNumOfPlayers : number)
	local success, results = PullPlayersFromMap(string, minNumOfPlayers, maxNumOfPlayers)
	if not success then return end
	local success = RemovePulledPlayersFromMap(string, results)
	if not success then return end
	success = RequestTeleportationToReservedServer(string, results)
	if not success then return end
end


function module.GetTimeQueued(plr : Player | number) : number
	if typeof(plr) == "number" then
		if not StatusTracker[plr] then warn("Player is not queued!") return -1 end
		return os.difftime(os.time(), time_list[plr])
	else
		if not StatusTracker[plr.UserId] then warn("Player is not queued!") return -1 end
		return os.difftime(os.time(), time_list[plr.UserId])
	end
end


function module.GetPlayerStatus(plr : Player | number) : boolean
	if typeof(plr) == "number" then
		return StatusTracker[plr]
	else
		return StatusTracker[plr.UserId]
	end
end

--returns the queue size. Only meaningful for small queues. If the queue is greater than 100, it will return 100.
--returns -1 if the request fails
function module.GetQueueSize(gameMode : string) : number
	local MatchmakingMap : MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(STRING_TEMPLATE..gameMode)
	local success, results = protectedCall(function()
		return MatchmakingMap:GetRangeAsync(Enum.SortDirection.Descending, 100)
	end)
	
	if success then
		if results then return #results
		else return 0 end
	else
		warn("Queue size request failed!")
		return -1
	end
end

--internal module functions
function PullPlayersFromMap(gameMode : string, minNumOfPlayers : number, maxNumOfPLayers ) : (boolean, {[string] : {any}}?)
	local MatchmakingMap : MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(STRING_TEMPLATE..gameMode)

	local success, results = protectedCall(function()
		return MatchmakingMap:GetRangeAsync(Enum.SortDirection.Descending, maxNumOfPLayers)
	end)

	if results and #results < minNumOfPlayers then return false, nil end

	return success, results
end


function RemovePulledPlayersFromMap(gameMode : string, results) : (boolean, any?)
	local MatchmakingMap : MemoryStoreSortedMap = MemoryStoreService:GetSortedMap(STRING_TEMPLATE..gameMode)
	local success, err = false, nil
	for _, v in results do
		local plrID = v["key"]
		success, err = protectedCall(function()
			return MatchmakingMap:RemoveAsync(plrID)
		end)

		time_list[plrID] = nil
		StatusTracker[plrID] = not success
		if not success then return success, err end
	end

	return success, err
end


function RequestTeleportationToReservedServer(gameMode : string, results : {[string] : {any}}) : (boolean, any?)
	local ReservedServerCode = TeleportService:ReserveServer(MAP_PLACE_ID)

	local success, err = protectedCall(function()
		return MessagingService:PublishAsync(STRING_TEMPLATE..gameMode, {gameMode, ReservedServerCode, results})
	end)

	return success, err
end


function HandleTeleportationRequest(message : any)
	local data = message.Data
	local gameMode = data[1]
	local serverAccessCode = data[2]
	local request = data[3]
	local plrsToTeleport = {}
	
	for _, packet in request do
		local plrID = packet["key"]
		local jobID = packet["value"][1]
		if game.JobId == jobID then 
			for _, plr in Players:GetPlayers() do
				if (plr::Player).UserId == tonumber(plrID) then table.insert(plrsToTeleport, plr) end
			end
		end
	end
	
	if #plrsToTeleport > 0 then 
		TeleportService:TeleportToPrivateServer(MAP_PLACE_ID, serverAccessCode, plrsToTeleport, nil, {gameMode})
	end
end



function protectedCall(func, ...) : (boolean, any?)
	local success, results, retries = false, nil, 0
	local args = {...}
	
	while ((not success) and retries <= MAX_RETRIES) do
		retries += 1
		success, results = pcall(func, unpack(args))
	end

	if not success then warn(results) end
	return success, results
end

Players.PlayerRemoving:Connect(function(plr)
	for _,gameMode in GameModesList do
		module.CancelMatchmaking(plr, gameMode)
	end
	
end)

TeleportService.TeleportInitFailed:Connect(function(plr : Instance)
	StatusTracker[(plr::Player).UserId] = false
end)

return module