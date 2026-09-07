local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local CONFIG_FILE = "PrxDIGY_Fruit_Config.json"
local Config = {
    AutoBuyRandomFruit=false, AutoEatFruit=false, AutoStoreFruit=false, FruitNotification=false,
    TeleportToFruit=false, TweenToFruit=false, AutoSnipeFruit=false, AutoGrabAll=false,
    AutoServerHop=false, StoreRarity="Common - Mythical", SnipeRarity="Legendary - Mythical"
}

local function loadConfig()
    if type(readfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data)=="table" then for k,v in pairs(data) do Config[k]=v end end
    end
end
local function saveConfig()
    if type(writefile) ~= "function" then return false, "writefile unavailable" end
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
    return ok, err
end
loadConfig()

local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local function guiParent()
    local ok, hui = pcall(function() return gethui() end)
    return ok and hui or CoreGui
end

pcall(function()
    local old = guiParent():FindFirstChild("PrxDIGYFruitEdition")
    if old then old:Destroy() end
end)

local Theme = {
    bg = Color3.fromRGB(10, 10, 12),
    panel = Color3.fromRGB(15, 14, 17),
    panel2 = Color3.fromRGB(20, 18, 22),
    card = Color3.fromRGB(28, 24, 29),
    cardHover = Color3.fromRGB(37, 28, 34),
    red = Color3.fromRGB(205, 38, 53),
    red2 = Color3.fromRGB(242, 72, 82),
    redDark = Color3.fromRGB(72, 18, 25),
    text = Color3.fromRGB(244, 246, 250),
    muted = Color3.fromRGB(151, 157, 171),
    green = Color3.fromRGB(51, 209, 132),
    line = Color3.fromRGB(52, 55, 68)
}

local function tween(obj, duration, props)
    return TweenService:Create(obj, TweenInfo.new(duration or .2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function outline(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.line
    s.Transparency = transparency == nil and .35 or transparency
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function label(parent, value, size, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = value or ""
    l.TextColor3 = Theme.text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
    l.TextSize = size or 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "PrxDIGYFruitEdition"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = guiParent()

local ToastHolder = Instance.new("Frame")
ToastHolder.BackgroundTransparency = 1
ToastHolder.AnchorPoint = Vector2.new(1, 0)
ToastHolder.Position = UDim2.new(1, -18, 0, 72)
ToastHolder.Size = UDim2.new(0, 330, 0, 400)
ToastHolder.Parent = Screen

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.Parent = ToastHolder

local function notify(title, description, duration)
    local toast = Instance.new("Frame")
    toast.BackgroundColor3 = Theme.panel2
    toast.BackgroundTransparency = 1
    toast.Size = UDim2.new(1, 0, 0, 58)
    toast.Parent = ToastHolder
    corner(toast, 12)
    outline(toast, Theme.red, .5, 1)

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Theme.red
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.Parent = toast
    corner(bar, 3)

    local t = label(toast, title or "PrxDIGY Hub", 12, true)
    t.Position = UDim2.new(0, 22, 0, 8)
    t.Size = UDim2.new(1, -32, 0, 18)

    local d = label(toast, description or "", 10, false)
    d.TextColor3 = Theme.muted
    d.Position = UDim2.new(0, 22, 0, 28)
    d.Size = UDim2.new(1, -32, 0, 18)

    tween(toast, .25, {BackgroundTransparency = .03}):Play()
    task.delay(duration or 3, function()
        if toast.Parent then
            tween(toast, .2, {BackgroundTransparency = 1}):Play()
            task.wait(.22)
            toast:Destroy()
        end
    end)
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(.5, .5)
Main.Position = UDim2.new(.5, 0, .5, 0)
Main.Size = UDim2.new(0, 1000, 0, 650)
Main.BackgroundColor3 = Theme.bg
Main.ClipsDescendants = true
Main.Parent = Screen
corner(Main, 20)
outline(Main, Theme.red, .55, 1)

local scale = Instance.new("UIScale")
scale.Parent = Main
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    scale.Scale = math.clamp(math.min((camera.ViewportSize.X - 20) / 1020, (camera.ViewportSize.Y - 20) / 670), .58, 1)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local background = Instance.new("Frame")
background.BackgroundColor3 = Theme.panel
background.Size = UDim2.new(1, 0, 1, 0)
background.Parent = Main
corner(background, 20)

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 7, 10)),
    ColorSequenceKeypoint.new(.55, Color3.fromRGB(10, 11, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 7, 9))
})
bgGradient.Rotation = 25
bgGradient.Parent = background

