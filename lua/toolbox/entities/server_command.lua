---@class toolbox_server_command : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Server Command",
    description = "Runs a console command on the server.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    inputs = {
        {
            name = "InExecute",
            type = "string",
            description = "Runs a command on the server"
        }
    }
}

---@param value string
function ENT:InExecute( _, _, value )
    local cmd_str = tostring( value )
    RunConsoleCommand( string.match( cmd_str, "^%s*([^%s]*)(.*)$" ) or cmd_str )
end
