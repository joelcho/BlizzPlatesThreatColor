local addonName, addon = ...

addon.SettingsLib = LibStub("LibEQOLSettingsMode-1.0")

-- 默认颜色配置
addon.DEFAULT_COLORS = {
	-- 坦克颜色
	TANK = {
		HAS_THREAT    = { r = 0.0, g = 1.0, b = 0.0 }, -- 绿色
		LOSING_THREAT = { r = 1.0, g = 1.0, b = 0.0 }, -- 黄色
		LOST_THREAT   = { r = 1.0, g = 0.0, b = 0.0 }, -- 红色
	},
	-- DPS/治疗颜色
	DPS = {
		NO_THREAT      = { r = 0.0, g = 1.0, b = 0.0 }, -- 绿色
		GAINING_THREAT = { r = 1.0, g = 1.0, b = 0.0 }, -- 黄色
		HAS_THREAT     = { r = 1.0, g = 0.0, b = 0.0 }, -- 红色
	}
}

-- 配置数据库
addon.InitDB = function()
	if not BlizzPlatesThreatColorDB then
		BlizzPlatesThreatColorDB = {}
	end
	if not BlizzPlatesThreatColorDB.colors then
		BlizzPlatesThreatColorDB.colors = CopyTable(addon.DEFAULT_COLORS)
	end
end

-- 获取当前使用的颜色
addon.GetColors =  function()
	return BlizzPlatesThreatColorDB and BlizzPlatesThreatColorDB.colors or addon.DEFAULT_COLORS
end

-- 注册系统配置
addon.RegisterSettings = function()
	local TANK_COLOR_CONFIGS = {
		{ key = "TANK_HAS_THREAT", label = "有仇恨", desc = "坦克当前有仇恨时的颜色" },
		{ key = "TANK_LOSING_THREAT", label = "即将丢失", desc = "坦克即将丢失仇恨时的颜色" },
		{ key = "TANK_LOST_THREAT", label = "失去仇恨", desc = "坦克完全失去仇恨时的颜色" },
	}

	local DPS_COLOR_CONFIGS = {
		{ key = "DPS_NO_THREAT", label = "无仇恨", desc = "DPS/治疗没有仇恨时的颜色" },
		{ key = "DPS_GAINING_THREAT", label = "即将获得", desc = "DPS/治疗即将获得仇恨时的颜色" },
		{ key = "DPS_HAS_THREAT", label = "获得仇恨", desc = "DPS/治疗获得仇恨时的颜色" },
	}

	local SettingsLib = addon.SettingsLib
	SettingsLib:SetVariablePrefix("BlizzPlatesThreatColor_")

	local category = SettingsLib:CreateRootCategory(addonName)

	-- 坦克颜色部分
	local tankSection = SettingsLib:CreateExpandableSection(category, {
		name = "|cff00ff00坦克颜色|r",
		expanded = true,
		colorizeTitle = true,
	})

	SettingsLib:CreateColorOverrides(category, {
		entries = TANK_COLOR_CONFIGS,
		hasOpacity = false,
		getColor = function(key)
			local subKey = key:match("^TANK_(.*)$")
			local color = BlizzPlatesThreatColorDB.colors.TANK[subKey]
			return color.r, color.g, color.b
		end,
		setColor = function(key, r, g, b)
			local subKey = key:match("^TANK_(.*)$")
			BlizzPlatesThreatColorDB.colors.TANK[subKey].r = r
			BlizzPlatesThreatColorDB.colors.TANK[subKey].g = g
			BlizzPlatesThreatColorDB.colors.TANK[subKey].b = b
			addon.UpdateAllNamePlates()
		end,
		getDefaultColor = function(key)
			local subKey = key:match("^TANK_(.*)$")
			local color = addon.DEFAULT_COLORS.TANK[subKey]
			return color.r, color.g, color.b
		end,
		colorizeLabel = true,
		parentSection = tankSection,
	})

	-- DPS/治疗颜色部分
	local dpsSection = SettingsLib:CreateExpandableSection(category, {
		name = "|cffff6666DPS/治疗颜色|r",
		expanded = true,
		colorizeTitle = true,
	})

	SettingsLib:CreateColorOverrides(category, {
		entries = DPS_COLOR_CONFIGS,
		hasOpacity = false,
		getColor = function(key)
			local subKey = key:match("^DPS_(.*)$")
			local color = BlizzPlatesThreatColorDB.colors.DPS[subKey]
			return color.r, color.g, color.b
		end,
		setColor = function(key, r, g, b)
			local subKey = key:match("^DPS_(.*)$")
			BlizzPlatesThreatColorDB.colors.DPS[subKey].r = r
			BlizzPlatesThreatColorDB.colors.DPS[subKey].g = g
			BlizzPlatesThreatColorDB.colors.DPS[subKey].b = b
			addon.UpdateAllNamePlates()
		end,
		getDefaultColor = function(key)
			local subKey = key:match("^DPS_(.*)$")
			local color = addon.DEFAULT_COLORS.DPS[subKey]
			return color.r, color.g, color.b
		end,
		colorizeLabel = true,
		parentSection = dpsSection,
	})
end
