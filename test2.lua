




local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GetSetting, SetSetting, ReadFileContent, WriteFileContent, QueueOnTeleport, AutoExecuteScript
do
    local SaveKey = "SymbioteSettings_" .. tostring(game.PlaceId) .. ".json"

    local DefaultSettings = {
        NoClip = false,
        WalkSpeed = false,
        WalkSpeedAmount = 1,
        LaggyRun = false,
        LaggyRunDistance = 1,
        LaggyRunDelay = 1,
        CtrlClickTP = false,
        InfiniteJump = false,
        AutoFarm = false,
        DistanceToTitan = 0,
        AutoReload = false,
        ExpandNapeHitbox = false,
        HitboxSize = 20,
        VisualizeHitbox = false,
        TitanESP = false,
        AutoRefill = false,
        ChangeCursor = false,
        AutoExecute = false,
        AutoRetry = false,
        AutoSkipCutscenes = false,
        KillWithoutTP = false,
        DelayToKill = false,
        DelayToKillAmount = 1,
        HitAll = false,
        AutoFamilySpin = false,
        FamiliesToStop = {},
        FamilyTiersToStop = {},
        AutoSellPerks = false,
        PerkTiersToSell = {},
        SpecificPerksToSell = {},
        AutoCreateTowers = false,
        AutoRetrieveSupplyCrates = false,
    }

    AutoExecuteScript = [[
        task.wait(3)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ssssssssss21/Symbiote/refs/heads/main/test2.lua"))()
    ]]

    function ReadFileContent(filename)
        local ok, data = pcall(function()
            local readFn = (syn and syn.read_file) or readfile
            if readFn then
                return readFn(filename)
            end
            return nil
        end)
        if ok and data and data ~= "" then
            return data
        end
        return nil
    end

    function WriteFileContent(filename, content)
        pcall(function()
            local writeFn = (syn and syn.write_file) or writefile
            if writeFn then
                writeFn(filename, content)
            end
        end)
    end

    function QueueOnTeleport(scriptCode)
        local fn = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
        if fn then
            pcall(function()
                fn(scriptCode)
            end)
        end
    end

    local function LoadSettings()
        local raw = ReadFileContent(SaveKey)
        if raw then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if ok and type(data) == "table" then
                return data
            end
        end
        return {}
    end

    local function SaveSettings(settings)
        local ok, json = pcall(function()
            return HttpService:JSONEncode(settings)
        end)
        if ok and json then
            WriteFileContent(SaveKey, json)
        end
    end

    local SavedSettings = LoadSettings()

    function GetSetting(key)
        if SavedSettings[key] ~= nil then
            return SavedSettings[key]
        end
        return DefaultSettings[key]
    end

    function SetSetting(key, value)
        SavedSettings[key] = value
        SaveSettings(SavedSettings)
    end

    if GetSetting("AutoExecute") then
        QueueOnTeleport(AutoExecuteScript)
    end
end

local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/ssssssssss21/09b303c5a1cf601bda1370252c65712a/raw/d7c50c43db2b33c1f7516a10317ff642f77c89a6/UITest.luau"))()

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoFarmEnabled = false
local NoClipEnabled = false
local CurrentTarget = nil

local TitanESPEnabled = false

local ExpandNapeHitboxEnabled = false
local NapeHitboxSize = 20
local VisualizeHitboxEnabled = false

local AutoReloadEnabled = false
local IsReloading = false

local WalkSpeedEnabled = false
local WalkSpeedSmoothing = 1

local LaggyRunEnabled = false
local LaggyRunDistance = 1
local LaggyRunDelay = 1

local CtrlClickTPEnabled = false
local InfiniteJumpEnabled = false

local AutoRefillEnabled = false
local IsRefilling = false
local SetsWentEmptyAt = nil

local ChangeCursorEnabled = false
local AutoRetryEnabled = false
local AutoSkipCutscenesEnabled = false

local AutoFamilySpinEnabled = false
local FamiliesToStop = {}
local FamilyTiersToStop = {}

local AutoSellPerksEnabled = false
local PerkTiersToSell = {}
local SpecificPerksToSell = {}

local AutoCreateTowersEnabled = false
local AutoRetrieveSupplyCratesEnabled = false
local CurrentTowerTarget = nil
local IsRetrievingCrates = false
local HoverConnection = nil
local LastHoverCFrame = nil

local UI = {}

local KillWithoutTPEnabled = false
local DelayToKillEnabled = false
local DelayToKillAmount = 1

local HitAllEnabled = false

local DistanceToTitanAmount = 0


local RemotePOST = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")
local RemoteGET  = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")

local function IsUsingSpears()
    local ok, result = pcall(function()
        local charsFolder = Workspace:FindFirstChild("Characters")
        if not charsFolder then return false end
        local playerFolder = charsFolder:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return false end
        local rig = playerFolder:FindFirstChild("Rig_" .. LocalPlayer.Name)
        if not rig then return false end
        local lla = rig:FindFirstChild("LeftLowerArm")
        local rla = rig:FindFirstChild("RightLowerArm")
        local llaSpears = lla and lla:FindFirstChild("Spears")
        local rlaSpears = rla and rla:FindFirstChild("Spears")
        return (llaSpears ~= nil) or (rlaSpears ~= nil)
    end)
    if ok then return result end
    return false
end

local function GetPlayerRig()
    local charsFolder = Workspace:FindFirstChild("Characters")
    local playerFolder = charsFolder and charsFolder:FindFirstChild(LocalPlayer.Name)
    local rig = playerFolder and playerFolder:FindFirstChild("Rig_" .. LocalPlayer.Name)
    if rig then return rig end
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("Rig_" .. LocalPlayer.Name)
    end
    return nil
end

local function GetPhysicalSpearCount()
    local rig = GetPlayerRig()
    if not rig then
        local char = LocalPlayer.Character
        local attr = char and char:GetAttribute("Spears")
        return (attr and tonumber(attr)) or 0
    end
    local lla = rig:FindFirstChild("LeftLowerArm") and rig.LeftLowerArm:FindFirstChild("Spears")
    local rla = rig:FindFirstChild("RightLowerArm") and rig.RightLowerArm:FindFirstChild("Spears")
    if not lla and not rla then
        local char = LocalPlayer.Character
        local attr = char and char:GetAttribute("Spears")
        return (attr and tonumber(attr)) or 0
    end
    local count = 0
    for i = 1, 16 do
        local folder = (i % 2 == 0) and rla or lla
        local sp = folder and folder:FindFirstChild(tostring(i))
        if sp and sp:GetAttribute("Used") == nil and sp.Transparency < 0.9 then
            count = count + 1
        end
    end
    return count
end

local function GetSpearsEmpty()
    local physCount = GetPhysicalSpearCount()
    local char = LocalPlayer.Character
    local attr = char and char:GetAttribute("Spears")
    if physCount == 0 then
        if char and attr ~= 0 then
            pcall(function() char:SetAttribute("Spears", 0) end)
        end
        return true
    end
    if attr ~= nil and tonumber(attr) ~= nil and tonumber(attr) <= 0 then
        return true
    end
    return false
end

local function GetCurrentSpearNumber()
    local ok, num = pcall(function()
        if GetSpearsEmpty() then return 0 end
        local rig = GetPlayerRig()
        if rig then
            local lla = rig:FindFirstChild("LeftLowerArm") and rig.LeftLowerArm:FindFirstChild("Spears")
            local rla = rig:FindFirstChild("RightLowerArm") and rig.RightLowerArm:FindFirstChild("Spears")
            for i = 16, 1, -1 do
                local folder = (i % 2 == 0) and rla or lla
                local sp = folder and folder:FindFirstChild(tostring(i))
                if sp and sp:GetAttribute("Used") == nil and sp.Transparency < 0.9 then
                    return i
                end
            end
        end
        return 0
    end)
    if ok and num and num > 0 then return num end
    return 0
end

local function IsUsingBlades()
    if IsUsingSpears() then return false end
    local ok, result = pcall(function()
        local charsFolder = Workspace:FindFirstChild("Characters")
        if not charsFolder then return false end
        local playerFolder = charsFolder:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return false end
        local rig = playerFolder:FindFirstChild("Rig_" .. LocalPlayer.Name)
        if not rig then return false end
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("MeshPart") and desc.Name:sub(1, 5) == "Blade" then
                return true
            end
        end
        return false
    end)
    if ok then return result end
    return true
end

local function SendReloadRemote()
    if not IsUsingBlades() then return end
    pcall(function()
        RemoteGET:InvokeServer("Blades", "Reload")
    end)
end

local GetRefillPart
do
    local CachedRefillPart = nil
    function GetRefillPart()
        if CachedRefillPart and CachedRefillPart.Parent and CachedRefillPart:IsA("BasePart") then
            return CachedRefillPart
        end
        CachedRefillPart = nil
        pcall(function()
            local searchFolders = {
                Workspace:FindFirstChild("Unclimbable"),
                Workspace:FindFirstChild("Climbable")
            }
            for _, folder in ipairs(searchFolders) do
                if folder then
                    for _, desc in ipairs(folder:GetDescendants()) do
                        if desc:IsA("BasePart") and desc.Name == "Refill" then
                            CachedRefillPart = desc
                            return
                        end
                    end
                end
            end
        end)
        return CachedRefillPart
    end
end

local function SendRefillRemote()
    local refillPart = GetRefillPart()
    if not refillPart then return end
    pcall(function()
        RemotePOST:FireServer("Attacks", "Reload", refillPart)
    end)
end

local function SendSpearReloadRemote()
    local refillPart = GetRefillPart()
    if not refillPart then return end
    pcall(function()
        RemotePOST:FireServer("Attacks", "Reload", refillPart)
    end)
    local startWait = os.clock()
    while os.clock() - startWait < 2 do
        task.wait(0.1)
        if not GetSpearsEmpty() then break end
    end
end

local function SendRetryRemote()
    pcall(function()
        RemoteGET:InvokeServer("Functions", "Retry", "Add")
    end)
end

local function GetSetsX()
    local ok, result = pcall(function()
        local gui = LocalPlayer.PlayerGui
        local label = gui.Interface.HUD.Main.Top["7"].Blades.Sets
        local text = label.Text
        local x = text:match("^(%d+)%s*/")
        if x then return tonumber(x) end
        return nil
    end)
    if ok then return result end
    return nil
end

local function GetBladesBroken()
    local ok, result = pcall(function()
        local rig = GetPlayerRig()
        if not rig then return false end
        local foundBlade = false
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("MeshPart") and desc.Name:sub(1, 5) == "Blade" then
                foundBlade = true
                if not desc:GetAttribute("Broken") then
                    return false
                end
            end
        end
        return foundBlade
    end)
    if ok then return result end
    return false
end

local function SetsEmpty()
    local x = GetSetsX()
    return x ~= nil and x == 0
end

local function NeedsRefill()
    if not SetsEmpty() then
        SetsWentEmptyAt = nil
        return false
    end
    if SetsWentEmptyAt == nil then
        SetsWentEmptyAt = os.clock()
        return false
    end
    if os.clock() - SetsWentEmptyAt < 2 then
        return false
    end
    return GetBladesBroken()
end

local function PerformReload()
    if IsReloading then return end
    IsReloading = true
    task.wait(0.05)
    if IsUsingSpears() then
        SendSpearReloadRemote()
    elseif IsUsingBlades() then
        SendReloadRemote()
        local start = os.clock()
        while os.clock() - start < 1.8 do
            task.wait(0.1)
            if not GetBladesBroken() then break end
        end
    end
    task.wait(0.2)
    IsReloading = false
end

local function RefillUntilFull()
    if IsRefilling then return end
    IsRefilling = true
    SetsWentEmptyAt = nil
    while AutoRefillEnabled do
        if not SetsEmpty() then break end
        if not GetBladesBroken() then break end
        SendRefillRemote()
        task.wait(3)
        if not SetsEmpty() then break end
        if not GetBladesBroken() then break end
    end
    SetsWentEmptyAt = nil
    task.wait(0.25)
    IsRefilling = false
end

local function CanAttack()
    if IsReloading or IsRefilling then return false end
    local char = LocalPlayer.Character
    if char and (char:GetAttribute("Ragdolled") ~= nil or char:GetAttribute("Shifter") ~= nil) then return false end
    if AutoReloadEnabled and IsUsingBlades() and GetBladesBroken() then return false end
    if AutoRefillEnabled and IsUsingBlades() and SetsEmpty() and GetBladesBroken() then return false end
    if IsUsingSpears() and GetSpearsEmpty() then return false end
    return true
end

local function GetTitansFolder()
    return Workspace:FindFirstChild("Titans")
end

local function GetAllTitans()
    local titans = {}
    local folder = GetTitansFolder()
    if not folder then return titans end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then table.insert(titans, model) end
    end
    return titans
end

local function GetNapePart(titan)
    local hitboxes = titan:FindFirstChild("Hitboxes")
    if not hitboxes then return nil end
    local hit = hitboxes:FindFirstChild("Hit")
    if not hit then return nil end
    return hit:FindFirstChild("Nape")
end

local function IsTitanDead(titan)
    if not titan or not titan.Parent then return true end
    local hrp = titan:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    if hrp.Anchored == true then return true end
    local state = titan:GetAttribute("State")
    if state == "Dead" or state == "Die" or state == "Dying" then return true end
    local hum = titan:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return true end
    return false
end

local function IsTitanValid(titan)
    if not titan or not titan.Parent then return false end
    local folder = GetTitansFolder()
    if not folder then return false end
    if titan.Parent ~= folder then return false end
    return not IsTitanDead(titan)
end

local function DetonateClientSpear()
    pcall(function()
        if run_on_actor and getactors then
            local actors = getactors()
            if actors and #actors > 0 then
                run_on_actor(actors[1], [[
                    for _, obj in ipairs(getgc(true)) do
                        if type(obj) == "table" and rawget(obj, "Cache") and rawget(obj, "Services") and rawget(obj, "Modules") then
                            obj.Spear_State = nil
                            obj.Using_Spear = nil
                            obj.Detonate = nil
                            obj.Can_Detonate = nil

                            if obj.Cache and obj.Cache.Variables and obj.Cache.Variables.Slash then
                                obj.Cache.Variables.Slash.Slashing = false
                                obj.Cache.Variables.Slash.Holding = false
                                obj.Cache.Variables.Slash.Released = false
                            end

                            if obj.Events then
                                if obj.Events.Spear_Stepped_2 then
                                    pcall(function() obj.Events.Spear_Stepped_2:Disconnect() end)
                                    obj.Events.Spear_Stepped_2 = nil
                                end
                                if obj.Events.Spear_Stepped then
                                    pcall(function() obj.Events.Spear_Stepped:Disconnect() end)
                                    obj.Events.Spear_Stepped = nil
                                end
                            end

                            if obj.Cache and obj.Cache.Interface and obj.Cache.Interface.Cursor and obj.Cache.Interface.Cursor.Distance2 then
                                obj.Cache.Interface.Cursor.Distance2.Visible = false
                            end

                            if obj.Cache and obj.Cache.Tracks then
                                for name, track in pairs(obj.Cache.Tracks) do
                                    if tostring(name):find("Spear") or tostring(name):find("Hit") or tostring(name):find("Slash") then
                                        pcall(function() track:Stop(0.1) end)
                                    end
                                end
                            end

                            if obj.Cache and obj.Cache.Animations then
                                for name, track in pairs(obj.Cache.Animations) do
                                    if tostring(name):find("Spear") or tostring(name):find("Hit") or tostring(name):find("Slash") then
                                        pcall(function() track:Stop(0.1) end)
                                    end
                                end
                            end
                            break
                        end
                    end
                ]])
            end
        end
    end)
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local iface = pgui and pgui:FindFirstChild("Interface")
        local cursor = iface and iface:FindFirstChild("Cursor")
        local dist2 = cursor and cursor:FindFirstChild("Distance2")
        if dist2 then dist2.Visible = false end
    end)
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local anim = hum and hum:FindFirstChild("Animator")
        if anim then
            for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                if track.Name:find("Spear") or track.Name:find("Slash") or track.Name:find("Hit") or track.Name:find("Throw") then
                    track:Stop(0.1)
                end
            end
        end
    end)
