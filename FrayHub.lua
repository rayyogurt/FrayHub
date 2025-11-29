-- [[ 0. AUTO-KILL OLD SCRIPT (PENCEGAH DOUBLE & CRASH) ]] --
if _G.FrayhubConnections then
    for _, conn in pairs(_G.FrayhubConnections) do
        if conn then conn:Disconnect() end
    end
    _G.FrayhubConnections = {}
end
_G.FrayhubConnections = {}
_G.ScanSecretToggle = false -- Reset toggle state
_G.ChatScan = false -- Reset chat scan state

-- [[ 1. KONFIGURASI UTAMA ]] --
local _G_WebhookURL = "https://discord.com/api/webhooks/1442845013057863743/lJMKfMxHsoEw4UGnZ4mRed_JIK8mFNElRRqZ9imqSC-DdeWrYLIHufHpGf1KfNPpYtw4"

-- DATABASE IKAN SECRET (Case Insensitive nanti)
local _G_SecretFishList = {
    "Robot Kraken", "Giant Squid", "Panther Eel", "Cryoshade Glider",
    "King Crab", "Queen Crab", "Mosasaur Shark", "King Jelly",
    "Bone Whale", "Elshark Gran Maja", "Thin Armor Shark", "Scare",
    "Blob Shark", "Ghost Shark", "Megalodon", "Crystal Crab", "Orca",
    "Great Whale", "Lochness Monster", "Ghost Worm", "Frostborn Shark",
    "Monster Shark", "Erie Shark", "Worm Fish"
}

-- Custom List Default
local _G_CustomFishList = {
    "Sacred Guardian Squid"
}

-- [[ 2. UTILITIES: PARSING & DISCORD ]] --

-- Fungsi Parsing Data (Diperbaiki agar support spasi pada berat)
local function ParseFishData(msg)
    local data = {
        PlayerName = "Unknown",
        FishName = msg,
        Weight = "N/A",
        Mutation = "None"
    }
    
    -- [FIXED LOGIC] Menggunakan (.-) untuk menangkap berat agar support spasi "1.71K kg"
    -- Pola 1: Format English "Player obtained a [Fish] (Weight)..."
    local player, fullContent, weight = msg:match("^(.+) obtained an? (.+) %((.-)%)")
    
    -- Pola 2: Format Indonesia (Backup)
    if not player then
        player, fullContent, weight = msg:match("^(.+) menangkap (.+) %(%s*(.-)%)")
    end

    if player and fullContent then
        -- Bersihkan nama player dari tag [Server]/[System]
        player = player:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
        
        data.PlayerName = player
        data.Weight = weight or "N/A"
        
        -- LOGIKA DETEKSI NAMA IKAN & MUTASI
        local detectedFishName = nil
        
        -- Gabungkan list Secret dan Custom untuk pengecekan
        local allKnownFish = {}
        for _, v in pairs(_G_SecretFishList) do table.insert(allKnownFish, v) end
        for _, v in pairs(_G_CustomFishList) do table.insert(allKnownFish, v) end
        
        -- Cek apakah nama ikan ada di database kita
        for _, fish in pairs(allKnownFish) do
            if fullContent:lower():find(fish:lower(), 1, true) then
                detectedFishName = fish
                break
            end
        end
        
        if detectedFishName then
            data.FishName = detectedFishName
            
            -- Escape karakter spesial agar aman saat replace string
            local safeFishName = detectedFishName:lower():gsub("([%-%^%$%(%)%%%.%[%]%*%+%?])", "%%%1")
            
            -- Sisa string adalah Mutasi (setelah nama ikan dihapus)
            local mutationStr = fullContent:lower():gsub(safeFishName, "")
            mutationStr = mutationStr:gsub("^%s+", ""):gsub("%s+$", "") -- Trim spasi
            
            if mutationStr ~= "" and mutationStr ~= " " then
                -- Huruf besar awal kata (Capitalize)
                data.Mutation = mutationStr:sub(1,1):upper()..mutationStr:sub(2)
            else
                data.Mutation = "None"
            end
        else
            -- Jika ikan tidak dikenali di database, anggap semuanya nama ikan
            data.FishName = fullContent
            data.Mutation = "None"
        end
    end
    
    return data
end

