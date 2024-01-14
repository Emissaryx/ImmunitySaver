-- Local data
local VERSION = 1.00
local TIME_DELAY = 1.5
local timeLeft = TIME_DELAY
local IMMOVABLE = 4
local UNSTOPPABLE = 5
local MAX_BUTTONS = 60
local eventsRegistered = false
local loadingEnd = false

-- Localized functions
local pairs = pairs
local tostring = tostring
local towstring = towstring
local GetBuffs = GetBuffs
local GetHotbarCooldown = GetHotbarCooldown
local GetAbilityData = GetAbilityData
local GetHotbarData = GetHotbarData
local BroadcastEvent = BroadcastEvent
local TextLogAddEntry = TextLogAddEntry
local RegisterEventHandler = RegisterEventHandler
local UnregisterEventHandler = UnregisterEventHandler

-- Local functions
local function hasHostileTarget()
	local target = TargetInfo.m_Units[TargetInfo.HOSTILE_TARGET]
	if target and target.entityid ~= 0 then
		return true
	end
	return false
end

local function hasBuff(target, abilityData, stackCount)
	if not target then
		return false
	end
	local buffData = GetBuffs(target)
    if not buffData then
		return false
    end

	for _, buff in pairs( buffData )
    do
		if buff.iconNum == abilityData.iconNum and buff.castByPlayer and buff.stackCount == stackCount then
			return true
        end
    end
    return false
end

local function getTargetType(targetType)
    -- Check if the target is hostile, and hasHostileTarget() returns true
    if targetType == 1 and hasHostileTarget() then
        return GameData.BuffTargetType.TARGET_HOSTILE
    else
        -- For all other conditions or target types, do nothing or return nil
        return nil
    end
end


local function alertText(text)
	if SettingsWindowTabInterface.SavedMessageSettings.combat then
		SystemData.AlertText.VecType = {SystemData.AlertText.Types.COMBAT}
		SystemData.AlertText.VecText = {towstring(text)}
		BroadcastEvent(SystemData.Events.SHOW_ALERT_TEXT)
	end
end

local function chatInfo(actionId, state)
	local name = tostring(GetAbilityData(actionId).name)
	local icon = "<icon".. tostring(GetAbilityData(actionId).iconNum) .. ">"
	if not state then
		TextLogAddEntry("Chat", 0, towstring("ImmunitySaver: Clearing check for " .. icon .. " " .. name))
	elseif state == IMMOVABLE then
		TextLogAddEntry("Chat", 0, towstring("ImmunitySaver: Setting <icon05007> Immovable check for " .. icon .. " " .. name))
	elseif state == UNSTOPPABLE then
		TextLogAddEntry("Chat", 0, towstring("ImmunitySaver: Setting <icon05006> Unstoppable check for " .. icon .. " " .. name))
	end
end

local function isAbilityBlocked(actionId)
	if ImmunitySaver.Settings.Enabled then
		local abilityData = GetAbilityData(actionId)
		
		if ImmunitySaver.TargetImmovable and ImmunitySaver.Settings.Abilities[actionId] and ImmunitySaver.Settings.Abilities[actionId] == IMMOVABLE then
			if ImmunitySaver.Settings.ErrorMessages then alertText("Target is Immovable") end
			return true
		elseif ImmunitySaver.TargetUnstoppable and ImmunitySaver.Settings.Abilities[actionId] and ImmunitySaver.Settings.Abilities[actionId] == UNSTOPPABLE then
			if ImmunitySaver.Settings.ErrorMessages then alertText("Target is Unstoppable") end
			return true
		else
			return false
		end
	else
		return false
	end

end

-- Block WindowGameAction
local orgWindowGameAction = WindowGameAction
local function blockedWindowGameAction(windowName)
	-- Do nothing
end

-- ImmunitySaver
ImmunitySaver = ImmunitySaver or {}
ImmunitySaver.HostileTargetId = 0
ImmunitySaver.TargetImmovable = false
ImmunitySaver.TargetUnstoppable = false
ImmunitySaver.HostileTargetEffects = {}
ImmunitySaver.EnabledStatesNeedUpdate = true -- Throttle calls to ImmunitySaver.UpdateButtonsEnabledStates()
ImmunitySaver.ButtonIconsNeedUpdate = true -- Throttle calls to ImmunitySaver.UpdateButtonIcons()

