AddCSLuaFile( "sledgehammer/cl_init.lua" )

---@class sledgehammer
local sledgehammer = sledgehammer
local logger = sledgehammer.Logger

local std = dreamwork.std

local string = std.string
local string_byte = string.byte

local raw_tonumber = std.raw.tonumber
local isFunction = std.isFunction

---@class Entity
local ENTITY = std.debug.findmetatable( "Entity" )
assert( ENTITY, "Potential environment corruption, unable to find `Entity` metatable." )

---@class sledgehammer.Base
local Base = sledgehammer.Base
Base.Type = "point"

local ENTITY_Fire = ENTITY.Fire

Base.GetValue = ENTITY.GetInternalVariable
Base.SetValue = ENTITY.SetKeyValue
Base.FireInput = ENTITY_Fire

local classes = sledgehammer.classes
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

---@type table<Entity, sledgehammer.Output[]>
local entity_to_outputs = {}

do

    local isentity = isentity

    setmetatable( entity_to_outputs, {
        ---@param self table<Entity, sledgehammer.Output[]>
        ---@param entity Entity
        ---@return sledgehammer.Output[]
        __index = function( self, entity )
            if not isentity( entity ) then
                error( "'entity' must be a valid entity", 3 )
            end

            if not entity:IsValid() then
                return {}
            end

            if not classes[ ENTITY_GetClass( entity ) ] then
                error( "received entity is not based on a sledgehammer class", 3 )
            end

            ---@type sledgehammer.Output[]
            local outputs = { [ 0 ] = 0 }
            self[ entity ] = outputs
            return outputs
        end,
        ___mode = "k"
    } )

end

