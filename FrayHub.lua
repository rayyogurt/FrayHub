-- [[ KONFIGURASI DISCORD ]] --
local _G_WebhookURL = "https://discord.com/api/webhooks/1442845013057863743/lJMKfMxHsoEw4UGnZ4mRed_JIK8mFNElRRqZ9imqSC-DdeWrYLIHufHpGf1KfNPpYtw4"

-- UTILITIES BARU: Fungsi untuk mengurai data ikan dari pesan
local function ParseFishData(msg)
    local data = {
        FishName = "Unknown Fish",
        Weight = "N/A",
        Mutation = "None",
        PlayerName = "N/A"
    }
    
    -- Pola 1: Mencari format umum "Player menangkap Fish (Weight)"
    -- Contoh: "[PlayerName] menangkap [FishName] ([Weight])"
    local playerMatch, fishMatch, weightMatch = msg:match("(.+) menangkap (.+) %(%s*([%d%.%s]+[kKmMBB]?)%)")
    
    if playerMatch and fishMatch and weightMatch then
        -- Hapus prefix [Server]: atau [System]: jika masih ada
        playerMatch = playerMatch:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
        
        data.PlayerName = playerMatch
        data.FishName = fishMatch
        data.Weight = weightMatch
    else
        -- Jika tidak cocok, gunakan pesan utuh sebagai nama ikan (untuk log non-player/item)
        data.FishName = msg
        data.PlayerName = "System/Server"
    end
    
    -- Mencari informasi mutasi di akhir pesan (contoh: Mutation: Glistening)
    local mutationMatch = msg:match("Mutation:%s*(%a+)")
    if mutationMatch then
        data.Mutation = mutationMatch
    end
    
    return data
end

-- Fungsi Pengirim Discord (Embed Rapi)
local function SendToDiscord(msg, rarity, colorDec, source, fishData) -- <--- TAMBAH fishData
    if _G_WebhookURL == "" or not _G_WebhookURL:find("http") then return end

    -- Deteksi Executor (Synapse, Krnl, Fluxus, dll)
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local player = game.Players.LocalPlayer
    local playerName = player.Name
    local playerDisplay = player.DisplayName
    
    -- LOGIKA UNTUK GAMBAR IKAN (THUMBNAIL)
    local fishImageURL = nil
    if rarity == "Secret" or rarity == "Custom Target" then
        -- GANTI URL INI DENGAN URL GAMBAR IKAN SECRET/CUSTOM YANG ANDA INGINKAN
        -- URL ini hanya akan digunakan jika rarity-nya Secret atau Custom Target
        fishImageURL = "https://i.imgur.com/eQJtOqB.png" -- Contoh Placeholder
    end

    local embedData = {
        ["username"] = "**Secret Notification**", -- <--- Diubah menjadi BOLD
        ["avatar_url"] = "https://share.google/images/qvmsQaZadX4enqVzr",
        ["embeds"] = {{
            ["title"] = "🎣 **" .. rarity .. "** Catch Detected!", -- <--- Diubah menjadi BOLD
            ["description"] = "**Original Message:** " .. msg, -- Pesan mentah tetap di sini sebagai cadangan
            ["color"] = colorDec,
            
            -- PENAMBAHAN THUMBNAIL (GAMBAR IKAN)
            ["thumbnail"] = fishImageURL and { ["url"] = fishImageURL } or nil, -- Menambahkan gambar jika ada
            
            -- PERUBAHAN SUSUNAN FIELDS
            ["fields"] = {
                {
                    ["name"] = "👤 Name",
                    ["value"] = "**"..fishData.PlayerName.."**", 
                    ["inline"] = true
                },
                {
                    ["name"] = "🐠 Fish",
                    ["value"] = "**"..fishData.FishName.."**", 
                    ["inline"] = true
                },
                {
                    ["name"] = "⚖️ Weight",
                    ["value"] = "**"..fishData.Weight.."**", 
                    ["inline"] = true
                },
                {
                    ["name"] = "🧬 Mutation",
                    ["value"] = "**"..fishData.Mutation.."**", 
                    ["inline"] = true
                },
                {
                    ["name"] = "📍 Source Log",
                    ["value"] = source,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Frayhub • " .. os.date("%X") .. " • " .. os.date("%d/%m/%Y")
            }
        }}
    }

    httpRequest({
        Url = _G_WebhookURL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = game:GetService("HttpService"):JSONEncode(embedData)
    })
end

-- [[ LOAD UI ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "✨ Frayhub ✨",
    Icon = 0,
    LoadingTitle = "FrayHub | Main Version 1.0",
    LoadingSubtitle = "by Frayphale",
    ShowText = "Frayhub",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FileName = "Frayhub_Config"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Frayhub Key",
        Subtitle = "Link In Discord Server",
        Note = "Join Server From Misc Tab",
        FileName = "Frayhubkey",
        SaveKey = true,
        GrabKeyFromSite = true,
        Key = {"https://pastebin.com/raw/DttgzM1m"}
    }
})

