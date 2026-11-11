---@class toolbox_timescale : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Time Scale",
    description = "Changes the game time scale.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "scale",
            type = "float",
            default = 1,
            description = "Initial time scale"
        }
    },
    inputs = {
        {
            name = "InScale",
            type = "float",
            description = "Sets the game time scale"
        }
    }
}

function ENT:InScale( _, _, value )
    game.SetTimeScale( tonumber( value, 10 ) or 1 )
end

function ENT:KeyValue_scale( value )
    self:InScale( nil, nil, value )
end
