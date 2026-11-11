---@class toolbox_code : toolbox.Base
local ENT = ENT

function ENT:Initialize()
    if self.m_strCode == nil then
        self.m_strCode = ""
    end
end

---@param value string
function ENT:KeyValue_code( value )
    self.m_strCode = tostring( value or "" )
end

---@param value string
function ENT:InSetCode( _, _, value )
    self.m_strCode = tostring( value or "" )
end

do

    local env = {}

    setmetatable( env, {
        __index = _G,
        __newindex = _G
    } )

    ---@param value string | number | nil
    ---@return Entity | nil
    local function resolve_entity( value )
        if value == nil or value == "" then
            return nil
        end

        local str = tostring( value )
        local index = tonumber( str, 10 )
        if index ~= nil then
            local ent = Entity( index )
            if ent:IsValid() then
                return ent
            end
        end

        local found = ents.FindByName( str )
        return found[ 1 ]
    end

    ---@param self toolbox_code
    ---@param source string
    ---@param activator Entity
    ---@param caller Entity
    ---@param value toolbox.Value
    local function run_source( self, source, activator, caller, value )
        if source == nil or source == "" then
            self:FireOutput( "OnError", activator, "empty code" )
            return
        end

        local fn = CompileString( source, "toolbox_code/" .. tostring( self:EntIndex() ), false )
        if not isfunction( fn ) then
            self:FireOutput( "OnError", activator, tostring( fn ) )
            self:ConsoleMessage( "error", "Compile failed: %s", tostring( fn ) )
            return
        end

        rawset( env, "A", activator )
        rawset( env, "C", caller )
        rawset( env, "S", self )
        rawset( env, "E", resolve_entity( value ) )
        rawset( env, "V", value )

        setfenv( fn, env )

        local ok, result = pcall( fn )
        if not ok then
            self:FireOutput( "OnError", activator, tostring( result ) )
            self:ConsoleMessage( "error", "Runtime error: %s", tostring( result ) )
            return
        end

        self:FireOutput( "OnSuccess", activator, result ~= nil and tostring( result ) or "" )
    end

    ---@param activator Entity
    ---@param caller Entity
    ---@param value toolbox.Value
    function ENT:InExecute( activator, caller, value )
        run_source( self, self.m_strCode, activator, caller, value )
    end

    ---@param activator Entity
    ---@param caller Entity
    ---@param value toolbox.Value
    function ENT:InRun( activator, caller, value )
        run_source( self, tostring( value or "" ), activator, caller, value )
    end

end
