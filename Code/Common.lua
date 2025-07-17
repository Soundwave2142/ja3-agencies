--- ===================================================================================================================
--- @author Soundwave2142
--- ===================================================================================================================

local AGENCIES_MOD_ID = "Agencies"
local AGENCIES_OPTION = "AgencyChoice"
AGENCIES_DEFAULT = "Default"
AGENCIES_DEFAULT_LABEL = "A.I.M."

--- @param modId string
function OnMsg.ApplyModOptions(modId)
    if modId ~= AGENCIES_MOD_ID then
        return
    end

    local mod = Mods[modId]
    local options = mod.options or empty_table

    for _, item in ipairs(mod:GetOptionItems()) do
        local value = options[item.name]

        if item.name == AGENCIES_OPTION then
            Agencies:ChangeAgency(value)
        end
    end
end

function OnMsg.ModsReloaded()
    Msg("AgenciesOptionsLoaded")
end

function IsAgency(agency)
    if agency == AGENCIES_DEFAULT then
        agency = AGENCIES_DEFAULT_LABEL
    end

    local mod = Mods[AGENCIES_MOD_ID]
    local options = mod.options or empty_table

    return options[AGENCIES_OPTION] == agency
end

function GetAgencies()
    local mod = Mods[AGENCIES_MOD_ID]

    for _, item in ipairs(mod:GetOptionItems()) do
        if item.name == AGENCIES_OPTION and item.ChoiceList then
            return item.ChoiceList
        end
    end

    return { AGENCIES_DEFAULT_LABEL }
end

function ApplyAgency()

end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class Agencies
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.Agencies = {}

function Agencies:ChangeAgency(agency)
    if agency == AGENCIES_DEFAULT_LABEL then
        agency = AGENCIES_DEFAULT
    end

    AgenciesUIHandler:ChanceAgencyUI(agency)
end
