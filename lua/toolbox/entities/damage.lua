---@class toolbox_damage : toolbox.Base
local ENT = ENT

ENT.Editor = {
    title = "Damage",
    description = "Applies CTakeDamageInfo damage to entities via TakeDamageInfo.",
    base = { "Targetname" },
    icon = "editor/info_target.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "damage", type = "float", default = 10, description = "Damage amount" },
        { name = "damage_type", type = "integer", default = 0, description = "DMG_* bitflags (0 = DMG_GENERIC)" },
        { name = "damage_force", type = "vector", default = "0 0 0", description = "Damage force vector" },
        { name = "damage_position", type = "vector", default = "", description = "Hit position (empty = target origin)" },
        { name = "attacker_name", type = "entity", default = "", description = "Attacker entity name (empty = activator, else self)" },
        { name = "inflictor_name", type = "entity", default = "", description = "Inflictor entity name (empty = self)" }
    },
    inputs = {
        { name = "InDamage", type = "nil", description = "Damages the activator" },
        { name = "InDamageEntity", type = "string", description = "Damages entities by name (value), or activator if empty" },
        { name = "InSetDamage", type = "float", description = "Sets the damage amount" },
        { name = "InSetDamageType", type = "integer", description = "Sets the DMG_* type flags" },
        { name = "InSetForce", type = "vector", description = "Sets the damage force" },
        { name = "InSetPosition", type = "vector", description = "Sets the damage position" }
    },
    outputs = {
        { name = "OnDamaged", type = "nil", description = "Fired for each entity that received damage" }
    }
}

local DMG_GENERIC = DMG_GENERIC or 0

function ENT:Initialize()
    if self.m_flDamage == nil then self.m_flDamage = 10 end
    if self.m_iDamageType == nil then self.m_iDamageType = DMG_GENERIC end
    if self.m_vForce == nil then self.m_vForce = Vector( 0, 0, 0 ) end
    if self.m_vPosition == nil then self.m_vPosition = nil end
    if self.m_strAttacker == nil then self.m_strAttacker = "" end
    if self.m_strInflictor == nil then self.m_strInflictor = "" end
end

---@param name string | nil
---@return Entity | nil
local function find_named( name )
    if name == nil or name == "" then
        return nil
    end

    local found = ents.FindByName( name )
    local ent = found[ 1 ]
    if ent ~= nil and ent:IsValid() then
        return ent
    end

    return nil
end

---@param self toolbox_damage
---@param activator Entity
---@return CTakeDamageInfo
local function build_damage_info( self, activator )
    local dmg = DamageInfo()
    dmg:SetDamage( self.m_flDamage or 10 )
    dmg:SetDamageType( self.m_iDamageType or DMG_GENERIC )

    local attacker = find_named( self.m_strAttacker )
    if attacker == nil then
        if activator:IsValid() then
            attacker = activator
        else
            attacker = self
        end
    end
    dmg:SetAttacker( attacker )

    local inflictor = find_named( self.m_strInflictor )
    if inflictor == nil then
        inflictor = self
    end
    dmg:SetInflictor( inflictor )

    local force = self.m_vForce
    if force ~= nil then
        dmg:SetDamageForce( force )
    end

    if self.m_vPosition ~= nil then
        dmg:SetDamagePosition( self.m_vPosition )
    end

    return dmg
end

---@param self toolbox_damage
---@param target Entity
---@param activator Entity
local function apply_damage( self, target, activator )
    if not target:IsValid() then
        return
    end

    local dmg = build_damage_info( self, activator )

    if self.m_vPosition == nil then
        dmg:SetDamagePosition( target:GetPos() )
    end

    target:TakeDamageInfo( dmg )
    self:FireOutput( "OnDamaged", target )
    self:ConsoleMessage( "debug", "Damaged %s for %s (type %s)", target, dmg:GetDamage(), dmg:GetDamageType() )
end

function ENT:KeyValue_damage( value )
    self.m_flDamage = tonumber( value, 10 ) or 10
end

function ENT:KeyValue_damage_type( value )
    self.m_iDamageType = tonumber( value, 10 ) or DMG_GENERIC
end

function ENT:KeyValue_damage_force( value )
    self.m_vForce = self.toVector( tostring( value ), 0, 0, 0 )
end

function ENT:KeyValue_damage_position( value )
    if value == nil or value == "" then
        self.m_vPosition = nil
        return
    end

    self.m_vPosition = self.toVector( tostring( value ) )
end

function ENT:KeyValue_attacker_name( value )
    self.m_strAttacker = tostring( value or "" )
end

function ENT:KeyValue_inflictor_name( value )
    self.m_strInflictor = tostring( value or "" )
end

function ENT:InSetDamage( _, _, value )
    self.m_flDamage = tonumber( value, 10 ) or self.m_flDamage
end

function ENT:InSetDamageType( _, _, value )
    self.m_iDamageType = tonumber( value, 10 ) or self.m_iDamageType
end

function ENT:InSetForce( _, _, value )
    self.m_vForce = self.toVector( tostring( value ), 0, 0, 0 )
end

function ENT:InSetPosition( _, _, value )
    if value == nil or value == "" then
        self.m_vPosition = nil
        return
    end

    self.m_vPosition = self.toVector( tostring( value ) )
end

---@param activator Entity
function ENT:InDamage( activator )
    apply_damage( self, activator, activator )
end

---@param activator Entity
---@param value string
function ENT:InDamageEntity( activator, _, value )
    local name = tostring( value or "" )
    if name == "" then
        apply_damage( self, activator, activator )
        return
    end

    local targets = ents.FindByName( name )
    for i = 1, #targets do
        apply_damage( self, targets[ i ], activator )
    end
end
