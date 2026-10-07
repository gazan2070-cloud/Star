-- ============================================================
-- KUKIRIN G2 AUTO STANT | BEAUTIFUL GUI + ANTI-FALL + MOBILE
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- ======================== НАСТРОЙКИ =========================
local AUTO_STANT_ENABLED = false
local MAX_SPEED_ENABLED = false
local STANT_ANGLE = 65          -- целевой угол подъёма (градусы)
local MAX_SAFE_ANGLE = 80       -- критический угол, после которого включается стабилизация
local STABILIZE_STRENGTH = 0.35 -- сила коррекции (0–1)

-- ======================== ОПРЕДЕЛЕНИЕ СКУТЕРА =========================
local function getScooter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        -- Проверяем, что это скутер Kukirin (по имени родителя или самого seat)
        local parent = seat.Parent
        if parent then
            local name = (parent.Name .. seat.Name):lower()
            if name:find("kukirin") or name:find("scooter") or name:find("g2") then
                return seat
            end
        end
        -- Если имя не совпало, но это VehicleSeat — всё равно возвращаем
        return seat
    end
    return nil
end

-- ======================== ЭМУЛЯЦИЯ КЛАВИШ (fallback) =========================
local function pressKey(keyCode, duration)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    task.wait(duration or 0.06)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- ======================== ФИЗИКА СТАНТА =========================
local function applyStantPhysics(scooter, angle)
    if not scooter then return false end
    local success = false
    pcall(function()
        -- Способ 1: BodyAngularVelocity
        local bodyAngular = scooter:FindFirstChildOfClass("BodyAngularVelocity")
        if bodyAngular then
            bodyAngular.AngularVelocity = Vector3.new(0, 0, math.rad(angle))
            bodyAngular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            success = true
        end
        -- Способ 2: BodyGyro
        local bodyGyro = scooter:FindFirstChildOfClass("BodyGyro")
        if bodyGyro then
            local targetCFrame = scooter.CFrame * CFrame.Angles(math.rad(angle), 0, 0)
            bodyGyro.CFrame = targetCFrame
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            success = true
        end
        -- Способ 3: HingeConstraint (если есть)
        for _, constraint in pairs(scooter:GetDescendants()) do
            if constraint:IsA("HingeConstraint") then
                local n = constraint.Name:lower()
                if n:find("tilt") or n:find("wheel") or n:find("stant") or n:find("angle") then
                    constraint.TargetAngle = angle
                    constraint.AngularVelocity = 0
                    constraint.MotorMaxTorque = math.huge
                    success = true
                end
            end
        end
    end)
    return success
end

local function resetStantPhysics(scooter)
    if not scooter then return end
    pcall(function()
        local bodyAngular = scooter:FindFirstChildOfClass("BodyAngularVelocity")
        if bodyAngular then
            bodyAngular.AngularVelocity = Vector3.zero
        end
        local bodyGyro = scooter:FindFirstChildOfClass("BodyGyro")
        if bodyGyro then
            bodyGyro.CFrame = scooter.CFrame
        end
        for _, constraint in pairs(scooter:GetDescendants()) do
            if constraint:IsA("HingeConstraint") then
                local n = constraint.Name:lower()
                if n:find("tilt") or n:find("wheel") or n:find("stant") or n:find("angle") then
                    constraint.TargetAngle = 0
                end
            end
        end
    end)
end

