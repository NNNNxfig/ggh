local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local M = {}

local enabled = false
local platform = nil
local stepConn = nil

local PLATFORM_NAME = "eNigma_DeleteAllPlatform"
local DEBUG_NAME = "eNigma_DeleteAllDebug"

local removed = {}
local removedParents = {}

local function getUI()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return pg:FindFirstChild("eNigmaUI")
end

local function getMainFrame()
	local g = getUI()
	if not g then return nil end
	for _, ch in ipairs(g:GetChildren()) do
		if ch:IsA("Frame") then return ch end
	end
	return nil
end

local debugFrame, debugText

local function dbg(msg)
	if debugText then
		debugText.Text = tostring(msg) .. "\n" .. debugText.Text
		if #debugText.Text > 3000 then
			debugText.Text = debugText.Text:sub(1, 3000)
		end
	end
end

local function clearDbg()
	if debugText then
		debugText.Text = ""
	end
end

local function buildDebug()
	if debugFrame and debugFrame.Parent then return end

	local main = getMainFrame()
	if not main then return end

	debugFrame = main:FindFirstChild(DEBUG_NAME)
	if debugFrame then
		debugText = debugFrame:FindFirstChild("Log")
		return
	end

	debugFrame = Instance.new("Frame")
	debugFrame.Name = DEBUG_NAME
	debugFrame.Size = UDim2.fromOffset(300, 180)
	debugFrame.Position = UDim2.new(1, -310, 1, -190)
	debugFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	debugFrame.BorderSizePixel = 0
	debugFrame.Parent = main
	debugFrame.ZIndex = 999

	local cr = Instance.new("UICorner", debugFrame)
	cr.CornerRadius = UDim.new(0, 12)

	local st = Instance.new("UIStroke", debugFrame)
	st.Color = Color3.fromRGB(45, 45, 55)
	st.Thickness = 1

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -70, 0, 22)
	title.Position = UDim2.new(0, 10, 0, 6)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "DeleteAll Debug"
	title.Parent = debugFrame
	title.ZIndex = 1000

	local close = Instance.new("TextButton")
	close.AutoButtonColor = false
	close.Size = UDim2.fromOffset(48, 20)
	close.Position = UDim2.new(1, -56, 0, 6)
	close.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.TextColor3 = Color3.fromRGB(235,235,235)
	close.Parent = debugFrame
	close.ZIndex = 1001
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

	local box = Instance.new("ScrollingFrame")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 10, 0, 32)
	box.Size = UDim2.new(1, -20, 1, -42)
	box.ScrollBarThickness = 3
	box.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85)
	box.CanvasSize = UDim2.new(0, 0, 0, 0)
	box.Parent = debugFrame
	box.ZIndex = 1000

	debugText = Instance.new("TextLabel")
	debugText.Name = "Log"
	debugText.BackgroundTransparency = 1
	debugText.Size = UDim2.new(1, 0, 0, 0)
	debugText.Position = UDim2.new(0, 0, 0, 0)
	debugText.Font = Enum.Font.Code
	debugText.TextSize = 12
	debugText.TextColor3 = Color3.fromRGB(235,235,235)
	debugText.TextXAlignment = Enum.TextXAlignment.Left
	debugText.TextYAlignment = Enum.TextYAlignment.Top
	debugText.TextWrapped = true
	debugText.Text = ""
	debugText.Parent = box
	debugText.ZIndex = 1001

	local function updateCanvas()
		local bounds = debugText.TextBounds
		debugText.Size = UDim2.new(1, 0, 0, bounds.Y + 10)
		box.CanvasSize = UDim2.new(0, 0, 0, bounds.Y + 20)
	end

	debugText:GetPropertyChangedSignal("Text"):Connect(updateCanvas)

	close.MouseButton1Click:Connect(function()
		debugFrame.Visible = false
	end)

	dbg("debug created")
end

local function getRootPart()
	local lp = Players.LocalPlayer
	local ch = lp and lp.Character
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function createPlatform()
	if platform and platform.Parent then
		dbg("platform already exists: parent=" .. platform.Parent:GetFullName())
		return
	end

	platform = Instance.new("Part")
	platform.Name = PLATFORM_NAME
	platform.Anchored = true
	platform.CanCollide = true
	platform.Locked = true
	platform.Size = Vector3.new(250, 6, 250)
	platform.Transparency = 0.2
	platform.Material = Enum.Material.Neon
	platform.Color = Color3.fromRGB(0, 255, 130)

	platform.Parent = Workspace
	dbg("platform created: " .. platform:GetFullName())
end

local function removePlatform()
	if platform then
		dbg("platform destroy")
		platform:Destroy()
		platform = nil
	end
end

local function updatePlatform()
	if not platform or not platform.Parent then
		dbg("updatePlatform: platform missing -> recreating")
		createPlatform()
	end

	local hrp = getRootPart()
	if not hrp then
		dbg("updatePlatform: HRP missing")
		return
	end

	local y = hrp.Position.Y - 8
	platform.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)

	dbg(("platform pos: %.1f %.1f %.1f"):format(platform.Position.X, platform.Position.Y, platform.Position.Z))
end

local function shouldDelete(inst)
	if not inst or not inst.Parent then return false end
	if inst == platform then return false end
	if inst.Name == PLATFORM_NAME then return false end
	if inst:IsDescendantOf(Players.LocalPlayer.Character or Instance.new("Folder")) then return false end
	return true
end

local function deleteMap()
	table.clear(removed)
	table.clear(removedParents)

	dbg("deleteMap: start")

	for _, inst in ipairs(Workspace:GetChildren()) do
		if shouldDelete(inst) and inst ~= Workspace.Terrain then
			removed[inst] = true
			removedParents[inst] = inst.Parent
			inst.Parent = nil
		end
	end

	dbg("deleteMap: done, removed=" .. tostring((function()
		local c = 0
		for _ in pairs(removed) do c += 1 end
		return c
	end)()))
end

local function restoreMap()
	local restored = 0
	for inst in pairs(removed) do
		if inst and inst.Parent == nil then
			local p = removedParents[inst]
			if p and p.Parent then
				inst.Parent = p
			else
				inst.Parent = Workspace
			end
			restored += 1
		end
	end
	table.clear(removed)
	table.clear(removedParents)
	dbg("restoreMap: restored=" .. tostring(restored))
end

function M.enable()
	if enabled then return end
	enabled = true

	buildDebug()
	clearDbg()
	dbg("ENABLE DeleteAll")

	dbg("workspace=" .. Workspace:GetFullName())

	createPlatform()
	updatePlatform()

	deleteMap()

	stepConn = RunService.RenderStepped:Connect(function()
		if enabled then
			updatePlatform()
		end
	end)
end

function M.disable()
	if not enabled then return end
	enabled = false

	buildDebug()
	dbg("DISABLE DeleteAll")

	if stepConn then
		stepConn:Disconnect()
		stepConn = nil
	end

	restoreMap()
	removePlatform()
end

return M
