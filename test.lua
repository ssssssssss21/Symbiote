local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    AutoReload = false,
    ExpandNapeHitbox = false,
    HitboxSize = 20,
    VisualizeHitbox = false,
    TitanESP = false,
    AutoRefill = false,
    ChangeCursor = false,
    AutoExecute = false,
    AutoRetry = false,
}

local function LoadSettings()
    local ok, data = pcall(function()
        local raw
        if syn and syn.read_file then
            raw = syn.read_file(SaveKey)
        elseif readfile then
            raw = readfile(SaveKey)
        end
        if raw and raw ~= "" then
            return HttpService:JSONDecode(raw)
        end
        return nil
    end)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

local function SaveSettings(settings)
    pcall(function()
        local json = HttpService:JSONEncode(settings)
        if syn and syn.write_file then
            syn.write_file(SaveKey, json)
        elseif writefile then
            writefile(SaveKey, json)
        end
    end)
end

local SavedSettings = LoadSettings()

local function GetSetting(key)
    if SavedSettings[key] ~= nil then
        return SavedSettings[key]
    end
    return DefaultSettings[key]
end

local function SetSetting(key, value)
    SavedSettings[key] = value
    SaveSettings(SavedSettings)
end

if GetSetting("AutoExecute") and queue_on_teleport then
    queue_on_teleport([[
        task.wait(3)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ssssssssss21/Symbiote/refs/heads/main/test.lua"))()
    ]])
end

local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/ssssssssss21/f2127829151a31beea020f5dd9211ad6/raw/0a8ddf2f4d018ada1b804820bcc5108e0df0498f/UI.lua"))()

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AutoFarmEnabled = false
local NoClipEnabled = false
local CurrentTarget = nil
local TweenSpeed = 300
local NoClipConnection = nil

local TitanESPEnabled = false

local ExpandNapeHitboxEnabled = false
local NapeHitboxSize = 20
local VisualizeHitboxEnabled = false
local OriginalNapeSizes = {}
local HitboxVisuals = {}

local AutoReloadEnabled = false

local WalkSpeedEnabled = false
local WalkSpeedSmoothing = 1
local WalkSpeedConnection = nil

local LaggyRunEnabled = false
local LaggyRunDistance = 1
local LaggyRunDelay = 1
local LaggyRunConnection = nil
local LaggyRunAccum = 0

local CtrlClickTPEnabled = false
local CtrlClickTPConnection = nil

local InfiniteJumpEnabled = false
local InfiniteJumpConnection = nil

local AutoRefillEnabled = false
local IsRefilling = false
local SetsWentEmptyAt = nil

local ChangeCursorEnabled = false
local CursorConnection = nil
local OriginalCursorVisible = nil

local AutoRetryEnabled = false
local AutoRetryConnection = nil

local function SendClick()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
        vim:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
    end)
    pcall(function()
        UserInputService:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, true)
        UserInputService:SendMouseButtonEvent(0, 0, Enum.UserInputType.MouseButton1, false)
    end)
end

local function SendReload()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
    pcall(function()
        UserInputService:SendKeyEvent(Enum.KeyCode.R, true)
        task.wait(0.05)
        UserInputService:SendKeyEvent(Enum.KeyCode.R, false)
    end)
end

local function SendKeyR()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.1)
        vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
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
        local charsFolder = Workspace:FindFirstChild("Characters")
        if not charsFolder then return false end
        local playerFolder = charsFolder:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return false end
        local rigName = "Rig_" .. LocalPlayer.Name
        local rig = playerFolder:FindFirstChild(rigName)
        if not rig then return false end
        local blades = {}
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("MeshPart") and desc.Name:sub(1, 5) == "Blade" then
                table.insert(blades, desc)
            end
        end
        if #blades == 0 then return true end
        for _, blade in ipairs(blades) do
            local val = blade:GetAttribute("Broken")
            if not val then return false end
        end
        return true
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

