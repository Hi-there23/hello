local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
	
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- 1. CREACIÓN DE LA INTERFAZ (GUI)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HabilidadesGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.8, 0)
frame.BackgroundTransparency = 1
frame.Parent = screenGui

local function crearBoton(nombre, texto, posicion)
	local btn = Instance.new("TextButton")
	btn.Name = nombre
	btn.Text = texto
	btn.Size = UDim2.new(0, 90, 0, 40)
	btn.Position = posicion
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 18
	btn.Parent = frame
	return btn
end

local dropdashBtn = crearBoton("DropdashButton", "Dropdash", UDim2.new(0, 0, 0, 0))
local peeloutBtn = crearBoton("PeeloutButton", "Peelout", UDim2.new(0, 110, 0, 0))


-- ==========================================
-- 2. VARIABLES GLOBALES Y UTILIDADES
-- ==========================================

local isHabilidadActiva = false 
local dropdashEnCooldown = false
local peeloutEnCooldown = false

local DROPDASH_ANIM_ID = "http://www.roblox.com/asset/?id=18537367238" 

player.CharacterAdded:Connect(function()
	isHabilidadActiva = false
end)

local function obtenerAnimacionCorrer(character)
	local animate = character:FindFirstChild("Animate")
	if animate then
		local run = animate:FindFirstChild("run")
		if run then
			local runAnimObj = run:FindFirstChildOfClass("Animation")
			if runAnimObj then
				return runAnimObj.AnimationId
			end
		end
	end
	return "rbxassetid://913376220" 
end

-- Función para manejar los tiempos de espera visualmente
local function manejarCooldown(boton, tiempo, textoOriginal, tipoHabilidad)
	task.spawn(function()
		for i = tiempo, 1, -1 do
			boton.Text = tostring(i)
			task.wait(1)
		end
		boton.Text = textoOriginal

		if tipoHabilidad == "dropdash" then
			dropdashEnCooldown = false
		elseif tipoHabilidad == "peelout" then
			peeloutEnCooldown = false
		end
	end)
end

-- Función para volvernos "fantasmas" contra otros jugadores en el Peelout
local function crearHitboxFantasma(character)
	if character:FindFirstChild("NoColConstraints") then
		character.NoColConstraints:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "NoColConstraints"
	folder.Parent = character

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			for _, myPart in ipairs(character:GetChildren()) do
				if myPart:IsA("BasePart") then
					for _, theirPart in ipairs(p.Character:GetChildren()) do
						if theirPart:IsA("BasePart") then
							local ncc = Instance.new("NoCollisionConstraint")
							ncc.Part0 = myPart
							ncc.Part1 = theirPart
							ncc.Parent = folder
						end
					end
				end
			end
		end
	end
end


-- ==========================================
-- 3. LÓGICA DEL DROPDASH
-- ==========================================
local isDropdashing = false
local dropdashVelocidad = 50 
local tiempoDropdash = 4.5  
local tiempoCooldownDropdash = 22 