-- Variabel Global
local _G_InfJumpConnection = nil
local _G_NoclipConnection = nil
local _G_SelectedPlayerToTP = nil    
local _G_SelectedAreaToTP = "Lost Isle"
local _G_AutoUpdateStats = false    
local _G_UISpy = false    
local _G_LastPlayerPositions = {}    
local _G_FishingTracker = {}    
local _G_SortMethod = "Name"    
local _G_FavoriteFilterList = {}    

-- Variabel Log System
local _G_ChatScan = false
local _G_ChatConnections = {}
local _G_LogHistory = {}
local _G_RarityFilters = {}    
local LogParagraph = nil    
-- [BARU] Variabel Custom List
local _G_CustomFishList = {}    
local CustomFishDisplayParagraph = nil

-- UI Variables
local InfoParagraph = nil    

-- DATABASE ZONA
local IslandZones = {
    {Name = "Fisherman Island", Pos = Vector3.new(79, 17, 2848),       Radius = 305},
    {Name = "Esoteric Depths",  Pos = Vector3.new(3226, -1302, 1407), Radius = 305},
    {Name = "Sacred Temple",    Pos = Vector3.new(1475, -21, -631),    Radius = 305},
    {Name = "Ancient Jungle",   Pos = Vector3.new(1489, 7, -430),       Radius = 477.5}    
}

-- UTILITIES (LAINNYA)
local function FormatShortNum(n)
    local num = tonumber(n) or 0
    if num >= 1000000000 then return string.format("%.2fB", num/1e9):gsub("%.00","")
    elseif num >= 1000000 then return string.format("%.2fM", num/1e6):gsub("%.00","")
    elseif num >= 1000 then return string.format("%.1fk", num/1e3):gsub("%.0","")
    else return tostring(num) end
end

local function FormatFixed(str, length)
    local s = tostring(str)
    if #s > length then return string.sub(s, 1, length - 2) .. ".."
    else return s .. string.rep(" ", length - #s) end
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
    local rawVal = 0
    local displayStr = "1/0"
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
    local caught = GetCaughtAmount(plr)
    return caught, "1/" .. FormatShortNum(caught)
end

local function GetPlayerNamesForList()
    local names = {}
    for _, v in pairs(game.Players:GetPlayers()) do table.insert(names, v.Name) end
    table.sort(names)
    return names
end

--[[ ==========================================
                TAB: HOME
========================================== ]]--
local MainTab = Window:CreateTab("🏠 Home", nil)
local MainSection = MainTab:CreateSection("Character Movement")

MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {16, 300}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "WalkspeedSlider",
    Callback = function(Value)
       if game.Players.LocalPlayer.Character then game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value end
    end,
})

MainTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",    
    Callback = function(Value)
       if Value then
           _G_InfJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
               game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
           end)
       else
           if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() _G_InfJumpConnection = nil end
       end
    end,
})

MainTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "Noclip",    
    Callback = function(Value)
       if Value then
           _G_NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
               if game.Players.LocalPlayer.Character then
                   for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                       if v:IsA("BasePart") then v.CanCollide = false end
                   end
               end
           end)
       else
           if _G_NoclipConnection then _G_NoclipConnection:Disconnect() _G_NoclipConnection = nil end
       end
    end,
})

--[[ ==========================================
                TAB: DATA
========================================== ]]--
local DataTab = Window:CreateTab("📊 Data", nil)

-- FILTER & LIST
local DataSection = DataTab:CreateSection("Live Player Tracker & Filter")

DataTab:CreateDropdown({
    Name = "Sort By", Options = {"Name", "Location", "Rarest Fish"}, CurrentOption = {"Name"}, MultipleOptions = false, Flag = "SortDropdown",    
    Callback = function(Options) _G_SortMethod = Options[1] end,
})

