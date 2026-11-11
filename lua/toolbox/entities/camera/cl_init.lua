---@class toolbox_camera : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

hook.Add( "CalcView", "toolbox::Camera", function( pl, _, _, fov )
    if not pl:GetNW2Bool( "toolbox_camera_active", false ) then
        return
    end

    local cam = pl:GetNW2Entity( "toolbox_camera" )
    if not IsValid( cam ) then
        return
    end

    local override_fov = cam:GetNW2Float( "fov", 0 )

    return {
        origin = cam:GetPos(),
        angles = cam:GetAngles(),
        fov = override_fov > 0 and override_fov or fov,
        drawviewer = cam:GetNW2Bool( "drawviewer", false )
    }
end )
