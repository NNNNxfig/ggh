local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local baseURL = (_G.eNigma and _G.eNigma.baseURL) or ""

local function import(path)
	local src = game:HttpGet(baseURL .. path)
	return loadstring(src)()
end

local function tryImport(path)
	local ok, res = pcall(function()
		return import(path)
	end)
	if ok then return true, res end
	return false, tostring(res)
end

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local ACCENT1 = Color3.fromRGB(210, 255, 40)
local ACCENT2 = Color3.fromRGB(0, 255, 130)

local BG = Color3.fromRGB(10, 10, 12)
local PANEL = Color3.fromRGB(16, 16, 20)
local PANEL2 = Color3.fromRGB(22, 22, 27)

local BORDER = Color3.fromRGB(45, 45, 55)
local TEXT = Color3.fromRGB(235, 235, 235)

local gui = Instance.new("ScreenGui")
gui.Name = "eNigmaUI"
gui.ResetOnSpawn = false
gui.Parent = pg

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(720, 440)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = BG
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = BORDER
stroke.Thickness = 1
stroke.Parent = main

local centerPos = UDim2.fromScale(0.5, 0.5)
local hiddenPos = UDim2.new(0.5, 0, 1.25, 0)

main.Position = hiddenPos
main.Visible = true

local isOpen = false
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function OpenMenu()
	isOpen = true
	main.Visible = true
	TweenService:Create(main, tweenInfo, { Position = centerPos }):Play()
end

local function CloseMenu()
	isOpen = false
	TweenService:Create(main, tweenInfo, { Position = hiddenPos }):Play()
end

do
	local dragging, dragStart, startPos = false, nil, nil
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 200, 1, 0)
sidebar.BackgroundColor3 = PANEL
sidebar.Parent = main

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 12)
sideCorner.Parent = sidebar

local sideMask = Instance.new("Frame")
sideMask.BackgroundColor3 = PANEL
sideMask.BorderSizePixel = 0
sideMask.Position = UDim2.new(1, -12, 0, 0)
sideMask.Size = UDim2.new(0, 12, 1, 0)
sideMask.Parent = sidebar

local sideStroke = Instance.new("UIStroke")
sideStroke.Color = BORDER
sideStroke.Thickness = 1
sideStroke.Parent = sidebar

local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 12)
sidePad.PaddingLeft = UDim.new(0, 12)
sidePad.PaddingRight = UDim.new(0, 12)
sidePad.PaddingBottom = UDim.new(0, 12)
sidePad.Parent = sidebar

local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Size = UDim2.new(1, 0, 0, 26)
brand.Font = Enum.Font.GothamBlack
brand.TextSize = 22
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Text = "eNigma"
brand.TextColor3 = TEXT
brand.Parent = sidebar

local brandGrad = Instance.new("UIGradient")
brandGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ACCENT1),
	ColorSequenceKeypoint.new(1, ACCENT2)
})
brandGrad.Parent = brand

local brandLine = Instance.new("Frame")
brandLine.BorderSizePixel = 0
brandLine.Size = UDim2.new(1, -40, 0, 2)
brandLine.Position = UDim2.new(0, 0, 0, 30)
brandLine.BackgroundColor3 = ACCENT2
brandLine.Parent = sidebar

local brandLineGrad = Instance.new("UIGradient")
brandLineGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ACCENT1),
	ColorSequenceKeypoint.new(1, ACCENT2)
})
brandLineGrad.Parent = brandLine

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.Size = UDim2.new(1, 0, 1, -44)
tabScroll.Position = UDim2.new(0, 0, 0, 44)
tabScroll.ScrollBarThickness = 3
tabScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85)
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.Parent = sidebar

local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 8)
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Parent = tabScroll

tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 10)
end)

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 200, 0, 0)
content.Size = UDim2.new(1, -200, 1, 0)
content.Parent = main

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 16)
contentPad.PaddingLeft = UDim.new(0, 14)
contentPad.PaddingRight = UDim.new(0, 14)
contentPad.PaddingBottom = UDim.new(0, 14)
contentPad.Parent = content

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0, 24)
header.Font = Enum.Font.GothamBold
header.TextSize = 18
header.TextColor3 = TEXT
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = ""
header.Parent = content

local pages = Instance.new("Frame")
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, 0, 0, 34)
pages.Size = UDim2.new(1, 0, 1, -34)
pages.Parent = content

local function NewPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Visible = false
	page.Parent = pages
	return page
end

