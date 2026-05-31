---@class sledgehammer_gravity : sledgehammer.Base
local ENT = ENT

function ENT:Initialize()
    self.m_vDirection = Vector( 0, 0, -1 )
    self.m_vForce = nil
    self:Apply()
end

function ENT:Apply()
    physenv.SetGravity( self.m_vDirection * (self.m_vForce or cvars.Number( "sv_gravity", 600 )) )
end

function ENT:InDirection( activator, _, value )
    local x, y, z = string.match( value, "^(%-?%d*%.?%d*)%s*(%-?%d*%.?%d*)%s*(%-?%d*%.?%d*)$" )
    self.m_vDirection = Vector( tonumber( x or 0, 10 ) or 0, tonumber( y or 0, 10 ) or 0, tonumber( z or 0, 10 ) or 0 )
    self:ConsoleMessage( "debug", "Gravity direction set to %s", self.m_vDirection )
    self:Apply()
end

function ENT:InForce( activator, _, value )
    self.m_vForce = tonumber( value, 10 ) or nil
    self:ConsoleMessage( "debug", "Gravity force set to %s", self.m_vForce )
    self:Apply()
end

function ENT:KeyValue_direction( value )
    self:InDirection( nil, nil, value )
end

function ENT:KeyValue_force( value )
    self:InForce( nil, nil, value )
end
