--[[
    MOTION BLUR CONTROLLER - ENHANCED EDITION

    Place in:
        StarterPlayer > StarterPlayerScripts

    Features:
        • Animated floating infinity button
        • Crystal / glass dark UI
        • Smooth open / close animations
        • PC + mobile support
        • Draggable floating button
        • Draggable settings panel
        • Motion Blur On / Off
        • Camera / Velocity / Acceleration modes
        • Shared Max Blur Size
        • Smoothed motion detection
        • Smooth blur interpolation
        • Respawn-safe
        • Roblox client-side only
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local config = {
    enabled = false,
    mode = "Velocity",

    cameraSensitivity = 8,
    velocityThreshold = 20,
    velocitySensitivity = 0.6,

    accelThreshold = 40,
    accelSensitivity = 0.35,

    -- Shared by every mode.
    maxBlurSize = 20,

    smoothing = 10,
}

local character
local humanoid
local rootPart

local currentBlur = 0
local smoothedSpeed = 0
local previousSpeed = 0
local previousCameraCFrame = workspace.CurrentCamera.CFrame
local cameraMotion = 0
local accelerationValue = 0

local panelOpen = false
local camera = workspace.CurrentCamera

-- Clean up a previous copy if this script was re-run.
for _, object in ipairs(Lighting:GetChildren()) do
    if object:IsA("BlurEffect") and object.Name == "MotionBlurEffect" then
        object:Destroy()
    end
end

local blur = Instance.new("BlurEffect")
blur.Name = "MotionBlurEffect"
blur.Size = 0
blur.Enabled = true
blur.Parent = Lighting

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 5)
    rootPart = char:WaitForChild("HumanoidRootPart", 5)

    previousSpeed = 0
    smoothedSpeed = 0
    accelerationValue = 0
end

if player.Character then
    task.spawn(setupCharacter, player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MotionBlurUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Floating button.
local iconHolder = Instance.new("Frame")
iconHolder.Name = "FloatingButtonHolder"
iconHolder.Size = UDim2.fromOffset(64, 64)
iconHolder.Position = UDim2.new(1, -85, 0.22, 0)
iconHolder.BackgroundTransparency = 1
iconHolder.Parent = screenGui

local iconShadow = Instance.new("Frame")
iconShadow.Size = UDim2.fromScale(1, 1)
iconShadow.Position = UDim2.fromOffset(0, 4)
iconShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconShadow.BackgroundTransparency = 0.55
iconShadow.ZIndex = 1
iconShadow.Parent = iconHolder
createCorner(iconShadow, 32)

local icon = Instance.new("TextButton")
icon.Name = "FloatingIcon"
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
icon.BackgroundTransparency = 0.05
icon.Text = ""
icon.AutoButtonColor = false
icon.ZIndex = 3
icon.Parent = iconHolder
createCorner(icon, 32)

local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 30, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 13, 18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 25, 32)),
})
iconGradient.Rotation = 135
iconGradient.Parent = icon

local iconStroke = createStroke(icon, Color3.fromRGB(90, 160, 255), 0.15, 2)

local infinity = Instance.new("TextLabel")
infinity.Name = "Infinity"
infinity.Size = UDim2.fromScale(1, 1)
infinity.BackgroundTransparency = 1
infinity.Text = "∞"
infinity.TextColor3 = Color3.fromRGB(225, 235, 255)
infinity.Font = Enum.Font.GothamBlack
infinity.TextSize = 38
infinity.ZIndex = 4
infinity.Parent = icon

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(9, 9)
statusDot.Position = UDim2.new(1, -13, 0, 5)
statusDot.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
statusDot.ZIndex = 5
statusDot.Parent = iconHolder
createCorner(statusDot, 10)
createStroke(statusDot, Color3.fromRGB(255, 255, 255), 0.5, 1)

task.spawn(function()
    while screenGui.Parent do
        local tween = TweenService:Create(
            infinity,
            TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Rotation = 360}
        )
        tween:Play()
        tween.Completed:Wait()
        infinity.Rotation = 0
    end
end)

