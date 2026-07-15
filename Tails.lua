-- SERVICIOS DE ROBLOX
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- VARIABLES PRINCIPALES
local jugador = Players.LocalPlayer
local pantallaGui = nil
local botonVuelo = nil

-- CONFIGURACIÓN DE LA HABILIDAD (Personalizable)
local CAPACIDAD_MAXIMA = 12.5    -- Puntos/Segundos base de la barra de vuelo
local GASTO_IMPULSO = 1.6     -- Multiplicador de gasto al usar el impulso
local SUSPENSION = 2.5        -- Segundos que se queda congelado flotando al llegar a 1 de barra
local COOLDOWN_TOTAL = 24     -- Tiempo de recarga obligatorio de la habilidad
local VELOCIDAD_SUBIDA = 15   -- Fuerza de ascenso con impulso
local VELOCIDAD_BAJADA = -5   -- Caída lenta/flote sin impulso
local ANIMACION_ID = 140528723556419 -- ID del Emote del catálogo


-- VARIABLES DE CONTROL INTERNO
local enCooldown = false
local volando = false
local fuerzaVuelo = nil
local animTrack = nil
local energiaActual = 0
local tiempoInicioVuelo = 0
local conexionBucle = nil
local fondoBarra, barraRelleno = nil, nil
local enSuspension = false
local tiempoSuspensionAcumulado = 0

-- ==========================================
-- 1. CREACIÓN AUTOMÁTICA DE LA INTERFAZ
-- ==========================================
local function inicializarInterfaz()
	local playerGui = jugador:WaitForChild("PlayerGui")

	pantallaGui = Instance.new("ScreenGui")
	pantallaGui.Name = "GuiHabilidadVuelo"
	pantallaGui.ResetOnSpawn = false
	pantallaGui.Parent = playerGui

	botonVuelo = Instance.new("TextButton")
	botonVuelo.Name = "BotonVuelo"
	-- DISEÑO USANDO SCALE (Porcentajes): 13% del ancho de la pantalla, 6.5% del alto
	botonVuelo.Size = UDim2.new(0.13, 0, 0.065, 0)
	-- Posicionado al 85% horizontal y 80% vertical de la pantalla
	botonVuelo.Position = UDim2.new(0.15, 0, 0.8, 0) 
	-- El AnchorPoint en (0.5, 0.5) asegura que el centro del botón se alinee exactamente en esa coordenada
	botonVuelo.AnchorPoint = Vector2.new(0.5, 0.5)
	botonVuelo.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	botonVuelo.TextColor3 = Color3.fromRGB(255, 255, 255)
	botonVuelo.TextSize = 16
	botonVuelo.Font = Enum.Font.SourceSansBold
	botonVuelo.Text = "Volar"
	botonVuelo.Parent = pantallaGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = botonVuelo
end

inicializarInterfaz()

-- ==========================================
-- 2. FUNCIONES AUXILIARES
-- ==========================================	
local function obtenerComponentes()
	local personaje = jugador.Character
	if not personaje then return nil, nil, nil end
	return personaje, personaje:FindFirstChildOfClass("Humanoid"), personaje:FindFirstChild("HumanoidRootPart")
end

local function crearBarraVisual()
	if fondoBarra then fondoBarra:Destroy() end

	fondoBarra = Instance.new("Frame")
	fondoBarra.Size = UDim2.new(0, 200, 0, 12)
	fondoBarra.Position = UDim2.new(0.5, -100, 0.75, 0)
	fondoBarra.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fondoBarra.BorderSizePixel = 0
	fondoBarra.Parent = pantallaGui

	local UICornerFondo = Instance.new("UICorner")
	UICornerFondo.CornerRadius = UDim.new(0, 4)
	UICornerFondo.Parent = fondoBarra

	barraRelleno = Instance.new("Frame")
	barraRelleno.Size = UDim2.new(1, 0, 1, 0)
	barraRelleno.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	barraRelleno.BorderSizePixel = 0
	barraRelleno.Parent = fondoBarra

	local UICornerRelleno = Instance.new("UICorner")
	UICornerRelleno.CornerRadius = UDim.new(0, 4)
	UICornerRelleno.Parent = barraRelleno
end

-- ==========================================
-- 3. FINALIZACIÓN Y SISTEMA DE COOLDOWN NUMÉRICO
-- ==========================================
local function finalizarVuelo(porCancelacionManual)
	volando = false
	enSuspension = false

	if conexionBucle then
		conexionBucle:Disconnect()
		conexionBucle = nil
	end

	if fondoBarra then
		fondoBarra:Destroy()
		fondoBarra = nil
	end

	if animTrack then
		animTrack:Stop(0.2)
		animTrack = nil
	end

	if fuerzaVuelo then
		fuerzaVuelo:Destroy()
		fuerzaVuelo = nil
	end

	-- CONTROL DE COOLDOWN REGRESIVO (Muestra números en pantalla)
	enCooldown = true
	botonVuelo.BackgroundColor3 = Color3.fromRGB(80, 40, 40)

	local tiempoRestante = COOLDOWN_TOTAL
	while tiempoRestante > 0 do
		botonVuelo.Text = string.format("%.1fs", tiempoRestante) -- Muestra formato decimal (ej: 21.5s) [1, 2]
		task.wait(0.1)
		tiempoRestante = tiempoRestante - 0.1
		if not enCooldown then break end -- Seguridad por si el script se reinicia
	end

	enCooldown = false
	botonVuelo.Text = "Volar"
	botonVuelo.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
