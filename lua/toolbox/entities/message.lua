---@class toolbox_message : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Message",
    description = "Prints a message to a player (activator) or globally.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "message_type",
            type = "integer",
            default = 3,
            description = "PrintMessage type: 1=notify, 2=console, 3=talk, 4=center"
        }
    },
    inputs = {
        {
            name = "InPrint",
            type = "string",
            description = "Prints the message to the activator if they are a player"
        },
        {
            name = "InPrintGlobal",
            type = "string",
            description = "Prints the message to every player"
        }
    }
}

local HUD_PRINTNOTIFY = HUD_PRINTNOTIFY or 1
local HUD_PRINTCONSOLE = HUD_PRINTCONSOLE or 2
local HUD_PRINTTALK = HUD_PRINTTALK or 3
local HUD_PRINTCENTER = HUD_PRINTCENTER or 4

---@type table<integer, boolean>
local allowed_message_types = {

}

---@param value string | number | nil
---@return integer
local function resolve_type( value )
    local message_type = tonumber( value, 10 )
    if message_type == HUD_PRINTNOTIFY
        or message_type == HUD_PRINTCONSOLE
        or message_type == HUD_PRINTTALK
        or message_type == HUD_PRINTCENTER then
        return message_type or HUD_PRINTTALK
    end

    return HUD_PRINTTALK
end

function ENT:Initialize()
    self.m_iMessageType = HUD_PRINTTALK
end

---@param value string
function ENT:KeyValue_message_type( value )
    self.m_iMessageType = resolve_type( value )
end

---@param activator Entity
---@param value string
function ENT:InPrint( activator, _, value )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    activator:PrintMessage( self.m_iMessageType or HUD_PRINTTALK, tostring( value ) )
end

---@param value string
function ENT:InPrintGlobal( _, _, value )
    PrintMessage( self.m_iMessageType or HUD_PRINTTALK, tostring( value ) )
end
