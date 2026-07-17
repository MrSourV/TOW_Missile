local rs    = game:GetService("RunService")
local tween = game:GetService("TweenService")
wait(2)

local stats = {
	boostThrust   = 1800,
	sustainThrust = 700,
	ejectTime     = 0.55,
	boostTime     = 0.4,
	sustainTime   = 4.0,
	mass          = 18.9,
	launchSpeed   = 18,
	airDensity    = 1.225,
	dragCoeff     = 0.38,
	crossSection  = 0.0095,
	wobbleAmp     = 5,
	wobbleDamp    = 2.8,
	wobbleFreq    = 7,
	guidanceDelay = 1.2,
	turnRate      = math.rad(18),
	guidanceGain  = 5.5,
	targetName    = "Target",
	gravity       = Vector3.new(0, -9.81, 0),
	blowRadius    = 3,
	maxRange      = 800,
	spiralRadius  = 0.6,
	spiralSpeed   = 10,
	spiralSettle  = 3.5,
	spiralDelay   = 0.4,
}

local m       = script.Parent
local basePrt = workspace:FindFirstChild("base")
local target  = workspace:FindFirstChild(stats.targetName)

for i, v in pairs(script.Parent:GetDescendants()) do
	if v:IsA("ParticleEmitter") and v.Parent ~= script.Parent.Folder then
		v.Enabled = true
	end
end

local startPos = m.Position
local vel      = m.CFrame.LookVector * stats.launchSpeed
local t        = 0
local dead     = false

m.Anchored   = true
m.CanCollide = false

local pAtt   = m:FindFirstChild("particleattachment")
local smoke  = pAtt and pAtt:FindFirstChild("Smoke")
local flame  = pAtt and pAtt:FindFirstChild("Flame")

local sound1 = m:FindFirstChild("p1")
local sound2 = m:FindFirstChild("p2")

local function setFx(smokeRate, flameRate, smokeSpd, flameSpd, flameSize)
	if smoke then
		smoke.Rate  = smokeRate
		smoke.Speed = NumberRange.new(smokeSpd * 0.8, smokeSpd * 1.2)
	end
	if flame then
		flame.Rate  = flameRate
		flame.Speed = NumberRange.new(flameSpd * 0.8, flameSpd * 1.2)
		if flameSize then
			flame.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0,   flameSize),
				NumberSequenceKeypoint.new(0.5, flameSize * 0.6),
				NumberSequenceKeypoint.new(1,   0),
			})
		end
	end
end

local function killFx()
	if smoke then smoke.Rate = 0 end
	if flame then flame.Rate = 0 end
end

if sound1 then
	sound1.RollOffMaxDistance = 500
	sound1.Volume = 2.5
	sound1:Play()
end

if sound2 then
	sound2.RollOffMaxDistance = 600
	sound2.Volume        = 0
	sound2.Looped        = true
	sound2.PlaybackSpeed = 1.1
	sound2:Play()
end

setFx(0, 0, 0, 0, 0)

local phase = "eject"

local tailGlow = Instance.new("Part")
tailGlow.Size         = Vector3.new(0.1, 0.1, 0.1)
tailGlow.Anchored     = true
tailGlow.CanCollide   = false
tailGlow.Transparency = 1
tailGlow.CastShadow   = false
tailGlow.Parent       = workspace

local tailLight = Instance.new("PointLight", tailGlow)
tailLight.Color      = Color3.fromRGB(255, 140, 40)
tailLight.Brightness = 0
tailLight.Range      = 0
tailLight.Shadows    = true

local noseGlow = Instance.new("Part")
noseGlow.Size         = Vector3.new(0.1, 0.1, 0.1)
noseGlow.Anchored     = true
noseGlow.CanCollide   = false
noseGlow.Transparency = 1
noseGlow.CastShadow   = false
noseGlow.Parent       = workspace

local frontLight = Instance.new("PointLight", noseGlow)
frontLight.Color      = Color3.fromRGB(180, 210, 255)
frontLight.Brightness = 0
frontLight.Range      = 0

local streakGap  = 0.018
local lastStreak = 0

