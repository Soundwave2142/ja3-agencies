--- ===================================================================================================================
--- Section 1 | Constants, global function to local overrides.
--- @author Soundwave2142
--- ===================================================================================================================

local ipairs = ipairs
local next = next
local table_insert = table.insert
local table_find_value = table.find_value
local string_starts_with = string.starts_with
local empty_table = empty_table
local PlaceObj = PlaceObj
local UIFindControl = UIFindControl
local IsKindOf = IsKindOf
local GetCurrentAgencyValue = GetCurrentAgencyValue

--- @return table
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

--- @param parent XTemplate
--- @param mode string
--- @param agencyTemplateValue string
--- @param baseTemplateName string
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

--- ===================================================================================================================
--- Section 2 | First load actions.
--- @author Soundwave2142
--- ===================================================================================================================

if FirstLoad then
    local templatesInserted = false

    --- Inserts all template switchers into game templates, template switchers are responsible for dynamically
    --- modifying __template property and therefore dynamically render different Ui depending on Agency.
    function OnMsg.ModsReloaded()
        if not templatesInserted then
            InsertAgencyTemplateSwitcher("PDABrowser", "PDAAIMBrowser", AgencyBrowserTemplateSwitcher)
            InsertAgencyTemplateSwitcher("PDABrowser", "PDABrowserLanding", AgencyLandingTemplateSwitcher)
            InsertAgencyAppearanceButton("PDAAIMBrowser")

            templatesInserted = true
        end
    end
end

--- When new agency applied, trigger new welcome page, new UI will be handled by switchers.
function OnMsg.AgenciesApplyAgency(previousAgency, newAgency)
    if previousAgency ~= newAgency and TutorialHintsState then
        TutorialHintsState.LandingPageShown = false
    end
end

--- Inserts switcher into template that will dynamically switch UI depending on Agency.
--- @param template string
--- @param template string
--- @param runFunction function
function InsertAgencyTemplateSwitcher(template, replacingTemplate, runFunction)
    local match = { __template = replacingTemplate }
    local element, elementParent, elementIndex = UIFindControl(template, match)

    if not element or not elementParent then
        return
    end

    table_insert(elementParent, 1, PlaceObj('XTemplateCode', { 'run', runFunction }))
end

--- Inserts "Redress" button to PDA Browser in merc section.
--- @param template string
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

    table_insert(elementParent, elementIndex + 1, action)
end

--- ===================================================================================================================
--- Section 3 | UI related appearance function.
--- @author Soundwave2142
--- ===================================================================================================================

--- Provides a state for Redress button in UI based on multiple conditions,
--- redress only allowed for unit that is owned by player and when unit is physically on the map.
--- @param host
--- @return string
function AgenciesGetRedressButtonState(host)
    if not IsAgenciesEnabled() then
        return "hidden"
    end

    local content = host.idContent

    if not IsKindOf(content, "PDABrowser") then
        return "hidden"
    end

    content = content.idBrowserContent

    if not IsKindOf(content, "PDAAIMBrowser") then
        return "hidden"
    end

    local mercId = content.selected_merc
    local team = table_find_value(g_Teams, "control", "UI")

    for _, unit in ipairs(team.units) do
        if mercId == unit.session_id then
            if gv_SatelliteView then
                return "disabled"
            end

            if not unit:IsLocalPlayerControlled() then
                return "disabled"
            end

            return "enabled"
        end
    end

    return "hidden"
end

--- Removes current preset of Agency merc and triggers reload
--- @param host
function AgenciesRedressButtonAction(host)
    local content = host.idContent

    if not IsKindOf(content, "PDABrowser") then
        return
    end

    content = content.idBrowserContent

    if not IsKindOf(content, "PDAAIMBrowser") then
        return
    end

    local unitId = content.selected_merc

    if not unitId then
        return
    end

    NetSyncEvent("AgenciesRedressSync", unitId)
end

--- @param unitId
function NetSyncEvents.AgenciesRedressSync(unitId)
    local unitData = gv_UnitData[unitId]

    if not unitData then
        return
    end

    unitData:ClearCurrentAgencyPreset()

    local mapUnit = g_Units[unitId]

    if mapUnit then
        ReloadUnitsAppearance({ mapUnit })
    end
end

--- ===================================================================================================================
--- Section 4 | Non template, but UI related overrides and compatibility changes.
--- @author Soundwave2142
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

--- Applies agency data to tabs when AgenciesApplyAgency (new agency applied) or ZuluGameLoaded.
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
