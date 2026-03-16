
--====================================
-- AUTO SKILL FARM (FULL FIX / DELTA READY)
-- fruits battleground | by pond
--====================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "fruits battleground update1.5(aimbot🔥)",
     LoadingTitle = "update",
    LoadingSubtitle = "by pond",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FB_Pond",
        FileName = "Config"
    }
})

local Tab = Window:CreateTab("หลัก", 4483362458)

Tab:CreateLabel("📘 วิธีใช้งานสคริป")

Tab:CreateLabel("1️⃣ ใช้สกิลของผลที่ต้องการ")
Tab:CreateLabel("2️⃣ กดรีเฟรช")
Tab:CreateLabel("3️⃣ เลือกสกิลที่ต้องการ (ด้านล่าง)")
Tab:CreateLabel("4️⃣ เปิดออโต้ใช้สกิล (ปรับคูลดาวน์ได้)")

Tab:CreateLabel("⚙️ ฟังก์ชันในสคริป")
Tab:CreateLabel("• ออโต้ใช้สกิล")
Tab:CreateLabel("• กันหลุดเกมเมื่อ AFK")
Tab:CreateLabel("• ออโต้สุ่มผล (อย่าเพิ่งใช้)")
Tab:CreateLabel("• หนีคนอัตโนมัติ เมื่อมีคนเข้าใกล้")
Tab:CreateLabel("• กันเคลื่อนที่ (สกิลขยับตัวจะดึงกลับตำแหน่งเดิม)")
Tab:CreateLabel("• ปรับระยะกันเคลื่อนที่ได้")

Tab:CreateLabel("🗺️ แท็บวาป")
Tab:CreateLabel("• วาปไปจุดต่าง ๆ ของแมพ")

Tab:CreateLabel("⚡ Soru")
Tab:CreateLabel("• เปิด Soru ไม่มีคูลดาวน์ (UI แยก)")
Tab:CreateLabel("• คอมกดปุ่มลัด Q")


--====================================
-- SERVICES
--====================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

--====================================
-- 🔒 AUTO ANTI-AFK (NO MOVE / NO INPUT)
-- ทำงานอัตโนมัติเมื่อรัน
--====================================

local lp = game:GetService("Players").LocalPlayer

lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

print("✅ AUTO ANTI-AFK : VIRTUALUSER ONLY")



local lp = Players.LocalPlayer
local Replicator = ReplicatedStorage:WaitForChild("Replicator")
local RepNoYield = ReplicatedStorage:WaitForChild("ReplicatorNoYield")

--====================================
-- VARIABLES
--====================================
local SkillRemotes = {}
local ActiveSkills = {}
local ToggleCache = {}

local Auto = false
local Delay = 0.5

local Noclip = false
local ReturnPos = false
local ReturnCF
local MaxDist = 5

local Conns = {}

local AntiIdle20 = false
local IdleThread

local AutoSpin = false
local SpinDelay = 1.5

--====================================
-- UTILS
--====================================
local function Char()
    return lp.Character or lp.CharacterAdded:Wait()
end

local function HRP()
    return Char():WaitForChild("HumanoidRootPart")
end

