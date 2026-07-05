local target = Bridge.DetectTarget()
Bridge.TargetName = target

Bridge.Target = {}

local zoneCounter = 0

local function nextName()
    zoneCounter = zoneCounter + 1
    return ('gunchi_zone_%d'):format(zoneCounter)
end

-- Add*Zone takes:
--   coords, radius (sphere) or size + heading (box)
--   label, icon, distance, onSelect, canInteract, debug
-- and returns a handle table, hang onto it and pass it back to RemoveZone

local function buildOxOptions(data)
    return {
        {
            name = data.name,
            label = data.label,
            icon = data.icon,
            distance = data.distance or (data.radius or 2.0),
            canInteract = data.canInteract,
            onSelect = data.onSelect,
        }
    }
end

local function buildQbOptions(data)
    return {
        {
            label = data.label,
            icon = data.icon,
            action = function()
                if data.canInteract and not data.canInteract() then return end
                data.onSelect()
            end,
            canInteract = data.canInteract and function()
                return data.canInteract()
            end or nil,
        }
    }
end

-- sleepless takes ox style options, distance is called activeDistance there
local function buildInteractOptions(data)
    return {
        {
            name = data.name,
            label = data.label,
            icon = data.icon,
            activeDistance = data.distance or (data.radius or 2.0),
            canInteract = data.canInteract,
            onSelect = data.onSelect,
        }
    }
end

function Bridge.Target.AddSphereZone(data)
    if target == 'ox' then
        local id = exports.ox_target:addSphereZone({
            coords = data.coords,
            radius = data.radius or 2.0,
            debug = data.debug or false,
            options = buildOxOptions(data),
        })
        return { type = 'ox', id = id }
    elseif target == 'qb' then
        local name = nextName()
        exports['qb-target']:AddCircleZone(name, data.coords, data.radius or 2.0, {
            name = name,
            useZ = true,
            debugPoly = data.debug or false,
        }, {
            options = buildQbOptions(data),
            distance = data.distance or (data.radius or 2.0),
        })
        return { type = 'qb', id = name }
    elseif target == 'interact' then
        local id = exports.sleepless_interact:addCoords(data.coords, buildInteractOptions(data))
        return { type = 'interact', id = id }
    end
    return { type = 'none' }
end

function Bridge.Target.AddBoxZone(data)
    if target == 'ox' then
        local id = exports.ox_target:addBoxZone({
            coords = data.coords,
            size = data.size or vec3(2.0, 2.0, 2.0),
            rotation = data.heading or 0.0,
            debug = data.debug or false,
            options = buildOxOptions(data),
        })
        return { type = 'ox', id = id }
    elseif target == 'qb' then
        local name = nextName()
        local size = data.size or vec3(2.0, 2.0, 2.0)
        exports['qb-target']:AddBoxZone(name, data.coords, size.x, size.y, {
            name = name,
            heading = data.heading or 0.0,
            minZ = data.coords.z - (size.z / 2),
            maxZ = data.coords.z + (size.z / 2),
            debugPoly = data.debug or false,
        }, {
            options = buildQbOptions(data),
            distance = data.distance or 2.0,
        })
        return { type = 'qb', id = name }
    elseif target == 'interact' then
        -- sleepless has no boxes, closest thing is a point at the centre
        local id = exports.sleepless_interact:addCoords(data.coords, buildInteractOptions(data))
        return { type = 'interact', id = id }
    end
    return { type = 'none' }
end

function Bridge.Target.RemoveZone(handle)
    if not handle then return end
    if handle.type == 'ox' then
        exports.ox_target:removeZone(handle.id)
    elseif handle.type == 'qb' then
        exports['qb-target']:RemoveZone(handle.id)
    elseif handle.type == 'interact' then
        exports.sleepless_interact:removeCoords(handle.id)
    end
end

-- entity/model targeting. Add* returns the option name, pass that plus the
-- same entities/models back into the matching Remove*.
-- onSelect and canInteract both get called with the entity.

local optionCounter = 0
local qbOptionLabels = {} -- qb-target removes by label, so remember them

local function entityOptions(data)
    optionCounter = optionCounter + 1
    local name = data.name or ('gunchi_opt_%d'):format(optionCounter)
    local option = {
        name = name,
        label = data.label,
        icon = data.icon,
        distance = data.distance or 2.0,
        activeDistance = data.distance or 2.0,
        onSelect = function(selected)
            -- ox/sleepless hand us a table with .entity on it, qb gives the entity
            data.onSelect(type(selected) == 'table' and selected.entity or selected)
        end,
        canInteract = data.canInteract and function(entity)
            return data.canInteract(entity)
        end or nil,
    }
    qbOptionLabels[name] = data.label
    return name, { option }
end

local function qbEntityOptions(data)
    return {
        options = {
            {
                label = data.label,
                icon = data.icon,
                action = function(entity)
                    data.onSelect(entity)
                end,
                canInteract = data.canInteract and function(entity)
                    return data.canInteract(entity)
                end or nil,
            }
        },
        distance = data.distance or 2.0,
    }
end

function Bridge.Target.AddLocalEntity(entities, data)
    local name, options = entityOptions(data)
    if target == 'ox' then
        exports.ox_target:addLocalEntity(entities, options)
    elseif target == 'qb' then
        ---@diagnostic disable-next-line: redundant-parameter
        exports['qb-target']:AddTargetEntity(entities, qbEntityOptions(data))
    elseif target == 'interact' then
        exports.sleepless_interact:addLocalEntity(entities, options)
    end
    return name
end

function Bridge.Target.RemoveLocalEntity(entities, name)
    if target == 'ox' then
        exports.ox_target:removeLocalEntity(entities, name)
    elseif target == 'qb' then
        local label = qbOptionLabels[name]
        if label then
            exports['qb-target']:RemoveTargetEntity(entities, label)
        end
    elseif target == 'interact' then
        exports.sleepless_interact:removeLocalEntity(entities, name)
    end
end

function Bridge.Target.AddModel(models, data)
    local name, options = entityOptions(data)
    if target == 'ox' then
        exports.ox_target:addModel(models, options)
    elseif target == 'qb' then
        ---@diagnostic disable-next-line: redundant-parameter
        exports['qb-target']:AddTargetModel(models, qbEntityOptions(data))
    elseif target == 'interact' then
        exports.sleepless_interact:addModel(models, options)
    end
    return name
end

function Bridge.Target.RemoveModel(models, name)
    if target == 'ox' then
        exports.ox_target:removeModel(models, name)
    elseif target == 'qb' then
        local label = qbOptionLabels[name]
        if label then
            exports['qb-target']:RemoveTargetModel(models, label)
        end
    elseif target == 'interact' then
        exports.sleepless_interact:removeModel(models, name)
    end
end