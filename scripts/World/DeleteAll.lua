local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local M = {}

local enabled = false
local platform = nil
local stepConn = nil

local removed = {}
local removedParents = {}

local PLATFORM_NAME = "eNigma_DeleteAllPlatform"

local function lpChar()
	local lp = Players.LocalPlayer
	return lp and lp.Character
end

local function isAnyPlayerChar(inst)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch and inst:IsDescendantOf(ch) then
			return true
		end
	end
	return false
end

local function modelIsHumanoidRig(model)
	if not model or not model:IsA("Model") then return false end

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		return true
	end

	local pp = model.PrimaryPart
	if pp and (pp.Name == "HumanoidRootPart" or pp.Name == "Head") then
		return true
	end

	if model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") then
		return true
	end

	return false
end

local function isProtectedTop(top)
	if not top or top == Workspace then return true end
	if top == Workspace.Terrain then return true end
	if top:IsA("Camera") then return true end
	if top.Name == PLATFORM_NAME then return true end

	local cam = Workspace.CurrentCamera
	if cam and (top == cam or top:IsDescendantOf(cam)) then
		return true
	end

	if isAnyPlayerChar(top) then return true end
	if top:IsA("Model") and modelIsHumanoidRig(top) then return true end

	return false
end

local function isMapObject(top)
	if not top or not top.Parent then return false end
	if isProtectedTop(top) then return false end

	if top:IsA("Model") then return true end
	if top:IsA("Folder") then return true end
	if top:IsA("BasePart") then return true end
	if top:IsA("UnionOperation") then return true end
	if top:IsA("MeshPart") then return true end
	if top:IsA("TrussPart") then return true end
	if top:IsA("SpawnLocation") then return true end

	return false
end

local function createPlatform()
	if platform and platform.Parent then return end

	platform = Instance.new("Part")
	platform.Name = PLATFORM_NAME
	platform.Anchored = true
	platform.CanCollide = true
	platform.Locked = true
	platform.Size = Vector3.new(250, 6, 250)
	platform.Transparency = 1
	platform.Parent = Workspace
end

local function removePlatform()
	if platform then
		platform:Destroy()
		platform = nil
	end
end

local function getRootPart()
	local ch = lpChar()
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function ensureCamera()
	local cam = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Name = "Camera"
		cam.Parent = Workspace
		Workspace.CurrentCamera = cam
	end

	local ch = lpChar()
	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
	end
end

local function updatePlatform()
	local hrp = getRootPart()
	if not hrp then return end
	if not platform then createPlatform() end
	platform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 8, hrp.Position.Z)
end

local function deleteMap()
	table.clear(removed)
	table.clear(removedParents)

	for _, top in ipairs(Workspace:GetChildren()) do
		if isMapObject(top) then
			removed[top] = true
			removedParents[top] = top.Parent
			top.Parent = nil
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

	ensureCamera()

	createPlatform()
	updatePlatform()

	deleteMap()

	stepConn = RunService.RenderStepped:Connect(function()
		if not enabled then return end
		ensureCamera()
		updatePlatform()
	end)
end

function M.disable()
	if not enabled then return end
	enabled = false

	if stepConn then
		stepConn:Disconnect()
		stepConn = nil
	end

	restoreMap()
	removePlatform()

	task.defer(function()
		ensureCamera()
	end)
end

return M