local Header = Instance.new("Frame")
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 88)
Header.Parent = Main

local logo = Instance.new("Frame")
logo.BackgroundColor3 = Theme.redDark
logo.Position = UDim2.new(0, 22, 0, 19)
logo.Size = UDim2.new(0, 50, 0, 50)
logo.Parent = Header
corner(logo, 14)
outline(logo, Theme.red, .15, 1)

local logoText = label(logo, "PX", 18, true)
logoText.TextXAlignment = Enum.TextXAlignment.Center
logoText.TextYAlignment = Enum.TextYAlignment.Center
logoText.Size = UDim2.new(1, 0, 1, 0)

local eyebrow = label(Header, "PRXDIGY  /  FRUIT TOOLS", 9, true)
eyebrow.TextColor3 = Theme.red2
eyebrow.Position = UDim2.new(0, 88, 0, 17)
eyebrow.Size = UDim2.new(0, 420, 0, 13)

local title = label(Header, "PrxDIGY", 26, true)
title.Position = UDim2.new(0, 88, 0, 27)
title.Size = UDim2.new(0, 420, 0, 26)

local subtitle = label(Header, "Fruit utility suite", 10, false)
subtitle.TextColor3 = Theme.muted
subtitle.Position = UDim2.new(0, 88, 0, 54)
subtitle.Size = UDim2.new(0, 460, 0, 17)

local minimized = false
local function headerControl(symbol, x, hint)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false; b.Text = symbol; b.TextColor3 = Theme.text
    b.Font = Enum.Font.GothamBold; b.TextSize = 15; b.BackgroundColor3 = Theme.card
    b.Position = UDim2.new(1, x, 0, 27); b.Size = UDim2.new(0, 30, 0, 30); b.Parent = Header
    corner(b, 8); outline(b, Theme.line, .6, 1)
    return b
end
local closeButton = headerControl("×", -42)
local minimizeButton = headerControl("—", -78)

local divider = Instance.new("Frame")
divider.BackgroundColor3 = Theme.line
divider.BackgroundTransparency = .35
divider.Position = UDim2.new(0, 22, 0, 87)
divider.Size = UDim2.new(1, -44, 0, 1)
divider.Parent = Header

local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 22, 0, 106)
Content.Size = UDim2.new(1, -44, 1, -146)
Content.Parent = Main

local function makeCard(parent, titleText, description, position, size)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Theme.panel2
    card.Position = position
    card.Size = size
    card.Parent = parent
    corner(card, 14)
    outline(card, Theme.line, .4, 1)

    local head = label(card, titleText, 13, true)
    head.Position = UDim2.new(0, 16, 0, 14)
    head.Size = UDim2.new(1, -32, 0, 20)

    local desc = label(card, description, 9, false)
    desc.TextColor3 = Theme.muted
    desc.Position = UDim2.new(0, 16, 0, 33)
    desc.Size = UDim2.new(1, -32, 0, 15)

    local line = Instance.new("Frame")
    line.BackgroundColor3 = Theme.line
    line.BackgroundTransparency = .5
    line.Position = UDim2.new(0, 14, 0, 57)
    line.Size = UDim2.new(1, -28, 0, 1)
    line.Parent = card

    local body = Instance.new("ScrollingFrame")
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Position = UDim2.new(0, 8, 0, 66)
    body.Size = UDim2.new(1, -16, 1, -74)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.CanvasSize = UDim2.new()
    body.ScrollBarThickness = 3
    body.ScrollBarImageColor3 = Theme.red
    body.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = body

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = body

    return card, body
end

local function makeRow(parent, height)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Theme.card
    row.Size = UDim2.new(1, 0, 0, height or 48)
    row.Parent = parent
    corner(row, 11)
    outline(row, Theme.line, .55, 1)
    return row
end

