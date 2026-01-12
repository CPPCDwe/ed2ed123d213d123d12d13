--// Services \\--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Variables \\--
local Player = Players.LocalPlayer
local Boosts = Workspace:WaitForChild("Map"):WaitForChild("Stages"):WaitForChild("Boosts")
local World = Player:WaitForChild("leaderstats"):WaitForChild("WORLD")
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

--// Optimization Variables \\--
local LastWorld = nil
local CachedBoosts = {}
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// Optimized Functions \\--
local function GetOptimalBoost(worldFolder)
    if not worldFolder then 
        return nil 
    end
    
    -- Приоритетные цели для сбора
    local PriorityTargets = {8, 7, 6, 4, 3}
    
    -- Кэшируем бусты для текущего мира
    local worldValue = World.Value
    if LastWorld ~= worldValue then
        CachedBoosts = {}
        LastWorld = worldValue
        
        -- Предварительно сортируем бусты по значению
        for _, boost in pairs(worldFolder:GetChildren()) do
            if boost.PrimaryPart then
                local name = boost.Name
                local number = tonumber(name:match("%d+$")) or tonumber(name:sub(-1))
                if number then
                    table.insert(CachedBoosts, {boost = boost, value = number, name = name})
                end
            end
        end
        
        -- Сортируем по убыванию значения
        table.sort(CachedBoosts, function(a, b) 
            return a.value > b.value 
        end)
    end
    
    -- Сначала ищем приоритетные цели A_4, A_6, A_8, A_3
    for _, priority in ipairs(PriorityTargets) do
        for _, boostData in ipairs(CachedBoosts) do
            if boostData.boost.Parent and boostData.value == priority then
                return boostData.boost
            end
        end
    end
    
    -- Если приоритетные не найдены, возвращаем буст с наивысшим значением
    for _, boostData in ipairs(CachedBoosts) do
        if boostData.boost.Parent then
            return boostData.boost
        end
    end
    
    return nil
end

local function UltraFastTeleport(target)
    if not target or not target.PrimaryPart then 
        return false 
    end
    
    -- Обновляем ссылку на персонажа если нужно
    if not Character or not Character.Parent then
        Character = Player.Character
        if Character then
            HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        end
    end
    
    if not Character or not HumanoidRootPart then 
        return false 
    end
    
    -- Метод 1: PivotTo() - самый современный и быстрый метод
    pcall(function()
        Character:PivotTo(target.PrimaryPart.CFrame)
    end)
    
    -- Метод 2: Прямое изменение CFrame (резервный)
    pcall(function()
        HumanoidRootPart.CFrame = target.PrimaryPart.CFrame
    end)
    
    -- Метод 3: Полная остановка физики для мгновенности
    pcall(function()
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    
    return true
end

local function SuperFastCollect(boost)
    if not boost or not boost.PrimaryPart then 
        return 
    end
    
    -- Ультра-быстрая телепортация
    if not UltraFastTeleport(boost) then 
        return 
    end
    
    -- Агрессивная активация касания (как в No LIMIT strongest punch simulator)
    pcall(function()
        -- Множественная активация для максимальной надежности
        for i = 1, 5 do
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 0)
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 1)
        end
        
        -- Дополнительная активация через небольшую задержку
        wait(0.000)
        for i = 1, 3 do
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 0)
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 1)
        end
    end)
    
    return true
end

--// Ultra-Fast Main Loop (No LIMIT Style) \\--
spawn(function()
    while wait(Delay) do
        -- Проверяем персонажа один раз за итерацию
        if not Character or not Character.Parent then
            Character = Player.Character
            if Character then
                HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            end
        end
        
        local Current_World = Boosts[World.Value]
        
        if Current_World and HumanoidRootPart then
            -- Получаем оптимальный буст (кэшированный и отсортированный)
            local Collectable = GetOptimalBoost(Current_World)
            
            -- Собираем буст если найден
            if Collectable then
                SuperFastCollect(Collectable)
            end
        end
        
        -- Переход к следующей области
        if AutoTeleport then
            spawn(function()
                RemoteEvent:FireServer({
                    "WarpPlrToOtherMap", 
                    "Next"
                })
            end)
        end
    end
end)
