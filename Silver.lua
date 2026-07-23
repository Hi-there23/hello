-- ====================================================================
-- SCRIPT COMPLETO DEFINITIVO: VUELO, MOVIMIENTO, HABILIDADES Y CANCELAR REVERSAL
-- ====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()
local Camera = Workspace.CurrentCamera
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- --- CONFIGURACIÓN DE PARÁMETROS SOLICITADOS ---
local VELOCIDAD_CAMINAR = 5
local VELOCIDAD_CORRER = 18.5
local ALTURA_MINIMA_VOLTERETA = 25.5 

-- --- IDS OFICIALES DE CATÁLOGO / ANIMACIONES ---
local ID_CATALOGO_OFICIAL = 18537367238 
local ID_ANIMACION_VUELO = 85232146719894

-- Configuración de Habilidades
local maxEnergy = 100
local currentEnergy = maxEnergy
local ENERGY_REGEN_PER_SECOND = 2
local tweenCooldown = 0 

local cooldownReversal = 0
local cooldownVelocidad = 0
local MAX_COOLDOWN_REVERSAL = 26
local MAX_COOLDOWN_VELOCIDAD = 30

-- Estados Globales
local esSprinting = false
local isSpeedBoosting = false

-- Carpeta de fantasmas para Reversal
local ghostFolder = workspace:FindFirstChild("TimeReversalGhosts")
if not ghostFolder then
	ghostFolder = Instance.new("Folder")
	ghostFolder.Name = "TimeReversalGhosts"
	ghostFolder.Parent = workspace
end

-- Objeto de Animación de Vuelo
local animVueloObj = Instance.new("Animation")
animVueloObj.AnimationId = "rbxassetid://" .. tostring(ID_ANIMACION_VUELO)
local trackVueloActual = nil

-- ==========================================
-- INTERFAZ GRÁFICA UNIFICADA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2MovilPerfeccionado"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- --- INTERFAZ TÁCTIL PRINCIPAL: BOTÓN CORRER ---
local RunButton = Instance.new("TextButton")
RunButton.Parent = ScreenGui
RunButton.Size = UDim2.new(0, 75, 0, 75)
RunButton.Position = UDim2.new(0.80, 0, 0.55, 0) 
RunButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
RunButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RunButton.TextSize = 13
RunButton.Text = "CORRER"
RunButton.Font = Enum.Font.SourceSansBold
RunButton.Active = true
RunButton.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 50)
UICorner.Parent = RunButton

-- --- INDICADOR APARTADO: CANDADO EMOJI ---
local LockLabel = Instance.new("TextLabel")
LockLabel.Parent = ScreenGui
LockLabel.Size = UDim2.new(0, 24, 0, 24)
LockLabel.BackgroundTransparency = 1
LockLabel.Text = "🔒"
LockLabel.TextSize = 18
LockLabel.Visible = false 

RunService.RenderStepped:Connect(function()
	if RunButton and LockLabel then
		LockLabel.Position = UDim2.new(RunButton.Position.X.Scale, RunButton.Position.X.Offset + 50, RunButton.Position.Y.Scale, RunButton.Position.Y.Offset - 22)
	end
end)

-- --- BOTONES DE HABILIDADES ---
local botonImpulso = Instance.new("TextButton")
botonImpulso.Size = UDim2.new(0, 140, 0, 50)
botonImpulso.Position = UDim2.new(0.5, -150, 0.85, -25) 
botonImpulso.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
botonImpulso.Text = "Time Reversal"
botonImpulso.TextColor3 = Color3.fromRGB(255, 255, 255)
botonImpulso.Font = Enum.Font.SourceSansBold
botonImpulso.TextSize = 20
botonImpulso.BorderSizePixel = 0
botonImpulso.Parent = ScreenGui

-- NUEVO: BOTÓN CANCELAR REVERSAL (Oculto por defecto)
local botonCancelarReversal = Instance.new("TextButton")
botonCancelarReversal.Size = UDim2.new(0, 140, 0, 30)
botonCancelarReversal.Position = UDim2.new(0.5, -150, 0.85, -95) -- Posicionado justo encima de la barra de energía
botonCancelarReversal.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
botonCancelarReversal.Text = "Cancelar"
botonCancelarReversal.TextColor3 = Color3.fromRGB(255, 255, 255)
botonCancelarReversal.Font = Enum.Font.SourceSansBold
botonCancelarReversal.TextSize = 18
botonCancelarReversal.BorderSizePixel = 0
botonCancelarReversal.Visible = false
botonCancelarReversal.Parent = ScreenGui