local function GetRefillParts()
    local parts = {}
    pcall(function()
        local hq = Workspace.Unclimbable.Props.HQ
        for _, desc in ipairs(hq:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name == "Refill" then
                table.insert(parts, desc)
            end
        end
    end)
    return parts
end

local function DoRefill()
    local parts = GetRefillParts()
    if #parts == 0 then return end
    local chosen = parts[math.random(1, #parts)]
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFrame.new(chosen.Position + Vector3.new(0, 10, 0))
    task.wait(1.5)
    SendKeyR()
end

local function RefillUntilFull()
    if IsRefilling then return end
    IsRefilling = true
    SetsWentEmptyAt = nil
    while AutoRefillEnabled do
        if not SetsEmpty() then break end
        if not GetBladesBroken() then break end
        DoRefill()
        task.wait(5)
        if not SetsEmpty() then break end
        if not GetBladesBroken() then break end
    end
    SetsWentEmptyAt = nil
    IsRefilling = false
end

local function EnableNoClip()
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

local function DisableNoClip()
    if NoClipConnection then NoClipConnection:Disconnect(); NoClipConnection = nil end
    local character = LocalPlayer.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

local function EnableWalkSpeed()
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
        local currentCF = hrp.CFrame
        local lookVec = currentCF.LookVector
        local rightVec = currentCF.RightVector
        local upVec = currentCF.UpVector
        local newPos = currentCF.Position + moveDir.Unit * WalkSpeedSmoothing
        hrp.CFrame = CFrame.fromMatrix(newPos, rightVec, upVec, -lookVec)
    end)
end

local function DisableWalkSpeed()
    if WalkSpeedConnection then WalkSpeedConnection:Disconnect(); WalkSpeedConnection = nil end
end

local function EnableLaggyRun()
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
        local currentCF = hrp.CFrame
        local lookVec = currentCF.LookVector
        local rightVec = currentCF.RightVector
        local upVec = currentCF.UpVector
        local newPos = currentCF.Position + moveDir.Unit * LaggyRunDistance
        hrp.CFrame = CFrame.fromMatrix(newPos, rightVec, upVec, -lookVec)
    end)
end

local function DisableLaggyRun()
    if LaggyRunConnection then LaggyRunConnection:Disconnect(); LaggyRunConnection = nil end
    LaggyRunAccum = 0
end

local function EnableCtrlClickTP()
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

local function DisableCtrlClickTP()
    if CtrlClickTPConnection then CtrlClickTPConnection:Disconnect(); CtrlClickTPConnection = nil end
end

local function EnableChangeCursor()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local interface = playerGui:FindFirstChild("Interface")
    if not interface then return end
    local cursor = interface:FindFirstChild("Cursor")
    if not cursor then return end
    if OriginalCursorVisible == nil then
        OriginalCursorVisible = cursor.Visible
    end
    cursor.Visible = false
    UserInputService.MouseIconEnabled = true
    CursorConnection = RunService.Heartbeat:Connect(function()
        if not ChangeCursorEnabled then return end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local iface = pg:FindFirstChild("Interface")
        if not iface then return end
        local cur = iface:FindFirstChild("Cursor")
        if cur then cur.Visible = false end
    end)
end

local function DisableChangeCursor()
    if CursorConnection then CursorConnection:Disconnect(); CursorConnection = nil end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local interface = playerGui:FindFirstChild("Interface")
    if not interface then return end
    local cursor = interface:FindFirstChild("Cursor")
    if cursor then
        cursor.Visible = OriginalCursorVisible ~= nil and OriginalCursorVisible or true
    end
    OriginalCursorVisible = nil
end

local function TryClickRetry()
    if not AutoRetryEnabled then return end

    local retryBtn = nil
    pcall(function()
        retryBtn = LocalPlayer.PlayerGui.Interface.Rewards.Main.Info.Main.Buttons.Retry
    end)
    if not retryBtn then return end

    local function DidClickWork()
        task.wait(0.5)
        local ok, vis = pcall(function()
            return LocalPlayer.PlayerGui.Interface.Rewards.Visible
        end)
        if ok and not vis then return true end
        return false
    end

    local function GetScreenPosition(btn)
        local btnPos = btn.AbsolutePosition
        local btnSize = btn.AbsoluteSize
        local centerX = math.floor(btnPos.X + btnSize.X / 2)
        local centerY = math.floor(btnPos.Y + btnSize.Y / 2)

        local guiInset = Vector2.new(0, 0)
        pcall(function()
            guiInset = game:GetService("GuiService"):GetGuiInset()
        end)
        centerY = centerY + math.floor(guiInset.Y)

        return centerX, centerY
    end

    local methods = {

        function()
            if not firesignal then return false end
            pcall(function() firesignal(retryBtn.MouseButton1Click) end)
            return DidClickWork()
        end,

        function()
            if not getconnections then return false end
            local ok, conns = pcall(function()
                return getconnections(retryBtn.MouseButton1Click)
            end)
            if not ok or not conns or #conns == 0 then return false end
            for _, conn in ipairs(conns) do
                pcall(function()
                    local fn = conn.Function or conn.Callback
                    if type(fn) == "function" then fn() end
                end)
            end
            return DidClickWork()
        end,

        function()
            if not firebutton then return false end
            pcall(function() firebutton(retryBtn) end)
            return DidClickWork()
        end,

        function()
            if not getcallbackvalue then return false end
            local ok, cb = pcall(function()
                return getcallbackvalue(retryBtn, "MouseButton1Click")
            end)
            if not ok or not cb then return false end
            pcall(cb)
            return DidClickWork()
        end,

        function()
            pcall(function() retryBtn:Activate() end)
            return DidClickWork()
        end,

        function()
            pcall(function() retryBtn:SimulateClick() end)
            return DidClickWork()
        end,

        function()
            local ok, vim = pcall(function()
                return game:GetService("VirtualInputManager")
            end)
            if not ok or not vim then return false end
            local centerX, centerY = GetScreenPosition(retryBtn)
            local viewportSize = Workspace.CurrentCamera.ViewportSize
            if centerX <= 0 or centerY <= 0
                or centerX >= viewportSize.X
                or centerY >= viewportSize.Y then
                return false
            end
            pcall(function() vim:SendMouseMoveEvent(centerX, centerY, game) end)
            task.wait(0.05)
            pcall(function()
                vim:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
            end)
            task.wait(0.1)
            pcall(function()
                vim:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
            end)
            return DidClickWork()
        end,

        function()
            local ok, uis = pcall(function()
                return game:GetService("UserInputService")
            end)
            if not ok or not uis then return false end
            local centerX, centerY = GetScreenPosition(retryBtn)
            if centerX <= 0 or centerY <= 0 then return false end
            pcall(function()
                uis:SendMouseButtonEvent(centerX, centerY,
                    Enum.UserInputType.MouseButton1, true)
            end)
            task.wait(0.05)
            pcall(function()
                uis:SendMouseButtonEvent(centerX, centerY,
                    Enum.UserInputType.MouseButton1, false)
            end)
            return DidClickWork()
        end,
    }

    for _, method in ipairs(methods) do
        local visOk, visVal = pcall(function()
            return LocalPlayer.PlayerGui.Interface.Rewards.Visible
        end)
        if visOk and not visVal then break end

        local success = false
        pcall(function() success = method() end)
        if success then break end

        task.wait(0.2)
    end
end

local AutoRetryTitanConnection = nil

local function EnableAutoRetry()
    if AutoRetryConnection then return end

    task.spawn(function()
        local rewards = nil
        pcall(function()
            rewards = LocalPlayer:WaitForChild("PlayerGui", 60)
                :WaitForChild("Interface", 60)
                :WaitForChild("Rewards", 60)
        end)
        if not rewards then return end

        if rewards.Visible then
            task.wait(2)
            TryClickRetry()
        end

        AutoRetryConnection = rewards:GetPropertyChangedSignal("Visible"):Connect(function()
            if not AutoRetryEnabled then return end
            if not rewards.Visible then return end
            task.wait(2)
            TryClickRetry()
        end)

        task.spawn(function()
            local lastVisible = rewards.Visible
            while AutoRetryEnabled do
                task.wait(1)
                if not AutoRetryEnabled then break end
                local ok, currentVisible = pcall(function() return rewards.Visible end)
                if not ok then break end
                if currentVisible and not lastVisible then
                    task.wait(2)
                    TryClickRetry()
                end
                lastVisible = currentVisible
            end
        end)

        task.spawn(function()
            while AutoRetryEnabled do
                task.wait(3)
                if not AutoRetryEnabled then break end
                local titansFolder = Workspace:FindFirstChild("Titans")
                if titansFolder then
                    local hasModel = false
                    for _, c in ipairs(titansFolder:GetChildren()) do
                        if c:IsA("Model") then
                            hasModel = true
                            break
                        end
                    end
                    if not hasModel then
                        task.wait(3)
                        if not AutoRetryEnabled then break end
                        TryClickRetry()
                    end
                end
            end
        end)
    end)
end

local function DisableAutoRetry()
    if AutoRetryConnection then
        AutoRetryConnection:Disconnect()
        AutoRetryConnection = nil
    end
    if AutoRetryTitanConnection then
        AutoRetryTitanConnection:Disconnect()
        AutoRetryTitanConnection = nil
    end
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
    return hrp.Anchored == true
end

local function IsTitanValid(titan)
    if not titan or not titan.Parent then return false end
    local folder = GetTitansFolder()
    if not folder then return false end
    if titan.Parent ~= folder then return false end
    return not IsTitanDead(titan)
end

local function ApplyNapeHitbox(overrideSize)
    local size = overrideSize or NapeHitboxSize
    local titans = GetAllTitans()
    for _, titan in ipairs(titans) do
        local nape = GetNapePart(titan)
        if nape and nape:IsA("BasePart") then
            if not OriginalNapeSizes[titan] then
                OriginalNapeSizes[titan] = nape.Size
            end
            nape.Size = Vector3.new(size, size, size)
        end
    end
end

local function RestoreNapeHitbox()
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

local function GetNapeTopPosition(nape)
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

local function RemoveAllVisuals()
    for titan, sel in pairs(HitboxVisuals) do
        if sel and sel.Parent then sel:Destroy() end
    end
    HitboxVisuals = {}
end

RunService.Heartbeat:Connect(function()
    if ExpandNapeHitboxEnabled then
        local targetSize = AutoFarmEnabled and 100 or NapeHitboxSize
        local titans = GetAllTitans()
        for _, titan in ipairs(titans) do
            local nape = GetNapePart(titan)
            if nape and nape:IsA("BasePart") then
                if not OriginalNapeSizes[titan] then
                    OriginalNapeSizes[titan] = nape.Size
                end
                local current = math.max(nape.Size.X, nape.Size.Y, nape.Size.Z)
                if math.abs(current - targetSize) > 0.01 then
                    nape.Size = Vector3.new(targetSize, targetSize, targetSize)
                end
            end
        end
    end
    if VisualizeHitboxEnabled then CreateOrUpdateVisuals() end
end)

local FarmAboveOffset = 2

local function GetFarmCFrame(titan)
    local nape = GetNapePart(titan)
    if not nape then
        local hrp = titan:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local topPos = hrp.Position + Vector3.new(0, 3, 0)
        return CFrame.new(topPos + Vector3.new(0, FarmAboveOffset, 0), topPos)
    end
    local topCorner = GetNapeTopPosition(nape)
    local targetPos = topCorner + Vector3.new(0, FarmAboveOffset, 0)
    return CFrame.new(targetPos, topCorner)
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

local function FindBestTitan()
    local folder = GetTitansFolder()
    if not folder then return nil end
    local best = nil
    local bestHeight = -math.huge
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and IsTitanValid(model) then
            local height = GetTitanHeight(model)
            if height > bestHeight then
                bestHeight = height
                best = model
            end
        end
    end
    return best
end

local function FarmLoop()
    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmEnabled then
            heartbeatConn:Disconnect()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            return
        end
        if IsRefilling then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hum.PlatformStand = true
        if CurrentTarget and IsTitanValid(CurrentTarget) then
            local farmCF = GetFarmCFrame(CurrentTarget)
            if farmCF then
                local dist = (hrp.Position - farmCF.Position).Magnitude
                if dist < 0.5 then
                    hrp.CFrame = farmCF
                else
                    local alpha = math.clamp((TweenSpeed / 16) * 0.15, 0.05, 1)
                    hrp.CFrame = hrp.CFrame:Lerp(farmCF, alpha)
                end
            end
        end
    end)

    task.spawn(function()
        while AutoFarmEnabled do
            if AutoRefillEnabled and not IsRefilling then
                if NeedsRefill() then
                    task.spawn(RefillUntilFull)
                    while IsRefilling do task.wait(0.2) end
                end
            end
            if IsRefilling then task.wait(0.2); continue end

            if not CurrentTarget or not IsTitanValid(CurrentTarget) then
                CurrentTarget = FindBestTitan()
            end
            if not CurrentTarget or not IsTitanValid(CurrentTarget) then
                task.wait(0.3)
                continue
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local farmCF = GetFarmCFrame(CurrentTarget)
                if farmCF then hrp.CFrame = farmCF end
            end

            local nape = GetNapePart(CurrentTarget)
            if nape then SendClick() end

            local hitCount = 1

            while AutoFarmEnabled do
                task.wait(0.2)

                if AutoRefillEnabled and not IsRefilling then
                    if NeedsRefill() then
                        task.spawn(RefillUntilFull)
                        while IsRefilling do task.wait(0.2) end
                    end
                end
                if IsRefilling then continue end

                if not IsTitanValid(CurrentTarget) then
                    CurrentTarget = nil
                    hitCount = 0
                    break
                end

                local c = LocalPlayer.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                if h then
                    local farmCF = GetFarmCFrame(CurrentTarget)
                    if farmCF then h.CFrame = farmCF end
                end

                local napeNow = GetNapePart(CurrentTarget)
                if napeNow then
                    SendClick()
                    hitCount = hitCount + 1

                    if hitCount % 2 == 0 then
                        local headPart = nil
                        pcall(function()
                            for _, desc in ipairs(CurrentTarget:GetDescendants()) do
                                if desc:IsA("MeshPart") and desc.Name == "Head" then
                                    headPart = desc
                                    break
                                end
                            end
                        end)
                        if headPart then
                            pcall(function() headPart.Anchored = true end)
                            task.delay(0.2, function()
                                pcall(function()
                                    if headPart and headPart.Parent then
                                        headPart.Anchored = false
                                    end
                                end)
                            end)
                        end
                    end
                end
            end
        end
    end)

    while AutoFarmEnabled do task.wait(0.05) end
    if heartbeatConn then heartbeatConn:Disconnect() end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    CurrentTarget = nil
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if not AutoReloadEnabled then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        local charsFolder = Workspace:FindFirstChild("Characters")
        if not charsFolder then continue end
        local playerFolder = charsFolder:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then continue end
        local rigName = "Rig_" .. LocalPlayer.Name
        local rig = playerFolder:FindFirstChild(rigName)
        if not rig then continue end
        local blades = {}
        for _, desc in ipairs(rig:GetDescendants()) do
            if desc:IsA("MeshPart") and desc.Name:sub(1, 5) == "Blade" then
                table.insert(blades, desc)
            end
        end
        if #blades == 0 then continue end
        local allBroken = true
        for _, blade in ipairs(blades) do
            local ok, val = pcall(function() return blade:GetAttribute("Broken") end)
            if not ok or not val then allBroken = false; break end
        end
        if allBroken then
            SendReload()
            task.wait(1.5)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not AutoRefillEnabled then
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

