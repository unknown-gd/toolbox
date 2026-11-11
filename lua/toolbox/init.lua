---@diagnostic disable: inject-field
AddCSLuaFile( "toolbox/cl_init.lua" )

---@class toolbox
local toolbox = toolbox
local logger = toolbox.Logger

local std = dreamwork.std

local string = std.string
local string_byte = string.byte
local string_format = string.format
local string_lower = string.lower

local table = std.table
local table_concat = table.concat
local table_remove = table.remove

local raw_tonumber = std.raw.tonumber
local isFunction = std.isFunction
local tostring = std.tostring

---@param str string | nil
---@return boolean
function toolbox.isWebMaterialURL( str )
    return std.isString( str ) and string.isURL( str )
end

---@param entity Entity
---@param url string
function toolbox.ApplyWebMaterial( entity, url )
    if not entity:IsValid() then
        return
    end

    entity:SetNW2String( toolbox.WEB_MATERIAL_NW, tostring( url or "" ) )
end

---@param entity Entity
function toolbox.ClearWebMaterial( entity )
    if not entity:IsValid() then
        return
    end

    entity:SetNW2String( toolbox.WEB_MATERIAL_NW, "" )
end

---@class Entity
local ENTITY = std.debug.findmetatable( "Entity" )
assert( ENTITY, "Potential environment corruption, unable to find `Entity` metatable." )

---@class toolbox.Base
local Base = toolbox.Base
Base.Type = "point"

local ENTITY_Fire = ENTITY.Fire

Base.GetValue = ENTITY.GetInternalVariable
Base.SetValue = ENTITY.SetKeyValue
Base.FireInput = ENTITY_Fire

Base.toString = toolbox.toString
Base.toInteger = toolbox.toInteger
Base.toFloat = toolbox.toFloat
Base.toNumber = toolbox.toFloat
Base.toColor = toolbox.toColor
Base.toVector = toolbox.toVector
Base.toAngle = toolbox.toAngle

do

    local Color = Color
    local cvars_Number = cvars.Number
    local MsgC = MsgC

    local main = Color( 250, 50, 0 )
    local text = Color( 220, 220, 220 )

    local type_colors = {
        info = Color( 70, 135, 255 ),
        warn = Color( 255, 130, 90 ),
        error = Color( 250, 55, 40 ),
        debug = Color( 0, 200, 150 )
    }

    ---@alias toolbox.MessageType
    ---| "info"
    ---| "warn"
    ---| "error"
    ---| "debug"

    ---@param type toolbox.MessageType
    ---@param fmt string
    ---@param ... any
    function Base:ConsoleMessage( type, fmt, ... )
        if type == "debug" and cvars_Number( "developer", 0 ) < 1 then
            return
        end

        MsgC(
            main, "[ToolBox/",
            type_colors[ type ] or color_white, string.upper( type ) .. "] ",
            text, string_format( fmt, ... ), "\n"
        )
    end

end

local classes = toolbox.classes
local ENTITY_GetClass = ENTITY.GetClass

---@param str string
---@return boolean
local function isInput( str )
    local b1, b2, b3 = string_byte( str, 1, 3 )
    return b1 == 0x49 --[[ I ]] and b2 == 0x6E --[[ n ]] and b3 > 0x40 and b3 < 0x5B --[[ A-Z ]]
end

---@param str string
---@return boolean
local function isOutput( str )
    local b1, b2, b3, b4 = string_byte( str, 1, 4 )
    return (b1 == 0x4F --[[ O ]] and b2 == 0x75 --[[ u ]] and b3 == 0x74 --[[ t ]] and b4 > 0x40 and b4 < 0x5B --[[ A-Z ]]) or
        (b1 == 0x4F --[[ O ]] and b2 == 0x6E --[[ n ]] and b3 > 0x40 and b3 < 0x5B --[[ A-Z ]])
end

---@param str string
---@return boolean
local function isKeyValue( str )
    return not (isInput( str ) or isOutput( str ))