local function makeStreak(pos)
	local s = Instance.new("Part")
	s.Shape        = Enum.PartType.Ball
	s.Size         = Vector3.new(0.22, 0.22, 0.22)
	s.Position     = pos
	s.Anchored     = true
	s.CanCollide   = false
	s.CastShadow   = false
	s.Material     = Enum.Material.Neon
	s.Color        = Color3.fromRGB(255, 120, 20)
	s.Transparency = 0.1
	s.Parent       = workspace

	tween:Create(s,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }
	):Play()

	task.delay(0.22, function()
		if s and s.Parent then s:Destroy() end
	end)
end

local wireSegs   = 22
local wireWidth  = 0.09
local wireColor  = Color3.fromRGB(8, 8, 8)
local sagAmt     = 0.07
local sagTime    = 1.8
local wireOffs   = {
	Vector3.new(0,  0.12,  0.20),
	Vector3.new(0,  0.12, -0.20),
}

local function makeWire()
	local data = { nodes = {}, beams = {} }
	for i = 1, wireSegs + 1 do
		local node = Instance.new("Part")
		node.Name         = "WireNode"
		node.Size         = Vector3.new(0.1, 0.1, 0.1)
		node.Anchored     = true
		node.CanCollide   = false
		node.Transparency = 1
		node.CastShadow   = false
		node.Parent       = workspace
		local attOut = Instance.new("Attachment", node)
		local attIn  = Instance.new("Attachment", node)
		table.insert(data.nodes, { part = node, attOut = attOut, attIn = attIn })
	end
	for i = 1, wireSegs do
		local beam = Instance.new("Beam")
		beam.Attachment0    = data.nodes[i].attOut
		beam.Attachment1    = data.nodes[i + 1].attIn
		beam.Color          = ColorSequence.new(wireColor)
		beam.Width0         = wireWidth
		beam.Width1         = wireWidth
		beam.FaceCamera     = true
		beam.Segments       = 1
		beam.CurveSize0     = 0
		beam.CurveSize1     = 0
		beam.LightInfluence = 0
		beam.Transparency   = NumberSequence.new(0)
		beam.Parent         = data.nodes[i].part
		table.insert(data.beams, beam)
	end
	return data
end

local function moveWire(data, p0, p1, time)
	local n      = wireSegs
	local len    = (p1 - p0).Magnitude
	local ramp   = math.min(time / sagTime, 1)
	for i = 1, n + 1 do
		local f       = (i - 1) / n
		local pos     = p0:Lerp(p1, f)
		local sag     = sagAmt * len * f * (1 - f) * ramp
		local flutter = math.sin(time * 6 + f * math.pi) * 0.025 * ramp
		data.nodes[i].part.Position = pos + Vector3.new(flutter, -sag, 0)
	end
end

local function killWires(w1, w2)
	for _, wire in ipairs({ w1, w2 }) do
		if wire then
			for _, n in ipairs(wire.nodes) do
				if n.part and n.part.Parent then n.part:Destroy() end
			end
		end
	end
end

local w1, w2
if basePrt then
	w1 = makeWire()
	w2 = makeWire()
	print("[TOW] Wires active")
else
	warn("[TOW] No Part named 'base' found — wires disabled")
end

local function calcDrag(v)
	local spd = v.Magnitude
	if spd < 0.01 then return Vector3.zero end
	return -v.Unit * (0.5 * stats.airDensity * spd * spd * stats.dragCoeff * stats.crossSection)
end

local function calcThrust(time)
	local motorT = time - stats.ejectTime
	if motorT < 0 then return 0
	elseif motorT <= stats.boostTime then return stats.boostThrust
	elseif motorT <= stats.boostTime + stats.sustainTime then return stats.sustainThrust
	end
	return 0
end

local function calcWobble(time)
	if time > stats.guidanceDelay + 2.2 then return 0 end
	return math.rad(stats.wobbleAmp) * math.exp(-stats.wobbleDamp * time) * math.cos(stats.wobbleFreq * time)
end

local function calcGuidance(mPos, tPos, fwd)
	local toTarget = tPos - mPos
	if toTarget.Magnitude < 0.5 then return Vector3.zero end
	local err  = toTarget.Unit - fwd
	local corr = err * stats.guidanceGain
	if corr.Magnitude > stats.turnRate then
		corr = corr.Unit * stats.turnRate
	end
	return corr
end

