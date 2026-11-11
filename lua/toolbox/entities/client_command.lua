---@class toolbox_client_command : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Client Command",
    description = "Runs a console command on the activator client.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    inputs = {
        {
            name = "InExecute",
            type = "string",
            description = "Runs a command on the activator (players only)"
        }
    }
}

---@param activator Entity
---@param value string
function ENT:InExecute( activator, _, value )
    if activator:IsPlayer() then
        ---@cast activator Player
        activator:ConCommand( tostring( value ) )
    end
end
