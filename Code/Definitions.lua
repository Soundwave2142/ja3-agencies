--- ===================================================================================================================
--- @author Soundwave2142
--- ===================================================================================================================

--- @param entityClass string
--- @param skipNone boolean
--- @param filter function
--- @return table
local function GetEntityClassInherits(entityClass, skipNone, filter)
    local inherits = ClassLeafDescendantsList(entityClass, function(class)
        return not table.find(filter, class)
    end)

    if not skipNone then
        table.insert(inherits, 1, "")
    end

    return inherits
end

--- @param part string
--- @param gender string
--- @return table
function GetAgencyAttirePoolItems(part, gender)
    return GetEntityClassInherits(part .. gender)
end

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
            help = "From 0 to 100, defines a chance for this item to be rolled upon attire generation."
        },
        {
            category = "Attire",
            id = "AttireChanceToRollForHip",
            name = "Roll for Pants chance",
            editor = "number",
            default = 80,
            scale = "%",
            help = "From 0 to 100, defines a chance for this item to be rolled upon attire generation."
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
        -- Group - Attire - Head
        {
            category = "Attire",
            id = "Colors",
            name = "Colors",
            editor = "nested_list",
            default = false,
            base_class = "ColorizationPropSet",
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

--- @param unit table
--- @return boolean
function AgencyAttirePool:IsPoolAllowedForUnit(unit)
    return self:IsPoolAllowed(unit.Specialization, unit.Tier)
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
            id = "Colors",
            name = "Colors",
            editor = "nested_list",
            default = false,
            base_class = "ColorizationPropSet",
        },
        {
            category = "Part",
            id = "IgnoreFactionColorPool",
            name = "Ignore General Color Pool",
            editor = "bool",
            default = false
        },
        {
            category = "Limits",
            id = "Gender",
            name = "Gender",
            editor = "combo",
            default = "",
            items = function(self) return { "", "Male", "Female" } end,
        }
    }
}

--- @param gender string
--- @return boolean
function AgencyAttirePoolItem:IsItemAllowed(gender)
    local allowedGender = self:ResolveValue('Gender')

    return allowedGender == '' or allowedGender == gender
end

--- @param unit table
--- @return boolean
function AgencyAttirePoolItem:IsItemAllowedForUnit(unit)
    return self:IsItemAllowed(unit:GetGender())
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHat
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHat = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "HideHair",
            name = "Hide Hair",
            editor = "bool",
            default = true
        },
        {
            id = "RollForHat2",
            name = "Allow to Roll for Hat2",
            editor = "bool",
            default = true
        },
        {
            id = "Hat",
            name = "Hat",
            editor = "combo",
            default = false,
            items = function(self) return GetCharacterHatComboItems() end,
        },
        {
            id = "HatSpot",
            name = "Hat Spot",
            help = "Where to attach the hat",
            editor = "combo",
            default = "Head",
            items = function(self) return { "Head", "Origin" } end,
        },
        {
            id = "HatAttachOffsetX",
            name = "Hat Attach Offset X",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "HatAttachOffsetY",
            name = "Hat Attach Offset Y",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "HatAttachOffsetZ",
            name = "Hat Attach Offset Z",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "HatAttachOffsetAngle",
            name = "Hat Attach Offset Angle",
            editor = "number",
            default = false,
            scale = "deg",
            slider = true,
            min = -18000,
            max = 10800,
        },
    },

    EditorView = Untranslated("<Gender> - <Hat>"),
}

function AgencyAttirePoolHat:GetEditorView()
    local view = ' - <Hat>'

    local gender = self:ResolveValue('Gender')
    view = (gender ~= '' and '<Gender>' or 'No Gender') .. view
    view = view .. (self:ResolveValue('HideHair') and ' - Hides Hair' or '')
    local hatSpot = self:ResolveValue('HatSpot')
    view = view .. (hatSpot and ' - ' .. hatSpot or '')

    return Untranslated(view)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHat2
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHat2 = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "HideHair",
            name = "Hide Hair",
            editor = "bool",
            default = true
        },
        {
            id = "Hat2",
            name = "Hat2",
            editor = "combo",
            default = false,
            items = function(self) return GetCharacterHatComboItems() end,
        },
        {
            id = "Hat2Spot",
            name = "Hat2 Spot",
            help = "Where to attach the hat",
            editor = "combo",
            default = "Head",
            items = function(self) return { "Head", "Origin" } end,
        },
        {
            id = "Hat2AttachOffsetX",
            name = "Hat2 Attach Offset X",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "Hat2AttachOffsetY",
            name = "Hat2 Attach Offset Y",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "Hat2AttachOffsetZ",
            name = "Hat2 Attach Offset Z",
            editor = "number",
            default = false,
            scale = "cm",
            slider = true,
            min = -50,
            max = 50,
        },
        {
            id = "Hat2AttachOffsetAngle",
            name = "Hat2 Attach Offset Angle",
            editor = "number",
            default = false,
            scale = "deg",
            slider = true,
            min = -18000,
            max = 10800,
        },
    },

    EditorView = Untranslated("<Gender> - <Hat>"),
}