end

local function SendSpearAttack(targetInput)
    if not CanAttack() then return false end
    local napeParts = {}
    if type(targetInput) == "table" and targetInput[1] ~= nil then
        for _, item in ipairs(targetInput) do
            if typeof(item) == "Instance" then
                if item:IsA("BasePart") and item.Name == "Nape" then
                    table.insert(napeParts, item)
                else
                    local n = GetNapePart(item)
                    if n then table.insert(napeParts, n) end
                end
            end
        end
    elseif typeof(targetInput) == "Instance" then
        if targetInput:IsA("BasePart") and targetInput.Name == "Nape" then
            table.insert(napeParts, targetInput)
        else
            local n = GetNapePart(targetInput)
            if n then table.insert(napeParts, n) end
        end
    end
    if #napeParts == 0 then return false end

    local spearNum = GetCurrentSpearNumber()
    if not spearNum or spearNum <= 0 then
        if AutoReloadEnabled and not IsReloading then
            PerformReload()
        end
        return false
    end

    local fireSuccess = nil
    local ok = pcall(function()
        fireSuccess = RemoteGET:InvokeServer("Spears", "S_Fire", tostring(spearNum))
    end)

    if not ok or fireSuccess ~= true then
        local nextSpear = GetCurrentSpearNumber()
        if nextSpear and nextSpear > 0 and nextSpear ~= spearNum then
            spearNum = nextSpear
            pcall(function()
                fireSuccess = RemoteGET:InvokeServer("Spears", "S_Fire", tostring(spearNum))
            end)
        end
        if fireSuccess ~= true then
            pcall(function()
                RemotePOST:FireServer("Spears", "Reset")
            end)
            return false
        end
    end

    task.wait(0.03)
    for _, nape in ipairs(napeParts) do
        if nape and nape.Parent then
            pcall(function()
                RemotePOST:FireServer("Spears", "S_Explode", nape.Position, 10)
            end)
        end
    end
    DetonateClientSpear()
    return true
end

local function SendSlashAttack(titanModel)
    if not CanAttack() then return end
    if IsUsingSpears() then
        SendSpearAttack(titanModel)
        return
    end
    local distAttr = titanModel:GetAttribute("Distance") or 10

    local hitboxes = titanModel:FindFirstChild("Hitboxes")
    local hitPart = hitboxes and hitboxes:FindFirstChild("Hit")
    local napeHit = hitPart and hitPart:FindFirstChild("Nape")
    if not napeHit then return end

    pcall(function()
        RemotePOST:FireServer("Attacks", "Slash", true)
    end)
    pcall(function()
        RemotePOST:FireServer("Hitboxes", "Register", napeHit, distAttr, 10)
    end)
    pcall(function()
        RemotePOST:FireServer("Attacks", "Slash", false)
    end)
end

local EnableNoClip, DisableNoClip
do
    local NoClipConnection = nil
    function EnableNoClip()
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end

    function DisableNoClip()
        if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

local EnableWalkSpeed, DisableWalkSpeed
do
    local WalkSpeedConnection = nil
    function EnableWalkSpeed()
        if WalkSpeedConnection then WalkSpeedConnection:Disconnect() end
        WalkSpeedConnection = RunService.Heartbeat:Connect(function()
            if not WalkSpeedEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude < 0.1 then return end
            hrp.CFrame = hrp.CFrame + (moveDir.Unit * WalkSpeedSmoothing)
        end)
    end

    function DisableWalkSpeed()
        if WalkSpeedConnection then WalkSpeedConnection:Disconnect(); WalkSpeedConnection = nil end
    end
end

local EnableLaggyRun, DisableLaggyRun
do
    local LaggyRunConnection = nil
    local LaggyRunAccum = 0
    function EnableLaggyRun()
        if LaggyRunConnection then LaggyRunConnection:Disconnect() end
        LaggyRunAccum = 0
        LaggyRunConnection = RunService.Heartbeat:Connect(function(dt)
            if not LaggyRunEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude < 0.1 then LaggyRunAccum = 0; return end
            LaggyRunAccum = LaggyRunAccum + dt
            local delayThreshold = LaggyRunDelay * 0.1
            if LaggyRunAccum < delayThreshold then return end
            LaggyRunAccum = 0
            hrp.CFrame = hrp.CFrame + (moveDir.Unit * LaggyRunDistance)
        end)
    end

    function DisableLaggyRun()
        if LaggyRunConnection then LaggyRunConnection:Disconnect(); LaggyRunConnection = nil end
        LaggyRunAccum = 0
    end
end

local EnableCtrlClickTP, DisableCtrlClickTP
do
    local CtrlClickTPConnection = nil
    function EnableCtrlClickTP()
        if CtrlClickTPConnection then return end
        CtrlClickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not CtrlClickTPEnabled then return end
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local cam = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {char}
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 5000, raycastParams)
            if result then
                local hitPos = result.Position
                hrp.CFrame = CFrame.new(hitPos + Vector3.new(0, 3, 0)) * (hrp.CFrame - hrp.CFrame.Position)
            end
        end)
    end

    function DisableCtrlClickTP()
        if CtrlClickTPConnection then CtrlClickTPConnection:Disconnect(); CtrlClickTPConnection = nil end
    end
end

local EnableInfiniteJump, DisableInfiniteJump
do
    local InfiniteJumpConnection = nil
    function EnableInfiniteJump()
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not InfiniteJumpEnabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end

    function DisableInfiniteJump()
        if InfiniteJumpConnection then
            InfiniteJumpConnection:Disconnect()
            InfiniteJumpConnection = nil
        end
    end
end

local EnableChangeCursor, DisableChangeCursor
do
    local CursorConnection = nil
    local OriginalCursorVisible = nil
    function EnableChangeCursor()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local interface = playerGui and playerGui:FindFirstChild("Interface")
        local cursor = interface and interface:FindFirstChild("Cursor")
        if cursor and OriginalCursorVisible == nil then
            OriginalCursorVisible = cursor.Visible
        end
        if cursor then cursor.Visible = false end
        UserInputService.MouseIconEnabled = true
        if CursorConnection then CursorConnection:Disconnect() end
        CursorConnection = RunService.Heartbeat:Connect(function()
            if not ChangeCursorEnabled then return end
            if not cursor or not cursor.Parent then
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local iface = pg and pg:FindFirstChild("Interface")
                cursor = iface and iface:FindFirstChild("Cursor")
            end
            if cursor then cursor.Visible = false end
        end)
    end

    function DisableChangeCursor()
        if CursorConnection then CursorConnection:Disconnect(); CursorConnection = nil end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local interface = playerGui and playerGui:FindFirstChild("Interface")
        local cursor = interface and interface:FindFirstChild("Cursor")
        if cursor then
            cursor.Visible = OriginalCursorVisible ~= nil and OriginalCursorVisible or true
        end
        OriginalCursorVisible = nil
    end
end

local EnableAutoRetry, DisableAutoRetry
do
    local AutoRetryConnection = nil
    local function TryRetry()
        if not AutoRetryEnabled then return end
        SendRetryRemote()
    end

    function DisableAutoRetry()
        if AutoRetryConnection then
            AutoRetryConnection:Disconnect()
            AutoRetryConnection = nil
        end
    end

    function EnableAutoRetry()
        DisableAutoRetry()

        task.spawn(function()
            local rewards = nil
            pcall(function()
                rewards = LocalPlayer:WaitForChild("PlayerGui", 60)
                    :WaitForChild("Interface", 60)
                    :WaitForChild("Rewards", 60)
            end)
            if not rewards then return end

            if rewards.Visible then
                task.wait(1)
                TryRetry()
            end

            AutoRetryConnection = rewards:GetPropertyChangedSignal("Visible"):Connect(function()
                if not AutoRetryEnabled then return end
                if not rewards.Visible then return end
                task.wait(1)
                TryRetry()
            end)

            task.spawn(function()
                local lastVisible = rewards.Visible
                while AutoRetryEnabled do
                    task.wait(1)
                    if not AutoRetryEnabled then break end
                    local ok, currentVisible = pcall(function() return rewards.Visible end)
                    if not ok then break end
                    if currentVisible and not lastVisible then
                        task.wait(1)
                        TryRetry()
                    end
                    lastVisible = currentVisible
                end
            end)
        end)
    end
end

local EnableAutoSkipCutscenes, DisableAutoSkipCutscenes
do
    local AutoSkipCutscenesConnection = nil
    local AutoSkipCutscenesBusy = false
    local AutoSkipCutscenesThread = nil

    local function GetNil(name)
        local getNil = getnilinstances or get_nil_instances
        if not getNil then return nil end
        local list = getNil()
        if type(list) == "table" then
            for _, object in ipairs(list) do
                if object.Name == name then
                    return object
                end
            end
        end
        return nil
    end

    local function SendSkipKeyInput(skipButton)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)

        local interact = skipButton and (skipButton:FindFirstChild("Interact") or skipButton:FindFirstChildWhichIsA("GuiButton", true))
        if interact then
            local fireSignal = firesignal
            if fireSignal then
                pcall(function() fireSignal(interact.MouseButton1Click) end)
                pcall(function() fireSignal(interact.MouseButton1Down) end)
                pcall(function() fireSignal(interact.MouseButton1Up) end)
                pcall(function() fireSignal(interact.Activated) end)
            end
            if interact.AbsolutePosition and interact.AbsoluteSize then
                local center = interact.AbsolutePosition + (interact.AbsoluteSize / 2)
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                end)
            end
        end
    end

    local function CheckAndSkipCutscene(skip)
        if not AutoSkipCutscenesEnabled or AutoSkipCutscenesBusy then return end
        if not (skip and skip.Visible) then return end

        AutoSkipCutscenesBusy = true

        local middleObj = GetNil("Middle")
        if middleObj then
            pcall(function()
                RemotePOST:FireServer("Functions", "Finished", middleObj)
            end)
        end

        task.wait(0.3)

        if AutoSkipCutscenesEnabled and skip and skip.Visible then
            SendSkipKeyInput(skip)
        end

        task.wait(0.5)
        AutoSkipCutscenesBusy = false
    end

    function DisableAutoSkipCutscenes()
        if AutoSkipCutscenesConnection then
            AutoSkipCutscenesConnection:Disconnect()
            AutoSkipCutscenesConnection = nil
        end
        if AutoSkipCutscenesThread then
            task.cancel(AutoSkipCutscenesThread)
            AutoSkipCutscenesThread = nil
        end
        AutoSkipCutscenesBusy = false
    end

    function EnableAutoSkipCutscenes()
        DisableAutoSkipCutscenes()
        AutoSkipCutscenesThread = task.spawn(function()
            local skip = nil
            pcall(function()
                skip = LocalPlayer:WaitForChild("PlayerGui", 60)
                    :WaitForChild("Interface", 60)
                    :WaitForChild("Skip", 60)
            end)
            if not skip then return end

            if skip.Visible then
                task.spawn(function()
                    CheckAndSkipCutscene(skip)
                end)
            end

            AutoSkipCutscenesConnection = skip:GetPropertyChangedSignal("Visible"):Connect(function()
                if not AutoSkipCutscenesEnabled then return end
                if skip.Visible then
                    task.spawn(function()
                        CheckAndSkipCutscene(skip)
                    end)
                end
            end)

            while AutoSkipCutscenesEnabled do
                task.wait(0.5)
                if not AutoSkipCutscenesEnabled then break end
                if not skip or not skip.Parent then
                    if AutoSkipCutscenesConnection then
                        AutoSkipCutscenesConnection:Disconnect()
                        AutoSkipCutscenesConnection = nil
                    end
                    pcall(function()
                        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                        local iface = pgui and pgui:FindFirstChild("Interface")
                        skip = iface and iface:FindFirstChild("Skip")
                    end)
                    if skip and AutoSkipCutscenesConnection == nil then
                        AutoSkipCutscenesConnection = skip:GetPropertyChangedSignal("Visible"):Connect(function()
                            if not AutoSkipCutscenesEnabled then return end
                            if skip.Visible then
                                task.spawn(function()
                                    CheckAndSkipCutscene(skip)
                                end)
                            end
                        end)
                    end
                end
                local ok, isVisible = pcall(function() return skip and skip.Visible end)
                if ok and isVisible and not AutoSkipCutscenesBusy then
                    task.spawn(function()
                        CheckAndSkipCutscene(skip)
                    end)
                end
            end
            AutoSkipCutscenesThread = nil
        end)
    end
end



local ApplyNapeHitbox, RestoreNapeHitbox, GetNapeTopPosition, RemoveAllVisuals
do
    local OriginalNapeSizes = {}
    local HitboxVisuals = {}

    function ApplyNapeHitbox(overrideSize)
        local size = overrideSize or NapeHitboxSize
        local titans = GetAllTitans()
        for _, titan in ipairs(titans) do
            local nape = GetNapePart(titan)
            if nape and nape:IsA("BasePart") then
                if not OriginalNapeSizes[titan] then
                    OriginalNapeSizes[titan] = nape.Size
                end
                local current = math.max(nape.Size.X, nape.Size.Y, nape.Size.Z)
                if math.abs(current - size) > 0.01 then
                    nape.Size = Vector3.new(size, size, size)
                end
            end
        end
        for titan in pairs(OriginalNapeSizes) do
            if not titan.Parent then
                OriginalNapeSizes[titan] = nil
            end
        end
    end

    function RestoreNapeHitbox()
        local titans = GetAllTitans()
        for _, titan in ipairs(titans) do
            local nape = GetNapePart(titan)
            if nape and nape:IsA("BasePart") then
                if OriginalNapeSizes[titan] then
                    nape.Size = OriginalNapeSizes[titan]
                    OriginalNapeSizes[titan] = nil
                end
            end
        end
        for titan in pairs(OriginalNapeSizes) do
            if not titan.Parent then OriginalNapeSizes[titan] = nil end
        end
    end

    function GetNapeTopPosition(nape)
        local halfExtent = math.max(nape.Size.X, nape.Size.Y, nape.Size.Z) / 2
        local napeUp = nape.CFrame.UpVector
        local napeRight = nape.CFrame.RightVector
        local napeLook = nape.CFrame.LookVector
        local topCenter = nape.Position + napeUp * halfExtent
        local corner1 = topCenter + napeRight * halfExtent + napeLook * halfExtent
        local corner2 = topCenter + napeRight * halfExtent - napeLook * halfExtent
        local corner3 = topCenter - napeRight * halfExtent + napeLook * halfExtent
        local corner4 = topCenter - napeRight * halfExtent - napeLook * halfExtent
        local highest = corner1
        if corner2.Y > highest.Y then highest = corner2 end
        if corner3.Y > highest.Y then highest = corner3 end
        if corner4.Y > highest.Y then highest = corner4 end
        return highest
    end

    local function CreateOrUpdateVisuals()
        if not VisualizeHitboxEnabled then return end
        local titans = GetAllTitans()
        local activeTitans = {}
        for _, titan in ipairs(titans) do
            activeTitans[titan] = true
            local nape = GetNapePart(titan)
            if nape and nape:IsA("BasePart") then
                if not HitboxVisuals[titan] then
                    local sel = Instance.new("SelectionBox")
                    sel.Color3 = Color3.fromRGB(255, 50, 50)
                    sel.LineThickness = 0.08
                    sel.SurfaceTransparency = 1
                    sel.Adornee = nape
                    sel.Parent = Workspace.CurrentCamera
                    HitboxVisuals[titan] = sel
                end
            end
        end
        for titan, sel in pairs(HitboxVisuals) do
            if not activeTitans[titan] then
                if sel and sel.Parent then sel:Destroy() end
                HitboxVisuals[titan] = nil
            end
        end
    end

    function RemoveAllVisuals()
        for titan, sel in pairs(HitboxVisuals) do
            if sel and sel.Parent then sel:Destroy() end
        end
        HitboxVisuals = {}
    end

    RunService.Heartbeat:Connect(function()
        if ExpandNapeHitboxEnabled then
            local targetSize = AutoFarmEnabled and 100 or NapeHitboxSize
            ApplyNapeHitbox(targetSize)
        end
        if VisualizeHitboxEnabled then CreateOrUpdateVisuals() end
    end)
