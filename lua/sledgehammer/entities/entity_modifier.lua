
local isfunction = isfunction
local isstring = isstring

---@class sh_entity_setup : sh_base
local ENT = ENT

ENT.Base = "sh_base"

---@param entity Entity
---@param fn_name string
---@param str string
---@param is_valid nil | fun( str: string ): boolean
local function apply_string( entity, fn_name, str, is_valid )
    if str == nil or not isstring( str ) then return end
    if is_valid ~= nil and not is_valid( str ) then return end

    local fn = entity[ fn_name ]
    if not isfunction( fn ) then return end

    fn( entity, str )
end

---@param str string
---@return boolean
local function is_valid_model( str )
    return str ~= "" and util.IsValidModel( str )
end

---@param entity Entity
---@param fn_name string
---@param str string
---@param is_valid nil | fun( value: integer ): boolean
local function apply_integer( entity, fn_name, str, is_valid )
    if str == nil or not isstring( str ) then return end

    local value = tonumber( str, 10 )
    if value == nil then return end
    value = math.floor( value )

    if is_valid ~= nil and not is_valid( value ) then return end

    local fn = entity[ fn_name ]
    if not isfunction( fn ) then return end

    fn( entity, value )
end


---@param entity Entity
---@param fn_name string
---@param str string
---@param is_valid nil | fun( value: number ): boolean
local function apply_double( entity, fn_name, str, is_valid )
    if str == nil or not isstring( str ) then return end

    local value = tonumber( str, 10 )
    if value == nil then return end

    if is_valid ~= nil and not is_valid( value ) then return end

    local fn = entity[ fn_name ]
    if not isfunction( fn ) then return end

    fn( entity, value )
end

---@param activator Entity
function ENT:InSetup( activator )
    apply_string( activator, "SetName", self:GetValue( "entity_name" ) )

    apply_string( activator, "SetModel", self:GetValue( "model_path" ), is_valid_model )
    apply_string( activator, "SetMaterial", self:GetValue( "model_material" ) )
    --- TODO: add web materials support
    apply_double( activator, "SetModelScale", self:GetValue( "model_scale" ) )
    apply_integer( activator, "SetSkin", self:GetValue( "model_skin" ) )
    apply_string( activator, "SetBodyGroups", self:GetValue( "model_bodygroups" ) )

    local color_str = self:GetValue( "model_color" )
    if color_str ~= nil and isstring( color_str ) then
        local color = self.toColor( color_str )
        if color ~= nil then
            local fn = activator.SetColor
            if isfunction( fn ) then
                fn( activator, color )
            end
        end
    end

    local position_str = self:GetValue( "position" )
    if position_str ~= nil and isstring( position_str ) then
        local position = self.toVector( position_str )
        if position ~= nil then
            local fn = activator.SetPos
            if isfunction( fn ) then
                fn( activator, position )
            end
        end
    end

    local angles_str = self:GetValue( "angles" )
    if angles_str ~= nil and isstring( angles_str ) then
        local angles = self.toAngle( angles_str )
        if angles ~= nil then
            ---@cast activator Player
            local fn = activator:IsPlayer() and activator.SetEyeAngles or activator.SetAngles
            if isfunction( fn ) then
                fn( activator, angles )
            end
        end
    end

    local parent_name_str = self:GetValue( "parent_name" )
    if parent_name_str ~= nil and isstring( parent_name_str ) then
        local entities = ents.FindByName( parent_name_str )

        local parent = entities[ math.random( 1, #entities ) ]
        if parent ~= nil and parent:IsValid() then
            local fn = activator.SetParent
            if isfunction( fn ) then
                fn( activator, parent )
            end
        end
    end

    apply_integer( activator, "SetCollisionGroup", self:GetValue( "collision_group" ) )
    apply_integer( activator, "SetMoveType", self:GetValue( "move_type" ) )

    apply_integer( activator, "SetHealth", self:GetValue( "health" ) )
    apply_integer( activator, "SetMaxHealth", self:GetValue( "max_health" ) )

    local phys_mass = self:GetValue( "phys_mass" )
    if phys_mass ~= nil then
        phys_mass = self.toNumber( phys_mass )
    end

    local phys_buoyancy = self:GetValue( "phys_buoyancy" )
    if phys_buoyancy ~= nil and isstring( phys_buoyancy ) then
        phys_buoyancy = self.toVector( phys_buoyancy )
    end

    local phys_flags = self:GetValue( "phys_flags" )
    if phys_flags ~= nil then
        phys_flags = self.toInteger( phys_flags )
    end

    local phys_material = self:GetValue( "phys_material" )
    if phys_material ~= nil and not isstring( phys_material ) then
        phys_material = tostring( phys_material )
    end

    local phys_gravity = self:GetValue( "phys_gravity" )
    if phys_gravity ~= nil then
        phys_gravity = tobool( phys_gravity )
    end

    local phys_collision = self:GetValue( "phys_collision" )
    if phys_collision ~= nil then
        phys_collision = tobool( phys_collision )
    end

    local phys_motion = self:GetValue( "phys_motion" )
    if phys_motion ~= nil then
        phys_motion = tobool( phys_motion )
    end

    for i = 0, activator:GetPhysicsObjectCount() - 1, 1 do
        local phys_object = activator:GetPhysicsObjectNum( i )
        if phys_object ~= nil and phys_object:IsValid() then
            if phys_mass ~= nil then
                phys_object:SetMass( phys_mass )
            end

            if phys_buoyancy ~= nil then
                phys_object:SetBuoyancyRatio( phys_buoyancy )
            end

            if phys_flags ~= nil then
                phys_object:AddGameFlag( phys_flags )
            end

            if phys_material ~= nil then
                phys_object:SetMaterial( phys_material )
            end

            if phys_gravity ~= nil then
                phys_object:EnableGravity( phys_gravity )
            end

            if phys_collision ~= nil then
                phys_object:EnableCollisions( phys_collision )
            end

            if phys_motion ~= nil then
                phys_object:EnableMotion( phys_motion )

                if phys_motion then
                    phys_object:Wake()
                end
            end
        end
    end
end
