--local gameModeList = require()

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local sorted_map = MemoryStoreService:GetSortedMap("Servers")
local Players = game:GetService("Players")
local run_service = game:GetService("RunService")

local remote : RemoteEvent = script.UpdationRemote

local IsServer = run_service:IsServer()
local IsClient = run_service:IsClient()

local ELEMENT_TEMPLATE = script.Template
local LIST_LAYOUT_TEMPLATE = game:GetService("ReplicatedStorage").Matchmaker.UIListLayout
local MAX_RETRIES = 3

local module = {}

module.LocalList = {}

if IsServer() then

    function module.UpdateLocalList() : boolean
        local success = false
        success, module.LocalList = protectedCall(function()
            return sorted_map:GetAsync()
        end)
        return success
    end

    function module.UpdateUI()
        remote:FireAllClients(module.LocalList)
    end

end

if IsClient then
    remote.OnClientEvent:Connect(function(LocalList)

        local frame = Players.LocalPlayer.PlayerGui.ServerList.ScrollingFrame

        frame:ClearAllChildren()
        LIST_LAYOUT_TEMPLATE:Clone().Parent = frame
        
        for _,tbl in ipairs(LocalList) do
            local element = ELEMENT_TEMPLATE:Clone()
            element.Parent = frame

            local ServerId = tbl["value"][1]
            local Gamemode = tbl["value"][2]
            local PlrCount = tbl["value"][3]

            element.ServerID.Text = ServerId
            element.Gamemode.Text = Gamemode
            element.PlrCount = PlrCount
            --element.MaxPlrCount = gameModeList.GetMaxPlrCount(Gamemode)

            element.Join.MouseButton1Click:Connect(function()
                
            end)
        end

    end)    
end


function module.IsServerFull(s)
    
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