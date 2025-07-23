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
--- @class AgenciesAppearanceHandler
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgenciesAppearanceHandler = {
    DefaultOptions = {
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
                Units = { 'Ice', 'Vicki', 'Magic', 'Len', 'PierreMerc', 'Pierre_FS' },
                Color = { 20, 7, 5, 255 },
            },
        },

        DefaultItemColors = PlaceObj('ColorizationPropSet', {
            'EditableColor1', RGBA(11, 19, 8, 255),
            'EditableColor2', RGBA(11, 19, 8, 255),
            'EditableColor3', RGBA(11, 19, 8, 255),
        }),

        -- Always Roll tables
        AlwaysRollForHat = { 'Mouse', 'Livewire' },
        AlwaysRollForHat2 = { 'Livewire' },
        AlwaysRollForHead = {},
        AlwaysRollForBody = {},
        AlwaysRollForShirt = {},
        AlwaysRollForArmor = {},
        AlwaysRollForChest = {},
        AlwaysRollForPants = {},
        AlwaysRollForHip = {},

        -- Never Roll tables
        NeverRollForHat = {},
        NeverRollForHat2 = {},
        NeverRollForHead = { 'Steroid' },
        NeverRollForBody = { 'Steroid' },
        NeverRollForShirt = { 'Steroid' },
        NeverRollForArmor = { 'Steroid' },
        NeverRollForChest = {},
        NeverRollForArmor = { 'Steroid' },
        NeverRollForPants = {},
        NeverRollForHip = {},
    },
    OptionsLoaded = false,
    OptionsLoadedForAgency = false
}

--- Iterates over default options and assigns them to self.
--- Then takes values from current faction if possible.
--- The idea is to allow other mods to insert their own values.
function AgenciesAppearanceHandler:EnsureOptionsAreLoaded()
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

    -- load faction values
    self.Pools = GetCurrentAgencyValue('AttirePools') or {}
    self.ChanceToRollForHat = GetCurrentAgencyValue('AttireChanceToRollForHat') or 80
    self.ChanceToRollForHat2 = GetCurrentAgencyValue('AttireChanceToRollForHat2') or 60
    self.ChanceToRollForHead = GetCurrentAgencyValue('AttireChanceToRollForHead') or 50
    self.ChanceToRollForBody = GetCurrentAgencyValue('AttireChanceToRollForBody') or 100
    self.ChanceToRollForShirt = GetCurrentAgencyValue('AttireChanceToRollForShirt') or 100
    self.ChanceToRollForArmor = GetCurrentAgencyValue('AttireChanceToRollForArmor') or 60
    self.ChanceToRollForChest = GetCurrentAgencyValue('AttireChanceToRollForChest') or 80
    self.ChanceToRollForPants = GetCurrentAgencyValue('AttireChanceToRollForPants') or 100
    self.ChanceToRollForHip = GetCurrentAgencyValue('AttireChanceToRollForHip') or 80

    Msg("AgenciesAppearanceOptionsLoaded", self, loadingForAgency)
    self.OptionsLoaded = true
    self.OptionsLoadedForAgency = loadingForAgency
end

function AgenciesAppearanceHandler:ReloadOptions()
    self.OptionsLoaded = false
    self:LoadOptions()
end

--- Generated (or takes from Game) parts for preset and inserts into the game.
--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @return string id of generated preset
function AgenciesAppearanceHandler:GeneratePreset(unit, defaultPresetId)
    self:EnsureOptionsAreLoaded()

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

--- Checks whatever Preset can be applied to unit. Currently only Mercs are supported.
--- @param unit UnitDataCompositeDef
function AgenciesAppearanceHandler:CanBeGeneratedForUnit(unit)
    if not self.Pools or #self.Pools == 0 then
        return false
    end

    local reasonsNotTo = {}
    Msg("AgenciesAppearanceCanApplyToUnit", unit, self, reasonsNotTo)

    if next(reasonsNotTo) ~= nil then
        return false
    end

    return unit and IsMerc(unit) and unit:ResolveValue("gender")