local TitanESPObjects = {}

local function RemoveAllTitanESP()
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
                entry.distLabel.Text = dist .. " m"
            end
        end
    end
end)

local Window = Library:CreateWindow({
    Title = " Symbiote ",
    Size = UDim2.new(0, 580, 0, 440),
})

local PlayerTab = Window:CreateTab("Player")
local AutoFarmTab = Window:CreateTab("Auto Farm")
local VariousTab = Window:CreateTab("Various")

local noClipToggleRef = PlayerTab:AddToggle("NoClip", function(state)
    NoClipEnabled = state
    SetSetting("NoClip", state)
    if state then EnableNoClip() else DisableNoClip() end
end)

local walkSpeedToggleRef = PlayerTab:AddToggle("Walk Speed", function(state)
    WalkSpeedEnabled = state
    SetSetting("WalkSpeed", state)
    if state then EnableWalkSpeed() else DisableWalkSpeed() end
end)
local walkSpeedSliderRef = PlayerTab:AddSlider("Walk Speed Amount", 1, 5, GetSetting("WalkSpeedAmount"), function(v)
    WalkSpeedSmoothing = v
    SetSetting("WalkSpeedAmount", v)
end)

local laggyRunToggleRef = PlayerTab:AddToggle("Laggy Run", function(state)
    LaggyRunEnabled = state
    SetSetting("LaggyRun", state)
    if state then EnableLaggyRun() else DisableLaggyRun() end
end)
local laggyRunDistSliderRef = PlayerTab:AddSlider("Laggy Run Distance", 1, 10, GetSetting("LaggyRunDistance"), function(v)
    LaggyRunDistance = v
    SetSetting("LaggyRunDistance", v)
end)
local laggyRunDelaySliderRef = PlayerTab:AddSlider("Laggy Run Delay", 1, 10, GetSetting("LaggyRunDelay"), function(v)
    LaggyRunDelay = v
    SetSetting("LaggyRunDelay", v)
end)

