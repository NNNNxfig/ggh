local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local M = {}

local enabled = false
local platform = nil
local hbConn = nil

local removed = {}
local removedParents = {}

local function isPlayerInstance(inst)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch and inst:IsDescendantOf(ch) then
			return true
		end
	end
	return false
end

local function isSafeRoot(inst)
	if inst == Workspace then return true end
	if inst == Workspace.Terrain then return true end

	local cam = Workspace:FindFirstChildWhichIsA("Camera")
	if cam and (inst == cam or inst:IsDescendantOf(cam)) then
		return true
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch and (inst == ch or inst:IsDescendantOf(ch)) then
			return true
		end
	end

	return false
end

local function shouldDelete(inst)
	if not inst or not inst.Parent then return false end
	if isSafeRoot(inst) then return false end
	if isPlayerInstance(inst) then return false end
	if inst:IsA("Player") then return false end
	return true
end

local function createPlatform()
	if platform then return end
	platform = Instance.new("Part")
	platform.Name = "eNigma_DeleteAllPlatform"
	platform.Anchored = true
	platform.CanCollide = true
	platform.Locked = true
	platform.Size = Vector3.new(40, 2, 40)
	platform.Transparency = 0.35
	platform.Parent = Workspace
end

local function removePlatform()
	if platform then
		platform:Destroy()
		platform = nil
	end
end

local function getRootPart()
	local lp = Players.LocalPlayer
	local ch = lp and lp.Character
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function updatePlatform()
	local hrp = getRootPart()
	if not hrp then return end
	if not platform then createPlatform() end
	platform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 6, hrp.Position.Z)
end

local function deleteMap()
	table.clear(removed)
	table.clear(removedParents)

	for _, inst in ipairs(Workspace:GetChildren()) do
		if inst ~= Workspace.Terrain and not isSafeRoot(inst) then
			if shouldDelete(inst) then
				removed[inst] = true
				removedParents[inst] = inst.Parent
				inst.Parent = nil
			end
		end
	end

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if shouldDelete(inst) then
			local top = inst
			while top.Parent and top.Parent ~= Workspace do
				top = top.Parent
			end

			if top and shouldDelete(top) and not removed[top] then
				removed[top] = true
				removedParents[top] = top.Parent
				top.Parent = nil
			end
		end
	end
end

local function restoreMap()
	for inst in pairs(removed) do
		if inst and inst.Parent == nil then
			local p = removedParents[inst]
			if p and p.Parent then
				inst.Parent = p
			else
				inst.Parent = Workspace
			end
		end
	end
	table.clear(removed)
	table.clear(removedParents)
end

function M.enable()
	if enabled then return end
	enabled = true

	createPlatform()
	updatePlatform()

	deleteMap()

	hbConn = RunService.Heartbeat:Connect(function()
		if not enabled then return end
		updatePlatform()
	end)
end

function M.disable()
	if not enabled then return end
	enabled = false

	if hbConn then
		hbConn:Disconnect()
		hbConn = nil
	end

	restoreMap()
	removePlatform()
end

return M