ImmunitySaver.DefaultSettings = {
	Version = VERSION,
	Enabled = true,
	Symbols = true,
	ErrorMessages = true,
	Abilities = {
		-- Ironbreaker
		[1384] = UNSTOPPABLE,	-- Cave-In
		[1369] = UNSTOPPABLE,	-- Shield of Reprisal
		[1365] = IMMOVABLE,		-- Away With Ye
		-- Slayer
		[1443] = UNSTOPPABLE,	-- Incapacitate
		-- Runepriest
		[1613] = UNSTOPPABLE,	-- Rune of Binding
		[1607] = UNSTOPPABLE,	-- Spellbinding Rune
		-- Engineer
		[1536] = UNSTOPPABLE,	-- Crack Shot
		[1531] = IMMOVABLE,		-- Concussion Grenade
		-- Black Orc
		[1688] = UNSTOPPABLE,	-- Down Ya Go
		[1683] = UNSTOPPABLE,	-- Shut Yer Face
		-- Choppa
		[1755] = UNSTOPPABLE,	-- Sit Down!
		-- Shaman
		[1929] = IMMOVABLE,		-- Geddoff!
		[1917] = UNSTOPPABLE,	-- You Got Nuthin!
		-- Squig Herder
		[1839] = UNSTOPPABLE,	-- Choking Arrer
		[1837] = UNSTOPPABLE,	-- Drop That!!
		[1835] = UNSTOPPABLE,	-- Not So Fast!
		-- Witch Hunter
		[8110] = UNSTOPPABLE,	-- Dragon Gun
		[8086] = UNSTOPPABLE,	-- Confess!
		[8115] = UNSTOPPABLE,	-- Pistol Whip
		[8100] = UNSTOPPABLE,	-- Silence The Heretic
		[8094] = UNSTOPPABLE,	-- Declare Anathema
		-- Knight of the Blazing Sun
		[8018] = UNSTOPPABLE,	-- Smashing Counter
		[8017] = IMMOVABLE,		-- Repel Darkness
		-- Bright Wizard
		[8186] = UNSTOPPABLE,	-- Stop, Drop, and Roll
		[8174] = UNSTOPPABLE,	-- Choking Smoke
		-- Warrior Priest
		[8256] = UNSTOPPABLE,	-- Vow of Silence
		-- Chosen
		[8346] = UNSTOPPABLE,	-- Downfall
		[8329] = IMMOVABLE,		-- Repel
		-- Marauder
		[8412] = UNSTOPPABLE,	-- Mutated Energy
		[8405] = UNSTOPPABLE,	-- Death Grip
		[8410] = IMMOVABLE,		-- Terrible Embrace
		-- Zealot
		[8571] = UNSTOPPABLE,	-- Aethyric Shock
		[8565] = UNSTOPPABLE,	-- Tzeentch's Lash
		-- Magus
		[8495] = UNSTOPPABLE,	-- Perils of The Warp
		[8483] = IMMOVABLE,		-- Warping Blast
		-- Swordmaster
		[9032] = IMMOVABLE,		-- Redirected Force
		-- [9030] = UNSTOPPABLE,	-- Whispering Window
		[9028] = UNSTOPPABLE,	-- Chrashing Wave
		-- Shadow Warrior
		[9096] = UNSTOPPABLE,	-- Eye Shot
		[9108] = UNSTOPPABLE,	-- Exploit Weakness
		[9098] = UNSTOPPABLE,	-- Opportunistic Strike
		-- White Lion
		[9193] = UNSTOPPABLE,	-- Brutal Pounce
		[9177] = UNSTOPPABLE,	-- Throat Bite
		[9178] = IMMOVABLE,		-- Fetch!
		-- Archmage
		[9266] = IMMOVABLE,		-- Cleansing Flare
		[9253] = UNSTOPPABLE,	-- Law of Gold
		-- Blackguard
		[2888] = UNSTOPPABLE,	-- Malignant Strike!
		[9321] = UNSTOPPABLE,	-- Spiteful Slam
		[9328] = IMMOVABLE,		-- Exile
		-- Witch Elf
		[9422] = UNSTOPPABLE,	-- On Your Knees!
		[9400] = UNSTOPPABLE,	-- Sever Limb
		[9427] = UNSTOPPABLE,	-- Heart Seeker
		[9409] = UNSTOPPABLE,	-- Throat Slitter
		[9396] = UNSTOPPABLE,	-- Agile Escape
		-- Disciple of Khaine
		[9565] = UNSTOPPABLE,	-- Consume Thought
		-- Sorcerer
		[9482] = UNSTOPPABLE,	-- Frostbite
		[9489] = UNSTOPPABLE,	-- Stricken Voices
	},
}