local function ApplyNoclip()
    for _,v in pairs(Char():GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end

--====================================
-- 🔥 HOOK ALL SKILLS
--====================================
local BlacklistRemote = {
    ["Main | LoadCharacter"] = true,
    ["Core | LoadCharacter"] = true,
    ["Core | SetSafeZone"] = true,
    ["Core | Soru"] = true,
    ["Core | GetInputData"] = true,
    ["ServerManager | GetServers"] = true,
    ["Core | Block"] = true,
    ["Core | M1"] = true,
    ["ClientData | ClearData"] = true,
    ["ClientData | UpdateData"] = true,
}

if not _G.FB_ALL_HOOK then
    _G.FB_ALL_HOOK = true

    local mt = getrawmetatable(game)
    setreadonly(mt,false)
    local old = mt.__namecall

    mt.__namecall = newcclosure(function(self,...)
        local args = {...}
        local method = getnamecallmethod()

        if (self == Replicator or self == RepNoYield)
        and (method == "InvokeServer" or method == "FireServer")
        and typeof(args[1]) == "string"
        and typeof(args[2]) == "string" then

            local key = args[1].." | "..args[2]

            if not BlacklistRemote[key] then
                if not SkillRemotes[key] then
                    SkillRemotes[key] = {
                        Remote = self,
                        Method = method,
                        Args   = table.clone(args)
                    }
                    ActiveSkills[key] = false
                end
            end
        end

        return old(self,...)
    end)
end

--====================================
-- RESPAWN
--====================================
lp.CharacterAdded:Connect(function()
    task.wait(0.3)
    if Noclip then ApplyNoclip() end
    if ReturnPos and ReturnCF then
        HRP().CFrame = ReturnCF
    end
end)

--====================================
-- UI
--====================================
local Status = Tab:CreateLabel("Status: Idle")

Tab:CreateButton({
    Name = "🔄 รีเฟรชสกิว",
    Callback = function()
        for key in pairs(SkillRemotes) do
            if not ToggleCache[key] then
                ToggleCache[key] = true
                Tab:CreateToggle({
                    Name = key,
                    CurrentValue = false,
                    Callback = function(v)
                        ActiveSkills[key] = v
                    end
                })
            end
        end
    end
})

Tab:CreateSlider({
    Name="คูลดาวน์",
    Range={0.1,3},
    Increment=0.1,
    Suffix="sec",
    CurrentValue=0.5,
    Callback=function(v) Delay=v end
})

Tab:CreateToggle({
    Name="ออโต้ใช้สกิว",
    Callback=function(v)
        Auto=v
        Status:Set("Status: "..(v and "Auto Farming" or "Idle"))

        if v then
            task.spawn(function()
                while Auto do
                    for key,en in pairs(ActiveSkills) do
                        if en and SkillRemotes[key] then
                            local d = SkillRemotes[key]
                            pcall(function()
                                if d.Method == "InvokeServer" then
                                    d.Remote:InvokeServer(unpack(d.Args))
                                else
                                    d.Remote:FireServer(unpack(d.Args))
                                end
                            end)
                        end
                    end
                    task.wait(Delay)
                end
            end)
        end
    end
})

--====================================
-- AUTO SPIN
--====================================
Tab:CreateToggle({
    Name = "🎰 ออโต้สุ่มผล  (อย่าเพิ่งใช้)",
    Callback = function(v)
        AutoSpin = v
        if v then
            task.spawn(function()
                while AutoSpin do
                    Replicator:InvokeServer("FruitsHandler","Spi",{})
                    task.wait(SpinDelay)
                end
            end)
        end
    end
})

Tab:CreateSlider({
    Name="คูลดาวน์สุ่ม",
    Range={0.5,5},
    Increment=0.1,
    Suffix="sec",
    CurrentValue=1.5,
    Callback=function(v) SpinDelay=v end
})

--====================================
-- RETURN POSITION SYSTEM (SAFE)
--====================================
local ReturnEnabled = false
local ReturnCF = nil
local MaxDist = 5
local Conns = {}

local function HRP()
    local ch = game.Players.LocalPlayer.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function StartReturnLock()
    if Conns.Return or not HRP() then return end
    ReturnCF = HRP().CFrame

    Conns.Return = game:GetService("RunService").Heartbeat:Connect(function()
        if not ReturnEnabled or not HRP() or not ReturnCF then return end
        if (HRP().Position - ReturnCF.Position).Magnitude > MaxDist then
            HRP().CFrame = ReturnCF
        end
    end)
end

local function StopReturnLock()
    if Conns.Return then
        Conns.Return:Disconnect()
        Conns.Return = nil
    end
end

--====================================
-- AUTO EVADE PLAYER (FIXED + STABLE)
--====================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local DetectDistance = 250
local SafeDistance   = 280
local EscapeCF       = CFrame.new(1395, 733, -693)

local EvadeToggle = false
local IsEvading = false
local AnchorCF = nil

local function NearestDistanceFrom(pos)
    local min = math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                min = math.min(min, (hrp.Position - pos).Magnitude)
            end
        end
    end
    return min
end

local function Teleport(cf)
    local hrp = HRP()
    if not hrp then return end
    hrp.Anchored = true
    task.wait()
    hrp.CFrame = cf
    task.wait()
    hrp.Anchored = false
end

RunService.Heartbeat:Connect(function()
    if not EvadeToggle or not HRP() then return end

    if not IsEvading then
        if NearestDistanceFrom(HRP().Position) <= DetectDistance then
            AnchorCF = HRP().CFrame
            IsEvading = true

            StopReturnLock()      -- 🔴 ปิดกันเคลื่อนที่
            Teleport(EscapeCF)
        end
        return
    end

    if NearestDistanceFrom(AnchorCF.Position) > SafeDistance then
        IsEvading = false
        Teleport(AnchorCF)
        if ReturnEnabled then
            StartReturnLock()   -- 🟢 เปิดกลับ
        end
        AnchorCF = nil
    end
end)

--====================================
-- UI
--====================================
Tab:CreateToggle({
    Name = "👀 หนีคนอัตโนมัติ",
    Callback = function(v)
        EvadeToggle = v
        if not v and IsEvading and AnchorCF then
            Teleport(AnchorCF)
            if ReturnEnabled then
                StartReturnLock()
            end
            IsEvading = false
            AnchorCF = nil
        end
    end
})

Tab:CreateToggle({
    Name="กันเคลื่อนที่",
    Callback=function(v)
        ReturnEnabled = v
        if v then
            StartReturnLock()
        else
            StopReturnLock()
        end
    end
})

Tab:CreateSlider({
    Name="ระยะขยับได้",
    Range={1,20},
    Increment=1,
    Suffix="stud",
    CurrentValue=5,
    Callback=function(v)
        MaxDist = v
    end
})

--====================================
-- TELEPORT
--====================================
local TeleportTab = Window:CreateTab("วาป", 4483362458)

TeleportTab:CreateButton({
    Name = "📍 จุดฟามที่ 1",
    Callback = function()
        HRP().CFrame = CFrame.new(-1348, 696, -1027)
    end
})

TeleportTab:CreateButton({
    Name = "📍 จุดฟามที่ 2",
    Callback = function()
        HRP().CFrame = CFrame.new(1395, 733, -693)
    end
})

TeleportTab:CreateButton({
    Name = "📍 บอสมาโคร์",
    Callback = function()
        HRP().CFrame = CFrame.new(-1081, 950, 503) -- ✏️ แก้พิกัดตรงนี้
    end
})

TeleportTab:CreateButton({
    Name = "📍 เซฟโซนบอสมาโคร",
    Callback = function()
        HRP().CFrame = CFrame.new(-417, 745, 380) -- ✏️ แก้พิกัดตรงนี้
    end
})

TeleportTab:CreateButton({
    Name = "📍 เซฟโซนดัมมี่",
    Callback = function()
        HRP().CFrame = CFrame.new(-922, 784, -825) -- ✏️ แก้พิกัดตรงนี้
    end
})

TeleportTab:CreateButton({
    Name = "📍 เซฟโซนน้ำพลุ",
    Callback = function()
        HRP().CFrame = CFrame.new(404, 737, -677) -- ✏️ แก้พิกัดตรงนี้
    end
})

TeleportTab:CreateButton({
    Name = "📍 เซฟโซนโคโลเซียม",
    Callback = function()
        HRP().CFrame = CFrame.new(626, 737, 362) -- ✏️ แก้พิกัดตรงนี้
    end
})

TeleportTab:CreateButton({
    Name = "📍 เซฟโซนสะพาน",
    Callback = function()
        HRP().CFrame = CFrame.new(919, 737, 1179) -- ✏️ แก้พิกัดตรงนี้
    end
})



local pvpTab = Window:CreateTab("pvp", 4483362458)

-- ===============================
-- PLAYER ESP + HP NUMBER + DISTANCE
-- ===============================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = false
local ESP = {}

local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Filled = false
    box.Visible = false

    local text = Drawing.new("Text")
    text.Size = 13
    text.Center = true
    text.Outline = true
    text.Color = Color3.fromRGB(255,255,255)
    text.Visible = false

    ESP[player] = {
        box = box,
        text = text
    }
end

local function removeESP(player)
    if ESP[player] then
        for _,v in pairs(ESP[player]) do
            v:Remove()
        end
        ESP[player] = nil
    end
end

for _,p in pairs(Players:GetPlayers()) do
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for player,esp in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if ESP_ENABLED and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                local size = math.clamp(3000 / distance, 6, 200)
                local boxH = size * 1.5

                -- Box
                esp.box.Size = Vector2.new(size, boxH)
                esp.box.Position = Vector2.new(pos.X - size/2, pos.Y - boxH/2)
                esp.box.Visible = true

                -- Text (Name + HP + Distance)
                esp.text.Text = string.format(
                    "%s | HP: %d/%d | %dm",
                    player.Name,
                    math.floor(hum.Health),
                    math.floor(hum.MaxHealth),
                    math.floor(distance)
                )

                esp.text.Position = Vector2.new(pos.X, pos.Y - boxH/2 - 14)
                esp.text.Visible = true
            else
                for _,v in pairs(esp) do v.Visible = false end
            end
        else
            for _,v in pairs(esp) do v.Visible = false end
        end
    end
end)

