-- ragdoll script :)
-- by minishakk, don't distribute without contacting @minishakk on Discord first.

local player = game.Players.LocalPlayer

local tool = Instance.new("Tool")
tool.Name = "Ragdoll"
tool.CanBeDropped = false
tool.RequiresHandle = true

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(1, 1, 1)
handle.Transparency = 1
handle.CanCollide = false
handle.Parent = tool

local function ragdoll(character)
	local motors = {}

	for _, motor in ipairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local part0, part1 = motor.Part0, motor.Part1
			if part0 and part1 then
				table.insert(motors, {
					Name = motor.Name,
					Parent = motor.Parent,
					Part0 = part0,
					Part1 = part1,
					C0 = motor.C0,
					C1 = motor.C1,
				})

				local a0 = Instance.new("Attachment")
				a0.CFrame = motor.C0
				a0.Name = "RagdollAttachment0"
				a0.Parent = part0

				local a1 = Instance.new("Attachment")
				a1.CFrame = motor.C1
				a1.Name = "RagdollAttachment1"
				a1.Parent = part1

				local constraint = Instance.new("BallSocketConstraint")
				constraint.Attachment0 = a0
				constraint.Attachment1 = a1
				constraint.Name = "RagdollConstraint"
				constraint.Parent = part0
			end
			motor:Destroy()
		end
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local force = Instance.new("BodyVelocity")
		force.Velocity = root.CFrame.LookVector * 50
		force.MaxForce = Vector3.new(1e5, 0, 1e5)
		force.P = 1e4
		force.Parent = root
		game:GetService("Debris"):AddItem(force, 0.5)
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end

	task.wait(3)

	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("BallSocketConstraint") and desc.Name == "RagdollConstraint" then
			desc:Destroy()
		elseif desc:IsA("Attachment") and (desc.Name == "RagdollAttachment0" or desc.Name == "RagdollAttachment1") then
			desc:Destroy()
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
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local equipped = false
local mouseDownConnection

local mouse = player:GetMouse()

tool.Equipped:Connect(function()
	equipped = true
	mouseDownConnection = mouse.Button1Down:Connect(function()
		if equipped and mouse.Target then
			ragdoll(player.Character)
		end
	end)
end)

tool.Unequipped:Connect(function()
	equipped = false
	if mouseDownConnection then
		mouseDownConnection:Disconnect()
		mouseDownConnection = nil
	end
end)

tool.Parent = player.Backpack