function ImmunitySaver.Initialize()
	-- No old settings use default settings
	if not ImmunitySaver.Settings then
		ImmunitySaver.Settings = ImmunitySaver.DefaultSettings
	
	-- Import old settings
	elseif ImmunitySaver.Settings then
		ImmunitySaver.Settings.Version = ImmunitySaver.DefaultSettings.Version
		ImmunitySaver.Settings.Enabled = ImmunitySaver.Settings.Enabled or ImmunitySaver.DefaultSettings.Enabled
		ImmunitySaver.Settings.Symbols = ImmunitySaver.Settings.Symbols or ImmunitySaver.DefaultSettings.Symbols
		ImmunitySaver.Settings.ErrorMessages = ImmunitySaver.Settings.ErrorMessages or ImmunitySaver.DefaultSettings.ErrorMessages
		ImmunitySaver.Settings.Abilities = ImmunitySaver.Settings.Abilities or ImmunitySaver.DefaultSettings.Abilities
	end
	
	LibSlash.RegisterSlashCmd("ImmunitySaver", function(input) ImmunitySaver_Config.Slash(input) end)
	
	if ImmunitySaver.Settings.Enabled then ImmunitySaver.RegisterEvents()	end
	
	TextLogAddEntry("Chat", 0, towstring("<icon57> ImmunitySaver loaded. Type /ImmunitySaver for settings."))
end

function ImmunitySaver.OnShutdown()
	ImmunitySaver.UnregisterEvents()
end

function ImmunitySaver.RegisterEvents()
	if not eventsRegistered then
		RegisterEventHandler(SystemData.Events.ENTER_WORLD, "ImmunitySaver.ENTER_WORLD")
		RegisterEventHandler(SystemData.Events.PLAYER_ZONE_CHANGED, "ImmunitySaver.PLAYER_ZONE_CHANGED")
		RegisterEventHandler(SystemData.Events.INTERFACE_RELOADED, "ImmunitySaver.INTERFACE_RELOADED")
		RegisterEventHandler(SystemData.Events.PLAYER_TARGET_UPDATED, "ImmunitySaver.PLAYER_TARGET_UPDATED")
		RegisterEventHandler(SystemData.Events.PLAYER_TARGET_IS_IMMUNE_TO_MOVEMENT_IMPARING, "ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_MOVEMENT_IMPARING")
		RegisterEventHandler(SystemData.Events.PLAYER_TARGET_IS_IMMUNE_TO_DISABLES, "ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_DISABLES")
		RegisterEventHandler(SystemData.Events.PLAYER_HOT_BAR_UPDATED, "ImmunitySaver.PLAYER_HOT_BAR_UPDATED")
	end
	eventsRegistered = true
end

function ImmunitySaver.UnregisterEvents()
	if eventsRegistered then
		UnregisterEventHandler(SystemData.Events.ENTER_WORLD, "ImmunitySaver.ENTER_WORLD")
		UnregisterEventHandler(SystemData.Events.PLAYER_ZONE_CHANGED, "ImmunitySaver.PLAYER_ZONE_CHANGED")
		UnregisterEventHandler(SystemData.Events.INTERFACE_RELOADED, "ImmunitySaver.INTERFACE_RELOADED")
		UnregisterEventHandler(SystemData.Events.PLAYER_TARGET_UPDATED, "ImmunitySaver.PLAYER_TARGET_UPDATED")
		UnregisterEventHandler(SystemData.Events.PLAYER_TARGET_IS_IMMUNE_TO_MOVEMENT_IMPARING, "ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_MOVEMENT_IMPARING")
		UnregisterEventHandler(SystemData.Events.PLAYER_TARGET_IS_IMMUNE_TO_DISABLES, "ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_DISABLES")
		UnregisterEventHandler(SystemData.Events.PLAYER_HOT_BAR_UPDATED, "ImmunitySaver.PLAYER_HOT_BAR_UPDATED")
	end
	eventsRegistered = false
end

-- Event handlers
function ImmunitySaver.ENTER_WORLD()
	loadingEnd = true
	ImmunitySaver.ButtonIconsNeedUpdate = true
end

function ImmunitySaver.PLAYER_ZONE_CHANGED()
	loadingEnd = true
	ImmunitySaver.ButtonIconsNeedUpdate = true
end