local function addToggle(parent, titleText, defaultValue, callback)
    local row = makeRow(parent, 48)
    local t = label(row, titleText, 11, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -82, 1, 0)

    local value = defaultValue == true
    local switch = Instance.new("TextButton")
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.BackgroundColor3 = Color3.fromRGB(56, 34, 40)
    switch.Position = UDim2.new(1, -60, .5, -12)
    switch.Size = UDim2.new(0, 47, 0, 24)
    switch.Parent = row
    corner(switch, 15)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Theme.muted
    knob.Position = UDim2.new(0, 3, .5, -9)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Parent = switch
    corner(knob, 20)

    local function render()
        switch.BackgroundColor3 = value and Theme.red or Color3.fromRGB(56, 34, 40)
        knob.Position = value and UDim2.new(1, -21, .5, -9) or UDim2.new(0, 3, .5, -9)
        knob.BackgroundColor3 = value and Color3.new(1,1,1) or Theme.muted
    end
    render()

    switch.MouseButton1Click:Connect(function()
        value = not value
        tween(switch, .16, {BackgroundColor3 = value and Theme.red or Color3.fromRGB(56, 34, 40)}):Play()
        tween(knob, .16, {
            Position = value and UDim2.new(1, -21, .5, -9) or UDim2.new(0, 3, .5, -9),
            BackgroundColor3 = value and Color3.new(1,1,1) or Theme.muted
        }):Play()
        callback(value)
    end)

    return function() return value end
end

local function addDropdown(parent, titleText, options, default, callback)
    local row = makeRow(parent, 54)

    local titleLabel = label(row, titleText, 10, true)
    titleLabel.Position = UDim2.new(0, 14, 0, 6)
    titleLabel.Size = UDim2.new(1, -28, 0, 16)
    titleLabel.TextColor3 = Theme.muted

    local index = table.find(options, default) or 1
    local valueBox = Instance.new("Frame")
    valueBox.BackgroundColor3 = Color3.fromRGB(35, 17, 22)
    valueBox.Position = UDim2.new(0, 12, 0, 26)
    valueBox.Size = UDim2.new(1, -24, 0, 22)
    valueBox.Parent = row
    corner(valueBox, 7)
    outline(valueBox, Theme.red, .78, 1)

    local selectedLabel = label(valueBox, tostring(options[index]), 9, true)
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Center
    selectedLabel.Size = UDim2.new(1, -54, 1, 0)
    selectedLabel.Position = UDim2.new(0, 27, 0, 0)

    local function arrow(symbol, x)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Text = symbol
        b.TextColor3 = Theme.red2
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.BackgroundTransparency = 1
        b.Position = UDim2.new(x, 0, 0, 0)
        b.Size = UDim2.new(0, 27, 1, 0)
        b.Parent = valueBox
        return b
    end

    local left = arrow("‹", 0)
    local right = arrow("›", 1)
    right.AnchorPoint = Vector2.new(1, 0)

    local function render()
        selectedLabel.Text = tostring(options[index])
        tween(valueBox, .12, {BackgroundColor3 = Color3.fromRGB(47, 20, 27)}):Play()
        task.delay(.13, function()
            if valueBox.Parent then tween(valueBox, .16, {BackgroundColor3 = Color3.fromRGB(35, 17, 22)}):Play() end
        end)
        callback(options[index])
    end

    left.MouseButton1Click:Connect(function()
        index = index - 1
        if index < 1 then index = #options end
        render()
    end)

    right.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        render()
    end)
end

local function addButton(parent, titleText, callback)
    local row = makeRow(parent, 48)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = ""
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Parent = row

    local t = label(b, titleText, 11, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -62, 1, 0)

    local arrow = label(b, "→", 17, true)
    arrow.TextColor3 = Theme.red2
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Position = UDim2.new(1, -45, 0, 0)
    arrow.Size = UDim2.new(0, 30, 1, 0)

    b.MouseEnter:Connect(function() tween(row, .15, {BackgroundColor3 = Theme.cardHover}):Play() end)
    b.MouseLeave:Connect(function() tween(row, .15, {BackgroundColor3 = Theme.card}):Play() end)
    b.MouseButton1Click:Connect(function() task.spawn(callback) end)
end

