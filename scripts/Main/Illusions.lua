local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local M = {}

local lp = Players.LocalPlayer

local enabled = false
local tripConn = nil
local glitchConn = nil
local cloneConn = nil

local fxBlur, fxCC, fxBloom, fxDOF, fxSun

local illusionFolder
local uiGui, flash

local function getChar()
	return lp.Character
end

local function getHRP()
	local ch = getChar()
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function makeFolder()
	if illusionFolder and illusionFolder.Parent then return end
	illusionFolder = Instance.new("Folder")
	illusionFolder.Name = "eNigma_TripWorld"
	illusionFolder.Parent = Workspace
end

local function killFolder()
	if illusionFolder then
		illusionFolder:Destroy()
		illusionFolder = nil
	end
end

local function makeUI()
	if uiGui and uiGui.Parent then return end
	uiGui = Instance.new("ScreenGui")
	uiGui.Name = "eNigma_TripUI"
	uiGui.ResetOnSpawn = false
	uiGui.IgnoreGuiInset = true
	uiGui.Parent = lp:WaitForChild("PlayerGui")

	flash = Instance.new("Frame")
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.Parent = uiGui
end

local function killUI()
	if uiGui then
		uiGui:Destroy()
		uiGui = nil
		flash = nil
	end
end

local function applyFX()
	if fxBlur then return end

	fxBlur = Instance.new("BlurEffect")
	fxBlur.Name = "eNigmaTrip_Blur"
	fxBlur.Size = 0
	fxBlur.Parent = Lighting

	fxCC = Instance.new("ColorCorrectionEffect")
	fxCC.Name = "eNigmaTrip_CC"
	fxCC.Brightness = 0
	fxCC.Contrast = 0
	fxCC.Saturation = 0
	fxCC.TintColor = Color3.fromRGB(255, 255, 255)
	fxCC.Parent = Lighting

	fxBloom = Instance.new("BloomEffect")
	fxBloom.Name = "eNigmaTrip_Bloom"
	fxBloom.Intensity = 0.2
	fxBloom.Size = 24
	fxBloom.Threshold = 1
	fxBloom.Parent = Lighting

	fxDOF = Instance.new("DepthOfFieldEffect")
	fxDOF.Name = "eNigmaTrip_DOF"
	fxDOF.Enabled = true
	fxDOF.FarIntensity = 0.7
	fxDOF.InFocusRadius = 12
	fxDOF.NearIntensity = 1
	fxDOF.FocusDistance = 10
	fxDOF.Parent = Lighting

	fxSun = Instance.new("SunRaysEffect")
	fxSun.Name = "eNigmaTrip_Sun"
	fxSun.Enabled = true
	fxSun.Intensity = 0.08
	fxSun.Spread = 1
	fxSun.Parent = Lighting
end

local function clearFX()
	if fxBlur then fxBlur:Destroy() fxBlur = nil end
	if fxCC then fxCC:Destroy() fxCC = nil end
	if fxBloom then fxBloom:Destroy() fxBloom = nil end
	if fxDOF then fxDOF:Destroy() fxDOF = nil end
	if fxSun then fxSun:Destroy() fxSun = nil end
end

local function flashOnce(alpha)
	if not flash then return end
	flash.BackgroundTransparency = 1
	flash.BackgroundColor3 = Color3.fromHSV(math.random(), 1, 1)

	local t1 = TweenService:Create(flash, TweenInfo.new(0.06, Enum.EasingStyle.Linear), {
		BackgroundTransparency = math.clamp(alpha, 0, 0.9)
	})
	local t2 = TweenService:Create(flash, TweenInfo.new(0.12, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1
	})
	t1:Play()
	t1.Completed:Connect(function()
		if enabled then
			t2:Play()
		end
	end)
end

local function startTrip()
	applyFX()
	makeUI()

	local t = 0
	tripConn = RunService.RenderStepped:Connect(function(dt)
		if not enabled then return end
		t += dt

		local s1 = (math.sin(t * 17) + 1) * 0.5
		local s2 = (math.sin(t * 7.3 + 2) + 1) * 0.5
		local s3 = (math.sin(t * 31 + 1) + 1) * 0.5

		if fxBlur then
			fxBlur.Size = 10 + s1 * 30
		end

		if fxCC then
			fxCC.Brightness = -0.25 + s2 * 0.6
			fxCC.Contrast = -0.4 + s3 * 2
			fxCC.Saturation = 0.2 + s1 * 2.2
			fxCC.TintColor = Color3.fromHSV((t * 0.35) % 1, 1, 1)
		end

		if fxBloom then
			fxBloom.Intensity = 0.5 + s2 * 3
			fxBloom.Size = 24 + s3 * 64
		end

		if fxDOF then
			fxDOF.FocusDistance = 2 + s1 * 60
			fxDOF.InFocusRadius = 4 + s2 * 40
		end

		if math.random(1, 18) == 1 then
			flashOnce(0.35 + math.random() * 0.45)
		end
	end)
