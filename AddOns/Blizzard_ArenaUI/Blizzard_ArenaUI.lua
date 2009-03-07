MAX_ARENA_ENEMIES = 5;

function ArenaEnemyFrames_OnLoad(self)
	self:RegisterEvent("CVAR_UPDATE");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	if ( GetCVarBool("showArenaEnemyFrames") ) then
		ArenaEnemyFrames_Enable(self);
	else
		ArenaEnemyFrames_Disable(self);
	end
	local showCastbars = GetCVarBool("showArenaEnemyCastbar");
	local castFrame;
	for i = 1, MAX_ARENA_ENEMIES do
		castFrame = _G["ArenaEnemyFrame"..i.."CastingBar"];
		castFrame.showCastbar = showCastbars;
		CastingBarFrame_UpdateIsShown(castFrame);
	end
	
	UpdateArenaEnemyBackground(GetCVarBool("showPartyBackground"));
	ArenaEnemyBackground_SetOpacity(tonumber(GetCVar("partyBackgroundOpacity")));
end

function ArenaEnemyFrames_OnEvent(self, event, ...)
	local arg1, arg2 = ...;
	if ( (event == "CVAR_UPDATE") and (arg1 == "SHOW_ARENA_ENEMY_FRAMES_TEXT") ) then
		if ( arg2 == "1" ) then
			ArenaEnemyFrames_Enable(self);
		else
			ArenaEnemyFrames_Disable(self);
		end
	elseif ( event == "VARIABLES_LOADED" ) then
		if ( GetCVarBool("showArenaEnemyFrames") ) then
			ArenaEnemyFrames_Enable(self);
		else
			ArenaEnemyFrames_Disable(self);
		end
		local showCastbars = GetCVarBool("showArenaEnemyCastbar");
		local castFrame;
		for i = 1, MAX_ARENA_ENEMIES do
			castFrame = _G["ArenaEnemyFrame"..i.."CastingBar"];
			castFrame.showCastbar = showCastbars;
			CastingBarFrame_UpdateIsShown(castFrame);
		end
		for i=1, MAX_ARENA_ENEMIES do
			ArenaEnemyFrame_UpdatePet(_G["ArenaEnemyFrame"..i], i, true);
		end
		UpdateArenaEnemyBackground(GetCVarBool("showPartyBackground"));
		ArenaEnemyBackground_SetOpacity(tonumber(GetCVar("partyBackgroundOpacity")));
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		ArenaEnemyFrames_UpdateVisible();
	end
end

function ArenaEnemyFrames_OnShow(self)
	--Set it up to hide stuff we don't want shown in an arena.
	ArenaEnemyFrames_UpdateWatchFrame();
	
	DurabilityFrame_SetAlerts();
	UIParent_ManageFramePositions();
end

function ArenaEnemyFrames_UpdateWatchFrame()
	local ArenaEnemyFrames = ArenaEnemyFrames;
	if ( not WatchFrame:IsUserPlaced() ) then
		if ( ArenaEnemyFrames:IsShown() ) then
			if ( WatchFrame_RemoveObjectiveHandler(WatchFrame_DisplayTrackedQuests) ) then
				ArenaEnemyFrames.hidWatchedQuests = true;
			end
		else
			if ( ArenaEnemyFrames.hidWatchedQuests ) then
				WatchFrame_AddObjectiveHandler(WatchFrame_DisplayTrackedQuests);
				ArenaEnemyFrames.hidWatchedQuests = false;
			end
		end
		WatchFrame_ClearDisplay();
		WatchFrame_Update();
	elseif ( ArenaEnemyFrames.hidWatchedQuests ) then
		WatchFrame_AddObjectiveHandler(WatchFrame_DisplayTrackedQuests);
		ArenaEnemyFrames.hidWatchedQuests = false;
		WatchFrame_ClearDisplay();
		WatchFrame_Update();
	end
end

function ArenaEnemyFrames_OnHide(self)
	--Make the stuff that needs to be shown shown again.
	ArenaEnemyFrames_UpdateWatchFrame();
	
	DurabilityFrame_SetAlerts();
	UIParent_ManageFramePositions();
end

function ArenaEnemyFrames_Enable(self)
	self.show = true;
	ArenaEnemyFrames_UpdateVisible();
end

function ArenaEnemyFrames_Disable(self)
	self.show = false;
	ArenaEnemyFrames_UpdateVisible();
end

function ArenaEnemyFrames_UpdateVisible()
	local _, instanceType = IsInInstance();
	if ( ArenaEnemyFrames.show and (instanceType == "arena")) then
		ArenaEnemyFrames:Show();
	else
		ArenaEnemyFrames:Hide();
	end
end

function ArenaEnemyFrame_OnLoad(self)
	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;
	
	self.classPortrait = _G[self:GetName().."ClassPortrait"];
	ArenaEnemyFrame_UpdatePlayer(self, true);
	self:RegisterEvent("UNIT_PET");
	self:RegisterEvent("ARENA_OPPONENT_UPDATE");
	self:RegisterEvent("UNIT_NAME_UPDATE");
	
	UIDropDownMenu_Initialize(self.DropDown, ArenaEnemyDropDown_Initialize, "MENU");
	
	local showmenu = function()
		ToggleDropDownMenu(1, nil, getglobal("ArenaEnemyFrame"..self:GetID().."DropDown"), self:GetName(), 47, 15);
	end
	SecureUnitButton_OnLoad(self, "arena"..self:GetID(), showmenu);
