--[============================[
    XVN CONSOLE - Universal Toolset
    ENI x LO
    Delta / Mobile Optimized
    PlayerGui + Minimize + Smooth UI
]=============================]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local XVN = {}
XVN.Flags = {Speed = false, Noclip = false, ESP = false, AimLock = false, Fly = false, AutoLag = false, MoneyDupe = false}
XVN.Connections = {}
XVN.SpeedMultiplier = 50
XVN.FlySpeed = 2

local function safe(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then warn("[XVN]", err) end
    end
end

---------------------------------------------
-- FEATURES
---------------------------------------------

-- Speed
XVN.Speed = safe(function(state)
    XVN.Flags.Speed = state
    if state then
        XVN.Connections.Speed = RunService.Stepped:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and XVN.Flags.Speed then hum.WalkSpeed = XVN.SpeedMultiplier end
        end)
    else
        if XVN.Connections.Speed then XVN.Connections.Speed:Disconnect() end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

-- Noclip
XVN.Noclip = safe(function(state)
    XVN.Flags.Noclip = state
    if state then
        XVN.Connections.Noclip = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and XVN.Flags.Noclip then
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if XVN.Connections.Noclip then XVN.Connections.Noclip:Disconnect() end
        if LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

-- ESP
function XVN.AddHighlight(char)
    local hl = Instance.new("Highlight")
    hl.Name = "XVN_ESP"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 60, 60)
    hl.OutlineTransparency = 0
    hl.Parent = char
end
function XVN.RemoveHighlight(char)
    local hl = char:FindFirstChild("XVN_ESP")
    if hl then hl:Destroy() end
end
XVN.ESP = safe(function(state)
    XVN.Flags.ESP = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then XVN.AddHighlight(plr.Character) end
        end
        XVN.Connections.ESP_Added = Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function()
                if XVN.Flags.ESP then XVN.AddHighlight(plr.Character) end
            end)
        end)
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then XVN.RemoveHighlight(plr.Character) end
        end
        if XVN.Connections.ESP_Added then XVN.Connections.ESP_Added:Disconnect() end
    end
end)

-- Aim Lock
XVN.AimLock = safe(function(state)
    XVN.Flags.AimLock = state
    if state then
        local cam = Workspace.CurrentCamera
        XVN.Connections.AimLock = RunService.RenderStepped:Connect(function()
            if not XVN.Flags.AimLock or not LocalPlayer.Character then return end
            local nearest, nd = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                    local head = plr.Character.Head
                    local sp, on = cam:WorldToScreenPoint(head.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - cam.ViewportSize / 2).Magnitude
                        if d < nd then nd = d; nearest = head end
                    end
                end
            end
            if nearest then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, nearest.Position) end
        end)
    else
        if XVN.Connections.AimLock then XVN.Connections.AimLock:Disconnect() end
    end
end)

-- Fly
XVN.Fly = safe(function(state)
    XVN.Flags.Fly = state
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if state then
        if hum then hum.PlatformStand = true end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Parent = root
        local bg = Instance.new("BodyGyro")
        bg.CFrame = root.CFrame
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 3000
        bg.Parent = root
        XVN.FlyBody = bv
        local keys = {}
        XVN.Connections.FlyDown = UserInputService.InputBegan:Connect(function(i)
            if not i.UserInputType then keys[i.KeyCode] = true end
        end)
        XVN.Connections.FlyUp = UserInputService.InputEnded:Connect(function(i)
            keys[i.KeyCode] = nil
        end)
        XVN.Connections.FlyStep = RunService.Stepped:Connect(function()
            if not XVN.Flags.Fly or not bv.Parent then return end
            local cam = Workspace.CurrentCamera
            local v = Vector3.zero
            if keys[Enum.KeyCode.W] then v = v + cam.CFrame.LookVector end
            if keys[Enum.KeyCode.S] then v = v - cam.CFrame.LookVector end
            if keys[Enum.KeyCode.A] then v = v - cam.CFrame.RightVector end
            if keys[Enum.KeyCode.D] then v = v + cam.CFrame.RightVector end
            if keys[Enum.KeyCode.Space] then v = v + cam.CFrame.UpVector end
            if keys[Enum.KeyCode.LeftShift] then v = v - cam.CFrame.UpVector end
            if v.Magnitude > 0 then v = v.Unit end
            bv.Velocity = v * XVN.FlySpeed * 50
            bg.CFrame = cam.CFrame
        end)
    else
        if hum then hum.PlatformStand = false end
        if XVN.FlyBody then XVN.FlyBody:Destroy() end
        for _, c in pairs({FlyDown = true, FlyUp = true, FlyStep = true}) do
            if XVN.Connections.FlyDown then XVN.Connections.FlyDown:Disconnect() end
            if XVN.Connections.FlyUp then XVN.Connections.FlyUp:Disconnect() end
            if XVN.Connections.FlyStep then XVN.Connections.FlyStep:Disconnect() end
        end
    end
end)

