--[[
    [EXECUTOR SCRIPT] Auto-Buy & Auto-Drink Hub (UI Included)
    Target Items:
      1. Locked Reroll Scroll (ซื้ออย่างเดียว)
      2. Luck Potion (ซื้อ + กด Drink ในกระเป๋าอัตโนมัติ)
      3. Coins Potion (ซื้อ + กด Drink ในกระเป๋าอัตโนมัติ)
]]

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ป้องกันรันซ้ำแล้วหน้าต่างซ้อนกัน
if getgenv().ProPotionHubLoaded then
	pcall(function()
		CoreGui:FindFirstChild("ProPotionHubUI"):Destroy()
	end)
end
getgenv().ProPotionHubLoaded = true

-- ตั้งค่าการทำงาน (ปรับชื่อ Remote ให้ตรงกับแมพที่รัน)
local Settings = {
	MasterEnabled = false,
	LoopDelay = 0.5,
	DrinkDelay = 0.25,

	-- เปลี่ยนชื่อ Remote ตรงนี้ให้ตรงกับที่ดักได้จาก Remote Spy ของแมพ
	BuyRemoteName = "BuyShopItem",
	DrinkRemoteName = "UseItem",

	Items = {
		{ Name = "Locked Reroll Scroll", Enabled = true, AutoDrink = false },
		{ Name = "Luck Potion",          Enabled = true, AutoDrink = true },
		{ Name = "Coins Potion",         Enabled = true, AutoDrink = true }
	}
}

getgenv().ProPotionSettings = Settings

-- ค้นหา RemoteEvent หรือ RemoteFunction ทั้งใน ReplicatedStorage
local function findRemoteByName(remoteName: string): Instance?
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj.Name == remoteName and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
			return obj
		end
	end
	return nil
end

local function fireRemote(remote: Instance?, args: {any}): boolean
	if not remote then return false end
	local ok = pcall(function()
		if remote:IsA("RemoteEvent") then
			remote:FireServer(unpack(args))
		elseif remote:IsA("RemoteFunction") then
			remote:InvokeServer(unpack(args))
		end
	end)
	return ok
end

-- สร้างหน้าต่าง UI โปรบนหน้าจอ (ใส่ใน CoreGui หรือ PlayerGui)
local parentGui = (gethui and gethui()) or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProPotionHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 235)
MainFrame.Position = UDim2.new(0.5, -130, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- ลากย้ายหน้าต่างบนจอได้
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 195, 0)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 34)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "AUTO BUY & DRINK HUB"
Title.TextColor3 = Color3.fromRGB(255, 210, 40)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 36)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: IDLE (กดปุ่มด้านล่างเพื่อเริ่ม)"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- สร้างปุ่มเปิด-ปิดแยกตามแต่ละไอเทม
for index, item in ipairs(Settings.Items) do
	local rowBtn = Instance.new("TextButton")
	rowBtn.Size = UDim2.new(1, -20, 0, 32)
	rowBtn.Position = UDim2.new(0, 10, 0, 62 + ((index - 1) * 38))
	rowBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	rowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rowBtn.Font = Enum.Font.GothamSemibold
	rowBtn.TextSize = 12
	rowBtn.Text = string.format("[ON] %s %s", item.Name, item.AutoDrink and "(+Drink)" or "")
	rowBtn.Parent = MainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = rowBtn

	rowBtn.MouseButton1Click:Connect(function()
		item.Enabled = not item.Enabled
		rowBtn.Text = string.format(
			"[%s] %s %s",
			item.Enabled and "ON" or "OFF",
			item.Name,
			item.AutoDrink and "(+Drink)" or ""
		)
		rowBtn.TextColor3 = item.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	end)
end

-- ปุ่มหลัก START / STOP
local MasterBtn = Instance.new("TextButton")
MasterBtn.Size = UDim2.new(1, -20, 0, 36)
MasterBtn.Position = UDim2.new(0, 10, 1, -46)
MasterBtn.BackgroundColor3 = Color3.fromRGB(45, 170, 80)
MasterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterBtn.Font = Enum.Font.GothamBold
MasterBtn.TextSize = 13
MasterBtn.Text = "START AUTO-BUY"
MasterBtn.Parent = MainFrame

local masterCorner = Instance.new("UICorner")
masterCorner.CornerRadius = UDim.new(0, 8)
masterCorner.Parent = MasterBtn

MasterBtn.MouseButton1Click:Connect(function()
	Settings.MasterEnabled = not Settings.MasterEnabled
	if Settings.MasterEnabled then
		MasterBtn.Text = "STOP AUTO-BUY"
		MasterBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
		StatusLabel.Text = "Status: RUNNING..."
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
	else
		MasterBtn.Text = "START AUTO-BUY"
		MasterBtn.BackgroundColor3 = Color3.fromRGB(45, 170, 80)
		StatusLabel.Text = "Status: STOPPED"
		StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	end
end)

-- ลูปการทำงานหลักของตัวรัน
task.spawn(function()
	while getgenv().ProPotionHubLoaded do
		if Settings.MasterEnabled then
			local buyRemote = findRemoteByName(Settings.BuyRemoteName)
			local drinkRemote = findRemoteByName(Settings.DrinkRemoteName)

			if not buyRemote then
				StatusLabel.Text = "Status: ไม่พบ Remote '" .. Settings.BuyRemoteName .. "'"
				StatusLabel.TextColor3 = Color3.fromRGB(255, 190, 70)
			else
				StatusLabel.Text = "Status: กำลังซื้อ & ดื่มอัตโนมัติ..."
				StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 140)

				for _, item in ipairs(Settings.Items) do
					if not Settings.MasterEnabled then break end
					if item.Enabled then
						local bought = fireRemote(buyRemote, { item.Name, 1 })
						if bought and item.AutoDrink and drinkRemote then
							task.wait(Settings.DrinkDelay)
							fireRemote(drinkRemote, { item.Name, 1 })
						end
						task.wait(0.15)
					end
				end
			end
		end
		task.wait(Settings.LoopDelay)
	end
end)
