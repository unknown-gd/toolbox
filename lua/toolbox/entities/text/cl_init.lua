---@class toolbox_text : toolbox.Base
local ENT = ENT

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
    self:SetRenderBounds( Vector( -128, -128, -128 ), Vector( 128, 128, 128 ) )
end

function ENT:DrawTranslucent()
    if not self:GetNW2Bool( "enabled", true ) then
        return
    end

    local text = self:GetNW2String( "message", "" )
    if text == "" then
        return
    end

    local pl = LocalPlayer()
    if not IsValid( pl ) then
        return
    end

    local pos = self:GetPos()
    local eye = pl:EyePos()
    local ang = ( pos - eye ):Angle()
    ang:RotateAroundAxis( ang:Up(), 90 )
    ang:RotateAroundAxis( ang:Forward(), 90 )

    local scale = self:GetNW2Float( "scale", 0.25 )
    local font = self:GetNW2String( "font", "DermaLarge" )
    local rgb = self:GetNW2Vector( "text_color", Vector( 255, 255, 255 ) )
    local alpha = self:GetNW2Float( "text_alpha", 255 )
    local color = Color( rgb.x, rgb.y, rgb.z, alpha )

    cam.Start3D2D( pos, ang, scale )
        draw.SimpleText( text, font, 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    cam.End3D2D()
end
