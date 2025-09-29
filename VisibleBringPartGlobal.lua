-- BERLIAN_SUPER_GLOBAL_BRINGPART (GitHub-ready 1 file)
-- GUI + RemoteEvent + server logic dalam 1 file
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ===== RemoteEvent =====
local event = ReplicatedStorage:FindFirstChild("BerlianBringPartEvent")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "BerlianBringPartEvent"
    event.Parent = ReplicatedStorage
end

-- ===== Default Settings =====
local RADIUS = 500
local STRENGTH = 250000
local ACTIVE = false
local MAX_PARTS = 150

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "BERLIAN_BRINGPART_PANEL"
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0,250,0,200)
panel.Position = UDim2.new(0.5,-125,0.3,-100)
panel.BackgroundColor3 = Color3.fromRGB(20,20,40)
panel.Active = true
panel.Draggable = true
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "BERLIAN_BRINGPART"
title.TextColor3 = Color3.fromRGB(0,200,255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

local button = Instance.new("TextButton")
button.Size = UDim2.new(0,200,0,40)
button.Position = UDim2.new(0.5,-100,0.15,0)
button.BackgroundColor3 = Color3.fromRGB(0,100,255)
button.TextColor3 = Color3.new(1,1,1)
button.TextScaled = true
button.Text = "OFF"
button.Font = Enum.Font.GothamBold
button.Parent = panel

button.MouseButton1Click:Connect(function()
    ACTIVE = not ACTIVE
    button.Text = ACTIVE and "ON" or "OFF"
    if ACTIVE then
        event:FireServer("ON", RADIUS, STRENGTH)
    else
        event:FireServer("OFF")
    end
end)

local function createSlider(labelText, defaultValue, yPos, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,100,0,20)
    label.Position = UDim2.new(0.05,0,yPos,0)
    label.BackgroundTransparency = 1
    label.Text = labelText.." "..defaultValue
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.Parent = panel

    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(0,120,0,25)
    slider.Position = UDim2.new(0.5,0,yPos,0)
    slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    slider.TextColor3 = Color3.new(1,1,1)
    slider.Text = tostring(defaultValue)
    slider.ClearTextOnFocus = false
    slider.Font = Enum.Font.Gotham
    slider.TextScaled = true
    slider.Parent = panel

    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            callback(val)
            label.Text = labelText.." "..val
            if ACTIVE then
                event:FireServer("UPDATE", RADIUS, STRENGTH)
            end
        end
    end)
end

createSlider("Radius:", RADIUS, 0.35, function(val) RADIUS = val end)
createSlider("Strength:", STRENGTH, 0.55, function(val) STRENGTH = val end)

-- ===== Server logic (fungsi global) =====
if RunService:IsServer() then
    local activePlayers = {}
    event.OnServerEvent:Connect(function(player, action, radius, strength)
        if action == "ON" then
            activePlayers[player] = {Radius = radius or 500, Strength = strength or 250000}
        elseif action == "OFF" then
            activePlayers[player] = nil
        elseif action == "UPDATE" then
            if activePlayers[player] then
                activePlayers[player].Radius = radius or activePlayers[player].Radius
                activePlayers[player].Strength = strength or activePlayers[player].Strength
            end
        end
    end)

    local function applyForce(part, centerPos, strength)
        if part.Anchored then
            part.Anchored = false
        end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e14,1e14,1e14)
        bv.Velocity = (centerPos - part.Position).unit * strength
        bv.P = 1e5
        bv.Name = "BERLIAN_PULL_FORCE"
        bv.Parent = part
        Debris:AddItem(bv,0.5)
    end

    RunService.Heartbeat:Connect(function()
        for player,data in pairs(activePlayers) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local centerPos = char.HumanoidRootPart.Position
                local radius = data.Radius
                local strength = data.Strength

                local parts = {}
                for _,obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj:IsDescendantOf(char) then
                        if (obj.Position - centerPos).magnitude <= radius then
                            table.insert(parts,obj)
                        end
                    end
                end

                for i=1,math.min(#parts,MAX_PARTS) do
                    applyForce(parts[i], centerPos, strength)
                end
            end
        end
    end)
end
