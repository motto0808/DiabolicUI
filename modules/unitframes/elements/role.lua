local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local RoleTexCoord = {
    TANK = { 0,0.5, 0,0.5 },
	DAMAGER = { 0,0.5,0.5,1 },
	HEALER = { 0.5,1,0,0.5 },
    NONE = {0,0.5,0.5,1}
}

local Update = function(self, event, ...)
    local unit = self.unit
	if not UnitExists(self.unit) then
		return
	end
	
	local Role = self.Role
	local role = UnitGroupRolesAssigned(unit)
	
	Role:SetTexCoord(unpack(RoleTexCoord[role]))
end

local Enable = function(self)
	local Role = self.Role
    local unit = self.unit
	if Role then
        if unit:find("party") then
            self:RegisterEvent("GROUP_ROSTER_UPDATE", Update)
        elseif unit:find("raid") then
            self:RegisterEvent("GROUP_ROSTER_UPDATE", Update)
        end
	end
end

local Disable = function(self)
	local Role = self.Role
    local unit = self.unit
    if Role then
        if unit:find("party") then
            self:UnregisterEvent("GROUP_ROSTER_UPDATE", Update)
        elseif unit:find("raid") then
            self:UnregisterEvent("GROUP_ROSTER_UPDATE", Update)
        end
	end
end

Handler:RegisterElement("Role", Enable, Disable, Update)