-- Dragging.
local function makeDraggable(object, handle)
    handle = handle or object

    local dragging = false
    local dragStart
    local startPosition
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            moved = false
            dragStart = input.Position
            startPosition = object.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            moved = true
        end

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    return function()
        return moved
    end
end

local iconMoved = makeDraggable(iconHolder, icon)

-- Settings panel.
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.fromOffset(340, 440)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.Parent = screenGui

createCorner(panel, 18)
createStroke(panel, Color3.fromRGB(100, 110, 130), 0.35, 1)

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 27, 34)),
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(12, 13, 17)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 27)),
})
panelGradient.Rotation = 135
panelGradient.Parent = panel

local topGlow = Instance.new("Frame")
topGlow.Size = UDim2.new(0.75, 0, 0, 2)
topGlow.Position = UDim2.new(0.125, 0, 0, 0)
topGlow.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
topGlow.BackgroundTransparency = 0.15
topGlow.BorderSizePixel = 0
topGlow.ZIndex = 12
topGlow.Parent = panel
createCorner(topGlow, 5)

-- Title bar.
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 62)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 11
titleBar.Parent = panel

local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.fromOffset(42, 42)
titleIcon.Position = UDim2.fromOffset(14, 10)
titleIcon.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
titleIcon.Text = "∞"
titleIcon.TextColor3 = Color3.fromRGB(130, 185, 255)
titleIcon.Font = Enum.Font.GothamBlack
titleIcon.TextSize = 25
titleIcon.ZIndex = 12
titleIcon.Parent = titleBar
createCorner(titleIcon, 12)
createStroke(titleIcon, Color3.fromRGB(80, 145, 230), 0.5, 1)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 25)
title.Position = UDim2.fromOffset(68, 10)
title.BackgroundTransparency = 1
title.Text = "Motion Blur"
title.TextColor3 = Color3.fromRGB(240, 243, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12
title.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -120, 0, 18)
subtitle.Position = UDim2.fromOffset(69, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Visual motion enhancement"
subtitle.TextColor3 = Color3.fromRGB(130, 135, 148)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 12
subtitle.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.Position = UDim2.new(1, -48, 0, 14)
closeButton.BackgroundColor3 = Color3.fromRGB(28, 29, 36)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(205, 208, 216)
closeButton.Font = Enum.Font.GothamMedium
closeButton.TextSize = 24
closeButton.AutoButtonColor = false
closeButton.ZIndex = 13
closeButton.Parent = titleBar
createCorner(closeButton, 10)

makeDraggable(panel, titleBar)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.fromOffset(14, 62)
divider.BackgroundColor3 = Color3.fromRGB(55, 58, 68)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.ZIndex = 11
divider.Parent = panel

-- Toggle.
local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -28, 0, 62)
toggleRow.Position = UDim2.fromOffset(14, 76)
toggleRow.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
toggleRow.BackgroundTransparency = 0.15
toggleRow.BorderSizePixel = 0
toggleRow.ZIndex = 11
toggleRow.Parent = panel
createCorner(toggleRow, 12)
createStroke(toggleRow, Color3.fromRGB(60, 65, 78), 0.6, 1)

local toggleTitle = Instance.new("TextLabel")
toggleTitle.Size = UDim2.new(1, -90, 0, 23)
toggleTitle.Position = UDim2.fromOffset(14, 9)
toggleTitle.BackgroundTransparency = 1
toggleTitle.Text = "Motion Blur"
toggleTitle.TextColor3 = Color3.fromRGB(235, 237, 244)
toggleTitle.Font = Enum.Font.GothamSemibold
toggleTitle.TextSize = 14
toggleTitle.TextXAlignment = Enum.TextXAlignment.Left
toggleTitle.ZIndex = 12
toggleTitle.Parent = toggleRow