end

-- ==========================================
-- 4. EJECUCIÓN PRINCIPAL DEL VUELO
-- ==========================================
local function ejecutarVuelo()
	local _, humanoid, rootPart = obtenerComponentes()
	if not humanoid or not rootPart then return end

	volando = true
	enSuspension = false
	energiaActual = CAPACIDAD_MAXIMA
	tiempoInicioVuelo = tick()
	tiempoSuspensionAcumulado = 0

	botonVuelo.Text = "Cancelar"
	botonVuelo.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

	-- Cargar el Emote en bucle continuo
	local animacion = Instance.new("Animation")
	animacion.AnimationId = "http://www.roblox.com/asset/?id=" .. ANIMACION_ID
	animTrack = humanoid:LoadAnimation(animacion)
	animTrack.Priority = Enum.AnimationPriority.Action4
	animTrack.Looped = true
	animTrack:Play()

	-- Configurar la fuerza física en el Eje Y
	local adjunto = rootPart:FindFirstChild("RootAttachment") or Instance.new("Attachment", rootPart)
	fuerzaVuelo = Instance.new("LinearVelocity")
	fuerzaVuelo.MaxForce = math.huge
	fuerzaVuelo.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	fuerzaVuelo.LineDirection = Vector3.new(0, 1, 0)
	fuerzaVuelo.Attachment0 = adjunto
	fuerzaVuelo.Parent = rootPart

	crearBarraVisual()

	-- BUCLE FÍSICO FRAME A FRAME
	conexionBucle = RunService.Heartbeat:Connect(function(deltaTime)
		local _, hum, root = obtenerComponentes()

		-- Seguridad básica de personaje vivo
		if not hum or not root then
			finalizarVuelo(false)
			return
		end

		-- Cancelación automática si caes y tocas el suelo (Excepto si estás en suspensión alta)
		if (tick() - tiempoInicioVuelo) > 0.3 and hum.FloorMaterial ~= Enum.Material.Air then
			finalizarVuelo(false)
			return
		end

		-- LÓGICA CUANDO LA BARRA ENTRA EN FASE DE SUSPENSIÓN (Energía <= 1)
		if energiaActual <= 1 then
			if not enSuspension then
				enSuspension = true
				botonVuelo.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			end

			-- 1. Clavar la velocidad en 0 para que no suba ni baje (Flote estático perfecto) [2, 3]
			fuerzaVuelo.LineVelocity = 0

			-- 2. Consumir el resto de la barra de forma proporcional al tiempo de suspensión elegido
			tiempoSuspensionAcumulado = tiempoSuspensionAcumulado + deltaTime
			energiaActual = 1 - (tiempoSuspensionAcumulado / SUSPENSION)

			-- 3. Cuando la barra toca 0 de forma definitiva, se apaga el vuelo
			if energiaActual <= 0 then
				energiaActual = 0
				if barraRelleno then barraRelleno.Size = UDim2.new(0, 0, 1, 0) end
				finalizarVuelo(false)
				return
			end
		else
			-- COMPORTAMIENTO NORMAL DE VUELO (Por encima de 1 punto de barra)
			local usandoImpulso = UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump

			-- Gasto extra si mantiene pulsado salto
			if usandoImpulso then
				energiaActual = energiaActual - (deltaTime * GASTO_IMPULSO)
			else
				energiaActual = energiaActual - deltaTime
			end

			-- Asignar velocidades normales de vuelo
			if usandoImpulso then
				fuerzaVuelo.LineVelocity = VELOCIDAD_SUBIDA
			else
				fuerzaVuelo.LineVelocity = VELOCIDAD_BAJADA
			end
		end

		-- Actualizar tamaño visual de la barra de progreso en tiempo real
		if barraRelleno then
			local porcentaje = math.clamp(energiaActual / CAPACIDAD_MAXIMA, 0, 1)
			barraRelleno.Size = UDim2.new(porcentaje, 0, 1, 0)
		end
	end)
end

-- ==========================================
-- 5. DETECTORES Y EVENTOS
-- ==========================================
botonVuelo.MouseButton1Click:Connect(function()
	if enCooldown then return end

	if volando then
		-- NUEVO AJUSTE: Si el personaje ya entró en estado de suspensión, se ignora el clic de cancelación
		if enSuspension then 
			return 
		end
		
		finalizarVuelo(true) -- Cancelación manual: Directo al suelo sin flotar
		return
	end

	local _, humanoid, _ = obtenerComponentes()
	if not humanoid then return end

	-- Solo activar si está despegado del piso
	if humanoid.FloorMaterial == Enum.Material.Air then
		ejecutarVuelo()
	else
		local textoOriginal = botonVuelo.Text
		botonVuelo.Text = "¡Salta primero!"
		task.wait(1)
		if not volando and not enCooldown then
			botonVuelo.Text = textoOriginal
		end
	end
end)

-- Limpieza absoluta si el jugador muere
jugador.CharacterAdded:Connect(function()
	if conexionBucle then conexionBucle:Disconnect() conexionBucle = nil end
	if fondoBarra then fondoBarra:Destroy() fondoBarra = nil end
	volando = false
	enCooldown = false
	if botonVuelo then
		botonVuelo.Text = "Volar"
		botonVuelo.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end
end)
