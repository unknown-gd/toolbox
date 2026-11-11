---@class toolbox_navigator : NextBot, toolbox.Base
local ENT = ENT

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

function ENT:Initialize()
    if self.m_strModel == nil then
        self.m_strModel = "models/hunter/blocks/cube025x025x025.mdl"
    end
    if self.m_strTarget == nil then self.m_strTarget = "" end
    if self.m_flSpeed == nil then self.m_flSpeed = 200 end
    if self.m_flAcceleration == nil then self.m_flAcceleration = 400 end
    if self.m_flDeceleration == nil then self.m_flDeceleration = 400 end
    if self.m_flJumpHeight == nil then self.m_flJumpHeight = 58 end
    if self.m_flStepHeight == nil then self.m_flStepHeight = 18 end
    if self.m_flDeathDrop == nil then self.m_flDeathDrop = 200 end
    if self.m_flGoalTolerance == nil then self.m_flGoalTolerance = 36 end
    if self.m_bAllowJump == nil then self.m_bAllowJump = true end
    if self.m_bAllowTeleport == nil then self.m_bAllowTeleport = false end
    if self.m_bEnabled == nil then self.m_bEnabled = true end

    self:SetModel( self.m_strModel )
    self:SetSolid( SOLID_BBOX )
    self:SetCollisionGroup( COLLISION_GROUP_NPC )
    self:DrawShadow( true )

    self.m_entTarget = NULL
    self:ResolveTarget()
    self:ApplyLoco()
end

function ENT:ApplyLoco()
    local loco = self.loco
    if loco == nil then
        return
    end

    loco:SetDesiredSpeed( self.m_flSpeed or 200 )
    loco:SetAcceleration( self.m_flAcceleration or 400 )
    loco:SetDeceleration( self.m_flDeceleration or 400 )
    loco:SetStepHeight( self.m_flStepHeight or 18 )
    loco:SetDeathDropHeight( self.m_flDeathDrop or 200 )

    if self.m_bAllowJump ~= false then
        loco:SetJumpHeight( self.m_flJumpHeight or 58 )
    else
        loco:SetJumpHeight( 0 )
    end
end

function ENT:ResolveTarget()
    local name = self.m_strTarget
    if name == nil or name == "" then
        self.m_entTarget = NULL
        return NULL
    end

    local found = ents.FindByName( name )
    local target = found[ 1 ]
    if target ~= nil and target:IsValid() then
        self.m_entTarget = target
        return target
    end

    self.m_entTarget = NULL
    return NULL
end

---@return Entity | nil
function ENT:GetMoveTarget()
    local target = self.m_entTarget
    if target:IsValid() then
        return target
    end

    return self:ResolveTarget()
end

function ENT:KeyValue_model( value )
    self.m_strModel = tostring( value or "" )
    if self.m_strModel == "" then
        self.m_strModel = "models/hunter/blocks/cube025x025x025.mdl"
    end
    if self:IsValid() then
        self:SetModel( self.m_strModel )
    end
end

function ENT:KeyValue_target_name( value )
    self.m_strTarget = tostring( value or "" )
    if self:IsValid() then
        self:ResolveTarget()
    end
end

function ENT:KeyValue_speed( value )
    self.m_flSpeed = tonumber( value, 10 ) or 200
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_acceleration( value )
    self.m_flAcceleration = tonumber( value, 10 ) or 400
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_deceleration( value )
    self.m_flDeceleration = tonumber( value, 10 ) or 400
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_jump_height( value )
    self.m_flJumpHeight = tonumber( value, 10 ) or 58
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_step_height( value )
    self.m_flStepHeight = tonumber( value, 10 ) or 18
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_death_drop( value )
    self.m_flDeathDrop = tonumber( value, 10 ) or 200
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_goal_tolerance( value )
    self.m_flGoalTolerance = tonumber( value, 10 ) or 36
end

function ENT:KeyValue_allow_jump( value )
    self.m_bAllowJump = tobool( value )
    if self:IsValid() then self:ApplyLoco() end
end

function ENT:KeyValue_allow_teleport( value )
    self.m_bAllowTeleport = tobool( value )
end

