local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local VirtualUser = game:service'VirtualUser'

local player = Players.LocalPlayer

local collectedcoins = 0

local SPEED = 15
local MAX_DISTANCE = 100

local function getNearestCoin(root)
    local nearestCoin = nil
    local nearestDistance = MAX_DISTANCE

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "Coin_Server" then
            local distance = (root.Position - v.Position).Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearestCoin = v
            end
        end
    end

    return nearestCoin, nearestDistance
end

game:GetService("RunService"):Set3dRenderingEnabled(false)

while task.wait(0.1) do
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")

    if root and humanoid then
        local coin, distance = getNearestCoin(root)

        if coin then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            
            local duration = distance / SPEED

            local tween = TweenService:Create(
                root,
                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Linear
                ),
                {
                    CFrame = CFrame.new(coin.Position)
                }
            )

            tween:Play()
            tween.Completed:Wait()
            coin:Remove()
            collectedcoins += 1
            if collectedcoins == 40 then
                collectedcoins = 0
                humanoid:TakeDamage(10000000000000)
            end
        end
    end
end
