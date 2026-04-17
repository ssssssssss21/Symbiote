local SERVER_URL = "https://web-production-5a98f4.up.railway.app"
local KEY_FILE = "advanced_key.json"

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local _req = (typeof(request) == "function" and request)
    or (typeof(http_request) == "function" and http_request)
    or (syn and typeof(syn.request) == "function" and syn.request)
    or (fluxus and typeof(fluxus.request) == "function" and fluxus.request)
    or nil

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64encode(data)
    local result = {}
    local pad = ""
    local len = #data
    local mod = len % 3
    if mod > 0 then
        data = data .. string.rep("\0", 3 - mod)
        if mod == 1 then pad = "==" elseif mod == 2 then pad = "=" end
    end
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i, i+2)
        local n = a * 65536 + b * 256 + c
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        table.insert(result, string.sub(b64chars, c1+1, c1+1))
        table.insert(result, string.sub(b64chars, c2+1, c2+1))
        table.insert(result, string.sub(b64chars, c3+1, c3+1))
        table.insert(result, string.sub(b64chars, c4+1, c4+1))
    end
    local encoded = table.concat(result)
    if #pad > 0 then
        encoded = string.sub(encoded, 1, #encoded - #pad) .. pad
    end
    encoded = encoded:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
    return encoded
end

local function urlEncode(str)
    str = tostring(str)
    local result = {}
    for i = 1, #str do
        local c = string.sub(str, i, i)
        local b = string.byte(c)
        if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or c == "-" or c == "_" or c == "." or c == "~" then
            table.insert(result, c)
        else
            table.insert(result, string.format("%%%02X", b))
        end
    end
    return table.concat(result)
end

local function doHttp(url, bodyTable)
    local fullUrl = url
    local headers = {["Content-Type"] = "application/json"}
    
    if bodyTable then
        local jsonStr = HttpService:JSONEncode(bodyTable)
        headers["X-Payload"] = base64encode(jsonStr)
    end
    
    if _req then
        local ok, res = pcall(_req, {
            Url = fullUrl,
            Method = "GET",
            Headers = headers
        })
        if not ok then return nil, "HTTP_FAIL: " .. tostring(res) end
        if type(res) ~= "table" then return nil, "RES_NOT_TABLE" end
        return res.Body or res.body or "", nil
    else
        local ok, res = pcall(function()
            return HttpService:RequestAsync({
                Url = fullUrl,
                Method = "GET",
                Headers = headers
            })
        end)
        if not ok then return nil, "HTTP_FAIL: " .. tostring(res) end
        return res.Body or res.body or "", nil
    end
end



local function jDecode(s)
    local ok, v = pcall(function() return HttpService:JSONDecode(s) end)
    return ok and v or nil
end

local function jEncode(t)
    local ok, v = pcall(function() return HttpService:JSONEncode(t) end)
    return ok and v or nil
end

local function saveKey(key)
    pcall(function()
        if writefile then
            writefile(KEY_FILE, jEncode({key = key, date = os.date("%x")}))
        end
    end)
end

local function loadStoredKey()
    local ok, res = pcall(function()
        if isfile and isfile(KEY_FILE) then
            local data = jDecode(readfile(KEY_FILE))
            return data and data.key or ""
        end
        return ""
    end)
    return ok and res or ""
end

local T = {
    Background = Color3.fromRGB(8, 6, 14),
    Surface = Color3.fromRGB(14, 11, 24),
    SurfaceLight = Color3.fromRGB(22, 18, 36),
    SurfaceHover = Color3.fromRGB(32, 26, 52),
    Accent = Color3.fromRGB(140, 60, 255),
    AccentBright = Color3.fromRGB(170, 100, 255),
    AccentDark = Color3.fromRGB(90, 35, 180),
    AccentDim = Color3.fromRGB(55, 25, 110),
    Border = Color3.fromRGB(40, 30, 65),
    BorderLight = Color3.fromRGB(55, 42, 90),
    Text = Color3.fromRGB(245, 240, 255),
    TextSub = Color3.fromRGB(180, 170, 200),
    TextDim = Color3.fromRGB(120, 110, 150),
    TextMuted = Color3.fromRGB(75, 65, 105),
    Success = Color3.fromRGB(80, 220, 150),
    SuccessDim = Color3.fromRGB(30, 80, 55),
    Error = Color3.fromRGB(240, 65, 75),
    ErrorDim = Color3.fromRGB(80, 25, 30),
    DropdownBg = Color3.fromRGB(12, 9, 20),
    Green = Color3.fromRGB(34, 140, 75),
    GreenHover = Color3.fromRGB(40, 170, 90),
    Yellow = Color3.fromRGB(250, 204, 21),
}

local function tw(obj, props, dur, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local old = CoreGui:FindFirstChild("KeySystemGui")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "KeySystemGui"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999
SG.IgnoreGuiInset = true
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 1
Overlay.Parent = SG

local Card = Instance.new("Frame")
Card.Name = "Card"
Card.Size = UDim2.new(0, 460, 0, 310)
Card.Position = UDim2.new(0.5, -230, 0.5, -155)
Card.BackgroundColor3 = T.Background
Card.BorderSizePixel = 0
Card.ClipsDescendants = true
Card.ZIndex = 2
Card.Parent = SG
addStroke(Card, T.Border, 1)

local EdgeGlow = Instance.new("Frame")
EdgeGlow.Size = UDim2.new(1, 6, 1, 6)
EdgeGlow.Position = UDim2.new(0, -3, 0, -3)
EdgeGlow.BackgroundTransparency = 1
EdgeGlow.BorderSizePixel = 0
EdgeGlow.ZIndex = 1
EdgeGlow.Parent = Card

local edgeStroke = Instance.new("UIStroke")
edgeStroke.Color = T.AccentDim
edgeStroke.Thickness = 2
edgeStroke.Transparency = 0.4
edgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
edgeStroke.Parent = EdgeGlow

local edgeGradient = Instance.new("UIGradient")
edgeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(0.15, T.AccentDim),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(20, 12, 40)),
    ColorSequenceKeypoint.new(0.65, Color3.fromRGB(20, 12, 40)),
    ColorSequenceKeypoint.new(0.85, T.AccentDim),
    ColorSequenceKeypoint.new(1, T.Accent),
})
edgeGradient.Rotation = 45
edgeGradient.Parent = edgeStroke

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BackgroundColor3 = T.Accent
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 10
AccentLine.Parent = Card

