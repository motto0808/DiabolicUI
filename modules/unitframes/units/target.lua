local Addon, Engine = ...
local Module = Engine:GetModule("UnitFrames")
local UnitFrameWidget = Module:SetWidget("Unit: Target")

local UnitFrame = Engine:GetHandler("UnitFrame")
local StatusBar = Engine:GetHandler("StatusBar")

-- Lua API
local unpack = unpack

-- WoW API
local UnitClassification = UnitClassification
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local PlayerIsRogue = select(2, UnitClass("player")) == "ROGUE" -- to check for rogue anticipation

local MAX_COMBO_POINTS = MAX_COMBO_POINTS or 5
local MAX_ANTICIPATION_POINTS = MAX_COMBO_POINTS or 5

-- Rogues get a new anticipation system in Legion, 
-- where anticipation is counted as merely 3 more combopoints.
if Engine:IsBuild("Legion") and PlayerIsRogue then
	MAX_COMBO_POINTS = 6
	MAX_ANTICIPATION_POINTS = 3
end


-- Utility Functions
--------------------------------------------------------------------------
local getBackdropName = function(haspower)
	return "Backdrop" .. (haspower and "Power" or "")
end

local getBorderName = function(isboss, haspower, ishighlight)
	return "Border" .. (isboss and "Boss" or "Normal") .. (haspower and "Power" or "") .. (ishighlight and "Highlight" or "")
end

local getThreatName = function(isboss, haspower)
	return "Threat" .. (isboss and "Boss" or "Normal") .. (haspower and "Power" or "")
end

local compare = function(a,b,c,d,e,f)
	if d == nil and e == nil and f == nil then
		return 
	end
	return (a == d) and (b == e) and (c == f)
end


-- reposition the unit classification when needed
local Classification_PostUpdate = function(self, unit)
	if not unit then
		return
	end

	local powerID, powerType = UnitPowerType(unit)
	local power = UnitPower(unit, powerID)
	local powermax = UnitPowerMax(unit, powerID)

	local haspower = not(power == 0 or powermax == 0)
	local isboss = UnitClassification(unit) == "worldboss"

	local hadpower = self.haspower
	local wasboss = self.isboss
	
	-- todo: clean this mess up
	if isboss then
		if haspower then
			if hadpower and wasboss then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.boss_double))
			self.isboss = true
			self.haspower = true
		else
			if wasboss and (not hadpower) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.boss_single))
			self.isboss = true
			self.haspower = false
		end
	else
		if haspower then
			if hadpower and (not wasboss) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.normal_double))
			self.isboss = false
			self.haspower = true
		else
			if (not hadpower) and (not wasboss) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.normal_single))
			self.isboss = false
			self.haspower = false
		end
	end
end

local SetLayer = function(self, isboss, haspower, ishighlight)
	local cache = self.layers
	local border_name = getBorderName(isboss, haspower, ishighlight)
	local backdrop_name = getBackdropName(haspower)
	local threat_name = getThreatName(isboss, haspower)
	
	-- display the correct border texture
	cache.border[border_name]:Show()
	for id,layer in pairs(cache.border) do
		if id ~= border_name then
			layer:Hide()
		end
	end
	
	-- display the correct backdrop texture
	cache.backdrop[backdrop_name]:Show()
	for id,layer in pairs(cache.backdrop) do
		if id ~= backdrop_name then
			layer:Hide()
		end
	end
	
	-- display the correct threat texture
	--  *This does not affect the visibility of the main threat object, 
	--   it only handles the visibility of the separate sub-textures.
	cache.threat[threat_name]:Show()
	for id,layer in pairs(cache.threat) do
		if id ~= threat_name then
			layer:Hide()
		end
	end
	
	-- Update combo- and anticipation point position
	local ComboPoints = self.ComboPoints
	if isboss then
		if haspower then
			ComboPoints:SetScale((2/3))
			ComboPoints:SetPoint("CENTER", (ComboPoints:GetWidth()/2 + 14)/(2/3), -26/(2/3)) -- perfect with power
		else
			ComboPoints:SetScale(.75)
			ComboPoints:SetPoint("CENTER", (ComboPoints:GetWidth()/2 + 20)/.75, -2/.75) -- perfect without
		end
	else 
		ComboPoints:SetScale(.75)
		--ComboPoints:SetScale(1)
		if haspower then
			ComboPoints:SetPoint("CENTER", 0, -24/.75) -- perfect with power
		else
			ComboPoints:SetPoint("CENTER", 0, -6/.75) -- perfect without
		end
		if ComboPoints.Anticipation then
			ComboPoints.Anticipation:ClearAllPoints()
			ComboPoints.Anticipation:SetPoint("TOP", ComboPoints, "BOTTOM", 0, 0) 
		end
	end
	
	