local FavoriteDropdown = DataTab:CreateDropdown({
    Name = "⭐ Filter / Favorite Players",
    Options = GetPlayerNamesForList(),
    CurrentOption = {},    
    MultipleOptions = true,
    Flag = "FavoritePlayerFilter",
    Callback = function(Options)
        _G_FavoriteFilterList = Options
    end,
})

DataTab:CreateButton({
    Name = "🔄 Refresh Player List (In Dropdown)",
    Callback = function()
        FavoriteDropdown:Refresh(GetPlayerNamesForList(), true)
        Rayfield:Notify({Title = "Refreshed", Content = "Dropdown updated.", Duration = 1})
    end,
})

-- STATS DISPLAY
local StatsParagraph = DataTab:CreateParagraph({Title = "( Loading... )", Content = "Activate Auto Update to see list..."})

local function UpdatePlayerData()
    local tempStats = {}    
    local players = game.Players:GetPlayers()
    local playerCount = #players
    local statusIcon = playerCount >= 20 and "🔴" or "🟢"    
    
    if InfoParagraph then
        InfoParagraph:Set({Title = "Status", Content = "Active: " .. playerCount .. "/" .. game.Players.MaxPlayers})
    end
    
    local currentTime = tick()

    for _, player in pairs(players) do
        local isShown = true
        if #_G_FavoriteFilterList > 0 then
            isShown = false
            for _, favName in pairs(_G_FavoriteFilterList) do
                if favName == player.Name then isShown = true break end
            end
        end

        if isShown then
            local rawPlace = "Loading..."
            local rawRarestValue = 0
            local rawStatStr, rawFishStatus, rawMoveStatus = "-", "Check", "Wait"
            local fishIcon, moveIcon = "🟢", "🔴"
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local currentPos = player.Character.HumanoidRootPart.Position
                local closestZoneName, closestDist = "Open Ocean", math.huge
                for _, zone in pairs(IslandZones) do
                    local dist = (currentPos - zone.Pos).Magnitude
                    if dist <= zone.Radius and dist < closestDist then closestDist = dist; closestZoneName = zone.Name end
                end
                rawPlace = closestZoneName

                local lastPos = _G_LastPlayerPositions[player.Name]
                if lastPos then
                    if (currentPos - lastPos).Magnitude > 0.2 then rawMoveStatus = "Mov"; moveIcon = "🟢"
                    else rawMoveStatus = "Idle"; moveIcon = "🟡" end
                else rawMoveStatus = "Idle"; moveIcon = "🟡" end
                _G_LastPlayerPositions[player.Name] = currentPos    
                
                local currentCaught = GetCaughtAmount(player)
                rawRarestValue, rawStatStr = GetDisplayStatData(player)
                
                local tracker = _G_FishingTracker[player.Name]
                if not tracker then
                    _G_FishingTracker[player.Name] = {LastCount = currentCaught, LastChangeTime = currentTime}
                    rawFishStatus = "Fish"; fishIcon = "🟢"
                else
                    if currentCaught > tracker.LastCount then
                        tracker.LastCount = currentCaught; tracker.LastChangeTime = currentTime
                        rawFishStatus = "Fish"; fishIcon = "🟢"
                    else
                        if (currentTime - tracker.LastChangeTime) > 30 then rawFishStatus = "AFK"; fishIcon = "🔴"
                        else rawFishStatus = "Fish"; fishIcon = "🟢" end
                    end
                end
                
                local displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>',    
                    "<b>"..FormatFixed(" "..player.Name.." ",15).."</b>", FormatFixed(rawPlace,16),    
                    FormatFixed(" "..rawStatStr.." ",9), FormatIconRight(rawFishStatus,fishIcon,7), FormatIconRight(rawMoveStatus,moveIcon,7))
                table.insert(tempStats, {Name=player.Name, Place=rawPlace, Rarest=rawRarestValue, Display=displayString})
            else
                local displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>',    
                    "<b>"..FormatFixed(" "..player.Name.." ",15).."</b>", FormatFixed("Dead/Loading",16),    
                    FormatFixed(" - ",9), FormatIconRight("Wait","🔴",7), FormatIconRight("Wait","🔴",7))
                table.insert(tempStats, {Name=player.Name, Place="Dead/Loading", Rarest=-1, Display=displayString})
            end
        end
    end
    
    if _G_SortMethod == "Name" then table.sort(tempStats, function(a,b) return a.Name:lower() < b.Name:lower() end)
    elseif _G_SortMethod == "Location" then table.sort(tempStats, function(a,b) return a.Place < b.Place end)
    elseif _G_SortMethod == "Rarest Fish" then table.sort(tempStats, function(a,b) return a.Rarest > b.Rarest end) end
    
    local finalList = {}
    for _, data in ipairs(tempStats) do table.insert(finalList, data.Display) end
    StatsParagraph:Set({Title = "<b>Player List ("..playerCount.."/"..game.Players.MaxPlayers..")</b> "..statusIcon, Content = table.concat(finalList, "\n")})
