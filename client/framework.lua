-- the server file defines some of these too, that's the point of a bridge
---@diagnostic disable: duplicate-set-field

local framework = Bridge.DetectFramework()
Bridge.Framework = framework

local ESX, NDCore
if framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
elseif framework == 'nd' then
    NDCore = exports[Bridge.ResourceStarted('ND_Core') and 'ND_Core' or 'nd_core']
end

-- raw framework player data, shape differs per framework so prefer GetJob /
-- HasJob below when you just want job info
function Bridge.GetPlayerData()
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayerData()
    elseif framework == 'qb' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
    elseif framework == 'esx' then
        return ESX.GetPlayerData()
    elseif framework == 'nd' then
        return NDCore:getPlayer()
    end
    return nil
end

-- normalised job: { name, label, grade, onDuty }, nil on standalone.
-- esx builds without duty and nd (no duty at all) come back onDuty = true
function Bridge.GetJob()
    local data = Bridge.GetPlayerData()
    if not data then return nil end

    if framework == 'nd' then
        local info = data.jobInfo or {}
        return {
            name = data.job,
            label = info.label or data.job,
            grade = info.rank or 0,
            onDuty = true,
        }
    end

    local job = data.job
    if not job then return nil end

    if framework == 'esx' then
        return {
            name = job.name,
            label = job.label or job.name,
            grade = job.grade or 0,
            onDuty = job.onDuty ~= false,
        }
    end

    return {
        name = job.name,
        label = job.label or job.name,
        grade = job.grade and (job.grade.level or job.grade) or 0,
        onDuty = job.onduty ~= false,
    }
end

---@param job string
---@param grade? number minimum grade
---@param onDuty? boolean
function Bridge.HasJob(job, grade, onDuty)
    if framework == 'nd' then
        -- nd players can hold several jobs through groups
        local data = Bridge.GetPlayerData()
        local group = data and data.groups and data.groups[job]
        if not group then return false end
        if grade and (group.rank or 0) < grade then return false end
        return true
    end

    local pjob = Bridge.GetJob()
    if not pjob or pjob.name ~= job then return false end
    if grade and pjob.grade < grade then return false end
    if onDuty and not pjob.onDuty then return false end
    return true
end

function Bridge.IsDead()
    -- check statebags first so custom death/medical scripts still count
    local st = LocalPlayer.state
    if st then
        if st.isDead or st.dead or st.laststand or st.inLaststand then
            return true
        end
    end
    return IsEntityDead(PlayerPedId())
end