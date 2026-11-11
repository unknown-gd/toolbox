---@class toolbox_chat : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Chat",
    description = "Chat manipulation entity, allows you to send messages as specific players.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    inputs = {
        {
            name = "InSendMessage",
            type = "string",
            description = "Sends a chat message as the activator (players only). Supports #{expr} substitutions with A=activator, C=self."
        }
    },
    outputs = {
        {
            name = "OnMessage",
            type = "string",
            description = "Fired when a player sends a chat message"
        },
        {
            name = "OnTeamMessage",
            type = "string",
            description = "Fired when a player sends a team chat message"
        }
    }
}

do

    local env = {}

    setmetatable( env, {
        __index = _G,
        __newindex = _G
    } )

    ---@param key string
    ---@return string
    local function formatter( key )
        local fn = CompileString( "return " .. key, "toolbox_chat", true )
        setfenv( fn, env )
        return tostring( fn() )
    end

    ---@param activator Entity
    ---@param value string
    function ENT:InSendMessage( activator, _, value )
        if activator:IsPlayer() then
            ---@cast activator Player
            rawset( env, "C", self )
            rawset( env, "A", activator )
            activator:Say( string.gsub( tostring( value ), "#{(.-)}", formatter ), false )
        end
    end

end

do

    ---@type toolbox_chat[]
    local handlers = {}

    ---@type integer
    local handler_count = 0

    hook.Add( "OnEntityCreated", "toolbox::Chat", function( entity )
        if entity:GetClass() ~= "toolbox_chat" then return end

        handler_count = handler_count + 1
        handlers[ handler_count ] = entity
    end, PRE_HOOK )

    hook.Add( "EntityRemoved", "toolbox::Chat", function( entity )
        if entity:GetClass() ~= "toolbox_chat" then return end

        for i = handler_count, 1, -1 do
            if handlers[ i ] == entity then
                table.remove( handlers, i )
                handler_count = handler_count - 1
            end
        end
    end, PRE_HOOK )

    ---@param pl Player
    ---@param message string
    ---@param is_team_chat boolean
    hook.Add( "PlayerSay", "toolbox::Chat", function( pl, message, is_team_chat )
        for i = 1, handler_count do
            handlers[ i ]:FireOutput( is_team_chat and "OnTeamMessage" or "OnMessage", pl, message )
        end
    end )

end