end

--- Nested map: entity -> output name -> output connections
---@type table<Entity, table<string, toolbox.Output[]>>
local entity_to_outputs = {}

do

    local isentity = isentity

    local output_list_metatable = {
        ---@param self table<string, toolbox.Output[]>
        ---@param key string
        ---@return toolbox.Output[]
        __index = function( self, key )
            ---@type toolbox.Output[]
            local list = { [ 0 ] = 0 }
            self[ key ] = list
            return list
        end
    }

    setmetatable( entity_to_outputs, {
        ---@param self table<Entity, table<string, toolbox.Output[]>>
        ---@param entity Entity
        ---@return table<string, toolbox.Output[]>
        __index = function( self, entity )
            if not isentity( entity ) then
                error( "'entity' must be a valid entity", 3 )
            end

            if not entity:IsValid() then
                return setmetatable( {}, output_list_metatable )
            end

            if not classes[ ENTITY_GetClass( entity ) ] then
                error( "received entity is not based on a toolbox class", 3 )
            end

            local outputs = setmetatable( {}, output_list_metatable )
            self[ entity ] = outputs
            return outputs
        end,
        __mode = "k"
    } )

end

do

    ---@type Entity[]
    local cleanup_queue = { [ 0 ] = 0 }

    hook.Add( "EntityRemoved", "toolbox::Cleanup", function( entity )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        local queue_size = cleanup_queue[ 0 ] + 1
        cleanup_queue[ queue_size ] = entity
        cleanup_queue[ 0 ] = queue_size
    end, PRE_HOOK )

    hook.Add( "Tick", "toolbox::Cleanup", function()
        local queue_size = cleanup_queue[ 0 ]
        if queue_size == 0 then
            return nil
        end

        local entity = cleanup_queue[ queue_size ]
        if entity == nil then
            return nil
        end

        cleanup_queue[ queue_size ] = nil
        cleanup_queue[ 0 ] = queue_size - 1

        entity_to_outputs[ entity ] = nil
        return nil
    end, PRE_HOOK )

end

do

    local player_Iterator = player.Iterator
    local ents_FindByName = ents.FindByName

    ---@param entity Entity
    ---@param output toolbox.Output
    ---@param value toolbox.Value
    ---@param activator Entity
    ---@param caller Entity
    local function perform_output( entity, output, value, activator, caller )
        ENTITY_Fire( entity, output.input, value or output.value, output.delay, activator, caller )
    end

    ---@param key toolbox.Key
    ---@param activator Entity
    ---@param value toolbox.Value
    function Base:FireOutput( key, activator, value )
        if not isOutput( key ) then
            error( "Output key '" .. key .. "' must start with 'On' or 'Out'", 2 )
        end

        -- Prefer an explicit Outputs table entry, then a method on the entity (On*/Out*).
        local transforms = self.Outputs
        local fn = (transforms and transforms[ key ]) or self[ key ]
        if isFunction( fn ) then
            value = fn( self, activator, value ) or value
        end

        local outputs = entity_to_outputs[ self ][ key ]
        local count = outputs[ 0 ]

        if count == 0 then
            return false
        end

        for i = count, 1, -1 do
            local output = outputs[ i ]

            if output.target == "!activator" then
                perform_output( activator, output, value, activator, self )
            elseif output.target == "!self" then
                perform_output( self, output, value, activator, self )
            elseif output.target == "!player" then
                for _, pl in player_Iterator() do
                    perform_output( pl, output, value, activator, self )
                end
            else
                ---@type Entity[]
                local entities = ents_FindByName( output.target )
                for j = 1, #entities, 1 do
                    perform_output( entities[ j ], output, value, activator, self )
                end
            end

            local repetitions = output.repetitions
            if repetitions ~= -1 then
                output.repetitions = repetitions - 1

                if repetitions <= 0 then
                    table_remove( outputs, i )
                    count = count - 1
                end
            end
        end

        outputs[ 0 ] = count

        return true
    end

