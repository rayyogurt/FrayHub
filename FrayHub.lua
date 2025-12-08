-- [[ 0. AUTO-KILL OLD SCRIPT (CLEANUP BEFORE EXECUTE) ]] --
if _G.FrayhubConnections then
    for _, conn in pairs(_G.FrayhubConnections) do
        if conn then conn:Disconnect() end
    end
    _G.FrayhubConnections = {}
end

-- Cleanup Variable Scanner Khusus
if _G.ActiveScannerConnection then
    _G.ActiveScannerConnection:Disconnect()
    _G.ActiveScannerConnection = nil
end

-- Hapus UI Lama
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("FrayHub | Main Version 2.0") then
    CoreGui["FrayHub | Main Version 2.0"]:Destroy()
end

_G.FrayhubConnections = {}
_G.ScanSecretToggle = false 
_G.ChatScan = false 

-- Pastikan ID Pesan tersimpan di Global agar tidak reset saat re-execute
_G.FrayHub_MessageID = _G.FrayHub_MessageID or nil

-- [[ 1. KONFIGURASI UTAMA ]] --
local _G_WebhookURL = "https://discord.com/api/webhooks/1442845013057863743/lJMKfMxHsoEw4UGnZ4mRed_JIK8mFNElRRqZ9imqSC-DdeWrYLIHufHpGf1KfNPpYtw4"
local _G_LiveStatsWebhook = "https://discord.com/api/webhooks/1447642456287088740/kgVrTAt_sTiqbBjwwn3FAuE_LZdia-d5TzaAPcP_4_s8olFg4AY-qiiV4LRXiZGQr-4n"

-- DATABASE IKAN SECRET 
local _G_SecretFishList = {
    -- [[ Fisherman Island ]]
    "Crystal Crab",
    "Orca",

    -- [[ Kohana ]]
    "Lochness Monster",

    -- [[ Esoteric Depths ]]
    "Thin Armor Shark",
    "Scare", -- Pastikan ejaan ini benar sesuai game

    -- [[ The Coral Reefs ]]
    "Eerie Shark",
    "Monster Shark",

    -- [[ Tropical Grove ]]
    "Great Whale",

    -- [[ Crater Island / Icy ]]
    "Frostborn Shark",

    -- [[ Ocean / General ]]
    "Worm Fish",
    "Ghost Shark",
    "Megalodon",
    "Ghost Worm",
    "Blob Shark",
    "Skeleton Narwhal",

    -- [[ Treasure Room (Lost Isle) ]]
    "Queen Crab",
    "King Crab",

    -- [[ Sisyphus Statue (Lost Isle) ]]
    "Panther Eel",
    "Giant Squid",
    "Robot Kraken",
    "Cryoshade Glider",
    "Depthseeker Ray",

    -- [[ Ancient Jungle / Sacred Temple ]]
    "Elshark Gran Maja",
    "Bone Whale",
    "Mosasaur Shark",
    "King Jelly",

    -- [[ Ancient Ruin ]]
    "Ancient Lochness Monster",
    "Gladiator Shark",

    -- [[ Classic Island ]]
    "ElRetro Gran Maja",
    "1x1x1x1 Shark",

    -- [[ Event Limited Fish ]]
    "Bloodmoon Whale",
    "Strawberry Choc Megalodon",
    "Hacker Shark"
}

-- Custom List Default
local _G_CustomFishList = { "Sacred Guardian Squid" }

