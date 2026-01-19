local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local M = {}

local fogEnabled = false
local fogColor = Color3.fromRGB(180, 180, 180)

local picker, preview
local rVal, gVal, bVal
local fogToggleBtn

local function getUI()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return pg:FindFirstChild("eNigmaUI")
end

local function setFog(state)
	fogEnabled = state
	if fogEnabled then
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

local function slider(parent, name, y, startValue)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 20, 0, 18)
	label.Position = UDim2.new(0, 110, 0, y)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(235,235,235)
	label.Text = name
	label.Parent = parent

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 190, 0, 8)
	bar.Position = UDim2.new(0, 135, 0, y + 5)
	bar.BackgroundColor3 = Color3.fromRGB(35,35,42)
	bar.BorderSizePixel = 0
	bar.Parent = parent
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(startValue/255, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0,255,130)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 999)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(startValue/255, -7, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(240,240,240)
	knob.BorderSizePixel = 0
	knob.Parent = bar
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 999)

	local valueLbl = Instance.new("TextLabel")
	valueLbl.BackgroundTransparency = 1
	valueLbl.Size = UDim2.new(0, 40, 0, 18)
	valueLbl.Position = UDim2.new(1, -40, 0, y - 2)
	valueLbl.Font = Enum.Font.Gotham
	valueLbl.TextSize = 12
	valueLbl.TextColor3 = Color3.fromRGB(235,235,235)
	valueLbl.Text = tostring(startValue)
	valueLbl.Parent = parent

	local dragging = false
	local val = startValue

	local function setFromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		val = math.floor(rel * 255 + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, -7, 0.5, 0)
		valueLbl.Text = tostring(val)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
		end
	end)

	return function() return val end
end

local function buildPicker(root)
	if picker then return end

	picker = Instance.new("Frame")
	picker.Name = "FogColorPicker"
	picker.Size = UDim2.fromOffset(360, 250)
	picker.Position = UDim2.new(0.5, -180, 0.5, -125)
	picker.BackgroundColor3 = Color3.fromRGB(16,16,20)
	picker.BorderSizePixel = 0
	picker.Visible = false
	picker.Parent = root

	Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 14)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45,45,55)
	stroke.Thickness = 1
	stroke.Parent = picker

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Position = UDim2.new(0, 0, 0, 6)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.Text = "Fog Color (RGB)"
	title.Parent = picker

	preview = Instance.new("Frame")
	preview.Size = UDim2.fromOffset(80, 80)
	preview.Position = UDim2.new(0, 18, 0, 48)
	preview.BackgroundColor3 = fogColor
	preview.BorderSizePixel = 0
	preview.Parent = picker
	Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 12)

	local r0, g0, b0 = math.floor(fogColor.R*255), math.floor(fogColor.G*255), math.floor(fogColor.B*255)
	rVal = slider(picker, "R", 52, r0)
	gVal = slider(picker, "G", 92, g0)
	bVal = slider(picker, "B", 132, b0)

	local function updatePreview()
		local c = Color3.fromRGB(rVal(), gVal(), bVal())
		preview.BackgroundColor3 = c
	end

	UIS.InputChanged:Connect(function(input)
		if picker.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			updatePreview()
		end
	end)

	local apply = Instance.new("TextButton")
	apply.AutoButtonColor = false
	apply.Size = UDim2.fromOffset(120, 28)
	apply.Position = UDim2.new(1, -140, 1, -44)
	apply.BackgroundColor3 = Color3.fromRGB(0,255,130)
	apply.Text = "Apply"
	apply.Font = Enum.Font.GothamBold
	apply.TextSize = 13
	apply.TextColor3 = Color3.fromRGB(10,10,12)
	apply.Parent = picker
	Instance.new("UICorner", apply).CornerRadius = UDim.new(0, 10)

	local close = Instance.new("TextButton")
	close.AutoButtonColor = false
	close.Size = UDim2.fromOffset(80, 28)
	close.Position = UDim2.new(0, 18, 1, -44)
	close.BackgroundColor3 = Color3.fromRGB(55,55,65)
	close.Text = "Close"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.TextColor3 = Color3.fromRGB(235,235,235)
	close.Parent = picker
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)

	apply.MouseButton1Click:Connect(function()
		fogColor = Color3.fromRGB(rVal(), gVal(), bVal())
		if fogEnabled then
			setFog(true)
		end
		picker.Visible = false
	end)

	close.MouseButton1Click:Connect(function()
		picker.Visible = false
	end)
end

local function findFogToggle()
	local ui = getUI()
	if not ui then return end

	local function scan(obj)
		for _, v in ipairs(obj:GetDescendants()) do
			if v:IsA("TextLabel") and v.Text == "Fog" then
				local row = v.Parent
				if row and row:IsA("Frame") then
					local tb = row:FindFirstChildWhichIsA("TextButton")
					if tb then return tb end
				end
			end
		end
	end

	local btn = scan(ui)
	return btn
end

local inputConn

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
		if not inside then return end

		local ui = getUI()
		if not ui then return end
		buildPicker(ui)

		picker.Visible = true
		preview.BackgroundColor3 = fogColor
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