function ImmunitySaver.INTERFACE_RELOADED()
	loadingEnd = true
	ImmunitySaver.ButtonIconsNeedUpdate = true
end

function ImmunitySaver.PLAYER_TARGET_UPDATED(targetClassification, targetId, targetType)
    if targetClassification ~= "mouseovertarget" then
	-- Ignore mouseover target changes
	if targetClassification == TargetInfo.HOSTILE_TARGET and ImmunitySaver.HostileTargetId ~= targetId then
		ImmunitySaver.HostileTargetId = targetId
		ImmunitySaver.HostileTargetEffects = {}
		ImmunitySaver.TargetImmovable = false
		ImmunitySaver.TargetUnstoppable = false
		ImmunitySaver.EnabledStatesNeedUpdate = true
	end
	end
end

function ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_DISABLES(state)
	ImmunitySaver.TargetUnstoppable = state
	ImmunitySaver.EnabledStatesNeedUpdate = true
end

function ImmunitySaver.PLAYER_TARGET_IS_IMMUNE_TO_MOVEMENT_IMPARING(state)
	ImmunitySaver.TargetImmovable = state
	ImmunitySaver.EnabledStatesNeedUpdate = true
end

function ImmunitySaver.PLAYER_HOT_BAR_UPDATED(slot, actionType, actionId)
	ImmunitySaver.UpdateButtonIcon(slot, ImmunitySaver.Settings.Abilities[actionId])
	ImmunitySaver.UpdateButtonEnabledState(slot)
end

-- Main update function
function ImmunitySaver.OnUpdate(elapsed)
	if not loadingEnd then return end
	if not ImmunitySaver.Settings.Enabled then return end
	
	timeLeft = timeLeft - elapsed
    if timeLeft > 0 then
        return
    end
    timeLeft = TIME_DELAY
	
	if ImmunitySaver.ButtonIconsNeedUpdate then
		ImmunitySaver.UpdateButtonIcons()
		ImmunitySaver.ButtonIconsNeedUpdate = false
	end
	
	if ImmunitySaver.EnabledStatesNeedUpdate then
		ImmunitySaver.UpdateButtonsEnabledStates()
		ImmunitySaver.EnabledStatesNeedUpdate = false
	end
end

function ImmunitySaver.UpdateSettings()
	if ImmunitySaver.Settings.Enabled and not eventsRegistered then
		ImmunitySaver.RegisterEvents()
	elseif not ImmunitySaver.Settings.Enabled and eventsRegistered then
		ImmunitySaver.UnregisterEvents()
	end
	
	ImmunitySaver.UpdateButtonIcons()

	TextLogAddEntry("Chat", 0, towstring("ImmunitySaver v" .. tostring(ImmunitySaver.Settings.Version) .. " settings: /ImmunitySaver"))
	if ImmunitySaver.Settings.Enabled then
		TextLogAddEntry("Chat", 0, L"--- <icon57> Enabled")
	else
		TextLogAddEntry("Chat", 0, L"--- <icon58> Enabled")
	end
	if ImmunitySaver.Settings.Symbols then
		TextLogAddEntry("Chat", 0, L"--- <icon57> Show Symbols")
	else
		TextLogAddEntry("Chat", 0, L"--- <icon58> Show Symbols")
	end
	if ImmunitySaver.Settings.ErrorMessages then
		TextLogAddEntry("Chat", 0, L"--- <icon57> Show Combat Error Messages")
	else
		TextLogAddEntry("Chat", 0, L"--- <icon58> Show Combat Error Messages")
	end
end

function ImmunitySaver.UpdateButtonIcons()
	local actionType, actionId, isSlotEnabled, isTargetValid, isSlotBlocked
	for i = 1, MAX_BUTTONS do
		actionType, actionId, isSlotEnabled, isTargetValid, isSlotBlocked = GetHotbarData(i)
		if ImmunitySaver.Settings.Enabled and ImmunitySaver.Settings.Symbols and ImmunitySaver.Settings.Abilities[actionId] then
			ImmunitySaver.UpdateButtonIcon(i, ImmunitySaver.Settings.Abilities[actionId])
		elseif (not ImmunitySaver.Settings.Enabled or not ImmunitySaver.Settings.Symbols) and ImmunitySaver.Settings.Abilities[actionId] then
			ImmunitySaver.UpdateButtonIcon(i, 0)
		end
	end
end

