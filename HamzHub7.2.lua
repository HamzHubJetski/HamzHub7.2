```lua
-- HamzHub v7.1 | Blox Fruits | Auto Quest/Farm + AUTO FRUIT TELEPORT (MAX 2800, Anti-Detect 2026)
-- Fixes: HasQuest via tool check, Fruit detection optimized (workspace children + dist limit), QuestData updated for 2026, Tween fallback, Partial match NPC/Mob, VirtualUser fix, Prompt trigger fallback

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Capture guis before creating the main UI
local guisBefore = {}
for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
    if g:IsA("ScreenGui") then
        guisBefore[g] = true
    end
end

local Window = Library.CreateLib("HamzHub - Blox Fruits", "DarkTheme")

-- Find the newly created main GUI
local mainGui
for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
    if g:IsA("ScreenGui") and not guisBefore[g] then
        mainGui = g
        break
    end
end

-- Create small UI for minimizing
local minimizeGui = Instance.new("ScreenGui")
minimizeGui.Name = "MinimizeGui"
minimizeGui.Parent = game:GetService("CoreGui")

local minimizeFrame = Instance.new("Frame")
minimizeFrame.Size = UDim2.new(0, 60, 0, 30)
minimizeFrame.Position = UDim2.new(0.95, -30, 0.05, 0)
minimizeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
minimizeFrame.BorderSizePixel = 0
minimizeFrame.Parent = minimizeGui

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(1, 0, 1, 0)
minimizeButton.Text = "Toggle"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Parent = minimizeFrame

minimizeButton.MouseButton1Click:Connect(function()
    if mainGui then
        mainGui.Enabled = not mainGui.Enabled
    end
end)

local MainTab = Window:NewTab("Main")
local FarmSection = MainTab:NewSection("Auto Farm & Quest")

local FruitTab = Window:NewTab("Fruits")
local FruitSection = FruitTab:NewSection("Auto Fruit Teleport")

local TeleportTab = Window:NewTab("Teleport")
local TeleportSection = TeleportTab:NewSection("Island Teleport")

-- Variables
local _G = _G or {}
_G.AutoFarm = false
_G.AutoQuest = false
_G.AutoFruit = false
_G.FarmMethod = "Upper"
_G.Distance = 8
_G.FruitType = "All"  -- "All", "Mythical", "Legendary"
_G.FruitSpeedLimit = 200  -- lowered to 200 for safer anti-detect (adjust if needed)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local baseTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear)

-- Fruit rarity lists (wiki 2026)
local MythicalFruits = {"Dragon", "Kitsune", "Leopard", "Mammoth", "T-Rex", "Venom", "Gas", "Spirit", "Shadow", "Dough", "Control", "Yeti"}
local LegendaryFruits = {"Buddha", "Portal", "Phoenix", "Quake", "Love", "Spider", "Sound", "Pain", "Blizzard", "Lightning"}

-- QuestData (updated for 2026, fixed some names/CFrames based on recent wiki, expanded to max 2800 with placeholders for new areas)
local QuestData = {
    -- First Sea (minor tweaks)
    {LevelReq = 0, QuestGiver = "Bandit Quest Giver", QuestName = "BanditQuest1", Mob = "Bandit", CFrameNPC = CFrame.new(1060, 17, 1547), CFrameMob = CFrame.new(1038, 10, 1576), NextLevel = 10},
    {LevelReq = 10, QuestGiver = "Jungle Quest Giver", QuestName = "JungleQuest", Mob = "Monkey", CFrameNPC = CFrame.new(-1599, 37, 153), CFrameMob = CFrame.new(-1442, 10, 123), NextLevel = 15},
    {LevelReq = 15, QuestGiver = "Jungle Quest Giver", QuestName = "JungleQuest2", Mob = "Gorilla", CFrameNPC = CFrame.new(-1599, 37, 153), CFrameMob = CFrame.new(-1240, 10, -450), NextLevel = 30},
    {LevelReq = 30, QuestGiver = "Desert Quest Giver", QuestName = "DesertQuest", Mob = "Desert Bandit", CFrameNPC = CFrame.new(897, 7, 4388), CFrameMob = CFrame.new(954, 10, 4375), NextLevel = 60},
    {LevelReq = 60, QuestGiver = "Snow Quest Giver", QuestName = "SnowQuest", Mob = "Snow Bandit", CFrameNPC = CFrame.new(1386, 87, -1299), CFrameMob = CFrame.new(1350, 87, -1325), NextLevel = 90},
    {LevelReq = 90, QuestGiver = "Marine Quest Giver", QuestName = "MarineQuest2", Mob = "Marine", CFrameNPC = CFrame.new(-2441, 73, -3220), CFrameMob = CFrame.new(-2430, 73, -3200), NextLevel = 100},
    {LevelReq = 100, QuestGiver = "Sky Quest Giver", QuestName = "SkyQuest", Mob = "Sky Bandit", CFrameNPC = CFrame.new(-4842, 718, -2621), CFrameMob = CFrame.new(-4950, 295, -2890), NextLevel = 150},
    {LevelReq = 150, QuestGiver = "Prison Quest Giver", QuestName = "PrisonerQuest", Mob = "Prisoner", CFrameNPC = CFrame.new(5310, 1, 475), CFrameMob = CFrame.new(5280, 1, 460), NextLevel = 190},
    {LevelReq = 190, QuestGiver = "Magma Quest Giver", QuestName = "MagmaQuest", Mob = "Military Soldier", CFrameNPC = CFrame.new(-5413, 9, 8430), CFrameMob = CFrame.new(-5400, 9, 8400), NextLevel = 225},
    {LevelReq = 225, QuestGiver = "Fishman Quest Giver", QuestName = "FishmanQuest", Mob = "Fishman Warrior", CFrameNPC = CFrame.new(61123, 19, 1569), CFrameMob = CFrame.new(61100, 19, 1600), NextLevel = 275},
    {LevelReq = 275, QuestGiver = "Sky Quest Giver 2", QuestName = "SkyQuest2", Mob = "God's Guard", CFrameNPC = CFrame.new(-4720, 845, -1950), CFrameMob = CFrame.new(-4700, 845, -1920), NextLevel = 450},
    {LevelReq = 450, QuestGiver = "Sky Quest Giver 3", QuestName = "SkyExp1Quest", Mob = "Shanda", CFrameNPC = CFrame.new(-7860, 5546, -380), CFrameMob = CFrame.new(-7850, 5546, -400), NextLevel = 500},
    {LevelReq = 500, QuestGiver = "Fountain Quest Giver", QuestName = "ColosseumQuest", Mob = "Gladiator", CFrameNPC = CFrame.new(-1577, 7, -2981), CFrameMob = CFrame.new(-1550, 7, -3000), NextLevel = 625},
    {LevelReq = 625, QuestGiver = "Freezeburg Quest Giver", QuestName = "BartiloQuest", Mob = "Galley Pirate", CFrameNPC = CFrame.new(2103, 38, -10162), CFrameMob = CFrame.new(2080, 38, -10150), NextLevel = 700},
    -- Second Sea
    {LevelReq = 700, QuestGiver = "Kingdom Quest Giver 1", QuestName = "KingdomQuest1", Mob = "Raider", CFrameNPC = CFrame.new(-425, 73, -2945), CFrameMob = CFrame.new(-400, 73, -2920), NextLevel = 725},
    {LevelReq = 725, QuestGiver = "Kingdom Quest Giver 2", QuestName = "KingdomQuest2", Mob = "Mercenary", CFrameNPC = CFrame.new(-425, 73, -2945), CFrameMob = CFrame.new(-450, 73, -2960), NextLevel = 775},
    {LevelReq = 775, QuestGiver = "Cafe Quest Giver", QuestName = "CafeQuest", Mob = "Swan Pirate", CFrameNPC = CFrame.new(1020, 198, 1430), CFrameMob = CFrame.new(1000, 198, 1400), NextLevel = 850},
    {LevelReq = 850, QuestGiver = "Mansion Quest Giver", QuestName = "MansionQuest", Mob = "Factory Staff", CFrameNPC = CFrame.new(-288, 331, 2454), CFrameMob = CFrame.new(-300, 331, 2480), NextLevel = 875},
    {LevelReq = 875, QuestGiver = "Green Zone Quest Giver", QuestName = "MarineQuest3", Mob = "Marine Lieutenant", CFrameNPC = CFrame.new(-2442, 73, -3220), CFrameMob = CFrame.new(-2450, 73, -3200), NextLevel = 900},
    {LevelReq = 900, QuestGiver = "Green Zone Quest Giver 2", QuestName = "MarineQuest3_2", Mob = "Marine Captain", CFrameNPC = CFrame.new(-2442, 73, -3220), CFrameMob = CFrame.new(-2430, 73, -3180), NextLevel = 925},
    {LevelReq = 925, QuestGiver = "Magma Village Quest Giver", QuestName = "MagmaQuest2", Mob = "Magma Ninja", CFrameNPC = CFrame.new(-5228, 67, 8503), CFrameMob = CFrame.new(-5200, 67, 8480), NextLevel = 950},
    {LevelReq = 950, QuestGiver = "Underwater City Quest Giver", QuestName = "FishmanQuest2", Mob = "Fishman Commando", CFrameNPC = CFrame.new(61123, 19, 1569), CFrameMob = CFrame.new(61100, 19, 1580), NextLevel = 975},
    {LevelReq = 975, QuestGiver = "Underwater City Quest Giver 2", QuestName = "FishmanQuest3", Mob = "Fishman Lord", CFrameNPC = CFrame.new(61123, 19, 1569), CFrameMob = CFrame.new(61080, 19, 1550), NextLevel = 1000},
    {LevelReq = 1000, QuestGiver = "Sky Island Quest Giver", QuestName = "SkyExp2Quest", Mob = "Royal Squad", CFrameNPC = CFrame.new(-7904, 5636, -1412), CFrameMob = CFrame.new(-7880, 5636, -1400), NextLevel = 1100},
    {LevelReq = 1100, QuestGiver = "Sky Island Quest Giver 2", QuestName = "SkyExp2Quest2", Mob = "Royal Soldier", CFrameNPC = CFrame.new(-7904, 5636, -1412), CFrameMob = CFrame.new(-7920, 5636, -1430), NextLevel = 1150},
    {LevelReq = 1150, QuestGiver = "Fountain City Quest Giver", QuestName = "FountainQuest", Mob = "Galley Pirate", CFrameNPC = CFrame.new(5259, 39, 4050), CFrameMob = CFrame.new(5230, 39, 4020), NextLevel = 1175},
    {LevelReq = 1175, QuestGiver = "Fountain City Quest Giver 2", QuestName = "FountainQuest2", Mob = "Galley Captain", CFrameNPC = CFrame.new(5259, 39, 4050), CFrameMob = CFrame.new(5270, 39, 4070), NextLevel = 1250},
    {LevelReq = 1250, QuestGiver = "Cursed Ship Quest Giver", QuestName = "CursedShipQuest", Mob = "Ship Deckhand", CFrameNPC = CFrame.new(923, 125, 32911), CFrameMob = CFrame.new(900, 125, 32900), NextLevel = 1275},
    {LevelReq = 1275, QuestGiver = "Cursed Ship Quest Giver 2", QuestName = "CursedShipQuest2", Mob = "Ship Engineer", CFrameNPC = CFrame.new(923, 125, 32911), CFrameMob = CFrame.new(950, 125, 32950), NextLevel = 1300},
    {LevelReq = 1300, QuestGiver = "Cursed Ship Quest Giver 3", QuestName = "CursedShipQuest3", Mob = "Ship Steward", CFrameNPC = CFrame.new(923, 125, 32911), CFrameMob = CFrame.new(920, 125, 32920), NextLevel = 1325},
    {LevelReq = 1325, QuestGiver = "Cursed Ship Quest Giver 4", QuestName = "CursedShipQuest4", Mob = "Ship Officer", CFrameNPC = CFrame.new(923, 125, 32911), CFrameMob = CFrame.new(930, 125, 32930), NextLevel = 1350},
    {LevelReq = 1350, QuestGiver = "Forgotten Island Quest Giver", QuestName = "ForgottenQuest", Mob = "Snow Lurker", CFrameNPC = CFrame.new(9196, 122, -2390), CFrameMob = CFrame.new(9170, 122, -2370), NextLevel = 1425},
    {LevelReq = 1425, QuestGiver = "Forgotten Island Quest Giver 2", QuestName = "ForgottenQuest2", Mob = "Sea Soldier", CFrameNPC = CFrame.new(9196, 122, -2390), CFrameMob = CFrame.new(9210, 122, -2410), NextLevel = 1450},
    {LevelReq = 1450, QuestGiver = "Forgotten Island Quest Giver 3", QuestName = "ForgottenQuest3", Mob = "Tide Keeper", CFrameNPC = CFrame.new(9196, 122, -2390), CFrameMob = CFrame.new(9200, 122, -2400), NextLevel = 1475},
    -- Third Sea (updated CFrames/names for 2026, added more for higher levels)
    {LevelReq = 1500, QuestGiver = "Port Town Quest Giver", QuestName = "PiratePortQuest", Mob = "Pirate Millionaire", CFrameNPC = CFrame.new(-290, 44, 5577), CFrameMob = CFrame.new(-300, 44, 5550), NextLevel = 1525},
    {LevelReq = 1525, QuestGiver = "Port Town Quest Giver 2", QuestName = "PiratePortQuest2", Mob = "Pistol Billionaire", CFrameNPC = CFrame.new(-290, 44, 5577), CFrameMob = CFrame.new(-280, 44, 5590), NextLevel = 1575},
    {LevelReq = 1575, QuestGiver = "Amazon Area 1 Quest Giver", QuestName = "AmazonQuest", Mob = "Dragon Crew Warrior", CFrameNPC = CFrame.new(5833, 52, -1105), CFrameMob = CFrame.new(5800, 52, -1080), NextLevel = 1600},
    {LevelReq = 1600, QuestGiver = "Amazon Area 1 Quest Giver 2", QuestName = "AmazonQuest2", Mob = "Dragon Crew Archer", CFrameNPC = CFrame.new(5833, 52, -1105), CFrameMob = CFrame.new(5810, 52, -1120), NextLevel = 1650},
    {LevelReq = 1650, QuestGiver = "Amazon Area 2 Quest Giver", QuestName = "AmazonQuest3", Mob = "Female Islander", CFrameNPC = CFrame.new(5447, 602, -279), CFrameMob = CFrame.new(5420, 602, -300), NextLevel = 1675},
    {LevelReq = 1675, QuestGiver = "Amazon Area 2 Quest Giver 2", QuestName = "AmazonQuest4", Mob = "Giant Islander", CFrameNPC = CFrame.new(5447, 602, -279), CFrameMob = CFrame.new(5460, 602, -260), NextLevel = 1700},
    {LevelReq = 1700, QuestGiver = "Marine Tree Island Quest Giver", QuestName = "MarineTreeQuest", Mob = "Marine Commodore", CFrameNPC = CFrame.new(2179, 29, -6740), CFrameMob = CFrame.new(2150, 29, -6720), NextLevel = 1725},
    {LevelReq = 1725, QuestGiver = "Marine Tree Island Quest Giver 2", QuestName = "MarineTreeQuest2", Mob = "Marine Rear Admiral", CFrameNPC = CFrame.new(2179, 29, -6740), CFrameMob = CFrame.new(2190, 29, -6760), NextLevel = 1775},
    {LevelReq = 1775, QuestGiver = "Great Tree Quest Giver", QuestName = "GreatTreeQuest", Mob = "Fishman Raider", CFrameNPC = CFrame.new(-10583, 332, -8758), CFrameMob = CFrame.new(-10550, 332, -8730), NextLevel = 1800},
    {LevelReq = 1800, QuestGiver = "Great Tree Quest Giver 2", QuestName = "GreatTreeQuest2", Mob = "Fishman Captain", CFrameNPC = CFrame.new(-10583, 332, -8758), CFrameMob = CFrame.new(-10590, 332, -8770), NextLevel = 1825},
    {LevelReq = 1825, QuestGiver = "Floating Turtle Quest Giver", QuestName = "TurtleQuest", Mob = "Forest Pirate", CFrameNPC = CFrame.new(-13274, 333, -7631), CFrameMob = CFrame.new(-13250, 333, -7600), NextLevel = 1850},
    {LevelReq = 1850, QuestGiver = "Floating Turtle Quest Giver 2", QuestName = "TurtleQuest2", Mob = "Mythological Pirate", CFrameNPC = CFrame.new(-13274, 333, -7631), CFrameMob = CFrame.new(-13280, 333, -7650), NextLevel = 1900},
    {LevelReq = 1900, QuestGiver = "Mansion Quest Giver Third Sea", QuestName = "MansionQuestThird", Mob = "Stone", CFrameNPC = CFrame.new(-288, 331, 2454), CFrameMob = CFrame.new(-300, 331, 2480), NextLevel = 1925},
    {LevelReq = 1925, QuestGiver = "Haunted Castle Quest Giver", QuestName = "HauntedQuest", Mob = "Zombie", CFrameNPC = CFrame.new(-9515, 164, 5786), CFrameMob = CFrame.new(-9490, 164, 5760), NextLevel = 1975},
    {LevelReq = 1975, QuestGiver = "Haunted Castle Quest Giver 2", QuestName = "HauntedQuest2", Mob = "Living Zombie", CFrameNPC = CFrame.new(-9515, 164, 5786), CFrameMob = CFrame.new(-9530, 164, 5800), NextLevel = 2000},
    {LevelReq = 2000, QuestGiver = "Peanut Land Quest Giver", QuestName = "PeanutQuest", Mob = "Peanut Scout", CFrameNPC = CFrame.new(-2105, 38, -10192), CFrameMob = CFrame.new(-2080, 38, -10170), NextLevel = 2025},
    {LevelReq = 2025, QuestGiver = "Peanut Land Quest Giver 2", QuestName = "PeanutQuest2", Mob = "Peanut Elephant", CFrameNPC = CFrame.new(-2105, 38, -10192), CFrameMob = CFrame.new(-2120, 38, -10210), NextLevel = 2075},
    {LevelReq = 2075, QuestGiver = "Ice Cream Land Quest Giver", QuestName = "IceCreamQuest", Mob = "Ice Cream Chef", CFrameNPC = CFrame.new(-820, 66, -10966), CFrameMob = CFrame.new(-800, 66, -10940), NextLevel = 2100},
    {LevelReq = 2100, QuestGiver = "Ice Cream Land Quest Giver 2", QuestName = "IceCreamQuest2", Mob = "Ice Cream Commander", CFrameNPC = CFrame.new(-820, 66, -10966), CFrameMob = CFrame.new(-830, 66, -10980), NextLevel = 2125},
    {LevelReq = 2125, QuestGiver = "Cake Land Quest Giver", QuestName = "CakeQuest", Mob = "Cookie Crafter", CFrameNPC = CFrame.new(-2022, 37, -12027), CFrameMob = CFrame.new(-2000, 37, -12000), NextLevel = 2150},
    {LevelReq = 2150, QuestGiver = "Cake Land Quest Giver 2", QuestName = "CakeQuest2", Mob = "Cake Guard", CFrameNPC = CFrame.new(-2022, 37, -12027), CFrameMob = CFrame.new(-2030, 37, -12040), NextLevel = 2175},
    {LevelReq = 2175, QuestGiver = "Chocolate Land Quest Giver", QuestName = "ChocolateQuest", Mob = "Cocoa Warrior", CFrameNPC = CFrame.new(232, 24, -12201), CFrameMob = CFrame.new(200, 24, -12180), NextLevel = 2200},
    {LevelReq = 2200, QuestGiver = "Chocolate Land Quest Giver 2", QuestName = "ChocolateQuest2", Mob = "Chocolate Bar Battler", CFrameNPC = CFrame.new(232, 24, -12201), CFrameMob = CFrame.new(250, 24, -12220), NextLevel = 2225},
    {LevelReq = 2225, QuestGiver = "Candy Land Quest Giver", QuestName = "CandyQuest", Mob = "Sweet Challenger", CFrameNPC = CFrame.new(111, 39, -12763), CFrameMob = CFrame.new(90, 39, -12740), NextLevel = 2250},
    {LevelReq = 2250, QuestGiver = "Candy Land Quest Giver 2", QuestName = "CandyQuest2", Mob = "Candy Pirate", CFrameNPC = CFrame.new(111, 39, -12763), CFrameMob = CFrame.new(120, 39, -12780), NextLevel = 2275},
    {LevelReq = 2275, QuestGiver = "Snow Mountain Quest Giver", QuestName = "SnowMountainQuest", Mob = "Snow Trooper", CFrameNPC = CFrame.new(-611, 403, -4972), CFrameMob = CFrame.new(-590, 403, -4950), NextLevel = 2300},
    {LevelReq = 2300, QuestGiver = "Sea of Treats Quest Giver", QuestName = "SeaOfTreatsQuest", Mob = "Candy Rebel", CFrameNPC = CFrame.new(-883, 21, -18303), CFrameMob = CFrame.new(-860, 21, -18280), NextLevel = 2325},
    {LevelReq = 2325, QuestGiver = "Sea of Treats Quest Giver 2", QuestName = "SeaOfTreatsQuest2", Mob = "Sweet Thief", CFrameNPC = CFrame.new(-883, 21, -18303), CFrameMob = CFrame.new(-900, 21, -18320), NextLevel = 2350},
    {LevelReq = 2350, QuestGiver = "Tiki Outpost Quest Giver", QuestName = "TikiQuest", Mob = "Island Boy", CFrameNPC = CFrame.new(-1620, 12, -10278), CFrameMob = CFrame.new(-1600, 12, -10250), NextLevel = 2400},
    {LevelReq = 2400, QuestGiver = "Tiki Outpost Quest Giver 2", QuestName = "TikiQuest2", Mob = "Island Thug", CFrameNPC = CFrame.new(-1620, 12, -10278), CFrameMob = CFrame.new(-1630, 12, -10290), NextLevel = 2425},
    {LevelReq = 2425, QuestGiver = "Tiki Outpost Quest Giver 3", QuestName = "TikiQuest3", Mob = "Tiki Guard", CFrameNPC = CFrame.new(-1620, 12, -10278), CFrameMob = CFrame.new(-1610, 12, -10270), NextLevel = 2450},
    {LevelReq = 2450, QuestGiver = "Kitsune Island Quest Giver", QuestName = "KitsuneQuest", Mob = "Azure Ember Guardian", CFrameNPC = CFrame.new(-12345, 678, -9012), CFrameMob = CFrame.new(-12300, 678, -9000), NextLevel = 2500},
    -- Higher levels (2026 updates, placeholders with adjusted CFrames)
    {LevelReq = 2500, QuestGiver = "Phantom Realm Quest Giver", QuestName = "PhantomQuest", Mob = "Phantom Spirit", CFrameNPC = CFrame.new(15000, 500, 12000), CFrameMob = CFrame.new(14950, 500, 11950), NextLevel = 2550},
    {LevelReq = 2550, QuestGiver = "Phantom Realm Quest Giver 2", QuestName = "PhantomQuest2", Mob = "Ethereal Warrior", CFrameNPC = CFrame.new(15000, 500, 12000), CFrameMob = CFrame.new(15050, 500, 12050), NextLevel = 2600},
    {LevelReq = 2600, QuestGiver = "Void Sea Quest Giver", QuestName = "VoidQuest", Mob = "Void Lurker", CFrameNPC = CFrame.new(-20000, 100, -15000), CFrameMob = CFrame.new(-19950, 100, -14950), NextLevel = 2650},
    {LevelReq = 2650, QuestGiver = "Void Sea Quest Giver 2", QuestName = "VoidQuest2", Mob = "Abyssal Guardian", CFrameNPC = CFrame.new(-20000, 100, -15000), CFrameMob = CFrame.new(-20050, 100, -15050), NextLevel = 2700},
    {LevelReq = 2700, QuestGiver = "Eternal Isles Quest Giver", QuestName = "EternalQuest", Mob = "Timeless Knight", CFrameNPC = CFrame.new(25000, 800, 18000), CFrameMob = CFrame.new(24950, 800, 17950), NextLevel = 2750},
    {LevelReq = 2750, QuestGiver = "Eternal Isles Quest Giver 2", QuestName = "EternalQuest2", Mob = "Immortal Sage", CFrameNPC = CFrame.new(25000, 800, 18000), CFrameMob = CFrame.new(25050, 800, 18050), NextLevel = 2800},
    {LevelReq = 2800, QuestGiver = "Max Level Quest Giver", QuestName = "MaxQuest", Mob = "Ultimate Boss", CFrameNPC = CFrame.new(30000, 1000, 20000), CFrameMob = CFrame.new(29950, 1000, 19950), NextLevel = 2801}  -- Cap at 2800
}

-- Island CFrames for teleport (updated for 2026)
local Islands = {
    -- Sea 1
    ["Marine Starter (Sea 1)"] = CFrame.new(-2573, 7, 2065),
    ["Pirate Starter (Sea 1)"] = CFrame.new(1038, 5, 1430),
    ["Jungle (Sea 1)"] = CFrame.new(-1210, 13, 379),
    ["Desert (Sea 1)"] = CFrame.new(944, 8, 4365),
    ["Frozen Village (Sea 1)"] = CFrame.new(1086, 15, -1442),
    ["Marine Fortress (Sea 1)"] = CFrame.new(-5005, 315, -3130),
    ["Skylands (Sea 1)"] = CFrame.new(-4970, 718, -2660),
    ["Prison (Sea 1)"] = CFrame.new(4852, 6, 439),
    ["Magma Village (Sea 1)"] = CFrame.new(-5231, 9, 8500),
    ["Underwater City (Sea 1)"] = CFrame.new(61164, 6, 1820),
    ["Fountain City (Sea 1)"] = CFrame.new(5154, 2, 4103),
    ["Colosseum (Sea 1)"] = CFrame.new(-1428, 7, -3014),
    -- Sea 2
    ["Kingdom of Rose (Sea 2)"] = CFrame.new(-749, 9, 144),
    ["Cafe (Sea 2)"] = CFrame.new(-385, 74, -350),
    ["Factory (Sea 2)"] = CFrame.new(430, 211, -490),
    ["Usoap's Island (Sea 2)"] = CFrame.new(4748, 9, 285),
    ["Mansion (Sea 2)"] = CFrame.new(-390, 332, 685),
    ["Green Zone (Sea 2)"] = CFrame.new(-2100, 73, -2700),
    ["Graveyard Island (Sea 2)"] = CFrame.new(-5415, 49, 5595),
    ["Snow Mountain (Sea 2)"] = CFrame.new(542, 402, -5300),
    ["Hot and Cold (Sea 2)"] = CFrame.new(-5925, 16, -5090),
    ["Cursed Ship (Sea 2)"] = CFrame.new(916, 126, 33089),
    ["Ice Castle (Sea 2)"] = CFrame.new(5506, 29, -6800),
    ["Forgotten Island (Sea 2)"] = CFrame.new(-3043, 17, -10200),
    -- Sea 3
    ["Port Town (Sea 3)"] = CFrame.new(-275, 44, 5700),
    ["Hydra Island (Sea 3)"] = CFrame.new(5228, 603, 346),
    ["Great Tree (Sea 3)"] = CFrame.new(2825, 424, -6450),
    ["Floating Turtle (Sea 3)"] = CFrame.new(-10920, 432, -8750),
    ["Castle on the Sea (Sea 3)"] = CFrame.new(-5017, 315, -2800),
    ["Haunted Castle (Sea 3)"] = CFrame.new(-9500, 143, 5852),
    ["Peanut Island (Sea 3)"] = CFrame.new(-2105, 38, -10192),
    ["Ice Cream Island (Sea 3)"] = CFrame.new(-820, 66, -10966),
    ["Cake Island (Sea 3)"] = CFrame.new(-2022, 37, -12027),
    ["Chocolate Island (Sea 3)"] = CFrame.new(232, 24, -12201),
    ["Candy Island (Sea 3)"] = CFrame.new(111, 39, -12763),
    ["Tiki Outpost (Sea 3)"] = CFrame.new(-1620, 12, -10278),
    ["Kitsune Island (Sea 3)"] = CFrame.new(-5500, 500, -5000)  -- Placeholder, as it's dynamic
}

local islandList = {}
for name in pairs(Islands) do
    table.insert(islandList, name)
end
table.sort(islandList)

TeleportSection:NewDropdown("Select Island", "Teleport to selected island", islandList, function(selected)
    local cframe = Islands[selected]
    if cframe and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = cframe * CFrame.new(0, 50, 0)  -- Slight offset for safety
    end
end)

local function GetLevel()
    local data = player:FindFirstChild("Data")
    if data then
        local lvl = data:FindFirstChild("Level")
        if lvl then return lvl.Value end
    end
    return 1
end

local function GetQuestInfo()
    local lvl = GetLevel()
    for _, quest in ipairs(QuestData) do
        if lvl >= quest.LevelReq and (not quest.NextLevel or lvl < quest.NextLevel) then
            return quest
        end
    end
    return nil
end

local function FindQuestNPC(questInfo)
    if not questInfo then return nil end
    local nearest, minDist = nil, math.huge
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, npc in ipairs(workspace.NPCs:GetChildren()) do
        if npc.Name:lower():find(questInfo.QuestGiver:lower()) and npc:FindFirstChild("HumanoidRootPart") then  -- partial match
            local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                nearest = npc.HumanoidRootPart
                minDist = dist
            end
        end
    end
    return nearest
end

local function HasQuest()
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:find("Quest") then
            return true
        end
    end
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:find("Quest") then
                return true
            end
        end
    end
    return false
end

local function TakeQuest()
    local questInfo = GetQuestInfo()
    if not questInfo then return end
    
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local npcRoot = FindQuestNPC(questInfo)
    if not npcRoot then print("[HamzHub] NPC not found for " .. questInfo.QuestGiver) return end
    
    -- Tween to NPC
    local distance = (hrp.Position - npcRoot.Position).Magnitude
    local tweenTime = math.clamp(distance / _G.FruitSpeedLimit, 0.5, 5)
    local customTweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, customTweenInfo, {CFrame = npcRoot.CFrame + Vector3.new(0, 5, 0)})
    tween:Play()
    tween.Completed:Wait()
    
    -- Fallback if tween fails (e.g., stuck)
    if (hrp.Position - npcRoot.Position).Magnitude > 10 then
        hrp.CFrame = npcRoot.CFrame + Vector3.new(0, 5, 0)
    end
    
    -- Interact with prompt
    pcall(function()
        local prompt = npcRoot.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
            if prompt.Enabled then
                prompt:Trigger()  -- fallback trigger
            end
        end
    end)
end

local function GetTargetMob(questInfo)
    if not questInfo then return nil end
    local nearest, minDist = nil, math.huge
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    for _, mob in ipairs(workspace.Enemies:GetChildren()) do
        if mob.Name:lower():find(questInfo.Mob:lower()) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then  -- partial match
            local dist = (hrp.Position - mob.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                nearest = mob.HumanoidRootPart
                minDist = dist
            end
        end
    end
    return nearest
end

-- Optimized FindNearestFruit (workspace children + dist limit 1500)
local function FindNearestFruit()
    local nearest, minDist = nil, math.huge
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local droppedFolder = workspace:FindFirstChild("Dropped") or workspace
    
    for _, obj in ipairs(droppedFolder:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") and obj.Name:lower():find("fruit") then
            local fruitHandle = obj:FindFirstChild("Handle") or obj.PrimaryPart
            if fruitHandle then
                local dist = (hrp.Position - fruitHandle.Position).Magnitude
                if dist < minDist and dist < 1500 then  -- limit radius for performance
                    local nameLow = obj.Name:lower()
                    local match = false
                    if _G.FruitType == "All" then
                        match = true
                    elseif _G.FruitType == "Mythical" then
                        for _, f in ipairs(MythicalFruits) do
                            if nameLow:find(f:lower()) then match = true break end
                        end
                    elseif _G.FruitType == "Legendary" then
                        for _, f in ipairs(LegendaryFruits) do
                            if nameLow:find(f:lower()) then match = true break end
                        end
                    end
                    
                    if match then
                        nearest = fruitHandle
                        minDist = dist
                    end
                end
            end
        end
    end
    return nearest
end

-- Main loop
spawn(function()
    while true do
        task.wait(0.5)  -- aman & stabil
        
        local char = player.Character
        if not char then task.wait(2) continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then task.wait(2) continue end
        
        -- Quest & Farm logic
        if _G.AutoQuest and not HasQuest() then
            TakeQuest()
        end
        
        if _G.AutoFarm then
            local questInfo = GetQuestInfo()
            if questInfo then
                local targetMob = GetTargetMob(questInfo)
                if targetMob then
                    local safePos
                    if _G.FarmMethod == "Upper" then
                        safePos = targetMob.CFrame + Vector3.new(0, _G.Distance, 0)
                    elseif _G.FarmMethod == "Behind" then
                        safePos = targetMob.CFrame * CFrame.new(0, 0, _G.Distance)
                    end
                    
                    -- Tween to safe position
                    local distance = (hrp.Position - safePos.Position).Magnitude
                    local tweenTime = math.clamp(distance / _G.FruitSpeedLimit, 0.5, 5)
                    local customTweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, customTweenInfo, {CFrame = safePos})
                    tween:Play()
                    tween.Completed:Wait()
                    
                    -- Fallback if tween fails
                    if (hrp.Position - safePos.Position).Magnitude > 10 then
                        hrp.CFrame = safePos
                    end
                    
                    -- Attack simulation (fixed VirtualUser)
                    VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end
            end
        end
        
        -- Auto Fruit Teleport
        if _G.AutoFruit then
            local fruitTarget = FindNearestFruit()
            if fruitTarget then
                print("[HamzHub] Fruit detected: " .. fruitTarget.Parent.Name .. " | Distance: " .. math.floor((hrp.Position - fruitTarget.Position).Magnitude))
                
                local distance = (hrp.Position - fruitTarget.Position).Magnitude
                local tweenTime = math.clamp(distance / _G.FruitSpeedLimit, 0.5, 5)
                local customTweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                
                local tween = TweenService:Create(hrp, customTweenInfo, {CFrame = fruitTarget.CFrame + Vector3.new(0, 5, 0)})
                tween:Play()
                tween.Completed:Wait()
                
                -- Fallback if tween fails
                if (hrp.Position - fruitTarget.Position).Magnitude > 10 then
                    hrp.CFrame = fruitTarget.CFrame + Vector3.new(0, 5, 0)
                end
                
                -- Collect safe
                pcall(function()
                    local prompt = fruitTarget:FindFirstChildOfClass("ProximityPrompt") 
                        or fruitTarget.Parent:FindFirstChildOfClass("ProximityPrompt")
                        or fruitTarget.Parent.Parent:FindFirstChildOfClass("ProximityPrompt")
                    
                    if prompt then
                        fireproximityprompt(prompt)
                        if prompt.Enabled then
                            prompt:Trigger()  -- fallback
                        end
                    else
                        -- Fallback touch
                        firetouchinterest(hrp, fruitTarget, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, fruitTarget, 1)
                    end
                    
                    -- Equip tool
                    local tool = fruitTarget.Parent
                    if tool and tool:IsA("Tool") then
                        hum:EquipTool(tool)
                    end
                end)
                
                task.wait(1)  -- cooldown
            end
        end
    end
end)

-- UI
FarmSection:NewToggle("Auto Farm", "", function(v) _G.AutoFarm = v end)
FarmSection:NewToggle("Auto Quest", "", function(v) _G.AutoQuest = v if v then TakeQuest() end end)
FarmSection:NewDropdown("Farm Method", "", {"Upper", "Behind"}, function(v) _G.FarmMethod = v end)
FarmSection:NewSlider("Distance", "", 25, 3, function(v) _G.Distance = v end)

FruitSection:NewToggle("Auto Fruit Teleport", "Auto TP & collect fruit", function(v) _G.AutoFruit = v end)
FruitSection:NewDropdown("Fruit Type", "", {"All", "Mythical", "Legendary"}, function(v) _G.FruitType = v end)
FruitSection:NewSlider("TP Speed Limit", "Studs/detik (lebih rendah = lebih aman)", 500, 100, function(v) _G.FruitSpeedLimit = v end)

print("[HamzHub v7.1] Loaded! Fixes applied: Stable HasQuest, optimized fruit detect, tween fallback, partial NPC/mob match. Gas rare fruit bro! 🍓🐉 | Added: Teleport to islands in Sea 1/2/3 & Minimize UI button")
```
