---@class toolbox_navigator : toolbox.Base
local ENT = ENT

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"

ENT.Editor = {
    title = "Navigator",
    description = "NextBot that pathfinds to a target on the navmesh with configurable speed, jump and teleport.",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/cs_hostage.vmt",
    size = { min = "-16 -16 -16", max = "16 16 16" },
    keyvalues = {
        { name = "model", type = "studio", default = "models/hunter/blocks/cube025x025x025.mdl", description = "Navigator model" },
        { name = "target_name", type = "entity", default = "", description = "Entity name to move toward" },
        { name = "speed", type = "float", default = 200, description = "Desired movement speed" },
        { name = "acceleration", type = "float", default = 400, description = "Locomotion acceleration" },
        { name = "deceleration", type = "float", default = 400, description = "Locomotion deceleration" },
        { name = "jump_height", type = "float", default = 58, description = "Max jump height when jumping is allowed" },
        { name = "step_height", type = "float", default = 18, description = "Max step height" },
        { name = "death_drop", type = "float", default = 200, description = "Max death drop height" },
        { name = "goal_tolerance", type = "float", default = 36, description = "Distance at which the target is considered reached" },
        { name = "allow_jump", type = "boolean", default = 1, description = "Allow jumping while pathing" },
        { name = "allow_teleport", type = "boolean", default = 0, description = "Teleport to the target when stuck or path is invalid" },
        { name = "enabled", type = "boolean", default = 1, description = "Start moving toward the target on spawn" }
    },
    inputs = {
        { name = "InStart", type = "nil", description = "Starts moving toward the current target" },
        { name = "InStop", type = "nil", description = "Stops movement" },
        { name = "InSetTarget", type = "string", description = "Sets the target entity name (empty clears)" },
        { name = "InSetSpeed", type = "float", description = "Sets movement speed" },
        { name = "InTeleport", type = "nil", description = "Teleports to the target if allow_teleport is enabled" },
        { name = "InAttach", type = "nil", description = "Parents the activator to this navigator" },
        { name = "InDetach", type = "nil", description = "Unparents the activator from this navigator" },
        { name = "InEnableJump", type = "nil", description = "Allows jumping" },
        { name = "InDisableJump", type = "nil", description = "Disallows jumping" },
        { name = "InEnableTeleport", type = "nil", description = "Allows fallback teleport" },
        { name = "InDisableTeleport", type = "nil", description = "Disallows fallback teleport" }
    },
    outputs = {
        { name = "OnReached", type = "nil", description = "Fired when the navigator reaches its target" },
        { name = "OnLostTarget", type = "nil", description = "Fired when the target becomes invalid" },
        { name = "OnStuck", type = "nil", description = "Fired when locomotion reports stuck" },
        { name = "OnTeleported", type = "nil", description = "Fired after a teleport to the target" }
    }
}
