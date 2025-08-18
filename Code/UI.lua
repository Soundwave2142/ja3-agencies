--- ===================================================================================================================
--- Section 1 | Constants, global function to local overrides.
--- @author Soundwave2142
--- ===================================================================================================================

local table = table
local ipairs = ipairs
local string_starts_with = string.starts_with
local empty_table = empty_table
local PlaceObj = PlaceObj
local UIFindControl = UIFindControl
local GetCurrentAgencyValue = GetCurrentAgencyValue

--- ===================================================================================================================
--- Section 2 | First load actions.
--- @author Soundwave2142
--- ===================================================================================================================

local function GetReasonsNotToEnableAgenciesUI(template)
    local reasonsNotTo = {}
    local options = CurrentModOptions or empty_table

    if not template then
        reasonsNotTo['template not found'] = true
    end

    if not IsAgenciesEnabled() then
        reasonsNotTo['agencies are disabled'] = true
    end

    if not options.AgencyEnableThemedUI then
        reasonsNotTo['setting not enabled'] = true
    end

    return reasonsNotTo
end

local function AgencyGeneralTemplateSwitcher(parent, mode, agencyTemplateValue, baseTemplateName)
    local template = GetCurrentAgencyValue(agencyTemplateValue)
    local reasonsNotTo = GetReasonsNotToEnableAgenciesUI(template)
    Msg("AgenciesCanApplyUI", parent, template, reasonsNotTo)

    if next(reasonsNotTo) ~= nil then
        template = baseTemplateName
    end

    for _, modes in ipairs(parent.xtemplate) do
        if modes['mode'] and modes.mode == mode then
            for _, element in ipairs(modes) do
                if element['__template'] and string_starts_with(element['__template'], baseTemplateName) then
                    element['__template'] = template
                end
            end
        end
    end
end

local function AgencyBrowserTemplateSwitcher(self, parent, context)
    return AgencyGeneralTemplateSwitcher(
        parent,
        "aim",
        "BrowserTemplate",
        "PDAAIMBrowser"
    )
end

local function AgencyLandingTemplateSwitcher(self, parent, context)
    return AgencyGeneralTemplateSwitcher(
        parent,
        "landing",
        "LandingTemplate",
        "PDABrowserLanding"
    )
end

function InsertAgencyTemplateSwitcher(template, replacingTemplate, runFunction)
    local match = { __template = replacingTemplate }
    local element, elementParent, elementIndex = UIFindControl(template, match)

    if not element or not elementParent then
        return
    end

    table.insert(elementParent, 1, PlaceObj('XTemplateCode', { 'run', runFunction }))
end

if FirstLoad then
    local templatesInserted = false

    function OnMsg.ModsReloaded()
        if not templatesInserted then
            InsertAgencyTemplateSwitcher("PDABrowser", "PDAAIMBrowser", AgencyBrowserTemplateSwitcher)
            InsertAgencyTemplateSwitcher("PDABrowser", "PDABrowserLanding", AgencyLandingTemplateSwitcher)

            templatesInserted = true
        end
    end
end

function OnMsg.AgenciesApplyAgency(previousAgency, newAgency)
    if previousAgency ~= newAgency and TutorialHintsState then
        TutorialHintsState.LandingPageShown = false
    end
end

--- ===================================================================================================================
--- SECTION 2 | Non template, but UI related overrides and compatibility changes.
--- ===================================================================================================================

local BasePDAUrl = TFormat.PDAUrl

--- Override original in order to replace A.I.M. url with whatever agency is current active.
TFormat.PDAUrl = function(...)
    local result = BasePDAUrl(...)

    return result
end
