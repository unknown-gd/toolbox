---@class toolbox_picture : toolbox.Base
local ENT = ENT

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    self:SetRenderBounds( Vector( -64, -64, -64 ), Vector( 64, 64, 64 ) )
    self.m_matImage = nil
    self.m_strLoadedURL = nil
end

function ENT:Think()
    local url = self:GetNW2String( "url", "" )
    if url == self.m_strLoadedURL then
        return
    end

    self.m_strLoadedURL = url
    self.m_matImage = nil

    if url == "" then
        return
    end

    toolbox.FetchWebMaterial( url, function( mat )
        if not IsValid( self ) then
            return
        end

        if self:GetNW2String( "url", "" ) == url then
            self.m_matImage = mat
        end
    end )
end

function ENT:DrawTranslucent()
    local mat = self.m_matImage
    if mat == nil then return end

    local width = self:GetNW2Float( "width", 128 )
    local height = self:GetNW2Float( "height", 128 )
    local pos = self:GetPos()
    local ang = self:GetAngles()

    cam.Start3D2D( pos, ang, 1 )
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.SetMaterial( mat )
    surface.DrawTexturedRect( -width * 0.5, -height * 0.5, width, height )
    cam.End3D2D()
end