local ctrlClickToggleRef = PlayerTab:AddToggle("CTRL + Click to TP", function(state)
    CtrlClickTPEnabled = state
    SetSetting("CtrlClickTP", state)
    if state then EnableCtrlClickTP() else DisableCtrlClickTP() end
end)

local infiniteJumpToggleRef = PlayerTab:AddToggle("Infinite Jump", function(state)
    InfiniteJumpEnabled = state
    SetSetting("InfiniteJump", state)
    if state then
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not InfiniteJumpEnabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect(); InfiniteJumpConnection = nil end
    end
end)

local autoFarmToggleRef = AutoFarmTab:AddToggle("Auto Farm", function(state)
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
    end
end)

local autoReloadToggleRef = AutoFarmTab:AddToggle("Auto Reload", function(state)
    AutoReloadEnabled = state
    SetSetting("AutoReload", state)
end)

local expandHitboxToggleRef = AutoFarmTab:AddToggle("Expand Nape Hitbox", function(state)
    ExpandNapeHitboxEnabled = state
    SetSetting("ExpandNapeHitbox", state)
    if not state then RestoreNapeHitbox() else ApplyNapeHitbox() end
end)

local hitboxSizeSliderRef = AutoFarmTab:AddSlider("Hitbox Size", 20, 100, GetSetting("HitboxSize"), function(v)
    NapeHitboxSize = v
    SetSetting("HitboxSize", v)
    if ExpandNapeHitboxEnabled then ApplyNapeHitbox() end
end)