do

    ---@type Entity[]
    local cleanup_queue = { [ 0 ] = 0 }

    hook.Add( "EntityRemoved", "sledgehammer::Cleanup", function( entity )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        local queue_size = cleanup_queue[ 0 ] + 1
        cleanup_queue[ queue_size ] = entity
        cleanup_queue[ 0 ] = queue_size
    end, PRE_HOOK )

    hook.Add( "Tick", "sledgehammer::Cleanup", function()
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
    ---@param output sledgehammer.Output
    ---@param value sledgehammer.Value
    ---@param activator Entity
    ---@param caller Entity
    local function preform_output( entity, output, value, activator, caller )
        ENTITY_Fire( entity, output.input, value or output.value, output.delay, activator, caller )
    end

    ---@param key sledgehammer.Key
    ---@param activator Entity
    ---@param value sledgehammer.Value
    function Base:FireOutput( key, activator, value )
        if not isOutput( key ) then
            error( "Output key '" .. key .. "' must start with 'On' or 'Out'", 2 )
        end

        local fn = self.Outputs[ key ]
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
                preform_output( activator, output, value, activator, self )
            elseif output.target == "!self" then
                preform_output( self, output, value, activator, self )
            elseif output.target == "!player" then
                for _, pl in player_Iterator() do
                    preform_output( pl, output, value, activator, self )
                end
            else
                local entities = ents_FindByName( output.target )
                for j = 1, #entities, 1 do
                    preform_output( entities[ j ], output, value, activator, self )
                end
            end

            local repetitions = output.repetitions
            if repetitions ~= -1 then
                output.repetitions = repetitions - 1

                if repetitions <= 0 then
                    table.remove( outputs, i )
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
    ---@param key sledgehammer.Key
    ---@param value string
    hook.Add( "EntityKeyValue", "sledgehammer::Outputs", function( entity, key, value )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        ---@cast entity sledgehammer.Base

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
            local fn = entity.KeyValues[ key ]
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
    ---@param key sledgehammer.Key
    ---@param activator Entity
    ---@param caller Entity
    ---@param value sledgehammer.Value
    hook.Add( "AcceptInput", "sledgehammer::Inputs", function( entity, key, activator, caller, value )
        if not classes[ ENTITY_GetClass( entity ) ] then
            return nil
        end

        ---@cast entity sledgehammer.Base

        -- sledgehammer.Type "void" | "string" | "integer" | "float" | "boolean" | "vector" | "color255" | "target_destination"
        ---@alias sledgehammer.Type "nil" | "string" | "integer" | "float" | "boolean" | "vector" | "angle" | "color" | "entity"

        local hammer_types = {
            [ "nil" ] = "void",
            [ "string" ] = "string",
            [ "integer" ] = "integer",
            [ "float" ] = "float",
            [ "boolean" ] = "boolean",
            [ "vector" ] = "vector",
            -- [ "choices" ] = "table", -- table<integer, string>
            [ "angle" ] = "angle",
            [ "color" ] = "color255",
            [ "entity" ] = "target_destination",
        }

        ---@class sledgehammer.Input
        ---@field name string
        ---@field description string
        ---@field type sledgehammer.Type

        if not isInput( key ) then
            logger:error( "'%s' received an invalid input key '%s', from '%s' by '%s'", entity, key, activator, caller )
            return nil
        end

        local fn = entity.Inputs[ key ]
        if isFunction( fn ) then
            fn( entity, activator, caller, value )
            return true
        end

        logger:warn( "'%s' left input '%s' unhandled from '%s' by '%s'", entity, key, activator, caller )
        return nil
    end, PRE_HOOK_RETURN )

    --                     name = "TurnOn",
    --                     type = "void",
    --                     description = "Enables the light"

end

-- void	OnTrigger
-- string	OnUser1
-- integer	Counter values
-- float	Timer values
-- boolean	Toggle state
-- vector	Position data
-- color255	Color data
-- target_destination	Entity references

-- do

--     local TYPE_MAP = {
--         integer = "integer",
--         float = "float",
--         string = "string",
--         boolean = "boolean",
--         studio = "studio",
--         target_destination = "target_destination",
--         [ "void" ] = "void"
--     }

--     local function quote( v )
--         if type( v ) == "string" then
--             return "\"" .. v .. "\""
--         end

--         return tostring( v )
--     end

--     local function format_keyvalue( kv )
--         local name = kv.name
--         local typ = TYPE_MAP[ kv.type ] or "string"
--         local default = kv.default or ""
--         local desc = kv.description or ""

--         return string.format(
--             "\t%s(%s) : \"%s\" : %s",
--             name, typ, desc, quote( default )
--         )
--     end

--     local function format_input( inp )
--         local name = inp.name
--         local typ = TYPE_MAP[ inp.type ] or "void"
--         local desc = inp.description or ""

--         return string.format(
--             "\tinput %s(%s) : \"%s\"",
--             name, typ, desc
--         )
--     end

--     local function format_output( out )
--         local name = out.name
--         local typ = TYPE_MAP[ out.type ] or "void"
--         local desc = out.description or ""

--         return string.format(
--             "\toutput %s(%s) : \"%s\"",
--             name, typ, desc
--         )
--     end

--     local function generate_entity( ent )
--         local lines = {}

--         local base_str = ""

--         if ent.base and #ent.base > 0 then
--             base_str = " base(" .. table.concat( ent.base, ", " ) .. ")"
--         end

--         local icon_path = ent.icon
--         if icon_path and not string.isEmpty( icon_path ) then
--             base_str = base_str .. " iconsprite(\"" .. icon_path .. "\")"
--         end

--         table.insert( lines,
--             string.format( "@%s%s = %s : \"%s\"",
--                 ent.class,
--                 base_str,
--                 ent.name,
--                 ent.description or ""
--             )
--         )

--         table.insert( lines, "[" )

--         if ent.keyvalues then
--             for _, kv in ipairs( ent.keyvalues ) do
--                 table.insert( lines, format_keyvalue( kv ) )
--             end
--         end

--         if ent.inputs then
--             for _, inp in ipairs( ent.inputs ) do
--                 table.insert( lines, format_input( inp ) )
--             end
--         end

--         if ent.outputs then
--             for _, out in ipairs( ent.outputs ) do
--                 table.insert( lines, format_output( out ) )
--             end
--         end

--         table.insert( lines, "]\n" )

--         return table.concat( lines, "\n" )
--     end

--     local function generate_fgd( entities )
--         local segments = {}
--         local segment_count = 0

--         for i = 1, #entities, 1 do
--             segment_count = segment_count + 1
--             segments[ segment_count ] = generate_entity( entities[ i ] )
--         end

--         if segment_count == 0 then
--             return ""
--         end

--         return table.concat( segments, "\n", 1, segment_count )
--     end

--     local data = {
--         {
--             class = "PointClass",
--             name = "dw_light",
--             icon = "editor/info_target.vmt",
--             base = {
--                 "Targetname",
--                 "Angles"
--             },

--             description = "Custom dynamic light entity",

--             size = {
--                 min = "-8 -8 -8",
--                 max = "8 8 8"
--             },

--             keyvalues = {
--                 {
--                     name = "brightness",
--                     type = "integer",
--                     default = 255,
--                     description = "Light brightness"
--                 },

--                 {
--                     name = "distance",
--                     type = "float",
--                     default = 512,
--                     description = "Light distance"
--                 },

--                 {
--                     name = "color",
--                     type = "string",
--                     default = "255 255 255",
--                     description = "RGB color"
--                 },

--                 {
--                     name = "model",
--                     type = "studio",
--                     default = "models/editor/light.mdl",
--                     description = "Editor model"
--                 }
--             },

--             inputs = {
--                 {
--                     name = "TurnOn",
--                     type = "void",
--                     description = "Enables the light"
--                 },

--                 {
--                     name = "TurnOff",
--                     type = "void",
--                     description = "Disables the light"
--                 },

--                 {
--                     name = "SetBrightness",
--                     type = "integer",
--                     description = "Changes brightness"
--                 }
--             },

--             outputs = {
--                 {
--                     name = "OnTurnedOn",
--                     type = "void",
--                     description = "Fired when enabled"
--                 },

--                 {
--                     name = "OnTurnedOff",
--                     type = "void",
--                     description = "Fired when disabled"
--                 }
--             }
--         },

--         ------------------------------------------------------------------------
--         -- NPC spawner
--         ------------------------------------------------------------------------

--         {
--             class = "PointClass",
--             name = "dw_npc_spawner",

--             base = {
--                 "Targetname",
--                 "Angles"
--             },

--             description = "NPC spawner entity",

--             size = {
--                 min = "-16 -16 0",
--                 max = "16 16 72"
--             },

--             keyvalues = {

--                 {
--                     name = "npc_class",
--                     type = "string",
--                     default = "npc_zombie",
--                     description = "NPC classname"
--                 },

--                 {
--                     name = "spawn_count",
--                     type = "integer",
--                     default = 5,
--                     description = "Amount of NPCs"
--                 },

--                 {
--                     name = "spawn_delay",
--                     type = "float",
--                     default = 1.0,
--                     description = "Delay between spawns"
--                 },

--                 {
--                     name = "start_disabled",
--                     type = "boolean",
--                     default = 0,
--                     description = "Start disabled"
--                 }
--             },

--             inputs = {

--                 {
--                     name = "SpawnNPC",
--                     type = "void",
--                     description = "Spawns NPC"
--                 },

--                 {
--                     name = "Enable",
--                     type = "void",
--                     description = "Enables spawner"
--                 },

--                 {
--                     name = "Disable",
--                     type = "void",
--                     description = "Disables spawner"
--                 }
--             },

--             outputs = {

--                 {
--                     name = "OnNPCSpawned",
--                     type = "void",
--                     description = "Fired when NPC spawned"
--                 },

--                 {
--                     name = "OnAllNPCsDead",
--                     type = "void",
--                     description = "Fired when all NPCs die"
--                 }
--             }
--         },

--         ------------------------------------------------------------------------
--         -- Brush entity
--         ------------------------------------------------------------------------

--         {
--             class = "SolidClass",
--             name = "dw_trigger_zone",

--             base = {
--                 "Targetname"
--             },

--             description = "Custom trigger volume",

--             keyvalues = {

--                 {
--                     name = "filtername",
--                     type = "target_destination",
--                     default = "",
--                     description = "Entity filter"
--                 },

--                 {
--                     name = "damage",
--                     type = "integer",
--                     default = 10,
--                     description = "Damage per second"
--                 }
--             },

--             inputs = {

--                 {
--                     name = "Enable",
--                     type = "void",
--                     description = "Enable trigger"
--                 },

--                 {
--                     name = "Disable",
--                     type = "void",
--                     description = "Disable trigger"
--                 }
--             },

--             outputs = {

--                 {
--                     name = "OnStartTouch",
--                     type = "void",
--                     description = "Entity entered trigger"
--                 },

--                 {
--                     name = "OnEndTouch",
--                     type = "void",
--                     description = "Entity left trigger"
--                 }
--             }
--         }
--     }

--     concommand.Add( "sledgehammer.server.fgd", function( pl )
--         if pl ~= nil and pl:IsValid() then return end

--         local file_path = string.lower( sledgehammer.name ) .. ".fgd.txt"
--         file.Write( file_path, generate_fgd( data ) )
--         logger:info( "Generated new FGD: 'data/%s'", file_path )
--     end )

-- end