local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 6, 14)),
    ColorSequenceKeypoint.new(0.2, T.AccentDim),
    ColorSequenceKeypoint.new(0.5, T.AccentBright),
    ColorSequenceKeypoint.new(0.8, T.AccentDim),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 14)),
})
accentGrad.Parent = AccentLine

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.Position = UDim2.new(0, 0, 0, 2)
TopBar.BackgroundColor3 = T.Surface
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = Card

local topBottomLine = Instance.new("Frame")
topBottomLine.Size = UDim2.new(1, 0, 0, 1)
topBottomLine.Position = UDim2.new(0, 0, 1, 0)
topBottomLine.BackgroundColor3 = T.Border
topBottomLine.BorderSizePixel = 0
topBottomLine.ZIndex = 3
topBottomLine.Parent = TopBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Text = utf8.char(9670)
TitleIcon.Size = UDim2.new(0, 30, 0, 42)
TitleIcon.Position = UDim2.new(0, 10, 0, -2)
TitleIcon.BackgroundTransparency = 1
TitleIcon.TextColor3 = T.Accent
TitleIcon.Font = Enum.Font.GothamBlack
TitleIcon.TextSize = 32
TitleIcon.TextYAlignment = Enum.TextYAlignment.Center
TitleIcon.ZIndex = 4
TitleIcon.Parent = TopBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Text = "  Symbiote Key System "
TitleLbl.Size = UDim2.new(1, -100, 1, 0)
TitleLbl.Position = UDim2.new(0, 44, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3 = T.Text
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 17
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
TitleLbl.ZIndex = 4
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = T.ErrorDim
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = T.Error
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 4
CloseBtn.Parent = TopBar

CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {BackgroundColor3 = Color3.fromRGB(120, 30, 35)}, 0.1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {BackgroundColor3 = T.ErrorDim}, 0.1) end)
CloseBtn.MouseButton1Click:Connect(function()
    tw(Card, {Size = UDim2.new(0, 460, 0, 0)}, 0.25)
    task.wait(0.28)
    SG:Destroy()
end)

