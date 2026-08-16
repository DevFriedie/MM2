local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Anti-AFK
player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

local SPEED = 25
local MAX_DISTANCE = 100
local COIN_NAME = "Coin_Server"
local TARGET_COINS = 40

-- Rendering deaktivieren
RunService:Set3dRenderingEnabled(false)

-- Coin-Cache statt jedes Mal workspace:GetDescendants() komplett zu durchsuchen
local coins = {}

local function addCoin(instance)
	if instance:IsA("BasePart") and instance.Name == COIN_NAME then
		coins[instance] = true
	end
end

local function removeCoin(instance)
	coins[instance] = nil
end

-- Bereits vorhandene Coins erfassen
for _, instance in ipairs(workspace:GetDescendants()) do
	addCoin(instance)
end

-- Neue Coins automatisch erfassen
workspace.DescendantAdded:Connect(addCoin)
workspace.DescendantRemoving:Connect(removeCoin)


local function getNearestCoin(root)
	local nearestCoin = nil
	local nearestDistance = MAX_DISTANCE

	for coin in pairs(coins) do
		if coin.Parent then
			local offset = root.Position - coin.Position
			local distance = offset.Magnitude

			if distance < nearestDistance then
				nearestDistance = distance
				nearestCoin = coin
			end
		end
	end

	return nearestCoin, nearestDistance
end


local function getCoinCount()
	local mainGui = playerGui:FindFirstChild("MainGUI")
	if not mainGui then
		return nil
	end

	local gameGui = mainGui:FindFirstChild("Game")
	if not gameGui then
		return nil
	end

	local coinBags = gameGui:FindFirstChild("CoinBags")
	local container = coinBags and coinBags:FindFirstChild("Container")
	local coinGui = container and container:FindFirstChild("Coin")
	local currencyFrame = coinGui and coinGui:FindFirstChild("CurrencyFrame")
	local icon = currencyFrame and currencyFrame:FindFirstChild("Icon")
	local coinText = icon and icon:FindFirstChild("Coins")

	if coinText and coinText:IsA("TextLabel") then
		-- Funktioniert auch bei Text wie "40/50"
		return tonumber(coinText.Text:match("%d+"))
	end

	return nil
end


local function getCharacter()
	local character = player.Character

	if not character then
		return nil, nil, nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil, nil
	end

	return character, root, humanoid
end


while task.wait(0.1) do
	local character, root, humanoid = getCharacter()

	if not root then
		continue
	end

	local coin, distance = getNearestCoin(root)

	if not coin then
		continue
	end

	-- Coin könnte zwischen Suche und Tween verschwunden sein
	if not coin.Parent then
		coins[coin] = nil
		continue
	end

	local duration = math.max(distance / SPEED, 0.05)

	local tween = TweenService:Create(
		root,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{
			CFrame = CFrame.new(coin.Position)
		}
	)

	tween:Play()
	tween.Completed:Wait()

	-- Prüfen, ob der Charakter während des Tweens gestorben ist
	if not humanoid.Parent or humanoid.Health <= 0 then
		tween:Cancel()
		continue
	end

	-- Coin entfernen
	if coin.Parent then
		coin:Destroy()
	end

	-- Bei 40 Coins sterben
	if getCoinCount() == TARGET_COINS then
		humanoid.Health = 0
	end
end
