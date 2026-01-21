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
local teleportConn = nil

local illusionFolder
local uiGui, flash

local fxBlur, fxCC, fxBloom, fxDOF, fxSun, fxInvert

local cam = nil
local baseFOV = 70
local baseCamType = nil

local rollCurrent = 0
local rollTarget = 0
local frozenUntil = 0

local function getChar()
	return lp.Character
end

local function getHRP()
	local ch = getChar()
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function ensureCamera()
	cam = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Name = "Camera"
		cam.Parent = Workspace
		Workspace.CurrentCamera = cam
	end
	return cam
end

local function makeFolder()
	if illusionFolder and illusionFolder.Parent then return end
	illusionFolder = Instance.new("Folder")
	illusionFolder.Name = "eNigma_TripWorld"
	illusionFolder.Parent = Workspace
end

local function clearFolder()
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
	fxDOF.FarIntensity = 0.75
	fxDOF.InFocusRadius = 10
	fxDOF.NearIntensity = 1
	fxDOF.FocusDistance = 10
	fxDOF.Parent = Lighting

	fxSun = Instance.new("SunRaysEffect")
	fxSun.Name = "eNigmaTrip_Sun"
	fxSun.Enabled = true
	fxSun.Intensity = 0.08
	fxSun.Spread = 1
	fxSun.Parent = Lighting

	fxInvert = Instance.new("ColorCorrectionEffect")
	fxInvert.Name = "eNigmaTrip_Invert"
	fxInvert.Enabled = false
	fxInvert.Contrast = 1
	fxInvert.Saturation = -1
	fxInvert.Brightness = 0
	fxInvert.TintColor = Color3.fromRGB(255, 255, 255)
	fxInvert.Parent = Lighting
end

local function clearFX()
	if fxBlur then fxBlur:Destroy() fxBlur = nil end
	if fxCC then fxCC:Destroy() fxCC = nil end
	if fxBloom then fxBloom:Destroy() fxBloom = nil end
	if fxDOF then fxDOF:Destroy() fxDOF = nil end
	if fxSun then fxSun:Destroy() fxSun = nil end
	if fxInvert then fxInvert:Destroy() fxInvert = nil end
end

local function flashOnce(strength, isWhite)
	if not flash then return end
	flash.BackgroundColor3 = isWhite and Color3.new(1,1,1) or Color3.fromHSV(math.random(), 1, 1)
	flash.BackgroundTransparency = 1

	local t1 = TweenService:Create(flash, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
		BackgroundTransparency = math.clamp(1 - strength, 0, 1)
	})
	local t2 = TweenService:Create(flash, TweenInfo.new(0.12, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1
	})

	t1:Play()
	t1.Completed:Connect(function()
		if enabled then t2:Play() end
	end)
end

local function safeCloneCharacter(char)
	if not char or not char.Parent then return nil end

	local ok, clone = pcall(function()
		return char:Clone()
	end)
	if not ok or not clone then return nil end

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

	return clone
end

