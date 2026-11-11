---@class toolbox_text : toolbox.Base
local ENT = ENT

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate.mdl" )
    self:DrawShadow( false )
    self:SetSolid( SOLID_NONE )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetNoDraw( false )

    self:SetNW2String( "message", self.m_strMessage or "Text" )
    self:SetNW2String( "font", self.m_strFont or "DermaLarge" )
    local color = self.m_cColor or Color( 255, 255, 255, 255 )
    self:SetNW2Vector( "text_color", Vector( color.r, color.g, color.b ) )
    self:SetNW2Float( "text_alpha", color.a or 255 )
    self:SetNW2Float( "scale", self.m_flScale or 0.25 )
    self:SetNW2Bool( "enabled", self.m_bEnabled ~= false )
end

---@param self toolbox_text
---@param color Color
local function store_color( self, color )
    self.m_cColor = color
    if self:IsValid() then
        self:SetNW2Vector( "text_color", Vector( color.r, color.g, color.b ) )
        self:SetNW2Float( "text_alpha", color.a or 255 )
    end
end

function ENT:KeyValue_message( value )
    self.m_strMessage = tostring( value or "" )
    if self:IsValid() then self:SetNW2String( "message", self.m_strMessage ) end
end

function ENT:KeyValue_font( value )
    self.m_strFont = tostring( value or "DermaLarge" )
    if self:IsValid() then self:SetNW2String( "font", self.m_strFont ) end
end

function ENT:KeyValue_text_color( value )
    store_color( self, self.toColor( tostring( value ), 255, 255, 255, 255 ) )
end

function ENT:KeyValue_scale( value )
    self.m_flScale = tonumber( value, 10 ) or 0.25
    if self:IsValid() then self:SetNW2Float( "scale", self.m_flScale ) end
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
    if self:IsValid() then self:SetNW2Bool( "enabled", self.m_bEnabled ) end
end

function ENT:InSetText( _, _, value )
    self.m_strMessage = tostring( value or "" )
    self:SetNW2String( "message", self.m_strMessage )
end

function ENT:InSetColor( _, _, value )
    store_color( self, self.toColor( tostring( value ), 255, 255, 255, 255 ) )
end

function ENT:InSetScale( _, _, value )
    self.m_flScale = tonumber( value, 10 ) or 0.25
    self:SetNW2Float( "scale", self.m_flScale )
end

function ENT:InEnable()
    self.m_bEnabled = true
    self:SetNW2Bool( "enabled", true )
end

function ENT:InDisable()
    self.m_bEnabled = false
    self:SetNW2Bool( "enabled", false )
end