end

local function stopTrip()
	if tripConn then
		tripConn:Disconnect()
		tripConn = nil
	end
	clearFX()
	killUI()
end

local function safeCloneCharacter(char)
	local clone = char:Clone()

	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			d.NameDisplayDistance = 0
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.Massless = true
			d.AssemblyLinearVelocity = Vector3.zero
			d.AssemblyAngularVelocity = Vector3.zero
		end
	end

	clone.Parent = illusionFolder
	return clone
end

local function spawnFakeTeleport()
	if not enabled then return end
	local hrp = getHRP()
	if not hrp then return end

	local all = Players:GetPlayers()
	if #all <= 1 then return end

	local pick = nil
	for _ = 1, 8 do
		local p = all[math.random(1, #all)]
		if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			pick = p
			break
		end
	end
	if not pick then return end

	local srcChar = pick.Character
	local srcHRP = srcChar:FindFirstChild("HumanoidRootPart")
	if not srcHRP then return end

	makeFolder()

	local clone = safeCloneCharacter(srcChar)
	local cHRP = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChildWhichIsA("BasePart")
	if not cHRP then
		clone:Destroy()
		return
	end

	local ang = math.random() * math.pi * 2
	local dist = math.random(4, 14)
	local height = math.random(-1, 6)

	local appearPos = hrp.Position + Vector3.new(math.cos(ang) * dist, height, math.sin(ang) * dist)
	cHRP.CFrame = CFrame.new(appearPos, hrp.Position)

	for _, bp in ipairs(clone:GetDescendants()) do
		if bp:IsA("BasePart") then
			bp.Transparency = 1
		end
	end

	local fadeIn = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
	for _, bp in ipairs(clone:GetDescendants()) do
		if bp:IsA("BasePart") then
			TweenService:Create(bp, fadeIn, { Transparency = 0 }):Play()
		end
	end

	local life = math.random(40, 120) / 100
	local tpCount = math.random(2, 6)

	task.spawn(function()
		local lastPos = appearPos
		for i = 1, tpCount do
			if not enabled or not clone.Parent then break end

			local a2 = math.random() * math.pi * 2
			local d2 = math.random(2, 10)
			local h2 = math.random(-2, 7)
			local newPos = hrp.Position + Vector3.new(math.cos(a2) * d2, h2, math.sin(a2) * d2)

			local tt = math.random(3, 12) / 100
			local tw = TweenService:Create(cHRP, TweenInfo.new(tt, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(newPos, hrp.Position)
			})
			tw:Play()
			task.wait(tt + math.random(2, 8) / 100)

			lastPos = newPos

			if math.random(1, 2) == 1 then
				flashOnce(0.2 + math.random() * 0.4)
			end
		end

		if clone and clone.Parent then
			local fadeOut = TweenInfo.new(0.12, Enum.EasingStyle.Linear)
			for _, bp in ipairs(clone:GetDescendants()) do
				if bp:IsA("BasePart") then
					TweenService:Create(bp, fadeOut, { Transparency = 1 }):Play()
				end
			end
			Debris:AddItem(clone, 0.2)
		end
	end)

	Debris:AddItem(clone, life + 1.5)
end

local function startFakeTeleports()
	if glitchConn then return end
	glitchConn = RunService.Heartbeat:Connect(function()
		if not enabled then return end
		if math.random(1, 3) ~= 1 then return end
		spawnFakeTeleport()
	end)
end

local function stopFakeTeleports()
	if glitchConn then
		glitchConn:Disconnect()
		glitchConn = nil
	end
end

function M.enable()
	if enabled then return end
	enabled = true

	makeFolder()
	startTrip()
	startFakeTeleports()
end

function M.disable()
	if not enabled then return end
	enabled = false

	stopFakeTeleports()
	stopTrip()

	if illusionFolder then
		illusionFolder:Destroy()
		illusionFolder = nil
	end
end

return M
