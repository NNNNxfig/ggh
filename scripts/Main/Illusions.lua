local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local M = {}

local lp = Players.LocalPlayer

local enabled = false
local conns = {}
local tripConn = nil
local spawnConn = nil

local uiGui, uiLabel
local soundsFolder
local illusionFolder
local pushkinModel

local fxBlur, fxCC, fxBloom

local function addConn(c)
	table.insert(conns, c)
	return c
end

local function clearConns()
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
end

local function getChar()
	return lp.Character
end

local function getHRP()
	local ch = getChar()
	if not ch then return nil end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function getPlayerGui()
	return lp:WaitForChild("PlayerGui")
end

local function makeUI()
	if uiGui and uiGui.Parent then return end

	uiGui = Instance.new("ScreenGui")
	uiGui.Name = "eNigma_IllusionsUI"
	uiGui.ResetOnSpawn = false
	uiGui.IgnoreGuiInset = true
	uiGui.Parent = getPlayerGui()

	uiLabel = Instance.new("TextLabel")
	uiLabel.Name = "Countdown"
	uiLabel.BackgroundTransparency = 1
	uiLabel.Size = UDim2.new(1, 0, 1, 0)
	uiLabel.Position = UDim2.new(0, 0, 0, 0)
	uiLabel.Font = Enum.Font.GothamBlack
	uiLabel.TextSize = 96
	uiLabel.TextColor3 = Color3.fromRGB(255, 40, 40)
	uiLabel.TextStrokeTransparency = 0
	uiLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	uiLabel.Text = ""
	uiLabel.Visible = true
	uiLabel.Parent = uiGui
end

local function destroyUI()
	if uiGui then
		uiGui:Destroy()
		uiGui = nil
		uiLabel = nil
	end
end

local function makeFolders()
	if not soundsFolder then
		soundsFolder = Instance.new("Folder")
		soundsFolder.Name = "eNigma_IllusionsSounds"
		soundsFolder.Parent = Workspace
	end
	if not illusionFolder then
		illusionFolder = Instance.new("Folder")
		illusionFolder.Name = "eNigma_IllusionsWorld"
		illusionFolder.Parent = Workspace
	end
end

local function destroyFolders()
	if soundsFolder then
		soundsFolder:Destroy()
		soundsFolder = nil
	end
	if illusionFolder then
		illusionFolder:Destroy()
		illusionFolder = nil
	end
end

local function makeSound(id, volume, looped)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = volume or 1
	s.Looped = looped or false
	s.Parent = soundsFolder
	return s
end

local function stopAllSounds()
	if soundsFolder then
		for _, s in ipairs(soundsFolder:GetChildren()) do
			if s:IsA("Sound") then
				pcall(function()
					s:Stop()
				end)
			end
		end
	end
end

local function clearIllusions()
	if illusionFolder then
		for _, v in ipairs(illusionFolder:GetChildren()) do
			v:Destroy()
		end
	end
end

local function clearFX()
	if fxBlur then fxBlur:Destroy() fxBlur = nil end
	if fxCC then fxCC:Destroy() fxCC = nil end
	if fxBloom then fxBloom:Destroy() fxBloom = nil end
end

local function applyTripFX()
	if fxBlur or fxCC or fxBloom then return end

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
end

local function startTripMode()
	applyTripFX()

	local t = 0
	tripConn = RunService.RenderStepped:Connect(function(dt)
		if not enabled then return end
		t += dt

		local flick = (math.sin(t * 16) + 1) * 0.5
		local flick2 = (math.sin(t * 9.5 + 2) + 1) * 0.5

		if fxBlur then
			fxBlur.Size = 6 + flick * 20
		end

		if fxCC then
			fxCC.Brightness = -0.15 + flick * 0.35
			fxCC.Contrast = -0.2 + flick2 * 1.25
			fxCC.Saturation = -0.1 + flick * 1.4
			fxCC.TintColor = Color3.fromHSV((t * 0.25) % 1, 1, 1)
		end

		if fxBloom then
			fxBloom.Intensity = 0.3 + flick2 * 1.6
			fxBloom.Size = 24 + flick * 40
		end
	end)
