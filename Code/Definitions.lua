--- ===================================================================================================================
--- Section 1 | Global function to local overrides, common functions.
--- @author Soundwave2142
--- ===================================================================================================================

local table_copy = table.copy
local table_find = table.find
local table_insert = table.insert
local PlaceObj = PlaceObj

--- @param entityClass string
--- @param skipNone boolean
--- @param filter function
--- @return table
local function GetEntityClassInherits(entityClass, skipNone, filter)
    local inherits = ClassLeafDescendantsList(entityClass, function(class)
        return not table_find(filter, class)
    end)

    if not skipNone then
        table_insert(inherits, 1, "")
    end

    return inherits
end

--- @param part string
--- @param gender string
--- @return table
function GetAgencyAttirePoolItems(part, gender)
    return GetEntityClassInherits(part .. gender)
end

--- ===================================================================================================================
--- Section 2 | Agency Presets and their related functionality, plus related in-preset pickers.
--- @author Soundwave2142
--- ===================================================================================================================

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class Agency
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.Agency = {
    __parents = {
        "MsgReactionsPreset",
        "DisplayPreset",
    },
    __generated_by_class = "PresetDef",

    properties = {
        -- category = UI
        {
            category = "UI",
            id = "LandingTemplate",
            name = "Browser Landing Template",
            editor = "preset_id",
            default = "",
            preset_class = "XTemplate",
        },
        {
            category = "UI",
            id = "BrowserTemplate",
            name = "Browser Template",
            editor = "preset_id",
            default = "",
            preset_class = "XTemplate",
        },
        {
            category = "UI",
            id = "BrowserUrl",
            name = "Browser URL",
            editor = "text",
            default = false,
        },
        {
            category = "UI",
            id = "BrowserUrlFile",
            name = "Browser URL Files",
            editor = "text",
            translate = true,
            default = false,
        },
        {
            category = "UI",
            id = "BrowserUrlName",
            name = "Browser URL Name",
            editor = "text",
            translate = true,
            default = false,
        },
        -- category = Attire
        {
            category = "Attire",
            id = "AttirePools",
            name = "Attire Pools",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttireSelector",
        },
        {
            category = "Attire",
            id = "AttireAppendDefaultHats",
            name = "Append Default/Current Hats",
            editor = "bool",
            default = true,
            help = "Allows appending default/current hats into generated preset."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForHat",
            name = "Roll for Hat chance",
            editor = "number",
            default = 80,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForHat2",
            name = "Roll for Hat 2 chance",
            editor = "number",
            default = 60,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForHead",
            name = "Roll for Head chance",
            editor = "number",
            default = 50,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForBody",
            name = "Roll for Body chance",
            editor = "number",
            default = 100,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForShirt",
            name = "Roll for Shirt chance",
            editor = "number",
            default = 100,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForArmor",
            name = "Roll for Armor chance",
            editor = "number",
            default = 60,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForChest",
            name = "Roll for Chest chance",
            editor = "number",
            default = 80,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForPants",
            name = "Roll for Pants chance",
            editor = "number",
            default = 100,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForHip",
            name = "Roll for Hip chance",
            editor = "number",
            default = 80,
            scale = "%",
            help = "Defines a chance for this item to be rolled upon attire generation."
        },
    },

    HasGroups = false,
    HasSortKey = true,
    HasParameters = true,
    GlobalMap = "Agencies",
    EditorNestedObjCategory = "Agencies",
    EditorMenubarName = "Agency",
    EditorIcon = "CommonAssets/UI/Icons/bullet list.png",
    EditorMenubar = "Editors.Lists",
    Documentation = "Creates an agency definition.",
}

DefineModItemPreset("Agency", { EditorName = "Agency", EditorSubmenu = "Agencies" })

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttireSelector
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttireSelector = {
    __parents = { "PropertyObject" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "AttirePool",
            name = "Attire Pool",
            editor = "preset_id",
            default = false,
            template = true,
            preset_class = "AgencyAttirePool",
        }
    },

    EditorView = Untranslated("<AttirePool>"),
}

--- @return (string|void)
function AgencyAttireSelector:GetError()
    if not self:ResolveValue('AttirePool') then
        return "Specify the pool"
    end
