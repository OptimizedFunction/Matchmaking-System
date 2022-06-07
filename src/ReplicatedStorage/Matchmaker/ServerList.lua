--!nocheck
--local gameModeList = require()

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local run_service = game:GetService("RunService")

local remote : RemoteEvent = script.UpdationRemote

local IsServer = run_service:IsServer()
local IsClient = run_service:IsClient()

local ELEMENT_TEMPLATE = script.Template
local MAP_PLACE_ID = game.PlaceId
local LIST_LAYOUT_TEMPLATE = script.UIListLayout
local MAX_RETRIES = 3

local module = {}

module.LocalList = {}

if IsServer then
    local sorted_map = MemoryStoreService:GetSortedMap("Servers")

    script.Join.OnServerEvent:Connect(function(...)
        module.AttemptTeleport(...)
    end)

    function module.UpdateLocalList() : boolean
        local success = false
        success, module.LocalList = protectedCall(function()
            return sorted_map:GetRangeAsync(Enum.SortDirection.Descending, 40)
        end)
        return success
    end

    function module.UpdateUI()
        remote:FireAllClients(module.LocalList)
    end

    function module.IsServerFull(AccessCode : string)
        local _, isFull
        _, isFull = protectedCall(function()
            MessagingService:PublishAsync(AccessCode, "")
            local conn
            conn = MessagingService:SubscribeAsync(AccessCode, function(bool : boolean)
                isFull = bool
                conn:Disconnect()
            end)
        end)

        return isFull
    end

    function module.AttemptTeleport(plr : Player, AccessCode : string)
        if module.IsServerFull(AccessCode) then
            --Show error, server Full!
        else
            TeleportService:TeleportToPrivateServer(MAP_PLACE_ID, AccessCode, {plr})
        end
    end

    function module.FlushList() : boolean
        local success = protectedCall(function()
            while true do
                local records = sorted_map:GetRangeAsync(Enum.SortDirection.Ascending, 100)
                for _,tbl in records do sorted_map:RemoveAsync(tbl["key"]) end
                if #records < 100 then break end
            end
        end)

        return success
    end
end

if IsClient then
    remote.OnClientEvent:Connect(function(LocalList)

        local frame = Players.LocalPlayer.PlayerGui.MatchmakerGUI.ScrollingFrame

        frame:ClearAllChildren()
        LIST_LAYOUT_TEMPLATE:Clone().Parent = frame
        
        for _,tbl in ipairs(LocalList) do
            local element = ELEMENT_TEMPLATE:Clone()
            element.Parent = frame

            local ServerId = tbl["value"][1]
            local Gamemode = tbl["value"][2]
            local PlrCount = tbl["value"][3]
            local AccessCode = tbl["value"][4]

            element.ServerID.Text = ServerId
            element.Gamemode.Text = Gamemode
            element.PlrCount.Text = PlrCount
            --element.MaxPlrCount = gameModeList.GetMaxPlrCount(Gamemode)

            element.JoinButton.MouseButton1Click:Connect(function()
                script.Join:FireServer(AccessCode)
            end)
        end

    end)
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

return module