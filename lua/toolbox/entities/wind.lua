---@class toolbox_wind : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Wind",
    description = "Controls map wind by managing an env_wind entity (direction, speeds, gusts).",
    base = { "Targetname", "Origin" },
    icon = "editor/env_wind.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "minwind", type = "integer", default = 20, description = "Minimum sustained wind speed" },
        { name = "maxwind", type = "integer", default = 40, description = "Maximum sustained wind speed" },
        { name = "mingust", type = "integer", default = 50, description = "Minimum gust speed" },
        { name = "maxgust", type = "integer", default = 80, description = "Maximum gust speed" },
        { name = "mingustdelay", type = "float", default = 5, description = "Minimum delay between gusts" },
        { name = "maxgustdelay", type = "float", default = 10, description = "Maximum delay between gusts" },
        { name = "gustduration", type = "float", default = 3, description = "Gust duration" },
        { name = "gustdirchange", type = "integer", default = 20, description = "Max gust direction change (degrees)" },
        { name = "gustdir", type = "angle", default = "0 0 0", description = "Initial wind yaw (pitch/roll ignored)" },
        { name = "enabled", type = "boolean", default = 1, description = "Spawn/enable the env_wind controller" }
    },
    inputs = {
        { name = "InEnable", type = "nil", description = "Creates/enables the env_wind" },
        { name = "InDisable", type = "nil", description = "Removes the env_wind" },
        { name = "InDirection", type = "angle", description = "Sets wind yaw direction" },
        { name = "InMinWind", type = "integer", description = "Sets minimum wind speed" },
        { name = "InMaxWind", type = "integer", description = "Sets maximum wind speed" },
        { name = "InMinGust", type = "integer", description = "Sets minimum gust speed" },
        { name = "InMaxGust", type = "integer", description = "Sets maximum gust speed" },
        { name = "InGustDuration", type = "float", description = "Sets gust duration" },
        { name = "InApply", type = "nil", description = "Recreates env_wind with current parameters" }
    }
}

function ENT:Initialize()
    if self.m_iMinWind == nil then self.m_iMinWind = 20 end
    if self.m_iMaxWind == nil then self.m_iMaxWind = 40 end
    if self.m_iMinGust == nil then self.m_iMinGust = 50 end
    if self.m_iMaxGust == nil then self.m_iMaxGust = 80 end
    if self.m_flMinGustDelay == nil then self.m_flMinGustDelay = 5 end
    if self.m_flMaxGustDelay == nil then self.m_flMaxGustDelay = 10 end
    if self.m_flGustDuration == nil then self.m_flGustDuration = 3 end
    if self.m_iGustDirChange == nil then self.m_iGustDirChange = 20 end
    if self.m_angGustDir == nil then self.m_angGustDir = Angle( 0, 0, 0 ) end
    if self.m_bEnabled == nil then self.m_bEnabled = true end

    self.m_entWind = NULL
    self:RebuildWind()
end

function ENT:OnRemove()
    if IsValid( self.m_entWind ) then
        self.m_entWind:Remove()
    end
end

function ENT:RebuildWind()
    if IsValid( self.m_entWind ) then
        self.m_entWind:Remove()
    end

    if not self.m_bEnabled then
        self.m_entWind = NULL
        return
    end

    local wind = ents.Create( "env_wind" )
    if not IsValid( wind ) then
        self:ConsoleMessage( "error", "Failed to create env_wind" )
        return
    end

    wind:SetPos( self:GetPos() )
    wind:SetKeyValue( "minwind", tostring( self.m_iMinWind ) )
    wind:SetKeyValue( "maxwind", tostring( self.m_iMaxWind ) )
    wind:SetKeyValue( "mingust", tostring( self.m_iMinGust ) )
    wind:SetKeyValue( "maxgust", tostring( self.m_iMaxGust ) )
    wind:SetKeyValue( "mingustdelay", tostring( self.m_flMinGustDelay ) )
    wind:SetKeyValue( "maxgustdelay", tostring( self.m_flMaxGustDelay ) )
    wind:SetKeyValue( "gustduration", tostring( self.m_flGustDuration ) )
    wind:SetKeyValue( "gustdirchange", tostring( self.m_iGustDirChange ) )
    wind:SetKeyValue( "gustdir", string.format( "%f %f %f", self.m_angGustDir.p, self.m_angGustDir.y, self.m_angGustDir.r ) )
    wind:Spawn()
    wind:Activate()

    self.m_entWind = wind
    self:ConsoleMessage( "debug", "env_wind rebuilt at %s", self:GetPos() )
end

function ENT:KeyValue_minwind( value )
    self.m_iMinWind = tonumber( value, 10 ) or 20
end

function ENT:KeyValue_maxwind( value )
    self.m_iMaxWind = tonumber( value, 10 ) or 40
end

function ENT:KeyValue_mingust( value )
    self.m_iMinGust = tonumber( value, 10 ) or 50
end

function ENT:KeyValue_maxgust( value )
    self.m_iMaxGust = tonumber( value, 10 ) or 80
end

function ENT:KeyValue_mingustdelay( value )
    self.m_flMinGustDelay = tonumber( value, 10 ) or 5
end

function ENT:KeyValue_maxgustdelay( value )
    self.m_flMaxGustDelay = tonumber( value, 10 ) or 10
end

function ENT:KeyValue_gustduration( value )
    self.m_flGustDuration = tonumber( value, 10 ) or 3
end

function ENT:KeyValue_gustdirchange( value )
    self.m_iGustDirChange = tonumber( value, 10 ) or 20
end

function ENT:KeyValue_gustdir( value )
    self.m_angGustDir = self.toAngle( tostring( value ), 0, 0, 0 )
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
end

function ENT:InEnable()
    self.m_bEnabled = true
    self:RebuildWind()
end

function ENT:InDisable()
    self.m_bEnabled = false
    self:RebuildWind()
end

function ENT:InDirection( _, _, value )
    self.m_angGustDir = self.toAngle( tostring( value ), 0, 0, 0 )
    self:RebuildWind()
end

function ENT:InMinWind( _, _, value )
    self.m_iMinWind = tonumber( value, 10 ) or self.m_iMinWind
    self:RebuildWind()
end

function ENT:InMaxWind( _, _, value )
    self.m_iMaxWind = tonumber( value, 10 ) or self.m_iMaxWind
    self:RebuildWind()
end

function ENT:InMinGust( _, _, value )
    self.m_iMinGust = tonumber( value, 10 ) or self.m_iMinGust
    self:RebuildWind()
end

function ENT:InMaxGust( _, _, value )
    self.m_iMaxGust = tonumber( value, 10 ) or self.m_iMaxGust
    self:RebuildWind()
end

function ENT:InGustDuration( _, _, value )
    self.m_flGustDuration = tonumber( value, 10 ) or self.m_flGustDuration
    self:RebuildWind()
end

function ENT:InApply()
    self:RebuildWind()
end
