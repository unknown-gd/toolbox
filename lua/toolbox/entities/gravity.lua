---@class toolbox_gravity : toolbox.Base
local ENT = ENT

ENT.Type = "point"

ENT.Editor = {
    title = "Gravity",
    description = "Sets the gravity of the map.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "direction",
            type = "vector",
            default = "0 0 -1",
            description = "Gravity direction"
        },
        {
            name = "force",
            type = "float",
            default = 600,
            description = "Gravity force (defaults to sv_gravity when empty)"
        }
    },
    inputs = {
        {
            name = "InDirection",
            type = "vector",
            description = "Changes the direction of gravity"
        },
        {
            name = "InForce",
            type = "float",
            description = "Changes the force of gravity"
        }
    }
}

function ENT:Initialize()
    if self.m_vDirection == nil then
        self.m_vDirection = Vector( 0, 0, -1 )
    end

    self:Apply()
end

function ENT:Apply()
    local direction = self.m_vDirection
    if direction == nil then
        return
    end

    physenv.SetGravity( direction * (self.m_vForce or cvars.Number( "sv_gravity", 600 )) )
end

function ENT:InDirection( _, _, value )
    self.m_vDirection = self.toVector( tostring( value ), 0, 0, -1 )
    self:ConsoleMessage( "debug", "Gravity direction set to %s", self.m_vDirection )
    self:Apply()
end

function ENT:InForce( _, _, value )
    self.m_vForce = tonumber( value, 10 ) or nil
    self:ConsoleMessage( "debug", "Gravity force set to %s", self.m_vForce )
    self:Apply()
end

function ENT:KeyValue_direction( value )
    self.m_vDirection = self.toVector( tostring( value ), 0, 0, -1 )
end

function ENT:KeyValue_force( value )
    self.m_vForce = tonumber( value, 10 ) or nil
end