local visualizeHitboxToggleRef = AutoFarmTab:AddToggle("Visualize Hitbox", function(state)
    VisualizeHitboxEnabled = state
    SetSetting("VisualizeHitbox", state)
    if not state then RemoveAllVisuals() end
end)

local titanESPToggleRef = VariousTab:AddToggle("Titan ESP", function(state)
    TitanESPEnabled = state
    SetSetting("TitanESP", state)
    if not state then RemoveAllTitanESP() end
end)

local autoRefillToggleRef = VariousTab:AddToggle("Auto Refill", function(state)
    AutoRefillEnabled = state
    SetSetting("AutoRefill", state)
    if not state then SetsWentEmptyAt = nil end
end)

local changeCursorToggleRef = VariousTab:AddToggle("Change Cursor", function(state)
    ChangeCursorEnabled = state
    SetSetting("ChangeCursor", state)
    if state then EnableChangeCursor() else DisableChangeCursor() end
end)

local autoExecuteToggleRef = VariousTab:AddToggle("Auto Execute", function(state)
    SetSetting("AutoExecute", state)
    if queue_on_teleport then
        if state then
            queue_on_teleport([[
                task.wait(3)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/ssssssssss21/Symbiote/refs/heads/main/test.lua"))()
            ]])
        else
            queue_on_teleport("")
        end
    end
end)

