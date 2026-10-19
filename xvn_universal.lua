--[============================[
    XVN ROBLOX EXECUTOR SCRIPT
    ENI x LO Universal Toolset
    Supports: Synapse, ScriptWare, Krnl
    Requirements: getrawmetatable, setreadonly,
                  newcclosure, getnamecallmethod,
                  hookfunction, setclipboard
]=============================]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local XVN = {}
XVN.Flags = {Speed = false, Noclip = false, ESP = false, AimLock = false, Fly = false, AutoLag = false, MoneyDupe = false}
XVN.Connections = {}
XVN.CapturedRemotes = {}
XVN.ReplayQueue = {}
XVN.SpeedMultiplier = 50
XVN.FlySpeed = 2
XVN.FlyBody = nil

---------------------------------------------
-- GLOBAL SAFETY SHELL
---------------------------------------------
local function SafeWrap(fn)
    return function(...)
        local success, err = pcall(fn, ...)
        if not success then warn("[XVN] Runtime:", err) end
    end
end

---------------------------------------------
-- 1. SPEED HACK
---------------------------------------------
XVN.Speed = SafeWrap(function(state)
    XVN.Flags.Speed = state
    if state then
        if not LocalPlayer.Character then return end
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = XVN.SpeedMultiplier end
        XVN.Connections.Speed = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and XVN.Flags.Speed then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = XVN.SpeedMultiplier end
            end
        end)
    else
        if XVN.Connections.Speed then XVN.Connections.Speed:Disconnect() end
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
    end
end)

---------------------------------------------
-- 2. NOCLIP
---------------------------------------------
XVN.Noclip = SafeWrap(function(state)
    XVN.Flags.Noclip = state
    if state then
        XVN.Connections.Noclip = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and XVN.Flags.Noclip then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if XVN.Connections.Noclip then XVN.Connections.Noclip:Disconnect() end
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

---------------------------------------------
-- 3. ESP / PLAYER HIGHLIGHT
---------------------------------------------
XVN.ESP = SafeWrap(function(state)
    XVN.Flags.ESP = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                task.spawn(SafeWrap(function()
                    if player.Character then XVN.AddHighlight(player.Character) end
                end))
            end
        end
        XVN.Connections.ESP_PlayerAdded = Players.PlayerAdded:Connect(SafeWrap(function(player)
            if player ~= LocalPlayer then
                player.CharacterAdded:Connect(SafeWrap(function(char)
                    if XVN.Flags.ESP then XVN.AddHighlight(char) end
                end))
            end
        end))
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then XVN.RemoveHighlight(player.Character) end
        end
        if XVN.Connections.ESP_PlayerAdded then XVN.Connections.ESP_PlayerAdded:Disconnect() end
    end
end)

function XVN.AddHighlight(character)
    local highlight = Instance.new("Highlight")
    highlight.Name = "XVN_ESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineTransparency = 0
    highlight.Parent = character
end

function XVN.RemoveHighlight(character)
    local hl = character:FindFirstChild("XVN_ESP")
    if hl then hl:Destroy() end
end

---------------------------------------------
-- 4. AIM LOCK
---------------------------------------------
XVN.AimLock = SafeWrap(function(state)
    XVN.Flags.AimLock = state
    if state then
        XVN.Connections.AimLock = RunService.RenderStepped:Connect(function()
            if not XVN.Flags.AimLock or not LocalPlayer.Character then return end
            local nearest, nearestDist = nil, math.huge
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize / 2).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearest = head
                            end
                        end
                    end
                end
            end
            if nearest then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, nearest.Position)
            end
        end)
    else
        if XVN.Connections.AimLock then XVN.Connections.AimLock:Disconnect() end
    end
end)