local OverviewCard = Instance.new("Frame")
OverviewCard.BackgroundColor3 = Theme.panel2
OverviewCard.Position = UDim2.new(0, 0, 0, 0)
OverviewCard.Size = UDim2.new(.38, -8, 1, 0)
OverviewCard.Parent = Content
corner(OverviewCard, 14)
outline(OverviewCard, Theme.line, .4, 1)

local overviewTitle = label(OverviewCard, "Overview", 16, true)
overviewTitle.Position = UDim2.new(0, 18, 0, 18)
overviewTitle.Size = UDim2.new(1, -36, 0, 22)

local overviewDesc = label(OverviewCard, "Monitor fruit activity and manage your active tools.", 10, false)
overviewDesc.TextColor3 = Theme.muted
overviewDesc.TextWrapped = true
overviewDesc.Position = UDim2.new(0, 18, 0, 45)
overviewDesc.Size = UDim2.new(1, -36, 0, 35)

local statCard = Instance.new("Frame")
statCard.BackgroundColor3 = Color3.fromRGB(29, 18, 23)
statCard.Position = UDim2.new(0, 18, 0, 100)
statCard.Size = UDim2.new(1, -36, 0, 100)
statCard.Parent = OverviewCard
corner(statCard, 13)
outline(statCard, Theme.red, .65, 1)

local statLabel = label(statCard, "FRUIT SCANNER", 8, true)
statLabel.TextColor3 = Theme.red2
statLabel.Position = UDim2.new(0, 15, 0, 14)
statLabel.Size = UDim2.new(1, -30, 0, 13)

local currentFruit = label(statCard, "Scanning workspace...", 13, true)
currentFruit.Position = UDim2.new(0, 15, 0, 36)
currentFruit.Size = UDim2.new(1, -30, 0, 21)

local scanStatus = label(statCard, "No fruit currently detected", 9, false)
scanStatus.TextColor3 = Theme.muted
scanStatus.Position = UDim2.new(0, 15, 0, 64)
scanStatus.Size = UDim2.new(1, -30, 0, 15)

local featuresTitle = label(OverviewCard, "ACTIVE MODULES", 9, true)
featuresTitle.TextColor3 = Theme.muted
featuresTitle.Position = UDim2.new(0, 18, 0, 224)
featuresTitle.Size = UDim2.new(1, -36, 0, 15)

local activeBox = Instance.new("Frame")
activeBox.BackgroundColor3 = Theme.card
activeBox.Position = UDim2.new(0, 18, 0, 248)
activeBox.Size = UDim2.new(1, -36, 0, 160)
activeBox.Parent = OverviewCard
corner(activeBox, 13)
outline(activeBox, Theme.line, .55, 1)

local activeCount = label(activeBox, "0 / 7 active", 12, true)
activeCount.Position = UDim2.new(0, 15, 0, 15)
activeCount.Size = UDim2.new(1, -30, 0, 20)

local activeDesc = label(activeBox, "Manage enabled tools from the control panels.", 9, false)
activeDesc.TextColor3 = Theme.muted
activeDesc.TextWrapped = true
activeDesc.Position = UDim2.new(0, 15, 0, 44)
activeDesc.Size = UDim2.new(1, -30, 0, 36)

local activeModules = {}
local function updateActive()
    local count = 0
    for _, v in pairs(activeModules) do if v then count += 1 end end
    activeCount.Text = string.format("%d / 10 active", count)
end

local function setModule(name, value)
    activeModules[name] = value
    updateActive()
end

local QuickCard, QuickBody = makeCard(Content, "Fruit Controls", "Collection and movement", UDim2.new(.39, 0, 0, 0), UDim2.new(.305, -8, 1, 0))
local ManageCard, ManageBody = makeCard(Content, "Inventory & Snipe", "Rarity and inventory management", UDim2.new(.695, 8, 0, 0), UDim2.new(.305, -8, 1, 0))

