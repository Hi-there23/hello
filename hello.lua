-- ====================================================================
-- SCRIPT COMPLETO DEFINITIVO: FIX TOTAL POST-VOLTERETA + LERP + RÉPLICA
-- ====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- --- CONFIGURACIÓN DE PARÁMETROS SOLICITADOS ---
local VELOCIDAD_CAMINAR = 5.5
local VELOCIDAD_CORRER = 18.5
local ALTURA_MINIMA_VOLTERETA = 15.5 

-- --- ID OFICIAL DEL CATÁLOGO DE ROBLOX ---
local ID_CATALOGO_OFICIAL = 18537367238 

-- --- INTERFAZ TÁCTIL PRINCIPAL ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2MovilPerfeccionado"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

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

-- Sincronización continua de posición del candado en la pantalla
RunService.RenderStepped:Connect(function()
	if RunButton and LockLabel then
		LockLabel.Position = UDim2.new(RunButton.Position.X.Scale, RunButton.Position.X.Offset + 50, RunButton.Position.Y.Scale, RunButton.Position.Y.Offset - 22)
	end
end)

-- --- SISTEMA DE MOVIMIENTO CON ACELERACIÓN SUAVE ---
local esSprinting = false

local function configurarPersonaje(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = VELOCIDAD_CAMINAR

	-- BUCLE DE ACELERACIÓN Y DESACELERACIÓN SUAVE (LERP)
	task.spawn(function()
		local factorSuavizadoMovimiento = 0.15 
		while character and character.Parent and humanoid and humanoid.Health > 0 do
			local velocidadObjetivo = esSprinting and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR

			if math.abs(humanoid.WalkSpeed - velocidadObjetivo) > 0.05 then
				humanoid.WalkSpeed = humanoid.WalkSpeed + (velocidadObjetivo - humanoid.WalkSpeed) * factorSuavizadoMovimiento
			else
				humanoid.WalkSpeed = velocidadObjetivo
			end
			task.wait(0.02) 
		end
	end)
end

-- Lógica táctil avanzada del botón
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

-- --- CONTROLADOR DE CÁMARA, RAYCASTING Y DETECTOR DINÁMICO DE ANIMACIÓN ---
local conexionCamara

local function iniciarFisicasAvanzadas(character)
	local torso = character:WaitForChild("UpperTorso", 5) or character:WaitForChild("Torso", 5)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local animateScript = character:WaitForChild("Animate", 5)
	if not torso or not humanoid or not rootPart then return end

	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = humanoid 

	-- Guardar IDs originales de forma segura una sola vez al cargar
	local idCaminataOriginal = nil
	local idCarreraOriginal = nil

	if animateScript then
		pcall(function()
			idCaminataOriginal = animateScript.walk.WalkAnim.AnimationId
			idCarreraOriginal = animateScript.run.RunAnim.AnimationId
		end)
	end

	-- Carga de animación de la voltereta
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

	-- Función auxiliar interna para forzar de inmediato los valores correctos de animación
	local function forzarAnimacionesSegunEstado()
		if animateScript and idCaminataOriginal and idCarreraOriginal then
			pcall(function()
				if esSprinting then
					animateScript.run.RunAnim.AnimationId = idCaminataOriginal
					animateScript.walk.WalkAnim.AnimationId = idCaminataOriginal
				else
					animateScript.walk.WalkAnim.AnimationId = idCarreraOriginal
					animateScript.run.RunAnim.AnimationId = idCarreraOriginal
				end
			end)
		end
	end

	conexionCamara = RunService.RenderStepped:Connect(function()
		if not torso or not torso.Parent or not humanoid then
			conexionCamara:Disconnect()
			return
		end

		-- 1. DETECTOR DINÁMICO DE SHIFT LOCK
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

		-- INYECTOR ANTIBUG CONTINUO
		if not ejecutandoVoltereta then
			forzarAnimacionesSegunEstado()
		end

		-- 2. ESCÁNER LÁSER DETECTOR DE IMPACTOS (RAYCASTING)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local resultadoRaycast = Workspace:Raycast(rootPart.Position, Vector3.new(0, -3.5, 0), raycastParams)

		if not resultadoRaycast then
			enElAire = true
			if rootPart.Position.Y > puntoMasAlto then
				puntoMasAlto = rootPart.Position.Y 
			end
		else
			if enElAire and not ejecutandoVoltereta then
				enElAire = false
				local distanciaCaida = puntoMasAlto - rootPart.Position.Y

				if distanciaCaida >= ALTURA_MINIMA_VOLTERETA then
					ejecutandoVoltereta = true

					if usaPoderOAltura then
						humanoid.JumpPower = 0
					else
						humanoid.JumpHeight = 0
					end

					trackVoltereta:Stop()
					trackVoltereta:Play() 

					local attachment = Instance.new("Attachment")
					attachment.Parent = rootPart

					local impulso = Instance.new("LinearVelocity")
					impulso.Attachment0 = attachment
					impulso.MaxForce = 35000 
					impulso.VectorVelocity = (rootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 48
					impulso.Parent = rootPart

					task.spawn(function()
						task.wait(0.25) 

						impulso:Destroy()
						attachment:Destroy()
						trackVoltereta:Stop(0.1)

						humanoid.WalkSpeed = 3
						task.wait(0.25)

						if usaPoderOAltura then
							humanoid.JumpPower = poderSaltoOriginal
						else
							humanoid.JumpHeight = poderSaltoOriginal
						end

						-- REVISIÓN DE SEGURIDAD POST-VOLTERETA: Forzar estado actual inmediatamente
						humanoid.WalkSpeed = esSprinting and VELOCIDAD_CORRER or VELOCIDAD_CAMINAR
						forzarAnimacionesSegunEstado() -- Corrige el bug de quedarse pegado en animación incorrecta

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

if LocalPlayer.Character then
	configurarPersonaje(LocalPlayer.Character)
	iniciarFisicasAvanzadas(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(nuevoChar)
	configurarPersonaje(nuevoChar)
	iniciarFisicasAvanzadas(nuevoChar)
end)
