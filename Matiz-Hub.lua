local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEFAULTS = {
	enabled = false,
	mode = "Hybrid", 
	intensity = 0.65,
	velocityThreshold = 18,
	accelerationThreshold = 35,
	response = 12,
	decay = 9,
	cameraWeight = 0.85,
	velocityWeight = 0.65,
	accelerationWeight = 0.75,
    cameraEnabled = true,
    velocityEnabled = true,
    accelerationEnabled = true,
}



local UI_CUSTOM = {
    scale = 1.00,              
    panelWidth = 350,         
    panelHeight = 455,         
    floatingIconSize = 56,     
    floatingRightOffset = 76,  
}

local config = table.clone(DEFAULTS)


local KEY = "FaceBookHub_MB_"

local function saveConfig()
	pcall(function()
		player:SetAttribute(KEY.."Enabled", config.enabled)
		player:SetAttribute(KEY.."Mode", config.mode)
		player:SetAttribute(KEY.."Intensity", config.intensity)
        player:SetAttribute(KEY.."CameraEnabled", config.cameraEnabled)
        player:SetAttribute(KEY.."VelocityEnabled", config.velocityEnabled)
        player:SetAttribute(KEY.."AccelerationEnabled", config.accelerationEnabled)
        player:SetAttribute(KEY.."CameraWeight", config.cameraWeight)
        player:SetAttribute(KEY.."VelocityWeight", config.velocityWeight)
        player:SetAttribute(KEY.."AccelerationWeight", config.accelerationWeight)
	end)
end

local function loadConfig()
	pcall(function()
		local e = player:GetAttribute(KEY.."Enabled")
		local m = player:GetAttribute(KEY.."Mode")
		local i = player:GetAttribute(KEY.."Intensity")
        local ce = player:GetAttribute(KEY.."CameraEnabled")
        local ve = player:GetAttribute(KEY.."VelocityEnabled")
        local ae = player:GetAttribute(KEY.."AccelerationEnabled")
        local cw = player:GetAttribute(KEY.."CameraWeight")
        local vw = player:GetAttribute(KEY.."VelocityWeight")
        local aw = player:GetAttribute(KEY.."AccelerationWeight")

		if typeof(e) == "boolean" then config.enabled = e end
		if typeof(m) == "string" and (
			m == "Camera" or m == "Velocity" or
			m == "Acceleration" or m == "Hybrid"
		) then config.mode = m end
		if typeof(i) == "number" then config.intensity = math.clamp(i, 0, 1) end
        if typeof(ce) == "boolean" then config.cameraEnabled = ce end
        if typeof(ve) == "boolean" then config.velocityEnabled = ve end
        if typeof(ae) == "boolean" then config.accelerationEnabled = ae end
        if typeof(cw) == "number" then config.cameraWeight = math.clamp(cw, 0, 1) end
        if typeof(vw) == "number" then config.velocityWeight = math.clamp(vw, 0, 1) end
        if typeof(aw) == "number" then config.accelerationWeight = math.clamp(aw, 0, 1) end
	end)
end

loadConfig()

-- Auto-save: periodically checks for any config change and persists it,
-- as a safety net on top of the existing explicit saveConfig() calls.
local function configsMatch(a, b)
	for k in pairs(DEFAULTS) do
		if a[k] ~= b[k] then return false end
	end
	return true
end

local lastSavedConfig = table.clone(config)

task.spawn(function()
	while true do
		task.wait(2)
		if not configsMatch(config, lastSavedConfig) then
			saveConfig()
			lastSavedConfig = table.clone(config)
		end
	end
end)

local oldGui = playerGui:FindFirstChild("FaceBookHubMotionBlur")
if oldGui then oldGui:Destroy() end

local oldBlur = Lighting:FindFirstChild("FaceBookHubMotionBlurEffect")
if oldBlur then oldBlur:Destroy() end

local blur = Instance.new("BlurEffect")
blur.Name = "MatizHubMotionBlur"
blur.Size = 0
blur.Parent = Lighting

local camera = workspace.CurrentCamera
local lastLook = camera and camera.CFrame.LookVector or Vector3.new(0,0,-1)
local lastSpeed = 0
local targetBlur = 0

