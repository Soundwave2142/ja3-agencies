--- ===================================================================================================================
--- File that holds event triggers and functions purely for debugging.
--- @author Soundwave2142
--- ===================================================================================================================

function AgenciesDebugAppearance(reloadOptions)
    local units = GetAllPlayerUnitsOnMap()

    for _, unit in ipairs(units) do
        local unitData = gv_UnitData[unit.unitdatadef_id]

        if unitData then
            unitData:ClearAgencyInfo()
        end
    end

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

function AgenciesTeleport(sector)
    local squad = gv_Squads[g_CurrentSquad]

    SetSatelliteSquadCurrentSector(squad, sector, true, true)
    OpenSatelliteView()

    local dlg = GetDialog("InGameInterface")

    if dlg then
        dlg:CreateThread("agencies-teleport", function()
            WaitMsg("OpenSatelliteView")
            UIEnterSector(sector)
        end)
    end
end

function AgenciesShutUpDebugger()
    local storage = CurrentModStorageTable or {}
    storage["Debugger"] = false

    WriteModPersistentStorageTable()
end

function AgenciesStartDebugger()
    local storage = CurrentModStorageTable or {}
    storage["Debugger"] = true

    WriteModPersistentStorageTable()
end

local storage = CurrentModStorageTable or {}

if storage["Debugger"] == false then
    return
end

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

    local campaign = Game and Game.Campaign

    if campaign and campaign == "HotDiamonds" then
        print("Agencies: Checking if", agencyBonusBelongsTo, "bonus is enabled. Reasons not:", reasonsToDisable)
    end
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