-- Fungsi Kirim ke Discord (Rich Embed)
local function SendToDiscord(msg, rarity, colorDec, source, fishData)
    if _G_WebhookURL == "" or not _G_WebhookURL:find("http") then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local timestamp = os.date("%H:%M:%S • %d/%m/%Y")
    local fishImageURL = "https://i.imgur.com/WxwNoO6.jpeg"

    local embedData = {
        ["username"] = "FrayHub Notification",
        ["avatar_url"] = "https://i.pinimg.com/originals/1b/ce/fe/1bcefe9201469c9fbbd932e4c5ab971d.gif",
        ["embeds"] = {{
            ["title"] = "<a:RedCircle:759942169980567632> " .. rarity .. " Catch Detected!",
            ["color"] = colorDec,
            ["thumbnail"] = { ["url"] = fishImageURL },
            ["fields"] = {
                -- [FIXED] inline = false agar memanjang ke bawah rapi di PC & HP
                { ["name"] = "**<a:owner:1407568729998360616> Player**", ["value"] = fishData.PlayerName, ["inline"] = false },
                { ["name"] = "**<a:swimming:1444221538587906142> Fish**", ["value"] = fishData.FishName, ["inline"] = false },
                { ["name"] = "**<:Scales:1444224451616051322> Weight**", ["value"] = fishData.Weight, ["inline"] = false },
                { ["name"] = "**<a:PinkSparkles:1444225554269212833> Mutation**", ["value"] = fishData.Mutation, ["inline"] = false },
                { ["name"] = "**<a:clock_running:1444223436221059194> Time**", ["value"] = timestamp, ["inline"] = false }
            },
            ["footer"] = {
                ["text"] = "FrayHub | By Frayphale"
            }
        }}
    }

    httpRequest({
        Url = _G_WebhookURL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = game:GetService("HttpService"):JSONEncode(embedData)
    })
end

-- [[ 3. LOAD UI RAYFIELD ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "FrayHub | Main Version 1.2",
    Icon = 0,
    LoadingTitle = "FrayHub | Main Version 1.2",
    LoadingSubtitle = "by Frayphale",
    ShowText = "Frayhub",
    Theme = "Amethyst",
    ToggleUIKeybind = "G",
    ConfigurationSaving = {
       Enabled = true,
       FileName = "Frayhub_Config"
    },
    KeySystem = true,
    KeySettings = {
       Title = "FrayHub Key",
       Subtitle = "Link In Discord Server",
       Note = "Community and Marketplace Server",
       FileName = "Frayhubkey",
       SaveKey = true,
       GrabKeyFromSite = true,
       Key = {"https://pastebin.com/raw/DttgzM1m"}
    }
})

-- Variabel Global Runtime
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
local _G_LogHistory = {}

-- UI Elements Placeholder
local LogParagraph = nil
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
           table.insert(_G.FrayhubConnections, _G_InfJumpConnection)
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
           table.insert(_G.FrayhubConnections, _G_NoclipConnection)
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
                TAB: LOG
========================================== ]]--
local LogTab = Window:CreateTab("📜 Log", nil)

LogTab:CreateSection("Chat Scanner & Filter")

LogTab:CreateToggle({
    Name = "✨ Only Scan Secret / Custom Target",
    CurrentValue = false,
    Flag = "ScanSecretToggle",
    Callback = function(Value)
        _G_ScanSecretToggle = Value
        if Value then
            Rayfield:Notify({Title = "Filter Active", Content = "Sekarang HANYA mendeteksi Secret & Target.", Duration = 2})
        else
            Rayfield:Notify({Title = "Filter Off", Content = "Mendeteksi semua rarity.", Duration = 2})
        end
    end,
})

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
   PlaceholderText = "Contoh: Manoai Statue Fish",
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
UpdateCustomListUI() -- Init display

LogTab:CreateButton({
    Name = "🗑️ Reset Daftar Target Ikan",
    Callback = function()
        _G_CustomFishList = {}
        UpdateCustomListUI()
        Rayfield:Notify({Title = "Reset", Content = "Daftar target dikosongkan.", Duration = 2})
    end,
})

LogTab:CreateSection("Log Output")
LogParagraph = LogTab:CreateParagraph({Title = "Log Output", Content = "Waiting for data..."})

-- Helper Check Rarity
local function CheckRarity(msg)
    local msgLower = msg:lower()

    if string.find(msg, "Enchant Stone") or string.find(msg, "Astra Damsel") then return "Epic" end
    if string.find(msg, "Magic Tang") or string.find(msg, "Big Temple") or string.find(msg, "Megalodon") then return "Legendary" end
    if string.find(msg, "Mythic") or string.find(msg, "Abyssal") then return "Mythic" end

    -- Cek Database Secret Fish
    for _, secretName in ipairs(_G_SecretFishList) do
        if string.find(msgLower, secretName:lower()) then
            return "Secret"
        end
    end

    return "Other"
end

-- Fungsi Update UI Log
local function UpdateLogDisplay()
    local content = table.concat(_G_LogHistory, "\n\n")
    LogParagraph:Set({Title = "Log Output (Last 15)", Content = content})
end

