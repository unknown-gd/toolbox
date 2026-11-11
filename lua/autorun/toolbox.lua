assert( dreamwork, "Failed to load 'toolbox', dreamwork is missing!" )
assert( glua_patches, "Failed to load 'toolbox', glua-patches is missing!" )

---@type dreamwork.std
local std = dreamwork.std

local isfunction = std.isFunction
local SERVER = SERVER

---@class toolbox
toolbox = toolbox or {}

toolbox.name = "ToolBox"
toolbox.author = "Unknown Developer"
toolbox.url = "https://github.com/unknown-gd/toolbox"
toolbox.license = "MIT"
toolbox.WEB_MATERIAL_NW = "toolbox_webmat_url"

---@type table<string, boolean>
local classes = {}
toolbox.classes = classes

---@alias toolbox.Key string
---@alias toolbox.Value string | number | boolean

---@class toolbox.Output
---@field target string
---@field input string
---@field delay number
---@field value toolbox.Value
---@field repetitions integer

local raw_tonumber = std.raw.tonumber

local math = std.math

local string = std.string
local string_match = string.match

toolbox.toString = tostring

do

    local math_trunc = math.trunc

    ---
    --- Converts a string to an integer, with an optional default value.
    ---
    ---@param str string
    ---@param default? integer
    function toolbox.toInteger( str, default )
        return math_trunc( raw_tonumber( str, 10 ) or default or 0 )
    end

end

do

    local math_round = math.round

    ---
    --- Converts a string to a float, with an optional default value.
    ---
    ---@param str string
    ---@param default? number
    function toolbox.toFloat( str, default )
        return math_round( raw_tonumber( str, 10 ) or default or 0, 4 )
    end

end

do

    local Color = Color

    ---
    --- Converts a string to a Color, with optional default values for each component.
    ---
    ---@param str string
    ---@param r? integer
    ---@param g? integer
    ---@param b? integer
    ---@param a? integer
    function toolbox.toColor( str, r, g, b, a )
        local r_str, g_str, b_str, a_str = string_match( str, "^(%d*)[^%d]*(%d*)[^%d]*(%d*)[^%d]*(%d*)" )
        return Color(
            raw_tonumber( r_str, 10 ) or r or 0,
            raw_tonumber( g_str, 10 ) or g or 0,
            raw_tonumber( b_str, 10 ) or b or 0,
            raw_tonumber( a_str, 10 ) or a or 255
        )
    end

end

do

    local Vector = Vector

    ---
    --- Converts a string to a Vector, with optional default values for each component.
    ---
    ---@param str string
    ---@param x? number
    ---@param y? number
    ---@param z? number
    function toolbox.toVector( str, x, y, z )
        -- Separators must not consume '-' or signs on later components are lost ("0 0 -1" -> 0 0 1).
        local x_str, y_str, z_str = string_match( str, "^(%-?%d*%.?%d*)[^%d%-]*(%-?%d*%.?%d*)[^%d%-]*(%-?%d*%.?%d*)" )
        return Vector(
            raw_tonumber( x_str, 10 ) or x or 0,
            raw_tonumber( y_str, 10 ) or y or 0,
            raw_tonumber( z_str, 10 ) or z or 0
        )
    end

end

do

    local Angle = Angle

    ---
    --- Converts a string to an Angle, with optional default values for each component.
    ---
    ---@param str string
    ---@param yaw? number
    ---@param pitch? number
    ---@param roll? number
    function toolbox.toAngle( str, yaw, pitch, roll )
        local p_str, y_str, r_str = string_match( str, "^(%-?%d*%.?%d*)[^%d%-]*(%-?%d*%.?%d*)[^%d%-]*(%-?%d*%.?%d*)" )
        return Angle(
            raw_tonumber( p_str, 10 ) or pitch or 0,
            raw_tonumber( y_str, 10 ) or yaw or 0,
            raw_tonumber( r_str, 10 ) or roll or 0
        )
    end

end

local logger = std.console.Logger( {
    color = std.color.fromRGB( 250, 50, 0 ),
    title = toolbox.name,
    interpolation = false
} )

toolbox.Logger = logger

logger:info( "And out of the blue, that just happened!" )

local prefix = string.lower( toolbox.name ) .. "_"

---@class toolbox.Base : ENT
---@field Outputs table<string, fun(self: toolbox.Base, activator: Entity, value: toolbox.Value): nil | toolbox.Value>
---@field Inputs table<string, fun(self: toolbox.Base, activator: Entity, caller: Entity, value: toolbox.Value)>
---@field KeyValues table<string, fun(self: toolbox.Base, value: string)>
local metatable_base = {}

toolbox.Base = metatable_base

include( "toolbox/" .. (SERVER and "" or "cl_") .. "init.lua" )

metatable_base.__index = FindMetaTable( "Entity" )

local env_metatable = {
    __index = _G
}

---@type table<string, toolbox.Editor>
local definitions = {}
toolbox.definitions = definitions

---@param class_name string
---@return table env, table metatable
local function prepare_env( class_name )
    local metatable = {
        ClassName = class_name
    }

    if SERVER then
        metatable.Type = "point"
    else
        metatable.Type = "anim"
    end

    setmetatable( metatable, metatable_base )

    local env = {
        ENT = metatable
    }

    setmetatable( env, env_metatable )

    return env, metatable
end