function AgencyAttirePoolHat2:GetEditorView()
    local view = ' - <Hat2>'

    local gender = self:ResolveValue('Gender')
    view = (gender ~= '' and '<Gender>' or 'No Gender') .. view
    view = view .. (self:ResolveValue('HideHair') and ' - Hides Hair' or '')
    local hatSpot = self:ResolveValue('Hat2Spot')
    view = view .. (hatSpot and ' - ' .. hatSpot or '')

    return Untranslated(view)
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHead
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHead = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "Head",
            name = "Head",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterHead', self:ResolveValue('Gender')) end,
        },
    },

    EditorView = Untranslated("<Gender> - <Head>"),
}

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolBody
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolBody = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Part",
            id = "Body",
            name = "Body",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterBody', self:ResolveValue('Gender')) end,
        },
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
            help = "Some parts have darker skin color. This will help allign them.",
            editor = "text",
            default = "",
        },
        {
            category = "Limits",
            id = "HideHair",
            name = "Hide Hair",
            editor = "bool",
            default = false
        },
        {
            category = "Limits",
            id = "HideHat",
            name = "Hide Hat",
            editor = "bool",
            default = false
        },
        {
            category = "Limits",
            id = "HideHat2",
            name = "Hide Hat2",
            editor = "bool",
            default = false
        },
    },

    EditorView = Untranslated("<Gender> - <Body>"),
}

function AgencyAttirePoolBody:GetBodyColorDeviationAsTable()
    local colorValues = self:ResolveValue("BodyColorDeviation")

    if not colorValues or colorValues == '' then
        return false
    end

    return string.split(colorValues, ',')
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolShirt
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolShirt = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "Shirt",
            name = "Shirt",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterShirts', self:ResolveValue('Gender')) end,
        },
        {
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
            help = "Some parts have darker skin color. This will help allign them.",
            editor = "text",
            default = "",
        }
    },

    EditorView = Untranslated("<Gender> - <Shirt>"),
}

function AgencyAttirePoolBody:GetBodyColorDeviationAsTable()
    local colorValues = self:ResolveValue("BodyColorDeviation")

    if not colorValues or colorValues == '' then
        return false
    end

    return string.split(colorValues, ',')
end

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolArmor
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolArmor = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "Armor",
            name = "Armor",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterArmor', self:ResolveValue('Gender')) end,
        }
    },

    EditorView = Untranslated("<Gender> - <Armor>"),
}

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolChest
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolChest = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Part",
            id = "Chest",
            name = "Chest",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterChest', self:ResolveValue('Gender')) end,
        },
        {
            category = "Part",
            id = "ChestSpot",
            name = "Chest Spot",
            help = "Where to attach the chest",
            editor = "combo",
            default = "Torso",
            items = function(self) return { "Torso", "Origin" } end,
        },
        {
            category = "Part",
            id = "ChestOffset",
            name = "Chest Offset",
            editor = "point",
            default = point30,
            scale = "cm"
        },
        {
            category = "Part",
            id = "ChestAngle",
            name = "Chest Angle",
            editor = "number",
            default = 0,
            scale = "deg"
        }
    },

    EditorView = Untranslated("<Gender> - <Chest>"),
}

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolHip
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolHip = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            category = "Part",
            id = "Hip",
            name = "Hip",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterHip', self:ResolveValue('Gender')) end,
        },
        {
            category = "Part",
            id = "HipSpot",
            name = "Hip Spot",
            help = "Where to attach the hat",
            editor = "combo",
            default = "Groin",
            items = function(self) return { "Groin", "Origin" } end,
        },
        {
            category = "Part",
            id = "HipOffset",
            name = "Chest Offset",
            editor = "point",
            default = point30,
            scale = "cm"
        },
        {
            category = "Part",
            id = "HipAngle",
            name = "Chest Angle",
            editor = "number",
            default = 0,
            scale = "deg"
        }
    },

    EditorView = Untranslated("<Gender> - <Hip>"),
}

--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- @class AgencyAttirePoolPants
--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++
DefineClass.AgencyAttirePoolPants = {
    __parents = { "AgencyAttirePoolItem" },
    __generated_by_class = "ClassDef",

    properties = {
        {
            id = "Pants",
            name = "Pants",
            editor = "combo",
            default = false,
            items = function(self) return GetAgencyAttirePoolItems('CharacterPants', self:ResolveValue('Gender')) end,
        },
    },

    EditorView = Untranslated("<Gender> - <Pants>"),
}