function ENT:KeyValue_enabled( value )
    self.m_bEnabled = tobool( value )
end

function ENT:InStart()
    self.m_bEnabled = true
end

function ENT:InStop()
    self.m_bEnabled = false
end

function ENT:InSetTarget( _, _, value )
    self.m_strTarget = tostring( value or "" )
    self:ResolveTarget()
end

function ENT:InSetSpeed( _, _, value )
    self.m_flSpeed = tonumber( value, 10 ) or self.m_flSpeed
    self:ApplyLoco()
end

function ENT:InEnableJump()
    self.m_bAllowJump = true
    self:ApplyLoco()
end

function ENT:InDisableJump()
    self.m_bAllowJump = false
    self:ApplyLoco()
end

function ENT:InEnableTeleport()
    self.m_bAllowTeleport = true
end

function ENT:InDisableTeleport()
    self.m_bAllowTeleport = false
end

---@param activator Entity
function ENT:InAttach( activator )
    if activator:IsValid() and activator ~= self then
        activator:SetParent( self )
    end
end

---@param activator Entity
function ENT:InDetach( activator )
    if activator:IsValid() and activator:GetParent() == self then
        activator:SetParent( NULL )
    end
end

---@param activator Entity | nil
---@return boolean
function ENT:TeleportToTarget( activator )
    if not self.m_bAllowTeleport then
        self:ConsoleMessage( "warn", "Teleport blocked (allow_teleport is disabled)" )
        return false
    end

    local target = self:GetMoveTarget()
    if target == nil then
        self:FireOutput( "OnLostTarget", activator or self )
        return false
    end

    self:SetPos( target:GetPos() )
    self:SetAngles( target:GetAngles() )
    self.loco:SetVelocity( Vector( 0, 0, 0 ) )
    self:FireOutput( "OnTeleported", activator or target )
    return true
end

function ENT:InTeleport( activator )
    self:TeleportToTarget( activator )
end

---@param pos Vector
---@return boolean
function ENT:MoveToPos( pos )
    local path = Path( "Follow" )
    path:SetMinLookAheadDistance( 100 )
    path:SetGoalTolerance( self.m_flGoalTolerance or 36 )
    path:Compute( self, pos )

    if not path:IsValid() then
        return false
    end

    while path:IsValid() and self.m_bEnabled do
        path:Update( self )

        if self.m_bAllowJump and self.loco:IsStuck() then
            -- try jumping over small obstacles when allowed
            if self.loco:IsOnGround() then
                self.loco:Jump()
            end
        end

        if self.loco:IsStuck() then
            self:FireOutput( "OnStuck", self )
            self:HandleStuck()

            if self.m_bAllowTeleport then
                self:TeleportToTarget( self )
                return true
            end

            return false
        end

        coroutine.yield()
    end

    return true
end

function ENT:RunBehaviour()
    while true do
        if self.m_bEnabled then
            local target = self:GetMoveTarget()
            if target ~= nil then
                local goal = target:GetPos()
                local tolerance = self.m_flGoalTolerance or 36

                if self:GetPos():DistToSqr( goal ) <= ( tolerance * tolerance ) then
                    self:FireOutput( "OnReached", target )

                    while self.m_bEnabled do
                        target = self:GetMoveTarget()
                        if target == nil then
                            self:FireOutput( "OnLostTarget", self )
                            break
                        end

                        if self:GetPos():DistToSqr( target:GetPos() ) > ( tolerance * tolerance ) then
                            break
                        end

                        coroutine.wait( 0.1 )
                    end
                else
                    self.loco:SetDesiredSpeed( self.m_flSpeed )
                    local ok = self:MoveToPos( goal )

                    if not ok then
                        if self.m_bAllowTeleport then
                            self:TeleportToTarget( self )
                        else
                            coroutine.wait( 0.5 )
                        end
                    elseif self:GetPos():DistToSqr( goal ) <= ( tolerance * tolerance ) then
                        self:FireOutput( "OnReached", target )
                    end
                end
            else
                coroutine.wait( 0.25 )
            end
        else
            coroutine.wait( 0.1 )
        end

        coroutine.yield()
    end
end
