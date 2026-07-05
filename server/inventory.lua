local inventory = Bridge.DetectInventory()
Bridge.InventoryName = inventory

Bridge.Inventory = {}

local function qbInvStarted()
    return Bridge.ResourceStarted('qb-inventory')
end

function Bridge.Inventory.AddItem(src, item, amount, metadata)
    amount = amount or 1
    if inventory == 'ox' then
        local success = exports.ox_inventory:AddItem(src, item, amount, metadata)
        return success and true or false
    elseif inventory == 'qb' then
        if qbInvStarted() then
            return exports['qb-inventory']:AddItem(src, item, amount, false, metadata) and true or false
        end
        local Player = Bridge.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.AddItem(item, amount, false, metadata) and true or false
    elseif inventory == 'tgiann' then
        return exports['tgiann-inventory']:AddItem(src, item, amount, nil, metadata, false) and true or false
    elseif inventory == 'origen' then
        return exports.origen_inventory:addItem(src, item, amount, metadata) and true or false
    elseif inventory == 'esx' then
        -- built in esx inventory, no metadata support
        local xPlayer = Bridge.GetPlayer(src)
        if not xPlayer then return false end
        if not Bridge.Inventory.CanCarryItem(src, item, amount) then return false end
        xPlayer.addInventoryItem(item, amount)
        return true
    end
    return false
end

function Bridge.Inventory.RemoveItem(src, item, amount)
    amount = amount or 1
    if inventory == 'ox' then
        local success = exports.ox_inventory:RemoveItem(src, item, amount)
        return success and true or false
    elseif inventory == 'qb' then
        if qbInvStarted() then
            return exports['qb-inventory']:RemoveItem(src, item, amount) and true or false
        end
        local Player = Bridge.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, amount) and true or false
    elseif inventory == 'tgiann' then
        return exports['tgiann-inventory']:RemoveItem(src, item, amount) and true or false
    elseif inventory == 'origen' then
        return exports.origen_inventory:removeItem(src, item, amount) and true or false
    elseif inventory == 'esx' then
        local xPlayer = Bridge.GetPlayer(src)
        if not xPlayer then return false end
        local data = xPlayer.getInventoryItem(item)
        if not data or data.count < amount then return false end
        xPlayer.removeInventoryItem(item, amount)
        return true
    end
    return false
end

function Bridge.Inventory.GetItemCount(src, item)
    if inventory == 'ox' then
        return exports.ox_inventory:Search(src, 'count', item) or 0
    elseif inventory == 'qb' then
        local Player = Bridge.GetPlayer(src)
        if not Player then return 0 end
        local data = Player.Functions.GetItemByName(item)
        return data and data.amount or 0
    elseif inventory == 'tgiann' then
        -- no count export, add up the slots ourselves
        local items = exports['tgiann-inventory']:GetPlayerItems(src)
        if not items then return 0 end
        local count = 0
        for _, data in pairs(items) do
            if data.name == item then
                count = count + (data.count or data.amount or 0)
            end
        end
        return count
    elseif inventory == 'origen' then
        return exports.origen_inventory:Search(src, 'count', item) or 0
    elseif inventory == 'esx' then
        local xPlayer = Bridge.GetPlayer(src)
        if not xPlayer then return 0 end
        local data = xPlayer.getInventoryItem(item)
        return data and data.count or 0
    end
    return 0
end

function Bridge.Inventory.HasItem(src, item, amount)
    return Bridge.Inventory.GetItemCount(src, item) >= (amount or 1)
end

function Bridge.Inventory.CanCarryItem(src, item, amount)
    amount = amount or 1
    if inventory == 'ox' then
        return exports.ox_inventory:CanCarryItem(src, item, amount) and true or false
    elseif inventory == 'qb' then
        if qbInvStarted() then
            local ok, result = pcall(function()
                return exports['qb-inventory']:CanAddItem(src, item, amount)
            end)
            if ok and result ~= nil then return result and true or false end
        end
        -- old qb-inventory has no capacity check, say yes and let AddItem
        -- be the one that decides
        return true
    elseif inventory == 'tgiann' then
        return exports['tgiann-inventory']:CanCarryItem(src, item, amount) and true or false
    elseif inventory == 'origen' then
        return exports.origen_inventory:CanCarryItem(src, item, amount) and true or false
    elseif inventory == 'esx' then
        local xPlayer = Bridge.GetPlayer(src)
        if not xPlayer then return false end
        -- really old esx has no weight system at all
        local ok, result = pcall(function()
            return xPlayer.canCarryItem(item, amount)
        end)
        if ok and result ~= nil then return result and true or false end
        return true
    end
    return false
end

function Bridge.Inventory.GetItemLabel(item)
    if inventory == 'ox' then
        local data = exports.ox_inventory:Items(item)
        return (data and data.label) or item
    elseif inventory == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local shared = QBCore.Shared.Items[item]
        return (shared and shared.label) or item
    elseif inventory == 'tgiann' then
        local ok, label = pcall(function()
            return exports['tgiann-inventory']:GetItemLabel(item)
        end)
        return (ok and label) or item
    elseif inventory == 'origen' then
        local items = exports.origen_inventory:Items()
        local data = items and items[item]
        return (data and data.label) or item
    elseif inventory == 'esx' then
        local ok, label = pcall(function()
            return exports.es_extended:getSharedObject().GetItemLabel(item)
        end)
        return (ok and label) or item
    end
    return item
end