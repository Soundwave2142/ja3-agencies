--- ===================================================================================================================
--- Section 1 | Global function to local overrides, common functions.
--- @author Soundwave2142
--- ===================================================================================================================

local table_find = table.find
local table_insert = table.insert

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
--- Section 2 | Agency Preset and related in-preset pickers.
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
            id = "BrowserLandingTemplate",
            name = "Browser Landing Template",
            editor = "preset_id",
            default = "",
            preset_class = "XTemplate",
        },
        {
            category = "UI",
            id = "LandingTemplate",
            name = "Browser Template",
            editor = "preset_id",
            default = "",
            preset_class = "XTemplate",
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
    local allowedSpecialization = self:ResolveValue('Specialization')
    local allowedTier = self:ResolveValue('Tier')

    local allowedBySpecialization = allowedSpecialization == '' or allowedSpecialization == unitSpecialization
    local allowedByTier = allowedTier == '' or allowedTier == unitTier

    return allowedBySpecialization and allowedByTier
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
        }
    },

    EditorView = Untranslated("<Gender> - <Part>"),
}

--- @param allParts table
--- @param color
function AgencyAttirePoolItem:GetItemOptions()
    assert(false, "GetItemOptions must be implemented for this item!")
end

function AgencyAttirePoolItem:GetPartName()
    assert(false, "GetPartName must be implemented for this item!")
end

--- @param gender string
--- @return boolean
function AgencyAttirePoolItem:IsItemAllowed(gender)
    local allowedGender = self:ResolveValue("Gender")

    return allowedGender == '' or allowedGender == gender
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

function AgencyAttirePoolItem:ApplyColorDeviation(colors, deviation, colorProperties)
    colorProperties = colorProperties or { "EditableColor1", "EditableColor2", "EditableColor3" }

    for _, colorPropertyName in ipairs(colorProperties) do
        local color = colors[colorPropertyName] or false

        if color then
            local rgba = pack_params(GetRGBA(color))

            for channel, channelValue in ipairs(rgba) do
                rgba[channel] = MulDivRound(channelValue, 100 + deviation, 100)
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
    __parents = { "AgencyAttirePoolHat" },
    __generated_by_class = "ClassDef",
}

--- @return string
function AgencyAttirePoolHat2:GetPartName()
    return "Hat2"
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

--- @return table
function AgencyAttirePoolHead:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterHead", self:ResolveValue("Gender"))
end

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

--- @return table
function AgencyAttirePoolBody:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterBody", self:ResolveValue("Gender"))
end

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
        "AgencyAttirePoolBody"
    },
    __generated_by_class = "ClassDef",
}

--- @return table
function AgencyAttirePoolShirt:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterShirt", self:ResolveValue("Gender"))
end

function AgencyAttirePoolShirt:GetPartName()
    return "Shirt"
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

--- @return table
function AgencyAttirePoolArmor:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterArmor", self:ResolveValue("Gender"))
end

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

--- @return table
function AgencyAttirePoolChest:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterChest", self:ResolveValue("Gender"))
end

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

--- @return table
function AgencyAttirePoolPants:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterPants", self:ResolveValue("Gender"))
end

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

--- @return table
function AgencyAttirePoolHip:GetItemOptions()
    return GetAgencyAttirePoolItems("CharacterHip", self:ResolveValue("Gender"))
end

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