-- ======================== СТАБИЛИЗАЦИЯ (ANTI-FALL) =========================
local function stabilizeScooter(scooter)
    if not scooter then return end
    pcall(function()
        local up = scooter.CFrame.UpVector
        local tiltAngle = math.deg(math.acos(math.clamp(up.Y, -1, 1)))
        if tiltAngle > MAX_SAFE_ANGLE then
            -- Плавно возвращаем скутер в безопасное положение
            local correction = CFrame.new(scooter.CFrame.Position) * CFrame.Angles(math.rad(-3), 0, 0)
            scooter.CFrame = scooter.CFrame:Lerp(correction, STABILIZE_STRENGTH)
            scooter.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- ======================== ЦИКЛ AUTO STANT =========================
local function autoStantLoop()
    while AUTO_STANT_ENABLED do
        local scooter = getScooter()
        if scooter then
            local ok = applyStantPhysics(scooter, STANT_ANGLE)
            if not ok then
                -- Fallback: эмуляция Shift
                pressKey(Enum.KeyCode.LeftShift, 0.06)
            end
            stabilizeScooter(scooter)
        end
        task.wait(0.03)
    end
    -- При выключении сбрасываем физику
    local scooter = getScooter()
    if scooter then resetStantPhysics(scooter) end
end

-- ======================== MAX SPEED =========================
local function applyMaxSpeed()
    local scooter = getScooter()
    if scooter then
        pcall(function()
            scooter.MaxSpeed = 500
        end)
        pcall(function()
            local bv = scooter:FindFirstChildOfClass("BodyVelocity")
            if bv then
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = scooter.CFrame.LookVector * 300
            end
        end)
    end
end

-- ======================== КРАСИВЫЙ GUI =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KukirinStantGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Иконка (перетаскиваемая)
local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 70, 0, 70)
Icon.Position = UDim2.new(0, 20, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
Icon.Text = "🛴"
Icon.TextSize = 40
Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
Icon.BorderSizePixel = 0
Icon.AutoButtonColor = false
Icon.Parent = ScreenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 20)
iconCorner.Parent = Icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(80, 120, 255)
iconStroke.Thickness = 2
iconStroke.Transparency = 0.3
iconStroke.Parent = Icon

local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 60, 140)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 40))
}
iconGradient.Rotation = 45
iconGradient.Parent = Icon

-- Меню (перетаскиваемое)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0, 20, 0, 190)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 80, 200)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.4
mainStroke.Parent = MainFrame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 55)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
Title.Text = "Kukirin G2 Stant"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 18)
titleCorner.Parent = Title

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Title

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = CloseBtn

-- Статус
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.05, 0, 0, 60)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Статус: не на скутере"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Функция создания кнопки
local function createButton(text, yPos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 55)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 18
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = btn

    return btn
end

local StantBtn = createButton("Auto Stant: OFF", 100, Color3.fromRGB(45, 45, 70))
local SpeedBtn = createButton("Max Speed: OFF", 165, Color3.fromRGB(45, 45, 70))

-- Инфо
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.9, 0, 0, 60)
InfoLabel.Position = UDim2.new(0.05, 0, 0, 240)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Сядь на скутер Kukirin G2.\nСкрипт сам поднимет колесо и не даст упасть."
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
InfoLabel.TextSize = 13
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextWrapped = true
InfoLabel.Parent = MainFrame

-- ======================== ПЕРЕТАСКИВАНИЕ =========================
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(Icon, Icon)
makeDraggable(MainFrame, Title)

-- ======================== ОБРАБОТЧИКИ =========================
Icon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    -- Анимация
    if MainFrame.Visible then
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0, 320, 0, 420)}):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

StantBtn.MouseButton1Click:Connect(function()
    AUTO_STANT_ENABLED = not AUTO_STANT_ENABLED
    StantBtn.Text = "Auto Stant: " .. (AUTO_STANT_ENABLED and "ON" or "OFF")
    StantBtn.BackgroundColor3 = AUTO_STANT_ENABLED and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(45, 45, 70)
    if AUTO_STANT_ENABLED then
        task.spawn(autoStantLoop)
    end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    MAX_SPEED_ENABLED = not MAX_SPEED_ENABLED
    SpeedBtn.Text = "Max Speed: " .. (MAX_SPEED_ENABLED and "ON" or "OFF")
    SpeedBtn.BackgroundColor3 = MAX_SPEED_ENABLED and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(45, 45, 70)
    if MAX_SPEED_ENABLED then
        task.spawn(function()
            while MAX_SPEED_ENABLED do
                applyMaxSpeed()
                task.wait(0.5)
            end
        end)
    end
end)

-- ======================== ОБНОВЛЕНИЕ СТАТУСА =========================
task.spawn(function()
    while true do
        local scooter = getScooter()
        if scooter then
            StatusLabel.Text = "Статус: на скутере ✅"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            StatusLabel.Text = "Статус: не на скутере ❌"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(0.5)
    end
end)

-- ======================== RESPAWN =========================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if AUTO_STANT_ENABLED then
        task.spawn(autoStantLoop)
    end
end)

warn("[KUKIRIN] Скрипт загружен. Нажми на иконку 🛴.")
