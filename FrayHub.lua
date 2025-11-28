-- [[ KONFIGURASI DISCORD ]] --
local _G_WebhookURL = "https://discord.com/api/webhooks/1442845013057863743/lJMKfMxHsoEw4UGnZ4mRed_JIK8mFNElRRqZ9imqSC-DdeWrYLIHufHpGf1KfNPpYtw4"

-- DATABASE IKAN SECRET BARU (Digunakan untuk deteksi di CheckRarity dan filter baru)
local _G_SecretFishList = {
    -- Sisyphus Statue - Lost Isle
    "Sisyphus Statue",
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

-- UTILITIES BARU: Fungsi untuk mengurai data ikan dari pesan
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
local function SendToDiscord(msg, rarity, colorDec, source, fishData)
    if _G_WebhookURL == "" or not _G_WebhookURL:find("http") then return end

    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local player = game.Players.LocalPlayer
    local playerName = player.Name
    local playerDisplay = player.DisplayName
    
    -- LOGIKA UNTUK GAMBAR IKAN (THUMBNAIL)
    local fishImageURL = nil
    -- Kita hanya menampilkan gambar untuk Secret dan Custom Target
    if rarity == "Secret" or rarity == "Custom Target" then
        -- Placeholder URL gambar ikan Secret/Target
        fishImageURL = "https://i.imgur.com/eQJtOqB.png" -- Contoh Placeholder
    end

    local embedData = {
        ["username"] = "**Secret Notification**",
        ["avatar_url"] = "https://share.google/images/qvmsQaZadX4enqVzr",
        ["embeds"] = {{
            ["title"] = "🎣 **" .. rarity .. "** Catch Detected!",
            ["description"] = "**Original Message:** " .. msg, 
            ["color"] = colorDec,
            
            -- PENAMBAHAN THUMBNAIL (GAMBAR IKAN)
            ["thumbnail"] = fishImageURL and { ["url"] = fishImageURL } or nil,
            
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

-- Variabel Global Lainnya (tetap sama)
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
local _G_ChatScan = false
local _G_ChatConnections = {}
local _G_LogHistory = {}
-- Hapus _G_RarityFilters karena kita pakai toggle baru
local _G_ScanSecretToggle = false -- <<<< TOGGLE BARU
local LogParagraph = nil    
local _G_CustomFishList = {}    
local CustomFishDisplayParagraph = nil
local InfoParagraph = nil    

-- [Kode UI Rayfield dan fungsi utility lainnya (FormatShortNum, dll.) TIDAK SAYA UBAH]

-- ... [Kode Rayfield: Window, MainTab, DataTab, TeleportTab, MiscTab] ...

-- Helper Check Rarity (DIUBAH TOTAL)
local function CheckRarity(msg)
    local msgLower = msg:lower()
    
    -- Cek Rarity Bawaan (Epic, Legendary, Mythic)
    if string.find(msg, "Enchant Stone") or string.find(msg, "Astra Damsel") then
        return "Epic"
    end
    
    if string.find(msg, "Magic Tang") or string.find(msg, "Big Temple") or string.find(msg, "Megalodon") then
        return "Legendary"
    end

    if string.find(msg, "Mythic") or string.find(msg, "Abyssal") then    
        return "Mythic"
    end
    
    -- Cek Semua Ikan Secret yang diminta pengguna
    for _, secretName in ipairs(_G_SecretFishList) do
        -- Jika pesan mengandung nama Secret Fish yang spesifik
        if string.find(msgLower, secretName:lower()) then
            return "Secret"
        end
    end

    return "Other"
end

-- Fungsi Update UI Log (tetap sama)
local function UpdateLogDisplay()
    local content = table.concat(_G_LogHistory, "\n\n")
    LogParagraph:Set({Title = "Log Output (Last 15)", Content = content})
end

-- Fungsi Proses Pesan (DISCORD INTEGRATED & CLEANED)
local function ProcessMessage(msg, source)
    local cleanMsg = msg:gsub("<[^>]+>", "")
    cleanMsg = cleanMsg:gsub("^%[Server%]:%s*", ""):gsub("^%[System%]:%s*", "")
    cleanMsg = cleanMsg:gsub("^%s+", "")
    
    local fishData = ParseFishData(cleanMsg) 
    
    -- 2.5 CEK APAKAH ADA DI CUSTOM LIST
    local isCustomTarget = false
    for _, targetName in pairs(_G_CustomFishList) do
        if string.find(cleanMsg:lower(), targetName:lower()) then
            isCustomTarget = true
            break
        end
    end

    -- 3. Tentukan Rarity
    local msgRarity = CheckRarity(cleanMsg)
    
    -- 4. LOGIKA FILTER (DIUBAH)
    local isAllowed = false

    if isCustomTarget then
        isAllowed = true
        msgRarity = "Custom Target" 
    elseif _G_ScanSecretToggle and msgRarity == "Secret" then -- Cek toggle Secret baru
        isAllowed = true
    else
        -- Jika tidak Secret/Custom, jangan lolos
        return
    end
    
    if not isAllowed then return end    

    -- 5. Tampilkan Log di UI
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

    local formattedLog = string.format('<font color="#F0C600">[%s]</font> <font color="#00FF00">[%s]:</font> <font color="%s">"%s"</font>', timestamp, source, msgColor, cleanMsg)
    
    table.insert(_G_LogHistory, 1, formattedLog)
    if #_G_LogHistory > 15 then table.remove(_G_LogHistory) end
    UpdateLogDisplay()

    -- 6. KIRIM KE DISCORD (Versi Bersih)
    pcall(function()
        SendToDiscord(cleanMsg, msgRarity, discordColor, source, fishData) 
    end)
end


-- [[ MODIFIKASI UI LOG TAB ]] --

local LogTab = Window:CreateTab("📜 Log", nil)

LogTab:CreateSection("Chat Scanner & Filter")

-- MENGGANTI DROPDOWN DENGAN TOGGLE BARU
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

-- [BARU] Bagian Input Custom Fish (Tidak diubah)
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

LogTab:CreateToggle({
    Name = "Auto Scan Chat (System & Player)",
    CurrentValue = false,
    Flag = "ChatScan",
    Callback = function(Value)
        _G_ChatScan = Value
        if Value then
            -- [Kode koneksi chat (TextChatService / DefaultChatSystemChatEvents) TIDAK DIUBAH]
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

-- [Kode Teleport Tab dan Misc Tab TIDAK SAYA UBAH]

-- ...

Rayfield:Notify({Title = "Frayhub Loaded", Content = "All Systems Go!", Duration = 5, Image = nil})
