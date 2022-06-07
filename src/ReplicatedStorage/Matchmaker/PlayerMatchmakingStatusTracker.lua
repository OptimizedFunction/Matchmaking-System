local module = {}

game:GetService("Players").PlayerAdded:Connect(function(plr)
	module.PlayerID = false
end)

game:GetService("Players").PlayerRemoving:Connect(function(plr)
	module.PlayerID = nil
end)
	
return module