function ImmunitySaver.UpdateButtonIcon(slot, check)
	local hbar, buttonid, button
	local buttonActionId
	hbar, buttonid = ActionBars:BarAndButtonIdFromSlot(slot)
	if hbar and buttonid then
		button = hbar.m_Buttons[buttonid]
		if not check then
			--button.m_Windows[7]:Show(false)
		elseif check == IMMOVABLE then
			button.m_Windows[7]:Show(true)
			button.m_Windows[7]:SetText("<icon05007>")
		elseif check == UNSTOPPABLE then
			button.m_Windows[7]:Show(true)
			button.m_Windows[7]:SetText("<icon05006>")
		elseif check == 0 then
			button.m_Windows[7]:Show(false)
		end
	end
end

function ImmunitySaver.UpdateButtonsEnabledStates()
	for i = 1, MAX_BUTTONS do
		ImmunitySaver.UpdateButtonEnabledState(i)
	end
end

function ImmunitySaver.UpdateButtonEnabledState(slot)
	local actionType, actionId, isSlotEnabled, isTargetValid, isSlotBlocked = GetHotbarData(slot)
	--if actionId ~= 0 then
	if ImmunitySaver.Settings.Abilities[actionId] then
		ActionBars.UpdateSlotEnabledState(slot, isSlotEnabled, isTargetValid, isSlotBlocked)
	end
end

-- Hooked Functions
local orgActionButtonOnLButtonDown = ActionButton.OnLButtonDown
function ActionButton.OnLButtonDown(self, flags, x, y)
	if flags == SystemData.ButtonFlags.SHIFT and self.m_ActionId ~= 0 then
    -- Cycle through no setting, IMMOVABLE, and UNSTOPPABLE
		if not ImmunitySaver.Settings.Abilities[self.m_ActionId] then
        ImmunitySaver.Settings.Abilities[self.m_ActionId] = IMMOVABLE -- First press sets to IMMOVABLE
    elseif ImmunitySaver.Settings.Abilities[self.m_ActionId] == IMMOVABLE then
        ImmunitySaver.Settings.Abilities[self.m_ActionId] = UNSTOPPABLE -- Second press sets to UNSTOPPABLE
    else
        ImmunitySaver.Settings.Abilities[self.m_ActionId] = nil -- Third press resets to no setting
		end

		ImmunitySaver.UpdateButtonIcon(self.m_HotBarSlot, ImmunitySaver.Settings.Abilities[self.m_ActionId] or 0)
		ImmunitySaver.UpdateButtonEnabledState(self.m_HotBarSlot)
		chatInfo(self.m_ActionId, ImmunitySaver.Settings.Abilities[self.m_ActionId])

		-- Block WindowGameAction
		WindowGameAction = blockedWindowGameAction

	elseif self.m_ActionId ~= 0
	and ImmunitySaver.Settings.Abilities[self.m_ActionId]
	and isAbilityBlocked(self.m_ActionId) then
		-- Block WindowGameAction
		WindowGameAction = blockedWindowGameAction

	else
		-- Restore WindowGameAction
		WindowGameAction = orgWindowGameAction

		orgActionButtonOnLButtonDown(self, flags, x, y)
	end
end

local orgActionBarsUpdateSlotEnabledState = ActionBars.UpdateSlotEnabledState
function ActionBars.UpdateSlotEnabledState(slot, isSlotEnabled, isTargetValid, isSlotBlocked)
	local hbar, buttonid = ActionBars:BarAndButtonIdFromSlot(slot)
	if hbar and buttonid then
		local button = hbar.m_Buttons[buttonid]
		local abilityData = GetAbilityData(button.m_ActionId)
		
		if ImmunitySaver.Settings.Abilities[button.m_ActionId]
		and ImmunitySaver.Settings.Abilities[button.m_ActionId] == IMMOVABLE
		and ImmunitySaver.TargetImmovable
		then
			isSlotEnabled = false
		elseif ImmunitySaver.Settings.Abilities[button.m_ActionId]
		and ImmunitySaver.Settings.Abilities[button.m_ActionId] == UNSTOPPABLE
		and ImmunitySaver.TargetUnstoppable
		then
			isSlotEnabled = false
		end
	end
	orgActionBarsUpdateSlotEnabledState(slot, isSlotEnabled, isTargetValid, isSlotBlocked)
end

local orgActionButtonUpdateInventory = ActionButton.UpdateInventory
function ActionButton.UpdateInventory(self)
	if not ImmunitySaver.Settings.Abilities[self.m_ActionId] then
		orgActionButtonUpdateInventory(self)
	end
end