local function refreshCamera()
	camera = workspace.CurrentCamera
	if camera then lastLook = camera.CFrame.LookVector end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshCamera)

local C = {
	bg = Color3.fromRGB(9,10,14),
	surface = Color3.fromRGB(17,19,25),
	surface2 = Color3.fromRGB(24,27,35),
	surface3 = Color3.fromRGB(31,34,43),
	accent = Color3.fromRGB(102,170,255),
	accent2 = Color3.fromRGB(65,130,230),
	text = Color3.fromRGB(242,244,250),
	sub = Color3.fromRGB(157,163,177),
	muted = Color3.fromRGB(105,111,125),
	white = Color3.fromRGB(255,255,255),
}

local function tw(obj, time, props)
	TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name = "FaceBookHubMotionBlur"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = playerGui

local scale = Instance.new("UIScale")
scale.Parent = gui

local function resizeUI()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local s = math.min(cam.ViewportSize.X, cam.ViewportSize.Y)
	if s <= 500 then
		scale.Scale = 0.78
	elseif s <= 700 then
		scale.Scale = 0.88
	elseif s <= 1000 then
		scale.Scale = 1
	else
		scale.Scale = 1.05
	end
end

resizeUI()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeUI)
end

local function draggable(obj, handle)
	handle = handle or obj
	local dragging, start, origin

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = input.Position
			origin = obj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - start
			obj.Position = UDim2.new(
				origin.X.Scale, origin.X.Offset + d.X,
				origin.Y.Scale, origin.Y.Offset + d.Y
			)
		end
	end)
end


local floating = Instance.new("TextButton")
floating.Size = UDim2.fromOffset(UI_CUSTOM.floatingIconSize,UI_CUSTOM.floatingIconSize)
floating.Position = UDim2.new(1,-UI_CUSTOM.floatingRightOffset,0.5,-UI_CUSTOM.floatingIconSize/2)
floating.BackgroundColor3 = C.surface
floating.Text = ""
floating.AutoButtonColor = false
floating.Parent = gui

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(1,0)
fc.Parent = floating

local fs = Instance.new("UIStroke")
fs.Color = C.accent
fs.Thickness = 2
fs.Transparency = 0.15
fs.Parent = floating

local infinity = Instance.new("TextLabel")
infinity.Size = UDim2.fromScale(1,1)
infinity.BackgroundTransparency = 1
infinity.Text = "∞"
infinity.TextColor3 = C.white
infinity.Font = Enum.Font.GothamBold
infinity.TextSize = math.floor(UI_CUSTOM.floatingIconSize * 0.55)
infinity.Parent = floating

-- Animated infinity icon: gentle breathing pulse + subtle color cycle
local infinityScale = Instance.new("UIScale")
infinityScale.Scale = 1
infinityScale.Parent = infinity

local function pulseInfinity()
	TweenService:Create(
		infinityScale,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Scale = 1.18}
	):Play()
	TweenService:Create(
		infinity,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{TextColor3 = C.accent}
	):Play()
end
pulseInfinity()

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(9,9)
dot.Position = UDim2.new(1,-13,0,5)
dot.BackgroundColor3 = C.muted
dot.BorderSizePixel = 0
dot.Parent = floating

local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(1,0)
dc.Parent = dot

draggable(floating)

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(UI_CUSTOM.panelWidth,UI_CUSTOM.panelHeight)
panel.Position = UDim2.fromScale(0.5,0.5)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Visible = false
panel.ClipsDescendants = true
panel.Parent = gui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0,16)
pc.Parent = panel

local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(55,60,72)
ps.Transparency = 0.2
ps.Parent = panel

local gradient = Instance.new("UIGradient")
gradient.Rotation = 135
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(21,25,36)),
	ColorSequenceKeypoint.new(.5,Color3.fromRGB(10,11,15)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(5,6,9))
})
gradient.Parent = panel