local toggleSubtitle = Instance.new("TextLabel")
toggleSubtitle.Size = UDim2.new(1, -90, 0, 18)
toggleSubtitle.Position = UDim2.fromOffset(14, 32)
toggleSubtitle.BackgroundTransparency = 1
toggleSubtitle.Text = "Enable visual motion processing"
toggleSubtitle.TextColor3 = Color3.fromRGB(125, 130, 142)
toggleSubtitle.Font = Enum.Font.Gotham
toggleSubtitle.TextSize = 10
toggleSubtitle.TextXAlignment = Enum.TextXAlignment.Left
toggleSubtitle.ZIndex = 12
toggleSubtitle.Parent = toggleRow

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.fromOffset(52, 28)
toggleButton.Position = UDim2.new(1, -66, 0.5, -14)
toggleButton.BackgroundColor3 = Color3.fromRGB(48, 50, 59)
toggleButton.Text = ""
toggleButton.AutoButtonColor = false
toggleButton.ZIndex = 13
toggleButton.Parent = toggleRow
createCorner(toggleButton, 20)

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.fromOffset(22, 22)
toggleKnob.Position = UDim2.fromOffset(3, 3)
toggleKnob.BackgroundColor3 = Color3.fromRGB(220, 223, 230)
toggleKnob.BorderSizePixel = 0
toggleKnob.ZIndex = 14
toggleKnob.Parent = toggleButton
createCorner(toggleKnob, 20)

local function updateToggleVisual(animated)
    local targetColor = config.enabled
        and Color3.fromRGB(75, 145, 235)
        or Color3.fromRGB(48, 50, 59)

    local targetPosition = config.enabled
        and UDim2.fromOffset(27, 3)
        or UDim2.fromOffset(3, 3)

    if animated then
        TweenService:Create(
            toggleButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {BackgroundColor3 = targetColor}
        ):Play()

        TweenService:Create(
            toggleKnob,
            TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Position = targetPosition}
        ):Play()
    else
        toggleButton.BackgroundColor3 = targetColor
        toggleKnob.Position = targetPosition
    end

    TweenService:Create(
        statusDot,
        TweenInfo.new(0.2),
        {
            BackgroundColor3 = config.enabled
                and Color3.fromRGB(90, 220, 150)
                or Color3.fromRGB(90, 90, 100)
        }
    ):Play()
end

toggleButton.MouseButton1Click:Connect(function()
    config.enabled = not config.enabled
    updateToggleVisual(true)

    if not config.enabled then
        currentBlur = 0
        TweenService:Create(
            blur,
            TweenInfo.new(0.25, Enum.EasingStyle.Quint),
            {Size = 0}
        ):Play()
    end
end)

-- Mode selector.
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -28, 0, 20)
modeLabel.Position = UDim2.fromOffset(14, 152)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "MOTION MODE"
modeLabel.TextColor3 = Color3.fromRGB(125, 135, 155)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 10
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.ZIndex = 12
modeLabel.Parent = panel

local modeContainer = Instance.new("Frame")
modeContainer.Size = UDim2.new(1, -28, 0, 46)
modeContainer.Position = UDim2.fromOffset(14, 175)
modeContainer.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
modeContainer.BackgroundTransparency = 0.1
modeContainer.BorderSizePixel = 0
modeContainer.ZIndex = 11
modeContainer.Parent = panel
createCorner(modeContainer, 11)
createStroke(modeContainer, Color3.fromRGB(60, 65, 78), 0.65, 1)

local modeLayout = Instance.new("UIListLayout")
modeLayout.FillDirection = Enum.FillDirection.Horizontal
modeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
modeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
modeLayout.Padding = UDim.new(0, 5)
modeLayout.Parent = modeContainer

local modeButtons = {}

local modeDisplayNames = {
    Camera = "Camera",
    Velocity = "Velocity",
    Acceleration = "Accel",
}

local function refreshModeButtons()
    for modeName, button in pairs(modeButtons) do
        local active = config.mode == modeName

        TweenService:Create(
            button,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 = active
                    and Color3.fromRGB(75, 145, 235)
                    or Color3.fromRGB(31, 33, 41),

                TextColor3 = active
                    and Color3.fromRGB(255, 255, 255)
                    or Color3.fromRGB(160, 165, 178),
            }
        ):Play()
    end
end

