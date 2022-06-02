local plr = game:GetService("Players").LocalPlayer
local gui = plr.PlayerGui.MatchmakerGUI
	
gui.TextButton.MouseButton1Click:Connect(function()
	local queued = game:GetService("ReplicatedStorage").PushRemote:InvokeServer(0)
	if not queued then  
		gui.TextLabel.Text = "Not Queued!"
	else
		gui.TextLabel.Text = "Queued!"
	end
end)

gui["ServerID Display"].Text = "The current Server ID is: "..tostring(game.JobId)