--- ===================================================================================================================
--- Section 1 | Global function to local overrides, constants.
--- @author Soundwave2142
--- ===================================================================================================================

local pairs = pairs
local ipairs = ipairs
local empty_table = empty_table

local AGENCIES_MOD_ID = "Agencies"
local AGENCIES_OPTION = "AgencyChoice"

local AGENCIES_DEFAULT = "Default"
local AGENCIES_DEFAULT_LABEL = "A.I.M."
local AGENCIES_AGENCY_STORAGE_KEY = "Agency"

GameVar("gv_Agency", false)

--- ===================================================================================================================
--- Section 2 | Game start, initial / common functions.
--- @author Soundwave2142
--- ===================================================================================================================

--- Makes sure correct agency is applied when game finished loading or mods were changed.
function OnMsg.ModsReloaded()
    -- wait for a sync event from host instead
    if netInGame and not NetIsHost() then
        return
    end

    if Game then
        CleanAgencyPresets(Game.id)
    end

    ApplyAgency(GetCurrentAgency(true))
end

--- Makes sure correct agency is applied when new game is started.
--- @param game table
function OnMsg.NewGame(game)
    if GameState.loading_savegame then
        return
    end

    -- wait for a sync event from host instead
    if netInGame and not NetIsHost() then
        return
    end

    CleanAgencyPresets(Game.id)
    ApplyAgency(GetCurrentAgency(true), true)
end

--- Makes sure correct agency is applied when game is loaded.
function OnMsg.ZuluGameLoaded()
    -- wait for a sync event from host instead
    if netInGame and not NetIsHost() then
        return
    end

    CleanAgencyPresets(Game.id)
    ApplyAgency(GetCurrentAgency(true), true)
end

--- Triggered when user manually changes the Agency in menu
--- @param agency string
function ApplyAgencyFromMenu(agency)
    -- clients cannot change agency
    if netInGame and not NetIsHost() then
        return
    end

    ApplyAgency(agency)
end

--- Triggers AgenciesApplyAgency to ensure current agency is applied to game and writes it to storage if needed.
--- @param agency string
--- @param doNoWriteToStorage boolean
function ApplyAgency(agency, doNoWriteToStorage)
    if not agency then
        agency = GetCurrentAgency(true)
    end

    local storage = CurrentModStorageTable or {}
    local storageAgency = storage[AGENCIES_AGENCY_STORAGE_KEY]

    if not doNoWriteToStorage and (not storageAgency or storageAgency ~= agency) then
        storage[AGENCIES_AGENCY_STORAGE_KEY] = agency
        WriteModPersistentStorageTable()
    end

    NetSyncEvent("AgenciesApplyAgencySync", storageAgency, agency)
end

--- Syncs agency between all game participants, triggered by ApplyAgency.
--- @param storageAgency string
--- @param agency string
function NetSyncEvents.AgenciesApplyAgencySync(storageAgency, agency)
    gv_Agency = agency

    Msg("AgenciesApplyAgency", storageAgency, agency)
end

--- Provides current agency id.
--- @return string
function GetCurrentAgency(fromStorage)
    local gameAgency = gv_Agency or AGENCIES_DEFAULT

    if not gameAgency or fromStorage then
        local storage = CurrentModStorageTable or {}
        local storageAgency = storage[AGENCIES_AGENCY_STORAGE_KEY] or AGENCIES_DEFAULT

        return storageAgency
    end

    return gameAgency
end

--- Checks if agencies functionality should be enabled in general.
--- @return boolean
function IsAgenciesEnabled()
    local reasonsToDisable = {}
    local currentAgency = GetCurrentAgency()

    if currentAgency == AGENCIES_DEFAULT then
        reasonsToDisable['default agency active'] = true
    end

    Msg("AgenciesIsEnabled", currentAgency, reasonsToDisable)

    return next(reasonsToDisable) == nil
end

--- Checks if passed agency is selected currently selected agency.
--- @param agency string
--- @return boolean
function IsAgency(agency)
    return GetCurrentAgency() == agency
end

--- @param value string
--- @param agency string
--- @return (table|string|number|boolean|nil)
function GetCurrentAgencyValue(value, agency)
    if not agency then
        agency = GetCurrentAgency()
    end

    local agencyObject = Agencies[agency]

    if not agencyObject then
        return nil
    end

    return agencyObject:ResolveValue(value)
end

--- @param option string
--- @return (string|boolean)
function GetAgencyOption(option)
    local mod = Mods[AGENCIES_MOD_ID]
    local options = mod.options or empty_table

    return options[option]
end

--- Checks if agencies functionality should be enabled in general.
--- @return boolean
function IsAgenciesBonusEnabled(agencyBonusBelongsTo)
    local reasonsToDisable = {}
    local options = CurrentModOptions or empty_table
    local currentAgency = GetCurrentAgency()

    if not IsAgenciesEnabled() then
        reasonsToDisable['agencies are disabled'] = true
    end

    if currentAgency ~= agencyBonusBelongsTo then
        reasonsToDisable['bonus agency missmatch'] = true
    end

    if not options.AgencyEnableBonus then
        reasonsToDisable['setting not enabled'] = true
    end

    Msg("AgenciesIsBonusEnabled", currentAgency, agencyBonusBelongsTo, reasonsToDisable)

    return next(reasonsToDisable) == nil
end

local AGENCIES_LIST = false

--- Provides sorted list of agencies (ids) without default agency.
--- @param clearList boolean can be used to empty cached list.
--- @return table
function GetAgencies(clearList)
    if clearList then
        AGENCIES_LIST = false
    end

    if AGENCIES_LIST then
        return AGENCIES_LIST
    end

    local agenciesMeta = {}

    for agencyId, agencyObj in pairs(Agencies) do
        table.insert(agenciesMeta, { SortKey = agencyObj.SortKey or 0, Id = agencyId })
    end

    table.stable_sort(agenciesMeta, function(a, b)
        return (a.SortKey or 0) < (b.SortKey or 0)
    end)

    local agenciesSorted = {}

    for key, agencyMeta in ipairs(agenciesMeta) do
        agenciesSorted[key] = agencyMeta.Id
    end

    AGENCIES_LIST = agenciesSorted
    return agenciesSorted;
end

--- ===================================================================================================================
--- Section 3 | Overrides
--- @author Soundwave2142
--- ===================================================================================================================

local BaseGetOptionMeta = ModItemOptionChoice.GetOptionMeta

--- Overrides options provider that is used in Options -> Mods -> Agencies section of main menu.
--- For the purpose of generating a list dynamically from Agencies global map + default agency.
--- @return table
function ModItemOptionChoice:GetOptionMeta(...)
    local name = self.name
    local meta = BaseGetOptionMeta(self, ...)

    if not name or name ~= AGENCIES_OPTION then
        return meta
    end

    meta.items = {
        { text = T(AGENCIES_DEFAULT_LABEL), value = AGENCIES_DEFAULT }
    }

    local agencies = GetAgencies()

    for _, agencyId in ipairs(agencies) do
        local agency = Agencies[agencyId]

        if agency then
            table.insert(meta.items, { text = agency.display_name, value = agency.id })
        end
    end

    return meta
end
