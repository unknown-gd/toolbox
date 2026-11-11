---@class toolbox_memory : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Memory",
    description = "Stores an inner string/number state, optionally persisted as JSON under data/toolbox/memory/<map>.json.",
    base = { "Targetname" },
    icon = "editor/logic_relay.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "value", type = "string", default = "", description = "Initial memory value" },
        { name = "autosave", type = "boolean", default = 0, description = "Write to the map file whenever the value changes" }
    },
    inputs = {
        { name = "InSet", type = "string", description = "Sets the stored value" },
        { name = "InGet", type = "nil", description = "Fires OutValue with the stored value" },
        { name = "InClear", type = "nil", description = "Clears the stored value" },
        { name = "InAdd", type = "float", description = "Adds a number to the stored numeric value" },
        { name = "InSave", type = "nil", description = "Writes the value to data/toolbox/memory/<map>.json" },
        { name = "InLoad", type = "nil", description = "Loads the value from data/toolbox/memory/<map>.json" }
    },
    outputs = {
        { name = "OutValue", type = "string", description = "Current memory value" },
        { name = "OnChanged", type = "string", description = "Fired when the value changes" }
    }
}

local MEMORY_DIR = "toolbox/memory"

file.CreateDir( MEMORY_DIR )

---@return string
local function map_file_name()
    local map = game.GetMap() or "unknown"
    map = string.gsub( map, "[^%w%._%-]", "_" )
    return map
end

---@return string
local function map_file_path()
    return MEMORY_DIR .. "/" .. map_file_name() .. ".json"
end

function ENT:Initialize()
    if self.m_strValue == nil then self.m_strValue = "" end
    if self.m_bAutosave == nil then self.m_bAutosave = false end
end

---@param self toolbox_memory
---@param activator Entity
---@param value string
local function set_value( self, activator, value )
    value = tostring( value or "" )
    if self.m_strValue == value then
        return
    end

    self.m_strValue = value
    self:FireOutput( "OnChanged", activator, value )

    if self.m_bAutosave then
        self:InSave( activator )
    end
end

function ENT:KeyValue_value( value )
    self.m_strValue = tostring( value or "" )
end

function ENT:KeyValue_autosave( value )
    self.m_bAutosave = tobool( value )
end

function ENT:InSet( activator, _, value )
    set_value( self, activator, value )
end

function ENT:InGet( activator )
    self:FireOutput( "OutValue", activator, self.m_strValue )
end

function ENT:InClear( activator )
    set_value( self, activator, "" )
end

function ENT:InAdd( activator, _, value )
    local current = tonumber( self.m_strValue, 10 ) or 0
    local delta = tonumber( value, 10 ) or 0
    set_value( self, activator, tostring( current + delta ) )
end

function ENT:InSave( activator )
    local path = map_file_path()
    local payload = util.TableToJSON( {
        value = self.m_strValue,
        time = os.time()
    }, true )

    file.Write( path, payload or "{}" )
    self:ConsoleMessage( "debug", "Saved memory to data/%s", path )
end

function ENT:InLoad( activator )
    local path = map_file_path()
    local raw = file.Read( path, "DATA" )
    if raw == nil then
        self:ConsoleMessage( "warn", "Memory file missing: %s", path )
        return
    end

    local data = util.JSONToTable( raw )
    if data == nil then
        self:ConsoleMessage( "error", "Invalid JSON in memory file: %s", path )
        return
    end

    set_value( self, activator, data.value ~= nil and tostring( data.value ) or "" )
    self:FireOutput( "OutValue", activator, self.m_strValue )
end