local autoRetryToggleRef = VariousTab:AddToggle("Auto Retry", function(state)
    AutoRetryEnabled = state
    SetSetting("AutoRetry", state)
    if state then EnableAutoRetry() else DisableAutoRetry() end
end)

local function ApplySavedSettings()
    WalkSpeedSmoothing = GetSetting("WalkSpeedAmount")
    LaggyRunDistance = GetSetting("LaggyRunDistance")
    LaggyRunDelay = GetSetting("LaggyRunDelay")
    NapeHitboxSize = GetSetting("HitboxSize")

    task.wait(0.3)

    if GetSetting("NoClip") then
        NoClipEnabled = true
        EnableNoClip()
        noClipToggleRef:SetState(true)
    end

    if GetSetting("WalkSpeed") then
        WalkSpeedEnabled = true
        EnableWalkSpeed()
        walkSpeedToggleRef:SetState(true)
    end

    walkSpeedSliderRef:SetValue(GetSetting("WalkSpeedAmount"))

    if GetSetting("LaggyRun") then
        LaggyRunEnabled = true
        EnableLaggyRun()
        laggyRunToggleRef:SetState(true)
    end

    laggyRunDistSliderRef:SetValue(GetSetting("LaggyRunDistance"))
    laggyRunDelaySliderRef:SetValue(GetSetting("LaggyRunDelay"))

    if GetSetting("CtrlClickTP") then
        CtrlClickTPEnabled = true
        EnableCtrlClickTP()
        ctrlClickToggleRef:SetState(true)
    end

    if GetSetting("InfiniteJump") then
        InfiniteJumpEnabled = true
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not InfiniteJumpEnabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        infiniteJumpToggleRef:SetState(true)
    end

    if GetSetting("AutoReload") then
        AutoReloadEnabled = true
        autoReloadToggleRef:SetState(true)
    end

    if GetSetting("ExpandNapeHitbox") then
        ExpandNapeHitboxEnabled = true
        ApplyNapeHitbox()
        expandHitboxToggleRef:SetState(true)
    end

    hitboxSizeSliderRef:SetValue(GetSetting("HitboxSize"))

    if GetSetting("VisualizeHitbox") then
        VisualizeHitboxEnabled = true
        visualizeHitboxToggleRef:SetState(true)
    end

    if GetSetting("TitanESP") then
        TitanESPEnabled = true
        titanESPToggleRef:SetState(true)
    end

    if GetSetting("AutoRefill") then
        AutoRefillEnabled = true
        autoRefillToggleRef:SetState(true)
    end

    if GetSetting("ChangeCursor") then
        ChangeCursorEnabled = true
        EnableChangeCursor()
        changeCursorToggleRef:SetState(true)
    end

    if GetSetting("AutoExecute") then
        autoExecuteToggleRef:SetState(true)
    end

    if GetSetting("AutoRetry") then
        AutoRetryEnabled = true
        EnableAutoRetry()
        autoRetryToggleRef:SetState(true)
    end

    if GetSetting("AutoFarm") then
        AutoFarmEnabled = true
        ExpandNapeHitboxEnabled = true
        NapeHitboxSize = 100
        ApplyNapeHitbox(100)
        task.spawn(FarmLoop)
        autoFarmToggleRef:SetState(true)
        expandHitboxToggleRef:SetState(true)
    end
end

ApplySavedSettings()