dropdashBtn.MouseButton1Click:Connect(function()
	if isHabilidadActiva or dropdashEnCooldown then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	isHabilidadActiva = true
	isDropdashing = true

	local renderSteppedConnection
	local touchConnection
	local animTrack
	local deathConnection

	local function finalizarDropdash()
		if not isDropdashing then return end -- Evita que se ejecute dos veces

		isDropdashing = false
		isHabilidadActiva = false 

		if renderSteppedConnection then renderSteppedConnection:Disconnect() end
		if touchConnection then touchConnection:Disconnect() end
		if animTrack then animTrack:Stop() end
		if deathConnection then deathConnection:Disconnect() end

		if rootPart then
			local att = rootPart:FindFirstChild("DropdashAtt")
			if att then att:Destroy() end
			local vel = rootPart:FindFirstChild("DropdashVel")
			if vel then vel:Destroy() end
		end

		-- Iniciar cooldown del Dropdash
		dropdashEnCooldown = true
		manejarCooldown(dropdashBtn, tiempoCooldownDropdash, "Dropdash", "dropdash")
	end

	deathConnection = humanoid.Died:Connect(function()
		finalizarDropdash()
	end)

	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local animacion = Instance.new("Animation")
	animacion.AnimationId = DROPDASH_ANIM_ID
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animTrack = animator:LoadAnimation(animacion)
		animTrack:Play()
	end

	task.wait(0.15)

	local tiempoEnElAire = 0
	while humanoid.FloorMaterial == Enum.Material.Air and humanoid.Health > 0 do
		local dt = task.wait()
		tiempoEnElAire = tiempoEnElAire + dt
		if tiempoEnElAire > 3 then
			finalizarDropdash()
			return
		end
	end

	if humanoid.Health <= 0 or not isDropdashing then return end

	if rootPart:FindFirstChild("DropdashAtt") then rootPart.DropdashAtt:Destroy() end
	if rootPart:FindFirstChild("DropdashVel") then rootPart.DropdashVel:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "DropdashAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DropdashVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(40000, 0, 40000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	local choques = 0
	local isBouncing = false

	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		if not isBouncing then
			linearVelocity.VectorVelocity = rootPart.CFrame.LookVector * dropdashVelocidad
		else
			linearVelocity.VectorVelocity = -rootPart.CFrame.LookVector * 40
		end
	end)

	touchConnection = rootPart.Touched:Connect(function(hit)
		if isBouncing or not isDropdashing then return end

		local enemigoChar = hit.Parent
		if enemigoChar == character then return end 

		local enemigoHum = enemigoChar:FindFirstChildOfClass("Humanoid")
		local enemigoRoot = enemigoChar:FindFirstChild("HumanoidRootPart")

		if enemigoHum and enemigoRoot then
			choques = choques + 1
			isBouncing = true 

			local pushDirection = (enemigoRoot.Position - rootPart.Position).Unit
			pushDirection = Vector3.new(pushDirection.X, 0, pushDirection.Z).Unit 

			if choques < 3 then
				enemigoRoot.AssemblyLinearVelocity = pushDirection * 120
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 35, 0)

				task.delay(0.4, function()
					if isDropdashing then isBouncing = false end
				end)
			else
				enemigoRoot.AssemblyLinearVelocity = pushDirection * 160
				rootPart.AssemblyLinearVelocity = (-rootPart.CFrame.LookVector * 40) + Vector3.new(0, 40, 0)
				finalizarDropdash()
			end
		end
	end)

	task.delay(tiempoDropdash, function()
		finalizarDropdash()
	end)
end)


-- ==========================================
-- 4. LÓGICA DEL PEELOUT (Solo impulso de velocidad personal)
-- ==========================================
local isPeelouting = false
local peeloutVelocidad = 120 
local tiempoPeelout = 7.5 
local tiempoCooldownPeelout = 24 

-- ==========================================
-- 4. LÓGICA DEL PEELOUT (Con Carga y Velocidad)
-- ==========================================
local isPeelouting = false
local peeloutVelocidad = 120 
local tiempoPeelout = 7.5 
local tiempoCarga = 3.5 -- ¡Aquí está tu tiempo de carga de vuelta!
local tiempoCooldownPeelout = 24 

