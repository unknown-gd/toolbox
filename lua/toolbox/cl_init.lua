---@class toolbox
local toolbox = toolbox

---@class toolbox.Base
local Base = toolbox.Base
Base.Type = "anim"

do

    local http_Fetch = http.Fetch
    local file_Write = file.Write
    local file_CreateDir = file.CreateDir
    local Material = Material
    local util_CRC = util.CRC
    local string_lower = string.lower
    local string_match = string.match
    local string_byte = string.byte
    local string_format = string.format
    local IsValid = IsValid

    file_CreateDir( "toolbox/webmat" )

    ---@type table<string, IMaterial | false>
    local cache = {}

    ---@type table<string, boolean>
    local pending = {}

    ---@param headers table | nil
    ---@return string | nil ext "png" | "jpg" | "vtf" | "vmt"
    local function extension_from_headers( headers )
        if headers == nil then
            return nil
        end

        local content_type = headers[ "Content-Type" ] or headers[ "content-type" ] or headers[ "Content-type" ]
        if content_type == nil then
            return nil
        end

        content_type = string_lower( tostring( content_type ) )
        -- strip parameters: image/png; charset=...
        content_type = string_match( content_type, "^([^;]+)" ) or content_type
        content_type = string_match( content_type, "^%s*(.-)%s*$" ) or content_type

        if content_type == "image/png" then
            return "png"
        end

        if content_type == "image/jpeg" or content_type == "image/jpg" then
            return "jpg"
        end

        if content_type == "image/vnd.valve.source.texture" or content_type == "application/x-valve-texture" then
            return "vtf"
        end

        if content_type == "application/x-valve-material" then
            return "vmt"
        end

        return nil
    end


    ---@param url string
    ---@return string | nil ext "png" | "jpg" | "vtf" | "vmt"
    local function extension_from_url( url )
        local path = string_match( url, "^[^%?#]+" ) or url
        local ext = string_match( string_lower( path ), "%.([a-z0-9]+)$" )
        if ext == "jpeg" then
            return "jpg"
        end

        if ext == "png" or ext == "jpg" or ext == "vtf" or ext == "vmt" then
            return ext
        end

        return nil
    end

    ---@param body string
    ---@return string | nil ext "png" | "jpg" | "vtf" | "vmt"
    local function extension_from_body( body )
        local b1, b2, b3, b4 = string_byte( body, 1, 4 )
        if b1 == nil then
            return nil
        end

        -- PNG
        if b1 == 0x89 and b2 == 0x50 and b3 == 0x4E and b4 == 0x47 then
            return "png"
        end

        -- JPEG
        if b1 == 0xFF and b2 == 0xD8 and b3 == 0xFF then
            return "jpg"
        end

        -- VTF ("VTF\0")
        if b1 == 0x56 and b2 == 0x54 and b3 == 0x46 and b4 == 0x00 then
            return "vtf"
        end

        -- VMT (text shader block)
        if string_match( body, "^%s*\"" ) ~= nil or string_match( string_lower( body ), "^%s*[a-z0-9_]+%s*%{" ) ~= nil then
            return "vmt"
        end

        return nil
    end

    ---@param crc string
    ---@param ext string
    ---@param body string
    ---@return IMaterial | nil
    local function write_and_load( crc, ext, body )
        local stem = "toolbox/webmat/" .. crc

        if ext == "png" or ext == "jpg" then
            local relative = stem .. "." .. ext
            file_Write( relative, body )
            local mat = Material( "data/" .. relative, "noclamp smooth" )
            if mat == nil or mat:IsError() then
                return nil
            end

            return mat
        end

        if ext == "vtf" then
            file_Write( stem .. ".vtf", body )
            file_Write( stem .. ".vmt", string_format( [["UnlitGeneric"
{
	"$basetexture" "../data/%s"
	"$vertexcolor" "1"
	"$vertexalpha" "1"
	"$translucent" "1"
	"$nolod" "1"
}
]], stem ) )

            local mat = Material( "../data/" .. stem )
            if mat == nil or mat:IsError() then
                return nil
            end

            return mat
        end

        if ext == "vmt" then
            file_Write( stem .. ".vmt", body )
            local mat = Material( "../data/" .. stem )
            if mat == nil or mat:IsError() then
                return nil
            end

            return mat
        end

        return nil
    end

    ---@param url string
    ---@param callback fun( mat: IMaterial | nil )
    function toolbox.FetchWebMaterial( url, callback )
        if url == nil or url == "" then
            callback( nil )
            return
        end

        local cached = cache[ url ]
        if cached ~= nil then
            callback( cached or nil )
            return
        end

        if pending[ url ] then
            timer.Create( "toolbox.webmat.wait." .. util_CRC( url ), 0.1, 50, function()
                local mat = cache[ url ]
                if mat ~= nil then
                    timer.Remove( "toolbox.webmat.wait." .. util_CRC( url ) )
                    callback( mat or nil )
                end
            end )

            return
        end

        pending[ url ] = true

        http_Fetch( url, function( body, _, headers, code )
            pending[ url ] = nil

            if code ~= 200 or body == nil or body == "" then
                cache[ url ] = false
                callback( nil )
                return
            end

            local ext = extension_from_body( body )
                or extension_from_headers( headers )
                or extension_from_url( url )
            if ext == nil then
                cache[ url ] = false
                callback( nil )
                return
            end

            local mat = write_and_load( util_CRC( url ), ext, body )
            if mat == nil then
                cache[ url ] = false
                callback( nil )
                return
            end

            cache[ url ] = mat
            callback( mat )
        end, function()
            pending[ url ] = nil
            cache[ url ] = false
            callback( nil )
        end )
    end

    ---@param entity Entity
    ---@param url string
    local function apply_to_entity( entity, url )
        if url == nil or url == "" then
            if IsValid( entity ) then
                entity:SetMaterial( "" )
            end

            return
        end

        toolbox.FetchWebMaterial( url, function( mat )
            if not IsValid( entity ) or mat == nil then
                return
            end

            local name = mat:GetName()
            if name == nil or name == "" or name == "___error" then
                return
            end

            entity:SetMaterial( name )
        end )
    end

    hook.Add( "EntityNetworkedVarChanged", "toolbox::WebMaterial", function( entity, name, _, value )
        if name ~= toolbox.WEB_MATERIAL_NW then
            return
        end

        apply_to_entity( entity, value )
    end )

    hook.Add( "NotifyShouldTransmit", "toolbox::WebMaterial", function( entity, should )
        if not should then
            return
        end

        local url = entity:GetNW2String( toolbox.WEB_MATERIAL_NW, "" )
        if url ~= "" then
            apply_to_entity( entity, url )
        end
    end )

end
