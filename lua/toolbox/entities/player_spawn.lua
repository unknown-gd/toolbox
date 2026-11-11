---@class toolbox_player_spawn : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Player Spawn",
    description = "Customizable player spawn point with enable/disable and optional team / SteamID filters.",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/player_start.vmt",
    size = { min = "-16 -16 -16", max = "16 16 16" },
    keyvalues = {
        { name = "enabled", type = "boolean", default = 1, description = "Whether this spawn can be selected" },
        { name = "team", type = "integer", default = -1, description = "Required team index, or -1 for any" },
        { name = "steamid", type = "string", default = "", description = "Optional SteamID/SteamID64 whitelist (comma-separated)" },
        { name = "priority", type = "integer", default = 0, description = "Higher priority spawns are preferred" }
    },
    inputs = {
        { name = "InEnable", type = "nil", description = "Enables this spawn point" },
        { name = "InDisable", type = "nil", description = "Disables this spawn point" },
        { name = "InToggle", type = "nil", description = "Toggles enabled state" },
        { name = "InForceSpawn", type = "nil", description = "Teleports/spawns the activator at this point" }
    },
    outputs = {
        { name = "OnSpawn", type = "nil", description = "Fired when a player spawns here" }
    }
}

---@type toolbox_player_spawn[]
local spawns = {}
local spawn_count = 0

function ENT:Initialize()
    if self.m_bEnabled == nil then self.m_bEnabled = true end
    if self.m_iTeam == nil then self.m_iTeam = -1 end
    if self.m_strSteamIDs == nil then self.m_strSteamIDs = "" end
    if self.m_iPriority == nil then self.m_iPriority = 0 end
    if self.m_tSteamIDs == nil then
        ---@type table<string, boolean>
        self.m_tSteamIDs = {}
    end

    spawn_count = spawn_count + 1
    spawns[ spawn_count ] = self
end

function ENT:OnRemove()
    for i = spawn_count, 1, -1 do
        if spawns[ i ] == self then
            table.remove( spawns, i )
            spawn_count = spawn_count - 1
        end
    end
end

---@param self toolbox_player_spawn
---@param list string
local function parse_steamids( self, list )
    ---@type table<string, boolean>
    local map = {}
    for id in string.gmatch( tostring( list or "" ), "[^,;]+" ) do
        id = string.Trim( id )
        if id ~= "" then
            map[ id ] = true
        end
    end
    self.m_tSteamIDs = map
    self.m_strSteamIDs = list
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
end

function ENT:KeyValue_team( value )
    self.m_iTeam = tonumber( value, 10 ) or -1
end

function ENT:KeyValue_steamid( value )
    parse_steamids( self, value )
end

function ENT:KeyValue_priority( value )
    self.m_iPriority = tonumber( value, 10 ) or 0
end

function ENT:InEnable()
    self.m_bEnabled = true
end

function ENT:InDisable()
    self.m_bEnabled = false
end

function ENT:InToggle()
    self.m_bEnabled = not self.m_bEnabled
end

---@param pl Player
---@return boolean
function ENT:CanSpawn( pl )
    if not self.m_bEnabled then
        return false
    end

    if self.m_iTeam ~= -1 and pl:Team() ~= self.m_iTeam then
        return false
    end

    if next( self.m_tSteamIDs ) ~= nil then
        local sid = pl:SteamID()
        local sid64 = pl:SteamID64()
        if not self.m_tSteamIDs[ sid ] and not self.m_tSteamIDs[ sid64 ] then
            return false
        end
    end

    return true
end

---@param activator Entity
function ENT:InForceSpawn( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    activator:SetPos( self:GetPos() )
    activator:SetEyeAngles( self:GetAngles() )
    self:FireOutput( "OnSpawn", activator )
end

---@param pl Player
---@return Entity | nil
local function pick_spawn( pl )
    ---@type toolbox_player_spawn | nil
    local best = nil
    local best_priority = -math.huge

    for i = 1, spawn_count do
        local ent = spawns[ i ]
        if ent:CanSpawn( pl ) and ent.m_iPriority >= best_priority then
            best = ent
            best_priority = ent.m_iPriority
        end
    end

    return best
end

hook.Add( "PlayerSelectSpawn", "toolbox::PlayerSpawn", function( pl )
    local spawn = pick_spawn( pl )
    if spawn == nil then
        return
    end

    spawn:FireOutput( "OnSpawn", pl )
    return spawn
end )
