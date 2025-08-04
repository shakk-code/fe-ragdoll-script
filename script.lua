--[[
	fe ragdoll script v2
	made by minishakk, fixed by CS 🔥🔥
	contact either @minishakk or @c_s911 on Discord BEFORE redistributing, and make sure credit for both is visibly shown, thanks
]]

-- enjoy

local ragspeed = 6000 -- CHANGE SPEED HERE!!!

local player = game.Players.LocalPlayer
local animcon = {}
local tool = Instance.new("Tool")
local handle = Instance.new("Part")
tool.Name = "Ragdoll"
tool.CanBeDropped = false
tool.RequiresHandle = true
handle.Name = "Handle"
handle.Size = Vector3.new(1,1,1)
handle.Transparency = 1
handle.CanCollide = false
handle.Parent = tool

local isragdoll = false
local movevec = Vector3.zero
local moveforce = nil
local started, finished, spacekey, renderc

local function nomoar()
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				local con = animator.AnimationPlayed:Connect(function(track)
					local id = track.Animation.AnimationId
					if id:match("507766388") or id:match("507766666") or track.Name:lower():match("toolnone") then
						track:Stop()
					end
				end)
				table.insert(animcon, con)
			end
		end
	end
end

local function startmove(root)
	moveforce = Instance.new("BodyForce")
	moveforce.Name = "MoveForce"
	moveforce.Force = Vector3.zero
	moveforce.Parent = root
	renderc = game:GetService("RunService").RenderStepped:Connect(function()
		if isragdoll and moveforce and workspace.CurrentCamera then
			local cam = workspace.CurrentCamera
			local forward = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit
			local right = Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z).Unit
			local dir = (forward * movevec.Z + right * movevec.X)
			if dir.Magnitude > 0 then
				dir = dir.Unit
			end
			moveforce.Force = dir * ragspeed
		end
	end)
end

local function stopmove()
	if renderc then renderc:Disconnect() end
	if moveforce then moveforce:Destroy() end
	moveforce = nil
end

local function ragdoll(char)
	if isragdoll then return end
	isragdoll = true

	local motors = {}
	for _, motor in ipairs(char:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			table.insert(motors, {
				Name = motor.Name, Parent = motor.Parent,
				Part0 = motor.Part0, Part1 = motor.Part1,
				C0 = motor.C0, C1 = motor.C1
			})
			local a0 = Instance.new("Attachment", motor.Part0)
			a0.Name = "RagdollAttachment0"; a0.CFrame = motor.C0
			local a1 = Instance.new("Attachment", motor.Part1)
			a1.Name = "RagdollAttachment1"; a1.CFrame = motor.C1
			local c = Instance.new("BallSocketConstraint", motor.Part0)
			c.Name = "RagdollConstraint"; c.Attachment0 = a0; c.Attachment1 = a1
			motor:Destroy()
		end
	end

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		for _, st in ipairs({
			Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
			Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Flying,
			Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Climbing,
			Enum.HumanoidStateType.Landed,
			}) do
			humanoid:SetStateEnabled(st, false)
		end
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
	end

	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		startmove(root)
	end

	local uis = game:GetService("UserInputService")
	started = uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W then movevec = Vector3.new(movevec.X,0,1) end
			if input.KeyCode == Enum.KeyCode.S then movevec = Vector3.new(movevec.X,0,-1) end
			if input.KeyCode == Enum.KeyCode.A then movevec = Vector3.new(-1,0,movevec.Z) end
			if input.KeyCode == Enum.KeyCode.D then movevec = Vector3.new(1,0,movevec.Z) end
		end
	end)

	finished = uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
				movevec = Vector3.new(movevec.X,0,0)
			elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
				movevec = Vector3.new(0,0,movevec.Z)
			end
		end
	end)

	spacekey = uis.InputBegan:Connect(function(i, gpe)
		if gpe then return end
		if i.KeyCode == Enum.KeyCode.Space and isragdoll then
			stopmove()
			started:Disconnect()
			finished:Disconnect()
			spacekey:Disconnect()

			for _, d in ipairs(char:GetDescendants()) do
				if (d:IsA("BallSocketConstraint") and d.Name=="RagdollConstraint")
					or (d:IsA("Attachment") and d.Name:match("RagdollAttachment")) then
					d:Destroy()
				end
			end

			for _, data in ipairs(motors) do
				local m = Instance.new("Motor6D")
				m.Name = data.Name
				m.Part0 = data.Part0
				m.Part1 = data.Part1
				m.C0 = data.C0
				m.C1 = data.C1
				m.Parent = data.Parent
			end

			if humanoid then
				for _, st in ipairs({
					Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
					Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Flying,
					Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Climbing,
					Enum.HumanoidStateType.Landed,
					}) do
					humanoid:SetStateEnabled(st, true)
				end
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				humanoid.PlatformStand = false
			end

			isragdoll = false
		end
	end)
end

tool.Equipped:Connect(function()
	nomoar()
end)

local clicked = false
tool.Activated:Connect(function()
	if not clicked and not isragdoll then
		clicked = true
		ragdoll(player.Character)
		wait(0.5)
		clicked = false
	end
end)

tool.Unequipped:Connect(function()
	if started then started:Disconnect() end
	if finished then finished:Disconnect() end
	if spacekey then spacekey:Disconnect() end
	coroutine.wrap(function()
		for _, c in ipairs(animcon) do c:Disconnect() end
		animcon = {}
	end)()
	isragdoll = false
end)

local starterGear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear")
tool.Parent = starterGear
tool:Clone().Parent = player:WaitForChild("Backpack")