local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,70)
header.BackgroundTransparency = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-70,0,28)
title.Position = UDim2.fromOffset(18,12)
title.BackgroundTransparency = 1
title.Text = "Motion Blur"
title.TextColor3 = C.text
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1,-90,0,20)
sub.Position = UDim2.fromOffset(19,39)
sub.BackgroundTransparency = 1
sub.Text = "Matiz Hub • Motion Controller"
sub.TextColor3 = C.sub
sub.Font = Enum.Font.Gotham
sub.TextSize = 11
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34,34)
close.Position = UDim2.new(1,-48,0,14)
close.BackgroundColor3 = C.surface2
close.Text = "×"
close.TextColor3 = C.text
close.Font = Enum.Font.GothamBold
close.TextSize = 22
close.AutoButtonColor = false
close.Parent = header

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0,9)
cc.Parent = close

draggable(panel,header)


local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1,-20,1,-82)
content.Position = UDim2.fromOffset(10,72)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.accent
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new(0,0,0,0)
content.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
content.Parent = panel

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0,4)
contentPadding.PaddingRight = UDim.new(0,4)
contentPadding.PaddingBottom = UDim.new(0,12)
contentPadding.Parent = content

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0,10)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = content

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 18)
end)


local toggleCard = Instance.new("Frame")
toggleCard.Size = UDim2.new(1,0,0,58)
toggleCard.BackgroundColor3 = C.surface
toggleCard.BorderSizePixel = 0
toggleCard.LayoutOrder = 1
toggleCard.Parent = content

local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0,11)
tc.Parent = toggleCard

local toggleText = Instance.new("TextLabel")
toggleText.Size = UDim2.new(1,-150,1,0)
toggleText.Position = UDim2.fromOffset(15,0)
toggleText.BackgroundTransparency = 1
toggleText.Text = "Motion Blur"
toggleText.TextColor3 = C.text
toggleText.Font = Enum.Font.GothamMedium
toggleText.TextSize = 14
toggleText.TextXAlignment = Enum.TextXAlignment.Left
toggleText.Parent = toggleCard

local toggleStatus = Instance.new("TextLabel")
toggleStatus.Size = UDim2.fromOffset(42, 20)
toggleStatus.Position = UDim2.new(1, -115, 0.5, -10)
toggleStatus.BackgroundTransparency = 1
toggleStatus.Text = "OFF"
toggleStatus.TextColor3 = C.muted
toggleStatus.Font = Enum.Font.GothamBold
toggleStatus.TextSize = 11
toggleStatus.TextXAlignment = Enum.TextXAlignment.Right
toggleStatus.Parent = toggleCard

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(54,28)
toggle.Position = UDim2.new(1,-68,.5,-14)
toggle.BackgroundColor3 = C.surface3
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Parent = toggleCard

local tcorner = Instance.new("UICorner")
tcorner.CornerRadius = UDim.new(1,0)
tcorner.Parent = toggle

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(22,22)
knob.Position = UDim2.fromOffset(3,3)
knob.BackgroundColor3 = C.text
knob.BorderSizePixel = 0
knob.Parent = toggle

local kcorner = Instance.new("UICorner")
kcorner.CornerRadius = UDim.new(1,0)
kcorner.Parent = knob


local modeCard = Instance.new("Frame")
modeCard.Size = UDim2.new(1,0,0,178)
modeCard.BackgroundColor3 = C.surface
modeCard.BorderSizePixel = 0
modeCard.LayoutOrder = 2
modeCard.Parent = content

local mcorner = Instance.new("UICorner")
mcorner.CornerRadius = UDim.new(0,14)
mcorner.Parent = modeCard

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1,-30,0,24)
modeTitle.Position = UDim2.fromOffset(15,9)
modeTitle.BackgroundTransparency = 1
modeTitle.Text = "Blur Source"
modeTitle.TextColor3 = C.text
modeTitle.Font = Enum.Font.GothamBold
modeTitle.TextSize = 14
modeTitle.TextXAlignment = Enum.TextXAlignment.Left
modeTitle.Parent = modeCard

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1,-30,0,18)
hint.Position = UDim2.fromOffset(15,30)
hint.BackgroundTransparency = 1
hint.Text = "Pick one mode, or mix each source separately in Hybrid."
hint.TextColor3 = C.muted
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = modeCard