local botonVelocidad = Instance.new("TextButton")
botonVelocidad.Size = UDim2.new(0, 140, 0, 50)
botonVelocidad.Position = UDim2.new(0.5, 10, 0.85, -25) 
botonVelocidad.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
botonVelocidad.Text = "Speed Boost"
botonVelocidad.TextColor3 = Color3.fromRGB(255, 255, 255)
botonVelocidad.Font = Enum.Font.SourceSansBold
botonVelocidad.TextSize = 20
botonVelocidad.BorderSizePixel = 0
botonVelocidad.Parent = ScreenGui

-- --- BARRA DE ENERGÍA ---
local energyBg = Instance.new("Frame")
energyBg.Size = UDim2.new(0, 300, 0, 15)
energyBg.Position = UDim2.new(0.5, -150, 0.85, -50)
energyBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
energyBg.BorderSizePixel = 0
energyBg.Parent = ScreenGui

local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(1, 0); bgCorner.Parent = energyBg
local energyFill = Instance.new("Frame"); energyFill.Size = UDim2.new(1, 0, 1, 0); energyFill.BackgroundColor3 = Color3.fromRGB(0, 100, 255); energyFill.BorderSizePixel = 0; energyFill.Parent = energyBg
local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1, 0); fillCorner.Parent = energyFill

local energyText = Instance.new("TextLabel")
energyText.Size = UDim2.new(1, 0, 1, 0); energyText.BackgroundTransparency = 1; energyText.Text = "100"; energyText.TextColor3 = Color3.fromRGB(255, 255, 255); energyText.TextStrokeTransparency = 0.5; energyText.Font = Enum.Font.SourceSansBold; energyText.TextSize = 14; energyText.ZIndex = 2; energyText.Parent = energyBg

-- --- BARRA DE VUELO ---
local barraVueloBg = Instance.new("Frame")
barraVueloBg.Size = UDim2.new(0, 200, 0, 15)
barraVueloBg.Position = UDim2.new(0.5, -100, 0.68, 0)
barraVueloBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
barraVueloBg.BorderSizePixel = 2
barraVueloBg.BorderColor3 = Color3.fromRGB(0, 0, 0)
barraVueloBg.BackgroundTransparency = 1 
barraVueloBg.Parent = ScreenGui

local barraVueloFill = Instance.new("Frame")
barraVueloFill.Size = UDim2.new(1, 0, 1, 0)
barraVueloFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barraVueloFill.BorderSizePixel = 0
barraVueloFill.BackgroundTransparency = 1 
barraVueloFill.Parent = barraVueloBg