end

do

    local string_sub = string.sub
    local string_len = string.len

    ---@param str string
    ---@param byte integer
    ---@param length integer
    ---@param limit integer
    ---@return string[]
    ---@return integer
    local function fast_split( str, byte, length, limit )
        ---@type string[]
        local values = {}

        ---@type integer
        local value_count = 0

        local split_position = 0
        local index = 1

        ::byte_split_loop::

        if string_byte( str, index, index ) == byte then
            if split_position ~= index then
                value_count = value_count + 1
                values[ value_count ] = string_sub( str, split_position + 1, index - 1 )
            end

            split_position = index
        end

        if value_count == limit then
            return values, value_count
        end

        if index ~= length then
            index = index + 1
            goto byte_split_loop
        end

        if split_position ~= index then
            value_count = value_count + 1
            values[ value_count ] = string_sub( str, split_position + 1, index )
        end

        return values, value_count
    end

    ---@param entity Entity
    ---@param key toolbox.Key
    ---@param value string
    hook.Add( "EntityKeyValue", "toolbox::Outputs", function( entity, key, value )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        ---@cast entity toolbox.Base

        if isOutput( key ) then
            local value_length = string_len( value )

            local values, value_count = fast_split( value, 0x1B --[[ ESC ]], value_length, 5 )
            if value_count < 2 then
                values, value_count = fast_split( value, 0x2C --[[ , ]], value_length, 5 )
            end

            local outputs = entity_to_outputs[ entity ][ key ]
            local count = outputs[ 0 ] + 1

            outputs[ count ] = {
                target = values[ 1 ] or "",
                input = values[ 2 ] or "",
                value = values[ 3 ] or "",
                delay = raw_tonumber( values[ 4 ], 10 ) or 0,
                repetitions = raw_tonumber( values[ 5 ], 10 ) or -1
            }

            outputs[ 0 ] = count

            return ""
        end

        if isKeyValue( key ) then
            entity.m_tKeyValues = entity.m_tKeyValues or {}
            entity.m_tKeyValues[ key ] = value

            local keyvalues = entity.KeyValues
            local fn = (keyvalues and keyvalues[ key ]) or entity[ "KeyValue_" .. key ]
            if isFunction( fn ) then
                fn( entity, value )
            end

            return nil
        end

        logger:error( "'%s' received an invalid key-value key '%s' with value '%s'", entity, key, value )
        return ""
    end, PRE_HOOK_RETURN )

end

do

    ---@param entity Entity
    ---@param key toolbox.Key
    ---@param activator Entity
    ---@param caller Entity
    ---@param value toolbox.Value
    hook.Add( "AcceptInput", "toolbox::Inputs", function( entity, key, activator, caller, value )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        ---@cast entity toolbox.Base

        if not isInput( key ) then
            logger:error( "'%s' received an invalid input key '%s', from '%s' by '%s'", entity, key, activator, caller )
            return nil
        end

        -- Prefer an explicit Inputs table entry, then an In* method on the entity.
        local inputs = entity.Inputs
        local fn = (inputs and inputs[ key ]) or entity[ key ]
        if isFunction( fn ) then
            fn( entity, activator, caller, value )
            return true
        end

        logger:warn( "'%s' left input '%s' unhandled from '%s' by '%s'", entity, key, activator, caller )
        return nil
    end, PRE_HOOK_RETURN )

end

---@alias toolbox.Type "nil" | "string" | "integer" | "float" | "boolean" | "vector" | "angle" | "color" | "entity" | "studio"

---@class toolbox.EditorField
---@field name string
---@field type? toolbox.Type
---@field description? string
---@field default? string | number | boolean

---@class toolbox.Editor
---@field title? string
---@field description? string
---@field icon? string
---@field base? string[]
---@field size? { min: string, max: string }
---@field inputs? toolbox.EditorField[]
---@field outputs? toolbox.EditorField[]
---@field keyvalues? toolbox.EditorField[]

