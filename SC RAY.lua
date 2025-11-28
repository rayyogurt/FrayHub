-- [[ INJEKSI RAYFIELD & WINDOW UTAMA ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "💫 Frayhub 💫",
    Icon = 0,
    LoadingTitle = "Frayhub Initializing...",
    LoadingSubtitle = "Loading core features...",
    ShowText = "Frayhub",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FileName = "Frayhub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
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

-- [[ KONFIGURASI DISCORD & DATABASE SECRET FISH ]] --

local _G_WebhookURL = "https://discord.com/api/webhooks/1442845013057863743/lJMKfMxHsoEw4UGnZ4mRed_JIK8mFNElRRqZ9imqSC-DdeWrYLIHufHpGf1KfNPpYtw4"

local _G_SecretFishList = {
    -- Sisyphus Statue - Lost Isle
    "Robot Kraken",
    "Giant Squid",
    "Panther Eel",
    "Cryoshade Glider",
    -- Treasure Room - Lost Isle
    "King Crab",
    "Queen Crab",
    -- Ancient Jungle
    "Mosasaur Shark",
    "King Jelly",
    -- Sacred Temple
    "Bone Whale",
    "Elshark Gran Maja",
    -- Esoteric Depths
    "Thin Armor Shark",
    "Scare",
    -- Ocean
    "Blob Shark",
    "Ghost Shark",
    "Megalodon", 
    -- Fisherman Island
    "Crystal Crab",
    "Orca",
    -- Tropical Grave
    "Great Whale"
}

-- DATABASE ZONA TELEPORT & DATA TRACKER
local IslandZones = {
    {Name = "Fisherman Island", Pos = Vector3.new(79, 17, 2848),     Radius = 305},
    {Name = "Esoteric Depths",  Pos = Vector3.new(3226, -1302, 1407), Radius = 305},
    {Name = "Sacred Temple",    Pos = Vector3.new(1475, -21, -631),    Radius = 305},
    {Name = "Ancient Jungle",   Pos = Vector3.new(1489, 7, -430),      Radius = 477.5} 
}

-- VARIABEL GLOBAL (Diperbarui untuk fitur Discord/Log)
local _G_InfJumpConnection = nil
local _G_NoclipConnection = nil
local _G_SelectedPlayerToTP = nil 
local _G_SelectedAreaToTP = "Lost Isle"
local _G_AutoUpdateStats = false 
local _G_UISpy = false 
local _G_LastPlayerPositions = {} 
local _G_FishingTracker = {} 
local _G_SortMethod = "Name" -- (Tidak digunakan, tapi dipertahankan)
local _G_FavoriteFilterList = {} -- (Tidak digunakan, tapi dipertahankan)
local _G_ChatScan = false
local _G_ChatConnections = {}
local _G_LogHistory = {}
local _G_ScanSecretToggle = false 
local LogParagraph = nil    -- Variabel Log Chat UI
local _G_CustomFishList = {}    
local CustomFishDisplayParagraph = nil
local InfoParagraph = nil    -- Variabel Server Info UI


--------------------------------------------------------------------------------

-- [[ UTILITIES FUNCTION (Data Tracking & Formatting) ]] 

-- FUNGSI FORMAT ANGKA
local function FormatShortNum(n)
    local num = tonumber(n) or 0
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000):gsub("%.00", "")
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000):gsub("%.00", "")
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000):gsub("%.0", "")
    else
        return tostring(num)
    end
end

-- FUNGSI FORMAT RATA KIRI + POTONG
local function FormatFixed(str, length)
    local s = tostring(str)
    local strLen = string.len(s)
    if strLen > length then
        return string.sub(s, 1, length - 2) .. ".."
    else
        return s .. string.rep(" ", length - strLen)
    end
end

-- FUNGSI FORMAT ICON RATA KANAN
local function FormatIconRight(text, icon, length)
    local s = tostring(text)
    local maxTextLen = length - 1 
    if string.len(s) > maxTextLen then
        s = string.sub(s, 1, maxTextLen)
    end
    local spaceCount = length - string.len(s) - 1 
    if spaceCount < 0 then spaceCount = 0 end
    return s .. string.rep(" ", spaceCount) .. icon
end