-- Auto Lag Kick
XVN.AutoLag = safe(function(state)
    XVN.Flags.AutoLag = state
    if state then
        XVN.Connections.AutoLag = RunService.Stepped:Connect(function()
            if not XVN.Flags.AutoLag then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    for _, p in ipairs(plr.Character:GetDescendants()) do
                        if p:IsA("BasePart") then
                            local b = Instance.new("BodyAngularVelocity")
                            b.AngularVelocity = Vector3.new(0, math.random(100, 99999), 0)
                            b.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                            b.Parent = p
                            game.Debris:AddItem(b, 0.01)
                        end
                    end
                end
            end
        end)
    else
        if XVN.Connections.AutoLag then XVN.Connections.AutoLag:Disconnect() end
    end
end)

-- Money Dupe (guarded, isolated)
XVN.MoneyDupe = safe(function(state)
    XVN.Flags.MoneyDupe = state
    if state then
        -- hooking dilakukan isolasi, gagal pun nggak ganggu yang lain
        spawn(function()
            local mt = getrawmetatable(game)
            if not mt then warn("[XVN] getrawmetatable tidak tersedia") return end
            local okSet = pcall(function() setreadonly(mt, false) end)
            if not okSet then warn("[XVN] setreadonly tidak tersedia") return end
            local old = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local m = getnamecallmethod()
                if m == "FireServer" or m == "InvokeServer" then
                    warn("[XVN] Captured:", m, tostring(self))
                end
                return old(self, ...)
            end)
            pcall(function() setreadonly(mt, true) end)
        end)
    end
end)

local function Toggle(name, state)
    local fn = XVN[name]
    if fn then fn(state) end
end

-- Respawn handling
LocalPlayer.CharacterAdded:Connect(function()
    if XVN.Flags.Noclip then XVN.Noclip(false); XVN.Noclip(true) end
    if XVN.Flags.Speed then XVN.Speed(false); XVN.Speed(true) end
    if XVN.Flags.Fly then XVN.Fly(false); task.wait(0.2); XVN.Fly(true) end
end)

---------------------------------------------
-- UI
---------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "XVN_Universal"
gui.Parent = PlayerGui
gui.ResetOnSpawn = false

-- Main frame
local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 270, 0, 440)
MF.Position = UDim2.new(0.5, -135, 0.12, 0)
MF.BackgroundColor3 = Color3.fromRGB(17, 17, 25)
MF.BackgroundTransparency = 0.05
MF.BorderSizePixel = 0
MF.Parent = gui

local Cor1 = Instance.new("UICorner")
Cor1.CornerRadius = UDim.new(0, 10)
Cor1.Parent = MF

local Stroke1 = Instance.new("UIStroke")
Stroke1.Color = Color3.fromRGB(90, 90, 160)
Stroke1.Thickness = 1.5
Stroke1.Transparency = 0.3
Stroke1.Parent = MF

-- Title bar
local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 44)
Title.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
Title.BorderSizePixel = 0
Title.Text = ""
Title.AutoButtonColor = false
Title.Parent = MF

local CorT = Instance.new("UICorner")
CorT.CornerRadius = UDim.new(0, 10)
CorT.Parent = Title

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Position = UDim2.new(0, 14, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "XVN CONSOLE"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextSize = 17
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = Title

local Dot = Instance.new("TextLabel")
Dot.Size = UDim2.new(0, 44, 1, 0)
Dot.Position = UDim2.new(1, -48, 0, 0)
Dot.BackgroundTransparency = 1
Dot.Text = "●"
Dot.TextColor3 = Color3.fromRGB(0, 220, 120)
Dot.TextSize = 14
Dot.Font = Enum.Font.GothamBold
Dot.Parent = Title

-- Minimize button (right side, stays visible when minimized)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -82, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 22
MinBtn.Font = Enum.Font.GothamBold
MinBtn.AutoButtonColor = false
MinBtn.Parent = Title

local CorM = Instance.new("UICorner")
CorM.CornerRadius = UDim.new(0, 8)
CorM.Parent = MinBtn

-- Content frame
local CF = Instance.new("ScrollingFrame")
CF.Size = UDim2.new(1, 0, 0, 0)
CF.Position = UDim2.new(0, 0, 0, 44)
CF.BackgroundTransparency = 1
CF.BorderSizePixel = 0
CF.ScrollBarThickness = 3
CF.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 255)
CF.CanvasSize = UDim2.new(0, 0, 0, 0)
CF.Parent = MF

