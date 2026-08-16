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

-- Coin-Cache
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
		if coin.Parent and coin:IsDescendantOf(workspace) then
			local offset = root.Position - coin.Position
			local distance = offset.Magnitude

			if distance < nearestDistance then
				nearestDistance = distance
				nearestCoin = coin
			end
		else
			-- Coin ist nicht mehr gültig
			coins[coin] = nil
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

	if player:GetAttribute("Alive") and root then

		local coin, distance = getNearestCoin(root)

		if coin then

			-- Prüfen, ob der Coin noch existiert
			if coin.Parent and coin:IsDescendantOf(workspace) then

				-- Position unmittelbar vor dem TP auslesen
				local coinPosition = coin.Position

				-- Zweite Prüfung direkt vor dem TP
				if coin.Parent and coin:IsDescendantOf(workspace) then

					root.CFrame = CFrame.new(coinPosition)

					task.wait(2)

					-- Nur entfernen, wenn der Coin noch existiert
					if coin.Parent and coin:IsDescendantOf(workspace) then
						coin:Destroy()
					end

					-- Bei 40 Coins sterben
					if getCoinCount() == TARGET_COINS then
						humanoid.Health = 0
					end
				else
					coins[coin] = nil
				end

			else
				-- Coin wurde inzwischen von jemand anderem entfernt
				coins[coin] = nil
			end
		end
	end
end