local function createModeButton(modeName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(95, 32)
    button.BackgroundColor3 = Color3.fromRGB(31, 33, 41)
    button.Text = modeDisplayNames[modeName]
    button.TextColor3 = Color3.fromRGB(160, 165, 178)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 11
    button.AutoButtonColor = false
    button.ZIndex = 13
    button.Parent = modeContainer
    createCorner(button, 8)

    button.MouseButton1Click:Connect(function()
        if config.mode == modeName then
            return
        end

        config.mode = modeName
        previousCameraCFrame = camera.CFrame
        previousSpeed = 0
        accelerationValue = 0
        refreshModeButtons()
    end)

    modeButtons[modeName] = button
end

createModeButton("Camera")
createModeButton("Velocity")
createModeButton("Acceleration")
refreshModeButtons()

-- Slider helper.
local function createSlider(
    parent,
    yPosition,
    labelText,
    minValue,
    maxValue,
    defaultValue,
    onChange
)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -28, 0, 54)
    container.Position = UDim2.fromOffset(14, yPosition)
    container.BackgroundTransparency = 1
    container.ZIndex = 11
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(205, 208, 217)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 12
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(100, 165, 255)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 12
    valueLabel.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.fromOffset(0, 30)
    track.BackgroundColor3 = Color3.fromRGB(42, 44, 53)
    track.BorderSizePixel = 0
    track.ZIndex = 12
    track.Parent = container
    createCorner(track, 10)

    local initialAlpha =
        (defaultValue - minValue) /
        (maxValue - minValue)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialAlpha, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(85, 155, 240)
    fill.BorderSizePixel = 0
    fill.ZIndex = 13
    fill.Parent = track
    createCorner(fill, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialAlpha, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(240, 244, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 14
    knob.Parent = track
    createCorner(knob, 20)
    createStroke(knob, Color3.fromRGB(100, 170, 255), 0.35, 1)

    local dragging = false

    local function setValueFromX(x)
        local width = track.AbsoluteSize.X

        if width <= 0 then
            return
        end

        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / width,
            0,
            1
        )

        local value =
            minValue +
            (maxValue - minValue) * alpha

        value = math.floor(value * 100 + 0.5) / 100

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        onChange(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setValueFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return container
end

createSlider(panel, 235, "Camera Sensitivity", 1, 20, config.cameraSensitivity, function(value)
    config.cameraSensitivity = value
end)

createSlider(panel, 291, "Velocity Sensitivity", 0.1, 2, config.velocitySensitivity, function(value)
    config.velocitySensitivity = value
end)

createSlider(panel, 347, "Acceleration Sensitivity", 0.1, 1, config.accelSensitivity, function(value)
    config.accelSensitivity = value
end)

createSlider(panel, 403, "Max Blur Size", 4, 32, config.maxBlurSize, function(value)
    config.maxBlurSize = value
end)

-- Panel animations.
local panelOriginalSize = UDim2.fromOffset(340, 440)

local function openPanel()
    if panelOpen then
        return
    end

    panelOpen = true
    panel.Visible = true
    panel.Size = UDim2.fromOffset(310, 400)
    panel.BackgroundTransparency = 0.4

    TweenService:Create(
        panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {
            Size = panelOriginalSize,
            BackgroundTransparency = 0.03,
        }
    ):Play()
end

local function closePanel()
    if not panelOpen then
        return
    end

    panelOpen = false

    local tween = TweenService:Create(
        panel,
        TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {
            Size = UDim2.fromOffset(310, 400),
            BackgroundTransparency = 0.45,
        }
    )

    tween:Play()

    tween.Completed:Once(function()
        if not panelOpen then
            panel.Visible = false
        end
    end)
end

icon.MouseButton1Click:Connect(function()
    if iconMoved() then
        return
    end

    if panelOpen then
        closePanel()
    else
        openPanel()
    end
end)

closeButton.MouseButton1Click:Connect(closePanel)

-- Hover effects.
icon.MouseEnter:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.18), {
        BackgroundColor3 = Color3.fromRGB(25, 29, 38),
    }):Play()

    TweenService:Create(iconStroke, TweenInfo.new(0.18), {
        Color = Color3.fromRGB(125, 190, 255),
        Transparency = 0,
    }):Play()

    TweenService:Create(iconHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Size = UDim2.fromOffset(68, 68),
    }):Play()
end)

