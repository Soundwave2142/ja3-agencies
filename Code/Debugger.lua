--- ===================================================================================================================
--- File that holds event triggers and funcitons purely for debugging.
--- @author Soundwave2142
--- ===================================================================================================================

function OnMsg.AgenciesApplyAgency(agency)
    print("Agencies: Applying agency", agency)
end

function AgenciesLocalStorageDebug()
    print(CurrentModStorageTable or {})
end
