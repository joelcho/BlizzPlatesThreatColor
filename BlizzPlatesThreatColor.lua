local addonName, addon = ...

-- 存储所有活动的血条 UnitFrame
local activeNamePlates = {}

-- 判断玩家是否是坦克
local function IsPlayerTank()
	local assignedRole = UnitGroupRolesAssigned("player")
	if assignedRole == "NONE" then
		local spec = C_SpecializationInfo.GetSpecialization()
		return spec and GetSpecializationRole(spec) == "TANK"
	end
	return assignedRole == "TANK"
end

-- 获取威胁状态
local function GetThreatStatus(unit)
	if not unit or not UnitExists(unit) then
		return nil
	end

	local isTank = IsPlayerTank()
	local threatStatus

	if isTank then
		threatStatus = UnitThreatLeadSituation("player", unit)
	else
		threatStatus = UnitThreatSituation("player", unit)
	end

	return threatStatus, isTank
end

-- 根据威胁状态获取颜色
local function GetColorFromThreatStatus(threatStatus, isTank)
	if not threatStatus then
		return nil
	end

	local colors = addon.GetColors()

	if isTank then
		if threatStatus <= 1 then
			return colors.TANK.HAS_THREAT
		elseif threatStatus == 2 then
			return colors.TANK.LOSING_THREAT
		else
			return colors.TANK.LOST_THREAT
		end
	else
		if threatStatus <= 1 then
			return colors.DPS.NO_THREAT
		elseif threatStatus == 2 then
			return colors.DPS.GAINING_THREAT
		else
			return colors.DPS.HAS_THREAT
		end
	end
end

-- 检查是否应该应用我们的颜色
local function ShouldApplyPlateColor(unit)
	if not unit then
		return false
	end
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

-- 应用自定义血条颜色
local function ApplyPlateColorToUnitFrame(unitFrame)
	if not unitFrame or not unitFrame.unit then
		return
	end

	local unit = unitFrame.unit
	if not ShouldApplyPlateColor(unit) then
		return
	end

	local threatStatus, isTank = GetThreatStatus(unit)
	local color = GetColorFromThreatStatus(threatStatus, isTank)

	if color and unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar then
		unitFrame.HealthBarsContainer.healthBar:SetStatusBarColor(color.r, color.g, color.b)
	end
end

local function KookCompactUnitFrame(frame)
	if activeNamePlates[frame] then
		ApplyPlateColorToUnitFrame(frame)
	end
end

-- 更新所有血条
function addon.UpdateAllNamePlates()
	for unitFrame in pairs(activeNamePlates) do
		ApplyPlateColorToUnitFrame(unitFrame)
	end
end

-- 事件帧
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
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
		or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
		addon.UpdateAllNamePlates()
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
		if namePlate and namePlate.UnitFrame then
			local unitFrame = namePlate.UnitFrame
			activeNamePlates[unitFrame] = true
			ApplyPlateColorToUnitFrame(unitFrame)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local unit = ...
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
		if namePlate and namePlate.UnitFrame then
			activeNamePlates[namePlate.UnitFrame] = nil
		end
	elseif event == "ADDON_LOADED" then
		local name = ...
		if name == addonName then
			addon.InitDB()
			addon.RegisterSettings()
			hooksecurefunc("CompactUnitFrame_UpdateHealthColor", KookCompactUnitFrame)
			hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", KookCompactUnitFrame)
		end
	end
end)
