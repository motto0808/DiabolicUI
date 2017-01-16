local Addon, Engine = ...
local Module = Engine:GetModule("UnitFrames")
local UnitFrameWidget = Module:SetWidget("Unit: Raid")

local UnitFrame = Engine:GetHandler("UnitFrame")
local StatusBar = Engine:GetHandler("StatusBar")

-- Lua API
local unpack, pairs = unpack, pairs

-- WoW API
local CreateFrame = CreateFrame

local UpdateLayers = function(self)
	if self:IsMouseOver() then
		self.BorderNormalHighlight:Show()
		self.BorderNormal:Hide()
	else
		self.BorderNormal:Show()
		self.BorderNormalHighlight:Hide()
	end
end

local Style = function(self, unit)
	local config = Module:GetStaticConfig("UnitFrames").visuals.units.raid
	local db = Module:GetConfig("UnitFrames") 

	local width, height = unpack(config.size)
	self:Size(width, height)
	local position1,position2,position3,x_pos,y_pos= unpack(config.position)
	local id = unit:match("raid(%d+)")
	local row = math.ceil(id / config.column_count)
	local col = id % config.column_count

	x_pos = x_pos + col * (width + config.row_margin)
	y_pos = y_pos - row * (height + config.col_margin)
	self:Place(position1,position2,position3,x_pos,y_pos)

	-- Artwork
	-------------------------------------------------------------------
	--[[
	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetSize(unpack(config.backdrop.texture_size))
	Backdrop:SetPoint(unpack(config.backdrop.texture_position))
	Backdrop:SetTexture(config.backdrop.texture)
	]]--
	-- border overlay frame
	local Border = CreateFrame("Frame", nil, self)
	Border:SetFrameLevel(self:GetFrameLevel() + 3)
	Border:SetAllPoints()
	
	local BorderNormal = Border:CreateTexture(nil, "BORDER")
	BorderNormal:SetSize(unpack(config.border.texture_size))
	BorderNormal:SetPoint(unpack(config.border.texture_position))
	BorderNormal:SetTexture(config.border.textures.normal)
	
	local BorderNormalHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalHighlight:SetSize(unpack(config.border.texture_size))
	BorderNormalHighlight:SetPoint(unpack(config.border.texture_position))
	BorderNormalHighlight:SetTexture(config.border.textures.highlight)
	BorderNormalHighlight:Hide()


	-- Health
	-------------------------------------------------------------------
	local Health = StatusBar:New(self)
	Health:SetSize(unpack(config.health.size))
	Health:SetPoint(unpack(config.health.position))
	Health:SetStatusBarTexture(config.health.texture)
	Health.frequent = 1/120

	-- Power
	-------------------------------------------------------------------
	local Power = StatusBar:New(self)
	Power:SetSize(unpack(config.power.size))
	Power:SetPoint(unpack(config.power.position))
	Power:SetStatusBarTexture(config.power.texture)
	Power.frequent = 1/120
	

	-- Texts
	-------------------------------------------------------------------
	local Name = Border:CreateFontString(nil, "OVERLAY")
	Name:SetFontObject(config.name.font_object)
	Name:SetPoint(unpack(config.name.position))
	Name:SetSize(unpack(config.name.size))
	Name:SetJustifyV("MIDDLE")
	Name:SetJustifyH("CENTER")
	Name:SetIndentedWordWrap(false)
	Name:SetWordWrap(true)
	Name:SetNonSpaceWrap(false)
	
	

	-- Other flag
	local FlagHolder = CreateFrame("Frame", nil, self)
	FlagHolder:SetFrameLevel(self:GetFrameLevel() + 2)
	FlagHolder:SetAllPoints()
	-- Role
	local Role = FlagHolder:CreateTexture(nil, "OVERLAY")
	Role:SetSize(unpack(config.role.texture_size))
	Role:SetPoint(unpack(config.role.texture_position))
	Role:SetTexture(config.role.texture)
	-- Leader
	local Leader = FlagHolder:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(unpack(config.leader.texture_size))
	Leader:SetPoint(unpack(config.leader.texture_position))


	self.CastBar = CastBar
	self.Health = Health
	self.Name = Name
	self.Portrait = Portrait
	self.Power = Power
	self.Threat = Threat
	self.Role = Role
	self.Leader = Leader

	self.BorderNormal = BorderNormal
	self.BorderNormalHighlight = BorderNormalHighlight
	self.PortraitBorderNormal = PortraitBorderNormal
	self.PortraitBorderNormalHighlight = PortraitBorderNormalHighlight

	self:HookScript("OnEnter", UpdateLayers)
	self:HookScript("OnLeave", UpdateLayers)
	
	--self:SetAttribute("toggleForVehicle", true)

end

UnitFrameWidget.OnEnable = function(self)
	local config = self:GetStaticConfig("UnitFrames").visuals.units.player
	local db = self:GetConfig("UnitFrames") 

	for i=1,40
	do 
		self.UnitFrame = UnitFrame:New("raid"..i, Engine:GetFrame(), Style) 
	end
	
end

UnitFrameWidget.GetFrame = function(self)
	return self.UnitFrame
end