end

--- ===================================================================================================================
--- Section 3 | Agency Attire Pool preset and in-preset related items.
--- @author Soundwave2142
--- ===================================================================================================================

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePool
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePool = {
    __parents = { "Preset" },
    __generated_by_class = "PresetDef",

    properties = {
        -- Group - Limits
        {
            category = "Limits",
            id = "Specialization",
            name = "Specialization",
            editor = "combo",
            default = "",
            items = function(self) return PresetGroupCombo("MercSpecializations", "Default") end,
            help = "Will limit this attire pool to particular Merc Specialization"
        },
        {
            category = "Limits",
            id = "Tier",
            name = "Tier",
            editor = "combo",
            default = "",
            items = function(self) return PresetGroupCombo("MercTiers", "Default") end,
            help = "Will limit this attire pool to particular Merc Tier"
        },
        {
            category = "Limits",
            id = "Condition",
            name = "Condition",
            editor = "expression",
            params = "",
            default = function() return true end
        },
        -- Group - Head
        {
            category = "Attire - Head",
            id = "Hat",
            name = "Hats",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolHat",
        },
        {
            category = "Attire - Head",
            id = "Hat2",
            name = "Hats2",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolHat2",
        },
        {
            category = "Attire - Head",
            id = "Head",
            name = "Heads",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolHead",
        },
        {
            category = "Attire - Body",
            id = "Body",
            name = "Bodies",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolBody",
        },
        {
            category = "Attire - Body",
            id = "Shirt",
            name = "Shirts",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolShirt",
        },
        {
            category = "Attire - Body",
            id = "Armor",
            name = "Armors",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolArmor",
        },
        {
            category = "Attire - Body",
            id = "Chest",
            name = "Chests",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolChest",
        },
        {
            category = "Attire - Pants",
            id = "Hip",
            name = "Hips",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolHip",
        },
        {
            category = "Attire - Pants",
            id = "Pants",
            name = "Pants",
            editor = "nested_list",
            default = false,
            base_class = "AgencyAttirePoolPants",
        },
    },

    HasGroups = true,
    HasSortKey = false,
    HasParameters = true,
    GlobalMap = "AgencyAttirePools",
    EditorNestedObjCategory = "Agency",
    EditorMenubarName = "Agency Attire",
    EditorIcon = "CommonAssets/UI/Icons/bullet list.png",
    EditorMenubar = "Editors.Lists",
    Documentation = "Creates a attire definition to be used in factions for Agency game-mode.",
}

--- @param unitSpecialization string
--- @param unitTier string
--- @return boolean
function AgencyAttirePool:IsPoolAllowed(unitSpecialization, unitTier)
    local allowedSpecialization = self:ResolveValue("Specialization")
    local allowedTier = self:ResolveValue("Tier")
    local allowedCondition = self:ResolveValue("Condition")

    local allowedBySpecialization = allowedSpecialization == '' or allowedSpecialization == unitSpecialization
    local allowedByTier = allowedTier == '' or allowedTier == unitTier

    return allowedBySpecialization and allowedByTier and allowedCondition()
end

--- @param unit UnitDataCompositeDef
--- @return boolean
function AgencyAttirePool:IsPoolAllowedForUnit(unit)
    return self:IsPoolAllowed(unit:ResolveValue("Specialization"), unit:ResolveValue("Tier"))
end

DefineModItemPreset("AgencyAttirePool", { EditorName = "Agency Attire Pool", EditorSubmenu = "Agencies" })

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolItem
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolItem = {
    __parents = { "PropertyObject" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Part",
            id = "Part",
            name = "Part",
            editor = "combo",
            default = false,
            items = function(self) return self:GetItemOptions() end,
        },
        {
            category = "Part",
            id = "Colors",
            name = "Colors",
            editor = "nested_list",
            default = false,
            base_class = "ColorizationPropSet"
        },
        {
            category = "Part",
            id = "ColorDeviation",
            name = "Color Deviation",
            editor = "number",
            default = 100,
            min = -100,
            max = 100,
            default = 0,
            scale = "%",
            help = "Some parts have darker color. This will help align them.",
        },
        {
            category = "Limits",
            id = "Gender",
            name = "Gender",
            editor = "combo",
            default = "",
            items = function(self) return { "", "Male", "Female" } end
        },
        {
            category = "Limits",
            id = "Condition",
            name = "Condition",
            editor = "expression",
            params = "",
            default = function() return true end
        }
    },

    EditorView = Untranslated("<Gender> - <Part>"),
}