end

--- @param unit table
--- @return string id of generated preset
function AgenciesAppearanceHandler:GenerateId(unit)
    return table.concat({ unit.id, '_', self.OptionsLoadedForAgency, '_', Game[AGENCIES_PERSISTED_ID] })
end

--- @param unit UnitDataCompositeDef
--- @param
function AgenciesAppearanceHandler:GetPickedParts(unit, defaultPresetId, presetId)
    if Game[AGENCIES_APPEARANCE_TABLE] and Game[AGENCIES_APPEARANCE_TABLE][presetId] then
        return Game[AGENCIES_APPEARANCE_TABLE][presetId]
    end

    local pickedParts = {
        NativePreset = defaultPresetId
    }

    self:PickHeadParts(unit, pickedParts)
    self:PickBodyParts(unit, pickedParts)
    self:PickPantsParts(unit, pickedParts)

    if not Game[AGENCIES_APPEARANCE_TABLE] then
        Game[AGENCIES_APPEARANCE_TABLE] = {}
    end

    Game[AGENCIES_APPEARANCE_TABLE][presetId] = pickedParts

    return pickedParts
end

--- Populates pickedParts param with head related items.
--- @param unit table
--- @param pickedParts table collection of all picked parts so far, these are passed to the preset object
function AgenciesAppearanceHandler:PickHeadParts(unit, pickedParts)
    local Hat = false
    local Hat2 = false

    local shouldPickHat = self:ShouldPickPart(
        unit.id, 'FSAppearanceHat', self.ChanceToRollForHat,
        self.AlwaysRollForHat, self.NeverRollForHat
    )
    local shouldPickHat2 = self:ShouldPickPart(
        unit.id, 'FSAppearanceHat2', self.ChanceToRollForHat2,
        self.AlwaysRollForHat2, self.NeverRollForHat2
    )
    local shouldPickHead = self:ShouldPickPart(
        unit.id, 'FSAppearanceHead', self.ChanceToRollForHead,
        self.AlwaysRollForHead, self.NeverRollForHead
    )

    if shouldPickHat then
        Hat = self:GetFromAllPools('Hat', 'HatColor', unit, pickedParts)
    end

    local canPickForHat2 = true
    if Hat and Hat:ResolveValue('RollForHat2') == false then
        canPickForHat2 = false
    end

    if shouldPickHat2 and canPickForHat2 then
        Hat2 = self:GetFromAllPools('Hat2', 'Hat2Color', unit, pickedParts)

        if Hat and Hat2 then
            local try = 0

            while Hat.Hat == Hat2.Hat2 and try < 5 do
                try = try + 1

                Hat2 = self:GetFromAllPools('Hat2', 'Hat2Color', unit, pickedParts)
            end
        end
    end

    if shouldPickHead then
        self:GetFromAllPools('Head', 'HeadColor', unit, pickedParts)
    end

    if Hat and Hat:ResolveValue('HideHair') then
        pickedParts['Hair'] = false
    end

    if Hat2 and Hat2:ResolveValue('HideHair') then
        pickedParts['Hair'] = false
    end
end

