---@class toolbox_camera : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate.mdl" )
    self:DrawShadow( false )
    self:SetSolid( SOLID_NONE )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetNoDraw( true )

    self:SetNW2Float( "fov", self.m_flFOV or 0 )
    self:SetNW2Bool( "drawviewer", self.m_bDrawViewer or false )

    ---@type table<Player, boolean>
    self.m_tViewers = {}

    if self.m_strParent ~= nil and self.m_strParent ~= "" then
        self:ApplyParent()
    end
end

function ENT:KeyValue_fov( value )
    self.m_flFOV = tonumber( value, 10 ) or 0
    if self:IsValid() then self:SetNW2Float( "fov", self.m_flFOV ) end
end

function ENT:KeyValue_drawviewer( value )
    self.m_bDrawViewer = tobool( value )
    if self:IsValid() then self:SetNW2Bool( "drawviewer", self.m_bDrawViewer ) end
end

function ENT:KeyValue_parent_name( value )
    self.m_strParent = tostring( value or "" )
    if self:IsValid() then self:ApplyParent() end
end

function ENT:ApplyParent()
    local name = self.m_strParent
    if name == nil or name == "" then
        self:SetParent( NULL )
        return
    end

    local found = ents.FindByName( name )
    local parent = found[ 1 ]
    if parent ~= nil and parent:IsValid() then
        self:SetParent( parent )
    end
end

---@param pl Player
---@param ent Entity
---@param active boolean
local function set_player_camera( pl, ent, active )
    if active then
        pl:SetNW2Entity( "toolbox_camera", ent )
        pl:SetNW2Bool( "toolbox_camera_active", true )
    else
        if pl:GetNW2Entity( "toolbox_camera" ) == ent then
            pl:SetNW2Entity( "toolbox_camera", NULL )
            pl:SetNW2Bool( "toolbox_camera_active", false )
        end
    end
end

---@param activator Entity
function ENT:InStart( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    self.m_tViewers[ activator ] = true
    set_player_camera( activator, self, true )
    self:FireOutput( "OnStart", activator )
end

---@param activator Entity
function ENT:InStop( activator )
    if not activator:IsPlayer() then
        return
    end

    ---@cast activator Player
    self.m_tViewers[ activator ] = nil
    set_player_camera( activator, self, false )
    self:FireOutput( "OnStop", activator )
end

function ENT:InStopAll()
    for pl in pairs( self.m_tViewers ) do
        if pl:IsValid() then
            set_player_camera( pl, self, false )
            self:FireOutput( "OnStop", pl )
        end
    end
    self.m_tViewers = {}
end

function ENT:InSetPos( _, _, value )
    local pos = self.toVector( tostring( value ) )
    if pos ~= nil then
        self:SetPos( pos )
    end
end

function ENT:InSetAngles( _, _, value )
    local ang = self.toAngle( tostring( value ) )
    if ang ~= nil then
        self:SetAngles( ang )
    end
end

function ENT:InSetFOV( _, _, value )
    self.m_flFOV = tonumber( value, 10 ) or 0
    self:SetNW2Float( "fov", self.m_flFOV )
end

function ENT:InParent( _, _, value )
    self.m_strParent = tostring( value or "" )
    self:ApplyParent()
end

function ENT:OnRemove()
    self:InStopAll()
end

hook.Add( "SetupPlayerVisibility", "toolbox::Camera", function( pl )
    if not pl:GetNW2Bool( "toolbox_camera_active", false ) then
        return
    end

    local cam = pl:GetNW2Entity( "toolbox_camera" )
    if not cam:IsValid() then
        return
    end

    AddOriginToPVS( cam:GetPos() )
end )

hook.Add( "PlayerDisconnected", "toolbox::Camera", function( pl )
    local cam = pl:GetNW2Entity( "toolbox_camera" )
    if cam:IsValid() and cam.m_tViewers then
        cam.m_tViewers[ pl ] = nil
    end
end )
