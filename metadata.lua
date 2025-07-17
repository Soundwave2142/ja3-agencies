return PlaceObj('ModDef', {
	'title', "Agencies",
	'id', "Agencies",
	'author', "Soundwave2142",
	'version_major', 1,
	'version', 74,
	'lua_revision', 233360,
	'saved_with_revision', 366685,
	'code', {
		"Code/Definitions.lua",
		"Code/Common.lua",
		"Code/Appearance.lua",
		"Code/UI.lua",
	},
	'default_options', {
		AgencyChoice = "A.I.M.",
	},
	'has_data', true,
	'saved', 1752756480,
	'code_hash', -5169835347639486403,
	'affected_resources', {
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "PDABrowserLandingMilitia",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "PDABrowserLandingRebels",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "PDAAIMBrowserMilitia",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "PDAAIMBrowserRebels",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
		PlaceObj('ModResourcePreset', {
			'Class', "XTemplate",
			'Id', "PDAStartButtonRebels",
			'ClassDisplayName', "UI Template (XTemplate)",
		}),
	},
	'TagGameSettings', true,
	'TagMercs', true,
	'TagOther', true,
	'TagQuest&Campaigns', true,
	'TagUI', true,
	'TagVisuals&Graphics', true,
})