local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local M = {}

local fogEnabled = false
local H, S, V = 0.25, 0.8, 0.9

local picker
local fogToggleBtn
local inputConn
local outsideConn

local svBox, svCursor, hueBar, hueCursor, preview, lockOverlay

local draggingSV = false
local draggingH = false

local debugGui, debugText

local function getUI()
	return Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("eNigmaUI")
end

local function getMainFrame()
	local ui = getUI()
	if not ui then return nil end
	for _, ch in ipairs(ui:GetChildren()) do
		if ch:IsA("Frame") then
			return ch
		end
	end
	return nil
end

local function dbg(msg)
	if not debugText then return end
	debugText.Text = debugText.Text .. "\n" .. tostring(msg)
end

local function dbgClear()
	if debugText then debugText.Text = "Fog Debug:" end
end

local function buildDebug()
	if debugGui then return end
	local ui = getUI()
	if not ui then return end
	local main = getMainFrame()
	if not main then return end

	debugGui = Instance.new("Frame")
	debugGui.Name = "eNigma_Debug"
	debugGui.Size = UDim2.fromOffset(250, 150)
	debugGui.Position = UDim2.new(1, -260, 0, 10)
	debugGui.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	debugGui.BackgroundTransparency = 0.15
	debugGui.BorderSizePixel = 0
	debugGui.Parent = main

	Instance.new("UICorner", debugGui).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 75)
	stroke.Thickness = 1
	stroke.Parent = debugGui

	debugText = Instance.new("TextLabel")
	debugText.BackgroundTransparency = 1
	debugText.Size = UDim2.new(1, -10, 1, -10)
	debugText.Position = UDim2.new(0, 5, 0, 5)
	debugText.Font = Enum.Font.Code
	debugText.TextSize = 12
	debugText.TextColor3 = Color3.fromRGB(235, 235, 235)
	debugText.TextXAlignment = Enum.TextXAlignment.Left
	debugText.TextYAlignment = Enum.TextYAlignment.Top
	debugText.TextWrapped = true
	debugText.Text = "Fog Debug:"
	debugText.Parent = debugGui
end

local function applyFog()
	local c = Color3.fromHSV(H, S, V)
	if fogEnabled then
		Lighting.FogStart = 0
		Lighting.FogEnd = 150
		Lighting.FogColor = c

		local atm = Lighting:FindFirstChild("CustomFogAtmosphere")
		if not atm then
			atm = Instance.new("Atmosphere")
			atm.Name = "CustomFogAtmosphere"
			atm.Parent = Lighting
		end
		atm.Color = c
		atm.Decay = c
		atm.Density = 0.35
		atm.Offset = 0
	else
		Lighting.FogStart = 0
		Lighting.FogEnd = 9e9
		local atm = Lighting:FindFirstChild("CustomFogAtmosphere")
		if atm then atm:Destroy() end
	end
end

local function setFog(state)
	fogEnabled = state
	applyFog()
	if lockOverlay then
		lockOverlay.Visible = not fogEnabled
	end
end

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function updateUI()
	local c = Color3.fromHSV(H, S, V)
	if preview then preview.BackgroundColor3 = c end
	if svBox then svBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1) end
	if svCursor then svCursor.Position = UDim2.new(S, 0, 1 - V, 0) end
	if hueCursor then hueCursor.Position = UDim2.new(0.5, 0, H, 0) end
	if fogEnabled then applyFog() end
end

local function setSV(mx, my)
	local ap = svBox.AbsolutePosition
	local as = svBox.AbsoluteSize
	S = clamp01((mx - ap.X) / as.X)
	V = 1 - clamp01((my - ap.Y) / as.Y)
	updateUI()
end

local function setH(my)
	local ap = hueBar.AbsolutePosition
	local as = hueBar.AbsoluteSize
	H = clamp01((my - ap.Y) / as.Y)
	updateUI()
end

