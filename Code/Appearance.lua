--- ===================================================================================================================
--- Section 1 | Global function to local overrides, constants.
--- @author Soundwave2142
--- ===================================================================================================================

local table_insert = table.insert
local table_copy = table.copy
local table_sort = table.sort
local table_find = table.find
local table_equal_values = table.equal_values
local table_imap = table.imap
local table_find_value = table.find_value
local table_concat = table.concat
local next = next
local pairs = pairs
local ipairs = ipairs
local type = type

local APPEARANCES_STORAGE_KEY = "LastAppearances"

--- ===================================================================================================================
--- Section 2 | General functions for appearance presets manipulation.
--- @author Soundwave2142
--- ===================================================================================================================

--- @param presetId string
--- @param presetParentId string
--- @param parts table
--- @param partsId string
--- @param gameId string
function PlaceAgencyPreset(presetId, presetParentId, parts, partsId, gameId)
    local currentPreset = AppearancePresets[presetId]

    -- ensure that AppearancePreset that exists in memory was generated from the same set of parts
    if currentPreset and currentPreset:ResolveValue("GeneratedFromAppearanceId") == partsId then
        return
    elseif currentPreset then
        DoneObject(AppearancePresets[presetId])
        AppearancePresets[presetId] = nil
    end

    local preset = table_copy(parts)

    preset.id = presetId
    preset.group = "Mercs"

    preset.IsAgencyPreset = true
    preset.GeneratedFromTheGameId = gameId or (Game and Game.id or false)
    preset.GeneratedFromAppearanceId = partsId or false

    AgenciesAppearanceOptions:EnsureOptionsAreLoaded()

    local presetParent = presetParentId and AppearancePresets[presetParentId]
    local isDefaultPartAllowed = function(part)
        if part == "Hat" or part == "Hat2" then
            return AgenciesAppearanceOptions.AppendDefaultHats
        end

        return true
    end

    -- iterate over original preset and place items from it
    -- include item only if in new preset there's no mention of it (aka not false, but nil)
    if presetParent then
        for partName, defaultPart in pairs(presetParent) do
            if isDefaultPartAllowed(partName) and preset[partName] == nil then
                preset[partName] = defaultPart
            end
        end
    end

    PlaceObj('AppearancePreset', preset)
end

--- Cleans placed agency appearance presets if they don't match provided gameId,
--- this is required in cases where different game / campaign is loaded.
--- @param gameId string
function CleanAgencyPresets(gameId)
    for presetId, preset in pairs(GetAgencyPresets()) do
        local generatedFromId = preset:ResolveValue("GeneratedFromTheGameId")

        if generatedFromId ~= gameId then
            DoneObject(AppearancePresets[presetId])
            AppearancePresets[presetId] = nil
        end
    end
end

--- Returns AppearancePresets but only those that were created by Agency code.
--- @return table of AppearancePresets
function GetAgencyPresets()
    local presets = {}

    for presetId, preset in pairs(AppearancePresets) do
        if preset:ResolveValue("IsAgencyPreset") then
            presets[presetId] = preset
        end
    end

    return presets
end

--- Iterates units, pausing their appearance and forcing them to re-choose their appearance preset.
--- @param units table
function ReloadUnitsAppearance(units)
    units = units or GetAllPlayerUnitsOnMap()

    if #units < 1 then
        return
    end

    for _, unit in ipairs(units) do
        ReloadUnitAppearance(unit)
    end
end

--- Reloads appearance preset of a particular unit.
--- @param unit Unit
function ReloadUnitAppearance(unit)
    unit:StopAnimMomentHook()
    local anim = unit:GetStateText()
    local phase = unit:GetAnimPhase()

    unit:ApplyAppearance(ChooseUnitAppearance(unit.unitdatadef_id, unit.handle), true)
    unit:SetStateText(anim, const.eKeepComponentTargets)
    unit:SetAnimPhase(1, phase)
    unit:StartAnimMomentHook()
    unit:UpdateModifiedAnim()
    unit:UpdateMoveAnim()
