local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local M = {}

local fogEnabled = false
local H, S, V = 0.25, 0.8, 0.9

local picker, lockOverlay, preview
local svBox, svCursor, hueBar, hueCursor
local fogToggleBtn
local hooked = false

local draggingSV, draggingH = false, false
local draggingPicker = false
local dragStartPos, pickerStartPos

local function getUI()
	return Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("eNigmaUI")
end

local function getMainFrame()
	local g = getUI()
	if not g then return nil end
	for _, ch in ipairs(g:GetChildren()) do
		if ch:IsA("Frame") then return ch end
	end
	return nil
end

local function currentColor()
	return Color3.fromHSV(H, S, V)
end

local function getOrCreateAtmosphere()
	local atm = Lighting:FindFirstChild("eNigmaFogAtmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Name = "eNigmaFogAtmosphere"
		atm.Parent = Lighting
	end
	return atm
end

local function applyFog()
	local c = currentColor()

	if fogEnabled then
		Lighting.FogStart = 0
		Lighting.FogEnd = 50
		Lighting.FogColor = c

		local atm = getOrCreateAtmosphere()
		atm.Color = c
		atm.Decay = c
		atm.Density = 0.85
		atm.Offset = 0
		atm.Haze = 3
		atm.Glare = 0

	else
		Lighting.FogStart = 0
		Lighting.FogEnd = 9e9
		local atm = Lighting:FindFirstChild("eNigmaFogAtmosphere")
		if atm then atm:Destroy() end
	end
end

local function updateUI()
	local c = currentColor()
	if svBox then svBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1) end
	if svCursor then svCursor.Position = UDim2.new(S, 0, 1 - V, 0) end
	if hueCursor then hueCursor.Position = UDim2.new(0.5, 0, H, 0) end
	if fogEnabled then applyFog() end
end

local function setFog(state)
	fogEnabled = state
	applyFog()
	if lockOverlay then lockOverlay.Visible = not fogEnabled end
end

local function clamp01(x)
	return math.clamp(x, 0, 1)
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

local function makeDraggable(frame, handle)
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingPicker = true
			dragStartPos = input.Position
			pickerStartPos = frame.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingPicker = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if draggingPicker and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStartPos
			frame.Position = UDim2.new(
				pickerStartPos.X.Scale, pickerStartPos.X.Offset + delta.X,
				pickerStartPos.Y.Scale, pickerStartPos.Y.Offset + delta.Y
			)
		end
	end)
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

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 30)
	top.BackgroundTransparency = 1
	top.Parent = picker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -90, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Fog HSV"
	title.Parent = top

	local close = Instance.new("TextButton")
	close.AutoButtonColor = false
	close.Size = UDim2.fromOffset(46, 22)
	close.Position = UDim2.new(1, -54, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.TextColor3 = Color3.fromRGB(235, 235, 235)
	close.Parent = top
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

	makeDraggable(picker, top)

    svBox = Instance.new("Frame")
    svBox.Size = UDim2.fromOffset(160, 140)
    svBox.Position = UDim2.new(0, 12, 0, 38)
    svBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
    svBox.BorderSizePixel = 0
    svBox.Parent = picker
    Instance.new("UICorner", svBox).CornerRadius = UDim.new(0, 10)

    local satOverlay = Instance.new("Frame")
    satOverlay.Size = UDim2.new(1, 0, 1, 0)
    satOverlay.BackgroundColor3 = Color3.fromRGB(255,255,255)
    satOverlay.BorderSizePixel = 0
    satOverlay.Parent = svBox
    Instance.new("UICorner", satOverlay).CornerRadius = UDim.new(0, 10)

    local sat = Instance.new("UIGradient")
    sat.Rotation = 0
    sat.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
    sat.Transparency = NumberSequence.new({
	    NumberSequenceKeypoint.new(0, 0),
	    NumberSequenceKeypoint.new(1, 1)
    })
    sat.Parent = satOverlay

    local valOverlay = Instance.new("Frame")
    valOverlay.Size = UDim2.new(1, 0, 1, 0)
    valOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    valOverlay.BorderSizePixel = 0
    valOverlay.Parent = svBox
    Instance.new("UICorner", valOverlay).CornerRadius = UDim.new(0, 10)

    local val = Instance.new("UIGradient")
    val.Rotation = 90
    val.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
    val.Transparency = NumberSequence.new({
	    NumberSequenceKeypoint.new(0, 1),
	    NumberSequenceKeypoint.new(1, 0)
    })
    val.Parent = valOverlay


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
	hs.Color = Color3.fromRGB(10,10,12)
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

	close.MouseButton1Click:Connect(function()
		picker.Visible = false
	end)

	updateUI()
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
	if not main then return end
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
	lockOverlay.Visible = not fogEnabled
end

local function hookButton()
	if hooked then return end
	fogToggleBtn = findFogToggle()
	if not fogToggleBtn then return end
	hooked = true

	fogToggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			showPickerNear(fogToggleBtn)
		end
	end)
end

function M.enable()
	hookButton()
	setFog(true)
end

function M.disable()
	hookButton()
	setFog(false)
end

return M