--- @return table
function AgencyAttirePoolItem:GetItemOptions()
    return GetAgencyAttirePoolItems("Character" .. self:GetPartName(), self:ResolveValue("Gender"))
end

--- @return table
function AgencyAttirePoolItem:GetPartName()
    assert(false, "GetPartName must be implemented for this item!")
end

--- @param gender string
--- @return boolean
function AgencyAttirePoolItem:IsItemAllowed(gender)
    local allowedGender = self:ResolveValue("Gender")
    local allowedCondition = self:ResolveValue("Condition")

    local allowedByGender = allowedGender == '' or allowedGender == gender

    return allowedByGender and allowedCondition()
end

--- @param unit table
--- @return boolean
function AgencyAttirePoolItem:IsItemAllowedForUnit(unit)
    return self:IsItemAllowed(unit:ResolveValue("gender"))
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolItem:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
end

--- @param allParts table
function AgencyAttirePoolItem:ResolveMainPart(allParts)
    local partName = self:GetPartName()

    allParts[partName] = self:ResolveValue("Part")
end

--- @param allParts table
function AgencyAttirePoolItem:ResolveColor(allParts)
    local partName = self:GetPartName()
    local allColors = self:ResolveValue("Colors")
    local defaultColor = AgenciesAppearanceOptions.DefaultItemColors
    local colorDeviation = self:ResolveValue("ColorDeviation")

    local pickedColorSet = #allColors > 0 and allColors[math.random(#allColors)] or defaultColor
    pickedColorSet = pickedColorSet:Clone()

    if colorDeviation and colorDeviation ~= 0 then
        self:ApplyColorDeviation(pickedColorSet, colorDeviation)
    end

    allParts[partName .. "Color"] = pickedColorSet
end

--- Not all pieces have equal color mask, this allows using the same color across multiple pieces,
--- but alter it's by certain percentage to achieve closer result. Used both by skin and cloth colors.
--- @param colors table
--- @param deviation number
--- @param colorProperties table
function AgencyAttirePoolItem:ApplyColorDeviation(colors, deviation, colorProperties)
    colorProperties = colorProperties or { "EditableColor1", "EditableColor2", "EditableColor3" }

    for _, colorPropertyName in ipairs(colorProperties) do
        local color = colors[colorPropertyName] or false

        if color then
            local rgba = pack_params(GetRGBA(color))

            for channel, channelValue in ipairs(rgba) do
                local modifiedChannelValue = MulDivRound(channelValue, 100 + deviation, 100)

                if modifiedChannelValue < 0 then
                    color = 0
                end

                if modifiedChannelValue > 255 then
                    color = 255
                end

                rgba[channel] = modifiedChannelValue
            end

            colors[colorPropertyName] = RGBA(unpack_params(rgba))
        end
    end
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolItemWithBodyColor
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolItemWithBodyColor = {
    __parents = { "PropertyObject" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Part",
            id = "BodyColorKey",
            name = "Body Color",
            editor = "combo",
            default = "",
            items = function(self) return { "", "EditableColor1", "EditableColor2", "EditableColor3" } end,
        },
        {
            category = "Part",
            id = "BodyColorDeviation",
            name = "Body Color Deviation",
            editor = "number",
            default = 100,
            min = -100,
            max = 100,
            default = 0,
            scale = "%",
            help = "Some parts have darker color. This will help align them.",
        }
    }
}

