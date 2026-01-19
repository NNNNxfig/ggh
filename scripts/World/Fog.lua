local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local M = {}

local fogEnabled = false
local fogColor = Color3.fromHSV(0.25, 0.8, 0.9)
local H, S, V = 0.25, 0.8, 0.9

local picker
local fogToggleBtn
local inputConn
local outsideConn

local satval, satvalCursor
local hueBar, hueCursor
local preview
local lockOverlay

local draggingSV = false
local draggingH = false
local draggingPicker = false
local dragStartPos, pickerStartPos

local function getUI()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return pg:FindFirstChild("eNigmaUI")
end

local function getMainFrame()
	local ui = getUI()
	if not ui then return end
	for _, ch in ipairs(ui:GetChildren()) do
		if ch:IsA("Frame") then
			return ch
		end
	end
end

local function setFog(state)
	fogEnabled = state
	if fogEnabled then
		fogColor = Color3.fromHSV(H, S, V)
		Lighting.FogStart = 0
		Lighting.FogEnd = 150
		Lighting.FogColor = fogColor

		local atm = Lighting:FindFirstChild("CustomFogAtmosphere")
		if not atm then
			atm = Instance.new("Atmosphere")
			atm.Name = "CustomFogAtmosphere"
			atm.Parent = Lighting
		end
		atm.Color = fogColor
		atm.Decay = fogColor
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
	if picker then
		lockOverlay.Visible = not fogEnabled
		lockOverlay.BackgroundTransparency = fogEnabled and 1 or 0.35
	end
end

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function updateFromHSV()
	fogColor = Color3.fromHSV(H, S, V)
	if preview then preview.BackgroundColor3 = fogColor end
	if satval then
		local hueColor = Color3.fromHSV(H, 1, 1)
		satval.BackgroundColor3 = hueColor
	end
	if satvalCursor then
		satvalCursor.Position = UDim2.new(S, 0, 1 - V, 0)
	end
	if hueCursor then
		hueCursor.Position = UDim2.new(0.5, 0, H, 0)
	end
	if fogEnabled then
		applyFog()
	end
end

local function setSVFromMouse(x, y)
	local ap = satval.AbsolutePosition
	local as = satval.AbsoluteSize

	local sx = clamp01((x - ap.X) / as.X)
	local sy = clamp01((y - ap.Y) / as.Y)

	S = sx
	V = 1 - sy
	updateFromHSV()
end

local function setHFromMouse(y)
	local ap = hueBar.AbsolutePosition
	local as = hueBar.AbsoluteSize

	local hy = clamp01((y - ap.Y) / as.Y)
	H = hy
	updateFromHSV()
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

