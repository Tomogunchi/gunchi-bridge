-- the client file defines some of these too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local framework = Bridge.DetectFramework()
Bridge.Framework = framework

local QBCore, ESX, NDCore
if framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
elseif framework == 'nd' then
    NDCore = exports[Bridge.ResourceStarted('ND_Core') and 'ND_Core' or 'nd_core']
end

-- raw framework player. shape differs per framework (qbx/qb share PlayerData,
-- esx gives an xPlayer, nd gives an nd player), so prefer the helpers below
-- over poking at this directly
function Bridge.GetPlayer(src)
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    elseif framework == 'esx' then
        return ESX.GetPlayerFromId(src)
    elseif framework == 'nd' then
        return NDCore:getPlayer(src)
    end
    return nil
end

function Bridge.GetIdentifier(src)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getIdentifier() or nil
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        return player and tostring(player.id) or nil
    elseif framework == 'standalone' then
        return GetPlayerIdentifierByType(src, 'license')
    end
    local Player = Bridge.GetPlayer(src)
    if not Player then return nil end
    return Player.PlayerData and Player.PlayerData.citizenid or nil
end

function Bridge.GetPlayerName(src)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getName() or ('Unknown (%s)'):format(src)
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        return player and player.fullname or ('Unknown (%s)'):format(src)
    elseif framework == 'standalone' then
        return GetPlayerName(src) or ('Unknown (%s)'):format(src)
    end
    local Player = Bridge.GetPlayer(src)
    if not Player or not Player.PlayerData then
        return ('Unknown (%s)'):format(src)
    end
    local ci = Player.PlayerData.charinfo
    if ci then
        return ('%s %s'):format(ci.firstname or '', ci.lastname or '')
    end
    return Player.PlayerData.name or ('Player %s'):format(src)
end

-- every online player keyed by source. values are raw framework players so
-- same caveat as GetPlayer
function Bridge.GetPlayers()
    if framework == 'qbx' then
        return exports.qbx_core:GetQBPlayers()
    elseif framework == 'qb' then
        return QBCore.Functions.GetQBPlayers()
    elseif framework == 'esx' then
        local players = {}
        for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
            players[xPlayer.source] = xPlayer
        end
        return players
    elseif framework == 'nd' then
        local players = {}
        for _, player in pairs(NDCore:getPlayers()) do
            players[player.source] = player
        end
        return players
    end
    return {}
end

-- jobs can be a single name or a list, onDutyOnly defaults to true.
-- esx has no duty on older builds and nd none at all, those count as on duty.
-- standalone checks the gunchi.job.<name> ace so servers can still mark cops:
--   add_ace group.police gunchi.job.police allow
function Bridge.GetPlayersWithJob(jobs, onDutyOnly)
    if type(jobs) == 'string' then jobs = { jobs } end
    if onDutyOnly == nil then onDutyOnly = true end

    local sources = {}

    if framework == 'esx' then
        for i = 1, #jobs do
            for _, xPlayer in pairs(ESX.GetExtendedPlayers('job', jobs[i])) do
                if not onDutyOnly or xPlayer.job.onDuty ~= false then
                    sources[#sources + 1] = xPlayer.source
                end
            end
        end
        return sources
    elseif framework == 'nd' then
        for i = 1, #jobs do
            for _, player in pairs(NDCore:getPlayers('job', jobs[i], true)) do
                sources[#sources + 1] = player.source
            end
        end
        return sources
    elseif framework == 'standalone' then
        for _, id in pairs(GetPlayers()) do
            for i = 1, #jobs do
                if IsPlayerAceAllowed(id, ('gunchi.job.%s'):format(jobs[i])) then
                    sources[#sources + 1] = tonumber(id)
                    break
                end
            end
        end
        return sources
    end

    local wanted = {}
    for i = 1, #jobs do wanted[jobs[i]] = true end

    for src, Player in pairs(Bridge.GetPlayers()) do
        local job = Player.PlayerData and Player.PlayerData.job
        if job and wanted[job.name] and (not onDutyOnly or job.onduty) then
            sources[#sources + 1] = tonumber(src)
        end
    end
    return sources
end

---@param src number
---@param job string
---@param grade? number minimum grade
---@param onDuty? boolean
function Bridge.HasJob(src, job, grade, onDuty)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        local pjob = xPlayer.getJob()
        if pjob.name ~= job then return false end
        if grade and (pjob.grade or 0) < grade then return false end
        if onDuty and pjob.onDuty == false then return false end
        return true
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        if not player then return false end
        local group = player.getGroup(job)
        if not group then return false end
        if grade and (group.rank or 0) < grade then return false end
        -- nd has no duty system
        return true
    elseif framework == 'standalone' then
        return IsPlayerAceAllowed(tostring(src), ('gunchi.job.%s'):format(job))
    end

    local Player = Bridge.GetPlayer(src)
    local pjob = Player and Player.PlayerData and Player.PlayerData.job
    if not pjob or pjob.name ~= job then return false end
    if grade then
        local level = pjob.grade and (pjob.grade.level or pjob.grade) or 0
        if level < grade then return false end
    end
    if onDuty and not pjob.onduty then return false end
    return true
end

-- money. account is 'cash' or 'bank' ('cash' maps to esx 'money').
-- standalone has no wallet so Add/Remove fail and Get comes back 0, keep that
-- in mind if a script sells stuff

local function esxAccount(account)
    return account == 'cash' and 'money' or account
end

---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason? string
function Bridge.AddMoney(src, account, amount, reason)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        xPlayer.addAccountMoney(esxAccount(account), amount, reason)
        return true
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        if not player then return false end
        player.addMoney(account, amount, reason)
        return true
    elseif framework == 'standalone' then
        return false
    end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false end
    Player.Functions.AddMoney(account, amount, reason)
    return true
end

---@param src number
---@param account 'cash'|'bank'
---@param amount number
---@param reason? string
function Bridge.RemoveMoney(src, account, amount, reason)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        -- old esx happily goes negative, check ourselves
        local acc = xPlayer.getAccount(esxAccount(account))
        if not acc or acc.money < amount then return false end
        xPlayer.removeAccountMoney(esxAccount(account), amount, reason)
        return true
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        if not player then return false end
        return player.deductMoney(account, amount, reason) and true or false
    elseif framework == 'standalone' then
        return false
    end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.RemoveMoney(account, amount, reason) and true or false
end

---@param src number
---@param account 'cash'|'bank'
function Bridge.GetMoney(src, account)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return 0 end
        local acc = xPlayer.getAccount(esxAccount(account))
        return acc and acc.money or 0
    elseif framework == 'nd' then
        local player = NDCore:getPlayer(src)
        return player and player[account] or 0
    elseif framework == 'standalone' then
        return 0
    end

    local Player = Bridge.GetPlayer(src)
    if not Player or not Player.PlayerData then return 0 end
    local money = Player.PlayerData.money
    return money and money[account] or 0
end