peeloutBtn.MouseButton1Click:Connect(function()
	if isHabilidadActiva or peeloutEnCooldown then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isHabilidadActiva = true
	isPeelouting = true

	local renderSteppedConnection
	local animTrack
	local deathConnection

	local originalWalkSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower

	local function finalizarPeelout()
		if not isPeelouting then return end 

		isPeelouting = false
		isHabilidadActiva = false 

		if humanoid then
			humanoid.WalkSpeed = originalWalkSpeed
			humanoid.JumpPower = originalJumpPower
		end

		if renderSteppedConnection then renderSteppedConnection:Disconnect() end
		if animTrack then animTrack:Stop() end
		if deathConnection then deathConnection:Disconnect() end

		if rootPart then
			local att = rootPart:FindFirstChild("PeeloutAtt")
			if att then att:Destroy() end
			local vel = rootPart:FindFirstChild("PeeloutVel")
			if vel then vel:Destroy() end
		end

		peeloutEnCooldown = true
		manejarCooldown(peeloutBtn, tiempoCooldownPeelout, "Peelout", "peelout")
	end

	deathConnection = humanoid.Died:Connect(function()
		finalizarPeelout()
	end)

	-- ==========================================
	-- FASE 1: CARGA (El jugador se queda quieto)
	-- ==========================================
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	if rootPart:FindFirstChild("PeeloutAtt") then rootPart.PeeloutAtt:Destroy() end
	if rootPart:FindFirstChild("PeeloutVel") then rootPart.PeeloutVel:Destroy() end

	local animacion = Instance.new("Animation")
	animacion.AnimationId = obtenerAnimacionCorrer(character)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animTrack = animator:LoadAnimation(animacion)
		animTrack:Play()
	end

	-- Bucle de carga: Aumenta la velocidad de la animación progresivamente
	local t = 0
	while t < tiempoCarga and isPeelouting and humanoid.Health > 0 do
		local dt = task.wait()
		t = t + dt
		if animTrack then
			animTrack:AdjustSpeed(1 + (t / tiempoCarga) * 3) 
		end
	end

	-- Si el jugador canceló o murió durante la carga, no continuamos
	if not isPeelouting or humanoid.Health <= 0 then return end

	-- ==========================================
	-- FASE 2: IMPULSO (Sale disparado)
	-- ==========================================
	local attachment = Instance.new("Attachment")
	attachment.Name = "PeeloutAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PeeloutVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(40000, 0, 40000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		linearVelocity.VectorVelocity = rootPart.CFrame.LookVector * peeloutVelocidad
	end)

	task.delay(tiempoPeelout, function()
		finalizarPeelout()
	end)

	-- FASE DE INICIO
	-- Evitamos que el jugador camine normal mientras es impulsado por la fuerza
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Limpieza de fuerzas anteriores por seguridad
	if rootPart:FindFirstChild("PeeloutAtt") then rootPart.PeeloutAtt:Destroy() end
	if rootPart:FindFirstChild("PeeloutVel") then rootPart.PeeloutVel:Destroy() end

	-- Creamos la fuerza lineal
	local attachment = Instance.new("Attachment")
	attachment.Name = "PeeloutAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PeeloutVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(40000, 0, 40000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = rootPart

	-- Reproducir la animación de correr muy rápido
	local animacion = Instance.new("Animation")
	animacion.AnimationId = obtenerAnimacionCorrer(character)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animTrack = animator:LoadAnimation(animacion)
		animTrack:Play()
		animTrack:AdjustSpeed(4) -- Hacemos que la animación de correr se vea súper rápida
	end

	-- Aplicar el impulso constantemente en la dirección a la que miras
	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		linearVelocity.VectorVelocity = rootPart.CFrame.LookVector * peeloutVelocidad
	end)

	-- Terminar la habilidad automáticamente después del tiempo establecido
	task.delay(tiempoPeelout, function()
		finalizarPeelout()
	end)
	-- FASE 1: CARGA
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	if rootPart:FindFirstChild("PeeloutAtt") then rootPart.PeeloutAtt:Destroy() end
	if rootPart:FindFirstChild("PeeloutVel") then rootPart.PeeloutVel:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "PeeloutAtt"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "PeeloutVel"
	linearVelocity.Attachment0 = attachment
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(100000, 0, 100000) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	linearVelocity.Parent = rootPart

	local animacion = Instance.new("Animation")
	animacion.AnimationId = obtenerAnimacionCorrer(character)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		animTrack = animator:LoadAnimation(animacion)
		animTrack:Play()
	end

	local t = 0
	while t < tiempoCarga and isPeelouting and humanoid.Health > 0 do
		local dt = task.wait()
		t = t + dt
		if animTrack then
			animTrack:AdjustSpeed(1 + (t / tiempoCarga) * 3) 
		end
	end

	if not isPeelouting or humanoid.Health <= 0 then return end

	-- FASE 2: IMPULSO
	-- Nos volvemos intangibles para otros jugadores (evita que tapen el paso)
	crearHitboxFantasma(character)

	linearVelocity.MaxAxesForce = Vector3.new(40000, 0, 40000) 

	renderSteppedConnection = RunService.RenderStepped:Connect(function()
		linearVelocity.VectorVelocity = rootPart.CFrame.LookVector * peeloutVelocidad
		-- BORRAMOS lo del CFrame del enemigo aquí, el servidor se encargará de eso.
	end)

	-- En tu evento Touched (aprox. línea 281)
	touchConnection = rootPart.Touched:Connect(function(hit)
		if not isPeelouting then return end

		local enemigoChar = hit.Parent
		if enemigoChar == character then return end 

		local enemigoHum = enemigoChar:FindFirstChildOfClass("Humanoid")
		local enemigoRoot = enemigoChar:FindFirstChild("HumanoidRootPart")

		if enemigoHum and enemigoRoot then
			if os.clock() - ultimoAgarre < tiempoEsperaAgarre then return end

			-- ¡AQUÍ ESTÁ LA MAGIA! Si no tenemos a nadie, lo agarramos y avisamos al servidor
			if jugadorAgarrado == nil then
				jugadorAgarrado = enemigoChar
				ultimoAgarre = os.clock() 

				-- Disparamos el RemoteEvent hacia el servidor
				agarrarJugador(enemigoChar) 
			end
		end
	end)

	task.delay(tiempoPeelout, function()
		finalizarPeelout()
	end)
end)
