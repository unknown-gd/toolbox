---@class toolbox_speaker : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

local wrong_paths = {
    [ "unknown" ] = true,
    [ "false" ] = true,
    [ "none" ] = true,
    [ "nil" ] = true,
    [ "" ] = true
}

---@param value any
---@return string
local function normalize_path( value )
    local path = string.Trim( tostring( value or "" ) )
    if wrong_paths[ string.lower( path ) ] then
        return ""
    end

    return path
end

---@param value any
---@param min number
---@param max number
---@param default number
---@return number
local function clamp_number( value, min, max, default )
    local n = tonumber( value, 10 )
    if n == nil then
        return default
    end

    return math.Clamp( n, min, max )
end

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate.mdl" )
    self:DrawShadow( false )
    self:SetSolid( SOLID_NONE )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetNoDraw( true )

    if self.m_strPath == nil then self.m_strPath = "" end
    if self.m_flVolume == nil then self.m_flVolume = 1 end
    if self.m_flRate == nil then self.m_flRate = 1 end
    if self.m_bLoop == nil then self.m_bLoop = true end
    if self.m_bSpatial == nil then self.m_bSpatial = true end
    if self.m_flFadeMin == nil then self.m_flFadeMin = 200 end
    if self.m_flFadeMax == nil then self.m_flFadeMax = 2000 end
    if self.m_bAutoplay == nil then self.m_bAutoplay = true end
    if self.m_bEnabled == nil then self.m_bEnabled = true end
    if self.m_bPlaying == nil then self.m_bPlaying = false end
    if self.m_bPause == nil then self.m_bPause = false end
    if self.m_flStartTime == nil then self.m_flStartTime = 0 end

    self:SyncNetwork()

    if self.m_bAutoplay and self.m_strPath ~= "" then
        self:StartPlayback( nil )
    end
end

function ENT:SyncNetwork()
    self:SetNW2String( "path", self.m_strPath or "" )
    self:SetNW2Float( "volume", self.m_flVolume or 1 )
    self:SetNW2Float( "rate", self.m_flRate or 1 )
    self:SetNW2Bool( "loop", self.m_bLoop ~= false )
    self:SetNW2Bool( "spatial", self.m_bSpatial ~= false )
    self:SetNW2Float( "fade_min", self.m_flFadeMin or 200 )
    self:SetNW2Float( "fade_max", self.m_flFadeMax or 2000 )
    self:SetNW2Bool( "enabled", self.m_bEnabled ~= false )
    self:SetNW2Bool( "playing", self.m_bPlaying == true )
    self:SetNW2Bool( "pause", self.m_bPause == true )
    self:SetNW2Float( "start_time", self.m_flStartTime or 0 )
end

function ENT:KeyValue_path( value )
    self.m_strPath = normalize_path( value )
    if self:IsValid() then self:SetNW2String( "path", self.m_strPath ) end
end

function ENT:KeyValue_volume( value )
    self.m_flVolume = clamp_number( value, 0, 2, 1 )
    if self:IsValid() then self:SetNW2Float( "volume", self.m_flVolume ) end
end

function ENT:KeyValue_rate( value )
    self.m_flRate = clamp_number( value, 0, 2, 1 )
    if self:IsValid() then self:SetNW2Float( "rate", self.m_flRate ) end
end

function ENT:KeyValue_loop( value )
    self.m_bLoop = tobool( value )
    if self:IsValid() then self:SetNW2Bool( "loop", self.m_bLoop ) end
end

function ENT:KeyValue_spatial( value )
    self.m_bSpatial = tobool( value )
    if self:IsValid() then self:SetNW2Bool( "spatial", self.m_bSpatial ) end
end

function ENT:KeyValue_fade_min( value )
    self.m_flFadeMin = tonumber( value, 10 ) or 200
    if self:IsValid() then self:SetNW2Float( "fade_min", self.m_flFadeMin ) end
end

function ENT:KeyValue_fade_max( value )
    self.m_flFadeMax = tonumber( value, 10 ) or 2000
    if self:IsValid() then self:SetNW2Float( "fade_max", self.m_flFadeMax ) end
end

function ENT:KeyValue_autoplay( value )
    self.m_bAutoplay = tobool( value )
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
    if self:IsValid() then self:SetNW2Bool( "enabled", self.m_bEnabled ) end
end

