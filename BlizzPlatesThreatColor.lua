local addonName, addon = ...

---存储所有活动的血条 UnitFrame
local activeNamePlates = {}
---当前玩家是否时坦克职责
local isPayerTank = false
---玩家当前目标GUID
local playerTargetGUID = nil
---玩家当前焦点GUID
local playerFocusGUID = nil

---获取玩家职责, 如果为坦克则返回true, 如果为DPS或治疗返回false.
---@return boolean
local function DetectPlayerGroupRole()
	local role = UnitGroupRolesAssigned("player")
	if role == "NONE" then
		local spec = C_SpecializationInfo.GetSpecialization()
		return spec and GetSpecializationRole(spec) == "TANK"
	end
	return role == "TANK"
end

---获取威胁状态. 当目标不存在时返回 nill
---@param unit UnitToken
---@param isTank boolean
---@return number?
local function GetThreatStatus(unit, isTank)
	local status
	if isTank then
		status = UnitThreatLeadSituation("player", unit)
	else
		status = UnitThreatSituation("player", unit)
	end

	return status
end

---获取血条颜色
---@param threatStatus number
---@param isTank boolean
---@param isFocus boolean
---@param isTartget boolean
local function GetPlateColor(threatStatus, isTank, isFocus, isTartget)
	local colors = addon.GetColors()

	if isTank then
		if threatStatus <= 1 then
			if isFocus then
				return colors.TARGET.FOCUS
			elseif isTartget then
				return colors.TARGET.TARGET
			else
				return colors.TANK.HAS_THREAT
			end
		elseif threatStatus == 2 then
			return colors.TANK.LOSING_THREAT
		else
			return colors.TANK.LOST_THREAT
		end
	else
		if threatStatus <= 1 then
			if isFocus then
				return colors.TARGET.FOCUS
			elseif isTartget then
				return colors.TARGET.TARGET
			else
				return colors.DPS.NO_THREAT
			end
		elseif threatStatus == 2 then
			return colors.DPS.GAINING_THREAT
		else
			return colors.DPS.HAS_THREAT
		end
	end
end

---检查目标是否需要进行血条染色
---@param unit UnitToken
---@return boolean
local function ShouldApplyPlateColor(unit)
	if UnitIsFriend("player", unit) then
		return false
	end
	if not UnitAffectingCombat("player") and not UnitAffectingCombat(unit) then
		return false
	end
	if UnitIsPlayer(unit) or UnitIsDeadOrGhost(unit) then
		return false
	end
	return true
end

---应用自定义血条颜色
local function ApplyPlateColorToUnitFrame(unitFrame)
	if not unitFrame or not unitFrame.unit then
		return
	end
	local unit = unitFrame.unit
	if not ShouldApplyPlateColor(unit) then
		return
	end

	local isTank = isPayerTank
	local threatStatus = GetThreatStatus(unit, isTank)
	if not threatStatus then
		return
	end
	local guid = UnitGUID(unit)
	if not guid then
		return
	end

	local isTarget = guid == playerTargetGUID
	local isFocus = guid == playerFocusGUID
	local color = GetPlateColor(threatStatus, isTank, isFocus, isTarget)

	if color and unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar then
		unitFrame.HealthBarsContainer.healthBar:SetStatusBarColor(color.r, color.g, color.b)
	end
end

---CompactUnitFrame 钩子函数
local function HookUpdateUnitFrame(frame)
	if activeNamePlates[frame] then
		ApplyPlateColorToUnitFrame(frame)
	end
end

---更新所有血条
function addon.UpdateAllNamePlates()
	for unitFrame in pairs(activeNamePlates) do
		ApplyPlateColorToUnitFrame(unitFrame)
	end
end

-- 事件帧
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE"
		or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED"
		or event == "GROUP_ROSTER_UPDATE" then
		addon.UpdateAllNamePlates()
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		if plate and plate.UnitFrame then
			local unitFrame = plate.UnitFrame
			activeNamePlates[unitFrame] = true
			ApplyPlateColorToUnitFrame(unitFrame)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local unit = ...
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		if plate and plate.UnitFrame then
			activeNamePlates[plate.UnitFrame] = nil
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		playerTargetGUID = UnitGUID("target")
	elseif event == "PLAYER_FOCUS_CHANGED" then
		playerFocusGUID = UnitGUID("focus")
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
		isPayerTank = DetectPlayerGroupRole()
		addon.UpdateAllNamePlates()
	elseif event == "ADDON_LOADED" then
		local name = ...
		if name == addonName then
			addon.InitDB()
			addon.RegisterSettings()
			hooksecurefunc("CompactUnitFrame_UpdateHealthColor", HookUpdateUnitFrame)
			hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", HookUpdateUnitFrame)
		end
	end
end)
