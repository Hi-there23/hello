local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = PlayerModule:GetControls()

--------------------------------------------------------
-- CONFIGURACIÓN DE MOVIMIENTO Y HABILIDADES
--------------------------------------------------------
local VELOCIDAD_CAMINAR = 5
local VELOCIDAD_CORRER = 18.5
local ID_ANIMACION_CARGA = "rbxassetid://93025862679737" 
local DISTANCIA_MAX_TRUCO = 100 

local MULTIPLICADOR_INVISIBILIDAD = 3
local GRAVEDAD_NORMAL = Workspace.Gravity
local GRAVEDAD_INVISIBILIDAD = 35 
	
--------------------------------------------------------
-- 1. CREACIÓN DE TODA LA INTERFAZ (GUI)
--------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InterfazGlobalPerfeccionada"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local pantallaOscura = Instance.new("Frame")
pantallaOscura.AnchorPoint = Vector2.new(0.5, 0.5) 
pantallaOscura.Size = UDim2.new(2, 0, 2, 0)
pantallaOscura.BackgroundColor3 = Color3.new(0, 0, 0)
pantallaOscura.BackgroundTransparency = 1
pantallaOscura.ZIndex = -1 
pantallaOscura.Parent = screenGui

local RunButton = Instance.new("TextButton")
RunButton.Parent = screenGui
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

local LockLabel = Instance.new("TextLabel")
LockLabel.Parent = screenGui
LockLabel.Size = UDim2.new(0, 24, 0, 24)
LockLabel.BackgroundTransparency = 1
LockLabel.Text = "🔒"
LockLabel.TextSize = 18
LockLabel.Visible = false 

local frameHabilidades = Instance.new("Frame")
frameHabilidades.Size = UDim2.new(0, 200, 0, 150)
frameHabilidades.Position = UDim2.new(0, 20, 0.5, -75)
frameHabilidades.BackgroundTransparency = 1
frameHabilidades.Parent = screenGui

local function crearBoton(nombre, texto, posicionY)
	local btn = Instance.new("TextButton")
	btn.Name = nombre
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.Position = UDim2.new(0, 0, 0, posicionY)
	btn.Text = texto
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = frameHabilidades
	return btn
end

local btnInvisibilidad = crearBoton("BtnInvisibilidad", "Invisibilidad", 0)
local btnCarga = crearBoton("BtnCarga", "Carga", 50)
local btnTruco = crearBoton("BtnTruco", "Truco de Dios", 100)

--------------------------------------------------------
-- 2. SISTEMA DE MOVIMIENTO Y CÁMARA
--------------------------------------------------------
local esSprinting = false
local invisibilidadActiva = false 

RunButton:GetPropertyChangedSignal("Position"):Connect(function()
	if LockLabel then
		LockLabel.Position = UDim2.new(RunButton.Position.X.Scale, RunButton.Position.X.Offset + 50, RunButton.Position.Y.Scale, RunButton.Position.Y.Offset - 22)
	end
end)