end

local UpdateLayers = function(self)
	local unit = self.unit
	if not unit then
		return
	end

	local powerID, powerType = UnitPowerType(unit)
	local power = UnitPower(unit, powerID)
	local powermax = UnitPowerMax(unit, powerID)

	local haspower = not(power == 0 or powermax == 0)
	local isboss = UnitClassification(unit) == "worldboss"
	local ishighlight = self:IsMouseOver()
	
	if compare(isboss, haspower, ishighlight, self.isboss, self.haspower, self.ishighlight) then
		return -- avoid unneeded graphic updates
	else
		if not haspower and self.haspower == true then
			-- Forcefully empty the bar fast to avoid 
			-- it being visible after the border has been hidden.
			self.Power:Clear() 
		end
	
		self.isboss = isboss
		self.haspower = haspower
		self.ishighlight = ishighlight

		SetLayer(self, isboss, haspower, ishighlight)
	end
	
end

-- This one will only be called in Legion, and only for Rogues
local UpdateComboPoints = function(self)
	local vehicle = UnitHasVehicleUI("player")
	local combo_unit = vehicle and "vehicle" or "player"
	local cp = UnitPower(combo_unit, SPELL_POWER_COMBO_POINTS)
	local cp_max = UnitPowerMax(combo_unit, SPELL_POWER_COMBO_POINTS)
	if cp_max == 8 then
		cp_max = 5
	end
	self:SetSize(self.point_width*cp_max + self.point_padding*(cp_max-1), self.point_height)
end

local Update = function(self, event, ...)
	UpdateLayers(self)
	Classification_PostUpdate(self.Classification, self.unit)
end

