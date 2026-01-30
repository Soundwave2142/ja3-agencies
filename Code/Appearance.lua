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
--- @return table
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

    local unitData = gv_UnitData[unit.id]
    local presetId = unitData:GetAgencyAppearancePresetId()

    if not presetId then
        return defaultPresetId
    end

    if AppearancePresets[presetId] then
        return presetId
    end

    unitData:EnsureAgencyAppearance(unit, defaultPresetId, presetId)
    return AppearancePresets[presetId] and presetId or defaultPresetId
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
    if not unit or not IsMerc(unit) or not unit:ResolveValue("gender") then
        return false
    end

    if not gv_UnitData[unit.id] then
        return false
    end

    local reasonsNotTo = GetReasonsNotToApplyAppearance()
    Msg("AgenciesAppearanceCanApplyToUnit", unit, self, reasonsNotTo)

    return next(reasonsNotTo) == nil
end

function OnMsg.AgenciesAppearanceCanApplyToUnit(unit, AgenciesAppearanceHandler, reasonsNotTo)
    if netInGame and not NetIsHost() then
        local unitData = gv_UnitData[unit.id]

        local presetId = unitData:GetAgencyAppearancePresetId()
        local savedAppearances = unitData:ResolveValue("AgencyAppearances")

        if not savedAppearances[presetId] then
            reasonsNotTo['net game unit has no preset saved parts'] = true
        end
    end
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

--- Overriden in order to allow AgenciesAppearanceHandler to handle appearance of a merc.
--- @param merc_id string
--- @param handle table(?)
function ChooseUnitAppearance(merc_id, handle)
    local unit = UnitDataDefs[merc_id]
    local basePreset = BaseChooseUnitAppearance(merc_id, handle)

    if not Game or not InGame or not unit then
        return basePreset
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
        ReloadUnitAppearance(unit)
    end
end

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

    -- get two tables containing string names of presets, in order to compare them
    local newPresets = table_imap(
        team.units,
        function(merc)
            local appearancePreset = merc:ResolveValue("Appearance")
            local appearancePresetGameId = Game and Game.id or false

            return table.concat({
                appearancePreset, '_', appearancePresetGameId
            })
        end
    )
    local oldPresets = table_imap(
        storage[AGENCIES_APPEARANCES_STORAGE_KEY] or {},
        function(preset)
            if type(preset) == "string" then
                return preset
            end

            if not preset then
                return nil
            end

            return table.concat({
                preset.id, '_', preset.gameId
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

            local appearancePreset = merc:ResolveValue("Appearance")
            local appearancePresetGameId = Game and Game.id or false
            local storedAppearances = mercUnitData:ResolveValue('AgencyAppearances')

            -- if preset is not in stored agency presets, return it as string,
            -- it is most likely native preset from the base game
            if not storedAppearances[appearancePreset] then
                return appearancePreset
            end

            local storedAppearance = storedAppearances[appearancePreset]

            return {
                id = appearancePreset,
                native = storedAppearance.presetParent,
                gameId = appearancePresetGameId,
                parts = storedAppearance.parts
            }
        end
    )

    storage[AGENCIES_APPEARANCES_STORAGE_KEY] = newPresetsParts
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

    for key, savedPickedParts in ipairs(lastSavedPresets) do
        -- some presets can be saved in table format, such as dynamic agency presets,
        -- other presets can be just default in-game defined.

        if type(savedPickedParts) == "table" then
            local appearance = {
                presetParent = savedPickedParts.native,
                parts = savedPickedParts.parts
            }

            AgencyAppearanceObject:PlaceAgencyAppearanceAsPreset(savedPickedParts.id, appearance)
            lastSavedPresets[key] = savedPickedParts.id
        elseif type(savedPickedParts) == "string" and AppearancePresets[savedPickedParts] then
            lastSavedPresets[key] = savedPickedParts
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