local function configurarPersonaje(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = VELOCIDAD_CAMINAR

	task.spawn(function()
		local factorSuavizadoMovimiento = 0.8
		while character and character.Parent and humanoid and humanoid.Health > 0 do
			local velocidadBase = esSprinting and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR
			local velocidadObjetivo = invisibilidadActiva and (velocidadBase * MULTIPLICADOR_INVISIBILIDAD) or velocidadBase

			if math.abs(humanoid.WalkSpeed - velocidadObjetivo) > 0.05 then
				humanoid.WalkSpeed = humanoid.WalkSpeed + (velocidadObjetivo - humanoid.WalkSpeed) * factorSuavizadoMovimiento
			else
				humanoid.WalkSpeed = velocidadObjetivo
			end
			task.wait(0.05) 
		end
	end)

	local animateScript = character:WaitForChild("Animate", 5)
	if animateScript then
		pcall(function()
			local idCaminataOriginal = animateScript.walk.WalkAnim.AnimationId
			local idCarreraOriginal = animateScript.run.RunAnim.AnimationId
			animateScript.walk.WalkAnim.AnimationId = idCarreraOriginal 
			animateScript.run.RunAnim.AnimationId = idCaminataOriginal   
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
		local character = player.Character
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

local conexionCamara
local function iniciarFisicasAvanzadas(character)
	local torso = character:WaitForChild("UpperTorso", 5) or character:WaitForChild("Torso", 5)
	local humanoid = character:WaitForChild("Humanoid")
	if not torso or not humanoid then return end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid 

	if conexionCamara then conexionCamara:Disconnect() end
	local factorSuavizadoNormal = 0.05 
	local desfaseActual = Vector3.new(0, 0, 0)

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
			local velocidadTorso = torso.AssemblyLinearVelocity
			local desfaseObjetivo = Vector3.new(0, 0, -velocidadTorso.Z) * 0.04
			desfaseObjetivo = Vector3.new(math.clamp(0, -1.8, 1.8), 0, math.clamp(desfaseObjetivo.Z, -1.8, 1.8))
			desfaseActual = desfaseActual:Lerp(desfaseObjetivo, factorSuavizadoNormal)
			humanoid.CameraOffset = desfaseActual
		end
	end)
end

if player.Character then
	configurarPersonaje(player.Character)
	iniciarFisicasAvanzadas(player.Character)
end
player.CharacterAdded:Connect(function(nuevoChar)
	configurarPersonaje(nuevoChar)
	iniciarFisicasAvanzadas(nuevoChar)
end)

--------------------------------------------------------
-- 3. FUNCIONES AUXILIARES PARA LAS HABILIDADES
--------------------------------------------------------
local function aplicarEfectoGhost(targetChar, estado, conFade, usarPantallaOscura)
	if not targetChar then return end
	local humanoid = targetChar:FindFirstChild("Humanoid")

	if estado then
		if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end
		if conFade then
			local viejoHl = targetChar:FindFirstChild("GhostHighlight")
			if viejoHl then viejoHl:Destroy() end

			local nuevoHl = Instance.new("Highlight")
			nuevoHl.Name = "GhostHighlight"
			nuevoHl.FillColor = Color3.new(1, 0, 0)
			nuevoHl.OutlineColor = Color3.new(1, 0, 0)
			nuevoHl.FillTransparency = 1
			nuevoHl.OutlineTransparency = 1
			nuevoHl.Parent = targetChar

			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(nuevoHl, tweenInfo, {FillTransparency = 0.3, OutlineTransparency = 0.2}):Play()

			if usarPantallaOscura ~= false then
				TweenService:Create(pantallaOscura, tweenInfo, {BackgroundTransparency = 0.4}):Play()
			end

			-- [MÁXIMA OPTIMIZACIÓN]: Transparencia instantánea, sin Tweens que saturen el celular
			for _, parte in ipairs(targetChar:GetDescendants()) do
				if (parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart") or parte:IsA("Decal") or parte:IsA("Texture") then
					parte.Transparency = 0.99
				end
			end
		end
	else
		if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
		local hl = targetChar:FindFirstChild("GhostHighlight")
		if hl then hl:Destroy() end

		TweenService:Create(pantallaOscura, TweenInfo.new(0), {BackgroundTransparency = 1}):Play()

		for _, parte in ipairs(targetChar:GetDescendants()) do
			if (parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart") or parte:IsA("Decal") or parte:IsA("Texture") then
				parte.Transparency = 0
			end
		end
	end
end

local function toggleAntiGravedad(hrp, estado)
	if estado then
		if not hrp:FindFirstChild("InvisAttachment") then
			local att = Instance.new("Attachment", hrp)
			att.Name = "InvisAttachment"
			local lv = Instance.new("LinearVelocity", hrp)
			lv.Name = "InvisVelocity"
			lv.Attachment0 = att
			lv.MaxForce = 9999999
			lv.VectorVelocity = Vector3.new(0, 0, 0)
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
		end
	else
		local att = hrp:FindFirstChild("InvisAttachment")
		if att then att:Destroy() end
		local lv = hrp:FindFirstChild("InvisVelocity")
		if lv then lv:Destroy() end
	end
end

--------------------------------------------------------
-- HABILIDAD 1: INVISIBILIDAD DEFINITIVA
--------------------------------------------------------
local cooldownInvisibilidad = false
local tiempoInicioInvis = 0
local syncConnection = nil 
local jumpConnection = nil

btnInvisibilidad.MouseButton1Click:Connect(function()
	if invisibilidadActiva then
		if tick() - tiempoInicioInvis >= 4 then invisibilidadActiva = false end
		return
	end

	if cooldownInvisibilidad then return end
	local realChar = player.Character
	if not realChar or not realChar:FindFirstChild("HumanoidRootPart") then return end

	cooldownInvisibilidad = true
	invisibilidadActiva = true
	tiempoInicioInvis = tick()

	local realHrp = realChar.HumanoidRootPart
	local realHumanoid = realChar:FindFirstChild("Humanoid")
	local nombreClonSeguro = "Ghost_Client_" .. player.Name

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == nombreClonSeguro then obj:Destroy() end
	end

	realChar.Archivable = true
	local ghostClone = realChar:Clone()
	ghostClone.Name = nombreClonSeguro
	ghostClone:PivotTo(realChar:GetPivot())
	ghostClone.Parent = Workspace

	local cloneHum = ghostClone:FindFirstChild("Humanoid")
	local cloneHrp = ghostClone:FindFirstChild("HumanoidRootPart")

	local animateScript = realChar:FindFirstChild("Animate")
	if animateScript then animateScript:Clone().Parent = ghostClone end

	if cloneHrp then
		cloneHrp.Anchored = true
		task.delay(0.05, function()
			if invisibilidadActiva and cloneHrp and cloneHrp.Parent then cloneHrp.Anchored = false end
		end)
	end
	Workspace.Gravity = GRAVEDAD_INVISIBILIDAD

	-- [MÁXIMA OPTIMIZACIÓN]: Mandamos al realChar al cielo UNA SOLA VEZ, no 60 veces por segundo.
	realChar:PivotTo(realChar:GetPivot() + Vector3.new(0, 1000, 0))
	
	for _, parte in ipairs(realChar:GetDescendants()) do
		if parte:IsA("BasePart") or parte:IsA("Decal") or parte:IsA("Texture") then 
			parte.Transparency = 1 
		end
	end

	toggleAntiGravedad(realHrp, true)
	realHrp.Anchored = false 
	realHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

	if syncConnection then syncConnection:Disconnect() end
	syncConnection = RunService.RenderStepped:Connect(function()
		if not ghostClone or not ghostClone.Parent then return end

		if cloneHum then
			local velocidadBase = esSSprint and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR
			local velocidadObjetivo = velocidadBase * MULTIPLICADOR_INVISIBILIDAD
			cloneHum.WalkSpeed = cloneHum.WalkSpeed + (velocidadObjetivo - cloneHum.WalkSpeed) * 0.8
		end

		if cloneHum and (cloneHrp and not cloneHrp.Anchored) then
			cloneHum:Move(controls:GetMoveVector(), true)
		end
		
		-- ELIMINAMOS EL CÓDIGO QUE MOVÍA AL REALCHAR AQUÍ ADENTRO. YA NO DA LAG.
	end)

	if jumpConnection then jumpConnection:Disconnect() end
	jumpConnection = UserInputService.JumpRequest:Connect(function()
		if invisibilidadActiva and cloneHum and (cloneHrp and not cloneHrp.Anchored) then
			cloneHum.Jump = true
		end
	end)

	local oldCamCF = camera.CFrame 
	player.Character = ghostClone
	camera.CameraSubject = cloneHum
	task.defer(function() camera.CFrame = oldCamCF end)

	aplicarEfectoGhost(ghostClone, true, true, true)

	task.spawn(function()
		local duracionMax = 35
		while invisibilidadActiva and (tick() - tiempoInicioInvis) < duracionMax do
			if not ghostClone or not ghostClone.Parent or not realChar or not realChar.Parent then break end
			local tiempoRestante = math.ceil(duracionMax - (tick() - tiempoInicioInvis))
			btnInvisibilidad.Text = "Invis. (" .. tiempoRestante .. "s)"
			task.wait(0.1)
		end

		invisibilidadActiva = false
		if syncConnection then syncConnection:Disconnect() syncConnection = nil end
		if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end

		task.spawn(function()
			for i = 20, 1, -1 do
				btnInvisibilidad.Text = "Invis. (CD: " .. i .. "s)"
				task.wait(1)
			end
			btnInvisibilidad.Text = "Invisibilidad"
			cooldownInvisibilidad = false
		end)

		local posicionFinal = CFrame.new()
		if realChar and realChar.PrimaryPart then
			posicionFinal = realChar:GetPivot() - Vector3.new(0, 100, 0)
		end

		local clonADestruir = ghostClone
		if clonADestruir and clonADestruir.Parent then
			posicionFinal = clonADestruir:GetPivot()
			local hrpFinal = clonADestruir:FindFirstChild("HumanoidRootPart")
			if hrpFinal then hrpFinal.Anchored = true end

			if cloneHum then
				local animator = cloneHum:FindFirstChild("Animator")
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
				end
			end
			aplicarEfectoGhost(clonADestruir, false, false)
			task.delay(0.01, function()
				if clonADestruir then clonADestruir:Destroy() end
			end)
		end

		if realChar and realChar.Parent and realHrp and realHrp.Parent then
			local backCamCF = camera.CFrame 
			player.Character = realChar

			Workspace.Gravity = GRAVEDAD_NORMAL
			toggleAntiGravedad(realHrp, false)
			realHrp.Anchored = false 
			
			-- Traemos al avatar original de vuelta desde el cielo a la posición del clon
			realChar:PivotTo(posicionFinal + Vector3.new(0, 3, 0))
			realHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

			camera.CameraType = Enum.CameraType.Custom
			if realHumanoid then
				camera.CameraSubject = realHumanoid
				realHumanoid.PlatformStanding = false
				realHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end

			task.defer(function() camera.CFrame = backCamCF end)

			local realAnimate = realChar:FindFirstChild("Animate")
			if realAnimate then
				local clonAnimate = realAnimate:Clone()
				realAnimate:Destroy()
				task.wait(0.05)
				clonAnimate.Parent = realChar
			end

			controls:Disable()
			task.wait(0.05)
			controls:Enable(true) 

			for _, parte in ipairs(realChar:GetDescendants()) do
				if parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart" then
					parte.Transparency = 0
				elseif parte:IsA("Decal") or parte:IsA("Texture") then
					parte.Transparency = 0
				elseif parte:IsA("Clothing") or parte:IsA("ShirtGraphic") then
					parte.Parent = realChar 
				end
			end
		end
	end)
end)

--------------------------------------------------------
-- HABILIDAD 2: CARGA
--------------------------------------------------------
local cooldownCarga = false
btnCarga.MouseButton1Click:Connect(function()
	if cooldownCarga then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	cooldownCarga = true
	btnCarga.Text = "Cargando..."

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0
	highlight.OutlineTransparency = 1
	highlight.Parent = char

	for i = 1, 2 do
		highlight.Enabled = true
		task.wait(0.4)
		highlight.Enabled = false
		task.wait(0.4)
	end
	highlight:Destroy()

	task.wait(0.8)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animacionCarga = Instance.new("Animation")
	animacionCarga.AnimationId = ID_ANIMACION_CARGA
	local animTrack = animator:LoadAnimation(animacionCarga)
	animTrack:Play()

	controls:Disable() 

	local attachment = Instance.new("Attachment", hrp)
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 9999999
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = hrp

	local tiempoFin = tick() + 4.5
	local conexion

	humanoid.AutoRotate = false 

	conexion = RunService.RenderStepped:Connect(function()
		if tick() < tiempoFin then
			local lookDir = camera.CFrame.LookVector
			linearVelocity.VectorVelocity = lookDir * 65
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(lookDir.X, 0, lookDir.Z))
		else
			conexion:Disconnect()
			linearVelocity:Destroy()
			attachment:Destroy()
			controls:Enable(true) 
			humanoid.AutoRotate = true 

			if animTrack.IsPlaying then animTrack:Stop() end
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

			task.spawn(function()
				for i = 34, 1, -1 do
					btnCarga.Text = "Carga (CD: " .. i .. "s)"
					task.wait(1)
				end
				btnCarga.Text = "Carga"
				cooldownCarga = false
			end)
		end
	end)
end)

--------------------------------------------------------
-- HABILIDAD 3: TRUCO DE DIOS
--------------------------------------------------------
local cooldownTruco = false
btnTruco.MouseButton1Click:Connect(function()
	if cooldownTruco then return end
	local realChar = player.Character
	local realHrp = realChar and realChar:FindFirstChild("HumanoidRootPart")
	local realHumanoid = realChar and realChar:FindFirstChild("Humanoid")
	if not realHrp or not realHumanoid then return end

	cooldownTruco = true
	btnTruco.Text = "Ejecutando..."

	realChar.Archivable = true
	local ghostClone = realChar:Clone()
	ghostClone.Name = "ClonTruco_" .. player.Name
	ghostClone:PivotTo(realChar:GetPivot())
	ghostClone.Parent = Workspace

	local cloneHrp = ghostClone:FindFirstChild("HumanoidRootPart")
	local cloneHum = ghostClone:FindFirstChild("Humanoid")
	if cloneHrp then cloneHrp.Anchored = true end

	camera.CameraSubject = cloneHum
	aplicarEfectoGhost(ghostClone, true, true, false) 

	for _, parte in ipairs(realChar:GetDescendants()) do
		if parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart" then 
			parte.Transparency = 1 
		elseif parte:IsA("Decal") or parte:IsA("Texture") then 
			parte.Transparency = 1 
		end
	end

	toggleAntiGravedad(realHrp, true)
	realHrp.Anchored = false 

	local posicionOriginal = realHrp.Position
	realChar:PivotTo(CFrame.new(posicionOriginal + Vector3.new(0, 1000, 0)))

	task.wait(1.2)

	local jugadoresCercanos = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local objetivoHrp = p.Character.HumanoidRootPart
			local distancia = (posicionOriginal - objetivoHrp.Position).Magnitude

			if distancia <= DISTANCIA_MAX_TRUCO then
				table.insert(jugadoresCercanos, p)
			end
		end
	end

	if ghostClone then ghostClone:Destroy() end
	camera.CameraSubject = realHumanoid

	if #jugadoresCercanos > 0 then
		local objetivoAleatorio = jugadoresCercanos[math.random(1, #jugadoresCercanos)]
		local objetivoHrp = objetivoAleatorio.Character.HumanoidRootPart

		controls:Disable() 

		local cfObjetivo = objetivoHrp.CFrame
		local posicionAtras = cfObjetivo.Position + (-cfObjetivo.LookVector * 5) + Vector3.new(0, 4, 0)
		realChar:PivotTo(CFrame.new(posicionAtras, posicionAtras + cfObjetivo.LookVector))

		for _, parte in ipairs(realChar:GetDescendants()) do
			if parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart" then
				parte.Transparency = 0
			elseif parte:IsA("Decal") or parte:IsA("Texture") then
				parte.Transparency = 0
			end
		end

		realHrp.Anchored = false
		toggleAntiGravedad(realHrp, true)
		realHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

		task.wait(2)

		toggleAntiGravedad(realHrp, false)

		local att = Instance.new("Attachment", realHrp)
		local lv = Instance.new("LinearVelocity", realHrp)
		lv.Attachment0 = att
		lv.MaxForce = 9999999
		lv.RelativeTo = Enum.ActuatorRelativeTo.World

		local tiempoInicioDash = tick()

		while objetivoHrp and objetivoHrp.Parent do
			local distancia = (objetivoHrp.Position - realHrp.Position).Magnitude
			if distancia < 4 or (tick() - tiempoInicioDash > 2.5) then break end

			local direccion = (objetivoHrp.Position - realHrp.Position).Unit
			lv.VectorVelocity = direccion * 120 
			RunService.RenderStepped:Wait()
		end

		if lv then lv:Destroy() end
		if att then att:Destroy() end
		realHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

		controls:Enable(true)
	else
		warn("No hay jugadores cerca.")
		for _, parte in ipairs(realChar:GetDescendants()) do
			if parte:IsA("BasePart") and parte.Name ~= "HumanoidRootPart" then 
				parte.Transparency = 0
			elseif parte:IsA("Decal") or parte:IsA("Texture") then 
				parte.Transparency = 0 
			end
		end
		toggleAntiGravedad(realHrp, false)
		realChar:PivotTo(CFrame.new(posicionOriginal) * realHrp.CFrame.Rotation)
	end

	task.spawn(function()
		for i = 45, 1, -1 do
			btnTruco.Text = "Truco (CD: " .. i .. "s)"
			task.wait(1)
		end
		btnTruco.Text = "Truco de Dios"
		cooldownTruco = false
	end)
end)