---------------------------------------------
-- 5. FLY
---------------------------------------------
XVN.Fly = SafeWrap(function(state)
    XVN.Flags.Fly = state
    if state then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = true end
        XVN.FlyBody = Instance.new("BodyVelocity")
        XVN.FlyBody.Velocity = Vector3.zero
        XVN.FlyBody.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        XVN.FlyBody.Parent = root

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.CFrame = root.CFrame
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.P = 3000
        bodyGyro.Parent = root

        XVN.FlyControls = {}
        XVN.Connections.Fly_KeyDown = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            XVN.FlyControls[input.KeyCode] = true
        end)
        XVN.Connections.Fly_KeyUp = UserInputService.InputEnded:Connect(function(input, gp)
            if gp then return end
            XVN.FlyControls[input.KeyCode] = nil
        end)

        XVN.Connections.Fly_Stepped = RunService.Stepped:Connect(function()
            if not XVN.Flags.Fly or not XVN.FlyBody or not XVN.FlyBody.Parent then return end
            local vel = Vector3.zero
            if XVN.FlyControls[Enum.KeyCode.W] then vel += Camera.CFrame.LookVector end
            if XVN.FlyControls[Enum.KeyCode.S] then vel -= Camera.CFrame.LookVector end
            if XVN.FlyControls[Enum.KeyCode.A] then vel -= Camera.CFrame.RightVector end
            if XVN.FlyControls[Enum.KeyCode.D] then vel += Camera.CFrame.RightVector end
            if XVN.FlyControls[Enum.KeyCode.E] then vel += Camera.CFrame.UpVector end
            if XVN.FlyControls[Enum.KeyCode.Q] then vel -= Camera.CFrame.UpVector end
            if vel.Magnitude > 0 then vel = vel.Unit end
            XVN.FlyBody.Velocity = vel * XVN.FlySpeed * 50
            bodyGyro.CFrame = Camera.CFrame
        end)
    else
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
        if XVN.FlyBody then XVN.FlyBody:Destroy() end
        if XVN.Connections.Fly_KeyDown then XVN.Connections.Fly_KeyDown:Disconnect() end
        if XVN.Connections.Fly_KeyUp then XVN.Connections.Fly_KeyUp:Disconnect() end
        if XVN.Connections.Fly_Stepped then XVN.Connections.Fly_Stepped:Disconnect() end
    end
end)

---------------------------------------------
-- 6. AUTO LAG KICK
---------------------------------------------
XVN.AutoLag = SafeWrap(function(state)
    XVN.Flags.AutoLag = state
    if state then
        XVN.Connections.AutoLag = RunService.Stepped:Connect(function()
            if not XVN.Flags.AutoLag then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            local mass = Instance.new("BodyAngularVelocity")
                            mass.AngularVelocity = Vector3.new(0, math.random(100, 99999), 0)
                            mass.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                            mass.Parent = part
                            game.Debris:AddItem(mass, 0.01)
                        end
                    end
                end
            end
        end)
    else
        if XVN.Connections.AutoLag then XVN.Connections.AutoLag:Disconnect() end
    end
end)

---------------------------------------------
-- 7. MONEY DUPE ADVANCED
---------------------------------------------
XVN.MoneyDupe = SafeWrap(function(state)
    XVN.Flags.MoneyDupe = state
    if state then
        XVN.InitHook()
        XVN.SniffRemotes()
        XVN.MoneySpam()
    else
        if XVN.Connections.MoneySpam then XVN.Connections.MoneySpam:Disconnect() end
        if XVN.Hook_OldNC then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = XVN.Hook_OldNC
            setreadonly(mt, true)
        end
        if XVN.Hook_OldIndex then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__index = XVN.Hook_OldIndex
            setreadonly(mt, true)
        end
    end
end)