-- Helper: Parse string singkatan
local function ParseAbbr(str)
    str = str:lower():gsub(",", "") 
    local val = tonumber(str:match("[%d.]+")) or 0
    
    if str:find("k") then val = val * 1000 end
    if str:find("m") then val = val * 1000000 end
    if str:find("b") then val = val * 1000000000 end
    
    return val
end

-- FUNGSI AMBIL CAUGHT
local function GetCaughtAmount(plr)
    if plr:FindFirstChild("leaderstats") then
        local s = plr.leaderstats:FindFirstChild("Caught") or plr.leaderstats:FindFirstChild("Fish") or plr.leaderstats:FindFirstChild("C") or plr.leaderstats:FindFirstChild("Streaks")
        if s then return tonumber(s.Value) or 0 end
    end
    return 0
end

-- FUNGSI AMBIL RAREST STAT
local function GetDisplayStat(plr)
    if plr:FindFirstChild("leaderstats") then
        local rare = plr.leaderstats:FindFirstChild("Rarest Fish")  
                     or plr.leaderstats:FindFirstChild("Rarest") 
                     or plr.leaderstats:FindFirstChild("Best") 
                     or plr.leaderstats:FindFirstChild("Record") 
                     or plr.leaderstats:FindFirstChild("Biggest")
        
        if rare then
            local rawVal = tostring(rare.Value)
            local maxVal = 0
            local found = false

            for s in rawVal:gmatch("[%d.,]+[kKmMbB]?") do
                local val = ParseAbbr(s)
                if val > 0 then
                    found = true
                    if val > maxVal then maxVal = val end
                end
            end
            
            if found then
                return "1/" .. FormatShortNum(maxVal)
            end
        end
    end
    
    local caught = GetCaughtAmount(plr)
    return "1/" .. FormatShortNum(caught)
end

--------------------------------------------------------------------------------

-- [[ UTILITIES FUNCTION (Discord & Log) ]]

-- Fungsi untuk mengurai data ikan dari pesan
local function ParseFishData(msg)
    local data = {
        FishName = "Unknown Fish",
        Weight = "N/A",
        Mutation = "None",
        PlayerName = "N/A"
    }
    
    -- Pola 1: Mencari format umum "Player menangkap Fish (Weight)"
    local playerMatch, fishMatch, weightMatch = msg:match("(.+) menangkap (.+) %(%s*([%d%.%s]+[kKmMBB]?)%)")
    
    if playerMatch and fishMatch and weightMatch then
        playerMatch = playerMatch:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
        data.PlayerName = playerMatch
        data.FishName = fishMatch
        data.Weight = weightMatch
    else
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

-- Helper Check Rarity (DIUBAH UNTUK PRIORITAS SECRET)
local function CheckRarity(msg)
    local msgLower = msg:lower()
    
    -- 1. CEK SEMUA IKAN SECRET DAHULU
    for _, secretName in ipairs(_G_SecretFishList) do
        if string.find(msgLower, secretName:lower()) then
            return "Secret"
        end
    end
    
    -- 2. Cek Rarity Bawaan (Epic, Legendary, Mythic)
    if string.find(msg, "Enchant Stone") or string.find(msg, "Astra Damsel") then
        return "Epic"
    end
    
    -- Cek Legendary (setelah Megalodon aman di Secret)
    if string.find(msg, "Magic Tang") or string.find(msg, "Big Temple") then 
        return "Legendary"
    end

    if string.find(msg, "Mythic") or string.find(msg, "Abyssal") then    
        return "Mythic"
    end

    return "Other"
end