end

local function stopTripMode()
	if tripConn then
		tripConn:Disconnect()
		tripConn = nil
	end
	clearFX()
end

local function spawnImageTowardsPlayer()
	if not enabled then return end
	local hrp = getHRP()
	if not hrp then return end
	if not illusionFolder then return end

	local dist = math.random(60, 220)
	local angle = math.random() * math.pi * 2
	local height = math.random(-10, 30)

	local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local startPos = hrp.Position + dir * dist + Vector3.new(0, height, 0)
	local endPos = hrp.Position + Vector3.new(math.random(-5, 5), math.random(-3, 6), math.random(-5, 5))

	local part = Instance.new("Part")
	part.Name = "IllusionImage"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(math.random(14, 24), math.random(18, 30), 0.2)
	part.Transparency = 1
	part.Parent = illusionFolder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = "rbxassetid://70841078990321"
	img.Parent = gui

	part.CFrame = CFrame.new(startPos, hrp.Position)

	local time = math.random(20, 55) / 10
	local tween = TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		CFrame = CFrame.new(endPos, hrp.Position)
	})
	tween:Play()

	Debris:AddItem(part, time + 0.25)
end

local function startSpawning()
	if spawnConn then return end
	spawnConn = RunService.Heartbeat:Connect(function()
		if not enabled then return end
		if math.random(1, 2) == 1 then
			spawnImageTowardsPlayer()
		end
	end)
end

local function stopSpawning()
	if spawnConn then
		spawnConn:Disconnect()
		spawnConn = nil
	end
end

local function spawnPushkin()
	if not enabled then return end
	if not illusionFolder then return end
	if pushkinModel and pushkinModel.Parent then return end

	local hrp = getHRP()
	if not hrp then return end

	pushkinModel = Instance.new("Model")
	pushkinModel.Name = "Pushkin"
	pushkinModel.Parent = illusionFolder

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Size = Vector3.new(6, 6, 6)
	head.Transparency = 1
	head.Parent = pushkinModel

	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://104805545286888"
	decal.Face = Enum.NormalId.Front
	decal.Parent = head

	local angle = math.random() * math.pi * 2
	local dist = math.random(14, 30)
	local pos = hrp.Position + Vector3.new(math.cos(angle) * dist, math.random(4, 10), math.sin(angle) * dist)
	head.CFrame = CFrame.new(pos, hrp.Position)

	local s = makeSound(127849538220992, 1, false)
	s:Play()

	s.Ended:Connect(function()
		if pushkinModel then
			pushkinModel:Destroy()
			pushkinModel = nil
		end
		if enabled then
			startTripMode()
		end
	end)
end

local function countdown10()
	makeUI()

	local startSnd = makeSound(89421922567748, 1, false)
	startSnd:Play()

	for i = 10, 1, -1 do
		if not enabled then return false end
		uiLabel.Text = tostring(i)
		task.wait(1)
	end

	if not enabled then return false end
	uiLabel.Text = "0"
	task.wait(0.15)

	uiLabel.Text = ""
	return true
end

function M.enable()
	if enabled then return end
	enabled = true

	makeFolders()
	clearIllusions()
	stopTripMode()
	stopAllSounds()

	local ok = countdown10()
	if not ok or not enabled then return end

	local mid = makeSound(109225597938785, 1, false)
	mid:Play()

	startSpawning()

	task.spawn(function()
		local delayTime = math.random(4, 13) + math.random()
		local t0 = tick()
		while enabled and (tick() - t0) < delayTime do
			task.wait(0.1)
		end
		if enabled then
			spawnPushkin()
		end
	end)
end

function M.disable()
	if not enabled then return end
	enabled = false

	stopSpawning()
	stopTripMode()
	clearConns()
	stopAllSounds()

	if pushkinModel then
		pushkinModel:Destroy()
		pushkinModel = nil
	end

	clearIllusions()
	destroyUI()
	destroyFolders()
end

return M
