---@class toolbox_camera : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

ENT.Editor = {
    title = "Camera",
    description = "Takes control of a player's camera view (CalcView) and keeps the origin in PVS.",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/camera.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "fov", type = "float", default = 0, description = "Override FOV (0 = keep player FOV)" },
        { name = "parent_name", type = "entity", default = "", description = "Optional parent entity name" },
        { name = "drawviewer", type = "boolean", default = 0, description = "Draw the player body while controlled" }
    },
    inputs = {
        { name = "InStart", type = "nil", description = "Starts controlling the activator's camera" },
        { name = "InStop", type = "nil", description = "Stops controlling the activator's camera" },
        { name = "InStopAll", type = "nil", description = "Stops controlling every player using this camera" },
        { name = "InSetPos", type = "vector", description = "Moves the camera origin" },
        { name = "InSetAngles", type = "angle", description = "Sets the camera angles" },
        { name = "InSetFOV", type = "float", description = "Sets FOV override (0 clears)" },
        { name = "InParent", type = "string", description = "Parents the camera to an entity name (empty clears)" }
    },
    outputs = {
        { name = "OnStart", type = "nil", description = "Fired when a player starts using this camera" },
        { name = "OnStop", type = "nil", description = "Fired when a player stops using this camera" }
    }
}
