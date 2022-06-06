local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")

local serverObj = {}
serverObj.__index = serverObj

function serverObj.new()
    local newObj = {}
    setmetatable(newObj, serverObj)

    newObj._JobId = game.JobId
    newObj.ServerId = string.split(newObj._JobId, "-")[1]
    newObj.Gamemode = ""
    newObj.PlayerCount = 0

    Players.PlayerAdded:Connect(function()
        newObj.PlayerCount += 1
    end)

    Players.PlayerRemoving:Connect(function()
        newObj.PlayerCount -= 1
    end)
end

function serverObj:GetPlayerCount() : number
    return self.PlayerCount
end

function serverObj:GetGamemode() : number
    return self.Gamemode
end

function serverObj:GetServerId() : string
    return self.ServerId
end

function serverObj:PublishToList()
    MemoryStoreService:GetSortedMap("Servers"):SetAsync(game.JobId, {serverObj:GetServerId(), serverObj:GetGamemode(), serverObj:GetPlayerCount()})
end

return serverObj