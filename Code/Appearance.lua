--- ===================================================================================================================
--- Section 1 | Constants, global function to local overrides.
--- @author Soundwave2142
--- ===================================================================================================================

--- ===================================================================================================================
--- Section 2 | Overrides and event listeners for appearance appliers.
--- @author Soundwave2142
--- ===================================================================================================================
function OnMsg.PreGameMenuOpen()
    AgenciesAppearanceHandler:ApplyToMainMenu()
end

local BaseChooseUnitAppearance = ChooseUnitAppearance

function ChooseUnitAppearance(merc_id, handle)
    local unit = g_Units[merc_id]
    local basePreset = BaseChooseUnitAppearance(merc_id, handle)

    if AgenciesAppearanceHandler:CanBeAppliedToUnit(unit) then
        return AgenciesAppearanceHandler:GeneratePreset(unit, basePreset)
    end

    return basePreset
end

function OnMsg.LoadSessionData()
    AgenciesAppearanceHandler:ApplyToTeam()
end

function OnMsg.ExplorationStart()
    AgenciesAppearanceHandler:ApplyToTeam()
end

function OnMsg.AgenciesApplyAgency()
    AgenciesAppearanceHandler:ApplyToTeam()
end

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
function AgenciesAppearanceHandler:LoadOptions()
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
                self[key] = table.copy(value)
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

--- Iterates the team members and calls for ApplyToUnit for each
function AgenciesAppearanceHandler:ApplyToTeam(units)
    if not Game or not Game.Agencies then return end

    local playerUnitsOnMap = GetAllPlayerUnitsOnMap()

    for _, unit in ipairs(units or playerUnitsOnMap) do
        self:ApplyToUnit(unit)
    end

    self:SaveToStorage()
end

--- Calls for Preset generation if possible, stops animations and applies preset.
--- @param unit table
--- @param presetId (string|nil)
function AgenciesAppearanceHandler:ApplyToUnit(unit, presetId, saveToStorage)
    self:LoadOptions() -- despite being called multiple times, options are only loaded once

    if not self:CanBeAppliedToUnit(unit) then
        return
    end

    unit:StopAnimMomentHook()
    local anim = unit:GetStateText()
    local phase = unit:GetAnimPhase()
    presetId = presetId or self:GeneratePreset(unit)

    unit:ApplyAppearance(presetId, true)
    unit:SetStateText(anim, const.eKeepComponentTargets)
    unit:SetAnimPhase(1, phase)
    unit:StartAnimMomentHook()
    unit:UpdateModifiedAnim()
    unit:UpdateMoveAnim()

    if saveToStorage then
        self:SaveToStorage()
    end
end

--- Checks whatever Preset can be applied to unit. Currently only Mercs are supported.
--- @param unit table
function AgenciesAppearanceHandler:CanBeAppliedToUnit(unit)
    if not self.Pools or #self.Pools == 0 then
        return false
    end

    local reasons = {}
    Msg("AgenciesAppearanceCanApplyToUnit", unit, self, reasons)

    if next(reasons) ~= nil then
        return false
    end

    return unit and IsMerc(unit) and unit:GetGender()
end

--- Generated (or takes from Game) parts for preset and inserts into the game.
--- @param unit table
--- @return string id of generated preset
function AgenciesAppearanceHandler:GeneratePreset(unit, defaultPreset)
    local defaultLook = AppearancePresets[defaultPreset or unit:ChooseAppearance()]
    local presetId = self:GenerateId(unit)

    if AppearancePresets[presetId] then
        return presetId
    end

    local pickedParts = self:GetPickedParts(unit, defaultLook, presetId)
    self:PlacePreset(presetId, pickedParts, defaultLook)

    return presetId
end

--- @param unit table
--- @return string id of generated preset
function AgenciesAppearanceHandler:GenerateId(unit)
    return table.concat({
        'Agencies', '_',
        Game.Agencies.id, '_',
        unit.unitdatadef_id, '_',
        self.OptionsLoadedForAgency,
    })
end

function AgenciesAppearanceHandler:GetPickedParts(unit, defaultLook, presetId)
    if Game.Agencies and Game.Agencies.appearancePresets and Game.Agencies.appearancePresets[presetId] then
        return Game.Agencies.appearancePresets[presetId]
    end

    local pickedParts = {
        NativePreset = defaultLook.id
    }

    self:PickHeadParts(unit, pickedParts)
    self:PickBodyParts(unit, pickedParts)
    self:PickPantsParts(unit, pickedParts)

    if not Game.Agencies.appearancePresets then
        Game.Agencies.appearancePresets = {}
    end

    Game.Agencies.appearancePresets[presetId] = pickedParts

    return pickedParts
end