-- [[ 2. UTILITIES: PARSING & DISCORD ]] --
local HttpService = game:GetService("HttpService")
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- Fungsi Formatting Fixed Width (Padding Spasi)
local function FormatFixed(str, length)
    local s = tostring(str)
    if #s > length then 
        return string.sub(s, 1, length) 
    else 
        return s .. string.rep(" ", length - #s) 
    end
end

-- Fungsi Mengirim/Update Live Stats ke Discord (Updated Format & Logic)
local function UpdateDiscordLiveStats(discordString, playerCountStr)
    if not httpRequest or _G_LiveStatsWebhook == "" then return end
    
    local timestamp = os.date("%H:%M:%S")
    
    local embedData = {
        ["username"] = "FrayHub Live Tracker",
        ["avatar_url"] = "https://i.imgur.com/WxwNoO6.jpeg",
        ["embeds"] = {{
            ["title"] = "<a:RedCircle:759942169980567632> Live Player Statistic (" .. playerCountStr .. ")", 
            ["description"] = discordString,
            ["color"] = 65280, -- Hijau
            ["footer"] = { ["text"] = "Last Update: " .. timestamp },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local jsonData = HttpService:JSONEncode(embedData)

    -- Logika Update yang Lebih Aman (Pakai Global ID)
    if _G.FrayHub_MessageID == nil then
        -- POST Request (Kirim Baru)
        local response = httpRequest({
            Url = _G_LiveStatsWebhook .. "?wait=true",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonData
        })
        
        if response and response.Body then
            local decoded = nil
            pcall(function() decoded = HttpService:JSONDecode(response.Body) end)
            if decoded and decoded.id then 
                _G.FrayHub_MessageID = decoded.id 
            end
        end
    else
        -- PATCH Request (Edit Pesan Lama)
        local response = httpRequest({
            Url = _G_LiveStatsWebhook .. "/messages/" .. _G.FrayHub_MessageID,
            Method = "PATCH",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonData
        })
        
        -- Jika pesan dihapus manual (404) atau Error lain, reset ID agar buat baru
        if response and (response.StatusCode == 404 or response.StatusCode == 400) then 
            _G.FrayHub_MessageID = nil 
        end
    end
end

local function ParseFishData(msg)
    local data = { PlayerName = "Unknown", FishName = msg, Weight = "N/A", Mutation = "None" }
    local player, fullContent, weight = msg:match("^(.+) obtained an? (.+) %((.-)%)")
    if not player then player, fullContent, weight = msg:match("^(.+) menangkap (.+) %(%s*(.-)%)") end

    if player and fullContent then
        player = player:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
        data.PlayerName = player
        data.Weight = weight or "N/A"
        
        local detectedFishName = nil
        local allKnownFish = {}
        for _, v in pairs(_G_SecretFishList) do table.insert(allKnownFish, v) end
        for _, v in pairs(_G_CustomFishList) do table.insert(allKnownFish, v) end
        table.sort(allKnownFish, function(a, b) return #a > #b end)
        
        for _, fish in pairs(allKnownFish) do
            if fullContent:lower():find(fish:lower(), 1, true) then
                detectedFishName = fish; break
            end
        end
        
        if detectedFishName then
            data.FishName = detectedFishName
            local safeFishName = detectedFishName:lower():gsub("([%-%^%$%(%)%%%.%[%]%*%+%?])", "%%%1")
            local mutationStr = fullContent:lower():gsub(safeFishName, "")
            mutationStr = mutationStr:gsub("^%s+", ""):gsub("%s+$", "")
            data.Mutation = (mutationStr ~= "" and mutationStr ~= " ") and mutationStr:sub(1,1):upper()..mutationStr:sub(2) or "None"
        else
            data.FishName = fullContent; data.Mutation = "None"
        end
    end
    return data
end

local function CheckRarity(msg)
    local msgLower = msg:lower()
    for _, secretName in ipairs(_G_SecretFishList) do if string.find(msgLower, secretName:lower()) then return "Secret" end end
    if string.find(msg, "Enchant Stone") or string.find(msg, "Astra Damsel") then return "Epic" end
    if string.find(msg, "Magic Tang") or string.find(msg, "Big Temple") or string.find(msg, "Megalodon") then return "Legendary" end
    if string.find(msg, "Mythic") or string.find(msg, "Abyssal") then return "Mythic" end
    return "Other"
end

local function SendToDiscord(msg, rarity, colorDec, source, fishData)
    if _G_WebhookURL == "" or not _G_WebhookURL:find("http") then return end
    local timestamp = os.date("%H:%M:%S • %d/%m/%Y")
    local embedData = {
        ["username"] = "FrayHub Notification",
        ["avatar_url"] = "https://i.pinimg.com/originals/1b/ce/fe/1bcefe9201469c9fbbd932e4c5ab971d.gif",
        ["embeds"] = {{
            ["title"] = "<a:RedCircle:759942169980567632> " .. rarity .. " Catch Detected!",
            ["color"] = colorDec,
            ["thumbnail"] = { ["url"] = "https://i.imgur.com/WxwNoO6.jpeg" },
            ["fields"] = {
                { ["name"] = "**<a:owner:1407568729998360616> Player**", ["value"] = fishData.PlayerName, ["inline"] = false },
                { ["name"] = "**<a:swimming:1444221538587906142> Fish**", ["value"] = fishData.FishName, ["inline"] = false },
                { ["name"] = "**<:Scales:1444224451616051322> Weight**", ["value"] = fishData.Weight, ["inline"] = false },
                { ["name"] = "**<a:PinkSparkles:1444225554269212833> Mutation**", ["value"] = fishData.Mutation, ["inline"] = false },
                { ["name"] = "**<a:clock_running:1444223436221059194> Time**", ["value"] = timestamp, ["inline"] = false }
            },
            ["footer"] = { ["text"] = "FrayHub | By Frayphale" }
        }}
    }
    httpRequest({ Url = _G_WebhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(embedData) })
end

-- [[ 3. LOAD UI RAYFIELD ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "FrayHub | Main Version 2.0",
    Icon = 0,
    LoadingTitle = "FrayHub | Main Version 2.0",
    LoadingSubtitle = "by Frayphale",
    Theme = "Amethyst",
    ToggleUIKeybind = "G",
    ConfigurationSaving = { Enabled = true, FileName = "Frayhub_Config" },
    KeySystem = true,
    KeySettings = {
        Title = "FrayHub Key", Subtitle = "Link In Discord Server", Note = "Community and Marketplace Server",
        FileName = "Frayhubkey", SaveKey = true, GrabKeyFromSite = true, Key = {"https://pastebin.com/raw/DttgzM1m"}
    }
})

-- Variabel Global Runtime
local _G_InfJumpConnection = nil
local _G_NoclipConnection = nil
local _G_ActiveScannerConnection = nil 
local _G_SelectedPlayerToTP = nil
local _G_SelectedAreaToTP = "Lost Isle"
local _G_AutoUpdateStats = false
local _G_LastPlayerPositions = {}
local _G_FishingTracker = {}
local _G_SortMethod = "Name"
local _G_FavoriteFilterList = {}
local CustomFishDisplayParagraph = nil
local InfoParagraph = nil

local IslandZones = {
    {Name = "Fisherman Island", Pos = Vector3.new(79, 17, 2848),    Radius = 305},
    {Name = "Esoteric Depths",  Pos = Vector3.new(3226, -1302, 1407), Radius = 305},
    {Name = "Sacred Temple",    Pos = Vector3.new(1475, -21, -631),   Radius = 305},
    {Name = "Ancient Jungle",   Pos = Vector3.new(1489, 7, -430),     Radius = 477.5}
}

-- UTILITIES FORMATTING
local function FormatShortNum(n)
    local num = tonumber(n) or 0
    if num >= 1000000000 then return string.format("%.2fB", num/1e9):gsub("%.00","")
    elseif num >= 1000000 then return string.format("%.2fM", num/1e6):gsub("%.00","")
    elseif num >= 1000 then return string.format("%.1fk", num/1e3):gsub("%.0","")
    else return tostring(num) end
end
local function FormatIconRight(text, icon, length)
    local s = tostring(text)
    local maxTextLen = length - 1
    if #s > maxTextLen then s = string.sub(s, 1, maxTextLen) end
    local spaceCount = length - #s - 1
    if spaceCount < 0 then spaceCount = 0 end
    return s .. string.rep(" ", spaceCount) .. icon
end
local function ParseAbbr(str)
    str = str:lower():gsub(",", "")
    local val = tonumber(str:match("[%d.]+")) or 0
    if str:find("k") then val = val * 1000 end
    if str:find("m") then val = val * 1000000 end
    if str:find("b") then val = val * 1000000000 end
    return val
end
local function GetCaughtAmount(plr)
    if plr:FindFirstChild("leaderstats") then
        local s = plr.leaderstats:FindFirstChild("Caught") or plr.leaderstats:FindFirstChild("Fish")
        if s then return tonumber(s.Value) or 0 end
    end
    return 0
end
local function GetDisplayStatData(plr)
    local caught = GetCaughtAmount(plr)
    if plr:FindFirstChild("leaderstats") then
        local rare = plr.leaderstats:FindFirstChild("Rarest Fish") or plr.leaderstats:FindFirstChild("Rarest")
        if rare then
            local valString = tostring(rare.Value)
            local maxVal = 0
            local found = false
            for s in valString:gmatch("[%d.,]+[kKmMbB]?") do
                local val = ParseAbbr(s)
                if val > 0 then found = true; if val > maxVal then maxVal = val end end
            end
            if found then return maxVal, "1/" .. FormatShortNum(maxVal) end
        end
    end
    return caught, "1/" .. FormatShortNum(caught)
end
local function GetPlayerNamesForList()
    local names = {}
    for _, v in pairs(game.Players:GetPlayers()) do table.insert(names, v.Name) end
    table.sort(names)
    return names
end

--[[ TAB 1: HOME ]]
local HomeTab = Window:CreateTab("🏠 Home", nil)
HomeTab:CreateSection("Community Hub")
HomeTab:CreateParagraph({Title = "FrayHub | Community", Content = "Join our Discord for Keys, Updates & Support"})
HomeTab:CreateButton({Name = "Copy Link Join Discord Here", Callback = function() setclipboard("https://discord.gg/cPDWVsgx") Rayfield:Notify({Title = "Link Copied", Content = "Discord Link copied!", Duration = 3}) end})

--[[ TAB 2: PLAYER ]]
local PlayerTab = Window:CreateTab("👤 Player", nil)
PlayerTab:CreateSection("Character Movement")
PlayerTab:CreateSlider({Name = "Walkspeed", Range = {16, 300}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "WalkspeedSlider", Callback = function(Value) if game.Players.LocalPlayer.Character then game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value end end})
PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump", Callback = function(Value)
    if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() _G_InfJumpConnection = nil end
    if Value then _G_InfJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function() game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end) table.insert(_G.FrayhubConnections, _G_InfJumpConnection) end
end})
PlayerTab:CreateToggle({Name = "Noclip", CurrentValue = false, Flag = "Noclip", Callback = function(Value)
    if _G_NoclipConnection then _G_NoclipConnection:Disconnect() _G_NoclipConnection = nil end
    if Value then _G_NoclipConnection = game:GetService("RunService").Stepped:Connect(function() if game.Players.LocalPlayer.Character then for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end end) table.insert(_G.FrayhubConnections, _G_NoclipConnection) end
end})

--[[ TAB 3: TELEPORT ]]
local TeleportTab = Window:CreateTab("📍 Teleport", nil)
TeleportTab:CreateSection("Target Player Teleport")
local PlayerDropdown = TeleportTab:CreateDropdown({Name = "Select Player", Options = GetPlayerNamesForList(), CurrentOption = {""}, MultipleOptions = false, Flag = "PlayerSelect", Callback = function(Options) _G_SelectedPlayerToTP = Options[1] end})
TeleportTab:CreateButton({Name = "🔄 Refresh List", Callback = function() PlayerDropdown:Refresh(GetPlayerNamesForList(), true) end})
TeleportTab:CreateButton({Name = "🚀 Teleport to Selected Player", Callback = function() if _G_SelectedPlayerToTP and game.Players:FindFirstChild(_G_SelectedPlayerToTP) then game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players[_G_SelectedPlayerToTP].Character.HumanoidRootPart.CFrame end end})
TeleportTab:CreateSection("Island Teleport")
TeleportTab:CreateDropdown({Name = "Select Area", Options = {"Lost Isle", "Ancient Jungle", "Esoteric Depths", "Sacred Temple", "Fisherman Island"}, CurrentOption = {"Lost Isle"}, MultipleOptions = false, Flag = "TeleportArea", Callback = function(Options) _G_SelectedAreaToTP = Options[1] end})
TeleportTab:CreateButton({Name = "🚀 Teleport to Selected Area", Callback = function() for _, z in pairs(IslandZones) do if z.Name == _G_SelectedAreaToTP then game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(z.Pos) return end end game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-3735, -135, -1011) end})

--[[ TAB 4: LOG ]]
local LogTab = Window:CreateTab("📜 Log", nil)
LogTab:CreateSection("Scanner & Filter")
local function HandleScannedMessage(msg, source)
    local cleanMsg = msg:gsub("<[^>]+>", ""):gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
    local fishData = ParseFishData(cleanMsg)
    local isCustomTarget = false
    if fishData.FishName ~= cleanMsg then for _, targetName in pairs(_G_CustomFishList) do if fishData.FishName:lower():find(targetName:lower()) then isCustomTarget = true; break end end end
    if not isCustomTarget then for _, targetName in pairs(_G_CustomFishList) do if cleanMsg:lower():find(targetName:lower()) then isCustomTarget = true; break end end end
    local msgRarity = CheckRarity(cleanMsg)
    local isAllowed = false
    if isCustomTarget then isAllowed = true; msgRarity = "Custom Target"
    elseif _G.ScanSecretToggle then if msgRarity == "Secret" then isAllowed = true end
    else if msgRarity ~= "Other" then isAllowed = true end end
    if not isAllowed then return end
    local discordColor = 16777215
    if msgRarity == "Epic" then discordColor = 10181046 elseif msgRarity == "Legendary" then discordColor = 15105570 elseif msgRarity == "Mythic" then discordColor = 15158332 elseif msgRarity == "Secret" then discordColor = 3066993 elseif msgRarity == "Custom Target" then discordColor = 48340 end
    pcall(function() SendToDiscord(cleanMsg, msgRarity, discordColor, source, fishData) end)
end

LogTab:CreateToggle({Name = "✨ Start Auto Scan (Secret & Custom Only)", CurrentValue = false, Flag = "AutoScanCombined", Callback = function(Value)
    _G.ScanSecretToggle = Value; _G.ChatScan = Value
    if _G_ActiveScannerConnection then _G_ActiveScannerConnection:Disconnect() _G_ActiveScannerConnection = nil end
    if Value then
        if game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService then
            _G_ActiveScannerConnection = game:GetService("TextChatService").MessageReceived:Connect(function(msgObj)
                local source = msgObj.PrefixText or "Unknown"; source = source:gsub("<[^>]+>", ""):gsub(":", "")
                if source == "" or string.find(source, "Server") then source = "Server" end
                if string.find(source, "System") then source = "System" end
                HandleScannedMessage(msgObj.Text, source) 
            end)
        else
            local ChatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            if ChatEvents then
                local OnMessage = ChatEvents:FindFirstChild("OnMessageDoneFiltering")
                if OnMessage then _G_ActiveScannerConnection = OnMessage.OnClientEvent:Connect(function(data) local source = data.FromSpeaker or "System"; HandleScannedMessage(data.Message, source) end) end
            end
        end
        if _G_ActiveScannerConnection then table.insert(_G.FrayhubConnections, _G_ActiveScannerConnection) end
        Rayfield:Notify({Title = "Scanner Started", Content = "Scanning...", Duration = 3})
    else Rayfield:Notify({Title = "Scanner Stopped", Content = "Monitoring paused.", Duration = 2}) end
end})

LogTab:CreateSection("Custom Target List") 
local function UpdateCustomListUI() local listContent = "None"; if #_G_CustomFishList > 0 then listContent = table.concat(_G_CustomFishList, ", ") end; if CustomFishDisplayParagraph then CustomFishDisplayParagraph:Set({Title = "Custom Fish List", Content = listContent}) end end
LogTab:CreateInput({Name = "Add Fish (Ex: Synodontis)", PlaceholderText = "Fish Name...", RemoveTextAfterFocusLost = true, Callback = function(Text) if Text and Text ~= "" then table.insert(_G_CustomFishList, Text); UpdateCustomListUI() end end})
CustomFishDisplayParagraph = LogTab:CreateParagraph({Title = "Custom Fish List", Content = "None"}) 
UpdateCustomListUI()
LogTab:CreateButton({Name = "Reset", Callback = function() _G_CustomFishList = {}; UpdateCustomListUI(); Rayfield:Notify({Title = "Reset", Content = "List cleared.", Duration = 2}) end})

--[[ TAB 5: DATA ]]
local DataTab = Window:CreateTab("📊 Data", nil)
local DataSection = DataTab:CreateSection("Live Player Data & Filter")

DataTab:CreateDropdown({Name = "Sort By", Options = {"Name", "Location", "Rarest Fish"}, CurrentOption = {"Name"}, MultipleOptions = false, Flag = "SortDropdown", Callback = function(Options) _G_SortMethod = Options[1] end})
local StatsParagraph = DataTab:CreateParagraph({Title = "( Loading... )", Content = "Activate Auto Update to see list..."})

local function UpdatePlayerData()
    local tempStats = {}
    local discordList = {}
    local players = game.Players:GetPlayers()
    local playerCount = #players
    local playerCountStr = playerCount .. "/" .. game.Players.MaxPlayers
    local statusIcon = playerCount >= 20 and "🔴" or "🟢"
    if InfoParagraph then InfoParagraph:Set({Title = "Status", Content = "Active: " .. playerCountStr}) end
    local currentTime = tick()
    
    for _, player in pairs(players) do
        local isShown = true
        if #_G_FavoriteFilterList > 0 then isShown = false; for _, favName in pairs(_G_FavoriteFilterList) do if favName == player.Name then isShown = true break end end end
        if isShown then
            local rawPlace = "Loading..."
            local rawRarestValue = 0
            local rawStatStr, rawFishStatus, rawMoveStatus = "-", "Check", "Wait"
            local fishIcon, moveIcon = "🟢", "🔴"
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local currentPos = player.Character.HumanoidRootPart.Position
                local closestZoneName, closestDist = "Open Ocean", math.huge
                for _, zone in pairs(IslandZones) do local dist = (currentPos - zone.Pos).Magnitude; if dist <= zone.Radius and dist < closestDist then closestDist = dist; closestZoneName = zone.Name end end
                rawPlace = closestZoneName
                
                local lastPos = _G_LastPlayerPositions[player.Name]
                if lastPos then if (currentPos - lastPos).Magnitude > 0.2 then rawMoveStatus = "Mov"; moveIcon = "🟢" else rawMoveStatus = "Idle"; moveIcon = "🟡" end else rawMoveStatus = "Idle"; moveIcon = "🟡" end
                _G_LastPlayerPositions[player.Name] = currentPos
                
                local currentCaught = GetCaughtAmount(player)
                rawRarestValue, rawStatStr = GetDisplayStatData(player)
                
                local tracker = _G_FishingTracker[player.Name]
                if not tracker then 
                    _G_FishingTracker[player.Name] = {LastCount = currentCaught, LastChangeTime = currentTime}
                    rawFishStatus = "Fish"; fishIcon = "🟢"
                else 
                    if currentCaught > tracker.LastCount then 
                        tracker.LastCount = currentCaught; tracker.LastChangeTime = currentTime; rawFishStatus = "Fish"; fishIcon = "🟢" 
                    else 
                        if (currentTime - tracker.LastChangeTime) > 30 then rawFishStatus = "AFK"; fishIcon = "🔴" else rawFishStatus = "Fish"; fishIcon = "🟢" end 
                    end 
                end
                
                -- UI Display (Tetap Lengkap)
                local displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>', "<b>"..FormatFixed(" "..player.Name.." ",15).."</b>", FormatFixed(rawPlace,16), FormatFixed(" "..rawStatStr.." ",9), FormatIconRight(rawFishStatus,fishIcon,7), FormatIconRight(rawMoveStatus,moveIcon,7))
                
                -- Discord Display (Format Rapi: Name | Fish/AFK | Rarity)
                -- 1. Nama di-pad 13 karakter, dibungkus backtick ` `
                local namePadded = FormatFixed(player.Name, 13)
                
                -- 2. Status di tengah, tanpa backtick agar Emoji Animasi jalan
                local discordStatus = rawFishStatus
                if rawFishStatus == "Fish" then
                    discordStatus = "Fish <a:pink_alert:1407568565237977209>"
                elseif rawFishStatus == "AFK" then
                    discordStatus = "AFK <a:Siren:1407567643292074054>"
                end
                
                -- 3. Rarity di-pad 10 karakter, dibungkus backtick ` `
                local statPadded = FormatFixed(rawStatStr, 10)
                
                local discordLine = string.format("<a:Arrow_White:1411455961209503855> `%s` | %s | `%s`", namePadded, discordStatus, statPadded)
                
                table.insert(tempStats, {Name=player.Name, Place=rawPlace, Rarest=rawRarestValue, Display=displayString, DiscordLine=discordLine})
            else
                local displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>', "<b>"..FormatFixed(" "..player.Name.." ",15).."</b>", FormatFixed("Dead/Loading",16), FormatFixed(" - ",9), FormatIconRight("Wait","🔴",7), FormatIconRight("Wait","🔴",7))
                table.insert(tempStats, {Name=player.Name, Place="Dead/Loading", Rarest=-1, Display=displayString, DiscordLine=""})
            end
        end
    end
    
    if _G_SortMethod == "Name" then table.sort(tempStats, function(a,b) return a.Name:lower() < b.Name:lower() end)
    elseif _G_SortMethod == "Location" then table.sort(tempStats, function(a,b) return a.Place < b.Place end)
    elseif _G_SortMethod == "Rarest Fish" then table.sort(tempStats, function(a,b) return a.Rarest > b.Rarest end) end
    
    local uiList = {}
    for _, data in ipairs(tempStats) do 
        table.insert(uiList, data.Display) 
        if data.DiscordLine ~= "" then table.insert(discordList, data.DiscordLine) end
    end
    
    local finalUIString = table.concat(uiList, "\n")
    local finalDiscordString = table.concat(discordList, "\n")
    
    StatsParagraph:Set({Title = "<b>Player List ("..playerCountStr..")</b> "..statusIcon, Content = finalUIString})
    
    -- Panggil Update Discord di dalam pcall biar kalau error ga stop loop
    if _G_AutoUpdateStats then 
        task.spawn(function() 
            pcall(function() UpdateDiscordLiveStats(finalDiscordString, playerCountStr) end) 
        end) 
    end
end

local ToggleAutoUpdate = DataTab:CreateToggle({
    Name = "Auto Update Data (Every 1s)", CurrentValue = false, Flag = "AutoUpdateStats",
    Callback = function(Value)
        _G_AutoUpdateStats = Value
        if Value then 
            task.spawn(function() 
                while _G_AutoUpdateStats do 
                    -- Bungkus UpdatePlayerData dalam pcall agar loop tidak pernah putus
                    pcall(function() UpdatePlayerData() end)
                    task.wait(1) 
                end 
            end) 
        else
            -- Optional: Reset ID kalau mau bikin pesan baru pas dinyalain lagi
            -- _G.FrayHub_MessageID = nil (Disable ini agar tetap edit pesan lama kalau dimatikan sebentar)
        end
    end,
})

local FavoriteDropdown = DataTab:CreateDropdown({Name = "Favorite Players", Options = GetPlayerNamesForList(), CurrentOption = {}, MultipleOptions = true, Flag = "FavoritePlayerFilter", Callback = function(Options) _G_FavoriteFilterList = Options end})
DataTab:CreateButton({Name = "Refresh Player List", Callback = function() FavoriteDropdown:Refresh(GetPlayerNamesForList(), true); Rayfield:Notify({Title = "Refreshed", Content = "Dropdown updated.", Duration = 1}) end})

--[[ TAB 6: MISC ]]
local MiscTab = Window:CreateTab("⚙️ Misc", nil)
MiscTab:CreateSection("Server Info")
InfoParagraph = MiscTab:CreateParagraph({Title = "Status", Content = "Initializing..."})
MiscTab:CreateButton({Name = "🔁 Rejoin Server", Callback = function() Rayfield:Notify({Title = "Rejoining...", Content = "Hop to same server.", Duration = 2}); game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer) end})
MiscTab:CreateSection("Utility")
local function SuperLowGraphics()
    local terrain = workspace:FindFirstChildOfClass("Terrain"); if terrain then terrain.WaterWaveSize=0; terrain.WaterReflectance=0; terrain.WaterTransparency=0 end
    game.Lighting.GlobalShadows=false; game.Lighting.FogEnd=9e9; game.Lighting.Brightness=0; settings().Rendering.QualityLevel="Level01"
    for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic; v.Reflectance=0; v.CastShadow=false elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled=false elseif v:IsA("MeshPart") then v.RenderFidelity=Enum.RenderFidelity.Performance end end
end
MiscTab:CreateToggle({Name = "Super Low Graphic", CurrentValue = false, Flag = "LowGraphics", Callback = function(V) if V then SuperLowGraphics() Rayfield:Notify({Title = "Potato Mode", Content = "Graphics minimized.", Duration = 2}) end end})
MiscTab:CreateToggle({Name = "Anti AFK", CurrentValue = false, Flag = "AntiAFK", Callback = function(Value)
    _G.AntiAFK = Value
    if Value then if not _G.AntiAFKConnection then _G.AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function() if _G.AntiAFK then game:GetService("VirtualUser"):CaptureController(); game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end end) end Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled.", Duration = 2})
    else if _G.AntiAFKConnection then _G.AntiAFKConnection:Disconnect() _G.AntiAFKConnection = nil end Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled.", Duration = 2}) end
end})

Rayfield:Notify({Title = "Frayhub Loaded", Content = "All Systems Go!", Duration = 5, Image = nil})
