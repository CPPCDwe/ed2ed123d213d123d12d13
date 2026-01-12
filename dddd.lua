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
                    table.insert(CachedBoosts, {boost = boost, value = number})
                end
            end
        end
        
        -- Сортируем по убыванию значения
        table.sort(CachedBoosts, function(a, b) 
            return a.value > b.value 
        end)
    end
    
    -- Возвращаем первый доступный буст (с наивысшим значением)
    for _, boostData in ipairs(CachedBoosts) do
        if boostData.boost.Parent then
            return boostData.boost
        end
    end
    
    return nil
end

local function InstantTeleport(target)
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
    
    if not HumanoidRootPart then 
        return false 
    end
    
    -- Отключаем физику для мгновенной телепортации
    HumanoidRootPart.Anchored = true
    
    -- Мгновенная телепортация
    local targetCFrame = target.PrimaryPart.CFrame
    HumanoidRootPart.CFrame = targetCFrame
    
    -- Полная остановка движения
    HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    -- Принудительное обновление сети
    RunService.Heartbeat:Wait()
    
    -- Включаем физику обратно
    HumanoidRootPart.Anchored = false
    
    return true
end

local function InstantCollect(boost)
    if not boost or not boost.PrimaryPart then 
        return 
    end
    
    -- Мгновенная телепортация
    if not InstantTeleport(boost) then 
        return 
    end
    
    -- Немедленная активация касания без задержек
    pcall(function()
        -- Множественная активация для гарантии
        for i = 1, 3 do
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 0)
            firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 1)
        end
    end)
    
    return true
end

--// Ultra-Fast Main Loop \\--
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
            InstantCollect(Collectable)
        end
    end
    
    -- Переход к следующей области
    if AutoTeleport then
        RemoteEvent:FireServer({
            "WarpPlrToOtherMap", 
            "Next"
        })
    end
end
