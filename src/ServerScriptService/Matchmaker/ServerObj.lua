local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local sorted_map = MemoryStoreService:GetSortedMap("Servers")

local gameModeList = require()

local MAX_RETRIES = 3


local serverObj = {}

serverObj._JobId = game.JobId
serverObj.ServerId = string.split(serverObj._JobId, "-")[1]
serverObj.Gamemode = ""
serverObj.PlayerCount = 0

function serverObj.Initialise(gamemode : string)

    serverObj.Gamemode = gamemode

    Players.PlayerAdded:Connect(function()
        serverObj.PlayerCount += 1
        serverObj:PublishToList()
    end)

    Players.PlayerRemoving:Connect(function()
        serverObj.PlayerCount -= 1
        serverObj:PublishToList()
    end)

    MessagingService:SubscribeAsync(game.JobId, function()
        local bool = if serverObj.PlayerCount+1 >= gameModeList.GetMaxPlrCount(serverObj.Gamemode) then true else false
        protectedCall(function()
            MessagingService:PublishAsync(game.JobId, bool)
        end)
    end)
    
end

function serverObj:GetPlayerCount() : number
    return self.PlayerCount
end

function serverObj:GetGamemode() : string
    return self.Gamemode
end

function serverObj:GetServerId() : string
    return self.ServerId
end

--[[
Call may fail. Always handle the situation when this method returns false.
Currently, the system simply ignores the failure and retries the next cycle.
]]
function serverObj:PublishToList() : (boolean, any?)
    local success, err = protectedCall(function()
        sorted_map:SetAsync(game.JobId, {serverObj:GetServerId(), serverObj:GetGamemode(), serverObj:GetPlayerCount()})
    end)
    return success, err
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

return serverObj