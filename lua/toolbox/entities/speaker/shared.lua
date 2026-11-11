---@class toolbox_speaker : toolbox.Base
local ENT = ENT

ENT.Type = "anim"

ENT.Editor = {
    title = "Speaker",
    description = "Plays a URL or GAME file over BASS, synced for all clients (optional 3D positional audio).",
    base = { "Targetname", "Origin", "Angles" },
    icon = "editor/env_soundscape.vmt",
    size = { min = "-8 -8 -8", max = "8 8 8" },
    keyvalues = {
        { name = "path", type = "string", default = "", description = "Audio URL (http/https) or GAME file path" },
        { name = "volume", type = "float", default = 1, description = "Playback volume (0-2)" },
        { name = "rate", type = "float", default = 1, description = "Playback rate (0-2)" },
        { name = "loop", type = "boolean", default = 1, description = "Loop when the track ends" },
        { name = "spatial", type = "boolean", default = 1, description = "3D positional audio from this entity" },
        { name = "fade_min", type = "float", default = 200, description = "3D distance with full volume" },
        { name = "fade_max", type = "float", default = 2000, description = "3D distance where volume stops falling off" },
        { name = "autoplay", type = "boolean", default = 1, description = "Start playing on spawn if path is set" },
        { name = "enabled", type = "boolean", default = 1, description = "Whether clients may play this speaker" }
    },
    inputs = {
        { name = "InPlay", type = "string", description = "Starts playback (optional path; empty uses current path)" },
        { name = "InStop", type = "nil", description = "Stops playback" },
        { name = "InPause", type = "nil", description = "Pauses playback" },
        { name = "InResume", type = "nil", description = "Resumes playback" },
        { name = "InTogglePause", type = "nil", description = "Toggles pause state" },
        { name = "InSetPath", type = "string", description = "Sets the path/URL without starting playback" },
        { name = "InSetVolume", type = "float", description = "Sets volume (0-2)" },
        { name = "InSetRate", type = "float", description = "Sets playback rate (0-2)" },
        { name = "InSetLoop", type = "boolean", description = "Enables/disables looping" },
        { name = "InSkip", type = "float", description = "Seeks relatively in seconds (+forward / -back)" },
        { name = "InSetTime", type = "float", description = "Seeks to an absolute time in seconds" },
        { name = "InSetFadeMin", type = "float", description = "Sets 3D fade min distance" },
        { name = "InSetFadeMax", type = "float", description = "Sets 3D fade max distance" },
        { name = "InEnable", type = "nil", description = "Allows clients to hear this speaker" },
        { name = "InDisable", type = "nil", description = "Mutes this speaker for clients" }
    },
    outputs = {
        { name = "OnPlay", type = "nil", description = "Fired when playback starts" },
        { name = "OnStop", type = "nil", description = "Fired when playback stops" }
    }
}