--- @param unitId string
--- @param allParts table
function AgencyAttirePoolItem:ResolveBodyColor(unitId, allParts)
    local partName = self:GetPartName()
    local partColor = allParts[partName .. "Color"] or false

    assert(partColor, "Color must be resolved first!")

    local bodyColorKey = self:ResolveValue("BodyColorKey")

    if bodyColorKey == nil or bodyColorKey == "" then
        return
    end

    partColor[bodyColorKey] = AgenciesAppearanceOptions:GetBodyColor(unitId)

    local bodyColorDeviation = self:ResolveValue("BodyColorDeviation")

    if bodyColorDeviation and bodyColorDeviation ~= 0 then
        self:ApplyColorDeviation(partColor, bodyColorDeviation, { bodyColorKey })
    end
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolItemWithSpot
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolItemWithSpot = {
    __parents = { "PropertyObject" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Spot",
            id = "PartSpot",
            name = "Part Spot",
            editor = "combo",
            default = "",
            items = function(self) return { "", "Head", "Torso", "Groin", "Origin" } end,
            help = "Where to attach the part.",
        },
        {
            category = "Spot",
            id = "PartOffset",
            name = "Part Offset",
            editor = "point",
            default = point30,
            scale = "cm"
        },
        {
            category = "Spot",
            id = "PartAngle",
            name = "Chest Angle",
            editor = "number",
            default = 0,
            scale = "deg"
        }
    }
}

--- @return string
function AgencyAttirePoolItemWithSpot:GetDefaultSpot()
    return "Head"
end

--- @return string
function AgencyAttirePoolItemWithSpot:GetSpotSystem()
    return "point30"
end

--- @param allParts table
function AgencyAttirePoolItemWithSpot:ResolveSpot(allParts)
    local partName = self:GetPartName()

    local spot = self:ResolveValue("PartSpot")
    local offset = self:ResolveValue("PartOffset")
    local angle = self:ResolveValue("PartAngle")

    if not spot or spot == "" then
        spot = self:GetDefaultSpot()
    end

    allParts[partName .. "Spot"] = spot

    if self:GetSpotSystem() == "point30" then
        allParts[partName .. "Offset"] = offset
        allParts[partName .. "Angle"] = angle
    else
        allParts[partName .. "AttachOffsetX"] = offset:x()
        allParts[partName .. "AttachOffsetY"] = offset:y()
        allParts[partName .. "AttachOffsetZ"] = offset:z()
        allParts[partName .. "AttachOffsetAngle"] = angle
    end
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolItemWithConflicts
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolItemWithConflicts = {
    __parents = { "PropertyObject" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Conflicts",
            id = "HideHair",
            name = "Hide Hair",
            editor = "bool",
            default = false,
            read_only = function(self) return self:GetPartName() == "Hair" end
        },
        {
            category = "Conflicts",
            id = "HideHat",
            name = "Hide Hat",
            editor = "bool",
            default = false,
            read_only = function(self) return self:GetPartName() == "Hat" end
        },
        {
            category = "Conflicts",
            id = "HideHat2",
            name = "Hide Hat2",
            editor = "bool",
            default = false,
            read_only = function(self) return self:GetPartName() == "Hat2" end
        },
    }
}

--- @param allParts table
function AgencyAttirePoolItemWithConflicts:ResolveConflicts(allParts)
    if self:ResolveValue("HideHair") then
        allParts['Hair'] = false
    end

    if self:ResolveValue("HideHat") then
        allParts['Hat'] = false
    end

    if self:ResolveValue("HideHat2") then
        allParts['Hat2'] = false
    end
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHat
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHat = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithSpot",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolHat:GetEditorView()
    local view = ' - <Part>'

    local gender = self:ResolveValue('Gender')
    view = (gender ~= '' and '<Gender>' or 'No Gender') .. view
    view = view .. (self:ResolveValue('HideHair') and ' - Hides Hair' or '')
    local hatSpot = self:ResolveValue('PartSpot')
    view = view .. (hatSpot and ' - ' .. hatSpot or '')

    return Untranslated(view)
end

--- @return table
function AgencyAttirePoolHat:GetItemOptions()
    return GetCharacterHatComboItems()
end

--- @return string
function AgencyAttirePoolHat:GetPartName()
    return "Hat"
end

