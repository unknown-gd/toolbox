---@class toolbox_spectate : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Spectate",
    description = "Forces players into spectator modes and controls their spectate target.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "mode",
            type = "integer",
            default = 5,
            description = "OBS_MODE: 0=none 1=deathcam 2=freezecam 3=fixed 4=in_eye 5=chase 6=roaming"
        },
        {
            name = "target_name",
            type = "entity",
            default = "",
            description = "Default spectate target entity/player name"
        }
    },
    inputs = {
        { name = "InSpectate",   type = "nil",     description = "Puts the activator into spectate using configured mode/target" },
        { name = "InUnspectate", type = "nil",     description = "Removes the activator from spectate" },
        { name = "InSetMode",    type = "integer", description = "Changes spectator mode for the activator" },
        { name = "InSetTarget",  type = "string",  description = "Sets spectate target by entity name (activator must already spectate)" },
        { name = "InRoam",       type = "nil",     description = "Forces roaming spectate on the activator" },
        { name = "InChase",      type = "nil",     description = "Forces chase spectate on the activator toward target/value" }
    },
    outputs = {
        { name = "OnSpectate",   type = "nil", description = "Fired when a player enters spectate" },
        { name = "OnUnspectate", type = "nil", description = "Fired when a player leaves spectate" }
    }
}

local OBS_MODE_NONE = OBS_MODE_NONE or 0
local OBS_MODE_CHASE = OBS_MODE_CHASE or 5
local OBS_MODE_ROAMING = OBS_MODE_ROAMING or 6

function ENT:Initialize()
    if self.m_iMode == nil then
        self.m_iMode = OBS_MODE_CHASE
    end

    if self.m_strTarget == nil then
        self.m_strTarget = ""
    end
end

function ENT:KeyValue_mode( value )
    self.m_iMode = tonumber( value, 10 ) or OBS_MODE_CHASE
end

function ENT:KeyValue_target_name( value )
    self.m_strTarget = tostring( value or "" )
end

---@param name string | nil
---@return Entity | nil
local function find_target( name )
    if name == nil or name == "" then
        return nil
    end

    local found = ents.FindByName( name )
    return found[ 1 ]
end

---@param pl Player
---@param mode integer
---@param target Entity | nil
local function apply_spectate( pl, mode, target )
    if mode == OBS_MODE_NONE then
        pl:UnSpectate()
        pl:Spawn()
        return
    end

    pl:Spectate( mode )

    if target ~= nil and target:IsValid() then
        pl:SpectateEntity( target )
    end
end

---@param activator Entity
function ENT:InSpectate( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    apply_spectate( activator, self.m_iMode, find_target( self.m_strTarget ) )
    self:FireOutput( "OnSpectate", activator )
end

---@param activator Entity
function ENT:InUnspectate( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    activator:UnSpectate()
    if not activator:Alive() then
        activator:Spawn()
    end

    self:FireOutput( "OnUnspectate", activator )
end

---@param activator Entity
---@param value string
function ENT:InSetMode( activator, _, value )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    local mode = tonumber( value, 10 ) or self.m_iMode
    self.m_iMode = mode
    apply_spectate( activator, mode, activator:GetObserverTarget() )
end

---@param activator Entity
---@param value string
function ENT:InSetTarget( activator, _, value )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    local name = tostring( value or self.m_strTarget )
    self.m_strTarget = name
    local target = find_target( name )
    if target ~= nil then
        activator:SpectateEntity( target )
    end
end

---@param activator Entity
function ENT:InRoam( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    apply_spectate( activator, OBS_MODE_ROAMING, nil )
    self:FireOutput( "OnSpectate", activator )
end

---@param activator Entity
---@param value string
function ENT:InChase( activator, _, value )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    local target = find_target( tostring( value or self.m_strTarget ) )
    apply_spectate( activator, OBS_MODE_CHASE, target )
    self:FireOutput( "OnSpectate", activator )
end