icon.MouseLeave:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.18), {
        BackgroundColor3 = Color3.fromRGB(13, 14, 18),
    }):Play()

    TweenService:Create(iconStroke, TweenInfo.new(0.18), {
        Color = Color3.fromRGB(90, 160, 255),
        Transparency = 0.15,
    }):Play()

    TweenService:Create(iconHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Size = UDim2.fromOffset(64, 64),
    }):Play()
end)

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(45, 47, 57),
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(28, 29, 36),
    }):Play()
end)

-- Motion calculations.
local function calculateCameraBlur(dt)
    local currentCFrame = camera.CFrame

    local previousLook = previousCameraCFrame.LookVector
    local currentLook = currentCFrame.LookVector

    local dot = math.clamp(previousLook:Dot(currentLook), -1, 1)
    local angleDelta = math.deg(math.acos(dot))

    local angularSpeed = angleDelta / math.max(dt, 1 / 240)

    cameraMotion = cameraMotion
        + (angularSpeed - cameraMotion) * math.clamp(dt * 12, 0, 1)

    previousCameraCFrame = currentCFrame

    local result = cameraMotion * config.cameraSensitivity * 0.035

    return math.clamp(result, 0, config.maxBlurSize)
end

local function calculateVelocityBlur(dt)
    if not rootPart then
        return 0
    end

    local velocity = rootPart.AssemblyLinearVelocity

    local horizontalVelocity = Vector3.new(
        velocity.X,
        0,
        velocity.Z
    )

    local speed = horizontalVelocity.Magnitude

    smoothedSpeed = smoothedSpeed
        + (speed - smoothedSpeed) * math.clamp(dt * 8, 0, 1)

    if smoothedSpeed <= config.velocityThreshold then
        return 0
    end

    local result =
        (smoothedSpeed - config.velocityThreshold) *
        config.velocitySensitivity

    return math.clamp(result, 0, config.maxBlurSize)
end

local function calculateAccelerationBlur(dt)
    if not rootPart then
        return 0
    end

    local velocity = rootPart.AssemblyLinearVelocity

    local horizontalVelocity = Vector3.new(
        velocity.X,
        0,
        velocity.Z
    )

    local speed = horizontalVelocity.Magnitude

    local acceleration =
        (speed - previousSpeed) /
        math.max(dt, 1 / 240)

    previousSpeed = speed

    local absoluteAcceleration = math.abs(acceleration)
    local target = 0

    if absoluteAcceleration > config.accelThreshold then
        target = absoluteAcceleration * config.accelSensitivity
        target = math.clamp(target, 0, config.maxBlurSize)
    end

    if target > accelerationValue then
        accelerationValue = accelerationValue
            + (target - accelerationValue) * math.clamp(dt * 18, 0, 1)
    else
        accelerationValue = accelerationValue
            + (target - accelerationValue) * math.clamp(dt * 5, 0, 1)
    end

    return math.clamp(accelerationValue, 0, config.maxBlurSize)
end

-- Main render loop.
RunService.RenderStepped:Connect(function(dt)
    if not config.enabled then
        currentBlur = currentBlur
            + (0 - currentBlur) * math.clamp(dt * 12, 0, 1)

        blur.Size = currentBlur
        return
    end

    local targetBlur = 0

    if config.mode == "Camera" then
        targetBlur = calculateCameraBlur(dt)
    elseif config.mode == "Velocity" then
        targetBlur = calculateVelocityBlur(dt)
    elseif config.mode == "Acceleration" then
        targetBlur = calculateAccelerationBlur(dt)
    end

    currentBlur = currentBlur
        + (targetBlur - currentBlur)
        * math.clamp(dt * config.smoothing, 0, 1)

    blur.Size = math.clamp(
        currentBlur,
        0,
        config.maxBlurSize
    )
end)

updateToggleVisual(false)
refreshModeButtons()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera

    if camera then
        previousCameraCFrame = camera.CFrame
        cameraMotion = 0
    end
end)

screenGui.AncestryChanged:Connect(function(_, parent)
    if not parent and blur and blur.Parent then
        blur:Destroy()
    end
end)

print("[MotionBlur] Enhanced Motion Blur Controller loaded.")
