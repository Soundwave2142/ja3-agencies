--- ===================================================================================================================
--- Section 1 | Global function to local overrides, constants.
--- @author Soundwave2142
--- ===================================================================================================================

local pairs = pairs
local ipairs = ipairs
local empty_table = empty_table

AGENCIES_MOD_ID = "Agencies"
AGENCIES_OPTION = "AgencyChoice"
AGENCIES_PERSISTED_ID = "AgenciesPersistentId"

AGENCIES_DEFAULT = "Default"
AGENCIES_DEFAULT_LABEL = "A.I.M."

AGENCIES_AGENCY_STORAGE_KEY = "Agency"

--- ===================================================================================================================
--- Section 2 | Game start, initial functions.
--- @author Soundwave2142
--- ===================================================================================================================

--- When mods done loading,  calls for ApplyAgency to ensure current agency is applied to game.
function OnMsg.ModsReloaded()
    ApplyAgency()
end

--- When mod options are applied, calls for ApplyAgency to ensure correct agency is applied.
--- This function can be redundant if OnApply from CommonLib to be used.
--- @param modId string
--function OnMsg.ApplyModOptions(modId)
--    if modId ~= AGENCIES_MOD_ID then
--        return
--    end
--
--    local mod = Mods[modId]
--    local options = mod.options or empty_table
--
--    for _, item in ipairs(mod:GetOptionItems()) do
--        local value = options[item.name]
--
--        if item.name == AGENCIES_OPTION then
--            ApplyAgency(value)
--        end
--    end
--end

--- Triggers AgenciesApplyAgency to ensure current agency is applied to game and writes it to storage if needed.
--- @param agency string
function ApplyAgency(agency)
    if not agency then
        agency = GetCurrentAgency()
    end

    local storage = CurrentModStorageTable or {}
    local storageAgency = storage[AGENCIES_AGENCY_STORAGE_KEY]

    if not storageAgency or storageAgency ~= agency then
        storage[AGENCIES_AGENCY_STORAGE_KEY] = agency
        WriteModPersistentStorageTable()
    end

    Msg("AgenciesApplyAgency", storageAgency, agency)
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

--- Provides current agency id.
--- @return string
function GetCurrentAgency()
    local storage = CurrentModStorageTable or {}

    return storage[AGENCIES_AGENCY_STORAGE_KEY] or AGENCIES_DEFAULT
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

function OnMsg.ZuluGameLoaded()
    if not Game then
        return
    end

    if Game[AGENCIES_PERSISTED_ID] then
        return
    end

    Game[AGENCIES_PERSISTED_ID] = GenerateAgencyPersistentId()
end

function GenerateAgencyPersistentId()
    return random_encode64(48)
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