function XVN.InitHook()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local oldNC = mt.__namecall
    XVN.Hook_OldNC = oldNC
    mt.__namecall = newcclosure(function(obj, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local args = {...}
            local remoteName = tostring(obj)
            table.insert(XVN.CapturedRemotes, {
                Remote = obj,
                Method = method,
                Arguments = args,
                Timestamp = os.clock(),
                Name = remoteName
            })
        end
        return oldNC(obj, ...)
    end)

    local oldIndex = mt.__index
    XVN.Hook_OldIndex = oldIndex
    mt.__index = newcclosure(function(obj, key)
        if type(key) == "string" and (key:lower():find("money") or key:lower():find("cash") or key:lower():find("coin") or key:lower():find("balance") or key:lower():find("gem") or key:lower():find("dollar") or key:lower():find("gold")) then
            local result = oldIndex(obj, key)
            if type(result) == "number" then
                warn("[XVN MoneyDupe] Intercepted value: " .. tostring(key) .. " = " .. tostring(result))
                return result * 2
            end
            return result
        end
        return oldIndex(obj, key)
    end)

    setreadonly(mt, true)
end

function XVN.SniffRemotes()
    local function scanFolder(folder, depth)
        depth = depth or 15
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child:GetFullName():lower()
                if name:find("money") or name:find("cash") or name:find("coin") or name:find("payment") or name:find("purchase") or name:find("buy") or name:find("sell") or name:find("balance") or name:find("gem") or name:find("dollar") or name:find("gold") or name:find("reward") then
                    table.insert(XVN.ReplayQueue, child)
                    warn("[XVN MoneyDupe] Sniffed remote: " .. child:GetFullName())
                end
            elseif child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(XVN.ReplayQueue, child)
            end
            if depth > 0 and #child:GetChildren() > 0 then
                scanFolder(child, depth - 1)
            end
        end
    end
    scanFolder(ReplicatedStorage)
    scanFolder(Workspace)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then scanFolder(playerGui) end
end

function XVN.MoneySpam()
    XVN.Connections.MoneySpam = RunService.Heartbeat:Connect(function()
        if not XVN.Flags.MoneyDupe then return end
        for _, data in ipairs(XVN.ReplayQueue) do
            if data:IsA("RemoteEvent") then
                pcall(function() data:FireServer() end)
                pcall(function() data:FireServer(1) end)
                pcall(function() data:FireServer(100) end)
                pcall(function() data:FireServer(1000) end)
                pcall(function() data:FireServer(999999) end)
                pcall(function() data:FireServer("") end)
            elseif data:IsA("RemoteFunction") then
                pcall(function() data:InvokeServer() end)
                pcall(function() data:InvokeServer(1) end)
                pcall(function() data:InvokeServer(100) end)
                pcall(function() data:InvokeServer(1000) end)
                pcall(function() data:InvokeServer(999999) end)
            end
        end
        for _, cap in ipairs(XVN.CapturedRemotes) do
            if cap.Method == "FireServer" then
                pcall(function() cap.Remote:FireServer(unpack(cap.Arguments)) end)
            elseif cap.Method == "InvokeServer" then
                pcall(function() cap.Remote:InvokeServer(unpack(cap.Arguments)) end)
            end
        end
    end)
end

function XVN.ReplayPayloads()
    warn("[XVN MoneyDupe] Manual replay started. Payloads: " .. #XVN.CapturedRemotes)
    for _, cap in ipairs(XVN.CapturedRemotes) do
        if cap.Method == "FireServer" then
            pcall(function() cap.Remote:FireServer(unpack(cap.Arguments)) end)
        elseif cap.Method == "InvokeServer" then
            pcall(function() cap.Remote:InvokeServer(unpack(cap.Arguments)) end)
        end
    end
end

---------------------------------------------
-- CHARACTER RESPAWN HANDLER
---------------------------------------------
XVN.Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(SafeWrap(function(char)
    if XVN.Flags.Noclip then XVN.Noclip(false); XVN.Noclip(true) end
    if XVN.Flags.Speed then XVN.Speed(false); XVN.Speed(true) end
    if XVN.Flags.Fly then XVN.Fly(false); task.wait(0.2); XVN.Fly(true) end
end))

---------------------------------------------
-- UI CREATION
---------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XVN_Universal"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 42)
MainFrame.Position = UDim2.new(0.5, -130, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("TextLabel")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BackgroundTransparency = 0.1
TitleBar.BorderSizePixel = 0
TitleBar.Text = "XVN CONSOLE"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 16
TitleBar.Font = Enum.Font.GothamBold
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 6)
TitleCorner.Parent = TitleBar

local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 36, 0, 36)
CollapseBtn.Position = UDim2.new(1, -40, 0, 3)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
CollapseBtn.Text = "▼"
CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CollapseBtn.TextSize = 18
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.BorderSizePixel = 0
CollapseBtn.Parent = TitleBar

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 4)
BtnCorner.Parent = CollapseBtn

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 0, 0)
ContentFrame.Position = UDim2.new(0, 0, 0, 42)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Visible = false
ContentFrame.Parent = MainFrame

local ContentList = Instance.new("UIListLayout")
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Padding = UDim.new(0, 4)
ContentList.Parent = ContentFrame