---@param tbl table
local function finalize_entity( tbl )
    if not SERVER then
        return
    end

    local user_initialize = tbl.Initialize
    local user_keyvalue = tbl.KeyValue

    function tbl:Initialize()
        self.Inputs = self.Inputs or {}
        self.Outputs = self.Outputs or {}
        self.KeyValues = self.KeyValues or {}

        if isfunction( user_initialize ) then
            user_initialize( self )
        end

        local init = self.Init
        if isfunction( init ) then
            init( self )
        end
    end

    -- Engine SetKeyValue on SENTs reliably hits ENT:KeyValue; the global
    -- EntityKeyValue hook is still kept for map IO / non-SENT cases.
    function tbl:KeyValue( key, value )
        self.m_tKeyValues = self.m_tKeyValues or {}
        self.m_tKeyValues[ key ] = value

        if isfunction( user_keyvalue ) then
            user_keyvalue( self, key, value )
        end

        local keyvalues = self.KeyValues
        local fn = (keyvalues and keyvalues[ key ]) or self[ "KeyValue_" .. key ]
        if isfunction( fn ) then
            fn( self, value )
        end
    end

    local entity_get_value = tbl.GetValue or metatable_base.GetValue

    function tbl:GetValue( key )
        local cached = self.m_tKeyValues and self.m_tKeyValues[ key ]
        if cached ~= nil then
            return cached
        end

        if isfunction( entity_get_value ) then
            return entity_get_value( self, key )
        end
    end
end

---@param tbl table
---@param class_name string
local function register_entity( tbl, class_name )
    class_name = tbl.ClassName or class_name
    tbl.ClassName = class_name

    -- Keep string bases (e.g. base_nextbot); drop non-string toolbox metatable refs.
    if not std.isString( tbl.Base ) then
        tbl.Base = nil
    end

    -- scripted_ents method lookup does not walk Lua metatables, so flatten Base.
    for key, value in pairs( metatable_base ) do
        if tbl[ key ] == nil and key ~= "__index" then
            tbl[ key ] = value
        end
    end

    finalize_entity( tbl )

    -- Ensure Type is set before Register (map spawn uses GetType).
    -- Do not call scripted_ents.Get here — base_point/base_anim are not loaded yet in autorun.
    if tbl.Type == nil then
        tbl.Type = SERVER and "point" or "anim"
    end

    classes[ class_name ] = true

    if tbl.Editor ~= nil then
        definitions[ class_name ] = tbl.Editor
    end

    scripted_ents.Register( tbl, class_name )
    logger:info( "Registered class: " .. class_name )
end


local CompileFile = CompileFile
local file_Exists = file.Exists
local file_Size = file.Size

---@param file_path string
---@return boolean
local function is_loadable( file_path )
    return file_Exists( file_path, "LUA" ) and (file_Size( file_path, "LUA" ) or 0) > 0
end

---@param file_path string
---@param env table
---@return boolean
local function run_file( file_path, env )
    if not is_loadable( file_path ) then
        return false
    end

    local fn = CompileFile( file_path, true )
    if fn == nil then
        return false
    end

    setfenv( fn, env )
    fn()
    return true
end

local function reload_entities()
    for class_name in pairs( classes ) do
        classes[ class_name ] = nil
    end

    for class_name in pairs( definitions ) do
        definitions[ class_name ] = nil
    end

    local files, folders = file.Find( "toolbox/entities/*", SERVER and "lsv" or "lcl" )

    for i = 1, #files, 1 do
        local file_name = files[ i ]
        local file_path = "toolbox/entities/" .. file_name

        local class_name, ext = string_match( file_name, "([^.]+)%.(%w+)$" )

        if ext == "lua" then
            if class_name == nil then
                error( "file name of '" .. file_path .. "' corrupted" )
            end

            -- if SERVER then
            --     AddCSLuaFile( file_path )
            -- end

            class_name = prefix .. class_name
            local env, tbl = prepare_env( class_name )

            if run_file( file_path, env ) then
                register_entity( tbl, class_name )
            end
        end
    end

    for i = 1, #folders, 1 do
        local folder_name = folders[ i ]
        local folder_path = "toolbox/entities/" .. folder_name

        local shared_path = folder_path .. "/shared.lua"
        local cl_init_path = folder_path .. "/cl_init.lua"
        local init_path = folder_path .. "/init.lua"

        if SERVER then
            if is_loadable( shared_path ) then
                AddCSLuaFile( shared_path )
            end

            if is_loadable( cl_init_path ) then
                AddCSLuaFile( cl_init_path )
            end
        end

        local entry_point = SERVER and init_path or cl_init_path
        if not is_loadable( entry_point ) and not is_loadable( shared_path ) then
            continue
        end

        local class_name = prefix .. folder_name
        local env, tbl = prepare_env( class_name )

        run_file( shared_path, env )

        if run_file( entry_point, env ) or is_loadable( shared_path ) then
            register_entity( tbl, class_name )
        end
    end
end

reload_entities()

local function dsplay_classes()
    logger:info( "Registered classes:" )

    for class_name in pairs( toolbox.classes ) do
        logger:info( "  - " .. class_name )
    end
end

if SERVER then
    concommand.Add( "toolbox.server.classes", function( pl )
        if pl ~= nil and pl:IsValid() then return end

        dsplay_classes()
    end )

    concommand.Add( "toolbox.server.reload", function( pl )
        if pl ~= nil and pl:IsValid() then return end

        reload_entities()
    end )

    return
end

concommand.Add( "toolbox.client.classes", function()
    dsplay_classes()
end )