end

local FarmAboveOffset = 2

local function GetFarmCFrame(titan)
    local nape = GetNapePart(titan)
    if not nape then
        local hrp = titan:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local topPos = hrp.Position + Vector3.new(0, 3, 0)
        return CFrame.new(topPos + Vector3.new(0, FarmAboveOffset + DistanceToTitanAmount, 0), topPos)
    end
    if IsUsingSpears() then
        local look = nape.CFrame.LookVector
        local dist = 85 + DistanceToTitanAmount
        local targetPos = nape.Position + Vector3.new(0, 55, 0) - (look * dist)
        return CFrame.lookAt(targetPos, nape.Position)
    else
        local totalOffset = FarmAboveOffset + DistanceToTitanAmount
        local topCorner = GetNapeTopPosition(nape)
        local targetPos = topCorner + Vector3.new(0, totalOffset, 0)
        return CFrame.new(targetPos, topCorner)
    end
end

local function GetTitanHeight(model)
    local minY = math.huge
    local maxY = -math.huge
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local top = part.Position.Y + part.Size.Y / 2
            local bot = part.Position.Y - part.Size.Y / 2
            if top > maxY then maxY = top end
            if bot < minY then minY = bot end
        end
    end
    if maxY == -math.huge then return 0 end
    return maxY - minY
end

local function FindBestTitan(exclude)
    local folder = GetTitansFolder()
    if not folder then return nil end
    local best = nil
    local bestHeight = -math.huge
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model ~= exclude and IsTitanValid(model) then
            local height = GetTitanHeight(model)
            if height > bestHeight then
                bestHeight = height
                best = model
            end
        end
    end
    return best
end

local function FindBestSpearTarget(exclude)
    local folder = GetTitansFolder()
    if not folder then return nil end
    local candidates = {}
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model ~= exclude and IsTitanValid(model) and GetNapePart(model) then
            table.insert(candidates, model)
        end
    end
    if #candidates == 0 then return nil end
    if #candidates == 1 then return candidates[1] end

    local bestTarget = candidates[1]
    local bestScore = -1
    for _, c1 in ipairs(candidates) do
        local nape1 = GetNapePart(c1)
        local pos1 = nape1 and nape1.Position
        if pos1 then
            local score = 0
            for _, c2 in ipairs(candidates) do
                local nape2 = GetNapePart(c2)
                if nape2 and (nape2.Position - pos1).Magnitude <= 135 then
                    score = score + 1
                end
            end
            if score > bestScore then
                bestScore = score
                bestTarget = c1
            end
        end
    end
    return bestTarget
end

local FindNextTower, IsTowerUnbuilt, ExpandTowerHitbox
do
    local LastTowerScanTime = 0

    function IsTowerUnbuilt(towerModel)
        if not towerModel or not towerModel.Parent then return false end
        local watchTower = towerModel:FindFirstChild("Watch_Tower")
        if not watchTower then return false end
        if watchTower:FindFirstChild("H") then return false end
        local circle = towerModel:FindFirstChild("Circle")
        if not circle then return false end
        local beam1 = circle:FindFirstChild("Beam1")
        if not beam1 or not beam1:IsA("BasePart") then return false end
        return true
    end

    function ExpandTowerHitbox(towerModel)
        local circle = towerModel and towerModel:FindFirstChild("Circle")
        local hitbox = circle and circle:FindFirstChild("Hitbox")
        if hitbox and hitbox:IsA("BasePart") then
            pcall(function()
                hitbox.Size = Vector3.new(1984, 1984, 1984)
            end)
        end
    end

    function FindNextTower()
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") and child.Name:find("WatchTower") then
                ExpandTowerHitbox(child)
                if IsTowerUnbuilt(child) then
                    return child
                end
            end
        end
        local mapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Unclimbable")
        if mapFolder then
            for _, child in ipairs(mapFolder:GetChildren()) do
                if child:IsA("Model") and child.Name:find("WatchTower") then
                    ExpandTowerHitbox(child)
                    if IsTowerUnbuilt(child) then
                        return child
                    end
                end
            end
        end
        local now = os.clock()
        if now - LastTowerScanTime > 1 then
            LastTowerScanTime = now
            for _, child in ipairs(Workspace:GetDescendants()) do
                if child:IsA("Model") and child.Name:find("WatchTower") then
                    ExpandTowerHitbox(child)
                    if IsTowerUnbuilt(child) then
                        return child
                    end
                end
            end
        end
        return nil
    end
end

local function UpdateHoverStabilizer()
    local shouldRun = (AutoFarmEnabled and not KillWithoutTPEnabled) or AutoCreateTowersEnabled
    if not shouldRun then
        if HoverConnection then
            HoverConnection:Disconnect()
            HoverConnection = nil
        end
        LastHoverCFrame = nil
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        return
    end

    if HoverConnection then return end

    HoverConnection = RunService.Heartbeat:Connect(function()
        local active = (AutoFarmEnabled and not KillWithoutTPEnabled) or AutoCreateTowersEnabled
        if not active then
            if HoverConnection then
                HoverConnection:Disconnect()
                HoverConnection = nil
            end
            LastHoverCFrame = nil
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            return
        end

        if IsRetrievingCrates then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetCF = nil

        if AutoCreateTowersEnabled then
            if CurrentTowerTarget and not IsTowerUnbuilt(CurrentTowerTarget) then
                CurrentTowerTarget = nil
            end
            if not CurrentTowerTarget then
                CurrentTowerTarget = FindNextTower()
                if CurrentTowerTarget then
                    ExpandTowerHitbox(CurrentTowerTarget)
                end
            end
            if CurrentTowerTarget and IsTowerUnbuilt(CurrentTowerTarget) then
                ExpandTowerHitbox(CurrentTowerTarget)
                local circle = CurrentTowerTarget:FindFirstChild("Circle")
                local beam1 = circle and circle:FindFirstChild("Beam1")
                if beam1 and beam1:IsA("BasePart") then
                    targetCF = beam1.CFrame + Vector3.new(0, 200, 0)
                end
            end
        end

        if not targetCF and AutoFarmEnabled and not KillWithoutTPEnabled then
            if CurrentTarget and IsTitanValid(CurrentTarget) then
                targetCF = GetFarmCFrame(CurrentTarget)
            else
                targetCF = LastHoverCFrame or hrp.CFrame
            end
        end

        if targetCF then
            hum.PlatformStand = true
            LastHoverCFrame = targetCF
            hrp.CFrame = targetCF
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        elseif not AutoFarmEnabled and not CurrentTowerTarget then
            hum.PlatformStand = false
        end
    end)
end

Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Model") and desc.Name:find("WatchTower") then
        task.delay(0.2, function()
            ExpandTowerHitbox(desc)
        end)
        task.delay(1, function()
            ExpandTowerHitbox(desc)
        end)
    elseif desc.Name == "Hitbox" and desc.Parent and desc.Parent.Name == "Circle" and desc.Parent.Parent and desc.Parent.Parent.Name:find("WatchTower") then
        pcall(function()
            desc.Size = Vector3.new(1984, 1984, 1984)
        end)
    end
end)

local RetrieveSupplyCrates, StartRetrieveSupplyCratesLoop
do
    local AutoRetrieveSupplyCratesThread = nil
    local VisitedCrateCooldowns = {}

    function RetrieveSupplyCrates()
        if not AutoRetrieveSupplyCratesEnabled then return end
        local unclimbable = Workspace:FindFirstChild("Unclimbable")
        if not unclimbable then return end

        local now = tick()
        for obj in pairs(VisitedCrateCooldowns) do
            if not obj.Parent or now > (VisitedCrateCooldowns[obj] or 0) then
                VisitedCrateCooldowns[obj] = nil
            end
        end

        local thunderSpearModels = {}
        for _, child in ipairs(unclimbable:GetChildren()) do
            if child:IsA("Model") and child.Name:find("ThunderSpear") then
                if not VisitedCrateCooldowns[child] or now > VisitedCrateCooldowns[child] then
                    table.insert(thunderSpearModels, child)
                end
            end
        end

        if #thunderSpearModels == 0 then return end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        IsRetrievingCrates = true

        for _, tsModel in ipairs(thunderSpearModels) do
            if not AutoRetrieveSupplyCratesEnabled then break end
            VisitedCrateCooldowns[tsModel] = tick() + 4
            local hitbox = tsModel:FindFirstChild("Hitbox") or tsModel:FindFirstChild("Hitbox", true)
            if hitbox and hitbox:IsA("BasePart") then
                pcall(function()
                    hitbox.Size = Vector3.new(1984, 1984, 1984)
                end)
                hrp.CFrame = hitbox.CFrame
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait(0.2)
            elseif tsModel.PrimaryPart then
                hrp.CFrame = tsModel.PrimaryPart.CFrame
                task.wait(0.2)
            end
        end

        if AutoRetrieveSupplyCratesEnabled then
            local suppliesCircle = unclimbable:FindFirstChild("Supplies_Circle")
            if suppliesCircle then
                local hitbox = suppliesCircle:FindFirstChild("Hitbox") or suppliesCircle:FindFirstChild("Hitbox", true)
                if hitbox and hitbox:IsA("BasePart") then
                    pcall(function()
                        hitbox.Size = Vector3.new(1984, 1984, 1984)
                    end)
                    hrp.CFrame = hitbox.CFrame
                    pcall(function()
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    task.wait(0.2)
                elseif suppliesCircle.PrimaryPart then
                    hrp.CFrame = suppliesCircle.PrimaryPart.CFrame
                    task.wait(0.2)
                end
            end
        end

        IsRetrievingCrates = false
    end

    function StartRetrieveSupplyCratesLoop()
        if AutoRetrieveSupplyCratesThread then return end
        AutoRetrieveSupplyCratesThread = task.spawn(function()
            while AutoRetrieveSupplyCratesEnabled do
                RetrieveSupplyCrates()
                task.wait(0.5)
            end
            AutoRetrieveSupplyCratesThread = nil
        end)
    end

    local function BindUnclimbable(folder)
        if not folder then return end
        folder.ChildAdded:Connect(function(child)
            if AutoRetrieveSupplyCratesEnabled and child:IsA("Model") and child.Name:find("ThunderSpear") then
                task.delay(0.1, RetrieveSupplyCrates)
            end
        end)
    end

    local initialUnclimbable = Workspace:FindFirstChild("Unclimbable")
    if initialUnclimbable then
        BindUnclimbable(initialUnclimbable)
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Unclimbable" then
            BindUnclimbable(child)
        end
    end)
end

