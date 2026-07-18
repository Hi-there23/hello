local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

-- ==========================================
-- 1. CREACIÓN DE LA INTERFAZ (GUI)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HabilidadesGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 100, 0, 50)
frame.Position = UDim2.new(0.5, -50, 0.8, 0)
frame.BackgroundTransparency = 1
frame.Parent = screenGui

local function crearBoton(nombre, texto, posicion)
	local btn = Instance.new("TextButton")
	btn.Name = nombre
	btn.Text = texto
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.Position = posicion
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 18
	btn.Parent = frame
	return btn
end

local chaosDashBtn = crearBoton("ChaosDashButton", "Chaos Dash", UDim2.new(0, 0, 0, 0))

local barraVueloBg = Instance.new("Frame")
barraVueloBg.Name = "BarraVueloBg"
barraVueloBg.Size = UDim2.new(0, 200, 0, 15)
barraVueloBg.Position = UDim2.new(0.5, -100, 0.85, 0)
barraVueloBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
barraVueloBg.BorderSizePixel = 2
barraVueloBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
barraVueloBg.BackgroundTransparency = 1 
barraVueloBg.Parent = screenGui

local barraVueloFill = Instance.new("Frame")
barraVueloFill.Name = "BarraVueloFill"
barraVueloFill.Size = UDim2.new(1, 0, 1, 0)
barraVueloFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barraVueloFill.BorderSizePixel = 0
barraVueloFill.BackgroundTransparency = 1 
barraVueloFill.Parent = barraVueloBg


-- ==========================================
-- 2. VARIABLES GLOBALES Y UTILIDADES
-- ==========================================
local isHabilidadActiva = false 
local chaosDashEnCooldown = false

local CHAOS_ANIM_ID = "http://www.roblox.com/asset/?id=18537367238" 

player.CharacterAdded:Connect(function()
	isHabilidadActiva = false
end)

local function manejarCooldown(boton, tiempo, textoOriginal)
	task.spawn(function()
		for i = tiempo, 1, -1 do
			boton.Text = tostring(i)
			task.wait(1)
		end
		boton.Text = textoOriginal
		chaosDashEnCooldown = false
	end)
end

-- ==========================================
-- 3. LÓGICA DEL VUELO LIBRE (TOGGLE)
-- ==========================================
local isVolando = false
local energiaVueloMax = 150
local energiaVueloActual = 150

local regenPorSegundo = 2 
local velocidadVueloLibre = 55 
local tiempoSinVolar = 0 
local finCooldownVuelo = 0 -- Variable para controlar los 7 segundos de castigo