---@param activator Entity | nil
function ENT:StartPlayback( activator )
    if self.m_strPath == nil or self.m_strPath == "" then
        return
    end

    self.m_bPlaying = true
    self.m_bPause = false
    self.m_flPauseStart = nil
    self.m_flStartTime = CurTime()

    self:SetNW2String( "path", self.m_strPath )
    self:SetNW2Bool( "playing", true )
    self:SetNW2Bool( "pause", false )
    self:SetNW2Float( "start_time", self.m_flStartTime )

    self:FireOutput( "OnPlay", activator )
end

---@param activator Entity | nil
function ENT:StopPlayback( activator )
    if not self.m_bPlaying then
        self.m_bPause = false
        self.m_flPauseStart = nil
        self:SetNW2Bool( "playing", false )
        self:SetNW2Bool( "pause", false )
        return
    end

    self.m_bPlaying = false
    self.m_bPause = false
    self.m_flPauseStart = nil
    self.m_flStartTime = 0

    self:SetNW2Bool( "playing", false )
    self:SetNW2Bool( "pause", false )
    self:SetNW2Float( "start_time", 0 )

    self:FireOutput( "OnStop", activator )
end

---@param paused boolean
function ENT:SetPaused( paused )
    paused = paused == true

    if not self.m_bPlaying or paused == self.m_bPause then
        return
    end

    local curtime = CurTime()

    if paused then
        self.m_flPauseStart = curtime
    else
        local offset = curtime - ( self.m_flPauseStart or curtime )
        self.m_flStartTime = ( self.m_flStartTime or curtime ) + offset
        self.m_flPauseStart = nil
        self:SetNW2Float( "start_time", self.m_flStartTime )
    end

    self.m_bPause = paused
    self:SetNW2Bool( "pause", paused )
end

---@param activator Entity
---@param value string
function ENT:InPlay( activator, _, value )
    local path = normalize_path( value )
    if path ~= "" then
        self.m_strPath = path
        self:SetNW2String( "path", path )
    end

    self:StartPlayback( activator )
end

---@param activator Entity
function ENT:InStop( activator )
    self:StopPlayback( activator )
end

function ENT:InPause()
    self:SetPaused( true )
end

function ENT:InResume()
    self:SetPaused( false )
end

function ENT:InTogglePause()
    self:SetPaused( not self.m_bPause )
end

function ENT:InSetPath( _, _, value )
    self.m_strPath = normalize_path( value )
    self:SetNW2String( "path", self.m_strPath )

    if self.m_strPath == "" then
        self:StopPlayback( nil )
    end
end

function ENT:InSetVolume( _, _, value )
    self.m_flVolume = clamp_number( value, 0, 2, self.m_flVolume or 1 )
    self:SetNW2Float( "volume", self.m_flVolume )
end

function ENT:InSetRate( _, _, value )
    self.m_flRate = clamp_number( value, 0, 2, self.m_flRate or 1 )
    self:SetNW2Float( "rate", self.m_flRate )
end

function ENT:InSetLoop( _, _, value )
    self.m_bLoop = tobool( value )
    self:SetNW2Bool( "loop", self.m_bLoop )
end

function ENT:InSkip( _, _, value )
    if not self.m_bPlaying then
        return
    end

    local seconds = tonumber( value, 10 ) or 0
    if seconds == 0 then
        return
    end

    local rate = self.m_flRate or 1
    if rate <= 0 then
        rate = 1
    end

    self.m_flStartTime = ( self.m_flStartTime or CurTime() ) - ( seconds / rate )
    self:SetNW2Float( "start_time", self.m_flStartTime )
end

function ENT:InSetTime( _, _, value )
    if not self.m_bPlaying then
        return
    end

    local seconds = math.max( 0, tonumber( value, 10 ) or 0 )
    local rate = self.m_flRate or 1
    if rate <= 0 then
        rate = 1
    end

    self.m_flStartTime = CurTime() - ( seconds / rate )
    if self.m_bPause then
        self.m_flPauseStart = CurTime()
    end

    self:SetNW2Float( "start_time", self.m_flStartTime )
end

function ENT:InSetFadeMin( _, _, value )
    self.m_flFadeMin = tonumber( value, 10 ) or self.m_flFadeMin or 200
    self:SetNW2Float( "fade_min", self.m_flFadeMin )
end

function ENT:InSetFadeMax( _, _, value )
    self.m_flFadeMax = tonumber( value, 10 ) or self.m_flFadeMax or 2000
    self:SetNW2Float( "fade_max", self.m_flFadeMax )
end

function ENT:InEnable()
    self.m_bEnabled = true
    self:SetNW2Bool( "enabled", true )
end

function ENT:InDisable()
    self.m_bEnabled = false
    self:SetNW2Bool( "enabled", false )
end

function ENT:OnRemove()
    self.m_bPlaying = false
end