local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = Card.Position
    end
end)
TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        Card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -40, 1, -64)
Content.Position = UDim2.new(0, 20, 0, 54)
Content.BackgroundTransparency = 1
Content.ZIndex = 3
Content.Parent = Card

local Desc = Instance.new("TextLabel")
Desc.Text = "Enter your key below to continue. If you don't have one, click 'Get Key'."
Desc.Size = UDim2.new(1, 0, 0, 30)
Desc.Position = UDim2.new(0, 0, 0, 0)
Desc.BackgroundTransparency = 1
Desc.TextColor3 = T.TextDim
Desc.Font = Enum.Font.Gotham
Desc.TextSize = 12
Desc.TextXAlignment = Enum.TextXAlignment.Left
Desc.TextWrapped = true
Desc.ZIndex = 3
Desc.Parent = Content

local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, 0, 0, 42)
InputFrame.Position = UDim2.new(0, 0, 0, 42)
InputFrame.BackgroundColor3 = T.DropdownBg
InputFrame.BorderSizePixel = 0
InputFrame.ZIndex = 3
InputFrame.Parent = Content
local InputStroke = addStroke(InputFrame, T.Border, 1)

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.new(0, 10, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.PlaceholderText = "Paste key here..."
KeyInput.PlaceholderColor3 = T.TextMuted
KeyInput.TextColor3 = T.AccentBright
KeyInput.TextSize = 13
KeyInput.Font = Enum.Font.Code
KeyInput.ClearTextOnFocus = false
KeyInput.ZIndex = 4
KeyInput.Text = loadStoredKey()
KeyInput.Parent = InputFrame

KeyInput.Focused:Connect(function()
    tw(InputStroke, {Color = T.Accent}, 0.15)
    tw(InputFrame, {BackgroundColor3 = T.SurfaceLight}, 0.15)
end)
KeyInput.FocusLost:Connect(function()
    tw(InputStroke, {Color = T.Border}, 0.15)
    tw(InputFrame, {BackgroundColor3 = T.DropdownBg}, 0.15)
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = ""
StatusLabel.Size = UDim2.new(1, 0, 0, 22)
StatusLabel.Position = UDim2.new(0, 0, 0, 92)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = T.Error
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.ZIndex = 3
StatusLabel.Parent = Content

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 0, 0, 100)
StatusDot.BackgroundColor3 = T.TextMuted
StatusDot.BackgroundTransparency = 1
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 3
StatusDot.Parent = Content

local function setStatus(msg, col)
    StatusLabel.Text = "    " .. msg
    StatusLabel.TextColor3 = col or T.Error
    StatusDot.BackgroundTransparency = 0
    StatusDot.BackgroundColor3 = col or T.Error
    tw(StatusDot, {BackgroundColor3 = col or T.Error}, 0.2)
end

local function clearStatus()
    StatusLabel.Text = ""
    StatusDot.BackgroundTransparency = 1
end

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.35, -4, 0, 42)
GetKeyBtn.Position = UDim2.new(0, 0, 0, 124)
GetKeyBtn.BackgroundColor3 = T.SurfaceLight
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = T.Accent
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 13
GetKeyBtn.AutoButtonColor = false
GetKeyBtn.ZIndex = 3
GetKeyBtn.Parent = Content
addStroke(GetKeyBtn, T.Border, 1)

