assert( dreamwork, "Failed to load 'sledgehammer', dreamwork is missing!" )
assert( glua_patches, "Failed to load 'sledgehammer', glua-patches is missing!" )

---@type dreamwork.std
local std = dreamwork.std

local isfunction = std.isFunction
local SERVER = SERVER

---@class sledgehammer
sledgehammer = sledgehammer or {}

sledgehammer.name = "Sledgehammer"
sledgehammer.author = "Unknown Developer"
sledgehammer.url = "https://github.com/unknown-gd/sledgehammer"
sledgehammer.license = "MIT"

---@type table<string, boolean>
local classes = {}
sledgehammer.classes = classes

---@alias sledgehammer.Key string
---@alias sledgehammer.Value string | number | boolean

---@class sledgehammer.Output
---@field target string
---@field input string
---@field delay number
---@field value sledgehammer.Value
---@field repetitions integer

local raw_tonumber = std.raw.tonumber

local math = std.math

local string = std.string
local string_match = string.match

sledgehammer.toString = tostring

do

    local math_trunc = math.trunc

    ---
    --- Converts a string to an integer, with an optional default value.
    ---
    ---@param str string
    ---@param default? integer
    function sledgehammer.toInteger( str, default )
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
    function sledgehammer.toFloat( str, default )
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
    function sledgehammer.toColor( str, r, g, b, a )
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
    function sledgehammer.toVector( str, x, y, z )
        local x_str, y_str, z_str = string_match( str, "^(%-?%d*%.?%d*)[^%d]*(%-?%d*%.?%d*)[^%d]*(%-?%d*%.?%d*)" )
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
    function sledgehammer.toAngle( str, yaw, pitch, roll )
        local p_str, y_str, r_str = string_match( str, "^(%-?%d*%.?%d*)[^%d]*(%-?%d*%.?%d*)[^%d]*(%-?%d*%.?%d*)" )
        return Angle(
            raw_tonumber( p_str, 10 ) or pitch or 0,
            raw_tonumber( y_str, 10 ) or yaw or 0,
            raw_tonumber( r_str, 10 ) or roll or 0
        )
    end

end

local logger = std.console.Logger( {
    color = std.Color( 250, 100, 0 ),
    title = sledgehammer.name,
    interpolation = false
} )

sledgehammer.Logger = logger

logger:info( "And out of the blue, that just happened!" )

local prefix = string.lower( sledgehammer.name ) .. "_"

---@class sledgehammer.Base : ENT
---@field Outputs table<string, fun(self: sledgehammer.Base, activator: Entity, value: sledgehammer.Value): nil | sledgehammer.Value>
---@field Inputs table<string, fun(self: sledgehammer.Base, activator: Entity, caller: Entity, value: sledgehammer.Value)>
---@field KeyValues table<string, fun(self: sledgehammer.Base, value: string)>
local metatable_base = {}

sledgehammer.Base = metatable_base

include( "sledgehammer/" .. (SERVER and "" or "cl_") .. "init.lua" )

metatable_base.__index = FindMetaTable( "Entity" )

local env_metatable = {
    __index = _G
}

---@param class_name string
---@return table env, table metatable
local function prepare_env( class_name )
    local metatable = {
        ClassName = class_name
    }

    if SERVER then
        metatable.Type = "point"

        function metatable:Initialize()
            self.Inputs = {}
            self.Outputs = {}
            self.KeyValues = {}

            local fn = self.Init
            if isfunction( fn ) then
                fn( self )
            end
        end

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

local ents_Register = scripted_ents.Register
local CompileFile = CompileFile

local function reload_entities()
    local files, folders = file.Find( "sledgehammer/entities/*", SERVER and "lsv" or "lcl" )

    for i = 1, #files, 1 do
        local file_name = files[ i ]
        local file_path = "sledgehammer/entities/" .. file_name

        local class_name, ext = string_match( file_name, "([^.]+)%.(%w+)$" )

        if ext == "lua" then
            if class_name == nil then
                error( "file name of '" .. file_path .. "' corrupted" )
            end

            class_name = prefix .. class_name
            local env, tbl = prepare_env( class_name )

            local fn = CompileFile( file_path, true )
            if fn ~= nil then
                setfenv( fn, env )
                fn()

                class_name = tbl.ClassName or class_name
                classes[ class_name ] = true

                ents_Register( tbl, class_name )
                logger:info( "Registered class: " .. class_name )
            end
        end
    end

    for i = 1, #folders, 1 do
        local folder_name = folders[ i ]
        local folder_path = "sledgehammer/entities/" .. folder_name

        local entry_point

        if SERVER then
            local cl_init = folder_path .. "/cl_init.lua"
            if file.Exists( cl_init, "LUA" ) then
                AddCSLuaFile( cl_init )
            end

            entry_point = "init.lua"
        else
            entry_point = "cl_init.lua"
        end

        if file.Exists( entry_point, "LUA" ) then
            local class_name = prefix .. folder_name
            local env, tbl = prepare_env( class_name )

            local fn = CompileFile( entry_point, true )
            if fn ~= nil then
                setfenv( fn, env )
                fn()

                class_name = tbl.ClassName or class_name
                classes[ class_name ] = true

                ents_Register( tbl, class_name )
                logger:info( "Registered class: " .. class_name )
            end
        end
    end
end

reload_entities()

local function dsplay_classes()
    logger:info( "Registered classes:" )

    for class_name in pairs( sledgehammer.classes ) do
        logger:info( "  - " .. class_name )
    end
end

if SERVER then
    concommand.Add( "sledgehammer.server.classes", function( pl )
        if pl ~= nil and pl:IsValid() then return end

        dsplay_classes()
    end )

    concommand.Add( "sledgehammer.server.reload", function( pl )
        if pl ~= nil and pl:IsValid() then return end

        reload_entities()
    end )

    return
end

concommand.Add( "sledgehammer.client.classes", function()
    dsplay_classes()
end )