local row = Instance.new("Frame")
row.Size = UDim2.new(1,-30,0,34)
row.Position = UDim2.fromOffset(15,53)
row.BackgroundTransparency = 1
row.Parent = modeCard

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(6,0)
grid.CellSize = UDim2.new(.25,-5,1,0)
grid.Parent = row

local modes = {"Camera","Velocity","Acceleration","Hybrid"}
local refreshUI
local modeButtons = {}

for _,name in ipairs(modes) do
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = C.surface3
    b.Text = name
    b.TextColor3 = C.sub
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 9
    b.AutoButtonColor = false
    b.Parent = row
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0,8)
    bc.Parent = b
    modeButtons[name] = b
    b.MouseButton1Click:Connect(function()
        config.mode = name
        saveConfig()
        refreshUI()
    end)
end

local hybridHint = Instance.new("TextLabel")
hybridHint.Size = UDim2.new(1,-30,0,18)
hybridHint.Position = UDim2.fromOffset(15,92)
hybridHint.BackgroundTransparency = 1
hybridHint.Text = "HYBRID CHANNELS"
hybridHint.TextColor3 = C.accent
hybridHint.Font = Enum.Font.GothamBold
hybridHint.TextSize = 9
hybridHint.TextXAlignment = Enum.TextXAlignment.Left
hybridHint.Parent = modeCard

local hybridRow = Instance.new("Frame")
hybridRow.Size = UDim2.new(1,-30,0,54)
hybridRow.Position = UDim2.fromOffset(15,114)
hybridRow.BackgroundTransparency = 1
hybridRow.Parent = modeCard

local hgrid = Instance.new("UIGridLayout")
hgrid.CellPadding = UDim2.fromOffset(6,0)
hgrid.CellSize = UDim2.new(1/3,-4,1,0)
hgrid.Parent = hybridRow

local hybridButtons = {}
local hybridDefs = {
    {key="cameraEnabled", label="CAMERA"},
    {key="velocityEnabled", label="VELOCITY"},
    {key="accelerationEnabled", label="ACCEL"},
}

for _,def in ipairs(hybridDefs) do
    local card = Instance.new("TextButton")
    card.BackgroundColor3 = C.surface3
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = hybridRow
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,9)
    corner.Parent = card

    local state = Instance.new("TextLabel")
    state.Size = UDim2.new(1,0,0,20)
    state.Position = UDim2.fromOffset(0,6)
    state.BackgroundTransparency = 1
    state.Text = "OFF"
    state.TextColor3 = C.muted
    state.Font = Enum.Font.GothamBold
    state.TextSize = 8
    state.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,20)
    label.Position = UDim2.fromOffset(0,25)
    label.BackgroundTransparency = 1
    label.Text = def.label
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 8
    label.Parent = card

    hybridButtons[def.key] = {button=card, state=state}
    card.MouseButton1Click:Connect(function()
        config[def.key] = not config[def.key]
        saveConfig()
        refreshUI()
    end)
end


local sliderCard = Instance.new("Frame")
sliderCard.Size = UDim2.new(1,0,0,78)
sliderCard.BackgroundColor3 = C.surface
sliderCard.BorderSizePixel = 0
sliderCard.LayoutOrder = 3
sliderCard.Parent = content

local slc = Instance.new("UICorner")
slc.CornerRadius = UDim.new(0,11)
slc.Parent = sliderCard

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1,-30,0,22)
sliderLabel.Position = UDim2.fromOffset(15,8)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = C.text
sliderLabel.Font = Enum.Font.GothamMedium
sliderLabel.TextSize = 13
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderCard

local track = Instance.new("Frame")
track.Size = UDim2.new(1,-30,0,7)
track.Position = UDim2.fromOffset(15,46)
track.BackgroundColor3 = C.surface3
track.BorderSizePixel = 0
track.Parent = sliderCard

local trc = Instance.new("UICorner")
trc.CornerRadius = UDim.new(1,0)
trc.Parent = track

local fill = Instance.new("Frame")
fill.BackgroundColor3 = C.accent
fill.BorderSizePixel = 0
fill.Parent = track