end

local ToggleAutoUpdate = DataTab:CreateToggle({
    Name = "Auto Update Data (Every 1s)", CurrentValue = false, Flag = "AutoUpdateStats",    
    Callback = function(Value)
       _G_AutoUpdateStats = Value
       if Value then task.spawn(function() while _G_AutoUpdateStats do UpdatePlayerData() task.wait(1) end end) end
    end,
})

--[[ ==========================================
                TAB: LOG (WITH DISCORD & CLEANER)
========================================== ]]--
local LogTab = Window:CreateTab("📜 Log", nil)

LogTab:CreateSection("Chat Scanner")

LogTab:CreateDropdown({
    Name = "🎨 Log Rarity Filter (Check to Enable)",
    Options = {"Epic", "Legendary", "Mythic", "Secret"},    
    CurrentOption = {},    
    MultipleOptions = true,
    Flag = "LogRarityFilter",
    Callback = function(Options)
        _G_RarityFilters = Options
    end,
})

-- [BARU] Bagian Input Custom Fish
LogTab:CreateSection("Target Ikan Khusus (Custom)")

local function UpdateCustomListUI()
    local listContent = "None"
    if #_G_CustomFishList > 0 then
        listContent = table.concat(_G_CustomFishList, ", ")
    end
    if CustomFishDisplayParagraph then
        CustomFishDisplayParagraph:Set({Title = "Daftar Target Ikan:", Content = listContent})
    end
end

LogTab:CreateInput({
   Name = "Tambah Nama Ikan",
   PlaceholderText = "Contoh: Sunfish",
   RemoveTextAfterFocusLost = true,
   Callback = function(Text)
       if Text and Text ~= "" then
            table.insert(_G_CustomFishList, Text)
            UpdateCustomListUI()
            Rayfield:Notify({Title = "Target Ditambahkan", Content = Text .. " masuk ke daftar pantau.", Duration = 2})
       end
   end,
})

CustomFishDisplayParagraph = LogTab:CreateParagraph({Title = "Daftar Target Ikan:", Content = "None"})

LogTab:CreateButton({
    Name = "🗑️ Reset Daftar Target Ikan",
    Callback = function()
        _G_CustomFishList = {}
        UpdateCustomListUI()
        Rayfield:Notify({Title = "Reset", Content = "Daftar target dikosongkan.", Duration = 2})
    end,
})

-- [AKHIR BARU]

LogTab:CreateSection("Log Output")
LogParagraph = LogTab:CreateParagraph({Title = "Log Output", Content = "Waiting for data..."})

-- Helper Check Rarity
local function CheckRarity(msg)
    if string.find(msg, "Enchant Stone") or string.find(msg, "Astra Damsel") then
        return "Epic"
    end
    
    if string.find(msg, "Magic Tang") or string.find(msg, "Big Temple") or string.find(msg, "Megalodon") then
        return "Legendary"
    end

    if string.find(msg, "Mythic") or string.find(msg, "Abyssal") then    
        return "Mythic"
    end

    if string.find(msg, "Thin Armor") or string.find(msg, "Secret") then
        return "Secret"
    end

    return "Other"
end

-- Fungsi Update UI Log
local function UpdateLogDisplay()
    local content = table.concat(_G_LogHistory, "\n\n")
    LogParagraph:Set({Title = "Log Output (Last 15)", Content = content})
end

