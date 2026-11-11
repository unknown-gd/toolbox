---@class toolbox_player_voice : toolbox.Base
local ENT = ENT

hook.Add( "EntityNetworkedVarChanged", "toolbox::PlayerVoiceVolume", function( entity, name, _, value )
    if name == "toolbox_voice_volume" and entity:IsPlayer() then
        ---@cast entity Player
        entity:SetVoiceVolumeScale( tonumber( value ) or 1 )
    end
end )

hook.Add( "NotifyShouldTransmit", "toolbox::PlayerVoiceVolume", function( entity, should )
    if should and entity:IsPlayer() then
        ---@cast entity Player
        local scale = entity:GetNW2Float( "toolbox_voice_volume", -1 )
        if scale >= 0 then
            entity:SetVoiceVolumeScale( scale )
        end
    end
end )