local fic = Instance.new("UICorner")
fic.CornerRadius = UDim.new(1,0)
fic.Parent = fill

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.fromOffset(16,16)
sliderKnob.AnchorPoint = Vector2.new(.5,.5)
sliderKnob.BackgroundColor3 = C.white
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 3
sliderKnob.Parent = track

local skc = Instance.new("UICorner")
skc.CornerRadius = UDim.new(1,0)
skc.Parent = sliderKnob

local function updateSlider()
	local v = math.clamp(config.intensity,0,1)
	fill.Size = UDim2.new(v,0,1,0)
	sliderKnob.Position = UDim2.new(v,0,.5,0)
	sliderLabel.Text = "Intensity    "..math.floor(v*100).."%"
end

local sliding = false

local function setSlider(x)
	local w = track.AbsoluteSize.X
	if w <= 0 then return end
	config.intensity = math.clamp((x-track.AbsolutePosition.X)/w,0,1)
	updateSlider()
    cameraWeightUI.update()
    velocityWeightUI.update()
    accelerationWeightUI.update()
    for key,item in pairs(hybridButtons) do
        local on = config[key]
        item.state.Text = on and "ON" or "OFF"
        item.state.TextColor3 = on and C.accent or C.muted
        item.button.BackgroundColor3 = on and C.surface3 or Color3.fromRGB(20,22,29)
    end
end

track.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		setSlider(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		setSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		if sliding then saveConfig() end
		sliding = false
	end
end)


local function makeHybridSlider(titleText, key, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,62)
    card.BackgroundColor3 = C.surface
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,12)
    corner.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-30,0,20)
    label.Position = UDim2.fromOffset(15,7)
    label.BackgroundTransparency = 1
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-30,0,6)
    track.Position = UDim2.fromOffset(15,39)
    track.BackgroundColor3 = C.surface3
    track.BorderSizePixel = 0
    track.Parent = card

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1,0)
    tc.Parent = track

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1,0)
    fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14,14)
    knob.AnchorPoint = Vector2.new(.5,.5)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1,0)
    kc.Parent = knob

    local draggingLocal = false
    local function update()
        local v = math.clamp(config[key],0,1)
        label.Text = titleText.."    "..math.floor(v*100).."%"
        fill.Size = UDim2.new(v,0,1,0)
        knob.Position = UDim2.new(v,0,.5,0)
    end
    local function setValue(x)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        config[key] = math.clamp((x-track.AbsolutePosition.X)/w,0,1)
        update()
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingLocal = true
            setValue(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingLocal and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setValue(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if draggingLocal and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            draggingLocal = false
            saveConfig()
        end
    end)
    update()
    return {update=update}
end

local cameraWeightUI = makeHybridSlider("Camera contribution", "cameraWeight", 4)
local velocityWeightUI = makeHybridSlider("Velocity contribution", "velocityWeight", 5)
local accelerationWeightUI = makeHybridSlider("Acceleration contribution", "accelerationWeight", 6)

-- Reset
local reset = Instance.new("TextButton")
reset.Size = UDim2.new(1,0,0,42)
reset.BackgroundColor3 = C.surface
reset.Text = "Reset Settings"
reset.TextColor3 = C.sub
reset.Font = Enum.Font.GothamMedium
reset.TextSize = 12
reset.AutoButtonColor = false
reset.LayoutOrder = 7
reset.Parent = content

local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0,11)
rc.Parent = reset

reset.MouseButton1Click:Connect(function()
	config.enabled = DEFAULTS.enabled
	config.mode = DEFAULTS.mode
	config.intensity = DEFAULTS.intensity
	config.cameraEnabled = DEFAULTS.cameraEnabled
	config.velocityEnabled = DEFAULTS.velocityEnabled
	config.accelerationEnabled = DEFAULTS.accelerationEnabled
	config.cameraWeight = DEFAULTS.cameraWeight
	config.velocityWeight = DEFAULTS.velocityWeight
	config.accelerationWeight = DEFAULTS.accelerationWeight
	saveConfig()
	refreshUI()
end)

toggle.MouseButton1Click:Connect(function()
	config.enabled = not config.enabled
	saveConfig()
	refreshUI()
end)

