--!nocheck

local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local sorted_map = MemoryStoreService:GetSortedMap("Servers")

--local gameModeList = require()

local MAX_RETRIES = 3

local serverObj = {}

function serverObj.Initialise(gamemode : string, accessCode : string)
    serverObj._JobId = game.JobId
    serverObj._ServerId = string.split(serverObj._JobId, "-")[1]
    serverObj._Gamemode = gamemode
    serverObj._PlayerCount = #game:GetService("Players"):GetPlayers()
    serverObj._AccessCode = accessCode

    if serverObj._PlrAddedConnection then serverObj._PlrAddedConnection:Disconnect() end
    serverObj._PlrAddedConnection = Players.PlayerAdded:Connect(function()
        serverObj._PlayerCount = #game:GetService("Players"):GetPlayers()
        serverObj:PublishToList()
    end)


    if serverObj._PlrRemovingConnection then serverObj._PlrRemovingConnection:Disconnect() end
    serverObj._PlrRemovingConnection = Players.PlayerRemoving:Connect(function()
        serverObj._PlayerCount = #game:GetService("Players"):GetPlayers()
        serverObj:PublishToList()
    end)

    MessagingService:SubscribeAsync(accessCode, function()
        --local bool = if serverObj._PlayerCount+1 >= gameModeList.GetMaxPlrCount(gamemode) then true else false
        local bool = if serverObj._PlayerCount+1 >= 1 then true else false
        protectedCall(function()
            MessagingService:PublishAsync(accessCode, bool)
        end)
    end)

    serverObj:PublishToList()
end

function serverObj:GetPlayerCount() : number
    return self._PlayerCount
end

function serverObj:GetGamemode() : string
    return self._Gamemode
end

function serverObj:GetServerId() : string
    return self._ServerId
end

function serverObj:GetAccessCode() : string
    return self._AccessCode
end

--[[
Call may fail. Always handle the situation when this method returns false.
Currently, the system simply ignores the failure and retries the next cycle.
]]
function serverObj:PublishToList() : (boolean, any?)
    local success, err = protectedCall(function()
        sorted_map:SetAsync(serverObj:GetAccessCode(), {serverObj:GetServerId(), serverObj:GetGamemode(), serverObj:GetPlayerCount(), serverObj:GetAccessCode()}, 3600)
    end)
    return success, err
end

function serverObj.Destroy()
    sorted_map:RemoveAsync(serverObj:GetAccessCode())
    if serverObj._PlrAddedConnection then serverObj._PlrAddedConnection:Disconnect() end
    if serverObj._PlrRemovingConnection then serverObj._PlrRemovingConnection:Disconnect() end
    serverObj = nil
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

game:BindToClose(serverObj.Destroy)

return serverObj