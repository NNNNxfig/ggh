local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local M = {}

local lp = Players.LocalPlayer
local enabled = false
local conn = nil

local tracers = {}

local function isEnemy(p)
	if p == lp then return false end
	if lp.Team and p.Team then
		return p.Team ~= lp.Team
	end
	return true
end

local function getRoot(p)
	local ch = p.Character
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")
end

local function removeTracer(p)
	local t = tracers[p]
	if t then
		if t.Line then t.Line:Remove() end
		tracers[p] = nil
	end
end

local function clearAll()
	for p in pairs(tracers) do
		removeTracer(p)
	end
end

local function createLine()
	local line = Drawing.new("Line")
	line.Visible = false
	line.Thickness = 1.7
	line.Transparency = 1
	line.Color = Color3.fromRGB(255, 0, 0)
	return line
end

function M.enable()
	if enabled then return end
	enabled = true

	conn = RunService.RenderStepped:Connect(function()
		if not enabled then return end

		local cam = workspace.CurrentCamera
		if not cam then return end

		for _, p in ipairs(Players:GetPlayers()) do
			if isEnemy(p) and not tracers[p] then
				tracers[p] = { Line = createLine() }
			end
		end

		for p, obj in pairs(tracers) do
			if not enabled then break end

			if not p or not p.Parent or not isEnemy(p) then
				removeTracer(p)
			else
				local root = getRoot(p)
				if not root then
					obj.Line.Visible = false
				else
					local pos, onScreen = cam:WorldToViewportPoint(root.Position)
					if not onScreen or pos.Z < 0 then
						obj.Line.Visible = false
					else
						obj.Line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
						obj.Line.To = Vector2.new(pos.X, pos.Y)
						obj.Line.Visible = true
					end
				end
			end
		end
	end)
end

function M.disable()
	if not enabled then return end
	enabled = false

	if conn then
		conn:Disconnect()
		conn = nil
	end

	clearAll()
end

return M
