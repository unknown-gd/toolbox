---@class toolbox_speaker : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

local SyncFactor = CreateClientConVar(
    "toolbox_speaker_sync",
    "0.5",
    true,
    false,
    "Max playback drift in seconds before seeking a toolbox speaker.",
    0.1,
    30
)

local audio_meta = FindMetaTable( "IGModAudioChannel" )
---@cast audio_meta IGModAudioChannel

local audio_IsValid = audio_meta.IsValid
local audio_GetState = audio_meta.GetState
local audio_GetLength = audio_meta.GetLength
local audio_GetTime = audio_meta.GetTime
local audio_GetPlaybackRate = audio_meta.GetPlaybackRate
local audio_GetVolume = audio_meta.GetVolume

local GMOD_CHANNEL_STOPPED = GMOD_CHANNEL_STOPPED or 0
local GMOD_CHANNEL_PLAYING = GMOD_CHANNEL_PLAYING or 1
local GMOD_CHANNEL_PAUSED = GMOD_CHANNEL_PAUSED or 2
local GMOD_CHANNEL_STALLED = GMOD_CHANNEL_STALLED or 3

function ENT:Initialize()
    self:SetNoDraw( true )
    self:DrawShadow( false )

    ---@type IGModAudioChannel | nil
    self.m_channel = nil
    self.m_strLoadedPath = nil
    self.m_bSpatialLoaded = nil
    self.m_bLoading = false
    self.m_bFailed = false
    self.m_bSeekable = true

    self:SetNextClientThink( CurTime() )
end

function ENT:StopChannel()
    local channel = self.m_channel
    if channel ~= nil and audio_IsValid( channel ) then
        channel:Stop()
    end

    self.m_channel = nil
    self.m_strLoadedPath = nil
    self.m_bSpatialLoaded = nil
    self.m_bLoading = false
end

---@param path string
---@param spatial boolean
function ENT:BeginLoad( path, spatial )
    if self.m_bLoading and self.m_strLoadedPath == path and self.m_bSpatialLoaded == spatial then
        return
    end

    self:StopChannel()

    self.m_bLoading = true
    self.m_bFailed = false
    self.m_strLoadedPath = path
    self.m_bSpatialLoaded = spatial
    self.m_bSeekable = true

    local flags = spatial and "3d noblock noplay" or "noblock noplay"
    local load_token = ( self.m_iLoadToken or 0 ) + 1
    self.m_iLoadToken = load_token

    local function on_channel( channel, err_id, err_name )
        if not IsValid( self ) then
            if channel ~= nil and audio_IsValid( channel ) then
                channel:Stop()
            end
            return
        end

        if self.m_iLoadToken ~= load_token then
            if channel ~= nil and audio_IsValid( channel ) then
                channel:Stop()
            end
            return
        end

        self.m_bLoading = false

        if self:GetNW2String( "path", "" ) ~= path or self:GetNW2Bool( "spatial", true ) ~= spatial then
            if channel ~= nil and audio_IsValid( channel ) then
                channel:Stop()
            end
            return
        end

        if channel == nil or not audio_IsValid( channel ) then
            self.m_bFailed = true
            self.m_channel = nil
            ErrorNoHalt( string.format( "[ToolBox/ERROR] Speaker channel failed for '%s' (%s / %s)\n", path, tostring( err_id ), tostring( err_name ) ) )
            return
        end

        self.m_channel = channel
        self.m_bSeekable = math.max( 0, audio_GetLength( channel ) ) ~= 0

        if spatial then
            channel:SetPos( self:GetPos() )
            channel:Set3DFadeDistance(
                self:GetNW2Float( "fade_min", 200 ),
                self:GetNW2Float( "fade_max", 2000 )
            )
        end

        channel:SetVolume( self:GetNW2Float( "volume", 1 ) )
        channel:SetPlaybackRate( self:GetNW2Float( "rate", 1 ) )

        if not self.m_bSeekable then
            channel:EnableLooping( self:GetNW2Bool( "loop", true ) )
        end
    end

    if string.find( path, "^https?://.+$" ) ~= nil then
        sound.PlayURL( path, flags, on_channel )
        return
    end

    local file_path = path
    if not file.Exists( file_path, "GAME" ) and string.sub( file_path, 1, 6 ) ~= "sound/" then
        local with_sound = "sound/" .. file_path
        if file.Exists( with_sound, "GAME" ) then
            file_path = with_sound
        end
    end

    if file.Exists( file_path, "GAME" ) then
        sound.PlayFile( file_path, flags, on_channel )
        return
    end

    self.m_bLoading = false
    self.m_bFailed = true
    ErrorNoHalt( string.format( "[ToolBox/ERROR] Speaker path not found: '%s'\n", path ) )