local function FarmLoop()
    UpdateHoverStabilizer()

    local isFirstTitan = true

    while AutoFarmEnabled do
        if not AutoFarmEnabled then break end

        if AutoReloadEnabled and not IsReloading then
            if IsUsingSpears() and GetSpearsEmpty() then
                PerformReload()
            elseif IsUsingBlades() and GetBladesBroken() then
                PerformReload()
            end
        end

        if not AutoFarmEnabled then break end

        if AutoRefillEnabled and not IsRefilling and IsUsingBlades() then
            if NeedsRefill() then
                task.spawn(RefillUntilFull)
                while IsRefilling do task.wait(0.2) end
            end
        end

        if not AutoFarmEnabled then break end
        if not CanAttack() then task.wait(0.1); continue end

        if HitAllEnabled then
            local allTitans = GetAllTitans()
            local validEntries = {}
            for _, titan in ipairs(allTitans) do
                if IsTitanValid(titan) then
                    local nape = GetNapePart(titan)
                    if nape then
                        table.insert(validEntries, { nape = nape, titan = titan })
                    end
                end
            end

            if #validEntries == 0 then
                CurrentTarget = nil
                task.wait(0.2)
                continue
            end

            local batchSize = 8
            if IsUsingSpears() then
                for i = 1, #validEntries, batchSize do
                    if not CanAttack() or not AutoFarmEnabled or not HitAllEnabled then break end
                    if AutoReloadEnabled and not IsReloading and GetSpearsEmpty() then
                        PerformReload()
                        if GetSpearsEmpty() then break end
                    end

                    local batch = {}
                    for j = i, math.min(i + batchSize - 1, #validEntries) do
                        local entry = validEntries[j]
                        if entry.titan and IsTitanValid(entry.titan) and entry.nape and entry.nape.Parent then
                            table.insert(batch, entry)
                        end
                    end
                    if #batch == 0 then continue end

                    CurrentTarget = batch[1].titan
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    if not KillWithoutTPEnabled and hrp and CurrentTarget then
                        local farmCF = GetFarmCFrame(CurrentTarget)
                        if farmCF then
                            hrp.CFrame = farmCF
                            LastHoverCFrame = farmCF
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end

                    local napeBatch = {}
                    for _, entry in ipairs(batch) do
                        table.insert(napeBatch, entry.nape)
                    end

                    local fired = SendSpearAttack(napeBatch)
                    if fired then
                        local waitTime = DelayToKillEnabled and math.max(DelayToKillAmount, 0.15) or 0.15
                        task.wait(waitTime)
                    else
                        task.wait(0.08)
                    end
                end
                task.wait(0.1)
            elseif IsUsingBlades() then
                if not KillWithoutTPEnabled then
                    CurrentTarget = FindBestTitan()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and CurrentTarget then
                        local farmCF = GetFarmCFrame(CurrentTarget)
                        if farmCF then
                            hrp.CFrame = farmCF
                            LastHoverCFrame = farmCF
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                else
                    CurrentTarget = nil
                end

                for i = 1, #validEntries, batchSize do
                    if not CanAttack() or not AutoFarmEnabled or not HitAllEnabled then break end
                    pcall(function() RemotePOST:FireServer("Attacks", "Slash", true) end)
                    for j = i, math.min(i + batchSize - 1, #validEntries) do
                        if not CanAttack() then break end
                        local entryNape = validEntries[j].nape
                        if entryNape and entryNape.Parent then
                            pcall(function()
                                RemotePOST:FireServer("Hitboxes", "Register", entryNape, 9e4, 9e4)
                            end)
                        end
                    end
                    task.wait(0.02)
                    pcall(function() RemotePOST:FireServer("Attacks", "Slash", false) end)

                    if DelayToKillEnabled and i + batchSize <= #validEntries then
                        task.wait(DelayToKillAmount)
                    else
                        task.wait(0.1)
                    end
                end
                task.wait(0.15)
            end
            continue
        end

        if not CurrentTarget or not IsTitanValid(CurrentTarget) then
            CurrentTarget = IsUsingSpears() and FindBestSpearTarget() or FindBestTitan()
        end
        if not CurrentTarget or not IsTitanValid(CurrentTarget) then
            task.wait(0.2)
            continue
        end

        if not CanAttack() then task.wait(0.1); continue end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not KillWithoutTPEnabled and not IsRetrievingCrates and (not AutoCreateTowersEnabled or not CurrentTowerTarget) then
            if hrp then
                local farmCF = GetFarmCFrame(CurrentTarget)
                if farmCF then
                    hrp.CFrame = farmCF
                    LastHoverCFrame = farmCF
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end

        if not AutoFarmEnabled then break end

        if IsUsingSpears() then
            local nape = GetNapePart(CurrentTarget)
            if nape and CanAttack() then
                SendSpearAttack(CurrentTarget)
            end

            local waitStart = os.clock()
            local maxWait = DelayToKillEnabled and math.max(DelayToKillAmount, 0.4) or 0.45
            while AutoFarmEnabled and not HitAllEnabled and (os.clock() - waitStart < maxWait) do
                task.wait(0.04)
                if not IsTitanValid(CurrentTarget) then break end
                if not KillWithoutTPEnabled and not IsRetrievingCrates and (not AutoCreateTowersEnabled or not CurrentTowerTarget) then
                    local c = LocalPlayer.Character
                    local h = c and c:FindFirstChild("HumanoidRootPart")
                    if h and CurrentTarget and IsTitanValid(CurrentTarget) then
                        local farmCF = GetFarmCFrame(CurrentTarget)
                        if farmCF then
                            h.CFrame = farmCF
                            LastHoverCFrame = farmCF
                            h.AssemblyLinearVelocity = Vector3.zero
                            h.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end
            end

            if not AutoFarmEnabled then break end

            if not IsTitanValid(CurrentTarget) then
                local deadTarget = CurrentTarget
                local nextTarget = FindBestSpearTarget(deadTarget)
                if nextTarget then
                    CurrentTarget = nextTarget
                    if not KillWithoutTPEnabled and not IsRetrievingCrates and (not AutoCreateTowersEnabled or not CurrentTowerTarget) then
                        local c = LocalPlayer.Character
                        local h = c and c:FindFirstChild("HumanoidRootPart")
                        if h then
                            local nextCF = GetFarmCFrame(nextTarget)
                            if nextCF then
                                h.CFrame = nextCF
                                LastHoverCFrame = nextCF
                                h.AssemblyLinearVelocity = Vector3.zero
                                h.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end
                else
                    CurrentTarget = nil
                end

                if DelayToKillEnabled and not isFirstTitan then
                    task.wait(DelayToKillAmount)
                end
                isFirstTitan = false
            end
        else
            while AutoFarmEnabled and not HitAllEnabled do
                task.wait(0.2)
                if not AutoFarmEnabled then break end

                if AutoReloadEnabled and not IsReloading and IsUsingBlades() and GetBladesBroken() then
                    PerformReload()
                end

                if AutoRefillEnabled and not IsRefilling and IsUsingBlades() and NeedsRefill() then
                    task.spawn(RefillUntilFull)
                    while IsRefilling do task.wait(0.2) end
                end
                if not AutoFarmEnabled then break end
                if not CanAttack() then continue end

                if not IsTitanValid(CurrentTarget) then
                    local deadTarget = CurrentTarget
                    local nextTarget = FindBestTitan(deadTarget)
                    if nextTarget then
                        CurrentTarget = nextTarget
                        if not KillWithoutTPEnabled and not IsRetrievingCrates and (not AutoCreateTowersEnabled or not CurrentTowerTarget) then
                            local c = LocalPlayer.Character
                            local h = c and c:FindFirstChild("HumanoidRootPart")
                            if h then
                                local farmCF = GetFarmCFrame(nextTarget)
                                if farmCF then
                                    h.CFrame = farmCF
                                    LastHoverCFrame = farmCF
                                    h.AssemblyLinearVelocity = Vector3.zero
                                    h.AssemblyAngularVelocity = Vector3.zero
                                end
                            end
                        end
                    else
                        CurrentTarget = nil
                    end

                    if DelayToKillEnabled and not isFirstTitan then
                        task.wait(DelayToKillAmount)
                    end
                    isFirstTitan = false

                    break
                end

                if not KillWithoutTPEnabled and not IsRetrievingCrates and (not AutoCreateTowersEnabled or not CurrentTowerTarget) then
                    local c = LocalPlayer.Character
                    local h = c and c:FindFirstChild("HumanoidRootPart")
                    if h then
                        local farmCF = GetFarmCFrame(CurrentTarget)
                        if farmCF then
                            h.CFrame = farmCF
                            LastHoverCFrame = farmCF
                            h.AssemblyLinearVelocity = Vector3.zero
                            h.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end

                local napeNow = GetNapePart(CurrentTarget)
                if napeNow and CanAttack() then
                    pcall(function() SendSlashAttack(CurrentTarget) end)
                end
            end
        end
    end

    UpdateHoverStabilizer()
    CurrentTarget = nil
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if not AutoReloadEnabled then continue end
        if AutoFarmEnabled then continue end
        if IsReloading or IsRefilling then continue end
        if IsUsingSpears() then
            if GetSpearsEmpty() then
                PerformReload()
            end
        elseif IsUsingBlades() then
            if GetBladesBroken() then
                PerformReload()
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not AutoRefillEnabled or not IsUsingBlades() then
            SetsWentEmptyAt = nil
            continue
        end
        if AutoFarmEnabled then continue end
        if IsRefilling then continue end
        if NeedsRefill() then
            task.spawn(RefillUntilFull)
        end
    end
end)

local RemoveAllTitanESP
do
    local TitanESPObjects = {}

    function RemoveAllTitanESP()
        for _, obj in pairs(TitanESPObjects) do
            if obj.highlight and obj.highlight.Parent then obj.highlight:Destroy() end
            if obj.billboard and obj.billboard.Parent then obj.billboard:Destroy() end
        end
        TitanESPObjects = {}
    end

    local function CreateTitanESP(model)
        if TitanESPObjects[model] then return end
        local rootPart = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChildWhichIsA("BasePart") or model.PrimaryPart
        if not rootPart then return end
        local highlight = Instance.new("SelectionBox")
        highlight.Color3 = Color3.fromRGB(120, 80, 255)
        highlight.LineThickness = 0.07
        highlight.SurfaceTransparency = 0.85
        highlight.SurfaceColor3 = Color3.fromRGB(120, 80, 255)
        highlight.Adornee = model
        highlight.Parent = Workspace.CurrentCamera
        local billboard = Instance.new("BillboardGui")
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 160, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.Adornee = rootPart
        billboard.Parent = Workspace.CurrentCamera
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.52, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 170, 255)
        nameLabel.TextStrokeTransparency = 0.35
        nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 5, 50)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Text = "Titan"
        nameLabel.Parent = billboard
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.48, 0)
        distLabel.Position = UDim2.new(0, 0, 0.52, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        distLabel.TextStrokeTransparency = 0.35
        distLabel.TextStrokeColor3 = Color3.fromRGB(20, 5, 50)
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextSize = 13
        distLabel.Text = "-- m"
        distLabel.Parent = billboard
        TitanESPObjects[model] = {
            highlight = highlight,
            billboard = billboard,
            distLabel = distLabel,
            rootPart = rootPart,
            lastDist = nil,
        }
    end

    RunService.Heartbeat:Connect(function()
        if not TitanESPEnabled then return end
        local character = LocalPlayer.Character
        local charHRP = character and character:FindFirstChild("HumanoidRootPart")
        local titansFolder = GetTitansFolder()
        local activeModels = {}
        if titansFolder then
            for _, model in pairs(titansFolder:GetChildren()) do
                if model:IsA("Model") then
                    activeModels[model] = true
                    if not TitanESPObjects[model] then CreateTitanESP(model) end
                end
            end
        end
        local toRemove = {}
        for model in pairs(TitanESPObjects) do
            if not activeModels[model] then table.insert(toRemove, model) end
        end
        for _, model in ipairs(toRemove) do
            local obj = TitanESPObjects[model]
            if obj.highlight and obj.highlight.Parent then obj.highlight:Destroy() end
            if obj.billboard and obj.billboard.Parent then obj.billboard:Destroy() end
            TitanESPObjects[model] = nil
        end
        if charHRP then
            for _, entry in pairs(TitanESPObjects) do
                if entry.rootPart and entry.rootPart.Parent then
                    local dist = math.floor((charHRP.Position - entry.rootPart.Position).Magnitude)
                    if entry.lastDist ~= dist then
                        entry.lastDist = dist
                        entry.distLabel.Text = dist .. " m"
                    end
                end
            end
        end
    end)
end


do
    local AutoFamilySpinThread = nil
    local AutoSellPerksThread = nil

    local Window = Library:CreateWindow({
    Title = " Symbiote ",
    Size = UDim2.new(0, 580, 0, 440),
})

local PlayerTab = Window:CreateTab("Player")
local AutoFarmTab = Window:CreateTab("Auto Farm")
local VariousTab = Window:CreateTab("Various")
local StatsTab = Window:CreateTab("Stats")

local StatsFile = "Symbiote_AOTR_Stats.json"

local function LoadStatsJson()
    local raw = ReadFileContent(StatsFile)
    if not raw then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local StatsData
do
    local LoadedData = LoadStatsJson() or {}
    StatsData = {
        Player = {
            Prestige = tonumber(LoadedData.Player and LoadedData.Player.Prestige) or 0,
            Level = tonumber(LoadedData.Player and LoadedData.Player.Level) or 1,
            Gems = tonumber(LoadedData.Player and LoadedData.Player.Gems) or 0,
            Gold = tonumber(LoadedData.Player and LoadedData.Player.Gold) or 0,
        },
        LastRound = {
            TimeTaken = tostring(LoadedData.LastRound and LoadedData.LastRound.TimeTaken or "00:00"),
            Difficulty = tostring(LoadedData.LastRound and LoadedData.LastRound.Difficulty or "N/A"),
            TitansKilled = tonumber(LoadedData.LastRound and LoadedData.LastRound.TitansKilled) or 0,
            DamageDealt = tonumber(LoadedData.LastRound and LoadedData.LastRound.DamageDealt) or 0,
            Gold = tonumber(LoadedData.LastRound and LoadedData.LastRound.Gold) or 0,
            Gems = tonumber(LoadedData.LastRound and LoadedData.LastRound.Gems) or 0,
            XP = tonumber(LoadedData.LastRound and LoadedData.LastRound.XP) or 0,
            Items = (LoadedData.LastRound and type(LoadedData.LastRound.Items) == "table") and LoadedData.LastRound.Items or {},
        },
        Session = {
            MissionsCompleted = tonumber(LoadedData.Session and LoadedData.Session.MissionsCompleted) or 0,
            TotalSeconds = tonumber(LoadedData.Session and LoadedData.Session.TotalSeconds) or 0,
            FastestSeconds = tonumber(LoadedData.Session and LoadedData.Session.FastestSeconds) or 0,
            TitansKilled = tonumber(LoadedData.Session and LoadedData.Session.TitansKilled) or 0,
            DamageDealt = tonumber(LoadedData.Session and LoadedData.Session.DamageDealt) or 0,
            Gold = tonumber(LoadedData.Session and LoadedData.Session.Gold) or 0,
            Gems = tonumber(LoadedData.Session and LoadedData.Session.Gems) or 0,
            XP = tonumber(LoadedData.Session and LoadedData.Session.XP) or 0,
            Items = (LoadedData.Session and type(LoadedData.Session.Items) == "table") and LoadedData.Session.Items or {},
            RarityCounts = (LoadedData.Session and type(LoadedData.Session.RarityCounts) == "table") and LoadedData.Session.RarityCounts or {
                Common = 0,
                Uncommon = 0,
                Rare = 0,
                Epic = 0,
                Legendary = 0,
                Mythic = 0,
                Secret = 0,
            },
        },
    }
end

local function SaveStatsJson()
    local ok, enc = pcall(function()
        return HttpService:JSONEncode(StatsData)
    end)
    if ok and enc then
        WriteFileContent(StatsFile, enc)
    end
end

local LiveRoundData = {
    Status = "In Progress",
    Seconds = 0,
    Difficulty = "N/A",
}

local PendingRoundDrops = {
    Gold = 0,
    Gems = 0,
    XP = 0,
    Items = {},
    Rarities = {},
}

local IgnoredDropNames = {
    ["Common_Perk"] = true,
    ["Uncommon_Perk"] = true,
    ["Rare_Perk"] = true,
    ["Epic_Perk"] = true,
    ["Legendary_Perk"] = true,
    ["Mythic_Perk"] = true,
    ["Common Perk"] = true,
    ["Uncommon Perk"] = true,
    ["Rare Perk"] = true,
    ["Epic Perk"] = true,
    ["Legendary Perk"] = true,
    ["Mythic Perk"] = true,
}

local function IsIgnoredDrop(name)
    if not name or name == "" then return true end
    if IgnoredDropNames[name] then return true end
    if name:match("[_%s]Perk$") then return true end
    return false
end

local RoundState = "Playing"
local FinalizeDebounce = false
local RoundStartTime = os.clock()

local function FormatNumber(num)
    if not num then return "0" end
    local n = math.floor(tonumber(num) or 0)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return formatted
end

local function FormatSeconds(sec)
    local total = math.max(0, math.floor(tonumber(sec) or 0))
    local m = math.floor(total / 60)
    local s = total % 60
    return string.format("%02d:%02d", m, s)
end

local function FormatAverageTime(totalSec, count)
    if not count or count <= 0 then return "00:00" end
    local avg = math.floor(totalSec / count)
    local low = math.max(0, math.floor(avg / 5) * 5)
    local high = low + 5
    return string.format("%s - %s", FormatSeconds(low), FormatSeconds(high))
end

local CachedModules = {}

local function GetPerksModule()
    if not CachedModules.Perks then
        pcall(function()
            CachedModules.Perks = require(ReplicatedStorage.Modules.Storage.Perks)
        end)
    end
    return CachedModules.Perks
end

local function GetItemsModule()
    if not CachedModules.Items then
        pcall(function()
            CachedModules.Items = require(ReplicatedStorage.Modules.Storage.Items)
        end)
    end
    return CachedModules.Items
end

local function GetValuesModule()
    if not CachedModules.Values then
        pcall(function()
            CachedModules.Values = require(ReplicatedStorage.Modules.Storage.Values)
        end)
    end
    return CachedModules.Values
end

local function GetPerkRarity(perkName)
    local perksMod = GetPerksModule()
    if type(perksMod) == "table" then
        local cleaned = string.gsub(perkName, "_", " ")
        for rarity, list in pairs(perksMod) do
            if type(list) == "table" and (list[perkName] or list[cleaned]) then
                return rarity
            end
        end
    end
    return "Rare"
end

local function GetItemRarity(itemName)
    local itemsMod = GetItemsModule()
    if type(itemsMod) == "table" then
        local cleaned = string.gsub(itemName, "_", " ")
        if itemsMod[itemName] then return itemsMod[itemName].Rarity end
        if itemsMod[cleaned] then return itemsMod[cleaned].Rarity end
    end
    return nil
end

local StatsLabels = {}
do
    local dummySectionRef = StatsTab:AddLabel("PLAYER STATS:")
    local statsPage = dummySectionRef.Row.Parent

    local function CreateStatsCard()
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -8, 0, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
        container.BackgroundTransparency = 0.2
        container.BorderSizePixel = 0
        container.Parent = statsPage

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(48, 40, 70)
        stroke.Thickness = 1
        stroke.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 14)
        padding.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(225, 220, 240)
        label.Font = Enum.Font.RobotoMono
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextWrapped = true
        label.Parent = container

        return label
    end

    StatsLabels.Player = CreateStatsCard()
    StatsTab:AddLabel("MISSION STATS (LIVE):")
    StatsLabels.LiveMission = CreateStatsCard()
    StatsTab:AddLabel("LAST ROUND STATS:")
    StatsLabels.LastRound = CreateStatsCard()
    StatsTab:AddLabel("TOTAL SESSION STATS:")
    StatsLabels.Session = CreateStatsCard()