local function boom(hitPart, hitPos)
	-- gotta unanchor stuff in range first or the blast wont throw anything
	local blastR = 18
	for _, obj in ipairs(workspace:GetPartBoundsInRadius(hitPos, blastR)) do
		if obj ~= m and obj.Name ~= "WireNode"
			and obj.Name ~= "base" and obj.Name ~= "baser" and not obj:IsDescendantOf(m) then
			obj.Anchored   = false
			obj.CanCollide = true
		end
	end

	task.delay(0.02, function()
		local blast = Instance.new("Explosion")
		blast.Position                  = hitPos
		blast.BlastRadius               = blastR
		blast.BlastPressure             = 1200000
		blast.DestroyJointRadiusPercent = 1.0
		blast.ExplosionType             = Enum.ExplosionType.Craters
		blast.Visible                   = false
		blast.Parent                    = workspace
	end)

	local folder = m:FindFirstChild("Folder")
	if not folder then return end

	local anchor = Instance.new("Part")
	anchor.Size         = Vector3.new(0.1, 0.1, 0.1)
	anchor.Anchored     = true
	anchor.CanCollide   = false
	anchor.Transparency = 1
	anchor.CastShadow   = false
	anchor.Position     = hitPos
	anchor.Parent       = hitPart or workspace

	local attach = Instance.new("Attachment")
	attach.Position = Vector3.new(0, 0, 0)
	attach.Parent   = anchor

	local emitters = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			local e = child:Clone()
			e.Enabled = false
			local ks = e.Size.Keypoints
			local newKs = {}
			for _, kp in ipairs(ks) do
				table.insert(newKs, NumberSequenceKeypoint.new(kp.Time, kp.Value * 4, kp.Envelope * 4))
			end
			e.Size = NumberSequence.new(newKs)
			e.Parent = attach
			emitters[child.Name] = e
		end
	end

	local boomLight = Instance.new("PointLight", anchor)
	boomLight.Color      = Color3.fromRGB(255, 160, 40)
	boomLight.Brightness = 12
	boomLight.Range      = 60
	boomLight.Shadows    = true
	tween:Create(boomLight,
		TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Brightness = 0, Range = 10 }
	):Play()

	local function emit(name, count)
		local e = emitters[name]
		if e then e:Emit(count) end
	end

	emit("Explosion",  60)
	task.delay(0.04, function() emit("Shockwave",  8)  end)
	task.delay(0.08, function() emit("Sparks",    150)  end)
	task.delay(0.10, function() emit("Smoke1",     35)  end)
	task.delay(0.18, function() emit("Debris",     30)  end)
	task.delay(0.22, function() emit("Explosion",  25)  end)
	task.delay(0.28, function() emit("Smoke2",     40)  end)
	task.delay(0.35, function() emit("Sparks",     80)  end)
	task.delay(0.40, function() emit("Debris2",    25)  end)
	task.delay(0.55, function() emit("Smoke3",     50)  end)
	task.delay(0.75, function() emit("Smoke1",     30)  end)
	task.delay(0.90, function() emit("Smoke4",     60)  end)
	task.delay(1.20, function() emit("Smoke3",     40)  end)
	task.delay(1.60, function() emit("Smoke4",     50)  end)
	task.delay(2.20, function() emit("Smoke4",     40)  end)

	local boomSound = script.Parent:FindFirstChild("Giant Explosion")
	if boomSound then
		local s = boomSound:Clone()
		s.Parent = anchor
		s:Play()
	end

	task.delay(10, function()
		if anchor and anchor.Parent then anchor:Destroy() end
	end)
end

local conn

local function blowUp(hitPart)
	if dead then return end
	dead = true
	if conn then conn:Disconnect() end
	killFx()
	tailLight.Brightness = 0
	tailLight.Range      = 0
	frontLight.Brightness = 0
	if tailGlow and tailGlow.Parent then tailGlow:Destroy() end
	if noseGlow and noseGlow.Parent then noseGlow:Destroy() end
	if sound2 then
		tween:Create(sound2, TweenInfo.new(0.1), { Volume = 0 }):Play()
		task.delay(0.15, function() if sound2 then sound2:Stop() end end)
	end
	killWires(w1, w2)
	local hitPos = m.Position
	boom(hitPart, hitPos)
	m:Destroy()
end