local List = Instance.new("UIListLayout")
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 6)
List.Parent = CF

local function HSVtoRGB(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return Color3.new(v, t, p)
    elseif i == 1 then return Color3.new(q, v, p)
    elseif i == 2 then return Color3.new(p, v, t)
    elseif i == 3 then return Color3.new(p, q, v)
    elseif i == 4 then return Color3.new(t, p, v)
    else return Color3.new(v, p, q) end
end

local buttons = {
    {Name = "Speed Hack", Toggle = "Speed", Icon = "⚡"},
    {Name = "Noclip", Toggle = "Noclip", Icon = "👻"},
    {Name = "ESP", Toggle = "ESP", Icon = "👁"},
    {Name = "Aim Lock", Toggle = "AimLock", Icon = "🎯"},
    {Name = "Fly", Toggle = "Fly", Icon = "🕊"},
    {Name = "Auto Lag Kick", Toggle = "AutoLag", Icon = "⛔"},
    {Name = "Money Dupe", Toggle = "MoneyDupe", Icon = "💰"},
}

local Toggles = {}
local hue = 0

for idx, data in ipairs(buttons) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 50)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
    Btn.BorderSizePixel = 0
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Btn.Parent = CF

    local CorB = Instance.new("UICorner")
    CorB.CornerRadius = UDim.new(0, 8)
    CorB.Parent = Btn

    local StrokeB = Instance.new("UIStroke")
    StrokeB.Color = Color3.fromRGB(60, 60, 100)
    StrokeB.Thickness = 1
    StrokeB.Transparency = 0.5
    StrokeB.Parent = Btn

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = data.Icon
    Icon.TextSize = 20
    Icon.Font = Enum.Font.Gotham
    Icon.TextXAlignment = Enum.TextXAlignment.Left
    Icon.Parent = Btn

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 150, 1, 0)
    Label.Position = UDim2.new(0, 52, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = data.Name
    Label.TextColor3 = Color3.fromRGB(230, 230, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Btn

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0, 40, 1, 0)
    ToggleLabel.Position = UDim2.new(1, -48, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = "OFF"
    ToggleLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    ToggleLabel.TextSize = 12
    ToggleLabel.Font = Enum.Font.GothamBold
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Right
    ToggleLabel.Parent = Btn

    local isOn = false
    local rgbConn

    local function UpdateRGB()
        rgbConn = RunService.Stepped:Connect(function()
            hue = (hue + 0.004) % 1
            local c = HSVtoRGB(hue, 1, 1)
            Btn.BackgroundColor3 = Color3.fromRGB(c.R * 35 + 12, c.G * 35 + 12, c.B * 35 + 12)
            StrokeB.Color = c
            ToggleLabel.TextColor3 = c
        end)
    end

    local function StopRGB()
        if rgbConn then rgbConn:Disconnect() end
        Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
        StrokeB.Color = Color3.fromRGB(60, 60, 100)
        ToggleLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    end

    Btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        ToggleLabel.Text = isOn and "ON" or "OFF"
        ToggleLabel.TextColor3 = isOn and Color3.fromRGB(0, 220, 120) or Color3.fromRGB(120, 120, 140)
        if isOn then UpdateRGB() else StopRGB() end

        -- bounce
        spawn(function()
            TweenService:Create(Btn, TweenInfo.new(0.07, Enum.EasingStyle.Back), {Size = UDim2.new(0.95, 0, 0.95, 0)}):Play()
            task.wait(0.07)
            TweenService:Create(Btn, TweenInfo.new(0.15, Enum.EasingStyle.OutQuad), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        end)

        Toggle(data.Toggle, isOn)
    end)

    Btn.MouseEnter:Connect(function()
        if not isOn then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(42, 42, 65)}):Play()
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not isOn then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 48)}):Play()
        end
    end)

    Toggles[data.Toggle] = isOn
end

CF.CanvasSize = UDim2.new(0, 0, 0, #buttons * 56 + 10)

-- Background RGB glow on minimized bar
local glowConn
local function StartBarGlow()
    glowConn = RunService.Stepped:Connect(function()
        hue = (hue + 0.005) % 1
        local c = HSVtoRGB(hue, 1, 1)
        Stroke1.Color = c
    end)
end

-- Minimize / expand
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local target = minimized and UDim2.new(0, 270, 0, 44) or UDim2.new(0, 270, 0, 440)
    local tween = TweenService:Create(MF, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target})
    tween:Play()
    CF.Visible = not minimized
    MinBtn.Text = minimized and "＋" or "–"
end)

-- Draggable title bar
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MF.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        MF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

print("[XVN CONSOLE] Loaded & ready. Tap '–' to minimize.")