-- Fungsi Proses Pesan
local function ProcessMessage(msg, source)
    -- 1. Bersihkan Pesan HTML & Tag
    local cleanMsg = msg:gsub("<[^>]+>", "")
    cleanMsg = cleanMsg:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", "")
    cleanMsg = cleanMsg:gsub("^%s+", "")
   
    -- 2. Parsing Data (Menggunakan Logic ParseFishData yang baru)
    local fishData = ParseFishData(cleanMsg)
   
    -- 3. Cek apakah ini Custom Target?
    local isCustomTarget = false
    -- Cek via nama ikan yang sudah diparse (lebih akurat)
    if fishData.FishName ~= cleanMsg then
         for _, targetName in pairs(_G_CustomFishList) do
            if fishData.FishName:lower():find(targetName:lower()) then
                isCustomTarget = true
                break
            end
        end
    end
    -- Cek fallback ke pesan mentah
    if not isCustomTarget then
         for _, targetName in pairs(_G_CustomFishList) do
            if cleanMsg:lower():find(targetName:lower()) then
                isCustomTarget = true
                break
            end
        end
    end

    -- 4. Tentukan Rarity
    local msgRarity = CheckRarity(cleanMsg)
   
    -- 5. LOGIKA FILTER (Apakah pesan ini boleh lewat?)
    local isAllowed = false

    if isCustomTarget then
        isAllowed = true
        msgRarity = "Custom Target"
    elseif _G_ScanSecretToggle then
        -- Jika mode "Hanya Secret" aktif, hanya loloskan Secret
        if msgRarity == "Secret" then isAllowed = true end
    else
        -- Jika mode normal, loloskan apa saja asal bukan "Other" (spam biasa)
        if msgRarity ~= "Other" then isAllowed = true end
    end
   
    if not isAllowed then return end

    -- 6. Tentukan Warna
    local timestamp = os.date("%X")
    local msgColor = "#FFFFFF"
    local discordColor = 16777215

    if msgRarity == "Epic" then discordColor = 10181046
    elseif msgRarity == "Legendary" then discordColor = 15105570
    elseif msgRarity == "Mythic" then msgColor = "#FF0000"; discordColor = 15158332
    elseif msgRarity == "Secret" then discordColor = 3066993; msgColor = "#00FFFF"
    elseif msgRarity == "Custom Target" then msgColor = "#00BFFF"; discordColor = 48340 end

    -- 7. Log ke UI
    local formattedLog = string.format('<font color="#F0C600">[%s]</font> <font color="#00FF00">[%s]:</font> <font color="%s">"%s"</font>', timestamp, source, msgColor, cleanMsg)
    table.insert(_G_LogHistory, 1, formattedLog)
    if #_G_LogHistory > 15 then table.remove(_G_LogHistory) end
    UpdateLogDisplay()

    -- 8. Kirim ke Discord
    pcall(function()
        SendToDiscord(cleanMsg, msgRarity, discordColor, source, fishData)
    end)
end

LogTab:CreateToggle({
    Name = "Auto Scan Chat (System & Player)",
    CurrentValue = false,
    Flag = "ChatScan",
    Callback = function(Value)
        _G_ChatScan = Value
        if Value then
            -- Support TextChatService (Roblox Baru)
            if game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService then
                local conn = game:GetService("TextChatService").MessageReceived:Connect(function(msgObj)
                    local source = msgObj.PrefixText or "Unknown"
                    source = source:gsub("<[^>]+>", ""):gsub(":", "")
                    if source == "" or string.find(source, "Server") then source = "Server" end
                    if string.find(source, "System") then source = "System" end
                    ProcessMessage(msgObj.Text, source)
                end)
                table.insert(_G.FrayhubConnections, conn)
            else
                -- Support Legacy Chat (Roblox Lama)
                local ChatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if ChatEvents then
                    local OnMessage = ChatEvents:FindFirstChild("OnMessageDoneFiltering")
                    if OnMessage then
                        local conn = OnMessage.OnClientEvent:Connect(function(data)
                            local source = data.FromSpeaker or "System"
                            ProcessMessage(data.Message, source)
                        end)
                        table.insert(_G.FrayhubConnections, conn)
                    end
                end
            end
            Rayfield:Notify({Title = "Scanner Started", Content = "Waiting for catches...", Duration = 3})
        else
            -- Matikan Koneksi Chat
            if _G.FrayhubConnections then
                -- Note: Kita tidak bisa matikan spesifik satu koneksi dengan mudah di struktur ini
                -- Jadi user harus matikan script (Unload) atau biarkan berjalan
                -- Tapi logic di dalam process message akan berhenti karena _G_ChatScan false
            end
            Rayfield:Notify({Title = "Scanner Paused", Content = "Stop listening to new messages.", Duration = 3})
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
        if _G.FrayhubConnections then
            for _, conn in pairs(_G.FrayhubConnections) do
                if conn then conn:Disconnect() end
            end
            _G.FrayhubConnections = {}
        end
        if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() end
        if _G_NoclipConnection then _G_NoclipConnection:Disconnect() end
        Rayfield:Destroy()
    end
})

MiscTab:CreateToggle({
    Name = "🛡️ Anti-AFK (Bypass 20m Kick)",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            if not _G.AntiAFKConnection then
                _G.AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                    if _G.AntiAFK then
                        local virtualUser = game:GetService("VirtualUser")
                        virtualUser:CaptureController()
                        virtualUser:ClickButton2(Vector2.new())
                        Rayfield:Notify({Title = "Anti-AFK", Content = "Kicking prevented!", Duration = 1})
                    end
                end)
            end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Enabled! You can sleep now.", Duration = 2})
        else
            if _G.AntiAFKConnection then
                _G.AntiAFKConnection:Disconnect()
                _G.AntiAFKConnection = nil
            end
            Rayfield:Notify({Title = "Anti-AFK", Content = "Disabled.", Duration = 2})
        end
    end,
})

Rayfield:Notify({Title = "Frayhub Loaded", Content = "All Systems Go!", Duration = 5, Image = nil})




