-- Esperamos a que el jugador, el personaje y el humanoide estén cargados
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Obtenemos el HumanoidDescription actual del avatar
local description = humanoid:GetAppliedDescription()

if not description then
    warn("No se pudo obtener la información del avatar.")
    return
end

print("⏳ Extrayendo información... por favor espera.")

-- Función para buscar el ID de venta (Bundle)
local function getBundleId(assetId)
    if not assetId or assetId == 0 then return nil end
    local success, result = pcall(function()
        local url = "https://catalog.roblox.com/v1/assets/" .. tostring(assetId) .. "/bundles"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        if data and data.data and #data.data > 0 then
            return data.data[1].id
        end
    end)
    return success and result or nil
end

local output = {}
table.insert(output, "=== REPORTE DE AVATAR DE " .. player.Name .. " ===")
table.insert(output, "")

-- 1. ACCESORIOS Y ROPA 3D
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
if accCount == 0 then table.insert(output, " - Ninguno") end
table.insert(output, "")

-- 2. ROPA 2D
table.insert(output, "[ROPA 2D (Classic)]")
local has2D = false
if description.Shirt > 0 then table.insert(output, " - Camisa: " .. tostring(description.Shirt)); has2D = true end
if description.Pants > 0 then table.insert(output, " - Pantalones: " .. tostring(description.Pants)); has2D = true end
if description.GraphicTShirt > 0 then table.insert(output, " - Camiseta: " .. tostring(description.GraphicTShirt)); has2D = true end
if not has2D then table.insert(output, " - Ninguna") end
table.insert(output, "")

-- 3. PAQUETE DE CUERPO Y CABEZAS 3D
table.insert(output, "[PARTES DEL CUERPO Y CABEZA]")
-- CORRECCIÓN: Usamos los nombres correctos de la API de Roblox
local bodyParts = {
    ["Cabeza"] = description.Head,
    ["Torso"] = description.Torso,
    ["Brazo Izq"] = description.LeftArm,
    ["Brazo Der"] = description.RightArm,
    ["Pierna Izq"] = description.LeftLeg,
    ["Pierna Der"] = description.RightLeg
}

local partCount = 0
for partName, assetId in pairs(bodyParts) do
    if assetId > 0 then 
        local bundleId = getBundleId(assetId)
        local displayStr = " - " .. partName .. ": Asset ID [" .. tostring(assetId) .. "]"
        if bundleId then
            displayStr = displayStr .. " | Bundle ID [" .. tostring(bundleId) .. "]"
        end
        table.insert(output, displayStr)
        partCount = partCount + 1
    end
end
if partCount == 0 then table.insert(output, " - Default de Roblox") end
table.insert(output, "")

-- 4. ANIMACIONES
table.insert(output, "[ANIMACIONES]")
if humanoid.RigType == Enum.HumanoidRigType.R15 then
    local anims = {["Idle"]=description.IdleAnimation, ["Walk"]=description.WalkAnimation, ["Run"]=description.RunAnimation, ["Jump"]=description.JumpAnimation, ["Fall"]=description.FallAnimation, ["Climb"]=description.ClimbAnimation, ["Swim"]=description.SwimAnimation}
    for name, id in pairs(anims) do
        if id > 0 then
            local bundleId = getBundleId(id)
            local line = " - " .. name .. ": Asset ID [" .. tostring(id) .. "]"
            if bundleId then line = line .. " | Bundle ID [" .. tostring(bundleId) .. "]" end
            table.insert(output, line)
        end
    end
else
    table.insert(output, " - Omitido (R6)")
end

table.insert(output, "\n=============================================")
local finalString = table.concat(output, "\n")
print("\n" .. finalString)

if setclipboard then
    setclipboard(finalString)
    print("✅ Información copiada.")
end
