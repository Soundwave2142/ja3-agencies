--- ===================================================================================================================
--- Section 1 | Global function to local overrides, constants.
--- @author Soundwave2142
--- ===================================================================================================================

local table_copy = table.copy
local table_sort = table.sort
local table_equal_values = table.equal_values
local table_imap = table.imap
local table_find_value = table.find_value
local next = next
local pairs = pairs
local ipairs = ipairs
local PlaceObj = PlaceObj

local AGENCIES_PERSISTED_ID = AGENCIES_PERSISTED_ID
local AGENCIES_APPEARANCE_TABLE = "AgenciesAppearances"
local AGENCIES_APPEARANCES_STORAGE_KEY = "LastAppearances"

--- ===================================================================================================================
--- Section 2 | Overrides and event listeners for appearance appliers.
--- @author Soundwave2142
--- ===================================================================================================================

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

--- Gets a particular part of the preset and it's color (e.g. Armor, Body etc) from all available pools.
--- Returns picked part (AgencyAttirePoolItem) and populates pickedParts with proper keys.
--- @param partName string part name in the both appearance and attire pool, like "Hat'. These have to match.
--- @param unit UnitDataCompositeDef
--- @param pickedParts table table containing parts and to which part and related fields will be appended.
--- @return (AgencyAttirePoolItem|nil)
function AgenciesAppearanceOptions:GetFromAllPools(partName, unit, pickedParts)
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
                    table.insert(items, item)
                end
            end
        end
    end

    if #items == 0 then
        return nil
    end

    local pickedItem = items[math.random(#items)]:Clone()
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

    local randName = "ShouldPickPart" .. partName .. "For" .. unitId
    return InteractionRand(100, randName) <= chanceToRoll
end

--- Returns a body color of a unit. Currently only basic game mercs are supported.
--- @param unitId string
--- @param deviation number
function AgenciesAppearanceOptions:GetBodyColor(unitId)
    local bodyColor = self.BodyColors.Default.Color

    for _, colorSet in pairs(self.BodyColors) do
        if table.find(colorSet.Units, unitId) then
            bodyColor = colorSet.Color
        end
    end

    bodyColor = table_copy(bodyColor)
    bodyColor = RGBA(unpack_params(bodyColor))

    return bodyColor
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgenciesAppearanceHandler
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgenciesAppearanceHandler = {}

--- Generated (or takes from Game) parts for preset and inserts into the game.
--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @return string id of generated preset
function AgenciesAppearanceHandler:GeneratePreset(unit, defaultPresetId)
    AgenciesAppearanceOptions:EnsureOptionsAreLoaded()

    if not self:CanBeGeneratedForUnit(unit) then
        return defaultPresetId
    end

    local presetId = self:GenerateId(unit)

    if AppearancePresets[presetId] then
        return presetId
    end

    local pickedParts = self:GetPickedParts(unit, defaultPresetId, presetId)
    self:PlacePreset(presetId, pickedParts, AppearancePresets[defaultPresetId])

    return presetId
end

--- Performs basic required checks for blocking appearance.
--- @return table
local function GetReasonsNotToApplyAppearance()
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
function AgenciesAppearanceHandler:CanBeGeneratedForUnit(unit)
    local reasonsNotTo = GetReasonsNotToApplyAppearance()
    Msg("AgenciesAppearanceCanApplyToUnit", unit, self, reasonsNotTo)

    if next(reasonsNotTo) ~= nil then
        return false
    end

    return unit and IsMerc(unit) and unit:ResolveValue("gender")
end

--- @param unit table
--- @return string id of generated preset
function AgenciesAppearanceHandler:GenerateId(unit)
    return table.concat({
        unit.id, '_',
        AgenciesAppearanceOptions.OptionsLoadedForAgency, '_',
        Game[AGENCIES_PERSISTED_ID]
    })
end

--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @param presetId string
function AgenciesAppearanceHandler:GetPickedParts(unit, defaultPresetId, presetId)
    if Game[AGENCIES_APPEARANCE_TABLE] and Game[AGENCIES_APPEARANCE_TABLE][presetId] then
        return Game[AGENCIES_APPEARANCE_TABLE][presetId]
    end

    local pickedParts = {
        NativePreset = defaultPresetId
    }

    local buildOrder = {
        "Body", "Shirt", "Armor", "Chest", -- upper part
        "Head", "Hat", "Hat2",             -- head
        "Pants", "Hip"                     -- lower part
    }

    for _, partName in ipairs(buildOrder) do
        AgenciesAppearanceOptions:GetFromAllPools(partName, unit, pickedParts)
    end

    if not Game[AGENCIES_APPEARANCE_TABLE] then
        Game[AGENCIES_APPEARANCE_TABLE] = {}
    end

    Game[AGENCIES_APPEARANCE_TABLE][presetId] = pickedParts

    return pickedParts
end

--- Merges pickedParts and defaultLook and places a preset inside AppearancePreset collection.
--- @param presetId string
--- @param pickedParts table all previously picked parts for an attire.
--- @param defaultPreset AppearancePreset a reference to units current/default look, this will be taken if nothing was picked.
function AgenciesAppearanceHandler:PlacePreset(presetId, pickedParts, defaultPreset)
    local preset = table_copy(pickedParts)

    preset.id = presetId
    preset.group = "Mercs"

    local isDefaultPartAllowed = function(part)
        if part == "Hat" or part == "Hat2" then
            return AgenciesAppearanceOptions.AppendDefaultHats
        end

        return true
    end

    -- iterate over original preset and place items from it
    -- include item only if in new preset there's no mention of it (aka not false, but nil)
    if defaultPreset then
        for partName, defaultPart in pairs(defaultPreset) do
            if isDefaultPartAllowed(partName) and preset[partName] == nil then
                preset[partName] = defaultPart
            end
        end
    end

    PlaceObj('AppearancePreset', preset)
end

--- ===================================================================================================================
--- Section 3 | Overrides and event listeners for appearance appliers DURING GAME.
--- @author Soundwave2142
--- ===================================================================================================================

local BaseChooseUnitAppearance = ChooseUnitAppearance

--- Overriden in order to allow AgenciesAppearanceHandler to handle appearance of a merc.
--- @param merc_id string
--- @param handle table(?)
function ChooseUnitAppearance(merc_id, handle)
    local unit = UnitDataDefs[merc_id]
    local basePreset = BaseChooseUnitAppearance(merc_id, handle)

    if not Game then
        return basePreset
    end

    if not Game[AGENCIES_PERSISTED_ID] then
        Game[AGENCIES_PERSISTED_ID] = GenerateAgencyPersistentId()
    end

    return AgenciesAppearanceHandler:GeneratePreset(unit, basePreset)
end

--- Iterates units, pausing their appearance and forcing them to re-choose their appearance preset.
--- @param units table
function ReloadUnitsAppearance(units)
    units = units or GetAllPlayerUnitsOnMap()

    if #units < 1 then
        return
    end

    for _, unit in ipairs(units) do
        unit:StopAnimMomentHook()
        local anim = unit:GetStateText()
        local phase = unit:GetAnimPhase()

        unit:ApplyAppearance(ChooseUnitAppearance(unit.unitdatadef_id, unit.handle))
        unit:SetStateText(anim, const.eKeepComponentTargets)
        unit:SetAnimPhase(1, phase)
        unit:StartAnimMomentHook()
        unit:UpdateModifiedAnim()
        unit:UpdateMoveAnim()
    end
end

--- Triggered when Agency is changed in game, reloads appearance.
function OnMsg.AgenciesApplyAgency()
    if not InGame then
        return
    end

    ReloadUnitsAppearance()
    SaveCurrentSquadPresets()
end

--- ===================================================================================================================
--- Section 4 | Overrides and event listeners for appearance appliers DURING MAIN MENU.
--- @author Soundwave2142
--- ===================================================================================================================

--- Saves current units in a team to the mod local storage to be used in Main Menu.
function SaveCurrentSquadPresets()
    local team = table_find_value(g_Teams, "control", "UI")
    local storage = CurrentModStorageTable or {}

    if not team or not team.units then
        return
    end

    local newPresets = table_imap(
        team.units,
        function(merc) return merc:ResolveValue("Appearance") end
    )
    local oldPresets = table_imap(
        storage[AGENCIES_APPEARANCES_STORAGE_KEY] or {},
        function(preset) return preset.id end
    )

    table_sort(newPresets)
    table_sort(oldPresets)

    if table_equal_values(newPresets, oldPresets) then
        return
    end

    local appearances = {}

    for _, presetId in ipairs(newPresets) do
        if Game and Game[AGENCIES_APPEARANCE_TABLE] and Game[AGENCIES_APPEARANCE_TABLE][presetId] then
            local presetParts = table_copy(Game[AGENCIES_APPEARANCE_TABLE][presetId])
            presetParts.id = presetId

            appearances[_] = presetParts
        else
            appearances[_] = presetId
        end
    end

    storage[AGENCIES_APPEARANCES_STORAGE_KEY] = appearances
    WriteModPersistentStorageTable()
end

OnMsg.EnterSector = SaveCurrentSquadPresets

--- Checks whatever it's possible to apply presets to Main Menu by making a message call.
function CanApplyAgencyPresetsInMainMenu()
    local reasonsNotTo = {}
    Msg("AgenciesAppearanceCanApplyInMainMenu", reasonsNotTo)

    return not InGame and next(reasonsNotTo) == nil
end

--- Iterates each dummy unit on the map and applies preset from last game (if any saved).
function ApplyAgencyPresetsInMainMenu()
    if not CanApplyAgencyPresetsInMainMenu() then
        return
    end

    local storage = CurrentModStorageTable or {}
    local lastSavedPresets = table_copy(storage[AGENCIES_APPEARANCES_STORAGE_KEY] or {})

    if not lastSavedPresets or next(lastSavedPresets) == nil then
        return
    end

    for key, pickedParts in ipairs(lastSavedPresets) do
        -- some presets can be saved in table format, such as dynamic agency presets,
        -- other presets can be just default in-game defined.

        if type(pickedParts) == "table" then
            local presetId = pickedParts.id
            local defaultPreset = pickedParts.NativePreset and AppearancePresets[pickedParts.NativePreset] or nil

            if not AppearancePresets[presetId] then
                AgenciesAppearanceHandler:PlacePreset(presetId, pickedParts, defaultPreset)
            end

            lastSavedPresets[key] = presetId
        elseif type(pickedParts) == "string" and not AppearancePresets[pickedParts] then
            table.remove(lastSavedPresets, key)
        end
    end

    local presetPosition = 0
    MapForEach("map", "DummyUnit", function(unit)
        local preset = lastSavedPresets[presetPosition + 1]

        if preset and unit.Groups then
            unit:ApplyAppearance(preset, true)
            unit:SetEnumFlags(const.efVisible)
            presetPosition = presetPosition + 1
        else
            unit:ClearEnumFlags(const.efVisible)
        end
    end)
end

OnMsg.PreGameMenuOpen = ApplyAgencyPresetsInMainMenu