local function NewColumns(page)
	local left = Instance.new("Frame")
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.5, -8, 1, 0)
	left.Parent = page

	local right = Instance.new("Frame")
	right.BackgroundTransparency = 1
	right.Position = UDim2.new(0.5, 8, 0, 0)
	right.Size = UDim2.new(0.5, -8, 1, 0)
	right.Parent = page

	local ll = Instance.new("UIListLayout")
	ll.Padding = UDim.new(0, 12)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Parent = left

	local rl = Instance.new("UIListLayout")
	rl.Padding = UDim.new(0, 12)
	rl.SortOrder = Enum.SortOrder.LayoutOrder
	rl.Parent = right

	return left, right
end

local function NewSection(parent, secTitle, height)
	local sec = Instance.new("Frame")
	sec.Size = UDim2.new(1, 0, 0, height or 260)
	sec.BackgroundColor3 = PANEL2
	sec.Parent = parent

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 12)
	sc.Parent = sec

	local ss = Instance.new("UIStroke")
	ss.Color = BORDER
	ss.Thickness = 1
	ss.Parent = sec

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = sec

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 18)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextColor3 = TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = secTitle
	t.Parent = sec

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.new(0, 0, 0, 24)
	holder.Size = UDim2.new(1, 0, 1, -24)
	holder.Parent = sec

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder

	return sec, holder
end

local moduleCache = {}

local function GetModule(path)
	if moduleCache[path] ~= nil then
		return moduleCache[path]
	end
	local ok, res = tryImport(path)
	if ok then
		moduleCache[path] = res
		return res
	end
	moduleCache[path] = false
	return nil
end

local function NewToggle(parent, text, scriptPath)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -54, 1, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextColor3 = TEXT
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = text
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(44, 18)
	btn.Position = UDim2.new(1, -44, 0.5, 0)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	btn.Parent = row

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 999)
	bc.Parent = btn

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	knob.Parent = btn

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 999)
	kc.Parent = knob

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, ACCENT1),
		ColorSequenceKeypoint.new(1, ACCENT2)
	})
	grad.Enabled = false
	grad.Parent = btn

	local state = false
	local module = nil

	local function apply(v)
		state = v
		btn.BackgroundColor3 = state and ACCENT2 or Color3.fromRGB(55, 55, 65)
		knob.Position = state and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		knob.AnchorPoint = state and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
		grad.Enabled = state

		if scriptPath and scriptPath ~= "" then
			module = module or GetModule(scriptPath)
			if type(module) == "table" then
				if state then
					if type(module.enable) == "function" then module.enable() end
				else
					if type(module.disable) == "function" then module.disable() end
				end
			end
		end
	end

	btn.MouseButton1Click:Connect(function()
		apply(not state)
	end)

	return row
end

local function BuildTab(tabName, page)
	local left, right = NewColumns(page)
	local _, holder = NewSection(left, tabName, 300)

	local ok, listOrErr = tryImport("Gui/buttons/" .. tabName .. "/buttons.lua")
	if not ok then
		return
	end

	if type(listOrErr) ~= "table" then
		return
	end

	for _, b in ipairs(listOrErr) do
		if type(b) == "table" and b.type == "toggle" then
			NewToggle(holder, b.name or "Button", b.scriptModule or "")
		end
	end
end

local tabs = {}
local pagesMap = {}

local function NewTab(name)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	b.Size = UDim2.new(1, 0, 0, 28)
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextColor3 = TEXT
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Text = "  " .. name
	b.Parent = tabScroll

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = b

	local st = Instance.new("UIStroke")
	st.Color = BORDER
	st.Thickness = 1
	st.Transparency = 0.7
	st.Parent = b

	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 3, 1, -10)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Visible = false
	line.Parent = b

	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, 6)
	lc.Parent = line

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, ACCENT1),
		ColorSequenceKeypoint.new(1, ACCENT2)
	})
	g.Parent = line

	tabs[name] = { Button = b, Line = line }
	return b
end

local function SwitchTab(name)
	for pn, pgFrame in pairs(pagesMap) do
		pgFrame.Visible = (pn == name)
	end
	for tn, t in pairs(tabs) do
		local active = (tn == name)
		t.Line.Visible = active
		t.Button.BackgroundColor3 = active and Color3.fromRGB(30, 30, 38) or Color3.fromRGB(24, 24, 30)
	end
	header.Text = ""
end

local tabNames = { "Rage", "Anti-aim", "Players", "Visual", "World", "Main" }

for _, tn in ipairs(tabNames) do
	local btn = NewTab(tn)
	local page = NewPage(tn)
	pagesMap[tn] = page

	btn.MouseButton1Click:Connect(function()
		SwitchTab(tn)
	end)

	BuildTab(tn, page)
end

pagesMap["Main"].Visible = true
SwitchTab("Main")

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Insert then
		if isOpen then
			CloseMenu()
		else
			OpenMenu()
		end
	end
end)

CloseMenu()