do

    ---@type table<toolbox.Type, string>
    local TYPE_MAP = {
        [ "nil" ] = "void",
        string = "string",
        integer = "integer",
        float = "float",
        boolean = "boolean",
        vector = "vector",
        angle = "angle",
        color = "color255",
        entity = "target_destination",
        studio = "studio"
    }

    ---@param value string | number | boolean | nil
    ---@return string
    local function quote( value )
        if value == nil then
            return "\"\""
        end

        if std.isString( value ) then
            return "\"" .. value .. "\""
        end

        return tostring( value )
    end

    ---@param field toolbox.EditorField
    ---@return string
    local function format_keyvalue( field )
        return string_format(
            "\t%s(%s) : \"%s\" : %s",
            field.name,
            TYPE_MAP[ field.type or "string" ] or "string",
            field.description or "",
            quote( field.default )
        )
    end

    ---@param field toolbox.EditorField
    ---@return string
    local function format_input( field )
        return string_format(
            "\tinput %s(%s) : \"%s\"",
            field.name,
            TYPE_MAP[ field.type or "nil" ] or "void",
            field.description or ""
        )
    end

    ---@param field toolbox.EditorField
    ---@return string
    local function format_output( field )
        return string_format(
            "\toutput %s(%s) : \"%s\"",
            field.name,
            TYPE_MAP[ field.type or "nil" ] or "void",
            field.description or ""
        )
    end

    ---@param class_name string
    ---@param editor toolbox.Editor
    ---@return string
    local function generate_entity( class_name, editor )
        ---@type string[]
        local lines = {}
        local line_count = 0

        ---@param line string
        local function push( line )
            line_count = line_count + 1
            lines[ line_count ] = line
        end

        local attrs = ""

        local bases = editor.base
        if bases ~= nil and #bases > 0 then
            attrs = attrs .. " base(" .. table_concat( bases, ", " ) .. ")"
        end

        local icon = editor.icon
        if icon ~= nil and icon ~= "" then
            attrs = attrs .. " iconsprite(\"" .. icon .. "\")"
        end

        local size = editor.size
        if size ~= nil then
            attrs = attrs .. " size( " .. (size.min or "-8 -8 -8") .. ", " .. (size.max or "8 8 8") .. " )"
        end

        push( string_format(
            "@PointClass%s = %s : \"%s\"",
            attrs,
            class_name,
            editor.description or editor.title or class_name
        ) )

        push( "[" )

        local keyvalues = editor.keyvalues
        if keyvalues ~= nil then
            for i = 1, #keyvalues, 1 do
                push( format_keyvalue( keyvalues[ i ] ) )
            end
        end

        local inputs = editor.inputs
        if inputs ~= nil then
            for i = 1, #inputs, 1 do
                push( format_input( inputs[ i ] ) )
            end
        end

        local outputs = editor.outputs
        if outputs ~= nil then
            for i = 1, #outputs, 1 do
                push( format_output( outputs[ i ] ) )
            end
        end

        push( "]" )

        return table_concat( lines, "\n", 1, line_count )
    end

    ---@return string
    function toolbox.generateFGD()
        ---@type string[]
        local segments = {
            "// Generated by ToolBox — do not edit by hand",
            ""
        }
        local segment_count = 2

        for class_name, editor in pairs( toolbox.definitions or {} ) do
            segment_count = segment_count + 1
            segments[ segment_count ] = generate_entity( class_name, editor )
            segment_count = segment_count + 1
            segments[ segment_count ] = ""
        end

        return table_concat( segments, "\n", 1, segment_count )
    end

    concommand.Add( "toolbox.server.fgd", function( pl )
        if pl ~= nil and pl:IsValid() then
            return
        end

        local file_path = string_lower( toolbox.name ) .. ".fgd.txt"
        file.Write( file_path, toolbox.generateFGD() )
        logger:info( "Generated new FGD: 'data/%s'", file_path )
    end )

end
