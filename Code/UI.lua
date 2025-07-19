--- ===================================================================================================================
--- Section 1 | Constants, global function to local overrides.
--- @author Soundwave2142
--- ===================================================================================================================

local AGENCIES_DEFAULT = AGENCIES_DEFAULT

local table = table
local PlaceObj = PlaceObj
local UIFindControl = UIFindControl
local IsAgency = IsAgency
local GetAgencies = GetAgencies

--- ===================================================================================================================
--- Section 2 | First load actions.
--- @author Soundwave2142
--- ===================================================================================================================

if FirstLoad then
    local templatesInserted = false

    function OnMsg.ModsReloaded()
        if not templatesInserted then
            AgenciesUIHandler:InsertAgencyTemplates()
            templatesInserted = true
        end
    end
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgenciesUIHandler
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgenciesUIHandler = {}

function AgenciesUIHandler:InsertAgencyTemplates()
    AgenciesUIHandler:InsertAgencyLandingPage()
    AgenciesUIHandler:InsertAgencyPage()
end

function AgenciesUIHandler:InsertAgencyLandingPage()
    local match = { __template = "PDABrowserLanding" }
    local element, parent, elementIndex = UIFindControl("PDABrowser", match)

    if not element then
        return
    end

    -- make base template on condition
    parent[elementIndex] = PlaceObj('XTemplateTemplate', {
        '__template', element['__template'],
        '__condition', function(parent1, context1) return IsAgency(AGENCIES_DEFAULT) end
    })

    for _, agency in ipairs(GetAgencies()) do
        table.insert(parent, elementIndex + 1, PlaceObj('XTemplateTemplate', {
            '__template', "PDABrowserLanding" .. agency,
            '__condition', function(parent1, context1) return IsAgency(agency) end
        }))
    end
end

function AgenciesUIHandler:InsertAgencyPage()
    local match = { __template = "PDAAIMBrowser" }
    local element, parent, elementIndex = UIFindControl("PDABrowser", match)

    if not element then
        return
    end

    -- make base template on condition
    parent[elementIndex] = PlaceObj('XTemplateTemplate', {
        'Id', "idBrowserContent",
        '__template', element['__template'],
        '__condition', function(parent1, context1) return IsAgency(AGENCIES_DEFAULT) end
    })

    for agencyIndex, agency in ipairs(GetAgencies()) do
        table.insert(parent, elementIndex + 1, PlaceObj('XTemplateTemplate', {
            'Id', "idBrowserContent",
            '__template', "PDAAIMBrowser" .. agency,
            '__condition', function(parent1, context1) return IsAgency(agency) end
        }))
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