local function spawnFakeTeleport()
	if not enabled then return end

	local hrp = getHRP()
	if not hrp then return end

	local list = Players:GetPlayers()
	if #list <= 1 then return end

	local pick = nil
	for _ = 1, 10 do
		local p = list[math.random(1, #list)]
		if p ~= lp and p.Character and p.Character.Parent then
			if p.Character:FindFirstChild("HumanoidRootPart") then
				pick = p
				break
			end
		end
	end
	if not pick then return end

	local srcChar = pick.Character
	if not srcChar then return end

	local clone = safeCloneCharacter(srcChar)
	if not clone then return end

	makeFolder()
	clone.Parent = illusionFolder

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

	local fadeIn = TweenInfo.new(0.06, Enum.EasingStyle.Linear)
	for _, bp in ipairs(clone:GetDescendants()) do
		if bp:IsA("BasePart") then
			TweenService:Create(bp, fadeIn, { Transparency = 0 }):Play()
		end
	end

	local tpCount = math.random(2, 7)
	task.spawn(function()
		for _ = 1, tpCount do
			if not enabled or not clone.Parent then break end
			local a2 = math.random() * math.pi * 2
			local d2 = math.random(2, 10)
			local h2 = math.random(-2, 7)
			local newPos = hrp.Position + Vector3.new(math.cos(a2) * d2, h2, math.sin(a2) * d2)
			local tt = math.random(3, 14) / 100
			local tw = TweenService:Create(cHRP, TweenInfo.new(tt, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(newPos, hrp.Position)
			})
			tw:Play()
			task.wait(tt + math.random(2, 9) / 100)

			if math.random(1, 2) == 1 then
				flashOnce(0.45, false)
			end
		end

		if clone and clone.Parent then
			local fadeOut = TweenInfo.new(0.10, Enum.EasingStyle.Linear)
			for _, bp in ipairs(clone:GetDescendants()) do
				if bp:IsA("BasePart") then
					TweenService:Create(bp, fadeOut, { Transparency = 1 }):Play()
				end
			end
			Debris:AddItem(clone, 0.2)
		end
	end)

	Debris:AddItem(clone, 2.0)
end

local function startFakeTeleports()
	if teleportConn then return end
	teleportConn = RunService.Heartbeat:Connect(function()
		if not enabled then return end
		if math.random(1, 3) == 1 then
			spawnFakeTeleport()
		end
	end)
end

local function stopFakeTeleports()
	if teleportConn then
		teleportConn:Disconnect()
		teleportConn = nil
	end
end

local function startTrip()
	applyFX()
	makeUI()
	ensureCamera()

	baseFOV = cam.FieldOfView
	baseCamType = cam.CameraType
	cam.CameraType = Enum.CameraType.Custom

	local t = 0
	tripConn = RunService.RenderStepped:Connect(function(dt)
		if not enabled then return end

		ensureCamera()
		t += dt

		local s1 = (math.sin(t * 17) + 1) * 0.5
		local s2 = (math.sin(t * 7.3 + 2) + 1) * 0.5
		local s3 = (math.sin(t * 31 + 1) + 1) * 0.5

		if math.random(1, 220) == 1 then
			frozenUntil = tick() + 0.05
		end

		if tick() < frozenUntil then
			dt = 0
		end

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

		if fxInvert then
			if math.random(1, 160) == 1 then
				fxInvert.Enabled = true
				task.delay(math.random(8, 18) / 100, function()
					if fxInvert then fxInvert.Enabled = false end
				end)
			end
		end

		if math.random(1, 22) == 1 then
			flashOnce(0.55 + math.random() * 0.4, math.random(1, 4) == 1)
		end

		local breathe = baseFOV + math.sin(t * 2.2) * (8 + s2 * 14)
		cam.FieldOfView = breathe

		if math.random(1, 120) == 1 then
			rollTarget = (math.random(-25, 25) / 10)
		end
		rollCurrent = rollCurrent + (rollTarget - rollCurrent) * math.clamp(dt * 6, 0, 1)

		local cf = cam.CFrame

		local shake = Vector3.new(
			(math.random() - 0.5) * (0.25 + s1 * 0.6),
			(math.random() - 0.5) * (0.25 + s2 * 0.6),
			(math.random() - 0.5) * (0.25 + s3 * 0.6)
		)

		local rot = CFrame.Angles(
			(math.random() - 0.5) * 0.01 * (2 + s1 * 4),
			(math.random() - 0.5) * 0.01 * (2 + s2 * 4),
			rollCurrent
		)

		cam.CFrame = cf * CFrame.new(shake) * rot
	end)
end

local function stopTrip()
	if tripConn then
		tripConn:Disconnect()
		tripConn = nil
	end

	if cam then
		cam.FieldOfView = baseFOV
		if baseCamType then cam.CameraType = baseCamType end
	end

	rollCurrent = 0
	rollTarget = 0
	frozenUntil = 0

	clearFX()
	killUI()
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
	clearFolder()
end

return M
