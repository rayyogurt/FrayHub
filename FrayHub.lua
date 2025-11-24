local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "💫 Frayhub 💫",
   Icon = 0,
   LoadingTitle = "Example Hub",
   LoadingSubtitle = "by Fray",
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

-- Variabel Global
local _G_InfJumpConnection = nil
local _G_NoclipConnection = nil
local _G_SelectedPlayerToTP = nil 
local _G_SelectedAreaToTP = "Lost Isle"
local _G_AutoUpdateStats = false 
local _G_UISpy = false 
local _G_LastPlayerPositions = {} 
local _G_FishingTracker = {} 

-- DATABASE ZONA
local IslandZones = {
    {Name = "Fisherman Island", Pos = Vector3.new(79, 17, 2848),     Radius = 305},
    {Name = "Esoteric Depths",  Pos = Vector3.new(3226, -1302, 1407), Radius = 305},
    {Name = "Sacred Temple",    Pos = Vector3.new(1475, -21, -631),   Radius = 305},
    {Name = "Ancient Jungle",   Pos = Vector3.new(1489, 7, -430),     Radius = 477.5} 
}

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

--[[ ==========================================
                TAB: HOME
========================================== ]]--
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
       if game.Players.LocalPlayer.Character then
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
               game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
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
       end
   end,
})

--[[ ==========================================
                TAB: DATA (FORMATTING FINAL V3)
========================================== ]]--
local DataTab = Window:CreateTab("📊 Data", nil)

-- BAGIAN 1: SERVER INFO
local ServerInfoSection = DataTab:CreateSection("Server Info")
local InfoParagraph = DataTab:CreateParagraph({Title = "Status", Content = "Initializing..."})

local ButtonRejoin = DataTab:CreateButton({
   Name = "🔁 Rejoin Server",
   Callback = function()
       Rayfield:Notify({Title = "Rejoining...", Content = "Hop to same server instance.", Duration = 2})
       game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
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
            
            -- Ambil Stat untuk Display (RAREST FISH)
            rawStat = GetDisplayStat(player)
            
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
            
            -- Nama: Bold + Spasi Kiri & Kanan (Lebar 15)
            local rawNamePadded = FormatFixed(" " .. player.Name .. " ", 15)
            local fName = "<b>" .. rawNamePadded .. "</b>"
            
            -- Tempat: (Lebar 16)
            local fPlace = FormatFixed(rawPlace, 16)
            
            -- Stat (Rarest): Spasi Kiri & Kanan (Lebar dikurangi dari 10 jadi 9)
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
    
    -- Sorting A-Z
    table.sort(playerList, function(a, b) return a:lower() < b:lower() end)
    
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

--[[ ==========================================
                TAB: TELEPORT
========================================== ]]--
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

--[[ ==========================================
                TAB: MISC
========================================== ]]--
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
       else
           game.Lighting.GlobalShadows = true
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
       if _G_InfJumpConnection then _G_InfJumpConnection:Disconnect() end
       if _G_NoclipConnection then _G_NoclipConnection:Disconnect() end
       print("Unloaded")
   end,
})

Rayfield:Notify({
   Title = "Frayhub Loaded",
   Content = "Systems ready!",
   Duration = 5,
   Image = nil,
})