local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Library.CreateLib("BTDX PRO - ArtSquadFive", "Midnight")

-- Переменные
local favoriteUnits = {}
local availableUnits = {}
local autoUpgrade = false

-- Функция для сканирования юнитов с Config -> Price и Upgrade
local function scanAvailableUnits()
    local units = {}
    local replicatedStorage = game:GetService("ReplicatedStorage")
    
    local towersFolder = replicatedStorage:FindFirstChild("Towers")
    if not towersFolder then return units end
    
    for _, towerModel in pairs(towersFolder:GetChildren()) do
        if towerModel:IsA("Model") then
            local unitName = towerModel.Name
            local unitPrice = "???"
            local upgradeCost = "???"
            
            -- Ищем Config папку
            local configFolder = towerModel:FindFirstChild("Config")
            if configFolder then
                -- Цена из Config -> Price
                local priceValue = configFolder:FindFirstChild("Price")
                if priceValue and priceValue:IsA("NumberValue") then
                    unitPrice = priceValue.Value
                end
                
                -- Стоимость прокачки из Config -> Upgrade
                local upgradeValue = configFolder:FindFirstChild("Upgrade")
                if upgradeValue and upgradeValue:IsA("NumberValue") then
                    upgradeCost = upgradeValue.Value
                end
            end
            
            table.insert(units, {
                Name = unitName,
                Price = unitPrice,
                UpgradeCost = upgradeCost
            })
        end
    end
    
    table.sort(units, function(a, b)
        if a.Price == "???" then return false end
        if b.Price == "???" then return true end
        return a.Price < b.Price
    end)
    
    return units
end

-- Функция для спавна юнита
local function spawnUnit(unitName)
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character and character:FindFirstChild("Head") then
        local headPosition = character.Head.Position
        local success, result = pcall(function()
            return game:GetService("ReplicatedStorage").Functions.SpawnTower:InvokeServer(unitName, CFrame.new(headPosition))
        end)
        
        if success then
            print("✅ СПАВН: " .. unitName)
            return true
        else
            print("❌ ОШИБКА: " .. unitName .. " - " .. tostring(result))
            return false
        end
    end
    return false
end

-- Функция для прокачки юнитов
local function upgradeAllTowers()
    local workspaceTowers = workspace:FindFirstChild("Towers")
    if not workspaceTowers then return end
    
    local player = game.Players.LocalPlayer
    for _, tower in pairs(workspaceTowers:GetChildren()) do
        if tower:GetAttribute("Owner") == player.Name then
            pcall(function()
                game:GetService("ReplicatedStorage").Functions.Upgrade:InvokeServer(tower)
            end)
            wait(0.1)
        end
    end
end

-- Функция прокачки по уровням
local function upgradeToLevel(targetLevel)
    local workspaceTowers = workspace:FindFirstChild("Towers")
    if not workspaceTowers then return end
    
    local player = game.Players.LocalPlayer
    for _, tower in pairs(workspaceTowers:GetChildren()) do
        if tower:GetAttribute("Owner") == player.Name then
            local currentLevel = tower:GetAttribute("Level") or 1
            while currentLevel < targetLevel and currentLevel < 15 do
                pcall(function()
                    game:GetService("ReplicatedStorage").Functions.Upgrade:InvokeServer(tower)
                end)
                currentLevel = currentLevel + 1
                wait(0.15)
            end
        end
    end
end

-- Функция авто-прокачки
local function startAutoUpgrade()
    while autoUpgrade do
        upgradeAllTowers()
        wait(3)
    end
end

-- Сканируем юниты
availableUnits = scanAvailableUnits()

