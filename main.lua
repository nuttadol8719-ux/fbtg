--====================================
-- AUTO SKILL FARM (CLEAN + NO DUP + SMART REFRESH)
-- fruits battleground | by pond
--====================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "fruits battleground",
    LoadingTitle = "Auto Skill",
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
local lp = Players.LocalPlayer

--====================================
-- VARIABLES
--====================================
local SkillRemotes = {}
local ActiveSkills = {}

local SkillCache  = {}
local ToggleCache = {}
local Toggles = {}

local Auto = false
local Delay = 0.5

local Noclip = false
local ReturnPos = false
local AntiAFK = false

local ReturnCF = nil
local MaxDist = 5

local Conns = {}

-- 🔥 AUTO SPIN (INVOKE)
local AutoSpin = false
local SpinDelay = 1.5
local Replicator = ReplicatedStorage:WaitForChild("Replicator")

--====================================
-- UTILS
--====================================
local function Char()
    return lp.Character or lp.CharacterAdded:Wait()
end

local function ApplyNoclip()
    for _,v in pairs(Char():GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end

--====================================
-- HOOK SKILL (ONCE + NO DUP)
--====================================
if not _G.SkillHooked then
    _G.SkillHooked = true

    local mt = getrawmetatable(game)
    setreadonly(mt,false)
    local old = mt.__namecall

    mt.__namecall = newcclosure(function(self,...)
        local args = {...}
        if getnamecallmethod()=="InvokeServer"
        and self==Replicator
        and typeof(args[1])=="string"
        and typeof(args[2])=="string"
        and typeof(args[3])=="table" then

            local fruit = args[1]
            local skill = args[2]

            if skill=="SetSafeZone" or skill=="Block" then
                return old(self,...)
            end

            local key = fruit.."|"..skill
            if not SkillCache[key] then
                SkillCache[key] = true

                SkillRemotes[skill] = {
                    Remote = self,
                    Args   = table.clone(args),
                    Fruit  = fruit
                }
                ActiveSkills[skill] = ActiveSkills[skill] or false
                warn("📌 Add Skill:", key)
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
        Char():SetPrimaryPartCFrame(ReturnCF)
    end
end)

--====================================
-- UI
--====================================
local Status = Tab:CreateLabel("Status: Idle")

Tab:CreateButton({
    Name = "🔄 รีเฟรชสกิว",
    Callback = function()
        for skill,data in pairs(SkillRemotes) do
            if not ToggleCache[skill] then
                ToggleCache[skill] = true

                Tab:CreateToggle({
                    Name = data.Fruit.." | "..skill,
                    CurrentValue = ActiveSkills[skill],
                    Callback = function(v)
                        ActiveSkills[skill] = v
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
                    for s,en in pairs(ActiveSkills) do
                        if en and SkillRemotes[s] then
                            pcall(function()
                                SkillRemotes[s].Remote:InvokeServer(unpack(SkillRemotes[s].Args))
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
-- 🎰 AUTO SPIN (INVOKE SERVER)
-- อยู่เหนือปุ่ม "เดินทะลุ"
--====================================
Tab:CreateToggle({
    Name = "🎰 ออโต้สุ่มผล",
    CurrentValue = false,
    Callback = function(v)
        AutoSpin = v
        if v then
            task.spawn(function()
                while AutoSpin do
                    pcall(function()
                        Replicator:InvokeServer(
                            "FruitsHandler",
                            "Spin",
                            {}
                        )
                    end)
                    task.wait(SpinDelay)
                end
            end)
        end
    end
})

Tab:CreateSlider({
    Name = "คูลดาวน์สุ่ม",
    Range = {0.5,5},
    Increment = 0.1,
    Suffix = "sec",
    CurrentValue = 1.5,
    Callback = function(v)
        SpinDelay = v
    end
})

--====================================
-- REMAIN ORIGINAL
--====================================
Tab:CreateToggle({
    Name="กัน AFK",
    Callback=function(v)
        AntiAFK=v
        if Conns.AFK then Conns.AFK:Disconnect() end
        if v then
            Conns.AFK = RunService.Heartbeat:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

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
            local c = Char()
            if c.PrimaryPart then ReturnCF = c.PrimaryPart.CFrame end
            Conns.Return = RunService.Heartbeat:Connect(function()
                local p = lp.Character and lp.Character.PrimaryPart
                if p and ReturnCF and (p.Position-ReturnCF.Position).Magnitude > MaxDist then
                    p.CFrame = ReturnCF
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
-- END
--====================================
