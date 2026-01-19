--// eNigma UI (Roblox) - Clean Tabs + Slide From Bottom Animation
--// Insert = show/hide with tween

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

--// THEME (acid green)
local ACCENT1 = Color3.fromRGB(210, 255, 40)
local ACCENT2 = Color3.fromRGB(0, 255, 130)

local BG      = Color3.fromRGB(10, 10, 12)
local PANEL   = Color3.fromRGB(16, 16, 20)

local BORDER  = Color3.fromRGB(45, 45, 55)
local TEXT    = Color3.fromRGB(235, 235, 235)

--// ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "eNigmaUI"
gui.ResetOnSpawn = false
gui.Parent = pg

--// Main Window
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

--// Positions for animation
local centerPos = UDim2.fromScale(0.5, 0.5)
local hiddenPos = UDim2.new(0.5, 0, 1.25, 0) -- ниже экрана

main.Position = hiddenPos
main.Visible = true

local isOpen = false
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function OpenMenu()
	isOpen = true
	main.Visible = true
	local t = TweenService:Create(main, tweenInfo, {Position = centerPos})
	t:Play()
end

local function CloseMenu()
	isOpen = false
	local t = TweenService:Create(main, tweenInfo, {Position = hiddenPos})
	t:Play()
	t.Completed:Connect(function()
		if not isOpen then
			main.Visible = true -- можно оставить true, чтобы не ломать UI
		end
	end)
end

--// Dragging window
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

--// Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 200, 1, 0)
sidebar.BackgroundColor3 = PANEL
sidebar.Parent = main

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 12)
sideCorner.Parent = sidebar

-- fix rounded overlap
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

-- ✅ BRAND INSIDE SIDEBAR (TOP LEFT FIXED)
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

-- Tabs ScrollFrame
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

--// Content
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
header.Text = "Main"
header.Parent = content

local pages = Instance.new("Frame")
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, 0, 0, 34)
pages.Size = UDim2.new(1, 0, 1, -34)
pages.Parent = content

-- Page
local function NewPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Visible = false
	page.Parent = pages
	return page
end

-- Tabs
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

	tabs[name] = {Button = b, Line = line}
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
	header.Text = name
end

-- ✅ Tabs list
local tabNames = {"Ragebot","Anti-Aim","Players","Visual","World","Main"}

for _, tn in ipairs(tabNames) do
	local btn = NewTab(tn)
	local page = NewPage(tn)
	pagesMap[tn] = page

	btn.MouseButton1Click:Connect(function()
		SwitchTab(tn)
	end)
end

-- default open
pagesMap["Main"].Visible = true
SwitchTab("Main")

-- ✅ Insert show/hide with animation
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

-- start closed
CloseMenu()
