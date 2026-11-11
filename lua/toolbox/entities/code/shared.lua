---@class toolbox_code : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Code",
    description = "Executes Lua with activator/caller/self and an optional entity from the input value.",
    base = { "Targetname" },
    icon = "editor/logic_script.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "code",
            type = "string",
            default = "",
            description = "Lua source executed by InExecute (A=activator, C=caller, S=self, E=entity, V=value)"
        }
    },
    inputs = {
        {
            name = "InExecute",
            type = "string",
            description = "Runs stored code. Value may be an entity name/index bound to E."
        },
        {
            name = "InRun",
            type = "string",
            description = "Compiles and runs the input value as Lua (same environment as InExecute)."
        },
        {
            name = "InSetCode",
            type = "string",
            description = "Replaces the stored Lua source"
        }
    },
    outputs = {
        {
            name = "OnSuccess",
            type = "string",
            description = "Fired after successful execution (value = tostring of return)"
        },
        {
            name = "OnError",
            type = "string",
            description = "Fired when compilation or execution fails (value = error message)"
        }
    }
}
