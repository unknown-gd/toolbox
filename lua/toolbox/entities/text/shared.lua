---@class toolbox_text : toolbox.Base
local ENT = ENT

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Editor = {
    title = "Text",
    description = "3D2D billboard text that always faces the local player.",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "message", type = "string", default = "Text", description = "Text to display" },
        { name = "font", type = "string", default = "DermaLarge", description = "Font name" },
        { name = "text_color", type = "color", default = "255 255 255 255", description = "Text color" },
        { name = "scale", type = "float", default = 0.25, description = "3D2D scale" },
        { name = "enabled", type = "boolean", default = 1, description = "Whether the text is drawn" }
    },
    inputs = {
        { name = "InSetText", type = "string", description = "Changes the displayed text" },
        { name = "InSetColor", type = "color", description = "Changes the text color" },
        { name = "InSetScale", type = "float", description = "Changes the 3D2D scale" },
        { name = "InEnable", type = "nil", description = "Shows the text" },
        { name = "InDisable", type = "nil", description = "Hides the text" }
    }
}
