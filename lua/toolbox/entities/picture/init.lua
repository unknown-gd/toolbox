---@class toolbox_picture : toolbox.Base
local ENT = ENT

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Editor = {
    title = "Picture",
    description = "Downloads a PNG/JPG from a URL and renders it as a textured quad.",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/env_sprite.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "url", type = "string", default = "", description = "Image URL (png/jpg/vtf/vmt)" },
        { name = "width", type = "float", default = 128, description = "Quad width in units" },
        { name = "height", type = "float", default = 128, description = "Quad height in units" }
    },
    inputs = {
        { name = "InSetURL", type = "string", description = "Sets the image URL and refreshes" },
        { name = "InClear", type = "nil", description = "Clears the URL" }
    }
}

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate.mdl" )
    self:DrawShadow( false )
    self:SetSolid( SOLID_NONE )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetNoDraw( false )

    if self.m_strURL == nil then self:SetNW2String( "url", "" ) else self:SetNW2String( "url", self.m_strURL ) end
    if self.m_flWidth == nil then self:SetNW2Float( "width", 128 ) else self:SetNW2Float( "width", self.m_flWidth ) end
    if self.m_flHeight == nil then self:SetNW2Float( "height", 128 ) else self:SetNW2Float( "height", self.m_flHeight ) end
end

function ENT:KeyValue_url( value )
    self.m_strURL = tostring( value or "" )
    if self:IsValid() then self:SetNW2String( "url", self.m_strURL ) end
end

function ENT:KeyValue_width( value )
    self.m_flWidth = tonumber( value, 10 ) or 128
    if self:IsValid() then self:SetNW2Float( "width", self.m_flWidth ) end
end

function ENT:KeyValue_height( value )
    self.m_flHeight = tonumber( value, 10 ) or 128
    if self:IsValid() then self:SetNW2Float( "height", self.m_flHeight ) end
end

function ENT:InSetURL( _, _, value )
    self.m_strURL = tostring( value or "" )
    self:SetNW2String( "url", self.m_strURL )
end

function ENT:InClear()
    self.m_strURL = ""
    self:SetNW2String( "url", "" )
end

