--- ===================================================================================================================
--- File that holds event triggers and funcitons purely for debugging.
--- @author Soundwave2142
--- ===================================================================================================================

function OnMsg.AgenciesApplyAgency(agency)
    print("Agencies: Applying agency", agency)
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