local isBarraVisible = false
local tweenInfoFade = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function actualizarFadeBarra(mostrar)
	if mostrar and not isBarraVisible then
		isBarraVisible = true
		TweenService:Create(barraVueloBg, tweenInfoFade, {BackgroundTransparency = 0}):Play()
		TweenService:Create(barraVueloBg, tweenInfoFade, {BorderColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		TweenService:Create(barraVueloFill, tweenInfoFade, {BackgroundTransparency = 0}):Play()
	elseif not mostrar and isBarraVisible then
		isBarraVisible = false
		TweenService:Create(barraVueloBg, tweenInfoFade, {BackgroundTransparency = 1}):Play()
		TweenService:Create(barraVueloBg, tweenInfoFade, {BorderColor3 = Color3.fromRGB(20, 20, 20)}):Play()
		TweenService:Create(barraVueloFill, tweenInfoFade, {BackgroundTransparency = 1}):Play()
	end
end

local function empezarVueloNormal(rootPart, humanoid)
	-- Bloqueamos el inicio del vuelo si está en cooldown de agotamiento
	if isVolando or energiaVueloActual <= 0 or isHabilidadActiva or os.clock() < finCooldownVuelo then return end

	isVolando = true
	tiempoSinVolar = 0

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local attachment = Instance.new("Attachment")
	attachment.Name = "VueloNormalAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "VueloNormalVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(100000, 100000, 100000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = rootPart.AssemblyLinearVelocity 
	linearVelocity.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "VueloNormalGyro"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = 100000
	alignOrientation.Responsiveness = 80 
	alignOrientation.Parent = rootPart
end

local function terminarVueloNormal(rootPart, humanoid)
	if not isVolando then return end
	isVolando = false

	if rootPart then
		local att = rootPart:FindFirstChild("VueloNormalAtt")
		if att then att:Destroy() end
		local vel = rootPart:FindFirstChild("VueloNormalVel")
		if vel then vel:Destroy() end
		local gyro = rootPart:FindFirstChild("VueloNormalGyro")
		if gyro then gyro:Destroy() end
	end

	if humanoid and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and humanoid.Health > 0 then
				if isVolando then
					terminarVueloNormal(rootPart, humanoid)
				elseif humanoid.FloorMaterial == Enum.Material.Air and not isHabilidadActiva then
					empezarVueloNormal(rootPart, humanoid)
				end
			end
		end
	end
end)


-- ==========================================
-- 4. BUCLE PRINCIPAL (MANEJO DE ENERGÍA Y VUELO LIBRE)
-- ==========================================
RunService.RenderStepped:Connect(function(deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- 1. Manejo de Energía y Físicas
	if isVolando then
		tiempoSinVolar = 0

		local vel = rootPart:FindFirstChild("VueloNormalVel")
		local gyro = rootPart:FindFirstChild("VueloNormalGyro")

		if vel and gyro then
			local moveVector = Controls:GetMoveVector()
			local direccionDeseada = (camera.CFrame.RightVector * moveVector.X) + (camera.CFrame.LookVector * -moveVector.Z)

			local seEstaMoviendo = direccionDeseada.Magnitude > 0.01

			if seEstaMoviendo then
				direccionDeseada = direccionDeseada.Unit
			end

			local gastoActual = seEstaMoviendo and 15 or 5
			energiaVueloActual = math.max(0, energiaVueloActual - (gastoActual * deltaTime))

			-- Si se acaba la energía, aplicamos los 7 segundos de cooldown
			if energiaVueloActual <= 0 then
				finCooldownVuelo = os.clock() + 7
				terminarVueloNormal(rootPart, humanoid)
			end

			vel.VectorVelocity = vel.VectorVelocity:Lerp(direccionDeseada * velocidadVueloLibre, 0.1)

			if seEstaMoviendo then
				gyro.CFrame = CFrame.lookAt(Vector3.zero, direccionDeseada)
			else
				local lookActual = gyro.CFrame.LookVector
				local lookPlano = Vector3.new(lookActual.X, 0, lookActual.Z)
				if lookPlano.Magnitude > 0.01 then
					gyro.CFrame = CFrame.lookAt(Vector3.zero, lookPlano.Unit)
				end
			end
		end
	else
		-- Verificamos si ya pasaron los 7 segundos de castigo
		if os.clock() >= finCooldownVuelo then
			tiempoSinVolar = tiempoSinVolar + deltaTime
			if energiaVueloActual < energiaVueloMax then
				energiaVueloActual = math.min(energiaVueloMax, energiaVueloActual + (regenPorSegundo * deltaTime))
			end
		else
			-- Mantenemos tiempoSinVolar en 0 para que la barra no desaparezca mientras está vacía
			tiempoSinVolar = 0 
		end
	end

	-- 2. Visuales de la Barra (Lerp y Fade por inactividad)
	local porcentajeEnergia = energiaVueloActual / energiaVueloMax
	barraVueloFill.Size = barraVueloFill.Size:Lerp(UDim2.new(porcentajeEnergia, 0, 1, 0), 0.15)

	if tiempoSinVolar < 2 then
		actualizarFadeBarra(true)
	else
		actualizarFadeBarra(false)
	end
end)


-- ==========================================
-- 5. LÓGICA DEL CHAOS DASH
-- ==========================================
local isChaosDashing = false

local tiempoCarga = 1.5 
local velocidadRetroceso = 7.9 
local velocidadImpulsoMax = 550 
local velocidadImpulsoMin = 230 
local tiempoVuelo = 5.8 
local tiempoCooldown = 35 
local velocidadLerp = 0.08 

chaosDashBtn.MouseButton1Click:Connect(function()
	if isHabilidadActiva or chaosDashEnCooldown then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	if isVolando then
		terminarVueloNormal(rootPart, humanoid)
	end

	isHabilidadActiva = true
	isChaosDashing = true

	local renderSteppedConnection
	local animTrack
	local deathConnection
	local faseActual = "carga" 
	local inicioVuelo = 0 

	local cframeActual = rootPart.CFrame 

	local function finalizarChaosDash()
		if not isChaosDashing then return end

		isChaosDashing = false
		isHabilidadActiva = false 

		if renderSteppedConnection then renderSteppedConnection:Disconnect() end
		if animTrack then animTrack:Stop() end
		if deathConnection then deathConnection:Disconnect() end

		if rootPart then
			local att = rootPart:FindFirstChild("ChaosDashAtt")
			if att then att:Destroy() end
			local vel = rootPart:FindFirstChild("ChaosDashVel")
			if vel then vel:Destroy() end
			local gyro = rootPart:FindFirstChild("ChaosDashGyro")
			if gyro then gyro:Destroy() end
		end

		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		chaosDashEnCooldown = true
		manejarCooldown(chaosDashBtn, tiempoCooldown, "Chaos Dash")
	end

	deathConnection = humanoid.Died:Connect(function()
		finalizarChaosDash()
	end)

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local animacion = Instance.new("Animation")
	animacion.AnimationId = CHAOS_ANIM_ID
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animTrack = animator:LoadAnimation(animacion)
		animTrack:Play()
	end

	if rootPart:FindFirstChild("ChaosDashAtt") then rootPart.ChaosDashAtt:Destroy() end
	if rootPart:FindFirstChild("ChaosDashVel") then rootPart.ChaosDashVel:Destroy() end
	if rootPart:FindFirstChild("ChaosDashGyro") then rootPart.ChaosDashGyro:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "ChaosDashAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "ChaosDashVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(100000, 100000, 100000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "ChaosDashGyro"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = 100000
	alignOrientation.Responsiveness = 200 
	alignOrientation.Parent = rootPart

	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		cframeActual = cframeActual:Lerp(camera.CFrame, velocidadLerp)
		local lookVectorSuavizado = cframeActual.LookVector

		if faseActual == "carga" then
			linearVelocity.VectorVelocity = -lookVectorSuavizado * velocidadRetroceso
		elseif faseActual == "vuelo" then
			local tiempoTranscurrido = os.clock() - inicioVuelo
			local progreso = math.clamp(tiempoTranscurrido / tiempoVuelo, 0, 1)
			local velocidadActual = velocidadImpulsoMax - ((velocidadImpulsoMax - velocidadImpulsoMin) * progreso)
			linearVelocity.VectorVelocity = lookVectorSuavizado * velocidadActual
		end

		alignOrientation.CFrame = cframeActual
	end)

	task.delay(tiempoCarga, function()
		if not isChaosDashing then return end
		faseActual = "vuelo"
		inicioVuelo = os.clock()

		task.delay(tiempoVuelo, function()
			finalizarChaosDash()
		end)
	end)
end)