GetKeyBtn.MouseEnter:Connect(function() tw(GetKeyBtn, {BackgroundColor3 = T.SurfaceHover}, 0.1) end)
GetKeyBtn.MouseLeave:Connect(function() tw(GetKeyBtn, {BackgroundColor3 = T.SurfaceLight}, 0.1) end)

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.65, -4, 0, 42)
SubmitBtn.Position = UDim2.new(0.35, 4, 0, 124)
SubmitBtn.BackgroundColor3 = T.Accent
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Text = "Continue"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 14
SubmitBtn.AutoButtonColor = false
SubmitBtn.ZIndex = 3
SubmitBtn.Parent = Content

SubmitBtn.MouseEnter:Connect(function() tw(SubmitBtn, {BackgroundColor3 = T.AccentBright}, 0.1) end)
SubmitBtn.MouseLeave:Connect(function() tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1) end)

local DiscordLink = Instance.new("TextButton")
DiscordLink.Size = UDim2.new(1, 0, 0, 30)
DiscordLink.Position = UDim2.new(0, 0, 0, 176)
DiscordLink.BackgroundTransparency = 1
DiscordLink.Text = "Join Discord: discord.gg/w2yCPhqj5"
DiscordLink.TextColor3 = T.AccentBright
DiscordLink.Font = Enum.Font.GothamBold
DiscordLink.TextSize = 13
DiscordLink.AutoButtonColor = false
DiscordLink.ZIndex = 3
DiscordLink.Parent = Content

local discordGlow = Instance.new("UIStroke")
discordGlow.Color = T.Accent
discordGlow.Thickness = 0.5
discordGlow.Transparency = 0.4
discordGlow.Parent = DiscordLink

DiscordLink.MouseEnter:Connect(function() 
    tw(DiscordLink, {TextColor3 = Color3.new(1, 1, 1)}, 0.2)
    tw(discordGlow, {Thickness = 1, Transparency = 0}, 0.2)
end)
DiscordLink.MouseLeave:Connect(function() 
    tw(DiscordLink, {TextColor3 = T.AccentBright}, 0.2)
    tw(discordGlow, {Thickness = 0.5, Transparency = 0.4}, 0.2)
end)

DiscordLink.MouseButton1Click:Connect(function()
    local link = "https://discord.gg/w2yCPhqj5"
    if setclipboard then
        setclipboard(link)
        local old = DiscordLink.Text
        DiscordLink.Text = "Copied to Clipboard!"
        DiscordLink.TextColor3 = T.Success
        discordGlow.Color = T.Success
        task.delay(2, function()
            DiscordLink.Text = old
            DiscordLink.TextColor3 = T.AccentBright
            discordGlow.Color = T.Accent
        end)
    end
end)

local Footer = Instance.new("TextLabel")
Footer.Text = ""
Footer.Size = UDim2.new(1, 0, 0, 20)
Footer.Position = UDim2.new(0, 0, 0, 216)
Footer.BackgroundTransparency = 1
Footer.TextColor3 = T.TextMuted
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 10
Footer.TextXAlignment = Enum.TextXAlignment.Center
Footer.ZIndex = 3
Footer.Parent = Content

local BottomAccent = Instance.new("Frame")
BottomAccent.Size = UDim2.new(1, 0, 0, 2)
BottomAccent.Position = UDim2.new(0, 0, 1, -2)
BottomAccent.BackgroundColor3 = T.Accent
BottomAccent.BorderSizePixel = 0
BottomAccent.ZIndex = 10
BottomAccent.Parent = Card

local bottomGrad = Instance.new("UIGradient")
bottomGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 6, 14)),
    ColorSequenceKeypoint.new(0.2, T.AccentDim),
    ColorSequenceKeypoint.new(0.5, T.AccentBright),
    ColorSequenceKeypoint.new(0.8, T.AccentDim),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 14)),
})
bottomGrad.Parent = BottomAccent