local RarityFruits = {
    Common = {"Rocket Fruit","Spin Fruit","Blade Fruit","Spring Fruit","Bomb Fruit","Smoke Fruit","Spike Fruit"},
    Uncommon = {"Flame Fruit","Falcon Fruit","Ice Fruit","Sand Fruit","Diamond Fruit","Dark Fruit"},
    Rare = {"Light Fruit","Rubber Fruit","Barrier Fruit","Ghost Fruit","Magma Fruit"},
    Legendary = {"Quake Fruit","Buddha Fruit","Love Fruit","Spider Fruit","Sound Fruit","Phoenix Fruit","Portal Fruit","Rumble Fruit","Pain Fruit","Blizzard Fruit"},
    Mythical = {"Gravity Fruit","Mammoth Fruit","T-Rex Fruit","Dough Fruit","Shadow Fruit","Venom Fruit","Control Fruit","Gas Fruit","Spirit Fruit","Leopard Fruit","Yeti Fruit","Kitsune Fruit","Dragon Fruit"}
}
local rarityOrder = {"Common","Uncommon","Rare","Legendary","Mythical"}
local rarityOptions = {"Common - Mythical","Uncommon - Mythical","Rare - Mythical","Legendary - Mythical","Mythical"}
local rarityMin = { ["Common - Mythical"] = 1, ["Uncommon - Mythical"] = 2, ["Rare - Mythical"] = 3, ["Legendary - Mythical"] = 4, ["Mythical"] = 5 }

local function fruitsAtRarity(selected)
    local result = {}
    local minIndex = rarityMin[selected] or 1
    for index, rarity in ipairs(rarityOrder) do
        if index >= minIndex then
            for _, fruit in ipairs(RarityFruits[rarity]) do
                table.insert(result, fruit)
            end
        end
    end
    return result
end

local function isFruit(obj)
    return obj and obj:IsA("Tool") and string.find(obj.Name, "Fruit") ~= nil
end

local function getFruitObjects()
    local results = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if isFruit(obj) then table.insert(results, obj) end
    end
    return results
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function tweenTo(cframe)
    local root = getRoot()
    if not root then return end
    local distance = (root.Position - cframe.Position).Magnitude
    local duration = math.clamp(distance / 280, .15, 4)
    local tw = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = cframe})
    tw:Play()
    return tw
end

local AutoBuyRandomFruit = Config.AutoBuyRandomFruit
local AutoEatFruit = Config.AutoEatFruit
local AutoStoreFruit = Config.AutoStoreFruit
local FruitNotification = Config.FruitNotification
local TeleportToFruit = Config.TeleportToFruit
local TweenToFruit = Config.TweenToFruit
local AutoSnipeFruit = Config.AutoSnipeFruit
local AutoGrabAll = Config.AutoGrabAll
local AutoServerHop = Config.AutoServerHop
local StoreRarity = Config.StoreRarity or rarityOptions[1]
local SnipeRarity = Config.SnipeRarity or rarityOptions[4]
local function syncConfig() saveConfig() end

addToggle(QuickBody, "Auto Buy Random Fruit", AutoBuyRandomFruit, function(v)
    AutoBuyRandomFruit = v
    Config.AutoBuyRandomFruit = v; syncConfig()
    setModule("buy", v)
end)

addToggle(QuickBody, "Fruit Spawn Notification", FruitNotification, function(v)
    FruitNotification = v
    Config.FruitNotification = v; syncConfig()
    setModule("notify", v)
end)

addToggle(QuickBody, "Teleport To Fruit", TeleportToFruit, function(v)
    TeleportToFruit = v
    Config.TeleportToFruit = v; syncConfig()
    setModule("teleport", v)
end)

addToggle(QuickBody, "Tween To Fruit", TweenToFruit, function(v)
    TweenToFruit = v
    Config.TweenToFruit = v; syncConfig()
    setModule("tween", v)
end)

addButton(QuickBody, "Grab All Fruits Now", function()
    local root = getRoot()
    if not root then return end
    local count = 0
    for _, fruit in ipairs(getFruitObjects()) do
        local handle = fruit:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            handle.CFrame = root.CFrame
            count += 1
        end
    end
    notify("Fruit Collection", count > 0 and ("Moved " .. count .. " fruit(s) to you") or "No fruits found", 3)
end)

addToggle(QuickBody, "Auto Grab All Fruits", AutoGrabAll, function(v)
    AutoGrabAll = v; Config.AutoGrabAll = v; syncConfig(); setModule("grab", v)
end)

addToggle(QuickBody, "Auto Server Hop", AutoServerHop, function(v)
    AutoServerHop = v; Config.AutoServerHop = v; syncConfig(); setModule("hop", v)
end)

