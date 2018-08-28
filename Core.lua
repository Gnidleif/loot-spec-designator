---- LOGIC SECTION
--- Variables
local this = CreateFrame('frame')
this.specs = {} -- table containing available specs where [name] = id
this.instances = {} -- table containing available instances where [tier][type][name] = id

--- Exported functions
-- help prints a list of helpful tips on how to use the addon
function this:help(args)
    print("/lsd - brings up this help")
    print("/lsd mode [name] - switch loot spec to [name], leave empty to match spec")
end

-- set_mode changes the current loot spec
function this:set_mode(args)
    local name = args[2]
    if (not name) then
        SetLootSpecialization(0)
        return
    end
    index = this.specs[name]
    if (index) then
        SetLootSpecialization(index)
    else
        print("invalid specialization name")
    end
end

-- functions is a local variable used to store functions exposed to the player
this.functions = {
    ["help"] = this.help,
    ["mode"] = this.set_mode
}

--- Functions
-- init_specializations iterate the number of available specs for the active char and adds each ID to the list of specs using the spec name as a key
function this:init_specializations()
    local i = 0
    while (i < GetNumSpecializations()) do
        local id, name = GetSpecializationInfo(i+1)
        this.specs[string.lower(name)] = id
        i = i + 1
    end
end

-- init_instances iterates every available instance of every available tier and adds them as lists of lists in the this.instances table 
function this:init_instances()
    -- by_tier is a local function used to iterate every dungeon or raid of a given tier and return them as a table with the stored ID as a value and the name as a key
    local by_tier = function(tier, is_raid)
        -- sets the current tier to i in order to retrieve relevant instances
        EJ_SelectTier(tier)
        local instances = {}
        local i = 1
        local id, name = EJ_GetInstanceByIndex(i, is_raid)
        while (id) do
            instances[name] = id
            i = i + 1
            id, name = EJ_GetInstanceByIndex(i, is_raid)
        end
        return instances
    end
    -- for loop that iterates each tier
    for i = 1, EJ_GetNumTiers() do
        local tier = EJ_GetTierInfo(i)
        this.instances[tier] = {
            raids = by_tier(i, true),
            dungeons = by_tier(i, false),
        }
    end
    -- resets the selected tier to curren tier to avoid any bugs
    EJ_SelectTier(EJ_GetCurrentTier())
end

function this:SlashCommandHandler(cmd)
    if (not cmd) then
        this.help()
    end
    -- make cmd lower case
    cmd = string.lower(cmd)
    -- emulates a CLI by finding characters and adding them to a list of args which are then sent to the functions
    local args = {}
    for w in cmd:gmatch("%S+") do
        table.insert(args, w)
    end
    -- if args[1] exists, it's always the name of the function
    local func = this.functions[args[1]]
    if (func) then
        func(args)
    else
        -- defaults to calling the help function if user tries to call non-existant function
        this.help()
    end
end

--- Event handling
--[[
Checking of events should be in a descending order of commonality to do less average if-checks each time an event fires,
this should not matter too much since if-checks are cheap and only a few events are registered to this
]]
this:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
this:RegisterEvent("PLAYER_LOGIN")
this:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOOT_SPEC_UPDATED" then
        local id = GetLootSpecialization()
        if (id == 0) then
            print("Loot Specialization now matches your specialization")
        end
    elseif event == "PLAYER_LOGIN" then
        this.init_specializations()
        this.init_instances()
    end
end)

--- Slash recognition
SLASH_LOOTSPECDESIGNATOR1 = "/lsd"
SlashCmdList["LOOTSPECDESIGNATOR"] = this.SlashCommandHandler

-- fast command to reload ui
SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

--[[
SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FrameSTK = function()
  LoadAddon('Blizzard_DebugTools')
  FrameStackTooltip_Toggle()
end

-- disables turning when pressing arrow keys (used for debugging)
for i = 1, NUM_CHAT_WINDOWS do
  _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
end
]]

---- UI SECTION
--- Variables
--- Exported functions
--- Functions
--- Event handling