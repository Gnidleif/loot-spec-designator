local this = CreateFrame('frame')

--- Event handling
this:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
this:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOOT_SPEC_UPDATED" then
        local id = GetLootSpecialization()
        if (id == 0) then
            print("Loot Specialization now matches your specialization")
        end
    end
end)

--- Variables
this.initialized = false
this.specs = {}
this.args = {}
this.instances = {}

--- Exported functions
function this.help()
    print("/lsd - brings up this help")
    print("/lsd mode [name] - switch loot spec to [name], leave empty to match spec")
end

function this.set_mode()
    local name = this.args[2]
    if (not name) then
        SetLootSpecialization(0)
        return
    end
    index = this.specs[name]
    if (index) then
        SetLootSpecialization(index)
    else
        print("invalid mode name")
    end
end

this.functions = {
    ["help"] = this.help,
    ["mode"] = this.set_mode
}

-- Functions
function this.init()
    local i = 0
    while (i < GetNumSpecializations()) do
        local id, name = GetSpecializationInfo(i+1)
        this.specs[string.lower(name)] = id
        i = i + 1
    end
    this.get_instances()
    this.initialized = true
end

function this.get_instances_by_tier(tier, is_raid)
    local instances = {}
    local i = 1
    while (true) do
        local id, name = EJ_GetInstanceByIndex(i, is_raid)
        if (not id) then
            break
        end
        instances[name] = id
        i = i + 1
    end
    return instances
end

function this.get_instances()
    for i = 1, EJ_GetNumTiers() do
        local tier = EJ_GetTierInfo(i)
        EJ_SelectTier(i)
        this.instances[tier] = {}
        this.instances[tier]["dungeons"] = this.get_instances_by_tier(i, false)
        this.instances[tier]["raids"] = this.get_instances_by_tier(i, true)
    end
    EJ_SelectTier(EJ_GetCurrentTier())
end

function this.SlashCommandHandler(cmd)
    if (not this.initialized) then
        this.init()
    end
    if (not cmd) then
        this.help()
    end
    cmd = string.lower(cmd)
    this.args = {}
    for w in cmd:gmatch("%S+") do
        table.insert(this.args, w)
    end
    local func = this.functions[this.args[1]]
    if (func) then
        func()
    else
        this.help()
    end
end

SlashCmdList["LOOTSPECDESIGNATOR"] = this.SlashCommandHandler
SLASH_LOOTSPECDESIGNATOR1 = "/lsd"