---@class toolbox_player_voice : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Player Voice",
    description = "Controls who can hear whom in voice chat, and per-player voice volume scale.",
    base = { "Targetname" },
    icon = "editor/env_soundscape.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        {
            name = "mode",
            type = "integer",
            default = 0,
            description = "0=disabled, 1=block listed talkers, 2=allow only listed talkers, 3=mute activator targets"
        },
        {
            name = "volume",
            type = "float",
            default = 1,
            description = "Voice volume scale applied by InSetVolume (0-1+)"
        },
        {
            name = "enabled",
            type = "boolean",
            default = 1,
            description = "Whether this controller participates in voice filtering"
        }
    },
    inputs = {
        { name = "InEnable",    type = "nil",     description = "Enables this voice controller" },
        { name = "InDisable",   type = "nil",     description = "Disables this voice controller" },
        { name = "InBlock",     type = "nil",     description = "Blocks the activator from being heard (adds to block list)" },
        { name = "InAllow",     type = "nil",     description = "Allows the activator to be heard (removes from block / adds to allow)" },
        { name = "InMute",      type = "nil",     description = "Mutes the activator for all listeners" },
        { name = "InUnmute",    type = "nil",     description = "Unmutes the activator" },
        { name = "InSetVolume", type = "float",   description = "Sets voice volume scale on the activator client" },
        { name = "InSetMode",   type = "integer", description = "Changes filter mode" },
        { name = "InClear",     type = "nil",     description = "Clears block/allow/mute lists" }
    }
}

---@type toolbox_player_voice[]
local handlers = {}
local handler_count = 0

function ENT:Initialize()
    if self.m_iMode == nil then self.m_iMode = 0 end

    if self.m_bEnabled == nil then self.m_bEnabled = true end

    if self.m_flVolume == nil then self.m_flVolume = 1 end

    ---@type table<Player, boolean>
    self.m_tBlocked = self.m_tBlocked or {}
    ---@type table<Player, boolean>
    self.m_tAllowed = self.m_tAllowed or {}
    ---@type table<Player, boolean>
    self.m_tMuted = self.m_tMuted or {}

    handler_count = handler_count + 1
    handlers[ handler_count ] = self
end

function ENT:OnRemove()
    for i = handler_count, 1, -1 do
        if handlers[ i ] == self then
            table.remove( handlers, i )
            handler_count = handler_count - 1
        end
    end
end

function ENT:KeyValue_mode( value )
    self.m_iMode = tonumber( value, 10 ) or 0
end

function ENT:KeyValue_volume( value )
    self.m_flVolume = tonumber( value, 10 ) or 1
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
end

function ENT:InEnable()
    self.m_bEnabled = true
end

function ENT:InDisable()
    self.m_bEnabled = false
end

function ENT:InSetMode( _, _, value )
    self.m_iMode = tonumber( value, 10 ) or 0
end

function ENT:InClear()
    self.m_tBlocked = {}
    self.m_tAllowed = {}
    self.m_tMuted = {}
end

---@param activator Entity
function ENT:InBlock( activator )
    if activator:IsPlayer() then
        ---@cast activator Player
        self.m_tBlocked[ activator ] = true
        self.m_tAllowed[ activator ] = nil
    end
end

---@param activator Entity
function ENT:InAllow( activator )
    if activator:IsPlayer() then
        ---@cast activator Player
        self.m_tAllowed[ activator ] = true
        self.m_tBlocked[ activator ] = nil
        self.m_tMuted[ activator ] = nil
    end
end

---@param activator Entity
function ENT:InMute( activator )
    if activator:IsPlayer() then
        ---@cast activator Player
        self.m_tMuted[ activator ] = true
    end
end

---@param activator Entity
function ENT:InUnmute( activator )
    if activator:IsPlayer() then
        ---@cast activator Player
        self.m_tMuted[ activator ] = nil
    end
end

---@param activator Entity
---@param value string
function ENT:InSetVolume( activator, _, value )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    local scale = tonumber( value, 10 ) or self.m_flVolume or 1
    activator:SetNW2Float( "toolbox_voice_volume", scale )
end

---@param listener Player
---@param talker Player
---@return boolean | nil
---@return boolean | nil
local function evaluate( listener, talker )
    for i = 1, handler_count do
        local ent = handlers[ i ]
        if not ent.m_bEnabled then
            goto evaluate_loop
        end

        if ent.m_tMuted[ talker ] then
            return false, false
        end

        local mode = ent.m_iMode
        if mode == 1 then
            if ent.m_tBlocked[ talker ] then
                return false, false
            end
        elseif mode == 2 then
            if not ent.m_tAllowed[ talker ] then
                return false, false
            end
        elseif mode == 3 then
            if ent.m_tBlocked[ talker ] or ent.m_tMuted[ talker ] then
                return false, false
            end
        end

        ::evaluate_loop::
    end

    return nil
end

hook.Add( "PlayerCanHearPlayersVoice", "toolbox::PlayerVoice", function( listener, talker )
    return evaluate( listener, talker )
end )

hook.Add( "PlayerDisconnected", "toolbox::PlayerVoice", function( pl )
    for i = 1, handler_count do
        local ent = handlers[ i ]
        ent.m_tBlocked[ pl ] = nil
        ent.m_tAllowed[ pl ] = nil
        ent.m_tMuted[ pl ] = nil
    end
end )