--- Populates pickedParts param with body related items.
--- @param unit table
--- @param pickedParts table collection of all picked parts so far, these are passed to the preset object
function AgenciesAppearanceHandler:PickBodyParts(unit, pickedParts)
    local body = false

    local shouldPickBody = self:ShouldPickPart(
        unit.id, 'FSAppearanceBody', self.ChanceToRollForBody,
        self.AlwaysRollForBody, self.NeverRollForBody
    )
    local shouldPickShirt = self:ShouldPickPart(
        unit.id, 'FSAppearanceShirt', self.ChanceToRollForShirt,
        self.AlwaysRollForShirt, self.NeverRollForShirt
    )
    local shouldPickArmor = self:ShouldPickPart(
        unit.id, 'FSAppearanceArmor', self.ChanceToRollForArmor,
        self.AlwaysRollForArmor, self.NeverRollForArmor
    )
    local shouldPickChest = self:ShouldPickPart(
        unit.id, 'FSAppearanceChest', self.ChanceToRollForChest,
        self.AlwaysRollForChest, self.NeverRollForChest
    )

    if shouldPickBody then
        body = self:GetFromAllPools('Body', 'BodyColor', unit, pickedParts)
    end

    if shouldPickShirt then
        self:GetFromAllPools('Shirt', 'ShirtColor', unit, pickedParts)
    end

    if shouldPickArmor then
        self:GetFromAllPools('Armor', 'ArmorColor', unit, pickedParts)
    end

    -- TODO: add ChestAttachOffsetX to females if no armor
    if shouldPickChest then
        self:GetFromAllPools('Chest', 'ChestColor', unit, pickedParts)
    end

    if body and body:ResolveValue('HideHair') then
        pickedParts['Hair'] = false
    end

    if body and body:ResolveValue('HideHat') then
        pickedParts['Hat'] = false
    end

    if body and body:ResolveValue('HideHat2') then
        pickedParts['Hat2'] = false
    end
end

--- Populates pickedParts param with pants related items.
--- @param unit table
--- @param pickedParts table collection of all picked parts so far, these are passed to the preset object
function AgenciesAppearanceHandler:PickPantsParts(unit, pickedParts)
    local shouldPickPants = self:ShouldPickPart(
        unit.id, 'FSAppearancePants', self.ChanceToRollForPants,
        self.AlwaysRollForPants, self.NeverRollForPants
    )
    local shouldPickHip = self:ShouldPickPart(
        unit.id, 'FSAppearanceHip', self.ChanceToRollForHip,
        self.AlwaysRollForHip, self.NeverRollForHip
    )

    if shouldPickPants then
        self:GetFromAllPools('Pants', 'PantsColor', unit, pickedParts)
    end

    if shouldPickHip then
        self:GetFromAllPools('Hip', 'HipColor', unit, pickedParts)
    end
end

--- Return boolean whatever part should be picked based on chances and possibilities.
--- @param currentUnitId string will be compared in the lists
--- @param randName string name for InteractionRand
--- @param chanceToRoll (number|nil) chance that anything for this part will be picked
--- @param alwaysRollTable (table|nil) list of mercs that this part should ALWAYS be rolled for
--- @param neverRollTable (table|nil) list of mercs that this part should NEVER be rolled for
--- @return boolean
function AgenciesAppearanceHandler:ShouldPickPart(currentUnitId, randName, chanceToRoll, alwaysRollTable, neverRollTable)
    if alwaysRollTable then
        for _, unitId in pairs(alwaysRollTable) do
            if unitId == currentUnitId then
                return true
            end
        end
    end

    if neverRollTable then
        for _, unitId in pairs(neverRollTable) do
            if unitId == currentUnitId then
                return false
            end
        end
    end

    if not chanceToRoll then
        return true
    end

    return InteractionRand(100, randName) <= chanceToRoll
end

