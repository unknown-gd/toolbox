---@class sh_server_command : sh_base
local ENT = ENT

ENT.Base = "sh_base"

function ENT:InExecute( activator, _, value )
    local cmd_str = tostring( value )
    RunConsoleCommand( string.match( cmd_str, "^%s*([^%s]*)(.*)$" ) or cmd_str )
end