end

function ArenaEnemyFrame_UpdatePlayer(self, useCVars)--At some points, we need to use CVars instead of UVars even though UVars are faster.
	local id = self:GetID();
	if ( UnitExists(self.unit) ) then
		self:Show();
		UnitFrame_Update(self);
		
		local _, class = UnitClass(self.unit);
		self.classPortrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]));
	end

	ArenaEnemyFrames_UpdateVisible();
end

function ArenaEnemyFrame_Lock(self)
	self.healthbar:SetStatusBarColor(0.5, 0.5, 0.5);
	self.healthbar.lockValues = true;
	self.manabar:SetStatusBarColor(0.5, 0.5, 0.5);
	self.manabar.lockValue = true;
	self.hideStatusOnTooltip = true;
end

function ArenaEnemyFrame_Unlock(self)
	self.healthbar.lockValues = false;
	self.manabar.lockValues = false;
	self.hideStatusOnTooltip = false;
end

function ArenaEnemyFrame_OnEvent(self, event, arg1, arg2)
	if ( event == "ARENA_OPPONENT_UPDATE" and arg1 == self.unit ) then
		if ( arg2 == "seen" or arg2 == "destroyed") then
			ArenaEnemyFrame_Unlock(self);
			ArenaEnemyFrame_UpdatePlayer(self);
			UpdateArenaEnemyBackground();
			UIParent_ManageFramePositions();
		elseif ( arg2 == "unseen" ) then
			ArenaEnemyFrame_Lock(self);
		elseif ( arg2 == "cleared" ) then
			ArenaEnemyFrame_Unlock(self);
			self:Hide();
			ArenaEnemyFrames_UpdateVisible();
		end
	elseif ( event == "UNIT_PET" and arg1 == self.unit ) then
		ArenaEnemyFrame_UpdatePet(self);
	elseif ( event == "UNIT_NAME_UPDATE" and arg1 == self.unit ) then
		ArenaEnemyFrame_UpdatePlayer(self);
	end
end

function ArenaEnemyFrame_UpdatePet(self, id, useCVars)	--At some points, we need to use CVars instead of UVars even though UVars are faster.
	if ( not id ) then
		id = self:GetID();
	end
	
	local unitFrame = _G["ArenaEnemyFrame"..id];
	local petFrame = _G["ArenaEnemyFrame"..id.."PetFrame"];
	
	local showArenaEnemyPets = (SHOW_ARENA_ENEMY_PETS == "1");
	if ( useCVars ) then
		showArenaEnemyPets = GetCVarBool("showArenaEnemyPets");
	end
	
	if ( UnitExists(petFrame.unit) and showArenaEnemyPets) then
		petFrame:Show();
	else
		petFrame:Hide();
	end
	
	UnitFrame_Update(petFrame);
end

function ArenaEnemyPetFrame_OnLoad(self)
	local id = self:GetParent():GetID();
	self:SetID(id);
	self:SetParent(ArenaEnemyFrames);
	ArenaEnemyFrame_UpdatePet(self, id, true);
	self:RegisterEvent("ARENA_OPPONENT_UPDATE");
end

function ArenaEnemyPetFrame_OnEvent(self, event, ...)
	local arg1, arg2 = ...;
	if ( event == "ARENA_OPPONENT_UPDATE" and arg1 == self.unit ) then
		if ( arg2 == "seen" or arg2 == "destroyed") then
			ArenaEnemyFrame_Unlock(self);
			ArenaEnemyFrame_UpdatePet(self);
			UpdateArenaEnemyBackground();
		elseif ( arg2 == "unseen" ) then
			ArenaEnemyFrame_Lock(self);
		elseif ( arg2 == "cleared" ) then
			ArenaEnemyFrame_Unlock(self);
			self:Hide()
		end
	end
	UnitFrame_OnEvent(self, event, ...);
end

function ArenaEnemyDropDown_Initialize (self)
	UnitPopup_ShowMenu(self, "ARENAENEMY", "arena"..self:GetParent():GetID());
end

function UpdateArenaEnemyBackground(force)
	if ( (SHOW_PARTY_BACKGROUND == "1") or force ) then
		ArenaEnemyBackground:Show();
		local numOpps = GetNumArenaOpponents();
		if ( numOpps > 0 ) then
			ArenaEnemyBackground:SetPoint("BOTTOMLEFT", "ArenaEnemyFrame"..numOpps.."PetFrame", "BOTTOMLEFT", -15, -10);
		else
			ArenaEnemyBackground:Hide();
		end
	else
		ArenaEnemyBackground:Hide();
	end
	
end

function ArenaEnemyBackground_SetOpacity(opacity)
	local alpha;
	if ( not opacity ) then
		alpha = 1.0 - OpacityFrameSlider:GetValue();
	else
		alpha = 1.0 - opacity;
	end
	ArenaEnemyBackground:SetAlpha(alpha);
end