floating.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		content.CanvasPosition = Vector2.new(0,0)
		panel.Size = UDim2.fromOffset(UI_CUSTOM.panelWidth - 20, UI_CUSTOM.panelHeight - 20)
		tw(panel,.22,{Size=UDim2.fromOffset(UI_CUSTOM.panelWidth,UI_CUSTOM.panelHeight)})
	end
end)

close.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

refreshUI = function()
	local on = config.enabled
	toggleStatus.Text = on and "ON" or "OFF"
	toggleStatus.TextColor3 = on and C.accent or C.muted
	tw(toggleStatus,.15,{TextColor3=on and C.accent or C.muted})
	tw(toggle,.15,{BackgroundColor3=on and C.accent2 or C.surface3})
	tw(knob,.15,{Position=on and UDim2.new(1,-25,0,3) or UDim2.fromOffset(3,3)})
	tw(dot,.15,{BackgroundColor3=on and C.accent or C.muted})
	for name,b in pairs(modeButtons) do
		b.BackgroundColor3 = (name == config.mode) and C.accent2 or C.surface3
		b.TextColor3 = (name == config.mode) and C.white or C.sub
	end
	updateSlider()
	cameraWeightUI.update()
	velocityWeightUI.update()
	accelerationWeightUI.update()
	for key,item in pairs(hybridButtons) do
		local enabled = config[key]
		item.state.Text = enabled and "ON" or "OFF"
		item.state.TextColor3 = enabled and C.accent or C.muted
		item.button.BackgroundColor3 = enabled and C.surface3 or Color3.fromRGB(20,22,29)
	end
end


local function getHRP()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function cameraAmount(dt)
	if not camera then return 0 end
	local look = camera.CFrame.LookVector
	local dotProduct = math.clamp(lastLook:Dot(look),-1,1)
	local angle = math.deg(math.acos(dotProduct))
	lastLook = look
	local angularSpeed = angle / math.max(dt,1/240)
	return math.clamp(angularSpeed/180,0,1) * config.cameraWeight
end

local function velocityAmount(hrp)
	local speed = hrp.AssemblyLinearVelocity.Magnitude
	return math.clamp(math.max(speed-config.velocityThreshold,0)/100,0,1)
		* config.velocityWeight
end

local function accelerationAmount(hrp,dt)
	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local acceleration = math.abs(speed-lastSpeed)/math.max(dt,1/240)
	lastSpeed = speed
	return math.clamp(math.max(acceleration-config.accelerationThreshold,0)/180,0,1)
		* config.accelerationWeight
end

RunService.RenderStepped:Connect(function(dt)
	if not config.enabled then
		blur.Size += (0-blur.Size)*math.clamp(dt*14,0,1)
		return
	end

	local camAmount = cameraAmount(dt)
	local velAmount, accAmount = 0,0
	local hrp = getHRP()

	if hrp then
		velAmount = velocityAmount(hrp)
		accAmount = accelerationAmount(hrp,dt)
	else
		lastSpeed = 0
	end

	local raw
	if config.mode == "Camera" then
		raw = camAmount
	elseif config.mode == "Velocity" then
		raw = velAmount
	elseif config.mode == "Acceleration" then
		raw = accAmount
	else
		
		raw = 0
		if config.cameraEnabled then raw += camAmount end
		if config.velocityEnabled then raw += velAmount end
		if config.accelerationEnabled then raw += accAmount end
		raw = math.clamp(raw,0,1)
	end

	local target = math.clamp(raw*config.intensity*32,0,32)
	targetBlur += (target-targetBlur)*math.clamp(dt*config.response,0,1)
	blur.Size += (targetBlur-blur.Size)*math.clamp(dt*config.decay,0,1)
end)

player.CharacterAdded:Connect(function()
	lastSpeed = 0
	targetBlur = 0
	task.wait(.2)
	refreshCamera()
end)

refreshUI()

task.defer(function()
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.X < 600 then
		floating.Position = UDim2.new(1,-math.max(66,UI_CUSTOM.floatingRightOffset-10),.72,0)
	end
end)