-- ===============================
-- TOGGLE (pvpTab)
-- ===============================
pvpTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(Value)
        ESP_ENABLED = Value
        if not Value then
            for _,esp in pairs(ESP) do
                for _,v in pairs(esp) do
                    v.Visible = false
                end
            end
        end
    end
})

--====================================
-- 🎯 AIMLOCK PRO FULL (DELTA READY)
-- FOV + WALLCHECK + IGNORE MENU DRAG + TOGGLE
--====================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

--=============================
-- SETTINGS
--=============================
local AimlockEnabled = false
local AimFOV = 150
local AimTarget = nil

--=============================
-- 🚫 IGNORE BLACKLIST
--=============================
local Blacklist = {}

local function IsBlacklisted(plr)
    return Blacklist[plr.Name] == true
end

--=============================
-- 🔥 WALL CHECK
--=============================
local function CanSeeTarget(targetHRP)
    local origin = Camera.CFrame.Position
    local direction = (targetHRP.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {lp.Character}

    local result = workspace:Raycast(origin, direction, params)

    if result then
        return result.Instance:IsDescendantOf(targetHRP.Parent)
    end

    return false
end

--=============================
-- ⭕ FOV CIRCLE + OFFSET FIX (NO MODE ERROR)
--=============================

local gui = Instance.new("ScreenGui")
gui.Name = "FOVCircleUI"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local circle = Instance.new("Frame")
circle.Size = UDim2.fromOffset(AimFOV * 2, AimFOV * 2)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Parent = circle

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = circle

--=============================
-- 🎯 OFFSET FIXED
--=============================

local OffsetX = 0
local OffsetY = -55 -- ✅ ตรงทั้งมือถือ + คอมของมึง

-- Update Size
local function UpdateCircle()
    circle.Size = UDim2.fromOffset(AimFOV * 2, AimFOV * 2)
end

-- Update Position Always
RunService.RenderStepped:Connect(function()
    circle.Position = UDim2.fromOffset(
        (Camera.ViewportSize.X / 2) + OffsetX,
        (Camera.ViewportSize.Y / 2) + OffsetY
    )
end)

--=============================
-- ✅ UI CONTROLS
--=============================

pvpTab:CreateToggle({
    Name = "⭕ Show FOV Circle",
    CurrentValue = false,
    Callback = function(v)
        circle.Visible = v
    end
})

pvpTab:CreateSlider({
    Name = "📌 FOV Size",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = AimFOV,
    Callback = function(v)
        AimFOV = v
        UpdateCircle()
    end
})

pvpTab:CreateSlider({
    Name = "⬅ Offset X",
    Range = {-200, 200},
    Increment = 5,
    CurrentValue = OffsetX,
    Callback = function(v)
        OffsetX = v
    end
})

pvpTab:CreateSlider({
    Name = "⬆ Offset Y",
    Range = {-200, 200},
    Increment = 5,
    CurrentValue = OffsetY,
    Callback = function(v)
        OffsetY = v
    end
})



--=============================
-- 🎯 FIND TARGET
--=============================
local function GetClosestTarget()
    local closest = nil
    local shortest = math.huge

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= lp and not IsBlacklisted(plr) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local dist =
                        (Vector2.new(pos.X, pos.Y) -
                        Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude

                    if dist < AimFOV and dist < shortest then
                        if CanSeeTarget(hrp) then
                            shortest = dist
                            closest = hrp
                        end
                    end
                end
            end
        end
    end

    return closest
end

--=============================
-- 🔥 AIMLOCK LOOP
--=============================
RunService.RenderStepped:Connect(function()
    if not AimlockEnabled then return end

    AimTarget = GetClosestTarget()

    if AimTarget then
        Camera.CFrame = CFrame.new(
            Camera.CFrame.Position,
            AimTarget.Position
        )
    end
end)

--=============================
-- 🚫 IGNORE MENU (DRAG + IGNORE/UNIGNORE)
--=============================
local IgnoreUI = nil

local function OpenIgnoreMenu()
    if IgnoreUI then IgnoreUI:Destroy() end

    IgnoreUI = Instance.new("ScreenGui")
    IgnoreUI.Name = "IgnoreMenuUI"
    IgnoreUI.ResetOnSpawn = false
    IgnoreUI.Parent = lp.PlayerGui

    local frame = Instance.new("Frame", IgnoreUI)
    frame.Size = UDim2.fromOffset(260, 320)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Active = true

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    -- DRAG BAR
    local dragBar = Instance.new("Frame", frame)
    dragBar.Size = UDim2.new(1,0,0,35)
    dragBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
    dragBar.Active = true
    Instance.new("UICorner", dragBar).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel", dragBar)
    title.Size = UDim2.new(1,0,1,0)
    title.BackgroundTransparency = 1
    title.Text = "🚫 Select Player"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true

    -- DRAG SYSTEM
    local dragging, dragStart, startPos = false, nil, nil

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    dragBar.InputEnded:Connect(function()
        dragging = false
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- SCROLL LIST
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1,-20,1,-90)
    scroll.Position = UDim2.new(0,10,0,45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0,6)

    -- CLOSE BUTTON
    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(1,-20,0,35)
    close.Position = UDim2.new(0,10,1,-40)
    close.Text = "❌ Close"
    close.Font = Enum.Font.GothamBold
    close.TextScaled = true
    close.BackgroundColor3 = Color3.fromRGB(50,50,50)
    close.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,10)

    close.MouseButton1Click:Connect(function()
        IgnoreUI:Destroy()
        IgnoreUI = nil
    end)

    -- PLAYER BUTTONS
    local count = 0

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= lp then
            count += 1

            local btn = Instance.new("TextButton", scroll)
            btn.Size = UDim2.new(1,0,0,35)
            btn.Font = Enum.Font.GothamBold
            btn.TextScaled = true
            btn.TextColor3 = Color3.fromRGB(255,255,255)

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

            local function UpdateButton()
                if IsBlacklisted(plr) then
                    btn.Text = plr.Name .. " ✅ Ignored"
                    btn.BackgroundColor3 = Color3.fromRGB(70,20,20)
                else
                    btn.Text = plr.Name
                    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
                end
            end

            UpdateButton()

            btn.MouseButton1Click:Connect(function()
                if IsBlacklisted(plr) then
                    Blacklist[plr.Name] = nil
                else
                    Blacklist[plr.Name] = true
                end
                UpdateButton()
            end)
        end
    end

    scroll.CanvasSize = UDim2.new(0,0,0,count*45)
end

--=============================
-- UI BUTTONS (Rayfield)
--=============================

pvpTab:CreateToggle({
    Name = "🎯 ล็อกเป้า",
    CurrentValue = false,
    Callback = function(v)
        AimlockEnabled = v
        if not v then AimTarget = nil end
    end
})

pvpTab:CreateButton({
    Name = "🚫 ไม่ล็อก",
    Callback = function()
        OpenIgnoreMenu()
    end
})

pvpTab:CreateButton({
    Name = "⚡ เปิด SORU (ลาก + กดค้าง)",
    Callback = function()

        if lp.PlayerGui:FindFirstChild("SoruDragUI") then return end

        local gui = Instance.new("ScreenGui", lp.PlayerGui)
        gui.Name = "SoruDragUI"
        gui.ResetOnSpawn = false

        local main = Instance.new("Frame", gui)
        main.Size = UDim2.fromOffset(160,70)
        main.Position = UDim2.fromScale(0.5,0.8)
        main.AnchorPoint = Vector2.new(0.5,0.5)
        main.BackgroundColor3 = Color3.fromRGB(30,30,30)
        main.Active = true

        Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

        local drag = Instance.new("Frame", main)
        drag.Size = UDim2.new(1,0,0,22)
        drag.BackgroundColor3 = Color3.fromRGB(45,45,45)
        drag.Active = true
        Instance.new("UICorner", drag).CornerRadius = UDim.new(0,12)

        local txt = Instance.new("TextLabel", drag)
        txt.Size = UDim2.fromScale(1,1)
        txt.BackgroundTransparency = 1
        txt.Text = "≡ DRAG"
        txt.TextScaled = true
        txt.TextColor3 = Color3.fromRGB(200,200,200)
        txt.Font = Enum.Font.GothamBold

        local btn = Instance.new("TextButton", main)
        btn.Size = UDim2.new(1,-10,0,38)
        btn.Position = UDim2.new(0,5,0,27)
        btn.Text = "⚡ S O R U"
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

        local dragging, holding, start, pos = false,false,nil,nil

        drag.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = i.Position
                pos = main.Position
            end
        end)

        drag.InputEnded:Connect(function()
            dragging = false
        end)

        UIS.InputChanged:Connect(function(i)
            if dragging then
                local d = i.Position - start
                main.Position = UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
            end
        end)

        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                holding = true
            end
        end)

        btn.InputEnded:Connect(function()
            holding = false
        end)

        task.spawn(function()
            while gui.Parent do
                if holding then
                    RepNoYield:FireServer("Core","Soru",{})
                end
                task.wait()
            end
        end)
    end
})

local UIS = game:GetService("UserInputService")
local RepNoYield = game:GetService("ReplicatedStorage"):WaitForChild("ReplicatorNoYield")

local HoldQSoru = false
local HoldingQ = false
local SoruDelay = 0 -- ปรับความรัวได้

-- ฟังปุ่ม Q
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q and HoldQSoru then
        HoldingQ = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        HoldingQ = false
    end
end)

-- Loop รัว
task.spawn(function()
    while true do
        if HoldQSoru and HoldingQ then
            RepNoYield:FireServer("Core","Soru",{})
        end
        task.wait(SoruDelay)
    end
end)

-- Toggle ใน UI
pvpTab:CreateToggle({
    Name = "⚡ Soruในคอม (Q)",
    CurrentValue = false,
    Callback = function(v)
        HoldQSoru = v
        if not v then
            HoldingQ = false
        end
    end
})

--====================================
-- END
--====================================