conn = rs.Heartbeat:Connect(function(dt)
	if dead then return end
	t = t + dt

	if (m.Position - startPos).Magnitude > stats.maxRange then
		blowUp(nil); return
	end

	if target and target.Parent then
		if (m.Position - target.Position).Magnitude <= stats.blowRadius then
			blowUp(target); return
		end
	end

	local fwd    = m.CFrame.LookVector
	local thrust = calcThrust(t)
	local thrustF = fwd * thrust

	local gravF, dragF
	if t < stats.ejectTime then
		gravF = Vector3.zero
		dragF = Vector3.zero
	else
		gravF = stats.gravity * stats.mass
		dragF = calcDrag(vel)
	end

	local accel = (thrustF + gravF + dragF) / stats.mass
	vel = vel + accel * dt

	local nextPos = m.Position + vel * dt

	-- spiral kicks in a bit after launch so it clears the tube, then fades out over time
	local spiralT    = math.max(0, t - stats.spiralDelay)
	local spiralFade = 1 - math.min(spiralT / stats.spiralSettle, 1)
	local spiralR    = stats.spiralRadius * spiralFade
	local spiralUp   = math.sin(stats.spiralSpeed * spiralT) * spiralR
	local spiralSide = math.sin(stats.spiralSpeed * spiralT + math.pi / 2) * spiralR * (1 - math.exp(-stats.spiralSpeed * spiralT * 0.3))

	local right = m.CFrame.RightVector
	local up    = m.CFrame.UpVector
	local newPos = nextPos + right * spiralSide + up * spiralUp

	local wobble  = calcWobble(t)
	local lookDir = vel.Magnitude > 0.1 and vel.Unit or fwd

	m.CFrame =
		CFrame.lookAt(newPos, newPos + lookDir) *
		CFrame.Angles(wobble, 0, 0)

	if t > stats.guidanceDelay and target and target.Parent then
		local corr = calcGuidance(m.Position, target.Position, fwd)
		vel = vel + corr * vel.Magnitude * dt
	end

	local motorT  = t - stats.ejectTime
	local speed   = vel.Magnitude
	local tailPos = m.Position - m.CFrame.LookVector * (m.Size.Z * 0.5)
	local nosePos = m.Position + m.CFrame.LookVector * (m.Size.Z * 0.5)

	tailGlow.Position = tailPos
	noseGlow.Position = nosePos

	local speedFrac = math.clamp(speed / 80, 0, 1)
	frontLight.Brightness = speedFrac * 0.6
	frontLight.Range      = speedFrac * 6

	local flicker = 1 + (math.random() - 0.5) * 0.3

	if t < stats.ejectTime then
		if phase ~= "eject" then
			phase = "eject"
			setFx(0, 0, 0, 0, 0)
			tailLight.Brightness = 0
			tailLight.Range      = 0
			if sound2 then sound2.Volume = 0 end
		end

	elseif motorT <= stats.boostTime then
		if phase ~= "boost" then
			phase = "boost"
			setFx(80, 120, 12, 18, 0.55)
			if sound2 then
				sound2.PlaybackSpeed = 1.3
				tween:Create(sound2, TweenInfo.new(0.08), { Volume = 2.8 }):Play()
			end
		end
		tailLight.Brightness = 4.5 * flicker
		tailLight.Range      = 18

		if t - lastStreak >= streakGap then
			lastStreak = t
			makeStreak(tailPos)
		end

	elseif motorT <= stats.boostTime + stats.sustainTime then
		if phase ~= "sustain" then
			phase = "sustain"
			setFx(35, 55, 7, 10, 0.35)
			if sound2 then
				tween:Create(sound2, TweenInfo.new(0.3), { Volume = 2.0, PlaybackSpeed = 1.05 }):Play()
			end
		end
		tailLight.Brightness = 2.2 * flicker
		tailLight.Range      = 12

	else
		if phase ~= "coast" then
			phase = "coast"
			setFx(8, 0, 3, 0, 0)
			if sound2 then
				tween:Create(sound2, TweenInfo.new(0.6), { Volume = 0.6, PlaybackSpeed = 0.85 }):Play()
			end
		end
		tween:Create(tailLight, TweenInfo.new(0.5), { Brightness = 0, Range = 0 }):Play()
	end

	if basePrt and w1 and w2 then
		local bPos = basePrt.Position
		moveWire(w1, bPos + wireOffs[1], tailPos + wireOffs[1], t)
		moveWire(w2, bPos + wireOffs[2], tailPos + wireOffs[2], t)
	end
end)
