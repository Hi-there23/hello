-- SERVICIOS
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- VARIABLES PRINCIPALES
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator")

-- CONFIGURACIÓN
local TIEMPO_ESPERA_FLOTAR = 0.15   -- Tiempo mínimo cayendo para poder activar el flote
local COOLDOWN_REPETIR_FLOTE = 1.5 -- Cooldown invisible SOLO tras terminar el flote
local COOLDOWN_IMPULSO = 22        -- Tiempo de espera para volver a usar el impulso
local ID_ANIMACION = "rbxassetid://114731495347458"

-- ESTADOS
local estaFlotando = false
local ejecutandoImpulso = false
local tiempoEnElAire = 0
local sePuedeFlotarDeNuevo = true 
local sePuedeUsarImpulso = true   

-- CARGAR ANIMACIÓN
local animacion = Instance.new("Animation")
animacion.AnimationId = ID_ANIMACION
local trackAnimacion = animator:LoadAnimation(animacion)

-- CREACIÓN DE LA INTERFAZ DE USUARIO (GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ImpulsoGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local botonImpulso = Instance.new("TextButton")
botonImpulso.Size = UDim2.new(0, 140, 0, 50)
botonImpulso.Position = UDim2.new(0.5, -70, 0.85, -25) 
botonImpulso.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
botonImpulso.Text = "IMPULSO"
botonImpulso.TextColor3 = Color3.fromRGB(255, 255, 255)
botonImpulso.Font = Enum.Font.SourceSansBold
botonImpulso.TextSize = 20
botonImpulso.BorderSizePixel = 0
botonImpulso.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = botonImpulso

local textoCooldown = Instance.new("TextLabel")
textoCooldown.Size = UDim2.new(1, 0, 1, 0)
textoCooldown.BackgroundTransparency = 1
textoCooldown.Text = ""
textoCooldown.TextColor3 = Color3.fromRGB(255, 255, 255)
textoCooldown.Font = Enum.Font.SourceSansBold
textoCooldown.TextSize = 22
textoCooldown.Parent = botonImpulso

-- FUNCIÓN ÚNICA PARA CREAR EL EFECTO REBOTE
local function aplicarRebote(resultadoRaycast)
	local attRebote = Instance.new("Attachment")
	attRebote.Parent = rootPart

	local fuerzaRebote = Instance.new("LinearVelocity")
	fuerzaRebote.MaxForce = 80000
	-- Dirección normal de la pared (hacia atrás) + mini salto vertical (18)
	fuerzaRebote.VectorVelocity = (resultadoRaycast.Normal * 25) + Vector3.new(0, 18, 0)
	fuerzaRebote.Attachment0 = attRebote
	fuerzaRebote.Parent = rootPart

	task.delay(0.2, function()
		fuerzaRebote:Destroy()
		attRebote:Destroy()
	end)
end

-- FUNCIÓN PARA LIMPIAR LA FÍSICA DE FLOTE
local function detenerFlote()
	if not estaFlotando then return end
	estaFlotando = false
	trackAnimacion:Stop()

	local elementos = {"FuerzaFlote", "GiroFlote", "AttFlote"}
	for _, nombre in ipairs(elementos) do
		local elemento = rootPart:FindFirstChild(nombre)
		if elemento then elemento:Destroy() end
	end

	sePuedeFlotarDeNuevo = false
	task.delay(COOLDOWN_REPETIR_FLOTE, function()
		sePuedeFlotarDeNuevo = true
	end)
end

-- FUNCIÓN PRINCIPAL DE FLOTE
local function empezarFlote()
	if estaFlotando or not sePuedeFlotarDeNuevo then return end
	estaFlotando = true
	trackAnimacion:Play()

	local attFlote = Instance.new("Attachment")
	attFlote.Name = "AttFlote"
	attFlote.Parent = rootPart

	local fuerzaFlote = Instance.new("LinearVelocity")
	fuerzaFlote.Name = "FuerzaFlote"
	fuerzaFlote.MaxForce = 60000
	fuerzaFlote.Attachment0 = attFlote
	fuerzaFlote.Parent = rootPart

	local giroFlote = Instance.new("AngularVelocity")
	giroFlote.Name = "GiroFlote"
	giroFlote.MaxTorque = 400000
	giroFlote.Attachment0 = attFlote
	giroFlote.Parent = rootPart

	task.spawn(function()
		while estaFlotando and humanoid.FloorMaterial == Enum.Material.Air do
			local direccionMover = humanoid.MoveDirection
			if direccionMover.Magnitude == 0 then
				direccionMover = rootPart.CFrame.LookVector
			end

			fuerzaFlote.VectorVelocity = (direccionMover * 17.5) + Vector3.new(0, -4, 0)

			local frenteActual = rootPart.CFrame.LookVector
			local anguloGiro = frenteActual:Dot(direccionMover.Unit)
			local vectorCruzado = frenteActual:Cross(direccionMover.Unit)

			if direccionMover.Magnitude > 0 and anguloGiro < 0.999 then
				local direccionGiro = vectorCruzado.Y > 0 and 1 or -1
				giroFlote.AngularVelocity = Vector3.new(0, 4 * direccionGiro, 0)
			else
				giroFlote.AngularVelocity = Vector3.new(0, 0, 0)
			end

			-- DETECCIÓN DE PAREDES EN FLOTE
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local resultadoRaycast = workspace:Raycast(rootPart.Position, direccionMover * 2.5, raycastParams)

			if resultadoRaycast then
				detenerFlote()
				aplicarRebote(resultadoRaycast)
				break
			end
			RunService.Heartbeat:Wait()
		end

		if estaFlotando then
			detenerFlote()
		end
	end)
end

-- FUNCIÓN PARA EJECUTAR EL IMPULSO (CON DETECCIÓN DE PARED INCLUIDA)
local function activarImpulso()
	if not sePuedeUsarImpulso then return end
	sePuedeUsarImpulso = false
	ejecutandoImpulso = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "AttImpulso"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "FuerzaImpulso"
	linearVelocity.MaxForce = 50000
	linearVelocity.VectorVelocity = (rootPart.CFrame.LookVector * 55) + Vector3.new(0, 45, 0)
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = rootPart

	-- Bucle rápido durante el impulso para detectar colisiones antes de que termine la fuerza
	task.spawn(function()
		local tiempoTranscurrido = 0
		while ejecutandoImpulso and tiempoTranscurrido < 0.15 do
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			-- Revisa al frente de la dirección hacia donde apunta el impulso
			local resultadoRaycast = workspace:Raycast(rootPart.Position, rootPart.CFrame.LookVector * 2.5, raycastParams)

			if resultadoRaycast then
				ejecutandoImpulso = false
				linearVelocity:Destroy()
				attachment:Destroy()
				aplicarRebote(resultadoRaycast) -- Ejecuta el mismo rebote
				break
			end

			local dt = RunService.Heartbeat:Wait()
			tiempoTranscurrido = tiempoTranscurrido + dt
		end

		-- Si no chocó, limpia las fuerzas de forma normal al terminar los 0.15s
		if ejecutandoImpulso then
			ejecutandoImpulso = false
			linearVelocity:Destroy()
			attachment:Destroy()
		end
	end)

	-- Contador visual del cooldown en el botón
	task.spawn(function()
		botonImpulso.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		botonImpulso.Text = ""
		for i = COOLDOWN_IMPULSO, 1, -1 do
			textoCooldown.Text = tostring(i)
			task.wait(1)
		end
		textoCooldown.Text = ""
		botonImpulso.Text = "IMPULSO"
		botonImpulso.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		sePuedeUsarImpulso = true
	end)
end

-- CONECTAR EL CLICK DEL BOTÓN
botonImpulso.MouseButton1Click:Connect(activarImpulso)

-- DETECTAR ESPACIO EN EL AIRE
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space then
		if humanoid.FloorMaterial == Enum.Material.Air and not estaFlotando and sePuedeFlotarDeNuevo then
			if tiempoEnElAire >= TIEMPO_ESPERA_FLOTAR then
				empezarFlote()
			end
		end
	end
end)

-- SEGUIMIENTO DEL TIEMPO EN EL AIRE
RunService.Heartbeat:Connect(function(dt)
	if humanoid.FloorMaterial == Enum.Material.Air then
		tiempoEnElAire = tiempoEnElAire + dt
	else
		tiempoEnElAire = 0
		if estaFlotando then
			detenerFlote()
		end
	end
end)

-- RECONEXIÓN POR SI EL PERSONAJE MUERE O REAPARECE
player.CharacterAdded:Connect(function(nuevoPersonaje)
	character = nuevoPersonaje
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")
	trackAnimacion = animator:LoadAnimation(animacion)
	estaFlotando = false
	ejecutandoImpulso = false
	sePuedeFlotarDeNuevo = true
end)