-- Fungsi Proses Pesan (DISCORD INTEGRATED & CLEANED)
local function ProcessMessage(msg, source)
    -- 1. BERSIHKAN TAG HTML (Rich Text) DULUAN!
    local cleanMsg = msg:gsub("<[^>]+>", "")
    
    -- 2. BERSIHKAN PREFIX DAN SPASI
    cleanMsg = cleanMsg:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", "")
    cleanMsg = cleanMsg:gsub("^%s+", "")
    
    -- TAMBAH: Mengurai data ikan
    local fishData = ParseFishData(cleanMsg) -- <--- PARSING DATA IKAN
    
    -- [BARU] 2.5 CEK APAKAH ADA DI CUSTOM LIST
    local isCustomTarget = false
    for _, targetName in pairs(_G_CustomFishList) do
        if string.find(cleanMsg:lower(), targetName:lower()) then
            isCustomTarget = true
            break
        end
    end

    -- 3. Tentukan Rarity
    local msgRarity = CheckRarity(cleanMsg)
    
    -- 4. LOGIKA FILTER
    local isAllowed = false

    if isCustomTarget then
        -- Jika ada di custom list, LANGSUNG lolos filter (Bypass)
        isAllowed = true
        msgRarity = "Custom Target" -- Override nama rarity agar terlihat beda
    else
        -- Jika tidak, gunakan logika rarity biasa
        if msgRarity == "Other" then return end
        for _, selectedRarity in pairs(_G_RarityFilters) do
            if selectedRarity == msgRarity then
                isAllowed = true
                break
            end
        end
    end
    
    if not isAllowed then return end    

    -- 5. Tampilkan Log di UI
    local timestamp = os.date("%X")
    local msgColor = "#FFFFFF"    
    local discordColor = 16777215    

    if msgRarity == "Epic" then
        discordColor = 10181046 -- Ungu
    elseif msgRarity == "Legendary" then
        discordColor = 15105570 -- Orange/Gold
    elseif msgRarity == "Mythic" then
        msgColor = "#FF0000"
        discordColor = 15158332 -- Merah
    elseif msgRarity == "Secret" then
        discordColor = 3066993 -- Cyan/Teal
    elseif msgRarity == "Custom Target" then
        msgColor = "#00BFFF" -- Biru Langit untuk Custom
        discordColor = 48340 -- Biru
    end

    local formattedLog = string.format('<font color="#F0C600">[%s]</font> <font color="#00FF00">[%s]:</font> <font color="%s">"%s"</font>', timestamp, source, msgColor, cleanMsg)
    
    table.insert(_G_LogHistory, 1, formattedLog)
    if #_G_LogHistory > 15 then table.remove(_G_LogHistory) end
    UpdateLogDisplay()

    -- 6. KIRIM KE DISCORD (Versi Bersih)
    pcall(function()
        SendToDiscord(cleanMsg, msgRarity, discordColor, source, fishData) -- <--- TAMBAH fishData
    end)
end

LogTab:CreateToggle({
    Name = "Auto Scan Chat (System & Player)",
    CurrentValue = false,
    Flag = "ChatScan",
    Callback = function(Value)
        _G_ChatScan = Value
        if Value then
            if game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService then
                local conn = game:GetService("TextChatService").MessageReceived:Connect(function(msgObj)
                    local text = msgObj.Text
                    local source = msgObj.PrefixText or "Unknown"
                    source = source:gsub("<[^>]+>", ""):gsub(":", "")
                    if source == "" or string.find(source, "Server") then source = "Server" end
                    if string.find(source, "System") then source = "System" end
                    ProcessMessage(text, source)
                end)
                table.insert(_G_ChatConnections, conn)
            else
                local ChatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if ChatEvents then
                    local OnMessage = ChatEvents:FindFirstChild("OnMessageDoneFiltering")
                    if OnMessage then
                        local conn = OnMessage.OnClientEvent:Connect(function(data)
                            local text = data.Message
                            local source = data.FromSpeaker or "System"
                            ProcessMessage(text, source)
                        end)
                        table.insert(_G_ChatConnections, conn)
                    end
                end
            end
            Rayfield:Notify({Title = "Scanner Started", Content = "Waiting for selected items...", Duration = 3})
        else
            for _, conn in pairs(_G_ChatConnections) do conn:Disconnect() end
            _G_ChatConnections = {}
            Rayfield:Notify({Title = "Scanner Stopped", Content = "Stopped listening.", Duration = 3})
        end
    end,
})

LogTab:CreateButton({
    Name = "🧹 Clear Logs",
    Callback = function()
        _G_LogHistory = {}
        UpdateLogDisplay()
        LogParagraph:Set({Title = "Log Output", Content = "Logs cleared."})
    end,
})