-- ==========================================
-- SISTEMA DE MOVIMIENTO REPARADO Y BUFERS
-- ==========================================
local function configurarPersonaje(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = VELOCIDAD_CAMINAR

	task.spawn(function()
		local factorSuavizadoMovimiento = 0.8
		while character and character.Parent and humanoid and humanoid.Health > 0 do
			local baseSpeed = esSprinting and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR
			local velocidadObjetivo = isSpeedBoosting and (baseSpeed * 1.30) or baseSpeed

			if math.abs(humanoid.WalkSpeed - velocidadObjetivo) > 0.05 then
				humanoid.WalkSpeed = humanoid.WalkSpeed + (velocidadObjetivo - humanoid.WalkSpeed) * factorSuavizadoMovimiento
			else
				humanoid.WalkSpeed = velocidadObjetivo
			end
			task.wait(0.02)
		end
	end)

	local animateScript = character:WaitForChild("Animate", 5)
	if animateScript then
		pcall(function()
			local idCaminataOriginal = animateScript.walk.WalkAnim.AnimationId
			local idCarreraOriginal = animateScript.run.RunAnim.AnimationId
			animateScript.walk.WalkAnim.AnimationId = idCaminataOriginal 
			animateScript.run.RunAnim.AnimationId = idCarreraOriginal   
		end)
	end
end

local manteniendoBoton = false
local botonFijadoEnPantalla = false

RunButton.MouseButton1Down:Connect(function()
	manteniendoBoton = true
	local tiempoInicial = os.clock()

	task.spawn(function()
		while manteniendoBoton do
			if (os.clock() - tiempoInicial) >= 1.5 then
				botonFijadoEnPantalla = not botonFijadoEnPantalla
				RunButton.Draggable = not botonFijadoEnPantalla 
				LockLabel.Visible = botonFijadoEnPantalla
				manteniendoBoton = false
				break
			end
			task.wait(0.1)
		end
	end)
end)

RunButton.MouseButton1Up:Connect(function()
	if manteniendoBoton then
		manteniendoBoton = false
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if not esSprinting then
				esSprinting = true
				RunButton.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
				RunButton.Text = "RÁPIDO"
			else
				esSprinting = false
				RunButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				RunButton.Text = "CORRER"
			end
		end
	end
end)


-- ==========================================
-- CONTROLADOR DE CÁMARA ORIGINAL (INTACTO)
-- ==========================================
local conexionCamara

local function iniciarFisicasAvanzadas(character)
	local torso = character:WaitForChild("UpperTorso", 5) or character:WaitForChild("Torso", 5)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	if not torso or not humanoid or not rootPart then return end

	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = humanoid 

	local animVoltereta = Instance.new("Animation")
	animVoltereta.AnimationId = "rbxassetid://" .. tostring(ID_CATALOGO_OFICIAL)
	local trackVoltereta = humanoid:LoadAnimation(animVoltereta)
	trackVoltereta.Priority = Enum.AnimationPriority.Action4

	if conexionCamara then conexionCamara:Disconnect() end

	local factorSuavizadoNormal = 0.05 
	local desfaseActual = Vector3.new(0, 0, 0)
	local puntoMasAlto = rootPart.Position.Y
	local enElAire = false
	local ejecutandoVoltereta = false
	local poderSaltoOriginal = humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight
	local usaPoderOAltura = humanoid.UseJumpPower

	conexionCamara = RunService.RenderStepped:Connect(function()
		if not torso or not torso.Parent or not humanoid then
			conexionCamara:Disconnect()
			return
		end

		local shiftLockActivo = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
		if shiftLockActivo then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			desfaseActual = Vector3.new(0, 0, 0)
		else
			local velocidadTorso = torso.Velocity
			local desfaseObjetivo = Vector3.new(0, 0, -velocidadTorso.Z) * 0.04
			desfaseObjetivo = Vector3.new(math.clamp(0, -1.8, 1.8), 0, math.clamp(desfaseObjetivo.Z, -1.8, 1.8))
			desfaseActual = desfaseActual:Lerp(desfaseObjetivo, factorSuavizadoNormal)
			humanoid.CameraOffset = desfaseActual
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local resultadoRaycast = Workspace:Raycast(rootPart.Position, Vector3.new(0, -3.5, 0), raycastParams)

		if not resultadoRaycast then
			enElAire = true
			if rootPart.Position.Y > puntoMasAlto then puntoMasAlto = rootPart.Position.Y end
		else
			if enElAire and not ejecutandoVoltereta then
				enElAire = false
				local distanciaCaida = puntoMasAlto - rootPart.Position.Y

				if distanciaCaida >= ALTURA_MINIMA_VOLTERETA then
					ejecutandoVoltereta = true
					if usaPoderOAltura then humanoid.JumpPower = 0 else humanoid.JumpHeight = 0 end

					trackVoltereta:Stop()
					trackVoltereta:Play() 

					local attachment = Instance.new("Attachment"); attachment.Parent = rootPart
					local impulso = Instance.new("LinearVelocity")
					impulso.Attachment0 = attachment; impulso.MaxForce = 35000 
					impulso.VectorVelocity = (rootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 48
					impulso.Parent = rootPart

					task.spawn(function()
						task.wait(0.25) 
						impulso:Destroy(); attachment:Destroy()
						trackVoltereta:Stop(0.1)
						humanoid.WalkSpeed = 3
						task.wait(0.25)
						if usaPoderOAltura then humanoid.JumpPower = poderSaltoOriginal else humanoid.JumpHeight = poderSaltoOriginal end
						humanoid.WalkSpeed = esSprinting and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR
						ejecutandoVoltereta = false
					end)
				end
				puntoMasAlto = rootPart.Position.Y
			elseif not enElAire then
				puntoMasAlto = rootPart.Position.Y
			end
		end
	end)
end


-- ==========================================
-- SISTEMA DE VUELO INTEGRADO
-- ==========================================
local isVolando = false
local energiaVueloMax = 35
local energiaVueloActual = 35
local vueloDisponible = true
local regenPorSegundo = 3 
local velocidadVueloLibre = 55 
local tiempoSinVolar = 0 
local finCooldownVuelo = 0 
local ultimoIntentoSalto = 0 
local isBarraVisible = false

local function actualizarFadeBarra(mostrar)
	local twInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	if mostrar and not isBarraVisible then
		isBarraVisible = true
		TweenService:Create(barraVueloBg, twInfo, {BackgroundTransparency = 0, BorderColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		TweenService:Create(barraVueloFill, twInfo, {BackgroundTransparency = 0}):Play()
	elseif not mostrar and isBarraVisible then
		isBarraVisible = false
		TweenService:Create(barraVueloBg, twInfo, {BackgroundTransparency = 1, BorderColor3 = Color3.fromRGB(20, 20, 20)}):Play()
		TweenService:Create(barraVueloFill, twInfo, {BackgroundTransparency = 1}):Play()
	end
end

local function terminarVueloNormal(rootPart, humanoid)
	if not isVolando then return end
	isVolando = false
	if trackVueloActual then trackVueloActual:Stop(0.2); trackVueloActual = nil end
	if rootPart then
		local att = rootPart:FindFirstChild("VueloNormalAtt"); if att then att:Destroy() end
		local vel = rootPart:FindFirstChild("VueloNormalVel"); if vel then vel:Destroy() end
		local gyro = rootPart:FindFirstChild("VueloNormalGyro"); if gyro then gyro:Destroy() end
	end
	if humanoid and humanoid.Health > 0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function empezarVueloNormal(rootPart, humanoid)
	if isVolando or not vueloDisponible or energiaVueloActual <= 0 or os.clock() < finCooldownVuelo then return end
	isVolando = true; tiempoSinVolar = 0
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
	trackVueloActual = animator:LoadAnimation(animVueloObj)
	trackVueloActual.Priority = Enum.AnimationPriority.Action3
	trackVueloActual:Play(0.2)

	local attachment = Instance.new("Attachment"); attachment.Name = "VueloNormalAtt"; attachment.Parent = rootPart
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "VueloNormalVel"; linearVelocity.Attachment0 = attachment; linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(100000, 100000, 100000); linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World; linearVelocity.VectorVelocity = rootPart.AssemblyLinearVelocity; linearVelocity.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "VueloNormalGyro"; alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment; alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = 100000; alignOrientation.Responsiveness = 80; alignOrientation.Parent = rootPart
end

UserInputService.JumpRequest:Connect(function()
	if os.clock() - ultimoIntentoSalto < 0.1 then return end
	ultimoIntentoSalto = os.clock()
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			if isVolando then terminarVueloNormal(root, hum)
			elseif hum.FloorMaterial == Enum.Material.Air then empezarVueloNormal(root, hum) end
		end
	end
end)


-- ==========================================
-- HABILIDADES: REBOBINADO Y SPEED BOOST
-- ==========================================
local isRecording = false
local isRewinding = false
local activationCFrame = nil 
local positionHistory = {}   
local activeGhosts = {}
local activationGhost = nil
local timeSinceLastDrain = 0 

local speedBoostTimeLeft = 0
local speedDrainAccumulator = 0

local function updateUI(usarLerp, bloquearBarra)
	energyText.Text = tostring(math.floor(currentEnergy))

	-- UI Reversal (Manejo del botón de Cancelar)
	if isRecording and not isRewinding then
		botonCancelarReversal.Visible = true
	else
		botonCancelarReversal.Visible = false
	end

	if cooldownReversal > 0 then
		botonImpulso.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		botonImpulso.Text = string.format("CD: %.1fs", cooldownReversal)
	elseif isRewinding then
		botonImpulso.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		botonImpulso.Text = "Rewinding..."
	elseif isRecording then
		botonImpulso.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		botonImpulso.Text = "Return"
	else
		botonImpulso.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		botonImpulso.Text = "Time Reversal"
	end

	-- UI Speed Boost
	if cooldownVelocidad > 0 then
		botonVelocidad.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		botonVelocidad.Text = string.format("CD: %.1fs", cooldownVelocidad)
	elseif isSpeedBoosting then
		botonVelocidad.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		botonVelocidad.Text = "Boosting..."
	else
		botonVelocidad.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		botonVelocidad.Text = "Speed Boost"
	end

	if not bloquearBarra then
		local targetSize = UDim2.new(currentEnergy / maxEnergy, 0, 1, 0)
		if usarLerp then TweenService:Create(energyFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
		else energyFill.Size = targetSize end
	end
end

local function fadeAndDestroyGhost(ghost)
	if not ghost then return end
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, obj in pairs(ghost:GetDescendants()) do
		if obj:IsA("BasePart") then TweenService:Create(obj, tweenInfo, {Transparency = 1}):Play() end
	end
	task.delay(0.15, function() if ghost and ghost.Parent then ghost:Destroy() end end)
end

local function createGhost(character)
	character.Archivable = true; local ghost = character:Clone()
	local fIn = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fOut = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In) 

	for _, obj in pairs(ghost:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true; obj.CanCollide = false; obj.CanQuery = false; obj.CanTouch = false 
			obj.Material = Enum.Material.ForceField; obj.Color = Color3.fromRGB(0, 150, 255); obj.Transparency = 1 
			local tIn = TweenService:Create(obj, fIn, {Transparency = 0.3})
			local tOut = TweenService:Create(obj, fOut, {Transparency = 1})
			tIn.Completed:Connect(function() tOut:Play() end); tIn:Play()
			if obj:IsA("MeshPart") then obj.TextureID = "" end
		elseif obj:IsA("SpecialMesh") then obj.TextureId = ""
		elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Script") or obj:IsA("LocalScript") then obj:Destroy() end
	end
	local hum = ghost:FindFirstChild("Humanoid"); if hum then hum:Destroy() end
	ghost.Parent = ghostFolder; return ghost
end

local function doReversal()
	if not isRecording or isRewinding then return end
	isRecording = false; isRewinding = true
	updateUI(false, false)

	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart
		hrp.Anchored = true 
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear) 

		for i = #positionHistory, 1, -1 do
			TweenService:Create(hrp, tweenInfo, {CFrame = positionHistory[i]}):Play()
			task.wait(0.1)
			if activeGhosts[i] then fadeAndDestroyGhost(activeGhosts[i]); activeGhosts[i] = nil end
		end
		if activationCFrame then TweenService:Create(hrp, tweenInfo, {CFrame = activationCFrame}):Play(); task.wait(0.1) end
		hrp.Anchored = false
	end

	for _, g in ipairs(activeGhosts) do if g then fadeAndDestroyGhost(g) end end
	if activationGhost then fadeAndDestroyGhost(activationGhost) end

	activationCFrame = nil; table.clear(positionHistory); table.clear(activeGhosts)
	timeSinceLastDrain = 0; isRewinding = false
	cooldownReversal = MAX_COOLDOWN_REVERSAL 
	updateUI(false, false)
end

botonImpulso.MouseButton1Click:Connect(function()
	if isRewinding or cooldownReversal > 0 then return end 
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	if not isRecording then
		if currentEnergy > 0 then
			isRecording = true
			activationCFrame = character.HumanoidRootPart.CFrame
			table.clear(positionHistory)
			for _, g in ipairs(activeGhosts) do if g then g:Destroy() end end
			table.clear(activeGhosts)
			activationGhost = createGhost(character)
			timeSinceLastDrain = 0
			updateUI(false, false)
		end
	else task.spawn(doReversal) end
end)

-- NUEVO: Lógica del botón Cancelar Reversal
botonCancelarReversal.MouseButton1Click:Connect(function()
	if not isRecording or isRewinding then return end
	isRecording = false

	for _, g in ipairs(activeGhosts) do if g then fadeAndDestroyGhost(g) end end
	if activationGhost then fadeAndDestroyGhost(activationGhost) end

	activationCFrame = nil
	table.clear(positionHistory)
	table.clear(activeGhosts)
	timeSinceLastDrain = 0

	cooldownReversal = MAX_COOLDOWN_REVERSAL
	updateUI(false, false)
end)

local function endSpeedBoost()
	if not isSpeedBoosting then return end
	isSpeedBoosting = false
	cooldownVelocidad = MAX_COOLDOWN_VELOCIDAD 
	updateUI(false, false)
end

botonVelocidad.MouseButton1Click:Connect(function()
	if isSpeedBoosting or isRewinding or currentEnergy <= 0 or cooldownVelocidad > 0 then return end
	isSpeedBoosting = true
	speedBoostTimeLeft = 10 
	speedDrainAccumulator = 0
	updateUI(false, false)
end)


-- ==========================================
-- BUCLE MAESTRO DE CONTROL
-- ==========================================
RunService.RenderStepped:Connect(function(deltaTime)
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	-- 1. LÓGICA DE VUELO
	if rootPart and humanoid then
		if isVolando then
			tiempoSinVolar = 0
			local vel = rootPart:FindFirstChild("VueloNormalVel")
			local gyro = rootPart:FindFirstChild("VueloNormalGyro")
			if vel and gyro then
				local moveVector = Controls:GetMoveVector()
				local direccionDeseada = (Camera.CFrame.RightVector * moveVector.X) + (Camera.CFrame.LookVector * -moveVector.Z)
				local seEstaMoviendo = direccionDeseada.Magnitude > 0.01

				if seEstaMoviendo then direccionDeseada = direccionDeseada.Unit end
				local gastoActual = seEstaMoviendo and 15 or 5
				energiaVueloActual = math.max(0, energiaVueloActual - (gastoActual * deltaTime))

				if energiaVueloActual <= 0 then
					energiaVueloActual = 0; vueloDisponible = false 
					finCooldownVuelo = os.clock() + 0.5
					terminarVueloNormal(rootPart, humanoid)
				end

				vel.VectorVelocity = vel.VectorVelocity:Lerp(direccionDeseada * velocidadVueloLibre, 0.1)
				if seEstaMoviendo then gyro.CFrame = CFrame.lookAt(Vector3.zero, direccionDeseada)
				else
					local lookPlano = Vector3.new(gyro.CFrame.LookVector.X, 0, gyro.CFrame.LookVector.Z)
					if lookPlano.Magnitude > 0.01 then gyro.CFrame = CFrame.lookAt(Vector3.zero, lookPlano.Unit) end
				end
			end
		else
			if os.clock() >= finCooldownVuelo then
				tiempoSinVolar = tiempoSinVolar + deltaTime
				if energiaVueloActual < energiaVueloMax then
					energiaVueloActual = math.min(energiaVueloMax, energiaVueloActual + (regenPorSegundo * deltaTime))
					if energiaVueloActual >= energiaVueloMax then vueloDisponible = true end
				end
			else tiempoSinVolar = 0 end
		end
		barraVueloFill.Size = barraVueloFill.Size:Lerp(UDim2.new(energiaVueloActual / energiaVueloMax, 0, 1, 0), 0.15)
		actualizarFadeBarra(tiempoSinVolar < 2)
	end

	-- 2. LÓGICA DE ENERGÍA DE HABILIDADES
	local needsUIUpdate = false
	if cooldownReversal > 0 then cooldownReversal = math.max(0, cooldownReversal - deltaTime); needsUIUpdate = true end
	if cooldownVelocidad > 0 then cooldownVelocidad = math.max(0, cooldownVelocidad - deltaTime); needsUIUpdate = true end

	if currentEnergy < maxEnergy then currentEnergy = math.min(maxEnergy, currentEnergy + (ENERGY_REGEN_PER_SECOND * deltaTime)) end
	if tweenCooldown > 0 then tweenCooldown = tweenCooldown - deltaTime; needsUIUpdate = true end

	if isRecording then
		timeSinceLastDrain = timeSinceLastDrain + deltaTime
		if timeSinceLastDrain >= 1 then
			currentEnergy = math.max(0, currentEnergy - 10)
			timeSinceLastDrain = timeSinceLastDrain - 1 
			if rootPart then
				table.insert(positionHistory, rootPart.CFrame)
				table.insert(activeGhosts, createGhost(character))
			end
			tweenCooldown = 0.15; updateUI(true, false); needsUIUpdate = false
			if currentEnergy <= 0 then task.spawn(doReversal) end
		end
	end

	if isSpeedBoosting then
		speedBoostTimeLeft = speedBoostTimeLeft - deltaTime
		speedDrainAccumulator = speedDrainAccumulator + deltaTime
		if speedDrainAccumulator >= 1 then
			currentEnergy = math.max(0, currentEnergy - 5)
			speedDrainAccumulator = speedDrainAccumulator - 1
			tweenCooldown = 0.15; updateUI(true, false); needsUIUpdate = false
		end
		if speedBoostTimeLeft <= 0 or currentEnergy <= 0 then endSpeedBoost() end
	end

	if needsUIUpdate or (not isRecording and not isSpeedBoosting) then updateUI(false, tweenCooldown > 0) end
end)


-- ==========================================
-- EVENTOS DE CARGA DEL PERSONAJE
-- ==========================================
if LocalPlayer.Character then
	configurarPersonaje(LocalPlayer.Character)
	iniciarFisicasAvanzadas(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(nuevoChar)
	configurarPersonaje(nuevoChar)
	iniciarFisicasAvanzadas(nuevoChar)
end)