--- @return string
function AgencyAttirePoolHat:GetSpotSystem()
    return "non-point30"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolHat:ResolvePickedItem(unit, allParts)
    local partName = self:GetPartName()

    if allParts[partName] == false then
        return
    end

    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveSpot(allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHat2
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHat2 = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithSpot",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolHat2:GetEditorView()
    local view = ' - <Part>'

    local gender = self:ResolveValue('Gender')
    view = (gender ~= '' and '<Gender>' or 'No Gender') .. view
    view = view .. (self:ResolveValue('HideHair') and ' - Hides Hair' or '')
    local hatSpot = self:ResolveValue('PartSpot')
    view = view .. (hatSpot and ' - ' .. hatSpot or '')

    return Untranslated(view)
end

--- @return table
function AgencyAttirePoolHat2:GetItemOptions()
    return GetCharacterHatComboItems()
end

--- @return string
function AgencyAttirePoolHat2:GetPartName()
    return "Hat2"
end

--- @return string
function AgencyAttirePoolHat2:GetSpotSystem()
    return "non-point30"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolHat2:ResolvePickedItem(unit, allParts)
    local partName = self:GetPartName()

    if allParts[partName] == false then
        return
    end

    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveSpot(allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHead
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHead = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithBodyColor",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolHead:GetPartName()
    return "Head"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolHead:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveBodyColor(unit.id, allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolBody
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolBody = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithBodyColor",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolBody:GetPartName()
    return "Body"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolBody:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveBodyColor(unit.id, allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolShirt
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolShirt = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithBodyColor",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolShirt:GetPartName()
    return "Shirt"
end

--- @return table
function AgencyAttirePoolShirt:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterShirts", self:ResolveValue("Gender"))
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolShirt:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveBodyColor(unit.id, allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolArmor
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolArmor = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithConflicts"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolArmor:GetPartName()
    return "Armor"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolArmor:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveConflicts(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolChest
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolChest = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithSpot",
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolChest:GetPartName()
    return "Chest"
end

--- @return string
function AgencyAttirePoolChest:GetDefaultSpot()
    return "Torso"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolChest:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveSpot(allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolPants
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolPants = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithBodyColor"
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolPants:GetPartName()
    return "Pants"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolPants:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveBodyColor(unit.id, allParts)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHip
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHip = {
    __parents = {
        "AgencyAttirePoolItem",
        "AgencyAttirePoolItemWithSpot",
    },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolHip:GetPartName()
    return "Hip"
end

--- @return string
function AgencyAttirePoolHip:GetDefaultSpot()
    return "Groin"
end

--- @param unit UnitDataCompositeDef
--- @param allParts table
function AgencyAttirePoolHip:ResolvePickedItem(unit, allParts)
    self:ResolveMainPart(allParts)
    self:ResolveColor(allParts)
    self:ResolveSpot(allParts)
end

--- ===================================================================================================================
--- Section 3 | Base game classes extension.
--- @author Soundwave2142
--- ===================================================================================================================

--- Expands UnitBase with AgencyAppearanceObject parent to include agency related properties and methods.
AppendClass.UnitBase = {
    __parents = { "AgencyAppearanceObject" }
}

--- Returns id a UnitBase object, checks for child class, expanded due to common use.
--- @returns string
function UnitBase:GetCurrentId()
    local id

    if IsKindOf(self, "Unit") then
        id = self.unitdatadef_id
    elseif IsKindOf(self, "UnitData") then
        id = self.class
    elseif IsKindOf(self, "UnitDataCompositeDef") then
        return self.id
    end

    assert(id, 'Cannot extract id from unit!')
    return id
end

--- Expands with properties for Agency-generated preset identification.
AppendClass.AppearancePreset = {
    properties = {
        {
            id = "IsAgencyPreset",
            name = "Generated By Agency",
            editor = "bool",
            default = false,
            no_edit = true
        },
        {
            id = "GeneratedFromTheGameId",
            name = "Generated From Game Id",
            editor = "text",
            default = false,
            no_edit = true
        },
        {
            id = "GeneratedFromAppearanceId",
            name = "Generated From Appearance Id",
            editor = "text",
            default = false,
            no_edit = true
        }
    }
}

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- Responsible for UnitBase preset generation.
--- @class AgencyAppearanceObject
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAppearanceObject = {
    __parents = { "PropertyObject", "InitDone" },

    properties = {
        { id = "AgencyAppearances", editor = "nested_list", default = false, no_edit = true }
    }
}

--- Required for saving to work.
function AgencyAppearanceObject:Init()
    self.AgencyAppearances = {}
end

--- Calculates and returns preset id of the Agency appearance for object.
--- @return string
function AgencyAppearanceObject:GetAgencyAppearancePresetId()
    AgenciesAppearanceOptions:EnsureOptionsAreLoaded()

    return table.concat({
        self:GetCurrentId(), '_Agencies_', AgenciesAppearanceOptions.OptionsLoadedForAgency
    })
end

--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @param presetId string
function AgencyAppearanceObject:EnsureAgencyAppearance(unit, defaultPresetId, presetId)
    local appearance = self.AgencyAppearances[presetId]

    if not appearance then
        self:GenerateAgencyAppearance(unit, defaultPresetId, presetId)
        -- PlaceAgencyPreset() called after in sync event.
    else
        PlaceAgencyPreset(presetId, defaultPresetId, appearance.parts or {}, appearance.partsId or false)
    end
end

--- @param unit UnitDataCompositeDef
--- @param defaultPresetId string
--- @param presetId string
function AgencyAppearanceObject:GenerateAgencyAppearance(unit, defaultPresetId, presetId)
    local pickedParts = AgenciesAppearanceOptions:GetPickedPartsFromAllOptions(unit)
    self:PrepareAgencyAppearanceDataForSync(pickedParts)

    local appearance = {
        presetParent = defaultPresetId,
        parts = pickedParts,
        partsId = random_encode64(48)
    }
    NetSyncEvent("AgenciesUnitDataAppearanceSync", unit.id, presetId, appearance)
end

--- Colors cannot be serialized by Sync functionality, this is a workaround for that.
--- It turns colors into tables and puts them in separate table.
--- @param pickedParts table
function AgencyAppearanceObject:PrepareAgencyAppearanceDataForSync(pickedParts)
    pickedParts.Colors = {}

    for key, value in pairs(pickedParts) do
        if IsKindOf(value, "ColorizationPropSet") then
            pickedParts.Colors[key] = value:GetColorsAsTable()

            DoneObject(value)
            pickedParts[key] = nil
        end
    end
end

--- Syncs appearance between all game participants, this entire process is only triggered by host.
--- @param unitId string
--- @param presetId string
--- @param appearance table
function NetSyncEvents.AgenciesUnitDataAppearanceSync(unitId, presetId, appearance)
    local unitData = gv_UnitData[unitId]

    if not unitData then
        return
    end

    unitData:ProcessAgencyAppearanceDataForSync(appearance.parts)
    unitData.AgencyAppearances[presetId] = appearance

    ObjModified(unitData)
    ObjModified(unitData.AgencyAppearances)

    if AppearancePresets[presetId] then
        DoneObject(AppearancePresets[presetId])
        AppearancePresets[presetId] = nil
    end

    PlaceAgencyPreset(presetId, appearance.presetParent, appearance.parts, appearance.partsId)

    local unit = g_Units[unitId]

    if unit then
        ReloadUnitsAppearance({ unit })
    end
end

--- Colors cannot be serialized by Sync functionality, this is a workaround for that.
--- Turns previously turned table colors back into ColorizationPropSet object.
--- @param pickedParts table
function AgencyAppearanceObject:ProcessAgencyAppearanceDataForSync(pickedParts)
    for key, value in pairs(pickedParts.Colors) do
        -- for reasons unknown to me, table cannot be processed by PlaceObj, we need flat array
        local valueFlat = {}

        for valueKey, valueValue in pairs(value) do
            valueFlat[#valueFlat + 1] = valueKey
            valueFlat[#valueFlat + 1] = valueValue
        end

        pickedParts[key] = PlaceObj('ColorizationPropSet', valueFlat)
    end

    pickedParts.Colors = nil
end

--- Removes current Agency preset from data and memory.
function AgencyAppearanceObject:ClearCurrentPreset()
    local currentPreset = self:GetAgencyAppearancePresetId()

    self.AgencyAppearances[currentPreset] = nil

    if AppearancePresets[currentPreset] then
        DoneObject(AppearancePresets[currentPreset])
        AppearancePresets[currentPreset] = nil
    end

    ObjModified(self)
    ObjModified(self.AgencyAppearances)
end