local function buildPicker(parent)
	if picker then return end

	picker = Instance.new("Frame")
	picker.Name = "eNigma_FogHSVPicker"
	picker.Size = UDim2.fromOffset(270, 190)
	picker.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	picker.BorderSizePixel = 0
	picker.Visible = false
	picker.Parent = parent
	picker.Active = true

	Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = picker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 22)
	title.Position = UDim2.new(0, 10, 0, 6)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Fog HSV"
	title.Parent = picker

	preview = Instance.new("Frame")
	preview.Size = UDim2.fromOffset(22, 22)
	preview.Position = UDim2.new(1, -32, 0, 6)
	preview.BackgroundColor3 = Color3.fromHSV(H, S, V)
	preview.BorderSizePixel = 0
	preview.Parent = picker
	Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 7)

	svBox = Instance.new("Frame")
	svBox.Size = UDim2.fromOffset(160, 140)
	svBox.Position = UDim2.new(0, 12, 0, 38)
	svBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
	svBox.BorderSizePixel = 0
	svBox.Parent = picker
	Instance.new("UICorner", svBox).CornerRadius = UDim.new(0, 10)

	local sat = Instance.new("UIGradient")
	sat.Rotation = 0
	sat.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	sat.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	sat.Parent = svBox

	local valOverlay2 = Instance.new("Frame")
	valOverlay2.Size = UDim2.new(1, 0, 1, 0)
	valOverlay2.BackgroundColor3 = Color3.new(0, 0, 0)
	valOverlay2.BorderSizePixel = 0
	valOverlay2.Parent = svBox
	Instance.new("UICorner", valOverlay2).CornerRadius = UDim.new(0, 10)

	local val = Instance.new("UIGradient")
	val.Rotation = 90
	val.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
	val.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	val.Parent = valOverlay2

	svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.fromOffset(12, 12)
	svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	svCursor.Position = UDim2.new(S, 0, 1 - V, 0)
	svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	svCursor.BorderSizePixel = 0
	svCursor.Parent = svBox
	Instance.new("UICorner", svCursor).CornerRadius = UDim.new(0, 999)
	local cs = Instance.new("UIStroke")
	cs.Color = Color3.fromRGB(10, 10, 12)
	cs.Thickness = 2
	cs.Parent = svCursor

	hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.fromOffset(16, 140)
	hueBar.Position = UDim2.new(0, 184, 0, 38)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel = 0
	hueBar.Parent = picker
	Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 999)

	local hue = Instance.new("UIGradient")
	hue.Rotation = 90
	hue.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0))
	})
	hue.Parent = hueBar

	hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 8, 0, 4)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.Position = UDim2.new(0.5, 0, H, 0)
	hueCursor.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hueBar
	Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(0, 999)
	local hs = Instance.new("UIStroke")
	hs.Color = Color3.fromRGB(10, 10, 12)
	hs.Thickness = 1
	hs.Parent = hueCursor

	lockOverlay = Instance.new("Frame")
	lockOverlay.Size = UDim2.new(1, 0, 1, 0)
	lockOverlay.BackgroundColor3 = Color3.fromRGB(10,10,12)
	lockOverlay.BackgroundTransparency = 0.35
	lockOverlay.BorderSizePixel = 0
	lockOverlay.Visible = not fogEnabled
	lockOverlay.Parent = picker
	Instance.new("UICorner", lockOverlay).CornerRadius = UDim.new(0, 12)

	local lockText = Instance.new("TextLabel")
	lockText.BackgroundTransparency = 1
	lockText.Size = UDim2.new(1, 0, 1, 0)
	lockText.Font = Enum.Font.GothamBold
	lockText.TextSize = 14
	lockText.TextColor3 = Color3.fromRGB(235,235,235)
	lockText.Text = "Enable Fog to edit color"
	lockText.Parent = lockOverlay

	svBox.InputBegan:Connect(function(input)
		if not fogEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = true
			setSV(input.Position.X, input.Position.Y)
		end
	end)

	svBox.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = false
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if not fogEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingH = true
			setH(input.Position.Y)
		end
	end)

	hueBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingH = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not fogEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if draggingSV then
				setSV(input.Position.X, input.Position.Y)
			elseif draggingH then
				setH(input.Position.Y)
			end
		end
	end)
end

local function findFogToggle()
	local g = getUI()
	if not g then return nil end
	for _, v in ipairs(g:GetDescendants()) do
		if v:IsA("TextLabel") and v.Text == "Fog" then
			local row = v.Parent
			if row and row:IsA("Frame") then
				local tb = row:FindFirstChildWhichIsA("TextButton")
				if tb then return tb end
			end
		end
	end
	return nil
end

local function showPickerNear(btn)
	local main = getMainFrame()
	if not main then dbg("main frame = nil") return end

	buildPicker(main)

	local ap = btn.AbsolutePosition
	local as = btn.AbsoluteSize
	local mp = main.AbsolutePosition
	local ms = main.AbsoluteSize

	local x = (ap.X - mp.X) + as.X + 12
	local y = (ap.Y - mp.Y) - 10

	x = math.clamp(x, 10, ms.X - 270 - 10)
	y = math.clamp(y, 10, ms.Y - 190 - 10)

	picker.Position = UDim2.fromOffset(x, y)
	picker.Visible = true

	dbg("picker visible @ " .. x .. "," .. y)

	if outsideConn then outsideConn:Disconnect() outsideConn = nil end
	outsideConn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not picker.Visible then return end
		local pos = UIS:GetMouseLocation()
		local pa = picker.AbsolutePosition
		local ps = picker.AbsoluteSize
		local inside = pos.X >= pa.X and pos.X <= pa.X + ps.X and pos.Y >= pa.Y and pos.Y <= pa.Y + ps.Y
		if not inside then
			picker.Visible = false
			dbg("picker закрыт (click outside)")
		end
	end)
end

local function hookRightClick()
	if inputConn then return end

	inputConn = UIS.InputBegan:Connect(function(input, gp)
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

		buildDebug()
		dbgClear()
		dbg("ПКМ detected | gp=" .. tostring(gp))

		if not fogToggleBtn or not fogToggleBtn.Parent then
			fogToggleBtn = findFogToggle()
			dbg("fogToggleBtn=" .. tostring(fogToggleBtn))
		end
		if not fogToggleBtn then
			dbg("Fog toggle НЕ найден")
			return
		end

		local pos = UIS:GetMouseLocation()
		local ap = fogToggleBtn.AbsolutePosition
		local as = fogToggleBtn.AbsoluteSize

		local inside = pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
		dbg("mouse=" .. math.floor(pos.X) .. "," .. math.floor(pos.Y))
		dbg("toggle=" .. math.floor(ap.X) .. "," .. math.floor(ap.Y) .. " size=" .. as.X .. "x" .. as.Y)
		dbg("inside=" .. tostring(inside))

		if inside then
			showPickerNear(fogToggleBtn)
		end
	end)
end

function M.enable()
	buildDebug()
	hookRightClick()
	setFog(true)
	dbg("Fog enable()")
end

function M.disable()
	buildDebug()
	hookRightClick()
	setFog(false)
	dbg("Fog disable()")
end

return M