--- Populates pickedParts param with head related items.
--- @param unit table
--- @param pickedParts table collection of all picked parts so far, these are passed to the preset object
function AgenciesAppearanceHandler:PickHeadParts(unit, pickedParts)
    local Hat = false
    local Hat2 = false

    local shouldPickHat = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceHat', self.ChanceToRollForHat,
        self.AlwaysRollForHat, self.NeverRollForHat
    )
    local shouldPickHat2 = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceHat2', self.ChanceToRollForHat2,
        self.AlwaysRollForHat2, self.NeverRollForHat2
    )
    local shouldPickHead = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceHead', self.ChanceToRollForHead,
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
        unit.unitdatadef_id, 'FSAppearanceBody', self.ChanceToRollForBody,
        self.AlwaysRollForBody, self.NeverRollForBody
    )
    local shouldPickShirt = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceShirt', self.ChanceToRollForShirt,
        self.AlwaysRollForShirt, self.NeverRollForShirt
    )
    local shouldPickArmor = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceArmor', self.ChanceToRollForArmor,
        self.AlwaysRollForArmor, self.NeverRollForArmor
    )
    local shouldPickChest = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceChest', self.ChanceToRollForChest,
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
        unit.unitdatadef_id, 'FSAppearancePants', self.ChanceToRollForPants,
        self.AlwaysRollForPants, self.NeverRollForPants
    )
    local shouldPickHip = self:ShouldPickPart(
        unit.unitdatadef_id, 'FSAppearanceHip', self.ChanceToRollForHip,
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

    local pickedColor = #colors > 0 and colors[math.random(#colors)]:Clone() or self.DefaultItemColors:Clone()
    local bodyColorKey = pickedItem:ResolveValue('BodyColorKey')

    if bodyColorKey ~= nil and bodyColorKey ~= "" then
        local bodyColor = self:GetBodyColor(unit, pickedItem:GetBodyColorDeviationAsTable())

        pickedColor[bodyColorKey] = RGBA(unpack_params(bodyColor))
    end

    pickedParts[partColorKey] = pickedColor

    return pickedItem
end

--- Returns a body color of a unit. Currently only basic game mercs are supported.
--- @param unit table
function AgenciesAppearanceHandler:GetBodyColor(unit, deviation)
    local bodyColor = self.BodyColors.Default.Color

    for _, color in pairs(self.BodyColors) do
        for _, unitId in pairs(color.Units) do
            if unitId == unit.unitdatadef_id then
                bodyColor = color.Color
            end
        end
    end

    bodyColor = table.copy(bodyColor)

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
--- @param defaultLook table a reference to units current/default look, this will be taken if nothing was picked.
function AgenciesAppearanceHandler:PlacePreset(presetId, pickedParts, defaultLook)
    local preset = {
        group = "Mercs",
        id = presetId,
    }

    for partName, part in pairs(pickedParts) do
        preset[partName] = part
    end

    -- additionally, iterate over original preset and place items from it
    -- include item only if in new preset there's no mention of it (aka not false, but nil)
    for partName, defaultPart in pairs(defaultLook) do
        if preset[partName] == nil then
            preset[partName] = defaultPart
        end
    end

    PlaceObj('AppearancePreset', preset)
end

--- Saves currently loaded agency appearance presets in storage, to be used in main menu.
function AgenciesAppearanceHandler:SaveToStorage()
    if not Game then
        return
    end

    local storage = CurrentModStorageTable or {}
    local lastSavedPresets = storage["appearancePresets"] or {}
    local lastSavedPresetsList = {}
    local presets = Game.Agencies.appearancePresets or {}
    local presetsList = {}

    for preset, pickedItems in pairs(lastSavedPresets) do
        table.insert(lastSavedPresetsList, preset)
    end

    for preset, pickedItems in pairs(presets) do
        table.insert(presetsList, preset)
    end

    if table.equal_values(lastSavedPresetsList, presetsList) then
        return
    end

    storage["appearancePresets"] = presets
    WriteModPersistentStorageTable()
end

--- Applies unit presets to main menu DummyUnits if anything was saved in storage.
function AgenciesAppearanceHandler:ApplyToMainMenu()
    local storage = CurrentModStorageTable or {}
    local lastSavedPresets = storage["appearancePresets"] or {}

    if not lastSavedPresets or next(lastSavedPresets) == nil then
        return
    end

    local availablePresets = {}

    for presetId, pickedParts in pairs(lastSavedPresets) do
        local defaultLook = AppearancePresets[pickedParts.NativePreset]

        if not AppearancePresets[presetId] then
            self:PlacePreset(presetId, pickedParts, defaultLook)
        end

        table.insert(availablePresets, presetId)
    end

    local presetPosition = 0
    MapForEach("map", "DummyUnit", function(unit)
        local preset = availablePresets[presetPosition + 1]

        if preset and unit.Groups then
            unit:ApplyAppearance(preset, true)
            unit:SetEnumFlags(const.efVisible)
            presetPosition = presetPosition + 1
        else
            unit:ClearEnumFlags(const.efVisible)
        end
    end)
end
