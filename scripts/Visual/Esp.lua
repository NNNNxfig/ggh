local Players = game:GetService("Players")

local M = {}

local lp = Players.LocalPlayer
local running = false
local loopTask = nil

local function getColor(p)
	local color = Color3.fromRGB(255, 255, 0)
	if lp.Team and p.Team then
		if p.Team == lp.Team then
			color = Color3.fromRGB(0, 255, 0)
		else
			color = Color3.fromRGB(255, 0, 0)
		end
	end
	return color
end

local function applyESP(p)
	if not running then return end
	if p == lp then return end
	local ch = p.Character
	if not ch then return end

	local old = ch:FindFirstChild("SimpleESP")
	if old then old:Destroy() end

	local c = getColor(p)

	local h = Instance.new("Highlight")
	h.Name = "SimpleESP"
	h.FillColor = c
	h.FillTransparency = 0.8
	h.OutlineColor = c
	h.OutlineTransparency = 0.3
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = ch
	h.Parent = ch

	for _, part in ipairs(ch:GetChildren()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0.5
		end
	end
end

local function clearESPForChar(ch)
	if not ch then return end
	local old = ch:FindFirstChild("SimpleESP")
	if old then old:Destroy() end

	for _, part in ipairs(ch:GetChildren()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		end
	end
end

local function clearAll()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Character then
			clearESPForChar(p.Character)
		end
	end
end

function M.enable()
	if running then return end
	running = true

	loopTask = task.spawn(function()
		while running do
			for _, p in ipairs(Players:GetPlayers()) do
				applyESP(p)
			end
			task.wait(2)
		end
	end)
end

function M.disable()
	if not running then return end
	running = false
	loopTask = nil
	clearAll()
end

return M
