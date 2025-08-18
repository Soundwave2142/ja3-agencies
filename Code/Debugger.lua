--- ===================================================================================================================
--- File that holds event triggers and funcitons purely for debugging.
--- @author Soundwave2142
--- ===================================================================================================================

function OnMsg.AgenciesApplyAgency(previousAgency, newAgency)
    print("Agencies: Switching agency", previousAgency, "to", newAgency)
end

function OnMsg.AgenciesIsEnabled(currentAgency, reasonsToDisable)
    if next(reasonsToDisable) == nil then
        return
    end

    print("Agencies: Checking if", currentAgency, "agency is enabled. Reasons not:", reasonsToDisable)
end

function OnMsg.AgenciesIsBonusEnabled(currentAgency, agencyBonusBelongsTo, reasonsToDisable)
    if next(reasonsToDisable) == nil then
        return
    end

    print("Agencies: Checking if", agencyBonusBelongsTo, "bonus is enabled. Reasons not:", reasonsToDisable)
end

function OnMsg.AgenciesAppearanceCanApplyToUnit(unit, AgenciesAppearanceOptions, reasonsNotTo)
    if next(reasonsNotTo) == nil then
        return
    end

    local unitId = unit and unit.id or "(no unit id)"

    print("Agencies: Checking if can apply appearance for", unitId, "unit.", "Reasons not: ", reasonsNotTo)
end

function OnMsg.AgenciesAppearanceCanApplyInMainMenu(reasonsNotTo)
    if next(reasonsNotTo) == nil then
        return
    end

    print("Agencies: Checking if can apply appearance in Main Menu.", "Reasons not: ", reasonsNotTo)
end

function OnMsg.AgenciesCanApplyUI(parent, template, reasonsNotTo)
    if next(reasonsNotTo) == nil then
        return
    end

    print("Agencies: Checking if can apply UI changes of template", template, "Reasons not: ", reasonsNotTo)
end

function AgenciesDebugAppearance(reloadOptions)
    Game[AGENCIES_PERSISTED_ID] = GenerateAgencyPersistentId()
    Game["AgenciesAppearances"] = {}

    if reloadOptions then
        AgenciesAppearanceOptions:ReloadOptions()
    end

    ReloadUnitsAppearance()
end

function AgenciesLocalStorageClear()
    CurrentModStorageTable = {}
    WriteModPersistentStorageTable()
end

function AgenciesLocalStorageDebug(key)
    local storage = CurrentModStorageTable or {}
    print(key and storage[key] or storage)
end