local Style = function(self, unit)
	local config = Module:GetStaticConfig("UnitFrames").visuals.units.target
	local db = Module:GetConfig("UnitFrames") 
	
	self:Size(unpack(config.size))
	self:Place(unpack(config.position))


	-- Artwork
	-------------------------------------------------------------------

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetSize(unpack(config.textures.size))
	Backdrop:SetPoint(unpack(config.textures.position))
	Backdrop:SetTexture(config.textures.layers.backdrop.single)

	local BackdropPower = self:CreateTexture(nil, "BACKGROUND")
	BackdropPower:SetSize(unpack(config.textures.size))
	BackdropPower:SetPoint(unpack(config.textures.position))
	BackdropPower:SetTexture(config.textures.layers.backdrop.double)
	
	local Border = CreateFrame("Frame", nil, self)
	Border:SetFrameLevel(self:GetFrameLevel() + 3)
	Border:SetAllPoints()
	
	local BorderNormal = Border:CreateTexture(nil, "BORDER")
	BorderNormal:SetSize(unpack(config.textures.size))
	BorderNormal:SetPoint(unpack(config.textures.position))
	BorderNormal:SetTexture(config.textures.layers.border.standard_single.normal)
	
	local BorderNormalHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalHighlight:SetSize(unpack(config.textures.size))
	BorderNormalHighlight:SetPoint(unpack(config.textures.position))
	BorderNormalHighlight:SetTexture(config.textures.layers.border.standard_single.highlight)

	local BorderNormalPower = Border:CreateTexture(nil, "BORDER")
	BorderNormalPower:SetSize(unpack(config.textures.size))
	BorderNormalPower:SetPoint(unpack(config.textures.position))
	BorderNormalPower:SetTexture(config.textures.layers.border.standard_double.normal)

	local BorderNormalPowerHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalPowerHighlight:SetSize(unpack(config.textures.size))
	BorderNormalPowerHighlight:SetPoint(unpack(config.textures.position))
	BorderNormalPowerHighlight:SetTexture(config.textures.layers.border.standard_double.highlight)

	local BorderBoss = Border:CreateTexture(nil, "BORDER")
	BorderBoss:SetSize(unpack(config.textures.size))
	BorderBoss:SetPoint(unpack(config.textures.position))
	BorderBoss:SetTexture(config.textures.layers.border.boss_single.normal)

	local BorderBossHighlight = Border:CreateTexture(nil, "BORDER")
	BorderBossHighlight:SetSize(unpack(config.textures.size))
	BorderBossHighlight:SetPoint(unpack(config.textures.position))
	BorderBossHighlight:SetTexture(config.textures.layers.border.boss_single.highlight)

	local BorderBossPower = Border:CreateTexture(nil, "BORDER")
	BorderBossPower:SetSize(unpack(config.textures.size))
	BorderBossPower:SetPoint(unpack(config.textures.position))
	BorderBossPower:SetTexture(config.textures.layers.border.boss_double.normal)

	local BorderBossPowerHighlight = Border:CreateTexture(nil, "BORDER")
	BorderBossPowerHighlight:SetSize(unpack(config.textures.size))
	BorderBossPowerHighlight:SetPoint(unpack(config.textures.position))
	BorderBossPowerHighlight:SetTexture(config.textures.layers.border.boss_double.highlight)


	-- Health
	-------------------------------------------------------------------
	local Health = StatusBar:New(self)
	Health:SetSize(unpack(config.health.size))
	Health:SetPoint(unpack(config.health.position))
	Health:SetStatusBarTexture(config.health.texture)
	Health.frequent = 1/120
	
	local HealthValueHolder = CreateFrame("Frame", nil, Health:GetScaffold())
	HealthValueHolder:SetAllPoints()
	HealthValueHolder:SetFrameLevel(Border:GetFrameLevel() + 1)
	
	Health.Value = HealthValueHolder:CreateFontString(nil, "OVERLAY")
	Health.Value:SetFontObject(config.texts.health.font_object)
	Health.Value:SetPoint(unpack(config.texts.health.position))
	Health.Value:SetTextColor(unpack(config.texts.health.color))
	Health.Value.showPercent = false
	Health.Value.showDeficit = false
	Health.Value.showMaximum = false

	Health.PostUpdate = function(self)
		local min, max = self:GetMinMaxValues()
		local value = self:GetValue()
		if UnitAffectingCombat("player") then
			self.Value:Show()
		else
			self.Value:Show()
		end
	end
	
	
	-- Power
	-------------------------------------------------------------------
	local Power = StatusBar:New(self)
	Power:SetSize(unpack(config.power.size))
	Power:SetPoint(unpack(config.power.position))
	Power:SetStatusBarTexture(config.power.texture)
	Power.frequent = 1/120
	

	-- ComboPoints
	-- *TODO: Add the settings to the config file. Can't be arsed now. 
	-------------------------------------------------------------------
	local ComboPoints = CreateFrame("Frame", nil, Border)
	local cw, ch, cp = 28, 10, 2
	local combo_r = .6
	local combo_g = .15 
	local combo_b = .025
	local combo_r_last = .9686274509803922 
	local combo_g_last = .674509803921568 
	local combo_b_last = .1450980392156863
	
	ComboPoints.point_width = cw
	ComboPoints.point_height = ch
	ComboPoints.point_padding = cp
	
	ComboPoints:SetSize(cw*MAX_COMBO_POINTS + cp*(MAX_COMBO_POINTS-1), ch)
	ComboPoints:SetPoint("CENTER", 0, -22) -- perfect with power
	--ComboPoints:SetPoint("CENTER", 0, -2) -- perfect without
	
	for i = 1, MAX_COMBO_POINTS do
		local ComboPoint = CreateFrame("Frame", nil, ComboPoints)
		ComboPoint:Hide()
		ComboPoint:SetSize(cw, ch)
		ComboPoint:SetPoint("BOTTOMLEFT", (cw + cp)*(i-1), 0)
		ComboPoint:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			tile = false,
			edgeSize = 8,
			insets = { 
				left = 2.5,
				right = 1.5,
				top = 2.5,
				bottom = 1.5
			}
		})
		local r, g, b
		if i == 1 then
			r, g, b = combo_r, combo_g, combo_b
		elseif i == MAX_COMBO_POINTS then
			r, g, b = combo_r_last, combo_g_last, combo_b_last
		else
			-- Grrrrraaaaaadient!
			r = combo_r + ((combo_r_last-combo_r)/(MAX_COMBO_POINTS - 2))*(i - 1)
			g = combo_g + ((combo_g_last-combo_g)/(MAX_COMBO_POINTS - 2))*(i - 1)
			b = combo_b + ((combo_b_last-combo_b)/(MAX_COMBO_POINTS - 2))*(i - 1)
		end
		ComboPoint:SetBackdropColor(r, g, b, 1)
		ComboPoint:SetBackdropBorderColor(0, 0, 0, 1)
		
		ComboPoints[i] = ComboPoint
	end
	self.ComboPoints = ComboPoints
	
	
	-- Rogue Anticipation
	if PlayerIsRogue and Engine:IsBuild("5.0.4") then
		local Anticipation = CreateFrame("Frame", nil, ComboPoints)
		local cw, ch, cp = 24, 8, 2
		local anticipation_r = 0.4
		local anticipation_g = 0.05
		local anticipation_b = 0.15
		
		Anticipation:SetSize(cw*MAX_ANTICIPATION_POINTS + cp*(MAX_ANTICIPATION_POINTS-1), ch)
		Anticipation:SetPoint("TOP", ComboPoints, "BOTTOM", 0, 0) 
		
		for i = 1, MAX_ANTICIPATION_POINTS do
			local AnticipationPoint = CreateFrame("Frame", nil, Anticipation)
			AnticipationPoint:Hide()
			AnticipationPoint:SetSize(cw, ch)
			AnticipationPoint:SetPoint("BOTTOMLEFT", (cw + cp)*(i-1), 0)
			AnticipationPoint:SetBackdrop({
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
				tile = false,
				edgeSize = 8,
				insets = { 
					left = 2.5,
					right = 1.5,
					top = 2.5,
					bottom = 1.5
				}
			})
			AnticipationPoint:SetBackdropColor(anticipation_r, anticipation_g, anticipation_b, 1)
			AnticipationPoint:SetBackdropBorderColor(0, 0, 0, 1)
			
			Anticipation[i] = AnticipationPoint
		end
		
		ComboPoints.Anticipation = Anticipation
	end
	
	if Engine:IsBuild("Legion") then
		ComboPoints.PostUpdate = UpdateComboPoints
	end
	


	-- CastBar
	-------------------------------------------------------------------
	local CastBar = StatusBar:New(Health:GetScaffold())
	CastBar:Hide()
	CastBar:SetAllPoints()
	CastBar.DefaultColor = {1, 1, 1, .25}
	CastBar.SwitchColor = {1, 0, 0, .5}
	CastBar:SetSize(Health:GetSize())
	--CastBar:SetSize(unpack(config.castbar.size))
	--CastBar:SetSparkTexture(config.castbar.spark.texture)
	--CastBar:SetSparkSize(unpack(config.castbar.spark.size))
	--CastBar:SetSparkFlash(unpack(config.castbar.spark.flash))
	CastBar:DisableSmoothing(true)
    
	local CasetbarNameHolder = CreateFrame("Frame", nil, CastBar:GetScaffold())
	CasetbarNameHolder:SetAllPoints()
	CasetbarNameHolder:SetFrameLevel(Border:GetFrameLevel() + 1)
    
	CastBar.Name = CasetbarNameHolder:CreateFontString(nil, "OVERLAY")
	CastBar.Name:SetFontObject(config.texts.castbar.font_object)
	CastBar.Name:SetPoint(unpack(config.texts.castbar.position))
	CastBar.Name:SetTextColor(unpack(config.texts.castbar.color))
	

	-- Threat
	-------------------------------------------------------------------
	local Threat = CreateFrame("Frame", nil, self)
	Threat:SetFrameLevel(self:GetFrameLevel())
	Threat:SetAllPoints()
	Threat:Hide()
	
	local ThreatNormal = Threat:CreateTexture(nil, "BACKGROUND")
	ThreatNormal:Hide()
	ThreatNormal:SetSize(unpack(config.textures.size))
	ThreatNormal:SetPoint(unpack(config.textures.position))
	ThreatNormal:SetTexture(config.textures.layers.border.standard_single.threat)
	
	local ThreatNormalPower = Threat:CreateTexture(nil, "BACKGROUND")
	ThreatNormalPower:Hide()
	ThreatNormalPower:SetSize(unpack(config.textures.size))
	ThreatNormalPower:SetPoint(unpack(config.textures.position))
	ThreatNormalPower:SetTexture(config.textures.layers.border.standard_double.threat)

	local ThreatBoss = Threat:CreateTexture(nil, "BACKGROUND")
	ThreatBoss:Hide()
	ThreatBoss:SetSize(unpack(config.textures.size))
	ThreatBoss:SetPoint(unpack(config.textures.position))
	ThreatBoss:SetTexture(config.textures.layers.border.boss_single.threat)

	local ThreatBossPower = Threat:CreateTexture(nil, "BACKGROUND")
	ThreatBossPower:Hide()
	ThreatBossPower:SetSize(unpack(config.textures.size))
	ThreatBossPower:SetPoint(unpack(config.textures.position))
	ThreatBossPower:SetTexture(config.textures.layers.border.boss_double.threat)


	-- Texts
	-------------------------------------------------------------------
	local Name = Border:CreateFontString(nil, "OVERLAY")
	Name:SetFontObject(config.name.font_object)
	Name:SetPoint(unpack(config.name.position))
	Name:SetSize(unpack(config.name.size))
	Name:SetJustifyV("TOP")
	Name:SetJustifyH("CENTER")
	Name:SetIndentedWordWrap(false)
	Name:SetWordWrap(false)
	Name:SetNonSpaceWrap(false)
	Name.colorBoss = true
	
	local Classification = Border:CreateFontString(nil, "OVERLAY")
	Classification:SetFontObject(config.classification.font_object)
	Classification:SetPoint(unpack(config.classification.position.normal_single))
	Classification.position = config.classification.position -- should contain all 4 positions

	-- Auras
	if config.auras.enable then
		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetPoint(unpack(config.auras.position))
		local width = config.auras.col * config.auras.icon_size + (config.auras.col - 1) * config.auras.spacing
		local height = config.auras.row * config.auras.icon_size + (config.auras.row - 1) * config.auras.spacing
		Auras:SetSize(width, height)
		Auras.size = config.auras.icon_size
		Auras.spacing = config.auras.spacing
		Auras['growth-y'] = 'DOWN'
		Auras.onlyShowPlayer = true
		self.Auras = Auras
	end

	-- Put everything into our layer cache
	---------------------------------------------------------------------
	self.layers = { backdrop = {}, border = {}, threat = {} } -- cache for faster toggling

	self.layers.backdrop.Backdrop = Backdrop
	self.layers.backdrop.BackdropPower = BackdropPower

	self.layers.border.BorderNormal = BorderNormal
	self.layers.border.BorderNormalHighlight = BorderNormalHighlight
	self.layers.border.BorderNormalPower = BorderNormalPower
	self.layers.border.BorderNormalPowerHighlight = BorderNormalPowerHighlight
	self.layers.border.BorderBoss = BorderBoss
	self.layers.border.BorderBossHighlight = BorderBossHighlight
	self.layers.border.BorderBossPower = BorderBossPower
	self.layers.border.BorderBossPowerHighlight = BorderBossPowerHighlight

	self.layers.threat.ThreatNormal = ThreatNormal
	self.layers.threat.ThreatNormalPower = ThreatNormalPower
	self.layers.threat.ThreatBoss = ThreatBoss
	self.layers.threat.ThreatBossPower = ThreatBossPower

	self.CastBar = CastBar
	self.Classification = Classification
	self.Classification.PostUpdate = Classification_PostUpdate
	self.Health = Health
	self.Name = Name
	self.Power = Power
	self.Power.PostUpdate = function() Update(self) end
	self.Threat = Threat
	self.Threat.SetVertexColor = function(_, ...) 
		for i,v in pairs(self.layers.threat) do
			v:SetVertexColor(...)
		end
	end

	self:HookScript("OnEnter", UpdateLayers)
	self:HookScript("OnLeave", UpdateLayers)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
	self:RegisterEvent("UNIT_NAME_UPDATE", Update)

end

UnitFrameWidget.OnEnable = function(self)
	self.UnitFrame = UnitFrame:New("target", Engine:GetFrame(), Style)
end

UnitFrameWidget.GetFrame = function(self)
	return self.UnitFrame
end
