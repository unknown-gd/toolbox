
---@class sh_timescale : sh_base
local ENT = ENT

ENT.Base = "sh_base"

function ENT:InScale( activator, _, value )
    game.SetTimeScale( tonumber( value, 10 ) or 1 )
end

function ENT:KeyValue_scale( value )
    self:InScale( nil, nil, value )
end
