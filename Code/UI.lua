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

function InsertAgencyAppearanceButton(template)
    local match = { ActionId = "idHideBio" }
    local element, elementParent, elementIndex = UIFindControl(template, match)

    if not element or not elementParent then
        return
    end

    local action = PlaceObj('XTemplateAction', {
        'ActionId', "idRegenerateAttire",
        'ActionName', T(512051407484, "Redress"),
        'ActionToolbar', "ActionBar",
        'ActionState', function(self, host) return AgenciesGetRedressButtonState(host) end,
        'OnAction', function(self, host, source, ...) return AgenciesRedressButtonAction(host) end,
    })

    table.insert(elementParent, elementIndex + 1, action)
end

if FirstLoad then
    local templatesInserted = false

    function OnMsg.ModsReloaded()
        if not templatesInserted then
            InsertAgencyTemplateSwitcher("PDABrowser", "PDAAIMBrowser", AgencyBrowserTemplateSwitcher)
            InsertAgencyTemplateSwitcher("PDABrowser", "PDABrowserLanding", AgencyLandingTemplateSwitcher)
            InsertAgencyAppearanceButton("PDAAIMBrowser")

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
    local reasonsNotTo = GetReasonsNotToEnableAgenciesUI(true)
    Msg("AgenciesCanApplyUI", nil, true, reasonsNotTo)

    if next(reasonsNotTo) ~= nil then
        return result
    end

    local pda = GetDialog("PDADialog")

    if not pda then
        return false
    end

    local content = pda:ResolveId("idContent")
    local mercBrowser = IsKindOf(content, "PDABrowser") and content
    local mode = mercBrowser:GetMode()

    local agencyUrl = GetCurrentAgencyValue("BrowserUrl")

    local unsupportedModes = {
        imp = true, banner_page = true, page_error = true, bobby_ray_shop = true
    }

    if not IsAgenciesEnabled() or not agencyUrl or unsupportedModes[mode] then
        return result
    end

    local browserContent = mercBrowser.idBrowserContent

    if IsKindOf(browserContent, "PDAAIMBrowser") then
        local filters = GetAIMScreenFilters()
        local filter = filters[browserContent.current_filter]

        if not filter then
            return
        end

        local string = Untranslated(agencyUrl)
            .. GetCurrentAgencyValue("BrowserUrlFile")
            .. (filter.urlName or filter.name)
        local selectedUnit = browserContent.selected_merc

        if selectedUnit then
            string = string .. T { 260441561992, "/<Nick>", gv_UnitData[selectedUnit] }
        end

        return string
    end

    return Untranslated(agencyUrl)
end

--- Applies agency data to tabs.
function ApplyAgencyTabData()
    local urlName = GetCurrentAgencyValue("BrowserUrlName")
    local reasonsNotTo = GetReasonsNotToEnableAgenciesUI(true)
    Msg("AgenciesCanApplyUI", nil, true, reasonsNotTo)

    if next(reasonsNotTo) ~= nil or not urlName then
        urlName = T(750064110101, "A.I.M. Database")
    end

    for _, tab in ipairs(PDABrowserTabData or {}) do
        if tab.id and (tab.id == "aim" or tab.id == "landing") then
            tab.DisplayName = urlName
        end
    end
end

OnMsg.AgenciesApplyAgency = ApplyAgencyTabData
OnMsg.ZuluGameLoaded = ApplyAgencyTabData