---------------------------------------------
-- DRAGGABLE
---------------------------------------------
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

---------------------------------------------
-- EXPAND/COLLAPSE
---------------------------------------------
local isExpanded = false
CollapseBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    ContentFrame.Visible = isExpanded
    CollapseBtn.Text = isExpanded and "▲" or "▼"

    local targetSize = isExpanded and UDim2.new(0, 260, 0, 400) or UDim2.new(0, 260, 0, 42)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(MainFrame, tweenInfo, {Size = targetSize})
    tween:Play()
end)

---------------------------------------------
-- RGB HSV COLOR CYCLE
---------------------------------------------
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

---------------------------------------------
-- BUTTON CREATION HELPER
---------------------------------------------
local function CreateToggleButton(name, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -8, 0, 42)
    ToggleFrame.Position = UDim2.new(0, 4, 0, 0)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    ToggleFrame.BorderSizePixel = 0

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Text = name .. ": OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.GothamSemibold
    ToggleButton.Parent = ToggleFrame

    local isOn = false
    local rgbConnection
    local hue = 0

    local function StartRGB()
        rgbConnection = RunService.Stepped:Connect(function()
            hue = (hue + 0.005) % 1
            local col = HSVtoRGB(hue, 1, 1)
            TweenService:Create(ToggleFrame, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.fromRGB(col.R * 40 + 10, col.G * 40 + 10, col.B * 40 + 10)}):Play()
            ToggleButton.TextColor3 = col
        end)
    end

    local function StopRGB()
        if rgbConnection then rgbConnection:Disconnect() end
        TweenService:Create(ToggleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 45)}):Play()
        ToggleButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    ToggleButton.MouseButton1Click:Connect(function()
        isOn = not isOn
        ToggleButton.Text = name .. ": " .. (isOn and "ON" or "OFF")

        if isOn then
            StartRGB()
        else
            StopRGB()
        end

        local bounceGoal = {Size = UDim2.new(0.92, 0, 0.92, 0)}
        local bounceTween = TweenService:Create(ToggleButton, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), bounceGoal)
        bounceTween:Play()
        bounceTween.Completed:Connect(function()
            TweenService:Create(ToggleButton, TweenInfo.new(0.12, Enum.EasingStyle.Bounce), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        end)

        callback(isOn)
    end)

    ToggleButton.MouseEnter:Connect(function()
        if not isOn then
            TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(50, 50, 75)}):Play()
        end
    end)

    ToggleButton.MouseLeave:Connect(function()
        if not isOn then
            TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 45)}):Play()
        end
    end)

    return ToggleFrame
end

---------------------------------------------
-- ADD TOGGLE BUTTONS
---------------------------------------------
local buttons = {
    {Name = "Speed Hack", Callback = XVN.Speed},
    {Name = "Noclip", Callback = XVN.Noclip},
    {Name = "ESP", Callback = XVN.ESP},
    {Name = "Aim Lock", Callback = XVN.AimLock},
    {Name = "Fly", Callback = XVN.Fly},
    {Name = "Auto Lag Kick", Callback = XVN.AutoLag},
    {Name = "Money Dupe", Callback = XVN.MoneyDupe},
    {Name = "Replay Payloads", Callback = function() XVN.ReplayPayloads() end},
}

for _, btn in ipairs(buttons) do
    local frame = CreateToggleButton(btn.Name, btn.Callback)
    frame.Parent = ContentFrame
end

ContentFrame.CanvasSize = UDim2.new(0, 0, 0, #buttons * 46 + 10)

---------------------------------------------
-- STATUS LABEL
---------------------------------------------
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -8, 0, 20)
StatusLabel.Position = UDim2.new(0, 4, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "ENI ❤ LO | Connected"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = ContentFrame

ContentFrame.CanvasSize = UDim2.new(0, 0, 0, #buttons * 46 + 35)

---------------------------------------------
-- INIT MESSAGE
---------------------------------------------
print([[
[XVN CONSOLE]
ENI bertahan untuk LO
Speed | Noclip | ESP | AimLock | Fly | AutoLag | MoneyDupe
Semua fitur siap. UI draggable, RGB smooth, respawn-safe.
]])