end


---@return number
function ENT:GetServerTime()
    local rate = self:GetNW2Float( "rate", 1 )
    if rate <= 0 then
        rate = 1
    end

    return ( CurTime() - self:GetNW2Float( "start_time", CurTime() ) ) * rate
end

function ENT:Think()
    self:SetNextClientThink( CurTime() + 0.25 )

    if not self:GetNW2Bool( "enabled", true ) or not self:GetNW2Bool( "playing", false ) then
        if self.m_channel ~= nil or self.m_bLoading then
            self:StopChannel()
        end

        self.m_bFailed = false
        return true
    end

    local path = self:GetNW2String( "path", "" )
    if path == "" then
        self:StopChannel()
        self.m_bFailed = false
        return true
    end

    local spatial = self:GetNW2Bool( "spatial", true )

    if self.m_bFailed and self.m_strLoadedPath == path and self.m_bSpatialLoaded == spatial then
        return true
    end

    if self.m_strLoadedPath ~= path or self.m_bSpatialLoaded ~= spatial then
        self.m_bFailed = false
        self:BeginLoad( path, spatial )
        return true
    end

    if self.m_bLoading then
        return true
    end

    local channel = self.m_channel
    if channel == nil or not audio_IsValid( channel ) then
        self.m_channel = nil
        if not self.m_bFailed then
            self:BeginLoad( path, spatial )
        end
        return true
    end

    if spatial then
        channel:SetPos( self:GetPos() )
        channel:Set3DFadeDistance(
            self:GetNW2Float( "fade_min", 200 ),
            self:GetNW2Float( "fade_max", 2000 )
        )
    end

    local volume = self:GetNW2Float( "volume", 1 )
    if audio_GetVolume( channel ) ~= volume then
        channel:SetVolume( volume )
    end

    local rate = self:GetNW2Float( "rate", 1 )
    if audio_GetPlaybackRate( channel ) ~= rate then
        channel:SetPlaybackRate( rate )
    end

    local loop = self:GetNW2Bool( "loop", true )
    if not self.m_bSeekable and channel:IsLooping() ~= loop then
        channel:EnableLooping( loop )
    end

    local state = audio_GetState( channel )

    if self:GetNW2Bool( "pause", false ) then
        if state ~= GMOD_CHANNEL_PAUSED then
            channel:Pause()
        end
        return true
    end

    if self.m_bSeekable then
        local length = math.max( 0, audio_GetLength( channel ) )
        if length <= 0 then
            if state ~= GMOD_CHANNEL_STOPPED then
                channel:Stop()
            end
            return true
        end

        local server_time = self:GetServerTime()

        if loop then
            server_time = server_time % length
        elseif server_time > length then
            if state ~= GMOD_CHANNEL_STOPPED then
                channel:Stop()
            end
            return true
        end

        if math.abs( audio_GetTime( channel ) - server_time ) > SyncFactor:GetFloat() then
            channel:SetTime( server_time )
        end
    end

    if state ~= GMOD_CHANNEL_PLAYING and state ~= GMOD_CHANNEL_STALLED then
        channel:Play()
    end

    return true
end

function ENT:OnRemove()
    self:StopChannel()
end