LogTab:CreateButton({
    Name = "📋 Copy Logs to Clipboard",
    Callback = function()
        local rawText = ""
        for _, log in ipairs(_G_LogHistory) do
            local cleanLog = log:gsub("<[^>]+>", "")
            rawText = rawText .. cleanLog .. "\n"
        end
        setclipboard(rawText)
        Rayfield:Notify({Title = "Copied!", Content = "Logs copied to clipboard.", Duration = 2})
    end,
})

--[[ ==========================================
                TAB: TELEPORT
========================================== ]]--
local TeleportTab = Window:CreateTab("📍 Teleport", nil)
TeleportTab:CreateSection("Target Player Teleport")
local PlayerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player", Options = GetPlayerNamesForList(), CurrentOption = {""}, MultipleOptions = false, Flag = "PlayerSelect",    
    Callback = function(Options) _G_SelectedPlayerToTP = Options[1] end,
})
TeleportTab:CreateButton({
    Name = "🔄 Refresh List", Callback = function() PlayerDropdown:Refresh(GetPlayerNamesForList(), true) end,
})
TeleportTab:CreateButton({
    Name = "🚀 Teleport to Selected Player",    
    Callback = function()
       if _G_SelectedPlayerToTP and game.Players:FindFirstChild(_G_SelectedPlayerToTP) then
           game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players[_G_SelectedPlayerToTP].Character.HumanoidRootPart.CFrame
           Rayfield:Notify({Title = "Success", Content = "Teleported!", Duration = 2})
       end
    end,
})

TeleportTab:CreateSection("Island Teleport")
TeleportTab:CreateDropdown({
    Name = "Select Area", Options = {"Lost Isle", "Ancient Jungle", "Esoteric Depths", "Sacred Temple", "Fisherman Island"}, CurrentOption = {"Lost Isle"}, MultipleOptions = false, Flag = "TeleportArea",    
    Callback = function(Options) _G_SelectedAreaToTP = Options[1] end,
})
TeleportTab:CreateButton({
    Name = "🚀 Teleport to Selected Area",
    Callback = function()
        for _, z in pairs(IslandZones) do if z.Name == _G_SelectedAreaToTP then game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(z.Pos) return end end
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-3735, -135, -1011)
    end,
})

--[[ ==========================================
                TAB: MISC
========================================== ]]--
local MiscTab = Window:CreateTab("⚙️ Misc", nil)

-- SECTION SERVER INFO
MiscTab:CreateSection("Server Info")
InfoParagraph = MiscTab:CreateParagraph({Title = "Status", Content = "Initializing..."})    

MiscTab:CreateButton({
    Name = "🔁 Rejoin Server",
    Callback = function()
       Rayfield:Notify({Title = "Rejoining...", Content = "Hop to same server instance.", Duration = 2})
       game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end,
})

-- SECTION UTILITY
MiscTab:CreateSection("Utility")
MiscTab:CreateToggle({Name = "Super Low Graphics", CurrentValue = false, Flag = "LowGraphics", Callback = function(V) game.Lighting.GlobalShadows = not V end})
MiscTab:CreateToggle({Name = "UI Spy (F9)", CurrentValue = false, Flag = "UISpy", Callback = function(V) _G.UISpy = V end})
MiscTab:CreateButton({
    Name = "🔴 Unload Script",    
    Callback = function()    
        _G_AutoUpdateStats=false    
        _G_UISpy=false    
        _G_ChatScan = false    
        for _, conn in pairs(_G_ChatConnections) do conn:Disconnect() end
        if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() end    
        if _G_NoclipConnection then _G_NoclipConnection:Disconnect() end    
    end
})

MiscTab:CreateToggle({
    Name = "🛡️ Anti-AFK (Bypass 20m Kick)",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            -- Jalankan Anti-AFK
            if not _G.AntiAFKConnection then
                _G.AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                    if _G.AntiAFK then
                        local virtualUser = game:GetService("VirtualUser")
                        virtualUser:CaptureController()
                        virtualUser:ClickButton2(Vector2.new()) -- Simulasi Klik Kanan
                        Rayfield:Notify({Title = "Anti-AFK", Content = "Kicking prevented!", Duration = 1})
                    end
                end)
            end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled! You can sleep now.", Duration = 2})
        else
            -- Matikan Anti-AFK
            if _G.AntiAFKConnection then
                _G.AntiAFKConnection:Disconnect()
                _G.AntiAFKConnection = nil
            end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled.", Duration = 2})
        end
    end,
})

Rayfield:Notify({Title = "Frayhub Loaded", Content = "All Systems Go!", Duration = 5, Image = nil})