-- Fungsi Pengirim Discord (Embed Rapi)
local function SendToDiscord(msg, rarity, colorDec, source, fishData)
    if _G_WebhookURL == "" or not _G_WebhookURL:find("http") then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local fishImageURL = nil
    if rarity == "Secret" or rarity == "Custom Target" then
        fishImageURL = "https://i.imgur.com/eQJtOqB.png" -- Placeholder
    end

    local embedData = {
        ["username"] = "**Secret Notification**",
        ["avatar_url"] = "https://share.google/images/qvmsQaZadX4enqVzr",
        ["embeds"] = {{
            ["title"] = "🎣 **" .. rarity .. "** Catch Detected!",
            ["description"] = "**Original Message:** " .. msg, 
            ["color"] = colorDec,
            ["thumbnail"] = fishImageURL and { ["url"] = fishImageURL } or nil,
            ["fields"] = {
                { ["name"] = "👤 Name", ["value"] = "**"..fishData.PlayerName.."**", ["inline"] = true },
                { ["name"] = "🐠 Fish", ["value"] = "**"..fishData.FishName.."**", ["inline"] = true },
                { ["name"] = "⚖️ Weight", ["value"] = "**"..fishData.Weight.."**", ["inline"] = true },
                { ["name"] = "🧬 Mutation", ["value"] = "**"..fishData.Mutation.."**", ["inline"] = true },
                { ["name"] = "📍 Source Log", ["value"] = source, ["inline"] = true }
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

-- Fungsi Update UI Log
local function UpdateLogDisplay()
    local content = table.concat(_G_LogHistory, "\n\n")
    if LogParagraph then
        LogParagraph:Set({Title = "Log Output (Last 15)", Content = content})
    end
end

-- Fungsi Proses Pesan
local function ProcessMessage(msg, source)
    local cleanMsg = msg:gsub("<[^>]+>", "")
    cleanMsg = cleanMsg:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", ""):gsub("^%s+", "")
    
    local fishData = ParseFishData(cleanMsg)    
    local msgRarity = CheckRarity(cleanMsg)
    
    local isCustomTarget = false
    for _, targetName in pairs(_G_CustomFishList) do
        if string.find(cleanMsg:lower(), targetName:lower()) then
            isCustomTarget = true
            break
        end
    end

    -- LOGIKA FILTER UTAMA
    local isAllowed = false

    if isCustomTarget then
        isAllowed = true
        msgRarity = "Custom Target"    
    elseif _G_ScanSecretToggle and msgRarity == "Secret" then
        isAllowed = true
    else
        return -- Tidak lolos filter
    end
    
    if not isAllowed then return end    

    -- Pengaturan Warna
    local timestamp = os.date("%X")
    local msgColor = "#FFFFFF"    
    local discordColor = 16777215    

    if msgRarity == "Epic" then
        discordColor = 10181046 
    elseif msgRarity == "Legendary" then
        discordColor = 15105570 
    elseif msgRarity == "Mythic" then
        msgColor = "#FF0000"
        discordColor = 15158332 
    elseif msgRarity == "Secret" then
        discordColor = 3066993 -- Cyan/Teal
        msgColor = "#00FFFF"
    elseif msgRarity == "Custom Target" then
        msgColor = "#00BFFF" 
        discordColor = 48340 
    end

    -- Update Log UI
    local formattedLog = string.format('<font color="#F0C600">[%s]</font> <font color="#00FF00">[%s]:</font> <font color="%s">"%s"</font>', timestamp, source, msgColor, cleanMsg)
    table.insert(_G_LogHistory, 1, formattedLog)
    if #_G_LogHistory > 15 then table.remove(_G_LogHistory) end
    UpdateLogDisplay()

    -- KIRIM KE DISCORD
    pcall(function()
        SendToDiscord(cleanMsg, msgRarity, discordColor, source, fishData) 
    end)
end

--------------------------------------------------------------------------------

-- [[ TAB: HOME (MOVEMENT) ]]
local MainTab = Window:CreateTab("🏠 Home", nil)
local MainSection = MainTab:CreateSection("Character Movement")

local Slider = MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkspeedSlider",
    Callback = function(Value)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

local ToggleInfJump = MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump", 
    Callback = function(Value)
        if Value then
            _G_InfJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                if game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                end
            end)
        else
            if _G_InfJumpConnection then
                _G_InfJumpConnection:Disconnect()
                _G_InfJumpConnection = nil
            end
        end
    end,
})

local ToggleNoclip = MainTab:CreateToggle({
    Name = "Noclip (Walk Through Walls)",
    CurrentValue = false,
    Flag = "Noclip", 
    Callback = function(Value)
        if Value then
            _G_NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
                if game.Players.LocalPlayer.Character then
                    for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        else
            if _G_NoclipConnection then 
                _G_NoclipConnection:Disconnect()
                _G_NoclipConnection = nil
            end
            -- Re-enable collision on self (best effort)
            if game.Players.LocalPlayer.Character then
                 for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then -- Jangan ubah RootPart
                            v.CanCollide = true
                        end
                    end
            end
        end
    end,
})

---
-- [[ TAB: DATA (LIVE PLAYER TRACKER) ]]
---
local DataTab = Window:CreateTab("📊 Data", nil)

-- BAGIAN 1: SERVER INFO
local ServerInfoSection = DataTab:CreateSection("Server Info")
InfoParagraph = DataTab:CreateParagraph({Title = "Status", Content = "Initializing..."})

local ButtonRejoin = DataTab:CreateButton({
    Name = "🔁 Rejoin Server",
    Callback = function()
        Rayfield:Notify({Title = "Rejoining...", Content = "Hop to same server instance.", Duration = 2})
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

-- BAGIAN 2: LIVE TRACKER
local DataSection = DataTab:CreateSection("Live Player Tracker")
local StatsParagraph = DataTab:CreateParagraph({Title = "( Loading... )", Content = "Activate Auto Update to see list..."})

local function UpdatePlayerData()
    local playerList = {}
    local players = game.Players:GetPlayers()
    local playerCount = #players
    local maxPlayers = game.Players.MaxPlayers
    
    local statusIcon = "🟢"
    if playerCount >= (maxPlayers - 2) then statusIcon = "🔴" end 
    
    InfoParagraph:Set({
        Title = "Stats", 
        Content = "Active: " .. playerCount .. "/" .. maxPlayers
    })
    
    local currentTime = tick()

    -- Judul Tabel (diperbaiki agar sama dengan lebar konten)
    local titleHeader = string.format('<font face="Code"><b>|%s|%s|%s|%s|%s|</b></font>', 
        FormatFixed(" Name ", 15), 
        FormatFixed(" Location ", 16), 
        FormatFixed(" Rarest ", 9), 
        FormatFixed(" Fish ", 7), 
        FormatFixed(" Move ", 7))
    table.insert(playerList, titleHeader)

    for _, player in pairs(players) do
        local displayString = ""
        
        -- Default Values
        local rawPlace = "Loading..."
        local rawStat = "-"
        local rawFishStatus = "Check"
        local rawMoveStatus = "Wait"
        local fishIcon = "🟢"
        local moveIcon = "🔴"
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = player.Character.HumanoidRootPart.Position
            
            -- 1. DETEKSI LOKASI
            local closestZoneName = "Open Ocean"
            local closestDist = math.huge
            for _, zone in pairs(IslandZones) do
                local dist = (currentPos - zone.Pos).Magnitude
                if dist <= zone.Radius and dist < closestDist then
                    closestDist = dist
                    closestZoneName = zone.Name
                end
            end
            rawPlace = closestZoneName

            -- 2. DETEKSI GERAKAN
            local lastPos = _G_LastPlayerPositions[player.Name]
            if lastPos then
                local delta = (currentPos - lastPos).Magnitude
                if delta > 0.2 then 
                    rawMoveStatus = "Mov"
                    moveIcon = "🟢"
                else
                    rawMoveStatus = "Idle"
                    moveIcon = "🔴"
                end
            else
                 rawMoveStatus = "Idle"
                 moveIcon = "🔴"
            end
            _G_LastPlayerPositions[player.Name] = currentPos 
            
            -- 3. LOGIKA FISHING TRACKER
            local currentCaught = GetCaughtAmount(player)
            rawStat = GetDisplayStat(player) -- Ambil Stat Rarest
            
            local tracker = _G_FishingTracker[player.Name]
            if not tracker then
                _G_FishingTracker[player.Name] = {LastCount = currentCaught, LastChangeTime = currentTime}
                rawFishStatus = "Fish"
                fishIcon = "🟢"
            else
                if currentCaught > tracker.LastCount then
                    tracker.LastCount = currentCaught
                    tracker.LastChangeTime = currentTime
                    rawFishStatus = "Fish"
                    fishIcon = "🟢"
                else
                    local timeDiff = currentTime - tracker.LastChangeTime
                    if timeDiff > 30 then 
                        rawFishStatus = "AFK"
                        fishIcon = "🔴"
                    else
                        rawFishStatus = "Fish"
                        fishIcon = "🟢"
                    end
                end
            end
            
            -- 4. FORMAT FINAL
            local rawNamePadded = FormatFixed(" " .. player.Name .. " ", 15)
            local fName = "<b>" .. rawNamePadded .. "</b>"
            
            local fPlace = FormatFixed(rawPlace, 16)
            local fStat = FormatFixed(" " .. rawStat .. " ", 9)            
            
            local fFish = FormatIconRight(rawFishStatus, fishIcon, 7) 
            local fMove = FormatIconRight(rawMoveStatus, moveIcon, 7) 
            
            displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>', fName, fPlace, fStat, fFish, fMove)
        else
            -- Dead/Loading State
            local rawNamePadded = FormatFixed(" " .. player.Name .. " ", 15)
            local fName = "<b>" .. rawNamePadded .. "</b>"
            
            local fPlace = FormatFixed("Dead/Loading", 16)
            local fStat = FormatFixed(" - ", 9) 
            local fFish = FormatIconRight("Wait", "🔴", 7)
            local fMove = FormatIconRight("Wait", "🔴", 7)
            
            displayString = string.format('<font face="Code">|%s|%s|%s|%s|%s|</font>', fName, fPlace, fStat, fFish, fMove)
        end
        
        table.insert(playerList, displayString)
    end
    
    -- Sorting A-Z (kecuali header)
    local header = table.remove(playerList, 1)
    table.sort(playerList, function(a, b) return a:lower() < b:lower() end)
    table.insert(playerList, 1, header) -- Sisipkan header kembali
    
    -- Render Teks
    local finalContent = table.concat(playerList, "\n")
    
    -- Judul BOLD
    local titleString = "<b>Player List (" .. playerCount .. "/" .. maxPlayers .. ")</b> " .. statusIcon
    
    StatsParagraph:Set({Title = titleString, Content = finalContent})
end

local ToggleAutoUpdate = DataTab:CreateToggle({
    Name = "Auto Update Data (Every 1s)",
    CurrentValue = false,
    Flag = "AutoUpdateStats", 
    Callback = function(Value)
        _G_AutoUpdateStats = Value
        if Value then
            task.spawn(function()
                while _G_AutoUpdateStats do
                    UpdatePlayerData()
                    task.wait(1) 
                end
            end)
        end
    end,
})

---
-- [[ TAB: LOG (CHAT SCANNER & DISCORD) ]]
---
local LogTab = Window:CreateTab("📜 Log", nil)

LogTab:CreateSection("Chat Scanner & Filter")

-- Toggle untuk Scan Secret
LogTab:CreateToggle({
    Name = "✨ Scan All Secret/Target Catches", 
    CurrentValue = false, 
    Flag = "ScanSecretToggle",
    Callback = function(Value)
        _G_ScanSecretToggle = Value
        if Value then 
            Rayfield:Notify({Title = "Secret Filter", Content = "Hanya Secret dan Custom Target yang akan dipantau.", Duration = 2})
        else
            Rayfield:Notify({Title = "Secret Filter", Content = "Filter Secret dinonaktifkan.", Duration = 2})
        end
    end,
})

-- Bagian Input Custom Fish 
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

-- Log Output
LogTab:CreateSection("Log Output")
LogParagraph = LogTab:CreateParagraph({Title = "Log Output", Content = "Waiting for data..."})

LogTab:CreateToggle({
    Name = "Auto Scan Chat (System & Player)",
    CurrentValue = false,
    Flag = "ChatScan",
    Callback = function(Value)
        _G_ChatScan = Value
        if Value then
            -- Logic untuk TextChatService (Modern Roblox)
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
            -- Logic untuk Default Chat System (Legacy)
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

---
-- [[ TAB: TELEPORT ]]
---
local TeleportTab = Window:CreateTab("📍 Teleport", nil)

local PlayerSection = TeleportTab:CreateSection("Target Player Teleport")

local function GetPlayerNames()
   local Names = {}
   for _, v in pairs(game.Players:GetPlayers()) do
       if v ~= game.Players.LocalPlayer then table.insert(Names, v.Name) end
   end
   return Names
end

local PlayerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerNames(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "PlayerSelect", 
    Callback = function(Options)
        _G.SelectedPlayerToTP = Options[1]
    end,
})

local ButtonRefresh = TeleportTab:CreateButton({
    Name = "🔄 Refresh List",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerNames(), true)
    end,
})

local ButtonTPPlayer = TeleportTab:CreateButton({
    Name = "🚀 Teleport to Selected Player",
    Callback = function()
        local targetName = _G.SelectedPlayerToTP
        if targetName then
            local targetPlayer = game.Players:FindFirstChild(targetName)
            local LocalPlayer = game.Players.LocalPlayer
            
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                 if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                     LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                     Rayfield:Notify({Title = "Success", Content = "Teleported to " .. targetName, Duration = 2})
                 end
            else
                Rayfield:Notify({Title = "Error", Content = "Player not found/dead", Duration = 2})
            end
        end
    end,
})

local TpSection = TeleportTab:CreateSection("Island Teleport")

local DropdownArea = TeleportTab:CreateDropdown({
    Name = "Select Area",
    Options = {"Lost Isle", "Ancient Jungle", "Esoteric Depths", "Sacred Temple", "Fisherman Island"},
    CurrentOption = {"Lost Isle"},
    MultipleOptions = false,
    Flag = "TeleportArea", 
    Callback = function(Options)
        _G.SelectedAreaToTP = Options[1]
    end,
})

local ButtonTPArea = TeleportTab:CreateButton({
    Name = "🚀 Teleport to Selected Area",
    Callback = function()
        local SelectedArea = _G.SelectedAreaToTP
        local Player = game.Players.LocalPlayer
        local TargetCFrame = nil

        for _, zone in pairs(IslandZones) do
            if zone.Name == SelectedArea then
                TargetCFrame = CFrame.new(zone.Pos)
                break
            end
        end

        if not TargetCFrame and SelectedArea == "Lost Isle" then
            TargetCFrame = CFrame.new(-3735, -135, -1011) 
        end
        
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and TargetCFrame then
            Player.Character.HumanoidRootPart.CFrame = TargetCFrame
            Rayfield:Notify({Title = "Teleport", Content = "Warped to " .. SelectedArea, Duration = 2})
        end
    end,
})

---
-- [[ TAB: MISC ]]
---
local MiscTab = Window:CreateTab("⚙️ Misc", nil)
local MiscSection = MiscTab:CreateSection("Utility")

local ToggleGraphics = MiscTab:CreateToggle({
    Name = "Super Low Graphics",
    CurrentValue = false,
    Flag = "LowGraphics", 
    Callback = function(Value)
        if Value then
            local light = game.Lighting
            light.GlobalShadows = false
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic end
            end
            -- Force minimum rendering quality
            game:GetService("Settings").Rendering.QualityLevel = Enum.QualityLevel.Level01
            game:GetService("Settings").Rendering.MeshQuality = Enum.MeshQuality.Low
        else
            game.Lighting.GlobalShadows = true
            -- Reset ke default/auto
            game:GetService("Settings").Rendering.QualityLevel = Enum.QualityLevel.Automatic
            game:GetService("Settings").Rendering.MeshQuality = Enum.MeshQuality.Automatic
        end
    end,
})

local ToggleUISpy = MiscTab:CreateToggle({
    Name = "🕵️ UI Spy (F9)",
    CurrentValue = false,
    Flag = "UISpy",
    Callback = function(Value)
        _G.UISpy = Value
        if Value then
            task.spawn(function()
                local Plr = game.Players.LocalPlayer
                local Mouse = Plr:GetMouse()
                local PG = Plr:WaitForChild("PlayerGui")
                while _G.UISpy do
                    task.wait(0.5) 
                    local UIAtPos = PG:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)
                    if #UIAtPos > 0 then
                        print("UI: " .. UIAtPos[1].Name .. " | Path: " .. UIAtPos[1]:GetFullName())
                    end
                end
            end)
        end
    end,
})

local ButtonUnload = MiscTab:CreateButton({
    Name = "🔴 Unload Script",
    Callback = function()
        _G_AutoUpdateStats = false 
        _G_UISpy = false
        _G_ChatScan = false
        if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() end
        if _G_NoclipConnection then _G_NoclipConnection:Disconnect() end
        for _, conn in pairs(_G_ChatConnections) do conn:Disconnect() end
        _G_ChatConnections = {}
        Rayfield:Destroy()
        print("Frayhub Unloaded")
    end,
})

-- NOTIFIKASI FINAL
Rayfield:Notify({
    Title = "Frayhub Loaded",
    Content = "Systems ready! Check Log Tab for secret fish scanner.",
    Duration = 5,
    Image = nil,
})
