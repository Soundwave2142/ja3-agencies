--- ===================================================================================================================
--- @author Soundwave2142
--- ===================================================================================================================

--local starts_with = string.starts_with
local table = table
local PlaceObj = PlaceObj
local IsAgency = IsAgency

if FirstLoad then
    local templatesInserted = false

    function OnMsg.AgenciesOptionsLoaded()
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

    -- insert additional templates
    local agencies = GetAgencies()

    for agencyIndex, agency in ipairs(agencies) do
        if agency ~= AGENCIES_DEFAULT and agency ~= AGENCIES_DEFAULT_LABEL then
            table.insert(parent, elementIndex + 1, PlaceObj('XTemplateTemplate', {
                '__template', "PDABrowserLanding" .. agency,
                '__condition', function(parent1, context1) return IsAgency(agency) end
            }))
        end
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

    -- insert additional templates
    local agencies = GetAgencies()

    for agencyIndex, agency in ipairs(agencies) do
        if agency ~= AGENCIES_DEFAULT and agency ~= AGENCIES_DEFAULT_LABEL then
            table.insert(parent, elementIndex + 1, PlaceObj('XTemplateTemplate', {
                'Id', "idBrowserContent",
                '__template', "PDAAIMBrowser" .. agency,
                '__condition', function(parent1, context1) return IsAgency(agency) end
            }))
        end
    end
end

--function AgenciesUIHandler:ChanceAgencyUI(agency)
--    local templatesPostfix = agency and agency == AGENCIES_DEFAULT and '' or agency
--
--    -- self:ChanceBrowserLandingPage(templatesPostfix)
--end
--
--function AgenciesUIHandler:ChanceBrowserLandingPage(templatePostfix)
--    local match = { mode = "landing" }
--    local element, parent, idx = UIFindControl("PDABrowser", match)
--
--    if not element then
--        return
--    end
--
--    local baseTemplate = "PDABrowserLanding"
--
--    for subElementIndex, subElement in ipairs(element) do
--        if (subElement["__template"] and starts_with(subElement["__template"], baseTemplate)) then
--            element[subElementIndex] = self:GetTemplateReference(baseTemplate, baseTemplate .. templatePostfix)
--        end
--    end
--
--    -- debug purposes
--    if TutorialHintsState and TutorialHintsState.LandingPageShown then
--        TutorialHintsState.LandingPageShown = false
--    end
--end
--
--function AgenciesUIHandler:GetTemplateReference(baseTemplate, template)
--    local references = self.TemplateReferences[baseTemplate] or {}
--
--    if not references[template] then
--        references[template] = PlaceObj('XTemplateTemplate', {
--            '__template', template,
--        })
--
--        self.TemplateReferences[baseTemplate] = references
--    end
--
--    return references[template]
--end

local BasePDAUrl = TFormat.PDAUrl

TFormat.PDAUrl = function(...)
    local result = BasePDAUrl(...)

    return result
end
