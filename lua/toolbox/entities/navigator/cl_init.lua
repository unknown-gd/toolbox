---@class toolbox_navigator : NextBot, toolbox.Base
local ENT = ENT

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

function ENT:Draw()
    self:DrawModel()
end