--- Gets a particular part of the preset and it's color (e.g. Armor, Body etc) from all available pools.
--- Returns AgencyAttirePoolItem but still populates pickedParts with proper keys.
--- @param partKey string part name in the both appearance and attire pool, like "Hat'. These have to match.
--- @param partColorKey string color field name, like 'HatColor'. This one is needed because attire item doesn't share name.
--- @param unit table
--- @param pickedParts table table containing parts and to which part and related fields will be appended.
--- @return (AgencyAttirePoolItem|nil)
function AgenciesAppearanceHandler:GetFromAllPools(partKey, partColorKey, unit, pickedParts)
    local items = {}
    local colors = {}

    -- collect all items (for particular part, with matching gender) and colors of the item and pool
    for _, pool in pairs(self.Pools) do
        local poolObj = AgencyAttirePools[pool:ResolveValue('AttirePool')]

        if poolObj:IsPoolAllowedForUnit(unit) then
            local poolItems = poolObj:ResolveValue(partKey)

            for _, item in pairs(poolItems) do
                if item:IsItemAllowedForUnit(unit) then
                    table.insert(items, item)
                end
            end

            local poolColors = poolObj:ResolveValue('Colors');

            for _, colorItem in pairs(poolColors) do
                table.insert(colors, colorItem)
            end
        end
    end

    if #items == 0 then
        return nil
    end

    local pickedItem = items[math.random(#items)]:Clone()

    for _, colorItem in pairs(pickedItem.Colors) do
        table.insert(colors, colorItem)
    end

    -- TODO: rework this, implement ResolveValues in
    for pickedItemValueKey, pickedItemValue in pairs(pickedItem) do
        if pickedItemValueKey == 'param_bindings' then
            -- TODO: get rid of this param_bindings
        else
            pickedParts[pickedItemValueKey] = pickedItemValue
        end
    end

    local pickedColor = self:GetItemColor(colors, pickedItem:ResolveValue("ColorDeviation"))
    local bodyColorKey = pickedItem:ResolveValue('BodyColorKey')

    if bodyColorKey ~= nil and bodyColorKey ~= "" then
        local bodyColor = self:GetBodyColor(unit.id, pickedItem:GetBodyColorDeviationAsTable())

        pickedColor[bodyColorKey] = RGBA(unpack_params(bodyColor))
    end

    pickedParts[partColorKey] = pickedColor

    return pickedItem
end

function AgenciesAppearanceHandler:GetItemColor(colors, deviation)
    local pickedColor = #colors > 0 and colors[math.random(#colors)] or self.DefaultItemColors
    pickedColor = pickedColor:Clone()

    if deviation and deviation ~= 0 then
        local colorProperties = { "EditableColor1", "EditableColor2", "EditableColor3" }

        for _, colorPropertyName in ipairs(colorProperties) do
            local color = pickedColor[colorPropertyName] or false

            if color then
                local rgba = pack_params(GetRGBA(color))

                for channel, channelValue in ipairs(rgba) do
                    rgba[channel] = MulDivRound(channelValue, 100 + deviation, 100)
                end

                pickedColor[colorPropertyName] = RGBA(unpack_params(rgba))
            end
        end
    end

    return pickedColor;
end

--- Returns a body color of a unit. Currently only basic game mercs are supported.
--- @param unit table
function AgenciesAppearanceHandler:GetBodyColor(unitId, deviation)
    local bodyColor = self.BodyColors.Default.Color

    for _, color in pairs(self.BodyColors) do
        for _, colorsUnitId in pairs(color.Units) do
            if colorsUnitId == unitId then
                bodyColor = color.Color
            end
        end
    end

    bodyColor = table_copy(bodyColor)

    if deviation then
        for position, bodyColorChannelValue in ipairs(bodyColor) do
            bodyColor[position] = bodyColorChannelValue + (deviation[position] or 0)
        end
    end

    return bodyColor
end

--- Merges pickedParts and defaultLook and places a preset inside AppearancePreset collection.
--- @param presetId string
--- @param pickedParts table all previously picked parts for an attire.
--- @param defaultPreset AppearancePreset a reference to units current/default look, this will be taken if nothing was picked.
function AgenciesAppearanceHandler:PlacePreset(presetId, pickedParts, defaultPreset)
    local preset = table_copy(pickedParts)

    preset.id = presetId
    preset.group = "Mercs"

    -- additionally, iterate over original preset and place items from it
    -- include item only if in new preset there's no mention of it (aka not false, but nil)
    if defaultPreset then
        for partName, defaultPart in pairs(defaultPreset) do
            if preset[partName] == nil then
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

--- Triggered when Agency is changed in main menu or in game. Should only apply appearance in game.
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
        -- some presets can be saved in table format, such dynamic agency presets,
        -- other presets can be just default in-game defined.

        if type(pickedParts) == "table" then
            local presetId = pickedParts.id
            local defaultPreset = AppearancePresets[pickedParts.NativePreset]

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
