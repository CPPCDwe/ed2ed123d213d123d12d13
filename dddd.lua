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

local function FastTeleport(target)
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
    
    -- Мгновенная телепортация без анимации
    local targetCFrame = target.PrimaryPart.CFrame
    HumanoidRootPart.CFrame = targetCFrame
    
    -- Принудительное обновление позиции
    HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    return true
end

local function CollectBoost(boost)
    if not boost or not boost.PrimaryPart then 
        return 
    end
    
    -- Быстрая телепортация
    if not FastTeleport(boost) then 
        return 
    end
    
    -- Мгновенная активация касания
    local success = pcall(function()
        firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 0)
        firetouchinterest(HumanoidRootPart, boost.PrimaryPart, 1)
    end)
    
    return success
end

--// Optimized Main Loop \\--
while wait(Delay) do
    local Current_World = Boosts[World.Value]
    
    if Current_World then
        -- Получаем оптимальный буст (кэшированный и отсортированный)
        local Collectable = GetOptimalBoost(Current_World)
        
        -- Собираем буст если найден
        if Collectable then
            CollectBoost(Collectable)
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