local function buildHSVPicker(parent)
	if picker then return end

	picker = Instance.new("Frame")
	picker.Name = "eNigma_FogHSVPicker"
	picker.Size = UDim2.fromOffset(280, 190)
	picker.BackgroundColor3 = Color3.fromRGB(16,16,20)
	picker.BorderSizePixel = 0
	picker.Visible = false
	picker.Parent = parent
	picker.Active = true

	Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45,45,55)
	stroke.Thickness = 1
	stroke.Parent = picker

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 30)
	top.BackgroundTransparency = 1
	top.Parent = picker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Fog Color (HSV)"
	title.Parent = top

	local close = Instance.new("TextButton")
	close.AutoButtonColor = false
	close.Size = UDim2.fromOffset(46, 22)
	close.Position = UDim2.new(1, -54, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(55,55,65)
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.TextColor3 = Color3.fromRGB(235,235,235)
	close.Parent = top
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

	preview = Instance.new("Frame")
	preview.Size = UDim2.fromOffset(22, 22)
	preview.Position = UDim2.new(1, -28, 0, 4)
	preview.BackgroundColor3 = fogColor
	preview.BorderSizePixel = 0
	preview.Parent = top
	Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 7)

	makeDraggable(picker, top)

	satval = Instance.new("Frame")
	satval.Size = UDim2.fromOffset(160, 140)
	satval.Position = UDim2.new(0, 12, 0, 38)
	satval.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
	satval.BorderSizePixel = 0
	satval.Parent = picker
	Instance.new("UICorner", satval).CornerRadius = UDim.new(0, 10)

	local satGrad = Instance.new("UIGradient")
	satGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
	satGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	satGrad.Rotation = 0
	satGrad.Parent = satval

	local valOverlay = Instance.new("Frame")
	valOverlay.Size = UDim2.new(1, 0, 1, 0)
	valOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	valOverlay.BorderSizePixel = 0
	valOverlay.Parent = satval
	Instance.new("UICorner", valOverlay).CornerRadius = UDim.new(0, 10)

	local valGrad = Instance.new("UIGradient")
	valGrad.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
	valGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	valGrad.Rotation = 90
	valGrad.Parent = valOverlay

	satvalCursor = Instance.new("Frame")
	satvalCursor.Size = UDim2.fromOffset(12, 12)
	satvalCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	satvalCursor.Position = UDim2.new(S, 0, 1 - V, 0)
	satvalCursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
	satvalCursor.BorderSizePixel = 0
	satvalCursor.Parent = satval
	Instance.new("UICorner", satvalCursor).CornerRadius = UDim.new(0, 999)

	local cursorStroke = Instance.new("UIStroke")
	cursorStroke.Color = Color3.fromRGB(10,10,12)
	cursorStroke.Thickness = 2
	cursorStroke.Parent = satvalCursor

	hueBar = Instance.new("Frame")
	hueBar.Size = UDim2.fromOffset(16, 140)
	hueBar.Position = UDim2.new(0, 184, 0, 38)
	hueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
	hueBar.BorderSizePixel = 0
	hueBar.Parent = picker
	Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 999)

	local hueGrad = Instance.new("UIGradient")
	hueGrad.Rotation = 90
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0))
	})
	hueGrad.Parent = hueBar

	hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(1, 8, 0, 4)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.Position = UDim2.new(0.5, 0, H, 0)
	hueCursor.BackgroundColor3 = Color3.fromRGB(240,240,240)
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hueBar
	Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(0, 999)

	local hueStroke = Instance.new("UIStroke")
	hueStroke.Color = Color3.fromRGB(10,10,12)
	hueStroke.Thickness = 1
	hueStroke.Parent = hueCursor

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Size = UDim2.fromOffset(70, 50)
	info.Position = UDim2.new(0, 210, 0, 62)
	info.Font = Enum.Font.Gotham
	info.TextSize = 11
	info.TextColor3 = Color3.fromRGB(235,235,235)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Text = "ПКМ: открыть\nТуман: ON/OFF\nЦвет: Live"
	info.Parent = picker

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

	satval.InputBegan:Connect(function(input)
		if not fogEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = true
			setSVFromMouse(input.Position.X, input.Position.Y)
		end
	end)

	satval.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSV = false
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if not fogEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingH = true
			setHFromMouse(input.Position.Y)
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
				setSVFromMouse(input.Position.X, input.Position.Y)
			elseif draggingH then
				setHFromMouse(input.Position.Y)
			end
		end
	end)

	close.MouseButton1Click:Connect(function()
		picker.Visible = false
		if outsideConn then outsideConn:Disconnect() outsideConn = nil end
	end)

	updateFromHSV()
end

local function findFogToggle()
	local ui = getUI()
	if not ui then return end
	for _, v in ipairs(ui:GetDescendants()) do
		if v:IsA("TextLabel") and v.Text == "Fog" then
			local row = v.Parent
			if row and row:IsA("Frame") then
				local tb = row:FindFirstChildWhichIsA("TextButton")
				if tb then return tb end
			end
		end
	end
end

local function showPickerNear(btn)
	local main = getMainFrame()
	if not main then return end
	buildHSVPicker(main)

	local ap = btn.AbsolutePosition
	local as = btn.AbsoluteSize
	local mp = main.AbsolutePosition
	local ms = main.AbsoluteSize

	local localX = (ap.X - mp.X) + as.X + 12
	local localY = (ap.Y - mp.Y) - 10

	local maxX = ms.X - 280 - 10
	local maxY = ms.Y - 190 - 10

	localX = math.clamp(localX, 10, maxX)
	localY = math.clamp(localY, 10, maxY)

	picker.Position = UDim2.fromOffset(localX, localY)
	picker.Visible = true
	lockOverlay.Visible = not fogEnabled
	lockOverlay.BackgroundTransparency = fogEnabled and 1 or 0.35

	if outsideConn then outsideConn:Disconnect() outsideConn = nil end
	outsideConn = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not picker.Visible then return end
		local pos = UIS:GetMouseLocation()
		local pa = picker.AbsolutePosition
		local ps = picker.AbsoluteSize
		local inside = pos.X >= pa.X and pos.X <= pa.X + ps.X and pos.Y >= pa.Y and pos.Y <= pa.Y + ps.Y
		if not inside then
			picker.Visible = false
			if outsideConn then outsideConn:Disconnect() outsideConn = nil end
		end
	end)
end

local function hookRightClick()
	if inputConn then return end
	inputConn = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

		if not fogToggleBtn or not fogToggleBtn.Parent then
			fogToggleBtn = findFogToggle()
		end
		if not fogToggleBtn then return end

		local pos = UIS:GetMouseLocation()
		local ap = fogToggleBtn.AbsolutePosition
		local as = fogToggleBtn.AbsoluteSize
		local inside = pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y

		if inside then
			showPickerNear(fogToggleBtn)
		end
	end)
end

function M.enable()
	hookRightClick()
	setFog(true)
end

function M.disable()
	hookRightClick()
	setFog(false)
end

return M