end

--- Triggered when Agency is changed in game, reloads appearance.
function OnMsg.AgenciesApplyAgency()
    if not InGame then
        return
    end

    ReloadUnitsAppearance()
    SaveCurrentSquadPresets()
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- Responsible for providing pools, options and other for preset generation
--- @class AgenciesAppearanceOptions
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgenciesAppearanceOptions = {
    DefaultOptions = {
        DefaultItemColors = PlaceObj('ColorizationPropSet', {
            'EditableColor1', RGBA(11, 19, 8, 255),
            'EditableColor2', RGBA(11, 19, 8, 255),
            'EditableColor3', RGBA(11, 19, 8, 255),
        }),
        BodyColors = {
            -- white
            Default = {
                Color = { 187, 64, 35, 255 },
            },
            -- brown
            Brown = {
                Units = { 'Thor', 'Blood', 'Gus' },
                Color = { 91, 28, 18, 255 },
            },
            -- black
            Black = {
                Units = { 'Ice', 'Magic', 'Len', 'PierreMerc', 'Pierre_FS' },
                Color = { 20, 7, 5, 255 },
            },
            Black_Vicki = {
                Units = { 'Vicki' },
                Color = { 40, 13, 12, 255 }
            }
        },
        Offsets = { -- additional offsets applied for specific units.
            Hat = {
                Units = { 'Igor' },
                Offset = point(10, 0, 0)
            },
            Hat2 = {
                Units = { 'Igor' },
                Offset = point(10, 0, 0)
            }
            -- TODO: Implement
        },
        AlwaysRollFor = {
            Hat = { 'Mouse', 'Livewire' },
            Hat2 = { 'Livewire' },
        },
        NeverRollFor = {
            Head = { 'Steroid' },
            Body = { 'Steroid' },
            Shirt = { 'Steroid' },
            Armor = { 'Steroid' },
        },

        -- loaded from options of current Agency
        Pools = {},
        RollChances = {},
        AppendDefaultHats = true,
        BuildOrder = {
            "Body", "Shirt", "Armor", "Chest", -- upper part
            "Head", "Hat", "Hat2",             -- head
            "Pants", "Hip"                     -- lower part
        }
    },
    OptionsLoaded = false,
    OptionsLoadedForAgency = false
}

--- Iterates over default options and assigns them to self.
--- Then takes values from current faction if possible.
--- The idea is to allow other mods to insert their own values.
function AgenciesAppearanceOptions:EnsureOptionsAreLoaded()
    local loadingForAgency = GetCurrentAgency()

    if self.OptionsLoaded and self.OptionsLoadedForAgency == loadingForAgency then
        return
    end

    -- load default options first
    for key, value in pairs(self.DefaultOptions) do
        if type(value) == "table" then
            if type(value.class) == "string" and value.class then
                self[key] = value:Clone()
            else
                self[key] = table_copy(value)
            end
        else
            self[key] = value
        end
    end

    -- load agency values
    self.Pools = GetCurrentAgencyValue('AttirePools') or {}
    self.RollChances = {
        Hat = GetCurrentAgencyValue('AttireChanceToRollForHat') or 80,
        Hat2 = GetCurrentAgencyValue('AttireChanceToRollForHat2') or 60,
        Head = GetCurrentAgencyValue('AttireChanceToRollForHead') or 50,
        Body = GetCurrentAgencyValue('AttireChanceToRollForBody') or 100,
        Shirt = GetCurrentAgencyValue('AttireChanceToRollForShirt') or 100,
        Armor = GetCurrentAgencyValue('AttireChanceToRollForArmor') or 60,
        Chest = GetCurrentAgencyValue('AttireChanceToRollForChest') or 80,
        Pants = GetCurrentAgencyValue('AttireChanceToRollForPants') or 100,
        Hip = GetCurrentAgencyValue('AttireChanceToRollForHip') or 80,
    }
    self.AppendDefaultHats = GetCurrentAgencyValue('AttireAppendDefaultHats')

    Msg("AgenciesAppearanceOptionsLoaded", self, loadingForAgency)
    self.OptionsLoaded = true
    self.OptionsLoadedForAgency = loadingForAgency
