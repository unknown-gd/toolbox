---@class sh_client_command : sh_base
local ENT = ENT

ENT.Base = "sh_base"

---@param activator Entity
---@param value string
function ENT:InExecute( activator, _, value )
    if activator:IsPlayer() then
        ---@cast activator Player
        activator:ConCommand( tostring( value ) )
    end
end