addButton(ManageBody, "Save User Configuration", function()
    saveConfig(); notify("Configuration", "User settings saved successfully.", 3)
end)

addToggle(ManageBody, "Auto Eat Fruit", AutoEatFruit, function(v)
    AutoEatFruit = v
    Config.AutoEatFruit = v; syncConfig()
    setModule("eat", v)
end)

addDropdown(ManageBody, "Store Rarity", rarityOptions, StoreRarity, function(v)
    StoreRarity = v
    Config.StoreRarity = v; syncConfig()
end)

addToggle(ManageBody, "Auto Store Fruit", AutoStoreFruit, function(v)
    AutoStoreFruit = v
    Config.AutoStoreFruit = v; syncConfig()
    setModule("store", v)
end)

addDropdown(ManageBody, "Snipe Rarity", rarityOptions, SnipeRarity, function(v)
    SnipeRarity = v
    Config.SnipeRarity = v; syncConfig()
end)

addToggle(ManageBody, "Auto Snipe Fruit", AutoSnipeFruit, function(v)
    AutoSnipeFruit = v
    Config.AutoSnipeFruit = v; syncConfig()
    setModule("snipe", v)
end)

local lastNotified = {}

task.spawn(function()
    while task.wait(1) do
        local fruits = getFruitObjects()
        if #fruits > 0 then
            currentFruit.Text = fruits[1].Name
            scanStatus.Text = string.format("%d fruit(s) detected in workspace", #fruits)
        else
            currentFruit.Text = "No fruit detected"
            scanStatus.Text = "Scanner is monitoring the workspace"
        end
    end
end)

task.spawn(function()
    while task.wait(.8) do
        if AutoBuyRandomFruit then
            pcall(function() CommF_:InvokeServer("Cousin", "Buy") end)
        end
    end
end)

task.spawn(function()
    while task.wait(1.5) do
        if FruitNotification then
            for _, fruit in ipairs(getFruitObjects()) do
                if not lastNotified[fruit] then
                    lastNotified[fruit] = true
                    notify("Fruit Found", fruit.Name .. " detected on the map", 5)
                end
            end
            for fruit in pairs(lastNotified) do
                if not fruit or not fruit.Parent then lastNotified[fruit] = nil end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(.25) do
        if TeleportToFruit then
            local root = getRoot()
            if root then
                for _, fruit in ipairs(getFruitObjects()) do
                    local handle = fruit:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        root.CFrame = handle.CFrame
                        task.wait(.15)
                        break
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(.8) do
        if TweenToFruit then
            for _, fruit in ipairs(getFruitObjects()) do
                local handle = fruit:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    tweenTo(handle.CFrame)
                    break
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(.8) do
        if AutoEatFruit then
            pcall(function()
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if backpack and char and humanoid then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if isFruit(tool) then
                            humanoid:EquipTool(tool)
                            task.wait(.2)
                            CommF_:InvokeServer("EatFruit", tool.Name)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

local function tryStoreAvailableFruit()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    local valid = {}
    for _, name in ipairs(fruitsAtRarity(StoreRarity)) do valid[name] = true end
    for _, tool in ipairs(backpack:GetChildren()) do
        if valid[tool.Name] and isFruit(tool) then
            local short = tool.Name:gsub(" Fruit", "")
            local ok = pcall(function()
                CommF_:InvokeServer("StoreFruit", short .. "-" .. short, tool)
            end)
            task.wait(.25)
            if ok and not tool.Parent then return true end
        end
    end
    return false
end

task.spawn(function()
    while task.wait(1) do
        if AutoStoreFruit then
            tryStoreAvailableFruit()
        end
    end
end)

task.spawn(function()
    while task.wait(.5) do
        if AutoSnipeFruit then
            pcall(function()
                local valid = {}
                for _, name in ipairs(fruitsAtRarity(SnipeRarity)) do valid[name] = true end
                local root = getRoot()
                if not root then return end
                for _, fruit in ipairs(getFruitObjects()) do
                    if valid[fruit.Name] then
                        local handle = fruit:FindFirstChild("Handle")
                        if handle and handle:IsA("BasePart") then
                            root.CFrame = handle.CFrame
                            task.wait(.12)
                            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                fruit.Parent = LocalPlayer.Backpack
                                humanoid:EquipTool(fruit)
                            end
                            notify("Fruit Sniped", "Collected: " .. fruit.Name, 4)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

 task.spawn(function()
    while task.wait(.75) do
        if AutoGrabAll then
            local root = getRoot()
            if root then
                for _, fruit in ipairs(getFruitObjects()) do
                    local handle = fruit:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then handle.CFrame = root.CFrame end
                end
            end
        end
    end
end)

local emptyScans = 0
local resettingForHop = false

local function resetCharacterForHop()
    if resettingForHop then return end
    resettingForHop = true
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    task.wait(3)
    resettingForHop = false
end

local hopCandidates = {}
local hopIndex = 0
local hopInProgress = false
local hopRetryToken = 0
local hopToAnotherServer

local function fetchHopCandidates()
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if not ok or type(servers) ~= "table" then return false end

    hopCandidates = {}
    local seen = {[game.JobId] = true}
    for _, server in ipairs(servers.data or {}) do
        if server.id and not seen[server.id] and server.playing < server.maxPlayers then
            seen[server.id] = true
            table.insert(hopCandidates, server.id)
        end
    end

    -- Shuffle so a failed/restricted server is not repeatedly selected first.
    for i = #hopCandidates, 2, -1 do
        local j = math.random(i)
        hopCandidates[i], hopCandidates[j] = hopCandidates[j], hopCandidates[i]
    end

    hopIndex = 0
    return #hopCandidates > 0
end

local function tryNextHopCandidate()
    if not AutoServerHop or not hopInProgress then return false end

    hopIndex += 1
    local serverId = hopCandidates[hopIndex]
    if not serverId then
        hopInProgress = false
        notify("Server Hop", "No other available servers found. Retrying server list...", 3)
        task.delay(2, function()
            if AutoServerHop then hopToAnotherServer() end
        end)
        return false
    end

    notify("Server Hop", "Trying a different server...", 2)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)

    if not ok then
        -- If the teleport call itself errors, immediately skip this server.
        task.defer(tryNextHopCandidate)
        return false
    end

    return true
end

hopToAnotherServer = function()
    if hopInProgress then return true end
    if not fetchHopCandidates() then return false end

    hopInProgress = true
    hopRetryToken += 1
    return tryNextHopCandidate()
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player ~= LocalPlayer or not hopInProgress then return end

    -- Restricted/unavailable/full servers can fail here even though the teleport
    -- call itself did not throw. Mark that server as bad and immediately try the next one.
    if teleportResult == Enum.TeleportResult.Flooded
        or teleportResult == Enum.TeleportResult.Failure
        or teleportResult == Enum.TeleportResult.GameEnded
        or teleportResult == Enum.TeleportResult.GameFull
        or teleportResult == Enum.TeleportResult.Unauthorized
        or teleportResult == Enum.TeleportResult.IsTeleporting then
        task.delay(.15, function()
            if hopInProgress and AutoServerHop then
                tryNextHopCandidate()
            end
        end)
    else
        task.delay(.15, function()
            if hopInProgress and AutoServerHop then
                tryNextHopCandidate()
            end
        end)
    end
end)


task.spawn(function()
    while task.wait(1) do
        if not AutoServerHop then
            emptyScans = 0
        elseif #getFruitObjects() == 0 then
            emptyScans += 1
            if emptyScans >= 1 then
                emptyScans = 0
                notify("Server Hop", "No fruits found. Processing inventory...", 2)
                if AutoStoreFruit then
                    local storedAny = false
                    while tryStoreAvailableFruit() do
                        storedAny = true
                        task.wait(.35)
                    end
                    if storedAny then task.wait(.75) end
                end
                if #getFruitObjects() == 0 then
                    notify("Resetting", "Inventory processed. Resetting before server hop...", 2)
                    resetCharacterForHop()
                    task.wait(2)
                end
                notify("Server Hop", "Moving to another server...", 2)
                hopToAnotherServer()
            end
        else
            emptyScans = 0
        end
    end
end)

local glow = Instance.new("Frame")
glow.Name = "Glow"
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glow.BackgroundTransparency = 0.82
glow.Size = UDim2.new(0, 58, 0, 58)
glow.Position = UDim2.new(0, 18 + 24, 0.5, 0)
glow.ZIndex = 18
glow.Parent = Screen
corner(glow, 999)

local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Color3.fromRGB(255, 255, 255)
glowStroke.Thickness = 1
glowStroke.Transparency = 0.75
glowStroke.Parent = glow

local floating = Instance.new("TextButton")
floating.Name = "XLauncher"
floating.AnchorPoint = Vector2.new(0.5, 0.5)
floating.Text = "X"
floating.TextColor3 = Color3.fromRGB(255, 255, 255)
floating.Font = Enum.Font.GothamBold
floating.TextSize = 22
floating.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
floating.Size = UDim2.new(0, 48, 0, 48)
floating.Position = UDim2.new(0, 18 + 24, 0.5, 0)
floating.ZIndex = 20
floating.AutoButtonColor = false
floating.Parent = Screen
corner(floating, 999)

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(255, 255, 255)
floatStroke.Thickness = 2
floatStroke.Transparency = 0.15
floatStroke.Parent = floating

task.spawn(function()
    while floating.Parent do
        tween(glow, 1.1, {
            Size = UDim2.new(0, 70, 0, 70),
            BackgroundTransparency = 0.94
        }):Play()
        tween(glowStroke, 1.1, {Transparency = 0.9}):Play()
        task.wait(1.1)

        tween(glow, 1.1, {
            Size = UDim2.new(0, 58, 0, 58),
            BackgroundTransparency = 0.82
        }):Play()
        tween(glowStroke, 1.1, {Transparency = 0.75}):Play()
        task.wait(1.1)
    end
end)

floating.MouseEnter:Connect(function()
    tween(floating, 0.4, {Rotation = 90}):Play()
    tween(floatStroke, 0.2, {Transparency = 0}):Play()
    tween(glowStroke, 0.2, {Transparency = 0.45}):Play()
end)

floating.MouseLeave:Connect(function()
    tween(floating, 0.4, {Rotation = 0}):Play()
    tween(floatStroke, 0.2, {Transparency = 0.15}):Play()
    tween(glowStroke, 0.2, {Transparency = 0.75}):Play()
end)

local floatingDragging, floatingStart, floatingPos, floatingMoved = false, nil, nil, false
local clicked = false

floating.MouseButton1Click:Connect(function()
    if clicked then return end
    clicked = true
    tween(floating, 0.1, {Size = UDim2.new(0, 40, 0, 40)}, Enum.EasingStyle.Quad):Play()
    task.wait(0.1)
    tween(floating, 0.25, {Size = UDim2.new(0, 52, 0, 52)}, Enum.EasingStyle.Back):Play()
    task.wait(0.12)
    tween(floating, 0.15, {Size = UDim2.new(0, 48, 0, 48)}, Enum.EasingStyle.Quad):Play()
    clicked = false
end)

local function updatePositions(pos)
    floating.Position = pos
    glow.Position = pos
end

floating.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatingDragging = true
        floatingMoved = false
        floatingStart = input.Position
        floatingPos = floating.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if floatingDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - floatingStart
        if delta.Magnitude > 3 then floatingMoved = true end
        local newPos = UDim2.new(
            floatingPos.X.Scale, floatingPos.X.Offset + delta.X,
            floatingPos.Y.Scale, floatingPos.Y.Offset + delta.Y
        )
        updatePositions(newPos)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if floatingDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        floatingDragging = false
    end
end)

minimized = true
Main.Visible = false
floating.Visible = true
glow.Visible = true

minimizeButton.MouseButton1Click:Connect(function()
    minimized = true
    Main.Visible = false
    floating.Visible = true
    glow.Visible = true
end)

floating.MouseButton1Click:Connect(function()
    if floatingMoved then return end
    minimized = false
    Main.Visible = true
    floating.Visible = false
    glow.Visible = false
end)

closeButton.MouseButton1Click:Connect(function()
    saveConfig(); Screen:Destroy()
end)

local footer = label(Main, "PRXDIGY HUB  •  FRUIT TOOLS", 8, true)
footer.TextColor3 = Theme.muted
footer.Position = UDim2.new(0, 24, 1, -31)
footer.Size = UDim2.new(1, -48, 0, 16)
footer.TextXAlignment = Enum.TextXAlignment.Center

local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Startup notification removed
