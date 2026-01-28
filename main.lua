--====================================
-- AUTO SKILL FARM (FULL FIX / DELTA READY)
-- fruits battleground | by pond
--====================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "fruits battleground update1.15(fix)",
    LoadingTitle = "update",
    LoadingSubtitle = "by pond",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FB_Pond",
        FileName = "Config"
    }
})

local Tab = Window:CreateTab("หลัก", 4483362458)

--====================================
-- SERVICES
--====================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

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
-- ANTI IDLE
--====================================
Tab:CreateToggle({
    Name = "🛡️ กันหลุดAFK",
    Callback = function(v)
        AntiIdle20 = v
        if IdleThread then task.cancel(IdleThread) end
        if v then
            IdleThread = task.spawn(function()
                while AntiIdle20 do
                    task.wait(600)
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end
            end)
        end
    end
})

--====================================
-- AUTO SPIN
--====================================
Tab:CreateToggle({
    Name = "🎰 ออโต้สุ่มผล",
    Callback = function(v)
        AutoSpin = v
        if v then
            task.spawn(function()
                while AutoSpin do
                    Replicator:InvokeServer("FruitsHandler","Spin",{})
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
-- MOVEMENT
--====================================
Tab:CreateToggle({
    Name="เดินทะลุ",
    Callback=function(v)
        Noclip=v
        if Conns.Noclip then Conns.Noclip:Disconnect() end
        if v then
            Conns.Noclip = RunService.Stepped:Connect(ApplyNoclip)
        end
    end
})

Tab:CreateToggle({
    Name="กันเคลื่อนที่",
    Callback=function(v)
        ReturnPos=v
        if Conns.Return then Conns.Return:Disconnect() end
        if v then
            ReturnCF = HRP().CFrame
            Conns.Return = RunService.Heartbeat:Connect(function()
                if (HRP().Position-ReturnCF.Position).Magnitude > MaxDist then
                    HRP().CFrame = ReturnCF
                end
            end)
        end
    end
})

Tab:CreateSlider({
    Name="ระยะขยับได้",
    Range={1,20},
    Increment=1,
    Suffix="stud",
    CurrentValue=5,
    Callback=function(v) MaxDist=v end
})

--====================================
-- TELEPORT
--====================================
local TeleportTab = Window:CreateTab("วาป", 4483362458)

TeleportTab:CreateButton({
    Name = "📍 วาปตำแหน่งที่ 1",
    Callback = function()
        HRP().CFrame = CFrame.new(-1348, 696, -1027)
    end
})

TeleportTab:CreateButton({
    Name = "📍 วาปตำแหน่งที่ 2",
    Callback = function()
        HRP().CFrame = CFrame.new(1395, 733, -693)
    end
})

--====================================
-- ✅ SORU UI (กดปุ่มในแท็บวาปเพื่อรัน)
--====================================
TeleportTab:CreateButton({
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

--====================================
-- END
--====================================
