local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Crear la Interfaz (GUI)
local gui = Instance.new("ScreenGui")
gui.Name = "CustomShiftLockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true -- Clave para ignorar la barra superior de Roblox en celulares y PC
gui.Parent = player:WaitForChild("PlayerGui")

-- Botón de Candado (Esquina inferior derecha)
local lockBtn = Instance.new("ImageButton")
lockBtn.Size = UDim2.new(0, 50, 0, 50)
lockBtn.Position = UDim2.new(1, -70, 1, -200)
lockBtn.Image = "rbxassetid://7733658504"
lockBtn.BackgroundTransparency = 1
lockBtn.Parent = gui

-- Imagen del centro (Retícula perfectamente adaptada a cualquier pantalla)
local centerImage = Instance.new("ImageLabel")
centerImage.Size = UDim2.new(0, 0, 0, 0) -- Inicia cerrada
centerImage.AnchorPoint = Vector2.new(0.5, 0.5) -- Centro exacto de la imagen
centerImage.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centro exacto de la pantalla
centerImage.Image = "rbxassetid://10942997895" -- Tu ID solicitado
centerImage.ImageTransparency = 1 
centerImage.Rotation = -90 
centerImage.BackgroundTransparency = 1
centerImage.Parent = gui

-- Variables de estado
local isShiftLocked = false
local currentHumanoid = nil

-- Variables para evitar el "latigazo" de la cámara
local framesToFix = 0
local savedRotation = CFrame.new()

-- Configuración de Tweens (Animaciones)
local tweenInfoUI = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoCam = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local tweenIn = TweenService:Create(centerImage, tweenInfoUI, {
	Size = UDim2.new(0, 40, 0, 40), -- Tamaño final de la retícula
	ImageTransparency = 0,
	Rotation = 0
})

local tweenOut = TweenService:Create(centerImage, tweenInfoUI, {
	Size = UDim2.new(0, 0, 0, 0),
	ImageTransparency = 1,
	Rotation = 90
})

-- Función principal
local function toggleShiftLock()
	isShiftLocked = not isShiftLocked

	local camera = workspace.CurrentCamera
	savedRotation = camera.CFrame.Rotation
	framesToFix = 2 

	if isShiftLocked then
		tweenIn:Play()
		if currentHumanoid then
			TweenService:Create(currentHumanoid, tweenInfoCam, {CameraOffset = Vector3.new(1.75, 0, 0)}):Play()
		end
	else
		tweenOut:Play()
		if currentHumanoid then
			TweenService:Create(currentHumanoid, tweenInfoCam, {CameraOffset = Vector3.new(0, 0, 0)}):Play()
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

lockBtn.MouseButton1Click:Connect(toggleShiftLock)

-- Mantener la cámara estable y el mouse bloqueado al centro
RunService:BindToRenderStep("CustomShiftLockUpdate", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera

	if framesToFix > 0 then
		camera.CFrame = CFrame.new(camera.CFrame.Position) * savedRotation
		framesToFix -= 1
	end

	if isShiftLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

-- Actualizar el personaje al reaparecer
local function onCharacterAdded(character)
	currentHumanoid = character:WaitForChild("Humanoid")
	if isShiftLocked then
		currentHumanoid.CameraOffset = Vector3.new(1.75, 0, 0)
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Activar con teclado (Cualquier Shift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		toggleShiftLock()
	end
end)