GetKeyBtn.MouseButton1Click:Connect(function()
    GetKeyBtn.Active = false
    GetKeyBtn.Text = "Loading..."
    tw(GetKeyBtn, {TextColor3 = T.TextDim}, 0.1)

    local rawBody, err = doHttp(SERVER_URL .. "/getlink")
    local data = jDecode(rawBody or "")
    if data and data.url then
        setclipboard(data.url)
        setStatus("Link copied to clipboard!", T.Yellow)
        GetKeyBtn.Text = "Copied!"
        tw(GetKeyBtn, {TextColor3 = T.Success}, 0.1)
    else
        setStatus("Failed to get link: " .. tostring(err or (rawBody and rawBody:sub(1,60)) or "Unknown"), T.Error)
    end
    task.delay(2, function()
        GetKeyBtn.Active = true
        GetKeyBtn.Text = "Get Key"
        tw(GetKeyBtn, {TextColor3 = T.Accent}, 0.1)
    end)
end)

SubmitBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:match("^%s*(.-)%s*$")
    if key == "" then
        setStatus("Key cannot be empty!", T.Error)
        return
    end

    SubmitBtn.Active = false
    SubmitBtn.Text = "Verifying..."
    tw(SubmitBtn, {BackgroundColor3 = T.AccentDark}, 0.1)
    setStatus("Authenticating...", T.TextDim)

    local rawBody, err = doHttp(SERVER_URL .. "/getloader", {
        key = key,
        userId = tostring(LocalPlayer.UserId),
        clientId = game:GetService("RbxAnalyticsService"):GetClientId(),
        platform = UIS:GetPlatform().Name,
        executor = (identifyexecutor and identifyexecutor()) or "Unknown"
    })
    if not rawBody then
        setStatus("Connection Error: " .. tostring(err), T.Error)
        SubmitBtn.Active = true
        SubmitBtn.Text = "Continue"
        tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1)
        return
    end

    local data = jDecode(rawBody)
    if not data then
        setStatus("JSON Parse Error: " .. rawBody:sub(1, 50), T.Error)
        SubmitBtn.Active = true
        SubmitBtn.Text = "Continue"
        tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1)
        return
    end

    if not data.success then
        setStatus(tostring(data.reason or "Invalid Key"), T.Error)
        SubmitBtn.Active = true
        SubmitBtn.Text = "Continue"
        tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1)
        return
    end

    saveKey(key)
    setStatus("Success! Loading components...", T.Success)
    SubmitBtn.Text = "Loading..."
    tw(SubmitBtn, {BackgroundColor3 = T.Green}, 0.2)

    task.spawn(function()
        local expiresIso = data.expires_at
        local timeStr = "Unknown"
        if expiresIso and type(expiresIso) == "string" then
            local ok, dt = pcall(function() return DateTime.fromIsoDate(expiresIso) end)
            if ok and dt then
                local secsLeft = dt.UnixTimestamp - DateTime.now().UnixTimestamp
                if secsLeft > 0 then
                    local d = math.floor(secsLeft / 86400)
                    local h = math.floor((secsLeft % 86400) / 3600)
                    local m = math.floor((secsLeft % 3600) / 60)
                    local parts = {}
                    if d > 0 then table.insert(parts, d .. "D") end
                    if h > 0 then table.insert(parts, h .. "H") end
                    if m > 0 or #parts == 0 then table.insert(parts, m .. "M") end
                    timeStr = table.concat(parts, " ")
                else
                    timeStr = "Expired"
                end
            end
        end

        local ToastGui = Instance.new("ScreenGui")
        ToastGui.Name = "KeyExpiryToast"
        ToastGui.ResetOnSpawn = false
        ToastGui.DisplayOrder = 9999
        ToastGui.IgnoreGuiInset = true
        pcall(function() ToastGui.Parent = game:GetService("CoreGui") end)
        if not ToastGui.Parent then
            ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end

        local Toast = Instance.new("Frame")
        Toast.Size = UDim2.new(0, 320, 0, 72)
        Toast.Position = UDim2.new(1, 10, 1, -90)
        Toast.BackgroundColor3 = T.Surface
        Toast.BorderSizePixel = 0
        Toast.ZIndex = 10
        Toast.Parent = ToastGui
        do
            local r = Instance.new("UICorner")
            r.CornerRadius = UDim.new(0, 10)
            r.Parent = Toast
        end
        do
            local s = Instance.new("UIStroke")
            s.Color = T.Border
            s.Thickness = 1
            s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            s.Parent = Toast
        end

        local strip = Instance.new("Frame")
        strip.Size = UDim2.new(0, 3, 1, -16)
        strip.Position = UDim2.new(0, 0, 0, 8)
        strip.BackgroundColor3 = T.Success
        strip.BorderSizePixel = 0
        strip.ZIndex = 11
        strip.Parent = Toast
        do
            local r = Instance.new("UICorner")
            r.CornerRadius = UDim.new(0, 3)
            r.Parent = strip
        end

        local TopLine = Instance.new("TextLabel")
        TopLine.Text = utf8.char(9670) .. "  Key Active"
        TopLine.Size = UDim2.new(1, -20, 0, 24)
        TopLine.Position = UDim2.new(0, 14, 0, 10)
        TopLine.BackgroundTransparency = 1
        TopLine.TextColor3 = T.Success
        TopLine.Font = Enum.Font.GothamBold
        TopLine.TextSize = 14
        TopLine.TextXAlignment = Enum.TextXAlignment.Left
        TopLine.ZIndex = 11
        TopLine.Parent = Toast

        local BotLine = Instance.new("TextLabel")
        BotLine.Text = "Key will expire in:  " .. timeStr
        BotLine.Size = UDim2.new(1, -20, 0, 22)
        BotLine.Position = UDim2.new(0, 14, 0, 36)
        BotLine.BackgroundTransparency = 1
        BotLine.TextColor3 = T.TextSub
        BotLine.Font = Enum.Font.Gotham
        BotLine.TextSize = 12
        BotLine.TextXAlignment = Enum.TextXAlignment.Left
        BotLine.ZIndex = 11
        BotLine.Parent = Toast

        TweenService:Create(Toast, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -330, 1, -90)}):Play()

        task.wait(5)
        TweenService:Create(Toast, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 1, -90)}):Play()
        task.wait(0.38)
        ToastGui:Destroy()
    end)

    task.wait(0.5)

    local loaderCode = data.loader
    if type(loaderCode) ~= "string" or loaderCode == "" then
        setStatus("Server Error: Please try again.", T.Error)
        SubmitBtn.Active = true
        SubmitBtn.Text = "Continue"
        tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1)
        return
    end

    local loaderFn, compErr = loadstring(loaderCode, "Load")

    if not loaderFn then
        setStatus("Initialization failed. Please try again.", T.Error)
        SubmitBtn.Active = true
        SubmitBtn.Text = "Continue"
        tw(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.1)
        return
    end

    tw(Card, {Size = UDim2.new(0, 460, 0, 0)}, 0.25)
    tw(Overlay, {BackgroundTransparency = 1}, 0.25)
    task.wait(0.28)
    SG:Destroy()

    task.spawn(function()
        local sessToken = data.session_token
        if not sessToken then return end
        
        task.spawn(function()
            while task.wait(20) do
                pcall(function() doHttp(SERVER_URL .. "/heartbeat", {token = sessToken}) end)
            end
        end)
        
        local function deactivate() 
            pcall(function() doHttp(SERVER_URL .. "/deactivate", {token = sessToken}) end) 
        end
        pcall(function() game:BindToClose(deactivate) end)
        pcall(function() Players.PlayerRemoving:Connect(function(p) if p == LocalPlayer then deactivate() end end) end)
    end)

    pcall(loaderFn)
end)