end

local function UpdateStatsUI()
    StatsLabels.Player.Text = string.format(
        "Prestige: %s\nLevel: %s\nGems: %s\nGold: %s",
        FormatNumber(StatsData.Player.Prestige),
        FormatNumber(StatsData.Player.Level),
        FormatNumber(StatsData.Player.Gems),
        FormatNumber(StatsData.Player.Gold)
    )

    StatsLabels.LiveMission.Text = string.format(
        "Status: %s\nTime: %s\nDifficulty: %s",
        LiveRoundData.Status,
        FormatSeconds(LiveRoundData.Seconds),
        LiveRoundData.Difficulty
    )

    local lastRound = StatsData.LastRound
    local lastRoundDropCount = (lastRound.Items and #lastRound.Items) or 0
    local lastRoundLines = {
        "Time Taken: " .. tostring(lastRound.TimeTaken),
        "Difficulty: " .. tostring(lastRound.Difficulty),
        "Titans Killed: " .. FormatNumber(lastRound.TitansKilled or 0),
        "Damage Dealt: " .. FormatNumber(lastRound.DamageDealt or 0),
        "Gold: " .. FormatNumber(lastRound.Gold),
        "Gems: " .. FormatNumber(lastRound.Gems),
        "XP: " .. FormatNumber(lastRound.XP),
        "Drops (" .. tostring(lastRoundDropCount) .. "):",
    }
    if lastRoundDropCount > 0 then
        for _, itm in ipairs(lastRound.Items) do
            table.insert(lastRoundLines, "  " .. itm)
        end
    else
        table.insert(lastRoundLines, "  None")
    end
    StatsLabels.LastRound.Text = table.concat(lastRoundLines, "\n")

    local sess = StatsData.Session
    local count = sess.MissionsCompleted or 0
    local fastestStr = (sess.FastestSeconds and sess.FastestSeconds > 0)
        and FormatSeconds(sess.FastestSeconds)
        or "00:00"
    local avgStr = FormatAverageTime(sess.TotalSeconds or 0, count)

    local rc = sess.RarityCounts or {}
    local rarityLines = {
        string.format("Common: %s | Uncommon: %s | Rare: %s",
            FormatNumber(rc.Common or 0),
            FormatNumber(rc.Uncommon or 0),
            FormatNumber(rc.Rare or 0)
        ),
        string.format("Epic: %s | Legendary: %s | Mythic: %s",
            FormatNumber(rc.Epic or 0),
            FormatNumber(rc.Legendary or 0),
            FormatNumber(rc.Mythic or 0)
        ),
    }
    if (rc.Secret or 0) > 0 then
        table.insert(rarityLines, string.format("Secret: %s", FormatNumber(rc.Secret)))
    end

    local sessionLines = {
        "Missions Completed: " .. FormatNumber(count),
        "Fastest Time: " .. fastestStr,
        "Average Time: " .. avgStr,
        "Titans Killed: " .. FormatNumber(sess.TitansKilled or 0),
        "Damage Dealt: " .. FormatNumber(sess.DamageDealt or 0),
        "Gold: " .. FormatNumber(sess.Gold or 0),
        "Gems: " .. FormatNumber(sess.Gems or 0),
        "XP: " .. FormatNumber(sess.XP or 0),
        "Total Drops: " .. tostring(#(sess.Items or {})),
        "Rarity Breakdown:\n  " .. table.concat(rarityLines, "\n  "),
    }
    StatsLabels.Session.Text = table.concat(sessionLines, "\n")
end

local function FetchPlayerStats()
    local updated = false
    local isMainMenu = (game.PlaceId == 14916516914)

    if isMainMenu then
        local pAttr = LocalPlayer:GetAttribute("Prestige")
        if pAttr ~= nil then
            StatsData.Player.Prestige = tonumber(pAttr) or StatsData.Player.Prestige
            updated = true
        end

        local lAttr = LocalPlayer:GetAttribute("Level")
        if lAttr ~= nil then
            StatsData.Player.Level = tonumber(lAttr) or StatsData.Player.Level
            updated = true
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local iface = pg and pg:FindFirstChild("Interface")
        local topbar = iface and iface:FindFirstChild("Topbar")
        if topbar and topbar:FindFirstChild("Main") and topbar.Main:FindFirstChild("Currencies") then
            local curr = topbar.Main.Currencies
            local goldNode = curr:FindFirstChild("Gold") and curr.Gold:FindFirstChild("Amount")
            local gemsNode = curr:FindFirstChild("Gems") and curr.Gems:FindFirstChild("Amount")
            if goldNode and goldNode:IsA("TextLabel") then
                local rawGold = goldNode.Text:gsub(",", ""):gsub("%s", "")
                local nGold = tonumber(rawGold)
                if nGold then
                    StatsData.Player.Gold = nGold
                    updated = true
                end
            end
            if gemsNode and gemsNode:IsA("TextLabel") then
                local rawGems = gemsNode.Text:gsub(",", ""):gsub("%s", "")
                local nGems = tonumber(rawGems)
                if nGems then
                    StatsData.Player.Gems = nGems
                    updated = true
                end
            end
        end
    else
        local lAttr = LocalPlayer:GetAttribute("Level")
        if lAttr ~= nil then
            StatsData.Player.Level = tonumber(lAttr) or StatsData.Player.Level
            updated = true
        end

        local pAttr = LocalPlayer:GetAttribute("Prestige")
        if pAttr ~= nil then
            StatsData.Player.Prestige = tonumber(pAttr) or StatsData.Player.Prestige
            updated = true
        end

        local ok, _, playerProfileData = pcall(function()
            return RemoteGET:InvokeServer("S_Rewards", "Get")
        end)
        if ok and type(playerProfileData) == "table" then
            if playerProfileData.Progression and type(playerProfileData.Progression) == "table" then
                if playerProfileData.Progression.Prestige ~= nil then
                    StatsData.Player.Prestige = tonumber(playerProfileData.Progression.Prestige) or StatsData.Player.Prestige
                    updated = true
                end
                if playerProfileData.Progression.Level ~= nil then
                    StatsData.Player.Level = tonumber(playerProfileData.Progression.Level) or StatsData.Player.Level
                    updated = true
                end
            end
            if playerProfileData.Currency and type(playerProfileData.Currency) == "table" then
                if playerProfileData.Currency.Gold ~= nil then
                    StatsData.Player.Gold = tonumber(playerProfileData.Currency.Gold) or StatsData.Player.Gold
                    updated = true
                end
                if playerProfileData.Currency.Gems ~= nil then
                    StatsData.Player.Gems = tonumber(playerProfileData.Currency.Gems) or StatsData.Player.Gems
                    updated = true
                end
            end
        end
    end

    if updated then
        SaveStatsJson()
    end

    UpdateStatsUI()
end

local function FinalizeRound()
    if RoundState == "Ended" or FinalizeDebounce then return end
    FinalizeDebounce = true
    RoundState = "Ended"

    task.wait(0.6)

    LiveRoundData.Status = "Completed"

    local finSec = tonumber(Workspace:GetAttribute("Seconds"))
    if not finSec or finSec <= 0 then
        finSec = math.max(1, LiveRoundData.Seconds)
    end

    local finDiff = Workspace:GetAttribute("Difficulty")
    if not finDiff or tostring(finDiff) == "" or tostring(finDiff) == "N/A" then
        if LiveRoundData.Difficulty and LiveRoundData.Difficulty ~= "N/A" then
            finDiff = LiveRoundData.Difficulty
        elseif StatsData.LastRound.Difficulty and StatsData.LastRound.Difficulty ~= "N/A" then
            finDiff = StatsData.LastRound.Difficulty
        else
            finDiff = "Easy"
        end
    end
    finDiff = tostring(finDiff)

    local roundKills = 0
    local roundDamage = 0

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local iface = pg and pg:FindFirstChild("Interface")
    local rewGui = iface and iface:FindFirstChild("Rewards")
    local itemsFolder = nil
    if rewGui and rewGui:FindFirstChild("Main") and rewGui.Main:FindFirstChild("Info") then
        local infoMain = rewGui.Main.Info.Main
        local statsFolder = infoMain:FindFirstChild("Stats")
        if statsFolder then
            local timeNode = statsFolder:FindFirstChild("Time_Taken") and statsFolder.Time_Taken:FindFirstChild("Amount")
            if timeNode and timeNode:IsA("TextLabel") and timeNode.Text ~= "" and timeNode.Text ~= "00:00" then
                local minStr, secStr = string.match(timeNode.Text, "(%d+):(%d+)")
                if minStr and secStr then
                    local parsedSec = (tonumber(minStr) or 0) * 60 + (tonumber(secStr) or 0)
                    if parsedSec > 0 then
                        finSec = parsedSec
                    end
                end
            end
            local killsNode = statsFolder:FindFirstChild("Kills") and statsFolder.Kills:FindFirstChild("Amount")
            if killsNode and killsNode:IsA("TextLabel") then
                local rawK = killsNode.Text:gsub(",", ""):gsub("%s", "")
                roundKills = tonumber(rawK) or 0
            end
            local dmgNode = statsFolder:FindFirstChild("Damage") and statsFolder.Damage:FindFirstChild("Amount")
            if dmgNode and dmgNode:IsA("TextLabel") then
                local rawD = dmgNode.Text:gsub(",", ""):gsub("%s", "")
                roundDamage = tonumber(rawD) or 0
            end
        end

        itemsFolder = infoMain:FindFirstChild("Items")
    end

    local roundGold = PendingRoundDrops.Gold
    local roundGems = PendingRoundDrops.Gems
    local roundXP = PendingRoundDrops.XP
    local roundItems = {}
    local roundRarities = {}

    local okRem, roundRewardsData, playerProfileData = pcall(function()
        return RemoteGET:InvokeServer("S_Rewards", "Get")
    end)
    local gotServerDrops = false
    if okRem and type(roundRewardsData) == "table" then
        if roundRewardsData.Seconds and tonumber(roundRewardsData.Seconds) and tonumber(roundRewardsData.Seconds) > 0 then
            finSec = tonumber(roundRewardsData.Seconds)
        end
        if roundRewardsData.Stats and type(roundRewardsData.Stats) == "table" then
            if tonumber(roundRewardsData.Stats.Kills) and tonumber(roundRewardsData.Stats.Kills) > roundKills then
                roundKills = tonumber(roundRewardsData.Stats.Kills)
            end
            if tonumber(roundRewardsData.Stats.Damage) and tonumber(roundRewardsData.Stats.Damage) > roundDamage then
                roundDamage = tonumber(roundRewardsData.Stats.Damage)
            end
        end
        local obt = roundRewardsData.Obtained
        if type(obt) == "table" then
            local g = tonumber(obt.Gold) or 0
            local gm = tonumber(obt.Gems) or 0
            local x = tonumber(obt.XP) or 0
            if g > 0 then roundGold = g end
            if gm > 0 then roundGems = gm end
            if x > 0 then roundXP = x end

            if type(obt.Perks) == "table" then
                for _, pName in ipairs(obt.Perks) do
                    if not IsIgnoredDrop(pName) then
                        local r = GetPerkRarity(pName) or "Common"
                        local clean = string.gsub(pName, "_", " ") .. " (" .. r .. ")"
                        table.insert(roundItems, clean)
                        table.insert(roundRarities, r)
                    end
                end
            end
            if type(obt.Drops) == "table" then
                for _, dName in ipairs(obt.Drops) do
                    if not IsIgnoredDrop(dName) then
                        local r = GetItemRarity(dName) or "Common"
                        local clean = string.gsub(dName, "_", " ") .. " (" .. r .. ")"
                        table.insert(roundItems, clean)
                        table.insert(roundRarities, r)
                    end
                end
            end
            if type(obt.Chests) == "table" then
                for _, cName in ipairs(obt.Chests) do
                    if not IsIgnoredDrop(cName) then
                        local r = GetItemRarity(cName) or "Rare"
                        local clean = string.gsub(cName, "_", " ") .. " (" .. r .. ")"
                        table.insert(roundItems, clean)
                        table.insert(roundRarities, r)
                    end
                end
            end
            gotServerDrops = true
        end
    end

    if (not gotServerDrops or #roundItems == 0) and #PendingRoundDrops.Items > 0 then
        roundItems = table.clone(PendingRoundDrops.Items)
        roundRarities = table.clone(PendingRoundDrops.Rarities)
        if PendingRoundDrops.Gold > 0 then roundGold = PendingRoundDrops.Gold end
        if PendingRoundDrops.Gems > 0 then roundGems = PendingRoundDrops.Gems end
        if PendingRoundDrops.XP > 0 then roundXP = PendingRoundDrops.XP end
    elseif (not gotServerDrops or #roundItems == 0) and itemsFolder then
        for _, child in ipairs(itemsFolder:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("Main") and child.Main:FindFirstChild("Inner") then
                local inner = child.Main.Inner
                local qNode = inner:FindFirstChild("Quantity")
                local qText = qNode and qNode.Text or ""
                local rawQty = qText:gsub(",", ""):gsub("%+", ""):gsub("%s", "")
                local nQty = tonumber(rawQty) or 1
                local rFrame = inner:FindFirstChild("Rarity")
                local rColor = rFrame and rFrame.BackgroundColor3
                local matchedRarity = "Common"
                local valMod = GetValuesModule()
                if valMod and valMod.Colours then
                    for rName, cVal in pairs(valMod.Colours) do
                        if rColor and math.abs(rColor.R - cVal.R) < 0.05 and math.abs(rColor.G - cVal.G) < 0.05 and math.abs(rColor.B - cVal.B) < 0.05 then
                            matchedRarity = rName
                            break
                        end
                    end
                end
                local icon = inner:FindFirstChild("Icon")
                local img = icon and icon.Image or ""
                local itemName = nil
                local itemMod = GetItemsModule()
                if itemMod then
                    for iName, iData in pairs(itemMod) do
                        if iData.Image and tostring(iData.Image) ~= "" and img:find(tostring(iData.Image)) then
                            itemName = iName
                            break
                        end
                    end
                end
                if itemName and not IsIgnoredDrop(itemName) then
                    if itemName == "Gold" and roundGold == 0 then
                        roundGold = nQty
                    elseif itemName == "Gems" and roundGems == 0 then
                        roundGems = nQty
                    elseif itemName == "XP" and roundXP == 0 then
                        roundXP = nQty
                    else
                        local clean = string.gsub(itemName, "_", " ") .. " (" .. matchedRarity .. ")"
                        table.insert(roundItems, clean)
                        table.insert(roundRarities, matchedRarity)
                    end
                end
            end
        end
    end

    local lastRound = StatsData.LastRound
    lastRound.TimeTaken = FormatSeconds(finSec)
    lastRound.Difficulty = finDiff
    lastRound.TitansKilled = roundKills
    lastRound.DamageDealt = roundDamage
    lastRound.Gold = roundGold
    lastRound.Gems = roundGems
    lastRound.XP = roundXP
    lastRound.Items = table.clone(roundItems)

    local sess = StatsData.Session
    sess.MissionsCompleted = (sess.MissionsCompleted or 0) + 1
    sess.TotalSeconds = (sess.TotalSeconds or 0) + finSec
    if finSec > 0 then
        if not sess.FastestSeconds or sess.FastestSeconds == 0 or finSec < sess.FastestSeconds then
            sess.FastestSeconds = finSec
        end
    end
    sess.TitansKilled = (sess.TitansKilled or 0) + roundKills
    sess.DamageDealt = (sess.DamageDealt or 0) + roundDamage
    sess.Gold = (sess.Gold or 0) + roundGold
    sess.Gems = (sess.Gems or 0) + roundGems
    sess.XP = (sess.XP or 0) + roundXP
    sess.Items = sess.Items or {}
    for _, itm in ipairs(roundItems) do
        table.insert(sess.Items, itm)
    end
    sess.RarityCounts = sess.RarityCounts or {}
    for _, r in ipairs(roundRarities) do
        sess.RarityCounts[r] = (sess.RarityCounts[r] or 0) + 1
    end

    if okRem and type(playerProfileData) == "table" then
        if playerProfileData.Progression and type(playerProfileData.Progression) == "table" then
            if playerProfileData.Progression.Prestige ~= nil then
                StatsData.Player.Prestige = tonumber(playerProfileData.Progression.Prestige) or StatsData.Player.Prestige
            end
            if playerProfileData.Progression.Level ~= nil then
                StatsData.Player.Level = tonumber(playerProfileData.Progression.Level) or StatsData.Player.Level
            end
        end
        if playerProfileData.Currency and type(playerProfileData.Currency) == "table" then
            if playerProfileData.Currency.Gold ~= nil then
                StatsData.Player.Gold = tonumber(playerProfileData.Currency.Gold) or StatsData.Player.Gold
            end
            if playerProfileData.Currency.Gems ~= nil then
                StatsData.Player.Gems = tonumber(playerProfileData.Currency.Gems) or StatsData.Player.Gems
            end
        end
    end

    SaveStatsJson()
    UpdateStatsUI()

    FinalizeDebounce = false
end

local function StartNewRound()
    if RoundState == "Playing" then return end
    RoundState = "Playing"
    RoundStartTime = os.clock()

    LiveRoundData.Status = "In Progress"
    LiveRoundData.Seconds = 0

    local liveDiff = Workspace:GetAttribute("Difficulty")
    if not liveDiff or tostring(liveDiff) == "" or tostring(liveDiff) == "N/A" then
        liveDiff = StatsData.LastRound.Difficulty or "N/A"
    end
    LiveRoundData.Difficulty = tostring(liveDiff)

    PendingRoundDrops = {
        Gold = 0,
        Gems = 0,
        XP = 0,
        Items = {},
        Rarities = {},
    }

    UpdateStatsUI()
end

local function HookRewardsModule()
    pcall(function()
        local rewMod = ReplicatedStorage:WaitForChild("Modules", 10)
        local uiMod = rewMod and rewMod:WaitForChild("User Interface", 10)
        local rewardsMod = uiMod and uiMod:WaitForChild("Rewards", 10)
        if not rewardsMod then return end
        local rObj = require(rewardsMod)
        if type(rObj) ~= "table" then return end

        if type(rObj.Create) == "function" and not rObj.__SymbioteHooked then
            rObj.__SymbioteHooked = true
            local origCreate = rObj.Create
            rObj.Create = function(self, uiTarget, kind, itemKey, amountText, displayNameOverride)
                pcall(function()
                    local rawQty = tostring(amountText or ""):gsub(",", ""):gsub("%+", ""):gsub("%s", "")
                    local nQty = tonumber(rawQty) or 1
                    local rawName = tostring((displayNameOverride and displayNameOverride ~= "") and displayNameOverride or itemKey or "")

                    if kind == 1 or itemKey == "Gold" or rawName == "Gold" then
                        PendingRoundDrops.Gold = PendingRoundDrops.Gold + nQty
                    elseif itemKey == "Gems" or rawName == "Gems" then
                        PendingRoundDrops.Gems = PendingRoundDrops.Gems + nQty
                    elseif itemKey == "XP" or rawName == "XP" then
                        PendingRoundDrops.XP = PendingRoundDrops.XP + nQty
                    elseif not IsIgnoredDrop(rawName) then
                        local r = GetPerkRarity(rawName) or GetItemRarity(rawName)
                        if not r and type(self) == "table" and self.Modules and self.Modules.Items and self.Modules.Items[itemKey] then
                            r = self.Modules.Items[itemKey].Rarity
                        end
                        r = r or "Common"
                        local cleanName = string.gsub(rawName, "_", " ")
                        local entryText = cleanName .. " (" .. r .. ")"
                        table.insert(PendingRoundDrops.Items, entryText)
                        table.insert(PendingRoundDrops.Rarities, r)
                    end
                end)
                return origCreate(self, uiTarget, kind, itemKey, amountText, displayNameOverride)
            end
        end

        if type(rObj.Setup) == "function" and not rObj.__SymbioteSetupHooked then
            rObj.__SymbioteSetupHooked = true
            local origSetup = rObj.Setup
            rObj.Setup = function(self, payload)
                local ret = origSetup(self, payload)
                if RoundState == "Playing" then
                    task.defer(function()
                        FinalizeRound()
                    end)
                end
                return ret
            end
        end
    end)
end

local function HookMissionTracker()
    HookRewardsModule()

    task.spawn(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui", 60)
        local iface = pg and pg:WaitForChild("Interface", 60)
        local rewards = iface and iface:WaitForChild("Rewards", 60)
        if not rewards then return end

        rewards:GetPropertyChangedSignal("Visible"):Connect(function()
            if rewards.Visible then
                if RoundState == "Playing" then
                    task.delay(0.6, function()
                        FinalizeRound()
                    end)
                end
            else
                if RoundState == "Ended" and not FinalizeDebounce then
                    StartNewRound()
                end
            end
        end)
    end)

    Workspace:GetAttributeChangedSignal("Difficulty"):Connect(function()
        local d = Workspace:GetAttribute("Difficulty")
        if d and tostring(d) ~= "" and tostring(d) ~= "N/A" then
            LiveRoundData.Difficulty = tostring(d)
            UpdateStatsUI()
        end
    end)
end

StatsTab:AddButton("Reset Session Stats", function()
    StatsData.Session = {
        MissionsCompleted = 0,
        TotalSeconds = 0,
        FastestSeconds = 0,
        TitansKilled = 0,
        DamageDealt = 0,
        Gold = 0,
        Gems = 0,
        XP = 0,
        Items = {},
        RarityCounts = {
            Common = 0,
            Uncommon = 0,
            Rare = 0,
            Epic = 0,
            Legendary = 0,
            Mythic = 0,
            Secret = 0,
        },
    }
    SaveStatsJson()
    UpdateStatsUI()
end)

StatsTab:AddButton("Refresh Stats", function()
    FetchPlayerStats()
end)

task.spawn(function()
    task.wait(0.3)
    FetchPlayerStats()
    HookMissionTracker()

    local isMainMenu = (game.PlaceId == 14916516914)
    local refreshTimer = 0

    if not isMainMenu then
        RoundState = "Playing"
        local liveDiff = Workspace:GetAttribute("Difficulty")
        if not liveDiff or tostring(liveDiff) == "" or tostring(liveDiff) == "N/A" then
            liveDiff = StatsData.LastRound.Difficulty or "N/A"
        end
        LiveRoundData.Difficulty = tostring(liveDiff)
    else
        RoundState = "Lobby"
    end

    while true do
        task.wait(0.5)
        refreshTimer = refreshTimer + 0.5

        if isMainMenu then
            LiveRoundData.Status = "In Lobby"
            LiveRoundData.Seconds = 0
            LiveRoundData.Difficulty = "N/A"
        else
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local iface = pg and pg:FindFirstChild("Interface")
            local rew = iface and iface:FindFirstChild("Rewards")
            local rewardsVisible = rew and rew.Visible

            if rewardsVisible then
                if RoundState == "Playing" and not FinalizeDebounce then
                    task.delay(0.6, function()
                        FinalizeRound()
                    end)
                end
            else
                if RoundState == "Ended" and not FinalizeDebounce then
                    StartNewRound()
                elseif RoundState == "Playing" then
                    LiveRoundData.Status = "In Progress"
                    LiveRoundData.Seconds = math.max(0, math.floor(os.clock() - RoundStartTime))

                    local liveDiff = Workspace:GetAttribute("Difficulty")
                    if liveDiff and tostring(liveDiff) ~= "" and tostring(liveDiff) ~= "N/A" then
                        LiveRoundData.Difficulty = tostring(liveDiff)
                    elseif LiveRoundData.Difficulty == "N/A" and StatsData.LastRound.Difficulty and StatsData.LastRound.Difficulty ~= "N/A" then
                        LiveRoundData.Difficulty = StatsData.LastRound.Difficulty
                    end
                end
            end
        end

        if refreshTimer >= 15 then
            refreshTimer = 0
            FetchPlayerStats()
        else
            UpdateStatsUI()
        end
    end
end)

UI.NoClip = PlayerTab:AddToggle("NoClip", function(state)
    NoClipEnabled = state
    SetSetting("NoClip", state)
    if state then EnableNoClip() else DisableNoClip() end
end)

UI.WalkSpeed = PlayerTab:AddToggle("Walk Speed", function(state)
    WalkSpeedEnabled = state
    SetSetting("WalkSpeed", state)
    if state then EnableWalkSpeed() else DisableWalkSpeed() end
end)
UI.WalkSpeedSlider = PlayerTab:AddSlider("Walk Speed Amount", 1, 5, GetSetting("WalkSpeedAmount"), function(v)
    WalkSpeedSmoothing = v
    SetSetting("WalkSpeedAmount", v)
end)

UI.LaggyRun = PlayerTab:AddToggle("Laggy Run", function(state)
    LaggyRunEnabled = state
    SetSetting("LaggyRun", state)
    if state then EnableLaggyRun() else DisableLaggyRun() end
end)
UI.LaggyRunDistSlider = PlayerTab:AddSlider("Laggy Run Distance", 1, 10, GetSetting("LaggyRunDistance"), function(v)
    LaggyRunDistance = v
    SetSetting("LaggyRunDistance", v)
end)
UI.LaggyRunDelaySlider = PlayerTab:AddSlider("Laggy Run Delay", 1, 10, GetSetting("LaggyRunDelay"), function(v)
    LaggyRunDelay = v
    SetSetting("LaggyRunDelay", v)
end)

UI.CtrlClickTP = PlayerTab:AddToggle("CTRL + Click to TP", function(state)
    CtrlClickTPEnabled = state
    SetSetting("CtrlClickTP", state)
    if state then EnableCtrlClickTP() else DisableCtrlClickTP() end
end)

UI.InfiniteJump = PlayerTab:AddToggle("Infinite Jump", function(state)
    InfiniteJumpEnabled = state
    SetSetting("InfiniteJump", state)
    if state then EnableInfiniteJump() else DisableInfiniteJump() end
end)

UI.AutoFarm = AutoFarmTab:AddToggle("Auto Farm", function(state)
    SetSetting("AutoFarm", state)
    if state then
        AutoFarmEnabled = true
        ExpandNapeHitboxEnabled = true
        NapeHitboxSize = 100
        ApplyNapeHitbox(100)
        task.spawn(FarmLoop)
    else
        AutoFarmEnabled = false
        CurrentTarget = nil
        UpdateHoverStabilizer()
    end
end)

UI.HitAll = AutoFarmTab:AddToggle("Hit All", function(state)
    HitAllEnabled = state
    SetSetting("HitAll", state)
    if state then
        CurrentTarget = nil
    end
end)

UI.DistanceToTitanSlider = AutoFarmTab:AddSlider("Distance to Titan", 0, 50, GetSetting("DistanceToTitan"), function(v)
    DistanceToTitanAmount = v
    SetSetting("DistanceToTitan", v)
end)

UI.AutoReload = AutoFarmTab:AddToggle("Auto Reload", function(state)
    AutoReloadEnabled = state
    SetSetting("AutoReload", state)
end)

UI.KillWithoutTP = AutoFarmTab:AddToggle("Kill Without TP", function(state)
    KillWithoutTPEnabled = state
    SetSetting("KillWithoutTP", state)
    UpdateHoverStabilizer()
end)

UI.DelayToKill = AutoFarmTab:AddToggle("Delay To Kill", function(state)
    DelayToKillEnabled = state
    SetSetting("DelayToKill", state)
end)
UI.DelayToKillSlider = AutoFarmTab:AddSlider("Delay(s)", 0, 300, GetSetting("DelayToKillAmount"), function(v)
    DelayToKillAmount = v
    SetSetting("DelayToKillAmount", v)
end)

UI.ExpandNapeHitbox = AutoFarmTab:AddToggle("Expand Nape Hitbox", function(state)
    ExpandNapeHitboxEnabled = state
    SetSetting("ExpandNapeHitbox", state)
    if not state then RestoreNapeHitbox() else ApplyNapeHitbox() end
end)

UI.HitboxSizeSlider = AutoFarmTab:AddSlider("Hitbox Size", 20, 100, GetSetting("HitboxSize"), function(v)
    NapeHitboxSize = v
    SetSetting("HitboxSize", v)
    if ExpandNapeHitboxEnabled then ApplyNapeHitbox() end
end)

UI.VisualizeHitbox = AutoFarmTab:AddToggle("Visualize Hitbox", function(state)
    VisualizeHitboxEnabled = state
    SetSetting("VisualizeHitbox", state)
    if not state then RemoveAllVisuals() end
end)

VariousTab:AddLabel("VARIOUS")

UI.TitanESP = VariousTab:AddToggle("Titan ESP", function(state)
    TitanESPEnabled = state
    SetSetting("TitanESP", state)
    if not state then RemoveAllTitanESP() end
end)

UI.ChangeCursor = VariousTab:AddToggle("Change Cursor", function(state)
    ChangeCursorEnabled = state
    SetSetting("ChangeCursor", state)
    if state then EnableChangeCursor() else DisableChangeCursor() end
end)

UI.AutoRefill = VariousTab:AddToggle("Auto Refill", function(state)
    AutoRefillEnabled = state
    SetSetting("AutoRefill", state)
    if not state then SetsWentEmptyAt = nil end
end)

UI.AutoRetry = VariousTab:AddToggle("Auto Retry", function(state)
    AutoRetryEnabled = state
    SetSetting("AutoRetry", state)
    if state then EnableAutoRetry() else DisableAutoRetry() end
end)

UI.AutoExecute = VariousTab:AddToggle("Auto Execute", function(state)
    SetSetting("AutoExecute", state)
    if state then
        QueueOnTeleport(AutoExecuteScript)
    else
        QueueOnTeleport("")
    end
end)

UI.AutoSkipCutscenes = VariousTab:AddToggle("Auto Skip Cutscenes", function(state)
    AutoSkipCutscenesEnabled = state
    SetSetting("AutoSkipCutscenes", state)
    if state then EnableAutoSkipCutscenes() else DisableAutoSkipCutscenes() end
end)

local FamilyData = {
    AllFamilies = {},
    TierMap = {},
    TiersList = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
}
do
    pcall(function()
        local famMod = require(ReplicatedStorage.Modules.Storage.Families)
        for tier, list in pairs(famMod) do
            if type(list) == "table" then
                for name in pairs(list) do
                    table.insert(FamilyData.AllFamilies, name)
                    FamilyData.TierMap[name] = tier
                end
            end
        end
        table.sort(FamilyData.AllFamilies)
    end)
    if #FamilyData.AllFamilies == 0 then
        FamilyData.AllFamilies = {
            "Ackerman", "Arlert", "Azumabito", "Boyega", "Bozado", "Braun", "Braus",
            "Finger", "Fritz", "Galliard", "Grice", "Helos", "Hume", "Iglehaut",
            "Inocenio", "Kirstein", "Kruger", "Ksaver", "Leonhart", "Munsell",
            "Pikale", "Ral", "Reeves", "Reiss", "Shiki", "Smith", "Springer",
            "Tybur", "Yeager", "Zoe"
        }
        local staticTiers = {
            Legendary = { "Yeager", "Ackerman", "Reiss" },
            Common = { "Reeves", "Blouse", "Inocenio", "Munsell", "Boyega", "Ral", "Bozado", "Pikale", "Hume", "Iglehaut" },
            Epic = { "Galliard", "Zoe", "Leonhart", "Tybur", "Ksaver", "Braun", "Finger", "Arlert" },
            Secret = { "Shiki" },
            Mythic = { "Helos", "Fritz" },
            Rare = { "Braus", "Kruger", "Azumabito", "Smith", "Grice", "Springer", "Kirstein" }
        }
        for tier, list in pairs(staticTiers) do
            for _, name in ipairs(list) do
                FamilyData.TierMap[name] = tier
            end
        end
    end
end

local function ShowFamilyFoundNotification(familyName, tier)
    local targetContainer = nil
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        local test = Instance.new("Folder", coreGui)
        test:Destroy()
        targetContainer = coreGui
    end)
    if not targetContainer then
        targetContainer = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 3)
    end
    if not targetContainer then return end

    local oldNotify = targetContainer:FindFirstChild("Symbiote_FamilyFoundNotify")
    if oldNotify then
        oldNotify:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Symbiote_FamilyFoundNotify"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = targetContainer

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 52)
    frame.Position = UDim2.new(0.5, 0, 0.88, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(140, 60, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 1
    stroke.Parent = frame

    local glowBar = Instance.new("Frame")
    glowBar.Size = UDim2.new(0, 4, 0.65, 0)
    glowBar.Position = UDim2.new(0, 8, 0.5, 0)
    glowBar.AnchorPoint = Vector2.new(0, 0.5)
    glowBar.BackgroundColor3 = Color3.fromRGB(80, 220, 150)
    glowBar.BackgroundTransparency = 1
    glowBar.BorderSizePixel = 0
    glowBar.Parent = frame

    local title = Instance.new("TextLabel")
    title.Text = "Family found!"
    title.Size = UDim2.new(1, -26, 0, 20)
    title.Position = UDim2.new(0, 22, 0, 7)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(80, 220, 150)
    title.TextTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Text = string.format("%s (%s)", tostring(familyName), tostring(tier))
    sub.Size = UDim2.new(1, -26, 0, 18)
    sub.Position = UDim2.new(0, 22, 0, 27)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = Color3.fromRGB(245, 240, 255)
    sub.TextTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame

    local TweenService = game:GetService("TweenService")
    local twIn = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(frame, twIn, {Position = UDim2.new(0.5, 0, 0.84, 0), BackgroundTransparency = 0.1}):Play()
    TweenService:Create(stroke, twIn, {Transparency = 0}):Play()
    TweenService:Create(glowBar, twIn, {BackgroundTransparency = 0}):Play()
    TweenService:Create(title, twIn, {TextTransparency = 0}):Play()
    TweenService:Create(sub, twIn, {TextTransparency = 0}):Play()

    task.delay(5, function()
        if not sg or not sg.Parent then return end
        local twOut = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local t1 = TweenService:Create(frame, twOut, {Position = UDim2.new(0.5, 0, 0.88, 0), BackgroundTransparency = 1})
        TweenService:Create(stroke, twOut, {Transparency = 1}):Play()
        TweenService:Create(glowBar, twOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, twOut, {TextTransparency = 1}):Play()
        TweenService:Create(sub, twOut, {TextTransparency = 1}):Play()
        t1:Play()
        t1.Completed:Connect(function()
            if sg and sg.Parent then
                sg:Destroy()
            end
        end)
    end)
end

local function IsFamilyMatch(list, value)
    if type(list) ~= "table" or not value then return false end
    if list[value] == true then return true end
    for k, v in pairs(list) do
        if v == value or (k == value and v == true) then
            return true
        end
    end
    return false
end

local function StartFamilySpinLoop()
    if AutoFamilySpinThread then return end
    AutoFamilySpinThread = task.spawn(function()
        while AutoFamilySpinEnabled do
            local ok, spins, extra, rolledFamily, pity = pcall(function()
                return RemoteGET:InvokeServer("Family", "Roll")
            end)

            if ok and type(rolledFamily) == "string" and rolledFamily ~= "" then
                local rolledTier = FamilyData.TierMap[rolledFamily] or "Common"
                local totalSpins = (tonumber(spins) or 0) + (tonumber(extra) or 0)

                local getActorsFn = (getactors or (syn and syn.getactors))
                local runOnActorFn = (run_on_actor or (syn and syn.run_on_actor))

                if getActorsFn and runOnActorFn then
                    pcall(function()
                        local actor = getActorsFn()[1]
                        if actor then
                            actor:SetAttribute("Symbiote_RollSync", HttpService:JSONEncode({
                                Spins = spins,
                                Extra = extra,
                                Family = rolledFamily,
                                Pity = pity
                            }))
                            runOnActorFn(actor, [[
                                local act = getactors()[1]
                                local raw = act:GetAttribute("Symbiote_RollSync")
                                if not raw then return end
                                local http = game:GetService("HttpService")
                                local sync = http:JSONDecode(raw)
                                local host = nil
                                for _, v in ipairs(getgc(true)) do
                                    if type(v) == "table" and rawget(v, "Cache") and rawget(v, "Modules") and rawget(v, "Services") then
                                        host = v
                                        break
                                    end
                                end
                                if host and host.Cache and host.Cache.Data then
                                    local d = host.Cache.Data
                                    d.Spins = tonumber(sync.Spins) or d.Spins
                                    d.Extra = tonumber(sync.Extra) or d.Extra
                                    local slot = d.Slots and d.Current_Slot and d.Slots[d.Current_Slot]
                                    if slot and slot.Avatar then
                                        slot.Avatar.Family = sync.Family
                                        slot.Avatar.Pity = tonumber(sync.Pity) or slot.Avatar.Pity
                                    end
                                    local pgui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                                    local cust = pgui and pgui:FindFirstChild("Interface") and pgui.Interface:FindFirstChild("Customisation")
                                    local famUI = cust and cust:FindFirstChild("Family")
                                    local custMod = host.Modules and host.Modules.Customisation
                                    if custMod and custMod.Family_Details and famUI then
                                        pcall(function()
                                            custMod.Family_Details(host, famUI, true, false)
                                        end)
                                    end
                                end
                            ]])
                        end
                    end)
                end

                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local cust = pg and pg:FindFirstChild("Interface") and pg.Interface:FindFirstChild("Customisation")
                    local famUI = cust and cust:FindFirstChild("Family")
                    if famUI then
                        local famTitle = famUI:FindFirstChild("Family") and famUI.Family:FindFirstChild("Title")
                        if famTitle and famTitle:IsA("TextLabel") then
                            famTitle.Text = string.upper(rolledFamily) .. " (" .. rolledTier .. ")"
                        end
                        local rollBtn = famUI:FindFirstChild("Buttons_2") and famUI.Buttons_2:FindFirstChild("Roll")
                        local rollTitle = rollBtn and rollBtn:FindFirstChild("Title")
                        if rollTitle and rollTitle:IsA("TextLabel") then
                            rollTitle.Text = "ROLL (" .. tostring(totalSpins) .. ")"
                        end
                        local pityLabel = famUI:FindFirstChild("Pity")
                        if pityLabel and pityLabel:IsA("TextLabel") and pity then
                            pityLabel.Text = "EPIC+ PITY: " .. tostring(pity) .. "/400"
                        end
                    end
                end)

                if IsFamilyMatch(FamiliesToStop, rolledFamily) or IsFamilyMatch(FamilyTiersToStop, rolledTier) then
                    AutoFamilySpinEnabled = false
                    if UI.AutoFamilySpin then
                        UI.AutoFamilySpin:SetState(false)
                    end
                    ShowFamilyFoundNotification(rolledFamily, rolledTier)
                    break
                end

                if totalSpins <= 0 then
                    AutoFamilySpinEnabled = false
                    if UI.AutoFamilySpin then
                        UI.AutoFamilySpin:SetState(false)
                    end
                    break
                end

                task.wait(0.1)
            else
                task.wait(0.25)
            end
        end
        AutoFamilySpinThread = nil
    end)
end

VariousTab:AddLabel("AUTO FAMILY ROLL")

UI.AutoFamilySpin = VariousTab:AddToggle("Auto Family Spin", function(state)
    AutoFamilySpinEnabled = state
    SetSetting("AutoFamilySpin", state)
    if state then
        StartFamilySpinLoop()
    end
end)



UI.FamiliesDropdown = VariousTab:AddDropdown("Families To Stop", FamilyData.AllFamilies, function(selected)
    FamiliesToStop = selected or {}
    SetSetting("FamiliesToStop", FamiliesToStop)
end)

UI.FamilyTiersDropdown = VariousTab:AddDropdown("Family Tiers To Stop", FamilyData.TiersList, function(selected)
    FamilyTiersToStop = selected or {}
    SetSetting("FamilyTiersToStop", FamilyTiersToStop)
end)

local PerkData = {
    AllPerks = {},
    RarityMap = {},
    TiersList = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
}
do
    pcall(function()
        local perksMod = require(ReplicatedStorage.Modules.Storage.Perks)
        for tier, list in pairs(perksMod) do
            if type(list) == "table" then
                for name in pairs(list) do
                    table.insert(PerkData.AllPerks, name)
                    PerkData.RarityMap[name] = tier
                end
            end
        end
        table.sort(PerkData.AllPerks)
    end)
    if #PerkData.AllPerks == 0 then
        PerkData.AllPerks = {
            "Adaptation", "Adrenaline", "Aegis", "Art of War", "Black Flash", "Blessed", "Butcher", "Carnifex",
            "Courage Catalyst", "Cripple", "Critical Hunter", "Enduring", "Enhanced Metabolism", "Everlasting Flame",
            "Eviscerate", "Exhumation", "Experimental Shells", "First Aid", "Flame Rhapsody", "Flawed Release",
            "Focus", "Font of Inspiration", "Font of Vitality", "Forceful", "Fortitude", "Founder's Blessing",
            "Fully Stocked", "Gear Beginner", "Gear Expert", "Gear Intermediate", "Gear Master", "Hardy",
            "Heavenly Restriction", "Heightened Vitality", "Hollow", "Immortal", "Indefatigable", "Invincible",
            "Kengo", "Lightweight", "Lucky", "Luminous", "Mangle", "Maximum Firepower", "Mighty",
            "Munitions Expert", "Munitions Master", "Mutilate", "Peerless Commander", "Peerless Constitution",
            "Peerless Focus", "Peerless Strength", "Perfect Form", "Perfect Soul", "Protection", "Reckless Abandon",
            "Resilient", "Robust", "Safeguard", "Sanctified", "Siphoning", "Sixth Sense", "Solo",
            "Soulfeed", "Speedy", "Stalwart Durability", "Tatsujin", "Tough", "Trauma Battery", "Tyrant's Stare",
            "Unbreakable", "Unyielding", "Unparalleled Strength", "Unwavering Belief", "Warchief", "Warrior",
            "Wind Rhapsody"
        }
        local staticTiers = {
            Common = { "Cripple", "Enduring", "Enhanced Metabolism", "First Aid", "Fortitude", "Gear Beginner", "Hollow", "Lucky", "Mighty" },
            Rare = { "Blessed", "Critical Hunter", "Experimental Shells", "Forceful", "Fully Stocked", "Gear Intermediate", "Heightened Vitality", "Lightweight", "Mangle", "Protection", "Tough", "Unyielding" },
            Epic = { "Adrenaline", "Butcher", "Flawed Release", "Focus", "Gear Expert", "Hardy", "Luminous", "Munitions Expert", "Mutilate", "Peerless Strength", "Reckless Abandon", "Resilient", "Safeguard", "Siphoning", "Solo", "Speedy", "Stalwart Durability", "Trauma Battery", "Unbreakable", "Warrior" },
            Legendary = { "Aegis", "Carnifex", "Courage Catalyst", "Eviscerate", "Exhumation", "Flame Rhapsody", "Font of Vitality", "Gear Master", "Indefatigable", "Invincible", "Munitions Master", "Peerless Commander", "Peerless Constitution", "Peerless Focus", "Perfect Form", "Perfect Soul", "Robust", "Sanctified", "Sixth Sense", "Tyrant's Stare", "Unparalleled Strength", "Warchief", "Wind Rhapsody" },
            Mythic = { "Adaptation", "Art of War", "Black Flash", "Everlasting Flame", "Explosive Fortune", "Font of Inspiration", "Founder's Blessing", "Heavenly Restriction", "Immortal", "Kengo", "Maximum Firepower", "Soulfeed", "Tatsujin", "Unwavering Belief" }
        }
        for tier, list in pairs(staticTiers) do
            for _, name in ipairs(list) do
                PerkData.RarityMap[name] = tier
            end
        end
    end
end

local function SellMatchingPerks()
    if not AutoSellPerksEnabled then return end

    local function isMatch(name, rarity)
        if not name then return false end
        local r = rarity or PerkData.RarityMap[name] or "Common"
        if PerkTiersToSell[r] == true then
            return true
        end
        if SpecificPerksToSell[name] == true then
            return true
        end
        return false
    end

    local didActorScan = false
    local deletedLookup = {}
    local getActorsFn = (getactors or (syn and syn.getactors))
    local runOnActorFn = (run_on_actor or (syn and syn.run_on_actor))

    if getActorsFn and runOnActorFn then
        pcall(function()
            local actors = getActorsFn()
            local actor = actors and actors[1]
            if actor then
                actor:SetAttribute("Symbiote_PerkFilter", HttpService:JSONEncode({
                    Tiers = PerkTiersToSell,
                    Specific = SpecificPerksToSell
                }))
                runOnActorFn(actor, [[
                    local rs = game:GetService("ReplicatedStorage")
                    local remoteGET = rs:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
                    local perksMod = require(rs.Modules.Storage.Perks)
                    local rarityMap = {}
                    for r, list in pairs(perksMod) do
                        if type(list) == "table" then
                            for name in pairs(list) do
                                rarityMap[name] = r
                            end
                        end
                    end

                    local hostObj = nil
                    for _, v in ipairs(getgc(true)) do
                        if type(v) == "table" and rawget(v, "Cache") and rawget(v, "Modules") then
                            hostObj = v
                            break
                        end
                    end

                    local actor = getactors()[1]
                    if hostObj and hostObj.Cache and hostObj.Cache.Data then
                        local data = hostObj.Cache.Data
                        local currentSlot = data.Current_Slot or 1
                        local slotData = data.Slots and data.Slots[currentSlot]
                        if slotData and slotData.Perks and slotData.Perks.Storage then
                            local equippedIds = {}
                            for _, eqId in pairs(slotData.Perks.Equipped or {}) do
                                if eqId and eqId ~= "" then
                                    equippedIds[eqId] = true
                                end
                            end

                            local rawFilter = actor:GetAttribute("Symbiote_PerkFilter")
                            local http = game:GetService("HttpService")
                            local filter = rawFilter and http:JSONDecode(rawFilter) or { Tiers = {}, Specific = {} }

                            local batch = {}
                            local deletedList = {}
                            for id, info in pairs(slotData.Perks.Storage) do
                                local name = info.Name
                                local rarity = rarityMap[name] or "Common"
                                local match = (filter.Tiers[rarity] == true) or (filter.Specific[name] == true)
                                if match and not equippedIds[id] then
                                    table.insert(batch, tostring(id))
                                    table.insert(deletedList, tostring(id))
                                    if #batch >= 25 then
                                        local res = remoteGET:InvokeServer("S_Equipment", "Delete", "Perk", batch)
                                        if type(res) == "table" then
                                            hostObj.Cache.Data = res
                                            data = res
                                            slotData = data.Slots and data.Slots[currentSlot]
                                        end
                                        batch = {}
                                    end
                                end
                            end
                            if #batch > 0 then
                                local res = remoteGET:InvokeServer("S_Equipment", "Delete", "Perk", batch)
                                if type(res) == "table" then
                                    hostObj.Cache.Data = res
                                end
                            end
                            actor:SetAttribute("Symbiote_PerkDeleted", http:JSONEncode(deletedList))
                        end
                    end
                ]])
                didActorScan = true
                local rawDeleted = actor:GetAttribute("Symbiote_PerkDeleted")
                if rawDeleted then
                    local list = HttpService:JSONDecode(rawDeleted)
                    if type(list) == "table" then
                        for _, id in ipairs(list) do
                            deletedLookup[id] = true
                        end
                    end
                end
            end
        end)
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local iface = pg and pg:FindFirstChild("Interface")
    local equip = iface and iface:FindFirstChild("Equipment")
    local perkList = equip and equip:FindFirstChild("Perk_List")
    local holder = perkList and perkList:FindFirstChild("Holder")
    local itemsFolder = holder and holder:FindFirstChild("Items")
    if itemsFolder then
        local fallbackIds = {}
        local fallbackFrames = {}
        for _, child in ipairs(itemsFolder:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "Grid" then
                local id = child:GetAttribute("ID")
                local name = child:GetAttribute("Tag") or child.Name
                local rarity = child:GetAttribute("Rarity") or PerkData.RarityMap[name] or "Common"
                if id then
                    local idStr = tostring(id)
                    if deletedLookup[idStr] then
                        child:Destroy()
                    elseif not didActorScan and isMatch(name, rarity) then
                        table.insert(fallbackIds, idStr)
                        table.insert(fallbackFrames, child)
                    end
                end
            end
        end
        if #fallbackIds > 0 then
            local batch = {}
            for i, id in ipairs(fallbackIds) do
                table.insert(batch, id)
                if #batch >= 25 or i == #fallbackIds then
                    pcall(function()
                        RemoteGET:InvokeServer("S_Equipment", "Delete", "Perk", batch)
                    end)
                    batch = {}
                end
            end
            for _, frame in ipairs(fallbackFrames) do
                if frame and frame.Parent then
                    frame:Destroy()
                end
            end
        end
    end
end

local function StartAutoSellPerksLoop()
    if AutoSellPerksThread then return end
    AutoSellPerksThread = task.spawn(function()
        while AutoSellPerksEnabled do
            SellMatchingPerks()
            task.wait(1.5)
        end
        AutoSellPerksThread = nil
    end)
end

VariousTab:AddLabel("AUTO SELL PERKS")

UI.AutoSellPerks = VariousTab:AddToggle("Auto Sell Selected Tier Perks", function(state)
    AutoSellPerksEnabled = state
    SetSetting("AutoSellPerks", state)
    if state then
        SellMatchingPerks()
        StartAutoSellPerksLoop()
    end
end)

UI.PerkTiersDropdown = VariousTab:AddDropdown("Perk Tiers To Sell", PerkData.TiersList, function(selected)
    PerkTiersToSell = selected or {}
    SetSetting("PerkTiersToSell", PerkTiersToSell)
    if AutoSellPerksEnabled then
        SellMatchingPerks()
    end
end)

UI.SpecificPerksDropdown = VariousTab:AddDropdown("Select Perks To Sell", PerkData.AllPerks, function(selected)
    SpecificPerksToSell = selected or {}
    SetSetting("SpecificPerksToSell", SpecificPerksToSell)
    if AutoSellPerksEnabled then
        SellMatchingPerks()
    end
end)

VariousTab:AddLabel("THUNDER SPEARS")

UI.AutoCreateTowers = VariousTab:AddToggle("Auto Create Towers(Outskirts)", function(state)
    AutoCreateTowersEnabled = state
    SetSetting("AutoCreateTowers", state)
    if state then
        FindNextTower()
        UpdateHoverStabilizer()
    else
        CurrentTowerTarget = nil
        UpdateHoverStabilizer()
    end
end)

UI.AutoRetrieveSupplyCrates = VariousTab:AddToggle("Auto Retrieve Supply Crates(Forest)", function(state)
    AutoRetrieveSupplyCratesEnabled = state
    SetSetting("AutoRetrieveSupplyCrates", state)
    if state then
        StartRetrieveSupplyCratesLoop()
        task.spawn(RetrieveSupplyCrates)
    else
        IsRetrievingCrates = false
    end
end)

task.spawn(function()
    while true do
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local iface = pg and pg:FindFirstChild("Interface")
        local equip = iface and iface:FindFirstChild("Equipment")
        local perkList = equip and equip:FindFirstChild("Perk_List")
        local holder = perkList and perkList:FindFirstChild("Holder")
        local itemsFolder = holder and holder:FindFirstChild("Items")
        if itemsFolder then
            itemsFolder.ChildAdded:Connect(function(child)
                if not AutoSellPerksEnabled then return end
                task.delay(0.1, function()
                    if not AutoSellPerksEnabled then return end
                    if child and child:IsA("GuiObject") and child.Name ~= "Grid" then
                        local name = child:GetAttribute("Tag") or child.Name
                        local rarity = child:GetAttribute("Rarity") or PerkData.RarityMap[name] or "Common"
                        local id = child:GetAttribute("ID")
                        local match = (PerkTiersToSell[rarity] == true) or (SpecificPerksToSell[name] == true)
                        if id and match then
                            pcall(function()
                                RemoteGET:InvokeServer("S_Equipment", "Delete", "Perk", { tostring(id) })
                            end)
                            if child and child.Parent then
                                child:Destroy()
                            end
                        end
                    end
                end)
            end)
            break
        end
        task.wait(1)
    end
end)

local function ApplySavedSettings()
    WalkSpeedSmoothing = GetSetting("WalkSpeedAmount")
    LaggyRunDistance = GetSetting("LaggyRunDistance")
    LaggyRunDelay = GetSetting("LaggyRunDelay")
    NapeHitboxSize = GetSetting("HitboxSize")
    DelayToKillAmount = GetSetting("DelayToKillAmount")
    DistanceToTitanAmount = GetSetting("DistanceToTitan")

    task.wait(0.3)

    if GetSetting("NoClip") then
        NoClipEnabled = true
        EnableNoClip()
        if UI.NoClip then UI.NoClip:SetState(true) end
    end

    if GetSetting("WalkSpeed") then
        WalkSpeedEnabled = true
        EnableWalkSpeed()
        if UI.WalkSpeed then UI.WalkSpeed:SetState(true) end
    end

    if UI.WalkSpeedSlider then UI.WalkSpeedSlider:SetValue(GetSetting("WalkSpeedAmount")) end

    if GetSetting("LaggyRun") then
        LaggyRunEnabled = true
        EnableLaggyRun()
        if UI.LaggyRun then UI.LaggyRun:SetState(true) end
    end

    if UI.LaggyRunDistSlider then UI.LaggyRunDistSlider:SetValue(GetSetting("LaggyRunDistance")) end
    if UI.LaggyRunDelaySlider then UI.LaggyRunDelaySlider:SetValue(GetSetting("LaggyRunDelay")) end

    if GetSetting("CtrlClickTP") then
        CtrlClickTPEnabled = true
        EnableCtrlClickTP()
        if UI.CtrlClickTP then UI.CtrlClickTP:SetState(true) end
    end

    if GetSetting("InfiniteJump") then
        InfiniteJumpEnabled = true
        EnableInfiniteJump()
        if UI.InfiniteJump then UI.InfiniteJump:SetState(true) end
    end

    if GetSetting("AutoReload") then
        AutoReloadEnabled = true
        if UI.AutoReload then UI.AutoReload:SetState(true) end
    end

    if GetSetting("KillWithoutTP") then
        KillWithoutTPEnabled = true
        if UI.KillWithoutTP then UI.KillWithoutTP:SetState(true) end
    end

    if GetSetting("DelayToKill") then
        DelayToKillEnabled = true
        if UI.DelayToKill then UI.DelayToKill:SetState(true) end
    end

    if UI.DelayToKillSlider then UI.DelayToKillSlider:SetValue(GetSetting("DelayToKillAmount")) end
    if UI.DistanceToTitanSlider then UI.DistanceToTitanSlider:SetValue(GetSetting("DistanceToTitan")) end

    if GetSetting("HitAll") then
        HitAllEnabled = true
        if UI.HitAll then UI.HitAll:SetState(true) end
    end

    if GetSetting("ExpandNapeHitbox") then
        ExpandNapeHitboxEnabled = true
        ApplyNapeHitbox()
        if UI.ExpandNapeHitbox then UI.ExpandNapeHitbox:SetState(true) end
    end

    if UI.HitboxSizeSlider then UI.HitboxSizeSlider:SetValue(GetSetting("HitboxSize")) end

    if GetSetting("VisualizeHitbox") then
        VisualizeHitboxEnabled = true
        if UI.VisualizeHitbox then UI.VisualizeHitbox:SetState(true) end
    end

    if GetSetting("TitanESP") then
        TitanESPEnabled = true
        if UI.TitanESP then UI.TitanESP:SetState(true) end
    end

    if GetSetting("AutoRefill") then
        AutoRefillEnabled = true
        if UI.AutoRefill then UI.AutoRefill:SetState(true) end
    end

    if GetSetting("ChangeCursor") then
        ChangeCursorEnabled = true
        EnableChangeCursor()
        if UI.ChangeCursor then UI.ChangeCursor:SetState(true) end
    end

    if GetSetting("AutoExecute") then
        if UI.AutoExecute then UI.AutoExecute:SetState(true) end
    end

    if GetSetting("AutoRetry") then
        AutoRetryEnabled = true
        EnableAutoRetry()
        if UI.AutoRetry then UI.AutoRetry:SetState(true) end
    end

    if GetSetting("AutoSkipCutscenes") then
        AutoSkipCutscenesEnabled = true
        EnableAutoSkipCutscenes()
        if UI.AutoSkipCutscenes then UI.AutoSkipCutscenes:SetState(true) end
    end

    local savedFamilies = GetSetting("FamiliesToStop")
    if type(savedFamilies) == "table" and UI.FamiliesDropdown then
        FamiliesToStop = savedFamilies
        UI.FamiliesDropdown:SetSelected(savedFamilies)
    end

    local savedTiers = GetSetting("FamilyTiersToStop")
    if type(savedTiers) == "table" and UI.FamilyTiersDropdown then
        FamilyTiersToStop = savedTiers
        UI.FamilyTiersDropdown:SetSelected(savedTiers)
    end

    if GetSetting("AutoFamilySpin") then
        AutoFamilySpinEnabled = true
        if UI.AutoFamilySpin then UI.AutoFamilySpin:SetState(true) end
        StartFamilySpinLoop()
    end

    local savedPerkTiers = GetSetting("PerkTiersToSell")
    if type(savedPerkTiers) == "table" and UI.PerkTiersDropdown then
        PerkTiersToSell = savedPerkTiers
        UI.PerkTiersDropdown:SetSelected(savedPerkTiers)
    end

    local savedSpecificPerks = GetSetting("SpecificPerksToSell")
    if type(savedSpecificPerks) == "table" and UI.SpecificPerksDropdown then
        SpecificPerksToSell = savedSpecificPerks
        UI.SpecificPerksDropdown:SetSelected(savedSpecificPerks)
    end

    if GetSetting("AutoSellPerks") then
        AutoSellPerksEnabled = true
        if UI.AutoSellPerks then UI.AutoSellPerks:SetState(true) end
        SellMatchingPerks()
        StartAutoSellPerksLoop()
    end

    if GetSetting("AutoCreateTowers") then
        AutoCreateTowersEnabled = true
        if UI.AutoCreateTowers then UI.AutoCreateTowers:SetState(true) end
        FindNextTower()
        UpdateHoverStabilizer()
    end

    if GetSetting("AutoRetrieveSupplyCrates") then
        AutoRetrieveSupplyCratesEnabled = true
        if UI.AutoRetrieveSupplyCrates then UI.AutoRetrieveSupplyCrates:SetState(true) end
        StartRetrieveSupplyCratesLoop()
        task.spawn(RetrieveSupplyCrates)
    end

    if GetSetting("AutoFarm") then
        AutoFarmEnabled = true
        ExpandNapeHitboxEnabled = true
        NapeHitboxSize = 100
        ApplyNapeHitbox(100)
        task.spawn(FarmLoop)
        if UI.AutoFarm then UI.AutoFarm:SetState(true) end
        if UI.ExpandNapeHitbox then UI.ExpandNapeHitbox:SetState(true) end
    end
end

    ApplySavedSettings()
end
