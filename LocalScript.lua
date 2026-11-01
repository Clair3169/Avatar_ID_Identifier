-- Esperamos a que el jugador, el personaje y el humanoide estén cargados
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Obtenemos el HumanoidDescription actual del avatar
local description = humanoid:GetAppliedDescription()

if not description then
    warn("No se pudo obtener la información del avatar.")
    return
end

print("⏳ Extrayendo IDs de tu avatar, revisando el catálogo... por favor espera.")

-- FUNCIÓN NUEVA: Convierte un ID de malla/asset en el ID de compra real (Bundle)
local function getRealId(assetId)
    if not assetId or assetId == 0 then return 0 end
    
    -- Método 1: Usamos game:HttpGet (Súper rápido en ejecutores para buscar en el catálogo)
    local success, result = pcall(function()
        local url = "https://catalog.roblox.com/v1/assets/" .. tostring(assetId) .. "/bundles"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        if data and data.data and #data.data > 0 then
            return data.data[1].id -- Retorna el ID del paquete real que puedes comprar
        end
    end)
    
    if success and result then return result end
    
    -- Método 2 (Respaldo): Si el ejecutor no soporta HttpGet, usamos la API de Roblox
    local success2, result2 = pcall(function()
        local pages = AvatarEditorService:GetBundlesByAssetIdAsync(assetId)
        local currentPage = pages:GetCurrentPage()
        if currentPage and #currentPage > 0 then
            return currentPage[1].id
        end
    end)
    
    if success2 and result2 then return result2 end
    
    -- Si no es un Bundle (por ejemplo, es un accesorio clásico), devuelve el ID normal
    return assetId
end

local output = {}
table.insert(output, "=== REPORTE DE AVATAR DE " .. player.Name .. " ===")
table.insert(output, "")

-- 1. ACCESORIOS Y ROPA 3D (Layered Clothing)
table.insert(output, "[ACCESORIOS Y ROPA 3D]")
local accessories = description:GetAccessories(true) 
local accCount = 0

for _, acc in pairs(accessories) do
    if acc.AssetId and acc.AssetId > 0 then
        local accName = acc.AccessoryType and acc.AccessoryType.Name or "Accesorio"
        table.insert(output, " - " .. tostring(accName) .. ": " .. tostring(acc.AssetId))
        accCount = accCount + 1
    end
end

if accCount == 0 then
    table.insert(output, " - Ninguno")
end
table.insert(output, "")

-- 2. ROPA 2D (Camisas, Pantalones, Camisetas)
table.insert(output, "[ROPA 2D (Classic)]")
local has2D = false
if description.Shirt > 0 then 
    table.insert(output, " - Camisa (Shirt): " .. tostring(description.Shirt)) 
    has2D = true
end
if description.Pants > 0 then 
    table.insert(output, " - Pantalones (Pants): " .. tostring(description.Pants)) 
    has2D = true
end
if description.GraphicTShirt > 0 then 
    table.insert(output, " - Camiseta (T-Shirt): " .. tostring(description.GraphicTShirt)) 
    has2D = true
end

if not has2D then
    table.insert(output, " - Ninguna")
end
table.insert(output, "")

-- 3. PAQUETE DE CUERPO Y CABEZAS 3D DINÁMICAS
table.insert(output, "[PARTES DEL CUERPO Y CABEZA]")
local bodyParts = {
    ["Cabeza (Head)"] = description.Head,
    ["Torso"] = description.Torso,
    ["Brazo Izquierdo (LeftArm)"] = description.LeftArm,
    ["Brazo Derecho (RightArm)"] = description.RightArm,
    ["Pierna Izquierda (LeftLeg)"] = description.LeftLeg,
    ["Pierna Derecha (RightLeg)"] = description.RightLeg
}
local partCount = 0

for partName, assetId in pairs(bodyParts) do
    if assetId > 0 then 
        -- AQUÍ ACTÚA EL ARREGLO: Extraemos el Bundle ID si es que pertenece a un paquete
        local realId = getRealId(assetId)
        local note = (realId ~= assetId) and " (ID de Tienda/Bundle)" or ""
        table.insert(output, " - " .. partName .. ": " .. tostring(realId) .. note)
        partCount = partCount + 1
    end
end

if partCount == 0 then
    table.insert(output, " - Default de Roblox (Se omite)")
end
table.insert(output, "")

-- 4. ANIMACIONES (Solo para R15)
table.insert(output, "[ANIMACIONES]")
if humanoid.RigType == Enum.HumanoidRigType.R15 then
    local animations = {
        ["Inactivo (Idle)"] = description.IdleAnimation,
        ["Caminar (Walk)"] = description.WalkAnimation,
        ["Correr (Run)"] = description.RunAnimation,
        ["Saltar (Jump)"] = description.JumpAnimation,
        ["Caer (Fall)"] = description.FallAnimation,
        ["Escalar (Climb)"] = description.ClimbAnimation,
        ["Nadar (Swim)"] = description.SwimAnimation
    }
    local animCount = 0

    for animName, assetId in pairs(animations) do
        if assetId > 0 then
            -- LAS ANIMACIONES TAMBIÉN SE VENDEN COMO BUNDLE: Aplicamos el mismo arreglo
            local realId = getRealId(assetId)
            local note = (realId ~= assetId) and " (ID de Paquete)" or ""
            table.insert(output, " - " .. animName .. ": " .. tostring(realId) .. note)
            animCount = animCount + 1
        end
    end

    if animCount == 0 then
        table.insert(output, " - Default de Roblox (Sin ID custom)")
    end
else
    table.insert(output, " - Omitido (El avatar está utilizando el formato R6)")
end

table.insert(output, "")
table.insert(output, "=============================================")

-- Unificamos todo el texto
local finalString = table.concat(output, "\n")

-- 5. RESULTADOS (Print y Portapapeles)
print("\n" .. finalString)

if setclipboard then
    setclipboard(finalString)
    print("✅ ¡La información ha sido copiada! Ya puedes pegarla en tu Bloc de Notas.")
else
    warn("❌ Tu ejecutor no soporta setclipboard. Cópialo manual desde aquí.")
end