end

--- Reloads current options with new / updated values.
function AgenciesAppearanceOptions:ReloadOptions()
    self.OptionsLoaded = false
    self:EnsureOptionsAreLoaded()
end

--- @return boolean
function AgenciesAppearanceOptions:HasPools()
    return self.Pools and #self.Pools > 0
end

--- Compiles parts for given unit from possible options.
--- @param unit UnitDataCompositeDef
--- @return table
function AgenciesAppearanceOptions:GetPickedPartsFromAllOptions(unit)
    local pickedParts = {}

    for _, partName in ipairs(self.BuildOrder) do
        self:GetPartFromAllPools(partName, unit, pickedParts)
    end

    return pickedParts
end

--- Gets a particular part of the preset and it's color (e.g. Armor, Body etc) from all available pools.
--- Returns picked part (AgencyAttirePoolItem) and populates pickedParts with proper keys.
--- @param partName string part name in the both appearance and attire pool, like "Hat'. These have to match.
--- @param unit UnitDataCompositeDef
--- @param pickedParts table table containing parts and to which part and related fields will be appended.
--- @return (AgencyAttirePoolItem|nil)
function AgenciesAppearanceOptions:GetPartFromAllPools(partName, unit, pickedParts)
    if not self:ShouldPickPart(unit.id, partName) then
        return nil
    end

    local items = {}

    -- collect all items (for particular part, with matching gender) and colors of the item and pool
    for _, pool in pairs(self.Pools) do
        local poolObj = AgencyAttirePools[pool:ResolveValue('AttirePool')]

        if poolObj:IsPoolAllowedForUnit(unit) then
            local poolItems = poolObj:ResolveValue(partName)

            for _, item in pairs(poolItems) do
                if item:IsItemAllowedForUnit(unit) then
                    table_insert(items, item)
                end
            end
        end
    end

    if #items == 0 then
        return nil
    end

    local randName = "AgencyItem" .. partName .. "For" .. unit.id
    local pickedItemIndex = InteractionRand(#items, randName) + 1

    local pickedItem = items[pickedItemIndex]:Clone()
    pickedItem:ResolvePickedItem(unit, pickedParts)

    return pickedItem
end

--- Return boolean whatever part should be picked based on chances and possibilities.
--- @param unitId string will be compared in the lists
--- @param partName string name of the part (eg. Body, Pants)
--- @return boolean
function AgenciesAppearanceOptions:ShouldPickPart(unitId, partName)
    local alwaysRollTable = self.AlwaysRollFor[partName] or {}

    for _, alwaysRollUnit in pairs(alwaysRollTable) do
        if unitId == alwaysRollUnit then
            return true
        end
    end

    local neverRollTable = self.NeverRollFor[partName] or {}

    for _, neverRollUnit in pairs(neverRollTable) do
        if unitId == neverRollUnit then
            return false
        end
    end

    local chanceToRoll = self.RollChances[partName] or false

    if not chanceToRoll then
        return true
    end

    local randName = "AgencyPickRoll" .. partName .. "For" .. unitId
    return InteractionRand(100, randName) <= chanceToRoll
end

--- Returns a body color of a unit. Currently only basic game mercs are supported.
--- @param unitId string
--- @return table
function AgenciesAppearanceOptions:GetBodyColor(unitId)
    local bodyColor = self.BodyColors.Default.Color

    for _, colorSet in pairs(self.BodyColors) do
        if table_find(colorSet.Units, unitId) then
            bodyColor = colorSet.Color
        end
    end

    bodyColor = table_copy(bodyColor)
    bodyColor = RGBA(unpack_params(bodyColor))

    return bodyColor
end

--- ===================================================================================================================
--- Section 3 | Overrides and event listeners for appearance appliers DURING GAME.
--- @author Soundwave2142
--- ===================================================================================================================

--- During initial hire, force the game to generate a preset for a new merc.
--- @param unit UnitDataCompositeDef
--- @param oldStatus string
--- @param newStatus string
function OnMsg.MercHireStatusChanged(unit, oldStatus, newStatus)
    if not IsMerc(unit) then
        return
    end

    if newStatus == "Hired" then
        ChooseUnitAppearance(unit.session_id)
    end
end

local BaseChooseUnitAppearance = ChooseUnitAppearance

--- Overriden in order to allow AgencyAppearanceObject to handle appearance of a merc.
--- @param merc_id string
--- @param handle table(?)
--- @return string
function ChooseUnitAppearance(merc_id, handle)
    local unit = UnitDataDefs[merc_id]
    local basePreset = BaseChooseUnitAppearance(merc_id, handle)

    if not Game or not InGame or not unit then
        return basePreset
    end

    return GenerateAgencyPreset(unit, basePreset)
end

--- Returns either agency preset or default preset, depending if agency preset could be created.
--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @return string
function GenerateAgencyPreset(unit, defaultPresetId)
    AgenciesAppearanceOptions:EnsureOptionsAreLoaded()

    if not CanAgencyPresetBeGeneratedForUnit(unit) then
        return defaultPresetId
    end

    local unitData = gv_UnitData[unit.id]
    local presetId = unitData:GetAgencyAppearancePresetId()

    if not presetId then
        return defaultPresetId
    end

    unitData:EnsureAgencyAppearance(unit, defaultPresetId, presetId)
    return AppearancePresets[presetId] and presetId or defaultPresetId
end

--- Performs basic required checks for blocking appearance.
--- @return table
local function GetReasonsNotToApplyAgencyAppearance()
    local reasonsNotTo = {}

    if not IsAgenciesEnabled() then
        reasonsNotTo['agencies are disabled'] = true
    end

    if not AgenciesAppearanceOptions:HasPools() then
        reasonsNotTo['agency has no pools'] = true
    end

    return reasonsNotTo
end

--- Checks whatever Preset can be applied to unit. Currently only Mercs are supported.
--- @param unit UnitDataCompositeDef
--- @return boolean
function CanAgencyPresetBeGeneratedForUnit(unit)
    if not unit or not IsMerc(unit) or not unit:ResolveValue("gender") then
        return false
    end

    if not gv_UnitData[unit.id] then
        return false
    end

    local reasonsNotTo = GetReasonsNotToApplyAgencyAppearance()
    Msg("AgenciesAppearanceCanApplyToUnit", unit, reasonsNotTo)

    return next(reasonsNotTo) == nil
end

--- ===================================================================================================================
--- Section 4 | Overrides and event listeners for appearance appliers DURING and FOR MAIN MENU.
--- @author Soundwave2142
--- ===================================================================================================================

--- Saves current units in a team to the mod local storage to be used in Main Menu,
--- triggered by EnterSector event (definition below).
function SaveCurrentSquadPresets()
    local storage = CurrentModStorageTable or {}
    local team = table_find_value(g_Teams, "control", "UI")

    if not team or not team.units then
        return
    end

    -- get two tables containing string names of presets, in order to compare them
    local newPresets = table_imap(
        team.units,
        function(merc)
            local appearancePresetId = merc:ResolveValue("Appearance")
            local appearancePreset = AppearancePresets[appearancePresetId]

            if not appearancePreset:ResolveValue("IsAgencyPreset") then
                return appearancePresetId
            end

            return table_concat({
                appearancePresetId, "_",
                appearancePreset:ResolveValue("GeneratedFromTheGameId") or "NA", "_",
                appearancePreset:ResolveValue("GeneratedFromAppearanceId") or "NA"
            })
        end
    )
    local oldPresets = table_imap(
        storage[APPEARANCES_STORAGE_KEY] or {},
        function(preset)
            if type(preset) == "string" then
                return preset
            end

            if not preset then
                return nil
            end

            return table_concat({
                preset.id, "_",
                preset.gameId or "NA", "_",
                preset.partsId or "NA"
            })
        end
    )

    table_sort(newPresets)
    table_sort(oldPresets)

    if table_equal_values(newPresets, oldPresets) then
        return
    end

    -- if tables previously were not equal, we need to assemble new table to write into storage
    local newPresetsParts = table_imap(
        team.units,
        function(merc)
            local mercUnitData = gv_UnitData[merc.session_id]

            if not mercUnitData then
                return nil
            end

            local appearancePresetId = merc:ResolveValue("Appearance")
            local appearancePreset = AppearancePresets[appearancePresetId]
            local storedAppearances = mercUnitData:ResolveValue('AgencyAppearances')

            if not appearancePreset:ResolveValue("IsAgencyPreset") or not storedAppearances[appearancePresetId] then
                return appearancePresetId
            end

            local storedAppearance = storedAppearances[appearancePresetId]

            return {
                id = appearancePresetId,
                native = storedAppearance.presetParent,
                gameId = appearancePreset:ResolveValue("GeneratedFromTheGameId"),
                parts = storedAppearance.parts,
                partsId = appearancePreset:ResolveValue("GeneratedFromAppearanceId")
            }
        end
    )

    storage[APPEARANCES_STORAGE_KEY] = newPresetsParts
    WriteModPersistentStorageTable()
end

OnMsg.EnterSector = SaveCurrentSquadPresets

--- Iterates each dummy unit on the map and applies preset from last game (if any saved),
--- triggered by PreGameMenuOpen event (definition below).
function ApplyAgencyPresetsInMainMenu()
    if not CanApplyAgencyPresetsInMainMenu() then
        return
    end

    local storage = CurrentModStorageTable or {}
    local lastSavedPresets = table_copy(storage[APPEARANCES_STORAGE_KEY] or {})

    if not lastSavedPresets or next(lastSavedPresets) == nil then
        return
    end

    for key, preset in ipairs(lastSavedPresets) do
        -- some presets can be saved in table format, such as dynamic agency presets,
        -- other presets can be just default in-game defined. Additionally, validate preset against outdated ones.
        local isValidPreset = function()
            return preset.id and preset.native and preset.parts and preset.partsId and preset.gameId
        end

        if type(preset) == "table" and isValidPreset(preset) then
            PlaceAgencyPreset(preset.id, preset.native, preset.parts, preset.partsId, preset.gameId)
            lastSavedPresets[key] = preset.id
        elseif type(preset) == "string" and AppearancePresets[preset] then
            lastSavedPresets[key] = preset
        else
            lastSavedPresets[key] = nil
        end
    end

    if #lastSavedPresets <= 0 then
        return
    end

    local constant = const.efVisible
    local presetPosition = 0

    MapForEach("map", "DummyUnit", function(unit)
        local preset = lastSavedPresets[presetPosition + 1]

        if preset and unit.Groups then
            unit:ApplyAppearance(preset, true)
            unit:SetEnumFlags(constant)
            presetPosition = presetPosition + 1
        else
            unit:ClearEnumFlags(constant)
        end
    end)
end

OnMsg.PreGameMenuOpen = ApplyAgencyPresetsInMainMenu

--- Checks whatever it's possible to apply presets to Main Menu by making a message call.
function CanApplyAgencyPresetsInMainMenu()
    local reasonsNotTo = {}
    Msg("AgenciesAppearanceCanApplyInMainMenu", reasonsNotTo)

    return not InGame and next(reasonsNotTo) == nil
end