-- ВКЛАДКА 1: ВСЕ ЮНИТЫ
local allUnitsTab = Window:NewTab("ВСЕ ЮНИТЫ")
local allUnitsSection = allUnitsTab:NewSection("Все юниты (" .. #availableUnits .. " шт)")

for _, unit in pairs(availableUnits) do
    local buttonText = unit.Name .. " [" .. tostring(unit.Price) .. "]"
    local starText = favoriteUnits[unit.Name] and "⭐" or "☆"
    
    -- Кнопка спавна
    local spawnBtn = allUnitsSection:NewButton(buttonText, "Цена: " .. tostring(unit.Price) .. " | Прокачка: " .. tostring(unit.UpgradeCost), function()
        spawnUnit(unit.Name)
    end)
    
    -- Кнопка избранного
    local favBtn = allUnitsSection:NewButton(starText .. " " .. unit.Name, 
        favoriteUnits[unit.Name] and "Убрать из избранного" or "Добавить в избранное", 
        function()
            if favoriteUnits[unit.Name] then
                favoriteUnits[unit.Name] = nil
                print("❌ Убрано из избранного: " .. unit.Name)
            else
                favoriteUnits[unit.Name] = unit
                print("⭐ Добавлено в избранное: " .. unit.Name)
            end
        end
    )
end

-- ВКЛАДКА 2: ИЗБРАННОЕ
local favoriteTab = Window:NewTab("ИЗБРАННОЕ")
local favoriteSection = favoriteTab:NewSection("Любимые юниты")

-- Функция обновления избранного
local function updateFavoritesSection()
    favoriteSection:Clear()
    
    for unitName, unit in pairs(favoriteUnits) do
        favoriteSection:NewButton(
            "⭐ " .. unitName .. " [" .. tostring(unit.Price) .. "]", 
            "Цена: " .. tostring(unit.Price) .. " | Прокачка: " .. tostring(unit.UpgradeCost), 
            function()
                spawnUnit(unitName)
            end
        )
    end
    
    if next(favoriteUnits) == nil then
        favoriteSection:NewLabel("Нет избранных юнитов")
        favoriteSection:NewLabel("Добавьте юнитов во вкладке 'Все юниты'")
    end
end

favoriteSection:NewButton("Обновить список", "Обновить список избранных", function()
    updateFavoritesSection()
end)

updateFavoritesSection()

-- ВКЛАДКА 3: ПРОКАЧКА
local upgradeTab = Window:NewTab("ПРОКАЧКА")
local upgradeSection = upgradeTab:NewSection("Система прокачки")

upgradeSection:NewButton("ПРОКАЧАТЬ ВСЕХ", "Мгновенная прокачка всех юнитов", function()
    upgradeAllTowers()
end)

-- Прокачка по уровням от 1 до 15
for level = 2, 15 do
    upgradeSection:NewButton("УРОВЕНЬ " .. level, "Прокачать всех до " .. level .. " уровня", function()
        upgradeToLevel(level)
    end)
end

-- Авто-прокачка
upgradeSection:NewToggle("АВТО-ПРОКАЧКА", "Автоматически прокачивать каждые 3 сек", function(state)
    autoUpgrade = state
    if state then
        coroutine.wrap(startAutoUpgrade)()
    end
end)

-- ВКЛАДКА 4: МАССОВЫЙ СПАВН
local massTab = Window:NewTab("МАССОВЫЙ СПАВН")
local massSection = massTab:NewSection("Групповой спавн")

massSection:NewButton("СПАВН ВСЕХ ПРЕМИУМ", "Спавн топовых юнитов", function()
    local premiumUnits = {"Astroclaw TV-Guy", "Mecha Supreme Cinemaguy", "Supreme Cinemaguy", "Big TV-Guy", "TV-Gal"}
    for _, unitName in pairs(premiumUnits) do
        spawnUnit(unitName)
        wait(0.3)
    end
end)

massSection:NewButton("10 СЛУЧАЙНЫХ", "Спавн 10 случайных юнитов", function()
    for i = 1, 10 do
        if #availableUnits > 0 then
            local randomUnit = availableUnits[math.random(1, #availableUnits)]
            spawnUnit(randomUnit.Name)
            wait(0.2)
        end
    end
end)

massSection:NewButton("ВСЕ ЮНИТЫ", "СПАВН ВСЕГО ЧТО ЕСТЬ", function()
    for _, unit in pairs(availableUnits) do
        spawnUnit(unit.Name)
        wait(0.1)
    end
end)

-- ВКЛАДКА 5: ИНСТРУМЕНТЫ
local toolsTab = Window:NewTab("ИНСТРУМЕНТЫ")
local toolsSection = toolsTab:NewSection("Утилиты")

toolsSection:NewButton("ОБНОВИТЬ СПИСОК", "Пересканировать всех юнитов", function()
    availableUnits = scanAvailableUnits()
    print("✅ Список юнитов обновлен!")
end)

toolsSection:NewButton("ИНФО В КОНСОЛЬ", "Показать информацию в консоли", function()
    print("=== ИНФО О ЮНИТАХ ===")
    for i, unit in pairs(availableUnits) do
        local star = favoriteUnits[unit.Name] and "⭐" or "☆"
        print(i .. ". " .. star .. " " .. unit.Name .. " | Цена: " .. tostring(unit.Price) .. " | Прокачка: " .. tostring(unit.UpgradeCost))
    end
    print("=====================")
end)

-- ВКЛАДКА 6: ИНФО
local infoTab = Window:NewTab("ИНФО")
local infoSection = infoTab:NewSection("Информация")

infoSection:NewLabel("BTDX PRO - ArtSquadFive")
infoSection:NewLabel("Юнитов: " .. #availableUnits)
infoSection:NewLabel("Избранных: " .. #favoriteUnits)
infoSection:NewLabel("Версия: 3.0")

print("=== BTDX PRO ===")
print("✅ Юнитов: " .. #availableUnits)
print("✅ Цены из Config -> Price")
print("✅ Прокачка из Config -> Upgrade")
print("✅ Избранных: " .. #favoriteUnits)
print("✅ Прокачка до 15 уровня")
print("✅ Без RGB - чистый интерфейс")
print("=================")

-- Автоматический вывод списка юнитов
coroutine.wrap(function()
    wait(2)
    print("=== СПИСОК ЮНИТОВ ===")
    for i, unit in pairs(availableUnits) do
        if i <= 10 then
            print(i .. ". " .. unit.Name .. " | Цена: " .. tostring(unit.Price) .. " | Прокачка: " .. tostring(unit.UpgradeCost))
        end
    end
    if #availableUnits > 10 then
        print("... и еще " .. (#availableUnits - 10) .. " юнитов")
    end

end)()

